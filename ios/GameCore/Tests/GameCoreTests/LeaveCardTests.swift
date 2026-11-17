import XCTest
@testable import GameCore

/// TASK-023 W18 (Mission flow Rule 11, pause.md): the pause menu's "Về bản đồ" opens the leave card first.
/// Mirrors Android r14 LeaveCardTest. The press clock (uptime) is injected; the sim advances 1/60 s per step with it.
final class LeaveCardTests: XCTestCase {
    var now = 100.0
    func game() throws -> Game {
        let c = try ContentSet.load(dataRoot: Repo.data)
        let g = Game(content: c, hero: realHero(c), store: MemoryStore(), isDebug: true)
        g.uptime = { [unowned self] in self.now }
        return g
    }
    func step(_ g: Game, _ n: Int = 1) { for _ in 0..<n { now += 1.0 / 60; g.step(1.0 / 60, StepInput()) } }

    /// A run in play (beat 2), paused: the menu up, no card.
    func paused() throws -> Game {
        let g = try game()
        g.debugStart(screen: "play", q: nil, beat: 2, stage: nil, stars: nil)
        step(g, 30)
        g.pause()
        XCTAssertEqual(g.screen, .pause); XCTAssertFalse(g.leaveCard)
        return g
    }

    func test_the_menu_opens_the_card_and_nothing_else_leaves_pause() throws {
        let g = try paused()
        let beat = g.play.beat, x = g.play.hero.x
        g.home(); g.leave(at: now + 5)
        XCTAssertEqual(g.screen, .pause, "home() and leave() from the bare menu do nothing")
        g.askLeave()
        XCTAssertTrue(g.leaveCard); XCTAssertEqual(g.screen, .pause)
        XCTAssertEqual(g.play.beat, beat); XCTAssertEqual(g.play.hero.x, x, "opening the card discards nothing")
        g.resume(); g.home()
        XCTAssertEqual(g.screen, .pause, "resume() and home() aren't live under the card"); XCTAssertTrue(g.leaveCard)
    }

    func test_keep_playing_returns_to_the_menu_with_the_run_intact() throws {
        let g = try paused()
        let beat = g.play.beat, x = g.play.hero.x
        g.askLeave(); step(g, 60)
        g.keepPlaying(at: now)
        XCTAssertFalse(g.leaveCard); XCTAssertEqual(g.screen, .pause, "back to the menu")
        g.resume()
        XCTAssertEqual(g.screen, .play); XCTAssertEqual(g.play.beat, beat); XCTAssertEqual(g.play.hero.x, x)
    }

    func test_only_the_cards_to_the_map_leaves_and_shows_the_title() throws {
        let g = try paused()
        g.askLeave(); step(g, 60)
        g.leave(at: now)
        XCTAssertEqual(g.screen, .title, "the map screen isn't built yet (TASK-025): the title")
        XCTAssertFalse(g.leaveCard); XCTAssertEqual(g.play.beat, 0, "the run was discarded")
    }

    func test_the_cards_buttons_take_the_rolling_entry_lock() throws {
        let g = try paused()
        g.askLeave()
        let e = try XCTUnwrap(g.enteredAt)
        XCTAssertEqual(e, now, "opening the card is a new context")
        g.keepPlaying(at: now + 0.3); g.leave(at: now + 0.3)
        XCTAssertTrue(g.leaveCard); XCTAssertEqual(g.screen, .pause, "inside 0.6 s: dropped (the lock rolls to +0.9)")
        g.keepPlaying(at: e + 0.85)
        XCTAssertTrue(g.leaveCard, "0.85 s: still inside the rolled lock")
        g.keepPlaying(at: e + 0.85 + g.tuning["screen_enter_lock"] + 0.01)
        XCTAssertFalse(g.leaveCard, "≥ 0.6 s after the last dropped press: it works")
    }

    func test_closing_the_card_does_not_relock_the_menu() throws {
        let g = try game()
        g.debugStart(screen: "intro", q: nil, beat: nil, stage: nil, stars: nil)
        step(g, 60)
        let ctx = g.lockContextForDebug, entered = g.enteredAt
        g.pause(); g.askLeave()
        XCTAssertEqual(g.lockContextForDebug, (ctx ?? "pause") + "/leave")
        let cardEntered = g.enteredAt
        step(g, 60); g.keepPlaying(at: now)
        XCTAssertEqual(g.lockContextForDebug, ctx, "back to the box's context")
        XCTAssertEqual(g.enteredAt, cardEntered, "no new entry stamped on closing")
        XCTAssertNotEqual(g.enteredAt, entered)
        XCTAssertFalse(g.isLocked(at: now), "the menu (and the box after resume) isn't relocked")
    }

    func test_a_new_pause_never_reopens_an_old_card() throws {
        let g = try paused()
        g.askLeave(); step(g, 60); g.keepPlaying(at: now)
        g.resume(); step(g, 5); g.pause()
        XCTAssertFalse(g.leaveCard, "after Chơi tiếp and a resume")
        g.askLeave(); step(g, 60); g.leave(at: now)
        g.start(); step(g, 5); g.pause()
        XCTAssertFalse(g.leaveCard, "after leaving and starting a new run")
        g.askLeave()
        XCTAssertEqual(g.leaveT, 0, "a reopened card slides in from the start")
        step(g, 15)
        XCTAssertEqual(g.leaveT, 0.25, accuracy: 1e-9, "leaveT runs while the card is up")
    }

    func test_the_cards_line_in_vi_and_en() throws {
        let g = try game()
        g.forceLang(.vi); XCTAssertEqual(g.ui("ui.pause.leave_confirm"), "Về bản đồ?")
        g.forceLang(.en); XCTAssertEqual(g.ui("ui.pause.leave_confirm"), "Leave the story?")
        XCTAssertEqual(g.ui("ui.btn.to_map"), "To the map"); XCTAssertEqual(g.ui("ui.btn.resume"), "Keep playing")
    }
}

/// TASK-023 W17: the hold-meter beat's special pad shows a fist; training's finish keeps the banner.
final class SpecialIconTests: XCTestCase {
    func test_hold_meter_shows_a_fist_and_training_the_banner() {
        XCTAssertEqual(SpecialIcon.forBeat(type: "hold-meter"), .fist)
        XCTAssertEqual(SpecialIcon.forBeat(type: "training"), .banner)
        XCTAssertEqual(SpecialIcon.forBeat(type: nil), .banner)
    }

    func test_the_real_missions_hold_beat_gets_the_fist() throws {
        let c = try ContentSet.load(dataRoot: Repo.data), hero = realHero(c)
        var p = PlayState(tuning: c.tuning, beats: hero.mission.beats, seed: 1)
        p.debugJump(beat: beatIndex(hero, "hold-meter"), stage: nil)
        XCTAssertEqual(p.specialIcon, .fist)
        p.debugJump(beat: beatIndex(hero, "training"), stage: "finish")
        XCTAssertEqual(p.specialIcon, .banner)
    }
}
