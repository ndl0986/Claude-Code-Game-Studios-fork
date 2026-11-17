import XCTest
@testable import GameCore

/// Hints Rule 6 (r9) / AC12: on banner beats every hint pixel is at y ≥ 276; the hand sits above its pad when it fits,
/// else beside it on the side away from the screen edge, pointing at it; it never covers any visible pad (Android
/// CueLayout.hintHand, the same hand box: 56 × 100 plus the ±12 bounce).
final class HintHandTests: XCTestCase {
    func pad(_ k: Double) -> PadLayout { PadLayout(view: (w: 1280 * k, h: 720 * k), insets: (0, 0, 0, 0), padMin: 72, padGap: 12) }
    func squares(_ l: PadLayout, _ pads: [Circle]) -> [Box] { pads.map { Box($0.cx - $0.r, $0.cy - $0.r, 2 * $0.r, 2 * $0.r) } }

    func test_the_finish_steps_hands_on_a_banner_beat() {
        for k in [0.40, 0.488, 0.517] {
            let l = pad(k), all = [l.left, l.right, l.defend, l.attack, l.special], sq = squares(l, all)
            let flag = HintPlacement.hand(pad: l.special, avoid: sq, banner: true)
            XCTAssertEqual(flag.side, -1, "k \(k): Cờ's hand left of Cờ")
            XCTAssertEqual(flag.pointing, 1, "pointing right, at Cờ")
            XCTAssertEqual(flag.rect.midY, l.special.cy, accuracy: 3, "at Cờ's mid-height")
            // the other hands show in their own steps, with the pads visible there (dummies: move + attack; blocks:
            // + defend; Cờ hidden until the finish step, Rule 7c)
            let blocks = squares(l, [l.left, l.right, l.attack, l.defend])
            for (name, c) in [("left", l.left), ("right", l.right), ("attack", l.attack), ("defend", l.defend)] {
                let h = HintPlacement.hand(pad: c, avoid: blocks, banner: true)
                XCTAssertEqual(h.side, 0, "k \(k): \(name)'s hand above it")
                XCTAssertGreaterThanOrEqual(h.rect.y, 276 - 1e-9, "k \(k): \(name) below the bar")
                for s in blocks { XCTAssertFalse(h.rect.overlaps(s), "k \(k): \(name)'s hand never covers a pad") }
            }
            XCTAssertGreaterThanOrEqual(flag.rect.y, 276 - 1e-9); XCTAssertGreaterThanOrEqual(flag.rect.x, 8)
            for s in sq { XCTAssertFalse(flag.rect.overlaps(s), "k \(k): Cờ's hand never covers a pad") }
            // the stuck pulse (the halo r + 14 at scale 1.08) on Cờ also stays below the bar
            XCTAssertGreaterThanOrEqual(l.special.cy - (l.special.r + 14) * 1.08, 276, "k \(k): Cờ's pulse below the bar")
        }
    }

    func test_off_banner_beats_the_hand_stays_above_its_pad() {
        let l = pad(0.517), sq = squares(l, [l.left, l.right, l.defend, l.attack, l.special])
        XCTAssertEqual(HintPlacement.hand(pad: l.special, avoid: sq, banner: false).side, 0)
    }

    func test_the_hand_boxes() {
        let c = Circle(cx: 600, cy: 500, r: 80)
        let above = HintPlacement.handBox(pad: c, side: 0), left = HintPlacement.handBox(pad: c, side: -1), right = HintPlacement.handBox(pad: c, side: 1)
        XCTAssertEqual(above, Box(570, 290, 56, 124), "anchor (600, 438): x −30…+26, y −148…−24")
        XCTAssertEqual(left, Box(390, 474, 124, 56), "anchor (538, 500), pointing right: x −148…−24, y −26…+30")
        XCTAssertEqual(right, Box(686, 470, 124, 56), "anchor (662, 500), pointing left: x +24…+148, y −30…+26")
        XCTAssertEqual(above.bottom, c.cy - c.r - 6, accuracy: 1e-9, "6 above the pad")
        XCTAssertEqual(left.right, c.cx - c.r - 6, accuracy: 1e-9, "6 left of the pad")
    }
}
