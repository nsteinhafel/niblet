import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var lockManager: LockManager

    var body: some View {
        Group {
            if lockManager.isLocked {
                Text("Type \"\(lockManager.unlockPhrase)\" to unlock")
                    .foregroundStyle(.secondary)
            } else {
                Button("Lock Input") {
                    lockManager.lock()
                }
            }

            if !lockManager.isLocked {
                Divider()

                SettingsLink {
                    Text("Settings...")
                }

                Divider()

                Button("Quit Niblet") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }
}
