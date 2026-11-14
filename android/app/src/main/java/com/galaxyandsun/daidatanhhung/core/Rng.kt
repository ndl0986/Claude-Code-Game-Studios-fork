package com.galaxyandsun.daidatanhhung.core

/**
 * mulberry32, bit for bit the prototype's rng() (index.html @203d73e) in UInt32 math, so a
 * seed gives the same sequence on Android, iOS and the browser.
 */
class Mulberry32(seed: Long) {
    private var state: Int = seed.toInt()

    /** The next value in [0, 1). */
    fun next(): Double {
        state += 0x6D2B79F5
        var t = imul(state xor (state ushr 15), state or 1)
        t = t xor (t + imul(t xor (t ushr 7), t or 61))
        val u = (t xor (t ushr 14)).toLong() and 0xFFFFFFFFL
        return u / 4294967296.0
    }

    private fun imul(a: Int, b: Int): Int = a * b // Kotlin Int multiply wraps like Math.imul
}
