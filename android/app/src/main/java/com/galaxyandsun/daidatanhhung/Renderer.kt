package com.galaxyandsun.daidatanhhung

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import com.galaxyandsun.daidatanhhung.core.Action
import com.galaxyandsun.daidatanhhung.core.ScreenFit
import com.galaxyandsun.daidatanhhung.core.BeatType
import com.galaxyandsun.daidatanhhung.core.ClaimGate
import com.galaxyandsun.daidatanhhung.core.Game
import com.galaxyandsun.daidatanhhung.core.HandHint
import com.galaxyandsun.daidatanhhung.core.Phase
import com.galaxyandsun.daidatanhhung.core.Screen
import com.galaxyandsun.daidatanhhung.core.UiIds
import com.galaxyandsun.daidatanhhung.core.content.Text
import kotlin.math.cos
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/** A touch target drawn this frame: a pad (acts on down) or a button (fires on up inside). */
class Region(
    val key: String, val x: Float, val y: Float, val w: Float, val h: Float, val round: Boolean,
    val pad: Action? = null, val onTap: (() -> Boolean)? = null,
)

/**
 * Draws every screen of the slice into the 1280×720 world, letterboxed inside the safe rect
 * (system bars, cutout and gesture zones), and records the touch regions it drew.
 */
class Renderer(bold: Typeface, semi: Typeface, private val debug: Boolean, private val pictures: (String) -> android.graphics.Bitmap? = { null }) {
    private val d = Draw(bold, semi)
    private val fig = Figures(d)
    private var regions = ArrayList<Region>()
    private var next = ArrayList<Region>()
    @Volatile private var k = 1f; @Volatile private var ox = 0f; @Volatile private var oy = 0f
    private var lastGame: Game? = null

    fun layout(w: Float, h: Float, safe: IntArray, density: Float, padMinDp: Float) {
        val f = ScreenFit.of(w, h, safe, density, padMinDp)
        k = f.k; ox = f.ox; oy = f.oy; fit = f
    }
    private var fit = ScreenFit(1f, 0f, 0f, 0f)

    /** The region under a screen point (topmost first), from the last frame drawn. */
    fun hit(sx: Float, sy: Float): Region? {
        val x = (sx - ox) / k; val y = (sy - oy) / k
        for (i in regions.indices.reversed()) {
            val r = regions[i]
            val inside = if (r.round) hypot(x - r.x, y - r.y) <= r.w * 1.15f else x >= r.x && x <= r.x + r.w && y >= r.y && y <= r.y + r.h
            if (inside) return r
        }
        return null
    }

    fun cardForSlot(g: Game, slot: Int): (() -> Boolean)? = regions.firstOrNull { it.key == "card$slot" }?.onTap

    fun draw(canvas: Canvas, g: Game?, audioReady: Boolean, portrait: Boolean) {
        d.c = canvas
        canvas.drawColor(C.BG)
        canvas.save(); canvas.translate(ox, oy); canvas.scale(k, k)
        canvas.clipRect(0f, 0f, W, H)
        next = ArrayList()
        if (g == null) d.text("No mission bundled", W / 2, H / 2, 40f, C.WHITE)
        else when (g.screen) {
            Screen.TITLE -> title(g, audioReady)
            Screen.INTRO -> story(g, intro = true)
            Screen.PLAY -> play(g)
            Screen.PAUSE -> pause(g)
            Screen.ENDING -> story(g, intro = false)
            Screen.QUIZ -> quiz(g)
            Screen.RESULTS -> results(g)
            Screen.UNLOCK -> unlock(g)
        }
        canvas.restore()
        if (portrait && g != null) { next = ArrayList(); rotate(canvas, g) }
        regions = next
        lastGame = g
    }

    // ---- Widgets ----
    private fun button(key: String, label: String, x: Float, y: Float, w: Float, h: Float, t: Double, pulse: Boolean = false,
                       fill: Int = C.GOLD, shade: Int = C.GOLD_DARK, size: Float = 34f, enabled: Boolean = true, onTap: () -> Boolean) {
        val p = if (pulse && enabled) 1 + sin(t * 6).toFloat() * 0.04f else 1f
        val old = d.alpha; if (!enabled) d.alpha = 0.5
        d.c.save(); d.c.translate(x + w / 2, y + h / 2); d.c.scale(p, p)
        d.rr(-w / 2, -h / 2 + 6, w, h, h / 2.6f, shade); d.rr(-w / 2, -h / 2, w, h, h / 2.6f, fill, C.WHITE, 4f)
        d.c.restore()
        d.textBox(label, x + w / 2, y + h / 2, w - 30, size, C.INK, 1)
        d.alpha = old
        next += Region(key, x, y, w, h, false, onTap = onTap)
    }

    private fun langButton(g: Game) {
        val x = 1100f; val y = 18f; val w = 160f; val h = 96f
        d.rr(x, y, w, h, 30f, C.a(C.WHITE, 0.9), C.GOLD, 4f)
        val vi = g.lang.code == "vi"
        d.text(g.ui(UiIds.LANG_VI), x + 44, y + h / 2, 32f, if (vi) C.RED else 0xFF9A8F86.toInt())
        d.text("|", x + 80, y + h / 2, 30f, 0xFF9A8F86.toInt())
        d.text(g.ui(UiIds.LANG_EN), x + 116, y + h / 2, 32f, if (!vi) C.RED else 0xFF9A8F86.toInt())
        next += Region("lang", x, y, w, h, false, onTap = { g.toggleLang() })
    }

    private fun roundIcon(key: String, x: Float, y: Float, r: Float, draw: () -> Unit, onTap: () -> Boolean) {
        d.circle(x, y, r, C.a(C.WHITE, 0.85), C.GOLD, 4f); draw()
        next += Region(key, x - r, y - r, 2 * r, 2 * r, false, onTap = onTap)
    }

    private fun pauseGlyph(x: Float, y: Float, r: Float) { d.rr(x - r * 0.35f, y - r * 0.4f, r * 0.24f, r * 0.8f, 4f, C.INK); d.rr(x + r * 0.11f, y - r * 0.4f, r * 0.24f, r * 0.8f, 4f, C.INK) }
    private fun speakerGlyph(x: Float, y: Float, r: Float, muted: Boolean) {
        d.poly(C.INK, x - r * 0.45f, y - r * 0.18f, x - r * 0.2f, y - r * 0.18f, x + r * 0.12f, y - r * 0.45f, x + r * 0.12f, y + r * 0.45f, x - r * 0.2f, y + r * 0.18f, x - r * 0.45f, y + r * 0.18f)
        if (muted) { val p = d.stroke(C.INK, 4f); d.c.drawLine(x + r * 0.25f, y - r * 0.22f, x + r * 0.55f, y + r * 0.22f, p); d.c.drawLine(x + r * 0.55f, y - r * 0.22f, x + r * 0.25f, y + r * 0.22f, p) }
        else { d.arc(x + r * 0.15f, y, r * 0.3f, -0.8f, 0.8f, C.INK, 4f); d.arc(x + r * 0.15f, y, r * 0.5f, -0.8f, 0.8f, C.INK, 4f) }
    }
    private fun arrowGlyph(r: Float, dir: Int) = d.poly(C.INK, dir * r * 0.45f, 0f, -dir * r * 0.25f, -r * 0.4f, -dir * r * 0.25f, r * 0.4f)
    private fun shieldGlyph(r: Float) { d.circle(0f, -4f, r * 0.55f, 0xFFD8A657.toInt(), C.GOLD_DARK, 4f); d.circle(0f, -4f, r * 0.35f, null, 0xFFB8823A.toInt(), 3f); d.circle(0f, -4f, r * 0.14f, C.GOLD, C.GOLD_DARK, 3f) }
    private fun staffGlyph(r: Float) {
        d.c.save(); d.c.rotate(-45.8f); d.rr(-6f, -r * 0.6f, 12f, r * 1.1f, 6f, 0xFF8A5A2B.toInt()); d.rr(-8f, -r * 0.66f, 16f, 16f, 6f, C.GOLD); d.c.restore()
        d.arc(0f, 0f, r * 0.5f, -2.6f, -1.2f, C.RED, 6f)
    }

    private fun pad(key: String, cx: Float, cy: Float, r0: Float, action: Action, held: Boolean, pulse: Boolean, label: String?, t: Double, icon: (Float) -> Unit) {
        val r = fit.padRadius(r0)
        val p = if (pulse) 1 + 0.08f * sin(t * 10).toFloat() else 1f
        d.c.save(); d.c.translate(cx, cy); d.c.scale(p, p)
        if (pulse) d.circle(0f, 0f, r + 14, C.a(C.GLOW, 0.55))
        d.circle(0f, 6f, r, C.a(C.INK, 0.35))
        d.circle(0f, if (held) 4f else 0f, r, if (held) C.GOLD else C.a(C.CREAM, 0.88), if (held) C.GOLD_DARK else C.GOLD, 6f)
        d.c.translate(0f, if (held) 4f else 0f)
        d.c.save(); if (label != null) d.c.translate(0f, -r * 0.14f); icon(r); d.c.restore()
        if (label != null) d.text(label, 0f, r * 0.62f, 24f, C.INK)
        d.c.restore()
        next += Region(key, cx, cy, r, r, true, pad = action)
    }

    /** Debug builds: a small "UNSIGNED Cxx" badge on a Text whose claims are not approved. */
    private fun badge(g: Game, text: Text, x: Float, y: Float) {
        if (!debug) return
        val u = ClaimGate.unsigned(g.claimStatus, text.claims)
        if (u.isEmpty()) return
        val s = "UNSIGNED " + u.joinToString(",")
        val w = d.measure(s, 18f) + 20
        d.rr(x - w / 2, y - 14, w, 28f, 10f, C.a(0xFF2A2440.toInt(), 0.85), C.GLOW, 2f)
        d.text(s, x, y, 18f, C.GLOW)
    }

    // ---- Screens ----
    private fun title(g: Game, ready: Boolean) {
        val t = g.t
        fig.background(0.0, "village", GROUND)
        d.rr(150f, 60f, 980f, 210f, 40f, C.PANEL, C.GOLD, 6f)
        d.drum(240f, 165f, 70f, C.a(C.GOLD, 0.8)); d.drum(1040f, 165f, 70f, C.a(C.GOLD, 0.8))
        d.textBox(g.ui(UiIds.TITLE), W / 2, 140f, 740f, 68f, C.GOLD, 1)
        if (debug) d.text(g.ui(UiIds.SUBTITLE_DEBUG), W / 2, 220f, 36f, C.WHITE)
        fig.hero(260f, GROUND, 1, false, false, null, t, 0.8f)
        button("start", g.ui(UiIds.START), W / 2 - 190, 330f, 380f, 130f, t, pulse = true, size = 44f, enabled = ready) { ready && g.start() }
        d.rr(150f, 520f, 980f, 150f, 24f, C.a(C.CREAM, 0.92))
        val items = listOf<Pair<(Float) -> Unit, String>>(
            { r: Float -> d.c.save(); d.c.translate(-12f, 0f); arrowGlyph(r * 0.7f, -1); d.c.translate(24f, 0f); arrowGlyph(r * 0.7f, 1); d.c.restore() } to g.ui(UiIds.MOVE),
            { r: Float -> staffGlyph(r) } to g.ui(UiIds.ATTACK), { r: Float -> shieldGlyph(r) } to g.ui(UiIds.DEFEND))
        items.forEachIndexed { i, (ic, lab) ->
            val x = 300f + i * 340
            d.c.save(); d.c.translate(x - 60, 595f); d.circle(0f, 0f, 38f, C.WHITE, C.GOLD, 4f); ic(38f); d.c.restore()
            d.text(lab, x + 20, 595f, 32f, C.INK, Paint.Align.LEFT)
        }
        langButton(g)
    }

    private fun story(g: Game, intro: Boolean) {
        val t = g.t
        d.c.drawColor(C.BG)
        d.c.save(); d.path.reset(); d.path.addRoundRect(240f, 110f, 1040f, 470f, 30f, 30f, android.graphics.Path.Direction.CW); d.c.clipPath(d.path)
        d.c.save(); d.c.translate(0f, 0f); fig.background(if (intro) 0.0 else 5200.0, if (intro) "village" else "river", GROUND); d.c.restore()
        if (!intro) d.rr(240f, 110f, 800f, 360f, 0f, C.a(0xFFFF965A.toInt(), 0.3))
        fig.hero(if (intro) 560f else 640f, GROUND, 1, false, false, null, t, 0.9f)
        d.c.restore()
        d.rr(240f, 110f, 800f, 360f, 30f, null, C.GOLD, 8f)
        val lines = if (intro) g.bundle.mission.intro else g.bundle.mission.ending.lines
        val line = lines[g.line.coerceIn(0, lines.size - 1)]
        d.textBox(line.get(g.lang), W / 2, 530f, 1000f, 38f, C.WHITE, 2)
        badge(g, line, 1010f, 132f) // debug badge in the picture's corner, never over the text (QC r1)
        button("next", g.ui(UiIds.NEXT), W / 2 - 150, 590f, 300f, 110f, t, pulse = true) { g.next() }
        skipButton(g)
        skipWarning(g)
    }

    private fun play(g: Game) {
        val r = g.run; val h = r.hero; val t = r.t; val cam = r.cam.toFloat()
        val beat = r.currentBeat
        val ground = r.ground.toFloat()
        fig.background(r.cam, beat.theme, ground)
        d.c.save(); d.c.translate(-cam, 0f)
        if (r.beatType == BeatType.REACH && (r.phase == Phase.PLAY || r.phase == Phase.END)) fig.icon("flag", r.goalX.toFloat(), ground - 120, 150f)
        for (dm in r.dummies) fig.dummy(dm.x.toFloat(), ground, dm.down, dm.t)
        for (w in r.dropped) fig.dropped(w, ground)
        r.partner?.let { fig.partner(it, ground, t) }
        for (e in r.enemies) fig.enemy(e, ground, t)
        if (!(h.hurt > 0 && (t * 20).toInt() % 2 == 1)) fig.hero(h.x.toFloat(), ground, h.face, h.walk, h.def, if (h.atk >= 0) h.atk else null, t)
        if (r.bannerRaised && r.beatType == BeatType.TRAINING) fig.icon("flag", h.x.toFloat() - h.face * 60f, ground - 250, 110f)
        if (r.beatType == BeatType.HOLD && r.phase != Phase.CARD) holdMeter(h.x.toFloat() + h.face * 130f, ground - 200, r.heldTotal / r.holdSeconds(r.beat)) // beside the hero, clear of the goal bar
        for (p in r.parts) d.star(p.x.toFloat(), p.y.toFloat(), p.r.toFloat(), p.color.toInt(), C.GOLD_DARK, p.rot.toFloat())
        for (p in r.pops) { val old = d.alpha; d.alpha = min(1.0, p.life * 2); d.text(g.ui(p.textId), p.x.toFloat(), p.y.toFloat(), 40f, p.color.toInt()); d.alpha = old }
        r.stallTargetX?.let { fig.arrowDown(it.toFloat(), ground - 330, t) }
        d.c.restore()
        if (r.phase == Phase.WALK && r.beat > 0) {
            val p = (sin(t * 6) * 10).toFloat()
            d.c.save(); d.c.translate(1060 + p, 300f)
            d.poly(C.GOLD, -60f, -22f, 10f, -22f, 10f, -50f, 64f, 0f, 10f, 50f, 10f, 22f, -60f, 22f); d.c.drawPath(d.path, d.stroke(C.WHITE, 5f))
            d.c.restore(); d.text(g.ui(UiIds.GO), 1060f, 380f, 32f, C.INK)
        }
        // HUD: pause and sound always; beat medallions; the goal and the banner as text layers (never in art).
        roundIcon("pause", 66f, 66f, 48f, { pauseGlyph(66f, 66f, 48f) }) { g.pause() }
        roundIcon("mute", 176f, 66f, 48f, { speakerGlyph(176f, 66f, 48f, g.muted) }) { g.toggleMute() }
        val n = r.beats.size
        for (i in 0 until n) {
            val x = W / 2 - (n - 1) * 45 + i * 90
            val done = i < r.beat || (i == r.beat && (r.phase == Phase.CAPTION || r.phase == Phase.END))
            d.circle(x, 60f, 30f, if (done) C.GOLD else C.a(C.WHITE, 0.75), C.GOLD_DARK, 4f); d.drum(x, 60f, 22f, if (done) C.INK else C.a(C.INK, 0.35))
        }
        if (r.phase == Phase.PLAY || r.phase == Phase.END) { // the goal under the medallions; its badge clear of the "!" bubble
            d.rr(W / 2 - 300, 98f, 600f, 44f, 18f, C.a(C.CREAM, 0.85))
            d.textBox(beat.goal.get(g.lang), W / 2, 120f, 580f, 24f, C.INK, 1); badge(g, beat.goal, W / 2 + 390, 120f)
            if (beat.usesBanner) g.bundle.mission.banner?.let { b ->
                d.rr(W / 2 - 450, 150f, 900f, 44f, 18f, C.a(C.RED, 0.9)); d.textBox(b.get(g.lang), W / 2, 172f, 880f, 24f, C.GOLD, 1); badge(g, b, W / 2 + 540, 172f)
            }
        }
        val vis = r.visibleButtons()
        if (r.phase != Phase.CAPTION && r.phase != Phase.CARD) {
            // Only the beat's own pads are drawn (mission-flow rule 4): hidden, not greyed.
            if ("move" in vis) {
                pad("left", 140f, 610f, 80f, Action.LEFT, false, false, null, t) { rr -> arrowGlyph(rr, -1) }
                pad("right", 330f, 610f, 80f, Action.RIGHT, false, r.pulseRight, null, t) { rr -> arrowGlyph(rr, 1) }
            }
            if ("defend" in vis) pad("defend", 950f, 625f, 80f, Action.DEFEND, h.def, r.pulseDefend, g.ui(UiIds.DEFEND), t) { rr -> shieldGlyph(rr) }
            if ("attack" in vis) pad("attack", 1150f, 590f, 92f, Action.ATTACK, h.atk >= 0, r.pulseAttack, g.ui(UiIds.ATTACK), t) { rr -> staffGlyph(rr) }
            val special = if (r.beatType == BeatType.HOLD) Pair(1150f, 590f) else Pair(1150f, 400f) // alone, it takes attack's place
            if ("special" in vis) pad("special", special.first, special.second, 80f, Action.SPECIAL, false, r.pulseSpecial, g.uiOrNull(UiIds.SPECIAL), t) { rr -> bannerGlyph(rr) }
            when (r.hand) {
                HandHint.MOVE -> fig.hand(330f, 540f, t)
                HandHint.ATTACK -> fig.hand(1150f, 510f, t)
                HandHint.DEFEND -> fig.hand(950f, 555f, t)
                HandHint.SPECIAL_TAP, HandHint.SPECIAL_HOLD -> fig.hand(special.first, special.second - 70, if (r.hand == HandHint.SPECIAL_HOLD) 0.0 else t)
                HandHint.NONE -> Unit
            }
        } else if (r.phase == Phase.CAPTION) {
            storyPanel("${g.ui(UiIds.BEAT)} ${r.beat + 1}", beat.scene[r.captionLine.coerceIn(0, beat.scene.size - 1)], g, t)
        } else {
            val boxes = r.cardBoxes()
            storyPanel(beat.title.get(g.lang), boxes[r.cardLine.coerceIn(0, boxes.size - 1)], g, t, badgeFor = beat.title)
        }
        skipWarning(g)
    }

    /** A caption or beat card: header, one sentence, Next and Skip (D-07). */
    private fun storyPanel(head: String, line: Text, g: Game, t: Double, badgeFor: Text? = null) {
        d.rr(160f, 140f, 960f, 300f, 36f, C.PANEL, C.GOLD, 6f)
        d.drum(230f, 210f, 44f, C.a(C.GOLD, 0.8)); d.drum(1050f, 210f, 44f, C.a(C.GOLD, 0.8))
        d.textBox(head, W / 2, 190f, 700f, 30f, C.GOLD, 1); badgeFor?.let { badge(g, it, W / 2, 222f) }
        d.textBox(line.get(g.lang), W / 2, 295f, 760f, 40f, C.WHITE, 2); badge(g, line, W / 2, 410f)
        button("next", g.ui(UiIds.NEXT), W / 2 - 150, 470f, 300f, 110f, t, pulse = true) { g.next() }
        skipButton(g)
    }

    private fun skipButton(g: Game) {
        if (!g.onStoryBox) return
        val label = g.uiOrNull(UiIds.SKIP) ?: return
        button("skip", label, 1040f, 610f, 210f, 84f, g.t, fill = C.a(C.CREAM, 0.85), shade = 0xFFC8B89A.toInt(), size = 28f) { g.skip() }
    }

    /** D-07: one kind warning per run; fires on release like every menu. */
    private fun skipWarning(g: Game) {
        if (!g.skipWarning) return
        next = ArrayList()
        d.rr(0f, 0f, W, H, 0f, C.a(0xFF2A2440.toInt(), 0.75))
        d.rr(200f, 150f, 880f, 420f, 36f, C.CREAM, C.GOLD, 6f)
        medal(W / 2, 250f, 56f, false)
        d.textBox(g.ui(UiIds.SKIP_WARNING), W / 2, 365f, 780f, 34f, C.INK, 3)
        button("keep", g.ui(UiIds.KEEP_READING), 260f, 450f, 360f, 96f, g.t, pulse = true) { g.keepReading() }
        button("skipok", g.ui(UiIds.SKIP_CONFIRM), 660f, 450f, 360f, 96f, g.t, fill = C.a(C.WHITE, 0.9), shade = 0xFFC8B89A.toInt()) { g.confirmSkip() }
    }

    /** A drawn medal: a gold disc with the drum motif (earned) or an outline (not yet). */
    private fun medal(x: Float, y: Float, r: Float, earned: Boolean) {
        if (earned) { d.poly(C.RED, x - r * 0.5f, y - r * 1.6f, x - r * 0.1f, y - r * 1.6f, x + r * 0.15f, y - r * 0.7f, x - r * 0.25f, y - r * 0.7f)
            d.poly(C.RED, x + r * 0.5f, y - r * 1.6f, x + r * 0.1f, y - r * 1.6f, x - r * 0.15f, y - r * 0.7f, x + r * 0.25f, y - r * 0.7f)
            d.circle(x, y, r, C.GOLD, C.GOLD_DARK, 5f); d.drum(x, y, r * 0.8f, C.GOLD_DARK) }
        else { d.circle(x, y, r, null, C.a(C.INK, 0.5), 5f); d.drum(x, y, r * 0.8f, C.a(C.INK, 0.25)) }
    }

    private fun holdMeter(x: Float, y: Float, frac: Double) {
        d.circle(x, y, 48f, C.a(C.WHITE, 0.85), C.GOLD, 4f)
        d.arc(x, y, 40f, (-Math.PI / 2).toFloat(), (-Math.PI / 2 + 2 * Math.PI * frac).toFloat(), C.GLOW, 12f)
        fig.icon("orange", x, y, 46f * (1f - 0.35f * frac.toFloat()))
    }

    private fun bannerGlyph(r: Float) { d.rr(-r * 0.32f, -r * 0.5f, 7f, r * 1.0f, 3f, 0xFF6A4A2A.toInt()); d.poly(C.RED, -r * 0.28f, -r * 0.5f, r * 0.42f, -r * 0.38f, r * 0.42f, r * 0.02f, -r * 0.28f, -r * 0.06f) }

    private fun pause(g: Game) {
        if (g.pausedFrom == Screen.QUIZ) quiz(g) else play(g)
        next = ArrayList()
        d.rr(0f, 0f, W, H, 0f, C.a(0xFF2A2440.toInt(), 0.7))
        d.text(g.ui(UiIds.PAUSED), W / 2, 200f, 64f, C.WHITE)
        button("resume", g.ui(UiIds.RESUME), W / 2 - 200, 290f, 400f, 120f, g.t, pulse = true) { g.resume() }
        button("home", g.ui(UiIds.HOME), W / 2 - 200, 450f, 400f, 110f, g.t, fill = C.CREAM, shade = 0xFFC8B89A.toInt()) { g.home() }
        langButton(g)
    }

    /** Quiz pictures: real ids come from assets.json; debug sample ids "pic.icon.X" draw icon X. */
    private val dst = android.graphics.RectF()
    private val bmpPaint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG)
    private fun picture(id: String, x: Float, y: Float, s: Float) {
        val b = pictures(id)
        if (b == null) { fig.icon(id.removePrefix("pic.icon."), x, y, s); return }
        val box = s * 1.9f; val sc = min(box / b.width, box / b.height)
        dst.set(x - b.width * sc / 2, y - b.height * sc / 2, x + b.width * sc / 2, y + b.height * sc / 2)
        bmpPaint.alpha = (d.alpha * 255).toInt(); d.c.drawBitmap(b, null, dst, bmpPaint)
    }

    private fun quiz(g: Game) {
        val q = g.quiz ?: return
        val t = g.t
        d.c.drawColor(C.BG)
        d.drum(120f, 120f, 70f, C.a(C.GOLD, 0.25)); d.drum(1160f, 640f, 90f, C.a(C.GOLD, 0.18))
        val n = q.questions.size
        for (i in 0 until n) d.circle(W / 2 - (n - 1) * 30 + i * 60, 50f, 16f, if (i < q.index || (i == q.index && q.rightShown >= 0)) C.GOLD else C.a(C.WHITE, 0.3), C.GOLD_DARK, 3f)
        d.text("${g.ui(UiIds.QUESTION)} ${min(q.index + 1, n)}/$n", 120f, 50f, 28f, C.GOLD, Paint.Align.LEFT)
        val cur = q.current
        d.textBox(cur.prompt.get(g.lang), W / 2, 140f, 980f, 40f, C.WHITE, 2); badge(g, cur.prompt, W / 2, 222f)
        val cw = 360f; val ch = 370f; val gap = 40f; val x0 = (W - 3 * cw - 2 * gap) / 2; val y0 = 248f
        q.order.forEachIndexed { slot, j ->
            val a = cur.choices[j]
            var x = x0 + slot * (cw + gap)
            if (q.lastWrong == j && q.shakeT > 0) x += (sin(q.shakeT * 60) * 14 * q.shakeT * 2).toFloat()
            val wrong = j in q.wrongPicked; val ok = q.rightShown == j
            d.rr(x, y0 + 8, cw, ch, 30f, C.a(0, 0.3))
            d.rr(x, y0, cw, ch, 30f, if (ok) 0xFFD9F2D0.toInt() else if (wrong) C.TRY_AGAIN else C.CREAM, if (ok) C.RIGHT else if (wrong) 0xFF7E7299.toInt() else C.GOLD, if (ok) 10f else 5f)
            val old = d.alpha; if (wrong) d.alpha = 0.5
            picture(a.pictureId, x + cw / 2, y0 + 140, 110f)
            d.alpha = old
            if (wrong) { d.arc(x + cw - 44, y0 + 44, 18f, -0.3f, 4.4f, C.WHITE, 6f); d.poly(C.WHITE, x + cw - 26, y0 + 30, x + cw - 18, y0 + 46, x + cw - 34, y0 + 46) }
            if (ok) { val p = d.stroke(C.RIGHT, 10f); d.c.drawLine(x + cw - 64, y0 + 44, x + cw - 50, y0 + 60, p); d.c.drawLine(x + cw - 50, y0 + 60, x + cw - 24, y0 + 28, p) }
            d.textBox(a.text.get(g.lang), x + cw / 2, y0 + 300, cw - 40, 32f, if (wrong) 0xFF4A4060.toInt() else C.INK, 2)
            badge(g, a.text, x + cw / 2, y0 + 358)
            if (ok) for (kk in 0 until 5) { val ang = t * 3 + kk * 1.26; d.star(x + cw / 2 + cos(ang).toFloat() * 150, y0 + 140 + sin(ang).toFloat() * 110, 16f, C.GLOW, C.GOLD_DARK, ang.toFloat()) }
            next += Region("card$slot", x, y0, cw, ch, false, onTap = { g.answer(j) != com.galaxyandsun.daidatanhhung.core.PickResult.IGNORED })
        }
        if (q.rightShown >= 0) {
            d.rr(40f, 636f, 840f, 72f, 24f, C.a(C.RIGHT, 0.9))
            d.textBox("${g.ui(UiIds.CORRECT)} ${cur.why.get(g.lang)}", 460f, 672f, 800f, 26f, C.WHITE, 2); badge(g, cur.why, 460f, 620f)
            if (q.canAdvance) button("next", g.ui(UiIds.NEXT), 940f, 630f, 280f, 84f, t, pulse = true) { g.next() }
        } else if (q.shakeT > 0 || q.wrongPicked.isNotEmpty()) d.text(g.ui(UiIds.RETRY), W / 2, 670f, 36f, 0xFFE6E0F5.toInt())
        roundIcon("pause", 1214f, 66f, 48f, { pauseGlyph(1214f, 66f, 48f) }) { g.pause() }
    }

    private fun results(g: Game) {
        val t = g.t
        d.c.drawColor(C.BG)
        d.drum(W / 2, 300f, 260f, C.a(C.GOLD, 0.15))
        d.text(g.ui(UiIds.DONE), W / 2, 110f, 64f, C.GOLD)
        for (i in 0 until 3) {
            val appear = ((t - 0.3 - i * 0.35) / 0.3).coerceIn(0.0, 1.0).toFloat(); val got = i < g.stars
            val x = W / 2 + (i - 1) * 200; val y = if (i == 1) 270f else 300f
            val r = (if (i == 1) 90f else 75f) * (if (got) 0.6f + 0.4f * appear else 1f)
            if (got && appear > 0) d.star(x, y, r, C.GOLD, C.WHITE) else { d.star(x, y, r, C.a(C.WHITE, 0.08), C.a(C.WHITE, 0.55)) }
        }
        medal(1080f, 300f, 60f, g.medalThisRun || g.medalEarned)
        // Gold if earned in this or any run; the "earned" line only in the run that earns it (progression GDD rule 10).
        val medalLine = if (g.medalThisRun) UiIds.MEDAL_EARNED else if (!g.medalEarned) UiIds.MEDAL_MISSING else null
        medalLine?.let { d.textBox(g.ui(it), 1080f, 400f, 300f, 22f, C.a(C.WHITE, 0.85), 2) }
        if (g.newlyOpen == null) d.text(g.ui(UiIds.MORE_HEROES), W / 2, 450f, 30f, C.a(C.WHITE, 0.8), semiBold = true)
        button("next", g.ui(UiIds.NEXT), W / 2 - 150, 520f, 300f, 110f, t, pulse = true) { g.next() }
    }

    private fun medallion(x: Float, y: Float, r: Float, lit: Boolean) {
        d.circle(x, y, r + 10, if (lit) C.GOLD else 0xFF5A5370.toInt(), if (lit) C.WHITE else 0xFF7A7390.toInt(), 6f)
        d.circle(x, y, r, if (lit) C.CREAM else 0xFF3E3856.toInt()); d.drum(x, y, r * 0.95f, if (lit) C.a(C.GOLD_DARK, 0.5) else C.a(C.WHITE, 0.12))
    }

    private fun unlock(g: Game) {
        val t = g.t; val open = ((t - 0.6) / 0.8).coerceIn(0.0, 1.0).toFloat()
        d.c.drawColor(C.BG)
        d.c.drawLine(300f, 300f, 300 + 680 * min(1f, (t / 0.6).toFloat()), 300f, d.stroke(C.GOLD, 10f))
        medallion(300f, 300f, 110f, true)
        d.c.save(); d.path.reset(); d.path.addCircle(300f, 300f, 110f, android.graphics.Path.Direction.CW); d.c.clipPath(d.path)
        fig.hero(300f, 470f, 1, false, false, null, t, 0.75f); d.c.restore()
        val name = g.bundle.mission.hero.name
        d.textBox(name.get(g.lang), 300f, 450f, 360f, 30f, C.WHITE, 1); badge(g, name, 300f, 490f)
        medallion(980f, 300f, 110f, open >= 1)
        d.c.save(); d.c.translate(980f, 300f); val old = d.alpha; d.alpha = 1.0 - open * 0.85
        d.arc(0f, -30 - open * 40, 34f, Math.PI.toFloat(), (2 * Math.PI).toFloat(), C.STEEL, 14f); d.rr(-50f, -30f, 100f, 80f, 14f, C.STEEL); d.circle(0f, 4f, 10f, 0xFF3E3856.toInt())
        d.alpha = old; d.c.restore()
        if (open >= 1) { for (kk in 0 until 6) { val a = t * 2 + kk * 1.05; d.star(980 + cos(a).toFloat() * 150, 300 + sin(a).toFloat() * 120, 18f, C.GLOW, C.GOLD_DARK, a.toFloat()) }; d.text("?", 980f, 300f, 110f, C.GOLD_DARK) }
        d.text(g.ui(UiIds.UNLOCKED), W / 2, 100f, 52f, C.GOLD)
        d.text(g.ui(UiIds.MAP_STUB), W / 2, 530f, 26f, C.a(C.WHITE, 0.6), semiBold = true)
        button("replay", g.ui(UiIds.REPLAY), 260f, 580f, 340f, 110f, t, fill = C.CREAM, shade = 0xFFC8B89A.toInt()) { g.replay() }
        button("tomap", g.ui(UiIds.TO_MAP), 680f, 580f, 340f, 110f, t, pulse = true) { g.home() } // slice: "the map" is the title screen
    }

    private fun rotate(canvas: Canvas, g: Game) {
        canvas.drawColor(C.BG)
        val cx = canvas.width / 2f; val cy = canvas.height / 2f; val s = min(canvas.width, canvas.height) / 360f
        canvas.save(); canvas.translate(cx, cy); canvas.scale(s, s)
        d.rr(-22f, -110f, 44f, 96f, 10f, C.GOLD, C.WHITE, 5f); d.rr(-15f, -98f, 30f, 66f, 4f, 0xFFBFE6F0.toInt())
        d.text(g.ui(UiIds.TURN), 0f, 40f, 22f, C.WHITE)
        canvas.restore()
    }

    companion object {
        const val W = 1280f
        const val H = 720f
        const val GROUND = 470f
    }
}
