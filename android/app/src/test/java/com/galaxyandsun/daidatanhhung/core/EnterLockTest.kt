package com.galaxyandsun.daidatanhhung.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * QC r6 B7 (Input Rule 13, tuning `screen_enter_lock` 0.6 s): a child mashing Attack (where Tiếp sits)
 * across a context change mustn't skip the new screen's first box. Presses within the lock of entering a
 * context (intro, ending, quiz, results, unlock; in play beat_card, caption and a dialogue's first line)
 * are dropped; box-to-box within one context keeps only the 0.25 s debounce; pause and sound are exempt.
 * All times are the press clock (uptime), as the platform passes them.
 */
class EnterLockTest {
    private val dt = 1.0 / 60
    private var now = 1000.0
    private fun Game.frames(s: Double, input: () -> InputFrame = { InputFrame() }) =
        repeat(Math.round(s / dt).toInt()) { step(dt, input()); now += dt }
    /** A tap as the platform does it: gated at press time, fired at release with that press time. */
    private fun Game.tap(key: String, fire: Game.() -> Boolean): Boolean {
        if (!pressAllowed(key, now)) return false
        pressAt = now; try { return fire() } finally { pressAt = null }
    }

    private fun sample() = Game(TestContent.load(), "sample", MemoryStore(), { now }) {}
    private fun tqt() = Game(TestContent.fullContent(), "tran-quoc-toan", MemoryStore(), { now }) {}

    @Test fun aMashAcrossTheLastCaptionKeepsTheFirstEndingBoxFor600ms() {
        val g = sample()
        g.debugJump("caption", beat = g.run.beats.size); g.frames(1.0)
        // The last caption line closes: the ending is entered by this press.
        while (g.screen == Screen.PLAY) { assertTrue(g.tap("next") { next() }); g.frames(0.35) }
        assertEquals(Screen.ENDING, g.screen)
        val entered = now - 0.35
        // the rolling lock (TASK-005q): a continuous 0.35 s mash keeps restarting the window until the cap
        while (g.screen == Screen.ENDING && g.line == 0 && !g.tap("next") { next() }) g.frames(0.35)
        assertTrue("the first ending box held ≥ the cap: ${now - entered}", now - entered >= g.tuning["screen_enter_lock_max"] - 1e-9)
    }

    @Test fun walkingIntoTheDialogueLocksItsFirstLine() {
        val g = tqt()
        val i = g.run.beats.indices.first { g.run.typeOf(it) == BeatType.DIALOGUE }
        g.debugJump("play", beat = i, stage = "start") // the walk beat in play; walking on enters the dialogue
        var n = 0
        while (g.run.phase != Phase.DIALOGUE && n++ < 600) g.frames(dt) { InputFrame().apply { held += Action.RIGHT } }
        assertEquals(Phase.DIALOGUE, g.run.phase)
        g.frames(0.65); assertTrue("one press at +0.65 s (none before it)", g.tap("next") { next() }); assertEquals(1, g.run.lineIndex)
    }

    @Test fun aPressInsideTheLockIsDropped() {
        val g = tqt(); g.debugJump("intro"); g.frames(0.55)
        assertFalse("+0.55 s", g.tap("next") { next() }); assertEquals(0, g.line)
    }

    @Test fun boxToBoxWithinAContextKeepsOnlyTheDebounce() {
        val g = tqt(); g.debugJump("intro"); g.frames(1.0)
        assertTrue(g.tap("next") { next() }); g.frames(0.30)
        assertTrue("line 2 → 3 at +0.30 s: no entry lock inside the intro", g.tap("next") { next() })
        assertEquals(2, g.line)
    }

    @Test fun pauseAndSoundStayTappableInTheLock() {
        val g = tqt(); g.debugJump("intro"); g.frames(0.1)
        assertTrue(g.pressAllowed("pause", now)); assertTrue(g.pressAllowed("mute", now))
        assertFalse(g.pressAllowed("next", now)); assertFalse(g.pressAllowed("skip", now))
    }

    @Test fun aPressThatStartedBeforeTheContextIsDropped() {
        val g = tqt(); g.debugJump("intro"); g.frames(1.0)
        val before = now - 0.2 // a finger already down when the intro was entered (1.0 s ago in this test's clock)
        g.debugJump("ending") // a fresh context entered now
        assertFalse(g.pressAllowed("next", before))
    }

    // ---- The rolling lock (TASK-005q): each dropped press restarts the window, capped at screen_enter_lock_max ----

    /** Mash Next every [every] s for [secs] s from now; returns the times (since entry) at which a press advanced. */
    private fun Game.mash(entered: Double, every: Double, secs: Double, stopAt: Double = 1e9): List<Double> {
        val out = mutableListOf<Double>(); var t = 0.0
        while (t < secs) { if (t <= stopAt + 1e-9 && tap("next") { next() }) out += now - entered; frames(every); t += every }
        return out
    }

    @Test fun aContinuousMashHoldsTheEndingBoxUntilTheCapThenEachBoxAgain() {
        val g = tqt(); g.debugJump("ending"); val entered = now
        g.frames(0.35)
        val adv = g.mash(entered, 0.35, 3.3)
        val cap = g.tuning["screen_enter_lock_max"]; println("B7 timeline: advances at $adv (s after ending entry)")
        assertTrue("box 1 holds ≥ the ${cap} s cap: first advance at ${adv.firstOrNull()}", adv.isNotEmpty() && adv[0] >= cap - 1e-9)
        assertTrue("box 2 (the hero's last line) also holds ≥ $cap s: $adv", adv.size < 2 || adv[1] - adv[0] >= cap - 1e-9)
    }

    @Test fun aMashThatStopsLetsTheNextTapThroughALockAfterTheLastDroppedPress() {
        val g = tqt(); g.debugJump("ending"); val entered = now
        g.frames(0.4); assertFalse(g.tap("next") { next() })   // +0.4 dropped → window to 1.0
        g.frames(0.4); assertFalse(g.tap("next") { next() })   // +0.8 dropped → window to 1.4
        g.frames(0.59); assertFalse("+1.39 still inside", g.tap("next") { next() }) // dropped → window to min(1.99, 1.5)
        g.frames(0.15); assertTrue("past the 1.5 s cap", g.tap("next") { next() })
        assertTrue(now - entered < 1.6)
    }

    @Test fun pauseStaysTappableInsideTheRollingWindow() {
        val g = tqt(); g.debugJump("ending")
        repeat(3) { g.frames(0.35); assertFalse(g.tap("next") { next() }); assertTrue(g.pressAllowed("pause", now)) }
    }
}
