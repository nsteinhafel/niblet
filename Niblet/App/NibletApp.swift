import SwiftUI

@main
struct NibletApp: App {
    @StateObject private var lockManager = LockManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(lockManager)
        } label: {
            Image(lockManager.isLocked ? "MenuBarIconLocked" : "MenuBarIcon")
                .renderingMode(.template)
        }

        Settings {
            SettingsView()
                .environmentObject(lockManager)
        }
    }
}
