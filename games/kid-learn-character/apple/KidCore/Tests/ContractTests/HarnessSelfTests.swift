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

    /// A one-case settings-record-v2 file: a default macOS read, then `extraSteps`.
    func settingsFile(steps: [[String: Any]] = [], draws: [String: Any] = [:], streams: [String] = [], caseExtra: [String: Any] = [:]) -> [String: Any] {
        let record: [String: Any] = ["childLock": false, "keyboardRow": false, "muted": false, "schemaVersion": 1,
                                     "themeId": "dinosaurs", "volume": 8, "weather": "clear", "windy": false]
        var c: [String: Any] = ["id": "c1", "source": "gdd: settings-store.md R5", "given": ["platform": "macOS", "settingsBytes": NSNull()],
                                "draws": draws,
                                "steps": [["t": ["uptime": 0.0], "event": ["type": "read"],
                                           "expect": [["out": "record", "record": record, "childLockActive": false]]]] + steps]
        for (k, v) in caseExtra { c[k] = v }
        return ["contract": "settings-record-v2", "schema": 1, "uint64AsString": true, "units": ["time": "s"],
                "tolerance": ["gain": 1e-12], "streams": streams, "cases": [c]]
    }

    func write(_ obj: Any, dir: String = "settings-record-v2", name: String = "cases.json") throws {
        let d = root.appendingPathComponent(dir)
        try FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        try JSONSerialization.data(withJSONObject: obj).write(to: d.appendingPathComponent(name))
    }

    /// The README registry for the temporary folder (K-40). Default: settings-record-v2 runs, with 1 case.
    func registry(_ rows: [(String, String, Int)] = [("settings-record-v2", "runner: SettingsRecordRunner", 1)]) throws {
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
        XCTAssertTrue(fl[0].hasPrefix("settings-record-v2/c1 [gdd: settings-store.md R5] steps[0].expect[0].record.volume: expected 7, got 8"), fl[0])
    }

    func test_a_directory_with_no_registry_row_fails() throws {
        try write(settingsFile())
        try FileManager.default.createDirectory(at: root.appendingPathComponent("parade-v1"), withIntermediateDirectories: true)
        XCTAssertEqual(failures(), ["parade-v1: no registry row in contracts/README.md (K-40)"])
    }

    func test_a_wrong_declared_count_fails() throws {
        try write(settingsFile())
        try registry([("settings-record-v2", "runner: SettingsRecordRunner", 2)])
        XCTAssertEqual(failures(), ["settings-record-v2: 1 cases, the registry declares 2 (K-40)"])
    }

    func test_not_started_reports_not_assessed_never_pass() throws {
        var f = settingsFile(); f["contract"] = "parade-v1"
        try write(f, dir: "parade-v1")
        try write(settingsFile())
        try registry([("settings-record-v2", "runner: SettingsRecordRunner", 1), ("parade-v1", "not-started: story:parade", 1)])
        XCTAssertEqual(failures(), [])
        XCTAssertEqual(lines(), ["structure: 2/2 contracts OK (2 cases well-formed)",
                                 "NOT ASSESSED parade-v1: not started (story story:parade); structure OK, 0 of 1 cases run",
                                 "contracts: 1 run PASS (settings-record-v2), 1 NOT ASSESSED (not-started: parade-v1), 0 SUPERSEDED, 0 FAIL"])
    }

    func test_not_started_with_a_registered_runner_fails() throws {
        try write(settingsFile())
        try registry([("settings-record-v2", "not-started: story:settings", 1)])
        XCTAssertEqual(failures(), ["settings-record-v2: not-started but runner SettingsRecordRunner is registered (K-40)"])
    }

    func test_not_started_whose_story_is_done_fails() throws {
        var f = settingsFile(); f["contract"] = "parade-v1"
        try write(f, dir: "parade-v1")
        try write(settingsFile())
        try registry([("settings-record-v2", "runner: SettingsRecordRunner", 1), ("parade-v1", "not-started: PAR-001", 1)])
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
        try registry([("settings-record-v2", "runner: SettingsRecordRunner", 1), ("parade-v1", "superseded-by: parade-v2", 1),
                      ("parade-v2", "not-started: story:parade", 1)])
        XCTAssertEqual(failures(), [])
        XCTAssertTrue(lines().contains("SUPERSEDED parade-v1 → parade-v2: not run (1 cases)"), "\(lines())")
        try registry([("settings-record-v2", "runner: SettingsRecordRunner", 1), ("parade-v1", "superseded-by: parade-v3", 1),
                      ("parade-v2", "not-started: story:parade", 1)])
        XCTAssertEqual(failures(), ["parade-v1: superseded-by parade-v3: parade-v3 has no runner: or not-started: row (K-40)"])
    }

    func test_superseded_with_its_runner_still_registered_fails() throws {
        var v3 = settingsFile(); v3["contract"] = "settings-record-v3"
        try write(settingsFile()); try write(v3, dir: "settings-record-v3")
        try registry([("settings-record-v2", "superseded-by: settings-record-v3", 1), ("settings-record-v3", "not-started: story:settings", 1)])
        XCTAssertEqual(failures(), ["settings-record-v2: superseded-by settings-record-v3: runner SettingsRecordRunner still registered (K-40)"])
    }

    func test_an_empty_file_fails() throws {
        let d = root.appendingPathComponent("settings-record-v2")
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

    // MARK: expectState and case-level fields (TASK-148)

    /// A one-case stub-state-v1 file: `set` stores `value` as the state `value` and `obj.at`.
    func stubFile(set: Double, expectState: [String: Any], tolerance: Double = 1e-9) -> [String: Any] {
        let c: [String: Any] = ["id": "s1", "source": "gdd: test.md R1", "given": [String: Any](), "draws": [String: Any](),
                                "steps": [["t": ["uptime": 0.0], "event": ["type": "set", "value": set], "expect": [Any](),
                                           "expectState": expectState]]]
        return ["contract": "stub-state-v1", "schema": 1, "uint64AsString": true, "units": ["time": "s"],
                "tolerance": ["time": tolerance], "streams": [String](), "cases": [c]]
    }

    func stubFailures(_ file: [String: Any]) throws -> [String] {
        try write(file, dir: "stub-state-v1")
        try registry([("stub-state-v1", "runner: StubStateRunner", 1)])
        return ContractHarness.runAll(root: root, runners: [StubStateRunner.self]).failures
    }

    func test_expect_state_that_matches_passes() throws {
        XCTAssertEqual(try stubFailures(stubFile(set: 1.0, expectState: ["value": 1.0, "obj": ["at": 1.0]])), [])
    }

    func test_expect_state_with_a_wrong_value_fails_with_its_path() throws {
        let f = try stubFailures(stubFile(set: 1.0, expectState: ["value": 2.0]))
        XCTAssertEqual(f.count, 1, "\(f)")
        XCTAssertTrue(f[0].hasPrefix("stub-state-v1/s1 [gdd: test.md R1] steps[0].expectState.value: expected 2"), f[0])
    }

    func test_expect_state_doubles_compare_within_their_field_kind() throws {
        // `value` and `obj.at` are kind `time` (1e-9 here): inside passes, outside fails, at either depth.
        XCTAssertEqual(try stubFailures(stubFile(set: 1.0, expectState: ["value": 1.0 + 5e-10, "obj": ["at": 1.0 + 5e-10]])), [])
        let f = try stubFailures(stubFile(set: 1.0, expectState: ["obj": ["at": 1.0 + 1e-6]]))
        XCTAssertTrue(f.first?.contains("steps[0].expectState.obj.at: expected") ?? false, "\(f)")
        XCTAssertTrue(f.first?.contains("(tol 1e-09)") ?? false, "\(f)")
    }

    func test_expect_state_naming_unknown_state_fails() throws {
        let f = try stubFailures(stubFile(set: 1.0, expectState: ["nope": 1]))
        XCTAssertTrue(f.first?.contains("steps[0].expectState.nope: ") ?? false, "\(f)")
    }

    func test_a_record_written_with_a_subset_of_members_passes() throws {
        XCTAssertEqual(try stubFailures(stubFile(set: 1.0, expectState: ["rec": ["n": 3]])), [])
        XCTAssertEqual(try stubFailures(stubFile(set: 1.0, expectState: ["rec": ["at": 1.0 + 5e-10, "tag": "t"]])), [])
    }

    func test_a_record_member_with_a_wrong_value_fails_with_its_path() throws {
        let f = try stubFailures(stubFile(set: 1.0, expectState: ["rec": ["n": 4]]))
        XCTAssertTrue(f.first?.contains("steps[0].expectState.rec.n: expected 4, got 3") ?? false, "\(f)")
    }

    func test_a_record_member_the_runner_lacks_fails() throws {
        let f = try stubFailures(stubFile(set: 1.0, expectState: ["rec": ["n": 3, "missing": 1]]))
        XCTAssertTrue(f.first?.contains("steps[0].expectState.rec.missing: expected 1, got absent") ?? false, "\(f)")
    }

    func test_a_non_record_object_still_compares_whole() throws {
        // `obj` is not a record: a case that omits a member the runner has fails (exact, §6).
        let f = try stubFailures(stubFile(set: 1.0, expectState: ["obj": [String: Any]()]))
        XCTAssertTrue(f.first?.contains("steps[0].expectState.obj.at: expected absent") ?? false, "\(f)")
    }

    func test_a_set_with_the_same_elements_in_another_order_passes() throws {
        XCTAssertEqual(try stubFailures(stubFile(set: 1.0, expectState: ["set": ["c", "a", "b"]])), [])
    }

    func test_a_set_with_a_missing_or_extra_element_fails() throws {
        let missing = try stubFailures(stubFile(set: 1.0, expectState: ["set": ["a", "b"]]))
        XCTAssertTrue(missing.first?.contains("steps[0].expectState.set.count: expected 2, got 3") ?? false, "\(missing)")
        let other = try stubFailures(stubFile(set: 1.0, expectState: ["set": ["a", "b", "d"]]))
        XCTAssertTrue(other.first?.contains("steps[0].expectState.set[") ?? false, "\(other)")
    }

    func test_an_ordered_list_still_compares_in_order() throws {
        let f = try stubFailures(stubFile(set: 1.0, expectState: ["list": ["a", "b", "c"]]))
        XCTAssertTrue(f.first?.contains("steps[0].expectState.list[0]: expected \"a\", got \"b\"") ?? false, "\(f)")
    }

    func test_a_runner_with_no_state_fails_a_case_that_checks_state() throws {
        let record: [String: Any] = ["childLock": false, "keyboardRow": false, "muted": false, "schemaVersion": 1,
                                     "themeId": "dinosaurs", "volume": 8, "weather": "clear", "windy": false]
        try write(settingsFile(steps: [["t": ["uptime": 1.0], "event": ["type": "read"],
                                        "expect": [["out": "record", "record": record, "childLockActive": false]],
                                        "expectState": ["record": record]]]))
        XCTAssertTrue(failures().first?.contains("steps[1].expectState.record: this runner exposes no state") ?? false, "\(failures())")
    }

    func test_case_level_expect_permute_and_tolerance_fail_as_unsupported() throws {
        let extras: [(String, [String: Any])] = [
            ("expect", ["expect": ["x": 1]]),
            ("permute", ["permute": ["/platform"]]),
            ("tolerance", ["tolerance": ["steps[0].expect[0].record.volume": 0.5], "toleranceReason": "gdd: settings-store.md R5"])]
        for (k, extra) in extras {
            try write(settingsFile(caseExtra: extra))
            XCTAssertTrue(failures().contains { $0.contains("\(k): case-level \(k) is not supported") }, "\(k): \(failures())")
        }
    }
}

/// A test-only runner with state (TASK-148): `set` stores `value`; state `value` and `obj` (`{at}`) are kind `time`.
struct StubStateRunner: ContractRunner {
    static let contract = "stub-state-v1"
    static let declaration = ContractDeclaration(givenFields: [], events: ["set": ["value"]])
    static func kind(out: String, field: String) -> String? { nil }
    static func stateKind(name: String, field: String) -> String? { ["value", "at"].contains(field) ? "time" : nil }
    /// `rec` is a record (`{at, n, tag}`); `obj` is not.
    static func stateIsRecord(_ name: String) -> Bool { name == "rec" }
    /// `set` is a set; `list` (the same elements) is an ordered list.
    static func stateIsSet(_ name: String) -> Bool { name == "set" }
    var v = 0.0
    init(given: [String: JSONValue], draws: DrawQueues) throws {}
    mutating func step(uptime: Double, event e: [String: JSONValue]) throws -> Outputs { v = e["value"]?.number ?? 0; return [] }
    func state(_ name: String) throws -> JSONValue {
        switch name {
        case "value": return .double(v)
        case "obj": return .object(["at": .double(v)])
        case "rec": return .object(["at": .double(v), "n": .int(3), "tag": .string("t")])
        case "set", "list": return .array([.string("b"), .string("a"), .string("c")])
        default: throw ContractError("stub-state-v1 exposes no state named \(name)")
        }
    }
}
