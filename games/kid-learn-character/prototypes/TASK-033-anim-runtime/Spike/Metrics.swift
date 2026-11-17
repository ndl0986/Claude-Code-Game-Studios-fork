// PROTOTYPE - NOT FOR PRODUCTION (TASK-033 spike)
// Timing, frame and memory logs. All times are mach-based seconds (CACurrentMediaTime == systemUptime base), the
// same clock as UITouch/UIPress/NSEvent timestamps.
import Foundation
import QuartzCore
import Darwin

final class Metrics {
    static let shared = Metrics()

    struct PressRow {
        var key: String, source: String, runtime: String
        var press: Double            // the event's own timestamp
        var handled: Double          // when the app's handler ran
        var firstFrame: Double = 0   // renderer callback of the first frame drawing the change (lower bound of presentation)
        var presentEst: Double = 0   // the display link's target time for that frame (estimated presentation)
        var soundSched: Double = 0   // when the sound buffer was scheduled and the player started
        var soundEst: Double = 0     // soundSched + io buffer + output latency (estimated first audible sample)
        var cold: Bool
        var queued: Bool             // started later from the queue (not a latency sample)
        var dropped: Bool
    }

    var rows: [PressRow] = []
    var frameTimes: [Double] = []    // the renderer's own frame timestamps
    var memory: [(t: Double, mb: Double)] = []
    var maxActiveMorphs = 0, maxVoices = 0, maxQueue = 0
    var seenKeys = Set<String>()
    private var openRow: Int?
    var lastTargetTimestamp = 0.0, lastLinkDuration = 1.0 / 60

    func press(key: String, source: String, runtime: String, at t: Double) -> Int {
        let cold = !seenKeys.contains("\(runtime):\(key)"); seenKeys.insert("\(runtime):\(key)")
        rows.append(PressRow(key: key, source: source, runtime: runtime, press: t, handled: CACurrentMediaTime(), cold: cold, queued: false, dropped: false))
        return rows.count - 1
    }

    /// The press whose change the next rendered frame will show.
    func awaitFrame(_ row: Int) { openRow = row }

    /// Called by the renderer for every frame it draws.
    func frame(at t: Double) {
        frameTimes.append(t)
        if let r = openRow {
            rows[r].firstFrame = t
            // the display link's target time is the presentation time of the frame being prepared now
            // (the next vsync after this frame was encoded: step the last target forward until it lies after t)
            var p = lastTargetTimestamp, d = lastLinkDuration > 0 ? lastLinkDuration : 1.0 / 60
            if p <= 0 { p = t + d }
            while p <= t { p += d }
            rows[r].presentEst = p
            openRow = nil
        }
    }

    static func footprintMB() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let kr = withUnsafeMutablePointer(to: &info) { $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count) } }
        return kr == KERN_SUCCESS ? Double(info.phys_footprint) / 1_048_576 : -1
    }

    func sampleMemory() { memory.append((CACurrentMediaTime(), Self.footprintMB())) }

    static func pct(_ v: [Double], _ p: Double) -> Double {
        guard !v.isEmpty else { return .nan }
        let s = v.sorted(); return s[min(s.count - 1, Int((Double(s.count - 1) * p).rounded()))]
    }

    /// Writes CSVs and a summary to Documents and logs the summary.
    @discardableResult
    func dump(label: String) -> String {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var csv = "key,source,runtime,cold,queued,dropped,press,handled_ms,first_frame_ms,present_est_ms,sound_sched_ms,sound_est_ms\n"
        func ms(_ a: Double, _ b: Double) -> String { b > 0 ? String(format: "%.2f", (b - a) * 1000) : "" }
        for r in rows {
            csv += "\(r.key),\(r.source),\(r.runtime),\(r.cold),\(r.queued),\(r.dropped),\(String(format: "%.4f", r.press)),\(ms(r.press, r.handled)),\(ms(r.press, r.firstFrame)),\(ms(r.press, r.presentEst)),\(ms(r.press, r.soundSched)),\(ms(r.press, r.soundEst))\n"
        }
        try? csv.write(to: docs.appendingPathComponent("\(label)-presses.csv"), atomically: true, encoding: .utf8)
        let ft = zip(frameTimes.dropFirst(), frameTimes).map { ($0 - $1) * 1000 }
        try? ft.map { String(format: "%.3f", $0) }.joined(separator: "\n").write(to: docs.appendingPathComponent("\(label)-frames-ms.txt"), atomically: true, encoding: .utf8)
        try? memory.map { String(format: "%.2f,%.1f", $0.t - (memory.first?.t ?? 0), $0.mb) }.joined(separator: "\n").write(to: docs.appendingPathComponent("\(label)-memory.csv"), atomically: true, encoding: .utf8)

        let samples = rows.filter { !$0.queued && !$0.dropped && $0.firstFrame > 0 }
        func stat(_ name: String, _ f: (PressRow) -> Double, cold: Bool) -> String {
            let v = samples.filter { $0.cold == cold }.map(f).filter { $0 > 0 }.map { $0 * 1000 }
            return String(format: "%@ %@ n=%d median=%.1f p95=%.1f max=%.1f", name, cold ? "cold" : "warm", v.count, Self.pct(v, 0.5), Self.pct(v, 0.95), v.max() ?? .nan)
        }
        var lines = ["[spike] \(label): presses=\(rows.count) dropped=\(rows.filter(\.dropped).count) queued=\(rows.filter(\.queued).count) maxActiveMorphs=\(maxActiveMorphs) maxQueue=\(maxQueue) maxVoices=\(maxVoices)"]
        for cold in [true, false] {
            lines.append(stat("press→firstFrame", { $0.firstFrame - $0.press }, cold: cold))
            lines.append(stat("press→presentEst", { $0.presentEst - $0.press }, cold: cold))
            lines.append(stat("press→soundEst", { $0.soundEst > 0 ? $0.soundEst - $0.press : 0 }, cold: cold))
        }
        lines.append(String(format: "frames n=%d p50=%.2f p99=%.2f max=%.2f ms", ft.count, Self.pct(ft, 0.5), Self.pct(ft, 0.99), ft.max() ?? .nan))
        if let a = memory.first, let b = memory.last {
            let mid = memory[memory.count / 2]
            lines.append(String(format: "memory MB start=%.1f mid=%.1f end=%.1f (%.0f s)", a.mb, mid.mb, b.mb, b.t - a.t))
        }
        let summary = lines.joined(separator: "\n")
        try? summary.write(to: docs.appendingPathComponent("\(label)-summary.txt"), atomically: true, encoding: .utf8)
        NSLog("%@", summary)
        return summary
    }

    func reset() { rows = []; frameTimes = []; memory = []; maxActiveMorphs = 0; maxVoices = 0; maxQueue = 0 }
}
