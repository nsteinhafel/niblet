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

    static let defaultUnlockPhrase = "quit"

    enum Keys {
        static let unlockPhrase = "unlockPhrase"
        static let blockFunctionKeys = "blockFunctionKeys"
        static let showOverlay = "showOverlay"
    }

    private var storedUnlockPhrase: String

    private let defaults: UserDefaults
    private let inputBlocker: any InputBlocking
    private let overlay: any OverlayPresenting
    private let permissions: any PermissionHandling
    private let phraseDetector = PhraseDetector(phrase: LockManager.defaultUnlockPhrase)

    init(
        defaults: UserDefaults = .standard,
        inputBlocker: any InputBlocking = InputBlocker(),
        overlay: any OverlayPresenting = LockOverlayController(),
        permissions: any PermissionHandling = PermissionsService()
    ) {
        self.defaults = defaults
        self.inputBlocker = inputBlocker
        self.overlay = overlay
        self.permissions = permissions

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

        guard permissions.hasAccessibilityPermission else {
            permissions.requestAccessibilityPermission()
            permissions.showPermissionGuide()
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
            permissions.showPermissionGuide()
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
