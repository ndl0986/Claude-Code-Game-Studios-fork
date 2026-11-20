import ContractKit
import Foundation
import KidCore
import MorphCore
import ToolsCore
import XCTest

/// The glyph bake (TR-morph-002, ADR-0003 D4, content-pipeline story 002) on the real bundled font,
/// `content/fonts/Fredoka-wdth-wght.ttf`. Bakes go to a fresh temp content dir; nothing under `content/` is written.
final class GlyphBakeTests: XCTestCase {
    var gameRoot: URL { get throws { try Fixture.contractsRoot(from: #filePath).deletingLastPathComponent() } }
    var fontURL: URL { get throws { try gameRoot.appendingPathComponent("content/fonts/\(GlyphSetSpec.fredoka600.fontFile)") } }

    /// A temp content dir holding a copy of `content/fonts/`.
    func tempContent() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("glyphs-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: try gameRoot.appendingPathComponent("content/fonts"), to: dir.appendingPathComponent("fonts"))
        addTeardownBlock { try? FileManager.default.removeItem(at: dir) }
        return dir
    }

    func bytes(_ dir: URL, _ rel: String) throws -> Data { try Data(contentsOf: dir.appendingPathComponent(rel)) }

    func bbox(_ d: String) throws -> (minX: Double, minY: Double, maxX: Double, maxY: Double) {
        let pts = try SVGPath.polylines(d).flatMap { $0 }
        return (pts.map(\.x).min()!, pts.map(\.y).min()!, pts.map(\.x).max()!, pts.map(\.y).max()!)
    }

    // AC-1
    func test_the_bake_writes_36_glyphs_and_a_glyph_set_byte_identical_across_two_runs() throws {
        let a = try tempContent(), b = try tempContent()
        let first = try GlyphBake.bakeContent(contentDir: a), second = try GlyphBake.bakeContent(contentDir: b)
        XCTAssertEqual(first, second)
        XCTAssertEqual(first.count, 37, "36 glyph files plus glyphs.json")
        for rel in first { XCTAssertEqual(try bytes(a, rel), try bytes(b, rel), rel) }
        // A second run into the same folder rewrites the same bytes.
        let before = try first.map { try bytes(a, $0) }
        _ = try GlyphBake.bakeContent(contentDir: a)
        XCTAssertEqual(try first.map { try bytes(a, $0) }, before)

        let set = try GlyphSetDecoder.decode(contentsOf: a.appendingPathComponent("glyphs/fredoka600/glyphs.json"))
        XCTAssertEqual(set.id, "fredoka600")
        XCTAssertEqual(set.fontName, "Fredoka")
        XCTAssertEqual(set.fontVersion, "2.001")
        XCTAssertEqual(set.fontLicence, "OFL-1.1")
        XCTAssertEqual(set.baker, "\(SVGBake.toolName) \(SVGBake.toolVersion)")
        XCTAssertEqual(set.glyphs.keys.sorted(), KeyTable.keys.sorted())
        XCTAssertEqual(set.glyphs["A"], "glyph_fredoka_a.json")
        XCTAssertEqual(set.glyphs["3"], "glyph_fredoka_3.json")
        for (k, f) in set.glyphs {
            XCTAssertNotNil(FileProbe(root: a.appendingPathComponent("glyphs/fredoka600")).pathText(f), "glyph \(k): the validator reads its d")
        }
    }

    // AC-2
    func test_every_baked_glyph_parses_under_the_morph_v1_parser_with_a_non_zero_length() throws {
        let (files, _) = try GlyphBake.bakeSet(fontURL: try fontURL, spec: .fredoka600)
        for key in KeyTable.keys {
            let name = GlyphSetSpec.fredoka600.glyphFileName(key)
            let o = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(try XCTUnwrap(files[name]))) as? [String: Any])
            XCTAssertEqual(Set(o.keys), ["d", "tool", "version"])
            let d = try XCTUnwrap(o["d"] as? String)
            XCTAssertTrue(d.unicodeScalars.allSatisfy { "MLCQZ0123456789.- ".unicodeScalars.contains($0) }, "\(key): only M L C Q Z and plain decimals")
            XCTAssertNil(d.range(of: "Z[^M]", options: .regularExpression), "\(key): an M after every Z that is followed by drawing")
            let lines = try SVGPath.polylines(d)
            XCTAssertTrue(lines.contains { $0.count >= 2 }, key)
            var total = 0.0
            for l in lines { for j in l.indices.dropFirst() { total += hypot(l[j].x - l[j - 1].x, l[j].y - l[j - 1].y) } }
            XCTAssertGreaterThan(total, 0, key)
        }
    }

    // AC-3
    func test_a_key_with_no_glyph_fails_naming_the_key_and_the_font_file_and_writes_nothing() throws {
        let content = try tempContent()
        let missing = "\u{E000}"   // private use: Fredoka has no glyph for it
        XCTAssertThrowsError(try GlyphBake.bakeContent(contentDir: content, keys: ["A", missing, "B"])) { e in
            guard let e = e as? GlyphBakeError else { return XCTFail("not a GlyphBakeError: \(e)") }
            XCTAssertEqual(e.key, missing)
            XCTAssertEqual(e.fontFile, "fonts/Fredoka-wdth-wght.ttf")
            XCTAssertTrue(e.description.contains("fonts/Fredoka-wdth-wght.ttf"), e.description)
            XCTAssertTrue(e.description.contains(missing), e.description)
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: content.appendingPathComponent("glyphs").path), "a failed bake writes nothing")
    }

    func test_the_font_is_used_at_weight_600_in_font_units() throws {
        let (_, facts) = try GlyphBake.openFont(try fontURL, weight: 600, label: "f")
        XCTAssertEqual(facts.weight, 600)
        XCTAssertEqual(facts.unitsPerEm, 1000)
    }

    /// The coordinate convention of the morph contract's committed glyph inputs (font units, y down, baseline at 0):
    /// the re-baked D and 3 have the extent of `morph-contract-v1.json`'s `glyphPath` within 1 font unit.
    func test_glyphs_D_and_3_match_the_morph_contracts_committed_glyph_inputs() throws {
        let fixture = try gameRoot.appendingPathComponent("content/fixtures/morph-contract-v1.json")
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: fixture)) as? [String: Any])
        let cases = try XCTUnwrap(root["cases"] as? [[String: Any]])
        let (font, _) = try GlyphBake.openFont(try fontURL, weight: 600, label: "f")
        for (key, id) in [("D", "D-dinosaur"), ("3", "3-relative")] {
            let committed = try XCTUnwrap(cases.first { $0["id"] as? String == id }?["glyphPath"] as? String)
            let want = try bbox(committed), got = try bbox(try GlyphBake.path(font: font, key: key, label: "f"))
            for (w, g) in [(want.minX, got.minX), (want.minY, got.minY), (want.maxX, got.maxX), (want.maxY, got.maxY)] {
                XCTAssertEqual(g, w, accuracy: 1, "\(key): extent \(got) vs committed \(want)")
            }
        }
    }
}
