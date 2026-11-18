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
func signal(_ sg: Signal, phase: Double, seconds: Double) -> AVAudioPCMBuffer {
    let n = AVAudioFrameCount(sr * seconds)
    let b = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: n)!; b.frameLength = n
    for i in 0..<Int(n) { b.floatChannelData![0][i] = sg.sample(i, phase: phase) }
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
    for L in 0...2048 {
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
/// Gain trajectory for a non-tonal signal: g[n] = out[n] / (G·src[n]) where |src| is large enough; returns the largest
/// per-sample change of g. A 30 ms linear fade changes g by 1/1440 per sample; the gate is "no faster than a 15 ms
/// fade" (≤ 1/720). A hard stop gives ≈ 1.
func gainStepMax(_ out: [Float], src: UnsafePointer<Float>, srcOffset: [Int], from: Int) -> Float {
    // G from the steady part before the event
    var num = 0.0, den = 0.0
    for i in from..<min(out.count, from + 4800) { let s = Double(src[srcOffset[i]]); num += Double(out[i]) * s; den += s * s }
    let G = den > 0 ? num / den : 1
    var m: Float = 0, prev: (g: Float, i: Int)? = nil
    for i in from..<out.count {
        guard srcOffset[i] >= 0 else { prev = nil; continue }          // the player is stopped: no source frame
        let s = src[srcOffset[i]]
        guard abs(s) > 0.2 * amp else { continue }                     // too quiet to divide by; bridge the gap
        let g = Float(Double(out[i]) / (G * Double(s)))
        if let p = prev, i - p.i <= 96 { m = max(m, abs(g - p.g) / Float(i - p.i)) }   // rate per sample, gaps ≤ 2 ms
        prev = (g, i)
    }
    return m
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

struct Outcome { var worst: Float = -200; var best: Float = 200; var d2worst: Float = -200; var lost: [Int] = []; var latency = 0 }
var table: [String: Outcome] = [:]
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
                        let start = Int(frozenAt), rest = Int(src.frameLength) - start
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
            let from = Int(sr * 0.05)
            let x = rig.samples
            // which source frame each output frame carries (−1 while stopped)
            var o = table["\(cs.rawValue)|\(sg.rawValue)"] ?? Outcome()
            let L = latency(x, src.floatChannelData![0])
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
                        let si = Int(frozenAt) + (probe - resumedOutIndex - L) + i + lag
                        guard si >= 0, si < Int(src.frameLength), probe + i < x.count else { err = .greatestFiniteMagnitude; break }
                        let d = x[probe + i] - G0 * src.floatChannelData![0][si]; err += d * d
                    }
                    if err < bestErr { bestErr = err; bestLag = lag }
                }
                o.lost.append(bestLag); resumeLag = bestLag
            }
            var map = (0..<x.count).map { $0 - L }
            if cs == .freezeD7, resumedOutIndex > 0 {
                for i in stoppedOutIndex..<min(x.count, resumedOutIndex + L) { map[i] = -1 }
                for i in (resumedOutIndex + L)..<x.count { map[i] = Int(frozenAt) + (i - resumedOutIndex - L) + resumeLag }
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
print("single tones: predictor residual, threshold -60 dBFS; chord and voice-like line: largest per-sample gain step,")
print("threshold 1/720 (-57.1 dB: no faster than a 15 ms linear fade; a 30 ms fade is -63.2 dB, a hard stop ~0 dB)")
for cs in Case.allCases {
    for sg in Signal.allCases {
        let o = table["\(cs.rawValue)|\(sg.rawValue)"]!
        let limit: Float = sg.tones == nil ? dbfs(1.0 / 720) : -60
        let verdict = gatedCases.contains(cs) ? (o.worst <= limit ? "PASS (every phase)" : "FAIL") :
            (o.best > limit ? "FAIL (every phase)" : "FAIL at some phases")
        var line = String(format: "%-60@ %-18@ worst %6.1f  best %6.1f  %@", cs.rawValue as NSString, sg.rawValue as NSString, o.worst, o.best, verdict)
        if sg == .tone100 { line += String(format: "  [d2 worst %.1f]", o.d2worst) }
        line += "  [L \(o.latency)]"
        if !o.lost.isEmpty { line += "  resumed at freeze point +frames (negative = heard again): \(o.lost.map(String.init).joined(separator: ","))" }
        print(line)
    }
}
