import Foundation
import ToolsCore
import XCTest

/// Press Queue story 005, AC-21 (R13): `kidtools validate` checks `content/data/press-queue.json`.
final class DataValidatorTests: XCTestCase {
    func contentDir(_ json: String?) throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("data-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir.appendingPathComponent("data"), withIntermediateDirectories: true)
        if let json { try json.write(to: dir.appendingPathComponent("data/press-queue.json"), atomically: true, encoding: .utf8) }
        return dir
    }

    func test_the_real_content_passes_and_the_F1_check_is_not_assessed_yet() {
        let real = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../../content").standardized
        let r = DataValidator.run(contentDir: real)
        XCTAssertEqual(r.findings, [])
        XCTAssertEqual(r.notAssessed.count, 1)
        XCTAssertTrue(r.notAssessed[0].hasPrefix("NOT ASSESSED press-queue F1 build check"), r.notAssessed[0])
    }

    func test_a_missing_file_fails() throws {
        XCTAssertEqual(DataValidator.run(contentDir: try contentDir(nil)).findings, ["data/press-queue.json: missing (R13)"])
    }

    func test_an_out_of_range_value_fails_naming_it() throws {
        let r = DataValidator.run(contentDir: try contentDir(#"{"hold_s": 2.0, "queue_max": 3, "formed_timeout_s": 1.0}"#))
        XCTAssertEqual(r.findings, ["data/press-queue.json: hold_s: 2.0 is outside 2.95…6.0 (R13)"])
    }

    func test_a_boolean_or_a_string_is_not_a_number() throws {
        let r = DataValidator.run(contentDir: try contentDir(#"{"hold_s": true, "queue_max": "3", "formed_timeout_s": 1.0}"#))
        XCTAssertEqual(r.findings, ["data/press-queue.json: hold_s: missing or not a number (R13)",
                                    "data/press-queue.json: queue_max: missing or not a number (R13)"])
    }
}
