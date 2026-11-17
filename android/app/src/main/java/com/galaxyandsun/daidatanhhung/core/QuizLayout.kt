package com.galaxyandsun.daidatanhhung.core

import kotlin.math.max
import kotlin.math.min

/**
 * quiz-and-results §5.1/§5.2 (r8, leader's call with game-dev-ios): the reference layout (prompt ≤ 2 lines, cards,
 * the why line beside Tiếp on the bottom row) only fits while the cards end above Tiếp's top; otherwise the small
 * layout takes over (same geometric test as iOS QuizLayout.small). World px; pure, so the boxes are unit-tested.
 */
object QuizLayout {
    const val PROMPT_H = 108.0   // 2 lines at 40 px × 1.35
    const val CARD_GAP_TOP = 8.0
    const val CARD_H = 290.0
    const val TIEP_RIGHT = 1262.0

    /** The boxes for one screen: [cornerClear] = corner_bottom + 8, [pad] = pad_min in world px, [safeBottom] ≤ 720. */
    data class Boxes(val small: Boolean, val promptTop: Double, val cardsTop: Double, val cardsBottom: Double,
                     val rowTop: Double, val rowBottom: Double, val whyTop: Double, val whyBottom: Double,
                     val tiepLeft: Double, val rightCardRight: Double)

    fun boxes(cornerClear: Double, pad: Double, safeBottom: Double = 720.0): Boxes {
        val rowH = max(110.0, pad)
        val rowBottom = min(720.0, safeBottom) - 18
        val rowTop = rowBottom - rowH
        val cardsTop = cornerClear + PROMPT_H + CARD_GAP_TOP
        val cardsBottom = cardsTop + CARD_H
        val small = cardsBottom > rowTop
        // reference: the why line sits left of Tiếp on the bottom row; small: right of the right card (§5.2, 135 tall)
        // Tiếp: small 450 wide (x 812–1262, over the spent slot 3); reference 340 (x 922–1262, as iOS). The right card
        // after the pick: small → the left slot (x 40–420); reference → wherever it was (slot 3 ends at 1240, above the row)
        return if (small) Boxes(true, cornerClear, cardsTop, cardsBottom, rowTop, rowBottom, cardsTop, cardsTop + 135, TIEP_RIGHT - 450, 420.0)
        else Boxes(false, cornerClear, cardsTop, cardsBottom, rowTop, rowBottom, rowTop, rowBottom, TIEP_RIGHT - 340, 1240.0)
    }
}
