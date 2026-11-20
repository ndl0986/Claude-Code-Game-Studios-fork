import Foundation
import MorphCore

// Geometry for the SVG-subset bake (ADR-0003 D4): numbers, affine transforms, path data, shape-to-path conversion and
// the morph-v1 path writer. Plain Swift; no SVG library (K-31). Internal to ToolsCore.

struct P: Equatable { var x, y: Double }

/// One absolute path segment. Everything the bake reads is converted to these five.
enum Seg: Equatable {
    case move(P), line(P), cubic(P, P, P), quad(P, P), close
}

/// A reason a value or path was rejected; the caller adds element, attribute and line.
struct ValueFailure: Error { let reason: String }

// MARK: Numbers

enum SVGNumber {
    /// A plain SVG number: optional sign, digits with an optional fraction, optional exponent. No unit, no `%`.
    static func parse(_ text: String) -> Double? {
        var sc = Scanner(Array(text.unicodeScalars))
        sc.skipSpace()
        guard let v = try? sc.number() else { return nil }
        sc.skipSpace()
        return sc.atEnd ? v : nil
    }

    /// All numbers of a list separated by spaces and/or commas; nil if any token is not a plain number.
    static func list(_ text: String) -> [Double]? {
        var sc = Scanner(Array(text.unicodeScalars)), out: [Double] = []
        while true {
            sc.skipSpace()
            if sc.atEnd { return out }
            guard let v = try? sc.number() else { return nil }
            out.append(v)
        }
    }

    /// Fixed decimals for the baked files: round half away from zero to 3 decimals, no exponent, no trailing zeros,
    /// no `-0`. The same Double always gives the same text.
    static func format(_ v: Double) -> String {
        let n = Int64((abs(v) * 1000).rounded())
        if n == 0 { return "0" }
        var s = String(n / 1000)
        let frac = n % 1000
        if frac != 0 {
            var f = String(frac)
            f = String(repeating: "0", count: 3 - f.count) + f
            while f.hasSuffix("0") { f.removeLast() }
            s += "." + f
        }
        return v < 0 ? "-" + s : s
    }

    /// Scans numbers, flags and separators out of a scalar array (shared by path data, lists and transforms).
    struct Scanner {
        let s: [Unicode.Scalar]
        var i = 0
        init(_ s: [Unicode.Scalar]) { self.s = s }
        var atEnd: Bool { i >= s.count }
        var peek: Unicode.Scalar? { i < s.count ? s[i] : nil }

        mutating func skipSpace() {
            while i < s.count, s[i] == " " || s[i] == "\t" || s[i] == "\n" || s[i] == "\r" || s[i] == "," { i += 1 }
        }

        mutating func number() throws -> Double {
            skipSpace()
            let start = i
            func digit(_ k: Int) -> Bool { k < s.count && s[k].value >= 48 && s[k].value <= 57 }
            if i < s.count, s[i] == "-" || s[i] == "+" { i += 1 }
            var digits = 0
            while digit(i) { i += 1; digits += 1 }
            if i < s.count, s[i] == "." { i += 1; while digit(i) { i += 1; digits += 1 } }
            guard digits > 0 else { i = start; throw ValueFailure(reason: "expected a plain number") }
            if i < s.count, s[i] == "e" || s[i] == "E" {
                var k = i + 1
                if k < s.count, s[k] == "-" || s[k] == "+" { k += 1 }
                if digit(k) { while digit(k) { k += 1 }; i = k }
            }
            var text = ""
            text.unicodeScalars.append(contentsOf: s[start..<i])
            guard let v = Double(text), v.isFinite, abs(v) < 1e9 else { throw ValueFailure(reason: "number \(text) is out of range") }
            // A unit or % glued to the number is not a plain length.
            if i < s.count, s[i] == "%" || (s[i].properties.isAlphabetic && !isPathLetter(s[i])) {
                throw ValueFailure(reason: "'\(text)\(s[i])': units and percentages are not allowed")
            }
            return v
        }

        func isPathLetter(_ c: Unicode.Scalar) -> Bool { "MmLlHhVvCcSsQqTtAaZz".unicodeScalars.contains(c) }

        /// An arc flag: one `0` or `1` character.
        mutating func flag() throws -> Bool {
            skipSpace()
            guard i < s.count, s[i] == "0" || s[i] == "1" else { throw ValueFailure(reason: "arc flag must be 0 or 1") }
            defer { i += 1 }
            return s[i] == "1"
        }
    }
}

// MARK: Transforms

/// The affine matrix `[a c e; b d f]` (SVG order a b c d e f).
struct Matrix: Equatable {
    var a = 1.0, b = 0.0, c = 0.0, d = 1.0, e = 0.0, f = 0.0
    static let identity = Matrix()

    /// `self` applied after `n` (SVG's `self n`: the child's own transform is `n`).
    func concat(_ n: Matrix) -> Matrix {
        Matrix(a: a * n.a + c * n.b, b: b * n.a + d * n.b, c: a * n.c + c * n.d, d: b * n.c + d * n.d,
               e: a * n.e + c * n.f + e, f: b * n.e + d * n.f + f)
    }

    func apply(_ p: P) -> P { P(x: a * p.x + c * p.y + e, y: b * p.x + d * p.y + f) }

    /// Column lengths equal and columns orthogonal: a rotation, uniform scale and optional flip.
    var isSimilarity: Bool {
        let l1 = a * a + b * b, l2 = c * c + d * d
        return abs(l1 - l2) <= 1e-9 * max(l1, l2) && abs(a * c + b * d) <= 1e-9 * max(l1, l2)
    }

    /// Length scale of a similarity (for stroke widths).
    var uniformScale: Double { (a * a + b * b).squareRoot() }

    /// Parses `translate`, `rotate`, `scale` and a skew-free `matrix` (ADR-0003 D4); skew and anything else throw.
    static func parse(_ text: String) throws -> Matrix {
        var m = Matrix.identity
        let s = Array(text.unicodeScalars)
        var i = 0
        func skip() { while i < s.count, s[i] == " " || s[i] == "\t" || s[i] == "\n" || s[i] == "\r" || s[i] == "," { i += 1 } }
        var any = false
        while true {
            skip()
            if i >= s.count { break }
            var name = ""
            while i < s.count, s[i].properties.isAlphabetic { name.unicodeScalars.append(s[i]); i += 1 }
            skip()
            guard i < s.count, s[i] == "(", let close = s[i...].firstIndex(of: ")") else {
                throw ValueFailure(reason: "transform '\(text)' is not a list of name(args)")
            }
            var args = ""
            args.unicodeScalars.append(contentsOf: s[(i + 1)..<close])
            i = close + 1
            guard let n = SVGNumber.list(args) else { throw ValueFailure(reason: "\(name)(\(args)): arguments are not plain numbers") }
            let step: Matrix
            switch (name, n.count) {
            case ("translate", 1): step = Matrix(e: n[0])
            case ("translate", 2): step = Matrix(e: n[0], f: n[1])
            case ("scale", 1): step = Matrix(a: n[0], d: n[0])
            case ("scale", 2): step = Matrix(a: n[0], d: n[1])
            case ("rotate", 1), ("rotate", 3):
                let r = n[0] * Double.pi / 180, co = cos(r), si = sin(r)
                var rot = Matrix(a: co, b: si, c: -si, d: co)
                if n.count == 3 { rot = Matrix(e: n[1], f: n[2]).concat(rot).concat(Matrix(e: -n[1], f: -n[2])) }
                step = rot
            case ("matrix", 6):
                step = Matrix(a: n[0], b: n[1], c: n[2], d: n[3], e: n[4], f: n[5])
                guard abs(step.a * step.c + step.b * step.d) <= 1e-9 * (1 + abs(step.a * step.c) + abs(step.b * step.d)) ||
                      (step.a * step.a + step.b * step.b) * (step.c * step.c + step.d * step.d) == 0 else {
                    throw ValueFailure(reason: "matrix has a skew component (only translate, rotate and scale are allowed)")
                }
            case ("skewX", _), ("skewY", _):
                throw ValueFailure(reason: "\(name) is not allowed (only translate, rotate and scale)")
            default:
                throw ValueFailure(reason: "\(name) with \(n.count) argument(s) is not allowed (only translate, rotate, scale)")
            }
            m = m.concat(step); any = true
        }
        guard any else { throw ValueFailure(reason: "empty transform") }
        guard abs(m.a * m.d - m.b * m.c) > 1e-12 else { throw ValueFailure(reason: "transform scales an axis to zero") }
        return m
    }
}

// MARK: Path data

enum PathData {
    /// Parses SVG path data (`M L H V C S Q T A Z`, either case) into absolute segments: arcs become cubics, `S`/`T`
    /// become `C`/`Q`, `H`/`V` become lines, relative commands become absolute.
    static func parse(_ d: String) throws -> [Seg] {
        var sc = SVGNumber.Scanner(Array(d.unicodeScalars))
        var segs: [Seg] = []
        var cur = P(x: 0, y: 0), start = cur
        var lastC: P?, lastQ: P?           // reflection points for S and T
        var cmd: Unicode.Scalar?
        let letters = "MmLlHhVvCcSsQqTtAaZz".unicodeScalars
        while true {
            sc.skipSpace()
            guard let ch = sc.peek else { break }
            if letters.contains(ch) {
                cmd = ch; sc.i += 1
                if segs.isEmpty && ch != "M" && ch != "m" { throw ValueFailure(reason: "path data must start with M") }
            } else if sc.s[sc.i].properties.isAlphabetic {
                throw ValueFailure(reason: "path command '\(Character(ch))' is not in the subset")
            } else if cmd == nil || cmd == "Z" || cmd == "z" {
                throw ValueFailure(reason: "a number where a path command is expected")
            }
            guard let c = cmd else { break }
            let rel = c.value >= 97
            func pt(_ x: Double, _ y: Double) -> P { rel ? P(x: cur.x + x, y: cur.y + y) : P(x: x, y: y) }
            var newC: P?, newQ: P?
            switch c {
            case "M", "m":
                let x = try sc.number(), y = try sc.number()
                cur = pt(x, y); start = cur; segs.append(.move(cur))
                cmd = rel ? "l" : "L"
            case "L", "l":
                let x = try sc.number(), y = try sc.number()
                cur = pt(x, y); segs.append(.line(cur))
            case "H", "h":
                let x = try sc.number(); cur = P(x: rel ? cur.x + x : x, y: cur.y); segs.append(.line(cur))
            case "V", "v":
                let y = try sc.number(); cur = P(x: cur.x, y: rel ? cur.y + y : y); segs.append(.line(cur))
            case "C", "c":
                let n = try (0..<6).map { _ in try sc.number() }
                let c1 = pt(n[0], n[1]), c2 = pt(n[2], n[3]), e = pt(n[4], n[5])
                segs.append(.cubic(c1, c2, e)); newC = c2; cur = e
            case "S", "s":
                let n = try (0..<4).map { _ in try sc.number() }
                let c1 = lastC.map { P(x: 2 * cur.x - $0.x, y: 2 * cur.y - $0.y) } ?? cur
                let c2 = pt(n[0], n[1]), e = pt(n[2], n[3])
                segs.append(.cubic(c1, c2, e)); newC = c2; cur = e
            case "Q", "q":
                let n = try (0..<4).map { _ in try sc.number() }
                let q = pt(n[0], n[1]), e = pt(n[2], n[3])
                segs.append(.quad(q, e)); newQ = q; cur = e
            case "T", "t":
                let n = try (0..<2).map { _ in try sc.number() }
                let q = lastQ.map { P(x: 2 * cur.x - $0.x, y: 2 * cur.y - $0.y) } ?? cur
                let e = pt(n[0], n[1])
                segs.append(.quad(q, e)); newQ = q; cur = e
            case "A", "a":
                let rx = try sc.number(), ry = try sc.number(), rot = try sc.number()
                let large = try sc.flag(), sweep = try sc.flag()
                let x = try sc.number(), y = try sc.number()
                let e = pt(x, y)
                segs.append(contentsOf: arc(from: cur, rx: rx, ry: ry, rotation: rot, large: large, sweep: sweep, to: e))
                cur = e
            default: // Z, z
                segs.append(.close); cur = start
            }
            lastC = newC; lastQ = newQ
        }
        guard !segs.isEmpty else { throw ValueFailure(reason: "empty path data") }
        return segs
    }

    /// An SVG elliptical arc (implementation notes F.6.5) as cubic segments of at most 90 degrees each.
    static func arc(from p0: P, rx rx0: Double, ry ry0: Double, rotation: Double, large: Bool, sweep: Bool, to p1: P) -> [Seg] {
        if p0 == p1 { return [] }
        var rx = abs(rx0), ry = abs(ry0)
        if rx == 0 || ry == 0 { return [.line(p1)] }
        let phi = rotation * Double.pi / 180, cp = cos(phi), sp = sin(phi)
        let dx = (p0.x - p1.x) / 2, dy = (p0.y - p1.y) / 2
        let x1 = cp * dx + sp * dy, y1 = -sp * dx + cp * dy
        let lambda = x1 * x1 / (rx * rx) + y1 * y1 / (ry * ry)
        if lambda > 1 { let s = lambda.squareRoot(); rx *= s; ry *= s }
        let num = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
        let den = rx * rx * y1 * y1 + ry * ry * x1 * x1
        let coef = (large == sweep ? -1.0 : 1.0) * max(0, num / den).squareRoot()
        let cxp = coef * rx * y1 / ry, cyp = -coef * ry * x1 / rx
        let cx = cp * cxp - sp * cyp + (p0.x + p1.x) / 2, cy = sp * cxp + cp * cyp + (p0.y + p1.y) / 2
        let t1 = atan2((y1 - cyp) / ry, (x1 - cxp) / rx)
        let t2 = atan2((-y1 - cyp) / ry, (-x1 - cxp) / rx)
        var delta = t2 - t1
        if !sweep && delta > 0 { delta -= 2 * Double.pi } else if sweep && delta < 0 { delta += 2 * Double.pi }
        let n = max(1, Int((abs(delta) / (Double.pi / 2) - 1e-9).rounded(.up)))
        let step = delta / Double(n), k = 4.0 / 3.0 * tan(step / 4)
        func point(_ a: Double) -> P { P(x: cx + rx * cos(a) * cp - ry * sin(a) * sp, y: cy + rx * cos(a) * sp + ry * sin(a) * cp) }
        func deriv(_ a: Double) -> P { P(x: -rx * sin(a) * cp - ry * cos(a) * sp, y: -rx * sin(a) * sp + ry * cos(a) * cp) }
        var out: [Seg] = []
        for j in 0..<n {
            let a1 = t1 + Double(j) * step, a2 = a1 + step
            let s = point(a1), d1 = deriv(a1), d2 = deriv(a2)
            let e = j == n - 1 ? p1 : point(a2)
            let pe = point(a2)
            out.append(.cubic(P(x: s.x + k * d1.x, y: s.y + k * d1.y), P(x: pe.x - k * d2.x, y: pe.y - k * d2.y), e))
        }
        return out
    }
}

// MARK: Writer

/// Writes absolute `M L H V C Q Z` text with the fixed number format, the given transform applied to every point.
/// `allowHV` lets a transformed line that is exactly horizontal or vertical (at the baked precision) become `H`/`V`.
/// An `M` is written after every `Z` that is followed by a drawing command.
struct PathWriter {
    private(set) var text = ""
    let allowHV: Bool
    private var matrix = Matrix.identity
    private var lastX = "", lastY = "", startX = "", startY = "", needMove = false

    init(allowHV: Bool) { self.allowHV = allowHV }

    private func xy(_ p: P) -> (String, String) { let t = matrix.apply(p); return (SVGNumber.format(t.x), SVGNumber.format(t.y)) }

    private mutating func moveIfNeeded() {
        if needMove { text += "M\(startX) \(startY)"; lastX = startX; lastY = startY; needMove = false }
    }

    mutating func add(_ segs: [Seg], transformedBy m: Matrix) {
        matrix = m
        for s in segs {
            switch s {
            case .move(let p):
                let (x, y) = xy(p)
                text += "M\(x) \(y)"; lastX = x; lastY = y; startX = x; startY = y; needMove = false
            case .line(let p):
                moveIfNeeded()
                let (x, y) = xy(p)
                if allowHV && y == lastY { text += "H\(x)" } else if allowHV && x == lastX { text += "V\(y)" } else { text += "L\(x) \(y)" }
                lastX = x; lastY = y
            case .cubic(let c1, let c2, let p):
                moveIfNeeded()
                let (ax, ay) = xy(c1), (bx, by) = xy(c2), (x, y) = xy(p)
                text += "C\(ax) \(ay) \(bx) \(by) \(x) \(y)"; lastX = x; lastY = y
            case .quad(let c, let p):
                moveIfNeeded()
                let (ax, ay) = xy(c), (x, y) = xy(p)
                text += "Q\(ax) \(ay) \(x) \(y)"; lastX = x; lastY = y
            case .close:
                text += "Z"; lastX = startX; lastY = startY; needMove = true
            }
        }
    }
}

// MARK: Morph-v1 check

/// The drawable rule a baked path must meet (Key Table V8, MorphCore AC-10), shared by the silhouette and glyph bakes:
/// it parses under MorphCore's `SVGPath.polylines`, has a subpath of 2+ points, and its total length is above 0.
enum MorphPathCheck {
    enum Problem: Error { case unparsable(Error), notDrawable }

    /// nil when `d` is drawable; otherwise what is wrong.
    static func problem(_ d: String) -> Problem? {
        let lines: [[Pt]]
        do { lines = try SVGPath.polylines(d) } catch { return .unparsable(error) }
        var total = 0.0
        for l in lines { for j in l.indices.dropFirst() { total += ((l[j].x - l[j - 1].x) * (l[j].x - l[j - 1].x) + (l[j].y - l[j - 1].y) * (l[j].y - l[j - 1].y)).squareRoot() } }
        return lines.contains(where: { $0.count >= 2 }) && total > 0 ? nil : .notDrawable
    }
}

// MARK: Shapes

enum ShapeGeometry {
    /// The shape's outline as absolute segments in its own coordinates. `attrs` has been checked against the subset;
    /// a missing or invalid geometry value throws with the attribute name in `ValueFailure.attribute`.
    struct Failure: Error { let attribute: String; let reason: String }

    static func segments(element: String, attrs: [String: String]) throws -> [Seg] {
        func num(_ name: String, required: Bool = false) throws -> Double {
            guard let t = attrs[name] else {
                if required { throw Failure(attribute: name, reason: "missing") }
                return 0
            }
            guard let v = SVGNumber.parse(t) else { throw Failure(attribute: name, reason: "'\(t)' is not a plain number (no units, no %)") }
            return v
        }
        func positive(_ name: String) throws -> Double {
            let v = try num(name, required: true)
            guard v > 0 else { throw Failure(attribute: name, reason: "must be greater than 0") }
            return v
        }
        switch element {
        case "path":
            guard let d = attrs["d"] else { throw Failure(attribute: "d", reason: "missing") }
            do { return try PathData.parse(d) } catch let e as ValueFailure { throw Failure(attribute: "d", reason: e.reason) }
        case "line":
            return [.move(P(x: try num("x1"), y: try num("y1"))), .line(P(x: try num("x2"), y: try num("y2")))]
        case "polyline", "polygon":
            guard let t = attrs["points"] else { throw Failure(attribute: "points", reason: "missing") }
            guard let n = SVGNumber.list(t), n.count >= 4, n.count % 2 == 0 else {
                throw Failure(attribute: "points", reason: "'\(t)' is not a list of at least two x y pairs of plain numbers")
            }
            var s: [Seg] = [.move(P(x: n[0], y: n[1]))]
            for k in stride(from: 2, to: n.count, by: 2) { s.append(.line(P(x: n[k], y: n[k + 1]))) }
            if element == "polygon" { s.append(.close) }
            return s
        case "circle", "ellipse":
            let cx = try num("cx"), cy = try num("cy")
            let rx = try positive(element == "circle" ? "r" : "rx"), ry = element == "circle" ? rx : try positive("ry")
            let q = [P(x: cx + rx, y: cy), P(x: cx, y: cy + ry), P(x: cx - rx, y: cy), P(x: cx, y: cy - ry)]
            var s: [Seg] = [.move(q[0])]
            for k in 0..<4 { s += PathData.arc(from: q[k], rx: rx, ry: ry, rotation: 0, large: false, sweep: true, to: q[(k + 1) % 4]) }
            return s + [.close]
        case "rect":
            let x = try num("x"), y = try num("y"), w = try positive("width"), h = try positive("height")
            var rx = attrs["rx"] != nil ? try num("rx") : nil as Double?, ry = attrs["ry"] != nil ? try num("ry") : nil as Double?
            if rx == nil { rx = ry }; if ry == nil { ry = rx }
            let cx = min(max(rx ?? 0, 0), w / 2), cy = min(max(ry ?? 0, 0), h / 2)
            if cx == 0 || cy == 0 {
                return [.move(P(x: x, y: y)), .line(P(x: x + w, y: y)), .line(P(x: x + w, y: y + h)), .line(P(x: x, y: y + h)), .close]
            }
            func a(_ from: P, _ to: P) -> [Seg] { PathData.arc(from: from, rx: cx, ry: cy, rotation: 0, large: false, sweep: true, to: to) }
            var s: [Seg] = [.move(P(x: x + cx, y: y)), .line(P(x: x + w - cx, y: y))]
            s += a(P(x: x + w - cx, y: y), P(x: x + w, y: y + cy)); s.append(.line(P(x: x + w, y: y + h - cy)))
            s += a(P(x: x + w, y: y + h - cy), P(x: x + w - cx, y: y + h)); s.append(.line(P(x: x + cx, y: y + h)))
            s += a(P(x: x + cx, y: y + h), P(x: x, y: y + h - cy)); s.append(.line(P(x: x, y: y + cy)))
            s += a(P(x: x, y: y + cy), P(x: x + cx, y: y))
            return s + [.close]
        default:
            throw Failure(attribute: "(element)", reason: "not a shape")
        }
    }
}
