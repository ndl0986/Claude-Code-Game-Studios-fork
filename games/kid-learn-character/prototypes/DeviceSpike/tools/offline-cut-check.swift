// PROTOTYPE - NOT FOR PRODUCTION (TASK-087, ADR-0010 headless pre-check for Audio AC-9)
// Offline (manual rendering) check of cut mechanisms on the candidate graph: player → per-player mixer → submix →
// Apple PeakLimiter → main mixer. A 100 Hz tone at −1 dBFS is cut mid-tone; the detector is the largest second
// difference |x[n] − 2x[n−1] + x[n−2]| of the output, which for the clean tone is ≤ A·(2πf/sr)² ≈ −76 dBFS, so any
// excess is the cut's discontinuity. Threshold: −60 dBFS (Audio AC-9). Run: swift tools/offline-cut-check.swift
import AVFoundation

let sr = 48_000.0, f = 100.0, amp: Float = 0.891   // −1 dBFS
let fmt = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 1)!
/// `play()` is deprecated from the 27 SDKs; `playAudio()` (throws) is 27+ only, so deployment-26 code branches.
func startPlayer(_ p: AVAudioPlayerNode) throws {
    if #available(macOS 27, iOS 27, *) { try p.playAudio() } else { p.play() }
}
func dbfs(_ x: Float) -> String { x <= 0 ? "-inf" : String(format: "%.1f", 20 * log10(x)) }

struct Result { let name: String; let maxD2: Float; let tail: Float; var at: Double = 0; var silentAfter: Double = -1 }

func run(_ name: String, quantum: AVAudioFrameCount, cut: (AVAudioPlayerNode, AVAudioMixerNode, Int) -> Bool) throws -> Result {
    let engine = AVAudioEngine()
    try engine.enableManualRenderingMode(.offline, format: fmt, maximumFrameCount: 4096)
    let player = AVAudioPlayerNode(), pmix = AVAudioMixerNode(), submix = AVAudioMixerNode()
    let limiter = AVAudioUnitEffect(audioComponentDescription: AudioComponentDescription(
        componentType: kAudioUnitType_Effect, componentSubType: kAudioUnitSubType_PeakLimiter,
        componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0))
    [player, pmix, submix, limiter].forEach { engine.attach($0) }
    engine.connect(player, to: pmix, format: fmt); engine.connect(pmix, to: submix, format: fmt)
    engine.connect(submix, to: limiter, format: fmt); engine.connect(limiter, to: engine.mainMixerNode, format: fmt)
    let n = AVAudioFrameCount(sr)                         // 1 s tone, an exact number of periods
    let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: n)!; buf.frameLength = n
    for i in 0..<Int(n) { buf.floatChannelData![0][i] = amp * Float(sin(2 * .pi * f * Double(i) / sr)) }
    try engine.start(); try startPlayer(player)
    player.scheduleBuffer(buf, at: nil, options: .loops)
    let out = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: 4096)!
    var all: [Float] = []
    var chunk = 0, done = false
    while all.count < Int(sr * 0.6) {
        if !done { done = cut(player, pmix, chunk) }
        let st = try engine.renderOffline(quantum, to: out)
        guard st == .success else { break }
        all += Array(UnsafeBufferPointer(start: out.floatChannelData![0], count: Int(out.frameLength)))
        chunk += 1
    }
    engine.stop()
    // skip the first 50 ms (limiter attack settling); detector over the rest
    var maxD2: Float = 0, at = 0
    for i in max(2, Int(sr * 0.05))..<all.count { let d = abs(all[i] - 2 * all[i - 1] + all[i - 2]); if d > maxD2 { maxD2 = d; at = i } }
    let tail = all.suffix(Int(sr * 0.1)).map(abs).max() ?? 0
    // after the cut: how long until the output stays below -60 dBFS (the mixer's volume smoothing time)
    var lastLoud = -1
    for i in Int(cutAt * sr)..<min(all.count, Int((cutAt + 0.1) * sr)) where abs(all[i]) > 0.001 { lastLoud = i }
    let silentAfter = lastLoud < 0 ? 0 : Double(lastLoud + 1) / sr - cutAt
    return Result(name: name, maxD2: maxD2, tail: tail, at: Double(at) / sr, silentAfter: silentAfter)
}

let cutAt = 0.3                                          // the cut starts 300 ms in
func chunksFor(_ q: AVAudioFrameCount) -> Int { Int(cutAt * sr) / Int(q) }
var results: [Result] = []
// A. no cut: the detector's floor
results.append(try run("no cut (floor)", quantum: 240) { _, _, _ in true })
// B. hard stop
results.append(try run("hard stop", quantum: 240) { p, _, c in if c == chunksFor(240) { p.stop(); return true }; return false })
// C. mixer volume to 0 at once, then stop
results.append(try run("volume 0 at once", quantum: 240) { _, m, c in if c == chunksFor(240) { m.outputVolume = 0; return true }; return false })
// D/E. the DeviceSpike cut: 30 ms ramp of the per-player mixer volume, set once per render quantum
for (label, q) in [("ramp 30 ms, 5 ms quanta (IO 5 ms)", AVAudioFrameCount(240)), ("ramp 30 ms, 1 ms quanta", AVAudioFrameCount(48))] {
    let steps = Int(0.03 * sr) / Int(q)
    results.append(try run(label, quantum: q) { p, m, c in
        let k = c - chunksFor(q)
        if k < 0 { return false }
        if k >= steps { m.outputVolume = 0; p.stop(); return true }
        m.outputVolume = 1 - Float(k + 1) / Float(steps); return false
    })
}
// H. a new sound on a busy player with .interrupts (the old sound is cut hard by the switch)
results.append(try run("new buffer with .interrupts on a busy player", quantum: 240) { p, _, c in
    if c == chunksFor(240) {
        let n = AVAudioFrameCount(sr * 0.2), b = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: n)!; b.frameLength = n
        for i in 0..<Int(n) { b.floatChannelData![0][i] = 0 }      // silence, so any jump is the old sound's end
        p.scheduleBuffer(b, at: nil, options: .interrupts); return true
    }
    return false
})
// I. ADR-0010 D5: volume 0, wait cut_settle_s (40 ms = 8 quanta of 5 ms), stop, volume back to 1
results.append(try run("D5 cut: volume 0, settle 40 ms, stop", quantum: 240) { p, m, c in
    let k = c - chunksFor(240)
    if k == 0 { m.outputVolume = 0 }
    if k == 8 { p.stop(); m.outputVolume = 1; return true }
    return false
})
// J. ADR-0010 D7: freeze = volume 0, settle 40 ms, pause; resume 100 ms later = play, then volume 1
results.append(try run("D7 freeze/resume: settle 40 ms", quantum: 240) { p, m, c in
    let k = c - chunksFor(240)
    if k == 0 { m.outputVolume = 0 }
    if k == 8 { p.pause() }
    if k == 28 { try? startPlayer(p); m.outputVolume = 1; return true }
    return false
})
// F. the gate freeze, naive: pause at 300 ms, resume (play) at 400 ms
results.append(try run("freeze: pause / play at once", quantum: 240) { p, _, c in
    if c == chunksFor(240) { p.pause() }
    if c == chunksFor(240) + 20 { try? startPlayer(p); return true }
    return false
})
// G. the gate freeze, ramped: volume 0 then pause; on resume play then volume back to 1
results.append(try run("freeze: ramp 0, pause / play, ramp 1", quantum: 240) { p, m, c in
    let k = c - chunksFor(240)
    if k == 0 { m.outputVolume = 0 }
    if k == 2 { p.pause() }                                // 10 ms after the volume change
    if k == 20 { try? startPlayer(p) }
    if k == 21 { m.outputVolume = 1; return true }
    return false
})
print("offline cut check: 100 Hz tone at -1 dBFS, cut at 300 ms; detector max|d2x| (threshold -60 dBFS)")
for r in results {
    let pass = r.maxD2 <= 0.001
    print(String(format: "%-38@ maxD2 %@ dBFS at %.4f s  below -60 dBFS %.1f ms after the cut  %@", r.name as NSString, dbfs(r.maxD2), r.at, r.silentAfter * 1000, pass ? "PASS" : "FAIL"))
}
