// TASK-103 (ADR-0009) headless measurement, Mac CPU only, NOT device evidence.
// Parses TASK-077's layered test creatures (the Cast Rendering R2 subset, a1 layer ids), then for option B rasterises
// every part once per tier into a PNG (encoded in memory; no file is written) and reports:
//   - PNG bytes per creature per tier (the app-size delta of option B) against the SVG bytes (option A's stand-in);
//   - texture bytes w x h x 4 per creature per tier, and the F6 part-box sum against one whole-artboard image (1.5x cap);
//   - Mac CPU rasterisation ms per creature per tier (a load-cost hint for B-at-load; never device evidence).
// Usage: swiftc -O option-b-size.swift -o /tmp/x && /tmp/x <svg>... ; it prints a markdown table.
import AppKit
import CoreGraphics
import Foundation
import ImageIO

struct Style { var fill: CGColor? = CGColor(red: 0, green: 0, blue: 0, alpha: 1); var fillOpacity = 1.0; var stroke: CGColor?; var strokeWidth = 1.0; var opacity = 1.0 }
struct Shape { var path: CGPath; var style: Style }
final class Part { let id: String; var shapes: [String: [Shape]] = ["body": [], "outline": [], "detail": []]; init(_ id: String) { self.id = id } }

func color(_ s: String?) -> CGColor?? {
    guard let s else { return .none }                       // not given: inherit
    if s == "none" { return .some(nil) }
    var h = s.trimmingCharacters(in: .whitespaces); guard h.hasPrefix("#") else { return .none }
    h.removeFirst(); if h.count == 3 { h = h.map { "\($0)\($0)" }.joined() }
    guard let v = UInt32(h, radix: 16) else { return .none }
    return .some(CGColor(red: CGFloat((v >> 16) & 255) / 255, green: CGFloat((v >> 8) & 255) / 255, blue: CGFloat(v & 255) / 255, alpha: 1))
}

func nums(_ s: String) -> [Double] {
    var out: [Double] = [], cur = ""
    for ch in s {
        if ch.isNumber || ch == "." || ((ch == "-" || ch == "+") && (cur.isEmpty || cur.last == "e")) || ch == "e" { cur.append(ch) }
        else if ch == "-" { if let v = Double(cur) { out.append(v) }; cur = "-" }
        else { if let v = Double(cur) { out.append(v) }; cur = "" }
    }
    if let v = Double(cur) { out.append(v) }
    return out
}

func transform(_ s: String?) -> CGAffineTransform {
    guard let s else { return .identity }
    var t = CGAffineTransform.identity
    let re = try! NSRegularExpression(pattern: #"(translate|rotate|scale)\(([^)]*)\)"#)
    for m in re.matches(in: s, range: NSRange(s.startIndex..., in: s)) {
        let kind = String(s[Range(m.range(at: 1), in: s)!]), a = nums(String(s[Range(m.range(at: 2), in: s)!]))
        switch kind {
        case "translate": t = t.translatedBy(x: a[0], y: a.count > 1 ? a[1] : 0)
        case "scale": t = t.scaledBy(x: a[0], y: a.count > 1 ? a[1] : a[0])
        default:
            let r = a[0] * .pi / 180
            if a.count >= 3 { t = t.translatedBy(x: a[1], y: a[2]).rotated(by: r).translatedBy(x: -a[1], y: -a[2]) } else { t = t.rotated(by: r) }
        }
    }
    return t
}

func pathD(_ d: String) -> CGMutablePath {
    let p = CGMutablePath()
    var tokens: [String] = [], cur = ""
    for ch in d {
        if ch.isLetter && ch != "e" { if !cur.isEmpty { tokens.append(cur); cur = "" }; tokens.append(String(ch)) }
        else { cur.append(ch) }
    }
    if !cur.isEmpty { tokens.append(cur) }
    var i = 0, pt = CGPoint.zero
    while i < tokens.count {
        let c = tokens[i]; i += 1
        let a = i < tokens.count && !(tokens[i].first!.isLetter) ? nums(tokens[i]) : []
        if !a.isEmpty { i += 1 }
        switch c {
        case "M": p.move(to: CGPoint(x: a[0], y: a[1])); pt = CGPoint(x: a[0], y: a[1]); var k = 2; while k + 1 < a.count { pt = CGPoint(x: a[k], y: a[k + 1]); p.addLine(to: pt); k += 2 }
        case "L": var k = 0; while k + 1 < a.count { pt = CGPoint(x: a[k], y: a[k + 1]); p.addLine(to: pt); k += 2 }
        case "H": pt = CGPoint(x: a[0], y: pt.y); p.addLine(to: pt)
        case "V": pt = CGPoint(x: pt.x, y: a[0]); p.addLine(to: pt)
        case "C": var k = 0; while k + 5 < a.count { pt = CGPoint(x: a[k + 4], y: a[k + 5]); p.addCurve(to: pt, control1: CGPoint(x: a[k], y: a[k + 1]), control2: CGPoint(x: a[k + 2], y: a[k + 3])); k += 6 }
        case "Q": var k = 0; while k + 3 < a.count { pt = CGPoint(x: a[k + 2], y: a[k + 3]); p.addQuadCurve(to: pt, control: CGPoint(x: a[k], y: a[k + 1])); k += 4 }
        case "Z", "z": p.closeSubpath()
        default: fatalError("command \(c) is outside the tested subset (absolute M L H V C Q Z)")
        }
    }
    return p
}

final class SVGReader: NSObject, XMLParserDelegate {
    var parts: [Part] = []
    private var partStack: [Part] = [], layerStack: [String?] = [], styleStack = [Style()], tStack = [CGAffineTransform.identity]
    func parser(_ parser: XMLParser, didStartElement el: String, namespaceURI: String?, qualifiedName: String?, attributes a: [String: String]) {
        var st = styleStack.last!
        if case .some(let c) = color(a["fill"]) { st.fill = c }
        if case .some(let c) = color(a["stroke"]) { st.stroke = c }
        if let w = a["stroke-width"].flatMap(Double.init) { st.strokeWidth = w }
        if let o = a["fill-opacity"].flatMap(Double.init) { st.fillOpacity = o }
        if let o = a["opacity"].flatMap(Double.init) { st.opacity *= o }
        let t = transform(a["transform"]).concatenating(tStack.last!)
        switch el {
        case "g":
            let id = a["id"] ?? ""
            let layer = ["body", "outline", "detail"].first { id.hasSuffix("_" + $0) }
            if layer == nil, a["data-pivot"] != nil || id == "root" { let p = Part(id); parts.append(p); partStack.append(p); layerStack.append("@part") }
            else { layerStack.append(layer) }
            styleStack.append(st); tStack.append(t)
        case "path", "circle", "ellipse", "rect":
            let p: CGPath
            let d = { (k: String) in Double(a[k] ?? "0") ?? 0 }
            switch el {
            case "path": p = pathD(a["d"] ?? "")
            case "circle": p = CGPath(ellipseIn: CGRect(x: d("cx") - d("r"), y: d("cy") - d("r"), width: 2 * d("r"), height: 2 * d("r")), transform: nil)
            case "ellipse": p = CGPath(ellipseIn: CGRect(x: d("cx") - d("rx"), y: d("cy") - d("ry"), width: 2 * d("rx"), height: 2 * d("ry")), transform: nil)
            default:
                let rx = min(d("rx"), d("width") / 2), ry = min(a["ry"] != nil ? d("ry") : rx, d("height") / 2)
                p = CGPath(roundedRect: CGRect(x: d("x"), y: d("y"), width: d("width"), height: d("height")), cornerWidth: rx, cornerHeight: ry, transform: nil)
            }
            var tt = t
            let shaped = p.copy(using: &tt) ?? p
            if let layer = layerStack.last(where: { $0 != nil }) ?? nil, layer != "@part", let part = partStack.last { part.shapes[layer]!.append(Shape(path: shaped, style: st)) }
        default: break
        }
    }
    func parser(_ parser: XMLParser, didEndElement el: String, namespaceURI: String?, qualifiedName: String?) {
        guard el == "g" else { return }
        if layerStack.removeLast() == "@part" { partStack.removeLast() }
        styleStack.removeLast(); tStack.removeLast()
    }
}

/// One part's texture at `scale` px per artboard unit, drawing `layers`; returns (w, h, png bytes, ms).
func raster(_ part: Part, layers: [String], scale: Double) -> (Int, Int, Int, Double)? {
    let shapes = layers.flatMap { part.shapes[$0] ?? [] }
    guard !shapes.isEmpty else { return nil }
    var box = CGRect.null
    for s in shapes { box = box.union(s.path.boundingBoxOfPath.insetBy(dx: -s.style.strokeWidth, dy: -s.style.strokeWidth)) }
    let w = max(1, Int((box.width * scale).rounded(.up))), h = max(1, Int((box.height * scale).rounded(.up)))
    let t0 = Date()
    guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
    ctx.translateBy(x: 0, y: CGFloat(h)); ctx.scaleBy(x: scale, y: -scale); ctx.translateBy(x: -box.minX, y: -box.minY)
    ctx.setLineJoin(.round); ctx.setLineCap(.round)
    for layer in layers {
        let ss = part.shapes[layer] ?? []
        guard !ss.isEmpty else { continue }
        let groupAlpha = ss.first!.style.opacity                 // the outline layer's 0.8 group opacity, applied once per layer
        ctx.setAlpha(groupAlpha); ctx.beginTransparencyLayer(auxiliaryInfo: nil); ctx.setAlpha(1)
        for s in ss {
            if let f = s.style.fill { ctx.addPath(s.path); ctx.setFillColor(f.copy(alpha: s.style.fillOpacity) ?? f); ctx.fillPath() }
            if let k = s.style.stroke { ctx.addPath(s.path); ctx.setStrokeColor(k); ctx.setLineWidth(s.style.strokeWidth); ctx.strokePath() }
        }
        ctx.endTransparencyLayer()
    }
    guard let img = ctx.makeImage() else { return nil }
    let data = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil) else { return nil }
    CGImageDestinationAddImage(dest, img, nil); CGImageDestinationFinalize(dest)
    return (w, h, data.length, Date().timeIntervalSince(t0) * 1000)
}

// Tiers (Cast Rendering R3, R11: stage <= 1024 px, list, parade 256 px; the values are data, these are R11's).
// R3: a tier is a HEIGHT (the smallest tier at least the figure's on-screen height in physical px; the figure is the
// 440-unit artboard height), so px per artboard unit = tier / 440 and a whole-artboard image is 1490 x 1024 at the
// stage tier. (F6's arithmetic, 1024 x 704, treats 1024 as the width: recorded in ADR-0009.)
let tiers: [(name: String, side: Double, layers: [String])] = [
    ("stage 1024", 1024, ["body", "outline", "detail"]),
    ("list 256", 256, ["body", "outline", "detail"]),
    ("parade 256", 256, ["body", "outline"]),
]
print("| creature | parts | SVG bytes (A stand-in) | tier | PNG bytes (B) | texture bytes w*h*4 | part-box sum / one image (F6 cap 1.5) | Mac CPU raster ms |")
print("|---|---|---|---|---|---|---|---|")
var totals: [String: (png: Int, tex: Int)] = [:], svgTotal = 0
for path in CommandLine.arguments.dropFirst() {
    let url = URL(fileURLWithPath: path)
    let data = try! Data(contentsOf: url)
    let r = SVGReader(); let x = XMLParser(data: data); x.delegate = r; precondition(x.parse(), "parse failed: \(path)")
    svgTotal += data.count
    for tier in tiers {
        let scale = tier.side / 440
        var png = 0, tex = 0, ms = 0.0
        for p in r.parts { if let (w, h, b, t) = raster(p, layers: tier.layers, scale: scale) { png += b; tex += w * h * 4; ms += t } }
        let whole = Int((640 * scale).rounded(.up)) * Int(tier.side) * 4
        totals[tier.name, default: (0, 0)].png += png; totals[tier.name, default: (0, 0)].tex += tex
        print("| \(url.deletingPathExtension().lastPathComponent) | \(r.parts.count) | \(data.count) | \(tier.name) | \(png) | \(tex) | \(String(format: "%.2f", Double(tex) / Double(whole))) | \(String(format: "%.1f", ms)) |")
    }
}
let n = CommandLine.arguments.count - 1
print("")
print("Totals over \(n) creatures: SVG \(svgTotal) bytes. " + tiers.map { "\($0.name): PNG \(totals[$0.name]!.png) bytes, texture \(totals[$0.name]!.tex) bytes" }.joined(separator: "; "))
let pngAll = totals.values.reduce(0) { $0 + $1.png }
print(String(format: "Per creature, all tiers: PNG %.0f bytes vs SVG %.0f bytes. Linear extrapolation to 36 items (PARTIAL, 3 test creatures): PNG %.2f MB vs SVG %.2f MB.",
             Double(pngAll) / Double(n), Double(svgTotal) / Double(n), Double(pngAll) / Double(n) * 36 / 1_048_576, Double(svgTotal) / Double(n) * 36 / 1_048_576))
