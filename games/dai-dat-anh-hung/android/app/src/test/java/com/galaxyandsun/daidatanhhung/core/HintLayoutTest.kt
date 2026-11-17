package com.galaxyandsun.daidatanhhung.core

import com.galaxyandsun.daidatanhhung.core.CueLayout.Pad
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Hints Rule 6 / AC12 (r10): on banner beats every teach hand is wholly at y ≥ 276, beside its pad (away from the
 * screen edge) when it can't go above, and never over any pad's touch rect. Pads as the renderer places them.
 */
class HintLayoutTest {
    private fun r(r0: Double, k: Double) = maxOf(r0, 72 / k / 2)
    private fun pads(k: Double, set: Set<String>): Map<String, Pad> = buildMap {
        if ("move" in set) { put("left", Pad(140.0, 610.0, r(80.0, k))); put("right", Pad(330.0, 610.0, r(80.0, k))) }
        if ("defend" in set) put("defend", Pad(950.0, 625.0, r(80.0, k)))
        if ("attack" in set) put("attack", Pad(1150.0, 590.0, r(92.0, k)))
        if ("special" in set) put("special", Pad(1150.0, 400.0, r(80.0, k)))
    }

    @Test fun everyTrainingStepsHandsStayBelowTheBarAndOffEveryPad() {
        // each step's pads and the hands it can show (Mission.hand: move/attack in dummies, defend in blocks, Cờ in special)
        val steps = mapOf("dummies" to (setOf("move", "attack") to listOf("right", "attack")),
            "blocks" to (setOf("move", "attack", "defend") to listOf("defend")),
            "special" to (setOf("move", "attack", "defend", "special") to listOf("special")))
        for (k in listOf(0.40, 0.488, 0.517)) for ((step, spec) in steps) {
            val ps = pads(k, spec.first)
            for (target in spec.second) {
                val h = CueLayout.hintHand(ps.getValue(target), ps.values.toList())
                assertNotNull("k $k $step $target: a spot exists", h)
                val b = CueLayout.handBox(h!!)
                assertTrue("k $k $step $target: below the bar ($b)", b.top >= CueLayout.FLOOR)
                for ((name, p) in ps) assertTrue("k $k $step $target: off $name", b.right <= p.x - p.r || b.left >= p.x + p.r || b.bottom <= p.y - p.r || b.top >= p.y + p.r)
            }
        }
    }

    @Test fun theCoHandSitsLeftOfCoAtMidHeightPointingAtIt() {
        for (k in listOf(0.40, 0.488, 0.517)) {
            val ps = pads(k, setOf("move", "attack", "defend", "special"))
            val co = ps.getValue("special")
            val h = CueLayout.hintHand(co, ps.values.toList())!!
            assertEquals("k $k: points right", -90f, h.rot)
            assertEquals("k $k: at Cờ's mid-height", co.y, h.y, 1e-9)
            val b = CueLayout.handBox(h)
            assertTrue("k $k: left of Cờ", b.right <= co.x - co.r)
        }
    }
}
