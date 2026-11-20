import CoreText
import Foundation
import KidCore

/// A glyph bake failure. It always names the font file; `key` is set when one key is at fault.
public struct GlyphBakeError: Error, CustomStringConvertible, Equatable {
    /// The font file, as the caller labelled it (`fonts/Fredoka-wdth-wght.ttf` from `bakeContent`).
    public let fontFile: String
    /// The key at fault (`"A"`, `"3"`), or nil when the font or the set as a whole is at fault.
    public let key: String?
    /// What is wrong.
    public let reason: String

    public var description: String { "\(fontFile): " + (key.map { "key '\($0)': " } ?? "") + reason }
}

/// Which font, weight and names make up one glyph set (Key Table §2c). The font's name and version are not here: the
/// bake reads them from the font itself.
///
/// Example:
/// ```swift
/// let spec = GlyphSetSpec.fredoka600   // content/fonts/Fredoka-wdth-wght.ttf at wght 600 → content/glyphs/fredoka600/
/// ```
public struct GlyphSetSpec: Equatable, Sendable {
    /// The set id: the folder under `content/glyphs/` and the theme's `glyphSet` (`fredoka600`).
    public var id: String
    /// The font file name under `content/fonts/`.
    public var fontFile: String
    /// The `<font>` part of `glyph_<font>_<char>.json` (art bible §8), lowercase.
    public var fileStem: String
    /// The value set on the variable font's `wght` axis.
    public var weight: Double
    /// The licence id written to `glyphs.json` (`OFL-1.1`).
    public var licence: String
    /// The licence text's file name, next to the font under `content/fonts/`.
    public var licenceFile: String

    public init(id: String, fontFile: String, fileStem: String, weight: Double, licence: String, licenceFile: String) {
        self.id = id; self.fontFile = fontFile; self.fileStem = fileStem; self.weight = weight
        self.licence = licence; self.licenceFile = licenceFile
    }

    /// The shipped set: Fredoka (OFL 1.1) at weight 600 (ADR-0003 D4, Key Table §2c).
    public static let fredoka600 = GlyphSetSpec(id: "fredoka600", fontFile: "Fredoka-wdth-wght.ttf", fileStem: "fredoka",
                                                weight: 600, licence: "OFL-1.1", licenceFile: "OFL.txt")

    /// `glyph_<fileStem>_<char>.json`, the character lowercased (`glyph_fredoka_a.json`, `glyph_fredoka_3.json`).
    public func glyphFileName(_ key: String) -> String { "glyph_\(fileStem)_\(key.lowercased()).json" }
}

/// The build-time glyph bake (ADR-0003 D4, TR-morph-002): CoreText's `CTFontCreatePathForGlyph` turns each key's
/// glyph into a morph-v1 path (`M L C Q Z`, at most 3 decimals, an `M` after every `Z`), written as
/// `{"d": …, "font": {name, version, weight, licence, licenceFile}, "tool": …, "version": …}` like a baked silhouette plus the font record, plus the set's `glyphs.json`. Apple frameworks and own
/// code only (K-31); nothing is rasterised.
///
/// Coordinates match the morph contract's committed glyph inputs (`glyph-D.json`, `glyph-3.json` of TASK-033): font
/// units (the font is sized at its units per em, 1000 for Fredoka), x as in the font, **y flipped to y down** with the
/// baseline at y = 0, so a capital spans roughly y -700…0. MorphCore fits the path into its unit box at run time.
/// The font's quadratic and cubic curves are kept as `Q` and `C`; nothing is flattened to lines.
///
/// CoreText's outlines may differ between macOS versions. The baked files are committed, and every one records
/// `SVGBake.toolName`/`toolVersion` (shared with the SVG bake); bump `toolVersion` when a re-bake changes bytes.
///
/// Example:
/// ```swift
/// let written = try GlyphBake.bakeContent(contentDir: URL(fileURLWithPath: "content"))
/// // ["glyphs/fredoka600/glyph_fredoka_a.json", …, "glyphs/fredoka600/glyphs.json"]
/// let files = try GlyphBake.bakeSet(fontURL: url, spec: .fredoka600, keys: ["A", "3"])   // in memory, nothing written
/// ```
public enum GlyphBake {
    /// The OpenType `wght` variation axis tag, 'wght'.
    public static let weightAxis = 0x7767_6874

    /// What the bake read from the font itself.
    public struct FontFacts: Equatable, Sendable {
        /// The family name (`Fredoka`).
        public let name: String
        /// The version number without the `Version ` prefix (`2.001`).
        public let version: String
        /// Units per em; the font is sized to it, so paths are in font units.
        public let unitsPerEm: Int
        /// The `wght` value CoreText reports for the instance actually used.
        public let weight: Double
    }

    /// Opens `fontURL` (without registering it) at `weight` on the `wght` axis, sized to its units per em. Throws if the
    /// file is not a font or the instance does not report the requested weight (a static font or a missing axis).
    public static func openFont(_ fontURL: URL, weight: Double, label: String) throws -> (font: CTFont, facts: FontFacts) {
        guard let descs = CTFontManagerCreateFontDescriptorsFromURL(fontURL as CFURL) as? [CTFontDescriptor], let base = descs.first else {
            throw GlyphBakeError(fontFile: label, key: nil, reason: "missing or not a font file")
        }
        let desc = CTFontDescriptorCreateCopyWithAttributes(base, [kCTFontVariationAttribute: [weightAxis: weight]] as CFDictionary)
        let probe = CTFontCreateWithFontDescriptor(desc, 12, nil)
        let upem = Int(CTFontGetUnitsPerEm(probe))
        guard upem > 0 else { throw GlyphBakeError(fontFile: label, key: nil, reason: "units per em is 0") }
        let font = CTFontCreateWithFontDescriptor(desc, CGFloat(upem), nil)
        let variation = (CTFontCopyVariation(font) as? [NSNumber: NSNumber]) ?? [:]
        guard let w = variation[NSNumber(value: weightAxis)]?.doubleValue, w == weight else {
            throw GlyphBakeError(fontFile: label, key: nil, reason: "the font does not take wght \(SVGNumber.format(weight)) (variation: \(variation))")
        }
        let name = (CTFontCopyName(font, kCTFontFamilyNameKey) as String?) ?? ""
        var version = (CTFontCopyName(font, kCTFontVersionNameKey) as String?) ?? ""
        if version.hasPrefix("Version ") { version.removeFirst("Version ".count) }
        if let semi = version.firstIndex(of: ";") { version = String(version[..<semi]) }
        guard !name.isEmpty, !version.isEmpty else { throw GlyphBakeError(fontFile: label, key: nil, reason: "the font has no family name or version") }
        return (font, FontFacts(name: name, version: version, unitsPerEm: upem, weight: w))
    }

    /// The morph-v1 path of one key's glyph (one Unicode scalar). Throws naming the key and `label` when the font maps
    /// no glyph to it or the glyph has no drawable outline.
    public static func path(font: CTFont, key: String, label: String) throws -> String {
        guard key.unicodeScalars.count == 1 else { throw GlyphBakeError(fontFile: label, key: key, reason: "a key is one character") }
        var chars = Array(key.utf16), glyphs = [CGGlyph](repeating: 0, count: chars.count)
        guard CTFontGetGlyphsForCharacters(font, &chars, &glyphs, chars.count), glyphs[0] != 0 else {
            throw GlyphBakeError(fontFile: label, key: key, reason: "the font has no glyph for this key")
        }
        guard let cg = CTFontCreatePathForGlyph(font, glyphs[0], nil) else {
            throw GlyphBakeError(fontFile: label, key: key, reason: "the glyph has no outline")
        }
        var segs: [Seg] = []
        cg.applyWithBlock { el in
            let p = el.pointee.points
            func pt(_ i: Int) -> P { P(x: Double(p[i].x), y: Double(p[i].y)) }
            switch el.pointee.type {
            case .moveToPoint: segs.append(.move(pt(0)))
            case .addLineToPoint: segs.append(.line(pt(0)))
            case .addQuadCurveToPoint: segs.append(.quad(pt(0), pt(1)))
            case .addCurveToPoint: segs.append(.cubic(pt(0), pt(1), pt(2)))
            case .closeSubpath: segs.append(.close)
            @unknown default: break
            }
        }
        var w = PathWriter(allowHV: false)
        w.add(segs, transformedBy: Matrix(d: -1))   // font space is y up; the morph inputs are y down
        if let problem = MorphPathCheck.problem(w.text) {
            throw GlyphBakeError(fontFile: label, key: key, reason: "the baked path is not drawable under morph-v1 (\(problem))")
        }
        return w.text
    }

    /// Bakes the whole set in memory: file name → bytes, one `glyph_<font>_<char>.json` per key plus `glyphs.json`.
    /// The first key that fails stops the bake, so a failure yields nothing. `keys` defaults to the 36 keys A–Z, 0–9.
    public static func bakeSet(fontURL: URL, spec: GlyphSetSpec, keys: [String] = KeyTable.keys,
                               label: String? = nil) throws -> (files: [String: [UInt8]], facts: FontFacts) {
        let label = label ?? fontURL.lastPathComponent
        let (font, facts) = try openFont(fontURL, weight: spec.weight, label: label)
        var files: [String: [UInt8]] = [:], index: [String: JSONValue] = [:]
        // ADR-0001 D6 / ADR-0003 D4: every glyph file records the font's name, version and licence (game-dev-ios review).
        let fontRecord: [String: JSONValue] = ["name": .string(facts.name), "version": .string(facts.version), "weight": .number(spec.weight),
                                               "licence": .string(spec.licence), "licenceFile": .string(spec.licenceFile)]
        for key in keys {
            let d = try path(font: font, key: key, label: label)
            let name = spec.glyphFileName(key)
            files[name] = JSONValue.object(["d": .string(d), "font": .object(fontRecord), "tool": .string(SVGBake.toolName), "version": .string(SVGBake.toolVersion)]).render()
            index[key] = .string(name)
        }
        files["glyphs.json"] = JSONValue.object([
            "id": .string(spec.id),
            // The metrics (font units, at the baked size of units per em) let the glyph renderer (Cast Rendering R4) draw
            // every letter at one cap height (game-dev-ios advisory).
            "font": .object(fontRecord.merging([
                "unitsPerEm": .number(Double(facts.unitsPerEm)),
                "capHeight": .number(Double(CTFontGetCapHeight(font))),
                "ascender": .number(Double(CTFontGetAscent(font))),
            ]) { a, _ in a }),
            "baker": .string("\(SVGBake.toolName) \(SVGBake.toolVersion)"),
            "glyphs": .object(index),
        ]).render()
        return (files, facts)
    }

    /// Bakes `<contentDir>/fonts/<spec.fontFile>` into `<contentDir>/glyphs/<spec.id>/` and returns the written paths
    /// relative to `contentDir`, sorted. The licence file must sit next to the font. Nothing is written unless every
    /// key bakes.
    public static func bakeContent(contentDir: URL, spec: GlyphSetSpec = .fredoka600, keys: [String] = KeyTable.keys) throws -> [String] {
        let fonts = contentDir.appendingPathComponent("fonts")
        let label = "fonts/\(spec.fontFile)"
        guard FileManager.default.fileExists(atPath: fonts.appendingPathComponent(spec.licenceFile).path) else {
            throw GlyphBakeError(fontFile: label, key: nil, reason: "licence file fonts/\(spec.licenceFile) is missing")
        }
        let files = try bakeSet(fontURL: fonts.appendingPathComponent(spec.fontFile), spec: spec, keys: keys, label: label).files
        let out = contentDir.appendingPathComponent("glyphs/\(spec.id)")
        try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        for name in files.keys.sorted() { try Data(files[name]!).write(to: out.appendingPathComponent(name)) }
        return files.keys.sorted().map { "glyphs/\(spec.id)/\($0)" }
    }
}
