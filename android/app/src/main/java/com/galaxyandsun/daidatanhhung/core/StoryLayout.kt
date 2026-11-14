package com.galaxyandsun.daidatanhhung.core

import kotlin.math.max
import kotlin.math.min

/**
 * story-screens.md §5.2 (r8): where the placeholder still and the "Phần n / Part n" label go on a story screen.
 * World px (1280 × 720); pure, so the bounds are unit-tested at every k.
 */
object StoryLayout {
    /** An axis-aligned box in world px. */
    data class Box(val left: Double, val top: Double, val right: Double, val bottom: Double) {
        val width get() = right - left
        val cx get() = (left + right) / 2
        val cy get() = (top + bottom) / 2
    }

    const val CENTRE_X = 640.0
    const val TOP_MARGIN = 18.0
    const val MIN_STILL = 192.0
    /** Intro and caption: 256, bottom ≤ 301. */
    const val STILL = 256.0; const val STILL_BOTTOM = 301.0
    /** Beat card: 208, bottom ≤ 233. */
    const val CARD_STILL = 208.0; const val CARD_STILL_BOTTOM = 233.0
    /** The part label is 28 px; its box is 28 tall around the centre. */
    const val LABEL_SIZE = 28.0

    /** The part label's centre y: max(corner bottom + 8 + 16, panel top − 24) (matches iOS buildPlayHUD). */
    fun partLabelCentreY(panelTop: Double, cornerClear: Double) = max(cornerClear + 16, panelTop - 24)
    /** The part label's top edge. */
    fun partLabelTop(panelTop: Double, cornerClear: Double) = partLabelCentreY(panelTop, cornerClear) - LABEL_SIZE / 2

    /**
     * The placeholder portrait's square, centred on x 640: [card] 208 (bottom ≤ 233) else 256 (bottom ≤ 301); also
     * ≥ 8 px above the part label when one shows, right of the pause/sound block ([cornerRight] + 8) and below the
     * top margin. Smaller than 192 → null (the background shows alone).
     */
    fun still(card: Boolean, cornerRight: Double, labelTop: Double?): Box? {
        var bottom = if (card) CARD_STILL_BOTTOM else STILL_BOTTOM
        if (labelTop != null) bottom = min(bottom, labelTop - 8)
        val size = minOf(if (card) CARD_STILL else STILL, bottom - TOP_MARGIN, 2 * (CENTRE_X - (cornerRight + 8)))
        if (size < MIN_STILL) return null
        return Box(CENTRE_X - size / 2, bottom - size, CENTRE_X + size / 2, bottom)
    }
}
