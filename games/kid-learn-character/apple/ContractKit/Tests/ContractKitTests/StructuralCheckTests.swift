import ContractKit
import Foundation
import XCTest

/// case-schema-v1's self-test rule: every (S#) rule has a negative fixture that must FAIL with that rule.
final class StructuralCheckTests: XCTestCase {
    let decl = ContractDeclaration(givenFields: ["platform"], events: ["read": [], "change": ["field", "value"]])

    /// A valid file; each test breaks one thing.
    func base() -> [String: Any] {
        [
            "contract": "demo-v1", "schema": 1, "uint64AsString": true, "units": ["time": "s"], "tolerance": ["time": 1e-9],
            "streams": ["hints"], "fixtures": ["rec": ["a": [1, 2], "b": "x"]],
            "cases": [[
                "id": "c1", "source": "gdd: demo.md R1", "given": ["platform": "macOS"], "draws": ["hints": ["0", "18446744073709551615"]],
                "steps": [["t": ["uptime": 0.0], "event": ["type": "read"], "expect": [] as [Any]],
                          ["t": ["uptime": 1.0], "event": ["type": "change", "field": "f", "value": 1], "expect": [] as [Any]]],
            ]],
        ]
    }

    func errors(_ obj: [String: Any], layers: Set<String> = []) throws -> [String] {
        let data = try JSONSerialization.data(withJSONObject: obj)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("sc-\(UUID().uuidString).json")
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let d = ContractDeclaration(givenFields: decl.givenFields, events: decl.events, layers: layers)
        return StructuralCheck.check(try Fixture.load(url), directory: "demo-v1", file: "demo-v1/cases.json", declaration: d).map(\.rule)
    }

    func mutateCase(_ f: (inout [String: Any]) -> Void) -> [String: Any] {
        var b = base(); var cs = b["cases"] as! [[String: Any]]; f(&cs[0]); b["cases"] = cs; return b
    }

    func assertRule(_ rule: String, _ obj: [String: Any], layers: Set<String> = [], file: StaticString = #filePath, line: UInt = #line) throws {
        let e = try errors(obj, layers: layers)
        XCTAssertTrue(e.contains { $0.hasPrefix(rule + " ") }, "expected \(rule), got \(e)", file: file, line: line)
    }

    func test_valid_file_has_no_errors() throws { XCTAssertEqual(try errors(base()), []) }
    func test_S1_contract_must_equal_directory() throws { var b = base(); b["contract"] = "other-v1"; try assertRule("S1", b) }
    func test_S2_schema_must_be_1() throws { var b = base(); b["schema"] = 2; try assertRule("S2", b) }
    func test_S3_cases_must_be_non_empty() throws { var b = base(); b["cases"] = [] as [Any]; try assertRule("S3", b) }
    func test_S4_unknown_top_level_key() throws { var b = base(); b["extra"] = 1; try assertRule("S4", b) }
    func test_S5_duplicate_id() throws {
        var b = base(); let c = (b["cases"] as! [[String: Any]])[0]; b["cases"] = [c, c]; try assertRule("S5", b)
    }
    func test_S6_bad_source() throws { try assertRule("S6", mutateCase { $0["source"] = "design notes" }) }
    func test_S7_layer_missing_where_layers_exist() throws { try assertRule("S7", base(), layers: ["model", "file"]) }
    func test_S7_unknown_layer() throws { try assertRule("S7", mutateCase { $0["layer"] = "wire" }, layers: ["model", "file"]) }
    func test_S8_unknown_given_field() throws { try assertRule("S8", mutateCase { $0["given"] = ["platform": "macOS", "colour": "red"] }) }
    func test_S9_unlisted_stream() throws { try assertRule("S9", mutateCase { $0["draws"] = ["variety": ["1"]] }) }
    func test_S10_draw_not_a_uint64_string() throws { try assertRule("S10", mutateCase { $0["draws"] = ["hints": [5]] }) }
    func test_S10_draw_out_of_range() throws { try assertRule("S10", mutateCase { $0["draws"] = ["hints": ["18446744073709551616"]] }) }
    func test_S11_tolerance_without_reason() throws { try assertRule("S11", mutateCase { $0["tolerance"] = ["x": 0.1] }) }
    func test_S12_unknown_case_key() throws { try assertRule("S12", mutateCase { $0["weight"] = 1 }) }
    func test_S13_play_anywhere() throws {
        try assertRule("S13", mutateCase { c in var s = c["steps"] as! [[String: Any]]; s[0]["t"] = ["uptime": 0.0, "play": 0.0]; c["steps"] = s })
    }
    func test_S13_u_and_seed() throws {
        try assertRule("S13", mutateCase { $0["given"] = ["platform": ["u": 0.5]] })
        try assertRule("S13", mutateCase { $0["note"] = "x"; $0["given"] = ["platform": ["seed": "1"]] })
    }
    func test_S14_unknown_fixture() throws { try assertRule("S14", mutateCase { $0["given"] = ["platform": ["$fixture": "nope"]] }) }
    func test_S15_patch_target_missing() throws {
        try assertRule("S15", mutateCase { $0["given"] = ["platform": ["$fixture": "rec", "patch": [["op": "replace", "path": "/zz", "value": 1]]]] })
    }
    func test_S15_unknown_op() throws {
        try assertRule("S15", mutateCase { $0["given"] = ["platform": ["$fixture": "rec", "patch": [["op": "move", "path": "/b"]]]] })
    }
    func test_S16_uptime_decreases() throws {
        try assertRule("S16", mutateCase { c in var s = c["steps"] as! [[String: Any]]; s[1]["t"] = ["uptime": -1.0]; c["steps"] = s })
    }
    func test_S17_event_time() throws {
        try assertRule("S17", mutateCase { c in var s = c["steps"] as! [[String: Any]]; s[0]["event"] = ["type": "read", "time": 0.0]; c["steps"] = s })
    }
    func test_S18_undeclared_event_type_and_field() throws {
        try assertRule("S18", mutateCase { c in var s = c["steps"] as! [[String: Any]]; s[0]["event"] = ["type": "jump"]; c["steps"] = s })
        try assertRule("S18", mutateCase { c in var s = c["steps"] as! [[String: Any]]; s[0]["event"] = ["type": "read", "speed": 1]; c["steps"] = s })
    }

    func test_patch_ops_resolve() throws {
        let base: JSONValue = .object(["a": .array([.int(1), .int(2)]), "b": .string("x")])
        let ops: [JSONValue] = [
            .object(["op": .string("replace"), "path": .string("/b"), "value": .string("y")]),
            .object(["op": .string("add"), "path": .string("/a/1"), "value": .int(9)]),
            .object(["op": .string("remove-value"), "path": .string("/a"), "value": .int(1)]),
            .object(["op": .string("add"), "path": .string("/c~1d"), "value": .bool(true)]),
        ]
        XCTAssertEqual(try Patch.apply(ops, to: base), .object(["a": .array([.int(9), .int(2)]), "b": .string("y"), "c/d": .bool(true)]))
    }

    func test_compare_tolerance_by_kind_and_exact_otherwise() {
        let e: JSONValue = .object(["value": .double(0.8)]), a: JSONValue = .object(["value": .double(0.8 + 1e-13)])
        XCTAssertNil(Compare.diff(e, a, kindOf: { _ in "gain" }, tolerances: ["gain": 1e-12]))
        XCTAssertNotNil(Compare.diff(e, a))
        XCTAssertEqual(Compare.diff(.array([.int(1), .int(2)]), .array([.int(2), .int(1)]))?.path, "[0]")
    }
}
