package com.galaxyandsun.daidatanhhung.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** D-37 / TASK-007 profiling: the opt-in frame-time recorder's percentiles, jank counts and 10 s windows. */
class FrameStatsTest {
    @Test fun nearestRankPercentiles() {
        val xs = (1..100).map { it.toDouble() }
        assertEquals(50.0, FrameStats.percentile(xs, 50.0), 0.0)
        assertEquals(90.0, FrameStats.percentile(xs, 90.0), 0.0)
        assertEquals(99.0, FrameStats.percentile(xs, 99.0), 0.0)
        assertEquals(7.0, FrameStats.percentile(listOf(7.0), 99.0), 0.0)
        assertEquals(0.0, FrameStats.percentile(emptyList(), 50.0), 0.0)
    }

    @Test fun aWindowOf10SecondsGivesOneSummaryWithJankCounts() {
        val s = FrameStats(10.0)
        var out: String? = null; var n = 0
        while (out == null) { n++; val iv = when (n) { 100 -> 33.4; 200 -> 50.1; else -> 1000.0 / 60 }; out = s.add(iv, 4.0) }
        assertTrue(out, out.startsWith("frames=$n interval_ms p50=16.7"))
        assertTrue(out, out.contains("max=50.1 over20=2 over34=1"))
        assertTrue(out, out.endsWith("| work_ms p50=4.0 p90=4.0 p99=4.0 max=4.0"))
        assertNull("a new window starts empty", s.add(16.7, 4.0))
    }
}
