// PROTOTYPE - NOT FOR PRODUCTION (TASK-128, follow-up to TASK-127 P-7: "a pop on every button but Tone freeze")
// Offline (manual rendering) replay of each Audio-screen button of DeviceSpike, with the spike's own fixture buffers
// (the same formulas and 10 ms edge fades as AudioSpike.primeBuffers), bus volumes and timings, on the candidate graph:
//   player → gate mixer → bus mixer → submix → Apple PeakLimiter → main mixer.
// Unlike tools/offline-cut-check.swift (one event, metrics from 50 ms), this measures the **whole** sound: its start,
// the event (cut / mute / freeze), the resume, and its natural end, per phase, so a pop at a sound's start is seen.
// Metrics (threshold −60 dBFS, Audio AC-9):
//   tones (100 Hz, 1 kHz): the sine-predictor residual r[n] = x[n] − 2cos ω x[n−1] + x[n−2] (0 for a clean sine);
//   other sounds: the excess second difference over the same sound rendered with no event,
//   max(0, |d2 out| − |d2 ref|) per 5 ms bin (a smooth fade only lowers |d2|; a step raises it).
// Events land on 5 ms render boundaries (the iPad's IO period), as the spike's queue calls do.
// Run: swift tools/offline-button-check.swift            (the spike as built)
//      swift tools/offline-button-check.swift --resume-fade  (with a 10 ms fade-in on the resumed remainder)
import AVFoundation

let sr = 48_000.0
let fmt = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 1)!
let quantum: AVAudioFrameCount = 240                    // 5 ms
let settle = 0.04                                       // cut_settle_s
let rewindS = max(0.020, 5.33 / 1000 + 0.005)           // D7 rewind with the iPad's logged IO period (5.33 ms)
let resumeFade = CommandLine.arguments.contains("--resume-fade")

// MARK: the spike's fixtures (AudioSpike.primeBuffers), at 48 kHz
func make(_ dur: Double, _ f: (Double) -> Double) -> [Float] {
    let n = Int(dur * sr)
    return (0..<n).map { i in let t = Double(i) / sr; let env = min(1, t / 0.01) * min(1, (dur - t) / 0.01); return Float(f(t) * env) }
}
var seed: UInt32 = 1
let notes = [523.25, 659.25, 783.99, 1046.5, 783.99, 659.25, 523.25, 659.25]
let fixtures: [String: [Float]] = [
    "chime": make(0.4) { t in 0.5 * exp(-t * 7) * (sin(2 * .pi * 1568 * t) + 0.6 * sin(2 * .pi * 2093 * t)) },
    "voice": make(0.9) { t in 0.6 * sin(2 * .pi * (220 + 120 * t) * t + 0.3 * sin(2 * .pi * 5 * t)) },
    "cast": make(0.9) { t in
        seed = seed &* 1664525 &+ 1013904223
        let noise = Double(Int32(bitPattern: seed)) / Double(Int32.max)
        return 0.5 * (0.6 * sin(2 * .pi * 70 * t) + 0.4 * noise * 0.3) * exp(-t * 1.5)
    },
    "music": make(2.0) { t in let k = min(notes.count - 1, Int(t / 0.25)); return 0.4 * sin(2 * .pi * notes[k] * t) * exp(-(t - Double(k) * 0.25) * 4) },
    "tone100": make(2.0) { t in 0.891 * sin(2 * .pi * 100 * t) },
    "tone1k": make(2.0) { t in 0.891 * sin(2 * .pi * 1000 * t) },
    "chirp": make(2.0) { t in 0.891 * sin(2 * .pi * (200 * t + 450 * t * t)) },
]
let busVolume: [String: Float] = ["voice": 1, "cast": 0.63, "ui": 0.32, "music": 0.40]

func pcm(_ s: ArraySlice<Float>) -> AVAudioPCMBuffer {
    let b = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: AVAudioFrameCount(s.count))!
    b.frameLength = AVAudioFrameCount(s.count)
    s.withUnsafeBufferPointer { b.floatChannelData![0].update(from: $0.baseAddress!, count: s.count) }
    return b
}
func startPlayer(_ p: AVAudioPlayerNode) throws { if #available(macOS 27, *) { try p.playAudio() } else { p.play() } }
func connect(_ e: AVAudioEngine, _ a: AVAudioNode, _ b: AVAudioNode) throws {
    if #available(macOS 27, *) { try e.connectNode(a, to: b, format: fmt) } else { e.connect(a, to: b, format: fmt) }
}
func dbfs(_ x: Float) -> Float { x <= 0 ? -200 : 20 * log10(x) }

// MARK: one button
enum Event { case cut, mute, freezeResume(freezeAt: Double, resumeAt: Double), none }
struct Button { let name: String; let sound: String; let bus: String; let event: Event; let eventAt: Double; let seconds: Double }

/// Renders the button's sequence; `withEvent: false` renders the same sound with no event (the reference).
func render(_ b: Button, withEvent: Bool) throws -> (out: [Float], marks: [(String, Int)]) {
    let engine = AVAudioEngine(), player = AVAudioPlayerNode(), gate = AVAudioMixerNode(), bus = AVAudioMixerNode()
    let submix = AVAudioMixerNode()
    let limiter = AVAudioUnitEffect(audioComponentDescription: AudioComponentDescription(
        componentType: kAudioUnitType_Effect, componentSubType: kAudioUnitSubType_PeakLimiter,
        componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0))
    try engine.enableManualRenderingMode(.offline, format: fmt, maximumFrameCount: 4096)
    let buf = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: 4096)!
    for n in [player, gate, bus, submix, limiter] as [AVAudioNode] { engine.attach(n) }
    for (x, y) in [(player, gate), (gate, bus), (bus, submix), (submix, limiter), (limiter, engine.mainMixerNode)] as [(AVAudioNode, AVAudioNode)] {
        try connect(engine, x, y)
    }
    bus.outputVolume = busVolume[b.bus] ?? 1
    try engine.start(); try startPlayer(player)
    let src = fixtures[b.sound]!
    var out: [Float] = [], marks: [(String, Int)] = []
    let chunkOf = { (t: Double) in Int((t / (Double(quantum) / sr)).rounded()) }
    let total = chunkOf(b.seconds)
    var startSample: AVAudioFramePosition = 0, frozenAt: AVAudioFramePosition = 0
    func position() -> AVAudioFramePosition {
        guard let nt = player.lastRenderTime, let pt = player.playerTime(forNodeTime: nt) else { return 0 }
        return pt.sampleTime
    }
    for c in 0..<total {
        let here = out.count
        if c == chunkOf(0.02) {                         // the press: schedule on the running, silent player (spike)
            startSample = position()
            player.scheduleBuffer(pcm(src[...]), at: nil, options: .interrupts)
            marks.append(("start", here))
        }
        if withEvent {
            switch b.event {
            case .cut:
                if c == chunkOf(0.02 + b.eventAt) { gate.outputVolume = 0; marks.append(("cut", here)) }
                if c == chunkOf(0.02 + b.eventAt + settle) { player.stop(); try startPlayer(player); gate.outputVolume = 1 }
            case .mute:                                  // spike setMuted: 30 steps over ~30 ms (one per 1 ms; here per quantum)
                let m0 = chunkOf(0.02 + b.eventAt), m1 = chunkOf(0.02 + b.eventAt + 0.5)
                if c == m0 { marks.append(("mute", here)) }
                if c >= m0, c <= m0 + 6 { engine.mainMixerNode.outputVolume = 1 - Float(c - m0) / 6 }
                if c == m1 { marks.append(("unmute", here)) }
                if c >= m1, c <= m1 + 6 { engine.mainMixerNode.outputVolume = Float(c - m1) / 6 }
            case let .freezeResume(f, r):
                if c == chunkOf(0.02 + f) { frozenAt = max(0, position() - startSample); gate.outputVolume = 0; marks.append(("freeze", here)) }
                if c == chunkOf(0.02 + f + settle) { player.stop() }
                if c == chunkOf(0.02 + r) {
                    let from = max(0, Int(frozenAt) - Int(rewindS * sr))
                    var rest = Array(src[from...])
                    if resumeFade { for i in 0..<min(480, rest.count) { rest[i] *= Float(i) / 480 } }
                    try startPlayer(player)
                    player.scheduleBuffer(pcm(rest[...]), at: nil, options: .interrupts)
                    gate.outputVolume = 1
                    marks.append(("resume", here)); marks.append(("from", from))
                }
            case .none: break
            }
        }
        guard try engine.renderOffline(quantum, to: buf) == .success else { break }
        out += Array(UnsafeBufferPointer(start: buf.floatChannelData![0], count: Int(buf.frameLength)))
    }
    engine.stop()
    return (out, marks)
}

/// Per-sample click metric for the button's sound.
func metric(_ b: Button, _ out: [Float], _ ref: [Float], shift: (Int) -> Int) -> [Float] {
    var m = [Float](repeating: 0, count: out.count)
    let tone: Double? = b.sound == "tone100" ? 100 : b.sound == "tone1k" ? 1000 : nil
    if let f = tone {
        let c = Float(2 * cos(2 * .pi * f / sr))
        for i in 2..<out.count { m[i] = abs(out[i] - c * out[i - 1] + out[i - 2]) }
    } else {
        let bin = Int(quantum)
        for s in stride(from: 2, to: out.count, by: bin) {
            var o: Float = 0, r: Float = 0
            for i in s..<min(out.count, s + bin) {
                o = max(o, abs(out[i] - 2 * out[i - 1] + out[i - 2]))
                let j = i - shift(i)       // the reference, aligned on its own first output sample (and on the resumed frame)
                if j >= 2, j < ref.count { r = max(r, abs(ref[j] - 2 * ref[j - 1] + ref[j - 2])) }
            }
            m[s] = max(0, o - r)
        }
    }
    return m
}

let buttons: [Button] = [
    Button(name: "Tone cut voice", sound: "tone100", bus: "voice", event: .cut, eventAt: 0.5, seconds: 2.3),
    Button(name: "Tone cut cast", sound: "tone100", bus: "cast", event: .cut, eventAt: 0.5, seconds: 2.3),
    Button(name: "Tone cut music", sound: "tone100", bus: "music", event: .cut, eventAt: 0.5, seconds: 2.3),
    Button(name: "Tone mute", sound: "tone100", bus: "voice", event: .mute, eventAt: 0.5, seconds: 2.3),
    Button(name: "Tone freeze", sound: "tone100", bus: "music", event: .freezeResume(freezeAt: 0.5, resumeAt: 0.8), eventAt: 0.5, seconds: 2.6),
    Button(name: "Freeze continuity", sound: "chirp", bus: "voice", event: .freezeResume(freezeAt: 0.8, resumeAt: 1.1), eventAt: 0.8, seconds: 2.6),
    Button(name: "1 kHz cut voice", sound: "tone1k", bus: "voice", event: .cut, eventAt: 0.5, seconds: 2.3),
    Button(name: "1 kHz freeze music", sound: "tone1k", bus: "music", event: .freezeResume(freezeAt: 0.5, resumeAt: 0.8), eventAt: 0.5, seconds: 2.6),
    Button(name: "Play voice (to end)", sound: "voice", bus: "voice", event: .none, eventAt: 0, seconds: 1.2),
    Button(name: "Play voice + Cut", sound: "voice", bus: "voice", event: .cut, eventAt: 0.5, seconds: 1.2),
    Button(name: "Play cast + Cut", sound: "cast", bus: "cast", event: .cut, eventAt: 0.5, seconds: 1.2),
    Button(name: "Play music (to end)", sound: "music", bus: "music", event: .none, eventAt: 0, seconds: 2.3),
    Button(name: "Play music + Cut", sound: "music", bus: "music", event: .cut, eventAt: 1.0, seconds: 2.3),
    Button(name: "Play ui (chime)", sound: "chime", bus: "ui", event: .none, eventAt: 0, seconds: 0.7),
]

print("TASK-128 offline button check (spike fixtures, bus volumes, 5 ms quanta, cut_settle_s 40 ms, rewind \(Int(rewindS * 1000)) ms)\(resumeFade ? ", resume remainder faded in over 10 ms" : "")")
print("metric: tones = sine-predictor residual; other sounds = excess |d2| over the no-event render, per 5 ms bin; threshold -60 dBFS")
print("phase windows: start = first 30 ms; each event = -10..+90 ms; end = the sound's last 20 ms to +60 ms; body = the rest")
var anyFail = false
for b in buttons {
    let (out, marks) = try render(b, withEvent: true)
    let (ref, refMarks) = try render(b, withEvent: false)
    // the output latency (limiter look-ahead, player start): first sample above 1e-6 after the start mark
    let start = marks.first { $0.0 == "start" }!.1, refStart = refMarks.first { $0.0 == "start" }!.1
    let lat = (out[start...].firstIndex { abs($0) > 1e-6 } ?? start) - start
    let refLat = (ref[refStart...].firstIndex { abs($0) > 1e-6 } ?? refStart) - refStart
    let s0 = (start + lat) - (refStart + refLat)
    let res = marks.first { $0.0 == "resume" }?.1, from = marks.first { $0.0 == "from" }?.1
    // after a resume the output plays src[from...] from the resume mark: out[i] ↔ ref[i − (res + lat) + from + refStart + refLat]
    let m = metric(b, out, ref) { i in
        if let res, let from, i >= res + lat { return (res + lat) - from - (refStart + refLat) }
        return s0
    }
    var phase = [String: Float]()
    func put(_ k: String, _ a: Int, _ z: Int) {
        let lo = max(0, a + lat), hi = min(m.count, z + lat); guard lo < hi else { return }
        phase[k] = max(phase[k] ?? 0, m[lo..<hi].max() ?? 0)
    }
    let ten = Int(0.01 * sr), w = Int(0.09 * sr)
    put("start", start, start + Int(0.03 * sr))
    var covered = [(start, start + Int(0.03 * sr))]
    for (k, at) in marks where k != "start" && k != "from" { put(k, at - ten, at + w); covered.append((at - ten, at + w)) }
    // the natural end of the (last scheduled part of the) sound, when no cut ended it first
    if case .cut = b.event {} else {
        let len = fixtures[b.sound]!.count
        var endAt = start + len
        if let res = marks.first(where: { $0.0 == "resume" }), let from = marks.first(where: { $0.0 == "from" }) {
            endAt = res.1 + len - from.1
        }
        put("end", endAt - Int(0.02 * sr), endAt + Int(0.06 * sr)); covered.append((endAt - Int(0.02 * sr), endAt + Int(0.06 * sr)))
    }
    var body: Float = 0
    for i in 0..<m.count where !covered.contains(where: { i - lat >= $0.0 && i - lat < $0.1 }) { body = max(body, m[i]) }
    phase["body"] = body
    let order = ["start", "cut", "mute", "unmute", "freeze", "resume", "end", "body"]
    let worst = phase.values.max() ?? 0
    if dbfs(worst) > -60 { anyFail = true }
    let cells = order.compactMap { k in phase[k].map { String(format: "%@ %.1f", k, dbfs($0)) } }.joined(separator: " | ")
    print(String(format: "%-22@ %@  → %@", b.name as NSString, cells, dbfs(worst) <= -60 ? "PASS" : "FAIL"))
}
print(anyFail ? "RESULT: at least one phase above -60 dBFS (see FAIL rows)" : "RESULT: every phase of every button at or below -60 dBFS")
