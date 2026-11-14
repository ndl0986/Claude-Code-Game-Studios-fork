import Foundation

/// The device's key-value store (UserDefaults in the app, a dictionary in tests).
public protocol KeyValueStore: AnyObject {
    func object(forKey: String) -> Any?
    func set(_ value: Any?, forKey: String)
}

/// Saved data, the same keys and meaning on both apps (P-04 item 3). Nothing else is saved.
public struct Progress: Equatable, Sendable {
    public var lang: Language = .vi
    public var stars: [String: Int] = [:]
    public var unlocked: Set<String> = []

    public static func load(_ store: KeyValueStore, heroIds: [String]) -> Progress {
        var p = Progress()
        if let l = store.object(forKey: "lang") as? String, let lang = Language(rawValue: l) { p.lang = lang }
        for id in heroIds { if let s = store.object(forKey: "stars.\(id)") as? Int { p.stars[id] = s } }
        p.unlocked = Set(store.object(forKey: "unlocked") as? [String] ?? [])
        return p
    }

    public func saveLang(_ store: KeyValueStore) { store.set(lang.rawValue, forKey: "lang") }

    /// Written when the quiz finishes: best stars ever (never lowered) and the unlocked set.
    public mutating func recordQuiz(hero: String, stars s: Int, nextHero: String?, store: KeyValueStore) {
        stars[hero] = max(stars[hero] ?? 0, s)
        if let n = nextHero { unlocked.insert(n) }
        store.set(stars[hero], forKey: "stars.\(hero)")
        store.set(unlocked.sorted(), forKey: "unlocked")
    }
}

/// The screens of the slice: title, intro, play (walk / fight / caption), ending, quiz, results, unlock, plus pause.
public enum Screen: String, Sendable, CaseIterable { case title, intro, play, pause, ending, quiz, results, unlock }

/// The whole game: screen flow, play, quiz and saving. The app draws it and feeds it input.
public final class Game {
    public let content: ContentSet
    public let hero: HeroContent
    public let gate: ClaimGate.Result
    public let isDebug: Bool
    let store: KeyValueStore

    public private(set) var screen: Screen = .title
    public private(set) var progress: Progress
    public var lang: Language { progress.lang }
    public private(set) var muted = false
    /// Time on the current screen (animations).
    public private(set) var t = 0.0
    /// The intro / ending box showing (one sentence per box).
    public private(set) var storyLine = 0
    public private(set) var play: PlayState
    public private(set) var quiz: QuizSession?
    public private(set) var stars = 0
    /// Sounds the app plays this frame: UI taps and quiz chimes. Play events come from `play`.
    public private(set) var uiSounds: [UiSound] = []
    public enum UiSound: Sendable { case tap, chime, soft }
    var lastTap = -1.0
    var clock = 0.0
    var lastAdvance = -1.0

    /// `hero` is the mission to play. In a release build a hero whose claims aren't all approved
    /// never starts (the runtime guard of R12); `isPlayable` is false and the app shows the title only.
    public init(content: ContentSet, hero: HeroContent, store: KeyValueStore, isDebug: Bool) {
        self.content = content; self.hero = hero; self.store = store; self.isDebug = isDebug
        gate = ClaimGate.evaluate(hero)
        progress = Progress.load(store, heroIds: content.heroes.map(\.mission.hero.id))
        play = PlayState(tuning: content.tuning, beats: hero.mission.beats, seed: content.tuning.seed)
        if !isDebug && gate.runtimeRelease == .hideAndLog {
            NSLog("[claims] hero \(hero.mission.hero.id) hidden: unsigned \(gate.debugBadges.joined(separator: ", "))")
        }
    }

    public var isPlayable: Bool { isDebug || gate.runtimeRelease == .show }
    public var tuning: Tuning { content.tuning }
    public func ui(_ id: String) -> String { content.ui(id, lang) }

    /// The one tap tone of a menu press, at most once per 80 ms (P-04 item 4).
    func tap() { if lastTap < 0 || clock - lastTap >= 0.08 { uiSounds.append(.tap); lastTap = clock } }
    public func takeUiSounds() -> [UiSound] { defer { uiSounds = [] }; return uiSounds }

    func go(_ s: Screen) { screen = s; t = 0 }
    func reset() { play = PlayState(tuning: tuning, beats: hero.mission.beats, seed: tuning.seed); quiz = nil; stars = 0 }

    /// Story boxes ignore a second "Next" within `advance_debounce` of an advance (mission-flow AC9).
    func debounced() -> Bool {
        let d = tuning.values["advance_debounce"]?.value ?? 0.25
        if lastAdvance >= 0 && clock - lastAdvance < d { return true }
        lastAdvance = clock; return false
    }

    // MARK: actions (menus and cards fire on touch-up inside)

    public func start() { guard isPlayable else { return }; tap(); reset(); storyLine = 0; go(.intro) }
    public func toggleLang() { tap(); progress.lang = lang == .vi ? .en : .vi; progress.saveLang(store) }
    public func toggleMute() { muted.toggle(); tap() }
    /// The screen pause was opened from (play or quiz).
    public private(set) var pausedFrom: Screen = .play
    public func pause() { guard screen == .play || screen == .quiz else { return }; tap(); pausedFrom = screen; screen = .pause }
    /// Resume: play's hint timers restart from 0 (Hints GDD rule 5).
    public func resume() { guard screen == .pause else { return }; tap(); screen = pausedFrom; if pausedFrom == .play { play.resetHintTimers() } }
    public func home() { tap(); reset(); go(.title) }
    public func replay() { tap(); reset(); storyLine = 0; go(.intro) }

    /// "Tiếp / Next" on any story box, caption, results or unlock.
    public func next() {
        switch screen {
        case .intro, .ending:
            guard !debounced() else { return }
            tap()
            let lines = screen == .intro ? hero.mission.intro : hero.mission.ending.lines
            if storyLine + 1 < lines.count { storyLine += 1; return }
            if screen == .intro { go(.play) } else { startQuiz() }
        case .play where play.phase == .caption:
            guard !debounced() else { return }
            tap(); play.captionNext()
            if play.finished { storyLine = 0; go(.ending) }
        case .quiz:
            guard quiz?.okIndex != nil, !debounced() else { return }
            tap()
            if quiz!.advance() { finishQuiz() }
        case .results: tap(); if hero.mission.nextHero != nil { go(.unlock); uiSounds.append(.chime) } else { home() }
        case .unlock: home()
        default: break
        }
    }

    public func startQuiz() {
        quiz = QuizSession(quiz: hero.quiz, count: Int(tuning["quiz_count"]), seed: tuning.seed)
        go(.quiz)
    }

    /// A quiz card tapped (fires on touch-up inside).
    public func answer(_ j: Int) {
        guard screen == .quiz, quiz != nil else { return }
        switch quiz!.pick(slot: j) {
        case .right: uiSounds.append(.chime)
        case .wrong: uiSounds.append(.soft)
        case .ignored: break
        }
    }

    func finishQuiz() {
        guard let q = quiz else { return }
        stars = StarRule(content.rules.quizStars).stars(totalRetries: q.retries)
        progress.recordQuiz(hero: hero.mission.hero.id, stars: stars, nextHero: hero.mission.nextHero, store: store)
        go(.results); uiSounds.append(.chime)
    }

    // MARK: the fixed step

    public func step(_ dt: Double, _ input: StepInput) {
        clock += dt
        switch screen {
        case .play:
            t += dt
            play.update(dt, input)
            if play.finished { storyLine = 0; go(.ending) }
        case .quiz:
            t += dt
            quiz!.update(dt)
        case .pause: break
        default: t += dt
        }
    }

    /// The app went to the background: pause play, nothing advances (mission-flow edge case).
    public func backgrounded() { if screen == .play || screen == .quiz { pausedFrom = screen; screen = .pause } }

    // MARK: debug screen jumps (`-startScreen quiz -q 2`, same names as Android)

    public func debugStart(screen name: String, q: Int?, beat: Int?, stage: String?, stars s: Int?, wrong: Int?) {
        guard isDebug, let target = Screen(rawValue: name) else { return }
        reset()
        switch target {
        case .quiz:
            startQuiz(); quiz!.jump(to: (q ?? 1) - 1)
            if let w = wrong { _ = quiz!.pick(slot: w - 1) }
        case .results: startQuiz(); stars = s ?? 2; go(.results)
        case .play:
            go(.play)
            if let b = beat { play.debugJump(beat: b - 1, stage: stage) }
        case .pause: go(.play); if let b = beat { play.debugJump(beat: b - 1, stage: stage) }; pausedFrom = .play; screen = .pause
        default: go(target)
        }
    }
}
