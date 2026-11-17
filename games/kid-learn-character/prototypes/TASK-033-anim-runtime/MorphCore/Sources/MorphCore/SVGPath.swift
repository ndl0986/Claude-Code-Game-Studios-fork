// PROTOTYPE - NOT FOR PRODUCTION (TASK-033 spike)
/// A 2D point in the morph's unit space (y down, as in SVG and Android Canvas).
public struct Pt: Equatable, Sendable, Codable {
    public var x, y: Double
    public init(_ x: Double, _ y: Double) { self.x = x; self.y = y }
}

/// A portable subset of SVG path data: M m L l H h V v C c Q q Z z, numbers separated by spaces or commas.
/// Curves are flattened with a FIXED number of segments (`curveSegments`), never adaptively, so every port gets the
/// same polyline.
public enum SVGPath {
    public static let curveSegments = 16

    public enum ParseError: Error, Equatable { case badToken(String), missingNumber(Character) }

    /// The path as polylines, one per subpath (a Z closes it back to its start point).
    public static func polylines(_ d: String) throws -> [[Pt]] {
        var tokens: [String] = [], num = ""
        func flush() { if !num.isEmpty { tokens.append(num); num = "" } }
        for ch in d {
            if ch.isLetter && ch != "e" && ch != "E" { flush(); tokens.append(String(ch)) }
            else if ch == " " || ch == "," || ch == "\n" || ch == "\t" { flush() }
            else if ch == "-" && !num.isEmpty && num.last != "e" && num.last != "E" { flush(); num = "-" }
            else if ch == "." && (num.contains(".") || num.contains("e") || num.contains("E")) { flush(); num = "." }
            else { num.append(ch) }
        }
        flush()

        var out: [[Pt]] = [], cur: [Pt] = []
        var p = Pt(0, 0), start = Pt(0, 0), i = 0, cmd: Character = "M"
        func number() throws -> Double {
            guard i < tokens.count, let v = Double(tokens[i]) else { throw ParseError.missingNumber(cmd) }
            i += 1; return v
        }
        func hasNumber() -> Bool { i < tokens.count && Double(tokens[i]) != nil }
        func endSub() { if cur.count > 1 { out.append(cur) }; cur = [] }

        while i < tokens.count {
            if let c = tokens[i].first, tokens[i].count == 1, c.isLetter { cmd = c; i += 1 }
            else if !hasNumber() { throw ParseError.badToken(tokens[i]) }
            let rel = cmd.isLowercase
            switch cmd {
            case "M", "m":
                let x = try number(), y = try number()
                endSub(); p = rel ? Pt(p.x + x, p.y + y) : Pt(x, y); start = p; cur = [p]
                cmd = rel ? "l" : "L" // further pairs are line-tos
            case "L", "l":
                let x = try number(), y = try number()
                p = rel ? Pt(p.x + x, p.y + y) : Pt(x, y); cur.append(p)
            case "H", "h":
                let x = try number(); p = Pt(rel ? p.x + x : x, p.y); cur.append(p)
            case "V", "v":
                let y = try number(); p = Pt(p.x, rel ? p.y + y : y); cur.append(p)
            case "C", "c":
                var a = [Double](); for _ in 0..<6 { a.append(try number()) }
                let o = rel ? p : Pt(0, 0)
                let c1 = Pt(o.x + a[0], o.y + a[1]), c2 = Pt(o.x + a[2], o.y + a[3]), e = Pt(o.x + a[4], o.y + a[5])
                for k in 1...curveSegments {
                    let t = Double(k) / Double(curveSegments), u = 1 - t
                    let b0 = u * u * u, b1 = 3 * u * u * t, b2 = 3 * u * t * t, b3 = t * t * t
                    cur.append(Pt(b0 * p.x + b1 * c1.x + b2 * c2.x + b3 * e.x, b0 * p.y + b1 * c1.y + b2 * c2.y + b3 * e.y))
                }
                p = e
            case "Q", "q":
                var a = [Double](); for _ in 0..<4 { a.append(try number()) }
                let o = rel ? p : Pt(0, 0)
                let c1 = Pt(o.x + a[0], o.y + a[1]), e = Pt(o.x + a[2], o.y + a[3])
                for k in 1...curveSegments {
                    let t = Double(k) / Double(curveSegments), u = 1 - t
                    cur.append(Pt(u * u * p.x + 2 * u * t * c1.x + t * t * e.x, u * u * p.y + 2 * u * t * c1.y + t * t * e.y))
                }
                p = e
            case "Z", "z":
                if let f = cur.first, cur.last != f { cur.append(f) }
                endSub(); p = start; cur = [start] // as in SVG: a drawing command after Z starts at the subpath start
                if hasNumber() { throw ParseError.badToken(tokens[i]) }
            default:
                throw ParseError.badToken(String(cmd))
            }
        }
        endSub()
        return out
    }

    /// `n` points spread evenly by arc length over all subpaths together (the jumps between subpaths don't count),
    /// starting at the first point of the first subpath, mapped into the unit box of the WHOLE flattened path (see
    /// `box`), so drawing `normalisedPolylines` and the sampled points line up exactly.
    public static func sample(_ d: String, count n: Int) throws -> [Pt] {
        let lines = try polylines(d)
        var segs: [(Pt, Pt, Double)] = []
        for l in lines { for k in 1..<l.count { let a = l[k - 1], b = l[k]; segs.append((a, b, hypot(b.x - a.x, b.y - a.y))) } }
        let total = segs.reduce(0) { $0 + $1.2 }
        guard n > 0, total > 0 else { return [] }
        var pts: [Pt] = [], si = 0, acc = 0.0
        for k in 0..<n {
            let target = total * Double(k) / Double(n)
            while si < segs.count - 1 && acc + segs[si].2 < target { acc += segs[si].2; si += 1 }
            let (a, b, len) = segs[si], f = len > 0 ? min(1, max(0, (target - acc) / len)) : 0
            pts.append(Pt(a.x + (b.x - a.x) * f, a.y + (b.y - a.y) * f))
        }
        return box(lines).map(pts)
    }

    /// The flattened path fitted into the unit box (for drawing the glyph and the object).
    public static func normalisedPolylines(_ d: String) throws -> [[Pt]] {
        let lines = try polylines(d), b = box(lines)
        return lines.map(b.map)
    }

    /// The unit box of a flattened path: centred on (0, 0) by the bounding box of all its polyline points, scaled
    /// so the longer side is 1.
    public struct UnitBox: Sendable {
        public let cx, cy, side: Double
        public func map(_ p: [Pt]) -> [Pt] { p.map { Pt(($0.x - cx) / side, ($0.y - cy) / side) } }
    }

    public static func box(_ lines: [[Pt]]) -> UnitBox {
        let all = lines.flatMap { $0 }
        guard let x0 = all.map(\.x).min(), let x1 = all.map(\.x).max(), let y0 = all.map(\.y).min(), let y1 = all.map(\.y).max() else { return UnitBox(cx: 0, cy: 0, side: 1) }
        let side = max(x1 - x0, y1 - y0)
        return UnitBox(cx: (x0 + x1) / 2, cy: (y0 + y1) / 2, side: side > 0 ? side : 1)
    }
}

@inline(__always) func hypot(_ a: Double, _ b: Double) -> Double { (a * a + b * b).squareRoot() }
