import ContractKit
import Foundation
import KidCore

/// The fixture JSON → the KidCore models (the model layer's input is "a decoded model", spec.md). Lenient on purpose:
/// strict decoding is the file layer's, in apple/Tools.
enum ThemeFixture {
    static func str(_ v: JSONValue?) -> String { v?.string ?? "" }
    static func strMap(_ v: JSONValue?) -> [String: String] {
        guard case .object(let o)? = v else { return [:] }
        return o.compactMapValues(\.string)
    }

    static func item(_ v: JSONValue) -> ThemeItem {
        ThemeItem(castId: str(v["castId"]), name: str(v["name"]), word: str(v["word"]), say: str(v["say"]),
                  sound: v["sound"]?.string, family: str(v["family"]), variant: str(v["variant"]), hueSlot: str(v["hueSlot"]),
                  art: str(v["art"]), silhouette: str(v["silhouette"]), sfx: v["sfx"]?.string, voice: strMap(v["voice"]),
                  weight: v["weight"]?.number)
    }

    static func theme(_ v: JSONValue) -> ThemeModel {
        var families: [String: String] = [:]
        if case .object(let f)? = v["families"] { for (k, x) in f { families[k] = str(x["idle"]) } }
        var durations: [String: [String: Double]] = [:]
        if case .object(let d)? = v["voiceDurations"] {
            for (loc, lines) in d { if case .object(let l) = lines { durations[loc] = l.compactMapValues(\.number) } }
        }
        var keys: [String: [ThemeItem]] = [:]
        if case .object(let k)? = v["keys"] { for (key, e) in k { keys[key] = (e["items"]?.array ?? []).map(item) } }
        let c = v["countedItem"]
        return ThemeModel(
            schemaVersion: Int(v["schemaVersion"]?.number ?? 0), contentVersion: str(v["contentVersion"]), id: str(v["id"]),
            assetPrefix: v["assetPrefix"]?.string, name: str(v["name"]),
            voiceLocales: (v["voiceLocales"]?.array ?? []).compactMap(\.string), glyphSet: str(v["glyphSet"]), families: families,
            countedItem: CountedItem(castId: str(c?["castId"]), singular: str(c?["singular"]), plural: str(c?["plural"]),
                                     emptyCastId: str(c?["emptyCastId"]), emptyWord: str(c?["emptyWord"])),
            soundExceptions: strMap(v["soundExceptions"]), voiceDurations: durations, titleCastId: v["titleCastId"]?.string,
            rowWords: v["rowWords"]?.array?.compactMap(\.string), keys: keys)
    }

    static func glyphs(_ v: JSONValue) -> GlyphSetModel {
        GlyphSetModel(id: str(v["id"]), fontName: v["font"]?["name"]?.string, fontVersion: v["font"]?["version"]?.string,
                      fontLicence: v["font"]?["licence"]?.string, baker: str(v["baker"]), glyphs: strMap(v["glyphs"]))
    }
}

/// The `assets` fixture as a `ContentProbe`: files in exact case, measured durations.
struct FixtureProbe: ContentProbe {
    let files: Set<String>
    let durations: [String: Double]
    func exists(_ path: String) -> Bool { files.contains(path) }
    func byteSize(_ path: String) -> Int64? { nil }
    func decodedDuration(_ path: String) -> Double? { durations[path] }
}

/// key-table-schema-v1, `model` layer (ADR-0004 D3: the KidCore harness).
struct KeyTableModelRunner: ContractRunner {
    static let contract = "key-table-schema-v1"
    static let layer: String? = "model"
    static let declaration = ContractDeclaration(
        givenFields: ["theme", "assets", "glyphSet", "buildSettings", "state", "themeBytes"],
        events: ["validate": [], "pick": ["n", "last", "weights"], "nextU": ["stream"], "resolve": ["key"], "peek": ["key"],
                 "themeChanged": ["theme"], "keysInOrder": [], "titleCast": [], "decodeTheme": []],
        layers: ["model", "file"])
    static func kind(out: String, field: String) -> String? { nil }

    let given: [String: JSONValue]
    let draws: DrawQueues
    var theme: ThemeModel?
    var variety: KeyVariety

    init(given: [String: JSONValue], draws: DrawQueues) throws {
        self.given = given
        self.draws = draws
        theme = given["theme"].map(ThemeFixture.theme)
        var last: [String: Int] = [:]
        if case .object(let o)? = given["state"]?["lastShown"] { for (k, v) in o { last[k] = v.number.map { Int($0) } } }
        variety = KeyVariety(lastShown: last)
    }

    func needDraw() throws -> UInt64 { try draws.next("key-variety") }

    mutating func step(uptime: Double, event e: [String: JSONValue]) throws -> Outputs {
        switch e["type"]?.string {
        case "validate":
            guard let t = theme, let g = given["glyphSet"], let a = given["assets"] else { throw ContractError("validate needs theme, glyphSet, assets") }
            var durations: [String: Double] = [:]
            for k in ["sfxDurations", "voiceMeasured"] { if case .object(let o)? = a[k] { for (p, v) in o { durations[p] = v.number } } }
            let sil = ThemeFixture.strMap(a["silhouettePaths"]), gp = ThemeFixture.strMap(g["glyphPaths"])
            let facts = ThemeAssetFacts(
                folder: a["folder"]?.string ?? "", otherThemePrefixes: (a["otherThemePrefixes"]?.array ?? []).compactMap(\.string),
                probe: FixtureProbe(files: Set((a["files"]?.array ?? []).compactMap(\.string)), durations: durations),
                silhouettePath: { sil[$0] }, glyphPath: { gp[$0] })
            let single: Bool? = given["buildSettings"]?["singleItemPerKey"].flatMap { if case .bool(let b) = $0 { return b } else { return nil } }
            let v = KeyTable.validate(t, glyphs: ThemeFixture.glyphs(g), assets: facts, singleItemPerKey: single)
            return [.object(["out": .string("verdict"), "pass": .bool(v.pass), "failedRules": .array(v.failedRules.map { .string($0) })])]
        case "pick":
            let n = Int(e["n"]?.number ?? 1), last = e["last"]?.number.map { Int($0) }
            let weights = e["weights"]?.array?.compactMap(\.number)
            let u = KeyTable.pickNeedsDraw(n: n, last: last) ? unitDraw(try needDraw()) : 0
            return [.object(["out": .string("picked"), "index": .int(Int64(KeyTable.pick(n: n, weights: weights, last: last, u: u)))])]
        case "nextU":
            return [.object(["out": .string("u"), "value": .double(unitDraw(try draws.next(e["stream"]?.string ?? "")))])]
        case "resolve", "peek":
            guard let t = theme else { throw ContractError("no theme") }
            let key = e["key"]?.string ?? ""
            var exhausted = false
            let item: ThemeItem?
            if e["type"]?.string == "resolve" {
                let q = draws
                item = variety.resolve(key, in: t) { if let v = try? q.next("key-variety") { return unitDraw(v) }; exhausted = true; return 0 }
            } else {
                let q = draws
                item = variety.peek(key, in: t) { if let v = q.queues["key-variety"]?.first { return unitDraw(v) }; exhausted = true; return 0 }
            }
            if exhausted { throw DrawQueues.Exhausted(stream: "key-variety") }
            return [.object(["out": .string("item"), "castId": .string(item?.castId ?? "")])]
        case "themeChanged":
            theme = e["theme"].map(ThemeFixture.theme)
            variety.themeChanged()
            return []
        case "keysInOrder":
            return [.object(["out": .string("keys"), "value": .array(KeyTable.keys.map { .string($0) })])]
        case "titleCast":
            guard let t = theme else { throw ContractError("no theme") }
            let (item, fellBack) = KeyTable.titleCast(t)
            return (fellBack ? [.object(["out": .string("log")])] : []) + [.object(["out": .string("item"), "castId": .string(item?.castId ?? "")])]
        default:
            throw ContractError("event \(e["type"]?.string ?? "?") not in the model layer")
        }
    }
}
