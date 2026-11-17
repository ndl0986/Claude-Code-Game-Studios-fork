package com.galaxyandsun.daidatanhhung

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Mission flow Rule 7c / look sheet d18: the follower partner is drawn at 0.62 × the hero's height, not at
 * 0.62 of the art unit (r12 pre-freeze; iOS fixed the same mistake). Art unit: the body is 262 tall at s = 1.
 */
class FigureScaleTest {
    private val artUnitHeight = 262.0

    @Test fun theHeroIs180Tall() = assertEquals(180.0, artUnitHeight * Figures.HERO_S, 0.01)

    @Test fun thePartnerIs062OfTheHerosHeight() {
        val hero = artUnitHeight * Figures.HERO_S
        val partner = artUnitHeight * Figures.PARTNER_S
        assertEquals(0.62, partner / hero, 1e-6)
        assertEquals(111.6, partner, 0.05)
    }
}
