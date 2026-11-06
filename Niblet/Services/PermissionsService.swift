import ApplicationServices
import Cocoa

@MainActor
enum PermissionsService {
    static var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    /// Shows the system permission prompt and registers the app in the
    /// Accessibility list in System Settings.
    static func requestAccessibilityPermission() {
        // Literal key because kAXTrustedCheckOptionPrompt is imported as a
        // global var, which Swift 6 strict concurrency rejects
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    static func openAccessibilitySettings() {
        guard
            let url = URL(
                string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
            )
        else { return }
        NSWorkspace.shared.open(url)
    }
}
