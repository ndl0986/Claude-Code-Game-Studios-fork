import Foundation

/// The cross-file rules JSON Schema can't express (content/README.md, R2 and R4–R11).
/// Returns findings; an empty list means valid. R1 (schema) runs in the test target.
public struct ContentValidator {
    public struct Finding: Equatable, CustomStringConvertible, Sendable {
        public let rule: String
        public let message: String
        /// A warning (R15) never fails validation.
        public var isWarning = false
        public var description: String { "\(rule)\(isWarning ? " (warning)" : ""): \(message)" }
    }

    public let content: ContentSet
    /// R10 applies to `data/` only (P-04 item 5); the debug sample's pictures are drawn in code.
    public let checkPictures: Bool

    /// `dataRoot`: content/data on disk, so R19a can read each picture's header.
    public let dataRoot: URL?

    public init(content: ContentSet, checkPictures: Bool, dataRoot: URL? = nil) { self.content = content; self.checkPictures = checkPictures; self.dataRoot = dataRoot }

    public func validate() -> [Finding] {
        var out: [Finding] = []
        let sources = Dictionary(content.sources.sources.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let assetIds = Set(content.assets.assets.map(\.id))
        var ids = Set<String>()
        func checkIds(_ texts: [Text]) {
            for t in texts where !ids.insert(t.id).inserted { out.append(.init(rule: "R9", message: "duplicate Text id \(t.id)")) }
        }
        for s in content.strings.strings where !ids.insert(s.id).inserted { out.append(.init(rule: "R9", message: "duplicate id \(s.id)")) }
        for s in content.strings.strings {
            out += Self.nfc([s.vi, s.en], id: s.id)
            out += Self.enBudget(s.en, fieldType: s.field ?? Self.uiBudgetType(s.id), budgets: content.rules.textLimits.enBudget)
        }
        out += Self.schemaMajor(file: content.index.schemaVersion, app: ContentSet.supportedSchema)
        out += Self.tuningRules(content.tuning.values.mapValues(\.value))
        out += Self.starOrder(content.rules.quizStars.thresholds)
        // R8d (rules 1.2): every fit field has a size class and meets its minimum
        if let minPx = content.rules.textLimits.minPx, let fit = content.rules.textLimits.fit {
            for (name, f) in fit.fields.sorted(by: { $0.key < $1.key }) { out += Self.minSize(field: name, sizeClass: f.sizeClass, fontPx: f.fontPx, minPx: minPx) }
        }
        // R19a/R19b apply to schema 1.2 assets, which declare width/height
        for a in content.assets.assets where a.kind == "picture" {
            guard let w = a.width, let h = a.height else { continue }
            out += Self.pictureLimits(id: a.id, width: w, height: h)
            if let root = dataRoot, let d = try? Data(contentsOf: root.appendingPathComponent(a.file)), let real = Self.imageSize(d) {
                out += Self.declaredSize(id: a.id, declared: (w, h), actual: real)
            }
        }
        if let themes = content.themes {
            out += Self.themesCovered(themes: Array(themes.themes.keys), beatThemes: content.heroes.flatMap { $0.mission.beats.map(\.theme) })
        }
        let indexed = content.heroes.filter { content.index.heroes.contains($0.mission.hero.id) }
        out += Self.timeline(indexed.map { (id: $0.mission.hero.id, order: $0.mission.hero.timelineOrder, next: $0.mission.nextHero) })

        for hero in content.heroes {
            let claims = Dictionary(hero.claims.claims.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
            let texts = hero.mission.allTexts + hero.quiz.allTexts
            checkIds(texts)
            let labels = claims.mapValues(\.label)
            for t in texts {
                out += Self.nfc([t.vi, t.en], id: t.id)
                for c in t.claims where claims[c] == nil { out.append(.init(rule: "R2", message: "\(t.id) cites unknown claim \(c)")) }
            }
            // R4 on sentence fields; R4b on label fields (D-12)
            let m = hero.mission
            let dialogueSentences = m.beats.flatMap { ($0.params.lines ?? []).map(\.text) }
            let missionSentences = m.intro + m.beats.flatMap(\.scene) + m.ending.lines + dialogueSentences
            for t in m.intro + m.beats.flatMap(\.scene) + m.ending.lines { out += Self.legendMarker(t, labels: labels, markers: content.markers) }
            for b in m.beats {
                out += Self.cheerOnFight(beat: b.id, type: b.type, cheer: b.cheer)
                if b.type == "training" {
                    let t = content.tuning
                    out += Self.trainingZone(beat: b.id, dummies: b.params.dummies ?? 0, spacing: t["dummy_spacing"], enemyReach: t["enemy_reach"],
                                             edge: t["hero_edge_margin"], worldWidth: t.worldWidth)
                }
            }
            for b in m.beats where b.type == "dialogue" {
                out += Self.dialogueLegend(b.params.lines ?? [], labels: labels, markers: content.markers)
                if let a = b.params.ask { out += Self.askFits(lines: b.params.lines?.count ?? 0, taps: a.taps, atLine: a.atLine) }
            }
            var missionLabels = [m.hero.name, m.hero.place] + m.beats.flatMap { [$0.title] + ($0.goal.map { [$0] } ?? []) }
            if let b = m.banner { missionLabels.append(b) }
            for t in missionLabels { out += Self.legendLabel(t, scope: missionSentences, labels: labels, markers: content.markers) }
            for q in hero.quiz.questions {
                for t in [q.prompt, q.why] { out += Self.legendMarker(t, labels: labels, markers: content.markers) }
                for c in q.choices { out += Self.legendLabel(c.text, scope: [q.prompt, q.why], labels: labels, markers: content.markers) }
            }
            for c in hero.claims.claims {
                out += Self.sourceGate(c, sources: sources.mapValues(\.status))
                for s in c.sources where sources[s] == nil { out.append(.init(rule: "R2", message: "\(c.id) cites unknown source \(s)")) }
            }
            for t in hero.quiz.allTexts {
                for c in t.claims where claims[c]?.label == .invented { out.append(.init(rule: "R6", message: "\(t.id) quizzes invented claim \(c)")) }
            }
            out += budget(hero)
            for beat in hero.mission.beats { out += Self.beatButtons(type: beat.type, buttons: beat.buttons, params: beat.params) }
            if checkPictures {
                let portraits = hero.mission.beats.flatMap { ($0.params.lines ?? []).filter { $0.speaker != "narrator" }.map { Self.portraitId(hero: hero.mission.hero.id, $0) } }
                let pics = [hero.mission.ending.pictureId] + portraits + hero.quiz.questions.flatMap { q in (q.pictureId.map { [$0] } ?? []) + q.choices.map(\.pictureId) }
                for p in pics where !assetIds.contains(p) { out.append(.init(rule: "R10", message: "unknown picture id \(p)")) }
            }
        }
        return out
    }

    // MARK: single rules (each also driven by content/fixtures/validity.json)

    /// R4: a Text citing a legend claim carries a legend marker in VI and in EN.
    public static func legendMarker(_ t: Text, labels: [String: Claim.Label], markers: MarkersFile) -> [Finding] {
        guard t.claims.contains(where: { labels[$0] == .legend }) else { return [] }
        let okVi = markers.legend.vi.contains { t.vi.contains($0) }
        let okEn = markers.legend.en.contains { t.en.contains($0) }
        return okVi && okEn ? [] : [.init(rule: "R4", message: "\(t.id) cites a legend claim without a legend marker")]
    }

    /// R4b (D-12): a LABEL field (hero name, place, banner, beat title, goal, quiz choice) is exempt
    /// from R4 when, for each legend claim it cites, a sentence in its scope cites that claim and is
    /// marked in VI and in EN (the R4 test). Scope: the mission's sentences, or the choice's own
    /// question's prompt and why.
    public static func legendLabel(_ t: Text, scope: [Text], labels: [String: Claim.Label], markers: MarkersFile) -> [Finding] {
        for c in t.claims where labels[c] == .legend {
            let covered = scope.contains { s in
                s.claims.contains(c) && legendMarker(s, labels: labels, markers: markers).isEmpty
            }
            if !covered { return [.init(rule: "R4b", message: "\(t.id) labels legend claim \(c) with no marked sentence citing it")] }
        }
        return []
    }

    /// R5: a fact or fact_as_recorded claim can't be approved while a source is to_confirm; R5b: only invented may have no sources.
    public static func sourceGate(_ c: Claim, sources: [String: Source.Status]) -> [Finding] {
        var out: [Finding] = []
        if (c.label == .fact || c.label == .factAsRecorded), c.signoff.status == .approved,
           c.sources.contains(where: { sources[$0] != .confirmed }) {
            out.append(.init(rule: "R5", message: "\(c.id) approved while a source is to_confirm"))
        }
        if c.sources.isEmpty, c.label != .invented { out.append(.init(rule: "R5b", message: "\(c.id) has no sources")) }
        return out
    }

    /// R7: all text is NFC.
    public static func nfc(_ strings: [String], id: String) -> [Finding] {
        strings.contains { $0.precomposedStringWithCanonicalMapping.unicodeScalars.elementsEqual($0.unicodeScalars) == false }
            ? [.init(rule: "R7", message: "\(id) is not NFC")] : []
    }

    /// R8: EN fits the budget for its field type.
    public static func enBudget(_ en: String, fieldType: String, budgets: [String: Int]) -> [Finding] {
        guard let max = budgets[fieldType], en.count > max else { return [] }
        return [.init(rule: "R8", message: "EN \(fieldType) is \(en.count) chars, budget \(max)")]
    }

    /// R8 for strings.json: the budget type comes from the entry's `field` when set (D-21, as Android), else from the
    /// id (TASK-005e README).
    public static func uiBudgetType(_ id: String) -> String {
        if id.hasPrefix("ui.btn.") || id.hasPrefix("ui.pad.") || id.hasPrefix("ui.lang.") || id.hasSuffix("_confirm") || id.hasSuffix("_keep_reading") { return "button" }
        if id.hasSuffix("_warning") { return "dialog" }
        return "ui"
    }

    /// R11: a newer MAJOR fails (at build time); a newer MINOR passes.
    public static func schemaMajor(file: String, app: String) -> [Finding] {
        let f = Int(file.split(separator: ".").first ?? "") ?? Int.max
        let a = Int(app.split(separator: ".").first ?? "") ?? 0
        return f > a ? [.init(rule: "R11", message: "schema \(file) is newer than the app's \(app)")] : []
    }

    /// R13: minimum buttons per beat type, and `special` only where a type uses it; R13b: encounter order.
    public static func beatButtons(type: String, buttons: [String], params: BeatParams) -> [Finding] {
        var need: Set<String> = []
        var specialOK = false
        switch type {
        case "walk": need = ["move"]
        case "hold-meter": need = ["special"]; specialOK = true
        case "fight": need = ["move", "attack"]
        case "training":
            need = ["move", "attack"]
            if (params.blocks ?? 0) > 0 { need.insert("defend") }
            if params.finishSpecial == true { need.insert("special"); specialOK = true }
        case "reach-the-flag":
            need = ["move"] // D-10 B: no special on reach-the-flag in the slice
            if !(params.encounters ?? []).isEmpty { need.insert("attack") }
        case "dialogue": // no pads at all (schema 1.4)
            return buttons.isEmpty ? [] : [.init(rule: "R13", message: "dialogue beats have no buttons")]
        default: return [.init(rule: "R13", message: "unknown beat type \(type)")]
        }
        var out: [Finding] = []
        let missing = need.subtracting(buttons)
        if !missing.isEmpty { out.append(.init(rule: "R13", message: "\(type) needs \(missing.sorted())")) }
        if buttons.contains("special") && !specialOK { out.append(.init(rule: "R13", message: "special on \(type)")) }
        if let enc = params.encounters {
            let ats = enc.map(\.atScreen)
            let len = params.lengthScreens ?? 0
            if zip(ats, ats.dropFirst()).contains(where: { $0 >= $1 }) || ats.contains(where: { $0 <= 0 || $0 >= len }) {
                out.append(.init(rule: "R13b", message: "encounters must be strictly ascending inside (0, length_screens)"))
            }
        }
        return out
    }

    /// R8d (error): a fit field has a known size class and font_px ≥ that class's minimum (Language GDD Rule 6).
    public static func minSize(field: String, sizeClass: String?, fontPx: Double, minPx: [String: Double]) -> [Finding] {
        guard let c = sizeClass else { return [.init(rule: "R8d", message: "\(field) has no size class")] }
        guard let m = minPx[c] else { return [.init(rule: "R8d", message: "\(field) has unknown size class \(c)")] }
        return fontPx < m ? [.init(rule: "R8d", message: "\(field) font_px \(fontPx) < \(c) minimum \(m)")] : []
    }

    /// R14b (error, Combat Rule 15b): the last dummy is inside the capped training zone,
    /// dummies × dummy_spacing ≤ W − enemy_reach − 2 × hero_edge_margin (computed, never stored).
    public static func trainingZone(beat: String, dummies: Int, spacing: Double, enemyReach: Double, edge: Double, worldWidth: Double) -> [Finding] {
        let limit = worldWidth - enemyReach - 2 * edge, need = Double(dummies) * spacing
        return need > limit ? [.init(rule: "R14b", message: "\(beat): \(dummies) dummies × \(spacing) = \(need) > \(limit)")] : []
    }

    /// R21 (warning): `cheer: false` on a fight beat is ignored (fight beats always cheer).
    public static func cheerOnFight(beat: String, type: String, cheer: Bool?) -> [Finding] {
        type == "fight" && cheer == false ? [.init(rule: "R21", message: "\(beat): cheer false is ignored on a fight beat", isWarning: true)] : []
    }

    /// R14 (error): the hero reaches the front enemy; R15 (warning): telegraph ≥ 0.8 s.
    public static func tuningRules(_ v: [String: Double]) -> [Finding] {
        var out: [Finding] = []
        if let a = v["attack_range"], let r = v["enemy_reach"], let g = v["stand_gap"], a < r - g {
            out.append(.init(rule: "R14", message: "attack_range \(a) < enemy_reach − stand_gap \(r - g)"))
        }
        if let t = v["telegraph"], t < 0.8 { out.append(.init(rule: "R15", message: "telegraph \(t) s < 0.8 s", isWarning: true)) }
        return out
    }

    /// R17: timeline_order is unique across indexed heroes; R18: next_hero is the next indexed hero
    /// by timeline_order, or null for the last (claim status ignored; samples are not indexed).
    public static func timeline(_ heroes: [(id: String, order: Int, next: String?)]) -> [Finding] {
        var out: [Finding] = []
        let orders = heroes.map(\.order)
        if Set(orders).count != orders.count { out.append(.init(rule: "R17", message: "timeline_order not unique")) }
        let sorted = heroes.sorted { $0.order < $1.order }
        for (i, h) in sorted.enumerated() {
            let want = i + 1 < sorted.count ? sorted[i + 1].id : nil
            if h.next != want { out.append(.init(rule: "R18", message: "\(h.id) next_hero \(h.next ?? "null") should be \(want ?? "null")")) }
        }
        return out
    }

    /// R8c wrap fit (Language & text GDD F1): greedy wrap at spaces into box / (1 + allowance), using
    /// per-code-point advances (per 1000 em) at the field's weight. Returns the line count, or nil when
    /// a single word is wider than the box.
    public static func wrapLines(_ text: String, advances: [String: Double], fontPx: Double, box: Double, allowance: Double) -> Int? {
        let limit = box / (1 + allowance)
        func width(_ w: Substring) -> Double {
            w.unicodeScalars.reduce(0) { $0 + (advances[String(format: "%04X", $1.value)] ?? 0) } * fontPx / 1000
        }
        let space = (advances["0020"] ?? 0) * fontPx / 1000
        var lines = 1, cur = 0.0
        for word in text.precomposedStringWithCanonicalMapping.split(separator: " ", omittingEmptySubsequences: true) {
            let w = width(word)
            if w > limit { return nil }
            if cur == 0 { cur = w } else if cur + space + w <= limit { cur += space + w } else { lines += 1; cur = w }
        }
        return lines
    }

    /// R10 portrait id: pic.portrait_<hero_id>_<speaker>[_<mood>] (a missing mood variant fails, on data/ only).
    public static func portraitId(hero: String, _ l: BeatParams.DialogueLine) -> String {
        "pic.portrait_\(hero)_\(l.speaker)" + (l.mood.map { "_\($0)" } ?? "")
    }

    /// R13d: the ask button ends on or before the last line.
    public static func askFits(lines: Int, taps: Int, atLine: Int) -> [Finding] {
        atLine + taps <= lines ? [] : [.init(rule: "R13d", message: "ask \(atLine)+\(taps) runs past \(lines) lines")]
    }

    /// The button under each 1-based line L: "ask" when at_line ≤ L < at_line + taps, else "tiep".
    public static func askButtons(lines: Int, taps: Int, atLine: Int) -> [String] {
        (1...max(1, lines)).map { $0 >= atLine && $0 < atLine + taps ? "ask" : "tiep" }
    }

    /// R4c: in a dialogue beat, lines citing a legend claim pass R4 when the first line is a narrator
    /// line, marked in VI and EN, citing that claim; otherwise each such line needs its own marker.
    public static func dialogueLegend(_ lines: [BeatParams.DialogueLine], labels: [String: Claim.Label], markers: MarkersFile) -> [Finding] {
        guard let first = lines.first else { return [] }
        let firstMarked = first.speaker == "narrator" && legendMarker(first.text, labels: labels, markers: markers).isEmpty
            && first.text.claims.contains { labels[$0] == .legend }
        var out: [Finding] = []
        for l in lines {
            let legend = l.text.claims.filter { labels[$0] == .legend }
            guard !legend.isEmpty else { continue }
            if firstMarked && legend.allSatisfy({ first.text.claims.contains($0) }) { continue }
            out += legendMarker(l.text, labels: labels, markers: markers).map { .init(rule: "R4c", message: $0.message) }
        }
        return out
    }

    /// R19a (error): the declared size matches the file header.
    public static func declaredSize(id: String, declared: (Int, Int), actual: (Int, Int)) -> [Finding] {
        declared == actual ? [] : [.init(rule: "R19a", message: "\(id) declares \(declared.0)×\(declared.1), file is \(actual.0)×\(actual.1)")]
    }

    /// R19b (warning, ADR-0002): ≤ 2048 per side; quiz pictures ≤ 512²; scene tiles ≤ 1440×1320.
    public static func pictureLimits(id: String, width w: Int, height h: Int) -> [Finding] {
        var limit = (2048, 2048)
        if id.hasPrefix("pic.quiz_") { limit = (512, 512) } else if id.hasPrefix("pic.scene_") { limit = (1440, 1320) }
        return w > limit.0 || h > limit.1 ? [.init(rule: "R19b", message: "\(id) is \(w)×\(h), limit \(limit.0)×\(limit.1)", isWarning: true)] : []
    }

    /// R20: every theme a beat uses has a sky band; themes outside the mission enum are invalid.
    public static func themesCovered(themes: [String], beatThemes: [String]) -> [Finding] {
        let known: Set = ["village", "bamboo", "river", "camp"]
        return Set(beatThemes).sorted().compactMap { t in
            !known.contains(t) ? .init(rule: "R20", message: "unknown theme \(t)")
                : !themes.contains(t) ? .init(rule: "R20", message: "theme \(t) has no sky_band") : nil
        }
    }

    /// The pixel size from a PNG or WebP header (VP8, VP8L, VP8X), or nil.
    public static func imageSize(_ d: Data) -> (Int, Int)? {
        let b = [UInt8](d.prefix(32))
        func u32be(_ i: Int) -> Int { Int(b[i]) << 24 | Int(b[i + 1]) << 16 | Int(b[i + 2]) << 8 | Int(b[i + 3]) }
        if b.count >= 24, b[0..<8].elementsEqual([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) { return (u32be(16), u32be(20)) }
        guard b.count >= 30, String(bytes: b[0..<4], encoding: .ascii) == "RIFF", String(bytes: b[8..<12], encoding: .ascii) == "WEBP" else { return nil }
        switch String(bytes: b[12..<16], encoding: .ascii) {
        case "VP8 ": return (Int(b[26]) | Int(b[27] & 0x3F) << 8, Int(b[28]) | Int(b[29] & 0x3F) << 8)
        case "VP8L": let v = Int(b[21]) | Int(b[22]) << 8 | Int(b[23]) << 16 | Int(b[24]) << 24; return ((v & 0x3FFF) + 1, ((v >> 14) & 0x3FFF) + 1)
        case "VP8X": return ((Int(b[24]) | Int(b[25]) << 8 | Int(b[26]) << 16) + 1, (Int(b[27]) | Int(b[28]) << 8 | Int(b[29]) << 16) + 1)
        default: return nil
        }
    }

    /// R16: a lower star's max_retries is ≥ the higher star's; nil means no limit.
    public static func starOrder(_ th: [RulesFile.StarThreshold]) -> [Finding] {
        let sorted = th.sorted { $0.stars > $1.stars }
        for (hi, lo) in zip(sorted, sorted.dropFirst()) {
            if let h = hi.maxRetries, let l = lo.maxRetries, l < h { return [.init(rule: "R16", message: "\(lo.stars)★ stricter than \(hi.stars)★")] }
            if hi.maxRetries == nil && lo.maxRetries != nil { return [.init(rule: "R16", message: "\(lo.stars)★ stricter than \(hi.stars)★")] }
        }
        return []
    }

    private func budget(_ hero: HeroContent) -> [Finding] {
        let b = content.rules.textLimits.enBudget
        let m = hero.mission
        var pairs: [(String, String)] = [(m.hero.name.en, "hero_name"), (m.hero.place.en, "place")]
        pairs += m.intro.map { ($0.en, "intro") } + m.ending.lines.map { ($0.en, "ending") }
        if let banner = m.banner { pairs.append((banner.en, "banner")) }
        for beat in m.beats {
            pairs += [(beat.title.en, "beat_title")] + (beat.goal.map { [($0.en, "goal")] } ?? []) + beat.scene.map { ($0.en, "scene") }
            pairs += (beat.params.lines ?? []).map { ($0.text.en, $0.speaker == "narrator" ? "dialogue_narrator" : "dialogue_line") }
            if let a = beat.params.ask { pairs.append((a.button.en, "button")) }
        }
        for q in hero.quiz.questions { pairs += [(q.prompt.en, "quiz_prompt"), (q.why.en, "quiz_why")] + q.choices.map { ($0.text.en, "quiz_choice") } }
        return pairs.flatMap { Self.enBudget($0.0, fieldType: $0.1, budgets: b) }
    }
}
