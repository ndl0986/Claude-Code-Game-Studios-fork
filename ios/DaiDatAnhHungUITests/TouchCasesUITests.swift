import XCTest

/// QC's touch cases as UI tests (TASK-023 G): real touches on the Simulator, no macOS Accessibility needed.
/// Each test launches a Debug build at a debug screen, drives the pads by coordinates from the app's own
/// layout, and asserts on the debug-only `debugState` element (a JSON dump of the game state).
/// Shared helpers (no tests here, so subclasses don't re-run cases).
class UITestBase: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    func quit() { app?.terminate() }

    func launch(_ args: [String]) {
        app = XCUIApplication()
        app.launchArguments = args + ["-lang", "en"]
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["debugState"].waitForExistence(timeout: 15), "debugState (Debug build only)")
        _ = waitFor(5) { $0["screen"] as? String != nil }
    }

    func state() -> [String: Any] {
        let v = app.descendants(matching: .any)["debugState"].value as? String ?? "{}"
        return (try? JSONSerialization.jsonObject(with: Data(v.utf8))) as? [String: Any] ?? [:]
    }

    /// Polls the state (it publishes ~10 times a second) until `ok`, or times out.
    @discardableResult
    func waitFor(_ secs: Double, _ ok: ([String: Any]) -> Bool) -> [String: Any] {
        let end = Date().addingTimeInterval(secs)
        var s = state()
        while !ok(s) && Date() < end { Thread.sleep(forTimeInterval: 0.1); s = state() }
        return s
    }

    func point(_ norm: [Double]) -> XCUICoordinate {
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: norm[0], dy: norm[1]))
    }
    func pad(_ name: String) -> XCUICoordinate { point((state()["pads"] as! [String: [Double]])[name]!) }
    func button(_ id: String) -> XCUICoordinate? { ((state()["buttons"] as? [String: [Double]])?[id]).map(point) }
    func held(_ s: [String: Any]) -> [String] { s["held"] as? [String] ?? ["?"] }

    func shot(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }
    func note(_ name: String, _ text: String) {
        let a = XCTAttachment(string: text); a.name = name; a.lifetime = .keepAlways; add(a)
    }
    func log(_ s: [String: Any]) -> [(String, Double)] {
        (s["log"] as? [[String: Any]] ?? []).map { ($0["place"] as? String ?? "", $0["t"] as? Double ?? 0) }
    }
}

final class TouchCasesUITests: UITestBase {
    /// R2-03: press, move a little, release on each pad of the blocks step leaves nothing held.
    func test_R2_03_press_move_release_on_each_pad_leaves_nothing_held() {
        launch(["-startScreen", "play", "-beat", "4", "-stage", "blocks"])
        let visible = waitFor(5) { ($0["visible"] as? [String])?.isEmpty == false }["visible"] as? [String] ?? []
        XCTAssertFalse(visible.isEmpty)
        for name in visible {
            let from = pad(name), to = from.withOffset(CGVector(dx: 12, dy: -10))
            from.press(forDuration: 0.4, thenDragTo: to, withVelocity: .slow, thenHoldForDuration: 0.3)
            let s = waitFor(2) { self.held($0).isEmpty }
            XCTAssertEqual(held(s), [], "\(name): nothing held after release")
        }
        shot("R2-03 after the last release")
    }

    /// The ◀→▶ slide (Input Rule 9): pressing ◀ and sliding onto ▶ walks right; releasing holds nothing.
    func test_slide_from_left_to_right_walks_right_then_releases() {
        launch(["-startScreen", "play", "-beat", "1"])
        let s0 = waitFor(5) { ($0["visible"] as? [String])?.contains("right") == true }
        let x0 = s0["hero_x"] as? Double ?? 0
        pad("left").press(forDuration: 0.2, thenDragTo: pad("right"), withVelocity: .default, thenHoldForDuration: 1.5)
        let s1 = waitFor(2) { self.held($0).isEmpty }
        XCTAssertEqual(held(s1), [])
        XCTAssertGreaterThan(s1["hero_x"] as? Double ?? 0, x0, "the slide onto ▶ walked right")
        shot("slide ◀→▶ released")
    }

    /// Holding ▶ across a beat change (walk → the next beat's card): the hold ends cleanly, nothing stuck.
    func test_holding_right_across_a_beat_change_leaves_nothing_held() {
        launch(["-startScreen", "play", "-beat", "1"])
        let s0 = waitFor(5) { ($0["visible"] as? [String])?.contains("right") == true }
        let beat0 = s0["beat"] as? Int ?? -1
        pad("right").press(forDuration: 12)
        let s1 = waitFor(3) { self.held($0).isEmpty }
        XCTAssertEqual(held(s1), [], "nothing held after the release")
        XCTAssertGreaterThan(s1["beat"] as? Int ?? -1, beat0, "the walk beat ended while ▶ was held")
        shot("after holding ▶ across the beat change")
    }

    /// B1 (Input Rule 12): two fast taps on Tiếp advance one box. XCUITest can't place taps exactly 0.15 s
    /// apart, so the test reads the press times the app recorded (UITouch.timestamp, what the debounce
    /// compares) and reports the measured gap; a gap ≥ advance_debounce (0.25 s) is "not exercised".
    func test_B1_two_fast_taps_on_next_advance_one_box() throws {
        launch(["-startScreen", "intro"])
        let s0 = waitFor(5) { ($0["buttons"] as? [String: [Double]])?["next"] != nil }
        let line0 = s0["story_line"] as? Int ?? -1
        Thread.sleep(forTimeInterval: 0.5)
        button("next")!.doubleTap()
        let s1 = waitFor(2) { ($0["presses"] as? [[String: Any]])?.count ?? 0 >= 2 }
        let presses = s1["presses"] as? [[String: Any]] ?? []
        XCTAssertGreaterThanOrEqual(presses.count, 2, "both taps reached the app")
        let t = presses.suffix(2).map { $0["t"] as? Double ?? 0 }, adv = presses.suffix(2).map { $0["advanced"] as? Bool ?? false }
        let gap = t[1] - t[0]
        note("B1 measured gap", String(format: "gap %.3f s; advanced %@ / %@", gap, "\(adv[0])", "\(adv[1])"))
        shot("B1 after two taps")
        guard gap < 0.25 else { throw XCTSkip(String(format: "not exercised: XCUITest's taps were %.3f s apart (≥ 0.25)", gap)) }
        XCTAssertEqual(adv, [true, false], String(format: "gap %.3f s: the first advances, the second is ignored", gap))
        XCTAssertEqual(s1["story_line"] as? Int, line0 + 1, "one box advanced")
    }

    /// 15b (Combat AC24): holding ▶ 5 s at the start of training stops the camera at the cap and the hero at
    /// cap + W − enemy_reach − hero_edge_margin (1060 with today's tuning); nothing stays held.
    func test_15b_holding_right_in_training_stops_at_the_cap() {
        launch(["-startScreen", "play", "-beat", "4"])
        waitFor(5) { $0["train_cap"] is Double }
        pad("right").press(forDuration: 5)
        let s = waitFor(2) { self.held($0).isEmpty }
        let cap = s["train_cap"] as? Double ?? .nan, cam = s["cam"] as? Double ?? .nan, x = s["hero_x"] as? Double ?? .nan
        note("15b", "cap \(cap) cam \(cam) hero_x \(x) x_start \(s["x_start"] ?? "?")")
        XCTAssertEqual(cam, cap, accuracy: 0.001, "the camera stopped at the cap")
        XCTAssertEqual(x, cap + 1060, accuracy: 0.001, "the hero stopped at the right limit")
        XCTAssertEqual(held(s), [])
        shot("15b after holding ▶ 5 s")
    }
}

/// r7 additions (iOS QC r6): the title card is display only, one landed hit in slow motion (pop contrast and
/// AC13 contact), the entry lock under an Attack mash (B7), and a short run whose saved stars survive a relaunch.
final class MoreCasesUITests: UITestBase {

    /// Title AC4e: a tap on the hero card does nothing (no screen change, no button fires).
    func test_a_tap_on_the_title_card_does_nothing() {
        launch(["-resetProgress", "YES"])
        let s0 = waitFor(5) { $0["title_card_box"] != nil }
        XCTAssertEqual(s0["screen"] as? String, "title")
        point(s0["title_card_box"] as! [Double]).tap()
        Thread.sleep(forTimeInterval: 0.8)
        let s1 = state()
        XCTAssertEqual(s1["screen"] as? String, "title", "still the title")
        XCTAssertFalse(log(s1).contains { $0.0.hasPrefix("fire:") }, "no button fired: \(log(s1).map(\.0))")
        shot("title after a card tap")
    }

    /// One landed hit, slowed ×10 (`-timeScale 0.1`, the same fixed steps): screenshots of the AC13 contact
    /// (the padded tip on the hero's chest, ≈ 0.5 s real here) and of the "Ối!" pop on the camp sky.
    func test_one_landed_hit_in_slow_motion_for_contact_and_pop_screenshots() {
        launch(["-startScreen", "play", "-beat", "5", "-stage", "telegraph", "-timeScale", "0.1"])
        let s = waitFor(60) { ($0["strike"] as? Bool == true) && ($0["hero_hurt"] as? Bool == true) }
        XCTAssertEqual(s["strike"] as? Bool, true, "a strike landed")
        shot("AC13 contact (slow motion)")
        Thread.sleep(forTimeInterval: 0.6); shot("after contact: pushed pose")
        Thread.sleep(forTimeInterval: 1.5); shot("Ối! pop on the camp sky")
        note("hit", "slow motion ×0.1; strike landed at uptime \(s["now"] ?? "?")")
    }

    /// B7 (Input Rule 13): Attack mashed through the end of reach-the-flag keeps the first ending box ≥ 0.6 s.
    /// Uses the debug shortcut `-stage flag` (the hero at the flag, encounters counted as cleared): a test aid,
    /// reported here, never a real run.
    func test_an_attack_mash_through_the_beat_end_keeps_the_first_ending_box() throws {
        launch(["-startScreen", "play", "-beat", "5", "-stage", "flag"])
        let attack = pad("attack")
        var taps = 0
        let end = Date().addingTimeInterval(6)
        while Date() < end { attack.tap(); taps += 1 }
        let entries = log(state())
        note("B7 log (shortcut: -stage flag)", entries.map { String(format: "%@ @ %.3f", $0.0, $0.1) }.joined(separator: "\n") + "\ntaps \(taps)")
        let first = try XCTUnwrap(entries.first { $0.0.hasPrefix("ending|0|") }, "the ending showed")
        guard let second = entries.first(where: { $0.0.hasPrefix("ending|1|") || ($0.1 > first.1 && $0.0.hasPrefix("quiz")) }) else {
            throw XCTSkip("the mash never advanced the first ending box within 6 s (taps \(taps))")
        }
        XCTAssertGreaterThanOrEqual(second.1 - first.1, 0.6 - 1.0 / 60, "the first ending box stayed ≥ screen_enter_lock")
        shot("B7 after the mash")
    }

    /// A short run: Bỏ qua → the skip warning → Keep reading; the quiz answered right ×5; results 3★; a
    /// relaunch keeps the stars on the title card. The quiz is reached by a debug jump, so the medal (D-07: a
    /// fully read and played run) is NOT asserted here.
    func test_skip_warning_keep_reading_then_stars_survive_a_relaunch() throws {
        launch(["-startScreen", "intro", "-resetProgress", "YES"])
        Thread.sleep(forTimeInterval: 0.8) // past the entry lock
        try XCTUnwrap(button("skip")).tap()
        XCTAssertEqual(waitFor(3) { $0["skip_warning"] as? Bool == true }["skip_warning"] as? Bool, true, "the skip warning opened")
        try XCTUnwrap(button("keepReading")).tap()
        XCTAssertEqual(waitFor(3) { $0["skip_warning"] as? Bool == false }["skip_warning"] as? Bool, false, "Keep reading closed it")
        XCTAssertEqual(state()["screen"] as? String, "intro")
        quit()
        launch(["-startScreen", "quiz"])
        for _ in 0..<5 {
            let s = waitFor(5) { ($0["quiz"] as? [String: Any])?["picked"] as? Bool == false }
            let q = try XCTUnwrap(s["quiz"] as? [String: Any]), slot = q["correct_slot"] as! Int
            Thread.sleep(forTimeInterval: 0.7) // past the entry lock / debounce
            try XCTUnwrap(button("card\(slot)")).tap()
            _ = waitFor(5) { ($0["quiz"] as? [String: Any])?["can_advance"] as? Bool == true }
            Thread.sleep(forTimeInterval: 0.3)
            try XCTUnwrap(button("next")).tap()
            _ = waitFor(5) { $0["screen"] as? String == "results" || ($0["quiz"] as? [String: Any])?["picked"] as? Bool == false }
        }
        let r = waitFor(5) { $0["screen"] as? String == "results" }
        XCTAssertEqual(r["screen"] as? String, "results"); XCTAssertEqual(r["stars"] as? Int, 3)
        shot("results 3★")
        quit()
        launch([])
        let t = waitFor(5) { $0["title_card"] != nil }
        XCTAssertEqual((t["title_card"] as? [String: Any])?["stars"] as? Int, 3, "the saved best survives a relaunch")
        note("run", "quiz reached by a debug jump: the medal is not asserted (D-07)")
        shot("title after relaunch")
    }

    /// Android QC r6: the training card appears while ◀ is being tapped (Bỏ qua sits on ◀'s spot): the entry lock
    /// drops those taps, so no skip warning opens. Debug start `-stage walkto` (the hero just short of the beat).
    func test_left_taps_as_the_training_card_appears_open_no_skip_warning() throws {
        launch(["-startScreen", "play", "-beat", "4", "-stage", "walkto"])
        let left = pad("left"), right = pad("right")
        right.press(forDuration: 0.6) // arrive: the card appears during this press
        // tap ◀ only while the rolling lock can hold (its cap is 1.5 s from the card's entry); past the cap a
        // tap on the Bỏ qua spot is a real press and may open the warning, which is correct
        let cardAt = log(state()).first { $0.0.contains("beatCard") }?.1 ?? (state()["now"] as? Double ?? 0)
        while (state()["now"] as? Double ?? .infinity) - cardAt < 1.2 { left.tap() }
        let s = state(), entries = log(s)
        note("card mash", entries.map { String(format: "%@ @ %.3f", $0.0, $0.1) }.joined(separator: "\n"))
        let card = try XCTUnwrap(entries.first { $0.0.contains("beatCard") }, "the training card appeared")
        guard let firstSkip = entries.first(where: { $0.0 == "fire:skip" }) else {
            throw XCTSkip("no tap reached the Bỏ qua spot while the card showed")
        }
        guard firstSkip.1 - card.1 < 0.6 else {
            throw XCTSkip(String(format: "not exercised: the first tap came %.2f s after the card (≥ the lock)", firstSkip.1 - card.1))
        }
        XCTAssertEqual(s["skip_warning"] as? Bool, false, "no skip warning opened under the taps")
        shot("training card after the ◀ taps")
    }
}
