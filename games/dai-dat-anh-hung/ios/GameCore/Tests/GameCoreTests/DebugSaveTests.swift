import XCTest
@testable import GameCore

/// iOS QC r8 medal finding (leader rule, r9): a debug-jumped run (`-startScreen …`) never writes progress to the
/// device's store: no stars, medal, completed or seen_open. A real run from Start still writes all of them, and
/// the VI|EN setting is saved either way.
final class DebugSaveTests: XCTestCase {
    var now = 100.0
    let progressKeys = ["stars.", "medal.", "completed.", "seen_open."]

    func game(_ store: MemoryStore) throws -> Game {
        let c = try ContentSet.load(dataRoot: Repo.data)
        let g = Game(content: c, hero: realHero(c), store: store, isDebug: true) // debug: the claims are unsigned (R12)
        g.uptime = { [unowned self] in self.now }
        return g
    }

    /// Steps the game to the results: the bot plays the play beats, every story box and quiz card is pressed by
    /// time (after the entry lock), as the UI would.
    func runToResults(_ g: Game) {
        var step = 0, lastPress = now
        while g.screen != .results && step < 60 * 900 {
            now += 1.0 / 60; step += 1
            g.step(1.0 / 60, g.screen == .play && !GameScene_storyPhases.contains(g.play.phase) ? botInput(g.play, step: step) : StepInput())
            guard now - lastPress >= 1.6 else { continue } // past screen_enter_lock_max: every press lands
            lastPress = now
            switch g.screen {
            case .quiz:
                if let q = g.quiz, q.okIndex == nil, let slot = q.order.firstIndex(of: q.current.correctIndex) { g.answer(slot, at: now) } else { g.next(at: now) }
            case .play where g.play.askShowing: g.ask(at: now)
            default: g.next(at: now)
            }
        }
    }

    func progressKeys(_ s: MemoryStore) -> Set<String> { Set(s.values.keys.filter { k in progressKeys.contains { k.hasPrefix($0) } }) }
    /// The progress keys written since `before` (the launch's own title load marks the first hero seen_open in
    /// Game.init, before any jump; the first hero is always open, so that key carries nothing).
    func progressWrites(_ s: MemoryStore, since before: Set<String>) -> [String] { progressKeys(s).subtracting(before).sorted() }

    func test_a_jumped_quiz_run_writes_no_progress() throws {
        let store = MemoryStore(), g = try game(store), before = progressKeys(store)
        XCTAssertTrue(before.allSatisfy { $0.hasPrefix("seen_open.") }, "a launch writes only the first hero's seen_open")
        g.debugStart(screen: "quiz", q: nil, beat: nil, stage: nil, stars: nil)
        XCTAssertTrue(g.debugJumped)
        runToResults(g)
        XCTAssertEqual(g.screen, .results)
        XCTAssertEqual(g.stars, 3, "results still show the run's stars")
        XCTAssertTrue(g.medalEarned, "and its medal, in memory")
        XCTAssertEqual(progressWrites(store, since: before), [], "nothing reached the device's store")
        g.home() // back at the title in the same launch: seen_open isn't written either
        XCTAssertEqual(progressWrites(store, since: before), [])
        let again = try game(store) // a relaunch on the same store
        XCTAssertEqual(again.titleCard?.stars, 0); XCTAssertEqual(again.titleCard?.medal, false)
    }

    func test_a_jumped_play_run_to_the_results_writes_no_progress() throws {
        let store = MemoryStore(), g = try game(store), before = progressKeys(store)
        g.debugStart(screen: "play", q: nil, beat: 1, stage: nil, stars: nil)
        runToResults(g)
        XCTAssertEqual(g.screen, .results, "the jumped run reached the results")
        XCTAssertEqual(progressWrites(store, since: before), [])
    }

    func test_the_language_is_still_saved_after_a_jump() throws {
        let store = MemoryStore(), g = try game(store)
        g.debugStart(screen: "title", q: nil, beat: nil, stage: nil, stars: nil)
        g.toggleLang()
        XCTAssertNotNil(store.values["lang"], "VI|EN is a setting, not progress")
    }

    func test_a_real_run_from_start_writes_progress() throws {
        let store = MemoryStore(), g = try game(store)
        g.start()
        XCTAssertFalse(g.debugJumped)
        runToResults(g)
        XCTAssertEqual(g.screen, .results)
        XCTAssertEqual(store.values["stars.tran-quoc-toan"] as? Int, 3)
        XCTAssertEqual(store.values["medal.tran-quoc-toan"] as? Bool, true)
        XCTAssertEqual(store.values["completed.tran-quoc-toan"] as? Bool, true)
        let again = try game(store)
        XCTAssertEqual(again.titleCard?.stars, 3); XCTAssertEqual(again.titleCard?.medal, true)
    }
}
