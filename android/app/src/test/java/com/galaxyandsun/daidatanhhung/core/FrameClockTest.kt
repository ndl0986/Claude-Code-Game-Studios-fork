package com.galaxyandsun.daidatanhhung.core

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * r13 (iOS r10 N1 parity): the fixed-step frame clock, and the frame that leaves PAUSE carrying no time from before
 * the press, so the finish hold after a resume is never early in real time.
 */
class FrameClockTest {
    private val step = FrameClock.STEP
    private val vsync = 16_666_667L // 60 Hz, ns

    @Test fun theFirstFrameRunsNoStep() {
        val c = FrameClock(); c.start(); c.beginFrame(5_000_000_000L)
        assertEquals(0.0, c.dt, 0.0); assertEquals(0, c.steps())
    }

    @Test fun oneStepPerFrameAt60HzAndLongFramesAreClamped() {
        val c = FrameClock(); c.start(); var t = 0L; c.beginFrame(t)
        repeat(600) { t += vsync; c.beginFrame(t); assertEquals("frame $it", 1, c.steps()) }
        t += 2_000_000_000L; c.beginFrame(t) // a 2 s stall
        assertEquals(FrameClock.MAX_DT, c.dt, 1e-12); assertEquals(15, c.steps()) // 0.25 s, plus the 600 frames' tiny surplus
        c.beginFrame(t - 1); assertEquals("never negative", 0.0, c.dt, 0.0)
    }

    @Test fun theSlowScaleAppliesBeforeTheAccumulator() {
        val c = FrameClock(); c.start(); var t = 0L; c.beginFrame(t)
        var n = 0; repeat(100) { t += vsync; c.beginFrame(t); n += c.steps(0.1) }
        assertEquals(10, n)
    }

    @Test fun aResumeFrameRunsNoStepAndClearsTheAccumulator() {
        val c = FrameClock(); c.start(); var t = 0L; c.beginFrame(t)
        t += (1.9 * step * 1e9).toLong(); c.beginFrame(t); assertEquals(1, c.steps()) // 0.9 STEP left over
        t += vsync; c.beginFrame(t); c.resumed()
        assertEquals(0.0, c.dt, 0.0); assertEquals(0, c.steps())
        t += vsync; c.beginFrame(t); assertEquals("only time after the resume frame", 1, c.steps())
    }

    @Test fun afterAResumeSimTimeNeverExceedsWallTime() {
        val c = FrameClock(); c.start(); var t = 0L; c.beginFrame(t)
        t += (1.9 * step * 1e9).toLong(); c.beginFrame(t); c.steps()
        t += vsync; c.beginFrame(t); c.resumed(); c.steps()
        val resumedAt = t
        var steps = 0
        repeat(240) { t += vsync + (it % 3) * 1_000_000L; c.beginFrame(t); steps += c.steps()
            assertEquals(true, steps * step <= (t - resumedAt) / 1e9 + 1e-9) }
    }

    /** Through the game: pause in the finish hold, resume; the hold's last 0.833 s is exactly 50 frames at 60 Hz. */
    @Test fun theFinishHoldAfterAResumeEndsExactlyOnFrame50() {
        val g = Game(TestContent.load(), "tran-quoc-toan", MemoryStore()) {}
        val i = g.run.beats.indices.first { g.run.typeOf(it) == BeatType.TRAINING }
        g.debugJump("play", beat = i + 1, stage = "special")
        val c = FrameClock(); c.start(); var t = 0L; c.beginFrame(t)
        fun frame(tap: Set<Action> = emptySet(), during: () -> Unit = {}) {
            val wasPaused = g.screen == Screen.PAUSE
            during()
            if (wasPaused && g.screen != Screen.PAUSE) c.resumed()
            repeat(c.steps()) { g.step(step, InputFrame().apply { tapped += tap }) }
        }
        t += vsync; c.beginFrame(t); frame(setOf(Action.SPECIAL)); assertEquals(Phase.END, g.run.phase)
        repeat(18) { t += vsync; c.beginFrame(t); frame() } // +0.3 s
        t += vsync; c.beginFrame(t); frame { g.pause() }
        repeat(30) { t += vsync; c.beginFrame(t); frame() }
        t += (1.9 * step * 1e9).toLong(); c.beginFrame(t); frame() // a long paused frame leaves 0.9 STEP in the accumulator
        t += vsync; c.beginFrame(t); frame { g.resume() } // the resume frame
        assertEquals(Screen.PLAY, g.screen)
        var frames = 0
        while (g.run.phase == Phase.END && frames < 200) { t += vsync; c.beginFrame(t); frame(); frames++ }
        assertEquals("the hold ends on frame 50 after the resume frame (0.833 s)", 50, frames)
    }
}
