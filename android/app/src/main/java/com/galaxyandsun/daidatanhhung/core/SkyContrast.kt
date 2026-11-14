package com.galaxyandsun.daidatanhhung.core

import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow

/**
 * The pop outline ("Ối!", "Đỡ được!") chosen from the sky it sits on, not the theme's name (r9; as iOS
 * GameCore SkyContrast.popOutline). WCAG 2.x relative luminance (0.03928 threshold, as iOS; no rounding) and contrast
 * ratio; colours are ARGB ints.
 */
object SkyContrast {
    const val INK = 0xFF3A2A20.toInt()
    const val CREAM = 0xFFFFF6E3.toInt()

    private fun channel(c: Int): Double {
        val s = (c and 0xFF) / 255.0
        return if (s <= 0.03928) s / 12.92 else ((s + 0.055) / 1.055).pow(2.4)
    }

    /** WCAG relative luminance, 0 (black) … 1 (white). */
    fun luminance(argb: Int) = 0.2126 * channel(argb shr 16) + 0.7152 * channel(argb shr 8) + 0.0722 * channel(argb)

    /** WCAG contrast ratio, 1 … 21. */
    fun contrast(a: Int, b: Int): Double {
        val la = luminance(a); val lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    /** The outline that contrasts better with the sky band: each candidate is judged by its worse band end; ink wins a tie. */
    fun popOutline(top: Int, bottom: Int): Int {
        val ink = min(contrast(INK, top), contrast(INK, bottom))
        val cream = min(contrast(CREAM, top), contrast(CREAM, bottom))
        return if (cream > ink) CREAM else INK
    }
}
