package com.galaxyandsun.daidatanhhung.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * QC r3 B1 (third round): two activations 0.15 s apart advance exactly once on every story
 * advance path, intro, beat card, caption, dialogue Tiếp, ask and ending (Input Rule 12, F3:
 * press-time, one global clock, `advance_debounce` 0.25 s); 0.30 s apart advance twice.
 */
class StoryDebounceTest {
    private val dt = 1.0 / 60

    private fun game() = TestContent.fullGame()
    private fun Game.wait(s: Double) = repeat(Math.round(s / dt).toInt()) { step(dt, InputFrame()) }
    private fun beatOf(g: Game, type: BeatType) = g.run.beats.indices.first { g.run.typeOf(it) == type } + 1

    /** A "tap" as the platform layer does it: the press is gated at press time, then fires on release. */
    private fun Game.tap(key: String, fire: Game.() -> Boolean): Boolean = pressAllowed(key) && fire()

    private fun check(name: String, setup: (Game) -> Unit, state: (Game) -> Any, key: String = "next", fire: Game.() -> Boolean = { next() }) {
        for ((gap, advances) in listOf(0.15 to 1, 0.30 to 2)) {
            val g = game(); setup(g); g.wait(0.5) // past any debounce left from setup
            val s0 = state(g)
            assertTrue("$name: first tap", g.tap(key, fire))
            val s1 = state(g)
            g.wait(gap)
            val second = g.tap(key, fire)
            val s2 = state(g)
            assertTrue("$name: first tap advanced", s1 != s0)
            if (advances == 1) { assertFalse("$name: second tap at +$gap s must be ignored", second); assertEquals("$name at +$gap s", s1, s2) }
            else assertTrue("$name: second tap at +$gap s must advance", second && s2 != s1)
        }
    }

    @Test fun intro() = check("intro", { it.debugJump("intro") }, { it.screen to it.line })

    @Test fun beatCard() = check("card", { it.debugJump("play", beat = beatOf(it, BeatType.WALK), stage = "card") }, { it.run.phase to it.run.cardLine })

    @Test fun dialogueNext() = check("dialogue Tiếp", { it.debugJump("play", beat = beatOf(it, BeatType.DIALOGUE), stage = "line", line = 5) }, { it.run.lineIndex }) // lines 5–7 show Tiếp (ask is on 2–3)

    @Test fun dialogueAsk() {
        val setup = { g: Game ->
            val i = beatOf(g, BeatType.DIALOGUE)
            val at = g.run.mission.beats[i - 1].let { ContentLoaderHelper.askAt(it) }
            g.debugJump("play", beat = i, stage = "line", line = at)
        }
        check("dialogue ask", setup, { it.run.lineIndex to it.run.asksDone }, key = "ask") { ask() }
    }

    @Test fun ending() = check("ending", { it.debugJump("ending") }, { it.screen to it.line })

    /**
     * QC r3 B1 root cause: the debounce must compare the presses' own times, not the sim clock. A
     * slow frame after the first advance (the next box's picture loading) moves the sim clock by up
     * to 0.25 s before the second press is even handled; that press, made 0.15 s after the first,
     * must still be ignored.
     */
    @Test fun aFrameStallBetweenTwoPressesDoesNotLetTheSecondThrough() {
        var real = 100.0 // the platform's uptime clock, s
        val g = Game(TestContent.noEnterLock(TestContent.fullContent()), "tran-quoc-toan", MemoryStore(), { real }) {}
        g.debugJump("intro"); g.wait(0.5); real += 0.5
        assertTrue(g.pressAllowed("next", real)); g.pressAt = real; assertTrue(g.next()); g.pressAt = null
        val tap1 = real
        repeat(15) { g.step(dt, InputFrame()) } // one 0.25 s stalled frame, then a little more
        real = tap1 + 0.15 // the second press happened 0.15 s after the first
        assertFalse("pressed 0.15 s after an advance, after a frame stall", g.pressAllowed("next", real))
        g.pressAt = real; assertFalse(g.next()); g.pressAt = null
        assertEquals(1, g.line)
        real = tap1 + 0.30
        assertTrue(g.pressAllowed("next", real)); g.pressAt = real; assertTrue(g.next()); g.pressAt = null
        assertEquals(2, g.line)
    }

    @Test fun caption() {
        // The real TQT mission has no fight beat (so no caption); use the sample hero's fight caption.
        for ((gap, advances) in listOf(0.15 to 1, 0.30 to 2)) {
            val g = TestContent.game(); g.debugJump("caption", beat = 2); g.wait(0.5) // beat 2 has 2 scene lines
            val s0 = g.run.beat to g.run.captionLine
            assertTrue(g.tap("next") { next() }); val s1 = g.run.beat to g.run.captionLine
            g.wait(gap); val second = g.tap("next") { next() }; val s2 = g.run.beat to g.run.captionLine
            assertTrue("caption first tap advanced", s1 != s0)
            if (advances == 1) assertEquals("caption at +$gap s", s1, s2) else assertTrue(second && s2 != s1)
        }
    }

    /** Input Rule 3 / Mission flow States (W7): pause from the story screens and results returns to the same screen and line. */
    @Test fun pauseFromStoryScreensAndResultsResumesThere() {
        for (target in listOf("intro", "ending", "results")) {
            val g = game(); g.debugJump(target); g.wait(0.5)
            if (target != "results") { g.next(); g.wait(0.5) }
            val at = g.screen to g.line
            assertTrue("$target: pause", g.pause()); assertEquals(Screen.PAUSE, g.screen)
            assertTrue(g.resume()); assertEquals("$target: resumed", at, g.screen to g.line)
        }
        val g = game(); g.debugJump("title"); assertFalse("no pause on the title", g.pause())
    }
}

/** The dialogue's ask at_line (1-based), read from the beat params. */
object ContentLoaderHelper {
    fun askAt(b: com.galaxyandsun.daidatanhhung.core.content.Beat): Int =
        com.galaxyandsun.daidatanhhung.core.content.ContentLoader.dialogueParams(b)!!.ask!!.atLine
}
