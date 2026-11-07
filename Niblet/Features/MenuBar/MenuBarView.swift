import SwiftUI

struct MenuBarView: View {
    @Environment(LockManager.self) private var lockManager

    var body: some View {
        Group {
            if lockManager.isLocked {
                Text("Type \"\(lockManager.unlockPhrase)\" to unlock")
                    .foregroundStyle(.secondary)
            } else {
                Button("Lock Input") {
                    lockManager.lock()
                }

                Divider()

                SettingsLink {
                    Text("Settings…")
                }

                Divider()

                Button("Quit Niblet") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }
}
