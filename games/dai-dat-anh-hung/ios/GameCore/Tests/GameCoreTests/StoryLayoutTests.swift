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

/// story-screens.md §5.2 (r8, r8b) / AC12: until a screen has its real still, the intro, captions and beat cards show
/// the hero's portrait in a drum ring, centred on x 640, its bottom ≥ 8 px above the "Phần n" label (panel top − 46,
/// taken at the k 0.40 floor so it sits at the same world position at every k); below 192 it is dropped.
final class StoryPlaceholderTests: XCTestCase {
    func pad(_ k: Double) -> PadLayout { PadLayout(view: (w: 1280 * k, h: 720 * k), insets: (0, 0, 0, 0), padMin: 72, padGap: 12) }

    func test_the_spec_boxes() {
        XCTAssertEqual(StoryLayout.placeholder(.story), Box(512, 45, 256, 256), "intro and caption: 256 at y 45–301")
        XCTAssertEqual(StoryLayout.placeholder(.card), Box(536, 25, 208, 208), "beat card: 208 at y 25–233")
    }

    func test_clear_of_the_label_and_the_corner_at_every_k() {
        for k in [0.529, 0.527, 0.517, 0.48, 0.44, 0.40] {
            let p = pad(k), s = StoryLayout(pad: p)
            for (kind, h) in [(StoryLayout.Placeholder.story, StoryLayout.storyHeight), (.card, StoryLayout.cardHeight)] {
                let b = StoryLayout.placeholder(kind)!, labelTop = s.panel(box: 880, height: h).y - 38
                XCTAssertLessThanOrEqual(b.bottom, labelTop - 8 + 1e-9, "k \(k) \(kind): ≥ 8 above the part label")
                XCTAssertGreaterThanOrEqual(b.y, 18, "k \(k) \(kind): top margin")
                XCTAssertGreaterThan(b.x, p.mute.cx + p.mute.r + 8, "k \(k) \(kind): right of the pause/sound block")
                XCTAssertEqual(b.midX, 640, accuracy: 1e-9)
            }
        }
    }

    func test_dropped_when_less_than_192_fits() {
        XCTAssertEqual(StoryLayout.placeholder(bottom: 233, nominal: 240), Box(532.5, 18, 215, 215), "shrinks to fit under the label")
        XCTAssertEqual(StoryLayout.placeholder(bottom: 210, nominal: 256)?.w, 192, "192 still fits")
        XCTAssertNil(StoryLayout.placeholder(bottom: 209, nominal: 256), "less than 192: the background alone shows")
    }
}
