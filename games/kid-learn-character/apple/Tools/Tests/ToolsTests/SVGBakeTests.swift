import ContractKit
import Foundation
import MorphCore
import ToolsCore
import XCTest

/// The SVG-subset bake (TR-cast-001, ADR-0003 D4, content-pipeline story 001). Test SVGs are inline strings laid out so
/// that the shape under test is always on line 4 (see `cast(_:)`).
final class SVGBakeTests: XCTestCase {
    /// A one-part cast SVG: `shape` is line 4, the other two layers are empty groups.
    func cast(_ shape: String, root: String = "", partAttrs: String = "data-pivot=\"10 20\"", bodyAttrs: String = "") -> String {
        """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"\(root)>
          <g id="head" \(partAttrs)>
            <g id="head_body"\(bodyAttrs)>
              \(shape)
            </g>
            <g id="head_outline"></g>
            <g id="head_detail"></g>
          </g>
        </svg>
        """
    }

    let okPath = "<path d=\"M0 0L10 0L10 10Z\" fill=\"#ff0000\"/>"

    func json(_ bytes: [UInt8]) throws -> [String: Any] { try XCTUnwrap(JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any]) }
    func text(_ bytes: [UInt8]) -> String { String(decoding: bytes, as: UTF8.self) }

    /// All shape `d` strings of a baked cast file.
    func shapeData(_ bytes: [UInt8]) throws -> [String] {
        let parts = try XCTUnwrap(json(bytes)["parts"] as? [[String: Any]])
        return parts.flatMap { ($0["layers"] as! [[String: Any]]).flatMap { ($0["shapes"] as! [[String: Any]]).map { $0["d"] as! String } } }
    }

    func assertRejected(_ svg: String, element: String, attribute: String?, line: Int, sil: Bool = false,
                        file: StaticString = #filePath, at: UInt = #line) {
        XCTAssertThrowsError(try sil ? SVGBake.bakeSilhouette(svg: svg, file: "t.svg") : SVGBake.bakeCast(svg: svg, file: "t.svg"), file: file, line: at) { e in
            guard let e = e as? SVGBakeError else { return XCTFail("not an SVGBakeError: \(e)", file: file, line: at) }
            XCTAssertEqual(e.element, element, "\(e)", file: file, line: at)
            XCTAssertEqual(e.attribute, attribute, "\(e)", file: file, line: at)
            XCTAssertEqual(e.line, line, "\(e)", file: file, line: at)
            XCTAssertTrue(e.description.contains("<\(element)>") && e.description.contains(":\(line):") && e.description.contains("t.svg"), "\(e)", file: file, line: at)
            if let a = attribute { XCTAssertTrue(e.description.contains("'\(a)'"), "\(e)", file: file, line: at) }
        }
    }

    // MARK: AC-1: bakes, byte-stable

    func test_a_cast_svg_in_the_subset_bakes_and_baking_twice_gives_identical_bytes() throws {
        let svg = cast("\(okPath)<circle cx=\"5\" cy=\"5\" r=\"3\" stroke=\"rgb(0, 0, 0)\" stroke-width=\"2\"/>")
        let a = try SVGBake.bakeCast(svg: svg), b = try SVGBake.bakeCast(svg: svg)
        XCTAssertEqual(a, b)
        XCTAssertFalse(a.isEmpty)
    }

    func test_a_silhouette_svg_in_the_subset_bakes_and_baking_twice_gives_identical_bytes() throws {
        let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\"><path fill=\"#000000\" d=\"M0 0L10 0L10 10Z\"/></svg>"
        XCTAssertEqual(try SVGBake.bakeSilhouette(svg: svg), try SVGBake.bakeSilhouette(svg: svg))
        XCTAssertEqual(try json(SVGBake.bakeSilhouette(svg: svg))["d"] as? String, "M0 0L10 0L10 10Z")
    }

    func test_the_baked_file_has_sorted_keys_lf_endings_and_the_tool_name_and_version() throws {
        let t = text(try SVGBake.bakeCast(svg: cast(okPath)))
        XCTAssertFalse(t.contains("\r"))
        XCTAssertTrue(t.hasSuffix("}\n"))
        XCTAssertTrue(t.contains("\"tool\": \"\(SVGBake.toolName)\""))
        XCTAssertTrue(t.contains("\"version\": \"\(SVGBake.toolVersion)\""))
        let artboard = try XCTUnwrap(t.range(of: "\"artboard\"")), parts = try XCTUnwrap(t.range(of: "\"parts\"")), tool = try XCTUnwrap(t.range(of: "\"tool\""))
        XCTAssertTrue(artboard.lowerBound < parts.lowerBound && parts.lowerBound < tool.lowerBound)
        let shape = try XCTUnwrap(t.range(of: "\"d\":")), fill = try XCTUnwrap(t.range(of: "\"fill\":")), width = try XCTUnwrap(t.range(of: "\"strokeWidth\""))
        XCTAssertTrue(shape.lowerBound < fill.lowerBound && fill.lowerBound < width.lowerBound)
        let sil = text(try SVGBake.bakeSilhouette(svg: "<svg viewBox=\"0 0 9 9\"><path d=\"M0 0L5 5\"/></svg>"))
        XCTAssertEqual(sil, "{\n  \"d\": \"M0 0L5 5\",\n  \"tool\": \"\(SVGBake.toolName)\",\n  \"version\": \"\(SVGBake.toolVersion)\"\n}\n")
    }

    func test_numbers_have_at_most_three_decimals_no_exponent_and_no_trailing_zeros() throws {
        let svg = "<svg viewBox=\"0 0 9 9\"><path d=\"M0.12345 1.5000L-0.0004 100.0006L1e2 0Z\"/></svg>"
        XCTAssertEqual(try json(SVGBake.bakeSilhouette(svg: svg))["d"] as? String, "M0.123 1.5L0 100.001L100 0Z")
    }

    func test_shapes_convert_to_morph_v1_commands_with_the_transform_baked_in() throws {
        let shapes = """
        <rect x="0" y="0" width="10" height="5" transform="translate(1 2)"/>\
        <circle cx="0" cy="0" r="2"/><ellipse cx="0" cy="0" rx="3" ry="1"/><line x1="0" y1="0" x2="4" y2="5"/>\
        <polyline points="0,0 1,1 2,0" fill="none" stroke="#000"/><polygon points="0 0 5 0 5 5"/>\
        <path d="m1 1 2 0 0 2 q1 1 2 0 s1 1 2 0 t2 0 z"/>
        """
        let ds = try shapeData(SVGBake.bakeCast(svg: cast(shapes)))
        XCTAssertEqual(ds.count, 7)
        XCTAssertEqual(ds[0], "M1 2H11V7H1Z")
        for d in ds { XCTAssertTrue(d.allSatisfy { !$0.isLetter || "MLHVCQZ".contains($0) }, d) }
        XCTAssertEqual(ds[1].first, "M")
        XCTAssertEqual(ds[1].filter { $0 == "C" }.count, 4, "a circle is four cubic quarters")
    }

    func test_a_rotate_matrix_is_decomposed_and_applied() throws {
        let d = try shapeData(SVGBake.bakeCast(svg: cast("<path d=\"M0 0L10 0\" transform=\"matrix(0 1 -1 0 5 5)\"/>")))
        XCTAssertEqual(d, ["M5 5V15"])
        let rot = try shapeData(SVGBake.bakeCast(svg: cast("<path d=\"M10 0L20 0\" transform=\"rotate(90)\"/>")))
        XCTAssertEqual(rot, ["M0 10V20"])
        let sc = try shapeData(SVGBake.bakeCast(svg: cast("<path d=\"M1 1L2 1\" transform=\"translate(10) scale(2 3)\"/>")))
        XCTAssertEqual(sc, ["M12 3H14"])
    }

    func test_ignored_elements_and_an_empty_defs_are_not_baked() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
          <title>t</title><desc>d</desc><metadata><any/></metadata><defs></defs>
          <g id="head" data-pivot="1 2"><defs/>
            <g id="head_body">\(okPath)</g><g id="head_outline"/><g id="head_detail"/>
          </g>
        </svg>
        """
        XCTAssertEqual(try shapeData(SVGBake.bakeCast(svg: svg)), ["M0 0H10V10Z"])
    }

    func test_bake_content_writes_cast_and_sil_beside_the_source_names_and_is_stable() throws {
        let content = FileManager.default.temporaryDirectory.appendingPathComponent("bake-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: content) }
        let theme = content.appendingPathComponent("themes/tt")
        for d in ["src/art", "src/sil"] { try FileManager.default.createDirectory(at: theme.appendingPathComponent(d), withIntermediateDirectories: true) }
        try cast(okPath).write(to: theme.appendingPathComponent("src/art/cast_tt_a_x_01.svg"), atomically: true, encoding: .utf8)
        try "<svg viewBox=\"0 0 9 9\"><path d=\"M0 0L5 5\"/></svg>".write(to: theme.appendingPathComponent("src/sil/sil_tt_a_x_01.svg"), atomically: true, encoding: .utf8)
        try "<svg viewBox=\"0 0 9 9\"><use/></svg>".write(to: theme.appendingPathComponent("src/art/cast_tt_b_bad_01.svg"), atomically: true, encoding: .utf8)
        let r = SVGBake.bakeContent(contentDir: content)
        XCTAssertEqual(r.baked, ["themes/tt/cast/cast_tt_a_x_01.json", "themes/tt/sil/sil_tt_a_x_01.json"])
        XCTAssertEqual(r.failures.count, 1)
        XCTAssertTrue(r.failures[0].contains("cast_tt_b_bad_01.svg:1: <use>"), "\(r.failures)")
        XCTAssertFalse(FileManager.default.fileExists(atPath: theme.appendingPathComponent("cast/cast_tt_b_bad_01.json").path))
        let first = try Data(contentsOf: theme.appendingPathComponent("cast/cast_tt_a_x_01.json"))
        _ = SVGBake.bakeContent(contentDir: content)
        XCTAssertEqual(try Data(contentsOf: theme.appendingPathComponent("cast/cast_tt_a_x_01.json")), first)
    }

    // MARK: AC-2: each out-of-subset construct names element, attribute and line

    func test_use_is_rejected() { assertRejected(cast("<use href=\"#x\"/>"), element: "use", attribute: nil, line: 4) }
    func test_symbol_is_rejected() { assertRejected(cast("<symbol id=\"s\"/>"), element: "symbol", attribute: nil, line: 4) }
    func test_pattern_is_rejected() { assertRejected(cast("<pattern/>"), element: "pattern", attribute: nil, line: 4) }
    func test_mask_is_rejected() { assertRejected(cast("<mask/>"), element: "mask", attribute: nil, line: 4) }
    func test_clipPath_is_rejected() { assertRejected(cast("<clipPath/>"), element: "clipPath", attribute: nil, line: 4) }
    func test_filter_is_rejected() { assertRejected(cast("<filter/>"), element: "filter", attribute: nil, line: 4) }
    func test_a_linear_gradient_is_rejected() { assertRejected(cast("<linearGradient/>"), element: "linearGradient", attribute: nil, line: 4) }
    func test_a_radial_gradient_is_rejected() { assertRejected(cast("<radialGradient/>"), element: "radialGradient", attribute: nil, line: 4) }
    func test_text_is_rejected() { assertRejected(cast("<text>hi</text>"), element: "text", attribute: nil, line: 4) }
    func test_image_is_rejected() { assertRejected(cast("<image/>"), element: "image", attribute: nil, line: 4) }
    func test_foreignObject_is_rejected() { assertRejected(cast("<foreignObject/>"), element: "foreignObject", attribute: nil, line: 4) }
    func test_an_unlisted_element_is_rejected() { assertRejected(cast("<a/>"), element: "a", attribute: nil, line: 4) }

    func test_anything_inside_defs_is_rejected_naming_the_inner_element() {
        assertRejected(cast("<defs><path d=\"M0 0L1 1\"/></defs>"), element: "path", attribute: nil, line: 4)
        assertRejected(cast("<defs><linearGradient id=\"g\"/></defs>"), element: "linearGradient", attribute: nil, line: 4)
    }

    func test_a_style_attribute_is_rejected() {
        assertRejected(cast("<path d=\"M0 0L1 1\" style=\"fill:red\"/>"), element: "path", attribute: "style", line: 4)
    }
    func test_a_class_attribute_is_rejected() {
        assertRejected(cast("<path d=\"M0 0L1 1\" class=\"a\"/>"), element: "path", attribute: "class", line: 4)
    }
    func test_any_other_attribute_is_rejected() {
        assertRejected(cast("<path d=\"M0 0L1 1\" stroke-dasharray=\"1 2\"/>"), element: "path", attribute: "stroke-dasharray", line: 4)
        assertRejected(cast(okPath, root: " xmlns:xlink=\"http://www.w3.org/1999/xlink\""), element: "svg", attribute: "xmlns:xlink", line: 1)
    }
    func test_opacity_on_a_part_group_is_rejected() {
        assertRejected(cast("<path d=\"M0 0L1 1\"/>", partAttrs: "data-pivot=\"10 20\" opacity=\"0.5\""), element: "g", attribute: "opacity", line: 2)
    }

    func test_opacity_on_a_shape_is_rejected() {
        assertRejected(cast("<path d=\"M0 0L1 1\" opacity=\"0.5\"/>"), element: "path", attribute: "opacity", line: 4)
    }
    func test_url_paint_is_rejected() {
        assertRejected(cast("<path d=\"M0 0L1 1\" fill=\"url(#g)\"/>"), element: "path", attribute: "fill", line: 4)
    }
    func test_a_named_colour_is_rejected() {
        assertRejected(cast("<path d=\"M0 0L1 1\" stroke=\"red\"/>"), element: "path", attribute: "stroke", line: 4)
    }
    func test_currentColor_is_rejected() {
        assertRejected(cast("<path d=\"M0 0L1 1\" fill=\"currentColor\"/>"), element: "path", attribute: "fill", line: 4)
    }
    func test_skewX_is_rejected() {
        assertRejected(cast("<path d=\"M0 0L1 1\" transform=\"skewX(10)\"/>"), element: "path", attribute: "transform", line: 4)
    }
    func test_skewY_is_rejected() {
        assertRejected(cast("<path d=\"M0 0L1 1\" transform=\"translate(1) skewY(10)\"/>"), element: "path", attribute: "transform", line: 4)
    }
    func test_a_matrix_with_a_skew_component_is_rejected() {
        assertRejected(cast("<path d=\"M0 0L1 1\" transform=\"matrix(1 0 0.5 1 0 0)\"/>"), element: "path", attribute: "transform", line: 4)
    }
    func test_a_length_with_a_unit_is_rejected() {
        assertRejected(cast("<circle cx=\"5\" cy=\"5\" r=\"3px\"/>"), element: "circle", attribute: "r", line: 4)
    }
    func test_a_percentage_is_rejected() {
        assertRejected(cast("<rect x=\"0\" y=\"0\" width=\"50%\" height=\"5\"/>"), element: "rect", attribute: "width", line: 4)
        assertRejected(cast(okPath, root: " width=\"100%\""), element: "svg", attribute: "width", line: 1)
    }
    func test_a_linecap_other_than_round_is_rejected() {
        assertRejected(cast("<path d=\"M0 0L1 1\" stroke-linecap=\"square\"/>"), element: "path", attribute: "stroke-linecap", line: 4)
    }
    func test_a_path_command_outside_the_subset_or_malformed_is_rejected_naming_d() {
        assertRejected(cast("<path d=\"M0 0 X5 5\"/>"), element: "path", attribute: "d", line: 4)
        assertRejected(cast("<path d=\"M0 0 L5\"/>"), element: "path", attribute: "d", line: 4)
    }
    func test_malformed_xml_is_rejected_with_a_line() {
        XCTAssertThrowsError(try SVGBake.bakeCast(svg: "<svg viewBox=\"0 0 1 1\">\n<g>\n</svg>", file: "t.svg")) { e in
            XCTAssertTrue(e is SVGBakeError); XCTAssertTrue("\(e)".contains("t.svg:")) }
    }
    func test_the_silhouette_source_is_held_to_the_same_subset() {
        assertRejected("<svg viewBox=\"0 0 9 9\">\n<path d=\"M0 0L5 5\" style=\"x\"/>\n</svg>", element: "path", attribute: "style", line: 2, sil: true)
        assertRejected("<svg viewBox=\"0 0 9 9\">\n<use/>\n</svg>", element: "use", attribute: nil, line: 2, sil: true)
    }

    // MARK: AC-2/AC-4: structure

    func test_a_duplicate_id_is_rejected() {
        let svg = cast("<path id=\"head_body\" d=\"M0 0L1 1\"/>")
        assertRejected(svg, element: "path", attribute: "id", line: 4)
    }
    func test_a_layer_group_whose_prefix_is_not_the_enclosing_part_is_rejected() {
        let svg = """
        <svg viewBox="0 0 100 100">
          <g id="head" data-pivot="1 2">
            <g id="neck_body"></g>
          </g>
        </svg>
        """
        assertRejected(svg, element: "g", attribute: "id", line: 3)
    }
    func test_a_reserved_segment_in_a_part_name_is_rejected() {
        let svg = """
        <svg viewBox="0 0 100 100">
          <g id="body_detail_outline" data-pivot="1 2"></g>
        </svg>
        """
        assertRejected(svg, element: "g", attribute: "id", line: 2)
        assertRejected("<svg viewBox=\"0 0 9 9\">\n<g id=\"head_body_x\" data-pivot=\"1 2\"/></svg>", element: "g", attribute: "id", line: 2)
    }
    func test_a_missing_layer_group_is_rejected() {
        let svg = """
        <svg viewBox="0 0 100 100">
          <g id="head" data-pivot="1 2">
            <g id="head_body"></g>
            <g id="head_outline"></g>
          </g>
        </svg>
        """
        assertRejected(svg, element: "g", attribute: "id", line: 2)
    }
    func test_a_part_without_a_pivot_is_rejected() {
        assertRejected(cast(okPath, partAttrs: ""), element: "g", attribute: "data-pivot", line: 2)
        assertRejected(cast(okPath, partAttrs: "data-pivot=\"1\""), element: "g", attribute: "data-pivot", line: 2)
    }
    func test_an_uppercase_part_name_and_a_shape_outside_a_layer_are_rejected() {
        assertRejected("<svg viewBox=\"0 0 9 9\">\n<g id=\"Head_body\" data-pivot=\"1 2\"/></svg>", element: "g", attribute: "id", line: 2)
        assertRejected("<svg viewBox=\"0 0 9 9\">\n<g id=\"head\" data-pivot=\"1 2\">\n<path d=\"M0 0L1 1\"/></g></svg>", element: "path", attribute: nil, line: 3)
    }

    // MARK: AC-3: silhouettes

    func test_a_baked_silhouette_parses_under_the_morph_v1_parser_with_a_drawable_subpath() throws {
        let svg = "<svg viewBox=\"0 0 99 99\"><path d=\"M0 0L50 0L50 50Z\"/><circle cx=\"70\" cy=\"70\" r=\"10\"/></svg>"
        let d = try XCTUnwrap(json(SVGBake.bakeSilhouette(svg: svg))["d"] as? String)
        let lines = try SVGPath.polylines(d)
        XCTAssertEqual(lines.count, 2, "two pieces are two subpaths of one compound path")
        XCTAssertTrue(lines.allSatisfy { $0.count >= 2 })
        XCTAssertEqual(d.filter { $0 == "M" }.count, 2)
    }

    func test_the_bake_never_emits_an_arc_or_smooth_command() throws {
        let svg = "<svg viewBox=\"0 0 99 99\"><path d=\"M10 10 A20 20 0 0 1 50 10 s5 5 10 0 t10 0 L50 50 a5 5 0 1 0 10 0Z\"/><ellipse cx=\"5\" cy=\"5\" rx=\"4\" ry=\"2\"/><rect x=\"1\" y=\"1\" width=\"8\" height=\"8\" rx=\"2\"/></svg>"
        let d = try XCTUnwrap(json(SVGBake.bakeSilhouette(svg: svg))["d"] as? String)
        XCTAssertTrue(d.allSatisfy { !$0.isLetter || "MLCQZ".contains($0) }, d)
        XCTAssertNoThrow(try SVGPath.polylines(d))
        let cast = try shapeData(SVGBake.bakeCast(svg: self.cast("<path d=\"M10 10 A20 20 0 0 1 50 10\"/>")))
        XCTAssertTrue(cast[0].allSatisfy { !$0.isLetter || "MLHVCQZ".contains($0) }, cast[0])
    }

    func test_an_m_follows_every_z_that_is_followed_by_a_drawing_command() throws {
        let svg = "<svg viewBox=\"0 0 99 99\"><path d=\"M0 0L10 0L10 10Z L20 20 L30 20Z\"/></svg>"
        let d = try XCTUnwrap(json(SVGBake.bakeSilhouette(svg: svg))["d"] as? String)
        XCTAssertEqual(d, "M0 0L10 0L10 10ZM0 0L20 20L30 20Z")
    }

    func test_a_silhouette_with_no_length_is_rejected_naming_the_file() {
        XCTAssertThrowsError(try SVGBake.bakeSilhouette(svg: "<svg viewBox=\"0 0 9 9\"><path d=\"M5 5L5 5\"/></svg>", file: "sil_x.svg")) { e in
            XCTAssertTrue("\(e)".contains("sil_x.svg"), "\(e)")
        }
        XCTAssertThrowsError(try SVGBake.bakeSilhouette(svg: "<svg viewBox=\"0 0 9 9\"></svg>", file: "sil_x.svg"))
    }

    /// Key Table AC-3, validator side: a `sil/…json` whose `d` holds an `A` command fails V8 naming the file; a baked
    /// silhouette (with the tool and version fields) passes.
    func test_the_validator_fails_a_silhouette_file_with_an_arc_naming_the_file_and_accepts_a_baked_one() throws {
        let content = FileManager.default.temporaryDirectory.appendingPathComponent("content-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: content) }
        let cases = try Fixture.contractsRoot(from: #filePath).appendingPathComponent("key-table-schema-v3/cases.json")
        let fx = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: cases)) as? [String: Any])
        let fixtures = try XCTUnwrap(fx["fixtures"] as? [String: Any])
        let theme = try XCTUnwrap(fixtures["theme"] as? [String: Any]), assets = try XCTUnwrap(fixtures["assets"] as? [String: Any])
        var glyphSet = try XCTUnwrap(fixtures["glyphSet"] as? [String: Any])
        let glyphPaths = try XCTUnwrap(glyphSet.removeValue(forKey: "glyphPaths") as? [String: String])
        let root = content.appendingPathComponent("themes/\(theme["id"] as! String)")
        let fm = FileManager.default
        func write(_ data: Data, _ rel: String, in dir: URL) throws {
            let url = dir.appendingPathComponent(rel)
            try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url)
        }
        func pathFile(_ d: String) throws -> Data { try JSONSerialization.data(withJSONObject: ["d": d]) }
        try write(JSONSerialization.data(withJSONObject: theme), "theme.json", in: root)
        let sil = assets["silhouettePaths"] as! [String: String]
        for f in assets["files"] as! [String] {
            try write(sil[f].map(pathFile) ?? Data(), f, in: root)
            for (dir, src) in [("cast/", "src/art/"), ("sil/", "src/sil/")] where f.hasPrefix(dir) {
                try write(Data("<svg/>".utf8), src + (f as NSString).lastPathComponent.replacingOccurrences(of: ".json", with: ".svg"), in: root)
            }
        }
        let gdir = content.appendingPathComponent("glyphs/\(glyphSet["id"] as! String)")
        try write(JSONSerialization.data(withJSONObject: glyphSet), "glyphs.json", in: gdir)
        for (k, f) in glyphSet["glyphs"] as! [String: String] { try write(pathFile(glyphPaths[k]!), f, in: gdir) }

        let silFile = "sil/sil_tb_d_item_01.json"
        let baked = try SVGBake.bakeSilhouette(svg: "<svg viewBox=\"0 0 9 9\"><path d=\"M0 0L5 0L5 5Z\"/></svg>")
        try write(Data(baked), silFile, in: root)
        XCTAssertEqual(ContentValidator.run(contentDir: content).findings, [], "a baked silhouette passes V8")

        try write(try pathFile("M0 0 A5 5 0 0 1 10 0 L10 10Z"), silFile, in: root)
        let r = ContentValidator.run(contentDir: content)
        XCTAssertEqual(r.findings.map(\.rule), ["V8"], "\(r.findings)")
        XCTAssertTrue("\(r.findings)".contains("sil_tb_d_item_01.json"), "\(r.findings)")
    }

    // MARK: AC-4: part ids, layers, pivots

    func test_part_ids_layers_and_pivots_are_carried_into_the_baked_file() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 440">
          <g id="root" data-pivot="320 410">
            <g id="left_arm" data-pivot="10 20" transform="translate(5 5)">
              <g id="left_arm_detail"><path d="M0 0L1 1"/></g>
              <g id="left_arm_body" opacity="0.5"><path d="M0 0L2 2" fill="#abc"/></g>
              <g id="left_arm_outline"><path d="M0 0L3 3" fill="none" stroke="rgb(1, 2, 3)" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/></g>
            </g>
            <g id="root_body"/><g id="root_outline"/><g id="root_detail"/>
          </g>
        </svg>
        """
        let j = try json(SVGBake.bakeCast(svg: svg))
        XCTAssertEqual((j["artboard"] as? [String: Double]) ?? [:], ["width": 640, "height": 440])
        let parts = try XCTUnwrap(j["parts"] as? [[String: Any]])
        XCTAssertEqual(parts.map { $0["id"] as? String }, ["root", "left_arm"], "document order, parent first")
        XCTAssertEqual(parts[0]["pivot"] as? [Double], [320, 410])
        XCTAssertTrue(parts[0]["parent"] is NSNull)
        XCTAssertEqual(parts[1]["parent"] as? String, "root")
        XCTAssertEqual(parts[1]["pivot"] as? [Double], [15, 25], "the pivot goes through the part's own transform")
        let layers = try XCTUnwrap(parts[1]["layers"] as? [[String: Any]])
        XCTAssertEqual(layers.map { $0["layer"] as? String }, ["body", "outline", "detail"], "fixed order, not document order")
        XCTAssertEqual(layers[0]["opacity"] as? Double, 0.5, "a layer's opacity is its own group's, applied once")
        XCTAssertEqual(layers[1]["opacity"] as? Double, 1, "no opacity attribute means 1")
        let body = try XCTUnwrap((layers[0]["shapes"] as? [[String: Any]])?.first)
        XCTAssertEqual(body["d"] as? String, "M5 5L7 7")
        XCTAssertEqual(body["fill"] as? String, "#aabbcc")
        let outline = try XCTUnwrap((layers[1]["shapes"] as? [[String: Any]])?.first)
        XCTAssertEqual(outline["stroke"] as? String, "#010203")
        XCTAssertEqual(outline["strokeWidth"] as? Double, 2)
        XCTAssertEqual(outline["strokeLinecap"] as? String, "round")
        XCTAssertEqual(outline["strokeLinejoin"] as? String, "round")
    }

    func test_the_baked_file_does_not_encode_a_render_choice() throws {
        let t = text(try SVGBake.bakeCast(svg: cast(okPath))).lowercased()
        for word in ["texture", "sprite", "raster", "livepath", "option"] { XCTAssertFalse(t.contains(word), word) }
    }
}
