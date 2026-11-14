import XCTest
@testable import GameCore

/// The real Trần Quốc Toản mission: walk, hold-meter, training, reach-the-flag (mission-flow GDD).
final class BeatTypeTests: XCTestCase {
    let dt = 1.0 / 60
    var content: ContentSet!
    var hero: HeroContent!
    override func setUpWithError() throws { content = try ContentSet.load(dataRoot: Repo.data); hero = realHero(content) }
    func fresh() -> PlayState { PlayState(tuning: content.tuning, beats: hero.mission.beats, seed: 1) }
    func run(_ p: inout PlayState, _ n: Int, _ i: StepInput = StepInput()) { for _ in 0..<n { p.update(dt, i) } }

    func test_missionflow_AC20_F5_beat_positions_for_the_tqt_data() {
        let p = fresh()
        let types = hero.mission.beats.map(\.type)
        let expected: [Double]
        switch (types.count, content.tuning["beat_gap"]) {
        case (5, 800): expected = [900, 2980, 3780, 4580, 6580]      // TASK-016a: walk 1 screen + the Bình Than dialogue
        case (4, 800): expected = [900, 5540, 6340, 8340]             // TASK-005i: beat_gap 800
        default: expected = [900, 6340, 7940, 10740]                  // beat_gap 1600
        }
        XCTAssertEqual((0..<types.count).map { p.beatX($0) }, expected, "\(types)")
    }

    func test_missionflow_non_fight_beats_get_a_card_first_and_pads_follow_the_phase() {
        var p = fresh()
        XCTAssertEqual(p.visiblePads, [.left, .right], "walk_to = move only")
        while p.phase == .walkTo { p.update(dt, StepInput(held: [.right])) }
        XCTAssertEqual(p.phase, .beatCard)
        XCTAssertEqual(p.visiblePads, [], "story boxes: no pads")
        XCTAssertEqual(p.cardTexts.count, 1 + hero.mission.beats[beatIndex(hero, "walk")].scene.count, "scene lines, then the goal (title is the header)")
        for _ in p.cardTexts { p.cardNext() }
        XCTAssertEqual(p.phase, .beatPlay)
        XCTAssertEqual(p.visiblePads, [.left, .right], "exactly the beat's buttons (AC3)")
    }

    func test_missionflow_AC4_walk_ends_after_F2_time() {
        var p = fresh()
        p.debugJump(beat: beatIndex(hero, "walk"), stage: nil)
        let len = hero.mission.beats[beatIndex(hero, "walk")].params.lengthScreens!
        var steps = 0
        while p.phase == .beatPlay { p.update(dt, StepInput(held: [.right])); steps += 1 }
        XCTAssertEqual(Double(steps) * dt, len * 1280 / content.tuning["hero_speed"], accuracy: 0.1)
    }

    func test_missionflow_AC5_hold_meter_fills_only_while_held_and_never_drains() {
        var p = fresh()
        p.debugJump(beat: beatIndex(hero, "hold-meter"), stage: nil)
        let need = hero.mission.beats[beatIndex(hero, "hold-meter")].params.holdSeconds!
        run(&p, 72, StepInput(held: [.special]))                  // 1.2 s
        let m = p.meter
        XCTAssertEqual(m, 1.2 / need, accuracy: 0.02)
        run(&p, 180)                                               // released 3 s
        XCTAssertEqual(p.meter, m, "no drain")
        var more = 0
        while p.phase == .beatPlay { p.update(dt, StepInput(held: [.special])); more += 1 }
        XCTAssertEqual(Double(more) * dt, need - 1.2, accuracy: 2 * dt)
    }

    func test_hints_hold_hand_until_the_meter_passes_25_percent() {
        var p = fresh()
        p.debugJump(beat: beatIndex(hero, "hold-meter"), stage: nil)
        XCTAssertEqual(p.hand, .holdSpecial)
        while p.meter <= 0.25 { p.update(dt, StepInput(held: [.special])) }
        XCTAssertNil(p.hand)
    }

    func test_missionflow_AC6_training_runs_dummies_then_blocks_then_special_and_early_special_does_nothing() {
        var p = fresh()
        p.debugJump(beat: beatIndex(hero, "training"), stage: nil)
        XCTAssertEqual(p.trainingStage, .dummies)
        p.update(dt, StepInput(tapped: [.special]))
        XCTAssertEqual(p.trainingStage, .dummies, "early special does nothing")
        var step = 0
        while p.trainingStage == .dummies && step < 6000 { p.update(dt, botInput(p, step: step)); step += 1 }
        XCTAssertTrue(p.dummies.allSatisfy(\.hit))
        XCTAssertEqual(p.trainingStage, .blocks)
        XCTAssertNotNil(p.partner)
        while p.trainingStage == .blocks && step < 12000 { p.update(dt, StepInput(held: [.defend])); step += 1 }
        XCTAssertEqual(p.blocksDone, hero.mission.beats[beatIndex(hero, "training")].params.blocks)
        XCTAssertEqual(p.trainingStage, .special)
        p.update(dt, StepInput(tapped: [.special]))
        XCTAssertEqual(p.phase, .beatEnd)
    }

    func test_missionflow_AC21_a_training_block_counts_only_if_defend_is_held_at_strike_resolve() {
        var p = fresh()
        p.debugJump(beat: beatIndex(hero, "training"), stage: nil)
        var step = 0
        while p.trainingStage == .dummies && step < 6000 { p.update(dt, botInput(p, step: step)); step += 1 }
        // wait for a windup, press defend briefly during it, release before the strike
        while p.partner?.state != .windup { p.update(dt, StepInput()) }
        p.update(dt, StepInput(held: [.defend]))
        let hx = p.hero.x
        while p.partner?.state == .windup { p.update(dt, StepInput()) }
        XCTAssertEqual(p.blocksDone, 0, "released before the strike: not a block")
        XCTAssertNotEqual(p.hero.x, hx, "a miss is a pushback")
        while p.partner?.state != .windup { p.update(dt, StepInput()) }
        while p.partner?.state == .windup { p.update(dt, StepInput(held: [.defend])) }
        XCTAssertEqual(p.blocksDone, 1)
    }

    func test_missionflow_AC7_reach_encounter_locks_the_camera_until_cleared_then_flag_ends_it() {
        var p = fresh()
        p.debugJump(beat: beatIndex(hero, "reach-the-flag"), stage: nil)
        let b = hero.mission.beats[beatIndex(hero, "reach-the-flag")]
        let firstAt = p.xStart + b.params.encounters![0].atScreen * 1280
        while p.hero.x < firstAt { p.update(dt, StepInput(held: [.right])) }
        p.update(dt, StepInput(held: [.right]))
        XCTAssertTrue(p.locked)
        let lockX = p.lockX
        XCTAssertEqual(lockX, firstAt - content.tuning["lock_offset"], accuracy: content.tuning["hero_speed"] * dt * 2, "trigger x − lock_offset")
        var step = 0
        while p.locked && step < 36000 { p.update(dt, botInput(p, step: step)); step += 1 }
        XCTAssertEqual(p.encounterIndex, 1)
        botRunUntil(&p) { $0.phase != .beatPlay }
        XCTAssertGreaterThanOrEqual(p.hero.x, p.xStart + b.params.lengthScreens! * 1280)
    }

    func test_combat_AC19_resume_restarts_a_windup() {
        var p = fresh()
        p.debugJump(beat: beatIndex(hero, "reach-the-flag"), stage: nil)
        p.enemies.append(Enemy(id: 5, kind: .spear, x: p.hero.x + 140, face: -1, state: .windup, t: 0.9, hits: 0, kb: 0, moving: false))
        p.resetHintTimers()
        XCTAssertEqual(p.enemies.last!.t, 0)
    }

    func test_the_whole_tqt_mission_plays_to_the_end() {
        var p = fresh()
        let steps = botRun(&p)
        XCTAssertTrue(p.finished)
        XCTAssertLessThan(Double(steps) * dt, 600)
    }

    func botRunUntil(_ p: inout PlayState, _ done: (PlayState) -> Bool) {
        var step = 0
        while !done(p) && step < 36000 { p.update(dt, botInput(p, step: step)); step += 1 }
    }
}

/// D-07 skip, warning and medal; D-16 progression (Hero progression GDD).
final class SkipAndProgressTests: XCTestCase {
    func game(_ store: MemoryStore = MemoryStore()) throws -> Game {
        let c = try ContentSet.load(dataRoot: Repo.data)
        return Game(content: c, hero: realHero(c), store: store, isDebug: true)
    }
    func wait(_ g: Game, _ s: Double) { for _ in 0..<Int(s * 60) { g.step(1.0 / 60, StepInput()) } }

    func test_skip_warns_keep_reading_closes_and_it_comes_back_skip_anyway_ends_only_the_section() throws {
        let g = try game()
        g.start()
        XCTAssertTrue(g.canSkip)
        g.skip(); XCTAssertTrue(g.skipWarning)
        g.keepReading(); XCTAssertFalse(g.skipWarning); XCTAssertEqual(g.screen, .intro)
        g.skip(); XCTAssertTrue(g.skipWarning, "the warning comes back after Keep reading")
        g.skipAnyway()
        XCTAssertEqual(g.screen, .play, "only the intro section ended")
        XCTAssertTrue(g.skipped)
        for _ in 0..<600 where g.play.phase == .walkTo { g.step(1.0 / 60, StepInput(held: [.right])) }
        XCTAssertEqual(g.play.phase, .beatCard)
        g.skip()
        XCTAssertFalse(g.skipWarning, "one warning per run after Skip anyway")
        XCTAssertEqual(g.play.phase, .beatPlay)
    }

    func test_no_warning_once_the_medal_is_earned_and_the_medal_is_never_lost() throws {
        let store = MemoryStore()
        store.set(true, forKey: "medal.tran-quoc-toan")
        let g = try game(store)
        g.start(); g.skip()
        XCTAssertFalse(g.skipWarning)
        XCTAssertEqual(g.screen, .play)
        g.startQuiz()
        while g.screen == .quiz {
            let q = g.quiz!; g.answer(q.order.firstIndex(of: q.current.correctIndex)!); wait(g, 1); g.next()
        }
        XCTAssertTrue(g.medalEarned, "gold: earned in an earlier run")
        XCTAssertFalse(g.medalNew, "ui.medal.earned only in the run that earns it")
        XCTAssertEqual(store.values["medal.tran-quoc-toan"] as? Bool, true)
    }

    func test_quiz_finish_saves_completed_stars_medal_and_seen_open_before_results() throws {
        let store = MemoryStore()
        let g = try game(store)
        XCTAssertEqual(store.values["seen_open.tran-quoc-toan"] as? Bool, true, "title load saves every open hero")
        g.startQuiz()
        while g.screen == .quiz {
            let q = g.quiz!; g.answer(q.order.firstIndex(of: q.current.correctIndex)!); wait(g, 1); g.next()
        }
        XCTAssertEqual(g.screen, .results)
        XCTAssertEqual(store.values["completed.tran-quoc-toan"] as? Bool, true)
        XCTAssertEqual(store.values["stars.tran-quoc-toan"] as? Int, 3)
        XCTAssertNil(g.unlockedHero, "no next hero: more heroes are coming")
        wait(g, 0.3); g.next(); XCTAssertEqual(g.screen, .title)
    }

    func test_progression_open_rules() throws {
        let c = try ContentSet.load(dataRoot: Repo.data, extraHeroDirs: [Repo.sample])
        let pr = Progression(heroes: c.heroes) { _ in true }
        XCTAssertEqual(pr.order, ["tran-quoc-toan", "sample"], "timeline_order 10, then 999")
        var p = Progress()
        XCTAssertTrue(pr.isOpen("tran-quoc-toan", p), "the first hero is always open")
        XCTAssertFalse(pr.isOpen("sample", p))
        p.completed.insert("tran-quoc-toan")
        XCTAssertTrue(pr.isOpen("sample", p), "opens when the previous hero is completed")
        var q = Progress(); q.seenOpen.insert("sample")
        XCTAssertTrue(pr.isOpen("sample", q), "seen open never re-locks")
        let hidden = Progression(heroes: c.heroes) { $0.mission.hero.id != "tran-quoc-toan" }
        XCTAssertTrue(hidden.isOpen("sample", Progress()), "unplayable heroes are skipped")
    }
}

/// Parity with Android (delta review of 00f402d).
final class ParityTests: XCTestCase {
    let dt = 1.0 / 60
    func test_partner_first_windup_after_approach_min_time_and_encounter_lock_at_exact_trigger() throws {
        let c = try ContentSet.load(dataRoot: Repo.data)
        let hero = realHero(c)
        var p = PlayState(tuning: c.tuning, beats: hero.mission.beats, seed: 1)
        p.debugJump(beat: beatIndex(hero, "training"), stage: "blocks")
        XCTAssertEqual(p.partner?.state, .rest)
        var steps = 0
        while p.partner?.state != .windup { p.update(dt, StepInput()); steps += 1 }
        XCTAssertEqual(Double(steps) * dt, c.tuning["approach_min_time"], accuracy: dt)

        var r = PlayState(tuning: c.tuning, beats: hero.mission.beats, seed: 1)
        r.debugJump(beat: beatIndex(hero, "reach-the-flag"), stage: nil)
        let trigger = r.xStart + hero.mission.beats[beatIndex(hero, "reach-the-flag")].params.encounters![0].atScreen * 1280
        while !r.locked { r.update(dt, StepInput(held: [.right])) }
        XCTAssertEqual(r.lockX, trigger - c.tuning["lock_offset"])
    }
}

extension ParityTests {
    func test_holding_the_flag_in_hold_meter_does_not_suppress_trainings_tap_hand() throws {
        let c = try ContentSet.load(dataRoot: Repo.data)
        var p = PlayState(tuning: c.tuning, beats: realHero(c).mission.beats, seed: 1)
        p.debugJump(beat: beatIndex(realHero(c), "hold-meter"), stage: nil)
        while p.phase == .beatPlay { p.update(dt, StepInput(held: [.special])) }
        XCTAssertTrue(p.tut.holdPast25); XCTAssertFalse(p.tut.specialTapped)
        let t = p.tut
        p.debugJump(beat: beatIndex(realHero(c), "training"), stage: "blocks")
        p.tut.holdPast25 = t.holdPast25; p.tut.specialTapped = false; p.tut.blocked = true
        while p.trainingStage == .blocks { p.update(dt, StepInput(held: [.defend])) }
        XCTAssertEqual(p.hand, .special, "the tap hand still teaches training's finish")
    }

    func test_the_last_dummy_moves_training_to_blocks_in_the_same_frame() throws {
        let c = try ContentSet.load(dataRoot: Repo.data)
        var p = PlayState(tuning: c.tuning, beats: realHero(c).mission.beats, seed: 1)
        p.debugJump(beat: beatIndex(realHero(c), "training"), stage: nil)
        var step = 0
        while p.trainingStage == .dummies && step < 6000 {
            let before = p.dummies.filter(\.hit).count
            p.update(dt, botInput(p, step: step)); step += 1
            if p.dummies.filter(\.hit).count == p.dummies.count && before < p.dummies.count {
                XCTAssertEqual(p.trainingStage, .blocks, "same frame as the last hit")
            }
        }
    }
}

/// The dialogue beat (mission-flow 7d; TASK-016 Bình Than exchange).
final class DialogueTests: XCTestCase {
    let dt = 1.0 / 60
    func setup() throws -> (Game, Int) {
        let c = try ContentSet.load(dataRoot: Repo.data)
        let h = realHero(c)
        let g = Game(content: c, hero: h, store: MemoryStore(), isDebug: true)
        return (g, beatIndex(h, "dialogue"))
    }
    func wait(_ g: Game, _ s: Double) { for _ in 0..<Int(s * 60) { g.step(dt, StepInput()) } }

    func test_missionflow_AC23_ask_replaces_next_for_exactly_its_taps_and_no_pads_show() throws {
        let (g, i) = try setup()
        g.debugStart(screen: "play", q: nil, beat: i + 1, stage: nil, stars: nil)
        XCTAssertEqual(g.play.phase, .dialogueLine, "no beat card for dialogue")
        let lines = g.play.dialogueLines.count, ask = g.play.currentBeat!.params.ask!
        var kinds: [String] = []
        while g.play.phase == .dialogueLine {
            XCTAssertTrue(g.play.visiblePads.isEmpty)
            kinds.append(g.play.askShowing ? "ask" : "tiep")
            wait(g, 0.3)
            if g.play.askShowing { g.next(); XCTAssertTrue(g.play.askShowing, "Next is ignored while ask shows"); g.ask() } else { g.next() }
        }
        XCTAssertEqual(kinds, ContentValidator.askButtons(lines: lines, taps: ask.taps, atLine: ask.atLine))
        XCTAssertEqual(g.play.asksDone, ask.taps)
        XCTAssertEqual(g.play.phase, .beatEnd)
    }

    func test_missionflow_AC25_skipping_a_dialogue_costs_the_medal() throws {
        let (g, i) = try setup()
        g.debugStart(screen: "play", q: nil, beat: i + 1, stage: nil, stars: nil)
        XCTAssertTrue(g.canSkip)
        g.skip(); g.skipAnyway()
        XCTAssertTrue(g.skipped)
        XCTAssertEqual(g.play.phase, .beatEnd)
    }

    func test_ask_hint_after_hint_delay() throws {
        let (g, i) = try setup()
        g.debugStart(screen: "play", q: nil, beat: i + 1, stage: "ask", stars: nil)
        XCTAssertTrue(g.play.askShowing)
        XCTAssertFalse(g.play.askHint)
        for _ in 0..<301 { g.step(dt, StepInput()) }
        XCTAssertTrue(g.play.askHint)
    }
}
