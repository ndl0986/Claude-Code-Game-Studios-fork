import Foundation

/// The device's key-value store (UserDefaults in the app, a dictionary in tests).
public protocol KeyValueStore: AnyObject {
    func object(forKey: String) -> Any?
    func set(_ value: Any?, forKey: String)
}

/// Saved data, the same keys and meaning on both apps (D-16, Hero progression GDD rule 11):
/// `lang`, `completed.<id>`, `seen_open.<id>`, `stars.<id>` (best, never lowered),
/// `medal.<id>` (never cleared). Nothing else is saved.
public struct Progress: Equatable, Sendable {
    public var lang: Language = .vi
    public var stars: [String: Int] = [:]
    public var completed: Set<String> = []
    public var seenOpen: Set<String> = []
    public var medal: Set<String> = []

    public static func load(_ store: KeyValueStore, heroIds: [String]) -> Progress {
        var p = Progress()
        if let l = store.object(forKey: "lang") as? String, let lang = Language(rawValue: l) { p.lang = lang }
        for id in heroIds {
            if let s = store.object(forKey: "stars.\(id)") as? Int { p.stars[id] = s }
            if store.object(forKey: "completed.\(id)") as? Bool == true { p.completed.insert(id) }
            if store.object(forKey: "seen_open.\(id)") as? Bool == true { p.seenOpen.insert(id) }
            if store.object(forKey: "medal.\(id)") as? Bool == true { p.medal.insert(id) }
        }
        return p
    }

    public func saveLang(_ store: KeyValueStore) { store.set(lang.rawValue, forKey: "lang") }

    /// Quiz finish (written before results): completed, best stars, and the medal if no story was skipped.
    public mutating func recordQuiz(hero: String, stars s: Int, medalEarned: Bool, store: KeyValueStore) {
        completed.insert(hero); store.set(true, forKey: "completed.\(hero)")
        stars[hero] = max(stars[hero] ?? 0, s); store.set(stars[hero], forKey: "stars.\(hero)")
        if medalEarned { medal.insert(hero); store.set(true, forKey: "medal.\(hero)") }
    }

    public mutating func markSeenOpen(_ ids: [String], store: KeyValueStore) {
        for id in ids where !seenOpen.contains(id) { seenOpen.insert(id); store.set(true, forKey: "seen_open.\(id)") }
    }
}

/// Hero progression (GDD rules 1–7): playable heroes ordered by timeline_order; a hero is open if
/// it is the first, or the previous playable hero is completed, or it was seen open before.
public struct Progression: Sendable {
    public let order: [String]

    public init(heroes: [HeroContent], playable: (HeroContent) -> Bool) {
        order = heroes.filter(playable).sorted { $0.mission.hero.timelineOrder < $1.mission.hero.timelineOrder }.map(\.mission.hero.id)
    }

    public func isOpen(_ id: String, _ p: Progress) -> Bool {
        guard let i = order.firstIndex(of: id) else { return false }
        return i == 0 || p.completed.contains(order[i - 1]) || p.seenOpen.contains(id)
    }
    public func openHeroes(_ p: Progress) -> [String] { order.filter { isOpen($0, p) } }
    public func next(after id: String) -> String? {
        guard let i = order.firstIndex(of: id), i + 1 < order.count else { return nil }
        return order[i + 1]
    }
}

/// The screens of the slice: title, intro, play (walk_to / beat_card / beat_play / beat_end /
/// caption), ending, quiz, results, unlock, plus pause.
public enum Screen: String, Sendable, CaseIterable { case title, intro, play, pause, ending, quiz, results, unlock }

/// The whole game: screen flow, play, quiz, skip and medal, saving. The app draws it and feeds it input.
public final class Game {
    public let content: ContentSet
    public let hero: HeroContent
    public let gate: ClaimGate.Result
    public let isDebug: Bool
    public let progression: Progression
    let store: KeyValueStore

    public private(set) var screen: Screen = .title
    public private(set) var progress: Progress
    public var lang: Language { progress.lang }
    public private(set) var muted = false
    public private(set) var t = 0.0
    /// The intro / ending box showing (one sentence per box).
    public private(set) var storyLine = 0
    public private(set) var play: PlayState
    public private(set) var quiz: QuizSession?
    public private(set) var stars = 0
    /// D-07: a story section was skipped this run (no medal), the warning is up, the child chose "Skip anyway".
    public private(set) var skipped = false
    public private(set) var skipWarning = false
    var warningAccepted = false
    /// Results: the medal is earned (this or any run), and the hero this finish opened (unlock screen).
    public private(set) var medalEarned = false
    /// The medal was earned for the first time in this run (`ui.medal.earned` shows only then).
    public private(set) var medalNew = false
    public private(set) var unlockedHero: HeroContent?
    public private(set) var uiSounds: [UiSound] = []
    public enum UiSound: Sendable { case tap, chime, soft }
    var lastTap = -1.0
    var clock = 0.0
    var lastAdvance: Double?
    public private(set) var pausedFrom: Screen = .play

    /// `hero` is the mission to play. In a release build a hero whose claims aren't all approved
    /// never starts (the runtime guard of R12); `isPlayable` is false and the title shows no Start.
    public init(content: ContentSet, hero: HeroContent, store: KeyValueStore, isDebug: Bool) {
        self.content = content; self.hero = hero; self.store = store; self.isDebug = isDebug
        gate = ClaimGate.evaluate(hero)
        progress = Progress.load(store, heroIds: content.heroes.map(\.mission.hero.id))
        progression = Progression(heroes: content.heroes) { isDebug || ClaimGate.evaluate($0).runtimeRelease == .show }
        play = PlayState(tuning: content.tuning, beats: hero.mission.beats, seed: content.tuning.seed)
        if !isDebug && gate.runtimeRelease == .hideAndLog {
            NSLog("[claims] hero \(hero.mission.hero.id) hidden: unsigned \(gate.debugBadges.joined(separator: ", "))")
        }
        titleLoaded()
    }

    public var isPlayable: Bool { isDebug || gate.runtimeRelease == .show }
    public var tuning: Tuning { content.tuning }
    public var heroId: String { hero.mission.hero.id }
    public func ui(_ id: String) -> String { content.ui(id, lang) }

    /// The one tap tone of a menu press, at most once per 80 ms (P-04 item 4).
    func tap() { if lastTap < 0 || clock - lastTap >= 0.08 { uiSounds.append(.tap); lastTap = clock } }
    public func takeUiSounds() -> [UiSound] { defer { uiSounds = [] }; return uiSounds }
    public func takePlayEvents() -> [PlayEvent] { play.takeEvents() }

    func go(_ s: Screen) { screen = s; t = 0; skipWarning = false; if s == .title { titleLoaded() } }
    /// Title (the map in the slice) loads: every open hero is saved as seen open (never re-locks).
    func titleLoaded() { progress.markSeenOpen(progression.openHeroes(progress), store: store) }
    func reset() {
        play = PlayState(tuning: tuning, beats: hero.mission.beats, seed: tuning.seed)
        quiz = nil; stars = 0; skipped = false; warningAccepted = false; skipWarning = false; unlockedHero = nil
    }

    /// Input GDD Rule 12 / F3: an advance button ignores a press within `advance_debounce` of the last
    /// press that advanced. `press` is the press's own time (`UITouch.timestamp` in the app), never the
    /// sim clock: loading the next box stalls a frame and the clock jumps, which let a second tap through
    /// (Android B1). Without a press time (tests, debug) the sim clock stands in.
    func debounced(_ press: Double?) -> Bool {
        let t = press ?? clock
        if let last = lastAdvance, t - last < tuning["advance_debounce"] { return true }
        lastAdvance = t; return false
    }

    // MARK: actions (menus and cards fire on touch-up inside)

    public func start() { guard isPlayable, screen == .title else { return }; tap(); reset(); storyLine = 0; go(.intro) }
    /// VI|EN: title and pause only (leader's call for the slice).
    public func toggleLang() {
        guard screen == .title || screen == .pause else { return }
        tap(); progress.lang = lang == .vi ? .en : .vi; progress.saveLang(store)
    }
    /// Debug screenshots: set the language anywhere.
    public func forceLang(_ l: Language) { progress.lang = l; progress.saveLang(store) }
    public func toggleMute() { muted.toggle(); tap() }
    /// Input Rule 3 / W7: every screen but the title (sound only) and pause itself can pause.
    public func pause() { guard screen != .title && screen != .pause else { return }; tap(); pausedFrom = screen; screen = .pause; skipWarning = false }
    /// Resume: play's hint timers and windups restart (Hints GDD rule 5, AC19).
    public func resume() { guard screen == .pause else { return }; tap(); screen = pausedFrom; if pausedFrom == .play { play.resetHintTimers() } }
    public func home() { tap(); reset(); go(.title) }
    public func replay() { tap(); reset(); storyLine = 0; go(.intro) }

    /// "Tiếp / Next" on any story box, card, caption, quiz why, results or unlock; `press` is the
    /// press time (`UITouch.timestamp`), for the debounce.
    public func next(at press: Double? = nil) {
        guard !skipWarning else { return }
        switch screen {
        case .intro, .ending:
            guard !debounced(press) else { return }
            tap()
            let lines = screen == .intro ? hero.mission.intro : hero.mission.ending.lines
            if storyLine + 1 < lines.count { storyLine += 1; return }
            if screen == .intro { go(.play) } else { startQuiz() }
        case .play where play.phase == .caption || play.phase == .beatCard || play.phase == .dialogueLine:
            // while the ask button shows, "Tiếp" isn't on screen: ignore it without using up the debounce
            guard !(play.phase == .dialogueLine && play.askShowing), !debounced(press) else { return }
            tap()
            switch play.phase { case .caption: play.captionNext(); case .beatCard: play.cardNext(); default: play.dialogueNext() }
            if play.finished { storyLine = 0; go(.ending) }
        case .quiz:
            guard quizCanAdvance, !debounced(press) else { return }
            tap()
            if quiz!.advance() { finishQuiz() }
        case .results:
            guard !debounced(press) else { return }
            tap()
            if unlockedHero != nil { go(.unlock); uiSounds.append(.chime) } else { reset(); go(.title) }
        case .unlock: guard !debounced(press) else { return }; home()
        default: break
        }
    }

    /// The ask button in a dialogue beat (fires on touch-up inside, debounced like Next).
    public func ask(at press: Double? = nil) {
        guard screen == .play, play.askShowing, !skipWarning, !debounced(press) else { return }
        tap(); play.dialogueAsk()
    }

    // MARK: D-07 skip, warning and medal

    /// Skip is offered on story screens: intro, beat card, caption, ending (not the quiz why).
    public var canSkip: Bool {
        switch screen {
        case .intro, .ending: return true
        case .play: return play.phase == .beatCard || play.phase == .caption || play.phase == .dialogueLine
        default: return false
        }
    }
    var medalAlready: Bool { progress.medal.contains(heroId) }

    /// "Bỏ qua / Skip": shows the kind warning, unless the child already chose "Skip anyway"
    /// this run or the medal is already earned; "Keep reading" closes it and it comes back next time.
    public func skip() {
        guard canSkip, !skipWarning else { return }
        tap()
        if warningAccepted || medalAlready { skipSection() } else { skipWarning = true }
    }
    public func skipAnyway() { guard skipWarning else { return }; tap(); skipWarning = false; warningAccepted = true; skipSection() }
    public func keepReading() { guard skipWarning else { return }; tap(); skipWarning = false }

    /// Ends only the current section.
    func skipSection() {
        skipped = true
        switch screen {
        case .intro: go(.play)
        case .ending: startQuiz()
        case .play:
            play.skipSection()
            if play.finished { storyLine = 0; go(.ending) }
        default: break
        }
    }

    // MARK: quiz

    public func startQuiz() {
        quiz = QuizSession(quiz: hero.quiz, count: Int(tuning["quiz_count"]), seed: tuning.seed)
        go(.quiz)
    }

    /// The quiz "Tiếp" shows and works only once the right card's feedback_time has passed (QS AC5, iOS-R2-04).
    public var quizCanAdvance: Bool { guard let q = quiz, q.okIndex != nil else { return false }; return q.okTime >= tuning["feedback_time"] }

    /// A quiz card tapped (fires on touch-up inside), by display slot.
    public func answer(_ slot: Int) {
        guard screen == .quiz, quiz != nil else { return }
        switch quiz!.pick(slot: slot) {
        case .right: uiSounds.append(.chime)
        case .wrong: uiSounds.append(.soft)
        case .ignored: break
        }
    }

    /// Quiz finish: everything is saved before results (D-16), then results and maybe unlock.
    func finishQuiz() {
        guard let q = quiz else { return }
        stars = StarRule(content.rules.quizStars).stars(totalRetries: q.retries)
        let next = progression.next(after: heroId)
        let wasOpen = next.map { progression.isOpen($0, progress) } ?? true
        let hadMedal = medalAlready
        progress.recordQuiz(hero: heroId, stars: stars, medalEarned: !skipped, store: store)
        progress.markSeenOpen(progression.openHeroes(progress), store: store)
        medalEarned = progress.medal.contains(heroId)
        medalNew = medalEarned && !hadMedal
        unlockedHero = (!wasOpen ? next : nil).flatMap { id in content.heroes.first { $0.mission.hero.id == id } }
        go(.results); uiSounds.append(.chime)
    }

    // MARK: the fixed step

    public func step(_ dt: Double, _ input: StepInput) {
        clock += dt
        switch screen {
        case .play:
            t += dt
            if !skipWarning { play.update(dt, input) }
            if play.finished { storyLine = 0; go(.ending) }
        case .quiz:
            t += dt
            quiz!.update(dt)
        case .pause: break
        default: t += dt
        }
    }

    /// The app went to the background: play and quiz pause (mission-flow edge case, AC10).
    public func backgrounded() { if screen == .play || screen == .quiz { pausedFrom = screen; screen = .pause; skipWarning = false } }

    // MARK: debug screen jumps (same names as Android: -startScreen quiz -q 2 -stage wrong|right)

    public func debugStart(screen name: String, q: Int?, beat: Int?, stage: String?, stars s: Int?) {
        if name == "skipwarn" { debugStart(screen: "intro", q: q, beat: beat, stage: "skipwarning", stars: s); return } // Android's name
        guard isDebug, let target = Screen(rawValue: name) ?? (name == "caption" ? .play : nil) else { return }
        reset()
        switch target {
        case .quiz:
            startQuiz(); quiz!.jump(to: (q ?? 1) - 1)
            if stage == "wrong", let w = (0..<3).first(where: { quiz!.order[$0] != quiz!.current.correctIndex }) { _ = quiz!.pick(slot: w) }
            if stage == "right", let r = quiz!.order.firstIndex(of: quiz!.current.correctIndex) { _ = quiz!.pick(slot: r); quiz!.update(tuning["feedback_time"]) }
        case .results:
            startQuiz(); stars = s ?? 2; medalEarned = stage != "nomedal"; medalNew = stage == "newmedal"
            go(.results)
        case .unlock: stars = s ?? 2; unlockedHero = hero; go(.unlock)
        case .play:
            go(.play)
            if let b = beat { play.debugJump(beat: b - 1, stage: name == "caption" ? "caption" : stage) }
        case .pause: go(.play); if let b = beat { play.debugJump(beat: b - 1, stage: stage) }; pausedFrom = .play; screen = .pause
        default: go(target)
        }
        if stage == "skipwarning" && canSkip { skipWarning = true }
    }
}
