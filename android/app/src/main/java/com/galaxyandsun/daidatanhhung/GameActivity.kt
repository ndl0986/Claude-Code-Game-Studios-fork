package com.galaxyandsun.daidatanhhung

import android.app.Activity
import android.graphics.Typeface
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import com.galaxyandsun.daidatanhhung.core.ClaimGate
import com.galaxyandsun.daidatanhhung.core.Game
import com.galaxyandsun.daidatanhhung.core.content.ContentLoader
import com.galaxyandsun.daidatanhhung.core.content.Validator

/**
 * The single activity (TASK-007 vertical slice): landscape, immersive full screen, drawing under
 * the cutout; it loads content/ from assets, builds the [Game] and hosts the [GameView].
 */
class GameActivity : Activity() {
    private lateinit var view: GameView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.attributes = window.attributes.apply {
            layoutInDisplayCutoutMode = when {
                Build.VERSION.SDK_INT >= 30 -> WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
                Build.VERSION.SDK_INT >= 28 -> WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
                else -> layoutInDisplayCutoutMode
            }
        }
        val app = application as GameApp
        // Debug only: `--es missionFile mission-full.json` plays a draft mission (content/drafts) in place of the bundled one.
        val missionFile = if (BuildConfig.DEBUG) intent?.getStringExtra("missionFile") else null
        val content = ContentLoader { path ->
            val p = if (missionFile != null && path.endsWith("/mission.json")) path.replace("mission.json", missionFile) else path
            try { assets.open(p).bufferedReader().readText() } catch (e: Exception) { if (p != path) try { assets.open(path).bufferedReader().readText() } catch (e2: Exception) { null } else null }
        }.load(extraHeroes = if (BuildConfig.DEBUG) listOf("sample") else emptyList())
        val problems = Validator.validate(content, checkPictures = !BuildConfig.DEBUG)
        problems.forEach { Log.w(TAG, "content: $it") }
        // Release: a mission whose claims are not all approved is hidden and logged, never a crash (R12).
        val heroId = content.heroes.keys.firstOrNull { id ->
            val b = content.heroes.getValue(id)
            val gate = ClaimGate.evaluate(b.claims.claims.associate { it.id to it.signoff.status }, Validator.texts(b).map { it.second.claims })
            (BuildConfig.DEBUG || gate.runtimeShow).also { ok -> if (!ok) Log.w(TAG, "hiding mission $id: unsigned ${gate.debugBadges}") }
        }
        val font = { w: Int -> Typeface.Builder(assets, "fonts/nunito.ttf").setFontVariationSettings("'wght' $w").build() }
        val game = heroId?.let { Game(content, it, PrefsStore(this)) { s -> app.audio.play(s) } }
        app.audio.volume = (content.tuning.values["volume"]?.value ?: 0.5).toFloat()
        // Pictures from assets.json (png/webp under content/data), decoded once on first use.
        val files = content.assets.assets.filter { it.kind == "picture" }.associate { it.id to it.file }
        val cache = HashMap<String, android.graphics.Bitmap?>()
        val pictures = { id: String -> cache.getOrPut(id) { files[id]?.let { f -> try { assets.open(f).use { android.graphics.BitmapFactory.decodeStream(it) } } catch (e: Exception) { null } } } }
        view = GameView(this, game, app.audio, Renderer(font(800), font(600), BuildConfig.DEBUG, pictures))
        setContentView(view)
        if (BuildConfig.DEBUG && game != null) intent?.getStringExtra("startScreen")?.let { target ->
            game.debugJump(target, intent.getIntExtra("q", 1), intent.getIntExtra("beat", 1), intent.getStringExtra("stage"), intent.getIntExtra("stars", 2))
            view.frozen = intent.getBooleanExtra("freeze", false)
            intent.getStringExtra("lang")?.let { if (it != game.lang.code) game.forceLang(it) }
        }
        view.setOnApplyWindowInsetsListener { v, insets -> view.setSafeInsets(safeInsets(insets)); v.onApplyWindowInsets(insets) }
        immersive()
    }

    /** The max per side of the system bars (ignoring visibility, so pads don't jump), cutout and gesture zones. */
    private fun safeInsets(i: WindowInsets): IntArray {
        if (Build.VERSION.SDK_INT >= 30) {
            val bars = i.getInsetsIgnoringVisibility(WindowInsets.Type.systemBars())
            val cut = i.getInsets(WindowInsets.Type.displayCutout())
            val gest = i.getInsets(WindowInsets.Type.mandatorySystemGestures())
            return intArrayOf(maxOf(bars.left, cut.left, gest.left), maxOf(bars.top, cut.top, gest.top),
                maxOf(bars.right, cut.right, gest.right), maxOf(bars.bottom, cut.bottom, gest.bottom))
        }
        @Suppress("DEPRECATION")
        val st = intArrayOf(i.stableInsetLeft, i.stableInsetTop, i.stableInsetRight, i.stableInsetBottom)
        val c = if (Build.VERSION.SDK_INT >= 28) i.displayCutout else null
        val g = if (Build.VERSION.SDK_INT >= 29) @Suppress("DEPRECATION") i.mandatorySystemGestureInsets else null
        return intArrayOf(maxOf(st[0], c?.safeInsetLeft ?: 0, g?.left ?: 0), maxOf(st[1], c?.safeInsetTop ?: 0, g?.top ?: 0),
            maxOf(st[2], c?.safeInsetRight ?: 0, g?.right ?: 0), maxOf(st[3], c?.safeInsetBottom ?: 0, g?.bottom ?: 0))
    }

    private fun immersive() {
        if (Build.VERSION.SDK_INT >= 30) {
            window.setDecorFitsSystemWindows(false)
            window.insetsController?.let {
                it.hide(WindowInsets.Type.systemBars())
                it.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or View.SYSTEM_UI_FLAG_FULLSCREEN or
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) immersive() else view.releaseAll()
    }

    override fun onResume() { super.onResume(); view.onHostResume() }
    override fun onPause() { view.releaseAll(); view.onHostPause(); super.onPause() }

    companion object { const val TAG = "DaiDat" }
}
