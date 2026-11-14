package com.galaxyandsun.daidatanhhung.core.content

import java.text.Normalizer

/**
 * The cross-file rules of content/README.md "Validation rules" that JSON Schema cannot express.
 * Each returns the problems found (empty = valid). The unit tests run them over data/ and samples/,
 * and the shared fixtures/validity.json cases.
 */
object Validator {
    /** The schema MAJOR.MINOR this app understands. */
    const val SUPPORTED_SCHEMA = "1.1"

    /** R4: a Text citing a legend claim carries a legend marker in VI and in EN. */
    fun legendMarker(text: Text, labels: Map<String, String>, markers: MarkersFile): List<String> {
        if (text.claims.none { labels[it] == "legend" }) return emptyList()
        val out = mutableListOf<String>()
        if (markers.legend.vi.none { text.vi.contains(it) }) out += "R4 ${text.id}: VI has no legend marker"
        if (markers.legend.en.none { text.en.contains(it) }) out += "R4 ${text.id}: EN has no legend marker"
        return out
    }

    /** Sentence fields carry legend markers themselves (R4); label fields may lean on a marked sentence (R4b). */
    val SENTENCE_FIELDS = setOf("intro", "scene", "ending", "quiz_prompt", "quiz_why")

    /** R4's test: a legend marker in VI and in EN. */
    fun marked(t: Text, markers: MarkersFile) = markers.legend.vi.any { t.vi.contains(it) } && markers.legend.en.any { t.en.contains(it) }

    /**
     * R4b (D-12): a label citing a legend claim is fine when, for each such claim, a marked sentence
     * in its scope cites the same claim.
     */
    fun legendLabel(label: Text, labels: Map<String, String>, markers: MarkersFile, scope: List<Text>): List<String> =
        label.claims.filter { labels[it] == "legend" }
            .filterNot { c -> scope.any { s -> c in s.claims && marked(s, markers) } }
            .map { "R4b ${label.id}: legend claim $it has no marked sentence in scope" }

    /** R4 or R4b for one Text of [field] type. */
    fun legend(field: String, t: Text, labels: Map<String, String>, markers: MarkersFile, scope: List<Text>): List<String> =
        if (field in SENTENCE_FIELDS) legendMarker(t, labels, markers) else legendLabel(t, labels, markers, scope)

    /** R5: a fact / fact_as_recorded claim can't be approved while a source is to_confirm; R5b: only invented may have no sources. */
    fun claimSources(claim: Claim, sourceStatus: Map<String, String>): List<String> {
        val out = mutableListOf<String>()
        if (claim.label in setOf("fact", "fact_as_recorded") && claim.signoff.status == "approved" &&
            claim.sources.any { sourceStatus[it] != "confirmed" }) out += "R5 ${claim.id}: approved with an unconfirmed source"
        if (claim.sources.isEmpty() && claim.label != "invented") out += "R5b ${claim.id}: no sources"
        return out
    }

    /** R6: quiz text never cites an invented claim. */
    fun quizInvented(quizClaims: List<String>, labels: Map<String, String>): List<String> =
        quizClaims.filter { labels[it] == "invented" }.map { "R6 quiz cites invented claim $it" }

    /** R7: Unicode NFC. */
    fun isNfc(s: String): Boolean = Normalizer.isNormalized(s, Normalizer.Form.NFC)

    fun nfc(id: String, vararg lines: String): List<String> =
        if (lines.all(::isNfc)) emptyList() else listOf("R7 $id: not NFC")

    /** R8: line length and the EN budget for its field type. */
    fun enBudget(id: String, fieldType: String, en: String, vi: String?, limits: TextLimits): List<String> {
        val out = mutableListOf<String>()
        if (en.length > limits.maxChars || (vi != null && vi.length > limits.maxChars)) out += "R8 $id: over ${limits.maxChars} chars"
        val budget = limits.enBudget[fieldType] ?: return out + "R8 $id: unknown field type $fieldType"
        if (en.length > budget) out += "R8 $id: EN ${en.length} > $fieldType budget $budget"
        return out
    }

    /** R9: Text ids are unique. */
    fun duplicateIds(ids: List<String>): List<String> =
        ids.groupingBy { it }.eachCount().filter { it.value > 1 }.keys.map { "R9 duplicate id $it" }

    /** R10: a picture id resolves in assets.json. */
    fun pictureResolves(id: String, assetIds: Set<String>): List<String> =
        if (id in assetIds) emptyList() else listOf("R10 unknown picture id $id")

    /** R11: a newer MAJOR fails the build; a newer MINOR is fine. */
    fun schemaCompatible(appSupports: String, fileVersion: String): Boolean =
        fileVersion.substringBefore('.').toInt() <= appSupports.substringBefore('.').toInt()

    /** R13 / R13b: buttons per beat type, and reach-the-flag encounter order (schema 1.1, D-06). */
    fun beatButtons(beat: Beat): List<String> {
        val b = beat.buttons.toSet(); val p = beat.params
        fun int(k: String) = (p[k] as? kotlinx.serialization.json.JsonPrimitive)?.content?.toDoubleOrNull()
        fun bool(k: String) = (p[k] as? kotlinx.serialization.json.JsonPrimitive)?.content == "true"
        val encounters = (p["encounters"] as? kotlinx.serialization.json.JsonArray).orEmpty()
        val need = mutableSetOf<String>(); var specialOk = false
        when (beat.type) {
            "walk" -> need += "move"
            "hold-meter" -> { need += "special"; specialOk = true }
            "fight" -> need += listOf("move", "attack")
            "training" -> { need += listOf("move", "attack"); if ((int("blocks") ?: 0.0) > 0) need += "defend"
                if (bool("finish_special")) { need += "special"; specialOk = true } }
            "reach-the-flag" -> { need += "move"; if (encounters.isNotEmpty()) need += "attack"; specialOk = true }
        }
        val out = mutableListOf<String>()
        (need - b).forEach { out += "R13 ${beat.id}: ${beat.type} needs $it" }
        if ("special" in b && !specialOk) out += "R13 ${beat.id}: special not allowed on ${beat.type}"
        if (beat.type == "reach-the-flag") {
            val len = int("length_screens") ?: 0.0
            val at = encounters.map { ((it as kotlinx.serialization.json.JsonObject)["at_screen"] as kotlinx.serialization.json.JsonPrimitive).content.toDouble() }
            if (at.zipWithNext().any { (a, c) -> c <= a }) out += "R13b ${beat.id}: encounters not strictly ascending"
            if (at.any { it <= 0 || it >= len }) out += "R13b ${beat.id}: at_screen outside (0, length_screens)"
        }
        return out
    }

    /** R14: the attack reaches the enemy standing in front (error). */
    fun attackReaches(v: Map<String, Double>): List<String> {
        val need = (v["enemy_reach"] ?: 0.0) - (v["stand_gap"] ?: 0.0)
        return if ((v["attack_range"] ?: 0.0) < need) listOf("R14 attack_range ${v["attack_range"]} < enemy_reach - stand_gap $need") else emptyList()
    }

    /** R15: a telegraph under 0.8 s is a warning (returned separately, never fails a build). */
    fun telegraphWarnings(v: Map<String, Double>): List<String> =
        if ((v["telegraph"] ?: 1.0) < 0.8) listOf("R15 warning: telegraph ${v["telegraph"]} s < 0.8 s") else emptyList()

    /** R16: a lower star never allows fewer retries than a higher one (null = no limit). */
    fun starThresholds(t: List<Threshold>): List<String> {
        val sorted = t.sortedByDescending { it.stars }
        return sorted.zipWithNext().filter { (hi, lo) -> lo.maxRetries != null && (hi.maxRetries == null || lo.maxRetries < hi.maxRetries) }
            .map { (hi, lo) -> "R16 ${lo.stars}★ max_retries ${lo.maxRetries} < ${hi.stars}★ ${hi.maxRetries}" }
    }

    /** Every Text in one hero's bundle, paired with its R8 field type. */
    fun texts(hero: HeroBundle): List<Pair<String, Text>> {
        val m = hero.mission
        val out = mutableListOf("hero_name" to m.hero.name, "place" to m.hero.place)
        m.intro.forEach { out += "intro" to it }
        m.banner?.let { out += "banner" to it }
        for (b in m.beats) {
            out += "beat_title" to b.title; out += "goal" to b.goal
            b.scene.forEach { out += "scene" to it }
        }
        m.ending.lines.forEach { out += "ending" to it }
        for (q in hero.quiz.questions) {
            out += "quiz_prompt" to q.prompt; out += "quiz_why" to q.why
            q.choices.forEach { out += "quiz_choice" to it.text }
        }
        return out
    }

    /** Quiz Text only (R6). */
    fun quizTexts(hero: HeroBundle): List<Text> =
        hero.quiz.questions.flatMap { q -> listOf(q.prompt, q.why) + q.choices.map { it.text } }

    /**
     * Runs R2 and R4–R11 over the whole bundle. [checkPictures] is false for samples/ in debug
     * builds, whose pictures are drawn in code (parity item 5).
     */
    fun validate(c: Content, checkPictures: Boolean = true): List<String> {
        val out = mutableListOf<String>()
        val sourceStatus = c.sources.sources.associate { it.id to it.status }
        val assetIds = c.assets.assets.map { it.id }.toSet()
        val versions = listOf(c.index.schemaVersion, c.strings.schemaVersion, c.rules.schemaVersion,
            c.tuning.schemaVersion, c.assets.schemaVersion, c.markers.schemaVersion, c.sources.schemaVersion) +
            c.heroes.values.flatMap { listOf(it.mission.schemaVersion, it.quiz.schemaVersion, it.claims.schemaVersion) }
        versions.filterNot { schemaCompatible(SUPPORTED_SCHEMA, it) }.forEach { out += "R11 schema_version $it is newer than $SUPPORTED_SCHEMA" }
        val allIds = mutableListOf<String>()
        for (s in c.strings.strings) {
            out += nfc(s.id, s.vi, s.en); allIds += s.id
            out += enBudget(s.id, if (s.id.startsWith("ui.btn.") || s.id.startsWith("ui.pad.") || s.id.startsWith("ui.lang.")) "button" else "ui", s.en, s.vi, c.rules.textLimits)
        }
        for ((heroId, hero) in c.heroes) {
            val claims = hero.claims.claims.associateBy { it.id }
            val labels = claims.mapValues { it.value.label }
            for (claim in hero.claims.claims) {
                out += claimSources(claim, sourceStatus)
                out += nfc(claim.id, claim.vi, claim.en)
                claim.sources.filterNot { it in sourceStatus }.forEach { out += "R2 ${claim.id}: unknown source $it" }
            }
            val m = hero.mission
            val missionSentences = m.intro + m.beats.flatMap { it.scene } + m.ending.lines
            val choiceScope = hero.quiz.questions.flatMap { q -> q.choices.map { it.text.id to listOf(q.prompt, q.why) } }.toMap()
            for ((type, t) in texts(hero)) {
                allIds += t.id
                out += nfc(t.id, t.vi, t.en)
                out += enBudget(t.id, type, t.en, t.vi, c.rules.textLimits)
                out += legend(type, t, labels, c.markers, choiceScope[t.id] ?: missionSentences)
                t.claims.filterNot { it in claims }.forEach { out += "R2 ${t.id}: unknown claim $it" }
            }
            out += quizInvented(quizTexts(hero).flatMap { it.claims }.distinct(), labels)
            val next = hero.mission.nextHero
            if (hero.mission.hero.id != heroId) out += "R2 heroes/$heroId: mission hero id is ${hero.mission.hero.id}"
            if (checkPictures) {
                val pics = listOf(hero.mission.ending.pictureId) +
                    hero.quiz.questions.flatMap { q -> listOfNotNull(q.pictureId) + q.choices.map { it.pictureId } }
                pics.forEach { out += pictureResolves(it, assetIds) }
            }
            for (q in hero.quiz.questions) if (q.correctIndex !in q.choices.indices) out += "R2 ${q.id}: correct_index out of range"
            if (next != null && next.isBlank()) out += "R2 heroes/$heroId: blank next_hero"
        }
        for (hero in c.heroes.values) for (b in hero.mission.beats) out += beatButtons(b)
        out += attackReaches(c.tuning.values.mapValues { it.value.value })
        out += starThresholds(c.rules.quizStars.thresholds)
        out += duplicateIds(allIds)
        return out
    }
}
