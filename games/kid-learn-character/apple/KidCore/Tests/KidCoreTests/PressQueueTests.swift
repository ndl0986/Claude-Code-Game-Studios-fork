import KidCore
import XCTest

/// Press Queue stories 001 (start at once, queue during the hold, the formed guard, ignore when full; AC-1..AC-4)
/// and 002 (rest, no jumping, mash; AC-5, AC-6, AC-8, AC-22) of design/gdd/press-queue.md. An injected clock, a fake Reveal Stage and fixed lengths; no wall clock.
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
        let answer: RevealStart
        init(formedS: Double, revealLen: Double, wordLen: Double) {
            answer = RevealStart(formedS: formedS, revealLen: revealLen, hasWord: true, wordLen: wordLen, castId: "")
        }
        func startReveal(revealId: Int, key: String, source: PressSource, origin: PressOrigin?, r0: Double) -> RevealStart {
            calls.append(Call(revealId: revealId, key: key, source: source, origin: origin, r0: r0))
            var a = answer
            a.castId = "cast_\(key)"
            return a
        }
    }

    // Fixture values, named once. holdEff = max(3.0, 3.0, min(2.5 + 0.25 + 0.5, 3.0 + 1.5)) = 3.25.
    let knobs = PressQueueKnobs(holdS: 3.0, queueMax: 3, formedTimeoutS: 1.0, wordOffsetS: 0.25, holdExtMaxS: 1.5,
                                wordLenMaxS: 1.5)
    let holdEff = 3.25

    func makeQueue() -> (PressQueue, FakeStage, FakeClock) {
        let stage = FakeStage(formedS: 2.5, revealLen: 3.0, wordLen: 0.5)
        let clock = FakeClock()
        return (PressQueue(knobs: knobs, stage: stage, clock: clock), stage, clock)
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
}
