package com.galaxyandsun.daidatanhhung

import android.app.Activity
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.os.Bundle
import android.os.Debug
import android.os.SystemClock
import android.util.Log
import android.view.Choreographer
import android.view.SurfaceHolder
import android.view.SurfaceView
import java.io.File
import kotlin.math.sin

/**
 * Debug-only measurement for ADR-0002 (never in release builds). It makes a 2048² sprite atlas
 * (25 cells of 384², painted shapes with alpha) and a 1440×1620 opaque background tile, then:
 * 1. encodes each as WebP lossless, WebP lossy q85 and PNG, and logs the file sizes;
 * 2. decodes each file 5 times per config (ARGB_8888, HARDWARE, RGB_565 for the opaque tile),
 *    logging decode time and allocation bytes;
 * 3. draws a worst-case frame for 10 s on a hardware SurfaceView canvas (2 background tiles + 40
 *    sprites from the atlas, scaled to the screen) and logs frame-interval and draw-time percentiles.
 * Results go to logcat with the tag ADR0002.
 */
class AtlasBenchActivity : Activity(), SurfaceHolder.Callback, Choreographer.FrameCallback {
    private lateinit var view: SurfaceView
    private var atlas: Bitmap? = null
    private var bg: Bitmap? = null
    private val intervals = ArrayList<Double>()
    private val draws = ArrayList<Double>()
    private var last = -1L
    private var start = 0L
    private var running = false
    private val paint = Paint(Paint.FILTER_BITMAP_FLAG)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        view = SurfaceView(this); setContentView(view); view.holder.addCallback(this)
        Thread { measure(); runOnUiThread { running = true; start = SystemClock.uptimeMillis(); Choreographer.getInstance().postFrameCallback(this) } }.start()
    }

    private fun log(s: String) = Log.i("ADR0002", s)

    private fun makeAtlas(): Bitmap {
        val b = Bitmap.createBitmap(2048, 2048, Bitmap.Config.ARGB_8888)
        val c = Canvas(b); val p = Paint(Paint.ANTI_ALIAS_FLAG)
        for (i in 0 until 25) {
            val cx = (i % 5) * 384f + 192; val cy = (i / 5) * 384f + 192
            for (k in 0 until 14) { // a painted, cartoon-like figure: many soft shapes, gradients of colour
                p.color = Color.argb(255, (i * 37 + k * 23) % 255, (i * 11 + k * 51) % 255, (i * 73 + k * 7) % 255)
                c.drawOval(RectF(cx - 150 + k * 9, cy - 170 + k * 11, cx + 120 - k * 5, cy + 160 - k * 13), p)
            }
            p.color = Color.argb(160, 255, 255, 255); c.drawCircle(cx - 40, cy - 60, 40f, p)
        }
        return b
    }

    private fun makeBackground(): Bitmap {
        val b = Bitmap.createBitmap(1440, 1620, Bitmap.Config.ARGB_8888)
        val c = Canvas(b); val p = Paint(Paint.ANTI_ALIAS_FLAG)
        for (y in 0 until 1620 step 4) { p.color = Color.rgb(255 - y / 12, 220 - y / 20, 160 + y / 30); c.drawRect(0f, y.toFloat(), 1440f, y + 4f, p) }
        for (i in 0 until 60) { p.color = Color.rgb(60 + i * 2, 140 + (i * 7) % 90, 70 + (i * 13) % 80)
            c.drawOval(RectF(i * 24f, 900f + 200 * sin(i * 0.7f), i * 24f + 300, 1620f), p) }
        return b
    }

    private fun measure() {
        val dir = File(cacheDir, "adr0002").apply { mkdirs() }
        val sources = mapOf("atlas2048" to makeAtlas(), "bg1440x1620" to makeBackground())
        log("device: ${android.os.Build.MODEL} sdk ${android.os.Build.VERSION.SDK_INT}, maxMemory ${Runtime.getRuntime().maxMemory() / 1048576} MB")
        for ((name, src) in sources) {
            val formats = listOf(Triple("webp-lossless", Bitmap.CompressFormat.WEBP_LOSSLESS, 100), Triple("webp-q85", Bitmap.CompressFormat.WEBP_LOSSY, 85), Triple("png", Bitmap.CompressFormat.PNG, 100))
            for ((fmt, cf, q) in formats) {
                val f = File(dir, "$name.$fmt"); f.outputStream().use { src.compress(cf, q, it) }
                val configs = mutableListOf(Bitmap.Config.ARGB_8888, Bitmap.Config.HARDWARE)
                if (name.startsWith("bg")) configs += Bitmap.Config.RGB_565
                for (cfg in configs) {
                    val times = ArrayList<Double>(); var bytes = 0; var nativeDelta = 0L
                    repeat(5) {
                        System.gc(); val n0 = Debug.getNativeHeapAllocatedSize()
                        val t0 = SystemClock.elapsedRealtimeNanos()
                        val b = BitmapFactory.decodeFile(f.path, BitmapFactory.Options().apply { inPreferredConfig = cfg })
                        times += (SystemClock.elapsedRealtimeNanos() - t0) / 1e6
                        nativeDelta = Debug.getNativeHeapAllocatedSize() - n0
                        bytes = b.allocationByteCount; b.recycle()
                    }
                    times.sort()
                    log("$name $fmt file=${f.length() / 1024} KB  decode[$cfg] median=${"%.1f".format(times[2])} ms max=${"%.1f".format(times[4])} ms  allocationBytes=${bytes / 1048576.0} MB nativeHeapDelta=${nativeDelta / 1048576.0} MB")
                }
            }
        }
        atlas = BitmapFactory.decodeFile(File(dir, "atlas2048.webp-lossless").path, BitmapFactory.Options().apply { inPreferredConfig = Bitmap.Config.HARDWARE })
        bg = BitmapFactory.decodeFile(File(dir, "bg1440x1620.webp-q85").path, BitmapFactory.Options().apply { inPreferredConfig = Bitmap.Config.HARDWARE })
        log("frame test: 2 background tiles + 40 sprites from the 2048² atlas (HARDWARE bitmaps), 10 s")
    }

    override fun doFrame(frameTimeNanos: Long) {
        if (!running) return
        if (last > 0) intervals += (frameTimeNanos - last) / 1e6
        last = frameTimeNanos
        val holder = view.holder
        val t0 = SystemClock.elapsedRealtimeNanos()
        val c = try { holder.surface.lockHardwareCanvas() } catch (e: Exception) { null }
        if (c != null) {
            val w = c.width.toFloat(); val h = c.height.toFloat(); val k = h / 720f
            val b = bg!!; val a = atlas!!
            c.drawBitmap(b, null, RectF(0f, 0f, w / 2, h), paint); c.drawBitmap(b, null, RectF(w / 2, 0f, w, h), paint)
            val t = (frameTimeNanos / 1e9).toFloat()
            for (i in 0 until 40) {
                val cell = i % 25; val src = Rect((cell % 5) * 384, (cell / 5) * 384, (cell % 5) * 384 + 384, (cell / 5) * 384 + 384)
                val x = ((i * 157 + t * 120) % (w + 300)) - 150; val y = 200 * k + (i % 4) * 90 * k
                c.drawBitmap(a, src, RectF(x, y, x + 256 * k, y + 256 * k), paint)
            }
            holder.surface.unlockCanvasAndPost(c)
        }
        draws += (SystemClock.elapsedRealtimeNanos() - t0) / 1e6
        if (SystemClock.uptimeMillis() - start > 10_000) { running = false; report(); return }
        Choreographer.getInstance().postFrameCallback(this)
    }

    private fun pct(l: List<Double>, p: Double) = l.sorted()[((l.size - 1) * p).toInt()]

    private fun report() {
        log("frames=${intervals.size}  interval p50=${"%.2f".format(pct(intervals, 0.5))} p95=${"%.2f".format(pct(intervals, 0.95))} p99=${"%.2f".format(pct(intervals, 0.99))} ms  " +
            "draw(lock..post) p50=${"%.2f".format(pct(draws, 0.5))} p95=${"%.2f".format(pct(draws, 0.95))} ms  jank(>20ms)=${intervals.count { it > 20 }}")
        log("done")
    }

    override fun surfaceCreated(h: SurfaceHolder) {}
    override fun surfaceChanged(h: SurfaceHolder, f: Int, w: Int, hh: Int) {}
    override fun surfaceDestroyed(h: SurfaceHolder) { running = false }
}
