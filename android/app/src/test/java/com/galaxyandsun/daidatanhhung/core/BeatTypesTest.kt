package com.galaxyandsun.daidatanhhung.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.abs

/** The D-08 B beat types and flow (mission-flow GDD ACs), on the full Trần Quốc Toản mission. */
class BeatTypesTest {
    private val dt = 1.0 / 60
    private fun idle(g: Game, n: Int = 20) = repeat(n) { g.step(dt, InputFrame()) }
    private fun input(vararg held: Action) = InputFrame().apply { this.held += held }

    /** Starts play and walks to beat [i]'s start, through earlier beats via debug. */
    private fun atBeat(i: Int): Game {
        val g = TestContent.fullGame()
        g.debugJump("play", beat = i + 1, stage = "card")
        return g
    }

    private fun type(g: Game, i: Int) = g.run.typeOf(i)

    @Test fun fullMissionHasTheFourNonFightTypes() {
        val g = TestContent.fullGame()
        val types = g.bundle.mission.beats.indices.map { type(g, it) }
        assertEquals(listOf(BeatType.WALK, BeatType.HOLD, BeatType.TRAINING, BeatType.REACH), types)
        assertTrue(g.run.stubbedBeats.isEmpty())
    }

    /** Mission-flow AC1 (non-fight): the beat card comes before play, and no caption follows. */
    @Test fun ac1CardBeforePlayAndNoCaption() {
        val g = TestContent.fullGame()
        g.start(); repeat(g.bundle.mission.intro.size) { idle(g); g.next() }
        assertEquals(Screen.PLAY, g.screen); assertEquals(Phase.WALK, g.run.phase)
        var n = 0
        while (g.run.phase == Phase.WALK && n++ < 2000) g.step(dt, input(Action.RIGHT))
        assertEquals(Phase.CARD, g.run.phase)
        assertEquals(0, g.run.beat)
        repeat(g.run.cardBoxes().size) { idle(g); g.next() }
        assertEquals(Phase.PLAY, g.run.phase)
        n = 0
        val seen = mutableSetOf<Phase>()
        while (g.run.beat == 0 && n++ < 60 * 30) { g.step(dt, input(Action.RIGHT)); seen += g.run.phase }
        assertFalse(Phase.CAPTION in seen)
        assertEquals(1, g.run.beat)
    }

    /** Mission-flow AC20 (F5): the TQT beats start at 900, 6340, 7940, 10740. */
    @Test fun ac20BeatPositions() {
        val r = TestContent.fullGame().run
        assertEquals(listOf(900.0, 6340.0, 7940.0, 10740.0), (0..3).map { r.beatX(it) })
    }

    /** Mission-flow AC21: a training block counts only when defend is held at strike resolve. */
    @Test fun ac21TrainingBlockOnlyAtResolve() {
        val g = TestContent.fullGame()
        g.debugJump("play", beat = 3, stage = "blocks")
        val p = g.run.partner!!
        assertEquals(EnemyState.WINDUP, p.state)
        repeat(30) { g.step(dt, input(Action.DEFEND)) }   // held for 0.5 s of the windup, then released
        while (p.state == EnemyState.WINDUP) g.step(dt, InputFrame())
        assertEquals(0, g.run.blocksDone)
        repeat(60 * 4) { g.step(dt, input(Action.DEFEND)) } // held through the next resolve
        assertEquals(1, g.run.blocksDone)
    }

    /** AC3: a beat with buttons [move] shows only the move pads. */
    @Test fun ac3OnlyTheBeatsButtons() {
        val g = atBeat(0)
        idle(g); repeat(g.run.cardBoxes().size) { idle(g); g.next() }
        assertEquals(setOf("move"), g.run.visibleButtons())
        val h = atBeat(1)
        repeat(h.run.cardBoxes().size) { idle(h); h.next() }
        assertEquals(setOf("special"), h.run.visibleButtons())
    }

    /** AC4 (F2): a 3-screen walk ends at x_start + 3840 after 11.6 s ± 0.1 s at 330 px/s. */
    @Test fun ac4WalkLengthAndTime() {
        val g = atBeat(0)
        repeat(g.run.cardBoxes().size) { idle(g); g.next() }
        assertEquals(Phase.PLAY, g.run.phase)
        val x0 = g.run.xStart
        var steps = 0
        while (g.run.phase == Phase.PLAY && steps < 60 * 30) { g.step(dt, input(Action.RIGHT)); steps++ }
        assertTrue(g.run.hero.x >= x0 + 3840)
        assertEquals(3840.0 / 330.0, steps * dt, 0.1)
    }

    /** AC5 (F3): the meter holds 48% while released and ends after 1.3 s more holding. */
    @Test fun ac5HoldMeterNeverDrains() {
        val g = atBeat(1)
        repeat(g.run.cardBoxes().size) { idle(g); g.next() }
        assertEquals(2.5, g.run.holdSeconds(1), 0.0)
        repeat(72) { g.step(dt, input(Action.SPECIAL)) }              // 1.2 s
        val m = g.run.heldTotal / 2.5
        assertEquals(0.48, m, 0.01)
        repeat(180) { g.step(dt, InputFrame()) }                      // released 3 s
        assertEquals(m, g.run.heldTotal / 2.5, 0.0)
        var steps = 0
        while (g.run.phase == Phase.PLAY && steps < 600) { g.step(dt, input(Action.SPECIAL)); steps++ }
        assertEquals(1.3, steps * dt, 2 * dt)
    }

    /** AC6: special before the dummies and blocks does nothing; training ends only after hits, blocks, special. */
    @Test fun ac6TrainingOrder() {
        val g = atBeat(2)
        repeat(g.run.cardBoxes().size) { idle(g); g.next() }
        val r = g.run
        assertEquals(TrainingStep.DUMMIES, r.trainingStep)
        g.step(dt, InputFrame().apply { tapped += Action.SPECIAL })
        assertEquals(TrainingStep.DUMMIES, r.trainingStep); assertFalse(r.bannerRaised)
        var n = 0
        while (r.trainingStep == TrainingStep.DUMMIES && n++ < 60 * 60) {
            val next = r.dummies.first { !it.down }
            val i = InputFrame()
            if (abs(next.x - r.hero.x) > 120) i.held += Action.RIGHT else if (n % 20 == 0) i.tapped += Action.ATTACK
            g.step(dt, i)
        }
        assertEquals(3, r.dummies.count { it.down })
        assertEquals(TrainingStep.BLOCKS, r.trainingStep)
        n = 0
        while (r.trainingStep == TrainingStep.BLOCKS && n++ < 60 * 60) g.step(dt, input(Action.DEFEND))
        assertEquals(3, r.blocksDone)
        assertEquals(TrainingStep.SPECIAL, r.trainingStep)
        assertEquals(Phase.PLAY, r.phase)
        g.step(dt, InputFrame().apply { tapped += Action.SPECIAL })
        assertTrue(r.bannerRaised)
        assertEquals(Phase.END, r.phase)
    }

    /** Training: an unblocked practice strike only pushes back and doesn't count. */
    @Test fun trainingMissedBlockDoesNotCount() {
        val g = atBeat(2)
        repeat(g.run.cardBoxes().size) { idle(g); g.next() }
        val r = g.run
        var n = 0
        while (r.trainingStep == TrainingStep.DUMMIES && n++ < 60 * 60) {
            val next = r.dummies.first { !it.down }
            val i = InputFrame(); if (abs(next.x - r.hero.x) > 120) i.held += Action.RIGHT else if (n % 20 == 0) i.tapped += Action.ATTACK
            g.step(dt, i)
        }
        repeat(60 * 6) { g.step(dt, InputFrame()) }
        assertEquals(0, r.blocksDone)
    }

    /** AC7: an encounter locks the camera until its enemies run away; the flag ends the beat. */
    @Test fun ac7ReachTheFlagEncounterLocksTheCamera() {
        val g = atBeat(3)
        repeat(g.run.cardBoxes().size) { idle(g); g.next() }
        val r = g.run
        val firstAt = r.xStart + r.encounterAt(3)[0] * 1280
        var n = 0
        while (!r.inEncounter && n++ < 60 * 30) g.step(dt, input(Action.RIGHT))
        assertTrue(r.inEncounter); assertTrue(r.hero.x >= firstAt)
        val lock = r.lockX!!
        n = 0
        while (r.inEncounter && n++ < 60 * 120) {
            val i = InputFrame()
            val near = r.enemies.filter { it.state != EnemyState.FLEE }.minByOrNull { abs(it.x - r.hero.x) }
            if (near != null && (near.x - r.hero.x) * r.hero.face < 0) i.held += if (near.x < r.hero.x) Action.LEFT else Action.RIGHT
            else if (n % 18 == 0) i.tapped += Action.ATTACK
            g.step(dt, i)
            if (r.inEncounter) assertEquals(lock, r.cam, 0.0)
        }
        assertFalse(r.inEncounter); assertNull(r.lockX)
        n = 0
        while (r.phase == Phase.PLAY && n++ < 60 * 120) {
            val i = InputFrame()
            if (r.inEncounter) {
                val near = r.enemies.filter { it.state != EnemyState.FLEE }.minByOrNull { abs(it.x - r.hero.x) }
                if (near != null && (near.x - r.hero.x) * r.hero.face < 0) i.held += if (near.x < r.hero.x) Action.LEFT else Action.RIGHT
                else if (n % 18 == 0) i.tapped += Action.ATTACK
            } else i.held += Action.RIGHT
            g.step(dt, i)
        }
        assertEquals(Phase.END, r.phase)
        assertTrue(r.hero.x >= r.goalX)
    }

    /** AC9: two taps on Next within 0.25 s advance one box. */
    @Test fun ac9StoryBoxDebounce() {
        val g = TestContent.fullGame()
        g.debugJump("ending"); idle(g)
        val before = g.line
        assertTrue(g.next()); assertFalse(g.next())
        assertEquals(before + 1, g.line)
        idle(g, 16) // 0.27 s later the next tap counts again
        assertTrue(g.next())
    }

    /** QC B1: two taps 0.1 s apart advance one box, on the intro and on the quiz's Tiếp. */
    @Test fun b1TwoTapsPointOneSecondApart() {
        val g = TestContent.fullGame()
        g.debugJump("ending"); idle(g)
        assertTrue(g.next()); idle(g, 6); assertFalse(g.next())
        assertEquals(1, g.line)
        g.debugJump("quiz"); idle(g)
        g.answer(g.quiz!!.current.correctIndex); idle(g, 60)
        assertTrue(g.next()); val i = g.quiz!!.index
        g.answer(g.quiz!!.current.correctIndex); idle(g, 6)
        assertFalse(g.next()); assertEquals(i, g.quiz!!.index)
    }

    /** AC10: pause (the app going to the background) freezes the meter and the enemies. */
    @Test fun ac10PauseKeepsTheMeter() {
        val g = atBeat(1)
        repeat(g.run.cardBoxes().size) { idle(g); g.next() }
        repeat(90) { g.step(dt, input(Action.SPECIAL)) }
        val m = g.run.heldTotal
        g.pause(); repeat(300) { g.step(dt, input(Action.SPECIAL)) }
        assertEquals(m, g.run.heldTotal, 0.0)
        g.resume(); assertEquals(Screen.PLAY, g.screen)
    }

    /** Combat AC19: on resume a windup restarts its telegraph from 0. */
    @Test fun resumeRestartsTheTelegraph() {
        val g = TestContent.game()
        g.debugJump("play", beat = 2, stage = "telegraph")
        repeat(40) { g.step(dt, InputFrame()) }
        val e = g.run.enemies.first { it.state == EnemyState.WINDUP }
        assertTrue(e.t > 0.5)
        g.pause(); g.resume()
        assertEquals(0.0, e.t, 0.0)
    }

    // ---- D-07: skip and medal ----

    /** D-07 (leader's call): Keep reading → the next Skip warns again; Skip anyway → later skips are silent. */
    @Test fun skipWarningReturnsUntilSkipAnywayAndSkipEndsOnlyTheSection() {
        val g = TestContent.fullGame()
        g.start(); idle(g)
        assertTrue(g.skip()); assertTrue(g.skipWarning)
        assertTrue(g.keepReading()); assertFalse(g.skipped); assertEquals(Screen.INTRO, g.screen)
        assertTrue(g.skip()); assertTrue("warns again after Keep reading", g.skipWarning)
        assertTrue(g.confirmSkip()); assertTrue(g.skipped)
        assertEquals(Screen.PLAY, g.screen); assertEquals(Phase.WALK, g.run.phase) // play is never skipped
        var n = 0
        while (g.run.phase == Phase.WALK && n++ < 2000) g.step(dt, input(Action.RIGHT))
        assertEquals(Phase.CARD, g.run.phase)
        assertTrue(g.skip()); assertFalse("silent after Skip anyway", g.skipWarning)
        assertEquals(Phase.PLAY, g.run.phase) // a card skip goes to its play
    }

    @Test fun noWarningOnceTheMedalIsEarned() {
        val store = MemoryStore().apply { flags += "medal.tran-quoc-toan" }
        val g = TestContent.fullGame(store)
        g.start(); idle(g)
        assertTrue(g.skip()); assertFalse(g.skipWarning); assertEquals(Screen.PLAY, g.screen)
    }

    private fun finishQuiz(g: Game) {
        while (g.screen == Screen.QUIZ) { g.answer(g.quiz!!.current.correctIndex); idle(g, 60); g.next() }
    }

    @Test fun medalOnlyWithoutSkippingAndNeverLost() {
        val store = MemoryStore()
        val g = TestContent.fullGame(store)
        g.debugJump("ending"); repeat(g.bundle.mission.ending.lines.size) { idle(g); g.next() }
        finishQuiz(g)
        assertTrue(g.medalThisRun); assertTrue(store.flag("medal.tran-quoc-toan"))
        assertTrue(store.flag("completed.tran-quoc-toan"))
        // A later full-read replay keeps the gold medal but doesn't announce it again.
        val g1 = TestContent.fullGame(store)
        g1.debugJump("ending"); repeat(g1.bundle.mission.ending.lines.size) { idle(g1); g1.next() }
        finishQuiz(g1)
        assertFalse(g1.medalThisRun); assertTrue(g1.medalEarned)
        // A later run that skips earns no medal this run, but the saved medal stays.
        val g2 = TestContent.fullGame(store)
        g2.debugJump("ending"); g2.skip() // medal already earned: no warning
        assertEquals(Screen.QUIZ, g2.screen)
        finishQuiz(g2)
        assertFalse(g2.medalThisRun); assertTrue(store.flag("medal.tran-quoc-toan"))
    }

    @Test fun skippedRunEarnsNoMedal() {
        val store = MemoryStore()
        val g = TestContent.fullGame(store)
        g.debugJump("ending"); g.skip(); g.confirmSkip()
        finishQuiz(g)
        assertFalse(store.flag("medal.tran-quoc-toan")); assertEquals(Screen.RESULTS, g.screen)
    }

    /** The whole full mission plays from intro to results with simple scripted input. */
    @Test fun fullMissionPlaysThrough() {
        val g = TestContent.fullGame()
        g.start()
        var n = 0
        while (g.screen != Screen.RESULTS && n++ < 60 * 900) {
            val r = g.run; val i = InputFrame()
            when {
                g.screen == Screen.QUIZ -> { val q = g.quiz!!; if (q.rightShown < 0) g.answer(q.current.correctIndex) else if (q.canAdvance) g.next() }
                g.onStoryBox -> { if (n % 20 == 0) g.next() }
                g.screen == Screen.PLAY -> when {
                    r.phase == Phase.PLAY && r.beatType == BeatType.HOLD -> i.held += Action.SPECIAL
                    r.phase == Phase.PLAY && r.beatType == BeatType.TRAINING -> when (r.trainingStep) {
                        TrainingStep.DUMMIES -> { val d = r.dummies.first { !it.down }; if (abs(d.x - r.hero.x) > 120) i.held += Action.RIGHT else if (n % 20 == 0) i.tapped += Action.ATTACK }
                        TrainingStep.BLOCKS -> i.held += Action.DEFEND
                        else -> i.tapped += Action.SPECIAL
                    }
                    r.enemies.any { it.state != EnemyState.FLEE } -> {
                        val near = r.enemies.filter { it.state != EnemyState.FLEE }.minByOrNull { abs(it.x - r.hero.x) }!!
                        if ((near.x - r.hero.x) * r.hero.face < 0) i.held += if (near.x < r.hero.x) Action.LEFT else Action.RIGHT
                        else if (n % 18 == 0) i.tapped += Action.ATTACK
                    }
                    else -> i.held += Action.RIGHT
                }
            }
            g.step(dt, i)
        }
        assertEquals(Screen.RESULTS, g.screen)
        assertEquals(3, g.stars)
        assertTrue(g.medalThisRun)
    }

    @Test fun pauseClosesAnOpenSkipWarning() {
        val g = TestContent.fullGame()
        g.debugJump("play", beat = 1, stage = "card"); idle(g)
        assertTrue(g.skip()); assertTrue(g.skipWarning)
        assertTrue(g.pause()); assertFalse(g.skipWarning)
    }

    @Test fun flagArrowWhenIdleOnTheClearPath() {
        val g = atBeat(3)
        repeat(g.run.cardBoxes().size) { idle(g); g.next() }
        val r = g.run
        // Walk past both encounters' triggers is not needed: idle near the start, flag off screen → no arrow.
        repeat(60 * 6) { g.step(dt, InputFrame()) }
        assertFalse(r.flagArrow)
    }
}
