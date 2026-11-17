import XCTest
@testable import GameCore

/// title.md AC4d, AC4f, AC6 (D-27, D-27b) on phones from the reference k down to the 0.32 floor.
final class TitleLayoutTests: XCTestCase {
    /// A landscape phone where the world is fitted at `k` pt per world px (full-width view, home indicator 21 pt).
    func pad(k: Double, left: Double = 0) -> PadLayout {
        PadLayout(view: (w: 1280 * k, h: 720 * k), insets: (0, left, 21, 0), padMin: 72, padGap: 12)
    }

    func test_no_two_title_boxes_overlap_and_all_stay_in_the_safe_rect() {
        for k in [0.546, 0.527, 0.517, 0.46, 0.40, 0.36, 0.33, 0.32] {
            for debug in [false, true] {
                let p = pad(k: k), t = TitleLayout(pad: p, debug: debug), all = t.all
                for i in all.indices { for j in all.indices where j > i {
                    XCTAssertFalse(all[i].1.overlaps(all[j].1), "k \(k) debug \(debug): \(all[i].0) overlaps \(all[j].0)")
                } }
                for (n, b) in all {
                    XCTAssertGreaterThanOrEqual(b.x, p.safeLeft - 8.001, "k \(k): \(n) left"); XCTAssertLessThanOrEqual(b.right, p.safeRight + 8.001, "k \(k): \(n) right")
                    XCTAssertLessThanOrEqual(b.bottom, p.safeBottom + 0.001, "k \(k) debug \(debug): \(n) bottom \(b.bottom) > \(p.safeBottom)")
                }
                XCTAssertGreaterThanOrEqual(t.start.h * k, 72 - 0.001, "Start ≥ pad_min")
                XCTAssertGreaterThanOrEqual(t.chip.h * k, 72 - 0.001, "chip ≥ pad_min")
                XCTAssertLessThanOrEqual(t.chip.w, 1.6 * t.chip.h + 0.001)
                XCTAssertGreaterThanOrEqual(t.chip.x, t.card.right + 8, "the chip clears the card")
            }
        }
    }

    /// AC4d at the reference phones: the boxes are where title.md puts them.
    func test_reference_boxes() {
        let t = TitleLayout(pad: pad(k: 0.527), debug: true)
        XCTAssertEqual(t.titleRow, Box(260, 18, 760, 137))
        XCTAssertEqual(t.card, Box(260, 175, 760, 180))
        XCTAssertEqual(t.start.x, 430); XCTAssertEqual(t.start.y, 375); XCTAssertEqual(t.start.w, 420)
        XCTAssertEqual(t.mapStub.y, t.start.bottom + 16, accuracy: 1e-9)
        XCTAssertFalse(t.linesBesideStart)
    }

    /// AC4f (D-27b): at k 0.32 the column would pass safe_bottom, so the stub and debug line move right of Start.
    func test_low_k_moves_the_lines_beside_start() {
        let t = TitleLayout(pad: pad(k: 0.32), debug: true)
        XCTAssertTrue(t.linesBesideStart)
        XCTAssertEqual(t.mapStub, Box(870, 375, 380, 38))
        XCTAssertEqual(t.debugLine, Box(870, 421, 380, 34))
        XCTAssertEqual(t.start.x, 430); XCTAssertEqual(t.start.y, 375)
    }
}
