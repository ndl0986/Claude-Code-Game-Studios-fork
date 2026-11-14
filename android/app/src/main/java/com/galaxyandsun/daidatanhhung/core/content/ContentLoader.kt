package com.galaxyandsun.daidatanhhung.core.content

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.decodeFromJsonElement

/** One hero's mission, quiz and claims, as bundled under heroes/<id>/. */
data class HeroBundle(val mission: MissionFile, val quiz: QuizFile, val claims: ClaimsFile)

/** Everything the game reads from content/data (plus samples/ in debug builds). */
data class Content(
    val index: IndexFile,
    val strings: StringsFile,
    val rules: RulesFile,
    val tuning: TuningFile,
    val assets: AssetsFile,
    val markers: MarkersFile,
    val sources: SourcesFile,
    val heroes: Map<String, HeroBundle>,
) {
    private val ui = strings.strings.associateBy { it.id }

    /** A UI string; a missing id returns the id itself, so the gap is visible on screen. */
    fun ui(id: String, lang: Lang): String = ui[id]?.let { if (lang == Lang.VI) it.vi else it.en } ?: id
}

/**
 * Reads content through [read] (a path relative to content/data, e.g. "tuning.json"), so the
 * same code reads Android assets in the app and plain files in JVM unit tests.
 */
class ContentLoader(private val read: (String) -> String?, private val strict: Boolean = false) {
    fun load(extraHeroes: List<String> = emptyList()): Content {
        val index: IndexFile = decode("index.json")
        val heroIds = (index.heroes + extraHeroes).distinct()
        val heroes = heroIds.associateWith { id ->
            HeroBundle(decode("heroes/$id/mission.json"), decode("heroes/$id/quiz.json"), decode("heroes/$id/claims.json"))
        }
        return Content(
            index = index,
            strings = decode("strings.json"),
            rules = decode("rules.json"),
            tuning = decode("tuning.json"),
            assets = decode("assets.json"),
            markers = decode("markers.json"),
            sources = decode("sources.json"),
            heroes = heroes,
        )
    }

    private inline fun <reified T> decode(path: String): T {
        val text = read(path) ?: throw ContentException("missing content file $path")
        return try {
            (if (strict) JSON else LENIENT).decodeFromString<T>(text)
        } catch (e: Exception) {
            throw ContentException("$path: ${e.message}", e)
        }
    }

    companion object {
        /** Strict: unknown keys are errors. The content tests decode with this, so a typo fails a test. */
        val JSON = Json { ignoreUnknownKeys = false; explicitNulls = false }

        /**
         * Run time: unknown keys are ignored, so a newer MINOR schema (a new optional field) never stops
         * a shipped app from reading its bundle (R11: only a newer MAJOR is refused, at build time).
         */
        val LENIENT = Json { ignoreUnknownKeys = true; explicitNulls = false }

        /** A fight beat's params; other beat types play as a fight until D-08 decides them. */
        fun fightParams(beat: Beat): FightParams? =
            try { JSON.decodeFromJsonElement<FightParams>(beat.params) } catch (e: Exception) { null }
    }
}

class ContentException(message: String, cause: Throwable? = null) : RuntimeException(message, cause)
