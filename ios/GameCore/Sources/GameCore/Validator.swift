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

    public init(content: ContentSet, checkPictures: Bool) { self.content = content; self.checkPictures = checkPictures }

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
            out += Self.enBudget(s.en, fieldType: Self.uiBudgetType(s.id), budgets: content.rules.textLimits.enBudget)
        }
        out += Self.schemaMajor(file: content.index.schemaVersion, app: ContentSet.supportedSchema)
        out += Self.tuningRules(content.tuning.values.mapValues(\.value))
        out += Self.starOrder(content.rules.quizStars.thresholds)

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
            let missionSentences = m.intro + m.beats.flatMap(\.scene) + m.ending.lines
            for t in missionSentences { out += Self.legendMarker(t, labels: labels, markers: content.markers) }
            var missionLabels = [m.hero.name, m.hero.place] + m.beats.flatMap { [$0.title, $0.goal] }
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
                let pics = [hero.mission.ending.pictureId] + hero.quiz.questions.flatMap { q in (q.pictureId.map { [$0] } ?? []) + q.choices.map(\.pictureId) }
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

    /// R8 for strings.json: the budget type comes from the id (TASK-005e README).
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

    /// R14 (error): the hero reaches the front enemy; R15 (warning): telegraph ≥ 0.8 s.
    public static func tuningRules(_ v: [String: Double]) -> [Finding] {
        var out: [Finding] = []
        if let a = v["attack_range"], let r = v["enemy_reach"], let g = v["stand_gap"], a < r - g {
            out.append(.init(rule: "R14", message: "attack_range \(a) < enemy_reach − stand_gap \(r - g)"))
        }
        if let t = v["telegraph"], t < 0.8 { out.append(.init(rule: "R15", message: "telegraph \(t) s < 0.8 s", isWarning: true)) }
        return out
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
        for beat in m.beats { pairs += [(beat.title.en, "beat_title"), (beat.goal.en, "goal")] + beat.scene.map { ($0.en, "scene") } }
        for q in hero.quiz.questions { pairs += [(q.prompt.en, "quiz_prompt"), (q.why.en, "quiz_why")] + q.choices.map { ($0.text.en, "quiz_choice") } }
        return pairs.flatMap { Self.enBudget($0.0, fieldType: $0.1, budgets: b) }
    }
}
