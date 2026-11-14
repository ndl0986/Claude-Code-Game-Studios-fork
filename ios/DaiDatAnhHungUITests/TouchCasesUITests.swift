import XCTest

/// QC's touch cases as UI tests (TASK-023 G): real touches on the Simulator, no macOS Accessibility needed.
/// Each test launches a Debug build at a debug screen, drives the pads by coordinates from the app's own
/// layout, and asserts on the debug-only `debugState` element (a JSON dump of the game state).
final class TouchCasesUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
    }

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
