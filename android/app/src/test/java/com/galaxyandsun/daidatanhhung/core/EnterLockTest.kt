package com.galaxyandsun.daidatanhhung.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * QC r6 B7 (Input Rule 13, tuning `screen_enter_lock` 0.6 s): a child mashing Attack (where Tiếp sits)
 * across a context change mustn't skip the new screen's first box. Presses within the lock of entering a
 * context (intro, ending, quiz, results, unlock; in play beat_card, caption and a dialogue's first line)
 * are dropped; since r8 every story box and dialogue line takes the lock too (Input 13b); pause and sound are exempt.
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

    /** Input Rule 13b (QC r7, r8): the next box of the same screen takes the lock too, so +0.30 s is dropped, +0.6 s passes. */
    @Test fun everyBoxTakesTheLock() {
        val g = tqt(); g.debugJump("intro"); g.frames(1.0)
        assertTrue(g.tap("next") { next() }); g.frames(0.30)
        assertFalse("line 2 → 3 at +0.30 s: box 2 has its own entry lock", g.tap("next") { next() })
        assertEquals(1, g.line)
        g.frames(0.65); assertTrue("a deliberate tap 0.6 s after the last press", g.tap("next") { next() })
        assertEquals(2, g.line)
    }

    /** The quiz keeps its own rules (Input 13b): at normal k the next question takes no lock, only the debounce. */
    @Test fun quizQuestionsTakeNoLockAtNormalK() {
        val g = tqt(); g.debugJump("quiz", stage = "right"); g.frames(2.0)
        val q0 = g.quiz!!.index
        assertTrue(g.tap("next") { next() }); assertEquals(q0 + 1, g.quiz!!.index)
        g.frames(0.30)
        assertTrue("a card pick at +0.30 s on the new question", g.tap("card0") { answer(quiz!!.order[0]) != PickResult.IGNORED })
    }

    /** Presses every [every] s on whatever advances the screen; returns each box's hold time (from its appearance to its advance). */
    private fun Game.mashBoxes(state: Game.() -> Any?, press: Game.() -> Boolean, every: Double = 0.35, maxS: Double = 40.0): List<Double> {
        val holds = mutableListOf<Double>(); var shown = now; var s = state(); var t = 0.0
        while (t < maxS) {
            if (press()) { val s2 = state(); if (s2 != s) { holds += now - shown; shown = now; s = s2 } }
            if (s == null) break
            frames(every); t += every
        }
        return holds
    }

    /** Input AC22 / dialogue AC8: a 0.35 s mash from entry through the Bình Than dialogue (9 lines); ask taps count as advances. */
    @Test fun aMashHoldsEveryDialogueLine() {
        val g = tqt()
        val i = g.run.beats.indices.first { g.run.typeOf(it) == BeatType.DIALOGUE }
        g.debugJump("play", beat = i + 1, stage = "line", line = 1); val n = g.run.dialogue!!.lines.size
        val seen = mutableListOf<Int>()
        val holds = g.mashBoxes({ if (run.phase == Phase.DIALOGUE) run.lineIndex.also { if (seen.lastOrNull() != it) seen += it } else null },
            { if (run.dialogueButton == "ask") tap("ask") { ask() } else tap("next") { next() } })
        val cap = g.tuning["screen_enter_lock_max"]; println("AC22 holds: $holds")
        assertEquals("9 lines", 9, n)
        assertEquals("every line shown, none skipped", (0 until n).toList(), seen)
        assertTrue("every line held ≥ $cap s: $holds", holds.size >= n && holds.all { it >= cap - 1e-9 })
    }

    /** Story AC11: a 0.35 s mash holds every box of the intro, a beat card, a caption and the ending ≥ 1.5 s. */
    @Test fun aMashHoldsEveryStoryBox() {
        val cap = TestContent.load().tuning.let { Tuning.from(it)["screen_enter_lock_max"] }
        fun check(name: String, g: Game, state: Game.() -> Any?) {
            val holds = g.mashBoxes(state, { tap("next") { next() } })
            println("AC11 $name holds: $holds")
            assertTrue("$name: ≥ 2 boxes advanced: $holds", holds.size >= 2)
            assertTrue("$name: every box held ≥ $cap s: $holds", holds.all { it >= cap - 1e-9 })
        }
        tqt().let { g -> g.debugJump("intro"); check("intro", g) { if (screen == Screen.INTRO) line else null } }
        tqt().let { g -> g.debugJump("ending"); check("ending", g) { if (screen == Screen.ENDING) line else null } }
        tqt().let { g -> g.debugJump("play", beat = 1, stage = "card"); assertTrue("beat 1 card has ≥ 2 boxes", g.run.cardBoxes().size >= 2)
            check("beat card", g) { if (run.phase == Phase.CARD) run.cardLine else null } }
        sample().let { g -> g.debugJump("caption", beat = 2); check("caption", g) { if (run.phase == Phase.CAPTION && run.beat == 1) run.captionLine else null } }
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

    /** QC r6 (cost a medal): a ◀ tap landing on Bỏ qua as a card appears must not open the skip warning or skip. */
    @Test fun aLeftPadTapOnBoQuaAsACardAppearsDoesNothing() {
        val g = tqt()
        g.debugJump("play", beat = 1) // walk_to the first beat: walking on enters its card
        var n = 0
        while (g.run.phase != Phase.CARD && n++ < 900) g.frames(dt) { InputFrame().apply { held += Action.RIGHT } }
        assertEquals(Phase.CARD, g.run.phase)
        g.frames(0.2)
        assertFalse("Bỏ qua inside the lock", g.tap("skip") { skip() })
        assertFalse(g.skipWarning); assertEquals(Phase.CARD, g.run.phase); assertEquals(0, g.run.cardLine)
        assertFalse(g.medalEarned)
    }
}
