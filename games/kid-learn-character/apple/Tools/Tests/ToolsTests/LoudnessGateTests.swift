import AVFoundation
import ContractKit
import Foundation
import KidCore
import ToolsCore
import XCTest

/// Shared fixtures for the story-004 tests: a tone engine with controllable length, lead/tail silence and level; a
/// 3-key theme; temp theme folders with a voice script (trim data in the script).
enum GateFixture {
    /// A 48 kHz sine (440 Hz) per text: `seconds[text]` long (default `defaultSeconds`), `lead`/`tail` seconds of digital
    /// silence around it, peak `amp`; `spike` adds one full-scale-ish sample in the middle.
    final class ToneEngine: TTSEngine {
        let name = "fake-tone"
        var seconds: [String: Double] = [:], defaultSeconds = 0.5, lead = 0.0, tail = 0.0, amp: Float = 0.3, spike: Float? = nil
        init() {}
        func render(text: String) throws -> PCMAudio {
            let rate = 48_000.0, n = Int(((seconds[text] ?? defaultSeconds) * rate).rounded())
            var s = [Float](repeating: 0, count: Int(lead * rate)) + (0..<n).map { amp * Float(sin(2 * Double.pi * 440 * Double($0) / rate)) }
            if let spike { s[s.count / 2] = spike }
            s += [Float](repeating: 0, count: Int(tail * rate))
            return PCMAudio(samples: s, sampleRate: rate)
        }
        func reportedFacts() -> [String: String] { [:] }
    }

    static func item(_ n: Int, word: String, say: String, kind: String, id: String, wordId: String) -> ThemeItem {
        ThemeItem(castId: "c\(n)", name: word, word: word, say: say, sound: nil, family: "f", variant: "v\(n)", hueSlot: "rose",
                  art: "a", silhouette: "s", sfx: nil, voice: [kind: id, "word": wordId], weight: nil)
    }

    static var theme: ThemeModel {
        ThemeModel(schemaVersion: 1, contentVersion: "t", id: "test", assetPrefix: nil, name: "Test", voiceLocales: ["en-us"],
                   glyphSet: "fredoka600", families: [:],
                   countedItem: CountedItem(castId: "x", singular: "s", plural: "p", emptyCastId: "e", emptyWord: "w"),
                   soundExceptions: [:], voiceDurations: [:], titleCastId: nil, rowWords: nil,
                   keys: ["C": [item(1, word: "triceratops", say: "see", kind: "letter", id: "c", wordId: "triceratops")],
                          "3": [item(2, word: "three baby dinosaurs", say: "three", kind: "number", id: "3", wordId: "three_baby_dinosaurs")],
                          "A": [item(3, word: "ankylosaurus", say: "A.", kind: "letter", id: "a", wordId: "ankylosaurus")]])
    }

    static let scriptJSON = """
        {"schemaVersion": 1, "locale": "en-us",
         "engine": {"name": "Kokoro-82M", "package": "kokoro==0.9.4", "weightsRevision": "rev123", "voice": "af_heart", "langCode": "a", "speed": 0.88},
         "trim": {"thresholdDBFS": -50, "padSeconds": 0.02, "fadeSeconds": 0.005},
         "limiter": {"ceilingDBTP": -1.0, "lookaheadSeconds": 0.005, "releaseSeconds": 0.05, "warnReductionDB": 6.0},
         "respell": {"word_ankylosaurus": "ankie low saurus"}}
        """

    /// A temp theme folder with the voice script (`json`), removed at teardown.
    static func themeDir(_ test: XCTestCase, script json: String = scriptJSON) throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("gate-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir.appendingPathComponent("src/voice-scripts"), withIntermediateDirectories: true)
        try Data(json.utf8).write(to: dir.appendingPathComponent("src/voice-scripts/en-us.json"))
        test.addTeardownBlock { try? FileManager.default.removeItem(at: dir) }
        return dir
    }

    static func samples(_ url: URL) throws -> [Float] {
        let f = try AVAudioFile(forReading: url)
        let buf = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: f.processingFormat, frameCapacity: AVAudioFrameCount(f.length)))
        try f.read(into: buf)
        return Array(UnsafeBufferPointer(start: try XCTUnwrap(buf.floatChannelData)[0], count: Int(buf.frameLength)))
    }
}

/// Content-pipeline story 004 part A: silence trim, loudness to the voice target, clip guard, `voiceDurations` and the
/// V15 limits end to end (Key Table AC-14). Fake engines only; temp dirs.
final class LoudnessGateTests: XCTestCase {
    typealias Tone = GateFixture.ToneEngine
    func path(_ r: String) -> String { "voice/en-us/vo_en-us_\(r).caf" }

    // MARK: trim

    func test_a_line_with_400ms_of_silence_each_end_is_trimmed_to_the_tone_plus_pad_and_faded() throws {
        let dir = try GateFixture.themeDir(self), e = Tone()
        e.lead = 0.4; e.tail = 0.4; e.defaultSeconds = 0.5
        _ = try VoiceBake.bakeTheme(themeDir: dir, theme: GateFixture.theme) { _ in e }
        for line in ["letter_c", "word_triceratops"] {
            let s = try GateFixture.samples(dir.appendingPathComponent(path(line)))
            let seconds = Double(s.count) / 48_000
            // tone + 20 ms pad each side, within one 10 ms window of slack per end.
            XCTAssertGreaterThanOrEqual(seconds, 0.5 + 0.04 - 0.001, line)
            XCTAssertLessThanOrEqual(seconds, 0.5 + 0.04 + 0.02 + 0.001, line)
            XCTAssertEqual(s.first, 0, "fade-in starts at 0: \(line)")
            XCTAssertEqual(s.last, 0, "fade-out ends at 0: \(line)")
            XCTAssertGreaterThan(abs(s[s.count / 2]) + abs(s[s.count / 2 + 1]), 0)
        }
    }

    func test_trimSilence_keeps_pad_and_fades_with_the_script_values() throws {
        let trim = VoiceScript.Trim(thresholdDBFS: -50, padSeconds: 0.02, fadeSeconds: 0.005)
        var x = [Float](repeating: 0, count: 48_000)
        for i in 24_000..<28_800 { x[i] = 0.3 * Float(sin(2 * Double.pi * 440 * Double(i) / 48_000)) }
        let r = try VoiceBake.trimSilence(x, sampleRate: 48_000, trim: trim, file: "f.caf")
        XCTAssertEqual(r.head, 24_000 - 960)
        XCTAssertEqual(r.tail, 48_000 - 28_800 - 960, accuracy: 480)
        XCTAssertEqual(r.samples.first, 0); XCTAssertEqual(r.samples.last, 0)
        XCTAssertEqual(r.samples[240], x[r.head + 240], "after the 5 ms fade the samples are untouched")
    }

    func test_a_line_of_all_silence_is_refused_naming_the_file() throws {
        let dir = try GateFixture.themeDir(self), e = Tone()
        e.amp = 0
        XCTAssertThrowsError(try VoiceBake.bakeTheme(themeDir: dir, theme: GateFixture.theme) { _ in e }) { err in
            let f = (err as? VoiceBakeError)?.file ?? ""
            XCTAssertTrue(f.hasPrefix("voice/en-us/vo_en-us_"), f)
            XCTAssertTrue((err as? VoiceBakeError)?.reason.contains("all silence") ?? false, "\(err)")
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: dir.appendingPathComponent("voice").path), "nothing is written")
    }

    func test_the_voice_script_trim_block_is_required_and_bounded() throws {
        func parse(_ trim: String) -> String {
            let json = GateFixture.scriptJSON.replacingOccurrences(of: "\"trim\": {\"thresholdDBFS\": -50, \"padSeconds\": 0.02, \"fadeSeconds\": 0.005},", with: trim)
            do { _ = try VoiceScript.parse(Data(json.utf8), label: "en-us.json"); return "ok" }
            catch let e as VoiceBakeError { return e.reason } catch { return "\(error)" }
        }
        XCTAssertEqual(parse("\"trim\": {\"thresholdDBFS\": -50, \"padSeconds\": 0.02, \"fadeSeconds\": 0.005},"), "ok")
        XCTAssertTrue(parse("").hasPrefix("trim: missing"))
        XCTAssertTrue(parse("\"trim\": {\"thresholdDBFS\": 3, \"padSeconds\": 0.02, \"fadeSeconds\": 0.005},").hasPrefix("trim.thresholdDBFS"))
        XCTAssertTrue(parse("\"trim\": {\"thresholdDBFS\": -50, \"padSeconds\": -1, \"fadeSeconds\": 0.005},").hasPrefix("trim.padSeconds"))
        XCTAssertTrue(parse("\"trim\": {\"thresholdDBFS\": -50, \"padSeconds\": 0.02},").hasPrefix("trim.fadeSeconds"))
    }

    // MARK: normalisation

    func test_every_line_measures_minus_16_LUFS_within_1_LU_and_under_the_true_peak_ceiling() throws {
        for amp in [Float(0.03), 0.9] {
            let dir = try GateFixture.themeDir(self), e = Tone()
            e.amp = amp; e.seconds = ["A.": 0.2, "ankie low saurus": 1.1]   // one momentary-only line, one long
            _ = try VoiceBake.bakeTheme(themeDir: dir, theme: GateFixture.theme) { _ in e }
            for line in ["letter_a", "letter_c", "number_3", "word_ankylosaurus", "word_three_baby_dinosaurs", "word_triceratops"] {
                let s = try GateFixture.samples(dir.appendingPathComponent(path(line)))
                let m = LoudnessMeter.measure(s, sampleRate: 48_000)
                XCTAssertEqual(m.classLUFS, -16, accuracy: 1.0, "\(line) amp \(amp)")
                XCTAssertLessThanOrEqual(m.truePeakDBTP ?? 0, VoiceBake.truePeakCeilingDBTP, "\(line) amp \(amp)")
            }
        }
    }

    // MARK: clip guard

    /// The clip guard is a backstop behind the limiter: with the limiter on, no gain can reach it. It is proven through
    /// the `limiter: nil` seam of `VoiceBake.process` (the bake always passes the script's limiter).
    func test_with_the_limiter_off_a_line_whose_gain_would_clip_is_refused_naming_the_file() throws {
        let e = Tone()
        e.amp = 0.01; e.spike = 0.95   // quiet tone, one loud sample: the gain to -16 LUFS puts the spike past full scale
        let file = "voice/en-us/vo_en-us_word_x.caf"
        XCTAssertThrowsError(try VoiceBake.process(try e.render(text: "x"), file: file, trim: trim, limiter: nil)) { err in
            XCTAssertEqual((err as? VoiceBakeError)?.file, file)
            XCTAssertTrue((err as? VoiceBakeError)?.reason.hasPrefix("clip guard") ?? false, "\(err)")
        }
    }

    // MARK: limiter

    let trim = VoiceScript.Trim(thresholdDBFS: -50, padSeconds: 0.02, fadeSeconds: 0.005)
    let limiter = VoiceScript.Limiter(ceilingDBTP: -1, lookaheadSeconds: 0.005, releaseSeconds: 0.05, warnReductionDB: 6)

    func provenanceLine(_ dir: URL, _ line: String) throws -> [String: Any] {
        let o = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: dir.appendingPathComponent("voice/en-us/provenance.json"))) as? [String: Any])
        return try XCTUnwrap((o["perLine"] as? [String: Any])?[line] as? [String: Any])
    }

    func test_a_line_whose_plain_gain_passes_the_ceiling_is_limited_to_minus_16_LUFS_under_minus_1_dBTP_and_records_it() throws {
        let e = Tone()
        e.amp = 0.1; e.spike = 0.6   // a speech-like crest: the spike sits ~15 dB over the tone's peak
        let plain = try VoiceBake.process(try e.render(text: "x"), file: "x.caf", trim: trim, limiter: nil, checks: false)
        XCTAssertGreaterThan(plain.truePeak, -1, "the plain gain alone would pass the ceiling")
        let dir = try GateFixture.themeDir(self)
        let r = try VoiceBake.bakeThemeReport(themeDir: dir, theme: GateFixture.theme) { _ in e }
        XCTAssertEqual(r.warnings, [], "under 6 dB is not flagged")
        for line in ["letter_c", "word_triceratops"] {
            let s = try GateFixture.samples(dir.appendingPathComponent(path(line)))
            let m = LoudnessMeter.measure(s, sampleRate: 48_000)
            XCTAssertEqual(m.classLUFS, -16, accuracy: 1, line)
            XCTAssertLessThanOrEqual(m.truePeakDBTP ?? 0, -1, line)
            let red = try XCTUnwrap(try provenanceLine(dir, line)["maxGainReductionDB"] as? Double)
            XCTAssertGreaterThan(red, 1, line); XCTAssertLessThan(red, 6, line)
        }
    }

    func test_a_line_needing_more_than_6_dB_of_reduction_is_flagged_as_a_warning_not_a_failure() throws {
        let dir = try GateFixture.themeDir(self), e = Tone()
        e.amp = 0.01; e.spike = 0.95
        let r = try VoiceBake.bakeThemeReport(themeDir: dir, theme: GateFixture.theme) { _ in e }
        XCTAssertEqual(r.warnings.count, 6, "\(r.warnings)")
        XCTAssertTrue(r.warnings.contains { $0.hasPrefix("WARNING voice/en-us/vo_en-us_word_triceratops.caf: limiter reduced ") && $0.hasSuffix(" dB (> 6, not transparent)") }, "\(r.warnings)")
        XCTAssertGreaterThan(try XCTUnwrap(try provenanceLine(dir, "word_triceratops")["maxGainReductionDB"] as? Double), 6)
    }

    func test_a_quiet_line_passes_the_limiter_untouched_identical_to_gain_only() throws {
        let e = Tone()   // a 0.3 sine: at -16 LUFS its true peak is ~-12 dBTP
        let on = try VoiceBake.process(try e.render(text: "x"), file: "x.caf", trim: trim, limiter: limiter)
        let off = try VoiceBake.process(try e.render(text: "x"), file: "x.caf", trim: trim, limiter: nil)
        XCTAssertEqual(on.maxGainReductionDB, 0)
        XCTAssertEqual(on.pcm.samples, off.pcm.samples)
        XCTAssertEqual(on.gainDB, off.gainDB)
    }

    func test_the_limiter_gain_has_no_step_falls_before_the_peak_and_never_exceeds_unity() throws {
        let n = 48_000, peakAt = 24_000
        var x = (0..<n).map { Float(0.5 * sin(2 * Double.pi * 440 * Double($0) / 48_000)) }
        x[peakAt] = 2.0
        let (y, g) = VoiceBake.limit(x, sampleRate: 48_000, limiter: limiter)
        let lookahead = Int(limiter.lookaheadSeconds * 48_000)
        let steps = zip(g.dropFirst(), g).map { abs($0 - $1) }
        XCTAssertLessThanOrEqual(steps.max() ?? 1, 2.0 / Double(lookahead), "no step: the change per sample is bounded")
        XCTAssertTrue(g.allSatisfy { $0 <= 1 })
        XCTAssertLessThan(g[peakAt - lookahead / 4], 1, "the gain is already falling before the peak")
        XCTAssertEqual(g[peakAt - 3 * lookahead], 1, "and untouched well before it")
        XCTAssertEqual(g[0], 1); XCTAssertEqual(g[n - 1], 1, accuracy: 1e-4, "released back toward unity: 0.5 s is 10 release time constants")
        XCTAssertLessThanOrEqual(LoudnessMeter.truePeak(y), -1 - VoiceBake.limiterMarginDB + 1e-6)
    }

    func test_the_A7_gate_measures_the_decoded_written_file() throws {
        let dir = try GateFixture.themeDir(self)
        _ = try VoiceBake.bakeThemeReport(themeDir: dir, theme: GateFixture.theme) { _ in Tone() }
        let url = dir.appendingPathComponent(path("letter_c"))
        let gate = try VoiceBake.gateWrittenFile(at: url, file: path("letter_c"))
        let decoded = LoudnessMeter.measure(try GateFixture.samples(url), sampleRate: 48_000)
        XCTAssertEqual(gate.lufs, decoded.classLUFS)
        XCTAssertEqual(gate.truePeakDBTP, decoded.truePeakDBTP)
        XCTAssertEqual(try XCTUnwrap(try provenanceLine(dir, "letter_c")["fileLUFS"] as? Double), decoded.classLUFS, accuracy: 0.0006)
        // A file whose float source never went through the bake: written too loud, the gate reads it and refuses it.
        let loud = dir.appendingPathComponent("loud.caf")
        try VoiceBake.encode(PCMAudio(samples: (0..<48_000).map { Float(0.8 * sin(2 * Double.pi * 440 * Double($0) / 48_000)) }, sampleRate: 48_000), to: loud)
        XCTAssertThrowsError(try VoiceBake.gateWrittenFile(at: loud, file: "voice/en-us/loud.caf")) { err in
            XCTAssertEqual((err as? VoiceBakeError)?.file, "voice/en-us/loud.caf")
            XCTAssertTrue((err as? VoiceBakeError)?.reason.hasPrefix("written file measures") ?? false, "\(err)")
        }
    }

    func test_the_voice_script_limiter_block_is_required_and_bounded() throws {
        let block = "\"limiter\": {\"ceilingDBTP\": -1.0, \"lookaheadSeconds\": 0.005, \"releaseSeconds\": 0.05, \"warnReductionDB\": 6.0},"
        func parse(_ lim: String) -> String {
            do { _ = try VoiceScript.parse(Data(GateFixture.scriptJSON.replacingOccurrences(of: block, with: lim).utf8), label: "en-us.json"); return "ok" }
            catch let e as VoiceBakeError { return e.reason } catch { return "\(error)" }
        }
        XCTAssertEqual(parse(block), "ok")
        XCTAssertTrue(parse("").hasPrefix("limiter: missing"))
        XCTAssertTrue(parse(block.replacingOccurrences(of: "-1.0", with: "0.5")).hasPrefix("limiter.ceilingDBTP"))
        XCTAssertTrue(parse(block.replacingOccurrences(of: "0.005", with: "0.5")).hasPrefix("limiter.lookaheadSeconds"))
        XCTAssertNotEqual(VoiceBake.inputHash(line: line, script: try script(block)),
                          VoiceBake.inputHash(line: line, script: try script(block.replacingOccurrences(of: "0.05,", with: "0.08,"))),
                          "the limiter is part of the input hash")
    }

    let line = VoiceBake.Line(kind: "word", id: "x", text: "x", respelled: false)
    func script(_ lim: String) throws -> VoiceScript {
        let block = "\"limiter\": {\"ceilingDBTP\": -1.0, \"lookaheadSeconds\": 0.005, \"releaseSeconds\": 0.05, \"warnReductionDB\": 6.0},"
        return try VoiceScript.parse(Data(GateFixture.scriptJSON.replacingOccurrences(of: block, with: lim).utf8), label: "s")
    }

    // MARK: voiceDurations, V15 (Key Table AC-14)

    let themeText = "{\n  \"id\": \"voiceDurations\",\n  \"voiceDurations\": {\n    \"en-us\": {}\n  },\n  \"other\": [1, {\"voiceDurations\": 7}]\n}\n"

    func test_voiceDurations_is_written_into_theme_json_from_the_files_and_only_that_object_changes() throws {
        let dir = try GateFixture.themeDir(self), e = Tone()
        e.seconds = ["see": 0.512, "triceratops": 0.912]
        try Data(themeText.utf8).write(to: dir.appendingPathComponent("theme.json"))
        let r = try VoiceBake.bakeThemeReport(themeDir: dir, theme: GateFixture.theme) { _ in e }
        XCTAssertTrue(r.written.contains("theme.json"))
        let out = try String(contentsOf: dir.appendingPathComponent("theme.json"), encoding: .utf8)
        XCTAssertTrue(out.hasPrefix("{\n  \"id\": \"voiceDurations\",\n  \"voiceDurations\": {\n    \"en-us\": {\n"), out)
        XCTAssertTrue(out.hasSuffix("\n  },\n  \"other\": [1, {\"voiceDurations\": 7}]\n}\n"), out)
        let o = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(out.utf8)) as? [String: Any])
        let d = try XCTUnwrap((o["voiceDurations"] as? [String: [String: Double]])?["en-us"])
        XCTAssertEqual(Set(d.keys), ["letter_a", "letter_c", "number_3", "word_ankylosaurus", "word_three_baby_dinosaurs", "word_triceratops"])
        for (line, sec) in d {
            let f = try AVAudioFile(forReading: dir.appendingPathComponent(path(line)))
            XCTAssertEqual(sec, Double(f.length) / f.processingFormat.sampleRate, accuracy: 0.01, line)
            XCTAssertEqual(sec, (sec * 1000).rounded() / 1000, accuracy: 1e-9, "3 decimals: \(line)")
        }
        XCTAssertEqual(d["letter_c"] ?? 0, 0.512, accuracy: 0.001)
        XCTAssertEqual(d["word_triceratops"] ?? 0, 0.912, accuracy: 0.001)
        XCTAssertEqual(r.durations["en-us"], d)
        // The same bake again rewrites the same bytes (stable formatting).
        _ = try VoiceBake.bakeTheme(themeDir: dir, theme: GateFixture.theme) { _ in e }
        XCTAssertEqual(try String(contentsOf: dir.appendingPathComponent("theme.json"), encoding: .utf8), out)
    }

    /// V15 on a baked theme folder, the theme's voiceDurations taken from the bake (what the tool writes).
    func v15(word: Double, letter: Double) throws -> (failed: [String], dir: URL) {
        let dir = try GateFixture.themeDir(self), e = Tone()
        e.seconds = ["triceratops": word, "see": letter, "A.": 0.4, "three": 0.4, "three baby dinosaurs": 0.8, "ankie low saurus": 0.8]
        var model = GateFixture.theme
        model.voiceDurations = try VoiceBake.bakeThemeReport(themeDir: dir, theme: model) { _ in e }.durations
        let facts = ThemeAssetFacts(folder: "test", otherThemePrefixes: [], probe: FileProbe(root: dir), silhouettePath: { _ in nil }, glyphPath: { _ in nil })
        let v = KeyTable.validate(model, glyphs: GlyphSetModel(id: "fredoka600", fontName: nil, fontVersion: nil, fontLicence: nil, baker: "", glyphs: [:]),
                                  assets: facts, singleItemPerKey: true)
        return ((v.failed[15] ?? []).map { ContentValidator.voiceFile(forV15Message: $0, locales: ["en-us"]).map { "\($0) <- \($0)" } ?? $0 }, dir)
    }

    func test_a_word_line_of_1_30_s_fails_V15_naming_the_file() throws {
        let r = try v15(word: 1.30, letter: 0.6)
        XCTAssertEqual(r.failed.count, 1, "\(r.failed)")
        XCTAssertTrue(r.failed[0].hasPrefix("voice/en-us/vo_en-us_word_triceratops.caf"), "\(r.failed)")
    }

    func test_a_letter_line_of_1_10_s_fails_V15_naming_the_file() throws {
        let r = try v15(word: 0.9, letter: 1.10)
        XCTAssertEqual(r.failed.count, 1, "\(r.failed)")
        XCTAssertTrue(r.failed[0].hasPrefix("voice/en-us/vo_en-us_letter_c.caf"), "\(r.failed)")
    }

    func test_lines_within_the_limits_pass_V15() throws {
        XCTAssertEqual(try v15(word: 1.2, letter: 0.9).failed, [])
    }
}
