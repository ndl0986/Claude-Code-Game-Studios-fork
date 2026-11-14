package com.galaxyandsun.daidatanhhung.core

import kotlin.math.max

/**
 * hud.md §3.3 (r8, AC17): where the telegraph "!" bubble and the stuck arrow go. On a banner beat neither may
 * straddle the motto bar: every pixel at y ≥ bar bottom + 8. Screen coordinates (world px after the camera).
 */
object CueLayout {
    const val SCREEN_W = 1280.0
    /** The motto bar is 156–268 (hud.md §3.3); cues stay at y ≥ 276 on banner beats. */
    const val BAR_BOTTOM = 268.0; const val FLOOR = BAR_BOTTOM + 8
    const val EDGE = 8.0
    const val GAP = 12.0

    /** Which way the arrow's tip, or the bubble's tail, points. */
    enum class Dir { DOWN, LEFT, RIGHT }
    /** A placed cue: the shape's origin and its pointing direction. */
    data class Cue(val x: Double, val y: Double, val dir: Dir)

    /** What the cue points at: its centre x, top, mid-height and half width. */
    data class Target(val x: Double, val top: Double, val midY: Double, val halfW: Double)

    // The arrow (ASSET-034 placeholder): 64 long, drawn pointing down with its tip at +22 and its back at −42, ±30 wide,
    // bouncing ±6 (12) along its axis; above a target its tip rests on the target's top at the bounce's low point, so it
    // fits below the bar exactly when the target's top ≥ 276 + 64 + 12 = 352 (hud.md §3.3). Rotated 90° for the sides.
    const val A_TIP = 22.0; const val A_BACK = 42.0; const val A_HALF = 30.0; const val A_BOUNCE = 6.0
    // The bubble (ASSET-208 placeholder): a circle of radius 30 with a 12 px tail.
    const val B_R = 30.0; const val B_TAIL = 12.0

    /** Every pixel the arrow can reach over its bounce. */
    fun arrowBox(c: Cue): StoryLayout.Box = when (c.dir) {
        Dir.DOWN -> StoryLayout.Box(c.x - A_HALF, c.y - A_BACK - A_BOUNCE, c.x + A_HALF, c.y + A_TIP + A_BOUNCE)
        Dir.LEFT -> StoryLayout.Box(c.x - A_TIP - A_BOUNCE, c.y - A_HALF, c.x + A_BACK + A_BOUNCE, c.y + A_HALF)
        Dir.RIGHT -> StoryLayout.Box(c.x - A_BACK - A_BOUNCE, c.y - A_HALF, c.x + A_TIP + A_BOUNCE, c.y + A_HALF)
    }

    /** Every pixel of the bubble and its tail. */
    fun bubbleBox(c: Cue): StoryLayout.Box = when (c.dir) {
        Dir.DOWN -> StoryLayout.Box(c.x - B_R, c.y - B_R, c.x + B_R, c.y + B_R + B_TAIL)
        Dir.LEFT -> StoryLayout.Box(c.x - B_R - B_TAIL, c.y - B_R, c.x + B_R, c.y + B_R)
        Dir.RIGHT -> StoryLayout.Box(c.x - B_R, c.y - B_R, c.x + B_R + B_TAIL, c.y + B_R)
    }

    private fun onScreen(b: StoryLayout.Box) = b.left >= EDGE && b.right <= SCREEN_W - EDGE

    /**
     * Side placement: away from the hero (or, with no hero, the side nearer the screen centre); if that side is
     * within 8 px of the screen edge, the other side. [reach] is the distance from the target's centre to the cue's
     * origin; [box] measures a candidate.
     */
    private fun side(t: Target, heroX: Double?, y: Double, reach: Double, box: (Cue) -> StoryLayout.Box): Cue {
        val away = if (heroX != null) (if (t.x >= heroX) 1 else -1) else (if (t.x < SCREEN_W / 2) 1 else -1)
        fun at(s: Int) = Cue(t.x + s * reach, y, if (s > 0) Dir.LEFT else Dir.RIGHT)
        val first = at(away)
        return if (onScreen(box(first))) first else at(-away)
    }

    /** The stuck arrow: above the target when its whole bounce fits below the bar; else from the side, at mid-height. */
    fun arrow(t: Target, heroX: Double?, banner: Boolean): Cue {
        val above = Cue(t.x, t.top - A_TIP - A_BOUNCE, Dir.DOWN)
        if (!banner || arrowBox(above).top >= FLOOR) return above
        val y = max(t.midY, FLOOR + A_HALF)
        return side(t, heroX, y, t.halfW + GAP + A_TIP + A_BOUNCE, ::arrowBox)
    }

    /** The telegraph "!": above the helmet when it fits wholly below the bar; else beside the head at head height. */
    fun bubble(t: Target, heroX: Double?, banner: Boolean): Cue {
        val above = Cue(t.x, t.top - GAP - B_TAIL - B_R, Dir.DOWN)
        if (!banner || bubbleBox(above).top >= FLOOR) return above
        val y = max(t.midY, FLOOR + B_R)
        return side(t, heroX, y, t.halfW + B_TAIL + B_R, ::bubbleBox)
    }

    // ---- Props on banner beats (r9, leader's call (a); hud.md §3.3) ----
    // Figures.flag(x, y, s): the pole spans y − 0.7 s … y + 0.7 s and the cloth peaks at y − 0.8 s, so its box is
    // y − 0.8 s … y + 0.7 s (1.5 s tall).
    const val FLAG_TOP_K = 0.8; const val FLAG_FOOT_K = 0.7
    const val GOAL_FLAG = 150.0; const val GOAL_FLAG_BANNER = 120.0

    /** A flag icon's centre y and size. */
    data class Prop(val y: Double, val size: Double) { val top get() = y - FLAG_TOP_K * size; val foot get() = y + FLAG_FOOT_K * size }

    /** The goal flag, its foot on the ground; on a banner beat 120 so the whole flag sits at y ≥ 276 (below the bar). */
    fun goalFlag(ground: Double, banner: Boolean): Prop {
        val s = if (banner) GOAL_FLAG_BANNER else GOAL_FLAG
        return Prop(ground - FLAG_FOOT_K * s, s)
    }

    /** The banner the hero raises in training (110, held beside him): on a banner beat it stays below the bar too. */
    fun raisedBanner(ground: Double, banner: Boolean): Prop =
        if (!banner) Prop(ground - 250, 110.0) else Prop(max(ground - 250, FLOOR + FLAG_TOP_K * 110.0), 110.0)
}
