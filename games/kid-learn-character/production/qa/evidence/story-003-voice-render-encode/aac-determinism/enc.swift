import AVFoundation
// Encodes a fixed signal with VoiceBake's settings: AAC-LC mono 48 kHz 64 kbit/s via AVAudioFile, whole buffer write.
let out = URL(fileURLWithPath: CommandLine.arguments[1]); let mode = CommandLine.arguments[2]
let variant0 = CommandLine.arguments.count > 3 ? CommandLine.arguments[3] : "default"
let n = 70_000
let fmt = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1)!
let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: AVAudioFrameCount(n))!
buf.frameLength = AVAudioFrameCount(n)
for k in 0..<n { let t = Double(k) / 48_000; buf.floatChannelData![0][k] = Float(0.5 * sin(2 * .pi * 440 * t) * exp(-3 * t) + 0.1 * sin(2 * .pi * 3_100 * t)) }
var settings: [String: Any] = [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 48_000.0, AVNumberOfChannelsKey: 1, AVEncoderBitRateKey: 64_000]
if variant0 == "caf" { settings = [AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 48_000.0, AVNumberOfChannelsKey: 1, AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false, AVLinearPCMIsBigEndianKey: false, AVLinearPCMIsNonInterleaved: false] }
let variant = CommandLine.arguments.count > 3 ? CommandLine.arguments[3] : "default"
if variant == "cbr" { settings[AVEncoderBitRateStrategyKey] = AVAudioBitRateStrategy_Constant }
if variant == "cbrmax" { settings[AVEncoderBitRateStrategyKey] = AVAudioBitRateStrategy_Constant; settings[AVEncoderAudioQualityKey] = AVAudioQuality.max.rawValue }
do {
    let f = try! AVAudioFile(forWriting: out, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false)
    if mode == "whole" { try! f.write(from: buf) }
    else { // fixed 1024-frame chunks from a fresh buffer each time
        var o = 0
        while o < n {
            let c = min(1024, n - o)
            let b = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: 1024)!; b.frameLength = AVAudioFrameCount(c)
            for k in 0..<c { b.floatChannelData![0][k] = buf.floatChannelData![0][o + k] }
            try! f.write(from: b); o += c
        }
    }
}
