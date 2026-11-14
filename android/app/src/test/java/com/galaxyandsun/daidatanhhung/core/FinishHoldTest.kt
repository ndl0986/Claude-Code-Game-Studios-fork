package com.galaxyandsun.daidatanhhung.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.abs

/**
 * Mission flow Rule 7c / AC32 (r10): on the TQT training beat (beat 4, index 3, finish_special) the end after the
 * Cờ tap lasts finish_hold (1.5 s) instead of end_pause: pads hide, the banner rises over 0.67 s and stays up, the
 * partner re-enters beside the hero, taps are dropped, and a resume restarts the hold once.
 */
class FinishHoldTest {
    private val dt = 1.0 / 60

    private fun game(): Game = Game(TestContent.load(), "tran-quoc-toan", MemoryStore()) {}
    private fun Game.trainingAtSpecial(): Game {
        val i = run.beats.indices.first { run.typeOf(it) == BeatType.TRAINING }
        debugJump("play", beat = i + 1, stage = "special"); return this
    }
    private fun Game.frame(tap: Set<Action> = emptySet()) = step(dt, InputFrame().apply { tapped += tap })
    private fun Game.tapCo() { frame(setOf(Action.SPECIAL)); assertEquals("the Cờ tap ends the beat's play", Phase.END, run.phase) }
    /** Steps until the hero walks again (the next beat's walk_to); returns the seconds it took. */
    private fun Game.untilWalk(each: () -> Unit = {}): Double {
        var s = 0.0; while (run.phase == Phase.END && s < 10) { each(); frame(); s += dt }; return s
    }

    @Test fun theHoldLastsFinishHoldAndHidesEveryPad() {
        val g = game().trainingAtSpecial()
        assertTrue("Cờ is shown before the tap", "special" in g.run.visibleButtons())
        g.tapCo()
        assertTrue("finish_holding", g.run.finishHolding)
        assertEquals("every pad hides at the tap", emptySet<String>(), g.run.visibleButtons())
        val s = g.untilWalk()
        assertTrue("the walk starts ≥ 1.5 s after the tap, not before: $s", s >= g.tuning["finish_hold"] - dt - 1e-9)
        assertTrue("…and not much later: $s", s <= g.tuning["finish_hold"] + 2 * dt)
        assertEquals(Phase.WALK, g.run.phase)
    }

    @Test fun theBannerIsUpForAtLeast08sAfterTheRise() {
        val g = game().trainingAtSpecial(); g.tapCo()
        var up = 0.0
        g.untilWalk { if (g.run.raiseProgress >= 1.0) up += dt }
        assertTrue("banner-up ≥ 0.8 s after the 0.67 s rise: $up", up >= 0.8)
    }

    @Test fun thePartnerReentersBesideTheHeroFacingHimBeforeTheHoldEnds() {
        val g = game().trainingAtSpecial(); g.tapCo()
        val p0 = g.run.partner; assertNotNull("the partner re-enters at the hold start", p0)
        val start = abs(p0!!.x - g.run.hero.x)
        assertEquals("from 1.2 × enemy_reach", 1.2 * g.tuning["enemy_reach"], start, 1.0)
        repeat(Math.round(g.run.raiseTime / dt).toInt() + 1) { g.frame() }
        val p = g.run.partner!!
        assertEquals("beside the hero", MissionRun.FINISH_PARTNER_GAP, abs(p.x - g.run.hero.x), 0.5)
        assertEquals("facing the hero and his banner", if (g.run.hero.x > p.x) 1 else -1, p.face)
        assertTrue("staff upright (slice fist)", p.staffUp)
        assertTrue("the hold is still on", g.run.finishHolding)
    }

    @Test fun tapsThroughTheHoldAreDroppedNotCarried() {
        val g = game().trainingAtSpecial(); g.tapCo()
        val x0 = g.run.hero.x; var s = 0.0; var n = 0
        while (g.run.phase == Phase.END && s < 10) {
            val tap = if (n++ % 12 == 0) setOf(Action.SPECIAL, Action.ATTACK, Action.RIGHT) else emptySet() // every 0.2 s
            g.frame(tap); s += dt
        }
        assertTrue("taps don't shorten the hold: $s", s >= g.tuning["finish_hold"] - dt - 1e-9)
        assertEquals("the hero didn't move during the hold", x0, g.run.hero.x, 1e-9)
        assertFalse("no tap carried into the walk (no swing)", g.run.hero.atk >= 0)
    }

    @Test fun pauseAt03ThenResumeStillShowsTheBannerUpFor08s() {
        val g = game().trainingAtSpecial(); g.tapCo()
        repeat(18) { g.frame() } // +0.3 s
        assertTrue(g.pause()); repeat(120) { g.frame() }; assertTrue(g.resume())
        var up = 0.0; g.untilWalk { if (g.run.raiseProgress >= 1.0) up += dt }
        assertTrue("banner-up ≥ 0.8 s after the resume: $up", up >= 0.8)
    }

    /** Leader r10: pausing again and again can't keep the hold going; the restart happens once per hold. */
    @Test fun repeatedPauseResumeCannotLoopTheHold() {
        val g = game().trainingAtSpecial(); g.tapCo()
        var s = 0.0
        while (g.run.phase == Phase.END && s < 20) {
            repeat(30) { g.frame(); s += dt } // 0.5 s of play
            if (g.run.phase != Phase.END) break
            assertTrue(g.pause()); g.frame(); assertTrue(g.resume())
        }
        assertEquals("the hold ended", Phase.WALK, g.run.phase)
        assertTrue("within one restart: $s s of play", s <= g.tuning["finish_hold"] + (g.tuning["finish_hold"] - g.run.raiseTime) + 0.6)
    }

    @Test fun everyOtherBeatStillEndsAfterEndPause() {
        val g = Game(TestContent.noEnterLock(TestContent.load()), "tran-quoc-toan", MemoryStore()) {}
        g.debugJump("play", beat = 1) // walk beat 1 (river): through its card, then walk to its end
        var n = 0
        while (g.run.phase != Phase.END && n++ < 60 * 60) {
            if (g.run.phase == Phase.CARD) { g.next(); repeat(20) { g.frame() } }
            else g.step(dt, InputFrame().apply { held += Action.RIGHT })
        }
        assertEquals(Phase.END, g.run.phase); assertFalse(g.run.finishHolding)
        var s = 0.0; while (g.run.phase == Phase.END && s < 5) { g.frame(); s += dt }
        assertEquals("end_pause", g.tuning["end_pause"], s, 2 * dt)
    }
}
