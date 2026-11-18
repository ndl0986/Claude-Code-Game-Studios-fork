// PROTOTYPE - NOT FOR PRODUCTION (TASK-078 DeviceSpike, ADR-0010 candidate graph)
// The candidate audio graph from Audio & Voice R2/R4/R6: 7 players on 4 buses (voice 1, cast 1, ui 4, music 1),
// buses → submix → peak limiter → main mixer. Players start once and keep running; a sound is started by
// scheduling a primed buffer with .interrupts, off the main thread. A cut ramps that player's own mixer to 0 over
// cut_fade_s (the candidate no-click mechanism, checked by P-7 / M-14). Buffers are synthesised at the output rate.
import AVFoundation
import QuartzCore

final class AudioSpike: @unchecked Sendable {
    enum Bus: String, CaseIterable { case voice, cast, ui, music }
    let engine = AVAudioEngine()
    let queue = DispatchQueue(label: "spike.audio", qos: .userInteractive)
    private(set) var players: [(bus: Bus, node: AVAudioPlayerNode, mix: AVAudioMixerNode)] = []
    private var busMixers: [Bus: AVAudioMixerNode] = [:]
    private let submix = AVAudioMixerNode()
    private let limiter = AVAudioUnitEffect(audioComponentDescription: AudioComponentDescription(
        componentType: kAudioUnitType_Effect, componentSubType: kAudioUnitSubType_PeakLimiter,
        componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0))
    var format: AVAudioFormat
    var buffers: [String: AVAudioPCMBuffer] = [:]
    var cutFade = 0.03
    private var uiNext = 0
    var log: (String) -> Void = { _ in }

    init(log: @escaping (String) -> Void) {
        self.log = log
        #if os(iOS)
        let s = AVAudioSession.sharedInstance()
        try? s.setCategory(.soloAmbient, mode: .default)       // obeys silent mode, does not mix (Audio R6)
        try? s.setPreferredIOBufferDuration(0.005)
        try? s.setActive(true)
        #endif
        let rate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        format = AVAudioFormat(standardFormatWithSampleRate: rate > 0 ? rate : 48000, channels: 1)!
        engine.attach(submix); engine.attach(limiter)
        for b in Bus.allCases {
            let m = AVAudioMixerNode(); engine.attach(m); busMixers[b] = m
            engine.connect(m, to: submix, format: nil)
            let count = b == .ui ? 4 : 1
            for _ in 0..<count {
                let p = AVAudioPlayerNode(), pm = AVAudioMixerNode()
                engine.attach(p); engine.attach(pm)
                engine.connect(p, to: pm, format: format); engine.connect(pm, to: m, format: format)
                players.append((b, p, pm))
            }
        }
        busMixers[.cast]?.outputVolume = 0.63; busMixers[.ui]?.outputVolume = 0.32; busMixers[.music]?.outputVolume = 0.40
        engine.connect(submix, to: limiter, format: nil)
        engine.connect(limiter, to: engine.mainMixerNode, format: nil)
        primeBuffers()
        start(reason: "launch")
        observe()
    }

    func start(reason: String) {
        engine.prepare()
        do { try engine.start() } catch { log("engine start failed (\(reason)): \(error)") }
        for p in players where !p.node.isPlaying { p.node.play() }
        log("engine running (\(reason)) rate=\(format.sampleRate) io=\(String(format: "%.2f", ioBufferMs)) ms out=\(String(format: "%.2f", outputLatencyMs)) ms")
    }

    var ioBufferMs: Double {
        #if os(iOS)
        AVAudioSession.sharedInstance().ioBufferDuration * 1000
        #else
        Double(engine.outputNode.auAudioUnit.maximumFramesToRender) / max(format.sampleRate, 1) * 1000
        #endif
    }
    var outputLatencyMs: Double {
        #if os(iOS)
        AVAudioSession.sharedInstance().outputLatency * 1000
        #else
        engine.outputNode.presentationLatency * 1000
        #endif
    }

    // MARK: synthesised sounds (placeholders: the real files come from the content pipeline)
    func primeBuffers() {
        let r = format.sampleRate
        func make(_ dur: Double, _ f: (Double) -> Double) -> AVAudioPCMBuffer {
            let n = AVAudioFrameCount(dur * r), b = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: n)!
            b.frameLength = n; let d = b.floatChannelData![0]
            for i in 0..<Int(n) { let t = Double(i) / r; let env = min(1, t / 0.01) * min(1, (dur - t) / 0.01); d[i] = Float(f(t) * env) }
            return b
        }
        buffers["chime"] = make(0.4) { t in 0.5 * exp(-t * 7) * (sin(2 * .pi * 1568 * t) + 0.6 * sin(2 * .pi * 2093 * t)) }
        buffers["ping"] = make(0.18) { t in 0.35 * exp(-t * 14) * sin(2 * .pi * 2349 * t) }
        buffers["voice"] = make(0.9) { t in 0.6 * sin(2 * .pi * (220 + 120 * t) * t + 0.3 * sin(2 * .pi * 5 * t)) }
        var seed: UInt32 = 1
        buffers["cast"] = make(0.9) { t in
            seed = seed &* 1664525 &+ 1013904223
            let noise = Double(Int32(bitPattern: seed)) / Double(Int32.max)
            return 0.5 * (0.6 * sin(2 * .pi * 70 * t) + 0.4 * noise * 0.3) * exp(-t * 1.5)
        }
        let notes = [523.25, 659.25, 783.99, 1046.5, 783.99, 659.25, 523.25, 659.25]
        buffers["music"] = make(2.0) { t in let k = min(notes.count - 1, Int(t / 0.25)); return 0.4 * sin(2 * .pi * notes[k] * t) * exp(-(t - Double(k) * 0.25) * 4) }
        log("primed \(buffers.count) buffers at \(format.sampleRate) Hz mono")
    }

    /// Schedules a sound off the main thread on a running player (ADR-0010 candidate). Returns the uptime it was handed over.
    @discardableResult
    func play(_ name: String, on bus: Bus) -> Double {
        let handed = ProcessInfo.processInfo.systemUptime
        let idx: Int
        if bus == .ui { let ui = players.indices.filter { players[$0].bus == .ui }; idx = ui[uiNext % ui.count]; uiNext += 1 }
        else { idx = players.firstIndex { $0.bus == bus }! }
        guard let b = buffers[name] else { return handed }
        let p = players[idx]
        queue.async {
            p.mix.outputVolume = 1
            p.node.scheduleBuffer(b, at: nil, options: .interrupts)
            if !p.node.isPlaying { p.node.play() }
        }
        return handed
    }

    /// Ramps the bus's players to silence over cutFade, then stops the scheduled sound (P-7 / M-14 listen for clicks).
    func cut(_ bus: Bus) {
        let targets = players.filter { $0.bus == bus }
        let steps = max(1, Int(cutFade / 0.001))
        queue.async {
            for s in 0...steps { for t in targets { t.mix.outputVolume = Float(1 - Double(s) / Double(steps)) }; usleep(1000) }
            for t in targets { t.node.stop(); t.node.play(); t.mix.outputVolume = 1 }
        }
        log("cut \(bus.rawValue) fade=\(Int(cutFade * 1000)) ms")
    }

    func setMuted(_ m: Bool) { let target: Float = m ? 0 : 1; queue.async { let from = self.engine.mainMixerNode.outputVolume; for s in 0...30 { self.engine.mainMixerNode.outputVolume = from + (target - from) * Float(s) / 30; usleep(1000) } }; log("mute \(m)") }
    func freeze() { queue.async { for p in self.players { p.node.pause() } }; log("freeze: players paused") }
    func resume() { queue.async { for p in self.players { p.node.play() } }; log("resume") }

    private func observe() {
        let nc = NotificationCenter.default
        nc.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            self?.log("configuration change → restart and re-prime"); self?.primeBuffers(); self?.start(reason: "config change")
        }
        #if os(iOS)
        nc.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] n in
            let type = (n.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt).flatMap(AVAudioSession.InterruptionType.init)
            let opts = (n.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt).map(AVAudioSession.InterruptionOptions.init) ?? []
            self?.log("interruption \(type == .began ? "began" : "ended") shouldResume=\(opts.contains(.shouldResume))")
            if type == .ended { try? AVAudioSession.sharedInstance().setActive(true); self?.start(reason: "interruption ended") }
        }
        nc.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] n in
            let reason = (n.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt).flatMap(AVAudioSession.RouteChangeReason.init)
            let outs = AVAudioSession.sharedInstance().currentRoute.outputs.map { $0.portType.rawValue }.joined(separator: ",")
            self?.log("route change reason=\(reason.map { "\($0.rawValue)" } ?? "?") outputs=\(outs)")
            if reason == .oldDeviceUnavailable { self?.cut(.voice); self?.cut(.cast) }
        }
        nc.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { [weak self] _ in
            self?.log("media services reset → rebuild needed (spike: restart engine)"); self?.start(reason: "media reset")
        }
        #endif
    }
}
