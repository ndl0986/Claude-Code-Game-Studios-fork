import XCTest
@testable import GameCore

/// G2 (slice blocker): reach-the-flag encounters must be finishable by simple touch strategies.
final class G2Tests: XCTestCase {
    /// combat AC23's strategies: 0 hold ▶ and tap 2/s; 1 alternate ▶ for ½ s and a tap; 2 stand still and tap 2/s
    /// (▶ is held only while no fight holds the camera, so the hero reaches each encounter).
    func run(_ strat: Int) throws -> Double {
        let c = try ContentSet.load(dataRoot: Repo.data)
        var p = PlayState(tuning: c.tuning, beats: realHero(c).mission.beats, seed: 1)
        p.debugJump(beat: 3, stage: nil)
        var steps = 0
        while p.phase == .beatPlay && steps < 60 * 900 {
            let tap: Set<PadAction> = steps % 30 == 0 ? [.attack] : []
            var i: StepInput
            switch strat {
            case 0: i = StepInput(held: [.right], tapped: tap)
            case 1: i = (steps / 30) % 2 == 0 ? StepInput(held: [.right]) : StepInput(tapped: steps % 30 == 0 ? [.attack] : [])
            default: i = StepInput(held: p.locked ? [] : [.right], tapped: tap)
            }
            p.update(1.0 / 60, i); steps += 1
        }
        XCTAssertNotEqual(p.phase, .beatPlay, "strategy \(strat) finishes")
        return Double(steps) / 60
    }

    func test_combat_AC23_three_touch_strategies_finish_the_tqt_reach_beat_within_60s() throws {
        for s in 0..<3 { let t = try run(s); print("G2 strategy \(s): \(t) s"); XCTAssertLessThanOrEqual(t, 60) }
    }

    func test_rule1_hero_clamped_inside_the_lock_by_enemy_reach() throws {
        let c = try ContentSet.load(dataRoot: Repo.data)
        var p = PlayState(tuning: c.tuning, beats: realHero(c).mission.beats, seed: 1)
        p.debugJump(beat: 3, stage: "encounter")
        p.update(1.0 / 60, StepInput())
        XCTAssertTrue(p.locked)
        for _ in 0..<600 { p.update(1.0 / 60, StepInput(held: [.right])) }
        XCTAssertEqual(p.hero.x, p.lockX + 1280 - c.tuning["enemy_reach"] - c.tuning["hero_edge_margin"], accuracy: 0.001)
    }

    func test_rule2_and_2b_a_swing_faces_the_nearest_enemy_and_holding_right_keeps_it() throws {
        let c = try ContentSet.load(dataRoot: Repo.data)
        var p = PlayState(tuning: c.tuning, beats: realHero(c).mission.beats, seed: 1)
        p.debugJump(beat: 3, stage: "encounter")
        p.update(1.0 / 60, StepInput())
        p.enemies = [Enemy(id: 7, kind: .spear, x: p.hero.x - 120, face: 1, state: .rest, t: 0, hits: 0, kb: 0, moving: false)]
        p.update(1.0 / 60, StepInput(held: [.right], tapped: [.attack]))
        XCTAssertEqual(p.hero.face, -1, "faces the enemy behind")
        for _ in 0..<12 { p.update(1.0 / 60, StepInput(held: [.right])) }
        XCTAssertEqual(p.enemies.first?.hits, 1, "the swing lands though ▶ is held")
    }
}
