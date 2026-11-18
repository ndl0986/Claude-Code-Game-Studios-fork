// PROTOTYPE - NOT FOR PRODUCTION (TASK-078 DeviceSpike, ADR-0009 spike)
// A small reader for the cast-art SVG subset (ADR-0003 D4, Cast Rendering R2), enough to draw the TASK-077 test
// creatures by option A (live paths) and option B (rasterised per part). Layer groups are `<part>_<layer>` (the
// suffix rule agreed for the D4 clarification). Not the production bake tool (TASK-079's), and it checks less.
import Foundation

public struct Affine: Equatable, Sendable {
    public var a = 1.0, b = 0.0, c = 0.0, d = 1.0, tx = 0.0, ty = 0.0
    public init() {}
    public init(a: Double, b: Double, c: Double, d: Double, tx: Double, ty: Double) { (self.a, self.b, self.c, self.d, self.tx, self.ty) = (a, b, c, d, tx, ty) }
    public func apply(_ x: Double, _ y: Double) -> (Double, Double) { (a * x + c * y + tx, b * x + d * y + ty) }
    /// Returns self ∘ m: points go through m first, then self (SVG transform lists compose left to right).
    public func concat(_ m: Affine) -> Affine {
        Affine(a: a * m.a + c * m.b, b: b * m.a + d * m.b, c: a * m.c + c * m.d, d: b * m.c + d * m.d,
               tx: a * m.tx + c * m.ty + tx, ty: b * m.tx + d * m.ty + ty)
    }
    public static func translate(_ x: Double, _ y: Double) -> Affine { Affine(a: 1, b: 0, c: 0, d: 1, tx: x, ty: y) }
    public static func scale(_ x: Double, _ y: Double) -> Affine { Affine(a: x, b: 0, c: 0, d: y, tx: 0, ty: 0) }
    public static func rotate(_ deg: Double) -> Affine {
        let r = deg * .pi / 180
        return Affine(a: cos(r), b: sin(r), c: -sin(r), d: cos(r), tx: 0, ty: 0)
    }
}

public enum PathOp: Equatable, Sendable {
    case move(Double, Double), line(Double, Double), quad(Double, Double, Double, Double)
    case cubic(Double, Double, Double, Double, Double, Double), close
}

public struct Style: Equatable, Sendable {
    public var fill: UInt32? = nil          // 0xRRGGBB, nil = none
    public var fillOpacity = 1.0
    public var stroke: UInt32? = nil
    public var strokeWidth = 1.0
    public var opacity = 1.0
    public init() {}
}

public struct Shape: Equatable, Sendable { public var ops: [PathOp]; public var style: Style }
public struct Layer: Equatable, Sendable { public var name: String; public var shapes: [Shape] }

public final class Part: @unchecked Sendable {
    public let id: String
    public let pivot: (Double, Double)
    public var items: [Item] = []
    init(id: String, pivot: (Double, Double)) { self.id = id; self.pivot = pivot }
    public enum Item { case layer(Layer), part(Part) }
    public var partIds: [String] { [id] + items.flatMap { if case .part(let p) = $0 { return p.partIds } else { return [] } } }
}

public enum SVGArtError: Error, Equatable { case notAllowed(String), badLayer(String), parse(String) }

public enum SVGArt {
    public static func parse(_ data: Data) throws -> Part {
        let r = Reader(); let p = XMLParser(data: data); p.delegate = r
        guard p.parse(), r.error == nil, let root = r.root else { throw r.error ?? .parse(p.parserError.map { "\($0)" } ?? "?") }
        return root
    }

    // MARK: path data (M L H V C S Q T Z, absolute and relative; arcs are not in the test art and are rejected)
    public static func pathOps(_ d: String, _ m: Affine) throws -> [PathOp] {
        var toks: [String] = []; var num = ""
        func flush() { if !num.isEmpty { toks.append(num); num = "" } }
        for ch in d {
            if ch.isLetter && ch != "e" && ch != "E" { flush(); toks.append(String(ch)) }
            else if ch == "," || ch == " " || ch == "\n" || ch == "\t" { flush() }
            else if ch == "-" && !num.isEmpty && !(num.hasSuffix("e") || num.hasSuffix("E")) { flush(); num = "-" }
            else if ch == "." && (num.contains(".") || num.contains("e")) { flush(); num = "." }
            else { num.append(ch) }
        }
        flush()
        var ops: [PathOp] = [], i = 0, cmd = "", x = 0.0, y = 0.0, sx = 0.0, sy = 0.0, lcx = 0.0, lcy = 0.0, lqx = 0.0, lqy = 0.0, prev = ""
        func n() throws -> Double { guard i < toks.count, let v = Double(toks[i]) else { throw SVGArtError.parse("number in \(d)") }; i += 1; return v }
        func t(_ px: Double, _ py: Double) -> (Double, Double) { m.apply(px, py) }
        while i < toks.count {
            if let c = toks[i].first, c.isLetter { cmd = toks[i]; i += 1 }
            let rel = cmd == cmd.lowercased() && cmd != "Z"
            let ox = rel ? x : 0, oy = rel ? y : 0
            switch cmd.uppercased() {
            case "M":
                x = ox + (try n()); y = oy + (try n()); sx = x; sy = y
                let p = t(x, y); ops.append(.move(p.0, p.1)); cmd = rel ? "l" : "L"
            case "L": x = ox + (try n()); y = oy + (try n()); let p = t(x, y); ops.append(.line(p.0, p.1))
            case "H": x = ox + (try n()); let p = t(x, y); ops.append(.line(p.0, p.1))
            case "V": y = oy + (try n()); let p = t(x, y); ops.append(.line(p.0, p.1))
            case "C", "S":
                var x1 = 0.0, y1 = 0.0
                if cmd.uppercased() == "C" { x1 = ox + (try n()); y1 = oy + (try n()) }
                else { (x1, y1) = (prev == "C" || prev == "S") ? (2 * x - lcx, 2 * y - lcy) : (x, y) }
                let x2 = ox + (try n()), y2 = oy + (try n()); x = ox + (try n()); y = oy + (try n())
                lcx = x2; lcy = y2
                let a = t(x1, y1), b = t(x2, y2), e = t(x, y); ops.append(.cubic(a.0, a.1, b.0, b.1, e.0, e.1))
            case "Q", "T":
                var x1 = 0.0, y1 = 0.0
                if cmd.uppercased() == "Q" { x1 = ox + (try n()); y1 = oy + (try n()) }
                else { (x1, y1) = (prev == "Q" || prev == "T") ? (2 * x - lqx, 2 * y - lqy) : (x, y) }
                x = ox + (try n()); y = oy + (try n()); lqx = x1; lqy = y1
                let a = t(x1, y1), e = t(x, y); ops.append(.quad(a.0, a.1, e.0, e.1))
            case "Z": ops.append(.close); x = sx; y = sy
            default: throw SVGArtError.notAllowed("path command \(cmd)")
            }
            prev = cmd.uppercased()
        }
        return ops
    }

    static let k = 0.5522847498
    static func ellipse(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double, _ m: Affine) -> [PathOp] {
        func p(_ x: Double, _ y: Double) -> (Double, Double) { m.apply(x, y) }
        let s = p(cx + rx, cy), a = (p(cx + rx, cy + k * ry), p(cx + k * rx, cy + ry), p(cx, cy + ry)),
            b = (p(cx - k * rx, cy + ry), p(cx - rx, cy + k * ry), p(cx - rx, cy)),
            c = (p(cx - rx, cy - k * ry), p(cx - k * rx, cy - ry), p(cx, cy - ry)),
            d = (p(cx + k * rx, cy - ry), p(cx + rx, cy - k * ry), p(cx + rx, cy))
        return [.move(s.0, s.1)] + [a, b, c, d].map { .cubic($0.0.0, $0.0.1, $0.1.0, $0.1.1, $0.2.0, $0.2.1) } + [.close]
    }
    static func rect(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ rxIn: Double, _ ryIn: Double, _ m: Affine) -> [PathOp] {
        let rx = min(rxIn, w / 2), ry = min(ryIn, h / 2)
        func p(_ px: Double, _ py: Double) -> (Double, Double) { m.apply(px, py) }
        if rx <= 0 || ry <= 0 {
            let q = [p(x, y), p(x + w, y), p(x + w, y + h), p(x, y + h)]
            return [.move(q[0].0, q[0].1)] + q.dropFirst().map { .line($0.0, $0.1) } + [.close]
        }
        var o: [PathOp] = []
        func mv(_ a: (Double, Double)) { o.append(.move(a.0, a.1)) }
        func ln(_ a: (Double, Double)) { o.append(.line(a.0, a.1)) }
        func cu(_ a: (Double, Double), _ b: (Double, Double), _ c: (Double, Double)) { o.append(.cubic(a.0, a.1, b.0, b.1, c.0, c.1)) }
        mv(p(x + rx, y)); ln(p(x + w - rx, y)); cu(p(x + w - rx + k * rx, y), p(x + w, y + ry - k * ry), p(x + w, y + ry))
        ln(p(x + w, y + h - ry)); cu(p(x + w, y + h - ry + k * ry), p(x + w - rx + k * rx, y + h), p(x + w - rx, y + h))
        ln(p(x + rx, y + h)); cu(p(x + rx - k * rx, y + h), p(x, y + h - ry + k * ry), p(x, y + h - ry))
        ln(p(x, y + ry)); cu(p(x, y + ry - k * ry), p(x + rx - k * rx, y), p(x + rx, y)); o.append(.close)
        return o
    }

    static func transform(_ s: String) throws -> Affine {
        var m = Affine()
        var rest = Substring(s)
        while let open = rest.firstIndex(of: "("), let close = rest.firstIndex(of: ")") {
            let name = rest[..<open].trimmingCharacters(in: .whitespaces)
            let args = rest[rest.index(after: open)..<close].split(whereSeparator: { $0 == "," || $0 == " " }).compactMap { Double($0) }
            switch name {
            case "translate": m = m.concat(.translate(args[0], args.count > 1 ? args[1] : 0))
            case "scale": m = m.concat(.scale(args[0], args.count > 1 ? args[1] : args[0]))
            case "rotate":
                if args.count == 3 { m = m.concat(.translate(args[1], args[2])).concat(.rotate(args[0])).concat(.translate(-args[1], -args[2])) }
                else { m = m.concat(.rotate(args[0])) }
            default: throw SVGArtError.notAllowed("transform \(name)")
            }
            rest = rest[rest.index(after: close)...]
        }
        return m
    }

    static func color(_ s: String) throws -> UInt32? {
        let v = s.trimmingCharacters(in: .whitespaces)
        if v == "none" { return nil }
        if v.hasPrefix("#") {
            var h = String(v.dropFirst())
            if h.count == 3 { h = h.map { "\($0)\($0)" }.joined() }
            guard h.count == 6, let n = UInt32(h, radix: 16) else { throw SVGArtError.notAllowed("colour \(s)") }
            return n
        }
        throw SVGArtError.notAllowed("colour \(s)")
    }

    final class Reader: NSObject, XMLParserDelegate {
        var root: Part?
        var error: SVGArtError?
        // stack frames: (transform, style, kind)
        enum Kind { case svg, part(Part), layer(Part, String), other }
        var stack: [(Affine, Style, Kind)] = []
        var shapes: [Shape] = []
        static let allowed: Set<String> = ["svg", "g", "path", "circle", "ellipse", "rect", "line", "polyline", "polygon", "title", "desc", "metadata"]

        func parser(_ parser: XMLParser, didStartElement el: String, namespaceURI: String?, qualifiedName: String?, attributes a: [String: String] = [:]) {
            guard error == nil else { return }
            guard Self.allowed.contains(el) else { error = .notAllowed("element \(el)"); parser.abortParsing(); return }
            if el == "title" || el == "desc" || el == "metadata" { stack.append((stack.last?.0 ?? Affine(), stack.last?.1 ?? Style(), .other)); return }
            do {
                var m = stack.last?.0 ?? Affine(), st = stack.last?.1 ?? Style()
                if let t = a["transform"] { m = m.concat(try SVGArt.transform(t)) }
                if let f = a["fill"] { st.fill = try SVGArt.color(f) }
                if let f = a["fill-opacity"], let v = Double(f) { st.fillOpacity = v }
                if let f = a["stroke"] { st.stroke = try SVGArt.color(f) }
                if let f = a["stroke-width"], let v = Double(f) { st.strokeWidth = v }
                if a["style"] != nil || a["class"] != nil { throw SVGArtError.notAllowed("style/class") }
                let parentPart: Part? = {
                    for f in stack.reversed() { if case .part(let p) = f.2 { return p } }
                    return nil
                }()
                switch el {
                case "svg": stack.append((m, st, .svg))
                case "g":
                    let id = a["id"] ?? ""
                    if let pv = a["data-pivot"] {
                        let xy = pv.split(separator: " ").compactMap { Double($0) }
                        let p = Part(id: id, pivot: (xy[0], xy[1]))
                        if let parent = parentPart { parent.items.append(.part(p)) } else { root = p }
                        stack.append((m, st, .part(p)))
                    } else if let parent = parentPart, let us = id.lastIndex(of: "_"),
                              ["body", "outline", "detail"].contains(String(id[id.index(after: us)...])) {
                        guard String(id[..<us]) == parent.id else { throw SVGArtError.badLayer(id) }
                        var gs = st; if let o = a["opacity"], let v = Double(o) { gs.opacity = v }
                        stack.append((m, gs, .layer(parent, String(id[id.index(after: us)...]))))
                        shapes = []
                    } else { throw SVGArtError.badLayer(id.isEmpty ? "(unnamed g)" : id) }
                default:
                    func d(_ k: String) -> Double { Double(a[k] ?? "0") ?? 0 }
                    let ops: [PathOp]
                    switch el {
                    case "path": ops = try SVGArt.pathOps(a["d"] ?? "", m)
                    case "circle": ops = SVGArt.ellipse(d("cx"), d("cy"), d("r"), d("r"), m)
                    case "ellipse": ops = SVGArt.ellipse(d("cx"), d("cy"), d("rx"), d("ry"), m)
                    case "rect": ops = SVGArt.rect(d("x"), d("y"), d("width"), d("height"), a["rx"].flatMap(Double.init) ?? a["ry"].flatMap(Double.init) ?? 0, a["ry"].flatMap(Double.init) ?? a["rx"].flatMap(Double.init) ?? 0, m)
                    case "line": let p = m.apply(d("x1"), d("y1")), q = m.apply(d("x2"), d("y2")); ops = [.move(p.0, p.1), .line(q.0, q.1)]
                    default:
                        let v = (a["points"] ?? "").split(whereSeparator: { $0 == "," || $0 == " " }).compactMap { Double($0) }
                        var o: [PathOp] = []
                        for j in stride(from: 0, to: v.count - 1, by: 2) { let p = m.apply(v[j], v[j + 1]); o.append(j == 0 ? .move(p.0, p.1) : .line(p.0, p.1)) }
                        if el == "polygon" { o.append(.close) }
                        ops = o
                    }
                    shapes.append(Shape(ops: ops, style: st))
                    stack.append((m, st, .other))
                }
            } catch let e as SVGArtError { error = e; parser.abortParsing() } catch { self.error = .parse("\(error)"); parser.abortParsing() }
        }

        func parser(_ parser: XMLParser, didEndElement el: String, namespaceURI: String?, qualifiedName: String?) {
            guard error == nil, let top = stack.popLast() else { return }
            if case .layer(let part, let name) = top.2 {
                // a layer's own opacity multiplies into each shape (the outline's 80%)
                part.items.append(.layer(Layer(name: name, shapes: shapes.map { var s = $0; s.style.opacity = top.1.opacity; return s })))
                shapes = []
            }
        }
    }
}
