import KidCore
import XCTest

/// Press Queue story 005, AC-21 (R13): the queue data's ranges and F1's build checks (design/gdd/press-queue.md
/// Tuning Knobs and F1 "Build checks").
final class PressQueueDataTests: XCTestCase {
    /// The shipped values (content/data/press-queue.json) plus Audio & Voice's and KidCore's word limit.
    let shipped = PressQueueKnobs(holdS: 3.0, queueMax: 3, formedTimeoutS: 1.0, wordOffsetS: 0.25, holdExtMaxS: 1.5,
                                  wordLenMaxS: KeyTable.wordLenMaxSeconds)
    /// MorphCore F5's timing sets as the GDD states them (normal T 2.45 / 2.95, reduced 1.2 / 1.5).
    let sets = [PressQueueData.TimingSet(name: "normal", formedS: 2.45, revealLen: 2.95),
                PressQueueData.TimingSet(name: "reduced", formedS: 1.2, revealLen: 1.5)]

    func test_the_shipped_values_are_in_range() {
        XCTAssertEqual(PressQueueData.problems(["hold_s": 3.0, "queue_max": 3, "formed_timeout_s": 1.0]), [])
    }

    func test_a_missing_or_non_numeric_value_fails() {
        let p = PressQueueData.problems(["hold_s": 3.0, "queue_max": Double?.none])
        XCTAssertEqual(p, ["queue_max: missing or not a number", "formed_timeout_s: missing or not a number"])
    }

    func test_a_value_out_of_range_or_a_fractional_queue_max_fails() {
        XCTAssertEqual(PressQueueData.problems(["hold_s": 2.9, "queue_max": 3, "formed_timeout_s": 1.0]),
                       ["hold_s: 2.9 is outside 2.95…6.0"])
        XCTAssertEqual(PressQueueData.problems(["hold_s": 3.0, "queue_max": 6, "formed_timeout_s": 2.5]),
                       ["queue_max: 6.0 is outside 0.0…5.0", "formed_timeout_s: 2.5 is outside 0.5…2.0"])
        XCTAssertEqual(PressQueueData.problems(["hold_s": 3.0, "queue_max": 2.5, "formed_timeout_s": 1.0]),
                       ["queue_max: 2.5 is not a whole number"])
    }

    func test_the_shipped_values_pass_both_F1_build_checks() {
        XCTAssertEqual(PressQueueData.f1BuildCheck(shipped, sets: sets), [])
    }

    func test_the_tuning_row_hold_1_fails_check_1() {
        // GDD F1: "The tuning-build row above (hold_s 1.0) fails check 1: its word would be cut."
        var k = shipped; k.holdS = 1.0
        let f = PressQueueData.f1BuildCheck(k, sets: sets)
        XCTAssertTrue(f.contains { $0.hasPrefix("F1 check 1 (normal)") }, "\(f)")
    }

    func test_a_hold_below_the_reveal_fails_check_2() {
        var k = shipped; k.holdS = 2.9
        XCTAssertEqual(PressQueueData.f1BuildCheck(k, sets: sets), ["F1 check 2 (normal): hold_s 2.9 < revealLen 2.95"])
    }

    func test_check_1_boundary_is_inclusive() {
        // hold_s ≥ 2.45 + 0.25 + 1.5 − 1.5 = 2.70 (normal): 2.70 passes check 1 exactly (check 2 aside).
        var k = shipped; k.holdS = 2.70
        XCTAssertFalse(PressQueueData.f1BuildCheck(k, sets: [sets[0]]).contains { $0.contains("check 1") })
    }
}
