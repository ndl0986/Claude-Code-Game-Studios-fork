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
        repeat(g.bundle.mission.intro.size) { repeat(20) { g.step(dt, InputFrame()) }; g.next() }
        assertEquals(Screen.PLAY, g.screen)
    }

    @Test fun quizRetryUntilRightThenResultsStarsAndUnlock() {
        val store = MemoryStore()
        val g = TestContent.game(store)
        g.jumpKeepingSaveForTest("ending") // a real run's saves
        repeat(g.bundle.mission.ending.lines.size) { repeat(20) { g.step(dt, InputFrame()) }; g.next() }
        assertEquals(Screen.QUIZ, g.screen)
        val q = g.quiz!!
        assertEquals(4, q.questions.size)
        var wrongs = 0
        while (g.screen == Screen.QUIZ) {
            val cur = q.current
            if (wrongs < 3) { assertEquals(PickResult.WRONG, g.answer((cur.correctIndex + 1) % 3)); wrongs++
                assertEquals(PickResult.IGNORED, g.answer(cur.correctIndex)) // during the 0.5 s shake (AC6)
                repeat(31) { g.step(dt, InputFrame()) } }
            assertEquals(PickResult.RIGHT, g.answer(cur.correctIndex))
            assertFalse(g.next()) // no Next before feedback_time (AC5)
            repeat(60) { g.step(dt, InputFrame()) }
            assertEquals(Screen.QUIZ, g.screen) // never auto-advances
            assertTrue(g.next())
        }
        assertEquals(Screen.RESULTS, g.screen)
        assertEquals(3, g.retries)
        assertEquals(1, g.stars)
        assertEquals(1, store.stars("sample"))
        assertTrue(store.flag("completed.sample")) // saved at quiz finish, before results (D-16)
        // sample2 is not a bundled hero, so nothing newly opens: results goes to the title.
        repeat(20) { g.step(dt, InputFrame()) }
        g.next(); assertEquals(Screen.TITLE, g.screen)
    }

    @Test fun bestStarsAreNeverLowered() {
        val store = MemoryStore().apply { starMap["sample"] = 3 }
        val g = TestContent.game(store)
        g.debugJump("quiz")
        while (g.screen == Screen.QUIZ) { g.answer((g.quiz!!.current.correctIndex + 1) % 3); repeat(31) { g.step(dt, InputFrame()) }; g.answer(g.quiz!!.current.correctIndex); repeat(60) { g.step(dt, InputFrame()) }; g.next() }
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

    @Test fun pauseOnTheQuizSwitchesLanguageAndReturns() {
        val g = TestContent.game()
        g.debugJump("quiz")
        assertTrue(g.pause()); assertTrue(g.toggleLang()); assertTrue(g.resume())
        assertEquals(Screen.QUIZ, g.screen); assertEquals(Lang.EN, g.lang)
    }

    @Test fun resumeResetsTheHintTimers() {
        val g = TestContent.game()
        g.debugJump("play")
        repeat(400) { g.step(dt, InputFrame()) }
        assertTrue(g.run.pulseRight)
        g.pause(); g.resume()
        assertFalse(g.run.pulseRight && g.run.idle > 0)
        assertEquals(0.0, g.run.idle, 0.0)
    }

    @Test fun fullMissionPlaysToTheEnding() {
        val g = TestContent.game()
        g.start(); repeat(g.bundle.mission.intro.size) { repeat(20) { g.step(dt, InputFrame()) }; g.next() }
        var n = 0
        while (g.screen == Screen.PLAY && n++ < 60 * 600) {
            val i = InputFrame()
            if (g.run.phase == Phase.CAPTION || g.run.phase == Phase.CARD) { repeat(20) { g.step(dt, InputFrame()) }; g.next(); continue }
            if (g.run.phase == Phase.WALK) i.held += Action.RIGHT
            // Face the nearest enemy (a child turns toward it), then swing.
            val near = g.run.enemies.filter { it.state != EnemyState.FLEE }.minByOrNull { kotlin.math.abs(it.x - g.run.hero.x) }
            if (near != null && (near.x - g.run.hero.x) * g.run.hero.face < 0) i.held += if (near.x < g.run.hero.x) Action.LEFT else Action.RIGHT
            else if (n % 18 == 0) i.tapped += Action.ATTACK
            g.step(dt, i)
        }
        assertEquals(Screen.ENDING, g.screen)
        assertEquals(g.bundle.mission.beats.size, g.run.beat)
    }
}
