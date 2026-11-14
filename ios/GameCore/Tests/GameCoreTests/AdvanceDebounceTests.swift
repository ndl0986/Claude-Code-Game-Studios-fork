import XCTest
@testable import GameCore

/// Input GDD Rule 12 / F3: the advance debounce compares each press's own time, never the sim clock.
/// Android B1 root cause: loading the next box stalls a frame, the sim clock jumps (up to 0.25 s per
/// frame, more over two), and a second tap 0.06–0.20 s after the first got through. On iOS the press
/// time is `UITouch.timestamp`; these tests drive the core with press times directly.
final class AdvanceDebounceTests: XCTestCase {
    enum Path { case intro, card, caption, dialogueNext, ask, ending }

    /// A box that advances: the screen, the story line and every play line counter.
    func where_(_ g: Game) -> String {
        "\(g.screen) \(g.storyLine) \(g.play.phase) \(g.play.beat) \(g.play.cardLine) \(g.play.captionLine) \(g.play.lineIndex)"
    }

    /// A game on `path` with a further box after the first tap, so a wrongly accepted second tap shows.
    func game(_ path: Path) throws -> Game {
        let c = try Repo.contentSet()
        let hero = path == .caption ? Repo.sampleHero(c) : realHero(c)
        let g = Game(content: c, hero: hero, store: MemoryStore(), isDebug: true)
        let tqtDialogue = path == .caption ? 0 : beatIndex(hero, "dialogue") + 1
        switch path {
        case .intro: g.debugStart(screen: "intro", q: nil, beat: nil, stage: nil, stars: nil)          // 4 lines
        case .card: g.debugStart(screen: "play", q: nil, beat: 1, stage: "card", stars: nil)           // walk: 2 scene + goal
        case .caption: g.debugStart(screen: "caption", q: nil, beat: 2, stage: nil, stars: nil)        // sample beat 2: 2 boxes
        case .ending: g.debugStart(screen: "ending", q: nil, beat: nil, stage: nil, stars: nil)        // 2 lines
        case .ask: g.debugStart(screen: "play", q: nil, beat: tqtDialogue, stage: "ask", stars: nil)   // ask on lines 2 and 3
        case .dialogueNext:
            // past the ask lines, on line 4 of 9, so "Tiếp" shows on the next line too
            g.debugStart(screen: "play", q: nil, beat: tqtDialogue, stage: "ask", stars: nil)
            g.ask(at: 1); g.ask(at: 2)
            XCTAssertFalse(g.play.askShowing)
        }
        return g
    }

    func press(_ g: Game, _ path: Path, at t: Double) { path == .ask ? g.ask(at: t) : g.next(at: t) }

    /// QC's B1 sequence: tap 1 at T, a 0.30 s frame stall, tap 2 pressed at T + 0.15 → ignored.
    func test_second_press_inside_the_window_is_ignored_after_a_frame_stall_on_every_advance_path() throws {
        for path in [Path.intro, .card, .caption, .dialogueNext, .ask, .ending] {
            let g = try game(path)
            let t = 10.0, before = where_(g)
            press(g, path, at: t)
            let afterFirst = where_(g)
            XCTAssertNotEqual(afterFirst, before, "\(path): the first press advances")
            for _ in 0..<18 { g.step(1.0 / 60, StepInput()) } // the stall: the sim clock moves 0.30 s
            press(g, path, at: t + 0.15)
            XCTAssertEqual(where_(g), afterFirst, "\(path): a press 0.15 s after the last advance is ignored")
            press(g, path, at: t + 0.25) // F3 boundary: at exactly advance_debounce the press is accepted
            XCTAssertNotEqual(where_(g), afterFirst, "\(path): a press at +0.25 s advances")
        }
    }

    /// The window is measured from the last press that advanced, not from an ignored one.
    func test_an_ignored_press_does_not_restart_the_window() throws {
        let g = try game(.intro)
        g.next(at: 10); let one = where_(g)
        g.next(at: 10.2); XCTAssertEqual(where_(g), one)
        g.next(at: 10.3); XCTAssertNotEqual(where_(g), one, "0.30 s after the press that advanced")
    }

    /// No frame passes at all: two presses in one frame 0.30 s apart (a stall before both) both count.
    func test_presses_far_apart_count_even_without_a_frame_between() throws {
        let g = try game(.intro)
        g.next(at: 10); let one = where_(g)
        g.next(at: 10.3); XCTAssertNotEqual(where_(g), one)
    }
}
