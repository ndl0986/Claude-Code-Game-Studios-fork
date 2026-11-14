package com.galaxyandsun.daidatanhhung.core

/** Every strings.json id the slice shows (content tests check each exists). */
object UiIds {
    const val TITLE = "ui.app.title"
    const val SUBTITLE_DEBUG = "ui.debug.subtitle" // ui.debug.*: debug builds only
    const val START = "ui.btn.start"
    const val NEXT = "ui.btn.next"
    const val GO = "ui.btn.go"
    const val RESUME = "ui.btn.resume"
    const val HOME = "ui.btn.home"
    const val TO_MAP = "ui.btn.to_map"
    const val REPLAY = "ui.btn.replay"
    const val MOVE = "ui.pad.move"
    const val ATTACK = "ui.pad.attack"
    const val DEFEND = "ui.pad.defend"
    const val PAUSED = "ui.pause.title"
    const val RETRY = "ui.quiz.retry"
    const val CORRECT = "ui.quiz.correct"
    const val QUESTION = "ui.quiz.question"
    const val DONE = "ui.results.done"
    /** Results when next_hero is null (TASK-009 adds the string). */
    const val MORE_HEROES = "ui.results.more_heroes"
    const val UNLOCKED = "ui.unlock.title"
    const val MAP_STUB = "ui.unlock.map_stub"
    const val OOF = "ui.play.oof"
    const val BLOCKED = "ui.play.blocked"
    const val BEAT = "ui.play.beat"
    const val TURN = "ui.rotate.turn"
    const val LANG_VI = "ui.lang.vi"
    const val LANG_EN = "ui.lang.en"
    const val SPECIAL = "ui.pad.special"
    const val SKIP = "ui.story.skip"
    const val SKIP_WARNING = "ui.story.skip_warning"
    const val SKIP_CONFIRM = "ui.story.skip_confirm"
    const val KEEP_READING = "ui.story.keep_reading"
    const val MEDAL_EARNED = "ui.medal.earned"
    const val MEDAL_MISSING = "ui.medal.missing"
    /** D-07 strings, from TASK-011: checked by the content test once they are on the base. */
    val D07 = listOf(SKIP, SKIP_WARNING, SKIP_CONFIRM, KEEP_READING, MEDAL_EARNED, MEDAL_MISSING)
    val ALL = listOf(TITLE, SUBTITLE_DEBUG, START, NEXT, GO, RESUME, HOME, TO_MAP, REPLAY, MOVE, ATTACK, DEFEND,
        PAUSED, RETRY, CORRECT, QUESTION, DONE, MORE_HEROES, UNLOCKED, MAP_STUB, OOF, BLOCKED, BEAT, TURN, LANG_VI, LANG_EN, SPECIAL) + D07
}
