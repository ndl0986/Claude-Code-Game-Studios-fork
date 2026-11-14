import Foundation

/// The two languages the game ships in, Vietnamese first.
public enum Language: String, Codable, Sendable, CaseIterable { case vi, en }

/// A story, scene, intro, ending, banner or quiz line (ADR-0001): VI + EN and at least one claim.
public struct Text: Codable, Equatable, Sendable {
    public let id: String
    public let vi: String
    public let en: String
    public let claims: [String]

    public init(id: String, vi: String, en: String, claims: [String]) {
        self.id = id; self.vi = vi; self.en = en; self.claims = claims
    }

    /// The line in the given language.
    public func text(_ language: Language) -> String { language == .vi ? vi : en }
}

/// A UI string from `strings.json`: VI + EN, no claims.
public struct UiText: Codable, Equatable, Sendable {
    public let id: String
    public let vi: String
    public let en: String

    /// The string in the given language.
    public func text(_ language: Language) -> String { language == .vi ? vi : en }
}

/// `strings.json`.
public struct StringsFile: Codable, Sendable {
    public let schemaVersion: String
    public let strings: [UiText]

    /// The string with this id, or nil.
    public func string(_ id: String) -> UiText? { strings.first { $0.id == id } }
}

/// `index.json`: the content version and the heroes bundled.
public struct IndexFile: Codable, Sendable {
    public let schemaVersion: String
    public let contentVersion: Int
    public let heroes: [String]
}

/// One claim in a hero's `claims.json`.
public struct Claim: Codable, Equatable, Sendable {
    public enum Label: String, Codable, Sendable { case fact, factAsRecorded = "fact_as_recorded", interpretation, legend, invented }
    public struct Signoff: Codable, Equatable, Sendable {
        public enum Status: String, Codable, Sendable { case pending, approved }
        public let status: Status
        public let by: String?
        public let date: String?
    }
    public let id: String
    public let vi: String
    public let en: String
    public let label: Label
    public let sources: [String]
    public let signoff: Signoff
}

/// A hero's `claims.json`.
public struct ClaimsFile: Codable, Sendable {
    public let schemaVersion: String
    public let heroId: String
    public let claims: [Claim]
}

/// One source in `sources.json`.
public struct Source: Codable, Equatable, Sendable {
    public enum Status: String, Codable, Sendable { case toConfirm = "to_confirm", confirmed }
    public let id: String
    public let citation: String
    public let kind: String
    public let location: String
    public let status: Status
}

/// `sources.json`.
public struct SourcesFile: Codable, Sendable {
    public let schemaVersion: String
    public let sources: [Source]
}

/// `markers.json`: authored legend / chronicle markers (rule R4).
public struct MarkersFile: Codable, Sendable {
    public struct MarkerSet: Codable, Sendable { public let vi: [String]; public let en: [String] }
    public let schemaVersion: String
    public let legend: MarkerSet
    public let factAsRecorded: MarkerSet
}

/// `rules.json`: quiz stars and text limits.
public struct RulesFile: Codable, Sendable {
    public struct StarThreshold: Codable, Sendable { public let stars: Int; public let maxRetries: Int? }
    public struct QuizStars: Codable, Sendable {
        public let retriesCounted: String
        public let thresholds: [StarThreshold]
        public let finishingUnlocksNextHero: Bool
    }
    public struct TextLimits: Codable, Sendable {
        /// One wrap-fit field (R8c); `sizeClass` is rules 1.2's `class` (R8d).
        public struct FitField: Codable, Sendable {
            public let boxWidth: Double
            public let fontPx: Double
            public let maxLines: Int
            public let weight: Int
            public let sizeClass: String?
            enum CodingKeys: String, CodingKey { case boxWidth, fontPx, maxLines, weight, sizeClass = "class" }
        }
        public struct Fit: Codable, Sendable { public let allowance: Double; public let fields: [String: FitField] }
        public let maxChars: Int
        public let enBudget: [String: Int]
        /// Rules 1.2 (TASK-005l, R8d): the smallest font_px per size class. Absent before 1.2.
        public let minPx: [String: Double]?
        public let fit: Fit?
    }
    public let schemaVersion: String
    public let quizStars: QuizStars
    public let textLimits: TextLimits
}

/// `assets.json`.
public struct AssetsFile: Codable, Sendable {
    public struct Asset: Codable, Sendable {
        public let id: String
        public let kind: String
        public let file: String
        public let bytes: Int
        /// Pictures only (schema 1.2): the file's pixel size (R19a/R19b).
        public let width: Int?
        public let height: Int?
    }
    public let schemaVersion: String
    public let assets: [Asset]
}

/// `themes.json` (ADR-0002): the sky band above the background tiles, a gradient per theme.
public struct ThemesFile: Codable, Sendable {
    public struct Theme: Codable, Sendable { public struct Band: Codable, Sendable { public let top: String; public let bottom: String }; public let skyBand: Band }
    public let schemaVersion: String
    public let themes: [String: Theme]
}

/// A fight beat's walk-in list and limits (the prototype's MISSION.beats).
public struct FightParams: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable { case spear, shield, leader }
    public let enemies: [Kind]
    public let maxActive: Int
    public let fromLeft: [Int]
}

/// Every beat type's params, all optional (schema 1.1): the beat's `type` says which apply.
public struct BeatParams: Codable, Equatable, Sendable {
    public struct Encounter: Codable, Equatable, Sendable {
        public let atScreen: Double
        public let enemies: [FightParams.Kind]
        public let maxActive: Int
        public let fromLeft: [Int]
    }
    public var enemies: [FightParams.Kind]?
    public var maxActive: Int?
    public var fromLeft: [Int]?
    public var lengthScreens: Double?
    public var holdSeconds: Double?
    public var dummies: Int?
    public var blocks: Int?
    public var finishSpecial: Bool?
    public var encounters: [Encounter]?
    /// dialogue (schema 1.4): 2–12 lines, and an optional ask button.
    public struct DialogueLine: Codable, Equatable, Sendable { public let speaker: String; public let mood: String?; public let text: Text }
    public struct Ask: Codable, Equatable, Sendable { public let button: Text; public let taps: Int; public let atLine: Int }
    public var lines: [DialogueLine]?
    public var ask: Ask?
}

/// One beat of a mission.
public struct Beat: Codable, Sendable {
    public let id: String
    public let type: String
    public let theme: String
    public let buttons: [String]
    public let title: Text
    public let scene: [Text]
    /// Optional only for dialogue beats (schema 1.4).
    public let goal: Text?
    public let usesBanner: Bool?
    /// Schema 1.5 (TASK-005l): `false` ends a non-fight beat quietly (no cheer pose or sting, the page-turn
    /// sound once; the dots still fill). Absent means true; ignored on fight beats (R21 warns).
    public let cheer: Bool?

    /// Whether this beat ends with the cheer: fight beats always do.
    public var cheers: Bool { type == "fight" || cheer != false }
    public let params: BeatParams

    /// Fight params when the beat is a fight; nil for other types (the slice plays them as a fight stand-in).
    public var fight: FightParams? {
        guard type == "fight", let e = params.enemies, let m = params.maxActive else { return nil }
        return FightParams(enemies: e, maxActive: m, fromLeft: params.fromLeft ?? [])
    }
}

/// A hero's `mission.json`.
public struct Mission: Codable, Sendable {
    public struct Hero: Codable, Sendable {
        public let id: String
        public let name: Text
        public let timelineOrder: Int
        public let place: Text
    }
    public struct Ending: Codable, Sendable {
        public let lines: [Text]
        public let pictureId: String
    }
    public let schemaVersion: String
    public let hero: Hero
    public let nextHero: String?
    public let intro: [Text]
    public let banner: Text?
    public let beats: [Beat]
    public let ending: Ending

    /// Every Text in the mission, in reading order.
    public var allTexts: [Text] {
        var out = [hero.name, hero.place] + intro
        if let banner { out.append(banner) }
        for b in beats {
            out += [b.title] + b.scene + (b.goal.map { [$0] } ?? [])
            out += (b.params.lines ?? []).map(\.text) + (b.params.ask.map { [$0.button] } ?? [])
        }
        return out + ending.lines
    }
}

/// A hero's `quiz.json`.
public struct QuizFile: Codable, Sendable {
    public struct Choice: Codable, Sendable { public let text: Text; public let pictureId: String }
    public struct Question: Codable, Sendable {
        public let id: String
        public let prompt: Text
        public let pictureId: String?
        public let choices: [Choice]
        public let correctIndex: Int
        public let why: Text
    }
    public let schemaVersion: String
    public let heroId: String
    public let questions: [Question]

    /// Every Text in the quiz.
    public var allTexts: [Text] { questions.flatMap { [$0.prompt] + $0.choices.map(\.text) + [$0.why] } }
}

/// The decoder every content file uses: snake_case keys in JSON, camelCase in Swift.
public enum ContentJSON {
    public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return try d.decode(type, from: data)
    }
}

/// One hero's three files.
public struct HeroContent: Sendable {
    public let mission: Mission
    public let quiz: QuizFile
    public let claims: ClaimsFile
}

/// Everything the game reads from `content/data/` (plus, in debug builds, a sample hero).
public struct ContentSet: Sendable {
    public let index: IndexFile
    public let strings: StringsFile
    public let sources: SourcesFile
    public let markers: MarkersFile
    public let rules: RulesFile
    public let tuning: Tuning
    public let assets: AssetsFile
    /// Optional until data/TASK-005g merges into every base (parity with Android).
    public let themes: ThemesFile?
    public let heroes: [HeroContent]

    /// The schema MAJOR this app reads (rule R11).
    public static let supportedSchema = "1.0"

    /// Loads `data/` from `dataRoot`, and the heroes listed in `index.json` from `dataRoot/heroes/`.
    /// `extraHeroDirs` adds hero folders from elsewhere (the debug sample).
    public static func load(dataRoot: URL, extraHeroDirs: [URL] = []) throws -> ContentSet {
        func file<T: Decodable>(_ name: String, _ t: T.Type) throws -> T {
            try ContentJSON.decode(t, from: Data(contentsOf: dataRoot.appendingPathComponent(name)))
        }
        let index = try file("index.json", IndexFile.self)
        let dirs = index.heroes.map { dataRoot.appendingPathComponent("heroes/\($0)") } + extraHeroDirs
        let heroes = try dirs.map { dir in
            HeroContent(
                mission: try ContentJSON.decode(Mission.self, from: Data(contentsOf: dir.appendingPathComponent("mission.json"))),
                quiz: try ContentJSON.decode(QuizFile.self, from: Data(contentsOf: dir.appendingPathComponent("quiz.json"))),
                claims: try ContentJSON.decode(ClaimsFile.self, from: Data(contentsOf: dir.appendingPathComponent("claims.json"))))
        }
        return ContentSet(
            index: index,
            strings: try file("strings.json", StringsFile.self),
            sources: try file("sources.json", SourcesFile.self),
            markers: try file("markers.json", MarkersFile.self),
            rules: try file("rules.json", RulesFile.self),
            tuning: try Tuning(data: Data(contentsOf: dataRoot.appendingPathComponent("tuning.json"))),
            assets: try file("assets.json", AssetsFile.self),
            themes: FileManager.default.fileExists(atPath: dataRoot.appendingPathComponent("themes.json").path) ? try file("themes.json", ThemesFile.self) : nil,
            heroes: heroes)
    }

    /// A UI string in the given language. A missing id shows its key (debug aid; P-04 rule).
    public func ui(_ id: String, _ language: Language) -> String {
        strings.string(id)?.text(language) ?? id
    }
}
