import MorphCore

/// Key Table & Theme Data (key-table-theme-data.md): the plain models (ADR-0003 D7), the V1–V18 validator (§6),
/// and the F1 item pick with `resolve` / `peek` (§4). Decoding files into these models is Tools' (ADR-0004 D3).
public enum KeyTable {
    /// The canonical key order, A–Z then 0–9 (§1.2). A constant, never the JSON's order.
    public static let keys: [String] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".unicodeScalars.map { String($0) }
    /// The schema majors this app knows (V1).
    public static let knownSchemaVersions: Set<Int> = [1, 2]
    /// The eight hue slots (V10). `shared` is outside them (KT-Q7).
    public static let hueSlots: Set<String> = ["rose", "coral", "ochre", "leaf", "mint", "teal", "blue", "violet"]
    static let numberWords = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
}

/// One item of a key entry (§2b).
public struct ThemeItem: Equatable, Sendable {
    public var castId, name, word, say: String
    public var sound: String?
    public var family, variant, hueSlot, art, silhouette: String
    public var sfx: String?
    /// Voice line kind → line id, e.g. `letter` → `c`, `word` → `triceratops` (§2b).
    public var voice: [String: String]
    public var weight: Double?

    public init(castId: String, name: String, word: String, say: String, sound: String?, family: String, variant: String,
                hueSlot: String, art: String, silhouette: String, sfx: String?, voice: [String: String], weight: Double?) {
        self.castId = castId; self.name = name; self.word = word; self.say = say; self.sound = sound
        self.family = family; self.variant = variant; self.hueSlot = hueSlot; self.art = art
        self.silhouette = silhouette; self.sfx = sfx; self.voice = voice; self.weight = weight
    }
}

/// The counted item (§2a, §3).
public struct CountedItem: Equatable, Sendable {
    public var castId, singular, plural, emptyCastId, emptyWord: String
    public init(castId: String, singular: String, plural: String, emptyCastId: String, emptyWord: String) {
        self.castId = castId; self.singular = singular; self.plural = plural; self.emptyCastId = emptyCastId; self.emptyWord = emptyWord
    }
}

/// A decoded theme (§2a). `keys` holds whatever keys the file has, valid or not (V2, V3 judge them).
public struct ThemeModel: Equatable, Sendable {
    public var schemaVersion: Int
    public var contentVersion, id: String
    public var assetPrefix: String?
    public var name: String
    public var voiceLocales: [String]
    public var glyphSet: String
    /// Family id → idle parameter id.
    public var families: [String: String]
    public var countedItem: CountedItem
    public var soundExceptions: [String: String]
    /// Locale → line id (`<kind>_<id>`) → seconds.
    public var voiceDurations: [String: [String: Double]]
    public var titleCastId: String?
    public var rowWords: [String]?
    public var keys: [String: [ThemeItem]]

    public init(schemaVersion: Int, contentVersion: String, id: String, assetPrefix: String?, name: String,
                voiceLocales: [String], glyphSet: String, families: [String: String], countedItem: CountedItem,
                soundExceptions: [String: String], voiceDurations: [String: [String: Double]], titleCastId: String?,
                rowWords: [String]?, keys: [String: [ThemeItem]]) {
        self.schemaVersion = schemaVersion; self.contentVersion = contentVersion; self.id = id; self.assetPrefix = assetPrefix
        self.name = name; self.voiceLocales = voiceLocales; self.glyphSet = glyphSet; self.families = families
        self.countedItem = countedItem; self.soundExceptions = soundExceptions; self.voiceDurations = voiceDurations
        self.titleCastId = titleCastId; self.rowWords = rowWords; self.keys = keys
    }

    /// The keys present, in canonical order (§1.2); keys outside A–Z, 0–9 are not listed.
    public var keyOrder: [String] { KeyTable.keys.filter { keys[$0] != nil } }

    /// The prefix of every castId and asset name: `assetPrefix`, or the `id` for a v1 theme (V6).
    public var namingPrefix: String? { assetPrefix ?? (schemaVersion < 2 ? id : nil) }
}

/// The glyph set (§2c). `licence` and the other font fields are optional so V9 can judge them.
public struct GlyphSetModel: Equatable, Sendable {
    public var id: String
    public var fontName, fontVersion, fontLicence: String?
    public var baker: String
    /// Key → relative path of the baked glyph.
    public var glyphs: [String: String]
    public init(id: String, fontName: String?, fontVersion: String?, fontLicence: String?, baker: String, glyphs: [String: String]) {
        self.id = id; self.fontName = fontName; self.fontVersion = fontVersion; self.fontLicence = fontLicence
        self.baker = baker; self.glyphs = glyphs
    }
}

/// What the validator needs to know about the bundled files, measured upstream (§6; ADR-0003 D3).
public struct ThemeAssetFacts {
    /// The theme's folder name (V18).
    public var folder: String
    /// The `assetPrefix` of every other bundled theme (V18).
    public var otherThemePrefixes: [String]
    /// Exact-case existence and decoded durations (V7, V12, V15).
    public var probe: ContentProbe
    /// The morph-v1 path text of a silhouette file (V8), by its relative path.
    public var silhouettePath: (String) -> String?
    /// The morph-v1 path text of a glyph (V8), by key.
    public var glyphPath: (String) -> String?

    public init(folder: String, otherThemePrefixes: [String], probe: ContentProbe,
                silhouettePath: @escaping (String) -> String?, glyphPath: @escaping (String) -> String?) {
        self.folder = folder; self.otherThemePrefixes = otherThemePrefixes; self.probe = probe
        self.silhouettePath = silhouettePath; self.glyphPath = glyphPath
    }
}

/// The validator's verdict: the V-rule numbers that fail, in rule order (§6), with one message each.
public struct ThemeVerdict: Equatable, Sendable {
    public var failed: [Int: [String]] = [:]
    public var pass: Bool { failed.isEmpty }
    /// `["V2", "V6"]`, in rule-number order.
    public var failedRules: [String] { failed.keys.sorted().map { "V\($0)" } }
    mutating func fail(_ rule: Int, _ message: String) { failed[rule, default: []].append(message) }
}

extension KeyTable {
    /// V1–V18 over one theme (§6). `singleItemPerKey` is the build setting (V2, KT-Q4): nil at load time.
    public static func validate(_ t: ThemeModel, glyphs g: GlyphSetModel, assets a: ThemeAssetFacts,
                                singleItemPerKey: Bool? = nil) -> ThemeVerdict {
        var v = ThemeVerdict()
        // V1
        if !knownSchemaVersions.contains(t.schemaVersion) { v.fail(1, "unknown schemaVersion") }
        // V2, V3
        for k in keys {
            guard let items = t.keys[k], !items.isEmpty else { v.fail(2, "key \(k) missing or empty"); continue }
            if singleItemPerKey == true && items.count != 1 { v.fail(2, "key \(k) has \(items.count) items at build") }
        }
        let keySet = Set(keys)
        for k in t.keys.keys.sorted() where !keySet.contains(k) { v.fail(3, "extra key \(k)") }

        let entries: [(key: String, index: Int, item: ThemeItem)] = keys.flatMap { k in
            (t.keys[k] ?? []).enumerated().map { (key: k, index: $0.offset, item: $0.element) }
        }
        let prefix = t.namingPrefix
        var castIds = Set<String>()
        for (k, i, it) in entries {
            let isDigit = isASCIIDigit(k)
            // V4
            if !isDigit {
                if !asciiUppercased(it.word).contains(k) { v.fail(4, "\(it.castId): word lacks \(k)") }
                switch it.sound {
                case "start", "inside", "end": break
                case "exception": if t.soundExceptions[k] == nil { v.fail(4, "\(it.castId): exception not listed") }
                default: v.fail(4, "\(it.castId): sound unset")
                }
            }
            // V5
            if isDigit {
                let d = Int(k) ?? 0
                if d == 0 {
                    if it.castId != t.countedItem.emptyCastId || it.word != t.countedItem.emptyWord { v.fail(5, "key 0 is not the empty item") }
                } else {
                    let want = numberWords[d] + " " + (d == 1 ? t.countedItem.singular : t.countedItem.plural)
                    if it.word != want { v.fail(5, "\(it.castId): word must be '\(want)'") }
                }
            }
            // V6
            if !castIds.insert(it.castId).inserted { v.fail(6, "duplicate castId \(it.castId)") }
            if let p = prefix {
                let nn = (i + 1 < 10 ? "0" : "") + String(i + 1)
                let stem = p + "_" + asciiLowercasedKey(k) + "_"
                if !isAssetStem(it.castId, stem: stem, nn: nn) { v.fail(6, "\(it.castId): castId pattern") }
                // Art bible §8 naming with the same prefix, key and edition: `<category>_<stem><name>_<nn>.<ext>`.
                if !isAssetName(it.art, dir: "cast/cast_", stem: stem, nn: nn, ext: ".json") { v.fail(6, "\(it.castId): art name") }
                if !isAssetName(it.silhouette, dir: "sil/sil_", stem: stem, nn: nn, ext: ".json") { v.fail(6, "\(it.castId): silhouette name") }
                if let s = it.sfx, !isAssetName(s, dir: "sfx/sfx_", stem: stem, nn: nn, ext: ".m4a") { v.fail(6, "\(it.castId): sfx name") }
            } else { v.fail(6, "\(it.castId): no prefix to check") }
            // V7
            var files = [it.art, it.silhouette]
            if let s = it.sfx { files.append(s) }
            for loc in t.voiceLocales { for (kind, id) in it.voice.sorted(by: { $0.key < $1.key }) { files.append(voicePath(loc, kind, id)) } }
            for f in files where !a.probe.exists(f) { v.fail(7, "missing \(f)") }
            // V8
            if !pathIsDrawable(a.silhouettePath(it.silhouette)) { v.fail(8, "\(it.silhouette): not a drawable morph-v1 path") }
            // V12
            if let s = it.sfx, let d = a.probe.decodedDuration(s), d > 2.0 { v.fail(12, "\(s): \(d) s") }
            // V13
            if t.families[it.family] == nil { v.fail(13, "\(it.castId): unknown family") }
            // V14
            if let w = it.weight, !(w > 0) { v.fail(14, "\(it.castId): weight") }
        }
        // V8 glyphs, V9
        for k in keys {
            guard g.glyphs[k] != nil else { v.fail(9, "glyph \(k) missing"); continue }
            if !pathIsDrawable(a.glyphPath(k)) { v.fail(8, "glyph \(k): not a drawable morph-v1 path") }
        }
        if (g.fontName ?? "").isEmpty || (g.fontVersion ?? "").isEmpty || (g.fontLicence ?? "").isEmpty { v.fail(9, "font name, version or licence missing") }
        // V10
        var perSlot: [String: Int] = [:]
        var familySlots: [String: [String]] = [:]
        for (_, _, it) in entries where hueSlots.contains(it.hueSlot) {
            perSlot[it.hueSlot, default: 0] += 1
            familySlots[it.family, default: []].append(it.hueSlot)
        }
        for (s, n) in perSlot.sorted(by: { $0.key < $1.key }) where n > 4 { v.fail(10, "\(n) items in \(s)") }
        for (f, slots) in familySlots.sorted(by: { $0.key < $1.key }) {
            if Set(slots).count != slots.count { v.fail(10, "family \(f): siblings share a slot") }
            if slots.contains("leaf") && slots.contains("mint") { v.fail(10, "family \(f): leaf and mint") }
        }
        // V11
        var pairs = Set<String>()
        for (_, _, it) in entries where !pairs.insert(it.family + "\u{1F}" + it.variant).inserted { v.fail(11, "\(it.castId): family + variant repeated") }
        // V15
        for loc in t.voiceLocales {
            var want: [String: String] = [:]   // line id → kind
            for (_, _, it) in entries { for (kind, id) in it.voice { want[kind + "_" + id] = kind } }
            let have = t.voiceDurations[loc] ?? [:]
            for line in want.keys.sorted() where have[line] == nil { v.fail(15, "\(loc) \(line): no duration") }
            for line in have.keys.sorted() where want[line] == nil { v.fail(15, "\(loc) \(line): not a line of this theme") }
            for (line, kind) in want.sorted(by: { $0.key < $1.key }) {
                guard let d = have[line] else { continue }
                let id = String(line.utf8.dropFirst(kind.utf8.count + 1)) ?? ""
                if let m = a.probe.decodedDuration(voicePath(loc, kind, id)), abs(d - m) > 0.01 + 1e-9 { v.fail(15, "\(loc) \(line): \(d) vs measured \(m)") }
                if kind == "word" ? d > 1.25 : d > 1.0 { v.fail(15, "\(loc) \(line): too long") }
            }
        }
        // V16
        if let id = t.titleCastId, castIds.contains(id) {} else { v.fail(16, "titleCastId names no item") }
        // V17
        if t.schemaVersion >= 2 {
            if let words = t.rowWords {
                if words.count < 8 { v.fail(17, "fewer than 8 rowWords") }
                if Set(words).count != words.count { v.fail(17, "rowWords repeat") }
                for w in words {
                    let n = scalarCount(w)
                    if n < 2 || n > 8 || !isASCIIUpperLetters(w) { v.fail(17, "rowWord \(w)") }
                    else if !asciiLetters(w).allSatisfy({ t.keys[$0] != nil }) { v.fail(17, "rowWord \(w): letter not a key") }
                }
            } else { v.fail(17, "schema 2 needs rowWords") }
        }
        // V18
        if t.schemaVersion >= 2 {
            if let p = t.assetPrefix {
                let n = scalarCount(p)
                if n < 2 || n > 8 || !p.utf8.allSatisfy({ $0 >= 0x61 && $0 <= 0x7A }) { v.fail(18, "assetPrefix format") }
                if a.otherThemePrefixes.contains(p) { v.fail(18, "assetPrefix shared") }
            } else { v.fail(18, "assetPrefix missing") }
        }
        if t.id != a.folder { v.fail(18, "id differs from folder") }
        return v
    }

    /// `voice/<locale>/vo_<locale>_<kind>_<id>.m4a` (§2b: voice paths are built, not stored).
    public static func voicePath(_ locale: String, _ kind: String, _ id: String) -> String {
        "voice/\(locale)/vo_\(locale)_\(kind)_\(id).m4a"
    }

    /// V8: parses under morph-v1, has a subpath of 2+ points, and total length > 0.
    static func pathIsDrawable(_ d: String?) -> Bool {
        guard let d, let lines = try? SVGPath.polylines(d) else { return false }
        guard lines.contains(where: { $0.count >= 2 }) else { return false }
        var total = 0.0
        for l in lines { for j in l.indices.dropFirst() { let dx = l[j].x - l[j - 1].x, dy = l[j].y - l[j - 1].y; total += (dx * dx + dy * dy).squareRoot() } }
        return total > 0
    }

    static func isASCIIDigit(_ k: String) -> Bool { !k.isEmpty && k.utf8.allSatisfy { $0 >= 0x30 && $0 <= 0x39 } }
    static func asciiLowercasedKey(_ k: String) -> String {
        String(decoding: k.utf8.map { $0 >= 0x41 && $0 <= 0x5A ? $0 + 32 : $0 }, as: UTF8.self)
    }
    /// `<stem><name>_<nn>` with `<name>` one `[a-z][a-z0-9]*` token (V6).
    static func isAssetStem(_ s: String, stem: String, nn: String) -> Bool {
        guard s.hasPrefix(stem), s.hasSuffix("_" + nn) else { return false }
        let name = String(s.utf8.dropFirst(stem.utf8.count).dropLast(nn.utf8.count + 1)) ?? ""
        return isNameToken(name)
    }

    /// `<dir><stem><name>_<nn><ext>`, e.g. `cast/cast_dino_c_triceratops_01.json` (V6, art bible §8).
    static func isAssetName(_ s: String, dir: String, stem: String, nn: String, ext: String) -> Bool {
        guard s.hasPrefix(dir), s.hasSuffix(ext) else { return false }
        return isAssetStem(String(s.utf8.dropFirst(dir.utf8.count).dropLast(ext.utf8.count)) ?? "", stem: stem, nn: nn)
    }

    /// `[a-z][a-z0-9]*`.
    static func isNameToken(_ s: String) -> Bool {
        guard let f = s.utf8.first, f >= 0x61 && f <= 0x7A else { return false }
        return s.utf8.allSatisfy { ($0 >= 0x61 && $0 <= 0x7A) || ($0 >= 0x30 && $0 <= 0x39) }
    }
}

// MARK: - F1, resolve and peek (§4)

extension KeyTable {
    /// Whether F1 consumes a draw: only when |C| ≥ 2 (KT-Q2).
    public static func pickNeedsDraw(n: Int, last: Int?) -> Bool {
        n >= 2 && (last == nil ? n : n - 1) >= 2
    }

    /// F1: the item index for `n` items with `weights` (default 1), excluding `last`; `u` is used only when
    /// `pickNeedsDraw` is true.
    public static func pick(n: Int, weights: [Double]? = nil, last: Int?, u: Double) -> Int {
        if n <= 1 { return 0 }
        let c = (0..<n).filter { last == nil || $0 != last }
        if c.count == 1 { return c[0] }
        let w = { (i: Int) -> Double in weights.map { i < $0.count ? $0[i] : 1 } ?? 1 }
        let total = c.reduce(0.0) { $0 + w($1) }
        var run = 0.0
        for i in c {
            run += w(i)
            if run > u * total { return i }
        }
        return c[c.count - 1]
    }

    /// The Title's cast member (K-22): `titleCastId`, or key A's item 0 with `fellBack` set (one debug log line).
    public static func titleCast(_ t: ThemeModel) -> (item: ThemeItem?, fellBack: Bool) {
        let all = keys.flatMap { t.keys[$0] ?? [] }
        if let id = t.titleCastId, let it = all.first(where: { $0.castId == id }) { return (it, false) }
        return (t.keys["A"]?.first, true)
    }
}

/// The run's pick state: `lastShown[key]`, in memory only, reset on launch and on a theme change (§4.3).
public struct KeyVariety {
    public private(set) var lastShown: [String: Int]

    public init(lastShown: [String: Int] = [:]) { self.lastShown = lastShown }

    /// The item for `key` when its reveal starts (§4.1). `drawU` takes the next `key-variety` draw and returns its
    /// D4 `u` (`unitDraw`); it is called only when |C| ≥ 2.
    public mutating func resolve(_ key: String, in theme: ThemeModel, drawU: () -> Double) -> ThemeItem? {
        guard let items = theme.keys[key], !items.isEmpty else { return nil }
        let i = choose(items, key, drawU)
        lastShown[key] = i
        return items[i]
    }

    /// What `resolve` would pick now, without consuming the stream or touching `lastShown` (§4.5). `peekU` returns
    /// the `u` of the stream's next value without consuming it.
    public func peek(_ key: String, in theme: ThemeModel, peekU: () -> Double) -> ThemeItem? {
        guard let items = theme.keys[key], !items.isEmpty else { return nil }
        return items[choose(items, key, peekU)]
    }

    /// A theme change resets `lastShown` (§4.3).
    public mutating func themeChanged() { lastShown = [:] }

    func choose(_ items: [ThemeItem], _ key: String, _ drawU: () -> Double) -> Int {
        let last = lastShown[key].flatMap { $0 < items.count ? $0 : nil }
        let n = items.count
        let u = KeyTable.pickNeedsDraw(n: n, last: last) ? drawU() : 0
        return KeyTable.pick(n: n, weights: items.map { $0.weight ?? 1 }, last: last, u: u)
    }
}
