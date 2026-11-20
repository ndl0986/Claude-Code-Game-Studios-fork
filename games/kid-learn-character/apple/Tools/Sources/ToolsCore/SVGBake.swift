import Foundation
import KidCore
import MorphCore

/// An SVG that is outside ADR-0003 D4's subset (or not well-formed). Every rejection names the element, the attribute
/// and the line. `line` is the line where the element's start tag ends (what `XMLParser` reports).
public struct SVGBakeError: Error, CustomStringConvertible, Equatable {
    /// The source file (a path or a label), as given to the bake call.
    public let file: String
    /// The element name, without `<>`.
    public let element: String
    /// The attribute at fault, or nil when the whole element is rejected.
    public let attribute: String?
    /// 1-based line in the source.
    public let line: Int
    /// What is wrong and what is allowed.
    public let reason: String

    public var description: String {
        "\(file):\(line): <\(element)> attribute \(attribute.map { "'\($0)'" } ?? "(none, the element itself)"): \(reason)"
    }
}

/// The build-time SVG-subset bake (ADR-0003 D4, TR-cast-001): layered cast SVG to `cast/<stem>.json`, silhouette SVG
/// to `sil/<stem>.json`. Own Swift on Foundation's `XMLParser` (K-31). Output is byte-stable: sorted keys, at most 3
/// decimals, no exponent, LF, trailing newline, tool name and version in every file.
///
/// The cast file is one draw interface for both render options (ADR-0009 A: live paths, B: textures); it holds
/// geometry and paint only, never a render choice. Layout (this tool's own design, see `bakeCast`):
///
/// ```
/// { "artboard": {"height": 440, "width": 640},
///   "parts": [ {"id": "tail", "layers": [ {"layer": "body", "opacity": 1, "shapes": [ {"d": "M…Z", "fill": "#9a6fd1",
///               "fillOpacity": 1, "stroke": "none", "strokeLinecap": "butt", "strokeLinejoin": "miter",
///               "strokeWidth": 0} ]}, {"layer": "outline", …}, {"layer": "detail", …} ],
///              "parent": "root", "pivot": [196, 270]}, … ],
///   "tool": "kidtools", "version": "1.0.0" }
/// ```
///
/// Example:
/// ```swift
/// let bytes = try SVGBake.bakeCast(svg: text, file: "cast_dino_t_trex_01.svg")
/// let sil = try SVGBake.bakeSilhouette(svg: silText, file: "sil_dino_t_trex_01.svg")   // {"d": "...", "tool", "version"}
/// let report = SVGBake.bakeContent(contentDir: URL(fileURLWithPath: "content"))
/// ```
public enum SVGBake {
    /// Written to every baked file. Change `toolVersion` whenever the output for an unchanged source changes.
    public static let toolName = "kidtools", toolVersion = "1.0.0"

    /// Bakes one layered cast SVG to the cast JSON bytes. Throws `SVGBakeError` on the first rejection.
    ///
    /// `parts` come in document order (a parent before its children); `layers` in the fixed order body, outline,
    /// detail. `parent` is the enclosing part's id or null. `pivot` is the `data-pivot` in artboard units after the
    /// transforms. A layer's `opacity` is its own group's opacity exactly (opacity is allowed on `<part>_<layer>` groups
    /// only; a part group with `opacity` is rejected), so the renderer applies it once per layer. All coordinates are artboard units (the `viewBox`, origin moved to 0 0) with every transform baked in.
    public static func bakeCast(svg: String, file: String = "cast.svg") throws -> [UInt8] {
        var b = Baker(file: file)
        let root = try b.parse(svg)
        let art = try b.rootArtboard(root)
        var out: [String: JSONValue] = [:]
        for n in try b.children(of: root) {
            guard n.name == "g" else {
                throw b.err(n, nil, "only <g> part groups may sit directly in <svg>; shapes belong in a <part>_<layer> group")
            }
            try b.part(n, ctm: art.matrix, opacity: 1, parent: nil)
        }
        guard !b.parts.isEmpty else { throw b.err(root, nil, "no part group found") }
        out["artboard"] = .object(["height": .number(art.height), "width": .number(art.width)])
        out["parts"] = .array(b.parts.map { $0.json })
        out["tool"] = .string(toolName); out["version"] = .string(toolVersion)
        return JSONValue.object(out).render()
    }

    /// Bakes one silhouette SVG to `{"d": "<path>", "tool": …, "version": …}` (the format key-table-schema-v1's `sil/…json`
    /// uses; the validator reads only `d`). Every shape of the file becomes a subpath of one compound path, in the morph-v1
    /// subset `M L C Q Z` (arcs and `S`/`T` converted, transforms applied, an `M` after every `Z`). Baked as authored
    /// (the idle rest pose is not known yet). Throws unless the result parses under `SVGPath.polylines` with a subpath of
    /// 2+ points and a total length above 0.
    public static func bakeSilhouette(svg: String, file: String = "sil.svg") throws -> [UInt8] {
        var b = Baker(file: file)
        let root = try b.parse(svg)
        let art = try b.rootArtboard(root)
        var w = PathWriter(allowHV: false)
        try b.silhouetteShapes(of: root, ctm: art.matrix, into: &w)
        let d = w.text
        guard !d.isEmpty else { throw b.err(root, nil, "no shape found") }
        let lines: [[Pt]]
        do { lines = try SVGPath.polylines(d) } catch { throw b.err(root, "d", "baked path does not parse under morph-v1: \(error)") }
        var total = 0.0
        for l in lines { for j in l.indices.dropFirst() { total += ((l[j].x - l[j - 1].x) * (l[j].x - l[j - 1].x) + (l[j].y - l[j - 1].y) * (l[j].y - l[j - 1].y)).squareRoot() } }
        guard lines.contains(where: { $0.count >= 2 }), total > 0 else {
            throw b.err(root, "d", "silhouette needs a subpath of 2+ points and a total length above 0")
        }
        return JSONValue.object(["d": .string(d), "tool": .string(toolName), "version": .string(toolVersion)]).render()
    }

    /// What `bakeContent` did: relative paths written, and one message per rejected or unreadable source.
    public struct Report {
        /// Baked files, relative to the content dir (`themes/<id>/cast/<stem>.json`), in bake order.
        public var baked: [String] = []
        /// One line per rejected source (an `SVGBakeError` description); a rejected source writes nothing.
        public var failures: [String] = []
    }

    /// Bakes every theme under `<contentDir>/themes/*`: `src/art/<stem>.svg` to `cast/<stem>.json` and
    /// `src/sil/<stem>.svg` to `sil/<stem>.json`. Themes and files go in sorted order. A rejected file is reported and
    /// skipped; the rest still bake.
    public static func bakeContent(contentDir: URL) -> Report {
        var report = Report()
        let fm = FileManager.default
        let themes = ((try? fm.contentsOfDirectory(atPath: contentDir.appendingPathComponent("themes").path)) ?? []).sorted()
        for theme in themes {
            let root = contentDir.appendingPathComponent("themes/\(theme)")
            for (srcDir, outDir) in [("art", "cast"), ("sil", "sil")] {
                let src = root.appendingPathComponent("src/\(srcDir)")
                let names = ((try? fm.contentsOfDirectory(atPath: src.path)) ?? []).filter { $0.hasSuffix(".svg") }.sorted()
                for name in names {
                    let rel = "themes/\(theme)/src/\(srcDir)/\(name)"
                    let stem = String(name.dropLast(4))
                    do {
                        guard let text = try? String(contentsOf: src.appendingPathComponent(name), encoding: .utf8) else {
                            report.failures.append("\(rel):1: <svg> attribute (none, the element itself): unreadable or not UTF-8"); continue
                        }
                        let bytes = srcDir == "art" ? try bakeCast(svg: text, file: rel) : try bakeSilhouette(svg: text, file: rel)
                        let dir = root.appendingPathComponent(outDir)
                        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
                        try Data(bytes).write(to: dir.appendingPathComponent(stem + ".json"))
                        report.baked.append("themes/\(theme)/\(outDir)/\(stem).json")
                    } catch {
                        report.failures.append("\(error)")
                    }
                }
            }
        }
        return report
    }
}

// MARK: JSON output

/// A JSON value written with sorted keys, two-space indent, scalars-only arrays on one line, LF, final newline.
indirect enum JSONValue {
    case string(String), number(Double), null, array([JSONValue]), object([String: JSONValue])

    func render() -> [UInt8] { var o: [UInt8] = []; write(&o, 0); o.append(0x0A); return o }

    private var isScalar: Bool { switch self { case .array, .object: return false; default: return true } }

    private func write(_ o: inout [UInt8], _ depth: Int) {
        func put(_ s: String) { o.append(contentsOf: Array(s.utf8)) }
        let pad = String(repeating: "  ", count: depth + 1), end = String(repeating: "  ", count: depth)
        switch self {
        case .string(let s): CanonicalJSON.appendString(s, to: &o)
        case .number(let v): put(SVGNumber.format(v))
        case .null: put("null")
        case .array(let a) where a.allSatisfy(\.isScalar):
            put("["); for (i, v) in a.enumerated() { if i > 0 { put(", ") }; v.write(&o, depth) }; put("]")
        case .array(let a):
            put("[\n"); for (i, v) in a.enumerated() { put(pad); v.write(&o, depth + 1); put(i < a.count - 1 ? ",\n" : "\n") }; put(end + "]")
        case .object(let m):
            put("{\n")
            for (i, k) in m.keys.sorted().enumerated() {   // String < compares by Unicode scalars: stable and ASCII here
                put(pad); CanonicalJSON.appendString(k, to: &o); put(": "); m[k]!.write(&o, depth + 1); put(i < m.count - 1 ? ",\n" : "\n")
            }
            put(end + "}")
        }
    }
}

// MARK: Tree

private final class Node {
    let name: String, attrs: [String: String], line: Int
    var children: [Node] = []
    var hasText = false
    init(name: String, attrs: [String: String], line: Int) { self.name = name; self.attrs = attrs; self.line = line }
}

private final class TreeBuilder: NSObject, XMLParserDelegate {
    var root: Node?, stack: [Node] = []
    func parser(_ p: XMLParser, didStartElement name: String, namespaceURI: String?, qualifiedName: String?, attributes a: [String: String]) {
        let n = Node(name: name, attrs: a, line: p.lineNumber)
        if let top = stack.last { top.children.append(n) } else if root == nil { root = n }
        stack.append(n)
    }
    func parser(_ p: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName: String?) { _ = stack.popLast() }
    func parser(_ p: XMLParser, foundCharacters s: String) {
        if !s.allSatisfy({ $0 == " " || $0 == "\n" || $0 == "\t" || $0 == "\r" }) { stack.last?.hasText = true }
    }
}

// MARK: Baker

private struct Artboard { let width, height: Double, matrix: Matrix }

private struct PartAcc {
    let id: String, parent: String?, pivot: P
    var layers: [String: JSONValue] = [:]
    var json: JSONValue {
        .object(["id": .string(id), "parent": parent.map { .string($0) } ?? .null,
                 "pivot": .array([.number(pivot.x), .number(pivot.y)]),
                 "layers": .array(["body", "outline", "detail"].compactMap { layers[$0] })])
    }
}

private struct Style { var fill = "#000000", stroke = "none", cap = "butt", join = "miter"; var fillOpacity = 1.0, strokeWidth = 1.0 }

private struct Baker {
    let file: String
    var ids = Set<String>()
    var parts: [PartAcc] = []

    static let layerNames = ["body", "outline", "detail"]
    static let ignored: Set<String> = ["title", "desc", "metadata"]
    static let shapeAttrs: Set<String> = ["fill", "fill-opacity", "stroke", "stroke-width", "stroke-linejoin", "stroke-linecap", "transform", "id"]
    static let allowed: [String: Set<String>] = [
        "svg": ["xmlns", "version", "width", "height", "viewBox"],
        "g": ["id", "opacity", "transform", "data-pivot"],
        "path": shapeAttrs.union(["d"]),
        "circle": shapeAttrs.union(["cx", "cy", "r"]),
        "ellipse": shapeAttrs.union(["cx", "cy", "rx", "ry"]),
        "rect": shapeAttrs.union(["x", "y", "width", "height", "rx", "ry"]),
        "line": shapeAttrs.union(["x1", "y1", "x2", "y2"]),
        "polyline": shapeAttrs.union(["points"]),
        "polygon": shapeAttrs.union(["points"]),
    ]

    init(file: String) { self.file = file }

    func err(_ n: Node, _ attr: String?, _ reason: String) -> SVGBakeError {
        SVGBakeError(file: file, element: n.name, attribute: attr, line: n.line, reason: reason)
    }

    // Parsing and generic checks

    func parse(_ svg: String) throws -> Node {
        let builder = TreeBuilder(), parser = XMLParser(data: Data(svg.utf8))
        parser.delegate = builder
        guard parser.parse(), let root = builder.root else {
            let why = parser.parserError.map { ($0 as NSError).localizedDescription } ?? "no root element"
            throw SVGBakeError(file: file, element: "(xml)", attribute: nil, line: max(parser.lineNumber, 1), reason: "not well-formed XML: \(why)")
        }
        guard root.name == "svg" else { throw err(root, nil, "the root element must be <svg>") }
        return root
    }

    /// The element's children that count: skips <title>, <desc>, <metadata> and an empty <defs>; rejects text,
    /// anything inside <defs>, and elements outside the subset (with their attributes checked).
    mutating func children(of n: Node) throws -> [Node] {
        try checkElement(n)
        if n.hasText { throw err(n, nil, "text content is not allowed") }
        var out: [Node] = []
        for c in n.children {
            if Baker.ignored.contains(c.name) { continue }
            if c.name == "defs" {
                if let inner = c.children.first { throw err(inner, nil, "<\(inner.name)> inside <defs> is not allowed (an empty <defs> is ignored)") }
                if let a = c.attrs.keys.sorted().first { throw err(c, a, "attribute on <defs> is not allowed") }
                if c.hasText { throw err(c, nil, "text content is not allowed") }
                continue
            }
            out.append(c)
        }
        return out
    }

    /// Element in the subset, every attribute allowed for it, id unique in the file.
    mutating func checkElement(_ n: Node) throws {
        guard let ok = Baker.allowed[n.name] else {
            throw err(n, nil, "element <\(n.name)> is not in the SVG subset (svg, g, path, circle, ellipse, rect, line, polyline, polygon)")
        }
        for a in n.attrs.keys.sorted() where !ok.contains(a) {
            throw err(n, a, "attribute '\(a)' is not allowed on <\(n.name)> (allowed: \(ok.sorted().joined(separator: ", ")))")
        }
        if let id = n.attrs["id"] {
            if !ids.insert(id).inserted { throw err(n, "id", "duplicate id '\(id)'") }
        }
    }

    func number(_ n: Node, _ attr: String) throws -> Double? {
        guard let t = n.attrs[attr] else { return nil }
        guard let v = SVGNumber.parse(t) else { throw err(n, attr, "'\(t)' is not a plain number (no units, no %)") }
        return v
    }

    func transform(_ n: Node) throws -> Matrix {
        guard let t = n.attrs["transform"] else { return .identity }
        do { return try Matrix.parse(t) } catch let e as ValueFailure { throw err(n, "transform", e.reason) }
    }

    mutating func rootArtboard(_ root: Node) throws -> Artboard {
        try checkElement(root)
        _ = try number(root, "width"); _ = try number(root, "height")
        guard let vb = root.attrs["viewBox"] else { throw err(root, "viewBox", "missing (artboard units come from the viewBox)") }
        guard let v = SVGNumber.list(vb), v.count == 4, v[2] > 0, v[3] > 0 else {
            throw err(root, "viewBox", "'\(vb)' must be four plain numbers: min-x min-y width height, with width and height above 0")
        }
        return Artboard(width: v[2], height: v[3], matrix: Matrix(e: -v[0], f: -v[1]))
    }

    // Colours and paint

    func colour(_ n: Node, _ attr: String, _ t: String) throws -> String {
        if t == "none" { return "none" }
        if t.hasPrefix("#") {
            let h = Array(t.utf8.dropFirst())
            let hex = h.allSatisfy { ($0 >= 48 && $0 <= 57) || ($0 >= 65 && $0 <= 70) || ($0 >= 97 && $0 <= 102) }
            guard hex, h.count == 3 || h.count == 6 else { throw err(n, attr, "'\(t)' is not #rgb or #rrggbb") }
            let s = String(decoding: h, as: UTF8.self).lowercased()
            return "#" + (s.count == 3 ? s.map { "\($0)\($0)" }.joined() : s)
        }
        if t.hasPrefix("rgb(") && t.hasSuffix(")") {
            let parts = t.dropFirst(4).dropLast().split(separator: ",", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            let v = parts.map { p -> Int? in p.isEmpty || !p.allSatisfy({ $0.isASCII && $0.isNumber }) ? nil : Int(p) }
            guard v.count == 3, v.allSatisfy({ $0 != nil && $0! <= 255 }) else { throw err(n, attr, "'\(t)' is not rgb(r, g, b) with whole numbers 0 to 255") }
            return "#" + v.map { String(format: "%02x", $0!) }.joined()
        }
        let why = t.hasPrefix("url(") ? "url(#…) paint (gradients, patterns) is not allowed"
            : (t == "currentColor" ? "currentColor is not allowed" : "'\(t)' is not allowed: use #rgb, #rrggbb, rgb(r, g, b) or none (no named colours)")
        throw err(n, attr, why)
    }

    func style(_ n: Node) throws -> Style {
        var s = Style()
        if let t = n.attrs["fill"] { s.fill = try colour(n, "fill", t) }
        if let t = n.attrs["stroke"] { s.stroke = try colour(n, "stroke", t) }
        if let v = try number(n, "fill-opacity") {
            guard v >= 0 && v <= 1 else { throw err(n, "fill-opacity", "'\(v)' must be between 0 and 1") }
            s.fillOpacity = v
        }
        if let v = try number(n, "stroke-width") {
            guard v >= 0 else { throw err(n, "stroke-width", "'\(v)' must not be negative") }
            s.strokeWidth = v
        }
        for (attr, set) in [("stroke-linecap", 0), ("stroke-linejoin", 1)] {
            guard let t = n.attrs[attr] else { continue }
            guard t == "round" else { throw err(n, attr, "'\(t)' is not allowed (only round)") }
            if set == 0 { s.cap = "round" } else { s.join = "round" }
        }
        return s
    }

    // Shapes

    /// A shape's segments and the matrix that takes them to artboard units; validates the transform, geometry and paint.
    mutating func shape(_ n: Node, ctm: Matrix) throws -> (segs: [Seg], matrix: Matrix, style: Style) {
        try checkElement(n)
        let m = ctm.concat(try transform(n)), st = try style(n)
        do {
            let segs = try ShapeGeometry.segments(element: n.name, attrs: n.attrs)
            return (segs, m, st)
        } catch let f as ShapeGeometry.Failure { throw err(n, f.attribute, f.reason) }
    }

    mutating func silhouetteShapes(of n: Node, ctm: Matrix, into w: inout PathWriter) throws {
        for c in try children(of: n) {
            if c.name == "g" {
                let m = ctm.concat(try transform(c))
                try silhouetteShapes(of: c, ctm: m, into: &w)
            } else {
                let s = try shape(c, ctm: ctm)
                w.add(s.segs, transformedBy: s.matrix)
            }
        }
    }

    // Cast structure

    static func isPartName(_ s: String) -> Bool {
        s.split(separator: "_", omittingEmptySubsequences: false).allSatisfy { !$0.isEmpty && $0.utf8.allSatisfy { $0 >= 97 && $0 <= 122 } }
    }

    func opacity(_ n: Node, _ parent: Double) throws -> Double {
        guard let v = try number(n, "opacity") else { return parent }
        guard v >= 0 && v <= 1 else { throw err(n, "opacity", "'\(v)' must be between 0 and 1") }
        return parent * v
    }

    /// A group that is a part or a layer group, by its id; called for the children of the svg root and of a part.
    mutating func part(_ g: Node, ctm: Matrix, opacity parentOpacity: Double, parent: PartAcc?) throws {
        let kids = try children(of: g)
        guard let id = g.attrs["id"] else { throw err(g, "id", "missing: a group is a part (id = part name) or a layer (id = <part>_<layer>)") }
        let segs = id.split(separator: "_", omittingEmptySubsequences: false).map(String.init)
        if let last = segs.last, Baker.layerNames.contains(last) {
            guard let parent else { throw err(g, "id", "layer group '\(id)' is not inside a part group") }
            try layer(g, kids: kids, id: id, layer: last, prefixSegments: Array(segs.dropLast()), ctm: ctm, opacity: parentOpacity, part: parent)
            return
        }
        guard Baker.isPartName(id) else { throw err(g, "id", "part id '\(id)' must match [a-z]+(_[a-z]+)*") }
        // (a reserved word as the last segment is a layer id, handled above; it can only be an inner segment here)
        if let r = segs.first(where: { Baker.layerNames.contains($0) }) {
            throw err(g, "id", "'\(r)' is reserved for layers and may not be a segment of the part name '\(id)'")
        }
        // Group opacity composites a group once in SVG, so a part's opacity can't be split into its layers without a
        // double blend (game-dev-ios review; TASK-127 H-2): opacity lives on <part>_<layer> groups only.
        if g.attrs["opacity"] != nil {
            throw err(g, "opacity", "not allowed on part group '\(id)': put it on a '\(id)_body', '\(id)_outline' or '\(id)_detail' group")
        }
        let own = try transform(g), m = ctm.concat(own), op = parentOpacity
        guard let pv = g.attrs["data-pivot"] else { throw err(g, "data-pivot", "missing: every part carries data-pivot=\"x y\" in artboard units") }
        guard let n = SVGNumber.list(pv), n.count == 2 else { throw err(g, "data-pivot", "'\(pv)' must be two plain numbers: x y") }
        let acc = PartAcc(id: id, parent: parent?.id, pivot: m.apply(P(x: n[0], y: n[1])))
        let index = parts.count
        parts.append(acc)
        for c in kids {
            guard c.name == "g" else {
                throw err(c, nil, "<\(c.name)> directly inside part '\(id)': shapes belong in a '\(id)_body', '\(id)_outline' or '\(id)_detail' group")
            }
            try part(c, ctm: m, opacity: op, parent: parts[index])
        }
        for l in Baker.layerNames where parts[index].layers[l] == nil {
            throw err(g, "id", "part '\(id)' has no layer group '\(id)_\(l)'")
        }
    }

    private mutating func layer(_ g: Node, kids: [Node], id: String, layer: String, prefixSegments: [String], ctm: Matrix, opacity parentOpacity: Double, part parent: PartAcc) throws {
        let prefix = prefixSegments.joined(separator: "_")
        if prefix.isEmpty { throw err(g, "id", "'\(id)' is a reserved layer name, not a part name; a layer id is <part>_<layer>") }
        guard Baker.isPartName(prefix) else { throw err(g, "id", "the part in layer id '\(id)' must match [a-z]+(_[a-z]+)*") }
        if let r = prefixSegments.first(where: { Baker.layerNames.contains($0) }) {
            throw err(g, "id", "'\(r)' is reserved for layers and may not be a segment of the part name '\(prefix)'")
        }
        guard prefix == parent.id else { throw err(g, "id", "layer group '\(id)' is inside part '\(parent.id)': its id must start with '\(parent.id)_'") }
        if g.attrs["data-pivot"] != nil { throw err(g, "data-pivot", "only part groups carry data-pivot") }
        let m = ctm.concat(try transform(g)), op = try opacity(g, parentOpacity)
        var shapes: [JSONValue] = []
        for c in kids {
            if c.name == "g" { throw err(c, nil, "a group inside layer group '\(id)' is not allowed (a layer holds shapes only)") }
            let s = try shape(c, ctm: m)
            if s.style.stroke != "none" && !s.matrix.isSimilarity {
                throw err(c, "transform", "non-uniform scale on a stroked shape cannot keep the stroke width")
            }
            var w = PathWriter(allowHV: true)
            w.add(s.segs, transformedBy: s.matrix)
            let stroked = s.style.stroke != "none"
            shapes.append(.object([
                "d": .string(w.text), "fill": .string(s.style.fill), "fillOpacity": .number(s.style.fillOpacity),
                "stroke": .string(s.style.stroke), "strokeLinecap": .string(stroked ? s.style.cap : "butt"),
                "strokeLinejoin": .string(stroked ? s.style.join : "miter"),
                "strokeWidth": .number(stroked ? s.style.strokeWidth * s.matrix.uniformScale : 0),
            ]))
        }
        guard let index = parts.firstIndex(where: { $0.id == parent.id }) else { return }
        parts[index].layers[layer] = .object(["layer": .string(layer), "opacity": .number(op), "shapes": .array(shapes)])
    }
}
