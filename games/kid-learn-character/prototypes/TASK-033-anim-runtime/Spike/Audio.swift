// PROTOTYPE - NOT FOR PRODUCTION (TASK-033 spike)
// One AVAudioPlayerNode: a new reveal stops the old sound and starts the new one (at most 1 voice).
import AVFoundation
import QuartzCore

final class Audio {
    let engine = AVAudioEngine(), player = AVAudioPlayerNode()
    var buffer: AVAudioPCMBuffer?
    var ioBuffer = 0.0, outputLatency = 0.0

    init() {
        #if os(iOS)
        let s = AVAudioSession.sharedInstance()
        try? s.setCategory(.playback, mode: .default)
        try? s.setPreferredIOBufferDuration(0.005)
        try? s.setActive(true)
        #endif
        if let url = Bundle.main.url(forResource: "roar", withExtension: "wav"), let f = try? AVAudioFile(forReading: url),
           let b = AVAudioPCMBuffer(pcmFormat: f.processingFormat, frameCapacity: AVAudioFrameCount(f.length)) {
            try? f.read(into: b); buffer = b
            engine.attach(player); engine.connect(player, to: engine.mainMixerNode, format: f.processingFormat)
        }
        engine.prepare(); try? engine.start()
        #if os(iOS)
        ioBuffer = AVAudioSession.sharedInstance().ioBufferDuration; outputLatency = AVAudioSession.sharedInstance().outputLatency
        #else
        outputLatency = engine.outputNode.presentationLatency
        ioBuffer = Double(engine.outputNode.auAudioUnit.maximumFramesToRender) / engine.outputNode.outputFormat(forBus: 0).sampleRate
        #endif
        NSLog("[spike] audio ioBuffer=%.2f ms outputLatency=%.2f ms", ioBuffer * 1000, outputLatency * 1000)
    }

    /// Cuts any playing sound and starts the roar; returns (scheduled, estimated first audible sample).
    func roar() -> (Double, Double) {
        guard let b = buffer else { return (0, 0) }
        player.stop()
        player.scheduleBuffer(b, at: nil)
        player.play()
        let t = CACurrentMediaTime()
        Metrics.shared.maxVoices = max(Metrics.shared.maxVoices, 1)
        return (t, t + ioBuffer + outputLatency)
    }
}
