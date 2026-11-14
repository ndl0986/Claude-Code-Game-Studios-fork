package com.galaxyandsun.daidatanhhung.core

import com.galaxyandsun.daidatanhhung.core.content.Lang
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class GameFlowTest {
    private val dt = 1.0 / 60

    @Test fun languageDefaultsToVietnameseAndIsRemembered() {
        val store = MemoryStore()
        val g = TestContent.game(store)
        assertEquals(Lang.VI, g.lang)
        assertTrue(g.toggleLang())
        assertEquals("en", store.langCode)
        assertEquals(Lang.EN, TestContent.game(store).lang)
    }

    @Test fun languageToggleOnlyOnTitleAndPause() {
        val g = TestContent.game()
        g.start(); assertEquals(Screen.INTRO, g.screen)
        assertFalse(g.toggleLang())
    }

    @Test fun introThenPlay() {
        val g = TestContent.game()
        g.start()
        repeat(g.bundle.mission.intro.size) { g.next() }
        assertEquals(Screen.PLAY, g.screen)
    }

    @Test fun quizRetryUntilRightThenResultsStarsAndUnlock() {
        val store = MemoryStore()
        val g = TestContent.game(store)
        g.debugJump("ending")
        repeat(g.bundle.mission.ending.lines.size) { g.next() }
        assertEquals(Screen.QUIZ, g.screen)
        val q = g.quiz!!
        assertEquals(4, q.questions.size)
        var wrongs = 0
        while (g.screen == Screen.QUIZ) {
            val cur = q.current
            if (wrongs < 3) { assertEquals(PickResult.WRONG, g.answer((cur.correctIndex + 1) % 3)); wrongs++ }
            assertEquals(PickResult.RIGHT, g.answer(cur.correctIndex))
            repeat(60) { g.step(dt, InputFrame()) }
        }
        assertEquals(Screen.RESULTS, g.screen)
        assertEquals(3, g.retries)
        assertEquals(1, g.stars)
        assertEquals(1, store.stars("sample"))
        assertTrue("sample2" in store.unlocked())
        g.next(); assertEquals(Screen.UNLOCK, g.screen)
        g.home(); assertEquals(Screen.TITLE, g.screen)
    }

    @Test fun bestStarsAreNeverLowered() {
        val store = MemoryStore().apply { starMap["sample"] = 3 }
        val g = TestContent.game(store)
        g.debugJump("quiz")
        while (g.screen == Screen.QUIZ) { g.answer((g.quiz!!.current.correctIndex + 1) % 3); g.answer(g.quiz!!.current.correctIndex); repeat(60) { g.step(dt, InputFrame()) } }
        assertEquals(3, store.stars("sample"))
    }

    @Test fun pauseFreezesPlay() {
        val g = TestContent.game()
        g.debugJump("play")
        val i = InputFrame().apply { held += Action.RIGHT }
        g.step(dt, i); val x = g.run.hero.x
        g.pause(); repeat(30) { g.step(dt, i) }
        assertEquals(x, g.run.hero.x, 0.0)
        g.resume(); g.step(dt, i)
        assertTrue(g.run.hero.x > x)
    }

    @Test fun fullMissionPlaysToTheEnding() {
        val g = TestContent.game()
        g.start(); repeat(g.bundle.mission.intro.size) { g.next() }
        var n = 0
        while (g.screen == Screen.PLAY && n++ < 60 * 600) {
            val i = InputFrame()
            if (g.run.phase == Phase.CAPTION) { g.next(); continue }
            if (g.run.phase == Phase.WALK) i.held += Action.RIGHT
            // Face the nearest enemy (a child turns toward it), then swing.
            val near = g.run.enemies.filter { it.state != EnemyState.FLEE }.minByOrNull { kotlin.math.abs(it.x - g.run.hero.x) }
            if (near != null && (near.x - g.run.hero.x) * g.run.hero.face < 0) i.held += if (near.x < g.run.hero.x) Action.LEFT else Action.RIGHT
            else if (n % 18 == 0) i.tapped += Action.ATTACK
            g.step(dt, i)
        }
        assertEquals(Screen.ENDING, g.screen)
        assertEquals(4, g.run.beat)
    }
}
