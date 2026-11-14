package com.galaxyandsun.daidatanhhung.core

import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.abs

/**
 * QC r2 G2 (combat Rule 15: fight-zone clamp, attack auto-face, 2b swing keeps facing). The
 * reach-the-flag beat must be finishable by simple scripted "child" strategies in ≤ 60 s.
 */
class G2MeasureTest {
    private val dt = 1.0 / 60
    private val content = TestContent.fullContent()
    private val tuning = Tuning.from(content.tuning)

    private fun run() = MissionRun(content.heroes.getValue("tran-quoc-toan").mission, tuning, Mulberry32(tuning.seed), {})
        .also { r -> r.debugStartBeat(r.beats.indices.first { r.typeOf(it) == BeatType.REACH }, telegraph = false, caption = false) }

    private fun timeBeat(strategy: (MissionRun, Int) -> InputFrame): Double {
        val r = run(); var n = 0
        while (r.phase == Phase.PLAY && n < 60 * 900) { r.update(dt, strategy(r, n)); n++ }
        return n * dt
    }

    @Test fun everyScriptedStrategyFinishesWithin60s() {
        val strategies = mapOf<String, (MissionRun, Int) -> InputFrame>(
            "hold ▶ + tap 2/s" to { _, n -> InputFrame().apply { held += Action.RIGHT; if (n % 30 == 0) tapped += Action.ATTACK } },
            "alternate ▶ / tap" to { r, n -> InputFrame().apply { if (!r.inEncounter || n % 60 >= 30) held += Action.RIGHT else if (n % 30 == 0) tapped += Action.ATTACK } },
            "stand + tap 2/s" to { r, n -> InputFrame().apply { if (!r.inEncounter) held += Action.RIGHT else if (n % 30 == 0) tapped += Action.ATTACK } },
        )
        for ((name, s) in strategies) { val t = timeBeat(s); println("G2 $name: ${"%.1f".format(t)} s"); assertTrue("$name took $t s", t <= 60.0) }
    }

    /** Rule 2 parity: a tie between two sides, or an enemy at exactly hero.x, keeps the facing. */
    @Test fun autoFaceTieKeepsFacing() {
        val r = run(); val h = r.hero
        r.enemies.clear()
        r.enemies += Enemy(70, "spear", h.x - 100, 1).also { it.state = EnemyState.APPROACH }
        r.enemies += Enemy(71, "spear", h.x + 100, -1).also { it.state = EnemyState.APPROACH }
        h.face = 1
        r.update(dt, InputFrame().apply { tapped += Action.ATTACK })
        assertTrue(h.face == 1)
        r.enemies.removeAt(1); h.face = 1; h.atk = -1.0; h.cool = 0.0
        r.update(dt, InputFrame().apply { tapped += Action.ATTACK })
        assertTrue(h.face == -1)
    }

    /** Holding ▶ through an encounter keeps the front enemy on screen, and an attack lands within 2 swings. */
    @Test fun holdingRightKeepsTheEnemyOnScreenAndHitsWithin2Swings() {
        val r = run()
        val hold = InputFrame().apply { held += Action.RIGHT }
        var n = 0
        while (!r.inEncounter && n++ < 60 * 60) r.update(dt, hold)
        assertTrue(r.inEncounter)
        // hold ▶ until an enemy stands at its stand-off point
        n = 0
        while (r.enemies.none { it.state == EnemyState.APPROACH && !it.moving } && n++ < 60 * 20) r.update(dt, hold)
        val lock = r.lockX!!
        val front = r.enemies.filter { it.state != EnemyState.FLEE }.minByOrNull { abs(it.x - r.hero.x) }!!
        assertTrue("enemy at ${front.x} off screen [${lock}, ${lock + 1280}]", front.x in lock..(lock + 1280))
        var swings = 0
        while (front.hits == 0 && swings < 2) {
            r.update(dt, InputFrame().apply { held += Action.RIGHT; tapped += Action.ATTACK }); swings++
            repeat(((tuning["attack_time"] + tuning["attack_cooldown"]) / dt).toInt() + 1) { r.update(dt, hold) }
        }
        assertTrue("no hit within 2 swings", front.hits > 0)
    }
}
