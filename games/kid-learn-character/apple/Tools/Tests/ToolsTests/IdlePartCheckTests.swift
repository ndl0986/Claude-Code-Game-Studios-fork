import Foundation
import KidCore
import XCTest
@testable import ToolsCore

/// Story content-pipeline/004: the idle-part check (ADR-0003 D4), against provisional test idle data (OQ-1).
final class IdlePartCheckTests: XCTestCase {
    /// A theme with one item, family `sauropod`, whose cast file has parts `body` and `neck` (each with a pivot).
    func fixture(idle: String) throws -> (dir: URL, theme: ThemeModel) {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("idle-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir.appendingPathComponent("cast"), withIntermediateDirectories: true)
        let cast: [String: Any] = ["artboard": ["width": 10, "height": 10], "parts": [
            ["id": "body", "parent": NSNull(), "pivot": [5, 5], "layers": []],
            ["id": "neck", "parent": "body", "pivot": [6, 2], "layers": []]]]
        try JSONSerialization.data(withJSONObject: cast).write(to: dir.appendingPathComponent("cast/cast_dino_d_x_01.json"))
        let item = ThemeItem(castId: "dino_d_x", name: "X", word: "x", say: "x", sound: nil, family: "sauropod", variant: "01",
                             hueSlot: "h1", art: "cast/cast_dino_d_x_01.json", silhouette: "sil/sil_dino_d_x_01.json",
                             sfx: nil, voice: [:], weight: nil)
        let theme = ThemeModel(schemaVersion: 2, contentVersion: "1", id: "t", assetPrefix: nil, name: "T",
                               voiceLocales: ["en-us"], glyphSet: "g", families: ["sauropod": idle],
                               countedItem: CountedItem(castId: "dino_d_x", singular: "x", plural: "xs", emptyCastId: "e", emptyWord: "e"),
                               soundExceptions: [:], voiceDurations: [:], titleCastId: nil, rowWords: nil, keys: ["D": [item]])
        return (dir, theme)
    }

    func test_an_idle_naming_a_missing_part_fails_naming_the_part_and_the_file() throws {
        let (dir, theme) = try fixture(idle: "neck_sway")
        let fails = IdlePartCheck.check(themeDir: dir, theme: theme, idle: ["neck_sway": ["neck", "tail"]])
        XCTAssertEqual(fails, ["cast/cast_dino_d_x_01.json: idle neck_sway moves part tail, which is not in the art with a pivot"])
    }

    func test_an_idle_naming_existing_parts_passes() throws {
        let (dir, theme) = try fixture(idle: "neck_sway")
        XCTAssertEqual(IdlePartCheck.check(themeDir: dir, theme: theme, idle: ["neck_sway": ["neck", "body"]]), [])
    }

    func test_a_none_idle_passes() throws {
        let (dir, theme) = try fixture(idle: "none")
        XCTAssertEqual(IdlePartCheck.check(themeDir: dir, theme: theme, idle: [:]), [])
    }

    func test_an_idle_missing_from_the_data_fails() throws {
        let (dir, theme) = try fixture(idle: "neck_sway")
        XCTAssertEqual(IdlePartCheck.check(themeDir: dir, theme: theme, idle: [:]),
                       ["cast/cast_dino_d_x_01.json: family sauropod's idle neck_sway is not in the idle data"])
    }

    func test_no_idle_data_is_not_assessed() {
        let r = IdlePartCheck.bakeStep(contentDir: FileManager.default.temporaryDirectory, idleFile: nil)
        XCTAssertEqual(r.failures, [])
        XCTAssertEqual(r.notAssessed, ["NOT ASSESSED idle-part check: no idle data (OQ-1)"])
    }

    func test_the_idle_data_shape_is_parsed_and_a_bad_one_refused() throws {
        XCTAssertEqual(try IdlePartCheck.parse(Array(#"{"neck_sway":{"parts":["neck"]}}"#.utf8)), ["neck_sway": ["neck"]])
        XCTAssertThrowsError(try IdlePartCheck.parse(Array(#"{"neck_sway":["neck"]}"#.utf8)))
    }
}
