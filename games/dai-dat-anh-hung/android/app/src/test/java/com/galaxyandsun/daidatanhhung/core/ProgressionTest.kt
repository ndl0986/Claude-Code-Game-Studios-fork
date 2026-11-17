package com.galaxyandsun.daidatanhhung.core

import com.galaxyandsun.daidatanhhung.core.content.Content
import com.galaxyandsun.daidatanhhung.core.content.HeroBundle
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.assertFalse
import org.junit.Test

/** D-16 / Hero progression GDD: derived unlocks that survive content updates. */
class ProgressionTest {
    private val base = TestContent.load()
    private val tqt = base.heroes.getValue("tran-quoc-toan")

    /** A content bundle with heroes id → timeline_order, all copies of TQT. */
    private fun heroes(vararg h: Pair<String, Int>): Content = base.copy(heroes = h.associate { (id, order) ->
        id to HeroBundle(tqt.mission.copy(hero = tqt.mission.hero.copy(id = id, timelineOrder = order)), tqt.quiz, tqt.claims) })

    @Test fun ac1FirstHeroOpen() {
        assertEquals(setOf("a"), Progression.openHeroes(heroes("a" to 10, "b" to 20), MemoryStore()))
    }

    @Test fun ac2CompletingOpensTheNext() {
        val s = MemoryStore().apply { flags += "completed.a" }
        assertEquals(setOf("a", "b"), Progression.openHeroes(heroes("a" to 10, "b" to 20), s))
    }

    @Test fun ac3HeroAddedAtTheEnd() {
        val s = MemoryStore().apply { flags += "completed.a" }
        val c = heroes("a" to 10, "b" to 20, "c" to 30)
        assertTrue("c" !in Progression.openHeroes(c, s))
        s.flags += "completed.b"
        assertTrue("c" in Progression.openHeroes(c, s))
    }

    @Test fun ac4InsertedHeroOpensAndLaterStaysOpen() {
        val s = MemoryStore().apply { flags += "completed.a" }
        Progression.markSeen(heroes("a" to 10, "b" to 20), s)
        assertEquals(setOf("a", "a2", "b"), Progression.openHeroes(heroes("a" to 10, "a2" to 15, "b" to 20), s))
    }

    /** AC12: a title load saves seen_open for every hero shown open. */
    @Test fun ac12TitleLoadSavesSeenOpen() {
        val s = MemoryStore().apply { flags += "completed.tran-quoc-toan" }
        Game(heroes("tran-quoc-toan" to 10, "b" to 20, "c" to 30), "tran-quoc-toan", s) {}
        assertTrue(s.flag("seen_open.tran-quoc-toan")); assertTrue(s.flag("seen_open.b")); assertTrue(!s.flag("seen_open.c"))
    }

    /** Review item 1: a hero inserted before the first never re-locks the old first hero. */
    @Test fun insertBeforeFirstKeepsItOpen() {
        val s = MemoryStore()
        Progression.markSeen(heroes("a" to 10), s)
        assertEquals(setOf("z", "a"), Progression.openHeroes(heroes("z" to 5, "a" to 10), s))
    }
    /** Save GDD Rule 1/6, AC1: `sound` defaults on, is written at once on the toggle and read at the next launch. */
    @Test fun muteIsSavedAndReadAtLaunch() {
        val store = MemoryStore()
        val g = TestContent.game(store)
        assertFalse("fresh install: sound on", g.muted)
        g.toggleMute()
        assertEquals(false, store.soundOn)
        assertTrue("relaunch keeps mute", TestContent.game(store).muted)
        TestContent.game(store).toggleMute()
        assertFalse(TestContent.game(store).muted)
    }
}
