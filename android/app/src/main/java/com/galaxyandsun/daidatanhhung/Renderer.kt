package com.galaxyandsun.daidatanhhung

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import com.galaxyandsun.daidatanhhung.core.CueLayout
import com.galaxyandsun.daidatanhhung.core.StoryLayout
import com.galaxyandsun.daidatanhhung.core.QuizLayout
import com.galaxyandsun.daidatanhhung.core.SkyContrast
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
class Renderer(bold: Typeface, semi: Typeface, private val debug: Boolean, private val pictures: (String) -> android.graphics.Bitmap? = { null },
               skyBands: Map<String, Pair<Int, Int>> = emptyMap()) {
    private val d = Draw(bold, semi)
    private val fig = Figures(d).also { it.skyBands = skyBands }
    private var regions = ArrayList<Region>()
    private var next = ArrayList<Region>()
    @Volatile private var k = 1f; @Volatile private var ox = 0f; @Volatile private var oy = 0f
    private var lastGame: Game? = null

    fun layout(w: Float, h: Float, safe: IntArray, density: Float, padMinDp: Float) {
        val f = ScreenFit.of(w, h, safe, density, padMinDp)
        k = f.k; ox = f.ox; oy = f.oy; fit = f
        safeBottom = (h - safe[3] - oy) / k // world px; ≥ 720 when the world is width-limited
    }
    private var fit = ScreenFit(1f, 0f, 0f, 0f)
    /** The safe rect's bottom in world px (title.md small-k rule). */
    private var safeBottom = 720f

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
                       fill: Int = C.GOLD, shade: Int = C.GOLD_DARK, size: Float = 34f, enabled: Boolean = true, labelColor: Int = C.INK, onTap: () -> Boolean) {
        val p = if (pulse && enabled) 1 + sin(t * 6).toFloat() * 0.04f else 1f
        val old = d.alpha; if (!enabled) d.alpha = 0.5
        d.c.save(); d.c.translate(x + w / 2, y + h / 2); d.c.scale(p, p)
        d.rr(-w / 2, -h / 2 + 6, w, h, h / 2.6f, shade); d.rr(-w / 2, -h / 2, w, h, h / 2.6f, fill, C.WHITE, 4f)
        d.c.restore()
        d.textBox(label, x + w / 2, y + h / 2, w - 30, size, labelColor, 1)
        d.alpha = old
        next += Region(key, x, y, w, h, false, onTap = onTap)
    }

    /** title.md: the VI|EN chip, top-right, height ≥ pad_min, width 1.6 × height (ref ≈ x 1043–1262, y 18–155). */
    private fun chipBox(): Pair<Float, Float> { val h = max(96f, fit.padMinWorld); return h * 1.6f to h }

    private fun langButton(g: Game, enabled: Boolean = true) {
        val (w, h) = chipBox(); val x = 1262f - w; val y = 18f
        val old = d.alpha; if (!enabled) d.alpha = 0.5
        d.rr(x, y, w, h, 30f, C.a(C.WHITE, 0.9), C.GOLD, 4f)
        val vi = g.lang.code == "vi"; val fs = 32f * h / 96f
        d.text(g.ui(UiIds.LANG_VI), x + w * 0.27f, y + h / 2, fs, if (vi) C.RED else 0xFF9A8F86.toInt())
        d.text("|", x + w / 2, y + h / 2, fs * 0.95f, 0xFF9A8F86.toInt())
        d.text(g.ui(UiIds.LANG_EN), x + w * 0.73f, y + h / 2, fs, if (!vi) C.RED else 0xFF9A8F86.toInt())
        d.alpha = old
        next += Region("lang", x, y, w, h, false, onTap = { enabled && g.toggleLang() })
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
        if (label != null) d.text(label, 0f, r * 0.62f, 28f, C.INK) // labels next to an icon ≥ 28 (Language GDD rule 6)
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
    /** title.md (D-27: A): the title row, the hero card, Start, the map stub and (debug) the test-build line. */
    private fun title(g: Game, ready: Boolean) {
        val t = g.t
        fig.background(0.0, "village", GROUND)
        // Title row x 260–1020 (its right edge ≤ the chip's left − 8), y 18–155: a 1-line 56 px heading, no emblems.
        val rowR = min(1020f, 1262f - chipBox().first - 8f)
        d.rr(260f, 34f, rowR - 260f, 106f, 30f, C.a(C.PANEL, 0.92), C.GOLD, 4f)
        d.textBox(g.ui(UiIds.TITLE), (260f + rowR) / 2, 87f, rowR - 300f, 56f, C.GOLD, 1)
        heroCard(g, 260f, 175f)
        // Start: centred x 430–850, top 375, pad_min tall (button field, 34 px); the lines under it, or beside it when
        // the column would run past the safe rect's bottom (small k), computed from the real safe_bottom.
        val sh = max(110f, fit.padMinWorld)
        button("start", g.ui(UiIds.START), 430f, 375f, 420f, sh, t, pulse = true, size = 34f, enabled = ready) { ready && g.start() }
        val stacked = 375f + sh + 16f + 38f + (if (debug) 8f + 34f else 0f) <= safeBottom
        val (lx, ly) = if (stacked) 640f to 375f + sh + 16f else 1060f to 375f
        d.rr(lx - 190, ly, 380f, 38f, 14f, C.a(C.CREAM, 0.92))
        d.textBox(g.ui(UiIds.MAP_STUB), lx, ly + 19, 360f, 28f, C.INK, 1, semiBold = true) // label 28
        if (debug) { d.rr(lx - 190, ly + 46, 380f, 34f, 14f, C.a(C.PANEL, 0.85)); d.textBox(g.ui(UiIds.SUBTITLE_DEBUG), lx, ly + 63, 360f, 28f, C.WHITE, 1) }
        corner(g, pause = false, enabled = ready) // sound top-left, no pause; disabled until the preload ends (W19)
        langButton(g, enabled = ready)
    }

    /** title.md §5.5: portrait, name, best stars and medal; display only (no tap, no tone). */
    private fun heroCard(g: Game, x: Float, y: Float) {
        d.rr(x, y, 760f, 180f, 28f, 0xFFFFF6E3.toInt(), C.INK, 4f)
        d.rr(x + 6, y + 6, 748f, 168f, 24f, null, C.a(C.GOLD_DARK, 0.7), 3f) // the drum-ring border (one motif)
        val px = x + 20 + 70; val py = y + 90
        d.circle(px, py, 76f, C.CREAM, C.GOLD_DARK, 6f); d.drum(px, py, 72f, C.a(C.GOLD_DARK, 0.25))
        if (!portrait("pic.portrait_${g.heroId}_hero_determined", px, py, 66f)) {
            d.c.save(); d.path.reset(); d.path.addCircle(px, py, 70f, android.graphics.Path.Direction.CW); d.c.clipPath(d.path)
            fig.hero(px, py + 150f, 1, false, false, null, g.t, 0.75f); d.c.restore()
        }
        val name = g.bundle.mission.hero.name
        d.textBox(name.get(g.lang), x + 180 + 280, y + 52, 560f, 44f, C.INK, 1); badge(g, name, x + 700, y + 10) // fit.hero_name 560 @ 44
        val best = g.bestStars
        for (i in 0 until 3) {
            val sx = x + 210 + i * 62f; val sy = y + 124
            if (i < best) d.star(sx, sy, 24f, C.GOLD, C.GOLD_DARK) else d.star(sx, sy, 24f, C.a(C.WHITE, 0.4), C.a(C.INK, 0.5))
        }
        medal(x + 210 + 3 * 62f + 28, y + 128, 28f, g.medalEarned)
    }

    private fun story(g: Game, intro: Boolean) {
        val t = g.t
        // story-screens.md §5.2: the picture is full-bleed (no frame corner under pause/sound)
        if (intro) fig.background(0.0, "village", GROUND)
        else if (!endingStill(g)) fig.background(5200.0, "river", GROUND) // r8d: a missing ending still → the scene only, no face
        if (intro) storyStill(g, card = false, labelTop = null) // the ending keeps its own still (ASSET-016): no placeholder
        val lines = if (intro) g.bundle.mission.intro else g.bundle.mission.ending.lines
        val line = lines[g.line.coerceIn(0, lines.size - 1)]
        // the text panel: box 1000 + 2 × 32, H 167, bottom-anchored on Tiếp's top − 8 (fit.intro/ending 1000 @ 38, weight 600)
        val bottom = rowTop() - 8f; val top = max(bottom - 167f, cornerClear(g))
        d.rr(108f, top, 1064f, bottom - top, 30f, C.a(C.PANEL, 0.94), C.GOLD, 6f)
        d.textBox(line.get(g.lang), W / 2, (top + bottom) / 2, 1000f, 38f, C.WHITE, 2, semiBold = true)
        badge(g, line, 1010f, top)
        nextButton(g, t)
        skipButton(g)
        corner(g)
        skipWarning(g)
    }

    private fun play(g: Game) {
        val r = g.run; val h = r.hero; val t = r.t; val cam = r.cam.toFloat()
        val beat = r.currentBeat
        val ground = r.ground.toFloat()
        fig.background(r.cam, beat.theme, ground)
        // story-screens §5.2, dialogue §5.2 (r8, r8b): a beat card, a caption and a dialogue show the scene background only;
        // no sprite, flag, fx, pop, play hint or top stack (only the pause/sound corner). Dialogue dims the scene 30%.
        val storyPhase = r.phase == Phase.CARD || r.phase == Phase.CAPTION || r.phase == Phase.DIALOGUE
        if (storyPhase) { storyScreen(g, r); return }
        d.c.save(); d.c.translate(-cam, 0f)
        val bannerBeat = beat.usesBanner
        if (r.beatType == BeatType.REACH && (r.phase == Phase.PLAY || r.phase == Phase.END)) // r9 (a): wholly below the bar on banner beats
            CueLayout.goalFlag(ground.toDouble(), bannerBeat).let { f -> fig.icon("flag", r.goalX.toFloat(), f.y.toFloat(), f.size.toFloat()) }
        for (dm in r.dummies) fig.dummy(dm.x.toFloat(), ground, dm.down, dm.t)
        for (w in r.dropped) fig.dropped(w, ground)
        r.partner?.let { fig.partner(it, ground, t) }
        for (e in r.enemies) fig.enemy(e, ground, t)
        // Combat AC13 (QC r5): the sim pushes the hero back in the strike's first step, so the drawing holds contact for
        // 0.05 s (3 frames) and slides the push in behind the sim. Render-only: positions, timing and the trace are untouched.
        val contact = 0.05
        val hurtT = g.tuning["hurt_time"]
        val striker = (r.enemies + listOfNotNull(r.partner)).firstOrNull { it.state == com.galaxyandsun.daidatanhhung.core.EnemyState.STRIKE && it.t < contact }
        val heroX = if (striker != null && h.hurt > hurtT - contact - 1e-9)
            h.x + kotlin.math.sign(striker.x - h.x) * g.tuning["hero_pushback"] * (1 - striker.t / contact) else h.x
        val blinkOff = h.hurt > 0 && h.hurt < hurtT - contact && (t * 20).toInt() % 2 == 1 // no blink during contact
        if (!blinkOff) fig.hero(heroX.toFloat(), ground, h.face, h.walk, h.def, if (h.atk >= 0) h.atk else null, t,
            Figures.HERO_S, reach = (g.tuning["attack_range"] - 18 * Figures.HERO_S).toFloat()) // body 180 tall, swing arc = attack_range (AC13)
        if (r.bannerRaised && r.beatType == BeatType.TRAINING)
            CueLayout.raisedBanner(ground.toDouble(), bannerBeat).let { f -> fig.icon("flag", h.x.toFloat() - h.face * 60f, f.y.toFloat(), f.size.toFloat()) }
        if (r.beatType == BeatType.HOLD && (r.phase == Phase.PLAY || r.phase == Phase.END)) holdMeter(h.x.toFloat() + h.face * 130f, ground - 200, r.heldTotal / r.holdSeconds(r.beat)) // beside the hero, clear of the goal bar
        for (p in r.parts) d.star(p.x.toFloat(), p.y.toFloat(), p.r.toFloat(), p.color.toInt(), C.GOLD_DARK, p.rot.toFloat())
        if (r.cheerT >= 0 && r.t - r.cheerT < 0.6) { val k = ((r.t - r.cheerT) / 0.6).toFloat() // the cheer's stars, drawn here (no RNG)
            for (i in 0 until 10) { val a = i * 0.628; d.star(h.x.toFloat() + cos(a).toFloat() * 160 * k, ground - 260 + sin(a).toFloat() * 120 * k, 14f, C.GLOW, C.GOLD_DARK, a.toFloat()) } }
        d.c.restore()
        if (r.phase == Phase.WALK && r.beat > 0) {
            val p = (sin(t * 6) * 10).toFloat()
            d.c.save(); d.c.translate(1060 + p, 300f)
            d.poly(C.GOLD, -60f, -22f, 10f, -22f, 10f, -50f, 64f, 0f, 10f, 50f, 10f, 22f, -60f, 22f); d.c.drawPath(d.path, d.stroke(C.WHITE, 5f))
            d.c.restore(); d.text(g.ui(UiIds.GO), 1060f, 380f, 32f, C.INK)
        }
        // HUD: pause and sound always; beat medallions; the goal and the banner as text layers (never in art).
        corner(g)
        val n = r.beats.size
        val st = stack(g); val sx = st.cx
        for (i in 0 until n) { // hud.md §3.3: the top stack is centred in the free band right of pause/sound
            val x = sx - (n - 1) * 45 + i * 90
            val done = i < r.beat || (i == r.beat && (r.phase == Phase.CAPTION || r.phase == Phase.END))
            d.circle(x, 60f, 30f, if (done) C.GOLD else C.a(C.WHITE, 0.75), C.GOLD_DARK, 4f); d.drum(x, 60f, 22f, if (done) C.INK else C.a(C.INK, 0.35))
        }
        if (r.phase == Phase.PLAY || r.phase == Phase.END) { // the goal under the medallions; its badge clear of the "!" bubble
            // goal plate: 920 × 56 at 96–152, text box 880 @ 37 px, 1 line (rules.json fit.goal; hud.md §3.3), on every beat
            d.rr(st.left, 96f, st.width, 56f, 22f, C.a(C.CREAM, 0.88))
            beat.goal?.let { gl -> d.textBox(gl.get(g.lang), sx, 124f, st.box, 37f, C.INK, 1); badge(g, gl, st.left + st.width - 80, 96f) }
            if (beat.usesBanner) g.bundle.mission.banner?.let { b ->
                // banner motto bar: 920 × 112 at 156–268, fixed for 1 or 2 lines (fit.banner 880 @ 37); never over a body
                // the gold text carries an ink outline (QC r5: gold on vermilion alone is 2.6:1)
                d.rr(st.left, 156f, st.width, 112f, 18f, C.a(C.RED, 0.92)); d.textBox(b.get(g.lang), sx, 212f, st.box, 37f, C.GOLD, 2, outline = OUTLINE_INK, outlineW = 7f); badge(g, b, st.left + st.width - 80, 156f)
            }
        }
        // z-order (hud.md §3.3): bar → pops → hints and the telegraph "!" → HUD buttons
        // Pops ("Ối!", "Đỡ được!") beside the fighter's head at head height, away from the other fighter; never above the head.
        for (p in r.pops) {
            val px = p.x.toFloat() - cam
            val other = (r.enemies.map { it.x } + listOfNotNull(r.partner?.x)).minByOrNull { kotlin.math.abs(it - p.x) }
            val side = if (other != null && other > p.x) -1 else 1
            val rise = min(20f, (ground - 300f - p.y.toFloat()).coerceAtLeast(0f))
            val old = d.alpha; d.alpha = min(1.0, p.life * 2)
            // QC r5 / spec follow-up: an outline under the colour, ink on light skies and cream on the dark camp sky
            val ol = fig.skyBand(beat.theme).let { (top, bottom) -> SkyContrast.popOutline(top, bottom) } // r9: from the sky, as iOS
            d.textOutlined(g.ui(p.textId), (px + side * 120).coerceIn(90f, W - 90), ground - 150 - rise, 40f, p.color.toInt(), ol, 8f); d.alpha = old
        }
        cues(g, r, cam, ground, t)
        val vis = r.visibleButtons()
        if (r.phase != Phase.CAPTION && r.phase != Phase.CARD && r.phase != Phase.DIALOGUE) {
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
                // QC r2 B3 / r3 B3b: with the flag pad above attack, the hand comes from the upper left, its fingertip on
                // the attack pad's own edge (its real radius, grown to pad_min), clear of Defend (870–1030) and the flag.
                HandHint.ATTACK -> if ("special" in vis) { val ra = fit.padRadius(92f); fig.hand(1150f - ra * 0.82f, 590f - ra * 0.57f, t, -55f) } else fig.hand(1150f, 510f, t) // fingertip on the pad edge at 145°
                HandHint.DEFEND -> fig.hand(950f, 555f, t)
                HandHint.SPECIAL_TAP, HandHint.SPECIAL_HOLD -> fig.hand(special.first, special.second - 70, if (r.hand == HandHint.SPECIAL_HOLD) 0.0 else t)
                HandHint.NONE -> Unit
            }
        }
        skipWarning(g)
    }

    /** A beat card, caption or dialogue (r8): the background (drawn by play), then only the story layer. */
    private fun storyScreen(g: Game, r: com.galaxyandsun.daidatanhhung.core.MissionRun) {
        val t = r.t; val beat = r.currentBeat
        if (r.phase == Phase.DIALOGUE) d.rr(0f, 0f, W, H, 0f, C.a(0, 0.30)) // dialogue §5.2: the scene dimmed 30%, under everything else
        corner(g)
        when (r.phase) {
            Phase.DIALOGUE -> dialogue(g, r, t)
            Phase.CAPTION -> storyPanel(null, beat.scene[r.captionLine.coerceIn(0, beat.scene.size - 1)], g, t, part = r.beat + 1) // no heading (H 167)
            else -> { val boxes = r.cardBoxes()
                storyPanel(beat.title.get(g.lang), boxes[r.cardLine.coerceIn(0, boxes.size - 1)], g, t, badgeFor = beat.title, part = r.beat + 1) }
        }
        skipWarning(g)
    }

    /** Target geometry for the cues, in screen px: centre x, top, head (or mid) height and half width (hud.md §3.3). */
    /** Spec height: top ≈ 300; the half width covers the body and the held weapon's head (the leader's hammer is wide). */
    private fun enemyTarget(x: Float, ground: Float, kind: String = "spear") =
        CueLayout.Target(x.toDouble(), ground - 170.0, ground - 140.0, when (kind) { "leader" -> 95.0; "shield" -> 55.0; else -> 40.0 })
    private fun partnerTarget(x: Float, ground: Float) = CueLayout.Target(x.toDouble(), ground - 162.0, ground - 121.0, 30.0) // PARTNER_S 0.62
    private fun dummyTarget(x: Float, ground: Float) = CueLayout.Target(x.toDouble(), ground - 151.0, ground - 80.0, 30.0) // DUMMY_S 0.75
    private fun flagTarget(x: Float, ground: Float, banner: Boolean) = CueLayout.goalFlag(ground.toDouble(), banner).let { f ->
        CueLayout.Target(x + 0.1 * f.size, f.top, (f.top + f.foot) / 2, 0.6 * f.size) } // pole at x − 0.5 s, cloth to x + 0.7 s

    /**
     * hud.md §3.3 z-order: the stuck arrow and the telegraph "!" over the bar and pops. On a banner beat neither touches
     * the motto bar (CueLayout); elsewhere they sit above the target as before.
     */
    private fun cues(g: Game, r: com.galaxyandsun.daidatanhhung.core.MissionRun, cam: Float, ground: Float, t: Double) {
        val banner = r.currentBeat.usesBanner && (r.phase == Phase.PLAY || r.phase == Phase.END)
        val heroX = r.hero.x - cam
        val arrowAt = when {
            r.stallTargetX == null -> null
            r.beatType == BeatType.TRAINING && r.trainingStep == com.galaxyandsun.daidatanhhung.core.TrainingStep.DUMMIES -> dummyTarget(r.stallTargetX!!.toFloat() - cam, ground)
            else -> enemyTarget(r.stallTargetX!!.toFloat() - cam, ground, r.stallTarget?.kind ?: "spear")
        }
        arrowAt?.let { val c = CueLayout.arrow(it, heroX, banner); fig.arrow(c.x.toFloat(), c.y.toFloat(), c.dir, t) }
        if (r.flagArrow) { val c = CueLayout.arrow(flagTarget(r.goalX.toFloat() - cam, ground, r.currentBeat.usesBanner), heroX, banner); fig.arrow(c.x.toFloat(), c.y.toFloat(), c.dir, t) }
        for (e in r.enemies) if (e.state == com.galaxyandsun.daidatanhhung.core.EnemyState.WINDUP) {
            val c = CueLayout.bubble(enemyTarget(e.x.toFloat() - cam, ground, e.kind), heroX, banner); fig.bubble(c.x.toFloat(), c.y.toFloat(), c.dir)
        }
        r.partner?.takeIf { it.state == com.galaxyandsun.daidatanhhung.core.EnemyState.WINDUP }?.let {
            val c = CueLayout.bubble(partnerTarget(it.x.toFloat() - cam, ground), heroX, banner); fig.bubble(c.x.toFloat(), c.y.toFloat(), c.dir)
        }
    }

    /**
     * A dialogue line (mission-flow 7d): the speaker's portrait on their side (the hero left, others
     * right), the text box beside it (rules.json dialogue_line 720 / dialogue_narrator 880, 38 px,
     * weight 600), the title as the heading over line 1, then Tiếp or the ask button, and Skip.
     */
    private fun dialogue(g: Game, r: com.galaxyandsun.daidatanhhung.core.MissionRun, t: Double) {
        val dlg = r.dialogue ?: return
        val line = dlg.lines[r.lineIndex.coerceIn(0, dlg.lines.size - 1)]
        // dialogue.md + story-screens.md §5.2: one bottom-anchored panel holding the heading row (60 + 8, shown on line 1)
        // and the line; it starts at corner_bottom + 8 at the latest. The portrait shrinks to the room left (max 240).
        val bottom = rowTop() - 8f
        val top = max(bottom - (32f + 68f + 240f + 32f), cornerClear(g))
        d.rr(40f, top, 1200f, bottom - top, 36f, C.PANEL, C.GOLD, 6f)
        if (r.lineIndex == 0) { d.textBox(r.currentBeat.title.get(g.lang), W / 2, top + 32 + 30, 880f, 44f, C.GOLD, 1); badge(g, r.currentBeat.title, W / 2 + 440, top) }
        val areaTop = top + 32 + 68; val areaBottom = bottom - 32; val cy = (areaTop + areaBottom) / 2
        val pr = ((areaBottom - areaTop) / 2).coerceIn(60f, 120f)
        val narrator = line.speaker == "narrator"
        val heroSide = line.speaker == "hero"
        if (!narrator) {
            val px = if (heroSide) 170f else 1110f
            d.circle(px, cy, pr, C.a(C.CREAM, 0.95), C.GOLD, 6f)
            val id = "pic.portrait_${g.heroId}_${line.speaker}" + (line.mood?.let { "_$it" } ?: "")
            if (!portrait(id, px, cy, pr - 10)) { // debug placeholder: a figure cropped in the medallion (no text in art)
                d.c.save(); d.path.reset(); d.path.addCircle(px, cy, pr - 6, android.graphics.Path.Direction.CW); d.c.clipPath(d.path)
                fig.hero(px, cy + pr * 1.9f, if (heroSide) 1 else -1, false, false, null, t, 0.95f * pr / 120f,
                    tunic = when (line.speaker) { "hero" -> C.RED; "king" -> C.GOLD; else -> C.INDIGO })
                d.c.restore()
            }
        }
        val (cx, box) = when { narrator -> W / 2 to 880f; heroSide -> (320f + 360f) to 720f; else -> (200f + 360f) to 720f }
        d.textBox(line.text.get(g.lang), cx, cy, box, 38f, C.WHITE, if (narrator) 2 else 3, semiBold = true)
        badge(g, line.text, cx, bottom - 18)
        if (r.dialogueButton == "ask") {
            val ask = dlg.ask!!.button
            button("ask", ask.get(g.lang), 1262f - 340f, rowTop(), 340f, rowH(), t, pulse = true, fill = C.RED, shade = 0xFF9E2620.toInt(), size = 34f, labelColor = C.WHITE) { g.ask() } // white on #D9342B is 4.7:1 (QC r3)
            if (r.askHint) fig.hand(1262f - 170f, rowTop() + 10f, t)
        } else nextButton(g, t)
        skipButton(g)
    }


    private var loggedMissing = mutableSetOf<String>()

    /**
     * story-screens §5.2 (r8d): the ending draws its own still (`ending.picture_id`) full-bleed over the 1280 × 720
     * world, centre-cropped to fill when the file isn't 16:9 (never stretched). False when it's missing or doesn't
     * decode: the caller then shows the scene background only, and a debug build logs it once.
     */
    private fun endingStill(g: Game): Boolean {
        val id = g.bundle.mission.ending.pictureId
        val b = pictures(id)
        if (b == null) { if (debug && loggedMissing.add(id)) android.util.Log.w("DDAH", "missing picture $id on the ending: scene background only"); return false }
        val src = StoryLayout.coverCrop(b.width.toDouble(), b.height.toDouble(), W.toDouble(), H.toDouble())
        srcRect.set(src.left.toInt(), src.top.toInt(), src.right.toInt(), src.bottom.toInt())
        dst.set(0f, 0f, W, H); bmpPaint.alpha = 255; bmpPaint.isFilterBitmap = true
        d.c.drawBitmap(b, srcRect, dst, bmpPaint)
        return true
    }
    private val srcRect = android.graphics.Rect()

    /** A dialogue portrait from assets.json; false when the id has no picture yet (debug placeholder). */
    private fun portrait(id: String, x: Float, y: Float, r: Float): Boolean {
        val b = pictures(id) ?: return false
        d.c.save(); d.path.reset(); d.path.addCircle(x, y, r + 4, android.graphics.Path.Direction.CW); d.c.clipPath(d.path) // round frame
        dst.set(x - r - 4, y - r - 4, x + r + 4, y + r + 4); bmpPaint.alpha = 255; d.c.drawBitmap(b, null, dst, bmpPaint)
        d.c.restore(); return true
    }

    /**
     * story-screens §5.2 (r8): until a screen has its real still, the hero's determined portrait in a drum-ring frame,
     * centred on x 640 (StoryLayout.still: 256 on the intro and captions, 208 on beat cards; dropped below 192).
     */
    private fun storyStill(g: Game, card: Boolean, labelTop: Double?) {
        val (r, gap) = cornerSize(g)
        val box = StoryLayout.still(card, (18f + 4 * r + gap).toDouble(), labelTop) ?: return
        val cx = box.cx.toFloat(); val cy = box.cy.toFloat(); val rad = (box.width / 2).toFloat()
        d.circle(cx, cy, rad, C.GOLD_DARK); d.circle(cx, cy, rad - 4, C.GOLD) // the drum ring
        for (i in 0 until 12) { val a = i * Math.PI / 6; d.circle(cx + cos(a).toFloat() * (rad - 10), cy + sin(a).toFloat() * (rad - 10), 3.5f, C.GOLD_DARK) }
        d.circle(cx, cy, rad - 18, C.CREAM)
        if (!portrait("pic.portrait_${g.heroId}_hero_determined", cx, cy, rad - 22)) { // debug placeholder: the hero cropped in the ring
            d.c.save(); d.path.reset(); d.path.addCircle(cx, cy, rad - 18, android.graphics.Path.Direction.CW); d.c.clipPath(d.path)
            fig.hero(cx, cy + (rad - 18) * 1.9f, 1, false, false, null, g.t, 0.95f * (rad - 18) / 120f, tunic = C.RED)
            d.c.restore()
        }
    }

    /** A caption or beat card: header, one sentence, Next and Skip (D-07). */
    private fun storyPanel(head: String?, line: Text, g: Game, t: Double, badgeFor: Text? = null, part: Int? = null) {
        // story-screens.md §5.2: box 880 + 2 × 32; H 235 with a title (beat card), 167 without (caption); bottom-anchored
        val bottom = rowTop() - 8f; val hgt = if (head != null) 235f else 167f
        val top = max(bottom - hgt, cornerClear(g))
        // r8b: "Phần n / Part n" (ui.play.beat + n, the 1-based beat index), 28 px star gold, ink outline 2 px, centred
        // on max(corner_bottom + 8 + 16, panel top − 24); the placeholder still sits ≥ 8 above it
        val labelTop = part?.let { StoryLayout.partLabelTop(top.toDouble(), cornerClear(g).toDouble()) }
        storyStill(g, card = head != null, labelTop = labelTop)
        if (part != null) d.textBox("${g.ui(UiIds.BEAT)} $part", W / 2, (labelTop!! + StoryLayout.LABEL_SIZE / 2).toFloat(), 400f,
            StoryLayout.LABEL_SIZE.toFloat(), C.STAR_GOLD, 1, outline = OUTLINE_INK, outlineW = 4f)
        d.rr(168f, top, 944f, bottom - top, 36f, C.PANEL, C.GOLD, 6f)
        if (head != null) { d.textBox(head, W / 2, top + 32 + 30, 880f, 44f, C.GOLD, 1); badgeFor?.let { badge(g, it, W / 2 + 380, top) } } // fit.beat_title 880 @ 44
        val bodyTop = if (head != null) top + 32 + 68 else top + 32
        d.textBox(line.get(g.lang), W / 2, bodyTop + 51.5f, 880f, 38f, C.WHITE, 2, semiBold = true); badge(g, line, W / 2, bottom - 18) // fit.scene 880 @ 38, weight 600
        nextButton(g, t)
        skipButton(g)
    }

    // ---- story-screens.md §5.2 (QC r5): the bottom row and bottom-anchored panels, clear of the pause/sound corner ----
    /** Bottom-row buttons are pad_min tall (Input Rule 4). */
    private fun rowH() = max(110f, fit.padMinWorld)
    /** The bottom row's top: its buttons sit on safe_bottom − 18. */
    private fun rowTop() = min(720f, safeBottom) - 18f - rowH()
    /** corner_bottom + 8: nothing on a story screen starts above it. */
    private fun cornerClear(g: Game) = 18f + 2 * cornerSize(g).first + 8f

    /** "Tiếp" on the right of the bottom row. */
    private fun nextButton(g: Game, t: Double) = button("next", g.ui(UiIds.NEXT), 1262f - 300f, rowTop(), 300f, rowH(), t, pulse = true) { g.next() }

    private fun skipButton(g: Game) {
        if (!g.onStoryBox) return
        val label = g.uiOrNull(UiIds.SKIP) ?: return
        // "Bỏ qua" on the left of the bottom row, pad_min tall like Tiếp (fit.button 270 @ 34)
        button("skip", label, 18f, rowTop(), 300f, rowH(), g.t, fill = C.a(C.CREAM, 0.85), shade = 0xFFC8B89A.toInt(), size = 34f) { g.skip() }
    }

    /** D-07: one kind warning per run; fires on release like every menu. */
    private fun skipWarning(g: Game) {
        if (!g.skipWarning) return
        next = ArrayList()
        d.rr(0f, 0f, W, H, 0f, C.a(0xFF2A2440.toInt(), 0.75))
        val bh = rowH(); val by = 455f // pad_min buttons (Input Rule 4) inside the card, which grows to hold them (QC r6)
        d.rr(200f, 150f, 880f, by + bh + 24f - 150f, 36f, C.CREAM, C.GOLD, 6f)
        medal(W / 2, 250f, 56f, false)
        d.textBox(g.ui(UiIds.SKIP_WARNING), W / 2, 365f, 780f, 37f, C.INK, 3, semiBold = true) // fit.dialog 780 @ 37, 3 lines, weight 600
        button("keep", g.ui(UiIds.KEEP_READING), 260f, by, 360f, bh, g.t, pulse = true) { g.keepReading() }
        button("skipok", g.ui(UiIds.SKIP_CONFIRM), 660f, by, 360f, bh, g.t, fill = C.a(C.WHITE, 0.9), shade = 0xFFC8B89A.toInt()) { g.confirmSkip() }
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

    /** Input Rule 3 (TASK-020 W7): pause and sound sit top-left on every screen that has them. */
    private fun corner(g: Game, pause: Boolean = true, enabled: Boolean = true) {
        val (r, gap) = cornerSize(g)
        val cy = 18f + r; val x1 = 18f + r; val x2 = x1 + 2 * r + gap
        val old = d.alpha; if (!enabled) d.alpha = 0.5 // Audio Rule 7 / W19: drawn disabled until the preload ends
        if (pause) roundIcon("pause", x1, cy, r, { pauseGlyph(x1, cy, r) }) { enabled && g.pause() }
        val xs = if (pause) x2 else x1
        roundIcon("mute", xs, cy, r, { speakerGlyph(xs, cy, r, g.muted) }) { enabled && g.toggleMute() }
        d.alpha = old
    }

    /** Input Rule 4: pause/sound are ≥ pad_min across (137 world px on the Android reference phone), pad_gap apart. */
    private fun cornerSize(g: Game): Pair<Float, Float> =
        fit.padRadius(48f) to (g.tuning["pad_gap"] / g.tuning["pad_min"]).toFloat() * fit.padMinWorld

    /** The top stack's plates: left edge, width and text box (hud.md §3.3). */
    private data class Stack(val left: Float, val width: Float, val box: Float) { val cx get() = left + width / 2 }

    /**
     * hud.md §3.3: the stack starts at max(330, corner right + 8); its plates are 920 wide (text box 880), or on a
     * narrow phone (0.32 ≤ k < 0.48) 1270 − start wide (min 760) with the text box at rules.json narrow_box_width (720).
     */
    private fun stack(g: Game): Stack {
        val (r, gap) = cornerSize(g)
        val start = max(330f, 18f + 4 * r + gap + 8f)
        val w = min(920f, 1270f - start).coerceAtLeast(760f)
        val narrow = g.content.rules.textLimits.fit?.fields?.get("goal")?.narrowBoxWidth?.toFloat() ?: 720f
        return Stack(start, w, if (w < 920f) narrow else 880f)
    }

    private fun pause(g: Game) {
        when (g.pausedFrom) { Screen.QUIZ -> quiz(g); Screen.INTRO -> story(g, true); Screen.ENDING -> story(g, false); Screen.RESULTS -> results(g); else -> play(g) }
        next = ArrayList()
        d.rr(0f, 0f, W, H, 0f, C.a(0xFF2A2440.toInt(), 0.7))
        d.text(g.ui(UiIds.PAUSED), W / 2, 200f, 64f, C.WHITE)
        val bh = rowH() // pad_min (Input Rule 4)
        button("resume", g.ui(UiIds.RESUME), W / 2 - 200, 260f, 400f, bh, g.t, pulse = true) { g.resume() }
        button("home", g.ui(UiIds.HOME), W / 2 - 200, 260f + bh + 24f, 400f, bh, g.t, fill = C.CREAM, shade = 0xFFC8B89A.toInt()) { g.home() }
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

    /** quiz-and-results.md §5.2: the small-k quiz layout applies at 0.40 ≤ k < 0.48 (pad_min > 72 dp / 0.48 world px). */
    /**
     * quiz §5.2: k < 0.48 (as iOS QuizLayout.small). iOS's extra "cards reach Tiếp" guard isn't needed here: at k ≥ 0.48
     * Android's Tiếp goes below the cards (max(rowTop, cards bottom + 6)), so the cards never reach it.
     */
    private fun quizBoxes(g: Game) = QuizLayout.boxes(cornerClear(g).toDouble(), fit.padMinWorld.toDouble(), safeBottom.toDouble())
    private fun smallK(g: Game) = quizBoxes(g).small

    private fun quiz(g: Game) {
        val q = g.quiz ?: return
        val t = g.t
        val small = smallK(g); g.lockEachQuestion = small // §5.2: there each new question takes the entry lock (Tiếp over slot 3)
        d.c.drawColor(C.BG)
        d.drum(1160f, 640f, 90f, C.a(C.GOLD, 0.18)) // (no drum top-left: pause and sound sit there)
        // The counter and dots: top-centre of the free band right of pause/sound (max(330, corner right + 8) … 1262)
        val (cr, cgap) = cornerSize(g); val band0 = max(330f, 18f + 4 * cr + cgap + 8f); val bandC = (band0 + 1262f) / 2
        val n = q.questions.size; val dx = 60f; val d0 = bandC + 70f - (n - 1) * dx / 2
        for (i in 0 until n) d.circle(d0 + i * dx, 50f, 16f, if (i < q.index || (i == q.index && q.rightShown >= 0)) C.GOLD else C.a(C.WHITE, 0.3), C.GOLD_DARK, 3f)
        d.text("${g.ui(UiIds.QUESTION)} ${min(q.index + 1, n)}/$n", d0 - 40f, 50f, 28f, C.GOLD, Paint.Align.RIGHT)
        val cur = q.current
        // Prompt: 2 lines (≤ 108 at 40 px) from corner_bottom + 8 (163 at ref, 206 at k 0.40), then the cards 8 below
        val pTop = cornerClear(g)
        d.textBox(cur.prompt.get(g.lang), W / 2, pTop + 54f, 980f, 40f, C.WHITE, 2, semiBold = true); badge(g, cur.prompt, W / 2 + 420, pTop + 100f) // fit.quiz_prompt 980 @ 40, weight 600
        val ch = 290f; val y0 = pTop + 116f
        val (cw, gap) = if (small) 380f to 30f else 390f to 20f
        val x0 = if (small) 40f else (W - 3 * cw - 2 * gap) / 2
        // §5.2 after the right pick (small k): the wrong cards fade out over 0.2 s and are removed, then the right card glides
        // to the left slot over 0.3 s; all render-only from rightT, inside feedback_time (0.9 s), before Tiếp shows.
        val rt = if (q.rightShown >= 0) q.rightT else -1.0
        val fade = if (small && rt >= 0) (1 - rt / 0.2).coerceIn(0.0, 1.0) else 1.0
        val glide = if (small && rt >= 0) ((rt - 0.2) / 0.3).coerceIn(0.0, 1.0).toFloat() else 0f
        q.order.forEachIndexed { slot, j ->
            val a = cur.choices[j]
            val wrong = j in q.wrongPicked; val ok = q.rightShown == j
            if (!ok && small && rt >= 0 && fade <= 0.0) return@forEachIndexed // removed
            var x = x0 + slot * (cw + gap)
            if (ok && small) x += (x0 - x) * glide
            if (q.lastWrong == j && q.shakeT > 0) x += (sin(q.shakeT * 60) * 14 * q.shakeT * 2).toFloat()
            val old = d.alpha; if (!ok && small && rt >= 0) d.alpha = fade
            d.rr(x, y0 + 8, cw, ch, 30f, C.a(0, 0.3))
            // quiz-and-results.md: right = #D9F2D0 fill, #3FA34D 10 px border, tick; wrong = #E6E1F0 fill, #9C8FB8 10 px
            // border, circular arrow; ink labels; icons carry a thick ink outline (colour-blind-safe signals)
            d.rr(x, y0, cw, ch, 30f, if (ok) 0xFFD9F2D0.toInt() else if (wrong) 0xFFE6E1F0.toInt() else C.CREAM, if (ok) C.RIGHT else if (wrong) C.TRY_AGAIN else C.GOLD, if (ok || wrong) 10f else 5f)
            picture(a.pictureId, x + cw / 2, y0 + 112, 80f) // below the "Đúng rồi!" pill's row
            if (wrong) {
                val ax = x + cw - 44; val ay = y0 + 44
                d.arc(ax, ay, 18f, -0.3f, 4.4f, C.INK, 14f); d.arc(ax, ay, 18f, -0.3f, 4.4f, C.TRY_AGAIN, 7f)
                d.poly(C.TRY_AGAIN, ax + 18, ay - 18, ax + 28, ay + 4, ax + 6, ay + 4); d.c.drawPath(d.path, d.stroke(C.INK, 4f))
            }
            if (ok) {
                for ((col, w) in listOf(C.INK to 18f, C.RIGHT to 10f)) { // d.stroke is one shared Paint: set it per pass
                    val s0 = d.stroke(col, w); d.c.drawLine(x + cw - 64, y0 + 44, x + cw - 50, y0 + 60, s0); d.c.drawLine(x + cw - 50, y0 + 60, x + cw - 24, y0 + 28, s0)
                }
            }
            d.textBox(a.text.get(g.lang), x + cw / 2, y0 + 232, cw - 30, 37f, C.INK, 2) // fit.quiz_choice 360 @ 37
            badge(g, a.text, x + cw / 2, y0 + 282)
            if (ok) for (kk in 0 until 5) { val ang = t * 3 + kk * 1.26; d.star(x + cw / 2 + cos(ang).toFloat() * 150, y0 + 100 + sin(ang).toFloat() * 80, 16f, C.GLOW, C.GOLD_DARK, ang.toFloat()) }
            // 220×40 pill centred on the card's top row, over the picture and after the orbiting stars (no star crosses it);
            // deep-ink label (accessibility-requirements, quiz card labels: white on #3FA34D is 3.2:1), down to the 28 px floor
            if (ok) {
                val okLabel = g.ui(UiIds.CORRECT); var okSize = 30f
                while (okSize > 28f && d.measure(okLabel, okSize) > 204f) okSize -= 0.5f
                d.rr(x + cw / 2 - 110, y0 + 8, 220f, 40f, 20f, C.RIGHT); d.textBox(okLabel, x + cw / 2, y0 + 28, 208f, okSize, C.DEEP_INK, 1) // rides with the card
            }
            d.alpha = old
            if (!(small && rt >= 0)) next += Region("card$slot", x, y0, cw, ch, false, onTap = { g.answer(j) != com.galaxyandsun.daidatanhhung.core.PickResult.IGNORED })
        }
        if (q.rightShown >= 0) {
            if (small) {
                // §5.2: the why line takes the freed space right of the right card (box 750, ≤ 3 lines), after the glide
                if (glide >= 1f) { d.rr(450f, y0, 790f, 135f, 24f, C.a(C.RIGHT, 0.92)); d.textBox(cur.why.get(g.lang), 845f, y0 + 67f, 750f, 37f, C.WHITE, 3, semiBold = true); badge(g, cur.why, 845f, y0) }
                if (q.canAdvance) button("next", g.ui(UiIds.NEXT), 812f, rowTop(), 450f, rowH(), t, pulse = true) { g.next() } // over the spent slot 3
            } else {
                // the why line: fit.quiz_why 820 @ 37, up to 3 lines, under the cards; Tiếp at pad_min on the bottom row's right
                // r8: the why line left of Tiếp on the bottom row (QuizLayout; as iOS), Tiếp on the bottom row, both ≤ 702
                val qb = quizBoxes(g); val wt = qb.whyTop.toFloat(); val wb = qb.whyBottom.toFloat()
                d.rr(30f, wt, 866f, wb - wt, 24f, C.a(C.RIGHT, 0.92)) // x 30–896, 26 px clear of Tiếp at 922
                d.textBox(cur.why.get(g.lang), 463f, (wt + wb) / 2, 820f, 37f, C.WHITE, 3, semiBold = true); badge(g, cur.why, 463f, wt)
                if (q.canAdvance) button("next", g.ui(UiIds.NEXT), qb.tiepLeft.toFloat(), rowTop(), (QuizLayout.TIEP_RIGHT - qb.tiepLeft).toFloat(), rowH(), t, pulse = true) { g.next() }
            }
        } else if (q.shakeT > 0 || q.wrongPicked.isNotEmpty()) d.text(g.ui(UiIds.RETRY), W / 2, min(H - 40f, y0 + ch + 40f), 36f, 0xFFE6E0F5.toInt())
        corner(g)
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
        medal(1100f, 290f, 60f, g.medalThisRun || g.medalEarned)
        // Gold if earned in this or any run; the "earned" line only in the run that earns it (progression GDD rule 10).
        val medalLine = if (g.medalThisRun) UiIds.MEDAL_EARNED else if (!g.medalEarned) UiIds.MEDAL_MISSING else null
        medalLine?.let { d.textBox(g.ui(it), W / 2, 440f, 780f, 37f, C.a(C.WHITE, 0.9), 3, semiBold = true) } // fit.dialog 780 @ 37, weight 600
        if (g.newlyOpen == null) d.textBox(g.ui(UiIds.MORE_HEROES), W / 2, 525f, 700f, 30f, C.a(C.WHITE, 0.8), 1)
        button("next", g.ui(UiIds.NEXT), W / 2 - 150, rowTop(), 300f, rowH(), t, pulse = true) { g.next() } // pad_min (Input Rule 4)
        corner(g)
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
        d.textBox(name.get(g.lang), 300f, 456f, 560f, 44f, C.WHITE, 1); badge(g, name, 300f, 500f) // fit.hero_name 560 @ 44
        medallion(980f, 300f, 110f, open >= 1)
        d.c.save(); d.c.translate(980f, 300f); val old = d.alpha; d.alpha = 1.0 - open * 0.85
        d.arc(0f, -30 - open * 40, 34f, Math.PI.toFloat(), (2 * Math.PI).toFloat(), C.STEEL, 14f); d.rr(-50f, -30f, 100f, 80f, 14f, C.STEEL); d.circle(0f, 4f, 10f, 0xFF3E3856.toInt())
        d.alpha = old; d.c.restore()
        if (open >= 1) { for (kk in 0 until 6) { val a = t * 2 + kk * 1.05; d.star(980 + cos(a).toFloat() * 150, 300 + sin(a).toFloat() * 120, 18f, C.GLOW, C.GOLD_DARK, a.toFloat()) }; d.text("?", 980f, 300f, 110f, C.GOLD_DARK) }
        d.text(g.ui(UiIds.UNLOCKED), W / 2, 100f, 52f, C.GOLD)
        d.text(g.ui(UiIds.MAP_STUB), W / 2, 530f, 28f, C.a(C.WHITE, 0.6), semiBold = true)
        // unlock.md: one button, no "Play again" (replaying starts from the title); slice: "the map" is the title screen
        button("tomap", g.ui(UiIds.TO_MAP), W / 2 - 170, rowTop(), 340f, rowH(), t, pulse = true) { g.home() } // pad_min
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
        /** hud.md §3.3 (QC r5): the outline ink for pops on light skies and the banner text. */
        const val OUTLINE_INK = 0xFF3A2A20.toInt()
    }
}
