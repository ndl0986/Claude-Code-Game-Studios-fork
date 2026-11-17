import XCTest
@testable import GameCore

/// iOS QC r6 R6-02 and quiz-and-results §5.2 (AC7): the prompt starts below the pause/sound corner block,
/// nothing overlaps, and on a small-k phone the right card stays clear of the why line and Tiếp.
final class QuizLayoutTests: XCTestCase {
    func pad(_ k: Double) -> PadLayout { PadLayout(view: (w: 1280 * k, h: 720 * k), insets: (0, 0, 0, 0), padMin: 72, padGap: 12) }

    func test_the_prompt_starts_below_the_corner_block_and_nothing_overlaps() {
        for k in [0.6, 0.54, 0.529, 0.517, 0.48, 0.44, 0.40] {
            let p = pad(k), q = QuizLayout(pad: p), cornerBottom = p.pause.cy + p.pause.r
            XCTAssertGreaterThanOrEqual(q.prompt.y, cornerBottom + 8 - 0.001, "k \(k): prompt below the corner block")
            XCTAssertFalse(q.prompt.overlaps(Box(0, 0, p.mute.cx + p.mute.r, cornerBottom)), "k \(k)")
            for s in q.slots { XCTAssertFalse(s.overlaps(q.prompt)); XCTAssertLessThanOrEqual(s.bottom, 720) }
            for i in 0..<3 { for j in (i + 1)..<3 { XCTAssertFalse(q.slots[i].overlaps(q.slots[j])) } }
            if q.small {
                // after the right pick: the right card in the left slot, the why line and Tiếp clear of it and each other
                let right = q.rightCard(slot: 2)
                XCTAssertEqual(right, q.slots[0])
                XCTAssertFalse(right.overlaps(q.why), "k \(k)"); XCTAssertFalse(right.overlaps(q.next), "k \(k)")
                XCTAssertFalse(q.why.overlaps(q.next), "k \(k)")
            } else {
                // reference: the cards end above Tiếp's row; the why line sits left of Tiếp on that row
                for s in q.slots { XCTAssertLessThanOrEqual(s.bottom, q.next.y + 0.001, "k \(k)") }
                XCTAssertFalse(q.why.overlaps(q.next))
            }
            XCTAssertLessThanOrEqual(q.next.bottom, 720)
        }
        XCTAssertTrue(QuizLayout(pad: pad(0.529)).small, "r8c: with the corner at 18 + P the iPhone 18 Pro gets the small layout")
        XCTAssertFalse(QuizLayout(pad: pad(0.54)).small)
        XCTAssertTrue(QuizLayout(pad: pad(0.40)).small)
    }
}

/// r8c: the small quiz layout is the geometric test (reference cards' bottom 432 + P past Tiếp's top 702 − P, so
/// k < 72/135 ≈ 0.533 at pad_min 72); in it Tiếp is 450 wide (x 812–1262), in the reference layout 340.
final class QuizSwitchTests: XCTestCase {
    func q(_ k: Double) -> QuizLayout { QuizLayout(pad: PadLayout(view: (w: 1280 * k, h: 720 * k), insets: (0, 0, 0, 0), padMin: 72, padGap: 12)) }
    func test_the_switch_and_tieps_width() {
        XCTAssertTrue(q(0.517).small, "the QC iPhone 18 Pro (reference k 0.517) gets the small layout")
        XCTAssertTrue(q(0.529).small, "the dev iPhone 18 Pro, k 0.529, too")
        XCTAssertFalse(q(0.54).small)
        XCTAssertEqual(q(0.5).next.x, 812); XCTAssertEqual(q(0.5).next.w, 450)
        XCTAssertEqual(q(0.54).next.x, 922); XCTAssertEqual(q(0.54).next.w, 340)
        let s = q(0.40)
        XCTAssertFalse(s.why.overlaps(s.next), "k 0.40: the why line clear of Tiếp")
        XCTAssertFalse(s.slots[0].overlaps(s.next), "k 0.40: the right card (left slot) clear of Tiếp")
    }
}
