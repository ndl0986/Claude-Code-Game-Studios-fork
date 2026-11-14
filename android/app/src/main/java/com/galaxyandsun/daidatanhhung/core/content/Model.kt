package com.galaxyandsun.daidatanhhung.core.content

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject

// Data classes for content/ (ADR-0001, content/README.md). Decoded strictly: an unknown key is an
// error, so a typo in content fails the content tests instead of being ignored.

/** A story line with VI + EN and the claims it rests on. */
@Serializable
data class Text(val id: String, val vi: String, val en: String, val claims: List<String>) {
    fun get(lang: Lang): String = if (lang == Lang.VI) vi else en
}

/** A UI string (strings.json only): no claims. */
@Serializable
data class UiText(val id: String, val vi: String, val en: String, val field: String? = null)

enum class Lang(val code: String) { VI("vi"), EN("en");
    companion object { fun of(code: String?): Lang = entries.firstOrNull { it.code == code } ?: VI }
}

@Serializable
data class StringsFile(@SerialName("schema_version") val schemaVersion: String, val strings: List<UiText>)

@Serializable
data class IndexFile(
    @SerialName("schema_version") val schemaVersion: String,
    @SerialName("content_version") val contentVersion: Int,
    val heroes: List<String>,
)

@Serializable
data class HeroInfo(
    val id: String,
    val name: Text,
    @SerialName("timeline_order") val timelineOrder: Int,
    val place: Text,
)

@Serializable
data class Beat(
    val id: String,
    val type: String,
    val buttons: List<String>,
    val title: Text,
    val scene: List<Text>,
    /** Optional only for a dialogue beat (schema 1.4). */
    val goal: Text? = null,
    @SerialName("uses_banner") val usesBanner: Boolean = false,
    val params: JsonObject,
    val theme: String,
    /** Schema 1.5 (TASK-020 W21): false = no cheer at beat_end, a page-turn instead. Default true. */
    val cheer: Boolean = true,
)

@Serializable
data class FightParams(
    val enemies: List<String>,
    @SerialName("max_active") val maxActive: Int,
    @SerialName("from_left") val fromLeft: List<Int>,
)

@Serializable
data class Ending(val lines: List<Text>, @SerialName("picture_id") val pictureId: String)

@Serializable
data class MissionFile(
    @SerialName("schema_version") val schemaVersion: String,
    val hero: HeroInfo,
    @SerialName("next_hero") val nextHero: String?,
    val intro: List<Text>,
    val banner: Text? = null,
    val beats: List<Beat>,
    val ending: Ending,
)

@Serializable
data class Choice(val text: Text, @SerialName("picture_id") val pictureId: String)

@Serializable
data class Question(
    val id: String,
    val prompt: Text,
    @SerialName("picture_id") val pictureId: String? = null,
    val choices: List<Choice>,
    @SerialName("correct_index") val correctIndex: Int,
    val why: Text,
)

@Serializable
data class QuizFile(
    @SerialName("schema_version") val schemaVersion: String,
    @SerialName("hero_id") val heroId: String,
    val questions: List<Question>,
)

@Serializable
data class Signoff(val status: String, val by: String? = null, val date: String? = null)

@Serializable
data class Relabel(val to: String, @SerialName("when") val whenText: String)

@Serializable
data class Claim(
    val id: String,
    val vi: String,
    val en: String,
    val label: String,
    val sources: List<String>,
    @SerialName("relabel_condition") val relabelCondition: Relabel? = null,
    val signoff: Signoff,
)

@Serializable
data class ClaimsFile(
    @SerialName("schema_version") val schemaVersion: String,
    @SerialName("hero_id") val heroId: String,
    val claims: List<Claim>,
)

@Serializable
data class Threshold(val stars: Int, @SerialName("max_retries") val maxRetries: Int?)

@Serializable
data class QuizStars(
    @SerialName("retries_counted") val retriesCounted: String,
    val thresholds: List<Threshold>,
    @SerialName("finishing_unlocks_next_hero") val finishingUnlocksNextHero: Boolean,
)

@Serializable
data class TextLimits(
    @SerialName("max_chars") val maxChars: Int,
    @SerialName("en_budget") val enBudget: Map<String, Int>,
    /** R8b (D-21): VI characters per field type; null on a rules.json from before TASK-005h. */
    @SerialName("vi_budget") val viBudget: Map<String, Int>? = null,
    /** R8c (D-21): box and font per field type for the line-fit check. */
    val fit: TextFit? = null,
    /** R8d (rules 1.2, Language Rule 6): the minimum font_px per size class; null on rules 1.1. */
    @SerialName("min_px") val minPx: Map<String, Int>? = null,
)

@Serializable
data class FitField(
    @SerialName("box_width") val boxWidth: Int,
    @SerialName("font_px") val fontPx: Int,
    @SerialName("max_lines") val maxLines: Int,
    val weight: Int,
    /** R8d (rules 1.2): the field's size class (heading, body, button, label); null on rules 1.1. */
    @SerialName("class") val sizeClass: String? = null,
)

@Serializable
data class TextFit(val allowance: Double, val metrics: String, val fields: Map<String, FitField>)

/** content/metrics/nunito-advances.json: advance per code point (hex) at each rendered weight, per 1000 em. */
@Serializable
data class AdvanceTable(
    @SerialName("units_per_em") val unitsPerEm: Int,
    val source: String,
    val weights: Map<String, Map<String, Int>>,
)

@Serializable
data class RulesFile(
    @SerialName("schema_version") val schemaVersion: String,
    @SerialName("quiz_stars") val quizStars: QuizStars,
    @SerialName("text_limits") val textLimits: TextLimits,
)

@Serializable
data class TuningValue(val value: Double, val min: Double, val max: Double, val unit: String)

@Serializable
data class World(val width: Int, val height: Int)

@Serializable
data class TuningFile(
    @SerialName("schema_version") val schemaVersion: String,
    val world: World,
    val seed: Long,
    val values: Map<String, TuningValue>,
)

@Serializable
data class Asset(val id: String, val kind: String, val file: String, val bytes: Long, val width: Int? = null, val height: Int? = null)

@Serializable
data class AssetsFile(@SerialName("schema_version") val schemaVersion: String, val assets: List<Asset>)

@Serializable
data class MarkerSet(val vi: List<String>, val en: List<String>)

@Serializable
data class MarkersFile(
    @SerialName("schema_version") val schemaVersion: String,
    val legend: MarkerSet,
    @SerialName("fact_as_recorded") val factAsRecorded: MarkerSet,
)

@Serializable
data class Source(val id: String, val citation: String, val kind: String, val location: String, val status: String)

@Serializable
data class SourcesFile(@SerialName("schema_version") val schemaVersion: String, val sources: List<Source>)

@Serializable
data class SkyBand(val top: String, val bottom: String)

@Serializable
data class Theme(@SerialName("sky_band") val skyBand: SkyBand)

/** themes.json (ADR-0002 follow-up): per-theme sky band behind the background tiles. */
@Serializable
data class ThemesFile(@SerialName("schema_version") val schemaVersion: String, val themes: Map<String, Theme>)

/** A dialogue beat's params (schema 1.4, TASK-016). */
@Serializable
data class DialogueLine(val speaker: String, val mood: String? = null, val text: Text)

@Serializable
data class DialogueAsk(val button: Text, val taps: Int, @SerialName("at_line") val atLine: Int)

@Serializable
data class DialogueParams(val lines: List<DialogueLine>, val ask: DialogueAsk? = null) {
    /** "ask" while at_line ≤ L < at_line + taps (L 1-based), else "tiep" (R13d semantics). */
    fun buttonOn(line1: Int): String = if (ask != null && line1 >= ask.atLine && line1 < ask.atLine + ask.taps) "ask" else "tiep"
}
