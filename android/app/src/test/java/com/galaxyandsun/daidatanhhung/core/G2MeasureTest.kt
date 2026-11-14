package com.galaxyandsun.daidatanhhung.core

import org.junit.Test

/**
 * QC r2 G2 measurement (not an assertion): how long the reach-the-flag beat takes for scripted
 * "child" strategies, with today's rules and with game-art-content's proposal (zone bounds + auto-face).
 */
class G2MeasureTest {
    private val dt = 1.0 / 60
    private val content = TestContent.fullContent()
    private val tuning = Tuning.from(content.tuning)

    private fun runBeat(g2: Boolean, strategy: (MissionRun, Int) -> InputFrame): Double {
        val r = MissionRun(content.heroes.getValue("tran-quoc-toan").mission, tuning, Mulberry32(tuning.seed), {}, g2)
        r.debugStartBeat(3, telegraph = false, caption = false)
        var n = 0
        while (r.phase == Phase.PLAY && n < 60 * 900) { r.update(dt, strategy(r, n)); n++ }
        return n * dt
    }

    @Test fun measure() {
        val holdRightTap = { _: MissionRun, n: Int -> InputFrame().apply { held += Action.RIGHT; if (n % 30 == 0) tapped += Action.ATTACK } }
        val holdRightTapRelease = { r: MissionRun, n: Int -> InputFrame().apply { // releases ▶ to tap, 2 taps/s
            if (!r.inEncounter || n % 60 >= 30) held += Action.RIGHT else if (n % 30 == 0) tapped += Action.ATTACK } }
        val tapOnly = { r: MissionRun, n: Int -> InputFrame().apply { if (!r.inEncounter) held += Action.RIGHT else if (n % 30 == 0) tapped += Action.ATTACK } }
        for ((name, s) in listOf("hold ▶ + tap 2/s" to holdRightTap, "alternate ▶ / tap" to holdRightTapRelease, "stand + tap 2/s" to tapOnly)) {
            println("G2 $name: today ${"%.1f".format(runBeat(false, s))} s, proposal ${"%.1f".format(runBeat(true, s))} s")
        }
    }
}
