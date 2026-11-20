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
         "trim": {"thresholdDBFS": -50, "padSeconds": 0.02, "fadeSeconds": 0.005},
         "limiter": {"ceilingDBTP": -1.0, "lookaheadSeconds": 0.005, "releaseSeconds": 0.05, "warnReductionDB": 6.0},
         "respell": {"word_ankylosaurus": "ankie low saurus"}}
        """
        try Data(json.utf8).write(to: scripts.appendingPathComponent("en-us.json"))
        addTeardownBlock { try? FileManager.default.removeItem(at: dir) }
        return dir
    }

    let expected = ["voice/en-us/provenance.json", "voice/en-us/vo_en-us_letter_a.caf", "voice/en-us/vo_en-us_letter_c.caf",
                    "voice/en-us/vo_en-us_number_3.caf", "voice/en-us/vo_en-us_word_ankylosaurus.caf",
                    "voice/en-us/vo_en-us_word_three_baby_dinosaurs.caf", "voice/en-us/vo_en-us_word_triceratops.caf"]

    // AC-1
    func test_every_named_voice_line_is_rendered_as_caf_lpcm_mono_under_voice_locale_and_decodes() throws {
        let dir = try themeDir()
        let written = try VoiceBake.bakeTheme(themeDir: dir, theme: theme) { _ in FakeEngine() }
        XCTAssertEqual(written, expected)
        for rel in expected where rel.hasSuffix(".caf") {
            XCTAssertTrue(FileManager.default.fileExists(atPath: dir.appendingPathComponent(rel).path), rel)
            let f = try AVAudioFile(forReading: dir.appendingPathComponent(rel))
            XCTAssertEqual(f.fileFormat.settings[AVFormatIDKey] as? UInt32, kAudioFormatLinearPCM, rel)
            XCTAssertEqual(f.fileFormat.settings[AVLinearPCMBitDepthKey] as? Int, 16, rel)
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
    /// K-52: CAF linear PCM is exact. The file decodes to the source's frame count (the resampled count for a 24 kHz
    /// Kokoro source) and, at 48 kHz, to the 16-bit-quantised source samples within one LSB, with the onset at frame 0.
    func test_the_caf_file_decodes_to_the_exact_frame_count_and_the_16_bit_samples() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("caf-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        for sourceRate in [48_000.0, 24_000.0] {
            let n = Int(sourceRate)
            let samples = (0..<n).map { Float(0.5 * sin(2 * Double.pi * 1000 * Double($0) / sourceRate)) }
            let url = dir.appendingPathComponent("tone-\(Int(sourceRate)).caf")
            try VoiceBake.encode(PCMAudio(samples: samples, sampleRate: sourceRate), to: url)
            let f = try AVAudioFile(forReading: url)
            let buf = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: f.processingFormat, frameCapacity: AVAudioFrameCount(f.length)))
            try f.read(into: buf)
            let got = Array(UnsafeBufferPointer(start: try XCTUnwrap(buf.floatChannelData)[0], count: Int(buf.frameLength)))
            if sourceRate == VoiceBake.sampleRate {
                XCTAssertEqual(got.count, n, "48 kHz: same frame count")
                let worst = zip(got, samples).map { abs($0 - $1) }.max() ?? 1
                XCTAssertLessThanOrEqual(worst, 1.0 / 32_768, "48 kHz: the 16-bit samples, within one LSB")
                XCTAssertGreaterThan(abs(got[1]), 0, "onset at frame 0, no lead")
            } else {
                XCTAssertLessThanOrEqual(abs(Double(got.count) - Double(n) * VoiceBake.sampleRate / sourceRate), 1, "24 kHz: resampled frame count")
            }
        }
    }

    func test_encoding_the_same_audio_twice_gives_identical_bytes() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("stable-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let pcm = PCMAudio(samples: (0..<24_000).map { Float(0.3 * sin(Double($0) * 0.05)) }, sampleRate: 24_000)
        let a = dir.appendingPathComponent("a.caf"), b = dir.appendingPathComponent("b.caf")
        try VoiceBake.encode(pcm, to: a)
        Thread.sleep(forTimeInterval: 1.1)   // cross a second boundary, so any time stamp would differ
        try VoiceBake.encode(pcm, to: b)
        XCTAssertEqual(try Data(contentsOf: a), try Data(contentsOf: b))
    }

    func test_a_non_caf_path_is_refused() {
        XCTAssertThrowsError(try VoiceBake.encode(PCMAudio(samples: [0.1, 0.2], sampleRate: 48_000),
                                                  to: FileManager.default.temporaryDirectory.appendingPathComponent("x.m4a")))
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
        XCTAssertTrue(written.contains("voice/en-us/vo_en-us_word_ankylosaurus.caf"))
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
