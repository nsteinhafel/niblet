@testable import Niblet

@MainActor
final class FakeInputBlocker: InputBlocking {
    var onKeyPress: ((String) -> Void)?
    var blockFunctionKeys = true

    /// What `startBlocking()` reports, e.g. false to simulate a revoked permission.
    var startSucceeds = true
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var isBlocking = false

    func startBlocking() -> Bool {
        startCount += 1
        isBlocking = startSucceeds
        return startSucceeds
    }

    func stopBlocking() {
        stopCount += 1
        isBlocking = false
    }

    /// Simulates the event tap delivering each character of `text`.
    func type(_ text: String) {
        for char in text {
            onKeyPress?(String(char))
        }
    }
}

@MainActor
final class FakeOverlay: OverlayPresenting {
    private(set) var shownPhrases: [String] = []
    private(set) var hideCount = 0
    private(set) var isShowing = false

    func showOverlay(unlockPhrase: String) {
        shownPhrases.append(unlockPhrase)
        isShowing = true
    }

    func hideOverlay() {
        hideCount += 1
        isShowing = false
    }
}

@MainActor
final class FakePermissions: PermissionHandling {
    var hasAccessibilityPermission = true
    private(set) var requestCount = 0
    private(set) var guideCount = 0

    func requestAccessibilityPermission() {
        requestCount += 1
    }

    func showPermissionGuide() {
        guideCount += 1
    }
}
