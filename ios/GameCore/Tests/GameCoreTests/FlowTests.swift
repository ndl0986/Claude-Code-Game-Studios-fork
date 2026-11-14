import XCTest
@testable import GameCore

/// Screen flow, saving, quiz (Quiz & stars GDD, P-04, P-05).
final class FlowTests: XCTestCase {
    func game(debug: Bool = true, store: MemoryStore = MemoryStore()) throws -> Game {
        let c = try Repo.contentSet()
        return Game(content: c, hero: c.heroes[0], store: store, isDebug: debug)
    }
    func wait(_ g: Game, _ s: Double) { for _ in 0..<Int(s * 60) { g.step(1.0 / 60, StepInput()) } }

    func test_release_build_never_starts_an_unsigned_mission() throws {
        let g = try game(debug: false)
        XCTAssertFalse(g.isPlayable)
        g.start()
        XCTAssertEqual(g.screen, .title)
    }

    func test_screens_run_title_intro_play_ending_quiz_results_unlock_title() throws {
        let g = try game()
        g.start(); XCTAssertEqual(g.screen, .intro)
        wait(g, 0.3); g.next(); XCTAssertEqual(g.screen, .play)
        var steps = 0
        while g.screen == .play && steps < 60 * 600 {
            let p = g.play
            if p.phase == .caption { wait(g, 0.3); g.next() } else { g.step(1.0 / 60, botInput(p, step: steps)) }
            steps += 1
        }
        XCTAssertEqual(g.screen, .ending)
        wait(g, 0.3); g.next(); XCTAssertEqual(g.screen, .quiz)
        while g.screen == .quiz {
            let q = g.quiz!
            let slot = q.order.firstIndex(of: q.current.correctIndex)!
            wait(g, 0.6); g.answer(slot); wait(g, 0.3); g.next()
        }
        XCTAssertEqual(g.screen, .results)
        XCTAssertEqual(g.stars, 3)
        g.next(); XCTAssertEqual(g.screen, .unlock)
        g.next(); XCTAssertEqual(g.screen, .title)
    }

    func test_story_next_is_debounced() throws {
        let g = try game()
        g.debugStart(screen: "quiz", q: 1, beat: nil, stage: nil, stars: nil, wrong: nil)
        g.start(); wait(g, 0.3)
        g.next() // intro has 1 box → play
        XCTAssertEqual(g.screen, .play)
    }

    func test_quiz_saves_best_stars_never_lowered_and_unlocks_next_hero() throws {
        let store = MemoryStore()
        var p = Progress()
        p.recordQuiz(hero: "sample", stars: 3, nextHero: "sample2", store: store)
        p.recordQuiz(hero: "sample", stars: 1, nextHero: "sample2", store: store)
        XCTAssertEqual(store.values["stars.sample"] as? Int, 3)
        XCTAssertEqual(store.values["unlocked"] as? [String], ["sample2"])
        XCTAssertEqual(Progress.load(store, heroIds: ["sample"]).stars["sample"], 3)
    }

    func test_language_is_remembered_on_the_device() throws {
        let store = MemoryStore()
        let g = try game(store: store)
        g.toggleLang()
        XCTAssertEqual(store.values["lang"] as? String, "en")
        XCTAssertEqual(try game(store: store).lang, .en)
    }

    func test_P05_wrong_card_shakes_and_ignores_taps_then_why_then_next() throws {
        let g = try game()
        g.debugStart(screen: "quiz", q: 1, beat: nil, stage: nil, stars: nil, wrong: nil)
        let q = g.quiz!
        let right = q.order.firstIndex(of: q.current.correctIndex)!
        let wrong = (0..<3).first { $0 != right }!
        g.answer(wrong)
        g.answer(right)
        XCTAssertNil(g.quiz!.okIndex, "taps ignored during the 0.5 s shake")
        wait(g, 0.55)
        g.answer(right)
        XCTAssertNotNil(g.quiz!.okIndex)
        wait(g, 3)
        XCTAssertEqual(g.quiz!.index, 0, "no auto-advance: Next after why")
        g.next()
        XCTAssertEqual(g.quiz!.index, 1)
        XCTAssertEqual(g.quiz!.retries, 1)
    }

    func test_quiz_count_is_clamped_to_the_questions_available() throws {
        let g = try game()
        g.startQuiz()
        XCTAssertEqual(g.quiz!.questions.count, 4, "quiz_count 5, the sample has 4")
    }

    func test_pause_from_play_and_quiz_freezes_and_resume_returns() throws {
        let g = try game()
        g.debugStart(screen: "play", q: nil, beat: 1, stage: "telegraph", stars: nil, wrong: nil)
        g.pause(); XCTAssertEqual(g.screen, .pause)
        let t = g.play.t
        wait(g, 1)
        XCTAssertEqual(g.play.t, t, "frozen")
        g.resume(); XCTAssertEqual(g.screen, .play)
        g.startQuiz(); g.backgrounded(); XCTAssertEqual(g.screen, .pause)
        g.resume(); XCTAssertEqual(g.screen, .quiz)
    }

    func test_menu_tap_tone_at_most_once_per_80ms() throws {
        let g = try game()
        g.toggleMute(); g.toggleMute()
        XCTAssertEqual(g.takeUiSounds().count, 1)
        wait(g, 0.1); g.toggleMute()
        XCTAssertEqual(g.takeUiSounds().count, 1)
    }
}
