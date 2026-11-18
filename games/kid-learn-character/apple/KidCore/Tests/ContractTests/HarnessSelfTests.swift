import ContractKit
import Foundation
import KidCore
import XCTest

/// ADR-0004 Validation 2: the harness FAILs, with its cause, on each planted break. Runs on temporary contract folders.
final class HarnessSelfTests: XCTestCase {
    var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("harness-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: root) }

    /// A one-case settings-record-v1 file: a default macOS read, then `extraSteps`.
    func settingsFile(steps: [[String: Any]] = [], draws: [String: Any] = [:], streams: [String] = [], caseExtra: [String: Any] = [:]) -> [String: Any] {
        let record: [String: Any] = ["childLock": false, "keyboardRow": false, "muted": false, "schemaVersion": 1,
                                     "themeId": "dinosaurs", "volume": 8, "weather": "clear", "windy": false]
        var c: [String: Any] = ["id": "c1", "source": "gdd: settings-store.md R5", "given": ["platform": "macOS", "settingsBytes": NSNull()],
                                "draws": draws,
                                "steps": [["t": ["uptime": 0.0], "event": ["type": "read"],
                                           "expect": [["out": "record", "record": record, "childLockActive": false]]]] + steps]
        for (k, v) in caseExtra { c[k] = v }
        return ["contract": "settings-record-v1", "schema": 1, "uint64AsString": true, "units": ["time": "s"],
                "tolerance": ["gain": 1e-12], "streams": streams, "cases": [c]]
    }

    func write(_ obj: Any, dir: String = "settings-record-v1", name: String = "cases.json") throws {
        let d = root.appendingPathComponent(dir)
        try FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        try JSONSerialization.data(withJSONObject: obj).write(to: d.appendingPathComponent(name))
    }

    func failures() -> [String] { ContractHarness.runAll(root: root).failures }

    func test_a_correct_file_passes() throws {
        try write(settingsFile())
        XCTAssertEqual(failures(), [])
    }

    func test_a_wrong_expected_value_fails_with_the_field_path() throws {
        var f = settingsFile()
        var cs = f["cases"] as! [[String: Any]]; var s = cs[0]["steps"] as! [[String: Any]]
        s[0]["expect"] = [["out": "record", "record": ["childLock": false, "keyboardRow": false, "muted": false, "schemaVersion": 1,
                                                       "themeId": "dinosaurs", "volume": 7, "weather": "clear", "windy": false],
                           "childLockActive": false]]
        cs[0]["steps"] = s; f["cases"] = cs
        try write(f)
        let fl = failures()
        XCTAssertEqual(fl.count, 1)
        XCTAssertTrue(fl[0].hasPrefix("settings-record-v1/c1 [gdd: settings-store.md R5] steps[0].expect[0].record.volume: expected 7, got 8"), fl[0])
    }

    func test_a_directory_with_no_runner_fails() throws {
        try write(settingsFile())
        try FileManager.default.createDirectory(at: root.appendingPathComponent("parade-v1"), withIntermediateDirectories: true)
        XCTAssertEqual(failures(), ["parade-v1: no registered runner (ADR-0004 D5)"])
    }

    func test_an_empty_file_fails() throws {
        let d = root.appendingPathComponent("settings-record-v1")
        try FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        try Data().write(to: d.appendingPathComponent("cases.json"))
        XCTAssertTrue(failures().first?.contains("unreadable") ?? false)
    }

    func test_an_empty_generated_file_fails() throws {
        try write(settingsFile())
        var g = settingsFile(); g["cases"] = [] as [Any]
        try write(g, name: "cases-generated.json")
        XCTAssertTrue(failures().contains { $0.contains("S3") })
    }

    func test_a_leftover_draw_fails() throws {
        try write(settingsFile(draws: ["hints": ["1"]], streams: ["hints"]))
        XCTAssertTrue(failures().contains { $0.contains("draws: hints has 1 left") }, "\(failures())")
    }

    func test_a_play_field_fails() throws {
        try write(settingsFile(caseExtra: ["given": ["platform": "macOS", "settingsBytes": NSNull(), "play": 0]]))
        XCTAssertTrue(failures().contains { $0.contains("S13") })
    }

    func test_an_unordered_expect_fails() throws {
        // A change emits write then notify; the file lists notify first.
        let record: [String: Any] = ["childLock": false, "keyboardRow": false, "muted": false, "schemaVersion": 1,
                                     "themeId": "dinosaurs", "volume": 3, "weather": "clear", "windy": false]
        let bytes = #"{"childLock":false,"keyboardRow":false,"muted":false,"schemaVersion":1,"themeId":"dinosaurs","volume":3,"weather":"clear","windy":false}"#
        try write(settingsFile(steps: [["t": ["uptime": 1.0], "event": ["type": "change", "field": "volume", "value": 3],
                                        "expect": [["out": "notify", "record": record, "childLockActive": false],
                                                   ["out": "write", "bytes": bytes]]]]))
        XCTAssertTrue(failures().first?.contains("steps[1].expect[0]") ?? false, "\(failures())")
    }
}
