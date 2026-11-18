import ContractKit
import Foundation
import KidCore
import ToolsCore
import XCTest

/// key-table-schema-v1, `file` layer (ADR-0004 D3, D5): theme-file bytes → Tools' decoder → the model, compared with
/// the named fixture decoded the same way. Same discovery and failure format as the KidCore harness.
final class KeyTableFileLayerTests: XCTestCase {
    static let contract = "key-table-schema-v1"
    static let declaration = ContractDeclaration(
        givenFields: ["theme", "assets", "glyphSet", "buildSettings", "state", "themeBytes"],
        events: ["validate": [], "pick": ["n", "last", "weights"], "nextU": ["stream"], "resolve": ["key"], "peek": ["key"],
                 "themeChanged": ["theme"], "keysInOrder": [], "titleCast": [], "decodeTheme": []],
        layers: ["model", "file"])

    /// ContractKit's value → KidCore's parser value (object member order is not meaningful here).
    static func canonical(_ v: JSONValue) -> CanonicalJSON.Value {
        switch v {
        case .null: return .null
        case .bool(let b): return .bool(b)
        case .int(let i): return .number(Double(i))
        case .double(let d): return .number(d)
        case .string(let s): return .string(s)
        case .array(let a): return .array(a.map(canonical))
        case .object(let o): return .object(o.keys.sorted().map { (key: $0, value: canonical(o[$0]!)) })
        }
    }

    /// Runs every file-layer case; returns the failures and the pass count.
    static func run(file url: URL) -> (failures: [String], pass: Int, ran: Int) {
        let name = "\(contract)/\(url.lastPathComponent)"
        guard let root = try? Fixture.load(url) else { return (["\(name): unreadable"], 0, 0) }
        let schema = StructuralCheck.check(root, directory: contract, file: name, declaration: declaration)
        if !schema.isEmpty { return (schema.map(\.description), 0, 0) }
        var fixtures: [String: JSONValue] = [:]
        if case .object(let f)? = root["fixtures"] { fixtures = f }
        var failures: [String] = [], pass = 0, ran = 0
        for c in root["cases"]?.array ?? [] where c["layer"]?.string == "file" {
            ran += 1
            let head = "\(contract)/\(c["id"]?.string ?? "?") [\(c["source"]?.string ?? "?")]"
            let bytes = Array((c["given"]?["themeBytes"]?.string ?? "").utf8)
            var msg: String?
            for (j, s) in (c["steps"]?.array ?? []).enumerated() {
                guard s["event"]?["type"]?.string == "decodeTheme" else { msg = "\(head) steps[\(j)]: not a file-layer event"; break }
                let got: JSONValue
                do {
                    let m = try ThemeDecoder.decode(bytes)
                    let want = s["expect"]?.array?.first
                    var fixture = fixtures[want?["equalsFixture"]?.string ?? ""] ?? .null
                    if case .object(var o) = fixture { for f in want?["without"]?.array ?? [] { o[f.string ?? ""] = nil }; fixture = .object(o) }
                    let expectedModel = try? ThemeDecoder.decode(canonical(fixture))
                    var out: [String: JSONValue] = ["out": .string("model"),
                                                    "equalsFixture": m == expectedModel ? (want?["equalsFixture"] ?? .null) : .string("(differs)")]
                    if want?["keyOrder"] != nil { out["keyOrder"] = .array(m.keyOrder.map { .string($0) }) }
                    if let w = want?["without"] { out["without"] = w }
                    got = .array([.object(out)])
                } catch let e as ThemeDecoder.DecodeError {
                    got = .array([.object(["out": .string("decodeError"), "field": .string(e.field)])])
                } catch { got = .array([.object(["out": .string("decodeError"), "field": .string("?")])]) }
                if let d = Compare.diff(.array(s["expect"]?.array ?? []), got, path: "steps[\(j)].expect") {
                    msg = "\(head) \(d.path): expected \(d.expected), got \(d.actual) (tol \(d.tolerance))"
                    break
                }
            }
            if let msg { failures.append(msg) } else { pass += 1 }
        }
        if ran == 0 { failures.append("\(name): 0 file-layer cases (ADR-0004 D3)") }
        return (failures, pass, ran)
    }

    func test_key_table_schema_v1_file_layer() throws {
        // K-40: the registry decides; this harness runs only if the row names it.
        let root = try Fixture.contractsRoot(from: #filePath)
        let reg = ContractRegistry(readme: (try? String(contentsOf: root.appendingPathComponent("README.md"), encoding: .utf8)) ?? "")
        guard case .runner(let names)? = reg.entries[Self.contract]?.row, names.contains("Tools.KeyTableFileLayer") else {
            return XCTFail("\(Self.contract): the registry row does not name Tools.KeyTableFileLayer (K-40)")
        }
        let url = root.appendingPathComponent("\(Self.contract)/cases.json")
        let r = Self.run(file: url)
        print("CONTRACT \(Self.contract) [file]: \(r.pass) pass, \(r.failures.count) fail")
        for f in r.failures { XCTFail(f) }
    }

    func test_a_wrong_expected_field_fails() throws {
        // ADR-0004 V2 for this harness: a planted wrong expectation is caught with its field path.
        let src = try Fixture.contractsRoot(from: #filePath).appendingPathComponent("\(Self.contract)/cases.json")
        var text = try String(contentsOf: src, encoding: .utf8)
        text = text.replacingOccurrences(of: #""field": "extraField""#, with: #""field": "planted""#)
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("kt-\(UUID().uuidString).json")
        try text.write(to: tmp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmp) }
        // The structural check needs the directory name, so check the decode path directly.
        let r = Self.run(file: tmp)
        XCTAssertTrue(r.failures.contains { $0.contains("expected \"planted\", got \"extraField\"") }, "\(r.failures)")
    }

    func test_decoder_rejects_unknown_and_missing_and_wrong_type() {
        XCTAssertThrowsError(try ThemeDecoder.decode(Array(#"{"x":1}"#.utf8))) { XCTAssertEqual(($0 as? ThemeDecoder.DecodeError)?.field, "x") }
        XCTAssertThrowsError(try ThemeDecoder.decode(Array(#"{}"#.utf8))) { XCTAssertEqual(($0 as? ThemeDecoder.DecodeError)?.field, "schemaVersion") }
    }
}
