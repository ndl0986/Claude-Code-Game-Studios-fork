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
    val SENTENCE_FIELDS = setOf("intro", "scene", "ending", "quiz_prompt", "quiz_why", "dialogue_line", "dialogue_narrator")

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

    /** R8 budget type of a strings.json entry: its `field` if set (D-21), else the id-suffix rule (TASK-005e). */
    fun uiFieldType(u: UiText): String = u.field ?: uiFieldType(u.id)

    /** R8 budget type of a strings.json id (content/README.md R8, TASK-005e). */
    fun uiFieldType(id: String): String = when {
        id.startsWith("ui.btn.") || id.startsWith("ui.pad.") || id.startsWith("ui.lang.") ||
            id.endsWith("_confirm") || id.endsWith("_keep_reading") || id.endsWith(".keep_reading") -> "button"
        id.endsWith("_warning") -> "dialog"
        else -> "ui"
    }

    /** R17 / R18: a hero's place on the timeline (Hero progression GDD Rules 1 and 6). id → (timeline_order, next_hero). */
    fun timeline(heroes: List<Triple<String, Int, String?>>): List<String> {
        val out = mutableListOf<String>()
        heroes.groupBy { it.second }.filter { it.value.size > 1 }.forEach { (o, hs) -> out += "R17 timeline_order $o shared by ${hs.map { it.first }}" }
        val sorted = heroes.sortedBy { it.second }
        sorted.forEachIndexed { i, h ->
            val expected = sorted.getOrNull(i + 1)?.first
            if (h.third != expected) out += "R18 ${h.first}: next_hero ${h.third} should be $expected"
        }
        return out
    }

    /** R19a (error): the declared picture size matches the file's header. */
    fun sizeMatches(id: String, declared: Pair<Int, Int>, actual: Pair<Int, Int>?): List<String> =
        if (actual == null) listOf("R19a $id: can't read the image header")
        else if (declared != actual) listOf("R19a $id: declared ${declared.first}×${declared.second}, file is ${actual.first}×${actual.second}")
        else emptyList()

    /** R19b (warning until ADR-0002 is measured): ≤ 2048, quiz pictures ≤ 512², scene tiles ≤ 1440×1320. */
    fun sizeLimits(id: String, w: Int, h: Int): List<String> {
        val out = mutableListOf<String>()
        if (w > 2048 || h > 2048) out += "R19b $id: $w×$h is over 2048"
        if (id.startsWith("pic.quiz_") && (w > 512 || h > 512)) out += "R19b $id: quiz picture $w×$h is over 512×512"
        if (id.startsWith("pic.scene_") && (w > 1440 || h > 1320)) out += "R19b $id: scene tile $w×$h is over 1440×1320"
        return out
    }

    /** The mission schema's theme enum. */
    val THEMES = setOf("village", "bamboo", "river", "camp")

    /** R20: every theme a beat uses is in the enum and has a sky band. */
    fun themesCovered(themes: Set<String>, beatThemes: List<String>): List<String> =
        beatThemes.distinct().flatMap { t ->
            listOfNotNull(if (t !in THEMES) "R20 theme $t is not in the mission enum" else null,
                if (t !in themes) "R20 theme $t has no sky band in themes.json" else null)
        }

    /** A PNG or WebP's pixel size from its header bytes (null if neither). */
    fun imageSize(b: ByteArray): Pair<Int, Int>? {
        fun u(i: Int) = b[i].toInt() and 0xFF
        if (b.size >= 24 && u(0) == 0x89 && b[1] == 'P'.code.toByte()) // PNG IHDR
            return ((u(16) shl 24) or (u(17) shl 16) or (u(18) shl 8) or u(19)) to ((u(20) shl 24) or (u(21) shl 16) or (u(22) shl 8) or u(23))
        if (b.size >= 30 && String(b, 0, 4) == "RIFF" && String(b, 8, 4) == "WEBP") {
            return when (String(b, 12, 4)) {
                "VP8 " -> ((u(26) or (u(27) shl 8)) and 0x3FFF) to ((u(28) or (u(29) shl 8)) and 0x3FFF)
                "VP8L" -> { val v = u(21) or (u(22) shl 8) or (u(23) shl 16) or (u(24) shl 24); ((v and 0x3FFF) + 1) to (((v shr 14) and 0x3FFF) + 1) }
                "VP8X" -> (1 + (u(24) or (u(25) shl 8) or (u(26) shl 16))) to (1 + (u(27) or (u(28) shl 8) or (u(29) shl 16)))
                else -> null
            }
        }
        return null
    }

    /** R19a over the bundle's pictures, given a way to read a file under content/data. */
    fun pictureSizes(c: Content, bytes: (String) -> ByteArray?): List<String> =
        c.assets.assets.filter { it.kind == "picture" }.flatMap { a ->
            if (a.width == null || a.height == null) listOf("R19a ${a.id}: no width/height (assets.json 1.2)")
            else sizeMatches(a.id, a.width to a.height, bytes(a.file)?.let(::imageSize))
        }

    /** Warnings that never fail a build (R15, R19b, R21). */
    fun warnings(c: Content): List<String> =
        telegraphWarnings(c.tuning.values.mapValues { it.value.value }) +
            c.heroes.values.flatMap { h -> h.mission.beats.flatMap { cheerOnFight(it.id, it.type, it.cheer) } } +
            c.assets.assets.filter { it.kind == "picture" && it.width != null && it.height != null }.flatMap { sizeLimits(it.id, it.width!!, it.height!!) }

    /** R8b (D-21): VI fits `vi_budget` for its field type (skipped on rules.json without vi_budget). */
    fun viBudget(id: String, fieldType: String, vi: String, limits: TextLimits): List<String> {
        val b = limits.viBudget?.get(fieldType) ?: return emptyList()
        return if (vi.length > b) listOf("R8b $id: VI ${vi.length} > $fieldType budget $b") else emptyList()
    }

    /** R8c (D-21): VI and EN each fit their field's box in max_lines, measured with the real advances. */
    fun lineFit(id: String, fieldType: String, vi: String, en: String, limits: TextLimits, fit: LineFit?): List<String> {
        val f = limits.fit ?: return emptyList(); val lf = fit ?: return emptyList()
        val field = f.fields[fieldType] ?: return listOf("R8c $id: no fit entry for $fieldType")
        return listOf("vi" to vi, "en" to en).mapNotNull { (lang, s) ->
            val r = lf.lines(s, field, f.allowance)
            if (r.fails) "R8c $id: $lang takes ${r.lines} line(s) of ${field.boxWidth}px at ${field.fontPx}px (max ${field.maxLines})" else null
        }
    }

    /** R8c over the whole bundle (UI strings and every story Text). */
    fun lineFits(c: Content, fit: LineFit): List<String> {
        val l = c.rules.textLimits
        return c.strings.strings.flatMap { lineFit(it.id, uiFieldType(it), it.vi, it.en, l, fit) } +
            c.heroes.values.flatMap { h -> texts(h).flatMap { (type, t) -> lineFit(t.id, type, t.vi, t.en, l, fit) } }
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
            "reach-the-flag" -> { need += "move"; if (encounters.isNotEmpty()) need += "attack" } // D-10 B: no special
            "dialogue" -> if (b.isNotEmpty()) return listOf("R13 ${beat.id}: a dialogue beat has no buttons")
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

    /** R13d: a dialogue's ask ends on or before its last line. */
    fun askFits(lines: Int, taps: Int, atLine: Int): List<String> =
        if (atLine + taps > lines) listOf("R13d ask at_line $atLine + taps $taps > $lines lines") else emptyList()

    /** R4c: claims covered by a dialogue's first line (a narrator line marked in VI and EN), else empty. */
    fun dialogueCovered(lines: List<DialogueLine>, markers: MarkersFile): Set<String> {
        val first = lines.firstOrNull() ?: return emptySet()
        return if (first.speaker == "narrator" && marked(first.text, markers)) first.text.claims.toSet() else emptySet()
    }

    /** R4 for a dialogue's lines and ask button with R4c's cover. */
    fun dialogueLegend(lines: List<DialogueLine>, ask: Text?, labels: Map<String, String>, markers: MarkersFile): List<String> {
        val cover = dialogueCovered(lines, markers)
        return (lines.map { it.text } + listOfNotNull(ask)).flatMap { t ->
            if (t.claims.filter { labels[it] == "legend" }.all { it in cover }) emptyList() else legendMarker(t, labels, markers)
        }
    }

    /**
     * R8d (rules 1.2, Language Rule 6): every fit field has a known size class, and its font_px is at
     * least that class's minimum. Skipped on a rules.json without `min_px` (1.1).
     */
    fun sizeClasses(fields: Map<String, FitField>, minPx: Map<String, Int>?): List<String> {
        if (minPx == null) return emptyList()
        return fields.flatMap { (name, f) ->
            val cls = f.sizeClass
            when {
                cls == null -> listOf("R8d $name: no size class")
                cls !in minPx -> listOf("R8d $name: unknown size class $cls")
                f.fontPx < minPx.getValue(cls) -> listOf("R8d $name: font_px ${f.fontPx} < $cls minimum ${minPx.getValue(cls)}")
                else -> emptyList()
            }
        }
    }

    /**
     * R14b (Combat Rule 15b): a training beat's last dummy lies inside the capped training zone:
     * dummies × dummy_spacing ≤ W − enemy_reach − 2 × hero_edge_margin (error).
     */
    fun trainingFits(id: String, dummies: Int, worldWidth: Int, v: Map<String, Double>): List<String> {
        val room = worldWidth - (v["enemy_reach"] ?: 0.0) - 2 * (v["hero_edge_margin"] ?: 0.0)
        val need = dummies * (v["dummy_spacing"] ?: 0.0)
        return if (need > room) listOf("R14b $id: $dummies dummies × ${v["dummy_spacing"]} = $need > training zone $room") else emptyList()
    }

    /** R21 (schema 1.5): `cheer: false` on a fight beat is ignored at run time (fights end on their caption); a warning. */
    fun cheerOnFight(id: String, type: String, cheer: Boolean): List<String> =
        if (type == "fight" && !cheer) listOf("R21 $id: cheer false on a fight beat is ignored") else emptyList()

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
            out += "beat_title" to b.title; b.goal?.let { out += "goal" to it }
            b.scene.forEach { out += "scene" to it }
            ContentLoader.dialogueParams(b)?.let { d ->
                d.lines.forEach { out += (if (it.speaker == "narrator") "dialogue_narrator" else "dialogue_line") to it.text }
                d.ask?.let { out += "button" to it.button }
            }
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
            out += enBudget(s.id, uiFieldType(s), s.en, s.vi, c.rules.textLimits)
            out += viBudget(s.id, uiFieldType(s), s.vi, c.rules.textLimits)
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
            val dialogues = m.beats.mapNotNull { ContentLoader.dialogueParams(it) }
            val missionSentences = m.intro + m.beats.flatMap { it.scene } + m.ending.lines + dialogues.flatMap { d -> d.lines.map { it.text } }
            val dialogueIds = dialogues.flatMap { d -> d.lines.map { it.text.id } + listOfNotNull(d.ask?.button?.id) }.toSet()
            for (d in dialogues) {
                out += dialogueLegend(d.lines, d.ask?.button, labels, c.markers)
                d.ask?.let { out += askFits(d.lines.size, it.taps, it.atLine) }
            }
            val choiceScope = hero.quiz.questions.flatMap { q -> q.choices.map { it.text.id to listOf(q.prompt, q.why) } }.toMap()
            for ((type, t) in texts(hero)) {
                allIds += t.id
                out += nfc(t.id, t.vi, t.en)
                out += enBudget(t.id, type, t.en, t.vi, c.rules.textLimits)
                out += viBudget(t.id, type, t.vi, c.rules.textLimits)
                if (t.id !in dialogueIds) out += legend(type, t, labels, c.markers, choiceScope[t.id] ?: missionSentences) // dialogue: R4c above
                t.claims.filterNot { it in claims }.forEach { out += "R2 ${t.id}: unknown claim $it" }
            }
            out += quizInvented(quizTexts(hero).flatMap { it.claims }.distinct(), labels)
            val next = hero.mission.nextHero
            if (hero.mission.hero.id != heroId) out += "R2 heroes/$heroId: mission hero id is ${hero.mission.hero.id}"
            if (checkPictures) {
                // R10: dialogue portraits pic.portrait_<hero_id>_<speaker>[_<mood>] (a missing mood fails)
                dialogues.flatMap { it.lines }.filter { it.speaker != "narrator" }.forEach { l ->
                    out += pictureResolves("pic.portrait_${heroId}_${l.speaker}" + (l.mood?.let { "_$it" } ?: ""), assetIds) }
                val pics = listOf(hero.mission.ending.pictureId) +
                    hero.quiz.questions.flatMap { q -> listOfNotNull(q.pictureId) + q.choices.map { it.pictureId } }
                pics.forEach { out += pictureResolves(it, assetIds) }
            }
            for (q in hero.quiz.questions) if (q.correctIndex !in q.choices.indices) out += "R2 ${q.id}: correct_index out of range"
            if (next != null && next.isBlank()) out += "R2 heroes/$heroId: blank next_hero"
        }
        for (hero in c.heroes.values) for (b in hero.mission.beats) out += beatButtons(b)
        // R17/R18 over the indexed heroes only (samples are excluded).
        out += timeline(c.heroes.filterKeys { it in c.index.heroes }.values.map { Triple(it.mission.hero.id, it.mission.hero.timelineOrder, it.mission.nextHero) })
        val tv = c.tuning.values.mapValues { it.value.value }
        out += attackReaches(tv)
        for (hero in c.heroes.values) for (b in hero.mission.beats) if (b.type == "training")
            out += trainingFits(b.id, (b.params["dummies"] as? kotlinx.serialization.json.JsonPrimitive)?.content?.toIntOrNull() ?: 0, c.tuning.world.width, tv)
        c.rules.textLimits.fit?.let { out += sizeClasses(it.fields, c.rules.textLimits.minPx) }
        out += starThresholds(c.rules.quizStars.thresholds)
        c.themes?.let { th -> out += themesCovered(th.themes.keys, c.heroes.values.flatMap { h -> h.mission.beats.map { it.theme } }) }
        out += duplicateIds(allIds)
        return out
    }
}
