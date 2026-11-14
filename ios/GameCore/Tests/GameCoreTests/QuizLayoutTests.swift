import XCTest
@testable import GameCore

/// iOS QC r6 R6-02 and quiz-and-results §5.2 (AC7): the prompt starts below the pause/sound corner block,
/// nothing overlaps, and on a small-k phone the right card stays clear of the why line and Tiếp.
final class QuizLayoutTests: XCTestCase {
    func pad(_ k: Double) -> PadLayout { PadLayout(view: (w: 1280 * k, h: 720 * k), insets: (0, 0, 0, 0), padMin: 72, padGap: 12) }

    func test_the_prompt_starts_below_the_corner_block_and_nothing_overlaps() {
        for k in [0.529, 0.517, 0.48, 0.44, 0.40] {
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
        XCTAssertFalse(QuizLayout(pad: pad(0.529)).small, "the iPhone 18 Pro keeps the reference layout")
        XCTAssertTrue(QuizLayout(pad: pad(0.40)).small)
    }
}
