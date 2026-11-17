import XCTest
@testable import GameCore

/// hud.md §3.3 (r8) / HUD AC17, hints Rule 4: on a banner beat the stuck arrow and the telegraph "!" are each fully
/// below the motto bar (every pixel at y ≥ bar bottom + 8 = 276); the arrow bounces above its target only when it fits
/// there, else it points from the side away from the hero (edge → the hero's side; no hero → the side nearer the
/// centre); the "!" sits above the helmet only when it fits, else beside the head, away from the hero.
final class HintPlacementTests: XCTestCase {
    let ground = 470.0, cam = 0.0

    func assertBelowBar(_ p: HintPlacement.Placed, _ what: String) {
        XCTAssertGreaterThanOrEqual(p.rect.y, HintPlacement.clearY - 1e-9, "\(what): top \(p.rect.y) is below the bar + 8")
        XCTAssertGreaterThanOrEqual(p.rect.x, cam + 8 - 1e-9, "\(what): on screen (left)")
        XCTAssertLessThanOrEqual(p.rect.right, cam + 1280 - 8 + 1e-9, "\(what): on screen (right)")
    }

    func test_the_bar_numbers() {
        XCTAssertEqual(HintPlacement.barBottom, 268, "bar top 156 + 112")
        XCTAssertEqual(HintPlacement.clearY, 276)
        XCTAssertEqual(HintPlacement.arrowAboveMinTop, 352, "276 + 64 + 12")
    }

    func test_off_banner_beats_the_arrow_bounces_above_the_target() {
        let p = HintPlacement.arrow(target: .init(x: 700, top: ground - 170, halfWidth: 40), heroX: 400, cam: cam, banner: false)
        XCTAssertEqual(p.side, 0); XCTAssertEqual(p.angle, 0)
        XCTAssertLessThanOrEqual(p.rect.bottom, ground - 170, "its tip (lowest bounce) stays above the helmet")
    }

    func test_a_target_tall_enough_below_the_bar_keeps_the_arrow_above_it() {
        let p = HintPlacement.arrow(target: .init(x: 700, top: 400, halfWidth: 34), heroX: 400, cam: cam, banner: true)
        XCTAssertEqual(p.side, 0); assertBelowBar(p, "above a low target")
    }

    func test_on_a_banner_beat_the_arrow_points_from_the_side_away_from_the_hero() {
        for (target, hero, side) in [(700.0, 400.0, 1), (400, 700, -1)] {
            let t = HintPlacement.Target(x: target, top: ground - 170, halfWidth: 40)
            let p = HintPlacement.arrow(target: t, heroX: hero, cam: cam, banner: true)
            XCTAssertEqual(p.side, side, "away from the hero")
            XCTAssertEqual(p.angle, Double(side) * .pi / 2, accuracy: 1e-9, "rotated 90°, pointing back at the target")
            XCTAssertEqual(p.y, t.midY, accuracy: 1e-9, "at the target's mid-height")
            XCTAssertFalse(p.rect.x < t.x + t.halfWidth && p.rect.right > t.x - t.halfWidth, "beside, not over, the target")
            assertBelowBar(p, "enemy arrow")
        }
    }

    func test_the_arrow_uses_the_heros_side_at_a_screen_edge() {
        let p = HintPlacement.arrow(target: .init(x: 1230, top: ground - 170, halfWidth: 40), heroX: 900, cam: cam, banner: true)
        XCTAssertEqual(p.side, -1, "no room right of the target: from the hero's side (inward)")
        assertBelowBar(p, "edge")
    }

    func test_with_no_hero_the_arrow_uses_the_side_nearer_the_centre() {
        let left = HintPlacement.arrow(target: .init(x: 300, top: ground - 300, halfWidth: 8), heroX: nil, cam: cam, banner: true)
        let right = HintPlacement.arrow(target: .init(x: 1000, top: ground - 300, halfWidth: 8), heroX: nil, cam: cam, banner: true)
        XCTAssertEqual(left.side, 1); XCTAssertEqual(right.side, -1)
        XCTAssertEqual(left.y, ground - 150, accuracy: 1e-9, "the flag's mid-height")
        assertBelowBar(left, "flag"); assertBelowBar(right, "flag")
    }

    func test_the_camera_offset_is_respected() {
        let p = HintPlacement.arrow(target: .init(x: 5230, top: ground - 170, halfWidth: 40), heroX: 4900, cam: 4000, banner: true)
        XCTAssertEqual(p.side, -1, "screen x 1230: the edge fallback in world space")
        XCTAssertGreaterThanOrEqual(p.rect.x, 4008)
    }

    func test_the_bang_sits_beside_the_head_on_banner_beats_and_above_otherwise() {
        let e = HintPlacement.Fighter(x: 700, top: ground - 170, headY: ground - 145, headHalfWidth: 30)
        let off = HintPlacement.bang(e, heroX: 400, cam: cam, banner: false)
        XCTAssertEqual(off.side, 0); XCTAssertLessThanOrEqual(off.rect.bottom, e.top, "above the helmet")
        let on = HintPlacement.bang(e, heroX: 400, cam: cam, banner: true)
        XCTAssertEqual(on.side, 1, "away from the hero"); XCTAssertEqual(on.y, e.headY, accuracy: 1e-9, "at head height")
        XCTAssertGreaterThanOrEqual(on.rect.x, e.x + e.headHalfWidth, "beside the head, not on it")
        assertBelowBar(on, "bang")
        let edge = HintPlacement.bang(.init(x: 1240, top: e.top, headY: e.headY, headHalfWidth: 30), heroX: 1000, cam: cam, banner: true)
        XCTAssertEqual(edge.side, -1, "at the screen edge: the hero's side"); assertBelowBar(edge, "bang at the edge")
        let tallRoom = HintPlacement.bang(.init(x: 700, top: 420, headY: 440, headHalfWidth: 30), heroX: 400, cam: cam, banner: true)
        XCTAssertEqual(tallRoom.side, 0, "it fits above the helmet wholly below the bar"); assertBelowBar(tallRoom, "bang above")
    }
}
