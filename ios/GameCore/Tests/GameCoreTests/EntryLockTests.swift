import XCTest
@testable import GameCore

/// Input Rule 13 entry lock (QC r6 B7, TASK-005p): for screen_enter_lock (0.6 s) after a story, card, dialogue
/// or quiz context is entered, presses are dropped; box-to-box keeps the 0.25 s debounce; pause is exempt.
/// The press clock (uptime) is injected; the sim advances 1/60 s per step in step with it.
final class EntryLockTests: XCTestCase {
    var now = 100.0
    func game() throws -> Game {
        let c = try ContentSet.load(dataRoot: Repo.data)
        let g = Game(content: c, hero: realHero(c), store: MemoryStore(), isDebug: true)
        g.uptime = { [unowned self] in self.now }
        return g
    }
    func step(_ g: Game, _ input: StepInput = StepInput()) { now += 1.0 / 60; g.step(1.0 / 60, input) }

    /// B7: a child mashing at 0.35 s through the end of reach-the-flag never skips the first ending box.
    func test_a_mash_across_the_beat_end_keeps_the_first_ending_box_for_the_lock() throws {
        let g = try game()
        g.debugStart(screen: "play", q: nil, beat: beatIndex(realHero(g.content), "reach-the-flag") + 1, stage: nil, stars: nil)
        var steps = 0, lastMash = now, endingAt: Double?, firstBoxLeftAt: Double?
        while steps < 60 * 300 && firstBoxLeftAt == nil {
            if g.screen == .play && g.play.phase == .beatCard { g.next(at: now + 1) } // the card before play (not the case under test)
            step(g, botInput(g.play, step: steps)); steps += 1
            if now - lastMash >= 0.35 { g.next(at: now); lastMash = now } // the mash: a press every 0.35 s
            if g.screen == .ending && endingAt == nil { endingAt = now - 1.0 / 60 }
            if let e = endingAt, g.screen != .ending || g.storyLine > 0 { firstBoxLeftAt = now; _ = e }
        }
        let e = try XCTUnwrap(endingAt, "reached the ending")
        let left = try XCTUnwrap(firstBoxLeftAt, "the mash eventually advanced")
        XCTAssertGreaterThanOrEqual(left - e, g.tuning["screen_enter_lock"] - 1.0 / 60, "the first ending box stayed ≥ the lock")
    }

    func test_the_lock_boundary_and_box_to_box() throws {
        func intro() throws -> (Game, Double) {
            let g = try game()
            g.debugStart(screen: "intro", q: nil, beat: nil, stage: nil, stars: nil)
            step(g) // the intro context is entered on this step
            return (g, try XCTUnwrap(g.enteredAt))
        }
        var (g, e) = try intro()
        g.next(at: e + 0.59); XCTAssertEqual(g.storyLine, 0, "+0.59 s is dropped")
        g.next(at: e + 0.61); XCTAssertEqual(g.storyLine, 0, "rolling: +0.59 moved the end to +1.19, so +0.61 is dropped too (end +1.21)")
        g.next(at: e + 1.20); XCTAssertEqual(g.storyLine, 0, "+1.20 is still inside (end +1.21); it would move the end to +1.80, capped at +1.5")
        g.next(at: e + 1.49); XCTAssertEqual(g.storyLine, 0, "+1.49 is inside the capped end")
        g.next(at: e + 1.50); XCTAssertEqual(g.storyLine, 1, "+1.50 s (the cap, screen_enter_lock_max) advances")
        (g, e) = try intro()
        g.next(at: e + 0.61); XCTAssertEqual(g.storyLine, 1, "a first press at +0.61 s advances")
        g.next(at: e + 0.61 + 0.26); XCTAssertEqual(g.storyLine, 2, "box to box: only the 0.25 s debounce")
        (g, e) = try intro()
        g.next(at: e - 0.05); g.next(at: e + 0.61)
        XCTAssertEqual(g.storyLine, 1, "a press stamped before the entry is dropped without extending the lock")
    }

    /// TASK-005q: the lock rolls. A 0.35 s mash keeps it closed until the cap (1.5 s from entry), then the next
    /// press is accepted; box 2 then keeps the debounce. (The cap comes from a test tuning until 005q merges.)
    func test_a_continuous_mash_rolls_the_lock_up_to_the_cap() throws {
        let c = try ContentSet.load(dataRoot: Repo.data)
        var values = c.tuning.values.mapValues(\.value); values["screen_enter_lock_max"] = 1.5
        let t = Tuning(values: values, seed: c.tuning.seed)
        let content = ContentSet(index: c.index, strings: c.strings, sources: c.sources, markers: c.markers, rules: c.rules, tuning: t, assets: c.assets, themes: c.themes, heroes: c.heroes)
        let g = Game(content: content, hero: realHero(content), store: MemoryStore(), isDebug: true)
        g.uptime = { [unowned self] in self.now }
        g.debugStart(screen: "ending", q: nil, beat: nil, stage: nil, stars: nil)
        step(g)
        let e = try XCTUnwrap(g.enteredAt)
        var advancedAt: Double?
        for i in 1...8 {
            let p = e + Double(i) * 0.35
            g.next(at: p)
            if g.storyLine > 0 && advancedAt == nil { advancedAt = p }
        }
        XCTAssertEqual(try XCTUnwrap(advancedAt), e + 5 * 0.35, accuracy: 1e-9, "presses at 0.35…1.40 roll the lock to the 1.5 s cap; 1.75 advances")
    }

    /// B7 follow-up: every ending box takes the rolling lock. A 4 s mash at 0.35 s: box 1 and box 2 each hold
    /// ≥ screen_enter_lock_max (1.5 s; a test tuning until TASK-005q merges).
    func test_every_ending_box_takes_the_rolling_lock() throws {
        let c = try ContentSet.load(dataRoot: Repo.data)
        var values = c.tuning.values.mapValues(\.value); values["screen_enter_lock_max"] = 1.5
        let content = ContentSet(index: c.index, strings: c.strings, sources: c.sources, markers: c.markers, rules: c.rules,
                                 tuning: Tuning(values: values, seed: c.tuning.seed), assets: c.assets, themes: c.themes, heroes: c.heroes)
        let g = Game(content: content, hero: realHero(content), store: MemoryStore(), isDebug: true)
        g.uptime = { [unowned self] in self.now }
        g.debugStart(screen: "ending", q: nil, beat: nil, stage: nil, stars: nil)
        step(g)
        var shownAt = [0: try XCTUnwrap(g.enteredAt)], leftAt: [Int: Double] = [:]
        let start = now
        while now - start < 4 {
            now += 0.35
            let line = g.storyLine, screen = g.screen
            g.next(at: now)
            if screen == .ending && (g.screen != .ending || g.storyLine != line) {
                leftAt[line] = now
                if g.screen == .ending { shownAt[g.storyLine] = now }
            }
        }
        for box in [0, 1] {
            let shown = try XCTUnwrap(shownAt[box], "box \(box + 1) shown"), left = try XCTUnwrap(leftAt[box], "box \(box + 1) left")
            XCTAssertGreaterThanOrEqual(left - shown, 1.5 - 1e-9, "ending box \(box + 1) held ≥ 1.5 s under the mash")
        }
    }

    func test_pause_is_exempt_and_quiz_cards_are_locked() throws {
        let g = try game()
        g.debugStart(screen: "quiz", q: nil, beat: nil, stage: nil, stars: nil)
        step(g)
        let entered = try XCTUnwrap(g.enteredAt)
        g.answer(0, at: entered + 0.2); XCTAssertNil(g.quiz?.okIndex); XCTAssertTrue(g.quiz?.wrong.isEmpty ?? false, "a card press in the lock is dropped")
        g.pause(); XCTAssertEqual(g.screen, .pause, "pause works at once")
        g.resume(); XCTAssertEqual(g.screen, .quiz)
        XCTAssertEqual(g.enteredAt, entered, "returning from pause doesn't restart the lock")
    }
}

/// Input Rule 13b (QC r7, r8): every story box and every dialogue line takes the rolling lock, as if entered.
/// A press every 0.35 s holds each box ≥ screen_enter_lock_max (1.5 s) and skips none (Input AC21/AC22, story
/// AC11, dialogue AC8); a deliberate tap 0.6 s after the last press advances at once; the quiz keeps only the
/// debounce, except on a small-k phone (Game.quizLocksPerQuestion).
final class EveryBoxLockTests: XCTestCase {
    var now = 100.0
    func game() throws -> Game {
        let c = try ContentSet.load(dataRoot: Repo.data)
        let g = Game(content: c, hero: realHero(c), store: MemoryStore(), isDebug: true)
        g.uptime = { [unowned self] in self.now }
        return g
    }
    func step(_ g: Game) { now += 1.0 / 60; g.step(1.0 / 60, StepInput()) }
    func box(_ g: Game) -> String { "\(g.screen) \(g.storyLine) \(g.play.phase) \(g.play.beat) \(g.play.cardLine) \(g.play.captionLine) \(g.play.lineIndex)" }

    /// Mashes from the current box while `inside` holds: a press every 0.35 s (ask when the ask button shows,
    /// otherwise Next), the sim stepping in time. Returns how long each box was on screen before a press left it.
    func mash(_ g: Game, while inside: (Game) -> Bool) -> [(String, Double)] {
        step(g)
        var shown = now, current = box(g), held: [(String, Double)] = []
        while inside(g) && held.count < 40 {
            for _ in 0..<21 { step(g) } // 0.35 s
            if g.screen == .play && g.play.askShowing { g.ask(at: now) } else { g.next(at: now) }
            let b = box(g)
            if b != current { held.append((current, now - shown)); current = b; shown = now }
        }
        return held
    }

    func assertEachHeld(_ held: [(String, Double)], atLeast n: Int, _ what: String) {
        XCTAssertGreaterThanOrEqual(held.count, n, "\(what): \(n) boxes advanced")
        for (b, t) in held { XCTAssertGreaterThanOrEqual(t, 1.5 - 1e-6, "\(what): \(b) held \(t) s under the mash") }
    }

    func test_every_intro_box_holds_under_a_mash() throws {
        let g = try game()
        g.debugStart(screen: "intro", q: nil, beat: nil, stage: nil, stars: nil)
        assertEachHeld(mash(g) { $0.screen == .intro }, atLeast: g.hero.mission.intro.count, "intro")
    }

    func test_every_beat_card_box_holds_under_a_mash() throws {
        let g = try game()
        g.debugStart(screen: "play", q: nil, beat: 1, stage: "card", stars: nil)
        assertEachHeld(mash(g) { $0.screen == .play && $0.play.phase == .beatCard }, atLeast: 2, "beat card")
    }

    /// Captions exist only before fight beats; TQT has none, so the sample hero's fight beat (2 boxes).
    func test_every_caption_box_holds_under_a_mash() throws {
        let c = try Repo.contentSet(), h = Repo.sampleHero(c)
        let g = Game(content: c, hero: h, store: MemoryStore(), isDebug: true)
        g.uptime = { [unowned self] in self.now }
        let fight = try XCTUnwrap(h.mission.beats.firstIndex { $0.type == "fight" && $0.scene.count > 1 })
        g.debugStart(screen: "play", q: nil, beat: fight + 1, stage: "caption", stars: nil)
        XCTAssertEqual(g.play.phase, .caption)
        assertEachHeld(mash(g) { $0.screen == .play && $0.play.phase == .caption }, atLeast: h.mission.beats[fight].scene.count, "caption")
    }

    /// Input AC22 / dialogue AC8: the Bình Than dialogue (9 lines, the ask lines included) under a mash.
    func test_every_dialogue_line_holds_under_a_mash() throws {
        let g = try game()
        let h = realHero(g.content), d = beatIndex(h, "dialogue")
        g.debugStart(screen: "play", q: nil, beat: d + 1, stage: nil, stars: nil)
        XCTAssertEqual(g.play.phase, .dialogueLine); XCTAssertEqual(g.play.lineIndex, 0)
        let lines = g.play.dialogueLines.count
        assertEachHeld(mash(g) { $0.screen == .play && $0.play.phase == .dialogueLine }, atLeast: lines, "dialogue")
        XCTAssertNotEqual(g.play.phase, .dialogueLine, "the mash got through all \(lines) lines, one per lock")
    }

    /// A deliberate reader: a tap 0.6 s after the previous press advances at once, box after box.
    func test_a_tap_after_a_pause_advances_each_box_at_once() throws {
        let g = try game()
        g.debugStart(screen: "intro", q: nil, beat: nil, stage: nil, stars: nil)
        step(g)
        var t = try XCTUnwrap(g.enteredAt)
        for line in 1..<g.hero.mission.intro.count {
            t += 0.6; now = t; g.next(at: t)
            XCTAssertEqual(g.storyLine, line, "the tap 0.6 s after the last press shows box \(line + 1)")
        }
    }

    /// An ask tap is a line advance: two quick ask taps advance one line.
    func test_two_quick_ask_taps_advance_one_line() throws {
        let g = try game()
        let h = realHero(g.content)
        g.debugStart(screen: "play", q: nil, beat: beatIndex(h, "dialogue") + 1, stage: "ask", stars: nil)
        step(g)
        let e = try XCTUnwrap(g.enteredAt), line = g.play.lineIndex
        XCTAssertTrue(g.play.askShowing)
        now = e + 0.7; g.ask(at: now); XCTAssertEqual(g.play.lineIndex, line + 1, "the first ask tap advances")
        now = e + 1.0; g.ask(at: now); XCTAssertEqual(g.play.lineIndex, line + 1, "a second ask tap 0.3 s later is dropped")
    }

    /// The quiz keeps only the debounce between questions, unless the phone is small-k (§5.2).
    func test_the_next_quiz_question_is_locked_only_on_a_small_k_phone() throws {
        for small in [false, true] {
            let g = try game()
            g.quizLocksPerQuestion = small
            g.debugStart(screen: "quiz", q: nil, beat: nil, stage: nil, stars: nil)
            step(g)
            for _ in 0..<60 { step(g) } // past the entry lock
            let q = try XCTUnwrap(g.quiz)
            let right = try XCTUnwrap(q.order.firstIndex(of: q.current.correctIndex))
            g.answer(right, at: now)
            for _ in 0..<60 { step(g) } // feedback_time
            XCTAssertTrue(g.quizCanAdvance)
            g.next(at: now); XCTAssertEqual(g.quiz?.index, 1)
            let q2 = try XCTUnwrap(g.quiz), right2 = try XCTUnwrap(q2.order.firstIndex(of: q2.current.correctIndex))
            g.answer(right2, at: now + 0.3)
            XCTAssertEqual(g.quiz?.okIndex != nil, !small, small ? "small k: a pick 0.3 s into question 2 is dropped" : "a pick 0.3 s into question 2 counts")
        }
    }
}

/// QC r7 NOT ASSESSED: the medal under a mash in a real full run (no debug jump). From the title: Start, then a press
/// on Tiếp's spot every 0.35 s through every story box, card, caption and dialogue line (ask taps when the ask button
/// shows) and through the ending; the bot plays each beat; the quiz is answered right. The mash never counts as a
/// skip (only Bỏ qua does), so the medal is earned, and every story box held ≥ 1.5 s.
final class FullRunMashTests: XCTestCase {
    var now = 100.0
    func test_mashing_through_a_full_run_still_earns_the_medal() throws {
        let c = try ContentSet.load(dataRoot: Repo.data)
        let store = MemoryStore()
        let g = Game(content: c, hero: realHero(c), store: store, isDebug: true) // debug: the claims are unsigned (R12)
        g.uptime = { [unowned self] in self.now }
        let dt = 1.0 / 60
        g.start()
        XCTAssertEqual(g.screen, .intro)
        var step = 0, lastMash = now, shownAt = now, lastBox = "", held: [(String, Double)] = []
        func box() -> String { "\(g.screen) \(g.storyLine) \(g.play.phase) \(g.play.beat) \(g.play.cardLine) \(g.play.captionLine) \(g.play.lineIndex)" }
        while g.screen != .results && step < 60 * 900 {
            now += dt; step += 1
            g.step(dt, g.screen == .play && !GameScene_storyPhases.contains(g.play.phase) ? botInput(g.play, step: step) : StepInput())
            if now - lastMash >= 0.35 {
                lastMash = now
                switch g.screen {
                case .quiz:
                    if let q = g.quiz, q.okIndex == nil, let slot = q.order.firstIndex(of: q.current.correctIndex) { g.answer(slot, at: now) }
                    else { g.next(at: now) }
                case .play where g.play.askShowing: g.ask(at: now)
                default: g.next(at: now)
                }
            }
            let b = box()
            if b != lastBox {
                // a story box (intro, ending, beat card, caption, dialogue line) left: how long it was on screen
                let story = lastBox.hasPrefix("intro") || lastBox.hasPrefix("ending") || ["beatCard", "caption", "dialogueLine"].contains { lastBox.contains(" \($0) ") }
                if story { held.append((lastBox, now - shownAt)) }
                lastBox = b; shownAt = now
            }
        }
        XCTAssertEqual(g.screen, .results, "the run reached the results")
        XCTAssertTrue(g.medalEarned, "mashing Tiếp is not skipping: the medal is earned")
        XCTAssertTrue(g.progress.medal.contains(g.heroId), "and saved")
        XCTAssertEqual(g.stars, 3)
        XCTAssertGreaterThanOrEqual(held.count, 10, "story boxes were mashed through")
        for (b, t) in held { XCTAssertGreaterThanOrEqual(t, 1.5 - 1e-6, "\(b) held \(t) s") }
    }
}

/// The play phases drawn as story screens (the app's GameScene.storyPhases).
let GameScene_storyPhases: Set<PlayState.Phase> = [.beatCard, .caption, .dialogueLine]
