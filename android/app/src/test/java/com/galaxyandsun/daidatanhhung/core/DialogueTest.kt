package com.galaxyandsun.daidatanhhung.core

import com.galaxyandsun.daidatanhhung.core.content.Beat
import com.galaxyandsun.daidatanhhung.core.content.ContentLoader
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** The dialogue beat (mission-flow Rule 7d, AC23/AC25), on a test mission until TASK-016's data lands. */
class DialogueTest {
    private val dt = 1.0 / 60
    private fun idle(g: Game, n: Int = 20) = repeat(n) { g.step(dt, InputFrame()) }

    private fun line(i: Int, speaker: String) = """{"speaker":"$speaker","text":{"id":"t.d.$i","vi":"Câu $i.","en":"Line $i.","claims":["C01"]}}"""
    private val dialogueBeat: Beat = ContentLoader.JSON.decodeFromString(Beat.serializer(), """
        {"id":"t.dlg","type":"dialogue","buttons":[],"title":{"id":"t.dlg.title","vi":"Bến","en":"Pier","claims":["C01"]},
         "scene":[],"theme":"river","params":{"lines":[${line(1, "narrator")},${line(2, "hero")},${line(3, "guard")},${line(4, "hero")},${line(5, "king")}],
         "ask":{"button":{"id":"t.dlg.ask","vi":"Xin vào!","en":"Let me in!","claims":["C01"]},"taps":2,"at_line":2}}}""")

    /** The full content with a dialogue beat put first in the TQT mission. */
    private fun game(store: Store = MemoryStore()): Game {
        val c = TestContent.fullContent(); val h = c.heroes.getValue("tran-quoc-toan")
        val m = h.mission.copy(beats = listOf(dialogueBeat) + h.mission.beats)
        return Game(TestContent.noEnterLock(c.copy(heroes = mapOf("tran-quoc-toan" to h.copy(mission = m)))), "tran-quoc-toan", store) {}
    }

    private fun toDialogue(g: Game) {
        g.start(); while (g.screen == Screen.INTRO) { idle(g); g.next() }
        var n = 0
        while (g.run.phase == Phase.WALK && n++ < 2000) g.step(dt, InputFrame().apply { held += Action.RIGHT })
    }

    /** AC23: Tiếp on line 1; the ask button on lines 2 and 3, each tap one line; Tiếp from line 4; no pads at any point. */
    @Test fun ac23AskTiming() {
        val g = game(); toDialogue(g)
        assertEquals(Phase.DIALOGUE, g.run.phase) // no card before a dialogue
        val buttons = mutableListOf<String>()
        while (g.run.phase == Phase.DIALOGUE) {
            buttons += g.run.dialogueButton
            assertTrue(g.run.visibleButtons().isEmpty())
            idle(g)
            if (g.run.dialogueButton == "ask") { assertFalse(g.next()); assertTrue(g.ask()) } else { assertFalse(g.ask()); assertTrue(g.next()) }
        }
        assertEquals(listOf("tiep", "ask", "ask", "tiep", "tiep"), buttons)
        assertEquals(2, g.run.asksDone)
        repeat(60) { g.step(dt, InputFrame()) }
        assertEquals(Phase.WALK, g.run.phase); assertEquals(1, g.run.beat) // cheer, no caption, walk on
    }

    @Test fun askIsDebouncedLikeNext() {
        val g = game(); toDialogue(g)
        idle(g); g.next(); idle(g, 6)
        assertFalse(g.pressAllowed("ask")); assertFalse(g.ask())
    }

    @Test fun askHintAfterHintDelay() {
        val g = game(); toDialogue(g)
        idle(g); g.next()
        repeat(301) { g.step(dt, InputFrame()) }
        assertTrue(g.run.askHint)
    }

    /** AC25: skipping a dialogue (Skip anyway) means no medal this run. */
    @Test fun ac25SkipMeansNoMedal() {
        val store = MemoryStore(); val g = game(store); toDialogue(g)
        idle(g); assertTrue(g.skip()); assertTrue(g.confirmSkip())
        assertTrue(g.skipped); assertEquals(Phase.END, g.run.phase)
    }
}
