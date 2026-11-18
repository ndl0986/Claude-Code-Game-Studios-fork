import ContractKit
import Foundation
import XCTest

final class FixtureTests: XCTestCase {
    func test_finds_contracts_and_decodes_the_morph_fixture() throws {
        let root = try Fixture.contractsRoot(from: #filePath)
        let v = try Fixture.load(root.deletingLastPathComponent().appendingPathComponent("content/fixtures/morph-contract-v1.json"))
        XCTAssertNotNil(v.array ?? v["cases"]?.array ?? (v == .null ? nil : [v]))
    }

    func test_numbers_keep_int_and_double_and_bool() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ck-\(ProcessInfo.processInfo.processIdentifier).json")
        try Data(#"{"i": 3, "d": 0.5, "b": true, "s": "A"}"#.utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let v = try Fixture.load(url)
        XCTAssertEqual(v["i"], .int(3)); XCTAssertEqual(v["d"], .double(0.5)); XCTAssertEqual(v["b"], .bool(true))
        XCTAssertEqual(v["s"]?.string, "A")
    }

    func test_missing_file_is_an_error() {
        XCTAssertThrowsError(try Fixture.load(URL(fileURLWithPath: "/nonexistent/x.json")))
    }
}
