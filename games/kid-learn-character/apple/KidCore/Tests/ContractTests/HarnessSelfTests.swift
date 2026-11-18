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

    /// The README registry for the temporary folder (K-40). Default: settings-record-v1 runs, with 1 case.
    func registry(_ rows: [(String, String, Int)] = [("settings-record-v1", "runner: SettingsRecordRunner", 1)]) throws {
        let table = rows.map { "| \($0.0) | \($0.1) | \($0.2) |" }.joined(separator: "\n")
        try "# t\n\n## Registry\n\n| Contract | Row | Cases |\n|---|---|---|\n\(table)\n\n## Drift\n".write(
            to: root.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
    }

    func failures() -> [String] {
        if !FileManager.default.fileExists(atPath: root.appendingPathComponent("README.md").path) { try? registry() }
        return ContractHarness.runAll(root: root).failures
    }

    func lines() -> [String] { ContractHarness.runAll(root: root).lines }

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

    func test_a_directory_with_no_registry_row_fails() throws {
        try write(settingsFile())
        try FileManager.default.createDirectory(at: root.appendingPathComponent("parade-v1"), withIntermediateDirectories: true)
        XCTAssertEqual(failures(), ["parade-v1: no registry row in contracts/README.md (K-40)"])
    }

    func test_a_wrong_declared_count_fails() throws {
        try write(settingsFile())
        try registry([("settings-record-v1", "runner: SettingsRecordRunner", 2)])
        XCTAssertEqual(failures(), ["settings-record-v1: 1 cases, the registry declares 2 (K-40)"])
    }

    func test_not_started_reports_not_assessed_never_pass() throws {
        var f = settingsFile(); f["contract"] = "parade-v1"
        try write(f, dir: "parade-v1")
        try write(settingsFile())
        try registry([("settings-record-v1", "runner: SettingsRecordRunner", 1), ("parade-v1", "not-started: story:parade", 1)])
        XCTAssertEqual(failures(), [])
        XCTAssertEqual(lines(), ["structure: 2/2 contracts OK (2 cases well-formed)",
                                 "NOT ASSESSED parade-v1: not started (story story:parade); structure OK, 0 of 1 cases run",
                                 "contracts: 1 run PASS (settings-record-v1), 1 NOT ASSESSED (not-started: parade-v1), 0 SUPERSEDED, 0 FAIL"])
    }

    func test_not_started_with_a_registered_runner_fails() throws {
        try write(settingsFile())
        try registry([("settings-record-v1", "not-started: story:settings", 1)])
        XCTAssertEqual(failures(), ["settings-record-v1: not-started but runner SettingsRecordRunner is registered (K-40)"])
    }

    func test_not_started_whose_story_is_done_fails() throws {
        var f = settingsFile(); f["contract"] = "parade-v1"
        try write(f, dir: "parade-v1")
        try write(settingsFile())
        try registry([("settings-record-v1", "runner: SettingsRecordRunner", 1), ("parade-v1", "not-started: PAR-001", 1)])
        let story = root.deletingLastPathComponent().appendingPathComponent("production/stories")
        try FileManager.default.createDirectory(at: story, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent().appendingPathComponent("production")) }
        try "# Story PAR-001\n\nStatus: Done\n".write(to: story.appendingPathComponent("par-001.md"), atomically: true, encoding: .utf8)
        XCTAssertEqual(failures(), ["parade-v1: not-started but story PAR-001 is Done (K-40)"])
    }

    func test_superseded_reports_its_own_line_and_needs_a_live_target() throws {
        var v2 = settingsFile(); v2["contract"] = "parade-v2"
        var v1 = settingsFile(); v1["contract"] = "parade-v1"
        try write(v1, dir: "parade-v1"); try write(v2, dir: "parade-v2"); try write(settingsFile())
        try registry([("settings-record-v1", "runner: SettingsRecordRunner", 1), ("parade-v1", "superseded-by: parade-v2", 1),
                      ("parade-v2", "not-started: story:parade", 1)])
        XCTAssertEqual(failures(), [])
        XCTAssertTrue(lines().contains("SUPERSEDED parade-v1 → parade-v2: not run (1 cases)"), "\(lines())")
        try registry([("settings-record-v1", "runner: SettingsRecordRunner", 1), ("parade-v1", "superseded-by: parade-v3", 1),
                      ("parade-v2", "not-started: story:parade", 1)])
        XCTAssertEqual(failures(), ["parade-v1: superseded-by parade-v3: parade-v3 has no runner: or not-started: row (K-40)"])
    }

    func test_superseded_with_its_runner_still_registered_fails() throws {
        var v2 = settingsFile(); v2["contract"] = "settings-record-v2"
        try write(settingsFile()); try write(v2, dir: "settings-record-v2")
        try registry([("settings-record-v1", "superseded-by: settings-record-v2", 1), ("settings-record-v2", "not-started: story:settings", 1)])
        XCTAssertEqual(failures(), ["settings-record-v1: superseded-by settings-record-v2: runner SettingsRecordRunner still registered (K-40)"])
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
