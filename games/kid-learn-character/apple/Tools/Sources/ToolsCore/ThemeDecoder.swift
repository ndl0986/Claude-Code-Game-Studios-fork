import KidCore

/// Theme-file bytes → `ThemeModel` (Key Table §2a, §2b; KT-Q9). Strict: an unknown field, a missing required field
/// or a wrong type is a decode error naming the field. `assetPrefix`, `rowWords`, `titleCastId`, an item's `sound`,
/// `sfx` and `weight` may be absent (V4, V16, V17 and V18 judge them).
public enum ThemeDecoder {
    public struct DecodeError: Error, Equatable, CustomStringConvertible, Sendable {
        /// The field the error names.
        public let field: String
        public let reason: String
        public var description: String { "\(field): \(reason)" }
    }

    public typealias V = CanonicalJSON.Value

    static let themeRequired = ["schemaVersion", "contentVersion", "id", "name", "voiceLocales", "glyphSet", "families",
                                "countedItem", "soundExceptions", "voiceDurations", "keys"]
    static let themeOptional = ["assetPrefix", "titleCastId", "rowWords"]
    static let itemRequired = ["castId", "name", "word", "say", "family", "variant", "hueSlot", "art", "silhouette", "voice"]
    static let itemOptional = ["sound", "sfx", "weight"]

    /// Decodes `theme.json` bytes.
    public static func decode(_ bytes: [UInt8]) throws -> ThemeModel {
        let v: V
        do { v = try CanonicalJSON.parse(bytes) } catch { throw DecodeError(field: "(file)", reason: "not JSON") }
        return try decode(v)
    }

    /// Decodes an already-parsed theme value.
    public static func decode(_ v: V) throws -> ThemeModel {
        let o = try object(v, "(theme)", required: themeRequired, optional: themeOptional)
        var families: [String: String] = [:]
        for (k, f) in try object(o["families"]!, "families") {
            let fo = try object(f, "families.\(k)", required: ["idle"], optional: [])
            families[k] = try string(fo["idle"]!, "families.\(k).idle")
        }
        let c = try object(o["countedItem"]!, "countedItem", required: ["castId", "singular", "plural", "emptyCastId", "emptyWord"], optional: [])
        var durations: [String: [String: Double]] = [:]
        for (loc, lines) in try object(o["voiceDurations"]!, "voiceDurations") {
            var m: [String: Double] = [:]
            for (line, d) in try object(lines, "voiceDurations.\(loc)") { m[line] = try number(d, "voiceDurations.\(loc).\(line)") }
            durations[loc] = m
        }
        var keys: [String: [ThemeItem]] = [:]
        for (key, e) in try object(o["keys"]!, "keys") {
            let eo = try object(e, "keys.\(key)", required: ["items"], optional: [])
            keys[key] = try array(eo["items"]!, "keys.\(key).items").map(item)
        }
        guard case .number(let sv) = o["schemaVersion"]!, sv == roundHalfAwayFromZero(sv) else {
            throw DecodeError(field: "schemaVersion", reason: "not an integer")
        }
        return ThemeModel(
            schemaVersion: Int(sv), contentVersion: try string(o["contentVersion"]!, "contentVersion"),
            id: try string(o["id"]!, "id"), assetPrefix: try o["assetPrefix"].map { try string($0, "assetPrefix") },
            name: try string(o["name"]!, "name"),
            voiceLocales: try array(o["voiceLocales"]!, "voiceLocales").map { try string($0, "voiceLocales") },
            glyphSet: try string(o["glyphSet"]!, "glyphSet"), families: families,
            countedItem: CountedItem(castId: try string(c["castId"]!, "countedItem.castId"), singular: try string(c["singular"]!, "countedItem.singular"),
                                     plural: try string(c["plural"]!, "countedItem.plural"), emptyCastId: try string(c["emptyCastId"]!, "countedItem.emptyCastId"),
                                     emptyWord: try string(c["emptyWord"]!, "countedItem.emptyWord")),
            soundExceptions: try object(o["soundExceptions"]!, "soundExceptions").mapValues { try string($0, "soundExceptions") },
            voiceDurations: durations, titleCastId: try o["titleCastId"].map { try string($0, "titleCastId") },
            rowWords: try o["rowWords"].map { try array($0, "rowWords").map { try string($0, "rowWords") } }, keys: keys)
    }

    static func item(_ v: V) throws -> ThemeItem {
        let o = try object(v, "item", required: itemRequired, optional: itemOptional)
        let sfx: String?
        switch o["sfx"] { case nil, .null?: sfx = nil; case let s?: sfx = try string(s, "sfx") }
        return ThemeItem(
            castId: try string(o["castId"]!, "castId"), name: try string(o["name"]!, "name"), word: try string(o["word"]!, "word"),
            say: try string(o["say"]!, "say"), sound: try o["sound"].map { try string($0, "sound") },
            family: try string(o["family"]!, "family"), variant: try string(o["variant"]!, "variant"),
            hueSlot: try string(o["hueSlot"]!, "hueSlot"), art: try string(o["art"]!, "art"),
            silhouette: try string(o["silhouette"]!, "silhouette"), sfx: sfx,
            voice: try object(o["voice"]!, "voice").mapValues { try string($0, "voice") },
            weight: try o["weight"].map { try number($0, "weight") })
    }

    /// An object's members; with `required`, every other key outside `optional` is an error naming it.
    static func object(_ v: V, _ field: String, required: [String]? = nil, optional: [String] = []) throws -> [String: V] {
        guard case .object(let members) = v else { throw DecodeError(field: field, reason: "not an object") }
        var m: [String: V] = [:]
        for (k, x) in members { m[k] = x }
        if let required {
            let known = Set(required + optional)
            for (k, _) in members where !known.contains(k) { throw DecodeError(field: k, reason: "unknown field") }
            for k in required where m[k] == nil { throw DecodeError(field: k, reason: "missing") }
        }
        return m
    }

    static func string(_ v: V, _ field: String) throws -> String {
        guard case .string(let s) = v else { throw DecodeError(field: leaf(field), reason: "not a string") }
        return s
    }

    static func number(_ v: V, _ field: String) throws -> Double {
        guard case .number(let d) = v else { throw DecodeError(field: leaf(field), reason: "not a number") }
        return d
    }

    static func array(_ v: V, _ field: String) throws -> [V] {
        guard case .array(let a) = v else { throw DecodeError(field: leaf(field), reason: "not an array") }
        return a
    }

    /// The last path component: errors name the field itself (`schemaVersion`, `castId`).
    static func leaf(_ path: String) -> String { path.split(separator: ".").last.map(String.init) ?? path }
}
