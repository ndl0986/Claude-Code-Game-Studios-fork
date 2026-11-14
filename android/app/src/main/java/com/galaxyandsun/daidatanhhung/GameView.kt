package com.galaxyandsun.daidatanhhung

import android.annotation.SuppressLint
import android.content.Context
import android.os.Handler
import android.os.HandlerThread
import android.view.Choreographer
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.SurfaceHolder
import android.view.SurfaceView
import com.galaxyandsun.daidatanhhung.core.Action
import com.galaxyandsun.daidatanhhung.core.Game
import com.galaxyandsun.daidatanhhung.core.InputFrame
import com.galaxyandsun.daidatanhhung.core.Screen
import com.galaxyandsun.daidatanhhung.core.Sfx
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * The game's one view. A render thread runs a Choreographer (VSYNC) loop: a fixed 1/60 s
 * simulation step with an accumulator (frame delta clamped to 0.25 s), then one hardware-canvas
 * draw. Touches arrive on the UI thread, are queued, and are handled on the render thread
 * against the regions drawn last frame.
 *
 * Firing rule (TASK-007 brief item 10, a deliberate change from the prototype): menu buttons and
 * quiz cards fire on touch-UP inside the same button (avoids stray palm taps); the ◀ ▶ / attack /
 * defend pads act on touch-DOWN. Pointers are tracked by id; cancel, focus loss and pause clear them.
 */
@SuppressLint("ViewConstructor")
class GameView(context: Context, private val game: Game?, private val audio: Audio, private val renderer: Renderer) :
    SurfaceView(context), SurfaceHolder.Callback, Choreographer.FrameCallback {

    private sealed interface Ev
    /** [at]: the press's own time, uptime s (MotionEvent.eventTime): the debounce clock (QC r3 B1). */
    private data class Down(val id: Int, val x: Float, val y: Float, val at: Double) : Ev
    private data class Move(val id: Int, val x: Float, val y: Float) : Ev
    private data class Up(val id: Int, val x: Float, val y: Float) : Ev
    private data object CancelAll : Ev
    private data class Key(val code: Int, val down: Boolean, val at: Double) : Ev
    private data object AutoPause : Ev

    private val events = ConcurrentLinkedQueue<Ev>()
    private val thread = HandlerThread("render").apply { start() }
    private val handler = Handler(thread.looper)
    private var choreographer: Choreographer? = null
    private var running = false
    @Volatile private var surfaceOk = false
    private var hostResumed = true
    private var lastNanos = -1L
    private var acc = 0.0
    private val input = InputFrame()
    private val padHolds = com.galaxyandsun.daidatanhhung.core.PadHolds()
    private val keyHolds = HashSet<Action>()
    private val pressedButton = HashMap<Int, String>()
    /** The press time of each pointer's pressed menu button (fires on release, debounced by press). */
    private val pressedAt = HashMap<Int, Double>()
    @Volatile private var safe = IntArray(4)
    /** Debug screenshots: draw but don't step (`--ez freeze true`), so a 1.1 s telegraph can be captured. */
    @Volatile var frozen = false

    init {
        holder.addCallback(this)
        isFocusable = true; isFocusableInTouchMode = true
        handler.post { choreographer = Choreographer.getInstance() }
    }

    fun setSafeInsets(i: IntArray) { safe = i }
    fun releaseAll() { events += CancelAll }
    /** Focus loss or going to the background pauses play and the quiz (AC10). */
    fun autoPause() { events += CancelAll; events += AutoPause }

    fun onHostResume() { hostResumed = true; startLoop() }
    /** AC10: going to the background pauses the game; it stays paused on return. */
    fun onHostPause() { autoPause(); hostResumed = false; stopLoop() }

    override fun surfaceCreated(h: SurfaceHolder) { surfaceOk = true; startLoop() }
    override fun surfaceChanged(h: SurfaceHolder, format: Int, w: Int, hgt: Int) {}
    override fun surfaceDestroyed(h: SurfaceHolder) { surfaceOk = false; stopLoop() }

    private fun startLoop() {
        if (!surfaceOk || !hostResumed) return
        handler.post {
            if (running) return@post
            running = true; lastNanos = -1L; acc = 0.0
            choreographer?.postFrameCallback(this)
        }
    }

    /** Stops the loop and waits for it, so the surface is never drawn after it's destroyed. */
    private fun stopLoop() {
        val latch = CountDownLatch(1)
        handler.post { running = false; choreographer?.removeFrameCallback(this); latch.countDown() }
        latch.await(150, TimeUnit.MILLISECONDS) // short: never stall the UI thread; the draw is guarded by surfaceOk
    }

    override fun doFrame(frameTimeNanos: Long) {
        if (!running) return
        val dt = if (lastNanos < 0) 0.0 else ((frameTimeNanos - lastNanos) / 1e9).coerceIn(0.0, 0.25)
        lastNanos = frameTimeNanos
        val w = width.toFloat(); val h = height.toFloat()
        renderer.layout(w, h, safe, resources.displayMetrics.density, game?.tuning?.get("pad_min")?.toFloat() ?: 72f)
        drainInput()
        val portrait = h > w
        if (game != null && !portrait && !frozen) {
            acc += dt
            while (acc >= STEP) {
                input.held.clear(); input.held += padHolds.held(); input.held += keyHolds
                game.step(STEP, input)
                acc -= STEP
            }
        }
        audio.muted = game?.muted ?: false
        val c = if (!surfaceOk) null else try { holder.surface.lockHardwareCanvas() } catch (e: Exception) { null }
        if (c != null) {
            try { renderer.draw(c, game, audio.ready, portrait) } finally { holder.surface.unlockCanvasAndPost(c) }
        }
        choreographer?.postFrameCallback(this)
    }

    // ---- Input (render thread) ----
    private fun drainInput() {
        val g = game
        var firedThisFrame = false
        if (g?.screen == Screen.PAUSE || g?.skipWarning == true) { padHolds.clear(); keyHolds.clear() } // S2: pause releases every pad
        while (true) {
            val e = events.poll() ?: break
            when (e) {
                is Down -> {
                    val r = renderer.hit(e.x, e.y) ?: continue
                    val a = r.pad
                    if (a != null) { if (padHolds.down(e.id, a)) input.tapped += a } // Rule 6: a second pointer on an owned pad does nothing
                    else if (g == null || g.pressAllowed(r.key, e.at)) { pressedButton[e.id] = r.key; pressedAt[e.id] = e.at } // gate at press time (QC r2, r3 B1)
                }
                is Move -> padHolds.move(e.id, renderer.hit(e.x, e.y)?.pad)
                is Up -> {
                    padHolds.up(e.id)
                    val at = pressedAt.remove(e.id)
                    val key = pressedButton.remove(e.id) ?: continue
                    val r = renderer.hit(e.x, e.y)
                    if (r != null && r.key == key && r.onTap != null && !(firedThisFrame && key.startsWith("card"))) {
                        // Audio GDD Rule 6: one tone per press; a quiz card's own right/wrong sound is its tone.
                        g?.pressAt = at // the action is debounced by this press's down time (Input Rule 12)
                        val fired = try { r.onTap.invoke() } finally { g?.pressAt = null }
                        if (fired) { if (!key.startsWith("card")) audio.play(Sfx.TAP); firedThisFrame = true }
                    }
                }
                CancelAll -> { padHolds.clear(); pressedButton.clear(); pressedAt.clear(); keyHolds.clear() }
                is Key -> if (g != null) { g.pressAt = e.at; try { key(g, e.code, e.down) } finally { g.pressAt = null } }
                AutoPause -> g?.pause()
            }
        }
    }

    /** Keys mirror the prototype (handy for QC with `adb shell input keyevent`). */
    private fun key(g: Game, code: Int, down: Boolean) {
        val hold = when (code) {
            KeyEvent.KEYCODE_DPAD_LEFT, KeyEvent.KEYCODE_A -> Action.LEFT
            KeyEvent.KEYCODE_DPAD_RIGHT, KeyEvent.KEYCODE_D -> Action.RIGHT
            KeyEvent.KEYCODE_K, KeyEvent.KEYCODE_SHIFT_LEFT, KeyEvent.KEYCODE_SHIFT_RIGHT -> Action.DEFEND
            KeyEvent.KEYCODE_S -> Action.SPECIAL
            else -> null
        }
        if (hold != null) { if (down) { keyHolds += hold; if (hold == Action.SPECIAL) input.tapped += hold } else keyHolds -= hold; return }
        if (!down) return
        val fired = when (code) {
            KeyEvent.KEYCODE_J, KeyEvent.KEYCODE_SPACE -> { if (g.screen == Screen.PLAY) { input.tapped += Action.ATTACK; false } else confirm(g) }
            KeyEvent.KEYCODE_ENTER, KeyEvent.KEYCODE_DPAD_CENTER -> confirm(g)
            KeyEvent.KEYCODE_L -> g.toggleLang()
            KeyEvent.KEYCODE_P, KeyEvent.KEYCODE_ESCAPE -> if (g.screen == Screen.PAUSE) g.resume() else g.pause()
            KeyEvent.KEYCODE_M -> g.toggleMute()
            KeyEvent.KEYCODE_1, KeyEvent.KEYCODE_2, KeyEvent.KEYCODE_3 -> renderer.cardForSlot(g, code - KeyEvent.KEYCODE_1)?.invoke() ?: false
            else -> false
        }
        if (fired) audio.play(Sfx.TAP)
    }

    private fun confirm(g: Game): Boolean = when (g.screen) {
        Screen.TITLE -> audio.ready && g.start()
        Screen.PAUSE -> g.resume()
        Screen.UNLOCK -> g.home()
        else -> g.next()
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
        if (event.repeatCount == 0) events += Key(keyCode, true, event.eventTime / 1000.0)
        return keyCode != KeyEvent.KEYCODE_BACK || super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent): Boolean { events += Key(keyCode, false, event.eventTime / 1000.0); return keyCode != KeyEvent.KEYCODE_BACK || super.onKeyUp(keyCode, event) }

    @SuppressLint("ClickableViewAccessibility")
    override fun onTouchEvent(e: MotionEvent): Boolean {
        when (e.actionMasked) {
            MotionEvent.ACTION_DOWN, MotionEvent.ACTION_POINTER_DOWN -> { val i = e.actionIndex; events += Down(e.getPointerId(i), e.getX(i), e.getY(i), e.eventTime / 1000.0) }
            MotionEvent.ACTION_MOVE -> for (i in 0 until e.pointerCount) events += Move(e.getPointerId(i), e.getX(i), e.getY(i))
            MotionEvent.ACTION_UP, MotionEvent.ACTION_POINTER_UP -> { val i = e.actionIndex; events += Up(e.getPointerId(i), e.getX(i), e.getY(i)) }
            MotionEvent.ACTION_CANCEL -> events += CancelAll
        }
        return true
    }

    companion object { const val STEP = 1.0 / 60 }
}
