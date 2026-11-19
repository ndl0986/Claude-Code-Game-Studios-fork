// PROTOTYPE - NOT FOR PRODUCTION (TASK-078 DeviceSpike)
// On-screen and console log (debug); a session's results.md copies what it needs. Nothing is sent anywhere.
import SwiftUI
import os

@MainActor
final class SpikeLog: ObservableObject {
    static let shared = SpikeLog()
    static let build = (Bundle.main.object(forInfoDictionaryKey: "SpikeCommit") as? String) ?? "dev"
    @Published var lines: [String] = []
    private let logger = Logger(subsystem: "spike.devicespike", category: "spike")
    func line(_ s: String) {
        let t = String(format: "%.4f", ProcessInfo.processInfo.systemUptime)
        lines.append("\(t) \(s)"); if lines.count > 300 { lines.removeFirst(lines.count - 300) }
        logger.debug("\(s, privacy: .public)")
    }
}

struct LogView: View {
    @ObservedObject var log = SpikeLog.shared
    var body: some View {
        // follows the newest line (TASK-128): a headless screen capture of the iPad must show the latest results
        ScrollViewReader { r in
            ScrollView { VStack(alignment: .leading) { ForEach(Array(log.lines.enumerated()), id: \.offset) { Text($0.element).font(.caption.monospaced()).id($0.offset) } } }
                .onChange(of: log.lines.count) { _, n in if n > 0 { r.scrollTo(n - 1, anchor: .bottom) } }
        }
        .frame(maxHeight: 220).background(Color.black.opacity(0.05))
    }
}
