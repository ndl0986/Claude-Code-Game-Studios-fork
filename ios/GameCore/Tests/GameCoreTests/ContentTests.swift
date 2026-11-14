import XCTest
@testable import GameCore

/// The bundled data and the debug sample: schema (R1), cross-file rules, NFC, tuning keys.
final class ContentTests: XCTestCase {
    func test_every_data_and_sample_file_matches_its_schema() throws {
        let schema = try MiniSchema(dir: Repo.content.appendingPathComponent("schema"))
        let files: [(String, String)] = [
            ("data/index.json", "index"), ("data/strings.json", "strings"), ("data/sources.json", "sources"),
            ("data/markers.json", "markers"), ("data/rules.json", "rules"), ("data/tuning.json", "tuning"),
            ("data/assets.json", "assets"), ("data/themes.json", "themes"), ("samples/heroes/sample/mission.json", "mission"),
            ("samples/heroes/sample/quiz.json", "quiz"), ("samples/heroes/sample/claims.json", "claims"),
        ]
        for (path, s) in files where FileManager.default.fileExists(atPath: Repo.content.appendingPathComponent(path).path) {
            XCTAssertEqual(schema.validate(try Repo.json(path), file: "\(s).schema.json"), [], path)
        }
    }

    func test_the_mini_schema_validator_rejects_broken_content() throws {
        let schema = try MiniSchema(dir: Repo.content.appendingPathComponent("schema"))
        var m = try Repo.json("samples/heroes/sample/mission.json") as! [String: Any]
        var intro = m["intro"] as! [[String: Any]]
        intro[0]["claims"] = [String]()
        m["intro"] = intro
        XCTAssertFalse(schema.validate(m, file: "mission.schema.json").isEmpty, "story text with no claim")
        var q = try Repo.json("samples/heroes/sample/quiz.json") as! [String: Any]
        q["questions"] = Array((q["questions"] as! [Any]).prefix(2))
        XCTAssertFalse(schema.validate(q, file: "quiz.schema.json").isEmpty, "a 2-question quiz")
    }

    func test_cross_file_rules_pass_on_data_and_sample() throws {
        let content = try Repo.contentSet()
        let errors = ContentValidator(content: content, checkPictures: false).validate().filter { !$0.isWarning }
        XCTAssertEqual(errors, [])
    }

    func test_data_folder_pictures_resolve_and_files_exist() throws {
        let content = try ContentSet.load(dataRoot: Repo.data)
        XCTAssertEqual(ContentValidator(content: content, checkPictures: true, dataRoot: Repo.data).validate().filter { !$0.isWarning }, [], "incl. R19a headers")
        for a in content.assets.assets {
            let url = Repo.data.appendingPathComponent(a.file)
            let size = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int
            XCTAssertEqual(size, a.bytes, a.file)
        }
    }

    func test_tuning_has_every_key_the_core_reads() throws {
        XCTAssertEqual(try Repo.contentSet().tuning.missingKeys, [])
    }

    func test_strings_have_the_app_title_in_both_languages() throws {
        let c = try Repo.contentSet()
        XCTAssertEqual(c.ui("ui.app.title", .vi), "Dải Đất Anh Hùng")
        XCTAssertEqual(c.ui("ui.app.title", .en), "Land of Heroes")
        XCTAssertEqual(c.ui("ui.no.such", .vi), "ui.no.such", "a missing id shows its key")
    }

    func test_sample_is_pending_so_the_gate_hides_it_in_release_and_badges_it_in_debug() throws {
        let hero = Repo.sampleHero(try Repo.contentSet())
        let r = ClaimGate.evaluate(hero)
        XCTAssertEqual(r.releaseBuild, .fail)
        XCTAssertEqual(r.runtimeRelease, .hideAndLog)
        XCTAssertEqual(r.debugBadges, ["C01", "C02", "C12"])
    }

    func test_schema_major_supported() throws {
        let c = try Repo.contentSet()
        for v in [c.index.schemaVersion, c.strings.schemaVersion, c.rules.schemaVersion, c.tuning.schemaVersion] + c.heroes.map(\.mission.schemaVersion) {
            XCTAssertEqual(ContentValidator.schemaMajor(file: v, app: ContentSet.supportedSchema), [], v)
        }
    }
}

/// R19a header parsing: PNG and the three WebP kinds (VP8X carries lossy WebP with alpha).
final class ImageHeaderTests: XCTestCase {
    func test_png_and_webp_vp8x_vp8l_vp8_sizes() {
        var png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52])
        png += Data([0, 0, 1, 0, 0, 0, 0, 0xC8]) + Data(count: 8)
        XCTAssertTrue(ContentValidator.imageSize(png)! == (256, 200))
        func riff(_ fourcc: String, _ body: [UInt8]) -> Data {
            Data("RIFF".utf8) + Data([100, 0, 0, 0]) + Data("WEBP".utf8) + Data(fourcc.utf8) + Data([10, 0, 0, 0]) + Data(body) + Data(count: 16)
        }
        // VP8X: flags(4) then canvas width-1, height-1 as 24-bit little endian
        XCTAssertTrue(ContentValidator.imageSize(riff("VP8X", [0x10, 0, 0, 0, 0x2B, 0x01, 0x00, 0xC7, 0x00, 0x00]))! == (300, 200))
        // VP8L: signature 0x2f, then 14-bit width-1 and height-1
        let w = 300 - 1, h = 200 - 1, v = w | (h << 14)
        XCTAssertTrue(ContentValidator.imageSize(riff("VP8L", [0x2F, UInt8(v & 0xFF), UInt8((v >> 8) & 0xFF), UInt8((v >> 16) & 0xFF), UInt8((v >> 24) & 0xFF), 0, 0, 0, 0, 0]))! == (300, 200))
        // VP8 (lossy): frame tag(3) + start code 9d 01 2a + 14-bit width, height
        XCTAssertTrue(ContentValidator.imageSize(riff("VP8 ", [0, 0, 0, 0x9D, 0x01, 0x2A, 0x2C, 0x01, 0xC8, 0x00]))! == (300, 200))
    }
}
