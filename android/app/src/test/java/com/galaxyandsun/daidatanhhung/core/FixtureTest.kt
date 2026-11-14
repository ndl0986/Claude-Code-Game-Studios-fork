package com.galaxyandsun.daidatanhhung.core

import com.galaxyandsun.daidatanhhung.core.content.ContentLoader
import com.galaxyandsun.daidatanhhung.core.content.Question
import com.galaxyandsun.daidatanhhung.core.content.Choice
import com.galaxyandsun.daidatanhhung.core.content.Text
import com.galaxyandsun.daidatanhhung.core.content.Validator
import com.galaxyandsun.daidatanhhung.core.content.Claim
import com.galaxyandsun.daidatanhhung.core.content.Signoff
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.decodeFromJsonElement
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Runs every case of the shared fixtures (content/fixtures), the same files the iOS tests run. */
class FixtureTest {
    private val content = TestContent.load()
    private fun cases(name: String) = TestContent.fixture(name)["cases"]!!.jsonArray.map { it.jsonObject }
    private fun ints(o: JsonObject, k: String) = o[k]!!.jsonArray.map { it.jsonPrimitive.int }

    @Test fun quizStars() {
        for (c in cases("quiz-stars.json")) {
            val wrong = ints(c, "wrong_picks_per_question")
            val exp = c["expected"]!!.jsonObject
            val total = wrong.sum()
            assertEquals(c.toString(), exp["total_retries"]!!.jsonPrimitive.int, total)
            assertEquals(c.toString(), exp["stars"]!!.jsonPrimitive.int, StarRule.stars(content.rules.quizStars, total))
            assertEquals(exp["unlocks_next_hero"]!!.jsonPrimitive.boolean, content.rules.quizStars.finishingUnlocksNextHero)
            // The same totals through a real QuizSession.
            val qs = wrong.indices.map { question(correct = 0) }
            val s = QuizSession(qs, 0.9)
            for (w in wrong) { repeat(w) { k -> assertEquals(PickResult.WRONG, s.pick(1 + k)) }; assertEquals(PickResult.RIGHT, s.pick(0)); s.update(0.9) }
            assertTrue(s.finished); assertEquals(total, s.retries)
        }
    }

    @Test fun quizScoring() {
        for (c in cases("quiz-scoring.json")) {
            val s = QuizSession(listOf(question(c["correct_index"]!!.jsonPrimitive.int)), 0.9)
            val got = ints(c, "picks").map { s.pick(it).name.lowercase() }
            assertEquals(c["name"].toString(), c["expected"]!!.jsonArray.map { it.jsonPrimitive.content }, got)
        }
    }

    @Test fun claimGate() {
        for (c in cases("claim-gate.json")) {
            val statuses = c["claims"]!!.jsonObject.mapValues { it.value.jsonPrimitive.content }
            val texts = c["text_claims"]!!.jsonArray.map { a -> a.jsonArray.map { it.jsonPrimitive.content } }
            val exp = c["expected"]!!.jsonObject
            val r = ClaimGate.evaluate(statuses, texts)
            val name = c["name"].toString()
            assertEquals(name, exp["release_build"]!!.jsonPrimitive.content, if (r.releaseBuildPasses) "pass" else "fail")
            assertEquals(name, exp["runtime_release"]!!.jsonPrimitive.content, if (r.runtimeShow) "show" else "hide_and_log")
            assertEquals(name, exp["debug_badges"]!!.jsonArray.map { it.jsonPrimitive.content }, r.debugBadges)
        }
    }

    @Test fun validity() {
        var ran = 0
        for (c in cases("validity.json")) {
            val rule = c["rule"]!!.jsonPrimitive.content
            val expected = c["expected"]!!.jsonPrimitive.content
            fun labels() = c["claims"]!!.jsonObject.mapValues { it.value.jsonObject["label"]!!.jsonPrimitive.content }
            fun text() = ContentLoader.JSON.decodeFromJsonElement<Text>(c["text"]!!)
            val problems: List<String> = when (rule) {
                "R4" -> Validator.legendMarker(text(), labels(), content.markers)
                "R5" -> {
                    val cl = c["claim"]!!.jsonObject
                    val claim = Claim(cl["id"]!!.jsonPrimitive.content, "x", "x", cl["label"]!!.jsonPrimitive.content,
                        cl["sources"]!!.jsonArray.map { it.jsonPrimitive.content }, null,
                        ContentLoader.JSON.decodeFromJsonElement<Signoff>(cl["signoff"]!!))
                    Validator.claimSources(claim, c["sources"]!!.jsonObject.mapValues { it.value.jsonPrimitive.content })
                }
                "R6" -> Validator.quizInvented(c["quiz_claims"]!!.jsonArray.map { it.jsonPrimitive.content }, labels())
                "R7" -> text().let { Validator.nfc(it.id, it.vi, it.en) }
                "R8" -> Validator.enBudget("case", c["field_type"]!!.jsonPrimitive.content, c["en"]!!.jsonPrimitive.content, null, content.rules.textLimits)
                "R9" -> Validator.duplicateIds(c["ids"]!!.jsonArray.map { it.jsonPrimitive.content })
                "R10" -> Validator.pictureResolves(c["picture_id"]!!.jsonPrimitive.content, c["asset_ids"]!!.jsonArray.map { it.jsonPrimitive.content }.toSet())
                "R11" -> if (Validator.schemaCompatible(c["app_supports"]!!.jsonPrimitive.content, c["file_version"]!!.jsonPrimitive.content)) emptyList() else listOf("R11")
                else -> { println("validity.json: rule $rule not checked by this app yet"); continue }
            }
            val got = when (rule) { "R11" -> if (problems.isEmpty()) "build_passes" else "build_fails"; else -> if (problems.isEmpty()) "valid" else "invalid" }
            assertEquals("${c["name"]} ($rule): $problems", expected, got)
            ran++
        }
        assertTrue(ran >= 10)
    }

    private fun question(correct: Int) = Question(
        "x.q", t("x.q.p"), null, (0..2).map { Choice(t("x.q.c$it"), "pic.x") }, correct, t("x.q.why"))
    private fun t(id: String) = Text(id, "v", "e", listOf("C01"))
}
