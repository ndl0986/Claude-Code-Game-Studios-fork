package com.galaxyandsun.daidatanhhung.core

import com.galaxyandsun.daidatanhhung.core.SkyContrast.CREAM
import com.galaxyandsun.daidatanhhung.core.SkyContrast.INK
import org.junit.Assert.assertEquals
import org.junit.Test

/** r9: the pop outline follows the actual sky band (themes.json), judged at the band's worse end (as iOS). */
class SkyContrastTest {
    private fun hex(s: String) = (0xFF000000 or s.removePrefix("#").toLong(16)).toInt()

    @Test fun wcagSanity() {
        assertEquals(21.0, SkyContrast.contrast(hex("#FFFFFF"), hex("#000000")), 1e-9)
        assertEquals(1.0, SkyContrast.contrast(INK, INK), 1e-9)
        assertEquals("ink vs the river sky top (r8b table 7.9)", 7.9, SkyContrast.contrast(INK, hex("#9CCBEA")), 0.05)
    }

    /** iOS SkyContrastTests values (game-dev-ios, r9): ink / cream contrast per band end, 3 decimals, and the result. */
    @Test fun matchesIosValuesPerBand() {
        data class Row(val name: String, val top: String, val bottom: String, val ink: Pair<Double, Double>, val cream: Pair<Double, Double>, val want: Int)
        val rows = listOf(
            Row("village/bamboo", "#A9D3EC", "#CDE6EE", 8.627 to 10.542, 1.479 to 1.210, INK),
            Row("river", "#9CCBEA", "#BFE0F2", 7.927 to 9.896, 1.609 to 1.289, INK),
            Row("camp", "#2E3156", "#3B3F6B", 1.103 to 1.377, 11.565 to 9.266, CREAM),
            Row("QC day sky", "#C6E2EE", "#C6E2EE", 10.127 to 10.127, 1.260 to 1.260, INK))
        for (r in rows) {
            val t = hex(r.top); val b = hex(r.bottom)
            assertEquals("${r.name} ink/top", r.ink.first, SkyContrast.contrast(INK, t), 0.0005)
            assertEquals("${r.name} ink/bottom", r.ink.second, SkyContrast.contrast(INK, b), 0.0005)
            assertEquals("${r.name} cream/top", r.cream.first, SkyContrast.contrast(CREAM, t), 0.0005)
            assertEquals("${r.name} cream/bottom", r.cream.second, SkyContrast.contrast(CREAM, b), 0.0005)
            assertEquals(r.name, r.want, SkyContrast.popOutline(t, b))
        }
    }

    /** Every theme in content/data/themes.json: camp → cream, every other theme → ink. */
    @Test fun everyThemeBandPicksItsOutline() {
        val themes = TestContent.load().themes!!.themes
        for ((name, th) in themes) {
            val want = if (name == "camp") CREAM else INK
            assertEquals(name, want, SkyContrast.popOutline(hex(th.skyBand.top), hex(th.skyBand.bottom)))
        }
    }

    @Test fun aTieGoesToInk() {
        // a grey where ink and cream contrast equally can't be hit exactly in 8-bit; the rule is strict: cream only if better
        val g = hex("#8A8070")
        val ink = SkyContrast.contrast(INK, g); val cream = SkyContrast.contrast(CREAM, g)
        assertEquals(if (cream > ink) CREAM else INK, SkyContrast.popOutline(g, g))
    }
}
