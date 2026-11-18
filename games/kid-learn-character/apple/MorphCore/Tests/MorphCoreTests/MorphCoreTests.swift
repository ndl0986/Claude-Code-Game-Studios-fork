import XCTest
@testable import MorphCore

final class MorphCoreTests: XCTestCase {
    func test_splitmix_first_outputs_are_stable() {
        var a = SplitMix64(seed: 42), b = SplitMix64(seed: 42)
        XCTAssertEqual((0..<8).map { _ in a.next() }, (0..<8).map { _ in b.next() })
        var u = SplitMix64(seed: 7)
        for _ in 0..<1000 { let v = u.nextUnit(); XCTAssertTrue(v >= 0 && v < 1) }
    }

    func test_parse_errors() {
        XCTAssertThrowsError(try SVGPath.polylines("M 0 0 A 1 1 0 0 1 2 2")) // arcs are outside v1
        XCTAssertThrowsError(try SVGPath.polylines("M 0")) { XCTAssertEqual($0 as? SVGPath.ParseError, .missingNumber("M")) }
        XCTAssertThrowsError(try SVGPath.polylines("M 0 0 Z 5"))
    }

    func test_number_splitting_rules() throws {
        // '-' after a digit starts a number; '.' after a '.' or an exponent starts a number (contract §2).
        XCTAssertEqual(try SVGPath.polylines("M0 0L1-1"), [[Pt(0, 0), Pt(1, -1)]])
        XCTAssertEqual(try SVGPath.polylines("M0 0L.5.5"), [[Pt(0, 0), Pt(0.5, 0.5)]])
        XCTAssertEqual(try SVGPath.polylines("M0 0L1e-1 2"), [[Pt(0, 0), Pt(0.1, 2)]])
    }

    func test_positions_at_the_phase_ends() throws {
        let spec = MorphSpec(count: 12, seed: 1, glow: 0.8, dissolve: 0.4, travel: 1.25, spread: 0.35, drift: 0.02, swirl: 0.1)
        let m = try Morph(spec: spec, glyphPath: "M0 0 L1 0 L1 1 L0 1 Z", silhouettePath: "M0 0 L2 0 L1 2 Z")
        for i in 0..<spec.count {
            XCTAssertEqual(m.position(i, at: 0), m.from[i])
            XCTAssertEqual(m.position(i, at: spec.duration).x, m.to[m.pairing[i]].x, accuracy: 1e-12)
            XCTAssertEqual(m.position(i, at: spec.duration).y, m.to[m.pairing[i]].y, accuracy: 1e-12)
        }
    }
}
