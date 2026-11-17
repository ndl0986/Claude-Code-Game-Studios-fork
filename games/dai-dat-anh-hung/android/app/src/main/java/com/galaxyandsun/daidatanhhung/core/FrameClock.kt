package com.galaxyandsun.daidatanhhung.core

/**
 * The app's fixed-step frame clock (r13; the same seam as iOS r10's GameCore FrameClock). Each vsync gives a frame
 * delta clamped to [0, [MAX_DT]], 0 on the first frame after [start]; [steps] turns it, times the debug slow scale,
 * into whole [STEP]s and keeps the remainder.
 *
 * Resume (iOS r10 N1, QC timing): on the frame where input took the game out of PAUSE, [resumed] zeroes this frame's
 * delta and the accumulator, so no time from before the press reaches the sim. The finish hold's 0.833 s after a
 * resume then lasts exactly 50 frames at 60 Hz, never one early.
 */
class FrameClock {
    private var last = -1L
    private var acc = 0.0
    /** This frame's delta, seconds. */
    var dt = 0.0; private set

    /** The loop (re)starts: the next frame's delta is 0 and nothing is carried over. */
    fun start() { last = -1L; acc = 0.0; dt = 0.0 }

    /** A vsync at [nanos]: sets [dt] from the previous one. */
    fun beginFrame(nanos: Long) {
        dt = if (last < 0) 0.0 else ((nanos - last) / 1e9).coerceIn(0.0, MAX_DT)
        last = nanos
    }

    /** This frame left PAUSE (resume, or home from pause): drop the time before the press. */
    fun resumed() { dt = 0.0; acc = 0.0 }

    /** How many [STEP]s to run this frame, with the delta scaled by [scale] (debug slow motion; 1 in play). */
    fun steps(scale: Double = 1.0): Int {
        acc += dt * scale
        var n = 0
        while (acc >= STEP) { acc -= STEP; n++ }
        return n
    }

    companion object {
        const val STEP = 1.0 / 60
        const val MAX_DT = 0.25
    }
}
