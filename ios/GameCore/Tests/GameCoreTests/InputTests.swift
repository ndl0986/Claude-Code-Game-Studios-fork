import XCTest
@testable import GameCore

/// Touch handling and pad layout (P-04 items 4, pads ≥ pad_min inside the safe area).
final class InputTests: XCTestCase {
    func test_multi_touch_holds_slide_switches_direction_and_clear_all_unsticks() {
        var t = TouchPads()
        t.down(1, .right); t.down(2, .attack)
        var i = t.take()
        XCTAssertEqual(i.held, [.right, .attack]); XCTAssertEqual(i.tapped, [.right, .attack])
        t.moved(1, .left)
        i = t.take()
        XCTAssertEqual(i.held, [.left, .attack]); XCTAssertTrue(i.tapped.isEmpty, "taps are consumed")
        t.moved(2, .defend)
        XCTAssertEqual(t.take().held, [.left, .attack], "sliding never changes attack")
        t.clearAll()
        XCTAssertTrue(t.take().held.isEmpty)
    }

    func test_pads_are_at_least_72pt_and_inside_the_safe_area_on_the_iphone_duo_cover() {
        // the Duo's cover display in landscape: 2034×1398 px at 3x ≈ 678×466 pt; a camera cutout on the left
        let insets = (top: 0.0, left: 59.0, bottom: 21.0, right: 59.0)
        let l = PadLayout(view: (w: 678, h: 466), insets: insets, padMin: 72)
        let s = l.scale, oy = (466 - 720 * s) / 2, ox = (678 - 1280 * s) / 2
        for c in [l.left, l.right, l.defend, l.attack, l.special] {
            XCTAssertGreaterThanOrEqual(c.r * 2 * s, 72 - 0.001)
            XCTAssertGreaterThanOrEqual(ox + (c.cx - c.r) * s, insets.left - 0.001)
            XCTAssertLessThanOrEqual(ox + (c.cx + c.r) * s, 678 - insets.right + 0.001)
            XCTAssertLessThanOrEqual(oy + (c.cy + c.r) * s, 466 - insets.bottom + 0.001)
        }
        XCTAssertLessThan(l.left.cx + l.left.r, l.right.cx - l.right.r, "pads don't overlap")
        XCTAssertLessThan(l.defend.cx + l.defend.r, l.attack.cx - l.attack.r)
        XCTAssertLessThan(l.special.cy + l.special.r, l.attack.cy - l.attack.r, "special above attack")
        XCTAssertGreaterThanOrEqual(oy + (l.special.cy - l.special.r) * s, insets.top - 0.001)
    }

    /// HUD spec AC11 / Input Rule 4 on the iOS reference phone (Input F1: a 6.1" Dynamic Island iPhone,
    /// 852×393 pt landscape, 59 pt side insets, 21 pt home indicator): pause and sound are ≥ pad_min,
    /// pad_gap apart (as are ◀ ▶), and the block ends left of the top stack, which stays centred at 790.
    func test_pause_and_sound_keep_pad_min_and_pad_gap_clear_of_the_top_stack() {
        let insets = (top: 0.0, left: 59.0, bottom: 21.0, right: 59.0)
        let l = PadLayout(view: (w: 852, h: 393), insets: insets, padMin: 72, padGap: 12)
        let k = l.scale
        for c in [l.pause, l.mute] { XCTAssertGreaterThanOrEqual(c.r * 2 * k, 72 - 0.001) }
        XCTAssertGreaterThanOrEqual(((l.mute.cx - l.mute.r) - (l.pause.cx + l.pause.r)) * k, 12 - 0.001, "pause–sound pad_gap")
        XCTAssertGreaterThanOrEqual(((l.right.cx - l.right.r) - (l.left.cx + l.left.r)) * k, 12 - 0.001, "◀ ▶ pad_gap")
        XCTAssertLessThan(l.mute.cx + l.mute.r, 330, "clear of the top stack band")
        XCTAssertEqual(l.topStackCentre, 790)
    }

    /// The leader's r5 rule: a big corner (small k, a full-width view with a left inset) moves the stack right,
    /// its left edge at the corner + 8, with the centre clamped at 810.
    func test_a_wide_corner_pushes_the_top_stack_right_up_to_810() {
        let k = 0.49, l = PadLayout(view: (w: 1280 * k, h: 720 * k), insets: (0, 59, 21, 0), padMin: 72, padGap: 12)
        let corner = l.mute.cx + l.mute.r
        XCTAssertGreaterThan(corner + 8, 330)
        XCTAssertEqual(l.topStackCentre, min(810, corner + 8 + 460), accuracy: 1e-9)
        XCTAssertLessThanOrEqual(l.topStackCentre, 810)
    }

    func test_hit_test_finds_the_pad_with_slop() {
        let l = PadLayout(view: (w: 1280, h: 720), insets: (0, 0, 0, 0), padMin: 72)
        XCTAssertEqual(l.action(at: l.attack.cx + l.attack.r * 1.1, l.attack.cy), .attack)
        XCTAssertNil(l.action(at: 640, 300))
        XCTAssertNil(l.action(at: l.special.cx, l.special.cy, visible: [.left, .right]), "hidden pads never fire")
    }
}

/// iOS-R2-03: press → move → release leaves nothing held, even if the end event is lost.
final class StuckInputTests: XCTestCase {
    func test_press_move_release_leaves_nothing_held() {
        var t = TouchPads()
        t.down(7, .right); t.moved(7, .right); t.moved(7, .right)
        XCTAssertEqual(t.take().held, [.right])
        t.up(7)
        XCTAssertTrue(t.take().held.isEmpty)
        t.down(8, .defend); t.moved(8, nil)
        t.up(8)
        XCTAssertTrue(t.take().held.isEmpty, "a defend touch that wandered off the pad still releases")
    }

    func test_reconcile_drops_a_hold_whose_end_event_never_arrived() {
        var t = TouchPads()
        t.down(1, .right); t.down(2, .attack)
        t.reconcile(live: [2]) // touch 1 ended without touchesEnded reaching the scene
        XCTAssertEqual(t.take().held, [.attack])
        t.reconcile(live: [])
        XCTAssertTrue(t.take().held.isEmpty)
    }

    func test_quiz_next_appears_only_after_feedback_time() throws {
        let c = try Repo.contentSet()
        let g = Game(content: c, hero: Repo.sampleHero(c), store: MemoryStore(), isDebug: true)
        g.startQuiz()
        let q = g.quiz!
        g.answer(q.order.firstIndex(of: q.current.correctIndex)!)
        for _ in 0..<Int(c.tuning["feedback_time"] * 60) - 1 { g.step(1.0 / 60, StepInput()) }
        XCTAssertFalse(g.quizCanAdvance, "QS AC5: not before feedback_time")
        for _ in 0..<2 { g.step(1.0 / 60, StepInput()) }
        XCTAssertTrue(g.quizCanAdvance)
    }
}

/// TASK-019 (b): a second pointer on an already-held pad is ignored until it lifts.
final class SecondPointerTests: XCTestCase {
    func test_second_finger_on_a_held_pad_neither_fires_nor_co_holds() {
        var t = TouchPads()
        t.down(1, .attack)
        XCTAssertEqual(t.take().tapped, [.attack])
        t.down(2, .attack)
        XCTAssertTrue(t.take().tapped.isEmpty, "no second attack")
        t.down(3, .defend); _ = t.take()
        t.down(4, .defend)
        t.up(3)
        XCTAssertFalse(t.take().held.contains(.defend), "lifting the owner drops defend; the ignored finger doesn't keep it")
        t.up(4); t.down(5, .defend)
        XCTAssertTrue(t.take().held.contains(.defend), "after it lifts, a new press works")
    }
}

/// iOS QC r3 (R2-03 still reproducing): QC's exact sequence, including an up that arrives under a
/// different touch id (Device Hub mouse drags), must leave nothing held.
final class R3StuckSequenceTests: XCTestCase {
    func test_qc_sequence_left_slide_to_right_up_as_other_id_then_right_small_moves_up() {
        var t = TouchPads()
        t.apply(.began, id: 1, action: .left, live: [1])
        t.apply(.moved, id: 1, action: .left, live: [1])
        t.apply(.moved, id: 1, action: .right, live: [1])     // slides onto ▶
        XCTAssertEqual(t.take().held, [.right])
        t.apply(.ended, id: 2, action: nil, live: [])         // the up arrives as another touch
        XCTAssertTrue(t.take().held.isEmpty, "▶ must not stay held")
        t.apply(.began, id: 3, action: .right, live: [3])
        t.apply(.moved, id: 3, action: .right, live: [3])
        t.apply(.moved, id: 3, action: .right, live: [3])
        t.apply(.ended, id: 3, action: nil, live: [])
        XCTAssertTrue(t.take().held.isEmpty)
    }

    func test_an_up_that_never_arrives_is_dropped_at_the_next_callback() {
        var t = TouchPads()
        t.apply(.began, id: 1, action: .special, live: [1])
        t.apply(.began, id: 4, action: .attack, live: [4])    // touch 1 is no longer in allTouches
        XCTAssertEqual(t.take().held, [.attack])
    }
}
