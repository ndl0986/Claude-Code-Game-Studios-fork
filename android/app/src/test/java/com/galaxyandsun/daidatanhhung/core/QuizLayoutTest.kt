package com.galaxyandsun.daidatanhhung.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * r8 (leader's call): the small quiz layout turns on whenever the reference cards would pass Tiếp's top. On Android
 * (corner block at y 18, so corner_bottom + 8 = 26 + P with P = pad_min/k) that is P > 135, i.e. k < 0.5333.
 */
class QuizLayoutTest {
    private fun at(k: Double) = (72.0 / k).let { p -> QuizLayout.boxes(cornerClear = 26 + p, pad = p) }

    @Test fun smallOrReferenceByK() {
        for ((k, small) in listOf(0.40 to true, 0.488 to true, 0.515 to true, 0.527 to true, 0.533 to true, 0.534 to false, 0.60 to false))
            assertEquals("k $k", small, at(k).small)
    }

    /**
     * Leader r8 (corner_bottom = 18 + P stays): just below the switch (k 0.527, a geometry check; both Android devices
     * are k ≈ 0.488 per QC r8) the small layout still fits and Tiếp clears the right card.
     */
    @Test fun justBelowTheSwitchTheSmallLayoutFitsAndTiepClearsTheRightCard() {
        for (k in listOf(0.488, 0.527)) {
        val b = at(k)
        assertTrue(b.small)
        assertTrue("every box ≤ 720", maxOf(b.cardsBottom, b.whyBottom, b.rowBottom) <= 720)
        assertTrue("Tiếp (x ${b.tiepLeft}) clear of the right card in the left slot (to ${b.rightCardRight})", b.tiepLeft >= b.rightCardRight + 8)
        assertTrue("the why line ends above Tiếp's row", b.whyBottom <= b.rowTop)
        }
    }

    @Test fun everyBoxEndsOnScreenAndTiepNeverTouchesTheCards() {
        for (k in listOf(0.40, 0.45, 0.488, 0.514, 0.515, 0.527, 0.533, 0.534, 0.60, 0.70)) {
            val b = at(k)
            assertTrue("k $k: Tiếp row bottom ${b.rowBottom}", b.rowBottom <= 720 - 18 + 1e-9)
            assertTrue("k $k: why bottom ${b.whyBottom}", b.whyBottom <= 720 + 1e-9)
            assertTrue("k $k: cards bottom ${b.cardsBottom}", b.cardsBottom <= 720 + 1e-9)
            if (!b.small) assertTrue("k $k reference: cards end above Tiếp", b.cardsBottom <= b.rowTop + 1e-9)
            else assertTrue("k $k small: the why line beside the right card, above the bottom row", b.whyBottom <= b.rowTop + 1e-9)
        }
    }
}
