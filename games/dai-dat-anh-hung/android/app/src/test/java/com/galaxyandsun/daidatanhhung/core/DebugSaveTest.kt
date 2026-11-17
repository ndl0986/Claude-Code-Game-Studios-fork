package com.galaxyandsun.daidatanhhung.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * r12, parity with iOS r9: a debug-jumped run writes no progress (stars, medal, `completed`, `seen_open`) to the real
 * save. Progress still updates in memory so results show; the language setting is still saved. A real start still
 * writes everything. A fresh install's title shows no stars and no medal after any debug path.
 */
class DebugSaveTest {
    private val dt = 1.0 / 60
    private val hero = "tran-quoc-toan"
    private fun game(store: Store) = Game(TestContent.fullContent(), hero, store, null) {}
    private fun Game.idle() = repeat(40) { step(dt, InputFrame()) }

    /** Fresh-install save after construction: the title load marks only the first hero seen open. */
    private fun freshFlags() = MemoryStore().also { game(it) }.flags.toSet()

    private fun assertNoProgress(real: MemoryStore, what: String) {
        assertTrue("$what: no stars in the real save", real.starMap.isEmpty())
        assertEquals("$what: no progress flags", freshFlags(), real.flags.toSet())
        val title = game(real)
        assertEquals("$what: title stars", 0, title.bestStars)
        assertFalse("$what: title medal", title.medalEarned)
    }

    private fun Game.answerAllRight() {
        var guard = 0; while (screen == Screen.QUIZ && guard++ < 50) { answer(quiz!!.current.correctIndex); idle(); next() }
    }

    @Test fun aJumpedQuizAnsweredAllRightWritesNothing() {
        val real = MemoryStore(); val g = game(real)
        g.debugJump("quiz"); g.answerAllRight()
        assertEquals(Screen.RESULTS, g.screen); assertEquals(3, g.stars)
        assertTrue("results show the medal from memory", g.medalEarned && g.medalThisRun)
        assertTrue(g.debugJumped)
        assertNoProgress(real, "jumped quiz")
    }

    @Test fun aJumpedPlayRunCarriedToResultsWritesNothing() {
        val real = MemoryStore(); val g = game(real)
        g.debugJump("ending"); repeat(g.bundle.mission.ending.lines.size) { g.idle(); g.next() }
        assertEquals(Screen.QUIZ, g.screen); g.answerAllRight()
        assertEquals(Screen.RESULTS, g.screen)
        assertNoProgress(real, "jumped run to results")
    }

    @Test fun everyJumpTargetLeavesTheRealSaveWithoutProgress() {
        for (t in listOf("title", "intro", "play", "caption", "pause", "skipwarn", "ending", "quiz", "results", "unlock")) {
            val real = MemoryStore(); game(real).debugJump(t, question = 99, stage = "newmedal", starCount = 3)
            assertNoProgress(real, t)
        }
    }

    @Test fun aJumpedRunStillSavesTheLanguageAndSound() {
        val real = MemoryStore(); val g = game(real)
        g.debugJump("title"); g.forceLang("en"); g.toggleMute()
        assertEquals("en", real.langCode); assertEquals(false, real.soundOn)
    }

    @Test fun aRealStartStillWritesEverything() {
        val real = MemoryStore(); val g = game(real)
        g.jumpKeepingSaveForTest("quiz"); g.answerAllRight()
        assertEquals(3, real.stars(hero))
        assertTrue(real.flag("medal.$hero")); assertTrue(real.flag("completed.$hero"))
        assertFalse(g.debugJumped)
    }
}
