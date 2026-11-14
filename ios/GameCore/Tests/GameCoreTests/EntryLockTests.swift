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
        let g = try game()
        g.debugStart(screen: "intro", q: nil, beat: nil, stage: nil, stars: nil)
        step(g) // the intro context is entered on this step
        let entered = try XCTUnwrap(g.enteredAt)
        g.next(at: entered + 0.59); XCTAssertEqual(g.storyLine, 0, "+0.59 s is dropped")
        g.next(at: entered + 0.61); XCTAssertEqual(g.storyLine, 1, "+0.61 s advances")
        g.next(at: entered + 0.61 + 0.26); XCTAssertEqual(g.storyLine, 2, "box to box: only the 0.25 s debounce")
        g.next(at: entered - 0.05); XCTAssertEqual(g.storyLine, 2, "a press stamped before the entry is dropped")
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
