import CoreGraphics
import Foundation

/// The silhouette raster check (ADR-0003 D4; content-pipeline story 004): a baked silhouette (`sil/<stem>.json`,
/// `{"d": …}`) is compared with its art's baked cast file (`cast/<stem>.json`, the `SVGBake` layout) **at rest** (no
/// idle applied, the cast coordinates as baked) and **at artboard scale, 1 px = 1 unit**. Core Graphics only (K-31).
///
/// Definitions (this tool's own design, provisional until game-art-content or the ADR says otherwise):
/// - **Pixel grid:** one 8-bit gray `CGContext` per mask, antialiasing off (a pixel is in or out, decided by CG's
///   aliased fill), the artboard plus a `margin` of 8 px on every side so a stroke or silhouette that crosses the artboard
///   edge is not clipped. Pixel `(x, y)` covers artboard units `[x, x+1) × [y, y+1)`.
/// - **Art mask** `A` = the union over every part of
///   (a) every **body**-layer shape's fill (fill not `none`), non-zero rule;
///   (b) every **outline**-layer shape's fill (fill not `none`), non-zero rule;
///   (c) the **outer half** of every outline-layer stroke (stroke not `none`, width > 0): the full stroke (the shape's
///       width, join and cap, miter limit 4 as in SVG) **minus that same shape's own non-zero fill area**. For a closed
///       outline path this leaves exactly the half of the stroke outside the path; an open path is closed implicitly
///       for the subtraction, as SVG fills close it.
///   The detail layer, body strokes, layer opacity and fill opacity play no part (the mask is coverage, not paint).
/// - **Silhouette mask** `S` = the `d` path filled with the **non-zero** rule, the SVG default (the D4 subset has no
///   `fill-rule`, so the authored art and silhouette SVGs are non-zero, and the bake keeps every subpath's direction).
/// - **Pass:** every pixel of the symmetric difference `A ⊕ S` lies in the **1 px edge band of `A`**: its 3×3
///   neighbourhood (8 neighbours; outside the canvas counts as "not in `A`") holds at least one pixel whose `A` state
///   differs from its own. So a differing pixel just inside or just outside the art's edge is allowed; one 2 px or more
///   from it fails.
///
/// Not thread-safe per call? It is: every call allocates its own contexts and holds no shared state.
///
/// Example:
/// ```swift
/// let r = try RasterCheck.compare(castJSON: castBytes, silhouetteJSON: silBytes)
/// if !r.pass { print("\(r.outsideBand) px outside the band, first at \(r.firstOutside!)") }
/// ```
public enum RasterCheck {
    /// Pixels of canvas around the artboard on every side.
    public static let margin = 8

    /// A cast or silhouette file this check can't read.
    public struct FormatError: Error, CustomStringConvertible, Equatable {
        public let reason: String
        public var description: String { reason }
    }

    /// One comparison's outcome. Coordinates are artboard units (pixel x, y; may be negative inside the margin).
    public struct Result: Equatable, Sendable {
        /// Pixels in exactly one of the two masks.
        public let differing: Int
        /// Differing pixels outside the 1 px edge band of the art mask; the check passes when this is 0.
        public let outsideBand: Int
        /// The first such pixel in row-major order (top row first), or nil.
        public let firstOutside: (x: Int, y: Int)?
        public var pass: Bool { outsideBand == 0 }

        public static func == (l: Result, r: Result) -> Bool {
            l.differing == r.differing && l.outsideBand == r.outsideBand && l.firstOutside?.x == r.firstOutside?.x
                && l.firstOutside?.y == r.firstOutside?.y
        }
    }

    /// A binary mask: `bits[y * width + x]` for canvas pixel (x, y), canvas = artboard + `margin` each side.
    public struct Mask: Equatable, Sendable {
        public let width: Int, height: Int
        public var bits: [Bool]
        /// The mask value at artboard pixel (x, y); false off the canvas.
        public func at(_ x: Int, _ y: Int) -> Bool {
            let cx = x + RasterCheck.margin, cy = y + RasterCheck.margin
            return cx >= 0 && cy >= 0 && cx < width && cy < height && bits[cy * width + cx]
        }
        public var count: Int { bits.reduce(0) { $0 + ($1 ? 1 : 0) } }
    }

    /// Compares a baked cast file with a baked silhouette file (both as bytes). Throws `FormatError` if either is not
    /// the baked layout, or a path does not parse.
    public static func compare(castJSON: [UInt8], silhouetteJSON: [UInt8]) throws -> Result {
        let art = try artMask(castJSON: castJSON)
        let sil = try silhouetteMask(silhouetteJSON: silhouetteJSON, artboardWidth: art.width - 2 * margin,
                                     artboardHeight: art.height - 2 * margin)
        return compare(art: art, silhouette: sil)
    }

    /// The band rule over two masks of the same canvas size.
    public static func compare(art a: Mask, silhouette s: Mask) -> Result {
        precondition(a.width == s.width && a.height == s.height, "masks of different size")
        let w = a.width, h = a.height
        var differing = 0, outside = 0
        var first: (x: Int, y: Int)?
        for y in 0..<h {
            for x in 0..<w where a.bits[y * w + x] != s.bits[y * w + x] {
                differing += 1
                let me = a.bits[y * w + x]
                var nearEdge = false
                for dy in -1...1 where !nearEdge {
                    for dx in -1...1 where !(dx == 0 && dy == 0) {
                        let nx = x + dx, ny = y + dy
                        let other = nx >= 0 && ny >= 0 && nx < w && ny < h && a.bits[ny * w + nx]
                        if other != me { nearEdge = true; break }
                    }
                }
                if !nearEdge {
                    outside += 1
                    if first == nil { first = (x - margin, y - margin) }
                }
            }
        }
        return Result(differing: differing, outsideBand: outside, firstOutside: first)
    }

    /// The art mask of a baked cast file (see the type's doc comment for the definition).
    public static func artMask(castJSON: [UInt8]) throws -> Mask {
        guard let o = try? JSONSerialization.jsonObject(with: Data(castJSON)) as? [String: Any],
              let board = o["artboard"] as? [String: Any], let aw = (board["width"] as? NSNumber)?.doubleValue,
              let ah = (board["height"] as? NSNumber)?.doubleValue, let parts = o["parts"] as? [[String: Any]] else {
            throw FormatError(reason: "not a baked cast file (needs artboard and parts)")
        }
        let canvas = try Canvas(artboardWidth: aw, artboardHeight: ah)
        let scratch = try Canvas(artboardWidth: aw, artboardHeight: ah)
        var art = [Bool](repeating: false, count: canvas.count)
        for part in parts {
            for layer in part["layers"] as? [[String: Any]] ?? [] {
                let name = layer["layer"] as? String
                guard name == "body" || name == "outline" else { continue }
                for shape in layer["shapes"] as? [[String: Any]] ?? [] {
                    guard let d = shape["d"] as? String else { throw FormatError(reason: "a shape has no d") }
                    let path = try cgPath(d)
                    if let fill = shape["fill"] as? String, fill != "none" {
                        canvas.clear(); canvas.fill(path); canvas.or(into: &art)
                    }
                    let width = (shape["strokeWidth"] as? NSNumber)?.doubleValue ?? 0
                    if name == "outline", let stroke = shape["stroke"] as? String, stroke != "none", width > 0 {
                        scratch.clear()
                        scratch.stroke(path, width: width, join: shape["strokeLinejoin"] as? String, cap: shape["strokeLinecap"] as? String)
                        scratch.fill(path, white: false)   // the outer half: remove the shape's own fill area
                        scratch.or(into: &art)
                    }
                }
            }
        }
        return Mask(width: canvas.width, height: canvas.height, bits: art)
    }

    /// The silhouette mask of a baked silhouette file (`{"d": …}`), non-zero fill, on an artboard of the given size.
    public static func silhouetteMask(silhouetteJSON: [UInt8], artboardWidth: Int, artboardHeight: Int) throws -> Mask {
        guard let o = try? JSONSerialization.jsonObject(with: Data(silhouetteJSON)) as? [String: Any], let d = o["d"] as? String else {
            throw FormatError(reason: "not a baked silhouette file (needs d)")
        }
        let c = try Canvas(artboardWidth: Double(artboardWidth), artboardHeight: Double(artboardHeight))
        c.fill(try cgPath(d))
        var bits = [Bool](repeating: false, count: c.count)
        c.or(into: &bits)
        return Mask(width: c.width, height: c.height, bits: bits)
    }

    /// The `raster` findings for one theme: every item whose `art` and `silhouette` files both exist is checked once per
    /// (art, silhouette) pair. Returns the failure messages (each naming the silhouette file) and NOT ASSESSED lines
    /// (a file that exists but is not the baked layout, e.g. a placeholder; never a silent pass).
    ///
    /// Example:
    /// ```swift
    /// let (fails, notAssessed) = RasterCheck.check(themeDir: root, pairs: [("cast/cast_x.json", "sil/sil_x.json")])
    /// ```
    public static func check(themeDir: URL, pairs: [(art: String, silhouette: String)]) -> (failures: [String], notAssessed: [String]) {
        var fails: [String] = [], na: [String] = []
        var seen = Set<String>()
        let probe = FileProbe(root: themeDir)
        for (art, sil) in pairs where seen.insert(art + "\n" + sil).inserted {
            guard probe.exists(art), probe.exists(sil),
                  let a = FileManager.default.contents(atPath: themeDir.appendingPathComponent(art).path),
                  let s = FileManager.default.contents(atPath: themeDir.appendingPathComponent(sil).path) else { continue }
            do {
                let r = try compare(castJSON: Array(a), silhouetteJSON: Array(s))
                if !r.pass, let f = r.firstOutside {
                    fails.append("\(sil) vs \(art) at rest, 1 px = 1 unit: \(r.outsideBand) px of the symmetric difference lie outside the 1 px edge band (first at \(f.x) \(f.y); \(r.differing) px differ in all)")
                }
            } catch {
                na.append("NOT ASSESSED raster \(sil) vs \(art): \(error)")
            }
        }
        return (fails, na)
    }

    // MARK: Core Graphics

    static func cgPath(_ d: String) throws -> CGPath {
        let segs: [Seg]
        do { segs = try PathData.parse(d) } catch { throw FormatError(reason: "path does not parse: \(error)") }
        let p = CGMutablePath()
        for s in segs {
            switch s {
            case .move(let a): p.move(to: CGPoint(x: a.x, y: a.y))
            case .line(let a): p.addLine(to: CGPoint(x: a.x, y: a.y))
            case .cubic(let c1, let c2, let a):
                p.addCurve(to: CGPoint(x: a.x, y: a.y), control1: CGPoint(x: c1.x, y: c1.y), control2: CGPoint(x: c2.x, y: c2.y))
            case .quad(let c, let a): p.addQuadCurve(to: CGPoint(x: a.x, y: a.y), control: CGPoint(x: c.x, y: c.y))
            case .close: p.closeSubpath()
            }
        }
        return p
    }

    /// An aliased 8-bit gray bitmap with artboard units as user space (y down, origin at the artboard's top left).
    final class Canvas {
        let ctx: CGContext, width: Int, height: Int
        var count: Int { width * height }

        init(artboardWidth: Double, artboardHeight: Double) throws {
            guard artboardWidth > 0, artboardHeight > 0, artboardWidth < 10_000, artboardHeight < 10_000 else {
                throw FormatError(reason: "artboard \(artboardWidth) x \(artboardHeight) out of range")
            }
            width = Int(artboardWidth.rounded(.up)) + 2 * RasterCheck.margin
            height = Int(artboardHeight.rounded(.up)) + 2 * RasterCheck.margin
            guard let c = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                    space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
                throw FormatError(reason: "no bitmap context")
            }
            ctx = c
            ctx.setShouldAntialias(false); ctx.setAllowsAntialiasing(false)
            ctx.interpolationQuality = .none
            // Memory row 0 is the top of the bitmap: flip so artboard y grows downwards, then move past the margin.
            ctx.translateBy(x: 0, y: CGFloat(height)); ctx.scaleBy(x: 1, y: -1)
            ctx.translateBy(x: CGFloat(RasterCheck.margin), y: CGFloat(RasterCheck.margin))
            clear()
        }

        func clear() { if let d = ctx.data { memset(d, 0, ctx.bytesPerRow * height) } }

        func fill(_ p: CGPath, white: Bool = true) {
            ctx.setFillColor(gray: white ? 1 : 0, alpha: 1)
            ctx.addPath(p); ctx.fillPath(using: .winding)
        }

        func stroke(_ p: CGPath, width w: Double, join: String?, cap: String?) {
            ctx.setStrokeColor(gray: 1, alpha: 1)
            ctx.setLineWidth(w); ctx.setMiterLimit(4)
            ctx.setLineJoin(join == "round" ? .round : join == "bevel" ? .bevel : .miter)
            ctx.setLineCap(cap == "round" ? .round : cap == "square" ? .square : .butt)
            ctx.addPath(p); ctx.strokePath()
        }

        /// ORs this canvas (a byte ≥ 128 is "in") into `bits` (row-major, top row first).
        func or(into bits: inout [Bool]) {
            guard let d = ctx.data else { return }
            let row = ctx.bytesPerRow, bytes = d.assumingMemoryBound(to: UInt8.self)
            for y in 0..<height { for x in 0..<width where bytes[y * row + x] >= 128 { bits[y * width + x] = true } }
        }
    }
}
