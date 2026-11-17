package com.galaxyandsun.daidatanhhung.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.abs

/**
 * Combat GDD Rule 15b / AC24 (TASK-020a): in a training beat the camera follows right but never
 * past xStart − hero_edge_margin, and the hero never past cap + W − enemy_reach − hero_edge_margin,
 * so a child holding ▶ can't walk past the dummies and softlock the beat (iOS QC r3; Android bot).
 */
class TrainingCapTest {
    private val dt = 1.0 / 60
    private val content = TestContent.load()
    private val tuning = Tuning.from(content.tuning)

    private fun run() = MissionRun(content.heroes.getValue("tran-quoc-toan").mission, tuning, Mulberry32(tuning.seed), {})
        .also { r -> r.debugStartBeat(r.beats.indices.first { r.typeOf(it) == BeatType.TRAINING }, telegraph = false, caption = false) }

    private fun MissionRun.frame(hold: Set<Action> = emptySet(), tap: Set<Action> = emptySet()) =
        update(dt, InputFrame().apply { held += hold; tapped += tap })

    /** Walks to each standing dummy and hits it, blocks every partner strike, then raises the banner. */
    private fun finish(r: MissionRun): Boolean {
        var n = 0
        while (r.phase == Phase.PLAY && n++ < 60 * 120) {
            val h = r.hero
            when (r.trainingStep) {
                TrainingStep.DUMMIES -> {
                    val d = r.dummies.filter { !it.down }.minBy { abs(it.x - h.x) }
                    val dx = d.x - h.x
                    when {
                        abs(dx) > tuning["attack_range"] - 20 -> r.frame(setOf(if (dx > 0) Action.RIGHT else Action.LEFT))
                        (if (dx > 0) 1 else -1) != h.face -> r.frame(setOf(if (dx > 0) Action.RIGHT else Action.LEFT))
                        h.atk < 0 && h.cool <= 0 -> r.frame(tap = setOf(Action.ATTACK))
                        else -> r.frame()
                    }
                }
                TrainingStep.BLOCKS -> r.frame(if (r.partner?.state == EnemyState.WINDUP) setOf(Action.DEFEND) else emptySet())
                TrainingStep.SPECIAL -> r.frame(tap = setOf(Action.SPECIAL))
                TrainingStep.DONE -> r.frame()
            }
        }
        return r.phase != Phase.PLAY
    }

    @Test fun holdingRightFor5sNeverPassesTheCapsAndNeverJumpsOrSnaps() {
        val r = run()
        val xStart = r.xStart
        val cap = xStart - tuning["hero_edge_margin"]
        val heroMax = cap + MissionRun.WORLD_W - tuning["enemy_reach"] - tuning["hero_edge_margin"]
        var cam0 = r.cam; var x0 = r.hero.x
        repeat(300) {
            r.frame(setOf(Action.RIGHT))
            assertTrue("camera ${r.cam} past the cap $cap", r.cam <= cap + 1e-9)
            assertTrue("camera moved left", r.cam >= cam0 - 1e-9)
            assertTrue("camera jumped ${r.cam - cam0}", r.cam - cam0 <= tuning["hero_speed"] * dt + 1e-9)
            assertTrue("hero ${r.hero.x} past ${heroMax}", r.hero.x <= heroMax + 1e-9)
            assertTrue("hero snapped ${r.hero.x - x0}", abs(r.hero.x - x0) <= tuning["hero_speed"] * dt + 1e-9)
            cam0 = r.cam; x0 = r.hero.x
        }
        assertEquals("TQT: the camera stops at xStart − 70", cap, r.cam, 1e-9)
        assertEquals("TQT: the hero stops at xStart + 990", xStart + 990, r.hero.x, 1e-9)
        assertTrue("every dummy still standing and reachable", r.dummies.all { !it.down && it.x <= heroMax })
        assertTrue("a scripted run then finishes training", finish(r))
    }

    /** The bot that found the softlock: ▶ for 3 s or 5 s, then the child goes back for the dummies. */
    @Test fun runningPastTheDummiesNoLongerSoftlocks() {
        for (secs in listOf(1, 3, 5, 8)) {
            val r = run()
            repeat(secs * 60) { r.frame(setOf(Action.RIGHT)) }
            assertTrue("▶ for $secs s: training must still finish", finish(r))
        }
    }

    @Test fun theCapClearsAtBeatEndAndTheCameraFollowsAgain() {
        val r = run()
        assertTrue(finish(r))
        var n = 0
        while (r.phase != Phase.WALK && n++ < 600) r.frame()
        val cam0 = r.cam
        repeat(240) { r.frame(setOf(Action.RIGHT)) }
        assertTrue("walking on after training scrolls the camera again", r.cam > cam0 + 100)
    }

    /** Mission flow Rule 7c / AC27 (W12): the visible pads follow the training step. */
    @Test fun trainingShowsThePadsOfItsCurrentStep() {
        val r = run()
        assertEquals(setOf("move", "attack"), r.visibleButtons())
        r.debugTraining("blocks"); assertEquals(setOf("move", "attack", "defend"), r.visibleButtons())
        r.debugTraining("special"); assertEquals(setOf("move", "attack", "defend", "special"), r.visibleButtons())
    }

    /** Mission flow Rule 2 / AC30, Audio AC13 (schema 1.5): `cheer: false` ends the beat on a page turn, no cheer. */
    @Test fun aBeatWithCheerFalseEndsOnAPageTurn() {
        for (cheer in listOf(true, false)) {
            val m0 = content.heroes.getValue("tran-quoc-toan").mission
            val m = m0.copy(beats = m0.beats.mapIndexed { i, b -> if (i == 0) b.copy(cheer = cheer) else b })
            val sfx = mutableListOf<Sfx>()
            val r = MissionRun(m, tuning, Mulberry32(tuning.seed)) { sfx += it }
            r.debugStartBeat(0, telegraph = false, caption = false)
            var n = 0
            while (r.beat == 0 && n++ < 60 * 60) r.frame(setOf(Action.RIGHT))
            assertEquals("cheer=$cheer", if (cheer) Sfx.CHIME else Sfx.SOFT, sfx.last())
            assertEquals("cheer=$cheer: the burst time", cheer, r.cheerT >= 0)
        }
    }
}
