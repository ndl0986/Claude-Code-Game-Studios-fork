package com.galaxyandsun.daidatanhhung

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import android.os.SystemClock
import com.galaxyandsun.daidatanhhung.core.Sfx
import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.exp
import kotlin.math.ln
import kotlin.math.max
import kotlin.math.sin

/**
 * SoundPool with **placeholder sounds**: the prototype's Web Audio tones, synthesised once into
 * small WAV files in the cache folder (real sounds come from content/ later, as m4a or wav).
 * USAGE_GAME. [ready] turns true when every sound id has loaded (OnLoadCompleteListener).
 */
class Audio(context: Context) {
    private val pool = SoundPool.Builder().setMaxStreams(6).setAudioAttributes(
        AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_GAME).setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build(),
    ).build()
    private val ids = mutableMapOf<Sfx, Int>()
    private val loaded = mutableSetOf<Int>()
    @Volatile var ready = false; private set
    @Volatile var volume = 0.5f
    @Volatile var muted = false
    private var lastTap = -1L

    init {
        pool.setOnLoadCompleteListener { _, id, status ->
            synchronized(loaded) { if (status == 0) loaded += id; ready = loaded.size == Sfx.entries.size }
        }
        val dir = File(context.cacheDir, "sfx").apply { mkdirs() }
        for (s in Sfx.entries) {
            val f = File(dir, "${s.name.lowercase()}.wav")
            f.writeBytes(wav(synth(s)))
            ids[s] = pool.load(f.path, 1)
        }
    }

    /** Plays [s] once. The tap tone is limited to one per 80 ms, so a press sounds once (QC O6). */
    fun play(s: Sfx) {
        if (muted || !ready) return
        if (s == Sfx.TAP) {
            val now = SystemClock.uptimeMillis()
            if (lastTap >= 0 && now - lastTap < 80) return
            lastTap = now
        }
        ids[s]?.let { pool.play(it, volume, volume, 1, 0, 1f) }
    }

    fun release() = pool.release()

    // ---- Tone synthesis (the prototype's sfx table) ----
    private data class Tone(val freq: Double, val dur: Double, val type: String, val vol: Double, val slide: Double = 0.0)

    private fun tones(s: Sfx): List<Tone> = when (s) {
        Sfx.DRUM -> listOf(Tone(110.0, 0.25, "sine", 0.6, 0.5), Tone(220.0, 0.08, "triangle", 0.2))
        Sfx.CLANG -> listOf(Tone(880.0, 0.18, "triangle", 0.25), Tone(1320.0, 0.12, "sine", 0.15))
        Sfx.SWOOSH -> listOf(Tone(500.0, 0.12, "sawtooth", 0.05, 0.4))
        Sfx.BONK -> listOf(Tone(180.0, 0.2, "triangle", 0.25, 0.7))
        Sfx.CHIME -> listOf(Tone(784.0, 0.2, "sine", 0.3), Tone(1046.0, 0.3, "sine", 0.3))
        Sfx.SOFT -> listOf(Tone(260.0, 0.25, "triangle", 0.18, 0.85))
        Sfx.TAP -> listOf(Tone(660.0, 0.06, "sine", 0.15))
    }

    private fun synth(s: Sfx): ShortArray {
        val rate = RATE
        val ts = tones(s)
        val n = (ts.maxOf { it.dur } * rate).toInt() + 1
        val buf = DoubleArray(n)
        for (t in ts) {
            var phase = 0.0
            val len = (t.dur * rate).toInt()
            for (i in 0 until len) {
                val x = i / rate.toDouble()
                val f = if (t.slide > 0) t.freq * exp(ln(max(30.0 / t.freq, t.slide)) * x / t.dur) else t.freq
                phase += f / rate
                val p = phase - kotlin.math.floor(phase)
                val w = when (t.type) {
                    "sine" -> sin(2 * PI * p)
                    "triangle" -> 1 - 4 * abs(p - 0.5)
                    "sawtooth" -> 2 * p - 1
                    else -> if (p < 0.5) 1.0 else -1.0
                }
                val g = t.vol * exp(ln(0.001 / t.vol) * x / t.dur)
                buf[i] += w * g
            }
        }
        return ShortArray(n) { (buf[it].coerceIn(-1.0, 1.0) * 32767).toInt().toShort() }
    }

    private fun wav(pcm: ShortArray): ByteArray {
        val data = ByteBuffer.allocate(pcm.size * 2).order(ByteOrder.LITTLE_ENDIAN).apply { pcm.forEach { putShort(it) } }.array()
        val h = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN)
        h.put("RIFF".toByteArray()).putInt(36 + data.size).put("WAVE".toByteArray())
        h.put("fmt ".toByteArray()).putInt(16).putShort(1).putShort(1).putInt(RATE).putInt(RATE * 2).putShort(2).putShort(16)
        h.put("data".toByteArray()).putInt(data.size)
        return ByteArrayOutputStream().apply { write(h.array()); write(data) }.toByteArray()
    }

    companion object { const val RATE = 22050 }
}
