import XCTest
@testable import GameCore

/// Combat GDD Rule 15b / AC24 (TASK-020a): in a training beat the camera follows right but never past
/// cap = max(cam, xStart − hero_edge_margin), and the hero is stopped at cap + W − enemy_reach −
/// hero_edge_margin, so a child holding ▶ can't walk past the dummies and softlock the beat (iOS QC r3).
final class TrainingCapTests: XCTestCase {
    var content: ContentSet!
    var hero: HeroContent!
    let dt = 1.0 / 60

    override func setUpWithError() throws { content = try ContentSet.load(dataRoot: Repo.data); hero = realHero(content) }

    func training() -> PlayState {
        var p = PlayState(tuning: content.tuning, beats: hero.mission.beats, seed: 1)
        p.debugJump(beat: beatIndex(hero, "training"), stage: nil)
        return p
    }

    /// AC24 worked example: ▶ held for 5 s → the camera stops at xStart − 70, the hero at xStart + 990,
    /// with no jump or snap on the way; every dummy stays on screen.
    func test_holding_right_stops_the_camera_and_hero_at_the_cap_without_a_jump() {
        var p = training()
        let t = content.tuning, xs = p.xStart
        let cap = xs - t["hero_edge_margin"], heroMax = cap + 1280 - t["enemy_reach"] - t["hero_edge_margin"]
        var lastCam = p.cam, lastX = p.hero.x
        for _ in 0..<Int(5 / dt) {
            p.update(dt, StepInput(held: [.right]))
            XCTAssertGreaterThanOrEqual(p.cam, lastCam, "the camera never moves left")
            XCTAssertLessThanOrEqual(p.cam, cap + 1e-9, "the camera never passes the cap")
            XCTAssertLessThanOrEqual(p.hero.x, heroMax + 1e-9, "the hero never passes the right limit")
            XCTAssertLessThanOrEqual(abs(p.hero.x - lastX), t["hero_speed"] * dt + 1e-9, "no jump: the hero is stopped, never moved")
            lastCam = p.cam; lastX = p.hero.x
        }
        XCTAssertEqual(p.cam, cap, accuracy: 1e-9)
        XCTAssertEqual(p.hero.x, heroMax, accuracy: 1e-9)
        XCTAssertEqual(heroMax - xs, 990, accuracy: 1e-9, "TQT defaults: the hero is limited to xStart + 990")
        for d in p.dummies { XCTAssertTrue(d.x >= p.cam && d.x <= p.cam + 1280, "dummy at \(d.x) on screen") }
    }

    /// The softlock bot: ▶ for 1, 3, 5 or 8 s at the start of training, then the bot finishes the beat.
    func test_training_can_always_be_finished_after_holding_right() {
        for secs in [1.0, 3, 5, 8] {
            var p = training()
            for _ in 0..<Int(secs / dt) { p.update(dt, StepInput(held: [.right])) }
            var step = 0
            while p.phase == .beatPlay && step < 60 * 120 { p.update(dt, botInput(p, step: step)); step += 1 }
            XCTAssertNotEqual(p.phase, .beatPlay, "▶ \(secs) s: training finishes (stage \(p.trainingStage))")
        }
    }

    /// The cap ends with the beat: the next beat's walk scrolls freely again.
    func test_the_cap_is_released_when_the_training_beat_ends() {
        var p = training()
        var step = 0
        while p.phase != .walkTo && step < 60 * 180 { p.update(dt, botInput(p, step: step)); step += 1 }
        XCTAssertEqual(p.phase, .walkTo)
        XCTAssertNil(p.trainCap)
        let cam = p.cam
        for _ in 0..<Int(3 / dt) { p.update(dt, StepInput(held: [.right])) }
        XCTAssertGreaterThan(p.cam, cam, "free scroll after training")
    }
}

/// Mission flow Rule 7c (TASK-020 W12): training shows only the pads its current step uses.
final class TrainingPadsTests: XCTestCase {
    func test_training_pads_appear_step_by_step() throws {
        let c = try ContentSet.load(dataRoot: Repo.data), h = realHero(c)
        var p = PlayState(tuning: c.tuning, beats: h.mission.beats, seed: 1)
        p.debugJump(beat: beatIndex(h, "training"), stage: nil)
        XCTAssertEqual(p.trainingStage, .dummies)
        XCTAssertEqual(p.visiblePads, [.left, .right, .attack], "dummies: move + attack")
        var step = 0
        while p.trainingStage == .dummies && step < 6000 { p.update(1.0 / 60, botInput(p, step: step)); step += 1 }
        XCTAssertEqual(p.trainingStage, .blocks)
        XCTAssertEqual(p.visiblePads, [.left, .right, .attack, .defend], "blocks: + defend")
        while p.trainingStage == .blocks && step < 12000 { p.update(1.0 / 60, StepInput(held: [.defend])); step += 1 }
        XCTAssertEqual(p.trainingStage, .special)
        XCTAssertEqual(p.visiblePads, [.left, .right, .attack, .defend, .special], "finish: + special")
    }

    /// A hidden pad does nothing: defend held during the dummies step never raises the guard.
    func test_a_hidden_pad_is_filtered_out() throws {
        let c = try ContentSet.load(dataRoot: Repo.data), h = realHero(c)
        var p = PlayState(tuning: c.tuning, beats: h.mission.beats, seed: 1)
        p.debugJump(beat: beatIndex(h, "training"), stage: nil)
        for _ in 0..<10 { p.update(1.0 / 60, StepInput(held: [.defend])) }
        XCTAssertFalse(p.hero.def, "defend is hidden during the dummies")
    }
}
