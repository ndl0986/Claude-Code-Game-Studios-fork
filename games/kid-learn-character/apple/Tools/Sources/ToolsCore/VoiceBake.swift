import AVFoundation
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
    public var locale: String
    public var engine: EngineSettings
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
        let respell = (o["respell"] as? [String: Any]) ?? [:]
        var rs: [String: String] = [:]
        for (k, v) in respell {
            guard let s = v as? String, !s.isEmpty else { throw bad("respell.\(k): not a non-empty string") }
            rs[k] = s
        }
        return VoiceScript(locale: locale, engine: EngineSettings(name: try str("name"), package: try str("package"),
            weightsRevision: try str("weightsRevision"), voice: try str("voice"), langCode: try str("langCode"), speed: speed), respell: rs)
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

/// The build-time voice bake (TR-keytable-004 pre-rendered TTS + AAC mono, TR-audio-006 no run-time TTS; ADR-0003 D5/D6).
///
/// Per theme and per locale in `voiceLocales`: every voice line of every item (Key Table `voice` kind → id) is
/// rendered by the adapter and encoded to `voice/<locale>/vo_<locale>_<kind>_<id>.m4a` (`KeyTable.voicePath`). The text
/// of a line is the item's `word` for kind `word`, else its `say` (letter, number); `respell["<kind>_<id>"]` replaces it
/// for the TTS only (K-35). One line id used by several items is rendered once; if its text differs between items the
/// bake fails. Also writes `voice/<locale>/provenance.json` (byte-stable: sorted keys, no timestamps).
///
/// Encoding: AAC-LC, **mono, 48 000 Hz, 64 000 bit/s**, via `AVAudioFile` (Apple frameworks only, K-31). Engine audio
/// at another rate is resampled with `AVAudioConverter`. No trim, no loudness change (story 004).
/// Output is staged in a temp folder; nothing is written to the theme unless every line renders and encodes.
///
/// Example:
/// ```swift
/// let written = try VoiceBake.bakeTheme(themeDir: dir, theme: model) { script in KokoroProcessEngine(python: py, settings: script.engine) }
/// // ["voice/en-us/provenance.json", "voice/en-us/vo_en-us_letter_c.m4a", …]
/// ```
public enum VoiceBake {
    /// Output AAC sample rate (Hz), channel count and bit rate (bit/s): chosen here, not in the story or ADR.
    public static let sampleRate = 48_000.0, channels = 1, bitRate = 64_000

    /// One voice line.
    public struct Line: Equatable, Sendable {
        public var kind, id: String
        /// The text the engine is given (respelled when the script says so).
        public var text: String
        public var respelled: Bool
        /// `<kind>_<id>`, the key of `voiceDurations` and `respell`.
        public var lineId: String { kind + "_" + id }
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

    /// Encodes `pcm` to an AAC mono `.m4a` at `url`.
    public static func encode(_ pcm: PCMAudio, to url: URL) throws {
        let buf = try resampled(pcm, file: url.lastPathComponent)
        let settings: [String: Any] = [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: sampleRate,
                                       AVNumberOfChannelsKey: channels, AVEncoderBitRateKey: bitRate]
        do {
            let file = try AVAudioFile(forWriting: url, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false)
            try file.write(from: buf)   // the file is finalised when `file` goes out of scope at the end of this block
        } catch { throw VoiceBakeError(file: url.lastPathComponent, reason: "AAC encode failed: \(error)") }
        try zeroMP4Timestamps(url)
    }

    /// AVAudioFile stamps the MP4 movie, track and media headers (`mvhd`, `tkhd`, `mdhd`) with the encode time, so two
    /// bakes of the same audio differed in 12 header bytes while the decoded samples were identical. Zeroing the
    /// creation and modification times makes the voice files byte-stable like the other baked outputs (ADR-0003 D4).
    public static func zeroMP4Timestamps(_ url: URL) throws {
        var bytes = [UInt8](try Data(contentsOf: url))
        let file = url.lastPathComponent
        func u32(_ o: Int) -> Int { bytes[o..<o + 4].reduce(0) { $0 << 8 | Int($1) } }
        /// The child boxes of the payload `range`, walked by their size headers: (type, payload range, box start).
        /// Types match only at box boundaries, never at an arbitrary offset (game-dev-ios review).
        func children(_ range: Range<Int>) throws -> [(type: String, payload: Range<Int>, start: Int)] {
            var out: [(String, Range<Int>, Int)] = [], o = range.lowerBound
            while o + 8 <= range.upperBound {
                var size = u32(o), header = 8
                if size == 1 {   // a 64-bit size follows the type
                    guard o + 16 <= range.upperBound else { break }
                    size = bytes[o + 8..<o + 16].reduce(0) { $0 << 8 | Int($1) }; header = 16
                } else if size == 0 { size = range.upperBound - o }   // to the end of the parent
                guard size >= header, o + size <= range.upperBound else {
                    throw VoiceBakeError(file: file, reason: "malformed MP4 box at byte \(o)")
                }
                out.append((String(decoding: bytes[o + 4..<o + 8], as: UTF8.self), (o + header)..<(o + size), o))
                o += size
            }
            return out
        }
        /// A full box's version byte opens its payload; then creation and modification time, 4 bytes each in version 0
        /// and 8 in version 1.
        func zeroTimes(_ payload: Range<Int>, _ type: String) throws {
            let version = bytes[payload.lowerBound], width = version == 1 ? 8 : 4, start = payload.lowerBound + 4
            guard start + 2 * width <= payload.upperBound else { throw VoiceBakeError(file: file, reason: "\(type) too short") }
            for k in start..<(start + 2 * width) { bytes[k] = 0 }
        }
        guard let moov = try children(0..<bytes.count).first(where: { $0.type == "moov" }) else {
            throw VoiceBakeError(file: file, reason: "no moov box in the encoded file")
        }
        let inMoov = try children(moov.payload)
        guard let mvhd = inMoov.first(where: { $0.type == "mvhd" }) else { throw VoiceBakeError(file: file, reason: "no moov/mvhd") }
        try zeroTimes(mvhd.payload, "mvhd")
        let traks = inMoov.filter { $0.type == "trak" }
        guard !traks.isEmpty else { throw VoiceBakeError(file: file, reason: "no moov/trak") }
        for trak in traks {
            let inTrak = try children(trak.payload)
            guard let tkhd = inTrak.first(where: { $0.type == "tkhd" }) else { throw VoiceBakeError(file: file, reason: "no trak/tkhd") }
            try zeroTimes(tkhd.payload, "tkhd")
            guard let mdia = inTrak.first(where: { $0.type == "mdia" }),
                  let mdhd = try children(mdia.payload).first(where: { $0.type == "mdhd" }) else {
                throw VoiceBakeError(file: file, reason: "no trak/mdia/mdhd")
            }
            try zeroTimes(mdhd.payload, "mdhd")
        }
        try Data(bytes).write(to: url)
    }

    /// The provenance file bytes (K-41): engine settings, versions the engine reported, the espeak-ng fallback as a
    /// build-time tool, the encode settings, the bake tool, and the line ids (respelled ones listed, texts not).
    static func provenance(script: VoiceScript, engine: TTSEngine, lines: [Line]) -> [UInt8] {
        let facts = engine.reportedFacts()
        let e = script.engine
        return JSONValue.object([
            "baker": .string("\(SVGBake.toolName) \(SVGBake.toolVersion)"),
            "encode": .object(["bitRate": .number(Double(bitRate)), "channels": .number(Double(channels)),
                               "codec": .string("aac-lc"), "sampleRate": .number(sampleRate)]),
            "engine": .object(["langCode": .string(e.langCode), "name": .string(e.name), "package": .string(e.package),
                               "speed": .number(e.speed), "voice": .string(e.voice), "weightsRevision": .string(e.weightsRevision)]),
            "espeakNg": .object(["role": .string("build-time tool only, never shipped (misaki G2P fallback)"),
                                 "version": .string(facts["espeak-ng"] ?? "not reported")]),
            "lines": .array(lines.map { .string($0.lineId) }),
            "locale": .string(script.locale),
            "reportedByEngine": .object(facts.mapValues { .string($0) }),
            "respelled": .array(lines.filter(\.respelled).map { .string($0.lineId) }),
            "ttsEngine": .string(engine.name),
        ]).render()
    }

    /// Bakes one theme's voice into `<themeDir>/voice/<locale>/` for every locale in `theme.voiceLocales`, reading
    /// `<themeDir>/src/voice-scripts/<locale>.json`. Returns the written paths relative to `themeDir`, sorted.
    public static func bakeTheme(themeDir: URL, theme: ThemeModel, engineFor: (VoiceScript) throws -> TTSEngine) throws -> [String] {
        let fm = FileManager.default
        let stage = fm.temporaryDirectory.appendingPathComponent("voicebake-\(UUID().uuidString)")
        try fm.createDirectory(at: stage, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: stage) }
        var staged: [String] = []
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
            for line in lines {
                let rel = KeyTable.voicePath(loc, line.kind, line.id)
                do { try encode(try engine.render(text: line.text), to: stage.appendingPathComponent(rel)) }
                catch let e as VoiceBakeError { throw e }
                catch { throw VoiceBakeError(file: rel, reason: "\(error)") }
                staged.append(rel)
            }
            let prov = "voice/\(loc)/provenance.json"
            try Data(provenance(script: script, engine: engine, lines: lines)).write(to: stage.appendingPathComponent(prov))
            staged.append(prov)
        }
        for rel in staged {
            let dest = themeDir.appendingPathComponent(rel)
            try fm.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
            if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }
            try fm.copyItem(at: stage.appendingPathComponent(rel), to: dest)
        }
        return staged.sorted()
    }

    /// Bakes every theme under `<contentDir>/themes/*` that has a `theme.json`; a theme holding only `src/` is skipped
    /// and listed in `skipped`. Returns written paths relative to `contentDir`.
    public static func bakeContent(contentDir: URL, engineFor: (VoiceScript) throws -> TTSEngine) throws -> (written: [String], skipped: [String]) {
        let fm = FileManager.default
        var written: [String] = [], skipped: [String] = []
        let ids = ((try? fm.contentsOfDirectory(atPath: contentDir.appendingPathComponent("themes").path)) ?? []).sorted()
        for id in ids {
            let dir = contentDir.appendingPathComponent("themes/\(id)")
            guard let bytes = fm.contents(atPath: dir.appendingPathComponent("theme.json").path) else { skipped.append(id); continue }
            let theme: ThemeModel
            do { theme = try ThemeDecoder.decode([UInt8](bytes)) }
            catch { throw VoiceBakeError(file: "themes/\(id)/theme.json", reason: "\(error)") }
            written += try bakeTheme(themeDir: dir, theme: theme, engineFor: engineFor).map { "themes/\(id)/\($0)" }
        }
        return (written, skipped)
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
