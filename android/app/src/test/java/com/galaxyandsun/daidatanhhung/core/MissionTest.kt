package com.galaxyandsun.daidatanhhung.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** The mission rules: telegraph, block, no lives, flee, spawning, hints. */
class MissionTest {
    private val dt = 1.0 / 60
    private val content = TestContent.load()
    private val tuning = Tuning.from(content.tuning)
    private val sfx = mutableListOf<Sfx>()
    private fun run() = MissionRun(content.heroes.getValue("sample").mission, tuning, Mulberry32(tuning.seed), { sfx += it })
    private fun steps(r: MissionRun, seconds: Double, input: InputFrame = InputFrame()) {
        repeat((seconds / dt).toInt()) { r.update(dt, input); input.clearTaps() }
    }
    private fun walkToFight(r: MissionRun) {
        val i = InputFrame().apply { held += Action.RIGHT }
        var n = 0
        while (r.phase != Phase.PLAY && n++ < 2000) r.update(dt, i)
        assertEquals(Phase.PLAY, r.phase)
    }

    @Test fun walkingRightStartsBeatOneAndLocksTheCamera() {
        val r = run(); walkToFight(r)
        assertEquals(0, r.beat)
        assertEquals(r.beatX(0) - tuning["lock_offset"], r.cam, 1e-9)
        assertTrue(r.tut.moved)
    }

    @Test fun firstEnemyWalksInAfterFirstSpawnDelay() {
        val r = run(); walkToFight(r)
        steps(r, tuning["first_spawn_delay"] - 2 * dt)
        assertTrue(r.enemies.isEmpty())
        steps(r, 3 * dt)
        assertEquals(1, r.enemies.size)
        assertEquals(EnemyState.ENTER, r.enemies[0].state)
    }

    /** Returns the run with its first enemy just entering windup. */
    private fun untilWindup(r: MissionRun): Enemy {
        walkToFight(r)
        var n = 0
        while (r.enemies.none { it.state == EnemyState.WINDUP } && n++ < 2000) r.update(dt, InputFrame())
        return r.enemies.first { it.state == EnemyState.WINDUP }
    }

    @Test fun telegraphLastsOnePointOneSecondsBeforeTheStrike() {
        val r = run(); val e = untilWindup(r)
        assertEquals(1.1, tuning["telegraph"], 0.0)
        steps(r, 1.1 - 2 * dt)
        assertEquals(EnemyState.WINDUP, e.state)
        steps(r, 3 * dt)
        assertEquals(EnemyState.STRIKE, e.state)
    }

    @Test fun leaderTelegraphIsLonger() {
        val r = run()
        assertEquals(tuning["telegraph"] * tuning["leader_telegraph_mul"], r.windupTime("leader"), 1e-9)
    }

    @Test fun heldDefendAlwaysBlocks() {
        val r = run(); val e = untilWindup(r); sfx.clear()
        val x0 = r.hero.x
        val def = InputFrame().apply { held += Action.DEFEND }
        steps(r, 1.2, def)
        assertTrue(r.tut.blocked)
        assertTrue(Sfx.CLANG in sfx)
        assertEquals(x0, r.hero.x, 1e-9)
        assertTrue(e.state == EnemyState.STRIKE || e.state == EnemyState.REST)
    }

    @Test fun unblockedHitOnlyPushesTheHeroBack() {
        val r = run(); untilWindup(r); sfx.clear()
        val x0 = r.hero.x
        steps(r, 1.2)
        assertTrue(Sfx.BONK in sfx)
        assertTrue(r.hero.x < x0)  // pushed back, nothing lost: there are no lives to lose
        assertTrue(r.hero.hurt > 0)
    }

    @Test fun pressReleaseDuringWindupIsNotABlock() {
        val r = run(); untilWindup(r)
        steps(r, 0.3, InputFrame().apply { held += Action.DEFEND })
        steps(r, 1.0)
        assertFalse(r.tut.blocked)
    }

    @Test fun attackWhileDefendingIsDropped() {
        val r = run(); walkToFight(r)
        val i = InputFrame().apply { held += Action.DEFEND; tapped += Action.ATTACK }
        r.update(dt, i); i.clearTaps()
        assertEquals(-1.0, r.hero.atk, 0.0)
        i.held -= Action.DEFEND; r.update(dt, i)
        assertEquals(-1.0, r.hero.atk, 0.0) // not queued
    }

    @Test fun twoHitsMakeASpearSoldierDropHisWeaponAndFlee() {
        val r = run(); walkToFight(r)
        var n = 0
        while (r.enemies.isEmpty() && n++ < 600) r.update(dt, InputFrame())
        val e = r.enemies.first()
        n = 0
        while (e.state != EnemyState.FLEE && n++ < 60 * 30) {
            val i = InputFrame()
            if (kotlin.math.abs(e.x - r.hero.x) <= tuning["attack_range"]) i.tapped += Action.ATTACK
            r.update(dt, i)
        }
        assertEquals(EnemyState.FLEE, e.state)
        assertEquals(tuning.int("hp_spear"), e.hits)
        assertEquals(1, r.dropped.size)
    }

    @Test fun beatEndsInACaptionOnlyWhenTheGroupIsGone() {
        val r = run(); walkToFight(r)
        // Fight beat 1 with attack taps only (the hero is pushed back sometimes, never stopped).
        var n = 0
        while ((r.phase == Phase.PLAY || r.phase == Phase.END) && n++ < 60 * 120) {
            val i = InputFrame()
            if (n % 20 == 0) i.tapped += Action.ATTACK
            r.update(dt, i)
        }
        assertEquals(Phase.CAPTION, r.phase)
        assertTrue(r.enemies.isEmpty())
        assertFalse(r.captionNext())
        assertEquals(Phase.WALK, r.phase)
        assertEquals(1, r.beat)
    }

    @Test fun onlyOneEnemyWindsUpAtATime() {
        val r = run()
        r.debugStartBeat(1, telegraph = false, caption = false) // beat 2: max_active 2
        var n = 0
        while (n++ < 60 * 20) {
            r.update(dt, InputFrame())
            assertTrue(r.enemies.count { it.state == EnemyState.WINDUP || it.state == EnemyState.STRIKE } <= 1)
            assertTrue(r.enemies.count { it.state != EnemyState.FLEE } <= 2)
        }
    }

    @Test fun stallHintAfterFiveSecondsWithoutProgress() {
        val r = run(); walkToFight(r)
        steps(r, tuning["hint_delay"] - 0.1, InputFrame().apply { held += Action.DEFEND })
        assertFalse(r.stalled)
        steps(r, 0.2, InputFrame().apply { held += Action.DEFEND })
        assertTrue(r.stalled); assertTrue(r.pulseAttack); assertNotNull(r.stallTarget)
    }

    /** Strictly > hint_delay: with dt 1/60 the hint shows at step 301, not 300 (leader's parity call). */
    @Test fun stallHintBoundaryIsStep301() {
        val r = run(); walkToFight(r)
        val def = InputFrame().apply { held += Action.DEFEND }
        // The fight's first step already counted once in walkToFight.
        val already = (r.stall / dt).let { Math.round(it).toInt() }
        repeat(300 - already) { r.update(dt, def) }
        assertFalse("step 300: stall=${r.stall}", r.stalled)
        r.update(dt, def)
        assertTrue("step 301: stall=${r.stall}", r.stalled)
    }

    @Test fun anyMovementResetsWalkIdle() {
        val r = run()
        repeat(400) { r.update(dt, InputFrame()) }
        assertTrue(r.idle > 5)
        r.update(dt, InputFrame().apply { held += Action.LEFT })
        assertEquals(0.0, r.idle, 0.0)
    }

    @Test fun heroHitOnTheWindupsLastFrameCancelsTheStrike() {
        val r = run()
        r.debugStartBeat(0, telegraph = true, caption = false)
        val e = r.enemies.first { it.state == EnemyState.WINDUP }
        // Swing so the hit lands on the step the windup would end.
        val swingToHit = tuning["attack_hit_at"] * tuning["attack_time"]
        val stepsToEnd = Math.ceil(r.windupTime(e.kind) / dt).toInt()
        val startAt = stepsToEnd - Math.ceil(swingToHit / dt).toInt()
        repeat(startAt - 1) { r.update(dt, InputFrame()) }
        r.update(dt, InputFrame().apply { tapped += Action.ATTACK })
        var struck = false
        repeat(60) { r.update(dt, InputFrame()); if (e.state == EnemyState.STRIKE) struck = true }
        assertFalse("the hit should cancel the strike", struck)
        assertTrue(e.hits >= 1)
    }

    @Test fun firstUseHandsShowInOrder() {
        val r = run()
        assertEquals(HandHint.MOVE, r.hand)
        walkToFight(r)
        steps(r, 0.5)
        assertEquals(HandHint.ATTACK, r.hand)
    }

    @Test fun sameSeedSameRun() {
        fun trace(): List<Double> { val r = run(); val out = mutableListOf<Double>()
            val i = InputFrame().apply { held += Action.RIGHT }
            repeat(60 * 15) { k -> if (k % 30 == 0) i.tapped += Action.ATTACK; r.update(dt, i); i.clearTaps(); out += r.hero.x; r.enemies.forEach { out += it.x } }
            return out }
        assertEquals(trace(), trace())
    }
}
