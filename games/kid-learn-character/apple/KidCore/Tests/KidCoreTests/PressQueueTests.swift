import KidCore
import XCTest

/// Press Queue stories 001 (start at once, queue during the hold, the formed guard, ignore when full; AC-1..AC-4)
/// 002 (rest, no jumping, mash; AC-5, AC-6, AC-8, AC-22), 003 (hold and formed rules; AC-7, AC-11, AC-12, AC-24)
/// 004 (ids, sources, resting; AC-9, AC-10, AC-13, AC-18, AC-20) and 005 (panel, background, gate freeze, title,
/// theme; AC-14, AC-15, AC-16, AC-17, AC-23) of design/gdd/press-queue.md. An injected clock, a fake Reveal Stage and fixed lengths; no wall clock.
final class PressQueueTests: XCTestCase {
    /// A clock the test sets; `formed(revealId:)` reads it.
    final class FakeClock: UptimeClock {
        var t = 0.0
        func now() -> Double { t }
    }

    /// A fake Reveal Stage: the same lengths for every key (dyadic, so the sums are exact), every call recorded.
    final class FakeStage: PressQueueStage {
        struct Call: Equatable { var revealId: Int; var key: String; var source: PressSource; var origin: PressOrigin?; var r0: Double }
        var calls: [Call] = []
        var answer: RevealStart
        /// Reduce Motion as the stage reads it at each start (Reveal Stage R9), and its set (F5: formedS 1.25,
        /// revealLen 1.5 here, dyadic).
        var reduceMotion = false
        /// The theme's cast prefix Key Table resolves with (a theme switch changes it, AC-16).
        var castPrefix = "cast_"
        var reducedAnswer = RevealStart(formedS: 1.25, revealLen: 1.5, hasWord: true, wordLen: 0.5, castId: "")
        init(formedS: Double, revealLen: Double, wordLen: Double) {
            answer = RevealStart(formedS: formedS, revealLen: revealLen, hasWord: true, wordLen: wordLen, castId: "")
        }
        func startReveal(revealId: Int, key: String, source: PressSource, origin: PressOrigin?, r0: Double) -> RevealStart {
            calls.append(Call(revealId: revealId, key: key, source: source, origin: origin, r0: r0))
            var a = reduceMotion ? reducedAnswer : answer
            a.castId = "\(castPrefix)\(key)"
            return a
        }
    }

    /// The debug log; the queue writes one line for a missing word length (F1) and one for a formed timeout (R5).
    final class FakeLog: DebugLog {
        var lines: [String] = []
        func log(_ line: String) { lines.append(line) }
    }
    let log = FakeLog()

    // Fixture values, named once. holdEff = max(3.0, 3.0, min(2.5 + 0.25 + 0.5, 3.0 + 1.5)) = 3.25.
    let knobs = PressQueueKnobs(holdS: 3.0, queueMax: 3, formedTimeoutS: 1.0, wordOffsetS: 0.25, holdExtMaxS: 1.5,
                                wordLenMaxS: 1.5)
    let holdEff = 3.25

    /// The play clock the last `makeQueue()` built, for the story-005 tests that pause it.
    var play: PlayClock!

    func makeQueue() -> (PressQueue, FakeStage, FakeClock) {
        let stage = FakeStage(formedS: 2.5, revealLen: 3.0, wordLen: 0.5)
        let clock = FakeClock()
        play = PlayClock(uptime: clock)
        return (PressQueue(knobs: knobs, stage: stage, clock: play, log: log), stage, clock)
    }

    func press(_ key: String, at t: Double) -> Press { Press(key: key, source: .hardwareKey, time: t) }

    // AC-1
    func test_press_with_nothing_on_stage_starts_at_once() {
        var (q, stage, _) = makeQueue()
        let outcome = q.press(press("D", at: 10.0))
        XCTAssertEqual(outcome, .started(revealId: 1, r0: 10.0, castId: "cast_D"))
        XCTAssertEqual(stage.calls, [FakeStage.Call(revealId: 1, key: "D", source: .hardwareKey, origin: nil, r0: 10.0)])
        XCTAssertEqual(q.current?.holdEff, holdEff)
        XCTAssertEqual(q.nextRevealId, 2)
    }

    // AC-2
    func test_press_during_hold_queues_then_starts_at_hold_end() {
        var (q, stage, clock) = makeQueue()
        _ = q.press(press("D", at: 10.0))
        clock.t = 12.5
        q.formed(revealId: 1)
        XCTAssertEqual(q.press(press("B", at: 11.0)), .queued(index: 0))
        q.tick(now: 13.2490234375)  // just before r0 + holdEff
        XCTAssertEqual(stage.calls.count, 1)
        XCTAssertEqual(q.queue.map(\.key), ["B"])
        q.tick(now: 13.25)
        XCTAssertEqual(stage.calls.count, 2)
        XCTAssertEqual(stage.calls[1], FakeStage.Call(revealId: 2, key: "B", source: .hardwareKey, origin: nil, r0: 13.25))
        XCTAssertTrue(q.queue.isEmpty)
    }

    // AC-3
    func test_queued_press_waits_for_formed_even_after_hold_passed() {
        var (q, stage, clock) = makeQueue()
        _ = q.press(press("D", at: 10.0))
        XCTAssertEqual(q.press(press("B", at: 11.0)), .queued(index: 0))
        q.tick(now: 13.5)  // past the hold, D not formed
        XCTAssertEqual(stage.calls.count, 1)
        clock.t = 13.5
        q.formed(revealId: 1)
        q.tick(now: 13.625)
        XCTAssertEqual(stage.calls.count, 2)
        XCTAssertEqual(stage.calls[1].r0, 13.625)
    }

    func test_press_after_hold_but_before_formed_queues() {
        var (q, _, _) = makeQueue()
        _ = q.press(press("D", at: 10.0))
        XCTAssertEqual(q.press(press("B", at: 13.5)), .queued(index: 0))
    }

    func test_press_after_formed_but_before_hold_end_queues() {
        var (q, _, clock) = makeQueue()
        _ = q.press(press("D", at: 10.0))
        clock.t = 12.5
        q.formed(revealId: 1)
        XCTAssertEqual(q.press(press("B", at: 13.0)), .queued(index: 0))
    }

    func test_formed_for_another_reveal_or_twice_changes_nothing() {
        var (q, _, clock) = makeQueue()
        _ = q.press(press("D", at: 10.0))
        clock.t = 11.0
        q.formed(revealId: 7)
        XCTAssertEqual(q.current?.formed, false)
        q.formed(revealId: 1)
        clock.t = 12.0
        q.formed(revealId: 1)
        XCTAssertEqual(q.current?.formedAt, 11.0)
    }

    // AC-4
    func test_fourth_press_while_holding_is_ignored_and_uses_no_reveal_id() {
        var (q, stage, _) = makeQueue()
        _ = q.press(press("D", at: 10.0))
        XCTAssertEqual(q.press(press("A", at: 10.5)), .queued(index: 0))
        XCTAssertEqual(q.press(press("B", at: 10.5)), .queued(index: 1))
        XCTAssertEqual(q.press(press("C", at: 10.5)), .queued(index: 2))
        XCTAssertEqual(q.press(press("E", at: 10.75)), .ignored)
        XCTAssertEqual(q.queue.map(\.key), ["A", "B", "C"])
        XCTAssertEqual(q.nextRevealId, 2)
        XCTAssertEqual(stage.calls.count, 1)
    }

    func test_press_never_jumps_a_queued_key_after_hold_passed() {
        var (q, _, clock) = makeQueue()
        _ = q.press(press("D", at: 10.0))
        clock.t = 12.5
        q.formed(revealId: 1)
        XCTAssertEqual(q.press(press("B", at: 11.0)), .queued(index: 0))
        XCTAssertEqual(q.press(press("C", at: 14.0)), .queued(index: 1))
    }

    // MARK: story 002

    /// D started at 10.0 and formed at 12.5; its hold ends at 10.0 + holdEff.
    func formedQueue() -> (PressQueue, FakeStage, FakeClock) {
        var (q, stage, clock) = makeQueue()
        _ = q.press(press("D", at: 10.0))
        clock.t = 12.5
        q.formed(revealId: 1)
        return (q, stage, clock)
    }

    // AC-5
    func test_press_at_rest_starts_at_its_own_time_not_the_next_tick() {
        var (q, stage, _) = formedQueue()
        let restAt = 10.0 + holdEff + 0.5
        XCTAssertEqual(q.press(press("B", at: restAt)), .started(revealId: 2, r0: restAt, castId: "cast_B"))
        XCTAssertEqual(stage.calls.last?.r0, restAt)
        XCTAssertEqual(q.queue, [])
    }

    // AC-6
    func test_press_after_hold_with_one_queued_queues_behind_it_and_the_tick_starts_the_first() {
        var (q, stage, _) = formedQueue()
        XCTAssertEqual(q.press(press("B", at: 11.0)), .queued(index: 0))
        XCTAssertEqual(q.press(press("C", at: 10.0 + holdEff + 0.25)), .queued(index: 1))
        q.tick(now: 10.0 + holdEff + 0.5)
        XCTAssertEqual(stage.calls.map(\.key), ["D", "B"])
        XCTAssertEqual(q.current?.key, "B")
        XCTAssertEqual(q.queue.map(\.key), ["C"])
    }

    // AC-8
    func test_ten_presses_at_rest_in_one_batch_start_one_queue_three_and_ignore_six_in_order() {
        var (q, stage, _) = makeQueue()
        let keys = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
        let outcomes = keys.map { q.press(press($0, at: 10.0)) }
        XCTAssertEqual(outcomes, [.started(revealId: 1, r0: 10.0, castId: "cast_A"), .queued(index: 0), .queued(index: 1),
                                  .queued(index: 2)] + Array(repeating: .ignored, count: 6))
        XCTAssertEqual(q.queue.map(\.key), ["B", "C", "D"])
        XCTAssertEqual(stage.calls.count, 1)
        XCTAssertEqual(q.nextRevealId, 2)
    }

    // AC-22
    func test_a_tick_far_past_two_holds_starts_only_one_reveal() {
        var (q, stage, _) = formedQueue()
        _ = q.press(press("B", at: 11.0))
        _ = q.press(press("C", at: 11.0))
        q.tick(now: 10.0 + 4 * holdEff)
        XCTAssertEqual(stage.calls.map(\.key), ["D", "B"])
        XCTAssertEqual(q.queue.map(\.key), ["C"])
    }

    // MARK: story 003

    /// The holdEff a reveal with this answer gets (F1), read from the queue after one press at rest.
    func holdEff(formedS: Double, revealLen: Double, hasWord: Bool = true, wordLen: Double?) -> Double? {
        var (q, stage, _) = makeQueue()
        stage.answer = RevealStart(formedS: formedS, revealLen: revealLen, hasWord: hasWord, wordLen: wordLen, castId: "")
        _ = q.press(press("D", at: 10.0))
        return q.current?.holdEff
    }

    // AC-7 (the F1 table rows, normal set: formedS 2.45, revealLen 2.95)
    func test_hold_follows_the_F1_table_rows() throws {
        let rows: [(word: Double?, hold: Double)] = [(0.5, 3.2), (0.904, 3.604), (1.15, 3.85), (1.47, 4.17), (1.5, 4.2)]
        for r in rows {
            XCTAssertEqual(try XCTUnwrap(holdEff(formedS: 2.45, revealLen: 2.95, wordLen: r.word)), r.hold, accuracy: 1e-9, "word \(r.word!)")
        }
        XCTAssertEqual(log.lines, [])
    }

    // AC-7 (K-53: the missing-entry bound is formedS + word_offset_s + word_len_max_s, 1.75 with the shipped knobs)
    func test_a_missing_word_length_uses_the_bound_and_writes_one_log_line() throws {
        XCTAssertEqual(try XCTUnwrap(holdEff(formedS: 2.45, revealLen: 2.95, wordLen: nil)), 2.45 + 1.75, accuracy: 1e-9)
        XCTAssertEqual(log.lines.count, 1)
    }

    // AC-11 (the timeout, inclusive) and R7 (a later formed is ignored)
    func test_a_reveal_never_formed_is_formed_by_the_timeout_at_exactly_its_bound() {
        var (q, _, clock) = makeQueue()
        _ = q.press(press("D", at: 10.0))
        let bound = 10.0 + 3.0 + knobs.formedTimeoutS
        q.tick(now: bound - 0.0009765625)
        XCTAssertEqual(q.current?.formed, false)
        XCTAssertEqual(log.lines, [])
        q.tick(now: bound)
        XCTAssertEqual(q.current?.formed, true)
        XCTAssertEqual(q.current?.formedAt, bound)
        XCTAssertEqual(log.lines.count, 1)
        clock.t = bound + 0.125
        q.formed(revealId: 1)
        XCTAssertEqual(q.current?.formedAt, bound)
    }

    // R5: the timeout and an advance can happen in the same tick
    func test_the_timeout_and_the_advance_happen_in_one_tick() {
        var (q, stage, _) = makeQueue()
        _ = q.press(press("D", at: 10.0))
        _ = q.press(press("B", at: 10.5))
        q.tick(now: 14.0)
        XCTAssertEqual(stage.calls.map(\.key), ["D", "B"])
        XCTAssertEqual(stage.calls.last?.r0, 14.0)
    }

    // AC-12: the stage's fallback lengths are what holdEff uses
    func test_fallback_lengths_from_the_stage_set_the_hold() throws {
        // A long fallback revealLen dominates: max(3.0, 4.5, min(2.0 + 0.25 + 0.5, 4.5)) = 4.5.
        XCTAssertEqual(try XCTUnwrap(holdEff(formedS: 2.0, revealLen: 4.5, wordLen: 0.5)), 4.5, accuracy: 1e-9)
    }

    // AC-24
    func test_no_word_gives_the_longer_of_hold_and_reveal() throws {
        XCTAssertEqual(try XCTUnwrap(holdEff(formedS: 2.45, revealLen: 3.5, hasWord: false, wordLen: nil)), 3.5, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(holdEff(formedS: 2.45, revealLen: 2.95, hasWord: false, wordLen: nil)), 3.0, accuracy: 1e-9)
        XCTAssertEqual(log.lines, [], "no word: no missing-entry line")
    }

    // MARK: story 004

    // AC-9
    func test_every_press_returns_its_outcome_at_once_in_order() {
        var (q, _, _) = makeQueue()
        let outcomes = ["A", "B", "C", "D", "E"].map { q.press(press($0, at: 10.0)) }
        XCTAssertEqual(outcomes.count, 5)
        XCTAssertEqual(outcomes, [.started(revealId: 1, r0: 10.0, castId: "cast_A"), .queued(index: 0), .queued(index: 1),
                                  .queued(index: 2), .ignored])
    }

    // AC-10
    func test_started_reveals_number_one_two_three_with_no_gaps() {
        var (q, stage, clock) = makeQueue()
        _ = q.press(press("A", at: 10.0))
        _ = q.press(press("B", at: 10.5))
        _ = q.press(press("C", at: 10.5))
        _ = q.press(press("X", at: 10.5))
        _ = q.press(press("Y", at: 10.5))   // ignored: takes no id
        for n in 1...3 {
            clock.t = 10.0 + Double(n) * 4
            q.formed(revealId: n)
            q.tick(now: clock.t)
        }
        XCTAssertEqual(stage.calls.map(\.revealId), [1, 2, 3, 4])
        XCTAssertEqual(stage.calls.map(\.key), ["A", "B", "C", "X"])
        XCTAssertEqual(q.nextRevealId, 5)
    }

    // AC-13 (F5: the set is read at the start and locked; hold_s stays 3.0)
    func test_reduce_motion_mid_reveal_keeps_its_hold_and_the_next_reveal_uses_the_reduced_set() {
        var (q, stage, clock) = makeQueue()
        _ = q.press(press("D", at: 10.0))
        stage.reduceMotion = true   // turned on mid-reveal: D keeps the hold it started with
        XCTAssertEqual(q.current?.holdEff, holdEff)
        clock.t = 12.5
        q.formed(revealId: 1)
        _ = q.press(press("B", at: 10.0 + holdEff + 0.25))
        // max(3.0, 1.5, min(1.25 + 0.25 + 0.5, 4.5)) = 3.0: the pace of the queue is unchanged.
        XCTAssertEqual(q.current?.holdEff, 3.0)
        XCTAssertEqual(q.current?.revealLen, 1.5)
    }

    // AC-18 (R12: every source follows the same rules; only origin differs)
    func test_hardware_key_hint_and_keyboard_row_give_the_same_outcomes_and_times() {
        func run(_ source: PressSource, _ origin: PressOrigin?) -> ([PressOutcome], [Double]) {
            var (q, stage, clock) = makeQueue()
            var out = [q.press(Press(key: "D", source: source, time: 10.0, origin: origin)),
                       q.press(Press(key: "B", source: source, time: 10.5, origin: origin))]
            clock.t = 12.5
            q.formed(revealId: 1)
            q.tick(now: 10.0 + holdEff)
            out.append(q.press(Press(key: "C", source: source, time: 14.0, origin: origin)))
            return (out, stage.calls.map(\.r0))
        }
        let key = run(.hardwareKey, nil)
        XCTAssertEqual(run(.hint("3"), PressOrigin(x: 400, y: 200)).0, key.0)
        XCTAssertEqual(run(.hint("3"), PressOrigin(x: 400, y: 200)).1, key.1)
        XCTAssertEqual(run(.keyboardRow, PressOrigin(x: 120, y: 700)).0, key.0)
        XCTAssertEqual(run(.keyboardRow, PressOrigin(x: 120, y: 700)).1, key.1)
    }

    // AC-20 (R10)
    func test_resting_since_is_none_until_formed_with_an_empty_queue_then_the_formed_time() {
        var (q, _, clock) = makeQueue()
        _ = q.press(press("D", at: 10.0))
        XCTAssertNil(q.restingSince, "not formed")
        _ = q.press(press("B", at: 10.5))
        clock.t = 12.5
        q.formed(revealId: 1)
        XCTAssertNil(q.restingSince, "formed but B is queued")
        q.tick(now: 10.0 + holdEff)
        XCTAssertNil(q.restingSince, "B started, not formed")
        clock.t = 15.75
        q.formed(revealId: 2)
        XCTAssertEqual(q.restingSince, 15.75)
    }

    // MARK: story 005

    /// D started at 10.0 with A, B, C queued (not formed yet).
    func busyQueue() -> (PressQueue, FakeStage, FakeClock) {
        var (q, stage, clock) = makeQueue()
        _ = q.press(press("D", at: 10.0))
        for k in ["A", "B", "C"] { _ = q.press(press(k, at: 10.5)) }
        return (q, stage, clock)
    }

    // AC-14 (R8): the panel opens mid-morph
    func test_the_panel_clears_the_queue_and_settles_the_reveal_at_the_play_time() {
        var (q, stage, clock) = busyQueue()
        clock.t = 11.0
        q.settle()
        XCTAssertEqual(q.queue, [])
        XCTAssertEqual(q.current?.formed, true)
        XCTAssertEqual(q.current?.formedAt, 11.0)
        XCTAssertEqual(q.restingSince, 11.0)
        XCTAssertEqual(stage.calls.count, 1, "no reveal for the dropped presses")
        // After the panel closes, the next press starts at once: the settled hold counts as passed.
        XCTAssertEqual(q.press(press("E", at: 20.5)), .started(revealId: 2, r0: 20.5, castId: "cast_E"))
    }

    // AC-15 (R9): background clears and settles; the time away never counts
    func test_background_settles_and_its_time_is_excluded_from_play_time() {
        var (q, _, clock) = busyQueue()
        clock.t = 11.0
        q.settle()
        play.pause(.background, at: 11.0)
        clock.t = 311.0
        play.resume(.background, at: 311.0)
        XCTAssertEqual(q.current?.formedAt, 11.0)
        XCTAssertEqual(q.press(press("C", at: 311.5)), .started(revealId: 2, r0: 11.5, castId: "cast_C"))
    }

    // AC-23 (R8a): the gate challenge for 20 s, then a timeout
    func test_a_gate_freeze_then_timeout_keeps_the_queue_and_counts_no_frozen_time() {
        var (q, stage, clock) = makeQueue()
        _ = q.press(press("D", at: 10.0))
        _ = q.press(press("A", at: 10.5))
        _ = q.press(press("B", at: 10.5))
        play.pause(.freeze, at: 11.0); q.freeze()
        q.tick(now: play.play(20.0))
        XCTAssertEqual(q.queue.map(\.key), ["A", "B"], "frozen: nothing cleared, nothing advanced")
        play.resume(.freeze, at: 31.0); q.resume()
        clock.t = 32.5
        q.formed(revealId: 1)
        XCTAssertEqual(q.current?.formedAt, 12.5)
        q.tick(now: play.play(33.25))
        XCTAssertEqual(stage.calls.map(\.key), ["D", "A"])
        XCTAssertEqual(stage.calls.last?.r0, 10.0 + holdEff)
        XCTAssertEqual(q.queue.map(\.key), ["B"])
    }

    // AC-23 (R8 after R8a): a correct answer opens the panel; the settle is at the frozen play time
    func test_a_correct_answer_clears_and_settles_at_the_frozen_play_time() {
        var (q, _, clock) = makeQueue()
        _ = q.press(press("D", at: 10.0))
        _ = q.press(press("A", at: 10.5))
        play.pause(.freeze, at: 11.0); q.freeze()
        clock.t = 20.0
        q.settle()
        play.resume(.freeze, at: 20.0)
        XCTAssertEqual(q.queue, [])
        XCTAssertEqual(q.current?.formedAt, 11.0)
        XCTAssertFalse(q.frozen, "the panel ends the challenge's freeze")
    }

    // AC-17: play entered by a key
    func test_the_first_press_of_play_starts_at_once_as_reveal_one() {
        var (q, _, _) = makeQueue()
        XCTAssertNil(q.current)
        XCTAssertEqual(q.press(press("D", at: 5.0)), .started(revealId: 1, r0: 5.0, castId: "cast_D"))
    }

    // AC-16 (logic): after a theme switch the next started item is the new theme's (the stage resolves it)
    func test_after_a_theme_switch_the_next_reveal_takes_the_new_themes_item() {
        var (q, stage, clock) = makeQueue()
        _ = q.press(press("D", at: 10.0))
        clock.t = 11.0
        q.settle()   // the theme changes in the panel; the queue is already empty
        stage.castPrefix = "newtheme_"   // Key Table now resolves from the new theme
        XCTAssertEqual(q.press(press("D", at: 20.0)), .started(revealId: 2, r0: 20.0, castId: "newtheme_D"))
    }

    // The play clock: overlapping pauses count once
    func test_play_clock_excludes_overlapping_freeze_and_background_once() {
        let up = FakeClock()
        let p = PlayClock(uptime: up)
        p.pause(.freeze, at: 10.0)
        p.pause(.background, at: 12.0)
        p.resume(.freeze, at: 15.0)
        XCTAssertTrue(p.isPaused)
        p.resume(.background, at: 20.0)
        XCTAssertFalse(p.isPaused)
        up.t = 25.0
        XCTAssertEqual(p.now(), 15.0, "25 s of uptime minus the 10 s paused (10 to 20) once")
        XCTAssertEqual(p.play(21.0), 11.0)
    }
}
