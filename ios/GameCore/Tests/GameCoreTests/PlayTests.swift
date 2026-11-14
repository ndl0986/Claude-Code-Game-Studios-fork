import XCTest
@testable import GameCore

/// Combat and hint rules (design/gdd/side-scroll-combat.md, hints-and-onboarding.md), at dt = 1/60.
final class PlayTests: XCTestCase {
    let dt = 1.0 / 60
    var content: ContentSet!
    override func setUpWithError() throws { content = try Repo.contentSet() }
    var tuning: Tuning { content.tuning }
    var beats: [Beat] { Repo.sampleHero(content).mission.beats }

    func fresh() -> PlayState { PlayState(tuning: tuning, beats: beats, seed: tuning.seed) }

    /// A play state in beat 1's fight with one spear in front of the hero, as the debug jump makes it.
    func oneEnemy(_ state: Enemy.State = .approach, kind: FightParams.Kind = .spear, dx: Double? = nil) -> PlayState {
        var p = fresh()
        p.debugJump(beat: 0, stage: "telegraph")
        p.enemies[0] = Enemy(id: 99, kind: kind, x: p.hero.x + (dx ?? tuning["enemy_reach"] - tuning["stand_gap"]), face: -1, state: state)
        p.enemies[0].moving = false
        return p
    }

    func run(_ p: inout PlayState, steps: Int, _ input: StepInput = StepInput()) { for _ in 0..<steps { p.update(dt, input) } }

    func test_combat_AC1_two_hits_make_a_spear_flee_with_hurt_between() {
        var p = oneEnemy(.approach, dx: 100)
        p.update(dt, StepInput(tapped: [.attack]))
        run(&p, steps: 12)                                          // the hit lands at 0.45 × 0.28 s
        XCTAssertEqual(p.enemies[0].state, .hurt)
        XCTAssertEqual(p.enemies[0].hits, 1)
        run(&p, steps: 30)
        p.enemies[0].x = p.hero.x + 100
        p.update(dt, StepInput(tapped: [.attack]))
        run(&p, steps: 12)
        XCTAssertEqual(p.enemies[0].state, .flee)
        XCTAssertEqual(p.dropped.count, 1)
    }

    func test_combat_AC2_and_AC16_first_spawn_waits_then_spawn_gap_and_max_active() {
        var p = fresh()
        p.debugJump(beat: 2, stage: nil)                            // beat 3: 4 enemies, max_active 2
        XCTAssertTrue(p.enemies.isEmpty)
        var firstSpawn = 0
        while p.enemies.isEmpty { p.update(dt, StepInput()); firstSpawn += 1 }
        XCTAssertEqual(Double(firstSpawn) * dt, tuning["first_spawn_delay"], accuracy: 2 * dt, "first walk-in after first_spawn_delay")
        var second = 0
        while p.enemies.count < 2 { p.update(dt, StepInput()); second += 1 }
        XCTAssertEqual(Double(second) * dt, tuning["spawn_gap"], accuracy: 2 * dt, "then one per spawn_gap")
        var maxActive = 0
        for _ in 0..<600 { p.update(dt, StepInput()); maxActive = max(maxActive, p.enemies.filter { $0.state != .flee }.count) }
        XCTAssertEqual(maxActive, 2)
    }

    func test_combat_AC3_never_two_enemies_in_windup_or_strike() {
        var p = fresh()
        p.debugJump(beat: 2, stage: nil)
        for _ in 0..<1800 {
            p.update(dt, StepInput())
            XCTAssertLessThanOrEqual(p.enemies.filter { $0.state == .windup || $0.state == .strike }.count, 1)
        }
    }

    func test_combat_AC4_windup_strikes_after_telegraph_and_defend_blocks() {
        var p = oneEnemy(.windup)
        let steps = Int((tuning["telegraph"] / dt).rounded(.up))
        run(&p, steps: steps - 1, StepInput(held: [.defend]))
        XCTAssertEqual(p.enemies[0].state, .windup)
        run(&p, steps: 1, StepInput(held: [.defend]))
        XCTAssertEqual(p.enemies[0].state, .strike)
        XCTAssertTrue(p.tut.blocked)
        XCTAssertEqual(p.enemies[0].kb, tuning["block_knock"], "pushed block_knock away from the hero")
    }

    func test_combat_leader_telegraphs_longer() {
        var p = oneEnemy(.windup, kind: .leader)
        run(&p, steps: Int((tuning["telegraph"] / dt).rounded(.up)) + 1)
        XCTAssertEqual(p.enemies[0].state, .windup, "leader × leader_telegraph_mul")
    }

    func test_combat_AC5_unblocked_strike_pushes_the_hero_who_keeps_control() {
        var p = oneEnemy(.windup)
        let hx = p.hero.x
        run(&p, steps: Int((tuning["telegraph"] / dt).rounded(.up)))
        XCTAssertEqual(p.hero.x, hx - tuning["hero_pushback"], accuracy: 0.001)
        XCTAssertGreaterThan(p.hero.hurt, 0)
        let x1 = p.hero.x
        p.update(dt, StepInput(held: [.left]))
        XCTAssertLessThan(p.hero.x, x1, "moves during the flash")
    }

    func test_combat_AC6_and_AC17_a_hit_on_the_frame_the_windup_ends_cancels_the_strike() {
        var p = oneEnemy(.windup, dx: 100)
        let steps = Int((tuning["telegraph"] / dt).rounded(.up))
        let hitAfter = Int((tuning["attack_hit_at"] * tuning["attack_time"] / dt).rounded(.up))
        run(&p, steps: steps - hitAfter - 1)
        p.update(dt, StepInput(tapped: [.attack]))
        let hx = p.hero.x
        run(&p, steps: hitAfter + 1)
        XCTAssertNotEqual(p.enemies[0].state, .strike)
        XCTAssertEqual(p.hero.x, hx, accuracy: 0.001, "no push")
        XCTAssertFalse(p.tut.blocked, "nothing blocked")
    }

    func test_combat_AC7_hit_test_boundaries() {
        for (dx, hit) in [(175.0, true), (-49.0, true), (-51.0, false)] {
            var p = oneEnemy(.rest, dx: dx)
            p.hero.face = 1
            p.update(dt, StepInput(tapped: [.attack]))
            // keep it in place until the hit check
            for _ in 0..<12 { p.enemies[0].x = p.hero.x + dx; p.update(dt, StepInput()) }
            XCTAssertEqual(p.enemies[0].hits == 1, hit, "dx \(dx)")
        }
    }

    func test_combat_AC8_knockback_plays_out_to_170_or_85() {
        for (kind, dist) in [(FightParams.Kind.spear, 170.0), (.leader, 85.0)] {
            var p = oneEnemy(.rest, kind: kind, dx: 100)
            p.update(dt, StepInput(tapped: [.attack]))
            var x0 = 0.0
            for _ in 0..<12 { x0 = p.enemies[0].x; p.update(dt, StepInput()); if p.enemies[0].kb != 0 { break } }
            p.enemies[0].state = .flee; p.enemies[0].face = 0 // freeze its own walking; only knock-back moves it
            run(&p, steps: 120)
            XCTAssertEqual(p.enemies[0].x - x0, dist, accuracy: 2, "\(kind)")
        }
    }

    func test_combat_AC9_fight_ends_only_after_the_fleeing_enemy_is_gone_then_caption() {
        var p = oneEnemy(.rest, dx: 100)
        p.queue = []
        p.enemies[0].hits = Int(tuning["hp_spear"]) - 1
        p.update(dt, StepInput(tapped: [.attack]))
        run(&p, steps: 12)
        XCTAssertEqual(p.enemies[0].state, .flee)
        XCTAssertEqual(p.phase, .beatPlay)
        run(&p, steps: 600)
        XCTAssertEqual(p.phase, .caption)
    }

    func test_combat_AC10_and_AC18_defend_blocks_moving_and_drops_the_attack_tap() {
        var p = oneEnemy(.rest, dx: 400)
        let x = p.hero.x
        p.update(dt, StepInput(held: [.defend, .right], tapped: [.attack]))
        XCTAssertEqual(p.hero.x, x)
        XCTAssertEqual(p.hero.atk, -1)
        p.update(dt, StepInput())
        XCTAssertEqual(p.hero.atk, -1, "the tap was dropped, not queued")
    }

    func test_hints_AC4_stuck_arrow_shows_on_step_301_not_300() {
        var p = oneEnemy(.rest, dx: 400)
        p.enemies[0].state = .flee; p.enemies[0].face = 0 // nothing changes; only the stall timer runs
        p.tut = Tutorial(moved: true, hit: true, blocked: true, windupSeen: true, enemySeen: true)
        run(&p, steps: 300)
        XCTAssertFalse(p.stalled)
        run(&p, steps: 1)
        XCTAssertTrue(p.stalled)
    }

    func test_hints_AC5_a_hit_and_resume_reset_the_stuck_timer() {
        var p = oneEnemy(.rest, dx: 100)
        run(&p, steps: 301)
        XCTAssertTrue(p.stalled)
        p.resetHintTimers()
        XCTAssertFalse(p.stalled)
        run(&p, steps: 301)
        p.enemies[0].x = p.hero.x + 100
        p.update(dt, StepInput(tapped: [.attack]))
        run(&p, steps: 12)
        XCTAssertFalse(p.stalled, "a hit resets it")
    }

    func test_hints_AC1_to_AC3_hand_order_move_then_attack_then_defend() {
        var p = fresh()
        XCTAssertEqual(p.hand, .right)
        p.update(dt, StepInput(held: [.right]))
        XCTAssertNil(p.hand)
        p.debugJump(beat: 0, stage: "telegraph")
        p.tut = Tutorial(moved: true, hit: false, blocked: false, windupSeen: true, enemySeen: true)
        XCTAssertEqual(p.hand, .attack, "attack outranks defend")
        p.tut.hit = true
        XCTAssertEqual(p.hand, .defend, "defend only during a windup")
        p.enemies[0].state = .rest
        XCTAssertNil(p.hand)
    }

    func test_walk_hint_counts_idle_and_any_movement_resets_it() {
        var p = fresh()
        p.tut.moved = true
        p.update(dt, StepInput(held: [.right]))
        run(&p, steps: 300)
        XCTAssertFalse(p.rightPulse)
        run(&p, steps: 1)
        XCTAssertTrue(p.rightPulse, "idle > hint_delay while walking pulses ▶ (prototype)")
        p.update(dt, StepInput(held: [.left]))
        XCTAssertFalse(p.rightPulse, "any movement resets it")
        XCTAssertFalse(p.goArrow, "no go-arrow before beat 1")
    }

    func test_combat_AC14_the_whole_sample_mission_can_be_cleared_with_no_fail_state() {
        var p = fresh()
        let step = botRun(&p)
        XCTAssertTrue(p.finished, "no fail state: combat AC14")
        XCTAssertLessThan(Double(step) * dt, 4 * 120, "each fight within 2 minutes")
    }

    func test_a_seeded_run_is_deterministic() {
        func runOnce() -> (Double, [Double], Int) {
            var p = fresh()
            for s in 0..<3000 { p.update(dt, StepInput(held: s % 300 < 200 ? [.right] : [.defend], tapped: s % 31 == 0 ? [.attack] : [], confirm: p.phase == .caption)) }
            return (p.hero.x, p.enemies.map(\.x), p.beat)
        }
        let a = runOnce(), b = runOnce()
        XCTAssertEqual(a.0, b.0); XCTAssertEqual(a.1, b.1); XCTAssertEqual(a.2, b.2)
    }
}
