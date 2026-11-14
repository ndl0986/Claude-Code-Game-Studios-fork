import Foundation

/// The quiz screen's boxes (design/ux/quiz-and-results.md §5.1, §5.2; iOS QC r6 R6-02). World px, y down,
/// the world fitted to the safe rect. Nothing starts above the pause/sound corner block + 8.
public struct QuizLayout: Equatable, Sendable {
    /// The prompt (980 box, ≤ 2 lines at 40 px × 1.35 = 108 tall), at corner_bottom + 8.
    public let prompt: Box
    /// The three card slots while choosing: 380 × 290 each (picture plus a 2-line label).
    public let slots: [Box]
    /// "Tiếp" (after the right pick plus feedback_time only), on the story row (≥ pad_min).
    public let next: Box
    /// §5.2: on a small-k phone the cards use Tiếp's row while choosing; after the right pick the wrong
    /// cards fade, the right card glides to the left slot, and the why line sits right of it.
    public let small: Bool
    /// The why line (box = width − 40, ≤ 3 lines at 37): under the cards left of Tiếp, or right of the
    /// right card on a small-k phone.
    public let why: Box
    /// The dots and counter row's centre x (the free band right of the corner block).
    public let topCentre: Double

    public init(pad: PadLayout) {
        let story = StoryLayout(pad: pad)
        let row = story.next
        prompt = Box(150, story.minTop, 980, 108)
        let y = prompt.bottom + 8
        slots = [40.0, 450, 860].map { Box($0, y, 380, 290) }
        // r8c: the small layout is the geometric test, the reference cards' bottom (432 + P) past Tiếp's top
        // (702 − P), strict, no margin: k < 72/135 ≈ 0.533 at pad_min 72 (the QC iPhone 18 Pro, k 0.517, is small)
        small = slots[0].bottom > row.y
        // Tiếp on the story row: 340 wide in the reference layout, 450 (x 812–1262) in the small one (r8c)
        next = small ? Box(row.right - 450, row.y, 450, row.h) : row
        why = small ? Box(slots[1].x, y, slots[2].right - slots[1].x, 135)
                    : Box(40, next.y, next.x - 16 - 40, next.h)
        topCentre = pad.topStackCentre
    }

    /// The right card's box after the pick: the left slot on a small-k phone, its own slot otherwise.
    public func rightCard(slot: Int) -> Box { small ? slots[0] : slots[slot] }
}
