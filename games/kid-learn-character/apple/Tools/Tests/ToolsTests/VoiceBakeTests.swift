import AVFoundation
import ContractKit
import Foundation
import KidCore
import ToolsCore
import XCTest

/// The voice bake (TR-keytable-004, TR-audio-006, ADR-0003 D5/D6, content-pipeline story 003) with FAKE engines.
/// No Python, no network; temp dirs only.
final class VoiceBakeTests: XCTestCase {
    /// A sine whose length follows the text length; records every text it was asked for.
    final class FakeEngine: TTSEngine {
        let name: String, rate: Double
        var texts: [String] = []
        init(name: String = "fake-a", rate: Double = 24000) { self.name = name; self.rate = rate }
        func render(text: String) throws -> PCMAudio {
            texts.append(text)
            let n = Int(rate * 0.05) * (text.count + 2)
            return PCMAudio(samples: (0..<n).map { 0.3 * sin(Float($0) * 0.05) }, sampleRate: rate)
        }
        func reportedFacts() -> [String: String] { ["kokoro": "0.0-fake", "misaki": "0.0-fake"] }
    }

    func item(_ n: Int, key: String, word: String, say: String, kind: String, id: String, wordId: String) -> ThemeItem {
        ThemeItem(castId: "c\(n)", name: word, word: word, say: say, sound: nil, family: "f", variant: "v\(n)", hueSlot: "rose",
                  art: "a", silhouette: "s", sfx: nil, voice: [kind: id, "word": wordId], weight: nil)
    }

    var theme: ThemeModel {
        ThemeModel(schemaVersion: 1, contentVersion: "t", id: "test", assetPrefix: nil, name: "Test", voiceLocales: ["en-us"],
                   glyphSet: "fredoka600", families: [:],
                   countedItem: CountedItem(castId: "x", singular: "s", plural: "p", emptyCastId: "e", emptyWord: "w"),
                   soundExceptions: [:], voiceDurations: [:], titleCastId: nil, rowWords: nil,
                   keys: ["C": [item(1, key: "C", word: "triceratops", say: "see", kind: "letter", id: "c", wordId: "triceratops")],
                          "3": [item(2, key: "3", word: "three baby dinosaurs", say: "three", kind: "number", id: "3", wordId: "three_baby_dinosaurs")],
                          "A": [item(3, key: "A", word: "ankylosaurus", say: "A.", kind: "letter", id: "a", wordId: "ankylosaurus")]])
    }

    func themeDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("voice-\(UUID().uuidString)")
        let scripts = dir.appendingPathComponent("src/voice-scripts")
        try FileManager.default.createDirectory(at: scripts, withIntermediateDirectories: true)
        let json = """
        {"schemaVersion": 1, "locale": "en-us",
         "engine": {"name": "Kokoro-82M", "package": "kokoro==0.9.4", "weightsRevision": "rev123", "voice": "af_heart", "langCode": "a", "speed": 0.88},
         "respell": {"word_ankylosaurus": "ankie low saurus"}}
        """
        try Data(json.utf8).write(to: scripts.appendingPathComponent("en-us.json"))
        addTeardownBlock { try? FileManager.default.removeItem(at: dir) }
        return dir
    }

    let expected = ["voice/en-us/provenance.json", "voice/en-us/vo_en-us_letter_a.m4a", "voice/en-us/vo_en-us_letter_c.m4a",
                    "voice/en-us/vo_en-us_number_3.m4a", "voice/en-us/vo_en-us_word_ankylosaurus.m4a",
                    "voice/en-us/vo_en-us_word_three_baby_dinosaurs.m4a", "voice/en-us/vo_en-us_word_triceratops.m4a"]

    // AC-1
    func test_every_named_voice_line_is_rendered_as_aac_mono_under_voice_locale_and_decodes() throws {
        let dir = try themeDir()
        let written = try VoiceBake.bakeTheme(themeDir: dir, theme: theme) { _ in FakeEngine() }
        XCTAssertEqual(written, expected)
        for rel in expected where rel.hasSuffix(".m4a") {
            XCTAssertTrue(FileManager.default.fileExists(atPath: dir.appendingPathComponent(rel).path), rel)
            let f = try AVAudioFile(forReading: dir.appendingPathComponent(rel))
            XCTAssertEqual(f.fileFormat.settings[AVFormatIDKey] as? UInt32, kAudioFormatMPEG4AAC, rel)
            XCTAssertEqual(f.fileFormat.channelCount, 1, rel)
            XCTAssertEqual(f.fileFormat.sampleRate, VoiceBake.sampleRate, rel)
            XCTAssertGreaterThan(f.length, 1000, "decodes to audio: \(rel)")
            let buf = AVAudioPCMBuffer(pcmFormat: f.processingFormat, frameCapacity: AVAudioFrameCount(f.length))!
            try f.read(into: buf)
            XCTAssertGreaterThan(buf.floatChannelData![0].withMemoryRebound(to: Float.self, capacity: Int(buf.frameLength)) { p in (0..<Int(buf.frameLength)).map { abs(p[$0]) }.max()! }, 0.05, rel)
        }
        // Every path of KeyTable.voicePath for the theme is among them.
        for it in theme.keys.values.flatMap({ $0 }) { for (k, id) in it.voice { XCTAssertTrue(written.contains(KeyTable.voicePath("en-us", k, id))) } }
    }

    // AC-2
    /// ADR-0003 marks the AAC priming and padding values NOT SOURCEABLE until a build proves them (game-dev-ios review):
    /// a sharp onset at frame 0 must decode with no priming lead and the same length, or every voice line would shift
    /// under ADR-0010 and bias V15. Checked for a 48 kHz source and for Kokoro's 24 kHz (resampled) source.
    func test_the_aac_encode_strips_priming_and_padding_so_onset_and_length_survive() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("priming-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        for sourceRate in [48_000.0, 24_000.0] {
            let n = Int(sourceRate)  // 1 s, a 1 kHz tone at half scale starting at frame 0
            let samples = (0..<n).map { Float(0.5 * sin(2 * Double.pi * 1000 * Double($0) / sourceRate)) }
            let url = dir.appendingPathComponent("onset-\(Int(sourceRate)).m4a")
            try VoiceBake.encode(PCMAudio(samples: samples, sampleRate: sourceRate), to: url)
            let f = try AVAudioFile(forReading: url)
            let rate = f.processingFormat.sampleRate
            let expected = Double(n) * rate / sourceRate
            XCTAssertLessThanOrEqual(abs(Double(f.length) - expected), 1024, "\(Int(sourceRate)) Hz: decoded \(f.length) frames vs \(expected)")
            let buf = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: f.processingFormat, frameCapacity: AVAudioFrameCount(f.length)))
            try f.read(into: buf)
            let ch = try XCTUnwrap(buf.floatChannelData)[0]
            let first = (0..<Int(buf.frameLength)).first { abs(ch[$0]) > 0.001 }  // −60 dBFS
            let onset = try XCTUnwrap(first, "\(Int(sourceRate)) Hz: no sample above −60 dBFS")
            XCTAssertLessThanOrEqual(Double(onset) / rate, 0.005, "\(Int(sourceRate)) Hz: onset at \(onset) frames (\(Double(onset) / rate * 1000) ms), a priming lead")
        }
    }

    func test_encoding_the_same_audio_twice_gives_identical_bytes() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("stable-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let pcm = PCMAudio(samples: (0..<24_000).map { Float(0.3 * sin(Double($0) * 0.05)) }, sampleRate: 24_000)
        let a = dir.appendingPathComponent("a.m4a"), b = dir.appendingPathComponent("b.m4a")
        try VoiceBake.encode(pcm, to: a)
        Thread.sleep(forTimeInterval: 1.1)   // cross a second boundary, so an encode-time stamp would differ
        try VoiceBake.encode(pcm, to: b)
        XCTAssertEqual(try Data(contentsOf: a), try Data(contentsOf: b), "the MP4 header timestamps are zeroed")
        XCTAssertNoThrow(try AVAudioFile(forReading: b), "the patched file still decodes")
    }

    func test_two_different_engines_produce_the_same_file_paths() throws {
        let a = try themeDir(), b = try themeDir()
        let pa = try VoiceBake.bakeTheme(themeDir: a, theme: theme) { _ in FakeEngine(name: "fake-a", rate: 24000) }
        let pb = try VoiceBake.bakeTheme(themeDir: b, theme: theme) { _ in FakeEngine(name: "fake-b", rate: 48000) }
        XCTAssertEqual(pa, pb)
        let listing = { (d: URL) in (try FileManager.default.contentsOfDirectory(atPath: d.appendingPathComponent("voice/en-us").path)).sorted() }
        XCTAssertEqual(try listing(a), try listing(b))
    }

    func test_a_respelled_line_feeds_the_respelled_text_to_the_engine_but_keeps_the_line_id_name() throws {
        let dir = try themeDir(), engine = FakeEngine()
        let written = try VoiceBake.bakeTheme(themeDir: dir, theme: theme) { _ in engine }
        XCTAssertTrue(engine.texts.contains("ankie low saurus"))
        XCTAssertFalse(engine.texts.contains("ankylosaurus"))
        XCTAssertTrue(engine.texts.contains("see"), "letter lines use say")
        XCTAssertTrue(engine.texts.contains("three baby dinosaurs"), "word lines use word")
        XCTAssertTrue(written.contains("voice/en-us/vo_en-us_word_ankylosaurus.m4a"))
    }

    func test_provenance_is_written_and_byte_stable_across_two_runs() throws {
        let a = try themeDir(), b = try themeDir()
        _ = try VoiceBake.bakeTheme(themeDir: a, theme: theme) { _ in FakeEngine() }
        _ = try VoiceBake.bakeTheme(themeDir: b, theme: theme) { _ in FakeEngine() }
        let pa = try Data(contentsOf: a.appendingPathComponent("voice/en-us/provenance.json"))
        XCTAssertEqual(pa, try Data(contentsOf: b.appendingPathComponent("voice/en-us/provenance.json")))
        let text = String(decoding: pa, as: UTF8.self)
        for needle in ["\"weightsRevision\": \"rev123\"", "\"kokoro\": \"0.0-fake\"", "\"misaki\": \"0.0-fake\"", "\"voice\": \"af_heart\"",
                       "\"speed\": 0.88", "\"espeakNg\"", "\"baker\": \"kidtools", "word_ankylosaurus"] {
            XCTAssertTrue(text.contains(needle), needle)
        }
    }

    func test_a_failing_engine_writes_nothing_to_the_theme() throws {
        struct Boom: TTSEngine {
            let name = "boom"
            func render(text: String) throws -> PCMAudio { throw VoiceBakeError(file: "x", reason: "boom") }
            func reportedFacts() -> [String: String] { [:] }
        }
        let dir = try themeDir()
        XCTAssertThrowsError(try VoiceBake.bakeTheme(themeDir: dir, theme: theme) { _ in Boom() })
        XCTAssertFalse(FileManager.default.fileExists(atPath: dir.appendingPathComponent("voice").path))
    }

    // AC-3
    func test_the_app_sources_do_not_use_a_speech_synthesis_api() throws {
        let root = try Fixture.contractsRoot(from: #filePath).deletingLastPathComponent().appendingPathComponent("apple/LetterMorph")
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent("LetterMorphApp.swift").path))
        XCTAssertEqual(SpeechAPIScan.scan(directory: root), [])
    }

    func test_the_speech_scan_fails_on_a_fixture_naming_file_and_line() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("scan-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: dir) }
        try Data("import AVFoundation\nlet s = AVSpeechSynthesizer()\n".utf8).write(to: dir.appendingPathComponent("Bad.swift"))
        XCTAssertEqual(SpeechAPIScan.scan(directory: dir), ["Bad.swift:2: AVSpeechSynthesizer"])
    }
}
