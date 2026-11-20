import AVFoundation
import Foundation
import KidCore
import ToolsCore
import XCTest

/// Staleness on baked audio (ADR-0003 D3/D4, content-pipeline story 004): sfx by re-render and byte compare, voice by
/// hashed render inputs and re-measured voiceDurations. Fake engine; temp dirs.
final class StalenessTests: XCTestCase {
    /// A temp theme with a baked voice (fake engine) and a baked 2-recipe sfx set; returns the folder and the model with
    /// the bake's durations.
    func bakedTheme() throws -> (dir: URL, model: ThemeModel) {
        let dir = try GateFixture.themeDir(self)
        var model = GateFixture.theme
        model.voiceDurations = try VoiceBake.bakeThemeReport(themeDir: dir, theme: model) { _ in GateFixture.ToneEngine() }.durations
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("content/themes/dinosaurs/src/sfx/recipes.json")
        var o = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: root)) as? [String: Any])
        let all = try XCTUnwrap(o["recipes"] as? [String: Any])
        o["recipes"] = all.filter { ["dino_a_ankylosaurus_01", "dino_b_brachiosaurus_01"].contains($0.key) }
        try FileManager.default.createDirectory(at: dir.appendingPathComponent("src/sfx"), withIntermediateDirectories: true)
        try writeRecipes(o, dir)
        _ = try SfxBake.bakeTheme(themeDir: dir)
        return (dir, model)
    }

    func writeRecipes(_ o: [String: Any], _ dir: URL) throws {
        try JSONSerialization.data(withJSONObject: o, options: [.sortedKeys]).write(to: dir.appendingPathComponent("src/sfx/recipes.json"))
    }

    func test_an_untouched_baked_theme_has_no_stale_finding() throws {
        let (dir, model) = try bakedTheme()
        XCTAssertEqual(Staleness.check(themeDir: dir, theme: model), [])
    }

    func test_an_edited_script_text_without_a_rebake_is_stale_naming_the_line() throws {
        let (dir, model) = try bakedTheme()
        let p = dir.appendingPathComponent("src/voice-scripts/en-us.json")
        let edited = GateFixture.scriptJSON.replacingOccurrences(of: "ankie low saurus", with: "an key low saurus")
        try Data(edited.utf8).write(to: p)
        let msgs = Staleness.check(themeDir: dir, theme: model)
        XCTAssertEqual(msgs.count, 1, "\(msgs)")
        XCTAssertTrue(msgs[0].hasPrefix("voice/en-us/vo_en-us_word_ankylosaurus.caf: stale"), "\(msgs)")
    }

    func test_an_edited_trim_value_makes_every_line_stale() throws {
        let (dir, model) = try bakedTheme()
        let edited = GateFixture.scriptJSON.replacingOccurrences(of: "\"padSeconds\": 0.02", with: "\"padSeconds\": 0.03")
        try Data(edited.utf8).write(to: dir.appendingPathComponent("src/voice-scripts/en-us.json"))
        XCTAssertEqual(Staleness.check(themeDir: dir, theme: model).count, 6)
    }

    func test_a_changed_voice_file_and_a_wrong_voiceDuration_are_stale_naming_the_file() throws {
        let (dir, model) = try bakedTheme()
        let file = dir.appendingPathComponent("voice/en-us/vo_en-us_letter_c.caf")
        try VoiceBake.encode(PCMAudio(samples: (0..<48_000).map { 0.2 * Float(sin(Double($0) * 0.05)) }, sampleRate: 48_000), to: file)
        let msgs = Staleness.check(themeDir: dir, theme: model)
        XCTAssertTrue(msgs.contains { $0.hasPrefix("voice/en-us/vo_en-us_letter_c.caf: stale, the file differs") }, "\(msgs)")
        XCTAssertTrue(msgs.contains { $0.hasPrefix("voice/en-us/vo_en-us_letter_c.caf: stale voiceDurations") }, "\(msgs)")
        XCTAssertEqual(msgs.count, 2, "\(msgs)")
    }

    func test_an_edited_sfx_recipe_is_stale_naming_the_file_and_only_that_file() throws {
        let (dir, model) = try bakedTheme()
        var o = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: dir.appendingPathComponent("src/sfx/recipes.json"))) as? [String: Any])
        var r = try XCTUnwrap(o["recipes"] as? [String: Any]), x = try XCTUnwrap(r["dino_a_ankylosaurus_01"] as? [String: Any])
        x["f0"] = 75; r["dino_a_ankylosaurus_01"] = x; o["recipes"] = r
        try writeRecipes(o, dir)
        let msgs = Staleness.check(themeDir: dir, theme: model)
        XCTAssertEqual(msgs.count, 1, "\(msgs)")
        XCTAssertTrue(msgs[0].hasPrefix("sfx/sfx_dino_a_ankylosaurus_01.caf: differs"), "\(msgs)")
    }

    func test_a_theme_without_sources_has_nothing_to_be_stale_against() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("nosrc-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: dir) }
        XCTAssertEqual(Staleness.check(themeDir: dir, theme: GateFixture.theme), [])
    }
}
