import Foundation
import XCTest
@testable import ToolsCore

/// Story content-pipeline/004: the silhouette raster check (ADR-0003 D4).
final class RasterCheckTests: XCTestCase {
    /// A baked cast file: one part with a body rectangle and an outline rectangle stroked `width` wide.
    static func cast(rect r: (x: Double, y: Double, w: Double, h: Double), strokeWidth: Double = 0) -> [UInt8] {
        let d = "M\(r.x) \(r.y)L\(r.x + r.w) \(r.y)L\(r.x + r.w) \(r.y + r.h)L\(r.x) \(r.y + r.h)Z"
        var layers: [[String: Any]] = [["layer": "body", "opacity": 1, "shapes": [["d": d, "fill": "#88aa66"]]]]
        if strokeWidth > 0 {
            layers.append(["layer": "outline", "opacity": 1, "shapes": [["d": d, "fill": "none", "stroke": "#223322",
                                                                          "strokeWidth": strokeWidth, "strokeLinejoin": "miter"]]])
        }
        let o: [String: Any] = ["artboard": ["width": 100, "height": 100],
                                "parts": [["id": "body", "parent": NSNull(), "pivot": [50, 50], "layers": layers]],
                                "tool": "test", "version": 1]
        return Array(try! JSONSerialization.data(withJSONObject: o, options: [.sortedKeys]))
    }

    static func sil(rect r: (x: Double, y: Double, w: Double, h: Double)) -> [UInt8] {
        let d = "M\(r.x) \(r.y)L\(r.x + r.w) \(r.y)L\(r.x + r.w) \(r.y + r.h)L\(r.x) \(r.y + r.h)Z"
        return Array(try! JSONSerialization.data(withJSONObject: ["d": d]))
    }

    func test_a_matching_cast_and_silhouette_pass() throws {
        let r = try RasterCheck.compare(castJSON: Self.cast(rect: (20, 20, 60, 50)), silhouetteJSON: Self.sil(rect: (20, 20, 60, 50)))
        XCTAssertTrue(r.pass)
        XCTAssertEqual(r.outsideBand, 0)
    }

    func test_a_silhouette_offset_by_3_units_fails_naming_the_file() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("raster-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir.appendingPathComponent("cast"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dir.appendingPathComponent("sil"), withIntermediateDirectories: true)
        try Data(Self.cast(rect: (20, 20, 60, 50))).write(to: dir.appendingPathComponent("cast/cast_x.json"))
        try Data(Self.sil(rect: (23, 20, 60, 50))).write(to: dir.appendingPathComponent("sil/sil_x.json"))
        let (fails, na) = RasterCheck.check(themeDir: dir, pairs: [("cast/cast_x.json", "sil/sil_x.json")])
        XCTAssertEqual(na, [])
        XCTAssertEqual(fails.count, 1)
        XCTAssertTrue(fails[0].hasPrefix("sil/sil_x.json vs cast/cast_x.json"), fails[0])
    }

    func test_a_1_unit_offset_stays_inside_the_edge_band() throws {
        let r = try RasterCheck.compare(castJSON: Self.cast(rect: (20, 20, 60, 50)), silhouetteJSON: Self.sil(rect: (21, 20, 60, 50)))
        XCTAssertGreaterThan(r.differing, 0)
        XCTAssertTrue(r.pass)
    }

    func test_the_outer_half_of_the_outline_stroke_counts() throws {
        // A 6-unit outline adds 3 units outside the 60 x 50 body: the silhouette must be the 66 x 56 rectangle.
        let art = Self.cast(rect: (20, 20, 60, 50), strokeWidth: 6)
        XCTAssertTrue(try RasterCheck.compare(castJSON: art, silhouetteJSON: Self.sil(rect: (17, 17, 66, 56))).pass)
        XCTAssertFalse(try RasterCheck.compare(castJSON: art, silhouetteJSON: Self.sil(rect: (20, 20, 60, 50))).pass,
                       "the body alone misses the outer half of the stroke")
        XCTAssertFalse(try RasterCheck.compare(castJSON: art, silhouetteJSON: Self.sil(rect: (14, 14, 72, 62))).pass,
                       "the full stroke width is too big: only the outer half counts")
    }

    func test_a_cast_file_that_is_not_the_baked_layout_is_not_assessed() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("raster-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: dir.appendingPathComponent("c.json"))
        try Data(Self.sil(rect: (0, 0, 1, 1))).write(to: dir.appendingPathComponent("s.json"))
        let (fails, na) = RasterCheck.check(themeDir: dir, pairs: [("c.json", "s.json")])
        XCTAssertEqual(fails, [])
        XCTAssertEqual(na.count, 1)
        XCTAssertTrue(na[0].hasPrefix("NOT ASSESSED raster s.json vs c.json"), na[0])
    }

    /// The six batch-1 Dinosaurs pairs, baked from `src/` in memory, against their silhouettes.
    func test_batch_1_baked_pairs_pass_the_raster_check() throws {
        let src = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../../content/themes/dinosaurs/src").standardized
        let art = try FileManager.default.contentsOfDirectory(atPath: src.appendingPathComponent("art").path).filter { $0.hasSuffix(".svg") }.sorted()
        XCTAssertEqual(art.count, 6)
        var report: [String] = []
        for a in art {
            let stem = String(a.dropFirst("cast_".count).dropLast(".svg".count))
            let castSVG = try String(contentsOf: src.appendingPathComponent("art/\(a)"), encoding: .utf8)
            let silSVG = try String(contentsOf: src.appendingPathComponent("sil/sil_\(stem).svg"), encoding: .utf8)
            let r = try RasterCheck.compare(castJSON: try SVGBake.bakeCast(svg: castSVG, file: a),
                                            silhouetteJSON: try SVGBake.bakeSilhouette(svg: silSVG, file: "sil_\(stem).svg"))
            if !r.pass { report.append("\(stem): \(r.outsideBand) px outside the band, first at \(r.firstOutside!), \(r.differing) differ") }
        }
        XCTAssertEqual(report, [], report.joined(separator: "\n"))
    }
}
