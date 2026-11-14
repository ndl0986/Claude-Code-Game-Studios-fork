package com.galaxyandsun.daidatanhhung.core

import com.galaxyandsun.daidatanhhung.core.content.Question
import com.galaxyandsun.daidatanhhung.core.content.QuizStars

/** Stars from the quiz (rules.json quiz_stars): retries summed across the whole quiz. */
object StarRule {
    fun stars(rule: QuizStars, totalRetries: Int): Int =
        rule.thresholds.sortedByDescending { it.stars }
            .first { it.maxRetries == null || totalRetries <= it.maxRetries }.stars
}

/** What a pick did (fixtures/quiz-scoring.json). */
enum class PickResult { RIGHT, WRONG, IGNORED }

/** The card order of one question (P-05, Quiz GDD rule 3, fixtures/quiz-shuffle.json). */
object Shuffle {
    /** order[k] = the original choice index shown in slot k. Its own RNG per question, never the play stream. */
    fun order(seed: Long, questionIndex: Int, n: Int): List<Int> {
        val rng = Mulberry32(seed + questionIndex)
        val o = MutableList(n) { it }
        for (i in n - 1 downTo 1) {
            val j = kotlin.math.floor(rng.next() * (i + 1)).toInt()
            val t = o[i]; o[i] = o[j]; o[j] = t
        }
        return o
    }
}

/**
 * One quiz run (Quiz & stars GDD, P-05 for the slice):
 * - a wrong pick shakes for [shakeTime] (card taps are ignored meanwhile), greys that card and keeps
 *   the question; a repeat tap on a greyed card is ignored and doesn't count (D-11a);
 * - the right pick shows `why`; after [feedbackTime] the Next button may advance ([canAdvance]),
 *   and nothing advances until it is tapped.
 * Picks use the original choice index; [order] maps screen slots to choices.
 */
class QuizSession(
    val questions: List<Question>,
    private val feedbackTime: Double,
    private val seed: Long = 1,
    private val shakeTime: Double = 0.5,
) {
    var index = 0; private set
    var retries = 0; private set
    /** The right choice while its `why` shows, else -1. */
    var rightShown = -1; private set
    var rightT = 0.0; private set
    val wrongPicked = mutableSetOf<Int>()
    var lastWrong = -1; private set
    var shakeT = 0.0; private set
    var finished = false; private set
    var order: List<Int> = Shuffle.order(seed, 0, questions.firstOrNull()?.choices?.size ?: 0); private set

    val current: Question get() = questions[index.coerceAtMost(questions.size - 1)]
    val canAdvance get() = rightShown >= 0 && rightT >= feedbackTime

    fun pick(choice: Int): PickResult {
        if (finished || rightShown >= 0 || shakeT > 0 || choice in wrongPicked) return PickResult.IGNORED
        return if (choice == current.correctIndex) {
            rightShown = choice; rightT = 0.0; PickResult.RIGHT
        } else {
            wrongPicked += choice; lastWrong = choice; retries++; shakeT = shakeTime; PickResult.WRONG
        }
    }

    fun update(dt: Double) {
        shakeT = maxOf(0.0, shakeT - dt)
        if (rightShown >= 0) rightT += dt
    }

    /** Next after `why`. Returns true when that was the last question. */
    fun advance(): Boolean {
        if (!canAdvance) return false
        index++; rightShown = -1; rightT = 0.0; wrongPicked.clear(); lastWrong = -1; shakeT = 0.0
        if (index >= questions.size) { finished = true; return true }
        order = Shuffle.order(seed, index, current.choices.size)
        return false
    }

    companion object {
        /** quiz_count limited to 3..5 and to the questions available; the first N in file order. */
        fun count(quizCount: Int, available: Int): Int = minOf(available, quizCount.coerceIn(3, 5))
    }
}
