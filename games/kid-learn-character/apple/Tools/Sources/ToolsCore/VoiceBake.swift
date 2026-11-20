import AVFoundation
import CryptoKit
import Foundation
import KidCore

// MARK: Adapter

/// Mono floating-point audio from a TTS engine, before encoding.
public struct PCMAudio: Equatable, Sendable {
    /// Samples in -1…1, one channel.
    public var samples: [Float]
    /// Samples per second (Kokoro: 24000).
    public var sampleRate: Double
    public init(samples: [Float], sampleRate: Double) { self.samples = samples; self.sampleRate = sampleRate }
}

/// The engine-agnostic TTS adapter (ADR-0003 D6, K-41). The bake only ever sees this protocol, so swapping the engine
/// changes no file layout or name: names come from the Key Table line ids, never from the engine.
///
/// Not thread-safe: the bake calls one engine from one thread, line by line.
///
/// Example:
/// ```swift
/// struct Beep: TTSEngine {
///     let name = "beep"
///     func render(text: String) throws -> PCMAudio {
///         PCMAudio(samples: (0..<4800).map { sin(Float($0) * 0.1) * 0.2 }, sampleRate: 24000)
///     }
///     func reportedFacts() -> [String: String] { [:] }
/// }
/// ```
public protocol TTSEngine {
    /// The engine's own name, recorded in provenance (`Kokoro-82M`).
    var name: String { get }
    /// Renders `text` to mono PCM. Throws when the engine fails or returns no audio.
    func render(text: String) throws -> PCMAudio
    /// Versions the engine reported about itself (`kokoro`, `misaki`, `espeak-ng`, …), read after the last render and
    /// written to provenance. Empty for an engine with nothing to report.
    func reportedFacts() -> [String: String]
}

/// A voice-bake failure; names the file or line at fault.
public struct VoiceBakeError: Error, CustomStringConvertible, Equatable {
    public let file: String
    public let reason: String
    public var description: String { "\(file): \(reason)" }
    public init(file: String, reason: String) { self.file = file; self.reason = reason }
}

// MARK: Voice script

/// `content/themes/<id>/src/voice-scripts/<locale>.json` (ADR-0003 D1, D6): the engine settings and the respelled
/// TTS inputs (K-35). Build-only; never shipped.
public struct VoiceScript: Equatable, Sendable {
    /// The `engine` block.
    public struct EngineSettings: Equatable, Sendable {
        public var name, package, weightsRevision, voice, langCode: String
        public var speed: Double
    }
    /// The `trim` block (Audio & Voice GDD R8 note): the silence trim applied before loudness normalisation. Data, not literals.
    public struct Trim: Equatable, Sendable {
        /// Audio whose K-weighted 10 ms envelope is below this level (dBFS, negative) is silence.
        public var thresholdDBFS: Double
        /// Seconds of the original audio kept before the first and after the last audible 10 ms window.
        public var padSeconds: Double
        /// Linear fade-in and fade-out length (s) at the new ends (the first and last sample are then exactly 0).
        public var fadeSeconds: Double
        public init(thresholdDBFS: Double, padSeconds: Double, fadeSeconds: Double) {
            self.thresholdDBFS = thresholdDBFS; self.padSeconds = padSeconds; self.fadeSeconds = fadeSeconds
        }
    }
    /// The `limiter` block (ADR-0003 D5 detail): the lookahead true-peak limiter after the loudness gain. Data.
    public struct Limiter: Equatable, Sendable {
        /// The true-peak ceiling the limiter holds (dBTP); at most `VoiceBake.truePeakCeilingDBTP`.
        public var ceilingDBTP: Double
        /// How long before a peak the gain starts to fall (s).
        public var lookaheadSeconds: Double
        /// Time constant of the exponential release back to unity gain (s).
        public var releaseSeconds: Double
        /// A reduction deeper than this (dB) is reported as a warning (not transparent), never a failure.
        public var warnReductionDB: Double
        public init(ceilingDBTP: Double, lookaheadSeconds: Double, releaseSeconds: Double, warnReductionDB: Double) {
            self.ceilingDBTP = ceilingDBTP; self.lookaheadSeconds = lookaheadSeconds
            self.releaseSeconds = releaseSeconds; self.warnReductionDB = warnReductionDB
        }
    }
    public var locale: String
    public var engine: EngineSettings
    public var trim: Trim
    public var limiter: Limiter
    /// Line id (`word_ankylosaurus`) → text for the TTS only.
    public var respell: [String: String]

    /// Parses script bytes; `label` names the file in errors.
    public static func parse(_ data: Data, label: String) throws -> VoiceScript {
        func bad(_ r: String) -> VoiceBakeError { VoiceBakeError(file: label, reason: r) }
        guard let o = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { throw bad("not a JSON object") }
        guard (o["schemaVersion"] as? Int) == 1 else { throw bad("schemaVersion is not 1") }
        guard let locale = o["locale"] as? String else { throw bad("locale: missing") }
        guard let e = o["engine"] as? [String: Any] else { throw bad("engine: missing") }
        func str(_ k: String) throws -> String {
            guard let s = e[k] as? String, !s.isEmpty else { throw bad("engine.\(k): missing or not a string") }
            return s
        }
        guard let speed = e["speed"] as? Double, speed > 0 else { throw bad("engine.speed: missing or not a positive number") }
        guard let t = o["trim"] as? [String: Any] else { throw bad("trim: missing") }
        guard let lim = o["limiter"] as? [String: Any] else { throw bad("limiter: missing") }
        func num(_ k: String, _ range: ClosedRange<Double>, in block: [String: Any] = t, _ name: String = "trim") throws -> Double {
            guard let v = block[k] as? Double, v.isFinite, range.contains(v) else {
                throw bad("\(name).\(k): missing or not a number in \(range.lowerBound)…\(range.upperBound)")
            }
            return v
        }
        let limiter = Limiter(ceilingDBTP: try num("ceilingDBTP", -12 ... VoiceBake.truePeakCeilingDBTP, in: lim, "limiter"),
                              lookaheadSeconds: try num("lookaheadSeconds", 0.0005 ... 0.05, in: lim, "limiter"),
                              releaseSeconds: try num("releaseSeconds", 0.001 ... 2, in: lim, "limiter"),
                              warnReductionDB: try num("warnReductionDB", 0 ... 40, in: lim, "limiter"))
        let trim = Trim(thresholdDBFS: try num("thresholdDBFS", -120 ... -0.001), padSeconds: try num("padSeconds", 0 ... 0.5),
                        fadeSeconds: try num("fadeSeconds", 0 ... 0.1))
        let respell = (o["respell"] as? [String: Any]) ?? [:]
        var rs: [String: String] = [:]
        for (k, v) in respell {
            guard let s = v as? String, !s.isEmpty else { throw bad("respell.\(k): not a non-empty string") }
            rs[k] = s
        }
        return VoiceScript(locale: locale, engine: EngineSettings(name: try str("name"), package: try str("package"),
            weightsRevision: try str("weightsRevision"), voice: try str("voice"), langCode: try str("langCode"), speed: speed), trim: trim, limiter: limiter, respell: rs)
    }
}

// MARK: Kokoro (out of process)

/// The real engine: Kokoro-82M (K-41) run through `tts/kokoro_render.py` in a Python interpreter, out of process, on the
/// build Mac only. One helper process per line (the model reloads each time: slow but simple; batch mode is a later
/// optimisation). Never used by tests. UNVERIFIED end to end in this run: no venv exists yet.
///
/// Helper protocol: `python -I <helper> --text-file F --out W.wav --voice V --lang L --speed S --revision R --package P`.
/// The helper writes a mono WAV to `W.wav` and prints ONE JSON object of strings on its last stdout line, e.g.
/// `{"kokoro":"0.9.4","misaki":"0.9.4","espeak-ng":"1.52.0","torch":"…"}`; any non-zero exit fails the line, stderr is kept.
///
/// Example:
/// ```swift
/// let engine = KokoroProcessEngine(python: URL(fileURLWithPath: "/opt/kokoro-venv/bin/python"), settings: script.engine)
/// ```
public final class KokoroProcessEngine: TTSEngine {
    public let name: String
    let python: URL, helper: URL, settings: VoiceScript.EngineSettings
    private var facts: [String: String] = [:]

    /// The helper next to the sources: `apple/Tools/tts/kokoro_render.py` (found from this file's compile-time path).
    public static var defaultHelper: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("tts/kokoro_render.py")
    }

    public init(python: URL, helper: URL = KokoroProcessEngine.defaultHelper, settings: VoiceScript.EngineSettings) {
        self.python = python; self.helper = helper; self.settings = settings; self.name = settings.name
    }

    public func reportedFacts() -> [String: String] { facts }

    public func render(text: String) throws -> PCMAudio {
        let fm = FileManager.default
        let tmp = fm.temporaryDirectory.appendingPathComponent("kokoro-\(UUID().uuidString)")
        try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: tmp) }
        let textFile = tmp.appendingPathComponent("in.txt"), wav = tmp.appendingPathComponent("out.wav")
        let errFile = tmp.appendingPathComponent("err.txt")
        try Data(text.utf8).write(to: textFile)
        fm.createFile(atPath: errFile.path, contents: nil)
        let p = Process(), out = Pipe(), err = try FileHandle(forWritingTo: errFile)
        p.executableURL = python
        p.arguments = ["-I", helper.path, "--text-file", textFile.path, "--out", wav.path, "--voice", settings.voice,
                       "--lang", settings.langCode, "--speed", String(settings.speed), "--revision", settings.weightsRevision,
                       "--package", settings.package]
        p.standardOutput = out; p.standardError = err
        do { try p.run() } catch { throw VoiceBakeError(file: python.path, reason: "cannot run the interpreter: \(error)") }
        let outData = out.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit(); try? err.close()
        guard p.terminationStatus == 0 else {
            let msg = (try? String(contentsOf: errFile, encoding: .utf8))?.suffix(600) ?? ""
            throw VoiceBakeError(file: helper.path, reason: "exit \(p.terminationStatus): \(msg)")
        }
        guard let last = String(decoding: outData, as: UTF8.self).split(separator: "\n").last,
              let d = (try? JSONSerialization.jsonObject(with: Data(last.utf8))) as? [String: Any] else {
            throw VoiceBakeError(file: helper.path, reason: "last stdout line is not a JSON object")
        }
        let now = d.compactMapValues { $0 as? String }
        if !facts.isEmpty && facts != now { throw VoiceBakeError(file: helper.path, reason: "reported versions changed between lines") }
        facts = now
        let f = try AVAudioFile(forReading: wav)
        guard f.length > 0, let buf = AVAudioPCMBuffer(pcmFormat: f.processingFormat, frameCapacity: AVAudioFrameCount(f.length)) else {
            throw VoiceBakeError(file: wav.lastPathComponent, reason: "helper wrote no audio")
        }
        try f.read(into: buf)
        return PCMAudio(samples: Array(UnsafeBufferPointer(start: buf.floatChannelData![0], count: Int(buf.frameLength))),
                        sampleRate: f.processingFormat.sampleRate)
    }
}

// MARK: Bake

/// The build-time voice bake (TR-keytable-004 pre-rendered TTS, mono; TR-audio-006 no run-time TTS; ADR-0003 D5/D6).
///
/// Per theme and per locale in `voiceLocales`: every voice line of every item (Key Table `voice` kind → id) is
/// rendered by the adapter and written to `voice/<locale>/vo_<locale>_<kind>_<id>.caf` (`KeyTable.voicePath`). The text
/// of a line is the item's `word` for kind `word`, else its `say` (letter, number); `respell["<kind>_<id>"]` replaces it
/// for the TTS only (K-35). One line id used by several items is rendered once; if its text differs between items the
/// bake fails. Also writes `voice/<locale>/provenance.json` (byte-stable: sorted keys, no timestamps).
///
/// Encoding (K-52, Luan 2026-11-20): **CAF linear PCM, 16-bit, mono, 48 000 Hz**, via `AVAudioFile` (Apple frameworks only,
/// at another rate is resampled with `AVAudioConverter`). Before encoding each line is trimmed of silence and normalised to
/// −16 LUFS with a lookahead true-peak limiter (story 004: `trimSilence`, `limit`, `process`); `encode` itself changes no
/// sample; the written file is gated again on its decoded samples (`gateWrittenFile`).
/// Output is staged in a temp folder; nothing is written to the theme unless every line renders and encodes.
///
/// Example:
/// ```swift
/// let written = try VoiceBake.bakeTheme(themeDir: dir, theme: model) { script in KokoroProcessEngine(python: py, settings: script.engine) }
/// // ["voice/en-us/provenance.json", "voice/en-us/vo_en-us_letter_c.caf", …]
/// ```
public enum VoiceBake {
    /// Output sample rate (Hz), channel count and bit depth (K-52: linear PCM in CAF; 48 kHz matches the devices'
    /// output rate, ADR-0010 D3).
    public static let sampleRate = 48_000.0, channels = 1, bitDepth = 16


    /// One voice line.
    public struct Line: Equatable, Sendable {
        public var kind, id: String
        /// The text the engine is given (respelled when the script says so).
        public var text: String
        public var respelled: Bool
        /// `<kind>_<id>`, the key of `voiceDurations` and `respell`.
        public var lineId: String { kind + "_" + id }
        public init(kind: String, id: String, text: String, respelled: Bool) {
            self.kind = kind; self.id = id; self.text = text; self.respelled = respelled
        }
    }

    /// The lines of a theme for one locale, sorted by line id, duplicates merged.
    public static func lines(theme: ThemeModel, script: VoiceScript) throws -> [Line] {
        var byId: [String: Line] = [:]
        for key in theme.keys.keys.sorted() {
            for it in theme.keys[key]! {
                for (kind, id) in it.voice.sorted(by: { $0.key < $1.key }) {
                    let base = kind == "word" ? it.word : it.say
                    let lineId = kind + "_" + id
                    let respell = script.respell[lineId]
                    let line = Line(kind: kind, id: id, text: respell ?? base, respelled: respell != nil)
                    if base.trimmingCharacters(in: .whitespaces).isEmpty {
                        throw VoiceBakeError(file: KeyTable.voicePath(script.locale, kind, id), reason: "empty script text (\(it.castId))")
                    }
                    if let old = byId[lineId], old.text != line.text {
                        throw VoiceBakeError(file: KeyTable.voicePath(script.locale, kind, id),
                                             reason: "line id used with two texts: \"\(old.text)\" and \"\(line.text)\"")
                    }
                    byId[lineId] = line
                }
            }
        }
        return byId.keys.sorted().map { byId[$0]! }
    }

    /// Resamples to `VoiceBake.sampleRate` (a no-op copy when already there) into a mono Float32 buffer.
    static func resampled(_ pcm: PCMAudio, file: String) throws -> AVAudioPCMBuffer {
        guard !pcm.samples.isEmpty, pcm.sampleRate > 0 else { throw VoiceBakeError(file: file, reason: "engine returned no audio") }
        let inFmt = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: pcm.sampleRate, channels: 1, interleaved: false)!
        let outFmt = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 1, interleaved: false)!
        let src = AVAudioPCMBuffer(pcmFormat: inFmt, frameCapacity: AVAudioFrameCount(pcm.samples.count))!
        src.frameLength = AVAudioFrameCount(pcm.samples.count)
        pcm.samples.withUnsafeBufferPointer { src.floatChannelData![0].update(from: $0.baseAddress!, count: pcm.samples.count) }
        if pcm.sampleRate == sampleRate { return src }
        guard let conv = AVAudioConverter(from: inFmt, to: outFmt) else { throw VoiceBakeError(file: file, reason: "no sample-rate converter") }
        let cap = AVAudioFrameCount((Double(pcm.samples.count) * sampleRate / pcm.sampleRate).rounded(.up)) + 256
        let dst = AVAudioPCMBuffer(pcmFormat: outFmt, frameCapacity: cap)!
        final class Once: @unchecked Sendable { var done = false }
        let once = Once()
        var error: NSError?
        let status = conv.convert(to: dst, error: &error) { _, outStatus in
            if once.done { outStatus.pointee = .endOfStream; return nil }
            once.done = true; outStatus.pointee = .haveData; return src
        }
        if status == .error || dst.frameLength == 0 { throw VoiceBakeError(file: file, reason: "resample failed: \(error?.localizedDescription ?? "no output")") }
        return dst
    }

    /// Writes `pcm` at `url` as CAF linear PCM, 16-bit little-endian, mono, `sampleRate` (K-52). Byte-stable: the same
    /// samples give the same file in any process on either core class (AudioToolbox AAC did not:
    /// production/qa/evidence/story-003-voice-render-encode/aac-determinism/).
    public static func encode(_ pcm: PCMAudio, to url: URL) throws {
        guard url.pathExtension == "caf" else { throw VoiceBakeError(file: url.lastPathComponent, reason: "baked audio is .caf (K-52)") }
        let buf = try resampled(pcm, file: url.lastPathComponent)
        let settings: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: sampleRate,
                                       AVNumberOfChannelsKey: channels, AVLinearPCMBitDepthKey: bitDepth,
                                       AVLinearPCMIsFloatKey: false, AVLinearPCMIsBigEndianKey: false,
                                       AVLinearPCMIsNonInterleaved: false]
        do {
            let file = try AVAudioFile(forWriting: url, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false)
            try file.write(from: buf)   // the file is finalised when `file` goes out of scope at the end of this block
        } catch { throw VoiceBakeError(file: url.lastPathComponent, reason: "CAF write failed: \(error)") }
    }

    // MARK: Trim, normalise, clip guard (story 004)

    /// The voice class target (Audio F4): integrated LUFS (momentary max under 0.4 s), tolerance (LU), true-peak ceiling (dBTP).
    public static let targetLUFS = -16.0, toleranceLU = 1.0, truePeakCeilingDBTP = -1.0
    /// The silence-trim envelope window (s): 10 ms.
    public static let trimWindowSeconds = 0.010

    /// Trims leading and trailing silence from mono `samples` (Audio R8 note): the signal is K-weighted
    /// (`LoudnessMeter.kWeighting`), its RMS taken per `trimWindowSeconds` window (the last window may be partial), and a
    /// window is silent when below `trim.thresholdDBFS`. The first and last non-silent window bound the kept span, widened
    /// by `padSeconds` each side (clamped to the file) and faded linearly in and out over `fadeSeconds`, so the first and
    /// last sample are exactly 0. `head` and `tail` are the sample counts removed. Throws, naming `file`, when every window is silent.
    /// Pure; thread-safe.
    ///
    /// Example:
    /// ```swift
    /// let r = try VoiceBake.trimSilence(samples, sampleRate: 48_000, trim: script.trim, file: "vo_en-us_word_x.caf")
    /// ```
    public static func trimSilence(_ samples: [Float], sampleRate: Double, trim: VoiceScript.Trim, file: String) throws
        -> (samples: [Float], head: Int, tail: Int) {
        let win = max(1, Int((trimWindowSeconds * sampleRate).rounded()))
        let k = LoudnessMeter.kWeighting(sampleRate: sampleRate)
        var shelf = BiquadRunner(k.shelf), rlb = BiquadRunner(k.highpass)
        var first: Int?, last = 0, i = 0
        while i < samples.count {
            let end = min(i + win, samples.count)
            var sum = 0.0
            for j in i..<end { let y = rlb.process(shelf.process(Double(samples[j]))); sum += y * y }
            let rms = (sum / Double(end - i)).squareRoot()
            if rms > 0 && 20 * log10(rms) >= trim.thresholdDBFS { if first == nil { first = i }; last = end }
            i = end
        }
        guard let f = first else { throw VoiceBakeError(file: file, reason: "all silence: nothing at or above \(trim.thresholdDBFS) dBFS (K-weighted, 10 ms)") }
        let pad = Int((trim.padSeconds * sampleRate).rounded())
        let start = max(0, f - pad), stop = min(samples.count, last + pad)
        var out = Array(samples[start..<stop])
        let fade = min(Int((trim.fadeSeconds * sampleRate).rounded()), out.count / 2)
        if fade > 0 {
            for n in 0..<fade {
                let g = Float(n) / Float(fade)
                out[n] *= g
                out[out.count - 1 - n] *= g
            }
        }
        return (out, start, samples.count - stop)
    }

    /// What one voice line measured on its way to the file.
    public struct LineReport: Equatable, Sendable {
        public var lineId, path: String
        /// Decoded length of the written file, rounded to 3 decimals (the `voiceDurations` value).
        public var duration: Double
        /// Seconds trimmed from the head and the tail.
        public var trimmedHead, trimmedTail: Double
        /// Class loudness (LUFS) of the trimmed audio before the gain, after it, the gain (dB) and the true peak (dBTP) after it.
        public var loudnessBefore, loudnessAfter, gainDB, truePeakDBTP: Double
        /// The limiter's deepest reduction (dB).
        public var maxGainReductionDB: Double
        /// Class loudness (LUFS) and true peak (dBTP) measured on the decoded written file (the A7 gate, Audio R8).
        public var fileLUFS, fileTruePeakDBTP: Double
        /// SHA-256 (hex) of the render inputs (`inputHash`) and of the written file's bytes (byte-stable under K-52).
        public var inputSha256, fileSha256: String
    }

    /// The limiter's internal margin (dB) under `Limiter.ceilingDBTP`: it aims this far under the ceiling so the 16-bit
    /// write and the gain's slow variation inside the 12-tap interpolator cannot push the true peak over it.
    public static let limiterMarginDB = 0.1
    /// At most this many limiter passes per gain (each re-measures the true-peak envelope of the previous output).
    public static let limiterMaxPasses = 4

    /// A deterministic lookahead true-peak limiter (ADR-0003 D5 detail, leader-approved 2026-11-20). Sample by sample:
    /// 1. `env = LoudnessMeter.truePeakEnvelope(x)` (4x oversampled), required gain `r[i] = min(1, T / env[i])` with
    ///    `T` = ceiling − `limiterMarginDB`.
    /// 2. Min filter of `r` over ±L/2 samples (L = lookahead), then a box average over ±L/2: the gain starts falling L
    ///    samples before a peak, reaches `r` at the peak, and never steps (a change per sample ≤ 1/(L+1)). The result is
    ///    provably ≤ `r` everywhere (every averaged minimum covers the sample).
    /// 3. Release: the gain rises back to 1 no faster than exponentially with time constant `releaseSeconds`; it falls
    ///    as fast as step 2 asks.
    /// The gain is ≤ 1 and is exactly 1 where no peak needs reducing, so a quiet line passes through bit for bit. Passes
    /// repeat on the output (at most `limiterMaxPasses`) until its true peak is under `T`. Returns the output and the
    /// total per-sample gain. Pure; thread-safe.
    ///
    /// Example:
    /// ```swift
    /// let (y, gain) = VoiceBake.limit(x, sampleRate: 48_000, limiter: script.limiter)
    /// ```
    public static func limit(_ x: [Float], sampleRate: Double, limiter: VoiceScript.Limiter) -> (samples: [Float], gain: [Double]) {
        let n = x.count
        var out = x, total = [Double](repeating: 1, count: n)
        guard n > 0 else { return (out, total) }
        let ceiling = pow(10, (limiter.ceilingDBTP - limiterMarginDB) / 20)
        let h = max(1, Int((limiter.lookaheadSeconds * sampleRate / 2).rounded()))
        let alpha = 1 - exp(-1 / max(1, limiter.releaseSeconds * sampleRate))
        for _ in 0..<limiterMaxPasses {
            let env = LoudnessMeter.truePeakEnvelope(out)
            guard (env.max() ?? 0) > ceiling else { break }
            // Reduction d = 1 - r (0 where nothing is needed, so a no-peak region stays exactly 1).
            let d = env.map { $0 > ceiling ? 1 - ceiling / $0 : 0 }
            var m = [Double](repeating: 0, count: n)   // max reduction over ±h (= min gain)
            for i in 0..<n where d[max(0, i - h)...min(n - 1, i + h)].contains(where: { $0 > 0 }) {
                m[i] = d[max(0, i - h)...min(n - 1, i + h)].max()!
            }
            var cum = [Double](repeating: 0, count: n + 1)
            for i in 0..<n { cum[i + 1] = cum[i] + m[i] }
            var g = 1.0
            for i in 0..<n {
                let lo = max(0, i - h), hi = min(n - 1, i + h)
                let s = cum[hi + 1] - cum[lo] == 0 ? 1.0 : 1 - (cum[hi + 1] - cum[lo]) / Double(hi - lo + 1)
                g = min(s, g + (1 - g) * alpha)
                if g < 1 { out[i] = Float(Double(out[i]) * g); total[i] *= g }
            }
        }
        return (out, total)
    }

    /// What `process` produced for one line.
    public struct Processed: Sendable {
        public var pcm: PCMAudio
        /// Total gain (dB, plain gain plus any make-up), class loudness (LUFS) before it and after limiting, true peak (dBTP).
        public var gainDB, before, after, truePeak: Double
        /// The limiter's deepest reduction (dB, ≥ 0); 0 when it did nothing.
        public var maxGainReductionDB: Double
        /// Samples trimmed at the head and the tail.
        public var head, tail: Int
    }

    /// Resample → trim → one gain to −16 LUFS → limiter → clip guard → true-peak check → ±1 LU check, for one line.
    /// If limiting leaves the loudness under `targetLUFS − toleranceLU`, one make-up gain correction is applied to the
    /// unlimited audio and it is limited again (2 passes at most). `limiter: nil` turns the limiter off (a test seam for
    /// the clip guard; the bake always passes the script's). `checks: false` skips the three refusals so a test can see
    /// what the plain gain would give; the bake never passes it. Every refusal names `file`.
    ///
    /// Example:
    /// ```swift
    /// let p = try VoiceBake.process(pcm, file: "voice/en-us/vo_en-us_word_x.caf", trim: script.trim, limiter: script.limiter)
    /// ```
    public static func process(_ pcm: PCMAudio, file: String, trim: VoiceScript.Trim, limiter: VoiceScript.Limiter?,
                               checks: Bool = true) throws -> Processed {
        let buf = try resampled(pcm, file: file)
        let raw = Array(UnsafeBufferPointer(start: buf.floatChannelData![0], count: Int(buf.frameLength)))
        let t = try trimSilence(raw, sampleRate: sampleRate, trim: trim, file: file)
        let before = LoudnessMeter.measure(t.samples, sampleRate: sampleRate, truePeak: false)
        guard before.classLUFS.isFinite else { throw VoiceBakeError(file: file, reason: "silent or fully gated: no loudness to normalise") }
        var gainDB = targetLUFS - before.classLUFS
        var out: [Float] = [], reduction = 0.0, after = -Double.infinity
        for pass in 0..<2 {
            let g = pow(10, gainDB / 20)
            out = t.samples.map { Float(Double($0) * g) }
            reduction = 0
            if let limiter {
                let l = limit(out, sampleRate: sampleRate, limiter: limiter)
                out = l.samples
                reduction = -20 * log10(l.gain.min() ?? 1)
            }
            after = LoudnessMeter.measure(out, sampleRate: sampleRate, truePeak: false).classLUFS
            if pass == 0 && limiter != nil && after < targetLUFS - toleranceLU && after.isFinite { gainDB += targetLUFS - after } else { break }
        }
        if checks, let i = out.firstIndex(where: { abs($0) > 1.0 }) {
            throw VoiceBakeError(file: file, reason: "clip guard: sample \(i) is \(out[i]) after a \(gainDB) dB gain to \(targetLUFS) LUFS (|x| > 1.0)")
        }
        let peak = LoudnessMeter.truePeak(out)
        guard !checks || peak <= truePeakCeilingDBTP else {
            throw VoiceBakeError(file: file, reason: "true peak \(peak) dBTP is over \(truePeakCeilingDBTP) dBTP at \(targetLUFS) LUFS")
        }
        guard !checks || abs(after - targetLUFS) <= toleranceLU else {
            throw VoiceBakeError(file: file, reason: "\(after) LUFS after normalising and limiting, outside \(targetLUFS) ±\(toleranceLU) LU")
        }
        return Processed(pcm: PCMAudio(samples: out, sampleRate: sampleRate), gainDB: gainDB, before: before.classLUFS, after: after,
                         truePeak: peak, maxGainReductionDB: max(0, reduction), head: t.head, tail: t.tail)
    }

    /// The A7 gate on the WRITTEN file (Audio R8): decodes the 16-bit CAF at `url` and measures it with `LoudnessMeter`.
    /// Throws, naming `file`, unless the class loudness is within `targetLUFS` ±`toleranceLU` and the true peak is ≤
    /// `truePeakCeilingDBTP`. Returns the decoded figures (LUFS, dBTP).
    ///
    /// Example:
    /// ```swift
    /// let (lufs, peak) = try VoiceBake.gateWrittenFile(at: url, file: "voice/en-us/vo_en-us_letter_a.caf")
    /// ```
    public static func gateWrittenFile(at url: URL, file: String) throws -> (lufs: Double, truePeakDBTP: Double) {
        let samples: [Float]
        do {
            let f = try AVAudioFile(forReading: url)
            guard f.length > 0, let buf = AVAudioPCMBuffer(pcmFormat: f.processingFormat, frameCapacity: AVAudioFrameCount(f.length)) else {
                throw VoiceBakeError(file: file, reason: "written file decodes to no audio")
            }
            try f.read(into: buf)
            samples = Array(UnsafeBufferPointer(start: buf.floatChannelData![0], count: Int(buf.frameLength)))
        } catch let e as VoiceBakeError { throw e } catch { throw VoiceBakeError(file: file, reason: "cannot decode the written file: \(error)") }
        let m = LoudnessMeter.measure(samples, sampleRate: sampleRate)
        let peak = m.truePeakDBTP ?? .infinity
        guard abs(m.classLUFS - targetLUFS) <= toleranceLU else {
            throw VoiceBakeError(file: file, reason: "written file measures \(m.classLUFS) LUFS, outside \(targetLUFS) ±\(toleranceLU) LU (A7)")
        }
        guard peak <= truePeakCeilingDBTP else {
            throw VoiceBakeError(file: file, reason: "written file true peak \(peak) dBTP is over \(truePeakCeilingDBTP) dBTP (A7)")
        }
        return (m.classLUFS, peak)
    }

    /// SHA-256 (hex) of everything that decides a line's rendered audio: the locale, line id, the TTS text (after
    /// respelling), the engine pins (name, package, weights revision, voice, language, speed), the trim values, the
    /// limiter values (with its internal margin and pass count), the loudness target, the encode settings and the bake tool name and version. Staleness recomputes it (ADR-0003 D4:
    /// Kokoro cannot run in `validate`, so the inputs stand in for the re-render). A change to the tool's output for the
    /// same inputs must bump `SVGBake.toolVersion`.
    ///
    /// Example:
    /// ```swift
    /// let h = VoiceBake.inputHash(line: line, script: script)   // 64 hex characters
    /// ```
    public static func inputHash(line: Line, script: VoiceScript) -> String {
        let e = script.engine, t = script.trim
        let bytes = JSONValue.object([
            "baker": .string("\(SVGBake.toolName) \(SVGBake.toolVersion)"),
            "encode": .object(["bitDepth": .number(Double(bitDepth)), "channels": .number(Double(channels)), "sampleRate": .number(sampleRate)]),
            "engine": .object(["langCode": .string(e.langCode), "name": .string(e.name), "package": .string(e.package),
                               "speed": .number(e.speed), "voice": .string(e.voice), "weightsRevision": .string(e.weightsRevision)]),
            "limiter": .object(["ceilingDBTP": .number(script.limiter.ceilingDBTP), "lookaheadSeconds": .number(script.limiter.lookaheadSeconds),
                                "marginDB": .number(limiterMarginDB), "maxPasses": .number(Double(limiterMaxPasses)),
                                "releaseSeconds": .number(script.limiter.releaseSeconds), "warnReductionDB": .number(script.limiter.warnReductionDB)]),
            "lineId": .string(line.lineId), "locale": .string(script.locale),
            "target": .object(["classLUFS": .number(targetLUFS), "toleranceLU": .number(toleranceLU), "truePeakCeilingDBTP": .number(truePeakCeilingDBTP)]),
            "text": .string(line.text),
            "trim": .object(["fadeSeconds": .number(t.fadeSeconds), "padSeconds": .number(t.padSeconds), "thresholdDBFS": .number(t.thresholdDBFS)]),
        ]).render()
        return SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
    }

    /// The provenance file bytes (K-41): engine settings, versions the engine reported, the espeak-ng fallback as a
    /// build-time tool, the encode settings, the trim and loudness targets, the bake tool, the line ids (respelled ones
    /// listed, texts not) and per line the input and file hashes and the measurements (story 004; read by staleness).
    static func provenance(script: VoiceScript, engine: TTSEngine, lines: [Line], reports: [LineReport]) -> [UInt8] {
        let facts = engine.reportedFacts()
        let e = script.engine, t = script.trim
        var perLine: [String: JSONValue] = [:]
        for r in reports {
            perLine[r.lineId] = .object([
                "durationSeconds": .number(r.duration), "fileLUFS": .number(r.fileLUFS), "fileSha256": .string(r.fileSha256),
                "fileTruePeakDBTP": .number(r.fileTruePeakDBTP), "gainDB": .number(r.gainDB), "maxGainReductionDB": .number(r.maxGainReductionDB),
                "inputSha256": .string(r.inputSha256), "loudnessAfterLUFS": .number(r.loudnessAfter),
                "loudnessBeforeLUFS": .number(r.loudnessBefore), "trimHeadSeconds": .number(r.trimmedHead),
                "trimTailSeconds": .number(r.trimmedTail), "truePeakDBTP": .number(r.truePeakDBTP),
            ])
        }
        return JSONValue.object([
            "baker": .string("\(SVGBake.toolName) \(SVGBake.toolVersion)"),
            "encode": .object(["bitDepth": .number(Double(bitDepth)), "channels": .number(Double(channels)),
                               "codec": .string("lpcm"), "container": .string("caf"), "sampleRate": .number(sampleRate)]),
            "engine": .object(["langCode": .string(e.langCode), "name": .string(e.name), "package": .string(e.package),
                               "speed": .number(e.speed), "voice": .string(e.voice), "weightsRevision": .string(e.weightsRevision)]),
            "espeakNg": .object(["role": .string("build-time tool only, never shipped (misaki G2P fallback)"),
                                 "version": .string(facts["espeak-ng"] ?? "not reported")]),
            "limiter": .object(["ceilingDBTP": .number(script.limiter.ceilingDBTP), "lookaheadSeconds": .number(script.limiter.lookaheadSeconds),
                                "marginDB": .number(limiterMarginDB), "maxPasses": .number(Double(limiterMaxPasses)),
                                "releaseSeconds": .number(script.limiter.releaseSeconds), "warnReductionDB": .number(script.limiter.warnReductionDB)]),
            "lines": .array(lines.map { .string($0.lineId) }),
            "locale": .string(script.locale),
            "perLine": .object(perLine),
            "reportedByEngine": .object(facts.mapValues { .string($0) }),
            "respelled": .array(lines.filter(\.respelled).map { .string($0.lineId) }),
            "target": .object(["classLUFS": .number(targetLUFS), "toleranceLU": .number(toleranceLU), "truePeakCeilingDBTP": .number(truePeakCeilingDBTP)]),
            "trim": .object(["fadeSeconds": .number(t.fadeSeconds), "padSeconds": .number(t.padSeconds), "thresholdDBFS": .number(t.thresholdDBFS)]),
            "ttsEngine": .string(engine.name),
        ]).render()
    }

    /// What `bakeThemeReport` did: the paths written (relative to the theme folder, sorted), the measured durations
    /// (locale → line id → seconds, 3 decimals) and the per-line reports.
    public struct BakeResult: Sendable {
        public var written: [String]
        public var durations: [String: [String: Double]]
        public var lines: [String: [LineReport]]
        /// One line per voice file whose limiter reduction exceeded `warnReductionDB`:
        /// `WARNING <file>: limiter reduced N dB (> W, not transparent)`. Warnings, never failures.
        public var warnings: [String]
    }

    /// Bakes one theme's voice into `<themeDir>/voice/<locale>/` for every locale in `theme.voiceLocales`, reading
    /// `<themeDir>/src/voice-scripts/<locale>.json`. Per line: render → resample → trim → gain to −16 LUFS → limiter →
    /// clip guard → true-peak and loudness checks → CAF write → the A7 gate on the decoded file (`gateWrittenFile`); the
    /// decoded duration is then measured from the written file. Returns the written paths relative
    /// to `themeDir`, sorted. When `<themeDir>/theme.json` exists its `voiceDurations` is rewritten (only that object).
    public static func bakeTheme(themeDir: URL, theme: ThemeModel, engineFor: (VoiceScript) throws -> TTSEngine) throws -> [String] {
        try bakeThemeReport(themeDir: themeDir, theme: theme, engineFor: engineFor).written
    }

    /// As `bakeTheme`, also returning the measured durations and per-line reports. Nothing is written to the theme unless
    /// every line of every locale succeeds.
    ///
    /// Example:
    /// ```swift
    /// let r = try VoiceBake.bakeThemeReport(themeDir: dir, theme: model) { KokoroProcessEngine(python: py, settings: $0.engine) }
    /// // r.durations["en-us"]?["word_triceratops"] == 0.912
    /// ```
    public static func bakeThemeReport(themeDir: URL, theme: ThemeModel, engineFor: (VoiceScript) throws -> TTSEngine) throws -> BakeResult {
        let fm = FileManager.default
        let stage = fm.temporaryDirectory.appendingPathComponent("voicebake-\(UUID().uuidString)")
        try fm.createDirectory(at: stage, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: stage) }
        var staged: [String] = [], durations: [String: [String: Double]] = [:], allReports: [String: [LineReport]] = [:], warnings: [String] = []
        for loc in theme.voiceLocales {
            let label = "src/voice-scripts/\(loc).json"
            guard let data = fm.contents(atPath: themeDir.appendingPathComponent(label).path) else {
                throw VoiceBakeError(file: label, reason: "missing (locale \(loc) is in voiceLocales)")
            }
            let script = try VoiceScript.parse(data, label: label)
            guard script.locale == loc else { throw VoiceBakeError(file: label, reason: "locale is \(script.locale), expected \(loc)") }
            let engine = try engineFor(script)
            let lines = try Self.lines(theme: theme, script: script)
            try fm.createDirectory(at: stage.appendingPathComponent("voice/\(loc)"), withIntermediateDirectories: true)
            var reports: [LineReport] = []
            for line in lines {
                let rel = KeyTable.voicePath(loc, line.kind, line.id)
                let url = stage.appendingPathComponent(rel)
                do {
                    let p = try process(try engine.render(text: line.text), file: rel, trim: script.trim, limiter: script.limiter)
                    try encode(p.pcm, to: url)
                    let gate = try gateWrittenFile(at: url, file: rel)
                    if p.maxGainReductionDB > script.limiter.warnReductionDB {
                        warnings.append("WARNING \(rel): limiter reduced \(String(format: "%.2f", p.maxGainReductionDB)) dB (> \(SVGNumber.format(script.limiter.warnReductionDB)), not transparent)")
                    }
                    let f = try AVAudioFile(forReading: url)
                    let seconds = (Double(f.length) / f.processingFormat.sampleRate * 1000).rounded() / 1000
                    let bytes = try Data(contentsOf: url)
                    reports.append(LineReport(lineId: line.lineId, path: rel, duration: seconds, trimmedHead: Double(p.head) / sampleRate,
                                              trimmedTail: Double(p.tail) / sampleRate, loudnessBefore: p.before, loudnessAfter: p.after,
                                              gainDB: p.gainDB, truePeakDBTP: p.truePeak, maxGainReductionDB: p.maxGainReductionDB,
                                              fileLUFS: gate.lufs, fileTruePeakDBTP: gate.truePeakDBTP, inputSha256: inputHash(line: line, script: script),
                                              fileSha256: SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()))
                }
                catch let e as VoiceBakeError { throw e }
                catch { throw VoiceBakeError(file: rel, reason: "\(error)") }
                staged.append(rel)
            }
            durations[loc] = Dictionary(uniqueKeysWithValues: reports.map { ($0.lineId, $0.duration) })
            allReports[loc] = reports
            let prov = "voice/\(loc)/provenance.json"
            try Data(provenance(script: script, engine: engine, lines: lines, reports: reports)).write(to: stage.appendingPathComponent(prov))
            staged.append(prov)
        }
        // theme.json: voiceDurations is tool-written (ADR-0003 D4). Only that object is replaced, so the rest of the file
        // keeps its bytes. Staged here so a failure leaves the theme untouched.
        if let bytes = fm.contents(atPath: themeDir.appendingPathComponent("theme.json").path) {
            let out = try ThemeFile.replacingVoiceDurations(in: [UInt8](bytes), with: durations)
            try Data(out).write(to: stage.appendingPathComponent("theme.json"))
            staged.append("theme.json")
        }
        for rel in staged {
            let dest = themeDir.appendingPathComponent(rel)
            try fm.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
            if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }
            try fm.copyItem(at: stage.appendingPathComponent(rel), to: dest)
        }
        return BakeResult(written: staged.sorted(), durations: durations, lines: allReports, warnings: warnings)
    }

    /// Bakes every theme under `<contentDir>/themes/*` that has a `theme.json`; a theme holding only `src/` is skipped
    /// and listed in `skipped`. Returns written paths relative to `contentDir` and the limiter warnings (paths likewise).
    public static func bakeContent(contentDir: URL, engineFor: (VoiceScript) throws -> TTSEngine) throws -> (written: [String], skipped: [String], warnings: [String]) {
        let fm = FileManager.default
        var written: [String] = [], skipped: [String] = [], warnings: [String] = []
        let ids = ((try? fm.contentsOfDirectory(atPath: contentDir.appendingPathComponent("themes").path)) ?? []).sorted()
        for id in ids {
            let dir = contentDir.appendingPathComponent("themes/\(id)")
            guard let bytes = fm.contents(atPath: dir.appendingPathComponent("theme.json").path) else { skipped.append(id); continue }
            let theme: ThemeModel
            do { theme = try ThemeDecoder.decode([UInt8](bytes)) }
            catch { throw VoiceBakeError(file: "themes/\(id)/theme.json", reason: "\(error)") }
            let r = try bakeThemeReport(themeDir: dir, theme: theme, engineFor: engineFor)
            written += r.written.map { "themes/\(id)/\($0)" }
            warnings += r.warnings.map { $0.replacingOccurrences(of: "WARNING ", with: "WARNING themes/\(id)/") }
        }
        return (written, skipped, warnings)
    }
}

// MARK: No speech synthesis in the app (Audio R8)

/// A plain-text scan of app sources for run-time speech-synthesis APIs (TR-audio-006). The PKC binary scan covers the
/// built app later.
///
/// Example:
/// ```swift
/// let hits = SpeechAPIScan.scan(directory: URL(fileURLWithPath: "apple/LetterMorph"))   // ["StageView.swift:12: AVSpeechSynthesizer"]
/// ```
public enum SpeechAPIScan {
    /// The names that must not appear.
    public static let forbidden = ["AVSpeechSynthesizer", "NSSpeechSynthesizer", "AVSpeechUtterance"]

    /// `path-relative-to-directory:line: name` for every occurrence in `.swift .m .mm .h` files, sorted by path and line.
    public static func scan(directory: URL) -> [String] {
        let fm = FileManager.default
        guard let e = fm.enumerator(at: directory, includingPropertiesForKeys: nil) else { return [] }
        var files: [URL] = []
        for case let u as URL in e where ["swift", "m", "mm", "h"].contains(u.pathExtension) { files.append(u) }
        var hits: [String] = []
        for u in files.sorted(by: { $0.path < $1.path }) {
            guard let text = try? String(contentsOf: u, encoding: .utf8) else { continue }
            let rel = String(u.resolvingSymlinksInPath().path.dropFirst(directory.resolvingSymlinksInPath().path.count)).drop { $0 == "/" }
            for (i, l) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
                for name in forbidden where l.contains(name) { hits.append("\(rel):\(i + 1): \(name)") }
            }
        }
        return hits
    }
}
