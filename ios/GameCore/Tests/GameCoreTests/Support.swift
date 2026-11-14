import Foundation
import XCTest
@testable import GameCore

/// Paths into the repo's shared content/ folder, read in place by the tests.
enum Repo {
    /// `CONTENT_ROOT` points the suite at another content/ tree (e.g. a content branch under review).
    static let content = ProcessInfo.processInfo.environment["CONTENT_ROOT"].map { URL(fileURLWithPath: $0) }
        ?? URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("content")
    static let data = content.appendingPathComponent("data")
    static let sample = content.appendingPathComponent("samples/heroes/sample")
    static func json(_ path: String) throws -> Any {
        try JSONSerialization.jsonObject(with: Data(contentsOf: content.appendingPathComponent(path)))
    }
    static func fixture(_ name: String) throws -> [[String: Any]] {
        let f = try json("fixtures/\(name).json") as! [String: Any]
        return f["cases"] as! [[String: Any]]
    }
    static func contentSet() throws -> ContentSet { try ContentSet.load(dataRoot: data, extraHeroDirs: [sample]) }
    /// The debug sample hero (real heroes from data/index.json come first).
    static func sampleHero(_ c: ContentSet) -> HeroContent { c.heroes.first { $0.mission.hero.id == "sample" }! }
}

/// A small JSON Schema 2020-12 validator for the subset content/schema uses (ADR-0001: schema
/// checks are test-only). Supports $ref (local and to sibling files), type, required, properties,
/// additionalProperties, items, min/maxItems, uniqueItems, enum, const, pattern, min/maxLength,
/// minimum, maximum, exclusiveMinimum, oneOf, allOf, if/then, not.
struct MiniSchema {
    let schemas: [String: [String: Any]]   // file name → schema

    init(dir: URL) throws {
        var s: [String: [String: Any]] = [:]
        for f in try FileManager.default.contentsOfDirectory(atPath: dir.path) where f.hasSuffix(".json") {
            s[f] = try JSONSerialization.jsonObject(with: Data(contentsOf: dir.appendingPathComponent(f))) as? [String: Any]
        }
        schemas = s
    }

    func validate(_ value: Any, file: String) -> [String] {
        var errs: [String] = []
        check(value, schemas[file]!, file: file, path: "$", &errs)
        return errs
    }

    private func resolve(_ ref: String, file: String) -> (schema: [String: Any], file: String) {
        let parts = ref.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)
        let f = parts[0].isEmpty ? file : String(parts[0])
        var node: Any = schemas[f]!
        if parts.count > 1 {
            for key in parts[1].split(separator: "/") { node = (node as! [String: Any])[String(key)]! }
        }
        return (node as! [String: Any], f)
    }

    private func isType(_ v: Any, _ t: String) -> Bool {
        switch t {
        case "object": return v is [String: Any]
        case "array": return v is [Any]
        case "string": return v is String
        case "boolean": return (v as? NSNumber).map { CFGetTypeID($0) == CFBooleanGetTypeID() } ?? false
        case "null": return v is NSNull
        case "integer": if let n = v as? NSNumber, CFGetTypeID(n) != CFBooleanGetTypeID() { return n.doubleValue.rounded() == n.doubleValue }; return false
        case "number": if let n = v as? NSNumber { return CFGetTypeID(n) != CFBooleanGetTypeID() }; return false
        default: return false
        }
    }

    private func equal(_ a: Any, _ b: Any) -> Bool { (a as AnyObject).isEqual(b) }

    private func check(_ v: Any, _ s: [String: Any], file: String, path: String, _ errs: inout [String]) {
        if let ref = s["$ref"] as? String { let r = resolve(ref, file: file); check(v, r.schema, file: r.file, path: path, &errs) }
        if let t = s["type"] as? String, !isType(v, t) { errs.append("\(path): not \(t)"); return }
        if let e = s["enum"] as? [Any], !e.contains(where: { equal($0, v) }) { errs.append("\(path): not in enum") }
        if let c = s["const"], !equal(c, v) { errs.append("\(path): not const") }
        if let str = v as? String {
            if let p = s["pattern"] as? String, str.range(of: p, options: .regularExpression) == nil { errs.append("\(path): pattern \(p)") }
            if let m = s["minLength"] as? Int, str.count < m { errs.append("\(path): shorter than \(m)") }
            if let m = s["maxLength"] as? Int, str.count > m { errs.append("\(path): longer than \(m)") }
        }
        if let n = v as? NSNumber, !(v is String), CFGetTypeID(n) != CFBooleanGetTypeID() {
            let d = n.doubleValue
            if let m = s["minimum"] as? Double, d < m { errs.append("\(path): < \(m)") }
            if let m = s["maximum"] as? Double, d > m { errs.append("\(path): > \(m)") }
            if let m = s["exclusiveMinimum"] as? Double, d <= m { errs.append("\(path): <= \(m)") }
        }
        if let a = v as? [Any] {
            if let m = s["minItems"] as? Int, a.count < m { errs.append("\(path): fewer than \(m) items") }
            if let m = s["maxItems"] as? Int, a.count > m { errs.append("\(path): more than \(m) items") }
            if s["uniqueItems"] as? Bool == true, Set(a.map { "\($0)" }).count != a.count { errs.append("\(path): items not unique") }
            if let item = s["items"] as? [String: Any] { for (i, x) in a.enumerated() { check(x, item, file: file, path: "\(path)[\(i)]", &errs) } }
        }
        if let o = v as? [String: Any] {
            for r in s["required"] as? [String] ?? [] where o[r] == nil { errs.append("\(path): missing \(r)") }
            let props = s["properties"] as? [String: Any] ?? [:]
            for (k, x) in o {
                if let ps = props[k] as? [String: Any] { check(x, ps, file: file, path: "\(path).\(k)", &errs) }
                else if let ap = s["additionalProperties"] as? Bool, !ap { errs.append("\(path): unexpected \(k)") }
                else if let ap = s["additionalProperties"] as? [String: Any] { check(x, ap, file: file, path: "\(path).\(k)", &errs) }
            }
        }
        if let all = s["allOf"] as? [[String: Any]] { for sub in all { check(v, sub, file: file, path: path, &errs) } }
        if let one = s["oneOf"] as? [[String: Any]] {
            let ok = one.filter { sub in var e: [String] = []; check(v, sub, file: file, path: path, &e); return e.isEmpty }.count
            if ok != 1 { errs.append("\(path): oneOf matched \(ok)") }
        }
        if let iff = s["if"] as? [String: Any] {
            var e: [String] = []; check(v, iff, file: file, path: path, &e)
            if e.isEmpty, let then = s["then"] as? [String: Any] { check(v, then, file: file, path: path, &errs) }
        }
        if let not = s["not"] as? [String: Any] {
            var e: [String] = []; check(v, not, file: file, path: path, &e)
            if e.isEmpty { errs.append("\(path): matches not") }
        }
    }
}

final class MemoryStore: KeyValueStore {
    var values: [String: Any] = [:]
    func object(forKey k: String) -> Any? { values[k] }
    func set(_ v: Any?, forKey k: String) { values[k] = v }
}

/// A simple player for whole-mission tests: walks right, holds special in hold-meter, clears
/// training in order, turns toward the nearest enemy and swings. Story boxes are confirmed.
func botInput(_ p: PlayState, step: Int) -> StepInput {
    if p.phase == .caption { return StepInput(confirm: true) }
    if p.phase == .beatPlay, let b = p.currentBeat {
        if b.type == "hold-meter" { return StepInput(held: [.special]) }
        if b.type == "training" {
            switch p.trainingStage {
            case .dummies:
                guard let d = p.dummies.first(where: { !$0.hit }) else { return StepInput() }
                let dx = d.x - p.hero.x
                if dx > 150 || dx < 0 { return StepInput(held: [dx > 0 ? .right : .left]) }
                return StepInput(tapped: step % 3 == 0 ? [.attack] : [])
            case .blocks: return StepInput(held: [.defend])
            case .special: return StepInput(tapped: [.special])
            case .done: return StepInput()
            }
        }
    }
    guard let e = p.enemies.filter({ $0.state != .flee }).min(by: { abs($0.x - p.hero.x) < abs($1.x - p.hero.x) }) else {
        return StepInput(held: [.right])
    }
    let dx = e.x - p.hero.x
    let dir: PadAction = dx >= 0 ? .right : .left
    if (dx >= 0 ? 1.0 : -1.0) != p.hero.face { return StepInput(held: [dir]) }
    if abs(dx) > 170 { return StepInput(held: [dir]) }
    return StepInput(tapped: step % 3 == 0 ? [.attack] : [])
}

/// Runs a PlayState to its end with the bot, confirming beat cards. Returns the steps taken.
@discardableResult
func botRun(_ p: inout PlayState, maxSteps: Int = 60 * 900) -> Int {
    var step = 0
    while !p.finished && step < maxSteps {
        if p.phase == .beatCard { p.cardNext(); continue }
        p.update(1.0 / 60, botInput(p, step: step)); step += 1
    }
    return step
}

/// The real hero in data/ (Trần Quốc Toản).
func realHero(_ c: ContentSet) -> HeroContent { c.heroes.first { $0.mission.hero.id == "tran-quoc-toan" }! }
