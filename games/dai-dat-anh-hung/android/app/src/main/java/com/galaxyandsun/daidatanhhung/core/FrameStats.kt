package com.galaxyandsun.daidatanhhung.core

import kotlin.math.ceil

/**
 * TASK-007 low-end profiling (D-37): an opt-in frame-time recorder, off by default. The app feeds it each frame's
 * vsync interval and the time its own frame work took (input, sim steps, draw); every [windowS] seconds of frames it
 * returns a one-line summary for logcat. Nothing is stored or sent anywhere (P-04).
 */
class FrameStats(private val windowS: Double = 10.0) {
    private val intervals = ArrayList<Double>()
    private val work = ArrayList<Double>()
    private var elapsed = 0.0

    /** One frame, in ms. Returns the window's summary when the window is full, else null. */
    fun add(intervalMs: Double, workMs: Double): String? {
        intervals += intervalMs; work += workMs; elapsed += intervalMs / 1000
        if (elapsed < windowS) return null
        val s = summary(intervals, work)
        intervals.clear(); work.clear(); elapsed = 0.0
        return s
    }

    companion object {
        /** Nearest-rank percentile, [p] in 0..100. */
        fun percentile(xs: List<Double>, p: Double): Double {
            if (xs.isEmpty()) return 0.0
            val sorted = xs.sorted()
            return sorted[(ceil(p / 100 * sorted.size).toInt() - 1).coerceIn(0, sorted.size - 1)]
        }

        private fun f(x: Double) = "%.1f".format(java.util.Locale.ROOT, x)
        private fun dist(xs: List<Double>) =
            "p50=${f(percentile(xs, 50.0))} p90=${f(percentile(xs, 90.0))} p99=${f(percentile(xs, 99.0))} max=${f(xs.maxOrNull() ?: 0.0)}"

        /**
         * `frames=N interval_ms p50 p90 p99 max over20=… over34=… | work_ms p50 p90 p99 max`. over20 / over34: intervals
         * that missed at least one / two 60 Hz vsyncs (20 and 34 ms leave room for vsync jitter).
         */
        fun summary(intervals: List<Double>, work: List<Double>): String =
            "frames=${intervals.size} interval_ms ${dist(intervals)} over20=${intervals.count { it > 20.0 }} over34=${intervals.count { it > 34.0 }}" +
                " | work_ms ${dist(work)}"
    }
}
