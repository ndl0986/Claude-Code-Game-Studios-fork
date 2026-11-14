package com.galaxyandsun.daidatanhhung.core

import com.galaxyandsun.daidatanhhung.core.content.Content
import com.galaxyandsun.daidatanhhung.core.content.HeroBundle
import com.galaxyandsun.daidatanhhung.core.content.Lang

/** The prototype's screen names (caption is [Phase.CAPTION] inside play). */
enum class Screen(val id: String) {
    TITLE("title"), INTRO("intro"), PLAY("play"), PAUSE("pause"), ENDING("ending"),
    QUIZ("quiz"), RESULTS("results"), UNLOCK("unlock");
    companion object { fun of(id: String?) = entries.firstOrNull { it.id == id } }
}

/**
 * What the game keeps on the device, and nothing else (parity item 3): `lang`, the best
 * `stars.<hero_id>` (never lowered by a worse replay) and the `unlocked` hero ids.
 */
interface Store {
    fun lang(): String?
    fun setLang(code: String)
    fun stars(heroId: String): Int
    fun setStars(heroId: String, stars: Int)
    fun unlocked(): Set<String>
    fun unlock(heroId: String)
}

/** A store in memory, for tests and for when device storage fails. */
class MemoryStore : Store {
    var langCode: String? = null
    val starMap = mutableMapOf<String, Int>()
    val unlockedSet = mutableSetOf<String>()
    override fun lang() = langCode
    override fun setLang(code: String) { langCode = code }
    override fun stars(heroId: String) = starMap[heroId] ?: 0
    override fun setStars(heroId: String, stars: Int) { starMap[heroId] = stars }
    override fun unlocked() = unlockedSet
    override fun unlock(heroId: String) { unlockedSet += heroId }
}

/**
 * The whole slice's flow: title → intro → play (beats, captions) → ending → quiz → results →
 * unlock, plus pause. Pure Kotlin: the Android layer feeds it fixed steps and menu actions, then
 * draws what it exposes. Menu actions return true when they did something (the tap tone plays once).
 */
class Game(
    val content: Content,
    val heroId: String,
    private val store: Store,
    private val sfx: (Sfx) -> Unit,
) {
    val tuning = Tuning.from(content.tuning)
    val bundle: HeroBundle = content.heroes.getValue(heroId)
    val claimStatus: Map<String, String> = bundle.claims.claims.associate { it.id to it.signoff.status }

    var screen = Screen.TITLE; private set
    var lang = Lang.of(store.lang()); private set
    var muted = false; private set
    /** Seconds on the current screen (animations). */
    var t = 0.0; private set
    var line = 0; private set
    lateinit var run: MissionRun; private set
    var quiz: QuizSession? = null; private set
    var stars = 0; private set
    var retries = 0; private set

    init { reset() }

    private fun reset() {
        run = MissionRun(bundle.mission, tuning, Mulberry32(tuning.seed), sfx)
        quiz = null; line = 0; t = 0.0
    }

    fun ui(id: String) = content.ui(id, lang)

    /** One fixed step (1/60 s). Paused and title screens only animate. */
    fun step(dt: Double, input: InputFrame) {
        t += dt
        when (screen) {
            Screen.PLAY -> run.update(dt, input)
            Screen.QUIZ -> quiz?.update(dt)
            else -> Unit
        }
        input.clearTaps()
    }

    // ---- Menu actions (fired on touch-up inside, by the platform layer) ----
    fun start(): Boolean = (screen == Screen.TITLE).also { if (it) { reset(); go(Screen.INTRO) } }

    /** Next on intro, a caption or the ending: one sentence per box, then on. */
    fun next(): Boolean = when (screen) {
        Screen.INTRO -> { if (line < bundle.mission.intro.size - 1) line++ else go(Screen.PLAY); true }
        Screen.ENDING -> { if (line < bundle.mission.ending.lines.size - 1) line++ else startQuiz(); true }
        Screen.PLAY -> if (run.phase == Phase.CAPTION) { if (run.captionNext()) { line = 0; go(Screen.ENDING) }; true } else false
        Screen.QUIZ -> quiz?.let { q -> if (!q.canAdvance) false else { if (q.advance()) finishQuiz(); true } } ?: false
        Screen.RESULTS -> { go(Screen.UNLOCK); true }
        else -> false
    }

    /** The screen under the pause menu (play or quiz, P-05). */
    var pausedFrom = Screen.PLAY; private set

    fun pause(): Boolean = (screen == Screen.PLAY || screen == Screen.QUIZ).also { if (it) { pausedFrom = screen; screen = Screen.PAUSE } }

    /** Resuming resets the 5 s hint timers (Hints GDD; the prototype froze them). */
    fun resume(): Boolean = (screen == Screen.PAUSE).also { if (it) { screen = pausedFrom; if (screen == Screen.PLAY) run.resetHintTimers() } }
    fun home(): Boolean = (screen == Screen.PAUSE || screen == Screen.UNLOCK).also { if (it) { reset(); go(Screen.TITLE) } }
    fun replay(): Boolean = (screen == Screen.UNLOCK).also { if (it) { reset(); go(Screen.INTRO) } }

    /** The VI|EN toggle (title and pause only, leader's call for the slice). Remembered on the device. */
    fun toggleLang(): Boolean {
        if (screen != Screen.TITLE && screen != Screen.PAUSE) return false
        lang = if (lang == Lang.VI) Lang.EN else Lang.VI
        store.setLang(lang.code)
        return true
    }

    /** Debug screenshots only: set the language without the title/pause rule. */
    fun forceLang(code: String) { lang = Lang.of(code); store.setLang(lang.code) }

    fun toggleMute(): Boolean { muted = !muted; return true }

    /** A quiz card. Returns the pick's result; the platform plays chime / soft for it. */
    fun answer(choice: Int): PickResult {
        val q = quiz ?: return PickResult.IGNORED
        if (screen != Screen.QUIZ) return PickResult.IGNORED
        val r = q.pick(choice)
        when (r) { PickResult.RIGHT -> sfx(Sfx.CHIME); PickResult.WRONG -> sfx(Sfx.SOFT); else -> Unit }
        return r
    }

    private fun go(s: Screen) { screen = s; t = 0.0; if (s == Screen.INTRO || s == Screen.ENDING) line = 0 }

    private fun startQuiz() {
        val qs = bundle.quiz.questions
        val n = QuizSession.count(tuning.int("quiz_count"), qs.size)
        quiz = QuizSession(qs.take(n), tuning["feedback_time"], tuning.seed)
        go(Screen.QUIZ)
    }

    private fun finishQuiz() {
        val q = quiz ?: return
        retries = q.retries
        stars = StarRule.stars(content.rules.quizStars, retries)
        if (stars > store.stars(heroId)) store.setStars(heroId, stars)
        val next = bundle.mission.nextHero
        if (next != null && content.rules.quizStars.finishingUnlocksNextHero) store.unlock(next)
        sfx(Sfx.CHIME)
        go(Screen.RESULTS)
    }

    /** Debug builds: jump to a screen for screenshots (adb `--es startScreen`). */
    fun debugJump(target: String, question: Int = 1, beat: Int = 1, stage: String? = null, starCount: Int = 2) {
        reset()
        when (target) {
            "intro" -> go(Screen.INTRO)
            "play" -> { go(Screen.PLAY); if (beat > 1 || stage != null) run.debugStartBeat(beat - 1, stage == "telegraph", stage == "caption") }
            "caption" -> { go(Screen.PLAY); run.debugStartBeat(beat - 1, telegraph = false, caption = true) }
            "pause" -> { go(Screen.PLAY); pause() }
            "ending" -> go(Screen.ENDING)
            "quiz" -> { startQuiz(); repeat((question - 1).coerceAtLeast(0)) { skipQuestion() }; if (stage == "wrong") quiz?.let { answer((it.current.correctIndex + 1) % it.current.choices.size) } }
            "results" -> { stars = starCount; go(Screen.RESULTS) }
            "unlock" -> { stars = starCount; go(Screen.UNLOCK) }
            else -> go(Screen.TITLE)
        }
    }

    private fun skipQuestion() {
        val q = quiz ?: return
        q.pick(q.current.correctIndex); q.update(tuning["feedback_time"])
        if (q.advance()) finishQuiz()
    }
}
