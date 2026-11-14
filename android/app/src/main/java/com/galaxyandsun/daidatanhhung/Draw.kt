package com.galaxyandsun.daidatanhhung

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.text.TextUtils
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.sin

/** The prototype's palette (index.html `C`). */
object C {
    const val RED = 0xFFD9342B.toInt(); const val GOLD = 0xFFF2B632.toInt(); const val GOLD_DARK = 0xFFC98A12.toInt()
    const val CREAM = 0xFFFFF6E3.toInt(); const val INK = 0xFF3A2A1F.toInt(); const val SKIN = 0xFFF5C9A0.toInt()
    const val DEEP_INK = 0xFF1A120C.toInt() // labels on #3FA34D (white there is 3.2:1)
    const val HAIR = 0xFF231A16.toInt(); const val INDIGO = 0xFF2B4C8C.toInt(); const val LEAF = 0xFF6CBF4F.toInt()
    const val LEAF_DARK = 0xFF3F8A3A.toInt(); const val RIVER = 0xFF5AB4D6.toInt(); const val EARTH = 0xFFC99A5B.toInt()
    const val EARTH_DARK = 0xFFA87A45.toInt(); const val ENEMY = 0xFF6B5B95.toInt(); const val ENEMY_DARK = 0xFF4B3F6E.toInt()
    const val STEEL = 0xFF8D93A8.toInt(); const val TEAL = 0xFF3E6B6B.toInt(); const val GLOW = 0xFFFFE24A.toInt()
    const val PANEL = 0xDB2A2440.toInt(); const val BG = 0xFF2A2440.toInt(); const val WHITE = 0xFFFFFFFF.toInt()
    /** Quiz GDD / art bible §4: wrong = soft lavender-grey (never red), right = rice-green. */
    const val TRY_AGAIN = 0xFF9C8FB8.toInt(); const val RIGHT = 0xFF3FA34D.toInt()
    fun a(color: Int, alpha: Double): Int = (color and 0x00FFFFFF) or ((alpha.coerceIn(0.0, 1.0) * 255).toInt() shl 24)
}

/** Canvas helpers in world units (the canvas is already scaled to the 1280×720 world). */
class Draw(val bold: Typeface, val semi: Typeface) {
    lateinit var c: Canvas
    private val fillP = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
    private val strokeP = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE; strokeCap = Paint.Cap.ROUND; strokeJoin = Paint.Join.ROUND }
    private val textP = TextPaint(Paint.ANTI_ALIAS_FLAG)
    private val rect = RectF()
    val path = Path()
    var alpha = 1.0

    fun fill(color: Int): Paint = fillP.apply { this.color = color; this.alpha = (Color.alphaOf(color) * this@Draw.alpha).toInt() }
    fun stroke(color: Int, w: Float): Paint = strokeP.apply { this.color = color; strokeWidth = w; this.alpha = (Color.alphaOf(color) * this@Draw.alpha).toInt() }

    fun rr(x: Float, y: Float, w: Float, h: Float, r: Float, fill: Int?, stroke: Int? = null, lw: Float = 4f) {
        rect.set(x, y, x + w, y + h)
        if (fill != null) c.drawRoundRect(rect, r, r, fill(fill))
        if (stroke != null) c.drawRoundRect(rect, r, r, stroke(stroke, lw))
    }
    fun circle(x: Float, y: Float, r: Float, fill: Int?, stroke: Int? = null, lw: Float = 4f) {
        if (fill != null) c.drawCircle(x, y, r, fill(fill))
        if (stroke != null) c.drawCircle(x, y, r, stroke(stroke, lw))
    }
    fun ellipse(x: Float, y: Float, rx: Float, ry: Float, fill: Int, rot: Float = 0f) {
        c.save(); c.translate(x, y); if (rot != 0f) c.rotate(Math.toDegrees(rot.toDouble()).toFloat())
        rect.set(-rx, -ry, rx, ry); c.drawOval(rect, fill(fill)); c.restore()
    }
    fun arc(x: Float, y: Float, r: Float, a0: Float, a1: Float, color: Int, lw: Float) {
        rect.set(x - r, y - r, x + r, y + r)
        c.drawArc(rect, Math.toDegrees(a0.toDouble()).toFloat(), Math.toDegrees((a1 - a0).toDouble()).toFloat(), false, stroke(color, lw))
    }
    /** A filled half-dome (the art bible's helmets): the top half of a circle. */
    fun dome(x: Float, y: Float, r: Float, color: Int) {
        rect.set(x - r, y - r, x + r, y + r); c.drawArc(rect, 180f, 180f, true, fill(color))
    }
    fun poly(color: Int, vararg pts: Float) {
        path.reset(); path.moveTo(pts[0], pts[1]); var i = 2
        while (i < pts.size) { path.lineTo(pts[i], pts[i + 1]); i += 2 }
        path.close(); c.drawPath(path, fill(color))
    }
    fun star(x: Float, y: Float, r: Float, fill: Int, stroke: Int?, rot: Float = 0f) {
        path.reset()
        for (i in 0 until 10) {
            val a = rot - PI / 2 + i * PI / 5; val rad = if (i % 2 == 1) r * 0.45f else r
            val px = x + cos(a).toFloat() * rad; val py = y + sin(a).toFloat() * rad
            if (i == 0) path.moveTo(px, py) else path.lineTo(px, py)
        }
        path.close(); c.drawPath(path, fill(fill))
        if (stroke != null) c.drawPath(path, stroke(stroke, max(2f, r * 0.12f)))
    }
    /** The bronze-drum ring motif. */
    fun drum(x: Float, y: Float, r: Float, color: Int) {
        circle(x, y, r, null, color, max(2f, r * 0.06f)); circle(x, y, r * 0.72f, null, color, max(1.5f, r * 0.04f))
        for (i in 0 until 14) {
            val a = i * PI * 2 / 14
            c.drawLine(x + cos(a).toFloat() * r * 0.78f, y + sin(a).toFloat() * r * 0.78f, x + cos(a).toFloat() * r * 0.94f, y + sin(a).toFloat() * r * 0.94f, stroke(color, max(1.5f, r * 0.05f)))
        }
        star(x, y, r * 0.5f, color, null)
    }

    /** One line of text, centred vertically on [y]. */
    fun text(s: String, x: Float, y: Float, size: Float, color: Int, align: Paint.Align = Paint.Align.CENTER, semiBold: Boolean = false) {
        textP.typeface = if (semiBold) semi else bold; textP.textSize = size; textP.color = color; textP.textAlign = align
        textP.alpha = (Color.alphaOf(color) * alpha).toInt()
        val fm = textP.fontMetrics
        c.drawText(s, x, y - (fm.ascent + fm.descent) / 2, textP)
    }

    /** [text] with a stroke [outline] of [width] world px drawn under the fill (contrast on busy backgrounds). */
    fun textOutlined(s: String, x: Float, y: Float, size: Float, color: Int, outline: Int, width: Float, semiBold: Boolean = false) {
        textP.typeface = if (semiBold) semi else bold; textP.textSize = size; textP.textAlign = Paint.Align.CENTER
        val fm = textP.fontMetrics; val by = y - (fm.ascent + fm.descent) / 2
        textP.style = Paint.Style.STROKE; textP.strokeWidth = width; textP.strokeJoin = Paint.Join.ROUND
        textP.color = outline; textP.alpha = (Color.alphaOf(outline) * alpha).toInt(); c.drawText(s, x, by, textP)
        textP.style = Paint.Style.FILL; textP.color = color; textP.alpha = (Color.alphaOf(color) * alpha).toInt(); c.drawText(s, x, by, textP)
    }

    /** Wrapped text centred on (x, y), at most [maxLines] lines (Android's own shaping: full diacritics); optional [outline]. */
    fun textBox(s: String, x: Float, y: Float, maxW: Float, size: Float, color: Int, maxLines: Int = 2, semiBold: Boolean = false, outline: Int? = null, outlineW: Float = 0f) {
        if (outline != null) {
            textP.typeface = if (semiBold) semi else bold; textP.textSize = size; textP.textAlign = Paint.Align.LEFT
            textP.style = Paint.Style.STROKE; textP.strokeWidth = outlineW; textP.strokeJoin = Paint.Join.ROUND
            textP.color = outline; textP.alpha = (Color.alphaOf(outline) * alpha).toInt()
            val l = StaticLayout.Builder.obtain(s, 0, s.length, textP, maxW.toInt()).setAlignment(Layout.Alignment.ALIGN_CENTER)
                .setMaxLines(maxLines).setEllipsize(TextUtils.TruncateAt.END).setLineSpacing(0f, pitchMult()).setIncludePad(false).build()
            c.save(); c.translate(x - maxW / 2, y - l.height / 2f); l.draw(c); c.restore()
            textP.style = Paint.Style.FILL
        }
        textP.typeface = if (semiBold) semi else bold; textP.textSize = size; textP.color = color; textP.textAlign = Paint.Align.LEFT
        textP.alpha = (Color.alphaOf(color) * alpha).toInt()
        val l = StaticLayout.Builder.obtain(s, 0, s.length, textP, maxW.toInt()).setAlignment(Layout.Alignment.ALIGN_CENTER)
            .setMaxLines(maxLines).setEllipsize(TextUtils.TruncateAt.END).setLineSpacing(0f, pitchMult()).setIncludePad(false).build()
        c.save(); c.translate(x - maxW / 2, y - l.height / 2f); l.draw(c); c.restore()
    }

    /**
     * Language Rule 7: the line pitch is LINE_HEIGHT × the font size (the specs' and R8c's 1.35 em). StaticLayout's spacing
     * multiplies the font's own line height (≈ 1.37 em for Nunito), so scale it down to hit 1.35 em exactly (QC r6).
     */
    private fun pitchMult(): Float { val fm = textP.fontMetrics; return LINE_HEIGHT * textP.textSize / (fm.descent - fm.ascent) }

    /** How many lines [textBox] would use for [s] (up to [maxLines]). */
    fun lineCount(s: String, maxW: Float, size: Float, maxLines: Int, semiBold: Boolean = false): Int {
        textP.typeface = if (semiBold) semi else bold; textP.textSize = size
        return StaticLayout.Builder.obtain(s, 0, s.length, textP, maxW.toInt()).setMaxLines(maxLines).setLineSpacing(0f, pitchMult()).setIncludePad(false).build().lineCount
    }

    fun measure(s: String, size: Float): Float { textP.typeface = bold; textP.textSize = size; return textP.measureText(s) }

    object Color { fun alphaOf(c: Int) = (c ushr 24) and 0xFF }

    companion object {
        /** Language & text GDD rule 7: line height ≥ 1.35 × the font size (stacked Vietnamese marks never touch). */
        const val LINE_HEIGHT = 1.35f
    }
}
