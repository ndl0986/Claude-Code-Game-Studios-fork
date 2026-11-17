package com.galaxyandsun.daidatanhhung.core

import kotlin.math.max
import kotlin.math.min

/**
 * The pads held by each pointer id (TASK-007 brief item 10). Pads act on touch-down; sliding
 * between ◀ and ▶ switches direction; up, cancel, focus loss and pause release them.
 */
class PadHolds {
    private val holds = HashMap<Int, Action>()
    private fun ownedByOther(id: Int, a: Action) = holds.any { (k, v) -> k != id && v == a }
    /**
     * A pointer lands on pad [a]. Input GDD Rule 6: if another pointer already owns it, this one is
     * ignored until it lifts (it never takes the pad over). Returns true when it now owns the pad
     * (only then does the press fire).
     */
    fun down(id: Int, a: Action): Boolean {
        if (ownedByOther(id, a)) return false
        holds[id] = a; return true
    }
    /**
     * A move (Rule 9): a pointer keeps its pad from down to up; the only change is a held ◀/▶
     * following the finger onto the other arrow (unless another pointer owns that arrow).
     */
    fun move(id: Int, over: Action?) {
        val a = holds[id] ?: return
        if ((a == Action.LEFT || a == Action.RIGHT) && (over == Action.LEFT || over == Action.RIGHT) && !ownedByOther(id, over)) holds[id] = over
    }
    fun up(id: Int) { holds.remove(id) }
    fun clear() = holds.clear()
    fun held(): Set<Action> = holds.values.toSet()
}

/** The 1280×720 world letterboxed inside the safe rect, and the pad size floor (pad_min dp). */
data class ScreenFit(val k: Float, val ox: Float, val oy: Float, val padMinWorld: Float) {
    /** A pad's radius in world units: never smaller than pad_min dp across. */
    fun padRadius(r0: Float) = max(r0, padMinWorld / 2)

    companion object {
        const val W = 1280f
        const val H = 720f
        /** [safe] = left, top, right, bottom insets in px. */
        fun of(w: Float, h: Float, safe: IntArray, density: Float, padMinDp: Float): ScreenFit {
            val aw = max(1f, w - safe[0] - safe[2]); val ah = max(1f, h - safe[1] - safe[3])
            val k = min(aw / W, ah / H)
            return ScreenFit(k, safe[0] + (aw - W * k) / 2, safe[1] + (ah - H * k) / 2, padMinDp * density / k)
        }
    }
}
