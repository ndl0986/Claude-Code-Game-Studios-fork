package com.galaxyandsun.daidatanhhung.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Mission flow Rule 11 / pause.md AC6 (TASK-020 W18): the pause menu's "Về bản đồ" asks first. The leave card's
 * "Chơi tiếp" returns to the menu with the run intact; only its "Về bản đồ" discards the run and shows the title
 * (the map screen isn't built yet, TASK-025). Its buttons take the entry lock while it slides in (Input Rule 13).
 */
class LeaveCardTest {
    private val dt = 1.0 / 60
    private fun game() = TestContent.fullGame()
    private fun Game.wait(s: Double) = repeat(Math.round(s / dt).toInt()) { step(dt, InputFrame()) }

    private fun pausedMidMission(): Game {
        val g = game(); g.debugJump("play", beat = 3); g.wait(1.0)
        assertTrue(g.pause()); return g
    }

    @Test fun toTheMapOpensTheCardAndDiscardsNothing() {
        val g = pausedMidMission(); val beat = g.run.beat; val x = g.run.hero.x
        assertTrue(g.askLeave()); assertTrue(g.leaveCard)
        assertEquals(Screen.PAUSE, g.screen); assertEquals(beat, g.run.beat); assertEquals(x, g.run.hero.x, 0.0)
        assertFalse("resume is not live under the card", g.resume())
    }

    @Test fun keepPlayingReturnsToTheMenuWithTheRunIntact() {
        val g = pausedMidMission(); val beat = g.run.beat; val x = g.run.hero.x
        g.askLeave(); g.wait(0.5)
        assertTrue(g.keepPlaying()); assertFalse(g.leaveCard); assertEquals(Screen.PAUSE, g.screen)
        assertTrue(g.resume()); assertEquals(Screen.PLAY, g.screen); assertEquals(beat, g.run.beat); assertEquals(x, g.run.hero.x, 0.0)
    }

    @Test fun onlyTheCardsToTheMapLeavesAndShowsTheTitle() {
        val g = pausedMidMission()
        assertFalse("the menu can't leave without the card", g.home() || g.leave())
        g.askLeave(); g.wait(0.5)
        assertTrue(g.leave()); assertEquals(Screen.TITLE, g.screen); assertFalse(g.leaveCard)
        assertTrue("a new start begins from the intro", g.start()); assertEquals(Screen.INTRO, g.screen); assertEquals(1, g.run.beat + 1)
    }

    @Test fun theCardsButtonsTakeTheEntryLockWhileItSlidesIn() {
        var real = 100.0
        val g = Game(TestContent.fullContent(), "tran-quoc-toan", MemoryStore(), { real }) {}
        g.debugJump("play", beat = 3); g.wait(1.0); real += 1.0
        g.pause(); assertTrue("the pause menu is exempt", g.pressAllowed("pausemap", real))
        g.askLeave()
        assertFalse("pressed as the card opens", g.pressAllowed("leavego", real + 0.05))
        assertFalse(g.pressAllowed("leavekeep", real + 0.05))
        assertTrue("after the lock", g.pressAllowed("leavego", real + 1.5))
    }

    @Test fun closingTheCardDoesntLockTheMenuAgain() {
        var real = 100.0
        val g = Game(TestContent.fullContent(), "tran-quoc-toan", MemoryStore(), { real }) {}
        g.debugJump("play", beat = 3); g.wait(1.0); real += 1.0
        g.pause(); g.askLeave(); real += 1.5; g.keepPlaying()
        assertTrue(g.pressAllowed("resume", real + 0.01))
        g.resume(); assertEquals(Screen.PLAY, g.screen)
    }

    @Test fun aNewPauseNeverReopensAnOldCard() {
        val g = pausedMidMission(); g.askLeave(); g.keepPlaying(); g.resume(); g.wait(0.2)
        assertTrue(g.pause()); assertFalse(g.leaveCard)
    }

    @Test fun theLineLoadsInBothLanguages() {
        val g = game()
        assertEquals("Về bản đồ?", g.ui(UiIds.LEAVE_CONFIRM))
        g.debugJump("title"); g.forceLang("en"); assertEquals("Leave the story?", g.ui(UiIds.LEAVE_CONFIRM))
    }
}
