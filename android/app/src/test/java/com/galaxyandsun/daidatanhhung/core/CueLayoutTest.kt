package com.galaxyandsun.daidatanhhung.core

import com.galaxyandsun.daidatanhhung.core.CueLayout.Dir
import com.galaxyandsun.daidatanhhung.core.CueLayout.Target
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * hud.md §3.3 (r8), AC17: on a banner beat the "!" bubble and the stuck arrow never touch the motto bar (every pixel at
 * y ≥ 276); the "!" sits beside the head away from the hero (the hero's side at a screen edge); the arrow points from the
 * side when it can't bounce above its target below the bar. Targets as the renderer measures them at ground 470.
 */
class CueLayoutTest {
    private val g = 470.0
    private fun enemy(x: Double) = Target(x, g - 170, g - 140, 40.0)
    private fun partner(x: Double) = Target(x, g - 162, g - 121, 30.0)
    private fun dummy(x: Double) = Target(x, g - 151, g - 80, 30.0)
    private fun flag(x: Double) = CueLayout.goalFlag(g, banner = true).let { f -> Target(x + 0.1 * f.size, f.top, (f.top + f.foot) / 2, 0.6 * f.size) }
    private fun StoryLayout.Box.clearOfTheBar() = top >= CueLayout.FLOOR - 1e-9
    private fun StoryLayout.Box.onScreen() = left >= CueLayout.EDGE - 1e-9 && right <= CueLayout.SCREEN_W - CueLayout.EDGE + 1e-9
    /** The cue is fully beside the target's body, on the side [s] (+1 right). */
    private fun StoryLayout.Box.beside(t: Target, s: Int) = if (s > 0) left >= t.x + t.halfW - 1e-9 else right <= t.x - t.halfW + 1e-9

    @Test fun theBubbleSitsBesideTheHeadAwayFromTheHeroOnBannerBeats() {
        for ((t, hero) in listOf(enemy(800.0) to 500.0, partner(800.0) to 500.0, enemy(500.0) to 800.0, partner(500.0) to 800.0)) {
            val c = CueLayout.bubble(t, hero, banner = true); val b = CueLayout.bubbleBox(c)
            val away = if (t.x > hero) 1 else -1
            assertTrue("clear of the bar: $b", b.clearOfTheBar()); assertTrue(b.onScreen())
            assertTrue("beside, away from the hero: $c", b.beside(t, away))
            assertEquals("the tail points back at the helmet", if (away > 0) Dir.LEFT else Dir.RIGHT, c.dir)
            assertEquals("at head height", t.midY, c.y, 1e-9)
        }
    }

    @Test fun atTheScreenEdgeTheBubbleUsesTheHerosSide() {
        val c = CueLayout.bubble(enemy(1240.0), heroX = 1000.0, banner = true); val b = CueLayout.bubbleBox(c)
        assertTrue(b.onScreen()); assertTrue(b.clearOfTheBar()); assertTrue("hero's side", b.beside(enemy(1240.0), -1))
    }

    @Test fun offBannerBeatsTheBubbleStaysAboveTheHelmet() {
        val t = enemy(800.0); val c = CueLayout.bubble(t, 500.0, banner = false)
        assertEquals(Dir.DOWN, c.dir); assertEquals(t.x, c.x, 1e-9); assertTrue(CueLayout.bubbleBox(c).bottom <= t.top)
    }

    @Test fun theArrowNeverTouchesTheBarOverADummyAnEnemyOrTheFlag() {
        for ((t, hero) in listOf(dummy(700.0) to 400.0, enemy(900.0) to 600.0, flag(1000.0) to 600.0, dummy(1240.0) to 900.0, enemy(60.0) to 400.0)) {
            val c = CueLayout.arrow(t, hero, banner = true); val b = CueLayout.arrowBox(c)
            assertTrue("clear of the bar for $t: $b", b.clearOfTheBar()); assertTrue("on screen: $b", b.onScreen())
            assertTrue("from the side (targets at spec height are too tall): $c", c.dir != Dir.DOWN)
            assertTrue("beside the target", b.beside(t, if (c.dir == Dir.LEFT) 1 else -1))
            assertEquals("at mid-height", t.midY, c.y, 1e-9)
        }
    }

    @Test fun theArrowBouncesAboveATargetLowEnoughBelowTheBar() {
        val low = Target(640.0, 352.0, 410.0, 30.0)
        val c = CueLayout.arrow(low, 400.0, banner = true)
        assertEquals(Dir.DOWN, c.dir); assertTrue(CueLayout.arrowBox(c).clearOfTheBar()); assertTrue(CueLayout.arrowBox(c).bottom <= low.top)
        assertTrue("one px higher and it goes to the side", CueLayout.arrow(low.copy(top = 351.0), 400.0, true).dir != Dir.DOWN)
    }

    @Test fun withNoHeroBesideItTheArrowUsesTheSideNearerTheCentre() {
        assertEquals("target left of centre → arrow on its right, tip left", Dir.LEFT, CueLayout.arrow(dummy(300.0), null, true).dir)
        assertEquals(Dir.RIGHT, CueLayout.arrow(dummy(1000.0), null, true).dir)
    }

    /** r9 (a): on banner beats the whole goal flag (pole top and cloth) is below the bar, foot on the ground; k-independent world px. */
    @Test fun theGoalFlagSitsWhollyBelowTheBarOnBannerBeats() {
        for (k in listOf(0.40, 0.488)) { // the bar and the ground are fixed world px, so the flag's box is the same at every k
            val f = CueLayout.goalFlag(g, banner = true)
            assertEquals("k $k: size", 120.0, f.size, 1e-9)
            assertTrue("k $k: top ${f.top} ≥ 276", f.top >= CueLayout.FLOOR - 1e-9)
            assertEquals("k $k: foot on the ground", g, f.foot, 1e-9)
        }
        assertEquals("off banner beats the flag keeps 150", 150.0, CueLayout.goalFlag(g, banner = false).size, 1e-9)
        val b = CueLayout.raisedBanner(g, banner = true)
        assertTrue("the raised training banner stays below the bar too: ${b.top}", b.top >= CueLayout.FLOOR - 1e-9)
    }
}
