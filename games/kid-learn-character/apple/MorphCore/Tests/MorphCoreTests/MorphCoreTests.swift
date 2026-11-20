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

    // MARK: story morphcore/002

    private let squarePath = "M0 0 L10 0 L10 10 L0 10 Z"
    private func testSpec(seed: UInt64 = 42) -> MorphSpec {
        MorphSpec(count: 16, seed: seed, glow: 0.45, dissolve: 0.35, travel: 1.1, spread: 0.35, drift: 0.06, swirl: 0.35)
    }

    /// AC-9: empty or unparsable input builds no morph, never throws, and names the missing side.
    func test_empty_or_unparsable_paths_build_no_morph_and_name_the_side() {
        let spec = testSpec()
        let bad = ["", "M 5 5", "M 0 0 L 0 0", "M 0 0 A 1 1 0 0 1 2 2", "not a path"]
        for b in bad {
            guard case .noMorph(let g) = Morph.build(spec: spec, glyphPath: b, silhouettePath: squarePath) else { return XCTFail(b) }
            XCTAssertEqual(g, .glyph, b)
            guard case .noMorph(let s) = Morph.build(spec: spec, glyphPath: squarePath, silhouettePath: b) else { return XCTFail(b) }
            XCTAssertEqual(s, .silhouette, b)
            guard case .noMorph(let both) = Morph.build(spec: spec, glyphPath: b, silhouettePath: b) else { return XCTFail(b) }
            XCTAssertEqual(both, .both, b)
        }
        XCTAssertNotNil(Morph.build(spec: spec, glyphPath: squarePath, silhouettePath: squarePath).morph)
        XCTAssertNil(Morph.build(spec: spec, glyphPath: "", silhouettePath: squarePath).morph)
    }

    /// AC-3: the declared contract id equals the fixture's `contract` field.
    func test_declared_contract_id_matches_the_fixture() throws {
        let file = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("../../../../content/fixtures/morph-contract-v1.json").standardized
        let o = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [String: Any]
        XCTAssertEqual(morphContractID, "morph-v1")
        XCTAssertEqual(morphContractID, o["contract"] as? String)
    }

    /// AC-4: building the same morph twice gives identical results (no clock, no hidden state).
    func test_building_the_same_morph_twice_is_identical() throws {
        let a = try XCTUnwrap(Morph.build(spec: testSpec(), glyphPath: squarePath, silhouettePath: "M0 0 L10 5 L0 10 Z").morph)
        let b = try XCTUnwrap(Morph.build(spec: testSpec(), glyphPath: squarePath, silhouettePath: "M0 0 L10 5 L0 10 Z").morph)
        XCTAssertEqual(a.from, b.from); XCTAssertEqual(a.to, b.to); XCTAssertEqual(a.pairing, b.pairing)
        XCTAssertEqual(a.drift, b.drift); XCTAssertEqual(a.delay, b.delay); XCTAssertEqual(a.bow, b.bow)
        for s in [0.0, 0.3, 0.625, 1.0, 1.9, 5.0] { XCTAssertEqual(a.positions(at: s), b.positions(at: s), "s \(s)") }
    }

    /// AC-12: two presses of the same key differ; the same (key, count) repeats; different keys differ.
    func test_seed_differs_per_press_of_the_same_key() {
        XCTAssertNotEqual(morphSeed(key: "D", pressCount: 0), morphSeed(key: "D", pressCount: 1))
        XCTAssertNotEqual(morphSeed(key: "D", pressCount: 1), morphSeed(key: "D", pressCount: 2))
    }

    func test_seed_is_the_same_for_the_same_key_and_count() {
        XCTAssertEqual(morphSeed(key: "D", pressCount: 5), morphSeed(key: "D", pressCount: 5))
    }

    func test_seed_differs_between_keys_at_the_same_count() {
        XCTAssertNotEqual(morphSeed(key: "D", pressCount: 3), morphSeed(key: "B", pressCount: 3))
    }

    func test_seed_golden_value_pins_the_derivation() {
        // Regression pin: computed once from this implementation. If it fails, every morph changed.
        XCTAssertEqual(morphSeed(key: "D", pressCount: 0), 0x9921_a6c9_e27f_26fa)
    }
}
