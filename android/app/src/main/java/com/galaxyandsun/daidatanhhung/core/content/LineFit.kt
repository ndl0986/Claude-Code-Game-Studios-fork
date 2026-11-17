package com.galaxyandsun.daidatanhhung.core.content

/**
 * R8c (Language & text GDD F1, D-21): how many lines a text takes in its field's box, using Nunito's
 * real advances at the rendered weight (content/metrics/nunito-advances.json, not the font's
 * default-instance hmtx), a greedy word wrap at spaces, and a small allowance for kerning.
 * Deterministic and platform-independent, so both apps' validators agree.
 */
class LineFit(private val table: AdvanceTable) {
    /** The width of [s] in world px at [fontPx] and [weight]. A missing character counts as an em (fails loudly). */
    fun width(s: String, fontPx: Int, weight: Int): Double {
        val adv = table.weights[weight.toString()] ?: error("no advances for weight $weight")
        var units = 0
        var i = 0
        while (i < s.length) {
            val cp = s.codePointAt(i)
            units += adv[String.format("%04X", cp)] ?: table.unitsPerEm
            i += Character.charCount(cp)
        }
        return units.toDouble() * fontPx / table.unitsPerEm
    }

    /** Lines after a greedy wrap at spaces into [boxWidth] / (1 + [allowance]); a word wider than the box counts as overflow. */
    fun lines(s: String, f: FitField, allowance: Double): Result {
        val limit = f.boxWidth / (1 + allowance)
        val space = width(" ", f.fontPx, f.weight)
        var lines = 1; var cur = 0.0; var overflow = false
        for (word in s.split(' ').filter { it.isNotEmpty() }) {
            val w = width(word, f.fontPx, f.weight)
            if (w > limit) overflow = true
            if (cur == 0.0) cur = w
            else if (cur + space + w <= limit) cur += space + w
            else { lines++; cur = w }
        }
        return Result(lines, overflow || lines > f.maxLines)
    }

    data class Result(val lines: Int, val fails: Boolean)
}
