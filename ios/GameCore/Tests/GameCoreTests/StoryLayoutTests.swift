import XCTest
@testable import GameCore

/// story-screens.md §5.2 / dialogue.md §5.2 (QC r5): AC6, AC10 and the boxes clear of the corner block, from
/// the iPhone 18 Pro (k 0.529 with the world fitted to the safe rect) down to the k 0.40 floor.
final class StoryLayoutTests: XCTestCase {
    func pad(_ k: Double) -> PadLayout { PadLayout(view: (w: 1280 * k, h: 720 * k), insets: (0, 0, 0, 0), padMin: 72, padGap: 12) }

    func test_every_story_box_clears_the_corner_and_the_row_is_pad_min_tall() {
        for k in [0.529, 0.527, 0.517, 0.48, 0.44, 0.40] {
            let p = pad(k), s = StoryLayout(pad: p)
            XCTAssertGreaterThanOrEqual(s.next.h * k, 72 - 0.001); XCTAssertEqual(s.skip.h, s.next.h, "Bỏ qua as tall as Tiếp (AC10)")
            XCTAssertEqual(s.skip.y, s.next.y); XCTAssertGreaterThanOrEqual((s.next.x - s.skip.right) * k, 12)
            XCTAssertEqual(s.next.bottom, 702, accuracy: 0.001, "on safe_bottom − 18")
            var boxes = [("card", s.panel(box: 880, height: StoryLayout.cardHeight)), ("intro", s.panel(box: 1000, height: StoryLayout.storyHeight))]
            for sp in ["hero", "king", "narrator"] {
                let d = s.dialogue(speaker: sp); boxes.append(("dialogue \(sp)", d.panel))
                if let pt = d.portrait { boxes.append(("portrait \(sp)", pt)); XCTAssertFalse(pt.overlaps(d.panel)); XCTAssertEqual(pt.bottom, d.panel.bottom) }
            }
            for (n, b) in boxes {
                XCTAssertGreaterThanOrEqual(b.y, s.minTop - 0.001, "k \(k): \(n) top \(b.y) under the corner block (ends \(s.minTop - 8))")
                XCTAssertEqual(b.bottom, s.next.y - 8, accuracy: 0.001, "\(n) bottom-anchored above Tiếp")
                XCTAssertGreaterThanOrEqual(b.x, 0); XCTAssertLessThanOrEqual(b.right, 1280)
            }
        }
    }

    /// The worked numbers at the Android reference (k 0.527): Tiếp 565–702, beat card 322–557, dialogue 271–557.
    func test_reference_numbers() {
        let s = StoryLayout(pad: pad(0.527))
        XCTAssertEqual(s.next.y, 702 - 72 / 0.527, accuracy: 0.01)
        XCTAssertEqual(s.panel(box: 880, height: 235).y, s.next.y - 8 - 235, accuracy: 0.01)
        XCTAssertEqual(s.dialogue(speaker: "hero").panel.h, 286)
    }
}
