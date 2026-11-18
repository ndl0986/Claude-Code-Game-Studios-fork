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
    /// ADR-0010 D4: a per-player state machine on the audio queue. `gen` is the transition token (a delayed step runs
    /// only if it is still current); `sound` identifies the scheduled sound (its played-back completion counts only if
    /// it is still the sound on the player).
    enum PState: String { case idle, sounding, cutting, frozen }
    struct PlayerState {
        var state = PState.idle, gen = 0, sound = 0
        var buffer: AVAudioPCMBuffer?, startSample: AVAudioFramePosition = 0
        var frozenAt: AVAudioFramePosition = 0, stopped = false
        var pending: (AVAudioPCMBuffer, String)?
    }
    private var ps: [PlayerState]
    // ADR-0010 P-7/M-14 continuity measurement (DeviceSpike only)
    private var lastFreezeHost: UInt64 = 0, lastRewind: AVAudioFramePosition = 0
    private var lastFreezeRaw: [Int: AVAudioFramePosition] = [:], lastResumeFrom: [Int: AVAudioFramePosition] = [:]
    private var uiNext = 0
    var log: (String) -> Void = { _ in }

    init(log: @escaping (String) -> Void) {
        self.log = log
        ps = []
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
        ps = Array(repeating: PlayerState(), count: players.count)
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
        // ADR-0010 P-7/M-14 continuity: a linear chirp 200 → 2000 Hz over 2 s; aperiodic, so the content frame at any
        // output sample is found unambiguously by correlation
        buffers["chirp"] = make(2.0) { t in 0.891 * sin(2 * .pi * (200 * t + 450 * t * t)) }
        log("primed \(buffers.count) buffers at \(format.sampleRate) Hz mono")
    }

    /// Schedules a sound off the main thread on a running player (ADR-0010 candidate). Returns the uptime it was handed over.
    @discardableResult
    func play(_ name: String, on bus: Bus) -> Double {
        let handed = ProcessInfo.processInfo.systemUptime
        // spike only: the production adapter takes the player the plan chose (ADR-0010 D4; audio-plan-v1's cap)
        let idx: Int
        if bus == .ui { let ui = players.indices.filter { players[$0].bus == .ui }; idx = ui[uiNext % ui.count]; uiNext += 1 }
        else { idx = players.firstIndex { $0.bus == bus }! }
        guard let b = buffers[name] else { return handed }
        queue.async { self.request(idx, b, name, handed: handed) }
        return handed
    }

    // MARK: ADR-0010 D4/D5/D7 state machine (all on `queue`)
    private func request(_ i: Int, _ b: AVAudioPCMBuffer, _ name: String, handed: Double) {
        switch ps[i].state {
        case .idle: schedule(i, b, name: name, handed: handed)
        case .sounding: ps[i].pending = (b, name); cutPlayer(i)          // replacement: cut first, start after settle
        case .cutting: ps[i].pending = (b, name)                          // the newest request replaces a pending one
        case .frozen: log("play on a frozen player ignored (the plan starts nothing while frozen)")
        }
    }

    private func currentSample(_ i: Int) -> AVAudioFramePosition {
        let n = players[i].node
        guard let nt = n.lastRenderTime, let pt = n.playerTime(forNodeTime: nt) else { return 0 }
        return pt.sampleTime
    }

    /// Schedules on a silent player (so `.interrupts` never cuts a sound hard), optionally from a frame (D7 resume).
    private func schedule(_ i: Int, _ b: AVAudioPCMBuffer, name: String, handed: Double, from: AVAudioFramePosition = 0) {
        let p = players[i]
        ps[i].gen += 1; ps[i].sound += 1
        let sound = ps[i].sound
        ps[i].state = .sounding; ps[i].buffer = b; ps[i].stopped = false
        var toPlay = b
        if from > 0, from < AVAudioFramePosition(b.frameLength) {   // the rest of the buffer, copied here (not on a press)
            let rest = Int(b.frameLength) - Int(from)
            let r = AVAudioPCMBuffer(pcmFormat: b.format, frameCapacity: AVAudioFrameCount(rest))!
            r.frameLength = AVAudioFrameCount(rest)
            r.floatChannelData![0].update(from: b.floatChannelData![0] + Int(from), count: rest)
            toPlay = r
        }
        if !p.node.isPlaying { startPlayer(p.node) }
        ps[i].startSample = currentSample(i) - from                   // frame 0 of the original buffer, in player time
        p.node.scheduleBuffer(toPlay, at: nil, options: .interrupts, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            self?.queue.async {
                guard let self, self.ps[i].sound == sound, self.ps[i].state == .sounding else { return }
                self.ps[i].state = .idle                               // "sounding" ends when played back (D4)
            }
        }
        let at = ProcessInfo.processInfo.systemUptime
        log(String(format: "split %@: handed %.4f scheduled %.4f io %.2f ms out %.2f ms estOnset %.4f",
                   name, handed, at, ioBufferMs, outputLatencyMs, at + (ioBufferMs + outputLatencyMs) / 1000))
    }

    /// D5: gate to 0 (smoothed), after cutSettle stop, restart, gate back to 1, then any pending start.
    private func cutPlayer(_ i: Int) {
        let p = players[i]
        switch ps[i].state {
        case .idle, .cutting: return                                   // nothing sounding / already fading
        case .frozen where ps[i].stopped:                              // already silent and stopped
            ps[i].gen += 1; ps[i].state = .idle; startPlayer(p.node); p.mix.outputVolume = 1; return
        case .sounding, .frozen: break                                 // a frozen player still fading: finish as a cut
        }
        ps[i].state = .cutting; ps[i].gen += 1
        let g = ps[i].gen
        p.mix.outputVolume = 0
        queue.asyncAfter(deadline: .now() + cutSettle) {
            guard self.ps[i].gen == g else { return }
            p.node.stop(); self.startPlayer(p.node); p.mix.outputVolume = 1
            self.ps[i].state = .idle
            if let (b, name) = self.ps[i].pending { self.ps[i].pending = nil; self.schedule(i, b, name: name, handed: ProcessInfo.processInfo.systemUptime) }
        }
    }

    /// Cuts every player on a bus without a click (P-7 / M-14 listen for clicks). A cut drops any pending start.
    func cut(_ bus: Bus) {
        queue.async { for i in self.players.indices where self.players[i].bus == bus { self.ps[i].pending = nil; self.cutPlayer(i) } }
        log("cut \(bus.rawValue) settle=\(Int(cutSettle * 1000)) ms")
    }

    func setMuted(_ m: Bool) { let target: Float = m ? 0 : 1; queue.async { let from = self.engine.mainMixerNode.outputVolume; for s in 0...30 { self.engine.mainMixerNode.outputVolume = from + (target - from) * Float(s) / 30; usleep(1000) } }; log("mute \(m)") }

    /// D7: position taken at the freeze call (before the gate falls), gate 0, stop after cutSettle.
    func freeze() {
        queue.async {
            for i in self.players.indices where self.ps[i].state == .sounding {
                self.ps[i].frozenAt = max(0, self.currentSample(i) - self.ps[i].startSample)
                self.lastFreezeHost = mach_absolute_time(); self.lastFreezeRaw[i] = self.ps[i].frozenAt
                self.ps[i].state = .frozen; self.ps[i].stopped = false; self.ps[i].gen += 1
                let g = self.ps[i].gen, p = self.players[i]
                p.mix.outputVolume = 0
                self.queue.asyncAfter(deadline: .now() + self.cutSettle) {
                    guard self.ps[i].gen == g, self.ps[i].state == .frozen else { return }
                    p.node.stop(); self.ps[i].stopped = true
                }
            }
        }
        log("freeze: positions held, players faded and stopped")
    }
    /// D7: each frozen sound continues from its held frame; a resume before the stop only raises the gate.
    func resume() {
        queue.async {
            for i in self.players.indices where self.ps[i].state == .frozen {
                let p = self.players[i]
                if !self.ps[i].stopped {
                    self.ps[i].gen += 1; self.ps[i].state = .sounding        // the pending stop becomes a no-op
                } else if let b = self.ps[i].buffer {
                    // ADR-0010 D7: rewind = max(20 ms, actual IO period + 5 ms), capped at cutSettle, so nothing is skipped
                    // (the captured position runs ahead by the schedule-to-first-render delay, ≤ one IO period; H-1)
                    let rewindS = min(self.cutSettle, max(0.020, self.ioBufferMs / 1000 + 0.005))
                    if self.ioBufferMs / 1000 + 0.005 > self.cutSettle {   // ADR-0010 Risks (game-dev-android): capped rewind
                        self.log(String(format: "IO period %.1f ms + 5 ms > cut_settle_s %.0f ms: the capped rewind may skip up to %.1f ms",
                                        self.ioBufferMs, self.cutSettle * 1000, self.ioBufferMs + 5 - self.cutSettle * 1000))
                    }
                    let rewind = AVAudioFramePosition(rewindS * self.format.sampleRate)
                    self.lastResumeFrom[i] = max(0, self.ps[i].frozenAt - rewind); self.lastRewind = rewind
                    self.schedule(i, b, name: "resume", handed: ProcessInfo.processInfo.systemUptime, from: max(0, self.ps[i].frozenAt - rewind))
                    self.log("resume player \(i) from frame \(self.ps[i].frozenAt)")
                }
                p.mix.outputVolume = 1
            }
        }
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
    private var captureOn = false, capture: [Float] = [], captureStart: AVAudioFramePosition?
    private var captureAnchor: (host: UInt64, sample: AVAudioFramePosition)?

    private func ensureTap() {
        guard !tapInstalled else { return }
        tapInstalled = true
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buf, when in
            guard let self, let d = buf.floatChannelData?[0] else { return }
            self.tapLock.lock(); defer { self.tapLock.unlock() }
            if self.captureOn {                                   // P-7/M-14 continuity: samples on the output timeline
                if self.captureStart == nil, when.isSampleTimeValid { self.captureStart = when.sampleTime }
                if when.isHostTimeValid, when.isSampleTimeValid { self.captureAnchor = (when.hostTime, when.sampleTime) }
                self.capture.append(contentsOf: UnsafeBufferPointer(start: d, count: Int(buf.frameLength)))
            }
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
    /// ADR-0010 D7 on the device (P-7 / M-14 measure, game-qc-ios): plays the chirp on a bus, freezes at 0.8 s and resumes
    /// at 1.1 s, with the main mixer tapped. From the tap: the content frame actually audible at the freeze instant
    /// (correlation just before it, gain 1, mapped through the tap's host/sample times), the frame the app resumed from,
    /// Δ = resume − freeze (pass when −cut_settle_s ≤ Δ ≤ 0, Audio AC-21) and the start delay (captured − audible),
    /// logged against the rewind (if the delay ever reaches the rewind, the IO-period term is wrong for this device).
    func continuityTest(on bus: Bus) {
        ensureTap()
        guard let chirp = buffers["chirp"], let idx = players.firstIndex(where: { $0.bus == bus }) else { return }
        tapLock.lock(); captureOn = false; capture = []; captureStart = nil; captureAnchor = nil; tapLock.unlock()
        play("chirp", on: bus)
        let q = DispatchQueue.main
        q.asyncAfter(deadline: .now() + 0.3) { self.tapLock.lock(); self.captureOn = true; self.tapLock.unlock() }
        q.asyncAfter(deadline: .now() + 0.8) { self.freeze() }
        q.asyncAfter(deadline: .now() + 1.1) { self.resume() }
        q.asyncAfter(deadline: .now() + 1.5) {
            self.tapLock.lock(); self.captureOn = false
            let cap = self.capture, start = self.captureStart, anchor = self.captureAnchor; self.tapLock.unlock()
            DispatchQueue.global(qos: .utility).async {
                self.measureContinuity(cap: cap, start: start, anchor: anchor, chirp: chirp, player: idx, bus: bus)
            }
        }
    }

    private func measureContinuity(cap: [Float], start: AVAudioFramePosition?, anchor: (host: UInt64, sample: AVAudioFramePosition)?,
                                   chirp: AVAudioPCMBuffer, player i: Int, bus: Bus) {
        let rate = format.sampleRate
        guard let start, let anchor, let raw = lastFreezeRaw[i], let from = lastResumeFrom[i], lastFreezeHost != 0 else {
            log("continuity \(bus.rawValue): not measured (no capture or no freeze)"); return
        }
        // the freeze instant on the output timeline (tap sample time), from the anchor's host/sample pair
        let dt = AVAudioTime.seconds(forHostTime: lastFreezeHost) - AVAudioTime.seconds(forHostTime: anchor.host)
        let freezeOut = anchor.sample + AVAudioFramePosition((dt * rate).rounded())
        // the content frame at a known output sample, by correlation over a 4096-sample window 50–135 ms before the freeze
        let w = 4096, winOut = freezeOut - AVAudioFramePosition(0.05 * rate) - AVAudioFramePosition(w)
        let ci = Int(winOut - start)
        guard ci >= 0, ci + w <= cap.count else { log("continuity \(bus.rawValue): capture window out of range"); return }
        let src = chirp.floatChannelData![0], n = Int(chirp.frameLength)
        func score(_ c: Int) -> Float { var acc: Float = 0; for k in 0..<w { acc += cap[ci + k] * src[c + k] }; return acc }
        var best = 0, bestS = -Float.infinity
        for c in stride(from: 0, to: n - w, by: 8) { let sc = score(c); if sc > bestS { bestS = sc; best = c } }
        for c in max(0, best - 8)...min(n - w - 1, best + 8) { let sc = score(c); if sc > bestS { bestS = sc; best = c } }
        let freezeContent = AVAudioFramePosition(best) + (freezeOut - winOut)        // content audible at the freeze instant
        let delta = from - freezeContent, delay = raw - freezeContent
        let lo = -AVAudioFramePosition(cutSettle * rate)
        let ok = delta <= 0 && delta >= lo
        log(String(format: "continuity %@: resume − freeze Δ = %lld frames (%.1f ms) → %@ (pass −%.0f…0 ms); start delay %lld frames (%.1f ms) vs rewind %lld (%.1f ms)%@",
                   bus.rawValue, delta, Double(delta) / rate * 1000, ok ? "PASS" : "FAIL", cutSettle * 1000,
                   delay, Double(delay) / rate * 1000, lastRewind, Double(lastRewind) / rate * 1000,
                   delay >= lastRewind ? " — DELAY REACHES THE REWIND: the IO-period term is wrong on this device" : ""))
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
