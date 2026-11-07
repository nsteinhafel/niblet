import ServiceManagement
import SwiftUI

struct SettingsView: View {
    private enum Tab {
        case general, blocking
    }

    @State private var selectedTab: Tab = .general

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tab.general)

            BlockingSettingsTab()
                .tabItem {
                    Label("Blocking", systemImage: "hand.raised")
                }
                .tag(Tab.blocking)
        }
        .frame(width: 450, height: 250)
    }
}

struct GeneralSettingsTab: View {
    @Environment(LockManager.self) private var lockManager
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        @Bindable var lockManager = lockManager

        VStack(alignment: .leading, spacing: 8) {
            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, enabled in
                    guard enabled != (SMAppService.mainApp.status == .enabled) else { return }
                    do {
                        if enabled {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        // Revert the toggle to the actual registration state
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                }
                .onAppear {
                    // Pick up changes made in System Settings > Login Items
                    launchAtLogin = SMAppService.mainApp.status == .enabled
                }

            Text("Automatically start Niblet when you log in")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Text("Unlock phrase")

            TextField("", text: $lockManager.unlockPhrase)
                .textFieldStyle(.roundedBorder)

            Text("Type this phrase to unlock")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct BlockingSettingsTab: View {
    @Environment(LockManager.self) private var lockManager

    var body: some View {
        @Bindable var lockManager = lockManager

        VStack(alignment: .leading, spacing: 8) {
            Toggle("Block function keys", isOn: $lockManager.blockFunctionKeys)

            Text("Block volume, brightness, and media keys")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Toggle("Show overlay", isOn: $lockManager.showOverlay)

            Text("Display unlock hint on screen")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
