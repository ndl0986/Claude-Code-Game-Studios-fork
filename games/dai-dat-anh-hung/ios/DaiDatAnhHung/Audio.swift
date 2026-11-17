import AVFoundation

/// Placeholder sounds: the prototype's synthesised tones, rendered once into PCM buffers at launch,
/// before the title draws, and played from a small pool of player nodes (one tone per press).
final class Audio {
    enum Sfx: CaseIterable { case tap, drum, clang, swoosh, bonk, chime, soft }
    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var next = 0
    private var buffers: [Sfx: AVAudioPCMBuffer] = [:]
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    var muted = false { didSet { engine.mainMixerNode.outputVolume = muted ? 0 : volume } }
    var volume: Float = 0.5

    init(volume: Double) {
        self.volume = Float(volume)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        for _ in 0..<8 {
            let p = AVAudioPlayerNode()
            engine.attach(p); engine.connect(p, to: engine.mainMixerNode, format: format)
            players.append(p)
        }
        engine.mainMixerNode.outputVolume = self.volume
        // tone(freq, dur, wave, vol, slide) lists, as the prototype's sfx table
        let defs: [Sfx: [(Double, Double, Wave, Double, Double)]] = [
            .tap: [(660, 0.06, .sine, 0.15, 0)],
            .drum: [(110, 0.25, .sine, 0.6, 0.5), (220, 0.08, .triangle, 0.2, 0)],
            .clang: [(880, 0.18, .triangle, 0.25, 0), (1320, 0.12, .sine, 0.15, 0)],
            .swoosh: [(500, 0.12, .saw, 0.05, 0.4)],
            .bonk: [(180, 0.2, .triangle, 0.25, 0.7)],
            .chime: [(784, 0.2, .sine, 0.3, 0), (1046, 0.3, .sine, 0.3, 0)],
            .soft: [(260, 0.25, .triangle, 0.18, 0.85)],
        ]
        for (k, tones) in defs { buffers[k] = render(tones) }
        try? engine.start()
        for p in players { p.play() }
    }

    func play(_ s: Sfx) {
        guard !muted, let b = buffers[s] else { return }
        if !engine.isRunning { try? engine.start(); players.forEach { $0.play() } }
        let p = players[next]; next = (next + 1) % players.count
        p.scheduleBuffer(b, at: nil, options: .interrupts)
    }

    enum Wave { case sine, triangle, saw }

    private func render(_ tones: [(Double, Double, Wave, Double, Double)]) -> AVAudioPCMBuffer {
        let sr = format.sampleRate
        let len = AVAudioFrameCount((tones.map(\.1).max() ?? 0.1) * sr)
        let b = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: len)!
        b.frameLength = len
        let out = b.floatChannelData![0]
        for i in 0..<Int(len) { out[i] = 0 }
        for (f0, dur, wave, vol, slide) in tones {
            var phase = 0.0
            let n = Int(dur * sr)
            for i in 0..<n {
                let t = Double(i) / sr
                let f = slide > 0 ? f0 * pow(max(30 / f0, slide), t / dur) : f0
                phase += f / sr
                let x = phase - floor(phase)
                let v: Double
                switch wave { case .sine: v = sin(2 * .pi * x); case .triangle: v = 4 * abs(x - 0.5) - 1; case .saw: v = 2 * x - 1 }
                let env = vol * pow(0.001 / vol, t / dur) // exponential decay to 0.001, like the prototype's gain ramp
                out[i] += Float(v * env)
            }
        }
        return b
    }
}
