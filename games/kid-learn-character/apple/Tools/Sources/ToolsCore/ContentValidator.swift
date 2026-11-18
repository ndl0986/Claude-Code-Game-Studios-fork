import AVFoundation
import Foundation
import KidCore

/// `kidtools validate` (ADR-0003 D3, TASK-079 S2 stub): runs KidCore's V1–V18 over every theme in a content folder
/// with a file-system probe, plus the build-only **staleness stub** (each baked art and silhouette has its SVG source
/// by the stem rule, ADR-0003 D1). Byte-for-byte re-bake, the SVG checks and loudness wait for the bake tool story.
public enum ContentValidator {
    public struct Finding: Equatable, Sendable, CustomStringConvertible {
        public let theme: String
        public let rule: String
        public let message: String
        public var description: String { "FAIL \(theme) \(rule): \(message)" }
    }

    public struct Report: Sendable {
        public var themes: [String] = []
        public var findings: [Finding] = []
        public var pass: Bool { findings.isEmpty }
    }

    /// Validates `content/themes/*/theme.json` under `contentDir`. `singleItemPerKey` is the MVP build setting (V2).
    public static func run(contentDir: URL, singleItemPerKey: Bool = true) -> Report {
        var report = Report()
        let themesDir = contentDir.appendingPathComponent("themes")
        let folders = ((try? FileManager.default.contentsOfDirectory(atPath: themesDir.path)) ?? []).filter { !$0.hasPrefix(".") }.sorted()
        var decoded: [(folder: String, model: ThemeModel)] = []
        for f in folders {
            let file = themesDir.appendingPathComponent(f).appendingPathComponent("theme.json")
            guard let bytes = FileManager.default.contents(atPath: file.path) else {
                report.findings.append(Finding(theme: f, rule: "V1", message: "no theme.json")); continue
            }
            do { decoded.append((f, try ThemeDecoder.decode(Array(bytes)))) } catch {
                report.findings.append(Finding(theme: f, rule: "V1", message: "decode: \(error)"))
            }
        }
        for (folder, model) in decoded {
            report.themes.append(folder)
            let root = themesDir.appendingPathComponent(folder)
            let others = decoded.filter { $0.folder != folder }.compactMap(\.model.assetPrefix)
            let glyphDir = contentDir.appendingPathComponent("glyphs").appendingPathComponent(model.glyphSet)
            let glyphs: GlyphSetModel
            do { glyphs = try GlyphSetDecoder.decode(contentsOf: glyphDir.appendingPathComponent("glyphs.json")) } catch {
                report.findings.append(Finding(theme: folder, rule: "V9", message: "glyph set \(model.glyphSet): \(error)")); continue
            }
            let probe = FileProbe(root: root)
            let glyphProbe = FileProbe(root: glyphDir)
            let facts = ThemeAssetFacts(folder: folder, otherThemePrefixes: others, probe: probe,
                                        silhouettePath: { probe.pathText($0) },
                                        glyphPath: { k in glyphs.glyphs[k].flatMap { glyphProbe.pathText($0) } })
            let v = KeyTable.validate(model, glyphs: glyphs, assets: facts, singleItemPerKey: singleItemPerKey)
            for (rule, msgs) in v.failed.sorted(by: { $0.key < $1.key }) {
                for m in msgs { report.findings.append(Finding(theme: folder, rule: "V\(rule)", message: m)) }
            }
            // Staleness stub (build only): every baked art and silhouette has its source by the stem rule.
            for k in KeyTable.keys {
                for it in model.keys[k] ?? [] {
                    for (baked, src) in [(it.art, "src/art/"), (it.silhouette, "src/sil/")] {
                        let stem = (baked as NSString).lastPathComponent.replacingOccurrences(of: ".json", with: "")
                        if !probe.exists(src + stem + ".svg") {
                            report.findings.append(Finding(theme: folder, rule: "stale", message: "no source \(src)\(stem).svg for \(baked)"))
                        }
                    }
                }
            }
        }
        return report
    }
}

/// The glyph set file (Key Table §2c): `{ id, font { name, version, weight, licence, licenceFile }, baker, glyphs }`.
public enum GlyphSetDecoder {
    public static func decode(contentsOf url: URL) throws -> GlyphSetModel {
        guard let bytes = FileManager.default.contents(atPath: url.path) else { throw ThemeDecoder.DecodeError(field: "(file)", reason: "missing") }
        guard case .object(let m) = try CanonicalJSON.parse(Array(bytes)) else { throw ThemeDecoder.DecodeError(field: "(file)", reason: "not an object") }
        var o: [String: CanonicalJSON.Value] = [:]
        for (k, v) in m { o[k] = v }
        func str(_ v: CanonicalJSON.Value?) -> String? { if case .string(let s)? = v { return s } else { return nil } }
        var font: [String: CanonicalJSON.Value] = [:]
        if case .object(let f)? = o["font"] { for (k, v) in f { font[k] = v } }
        var glyphs: [String: String] = [:]
        if case .object(let g)? = o["glyphs"] { for (k, v) in g { if let s = str(v) { glyphs[k] = s } } }
        return GlyphSetModel(id: str(o["id"]) ?? "", fontName: str(font["name"]), fontVersion: str(font["version"]),
                             fontLicence: str(font["licence"]), baker: str(o["baker"]) ?? "", glyphs: glyphs)
    }
}

/// The file-system `ContentProbe` for Tools (ADR-0003 D3): exact case even on a case-insensitive volume.
public struct FileProbe: ContentProbe {
    public let root: URL
    public init(root: URL) { self.root = root }

    /// True only if every path component exists with exactly this spelling.
    public func exists(_ path: String) -> Bool {
        var dir = root
        for part in path.split(separator: "/").map(String.init) {
            guard let names = try? FileManager.default.contentsOfDirectory(atPath: dir.path), names.contains(part) else { return false }
            dir.appendPathComponent(part)
        }
        return true
    }

    public func byteSize(_ path: String) -> Int64? {
        guard exists(path), let a = try? FileManager.default.attributesOfItem(atPath: root.appendingPathComponent(path).path) else { return nil }
        return (a[.size] as? NSNumber)?.int64Value
    }

    /// Seconds of decoded audio (AVAudioFile's length, which excludes the AAC priming), or nil.
    public func decodedDuration(_ path: String) -> Double? {
        guard exists(path), let f = try? AVAudioFile(forReading: root.appendingPathComponent(path)) else { return nil }
        return Double(f.length) / f.processingFormat.sampleRate
    }

    /// The morph-v1 path text of a baked path file. **Provisional (S2 stub):** the file's top-level `"d"` string, until
    /// the bake tool story fixes the baked silhouette and glyph format (ADR-0003 D4).
    public func pathText(_ path: String) -> String? {
        guard exists(path), let bytes = FileManager.default.contents(atPath: root.appendingPathComponent(path).path),
              case .object(let m)? = try? CanonicalJSON.parse(Array(bytes)) else { return nil }
        for (k, v) in m where k == "d" { if case .string(let s) = v { return s } }
        return nil
    }
}
