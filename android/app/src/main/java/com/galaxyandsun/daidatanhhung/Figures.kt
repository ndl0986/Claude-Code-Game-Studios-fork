package com.galaxyandsun.daidatanhhung

import com.galaxyandsun.daidatanhhung.core.Dropped
import com.galaxyandsun.daidatanhhung.core.Enemy
import com.galaxyandsun.daidatanhhung.core.EnemyState
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin

/**
 * Placeholder figures drawn in code, ported from the prototype and following the art bible:
 * rounded, warm hero; muted purple-grey grumpy-cartoon enemies with dome helmets and padded
 * weapon tips; the commander no taller than the hero; no text inside art.
 */
class Figures(private val d: Draw) {
    private val c get() = d.c
    private fun deg(r: Double) = Math.toDegrees(r).toFloat()

    fun hero(x: Float, y: Float, face: Int, walk: Boolean, defend: Boolean, attack: Double?, t: Double, s: Float = 1f, tunic: Int = C.RED) {
        c.save(); c.translate(x, y); c.scale(face * s, s)
        d.ellipse(0f, 4f, 60f, 12f, C.a(0, 0.18))
        val w = if (walk) sin(t * 14).toFloat() else 0f
        val bob = if (walk) abs(sin(t * 14)).toFloat() * 4 else 0f
        c.translate(0f, -bob)
        if (!defend) d.ellipse(-30f, -118f, 14f, 40f, C.GOLD_DARK)
        d.rr(-24 + w * 8, -70f, 20f, 68f, 8f, C.INDIGO); d.rr(4 - w * 8, -70f, 20f, 68f, 8f, C.INDIGO)
        d.rr(-28 + w * 8, -10f, 28f, 12f, 6f, C.INK); d.rr(0 - w * 8, -10f, 28f, 12f, 6f, C.INK)
        d.path.reset(); d.path.moveTo(-34f, -150f); d.path.lineTo(34f, -150f); d.path.lineTo(42f, -62f)
        d.path.quadTo(0f, -52f, -42f, -62f); d.path.close(); c.drawPath(d.path, d.fill(tunic))
        d.rr(-38f, -96f, 76f, 12f, 6f, C.GOLD)
        d.poly(C.GOLD, -14f, -150f, 0f, -126f, 14f, -150f)
        val swing = attack ?: -1.0
        val ang = if (swing >= 0) -1.9 + swing * 2.6 else if (defend) 0.9 else -0.6
        c.save(); c.translate(18f, -128f); c.rotate(deg(ang))
        d.rr(-6f, -150f, 12f, 190f, 6f, 0xFF8A5A2B.toInt()); d.rr(-8f, -158f, 16f, 18f, 6f, C.GOLD); d.circle(0f, 0f, 12f, C.SKIN)
        c.restore()
        if (swing in 0.2..0.85) d.arc(18f, -128f, 150f, (-1.9 + 0.3).toFloat(), (-1.9 + swing * 2.6 - 0.3).toFloat(), C.a(C.WHITE, 0.8), 10f)
        d.circle(0f, -196f, 44f, C.SKIN)
        d.dome(-2f, -200f, 46f, C.HAIR)
        d.circle(-14f, -246f, 15f, C.HAIR)
        d.rr(-46f, -214f, 92f, 12f, 6f, C.RED)
        val flap = (sin(t * 9) * 6).toFloat()
        d.path.reset(); d.path.moveTo(-44f, -210f); d.path.quadTo(-70f, -206 + flap, -84f, -192 + flap); d.path.lineTo(-78f, -186 + flap)
        d.path.quadTo(-64f, -198f, -44f, -200f); d.path.close(); c.drawPath(d.path, d.fill(C.RED))
        d.circle(14f, -190f, 6f, C.INK); d.circle(32f, -190f, 6f, C.INK); d.circle(16f, -192f, 2f, C.WHITE); d.circle(34f, -192f, 2f, C.WHITE)
        val ink = d.stroke(C.INK, 4f)
        c.drawLine(8f, -204f, 20f, -202f, ink); c.drawLine(28f, -202f, 40f, -204f, ink)
        d.arc(24f, -176f, 9f, 0.2f, (Math.PI - 0.2).toFloat(), C.INK, 4f)
        d.circle(6f, -178f, 6f, C.a(0xFFF0786E.toInt(), 0.5)); d.circle(40f, -178f, 5f, C.a(0xFFF0786E.toInt(), 0.5))
        if (defend) {
            d.circle(46f, -128f, 50f, 0xFFD8A657.toInt(), C.GOLD_DARK, 5f)
            d.circle(46f, -128f, 36f, null, 0xFFB8823A.toInt(), 3f); d.circle(46f, -128f, 22f, null, 0xFFB8823A.toInt(), 3f)
            d.circle(46f, -128f, 10f, C.GOLD, C.GOLD_DARK, 3f)
        }
        c.restore()
    }

    private fun grumpy(fx: Float, fy: Float, r: Float, dizzy: Boolean, t: Double) {
        if (dizzy) {
            for (ex in listOf(fx - r * 0.3f, fx + r * 0.25f)) d.arc(ex, fy, r * 0.14f, (t * 8).toFloat(), (t * 8 + 5).toFloat(), C.INK, 3f)
            d.circle(fx, fy + r * 0.42f, r * 0.14f, null, C.INK, 3f)
        } else {
            d.circle(fx - r * 0.3f, fy, r * 0.11f, C.INK); d.circle(fx + r * 0.25f, fy, r * 0.11f, C.INK)
            val p = d.stroke(C.INK, 4f)
            c.drawLine(fx - r * 0.48f, fy - r * 0.28f, fx - r * 0.12f, fy - r * 0.16f, p); c.drawLine(fx + r * 0.42f, fy - r * 0.28f, fx + r * 0.08f, fy - r * 0.16f, p)
            d.arc(fx, fy + r * 0.5f, r * 0.22f, (Math.PI + 0.4).toFloat(), (2 * Math.PI - 0.4).toFloat(), C.INK, 4f)
        }
    }

    fun enemy(e: Enemy, ground: Float, t: Double) {
        val k = e.kind; val x = e.x.toFloat()
        if (e.state == EnemyState.WINDUP) {
            val p = 0.5 + 0.5 * sin(t * 16)
            d.ellipse(x, ground - 130, (if (k == "leader") 110f else 80f) + p.toFloat() * 10, 160f, C.a(C.GLOW, 0.3 + 0.25 * p))
        }
        c.save(); c.translate(x, ground); c.scale(e.face.toFloat(), 1f)
        if (e.state == EnemyState.HURT) c.rotate(deg(-0.12))
        d.ellipse(0f, 4f, if (k == "leader") 80f else if (k == "shield") 66f else 50f, 12f, C.a(0, 0.18))
        val walking = e.state == EnemyState.ENTER || e.state == EnemyState.FLEE || (e.state == EnemyState.APPROACH && e.moving)
        val lw = if (walking) sin(t * (if (e.state == EnemyState.FLEE) 24 else 12) + e.id).toFloat() else 0f
        val lean = if (e.state == EnemyState.WINDUP) -0.12 else if (e.state == EnemyState.STRIKE) 0.15 else 0.0
        val weapon = e.state != EnemyState.FLEE
        val dizzy = e.state == EnemyState.FLEE || e.state == EnemyState.HURT
        when (k) {
            "shield" -> {
                d.rr(-34 + lw * 8, -64f, 26f, 62f, 9f, C.ENEMY_DARK); d.rr(8 - lw * 8, -64f, 26f, 62f, 9f, C.ENEMY_DARK)
                c.save(); c.rotate(deg(lean))
                d.ellipse(0f, -112f, 58f, 56f, C.ENEMY)
                d.circle(0f, -184f, 34f, C.SKIN); grumpy(10f, -182f, 34f, dizzy, t)
                d.dome(0f, -192f, 38f, C.STEEL); d.rr(-40f, -196f, 14f, 34f, 6f, C.STEEL); d.rr(26f, -196f, 14f, 34f, 6f, C.STEEL)
                if (weapon) {
                    val push = if (e.state == EnemyState.STRIKE) 34f else if (e.state == EnemyState.WINDUP) -16f else 0f
                    d.rr(34 + push, -168f, 46f, 120f, 10f, C.TEAL, 0xFF2B4F4F.toInt(), 5f)
                    for (ry in listOf(-150f, -108f, -66f)) d.circle(57 + push, ry, 5f, 0xFFC8D3D3.toInt())
                } else { d.circle(-40f, -160f, 12f, C.SKIN); d.circle(44f, -164f, 12f, C.SKIN) }
                c.restore()
            }
            "leader" -> {
                d.rr(-50 + lw * 8, -66f, 36f, 64f, 12f, C.ENEMY_DARK); d.rr(14 - lw * 8, -66f, 36f, 64f, 12f, C.ENEMY_DARK)
                c.save(); c.rotate(deg(lean))
                d.poly(0xFF3B3A6B.toInt(), -60f, -170f, -100f, -64f, -30f, -70f)
                d.rr(-78f, -174f, 156f, 116f, 44f, C.ENEMY); d.rr(-54f, -156f, 108f, 56f, 16f, C.STEEL); d.circle(0f, -128f, 10f, C.GOLD)
                d.circle(6f, -200f, 38f, C.SKIN); grumpy(18f, -198f, 38f, dizzy, t)
                d.dome(6f, -208f, 42f, C.STEEL); d.rr(-40f, -212f, 92f, 10f, 5f, C.STEEL)
                d.path.reset(); d.path.moveTo(2f, -246f); d.path.quadTo(-18f, -260f, -40f, -252f); d.path.quadTo(-20f, -248f, -8f, -242f); d.path.close()
                c.drawPath(d.path, d.fill(0xFFC0733A.toInt()))
                if (weapon) {
                    val sw = if (e.state == EnemyState.WINDUP) -1.2 else if (e.state == EnemyState.STRIKE) 0.6 else -0.4
                    c.save(); c.translate(60f, -130f); c.rotate(deg(sw))
                    d.rr(-7f, -16f, 14f, 100f, 7f, 0xFF7A5530.toInt()); d.ellipse(0f, 96f, 28f, 32f, 0xFFE9E1CF.toInt())
                    c.restore()
                } else { d.circle(-80f, -170f, 14f, C.SKIN); d.circle(90f, -174f, 14f, C.SKIN) }
                c.restore()
            }
            else -> {
                d.rr(-18 + lw * 8, -80f, 16f, 78f, 7f, C.ENEMY_DARK); d.rr(2 - lw * 8, -80f, 16f, 78f, 7f, C.ENEMY_DARK)
                c.save(); c.rotate(deg(lean))
                d.rr(-26f, -176f, 52f, 104f, 18f, C.ENEMY); d.rr(-28f, -122f, 56f, 10f, 5f, C.STEEL)
                d.circle(4f, -206f, 32f, C.SKIN); grumpy(14f, -206f, 32f, dizzy, t)
                d.dome(4f, -214f, 36f, C.STEEL); d.rr(-36f, -218f, 80f, 10f, 5f, C.STEEL); d.circle(4f, -252f, 7f, C.STEEL)
                if (weapon) {
                    val reach = if (e.state == EnemyState.STRIKE) 40f else if (e.state == EnemyState.WINDUP) -30f else 0f
                    d.rr(-40 + reach, -140f, 150f, 10f, 5f, 0xFF7A5530.toInt())
                    d.circle(118 + reach, -135f, 17f, 0xFFE9E1CF.toInt(), 0xFFB8AB90.toInt(), 3f)
                    d.ellipse(86 + reach, -150f, 14f, 9f, 0xFF9B8FC0.toInt(), -0.3f)
                } else { d.circle(-30f, -190f, 10f, C.SKIN); d.circle(36f, -194f, 10f, C.SKIN) }
                c.restore()
            }
        }
        c.restore()
        val topY = ground - (if (k == "leader") 280 else if (k == "shield") 240 else 272)
        if (dizzy) for (i in 0 until 3) { val a = t * 5 + i * 2.1; d.star(x + cos(a).toFloat() * 34, topY + 20 + sin(a).toFloat() * 10, 9f, C.GLOW, C.GOLD_DARK, a.toFloat()) }
        if (e.state == EnemyState.WINDUP) { // the telegraph: glow + a drawn "!" (a HUD glyph, not text in art)
            val by = topY - 20
            d.circle(x, by, 30f, C.GLOW, C.GOLD_DARK, 4f); d.rr(x - 5, by - 18, 10f, 24f, 5f, C.INK); d.circle(x, by + 14, 5.5f, C.INK)
        }
    }

    /** A straw training dummy on a post; knocked over (rotated) once hit. */
    fun dummy(x: Float, ground: Float, down: Boolean, t: Double) {
        c.save(); c.translate(x, ground)
        if (down) c.rotate(-80f * minOf(1f, (t * 4).toFloat()))
        d.rr(-6f, -150f, 12f, 150f, 6f, 0xFF8A5A2B.toInt())
        d.ellipse(0f, -110f, 34f, 46f, 0xFFE3C46B.toInt()); d.circle(0f, -175f, 26f, 0xFFE3C46B.toInt(), 0xFFB8963A.toInt(), 3f)
        d.rr(-40f, -128f, 80f, 10f, 5f, 0xFFB8963A.toInt())
        c.restore()
    }

    /** Training's friendly partner: the hero's figure in an indigo practice tunic with a padded stick. */
    fun partner(p: Enemy, ground: Float, t: Double) {
        val x = p.x.toFloat()
        if (p.state == EnemyState.WINDUP) {
            val k = 0.5 + 0.5 * sin(t * 16)
            d.ellipse(x, ground - 130, 80f + k.toFloat() * 10, 160f, C.a(C.GLOW, 0.3 + 0.25 * k))
            d.circle(x, ground - 292, 30f, C.GLOW, C.GOLD_DARK, 4f); d.rr(x - 5, ground - 310, 10f, 24f, 5f, C.INK); d.circle(x, ground - 278, 5.5f, C.INK)
        }
        val swing = when (p.state) { EnemyState.WINDUP -> 0.0; EnemyState.STRIKE -> 0.6; else -> null }
        hero(x, ground, p.face, false, false, swing, t, 0.92f, tunic = C.INDIGO)
    }

    fun dropped(w: Dropped, ground: Float) {
        val old = d.alpha; d.alpha = minOf(1.0, w.life)
        c.save(); c.translate(w.x.toFloat(), ground - 8); c.rotate(deg(w.rot))
        when (w.kind) {
            "spear" -> { d.rr(-75f, -5f, 150f, 10f, 5f, 0xFF7A5530.toInt()); d.circle(80f, 0f, 15f, 0xFFE9E1CF.toInt(), 0xFFB8AB90.toInt(), 3f) }
            "shield" -> d.rr(-60f, -16f, 120f, 32f, 8f, C.TEAL)
            else -> { d.rr(-60f, -6f, 120f, 12f, 6f, 0xFF7A5530.toInt()); d.ellipse(70f, 0f, 30f, 24f, 0xFFE9E1CF.toInt()) }
        }
        c.restore(); d.alpha = old
    }

    fun hand(x: Float, y: Float, t: Double) {
        val b = (sin(t * 6) * 12).toFloat()
        c.save(); c.translate(x, y - 70 - b)
        d.rr(-8f, -10f, 16f, 44f, 8f, C.WHITE, C.INK); d.rr(-26f, -48f, 52f, 48f, 18f, C.WHITE, C.INK)
        d.rr(-30f, -42f, 14f, 30f, 7f, C.WHITE, C.INK); d.rr(-22f, -66f, 44f, 20f, 8f, C.RED)
        c.restore()
    }

    fun arrowDown(x: Float, y: Float, t: Double) {
        val b = (sin(t * 8) * 10).toFloat()
        d.poly(C.GLOW, x - 14, y - 40 + b, x + 14, y - 40 + b, x + 14, y - 10 + b, x + 30, y - 10 + b, x, y + 22 + b, x - 30, y - 10 + b, x - 14, y - 10 + b)
        c.drawPath(d.path, d.stroke(C.INK, 4f))
    }

    // ---- Icons: generic objects, no history claim (quiz pictures in debug, background props) ----
    fun icon(name: String, x: Float, y: Float, s: Float) {
        when (name) {
            "flag" -> flag(x, y, s, C.RED); "flag2" -> flag(x, y, s, C.GOLD); "flag3" -> flag(x, y, s, 0xFF3F9A8A.toInt())
            "child" -> {
                d.rr(x - s * 0.2f, y + s * 0.05f, s * 0.16f, s * 0.45f, 6f, C.INDIGO); d.rr(x + s * 0.04f, y + s * 0.05f, s * 0.16f, s * 0.45f, 6f, C.INDIGO)
                d.rr(x - s * 0.3f, y - s * 0.4f, s * 0.6f, s * 0.55f, 14f, C.RED)
                d.circle(x, y - s * 0.62f, s * 0.3f, C.SKIN); d.dome(x, y - s * 0.66f, s * 0.31f, C.HAIR)
                d.circle(x - s * 0.1f, y - s * 0.6f, 4f, C.INK); d.circle(x + s * 0.1f, y - s * 0.6f, 4f, C.INK)
                d.arc(x, y - s * 0.52f, s * 0.08f, 0.3f, (Math.PI - 0.3).toFloat(), C.INK, 3f)
            }
            "hourglass" -> {
                d.rr(x - s * 0.5f, y - s * 0.75f, s, s * 0.12f, 6f, 0xFF8A5A2B.toInt()); d.rr(x - s * 0.5f, y + s * 0.55f, s, s * 0.12f, 6f, 0xFF8A5A2B.toInt())
                d.poly(0xFFD7EEF5.toInt(), x - s * 0.38f, y - s * 0.63f, x + s * 0.38f, y - s * 0.63f, x + s * 0.06f, y - s * 0.04f, x + s * 0.38f, y + s * 0.55f, x - s * 0.38f, y + s * 0.55f, x - s * 0.06f, y - s * 0.04f)
                c.drawPath(d.path, d.stroke(0xFF8A5A2B.toInt(), 4f))
                d.poly(C.GOLD, x - s * 0.3f, y + s * 0.55f, x + s * 0.3f, y + s * 0.55f, x, y + s * 0.22f)
                d.poly(C.GOLD, x - s * 0.22f, y - s * 0.45f, x + s * 0.22f, y - s * 0.45f, x, y - s * 0.12f)
            }
            "bed" -> {
                d.rr(x - s * 0.8f, y - s * 0.35f, s * 0.14f, s * 0.8f, 5f, 0xFF8A5A2B.toInt()); d.rr(x + s * 0.66f, y - s * 0.05f, s * 0.14f, s * 0.5f, 5f, 0xFF8A5A2B.toInt())
                d.rr(x - s * 0.8f, y + s * 0.05f, s * 1.6f, s * 0.18f, 6f, 0xFFA8794A.toInt()); d.rr(x - s * 0.62f, y - s * 0.12f, s * 0.38f, s * 0.2f, 10f, C.WHITE)
                d.rr(x - s * 0.3f, y - s * 0.16f, s * 0.96f, s * 0.24f, 10f, 0xFF7AA8D8.toInt())
            }
            "orange" -> { d.circle(x, y, s * 0.5f, 0xFFF39A1E.toInt(), 0xFFC97010.toInt()); d.circle(x - s * 0.16f, y - s * 0.16f, s * 0.1f, C.a(C.WHITE, 0.45)); d.ellipse(x + s * 0.14f, y - s * 0.56f, s * 0.2f, s * 0.08f, C.LEAF_DARK, -0.5f) }
            "banana" -> {
                d.path.reset(); d.path.moveTo(x - s * 0.6f, y - s * 0.3f); d.path.quadTo(x - s * 0.3f, y + s * 0.55f, x + s * 0.6f, y - s * 0.15f)
                d.path.quadTo(x - s * 0.15f, y + s * 0.25f, x - s * 0.6f, y - s * 0.3f); d.path.close()
                c.drawPath(d.path, d.fill(0xFFF5D33A.toInt())); c.drawPath(d.path, d.stroke(0xFFB8960F.toInt(), 4f))
                d.rr(x - s * 0.68f, y - s * 0.4f, s * 0.12f, s * 0.14f, 3f, 0xFF6A4A2A.toInt())
            }
            "coconut" -> { d.circle(x, y, s * 0.5f, 0xFF7A5032.toInt(), 0xFF5A3820.toInt()); for ((dx, dy) in listOf(-0.12f to -0.12f, 0.1f to -0.12f, 0f to 0.06f)) d.circle(x + s * dx, y + s * dy, s * 0.06f, 0xFF3E2614.toInt()) }
            "helmet" -> { d.dome(x, y + s * 0.1f, s * 0.5f, C.STEEL); d.rr(x - s * 0.6f, y + s * 0.05f, s * 1.2f, s * 0.14f, 6f, 0xFF6F758A.toInt()); d.circle(x, y - s * 0.45f, s * 0.08f, C.STEEL) }
            "helmet2" -> { d.dome(x, y + s * 0.2f, s * 0.7f, C.STEEL); d.rr(x - s * 0.75f, y + s * 0.15f, s * 1.5f, s * 0.12f, 6f, 0xFF6F758A.toInt()) }
            "helmet3" -> { d.rr(x - s * 0.45f, y - s * 0.45f, s * 0.9f, s * 0.65f, 14f, C.STEEL); d.rr(x - s * 0.55f, y + s * 0.1f, s * 0.22f, s * 0.4f, 6f, 0xFF6F758A.toInt()); d.rr(x + s * 0.33f, y + s * 0.1f, s * 0.22f, s * 0.4f, 6f, 0xFF6F758A.toInt()) }
            "house" -> {
                d.path.reset(); d.path.moveTo(x - s * 0.85f, y - s * 0.05f); d.path.quadTo(x, y - s * 0.95f, x + s * 0.85f, y - s * 0.05f); d.path.close(); c.drawPath(d.path, d.fill(0xFFD9B26A.toInt()))
                d.rr(x - s * 0.6f, y - s * 0.05f, s * 1.2f, s * 0.45f, 6f, 0xFFA8794A.toInt()); d.rr(x - s * 0.12f, y + s * 0.08f, s * 0.24f, s * 0.32f, 4f, 0xFF6A4A2A.toInt())
            }
            "bamboo" -> for ((dx, h) in listOf(-0.35f to 1.3f, 0f to 1.6f, 0.35f to 1.1f)) {
                d.rr(x + s * dx - 9, y + s * 0.6f - s * h, 18f, s * h, 8f, C.LEAF)
                for (j in 1 until 4) d.rr(x + s * dx - 10, y + s * 0.6f - s * h * j / 4, 20f, 5f, 2f, C.LEAF_DARK)
            }
            "boat" -> {
                d.path.reset(); d.path.moveTo(x - s * 0.8f, y); d.path.quadTo(x, y + s * 0.5f, x + s * 0.8f, y); d.path.close(); c.drawPath(d.path, d.fill(0xFF9A6A3A.toInt()))
                d.rr(x - s * 0.9f, y + s * 0.25f, s * 1.8f, s * 0.15f, 8f, C.RIVER)
                d.poly(C.CREAM, x, y - s * 0.7f, x + s * 0.45f, y - s * 0.05f, x, y - s * 0.05f); d.rr(x - 3, y - s * 0.75f, 6f, s * 0.75f, 3f, 0xFF6A4A2A.toInt())
            }
            "lotus" -> {
                for (a in listOf(-0.9, -0.45, 0.0, 0.45, 0.9)) {
                    c.save(); c.translate(x, y + s * 0.2f); c.rotate(deg(a)); d.ellipse(0f, -s * 0.4f, s * 0.17f, s * 0.42f, if (a == 0.0) 0xFFF48FB1.toInt() else 0xFFF8BBD0.toInt()); c.restore()
                }
                d.ellipse(x, y + s * 0.38f, s * 0.7f, s * 0.12f, C.LEAF_DARK)
            }
            else -> { // a drum: the fallback picture for an id with no drawing yet
                d.ellipse(x, y + s * 0.3f, s * 0.7f, s * 0.18f, 0xFF8A5A2B.toInt()); d.rr(x - s * 0.7f, y - s * 0.25f, s * 1.4f, s * 0.55f, 10f, 0xFFB07A3A.toInt())
                d.ellipse(x, y - s * 0.25f, s * 0.7f, s * 0.2f, 0xFFE0A85A.toInt()); d.drum(x, y - s * 0.25f, s * 0.18f, 0xFF8A5A2B.toInt())
            }
        }
    }

    private fun flag(x: Float, y: Float, s: Float, col: Int) {
        d.rr(x - s * 0.5f, y - s * 0.7f, 8f, s * 1.4f, 4f, 0xFF6A4A2A.toInt())
        d.path.reset(); d.path.moveTo(x - s * 0.45f, y - s * 0.68f); d.path.quadTo(x + s * 0.1f, y - s * 0.8f, x + s * 0.7f, y - s * 0.6f)
        d.path.lineTo(x + s * 0.7f, y - s * 0.05f); d.path.quadTo(x + s * 0.1f, y - s * 0.2f, x - s * 0.45f, y - s * 0.1f); d.path.close()
        c.drawPath(d.path, d.fill(col))
    }

    fun background(camX: Double, theme: String, ground: Float) {
        val cam = camX.toFloat()
        d.rr(0f, 0f, 1280f, ground + 10, 0f, 0xFFFFE6B8.toInt())
        d.rr(0f, ground * 0.55f, 1280f, ground * 0.45f + 10, 0f, 0xFFE4F1E6.toInt())
        val sx = 980 - cam * 0.03f
        d.circle(sx, 190f, 54f, C.a(0xFFFFCF5A.toInt(), 0.8)); d.drum(sx, 190f, 46f, C.a(C.GOLD_DARK, 0.4))
        for (i in -1 until 8) {
            val bx = i * 260 - (cam * 0.15f) % 260
            d.path.reset(); d.path.moveTo(bx - 40, ground - 60); d.path.quadTo(bx + 20, ground - 330 - ((i % 3 + 3) % 3) * 30, bx + 90, ground - 260 + ((i % 2 + 2) % 2) * 40)
            d.path.quadTo(bx + 150, ground - 300, bx + 230, ground - 60); d.path.close(); c.drawPath(d.path, d.fill(0xFFA9CFC3.toInt()))
        }
        d.rr(0f, ground - 70, 1280f, 80f, 0f, 0xFF8FC77A.toInt())
        for (i in -1 until 9) {
            val bx = i * 180 - (cam * 0.45f) % 180
            val ii = (i + 10) % 10
            when {
                theme == "village" && ii % 2 == 0 -> icon("house", bx + 60, ground - 92, 80f)
                theme == "bamboo" -> icon("bamboo", bx + 50, ground - 120, 90f)
                theme == "river" && ii % 3 == 0 -> icon("boat", bx + 60, ground - 98, 55f)
                theme == "camp" && ii % 2 == 1 -> { d.poly(0xFFC9B38A.toInt(), bx, ground - 70, bx + 60, ground - 160, bx + 120, ground - 70); icon("flag", bx + 60, ground - 190, 40f) }
                else -> {
                    d.rr(bx + 52, ground - 230, 10f, 160f, 5f, 0xFF8A6A44.toInt())
                    for (a in listOf(-2.4, -1.9, -1.2, -0.7)) { c.save(); c.translate(bx + 57, ground - 230); c.rotate(deg(a)); d.ellipse(34f, 0f, 38f, 9f, C.LEAF_DARK); c.restore() }
                }
            }
        }
        if (theme == "river") d.rr(0f, ground - 30, 1280f, 26f, 0f, C.RIVER)
        d.rr(0f, ground - 6, 1280f, 14f, 0f, C.LEAF)
        d.rr(0f, ground + 8, 1280f, 720 - ground, 0f, C.EARTH)
        for (i in -1 until 12) { val px = i * 130 - cam % 130; d.ellipse(px, ground + 40 + ((i % 3 + 3) % 3) * 18, 18f, 6f, C.EARTH_DARK) }
        for (i in -1 until 6) { val px = i * 340 - cam % 340 + 120; icon("lotus", px, ground + 4, 26f) }
    }
}
