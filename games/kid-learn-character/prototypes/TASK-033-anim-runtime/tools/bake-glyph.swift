// PROTOTYPE - NOT FOR PRODUCTION (TASK-033 spike)
// Bakes a glyph's outline from a font file into an SVG path "d" string (y down), so neither the app nor a Kotlin
// port rasterises fonts at run time: both sample the same path with MorphCore's SVGPath.sample.
//
//   swift tools/bake-glyph.swift <font.ttf> <char> <weight 100…700> > fixtures/glyph-D.json
import CoreText
import Foundation

let args = CommandLine.arguments
guard args.count >= 3 else { FileHandle.standardError.write("usage: bake-glyph <font> <char> [weight]\n".data(using: .utf8)!); exit(2) }
let url = URL(fileURLWithPath: args[1]) as CFURL
let ch = args[2], weight = args.count > 3 ? Double(args[3]) ?? 600 : 600

guard let descs = CTFontManagerCreateFontDescriptorsFromURL(url) as? [CTFontDescriptor], let base = descs.first else { fatalError("can't read font") }
// the variable font's weight axis ('wght' = 0x77676874)
let varDesc = CTFontDescriptorCreateCopyWithAttributes(base, [kCTFontVariationAttribute: [0x7767_6874: weight]] as CFDictionary)
let size = 1000.0
let font = CTFontCreateWithFontDescriptor(varDesc, size, nil)

var unichars = Array(ch.utf16), glyphs = [CGGlyph](repeating: 0, count: unichars.count)
guard CTFontGetGlyphsForCharacters(font, &unichars, &glyphs, unichars.count), let path = CTFontCreatePathForGlyph(font, glyphs[0], nil) else { fatalError("no glyph for \(ch)") }

func f(_ v: CGFloat) -> String { String(format: "%.2f", Double(v)) }
var d = ""
// font space is y up: flip to y down
path.applyWithBlock { el in
    let e = el.pointee, p = e.points
    switch e.type {
    case .moveToPoint: d += "M\(f(p[0].x)) \(f(-p[0].y))"
    case .addLineToPoint: d += "L\(f(p[0].x)) \(f(-p[0].y))"
    case .addQuadCurveToPoint: d += "Q\(f(p[0].x)) \(f(-p[0].y)) \(f(p[1].x)) \(f(-p[1].y))"
    case .addCurveToPoint: d += "C\(f(p[0].x)) \(f(-p[0].y)) \(f(p[1].x)) \(f(-p[1].y)) \(f(p[2].x)) \(f(-p[2].y))"
    case .closeSubpath: d += "Z"
    @unknown default: break
    }
}
let name = CTFontCopyName(font, kCTFontFullNameKey) as String? ?? "?"
let version = CTFontCopyName(font, kCTFontVersionNameKey) as String? ?? "?"
let out: [String: Any] = [
    "char": ch, "font": name, "fontVersion": version, "fontFile": (args[1] as NSString).lastPathComponent,
    "licence": "SIL Open Font License 1.1", "weight": weight, "unitsPerEm": CTFontGetUnitsPerEm(font), "size": size, "d": d,
]
let json = try JSONSerialization.data(withJSONObject: out, options: [.prettyPrinted, .sortedKeys])
print(String(decoding: json, as: UTF8.self))
