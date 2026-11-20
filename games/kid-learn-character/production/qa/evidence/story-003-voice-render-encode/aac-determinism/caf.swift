import AVFoundation
// The bake's exact path: 24 kHz Float32 (Kokoro's rate) -> AVAudioConverter to 48 kHz -> CAF LPCM 16-bit mono.
let out = URL(fileURLWithPath: CommandLine.arguments[1])
let n = 39_000, inRate = 24_000.0, outRate = 48_000.0
var samples = [Float](repeating: 0, count: n)
for k in 0..<n { let t = Double(k) / inRate; samples[k] = Float(0.5 * sin(2 * .pi * 220 * t) * exp(-2 * t) + 0.15 * sin(2 * .pi * 2_900 * t)) }
let inFmt = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: inRate, channels: 1, interleaved: false)!
let outFmt = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: outRate, channels: 1, interleaved: false)!
let src = AVAudioPCMBuffer(pcmFormat: inFmt, frameCapacity: AVAudioFrameCount(n))!; src.frameLength = AVAudioFrameCount(n)
samples.withUnsafeBufferPointer { src.floatChannelData![0].update(from: $0.baseAddress!, count: n) }
let conv = AVAudioConverter(from: inFmt, to: outFmt)!
let dst = AVAudioPCMBuffer(pcmFormat: outFmt, frameCapacity: AVAudioFrameCount(Double(n) * 2) + 256)!
var done = false
_ = conv.convert(to: dst, error: nil) { _, st in if done { st.pointee = .endOfStream; return nil }; done = true; st.pointee = .haveData; return src }
let settings: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: outRate, AVNumberOfChannelsKey: 1, AVLinearPCMBitDepthKey: 16,
                               AVLinearPCMIsFloatKey: false, AVLinearPCMIsBigEndianKey: false, AVLinearPCMIsNonInterleaved: false]
do { let f = try! AVAudioFile(forWriting: out, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false); try! f.write(from: dst) }
