// PROTOTYPE - NOT FOR PRODUCTION (TASK-087, ADR-0010 H-1: headless pre-check for Audio AC-9 and AC-21)
// Offline (manual rendering) check of cut and freeze mechanisms on the candidate graph:
//   player → gate mixer → bus mixer → submix → Apple PeakLimiter → main mixer.
// Signal: a tone at −1 dBFS, 100 Hz and 1 kHz, each started at 8 phases (k/8 of a period), so the cut lands at every
// phase including the peak (game-dev-android R1: a cut on a 5 ms boundary always hit a 100 Hz zero crossing).
// Detector: the sine-predictor residual r[n] = x[n] − 2cos(ω)x[n−1] + x[n−2], exactly 0 for a clean sine of any
// amplitude and phase; a slow gain change leaves a tiny residual, a step leaves one the size of the step.
// Threshold −60 dBFS (Audio AC-9). Every gated mechanism must pass at every phase and both tones.
// The freeze case also measures how many frames are lost across the resume (AC-21 "continues from where it stopped").
// Run: swift tools/offline-cut-check.swift
import AVFoundation

let sr = 48_000.0, amp: Float = 0.891          // −1 dBFS
let fmt = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 1)!
let quantum: AVAudioFrameCount = 240            // 5 ms render quanta, the IO period requested on the iPad
let cutChunk = 60                               // the event happens at 300 ms
let settleChunks = 8                            // cut_settle_s 40 ms = 8 quanta (ADR-0010 D5)
let resumeChunk = cutChunk + 28                 // the freeze is released 140 ms after it started

func startPlayer(_ p: AVAudioPlayerNode) throws {
    if #available(macOS 27, iOS 27, *) { try p.playAudio() } else { p.play() }
}
enum Signal: String, CaseIterable {
    case tone100 = "100 Hz", tone1k = "1 kHz", chord = "220+347 Hz", voice = "voice-like FM line"
    /// the predictor's tones (nil for the voice line, which uses the gain-trajectory metric)
    var tones: [Double]? { switch self { case .tone100: [100]; case .tone1k: [1000]; case .chord, .voice: nil } }
    func sample(_ i: Int, phase: Double) -> Float {
        let t = Double(i) / sr
        switch self {
        case .tone100, .tone1k: return amp * Float(sin(2 * .pi * tones![0] * t + phase))
        case .chord: return amp / 2 * Float(sin(2 * .pi * 220 * t + phase) + sin(2 * .pi * 347 * t + 1.7 * phase))
        case .voice:   // the spike's synthetic voice: a gliding, vibrato'd tone with a slow syllable envelope
            let env = 0.6 + 0.4 * sin(2 * .pi * 3 * t + phase)
            return amp * Float(env * sin(2 * .pi * (220 + 120 * t) * t + 0.3 * sin(2 * .pi * 5 * t) + phase))
        }
    }
}
/// Every source starts with a one-sample marker and 10 ms of silence: the first non-zero output sample of that same
/// rendering is its latency (the player's start can move by one render quantum between processes, and correlating
/// the voice-like line was unstable; game-qc-ios). The metrics start at 50 ms, after the marker.
let markerEnd = 480
let rewindFrames = settleChunks * Int(quantum) / 2        // 20 ms: half of cut_settle_s
let limiterDelay = 96                                // Apple PeakLimiter look-ahead: a stop at render frame f silences at f + 96 (probe)
func markerLatency(_ out: [Float]) -> Int { (out.firstIndex { abs($0) > 1e-6 } ?? 0) }
func signal(_ sg: Signal, phase: Double, seconds: Double) -> AVAudioPCMBuffer {
    let n = AVAudioFrameCount(sr * seconds)
    let b = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: n)!; b.frameLength = n
    for i in 0..<Int(n) { b.floatChannelData![0][i] = i < markerEnd ? 0 : sg.sample(i, phase: phase) }
    b.floatChannelData![0][0] = 0.5                  // the latency marker: one impulse, then silence until markerEnd
    return b
}
/// `connect(_:to:format:)` is deprecated in the 27 SDKs; `connectNode(_:to:format:)` (throws) is 27.0+.
func connect(_ e: AVAudioEngine, _ a: AVAudioNode, _ b: AVAudioNode) throws {
    if #available(macOS 27, iOS 27, *) { try e.connectNode(a, to: b, format: fmt) } else { e.connect(a, to: b, format: fmt) }
}
func dbfs(_ x: Float) -> Float { x <= 0 ? -200 : 20 * log10(x) }

final class Rig {
    let engine = AVAudioEngine(), player = AVAudioPlayerNode(), gate = AVAudioMixerNode()
    let bus = AVAudioMixerNode(), submix = AVAudioMixerNode()
    let limiter = AVAudioUnitEffect(audioComponentDescription: AudioComponentDescription(
        componentType: kAudioUnitType_Effect, componentSubType: kAudioUnitSubType_PeakLimiter,
        componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0))
    let out: AVAudioPCMBuffer
    var samples: [Float] = []
    init() throws {
        try engine.enableManualRenderingMode(.offline, format: fmt, maximumFrameCount: 4096)
        out = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: 4096)!
        for n in [player, gate, bus, submix, limiter] as [AVAudioNode] { engine.attach(n) }
        for (a, b) in [(player, gate), (gate, bus), (bus, submix), (submix, limiter), (limiter, engine.mainMixerNode)] as [(AVAudioNode, AVAudioNode)] {
            try connect(engine, a, b)
        }
        try engine.start(); try startPlayer(player)
    }
    func render(_ chunks: Int, each: (Int) throws -> Void) throws {
        for c in 0..<chunks {
            try each(c)
            guard try engine.renderOffline(quantum, to: out) == .success else { break }
            samples += Array(UnsafeBufferPointer(start: out.floatChannelData![0], count: Int(out.frameLength)))
        }
        engine.stop()
    }
    /// The player's own sample position now (frames of the scheduled buffer played since it started at 0).
    var position: AVAudioFramePosition {
        guard let nt = player.lastRenderTime, let pt = player.playerTime(forNodeTime: nt) else { return 0 }
        return pt.sampleTime
    }
}

/// Predictor residual: the FIR whose zeros are the signal's tones (order 2 per tone) annihilates any clean mix of them.
func residualMax(_ x: [Float], tones: [Double], from: Int) -> Float {
    var h: [Double] = [1]
    for f in tones {                                   // multiply by (1 − 2cos ω z⁻¹ + z⁻²)
        let c = -2 * cos(2 * .pi * f / sr); var n = [Double](repeating: 0, count: h.count + 2)
        for (i, v) in h.enumerated() { n[i] += v; n[i + 1] += v * c; n[i + 2] += v }
        h = n
    }
    var m: Float = 0
    for i in max(h.count, from)..<x.count {
        var r = 0.0; for (k, v) in h.enumerated() { r += v * Double(x[i - k]) }
        m = max(m, Float(abs(r)))
    }
    return m
}
/// The graph's latency L in frames (the limiter looks ahead): out[n] ≈ G·src[n − L], found by correlation before the event.
func latency(_ out: [Float], _ src: UnsafePointer<Float>) -> Int {
    let a = Int(sr * 0.1), len = Int(sr * 0.15)
    var best = 0, bestC = -Double.infinity
    for L in 0...1024 {
        var c = 0.0, e1 = 0.0, e2 = 0.0
        for i in a..<(a + len) { let o = Double(out[i]), s = Double(src[i - L]); c += o * s; e1 += o * o; e2 += s * s }
        let r = c / max(1e-12, sqrt(e1 * e2))
        if r > bestC { bestC = r; best = L }
    }
    return best
}
/// The older d2 detector (kept one release to compare with earlier numbers).
func d2Max(_ x: [Float], from: Int) -> Float {
    var m: Float = 0
    for i in max(2, from)..<x.count { m = max(m, abs(x[i] - 2 * x[i - 1] + x[i - 2])) }
    return m
}
/// Gain trajectory for a non-tonal signal: two measures, both against the latency-aligned source, G-normalised.
/// (a) the AC-9-equivalent: the largest per-sample change of g[n] = out[n]/(G·src[n]) between **adjacent** samples
///     where |src| ≥ 0.2·amp (no bridging, no division): a step of Δg on a full-scale signal is a Δg discontinuity, so
///     the limit is 1/1000 per sample (−60 dB). A smooth fade reads its slope (the mixer's ≈ 27 ms fall: ≈ 1/1250).
/// (b) a guard for what (a) cannot see (a step that lands where |src| is small, game-qc-ios): the least-squares gain
///     over 1 ms windows, Σ out·src / Σ src², must not change by ≥ 0.25 between consecutive windows. A hard stop
///     always trips it (≥ 0.5 wherever it lands); a smooth fade changes it by ≤ 0.07 (its energy weighting makes
///     a smooth ramp read unevenly at 1 ms, so (b) is a guard, not a measure).
/// Returns (a), or 1.0 when (b) trips.
let gainWindow = 48
func gainStepMax(_ out: [Float], src: UnsafePointer<Float>, srcOffset: [Int], from: Int) -> Float {
    var num = 0.0, den = 0.0
    for i in from..<min(out.count, from + 4800) where srcOffset[i] >= 0 {
        let s = Double(src[srcOffset[i]]); num += Double(out[i]) * s; den += s * s
    }
    let G = den > 0 ? num / den : 1
    // (a)
    var a: Float = 0
    for i in (from + 1)..<out.count {
        guard srcOffset[i] >= 0, srcOffset[i - 1] >= 0 else { continue }
        let s0 = src[srcOffset[i - 1]], s1 = src[srcOffset[i]]
        guard abs(s0) >= 0.2 * amp, abs(s1) >= 0.2 * amp else { continue }
        a = max(a, abs(Float(Double(out[i]) / (G * Double(s1)) - Double(out[i - 1]) / (G * Double(s0)))))
    }
    // (b)
    var prev: Double? = nil, w = from
    while w + gainWindow <= out.count {
        var n = 0.0, d = 0.0, ok = true
        for i in w..<(w + gainWindow) {
            guard srcOffset[i] >= 0 else { ok = false; break }
            let s = Double(src[srcOffset[i]]); n += Double(out[i]) * s; d += s * s
        }
        if ok, d > 1e-6 {
            let g = n / (G * d)
            if let p = prev, abs(g - p) >= 0.25 { return 1.0 }
            prev = g
        } else if !ok { prev = nil }
        w += gainWindow
    }
    return a
}

enum Case: String, CaseIterable {
    case floor = "no cut (detector floor)"
    case hardStop = "hard stop()"
    case interrupts = ".interrupts on a busy player"
    case naivePause = "pause() / play at once"
    case cutD5 = "D5 cut: gate 0, settle 40 ms, stop"
    case muteD5 = "D5 mute: main mixer 0"
    case freezeD7 = "D7 freeze: position, gate 0, settle, stop; resume from position, gate 1"
}

struct Outcome { var worst: Float = -200; var best: Float = 200; var d2worst: Float = -200; var lost: [Int] = []; var lostL: [Int] = []; var latency = 0 }
var table: [String: Outcome] = [:]

// Probe (H1_PROBE3=1): D5 mute / D5 cut on 100 Hz, 8 phases × 6 repeats: worst residual, where, L, and the output
// envelope (max |x| per 1 ms) around it, to see whether a volume change was ever applied as a step.
if ProcessInfo.processInfo.environment["H1_PROBE3"] != nil {
    for mode in ["mute", "cut"] {
        for rep in 0..<6 {
            var line = "\(mode) rep \(rep):"
            for k in 0..<8 {
                let rig = try Rig(); let src = signal(.tone100, phase: 2 * .pi * Double(k) / 8, seconds: 2)
                rig.player.scheduleBuffer(src, at: nil, options: [])
                try rig.render(120) { c in
                    if c == cutChunk { if mode == "mute" { rig.engine.mainMixerNode.outputVolume = 0 } else { rig.gate.outputVolume = 0 } }
                    if mode == "cut", c == cutChunk + settleChunks { rig.player.stop() }
                }
                let x = rig.samples, L = markerLatency(x)
                let cc = Float(2 * cos(2 * .pi * 100 / sr)); var m: Float = 0, at = 0
                for i in max(2, Int(sr * 0.05))..<x.count { let r = abs(x[i] - cc * x[i - 1] + x[i - 2]); if r > m { m = r; at = i } }
                line += String(format: " k%d[%.1f@%d L%d]", k, dbfs(m), at, L)
                if dbfs(m) > -60 {
                    var env = ""
                    for w in stride(from: max(0, at - 480), to: min(x.count, at + 480), by: 48) { env += String(format: "%.2f ", x[w..<min(x.count, w + 48)].map(abs).max() ?? 0) }
                    print("  FAIL detail \(mode) k\(k): env around \(at): \(env)")
                }
            }
            print(line)
        }
    }
    exit(0)
}
// Probe (H1_PROBE2=1): voice-like hard stop at 8 phases, 3 repeats: latency, where the output goes silent, metric
if ProcessInfo.processInfo.environment["H1_PROBE2"] != nil {
    for rep in 0..<3 {
        var line = "rep \(rep):"
        for k in 0..<8 {
            let rig = try Rig(); let src = signal(.voice, phase: 2 * .pi * Double(k) / 8, seconds: 2)
            rig.player.scheduleBuffer(src, at: nil, options: [])
            try rig.render(120) { c in if c == cutChunk { rig.player.stop() } }
            let x = rig.samples, L = markerLatency(x)
            let lastLoud = x.lastIndex { abs($0) > 1e-4 } ?? -1
            let m = gainStepMax(x, src: src.floatChannelData![0], srcOffset: (0..<x.count).map { $0 - L }, from: Int(sr * 0.05))
            line += String(format: " k%d[L%d silentAt %d m %.1f]", k, L, lastLoud + 1, dbfs(m))
        }
        print(line)
    }
    exit(0)
}
// Probe (H1_PROBE=1): print the 1 ms least-squares gain around a D5 cut on the chord, phase 0, and exit.
if ProcessInfo.processInfo.environment["H1_PROBE"] != nil {
    let rig = try Rig(); let src = signal(.chord, phase: 0, seconds: 2)
    rig.player.scheduleBuffer(src, at: nil, options: [])
    try rig.render(120) { c in if c == cutChunk { rig.gate.outputVolume = 0 } }
    let L = latency(rig.samples, src.floatChannelData![0])
    var line = "L=\(L) gain per 1 ms from 296 ms:"
    var prev: Double? = nil
    for w in stride(from: Int(sr * 0.296), to: Int(sr * 0.336), by: gainWindow) {
        var n = 0.0, d = 0.0
        for i in w..<(w + gainWindow) { let s = Double(src.floatChannelData![0][i - L]); n += Double(rig.samples[i]) * s; d += s * s }
        let g = n / d
        line += String(format: " %.3f", g) + (prev.map { String(format: "(%+.3f)", g - $0) } ?? "")
        prev = g
    }
    print(line); exit(0)
}
let gatedCases: Set<Case> = [.floor, .cutD5, .muteD5, .freezeD7]

for sg in Signal.allCases {
    for k in 0..<8 {
        let phase = 2 * .pi * Double(k) / 8
        for cs in Case.allCases {
            let rig = try Rig()
            let src = signal(sg, phase: phase, seconds: 2)
            rig.player.scheduleBuffer(src, at: nil, options: [])
            var frozenAt: AVAudioFramePosition = -1, resumedOutIndex = -1, stoppedOutIndex = -1
            try rig.render(cs == .freezeD7 ? resumeChunk + 40 : 120) { c in
                switch cs {
                case .floor: break
                case .hardStop: if c == cutChunk { rig.player.stop() }
                case .interrupts:
                    if c == cutChunk {
                        let z = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: 4800)!; z.frameLength = 4800
                        for i in 0..<4800 { z.floatChannelData![0][i] = 0 }
                        rig.player.scheduleBuffer(z, at: nil, options: .interrupts)
                    }
                case .naivePause:
                    if c == cutChunk { rig.player.pause() }
                    if c == cutChunk + 20 { try startPlayer(rig.player) }
                case .cutD5:
                    if c == cutChunk { rig.gate.outputVolume = 0 }
                    if c == cutChunk + settleChunks { rig.player.stop(); try startPlayer(rig.player); rig.gate.outputVolume = 1 }
                case .muteD5:
                    if c == cutChunk { rig.engine.mainMixerNode.outputVolume = 0 }
                case .freezeD7:
                    // the position is taken at the freeze call, before the gate falls (game-dev-android): the faded
                    // part is heard again after the resume
                    if c == cutChunk { frozenAt = rig.position; rig.gate.outputVolume = 0 }
                    if c == cutChunk + settleChunks { rig.player.stop(); stoppedOutIndex = rig.samples.count }
                    if c == resumeChunk {
                        // the rest of the buffer from the captured frame (on the audio queue in the app, never on a press)
                        // ADR-0010 D7: resume half of cut_settle_s before the captured frame (the capture can run up to
                        // 15 ms ahead of the frame actually playing, measured below), so nothing is ever skipped
                        let start = max(0, Int(frozenAt) - rewindFrames), rest = Int(src.frameLength) - start
                        let b = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: AVAudioFrameCount(rest))!
                        b.frameLength = AVAudioFrameCount(rest)
                        b.floatChannelData![0].update(from: src.floatChannelData![0] + start, count: rest)
                        try startPlayer(rig.player)
                        rig.player.scheduleBuffer(b, at: nil, options: [])
                        rig.gate.outputVolume = 1
                        resumedOutIndex = rig.samples.count
                    }
                }
            }
            let x = rig.samples
            // which source frame each output frame carries (−1 while stopped)
            var o = table["\(cs.rawValue)|\(sg.rawValue)"] ?? Outcome()
            let L = markerLatency(x)
            // the metrics start after this rendering's signal onset (the player's start can be delayed by several quanta:
            // one rendering started 80 ms late, putting the marker inside a fixed 50 ms window)
            let from = max(Int(sr * 0.05), L + markerEnd + 48)
            var resumeLag = 0
            if cs == .freezeD7, resumedOutIndex > 0 {
                // continuity: which source frame does the resumed output line up with, against the frozen frame
                let probe = resumedOutIndex + Int(sr * 0.06), len = 480
                var num: Float = 0, den: Float = 0
                for i in Int(sr * 0.1)..<Int(sr * 0.25) { let s0 = src.floatChannelData![0][i - L]; num += x[i] * s0; den += s0 * s0 }
                let G0 = den > 0 ? num / den : 1
                var bestLag = 0, bestErr = Float.greatestFiniteMagnitude
                for lag in -1200...1200 {
                    var err: Float = 0
                    for i in 0..<len {
                        let si = max(0, Int(frozenAt) - rewindFrames) + (probe - resumedOutIndex - L) + i + lag
                        guard si >= 0, si < Int(src.frameLength), probe + i < x.count else { err = .greatestFiniteMagnitude; break }
                        let d = x[probe + i] - G0 * src.floatChannelData![0][si]; err += d * d
                    }
                    if err < bestErr { bestErr = err; bestLag = lag }
                }
                resumeLag = bestLag                          // used only to map the resumed output for the gain metric
                // Continuity, in content: the frame captured at the freeze call against the frame actually playing
                // then. The player's start offset in this rendering is L − limiterDelay (it moves by one quantum
                // between renderings), so the frame playing at render frame cutChunk·240 is cutChunk·240 − (L − 96).
                let trueFrame = cutChunk * Int(quantum) - (L - limiterDelay)
                o.lost.append(max(0, Int(frozenAt) - rewindFrames) - trueFrame); o.lostL.append(L - limiterDelay)
            }
            var map = (0..<x.count).map { $0 - L }
            if cs == .freezeD7, resumedOutIndex > 0 {
                for i in stoppedOutIndex..<min(x.count, resumedOutIndex + L) { map[i] = -1 }
                // Non-tonal signals: the resumed segment is not mapped (aligning content across a player restart is not
                // reliable offline; the fade-in is proven on the single tones, whose residual needs no alignment, and
                // P-7 / M-14 listen to it on the device). The metric covers the freeze's fade-out.
                for i in stoppedOutIndex..<x.count { map[i] = -1 }
            }
            o.latency = L
            map = map.map { $0 < Int(src.frameLength) ? $0 : -1 }
            let metric: Float
            if let tones = sg.tones { metric = dbfs(residualMax(x, tones: tones, from: from)) }
            else { metric = dbfs(gainStepMax(x, src: src.floatChannelData![0], srcOffset: map, from: from)) }
            o.worst = max(o.worst, metric); o.best = min(o.best, metric)
            if sg == .tone100 { o.d2worst = max(o.d2worst, dbfs(d2Max(x, from: from))) }
            table["\(cs.rawValue)|\(sg.rawValue)"] = o
        }
    }
}

print("H-1 offline cut check (8 start phases per signal; render quantum 5 ms; cut_settle_s 40 ms)")
print("single tones: predictor residual, threshold -60 dBFS; chord and voice-like line:")
print("(a) per-sample gain step between adjacent defined samples, limit 1/1000 (-60 dB, AC-9-equivalent; the 27 ms fall reads ~-62); (b) guard: no 1 ms LS-gain jump >= 0.25 (reads 0 dB if tripped)")
for cs in Case.allCases {
    for sg in Signal.allCases {
        let o = table["\(cs.rawValue)|\(sg.rawValue)"]!
        let limit: Float = sg.tones == nil ? dbfs(1.0 / 1000) : -60
        let verdict = gatedCases.contains(cs) ? (o.worst <= limit ? "PASS (every phase)" : "FAIL") :
            (o.best > limit ? "FAIL (every phase)" : "FAIL at some phases")
        var line = String(format: "%-60@ %-18@ worst %6.1f  best %6.1f  %@", cs.rawValue as NSString, sg.rawValue as NSString, o.worst, o.best, verdict)
        if sg == .tone100 { line += String(format: "  [d2 worst %.1f]", o.d2worst) }
        line += "  [L \(o.latency)]"
        if !o.lost.isEmpty { line += "  resume vs freeze frame (negative = heard again) [player start delay]: " + zip(o.lost, o.lostL).map { "\($0)[\($1)]" }.joined(separator: ",") }
        print(line)
    }
}

// Detector self-check (game-qc-ios): a hard stop must be detected at every phase on every signal.
var selfCheckOK = true
for sg in Signal.allCases {
    let o = table["\(Case.hardStop.rawValue)|\(sg.rawValue)"]!
    let limit: Float = sg.tones == nil ? dbfs(1.0 / 1000) : -60
    if o.best <= limit { selfCheckOK = false; print("SELF-CHECK FAILED: a hard stop on \(sg.rawValue) went undetected at some phase (best \(o.best))") }
}
print(selfCheckOK ? "SELF-CHECK OK: a hard stop is detected at every phase on every signal" : "SELF-CHECK FAILED")
if !selfCheckOK { exit(1) }
