package com.galaxyandsun.daidatanhhung.core

import org.junit.Assert.assertEquals
import org.junit.Test

/** TASK-020 W17 / A3 (Mission flow Rule 7c): the special pad's icon is set per beat type. */
class SpecialIconTest {
    @Test fun holdMeterShowsAFistAndTrainingTheBanner() {
        assertEquals(SpecialIcon.FIST, BeatType.HOLD.specialIcon)
        assertEquals(SpecialIcon.BANNER, BeatType.TRAINING.specialIcon)
    }

    @Test fun theRealMissionsHoldBeatGetsTheFist() {
        val g = TestContent.fullGame()
        val types = g.run.beats.indices.map { g.run.typeOf(it) }
        assertEquals(true, BeatType.HOLD in types)
        types.filter { it == BeatType.HOLD || it == BeatType.TRAINING }.forEach {
            assertEquals(if (it == BeatType.HOLD) SpecialIcon.FIST else SpecialIcon.BANNER, it.specialIcon)
        }
    }
}
