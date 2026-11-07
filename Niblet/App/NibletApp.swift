import SwiftUI

@main
struct NibletApp: App {
    @State private var lockManager = LockManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(lockManager)
        } label: {
            MenuBarIcon()
                .environment(lockManager)
        }

        Settings {
            SettingsView()
                .environment(lockManager)
        }
    }
}

/// Reads `isLocked` in a view body so the icon redraws when it changes.
private struct MenuBarIcon: View {
    @Environment(LockManager.self) private var lockManager

    var body: some View {
        Image(lockManager.isLocked ? "MenuBarIconLocked" : "MenuBarIcon")
            .renderingMode(.template)
    }
}
