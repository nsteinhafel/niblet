import Cocoa
import SwiftUI

final class LockOverlayWindow: NSWindow {
    init(screen: NSScreen, unlockPhrase: String) {
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        self.level = .screenSaver
        self.isOpaque = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.hasShadow = false

        let overlayView = LockOverlayView(unlockPhrase: unlockPhrase)
        self.contentView = NSHostingView(rootView: overlayView)
    }

    // Prevent the window from becoming key or main to avoid UI focus issues
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class LockOverlayController {
    private var windows: [LockOverlayWindow] = []

    func showOverlay(unlockPhrase: String) {
        // Hide existing windows first
        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()

        // Create overlay for each screen
        for screen in NSScreen.screens {
            let window = LockOverlayWindow(screen: screen, unlockPhrase: unlockPhrase)
            window.orderFrontRegardless()
            windows.append(window)
        }
    }

    func hideOverlay() {
        for window in windows {
            window.orderOut(nil)
        }
        // Don't removeAll - keep references to avoid deallocation during autorelease
    }
}
