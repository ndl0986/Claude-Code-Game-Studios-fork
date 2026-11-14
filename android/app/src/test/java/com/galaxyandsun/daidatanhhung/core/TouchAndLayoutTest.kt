package com.galaxyandsun.daidatanhhung.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Pads ≥ pad_min inside the safe rect, and input that never sticks (code review item 7). */
class TouchAndLayoutTest {
    private val padMin = TestContent.load().tuning.values.getValue("pad_min").value.toFloat()

    @Test fun padsAreAtLeastPadMinAndInsideTheSafeRect() {
        // A 20:9 phone in landscape, 2.625 density, cutout on the left, gesture zone at the bottom.
        val safe = intArrayOf(120, 0, 0, 84)
        val f = ScreenFit.of(2400f, 1080f, safe, 2.625f, padMin)
        val pads = listOf(Triple(140f, 610f, 80f), Triple(330f, 610f, 80f), Triple(950f, 625f, 80f), Triple(1150f, 590f, 92f))
        for ((x, y, r0) in pads) {
            val r = f.padRadius(r0)
            assertTrue("pad ${2 * r * f.k / 2.625f} dp across", 2 * r * f.k / 2.625f >= padMin - 0.01f)
            val sx = f.ox + x * f.k; val sy = f.oy + y * f.k; val sr = r * f.k
            assertTrue(sx - sr >= safe[0]); assertTrue(sy + sr <= 1080 - safe[3]); assertTrue(sx + sr <= 2400 - safe[2])
        }
    }

    @Test fun aSmallScreenGrowsPadsToPadMin() {
        val f = ScreenFit.of(640f, 360f, IntArray(4), 1f, padMin) // k = 0.5: an 80-unit pad would be 80 dp
        assertEquals(padMin / 2 / 0.5f, f.padRadius(10f), 0.001f)
    }

    @Test fun cancelAndFocusLossClearEveryPad() {
        val p = PadHolds()
        p.down(0, Action.RIGHT); p.down(1, Action.DEFEND)
        assertEquals(setOf(Action.RIGHT, Action.DEFEND), p.held())
        p.clear()
        assertTrue(p.held().isEmpty())
    }

    @Test fun pointerUpReleasesOnlyItsPadAndSlidingSwitchesDirection() {
        val p = PadHolds()
        p.down(0, Action.LEFT); p.down(1, Action.ATTACK)
        p.move(0, Action.RIGHT); assertEquals(setOf(Action.RIGHT, Action.ATTACK), p.held())
        p.move(1, Action.RIGHT); assertEquals(setOf(Action.RIGHT, Action.ATTACK), p.held()) // attack never slides
        p.up(1); assertEquals(setOf(Action.RIGHT), p.held())
    }
    /** Input GDD Rule 5b / AC13 (iOS-R2-03): a pointer's moves never keep its pad held after its up. */
    @Test fun pressSmallMovesAndUpLeavesNothingHeld() {
        for (pad in listOf(Action.DEFEND, Action.SPECIAL, Action.LEFT, Action.ATTACK)) {
            val p = PadHolds()
            p.down(7, pad)
            p.move(7, pad); p.move(7, null); p.move(7, Action.ATTACK); p.move(7, pad) // inside, off every pad, onto another
            p.up(7)
            assertTrue("$pad still held", p.held().isEmpty())
        }
        // Two pointers: only the one that lifts is released, whatever the other did.
        val p = PadHolds()
        p.down(0, Action.RIGHT); p.down(1, Action.DEFEND)
        p.move(1, null); p.move(0, null); p.up(1)
        assertEquals(setOf(Action.RIGHT), p.held())
        p.up(0); assertTrue(p.held().isEmpty())
    }
}
