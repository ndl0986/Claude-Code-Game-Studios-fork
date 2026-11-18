// PROTOTYPE - NOT FOR PRODUCTION (TASK-078 DeviceSpike)
// One spike app for the ★ ADR device rows (TASK-075): Audio (ADR-0010), Keys (ADR-0007), Lock / Guided Access
// (ADR-0008), Render A/B (ADR-0009). Debug menu, no gate: remove it from the child's iPad after each session.
import SwiftUI

@main
struct DeviceSpikeApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
    }
}

enum Screen: String, CaseIterable, Identifiable {
    case audio = "Audio (ADR-0010)", keys = "Keys (ADR-0007)", lock = "Lock / Guided Access (ADR-0008)", render = "Render A/B (ADR-0009)"
    var id: String { rawValue }
}

struct RootView: View {
    @State private var screen: Screen?
    var body: some View {
        Group {
            if let s = screen {
                VStack(spacing: 0) {
                    HStack { Button("◀ Menu") { screen = nil }.padding(8); Spacer(); Text(s.rawValue).font(.headline); Spacer() }
                    switch s {
                    case .audio: AudioScreen()
                    case .keys: KeysScreen()
                    case .lock: LockScreen()
                    case .render: RenderScreen()
                    }
                }
            } else {
                List(Screen.allCases) { s in Button(s.rawValue) { screen = s } }
                    .navigationTitle("DeviceSpike (TASK-078)")
            }
        }
        .onAppear {
            SpikeLog.shared.line("launch build=\(SpikeLog.build) uptime=\(ProcessInfo.processInfo.systemUptime)")
            // `-screen render|audio|keys|lock` opens a screen directly (headless smoke runs on the dev simulator)
            if let s = UserDefaults.standard.string(forKey: "screen") { screen = Screen.allCases.first { $0.rawValue.lowercased().hasPrefix(s) } }
        }
    }
}
