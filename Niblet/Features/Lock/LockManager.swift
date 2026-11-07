import Foundation
import Observation

@MainActor
@Observable
final class LockManager {
    private(set) var isLocked = false

    /// Sanitized on set so it only contains characters `PhraseDetector` can receive.
    var unlockPhrase: String {
        get { storedUnlockPhrase }
        set {
            storedUnlockPhrase = PhraseDetector.sanitize(phrase: newValue)
            defaults.set(storedUnlockPhrase, forKey: Keys.unlockPhrase)
        }
    }

    var blockFunctionKeys: Bool {
        didSet { defaults.set(blockFunctionKeys, forKey: Keys.blockFunctionKeys) }
    }

    var showOverlay: Bool {
        didSet { defaults.set(showOverlay, forKey: Keys.showOverlay) }
    }

    private static let defaultUnlockPhrase = "quit"

    private enum Keys {
        static let unlockPhrase = "unlockPhrase"
        static let blockFunctionKeys = "blockFunctionKeys"
        static let showOverlay = "showOverlay"
    }

    private var storedUnlockPhrase: String

    private let defaults = UserDefaults.standard
    private let inputBlocker = InputBlocker()
    private let overlay = LockOverlayController()
    private let phraseDetector = PhraseDetector(phrase: LockManager.defaultUnlockPhrase)

    init() {
        storedUnlockPhrase = PhraseDetector.sanitize(
            phrase: defaults.string(forKey: Keys.unlockPhrase) ?? Self.defaultUnlockPhrase
        )
        blockFunctionKeys = defaults.object(forKey: Keys.blockFunctionKeys) as? Bool ?? true
        showOverlay = defaults.object(forKey: Keys.showOverlay) as? Bool ?? true

        phraseDetector.onPhraseDetected = { [weak self] in
            // Hop out of the event tap callback before tearing the tap down
            Task { @MainActor in
                self?.unlock()
            }
        }

        inputBlocker.onKeyPress = { [weak self] key in
            guard let self else { return }
            phraseDetector.processKey(key)
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

        phraseDetector.phrase = unlockPhrase
        phraseDetector.reset()

        inputBlocker.blockFunctionKeys = blockFunctionKeys

        // If the tap can't be created (e.g. permission revoked since launch),
        // bail before showing the overlay so it never covers live input
        guard inputBlocker.startBlocking() else {
            PermissionGuideWindowController.shared.show()
            return
        }

        if showOverlay {
            overlay.showOverlay(unlockPhrase: unlockPhrase)
        }

        isLocked = true
    }

    /// Must not be called synchronously from inside the event tap callback.
    func unlock() {
        guard isLocked else { return }

        isLocked = false
        phraseDetector.reset()
        inputBlocker.stopBlocking()
        overlay.hideOverlay()
    }
}
