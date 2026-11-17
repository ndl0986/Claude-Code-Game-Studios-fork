// PROTOTYPE - NOT FOR PRODUCTION (TASK-033 spike)
import XCTest
@testable import MorphCore

final class MorphCoreTests: XCTestCase {
    let fixtures = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../fixtures").standardized

    func test_splitmix64_reference_values() {
        // Reference outputs for seed 0 (published with the algorithm, e.g. the xoshiro authors' splitmix64.c)
        var r = SplitMix64(seed: 0)
        XCTAssertEqual(r.next(), 0xE220_A839_7B1D_CDAF)
        XCTAssertEqual(r.next(), 0x6E78_9E6A_A1B9_65F4)
        XCTAssertEqual(r.next(), 0x06C4_5D18_8009_454F)
    }

    func test_svg_subset_parses_relative_and_absolute() throws {
        let a = try SVGPath.polylines("M0 0L10 0L10 10Z"), b = try SVGPath.polylines("m0 0l10 0l0 10z")
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.first?.count, 4, "Z closes back to the start")
        XCTAssertEqual(try SVGPath.polylines("M0,0 H5 V5 h-5 z").first?.count, 5)
        XCTAssertEqual(try SVGPath.polylines("M0 0Q5 5 10 0").first?.count, 1 + SVGPath.curveSegments)
    }

    func test_sampling_is_even_by_arc_length_and_normalised() throws {
        let p = try SVGPath.sample("M0 0L100 0", count: 4)
        // 4 points at x 0, 25, 50, 75 (the start, then every quarter), in the path's box 0…100: (x − 50) / 100
        let want = [-0.5, -0.25, 0, 0.25]
        for (g, w) in zip(p.map(\.x), want) { XCTAssertEqual(g, w, accuracy: 1e-12) }
    }

    func test_ends_on_the_glyph_and_the_silhouette() throws {
        let spec = MorphSpec(count: 50, seed: 7, glow: 0.4, dissolve: 0.3, travel: 1, spread: 0.3, drift: 0.05, swirl: 0.3, hold: 3)
        let m = try Morph(spec: spec, glyphPath: "M0 0L100 0L100 100Z", silhouettePath: "M0 0L50 80L-50 80Z")
        XCTAssertEqual(m.positions(at: 0), m.from)
        let end = m.positions(at: spec.duration)
        for i in 0..<spec.count { XCTAssertEqual(end[i], m.to[m.pairing[i]]) }
        XCTAssertEqual(Set(m.pairing), Set(0..<spec.count), "a permutation")
    }

    /// The shared fixture: re-running the recipe from its inputs reproduces every stored position (Kotlin: 1e-3).
    func test_shared_fixture_matches() throws {
        let o = try JSONSerialization.jsonObject(with: Data(contentsOf: fixtures.appendingPathComponent("morph-D-dinosaur.json"))) as! [String: Any]
        let s = o["spec"] as! [String: Any]
        let spec = MorphSpec(count: s["count"] as! Int, seed: (s["seed"] as! NSNumber).uint64Value, glow: s["glow"] as! Double, dissolve: s["dissolve"] as! Double,
                             travel: s["travel"] as! Double, spread: s["spread"] as! Double, drift: s["drift"] as! Double, swirl: s["swirl"] as! Double, hold: s["hold"] as! Double)
        let m = try Morph(spec: spec, glyphPath: o["glyphPath"] as! String, silhouettePath: o["silhouettePath"] as! String)
        let times = o["times"] as! [Double], positions = o["positions"] as! [[[Double]]]
        for (k, t) in times.enumerated() {
            let got = m.positions(at: t)
            XCTAssertEqual(got.count, positions[k].count)
            for (i, e) in positions[k].enumerated() {
                XCTAssertEqual(got[i].x, e[0], accuracy: 1e-6, "t \(t) particle \(i)"); XCTAssertEqual(got[i].y, e[1], accuracy: 1e-6)
            }
        }
    }
}
