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
        val fp = CueLayout.finishPartner(g.run.hero.x, g.run.hero.face, g.run.cam, true, g.tuning["enemy_reach"])
        assertEquals("starts 1.2 × enemy_reach outward from its spot", fp.spawn, p0!!.x, 1e-9)
        repeat(Math.round(g.run.raiseTime / dt).toInt() + 1) { g.frame() }
        val p = g.run.partner!!
        assertEquals("stands at its spot", fp.stand, p.x, 1e-9)
        val (cl, cr) = CueLayout.bannerSpan(g.run.hero.x, g.run.hero.face, true)
        assertEquals("facing the banner", if ((cl + cr) / 2 > p.x) 1 else -1, p.face)
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

    /** r11 (leader): every resume restarts the hold; after N pauses the banner is up ≥ 0.8 s after the last resume, and it ends. */
    @Test fun everyResumeRestartsTheHoldAndItStillEnds() {
        val g = game().trainingAtSpecial(); g.tapCo()
        repeat(5) {
            repeat(30) { g.frame() } // 0.5 s of play, under the 0.83 s left after a restart
            assertEquals("still holding before pause ${it + 1}", Phase.END, g.run.phase)
            assertTrue(g.pause()); repeat(10) { g.frame() }; assertTrue(g.resume())
        }
        var up = 0.0; val s = g.untilWalk { if (g.run.raiseProgress >= 1.0) up += dt }
        assertTrue("≥ 0.8 s banner-up after the last resume: $up", up >= 0.8)
        assertEquals("the hold ended", Phase.WALK, g.run.phase)
        assertTrue("…without stalling: $s", s < g.tuning["finish_hold"])
    }

    /** r11 (QC r10 B8): partner, cloth and hero boxes stay ≥ 8 apart and on screen, near either edge, both facings. */
    @Test fun thePartnerNeverOverlapsTheBannerOrTheHero() {
        val cam = 4000.0
        for (screenX in listOf(60.0, 200.0, 640.0, 1000.0, 1045.0, 1090.0, 1220.0)) for (face in listOf(1, -1)) {
            val h = cam + screenX
            val reach = TestContent.load().tuning.values.getValue("enemy_reach").value
            val fp = CueLayout.finishPartner(h, face, cam, true, reach)
            val (cl, cr) = CueLayout.bannerSpan(h, face, true)
            val pl = fp.stand - CueLayout.FIGURE_HALF; val pr = fp.stand + CueLayout.FIGURE_HALF
            val hl = h - CueLayout.FIGURE_HALF; val hr = h + CueLayout.FIGURE_HALF
            val tag = "hero at screen x $screenX, face $face: partner ${fp.stand - cam}"
            assertTrue("$tag clear of the cloth ($cl…$cr)", pr <= cl - 8 + 1e-9 || pl >= cr + 8 - 1e-9)
            assertTrue("$tag clear of the hero", pr <= hl - 8 + 1e-9 || pl >= hr + 8 - 1e-9)
            if (screenX in 200.0..1090.0) assertTrue("$tag on screen with 8 px margin", pl >= cam + 8 - 1e-9 && pr <= cam + 1272 + 1e-9)
            val side = if (fp.stand > h) 1 else -1
            assertEquals("$tag starts 1.2 × enemy_reach outward", fp.stand + side * 1.2 * reach, fp.spawn, 1e-9)
            assertEquals("$tag fades in only when it starts on screen", fp.spawn in cam..cam + 1280, fp.fadeIn)
            assertEquals("$tag faces the banner", if ((cl + cr) / 2 > fp.stand) 1 else -1, fp.face)
        }
        // QC's case: hero near Cờ on the right, facing right → the partner stands in front (right), not behind the cloth
        val fp = CueLayout.finishPartner(cam + 1045, 1, cam, true, 100.0)
        assertEquals("front side", cam + 1045 + 110, fp.stand, 1e-9)
    }

    @Test fun trainingDummiesAreGoneWhenTheBeatEnds() {
        val g = game().trainingAtSpecial(); g.tapCo()
        assertTrue("dummies stand through the hold", g.run.dummies.isNotEmpty())
        g.untilWalk()
        assertTrue("no dummies on the next beat", g.run.dummies.isEmpty())
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
