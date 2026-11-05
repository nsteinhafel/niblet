import Cocoa
import SwiftUI

@MainActor
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

@MainActor
final class LockOverlayController {
    private var windows: [LockOverlayWindow] = []
    private var screenObserver: NSObjectProtocol?
    private var activePhrase: String?

    func showOverlay(unlockPhrase: String) {
        activePhrase = unlockPhrase
        rebuildWindows()

        // Rebuild when displays are connected/disconnected or rearranged
        if screenObserver == nil {
            screenObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.rebuildWindows()
                }
            }
        }
    }

    func hideOverlay() {
        activePhrase = nil

        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
            screenObserver = nil
        }

        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()
    }

    private func rebuildWindows() {
        guard let phrase = activePhrase else { return }

        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()

        for screen in NSScreen.screens {
            let window = LockOverlayWindow(screen: screen, unlockPhrase: phrase)
            window.orderFrontRegardless()
            windows.append(window)
        }
    }
}
