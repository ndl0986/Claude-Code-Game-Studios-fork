// PROTOTYPE - NOT FOR PRODUCTION (TASK-078 DeviceSpike, ADR-0010 candidate graph)
// The candidate audio graph from Audio & Voice R2/R4/R6: 7 players on 4 buses (voice 1, cast 1, ui 4, music 1),
// buses → submix → peak limiter → main mixer. Players start once and keep running; a sound is started by
// scheduling a primed buffer, off the main thread. ADR-0010 D5 (TASK-087): a sounding player is never stopped,
// paused or interrupted hard (that clicks: tools/offline-cut-check.swift). A cut sets the player's own mixer volume
// to 0 (the mixer smooths it, ~27 ms to below −60 dBFS offline), waits cut_settle_s, then stops it and restores the
// volume; a sound for a busy player starts after that cut. Freeze/resume (D7) do the same around pause/play.
// Buffers are synthesised at the output rate.
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
    var cutSettle = 0.04          // ADR-0010 D5 cut_settle_s: the mixer's smoothing (~27 ms) plus margin
    private var busyUntil: [Double]
    private var uiNext = 0
    var log: (String) -> Void = { _ in }

    init(log: @escaping (String) -> Void) {
        self.log = log
        busyUntil = []
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
        busyUntil = Array(repeating: 0, count: players.count)
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
        for p in players where !p.node.isPlaying { startPlayer(p.node) }
        log("engine running (\(reason)) rate=\(format.sampleRate) io=\(String(format: "%.2f", ioBufferMs)) ms out=\(String(format: "%.2f", outputLatencyMs)) ms")
    }

    /// `play()` is deprecated from the 27 SDKs; `playAudio()` (throws) exists only on 27+ (deployment is 26).
    func startPlayer(_ n: AVAudioPlayerNode) {
        if #available(iOS 27, macOS 27, *) {
            do { try n.playAudio() } catch { log("playAudio failed: \(error)") }
        } else { n.play() }
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
        buffers["tone100"] = make(2.0) { t in 0.891 * sin(2 * .pi * 100 * t) }   // ADR-0010 P-7/M-14 test tone, −1 dBFS
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
        let dur = Double(b.frameLength) / format.sampleRate
        queue.async {
            let now = ProcessInfo.processInfo.systemUptime
            let schedule = {
                p.node.scheduleBuffer(b, at: nil, options: .interrupts)   // the player is silent here: no hard cut
                if !p.node.isPlaying { self.startPlayer(p.node) }
                self.busyUntil[idx] = ProcessInfo.processInfo.systemUptime + dur
            }
            if self.busyUntil[idx] > now {                                 // busy: cut first (D5), then start
                self.cutPlayer(idx) { schedule() }
            } else { schedule() }
        }
        return handed
    }

    /// ADR-0010 D5, on the audio queue: volume 0 (smoothed by the mixer), wait cutSettle, stop, volume back to 1.
    private func cutPlayer(_ idx: Int, then: (() -> Void)? = nil) {
        let p = players[idx]
        p.mix.outputVolume = 0
        queue.asyncAfter(deadline: .now() + cutSettle) {
            p.node.stop(); self.startPlayer(p.node); p.mix.outputVolume = 1; self.busyUntil[idx] = 0
            then?()
        }
    }

    /// Cuts every player on a bus without a click (P-7 / M-14 listen for clicks).
    func cut(_ bus: Bus) {
        queue.async { for i in self.players.indices where self.players[i].bus == bus { self.cutPlayer(i) } }
        log("cut \(bus.rawValue) settle=\(Int(cutSettle * 1000)) ms")
    }

    func setMuted(_ m: Bool) { let target: Float = m ? 0 : 1; queue.async { let from = self.engine.mainMixerNode.outputVolume; for s in 0...30 { self.engine.mainMixerNode.outputVolume = from + (target - from) * Float(s) / 30; usleep(1000) } }; log("mute \(m)") }
    /// ADR-0010 D7: volume 0, wait cutSettle, pause (the position is held ~cutSettle after the freeze moment).
    func freeze() {
        queue.async {
            for p in self.players { p.mix.outputVolume = 0 }
            self.queue.asyncAfter(deadline: .now() + self.cutSettle) { for p in self.players { p.node.pause() } }
        }
        log("freeze: players faded and paused")
    }
    /// ADR-0010 D7: play from the held position, then volume 1 (the mixer smooths the rise).
    func resume() {
        queue.async { for p in self.players { self.startPlayer(p.node); p.mix.outputVolume = 1 } }
        log("resume")
    }

    private func observe() {
        let nc = NotificationCenter.default
        nc.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            self?.log("configuration change → restart and re-prime"); self?.primeBuffers(); self?.start(reason: "config change")
        }
        #if os(iOS)
        if #available(iOS 27, *) {
            // ADR-0010 D8: on iPadOS 27 the interruption notification is deprecated; its replacements:
            nc.addObserver(forName: AVAudioSession.didBecomeInactiveNotification, object: nil, queue: .main) { [weak self] n in
                let ctx = n.userInfo?[AVAudioSession.deactivationContextKey] as? AVAudioSession.DeactivationContext
                self?.log("session inactive source=\(ctx.map { "\($0.source.rawValue)" } ?? "?")")
            }
            nc.addObserver(forName: AVAudioSession.resumptionRecommendationNotification, object: nil, queue: .main) { [weak self] n in
                let ctx = n.userInfo?[AVAudioSession.resumptionContextKey] as? AVAudioSession.ResumptionContext
                let resume = ctx?.recommendation == .shouldResume
                self?.log("resumption recommendation shouldResume=\(resume)")
                if resume { try? AVAudioSession.sharedInstance().setActive(true); self?.start(reason: "resumption") }
            }
        }
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

    // MARK: ADR-0010 row helpers (P-7 / M-14 capture, P-8 simulated reset)
    // H-1's detector on the live output: the largest |x[n] − 2x[n−1] + x[n−2]| of the main mixer's output, read by an
    // installTap. Only meaningful on the 100 Hz test tone (program sounds have large second differences of their own).
    private let tapLock = NSLock()
    private var tapOn = false, tapMax: Float = 0, tapA: Float = 0, tapB: Float = 0
    private var tapInstalled = false

    private func ensureTap() {
        guard !tapInstalled else { return }
        tapInstalled = true
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buf, _ in
            guard let self, let d = buf.floatChannelData?[0] else { return }
            self.tapLock.lock(); defer { self.tapLock.unlock() }
            var a = self.tapA, b = self.tapB
            for i in 0..<Int(buf.frameLength) {
                let x = d[i]
                if self.tapOn { self.tapMax = max(self.tapMax, abs(x - 2 * b + a)) }
                a = b; b = x
            }
            self.tapA = a; self.tapB = b
        }
    }
    private func arm(_ on: Bool) { tapLock.lock(); tapOn = on; if on { tapMax = 0 }; tapLock.unlock() }
    private func report(_ what: String) {
        tapLock.lock(); let m = tapMax; tapLock.unlock()
        let db = m > 0 ? 20 * log10(m) : -200
        log(String(format: "detector %@: max|d2x| %.1f dBFS → %@ (AC-9 threshold −60)", what, db, db <= -60 ? "PASS" : "FAIL"))
    }

    enum ToneTest: String { case cut, mute, freeze }
    /// Plays the 100 Hz tone on a bus, then at 0.5 s cuts / mutes / freezes (resume 0.3 s later), with the detector
    /// armed over the whole event; logs the result. P-7 (iPad) and M-14 (Mac) run it per bus; the ear checks the
    /// program sounds with the normal Play / Cut buttons.
    func toneTest(_ test: ToneTest, on bus: Bus) {
        ensureTap()
        play("tone100", on: bus)
        let q = DispatchQueue.main
        q.asyncAfter(deadline: .now() + 0.45) { self.arm(true) }
        q.asyncAfter(deadline: .now() + 0.5) {
            switch test {
            case .cut: self.cut(bus)
            case .mute: self.setMuted(true)
            case .freeze: self.freeze(); q.asyncAfter(deadline: .now() + 0.3) { self.resume() }
            }
        }
        q.asyncAfter(deadline: .now() + 1.0) {
            self.arm(false); self.report("\(test.rawValue) \(bus.rawValue)")
            if test == .mute { self.setMuted(false) }
        }
    }
    /// Plays the tone on the voice bus and arms the detector for 5 s, for the headphones-out case (unplug meanwhile).
    func toneArmed5s() {
        ensureTap(); play("tone100", on: .voice); arm(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { self.arm(false); self.report("armed 5 s (headphones out)") }
    }

    #if os(iOS)
    /// P-8: a real media-services reset cannot be produced on demand; this posts the notification so the handler runs.
    /// The log says "simulated"; a real reset stays NOT ASSESSED (ADR-0010 decision rule).
    func simulateMediaServicesReset() {
        log("media services reset: SIMULATED (posted by the app, debug)")
        NotificationCenter.default.post(name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
    }
    #endif
}
