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
        var t = 0.35
        while (t < 0.6 - 1e-9) { assertFalse("mash at +$t s", g.tap("next") { next() }); assertEquals(0, g.line); g.frames(0.35); t += 0.35 }
        assertTrue("the first press after the lock advances", g.tap("next") { next() })
        assertTrue("it moved on (the sample ending may have one box)", g.screen != Screen.ENDING || g.line == 1)
        assertTrue(now - entered >= 0.6)
    }

    @Test fun walkingIntoTheDialogueLocksItsFirstLine() {
        val g = tqt()
        val i = g.run.beats.indices.first { g.run.typeOf(it) == BeatType.DIALOGUE }
        g.debugJump("play", beat = i, stage = "start") // the walk beat in play; walking on enters the dialogue
        var n = 0
        while (g.run.phase != Phase.DIALOGUE && n++ < 600) g.frames(dt) { InputFrame().apply { held += Action.RIGHT } }
        assertEquals(Phase.DIALOGUE, g.run.phase)
        g.frames(0.59); assertFalse("+0.59 s", g.tap("next") { next() }); assertEquals(0, g.run.lineIndex)
        g.frames(0.02); assertTrue("+0.61 s", g.tap("next") { next() }); assertEquals(1, g.run.lineIndex)
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
}
