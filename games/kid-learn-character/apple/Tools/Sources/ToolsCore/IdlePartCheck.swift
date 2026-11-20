import Foundation
import KidCore

/// The idle-part check (ADR-0003 D4; content-pipeline story 004): every part a family's idle moves exists, with a
/// pivot, in the baked cast file of every item of that family, else the bake fails naming the part and the file.
///
/// **The idle data is provisional.** Cast Rendering's idle parameters don't exist yet (Luan's OQ-1 for four
/// families), so this check reads a minimal test-only shape, `{ "<idleId>": { "parts": ["neck", "head"] } }`, from a
/// file passed in. Idle `none` moves nothing. With no idle file the check is **NOT ASSESSED**, never a silent pass.
///
/// Example:
/// ```swift
/// let r = IdlePartCheck.bakeStep(contentDir: content, idleFile: nil)
/// r.notAssessed   // ["NOT ASSESSED idle-part check: no idle data (OQ-1)"]
/// ```
public enum IdlePartCheck {
    /// The NOT ASSESSED line printed when there is no idle data.
    public static let noIdleData = "NOT ASSESSED idle-part check: no idle data (OQ-1)"

    /// Idle id → the part ids it moves.
    public typealias IdleData = [String: [String]]

    /// Parses the provisional idle data shape. Throws naming the problem.
    public static func parse(_ bytes: [UInt8]) throws -> IdleData {
        guard let obj = try? JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any] else {
            throw RasterCheck.FormatError(reason: "idle data is not a JSON object")
        }
        var out: IdleData = [:]
        for (id, v) in obj {
            guard let o = v as? [String: Any], let parts = o["parts"] as? [String] else {
                throw RasterCheck.FormatError(reason: "idle \(id): needs \"parts\": [string]")
            }
            out[id] = parts
        }
        return out
    }

    /// Checks one theme: each item's family → its idle id → each part must be in the item's cast file with a pivot.
    /// Returns one failure per missing part, naming the part, the idle and the cast file. An idle id missing from the
    /// data also fails. Cast files that are absent are skipped (the bake or V-rules report those).
    public static func check(themeDir: URL, theme: ThemeModel, idle: IdleData) -> [String] {
        var fails: [String] = []
        var seen = Set<String>()
        for k in KeyTable.keys {
            for it in theme.keys[k] ?? [] where seen.insert(it.art).inserted {
                guard let idleId = theme.families[it.family], idleId != "none" else { continue }
                guard let parts = idle[idleId] else {
                    fails.append("\(it.art): family \(it.family)'s idle \(idleId) is not in the idle data"); continue
                }
                let url = themeDir.appendingPathComponent(it.art)
                guard let data = FileManager.default.contents(atPath: url.path) else { continue }
                let have = pivotedParts(Array(data))
                for p in parts where !have.contains(p) {
                    fails.append("\(it.art): idle \(idleId) moves part \(p), which is not in the art with a pivot")
                }
            }
        }
        return fails
    }

    /// The step `kidtools bake` runs after the SVG bake: every theme with a `theme.json`, against `idleFile`.
    /// No idle file: one NOT ASSESSED line. A theme without `theme.json`: NOT ASSESSED naming the theme.
    public static func bakeStep(contentDir: URL, idleFile: URL?) -> (failures: [String], notAssessed: [String]) {
        guard let idleFile else { return ([], [noIdleData]) }
        let idle: IdleData
        do {
            guard let d = FileManager.default.contents(atPath: idleFile.path) else {
                return (["idle data \(idleFile.lastPathComponent): cannot read"], [])
            }
            idle = try parse(Array(d))
        } catch { return (["idle data \(idleFile.lastPathComponent): \(error)"], []) }
        var fails: [String] = [], na: [String] = []
        let themes = contentDir.appendingPathComponent("themes")
        let names = ((try? FileManager.default.contentsOfDirectory(atPath: themes.path)) ?? []).sorted()
        for name in names where !name.hasPrefix(".") {
            let dir = themes.appendingPathComponent(name)
            guard let bytes = FileManager.default.contents(atPath: dir.appendingPathComponent("theme.json").path) else {
                na.append("NOT ASSESSED idle-part check \(name): no theme.json (in progress)"); continue
            }
            do {
                let model = try ThemeDecoder.decode(Array(bytes))
                fails += check(themeDir: dir, theme: model, idle: idle).map { "\(name)/\($0)" }
            } catch { fails.append("\(name)/theme.json: \(error)") }
        }
        return (fails, na)
    }

    /// Part ids in a baked cast file that carry a two-number pivot.
    static func pivotedParts(_ castJSON: [UInt8]) -> Set<String> {
        guard let o = try? JSONSerialization.jsonObject(with: Data(castJSON)) as? [String: Any],
              let parts = o["parts"] as? [[String: Any]] else { return [] }
        return Set(parts.compactMap { p in
            guard let id = p["id"] as? String, let pv = p["pivot"] as? [Any], pv.count == 2, pv.allSatisfy({ $0 is NSNumber }) else { return nil }
            return id
        })
    }
}
