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

/**
 * One quiz run: a wrong pick greys that card and keeps the question; a repeat tap on a greyed
 * card is ignored and doesn't count (D-11a), so retries per question are at most 2 and the quiz
 * always ends. The right pick shows `why`, then the next question after feedback_time.
 */
class QuizSession(val questions: List<Question>, private val feedbackTime: Double) {
    var index = 0; private set
    var retries = 0; private set
    /** The right card while its feedback shows, else -1. */
    var rightShown = -1; private set
    private var feedbackT = 0.0
    val wrongPicked = mutableSetOf<Int>()
    var lastWrong = -1; private set
    var finished = false; private set

    val current: Question get() = questions[index.coerceAtMost(questions.size - 1)]

    fun pick(choice: Int): PickResult {
        if (finished || rightShown >= 0 || choice in wrongPicked) return PickResult.IGNORED
        return if (choice == current.correctIndex) {
            rightShown = choice; feedbackT = 0.0; PickResult.RIGHT
        } else {
            wrongPicked += choice; lastWrong = choice; retries++; PickResult.WRONG
        }
    }

    /** Advances the feedback timer; returns true on the step the quiz finishes. */
    fun update(dt: Double): Boolean {
        if (finished || rightShown < 0) return false
        feedbackT += dt
        if (feedbackT >= feedbackTime) {
            index++; rightShown = -1; wrongPicked.clear(); lastWrong = -1
            if (index >= questions.size) { finished = true; return true }
        }
        return false
    }

    companion object {
        /** quiz_count limited to 3..5 and to the questions available; the first N in file order. */
        fun count(quizCount: Int, available: Int): Int = minOf(available, quizCount.coerceIn(3, 5))
    }
}
