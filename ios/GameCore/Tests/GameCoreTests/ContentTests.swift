import XCTest
@testable import GameCore

/// The bundled data and the debug sample: schema (R1), cross-file rules, NFC, tuning keys.
final class ContentTests: XCTestCase {
    func test_every_data_and_sample_file_matches_its_schema() throws {
        let schema = try MiniSchema(dir: Repo.content.appendingPathComponent("schema"))
        let files: [(String, String)] = [
            ("data/index.json", "index"), ("data/strings.json", "strings"), ("data/sources.json", "sources"),
            ("data/markers.json", "markers"), ("data/rules.json", "rules"), ("data/tuning.json", "tuning"),
            ("data/assets.json", "assets"), ("samples/heroes/sample/mission.json", "mission"),
            ("samples/heroes/sample/quiz.json", "quiz"), ("samples/heroes/sample/claims.json", "claims"),
        ]
        for (path, s) in files {
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
        XCTAssertEqual(ContentValidator(content: content, checkPictures: true).validate().filter { !$0.isWarning }, [])
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
        let hero = try Repo.contentSet().heroes[0]
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
