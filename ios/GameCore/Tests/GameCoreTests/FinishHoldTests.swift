import XCTest
@testable import GameCore

/// Mission flow Rule 7c (r9–r11) / AC32–34: the training finish's banner moment holds `finish_hold` (1.5 s) instead
/// of end_pause; pads hide and taps are dropped; the partner re-enters to its spot (front, else beyond the banner),
/// walks in linearly over the 0.67 s rise and faces the banner; every resume restarts the hold to "rise done";
/// training props are gone when the beat ends. Numbers shared with Android (trace 1.3).
final class FinishHoldTests: XCTestCase {
    var c: ContentSet!
    var hero: HeroContent!
    let dt = 1.0 / 60
    override func setUpWithError() throws { c = try ContentSet.load(dataRoot: Repo.data); hero = realHero(c) }

    /// The training finish step, the hero standing; returns the state just after the Cờ tap (the goal frame).
    func tapFlag(holdRight secs: Double = 0) -> PlayState {
        var p = PlayState(tuning: c.tuning, beats: hero.mission.beats, seed: 1)
        p.debugJump(beat: beatIndex(hero, "training"), stage: "finish")
        p.update(dt, StepInput())
        for _ in 0..<Int(secs / dt) { p.update(dt, StepInput(held: [.right])) } // against the training camera cap (15b)
        p.update(dt, StepInput(tapped: [.special]))
        return p
    }

    func test_finish_hold_is_a_required_tuning_key() {
        XCTAssertTrue(Tuning.requiredKeys.contains("finish_hold"))
        XCTAssertEqual(c.tuning["finish_hold"], 1.5)
    }

    func test_the_hold_lasts_finish_hold_with_pads_hidden_and_taps_dropped() {
        var p = tapFlag(holdRight: 5)
        XCTAssertEqual(p.phase, .beatEnd); XCTAssertNotNil(p.finishHold)
        XCTAssertTrue(p.visiblePads.isEmpty, "all pads hide at the Cờ tap")
        let x0 = p.hero.x, beat = p.beat
        var updates = 0
        // a tap every 0.2 s on every pad (Cờ's spot included) and ▶ held: nothing acts, nothing is carried over
        while p.phase == .beatEnd && updates < 600 {
            updates += 1
            let tap = updates % 12 == 0
            p.update(dt, StepInput(held: [.right, .defend], tapped: tap ? [.special, .attack, .left, .right] : []))
            if p.phase == .beatEnd { XCTAssertEqual(p.hero.x, x0, "the hero doesn't move in the hold"); XCTAssertFalse(p.hero.def) }
        }
        XCTAssertEqual(updates, 91, "dt sum reaches 1.5 on END update 91 (1.51666…), as on Android")
        XCTAssertEqual(p.beat, beat + 1); XCTAssertEqual(p.phase, .walkTo)
        XCTAssertNil(p.partner); XCTAssertTrue(p.dummies.isEmpty, "AC34: training props go with the beat"); XCTAssertNil(p.finishHold)
        XCTAssertLessThan(p.hero.atk, 0, "no swing carried into the walk")
        XCTAssertGreaterThanOrEqual(p.cam, p.hero.x - c.tuning["camera_follow_offset"] - 1e-9,
                                    "Android r12: the camera catches up in the update the beat ends, so the next theme never shows at the old capped view")
    }

    func test_other_beats_keep_end_pause() {
        var p = PlayState(tuning: c.tuning, beats: hero.mission.beats, seed: 1)
        p.debugJump(beat: beatIndex(hero, "hold-meter"), stage: nil)
        var n = 0
        while p.phase != .beatEnd && n < 6000 { p.update(dt, StepInput(held: [.special])); n += 1 }
        XCTAssertNil(p.finishHold)
        var updates = 0
        while p.phase == .beatEnd && updates < 600 { p.update(dt, StepInput()); updates += 1 }
        XCTAssertEqual(updates, 36, "end_pause 0.6 ends on update 36")
    }

    /// AC33 (a)–(d) and the trace's case; the spot formula.
    func test_the_partners_spot() {
        let r = c.tuning["enemy_reach"]
        // the trace 1.3 case: H 5044.3 facing left, cam 4514.5 → the front spot
        let t = PlayState.finishPartner(heroX: 5044.3, face: -1, cam: 4514.5, enemyReach: r)
        XCTAssertEqual(t.stand, 4934.3, accuracy: 1e-9); XCTAssertEqual(t.spawn, 4754.3, accuracy: 1e-9); XCTAssertEqual(t.face, 1)
        // (d) near the left edge facing left: beyond the banner, at H + 242, from 1.2 × reach further right, fading in
        let d = PlayState.finishPartner(heroX: 100, face: -1, cam: 0, enemyReach: r)
        XCTAssertEqual(d.stand, 342, accuracy: 1e-9); XCTAssertEqual(d.spawn, 342 + 1.2 * r, accuracy: 1e-9)
        XCTAssertEqual(d.face, -1, "faces left, toward the banner"); XCTAssertTrue(d.fadeIn)
        // (a) right edge facing right, (b) left edge facing right, (c) right edge facing left → the front spot
        for (h, f) in [(1050.0, 1.0), (100, 1), (1150, -1)] {
            let s = PlayState.finishPartner(heroX: h, face: f, cam: 0, enemyReach: r)
            XCTAssertEqual(s.stand, h + f * 110, accuracy: 1e-9, "screen x \(h) face \(f): the front spot")
        }
    }

    /// Mirrors Android's FinishHoldTest.thePartnerNeverOverlapsTheBannerOrTheHero: the partner's box (± 32) never
    /// overlaps the hero's (± 32) or the cloth's x-range, stays ≥ 8 on screen, and faces the banner.
    func test_the_partner_never_overlaps_the_banner_or_the_hero() {
        let r = c.tuning["enemy_reach"], cam = 2000.0
        for sx in [60.0, 200, 640, 1000, 1045, 1090, 1220] {
            for f in [1.0, -1.0] {
                let h = cam + sx, s = PlayState.finishPartner(heroX: h, face: f, cam: cam, enemyReach: r)
                let bx = h - f * 125, cl = bx - 55, cr = bx + 77
                XCTAssertGreaterThanOrEqual(abs(s.stand - h), 64, "x \(sx) f \(f): clear of the hero")
                XCTAssertFalse(s.stand + 32 > cl - 8 && s.stand - 32 < cr + 8, "x \(sx) f \(f): ≥ 8 clear of the cloth \(cl)…\(cr), stand \(s.stand)")
                XCTAssertEqual(s.face, (cl + cr) / 2 > s.stand ? 1 : -1, "faces the banner")
                if sx >= 70 && sx <= 1060 { // the training cap's range: on screen with the margin
                    XCTAssertTrue(s.stand - 32 >= cam + 8 && s.stand + 32 <= cam + 1272, "x \(sx) f \(f): on screen, stand \(s.stand - cam)")
                }
            }
        }
    }

    func test_the_walk_in_is_linear_over_the_rise_and_the_partner_holds_its_face() throws {
        var p = tapFlag()
        let fh = try XCTUnwrap(p.finishHold), pt = try XCTUnwrap(p.partner)
        XCTAssertEqual(pt.x, fh.spawn + (fh.stand - fh.spawn) * min(1, p.endT / 0.67), accuracy: 1e-9)
        for _ in 0..<20 {
            p.update(dt, StepInput())
            let q = try XCTUnwrap(p.partner)
            XCTAssertEqual(q.x, fh.spawn + (fh.stand - fh.spawn) * min(1, p.endT / 0.67), accuracy: 1e-9, "linear")
            XCTAssertEqual(q.face, fh.face); XCTAssertEqual(q.state, .rest); XCTAssertTrue(q.moving)
        }
        for _ in 0..<30 { p.update(dt, StepInput()) }
        XCTAssertEqual(p.partner?.x ?? 0, fh.stand, accuracy: 1e-9, "in place after the rise")
        XCTAssertEqual(p.partner?.moving, false)
    }

    /// AC32: pause 0.3 s into the hold, and N = 1, 2, 3 pauses: every resume restarts the hold to "rise done", the
    /// partner at its spot, and ≥ 0.8 s of banner-up follow before the beat ends.
    func test_every_resume_restarts_the_hold_to_rise_done() throws {
        for n in 1...3 {
            let g = Game(content: c, hero: hero, store: MemoryStore(), isDebug: true)
            g.debugStart(screen: "play", q: nil, beat: beatIndex(hero, "training") + 1, stage: "finish", stars: nil)
            g.step(dt, StepInput()); g.step(dt, StepInput(tapped: [.special]))
            XCTAssertNotNil(g.play.finishHold)
            for i in 0..<n {
                for _ in 0..<(i == 0 ? 18 : 30) { g.step(dt, StepInput()) } // 0.3 s in (during the rise), then 0.5 s after each resume
                g.pause(); g.resume()
                XCTAssertEqual(g.play.endT, 0.67, accuracy: 1e-9, "resume \(i + 1): rise done")
                let fh = try XCTUnwrap(g.play.finishHold)
                XCTAssertEqual(g.play.partner?.x ?? 0, fh.stand, accuracy: 1e-9, "the partner jumps to its spot")
            }
            var after = 0.0
            while g.play.phase == .beatEnd && after < 5 { g.step(dt, StepInput()); after += dt }
            XCTAssertGreaterThanOrEqual(after, 0.8, "N \(n): ≥ 0.8 s of banner-up after the last resume")
        }
    }
}
