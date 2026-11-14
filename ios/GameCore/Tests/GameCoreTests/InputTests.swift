import XCTest
@testable import GameCore

/// Touch handling and pad layout (P-04 items 4, pads ≥ pad_min inside the safe area).
final class InputTests: XCTestCase {
    func test_multi_touch_holds_slide_switches_direction_and_clear_all_unsticks() {
        var t = TouchPads()
        t.down(1, .right); t.down(2, .attack)
        var i = t.take()
        XCTAssertEqual(i.held, [.right, .attack]); XCTAssertEqual(i.tapped, [.right, .attack])
        t.moved(1, .left)
        i = t.take()
        XCTAssertEqual(i.held, [.left, .attack]); XCTAssertTrue(i.tapped.isEmpty, "taps are consumed")
        t.moved(2, .defend)
        XCTAssertEqual(t.take().held, [.left, .attack], "sliding never changes attack")
        t.clearAll()
        XCTAssertTrue(t.take().held.isEmpty)
    }

    func test_pads_are_at_least_72pt_and_inside_the_safe_area_on_the_iphone_duo_cover() {
        // the Duo's cover display in landscape: 2034×1398 px at 3x ≈ 678×466 pt; a camera cutout on the left
        let insets = (top: 0.0, left: 59.0, bottom: 21.0, right: 59.0)
        let l = PadLayout(view: (w: 678, h: 466), insets: insets, padMin: 72)
        let s = l.scale, oy = (466 - 720 * s) / 2, ox = (678 - 1280 * s) / 2
        for c in [l.left, l.right, l.defend, l.attack, l.special] {
            XCTAssertGreaterThanOrEqual(c.r * 2 * s, 72 - 0.001)
            XCTAssertGreaterThanOrEqual(ox + (c.cx - c.r) * s, insets.left - 0.001)
            XCTAssertLessThanOrEqual(ox + (c.cx + c.r) * s, 678 - insets.right + 0.001)
            XCTAssertLessThanOrEqual(oy + (c.cy + c.r) * s, 466 - insets.bottom + 0.001)
        }
        XCTAssertLessThan(l.left.cx + l.left.r, l.right.cx - l.right.r, "pads don't overlap")
        XCTAssertLessThan(l.defend.cx + l.defend.r, l.attack.cx - l.attack.r)
        XCTAssertLessThan(l.special.cy + l.special.r, l.attack.cy - l.attack.r, "special above attack")
        XCTAssertGreaterThanOrEqual(oy + (l.special.cy - l.special.r) * s, insets.top - 0.001)
    }

    func test_hit_test_finds_the_pad_with_slop() {
        let l = PadLayout(view: (w: 1280, h: 720), insets: (0, 0, 0, 0), padMin: 72)
        XCTAssertEqual(l.action(at: l.attack.cx + l.attack.r * 1.1, l.attack.cy), .attack)
        XCTAssertNil(l.action(at: 640, 300))
        XCTAssertNil(l.action(at: l.special.cx, l.special.cy, visible: [.left, .right]), "hidden pads never fire")
    }
}
