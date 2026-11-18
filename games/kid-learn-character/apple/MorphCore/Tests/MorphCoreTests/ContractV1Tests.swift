// morph-contract-v1: the shared fixture (content/fixtures/morph-contract-v1.json) reproduces from its inputs.
// The contract's tolerance is ±1e-3 (morph-contract-v1 §6); this port, the reference, matches to 1e-9.
import Foundation
import XCTest
@testable import MorphCore

final class ContractV1Tests: XCTestCase {
    /// apple/MorphCore/Tests/MorphCoreTests/ → games/kid-learn-character/content/fixtures/.
    let file = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("../../../../content/fixtures/morph-contract-v1.json").standardized

    func test_every_case_reproduces() throws {
        let o = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [String: Any]
        XCTAssertEqual(o["contract"] as? String, "morph-v1")
        let cases = o["cases"] as! [[String: Any]]
        XCTAssertEqual(cases.count, 4)
        for c in cases {
            let id = c["id"] as! String, s = c["spec"] as! [String: Any]
            let spec = MorphSpec(count: s["count"] as! Int, seed: UInt64(s["seed"] as! String)!,
                                 glow: s["glow"] as! Double, dissolve: s["dissolve"] as! Double,
                                 travel: s["travel"] as! Double, spread: s["spread"] as! Double,
                                 drift: s["drift"] as! Double, swirl: s["swirl"] as! Double)
            var rng = SplitMix64(seed: spec.seed)
            XCTAssertEqual((c["rngFirst4"] as! [String]).map { UInt64($0)! }, (0..<4).map { _ in rng.next() }, id)
            let m = try Morph(spec: spec, glyphPath: c["glyphPath"] as! String, silhouettePath: c["silhouettePath"] as! String)
            XCTAssertEqual(m.pairing, c["pairing"] as! [Int], id)
            for (k, t) in (c["times"] as! [Double]).enumerated() {
                let want = (c["positions"] as! [[[Double]]])[k], got = m.positions(at: t)
                XCTAssertEqual(got.count, want.count, id)
                for (i, w) in want.enumerated() {
                    XCTAssertEqual(got[i].x, w[0], accuracy: 1e-9, "\(id) t \(t) #\(i)")
                    XCTAssertEqual(got[i].y, w[1], accuracy: 1e-9, "\(id) t \(t) #\(i)")
                }
            }
        }
    }

    func test_tokenizer_cases() throws {
        let o = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [String: Any]
        let cases = o["tokenizer"] as! [[String: Any]]
        XCTAssertFalse(cases.isEmpty)
        for t in cases {
            let want = (t["polylines"] as! [[[Double]]]).map { $0.map { Pt($0[0], $0[1]) } }
            XCTAssertEqual(try SVGPath.polylines(t["d"] as! String), want, t["d"] as! String)
        }
    }
}
