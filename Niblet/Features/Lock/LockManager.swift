import SwiftUI

@MainActor
final class LockManager: ObservableObject {
    @Published private(set) var isLocked = false

    @Published var unlockPhrase: String {
        didSet {
            let sanitized = PhraseDetector.sanitize(phrase: unlockPhrase)
            if unlockPhrase != sanitized {
                unlockPhrase = sanitized
            }
            UserDefaults.standard.set(unlockPhrase, forKey: "unlockPhrase")
        }
    }

    @Published var blockFunctionKeys: Bool {
        didSet { UserDefaults.standard.set(blockFunctionKeys, forKey: "blockFunctionKeys") }
    }

    @Published var showOverlay: Bool {
        didSet { UserDefaults.standard.set(showOverlay, forKey: "showOverlay") }
    }

    private static let defaultUnlockPhrase = "quit"

    private let inputBlocker = InputBlocker()
    private let overlayController = LockOverlayController()
    private var phraseDetector: PhraseDetector?

    init() {
        // Load persisted settings
        self.unlockPhrase = PhraseDetector.sanitize(
            phrase: UserDefaults.standard.string(forKey: "unlockPhrase") ?? Self.defaultUnlockPhrase
        )
        self.blockFunctionKeys = UserDefaults.standard.object(forKey: "blockFunctionKeys") as? Bool ?? true
        self.showOverlay = UserDefaults.standard.object(forKey: "showOverlay") as? Bool ?? true

        setupPhraseDetector()
    }

    private func setupPhraseDetector() {
        phraseDetector = PhraseDetector(phrase: unlockPhrase)
        phraseDetector?.onPhraseDetected = { [weak self] in
            // Hop out of the event tap callback before tearing the tap down
            Task { @MainActor in
                self?.unlock()
            }
        }

        inputBlocker.onKeyPress = { [weak self] key in
            guard let self else { return }
            phraseDetector?.processKey(key)
            // Only the overlay's flash effect listens for this
            if showOverlay {
                NotificationCenter.default.post(name: .keyPressed, object: nil)
            }
        }
    }

    func lock() {
        guard !isLocked else { return }

        guard PermissionsService.hasAccessibilityPermission else {
            PermissionsService.requestAccessibilityPermission()
            PermissionGuideWindowController.shared.show()
            return
        }

        // An empty phrase would make the lock impossible to leave
        if unlockPhrase.isEmpty {
            unlockPhrase = Self.defaultUnlockPhrase
        }

        phraseDetector?.phrase = unlockPhrase
        phraseDetector?.reset()

        inputBlocker.blockFunctionKeys = blockFunctionKeys

        // If the tap can't be created (e.g. permission revoked since launch),
        // bail before showing the overlay so it never covers live input
        guard inputBlocker.startBlocking() else {
            PermissionGuideWindowController.shared.show()
            return
        }

        if showOverlay {
            overlayController.showOverlay(unlockPhrase: unlockPhrase)
        }

        isLocked = true
    }

    /// Must not be called synchronously from inside the event tap callback.
    func unlock() {
        guard isLocked else { return }

        isLocked = false
        phraseDetector?.reset()
        inputBlocker.stopBlocking()
        overlayController.hideOverlay()
    }
}
