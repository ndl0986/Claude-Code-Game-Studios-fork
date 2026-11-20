import ContractKit
import Foundation
import MorphCore
import XCTest

/// morphcore/001 AC-7's build-time test: the shipped `content/data/morph-timing.json` has a valid normal and reduced set.
/// JSON is decoded here, at the edge (Tools), never inside MorphCore (ADR-0002 D2).
final class MorphTimingDataTests: XCTestCase {
    var fileURL: URL {
        get throws {
            try Fixture.contractsRoot(from: #filePath).deletingLastPathComponent().appendingPathComponent("content/data/morph-timing.json")
        }
    }

    /// The edge decoder: a JSON number is `.number`; anything else (string, bool, null, array, object) is `.notNumber`.
    static func values(_ any: Any?) -> [String: TimingValue] {
        guard let dict = any as? [String: Any] else { return [:] }
        return dict.mapValues { v in
            guard let n = v as? NSNumber, CFGetTypeID(n) != CFBooleanGetTypeID() else { return .notNumber }
            return .number(n.doubleValue)
        }
    }

    func load(_ json: Data) throws -> Result<TimingData, TimingRejection> {
        let root = try JSONSerialization.jsonObject(with: json) as? [String: Any]
        return TimingData.load(normal: Self.values(root?["normal"]), reduced: Self.values(root?["reduced"]))
    }

    func test_the_shipped_normal_and_reduced_sets_are_valid() throws {
        let data = try load(Data(contentsOf: fileURL))
        switch data {
        case .failure(let why): XCTFail(why.message)
        case .success(let d):
            let n = d.morphSpec(reducedMotion: false, seed: 0), r = d.morphSpec(reducedMotion: true, seed: 0)
            XCTAssertEqual(n.duration, 2.45, accuracy: 1e-9); XCTAssertEqual(n.count, 240)
            XCTAssertEqual(r.duration, 1.2, accuracy: 1e-9); XCTAssertEqual(r.count, 240)
        }
    }

    func test_a_broken_copy_of_the_shipped_file_fails_the_check() throws {
        // The check can fail: a string where a number belongs, and a missing knob, are each rejected.
        var root = try JSONSerialization.jsonObject(with: Data(contentsOf: fileURL)) as! [String: Any]
        var reduced = root["reduced"] as! [String: Any]
        reduced["flow_s"] = "0.5"
        root["reduced"] = reduced
        guard case .failure(let a) = try load(JSONSerialization.data(withJSONObject: root)) else { return XCTFail("string accepted") }
        XCTAssertEqual(a, TimingRejection(set: "reduced", knob: .flow, reason: .notANumber))
        reduced["flow_s"] = true
        root["reduced"] = reduced
        guard case .failure(let b) = try load(JSONSerialization.data(withJSONObject: root)) else { return XCTFail("bool accepted") }
        XCTAssertEqual(b.reason, .notANumber)
        var normal = root["normal"] as! [String: Any]
        normal.removeValue(forKey: "particles")
        root["normal"] = normal
        guard case .failure(let c) = try load(JSONSerialization.data(withJSONObject: root)) else { return XCTFail("missing accepted") }
        XCTAssertEqual(c, TimingRejection(set: "normal", knob: .particles, reason: .missing))
    }

    func test_the_shipped_file_is_byte_stable_json() throws {
        let text = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(text.hasSuffix("}\n") && !text.hasSuffix("\n\n"), "one trailing newline")
        XCTAssertFalse(text.contains("\r"), "LF only"); XCTAssertFalse(text.contains("\t"), "spaces only")
        var keysBySection: [[String]] = []
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.hasPrefix("  \"") && line.hasSuffix("{") { keysBySection.append([]) }
            else if line.hasPrefix("    \""), let end = line.dropFirst(5).firstIndex(of: "\"") {
                keysBySection[keysBySection.count - 1].append(String(line[line.index(line.startIndex, offsetBy: 5)..<end]))
            }
        }
        XCTAssertEqual(keysBySection.count, 2)
        for keys in keysBySection { XCTAssertEqual(keys, keys.sorted(), "sorted keys"); XCTAssertEqual(keys.count, 9) }
    }
}
