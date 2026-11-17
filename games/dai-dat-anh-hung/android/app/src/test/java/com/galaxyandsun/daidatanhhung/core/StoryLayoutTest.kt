package com.galaxyandsun.daidatanhhung.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** story-screens §5.2 (r8, r8b), story AC12/AC13: the placeholder still and the part label. */
class StoryLayoutTest {
    /** corner_right at k 0.40 / 0.488 / 0.527: 18 + 4r + gap, r = pad_min/2 in world px (r8 spec: ≈ 416 at k 0.40). */
    private val cornerRights = listOf(0.40, 0.488, 0.527).map { k -> val pm = 72 / k; 18 + 2 * pm + 12 / k }

    @Test fun introAndCaptionStillIs256EndingAt301CentredClearOfTheCorner() {
        for (cr in cornerRights) {
            val b = StoryLayout.still(card = false, cornerRight = cr, labelTop = 309.0)!!
            assertEquals(256.0, b.width, 1e-9); assertEquals(301.0, b.bottom, 1e-9); assertEquals(45.0, b.top, 1e-9)
            assertEquals(640.0, b.cx, 1e-9); assertTrue("clear of the corner at $cr", b.left >= cr + 8)
        }
        assertEquals("the intro (no label) lines up with the captions", 301.0, StoryLayout.still(false, cornerRights[0], null)!!.bottom, 1e-9)
    }

    @Test fun beatCardStillIs208EndingAt233() {
        val label = StoryLayout.partLabelTop(panelTop = 279.0, cornerClear = 0.0)
        assertEquals("label box 241–269 over a card at the floor", 241.0, label, 1e-9)
        for (cr in cornerRights) {
            val b = StoryLayout.still(card = true, cornerRight = cr, labelTop = label)!!
            assertEquals(208.0, b.width, 1e-9); assertEquals(25.0, b.top, 1e-9); assertEquals(233.0, b.bottom, 1e-9)
            assertTrue("≥ 8 above the label", b.bottom <= label - 8 + 1e-9); assertTrue(b.left >= cr + 8)
        }
    }

    @Test fun captionLabelBoxIs309To337AtTheFloor() =
        assertEquals(309.0, StoryLayout.partLabelTop(panelTop = 347.0, cornerClear = 175.0), 1e-9)

    @Test fun theLabelNeverRisesIntoTheCornerBlock() =
        assertEquals("centre = corner_bottom + 8 + 16", 216.0 - 14, StoryLayout.partLabelTop(panelTop = 200.0, cornerClear = 200.0), 1e-9)

    @Test fun aStillThatWouldBeUnder192IsDropped() {
        assertEquals(204.0, StoryLayout.still(true, cornerRights[0], labelTop = 230.0)!!.width, 1e-9) // shrinks to fit
        assertNull("192 doesn't fit under a label at 200", StoryLayout.still(true, cornerRights[0], labelTop = 200.0))
        assertNull("192 doesn't fit right of a corner at 560", StoryLayout.still(false, 560.0, null))
    }
}
