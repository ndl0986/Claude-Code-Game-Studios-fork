import AVFoundation
import Foundation
import KidCore

/// `kidtools validate` (ADR-0003 D3, TASK-079 S2 stub): runs KidCore's V1–V18 over every theme in a content folder
/// with a file-system probe, plus the build-only **staleness stub** (each baked art and silhouette has its SVG source
/// by the stem rule, ADR-0003 D1) and the audio staleness check (`Staleness`: sfx re-rendered and compared byte for byte,
/// voice by hashed render inputs and re-measured `voiceDurations`). The SVG checks wait for the bake tool story.
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
        /// Theme folders that hold only build inputs under `src/` (ADR-0003 D1: B files) and no `theme.json` yet: a
        /// theme in progress. Reported NOT ASSESSED, never PASS; `--release` FAILs on any (TASK-125).
        public var inProgress: [String] = []
        /// Checks that could not be made, one line each (e.g. a cast file that is not the baked layout): never a pass.
        public var notAssessed: [String] = []
        public var pass: Bool { findings.isEmpty }
        /// The exit decision: a merge needs no finding; a release also needs no theme in progress (TASK-125).
        public func passes(release: Bool) -> Bool { pass && !(release && !inProgress.isEmpty) }
    }

    /// True when `folder` holds nothing but a `src/` directory (hidden files aside): build-only inputs, nothing the
    /// bundle would ship (ADR-0003 D1, D8). Any other entry (cast/, sil/, sfx/, voice/, a stray file) makes it a theme
    /// that must have a `theme.json`.
    static func isSourceOnly(_ folder: URL) -> Bool {
        let entries = ((try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []).filter { !$0.hasPrefix(".") }
        var isDir: ObjCBool = false
        return entries == ["src"]
            && FileManager.default.fileExists(atPath: folder.appendingPathComponent("src").path, isDirectory: &isDir) && isDir.boolValue
    }

    /// The voice file a V15 message (`"<locale> <kind>_<id>: …"`) is about, relative to the theme folder, or nil.
    ///
    /// Example:
    /// ```swift
    /// voiceFile(forV15Message: "en-us word_x: too long", locales: ["en-us"])   // "voice/en-us/vo_en-us_word_x.caf"
    /// ```
    public static func voiceFile(forV15Message m: String, locales: [String]) -> String? {
        for loc in locales where m.hasPrefix(loc + " ") {
            let rest = m.dropFirst(loc.count + 1)
            guard let colon = rest.firstIndex(of: ":"), let us = rest.firstIndex(of: "_"), us < colon else { return nil }
            return KeyTable.voicePath(loc, String(rest[..<us]), String(rest[rest.index(after: us)..<colon]))
        }
        return nil
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
                if isSourceOnly(themesDir.appendingPathComponent(f)) { report.inProgress.append(f) }
                else { report.findings.append(Finding(theme: f, rule: "V1", message: "no theme.json")) }
                continue
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
                for m in msgs {
                    let named = rule == 15 ? (voiceFile(forV15Message: m, locales: model.voiceLocales).map { "\(m) [\($0)]" } ?? m) : m
                    report.findings.append(Finding(theme: folder, rule: "V\(rule)", message: named))
                }
            }
            for m in Staleness.check(themeDir: root, theme: model) { report.findings.append(Finding(theme: folder, rule: "stale", message: m)) }
            // Silhouette raster check (build only, ADR-0003 D4): each item's silhouette vs its art at rest.
            var pairs: [(art: String, silhouette: String)] = []
            for k in KeyTable.keys { for it in model.keys[k] ?? [] { pairs.append((it.art, it.silhouette)) } }
            let raster = RasterCheck.check(themeDir: root, pairs: pairs)
            for m in raster.failures { report.findings.append(Finding(theme: folder, rule: "raster", message: m)) }
            report.notAssessed += raster.notAssessed.map { "\(folder): \($0)" }
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
