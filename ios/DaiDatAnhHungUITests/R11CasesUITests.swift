import XCTest

/// iOS r11 (TASK-023 W17, W18, W20; parity with Android r14 beea731), real touches on the Simulator.
/// W18: the pause menu's "Về bản đồ" opens the leave card; only the card's "Về bản đồ" leaves (to the title for now,
/// the map is TASK-025); its "Chơi tiếp" returns to the menu with the run intact. W20: the skip warning's
/// "Keep reading" is the big default button on the right. W17: the hold-meter's special pad shows a fist.
final class R11CasesUITests: UITestBase {
    func fires(_ s: [String: Any]) -> [(id: String, t: Double, locked: Bool)] {
        (s["fires"] as? [[String: Any]] ?? []).map { ($0["id"] as? String ?? "", $0["t"] as? Double ?? 0, $0["locked"] as? Bool ?? false) }
    }
    var uptime: Double { ProcessInfo.processInfo.systemUptime } // the simulator's processes share the press clock

    /// `launch` with a chosen language (the base launch forces EN).
    func launch(_ args: [String], lang: String) {
        app = XCUIApplication()
        app.launchArguments = args + ["-lang", lang]
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["debugState"].waitForExistence(timeout: 15), "debugState (Debug build only)")
        _ = waitFor(5) { $0["screen"] as? String != nil }
    }

    /// (a) The menu's "Về bản đồ" opens the card. Taps on it within the rolling entry lock (0.6 s after opening, each
    /// dropped press restarting it, capped at 1.5 s) do nothing; a tap ≥ 0.6 s after the last dropped press works.
    func test_a_the_menus_to_the_map_opens_the_card_and_early_taps_on_it_do_nothing() throws {
        var misses: [String] = []
        for attempt in 1...3 {
            launch(["-startScreen", "play", "-beat", "2"])
            Thread.sleep(forTimeInterval: 0.8)
            try XCTUnwrap(button("pause")).tap()
            _ = waitFor(3) { $0["screen"] as? String == "pause" }
            let toMap = try XCTUnwrap(button("pauseMap"))
            toMap.tap()
            let s0 = waitFor(3) { $0["leave_card"] as? Bool == true }
            XCTAssertEqual(s0["leave_card"] as? Bool, true, "the menu's Về bản đồ opened the card")
            XCTAssertEqual(s0["screen"] as? String, "pause", "nothing left yet")
            let e = try XCTUnwrap(s0["entered_at"] as? Double, "the card is a lock context")
            let keep = try XCTUnwrap(button("leaveKeep")), go = try XCTUnwrap(button("leaveGo"))
            go.tap() // early: aimed inside the lock
            let s1 = waitFor(1) { s in self.fires(s).contains { $0.id == "leaveGo" && $0.t > e } }
            guard let early = fires(s1).last(where: { $0.id == "leaveGo" && $0.t > e }) else { misses.append("no fire logged"); quit(); continue }
            note("early tap, attempt \(attempt)", String(format: "card entered %.3f; leaveGo at +%.3f s, locked %@", e, early.t - e, "\(early.locked)"))
            guard early.locked else { misses.append(String(format: "early tap at +%.3f s was past the lock", early.t - e)); quit(); continue }
            XCTAssertEqual(state()["screen"] as? String, "pause", "a locked Về bản đồ on the card did nothing")
            XCTAssertEqual(state()["leave_card"] as? Bool, true)
            shot("r11 (a) the card after an early tap: still up")
            // ≥ 0.6 s after the last dropped press (and the card fully in): Chơi tiếp works
            let until = min(early.t + 0.6, e + 1.5)
            let d = until + 0.15 - uptime; if d > 0 { Thread.sleep(forTimeInterval: d) }
            keep.tap()
            let s2 = waitFor(3) { $0["leave_card"] as? Bool == false }
            XCTAssertEqual(s2["leave_card"] as? Bool, false, "Chơi tiếp after the lock closed the card")
            XCTAssertEqual(s2["screen"] as? String, "pause", "back to the menu")
            return
        }
        throw XCTSkip("the early tap never landed inside the lock in 3 launches: " + misses.joined(separator: "; "))
    }

    /// (b) The card's "Chơi tiếp" returns to the menu with the run intact; resume continues the same beat.
    func test_b_keep_playing_returns_to_the_menu_and_resume_continues_the_same_beat() throws {
        launch(["-startScreen", "pause", "-beat", "2", "-stage", "leave"])
        let s0 = waitFor(3) { $0["leave_card"] as? Bool == true }
        let beat = try XCTUnwrap(s0["beat"] as? Int)
        Thread.sleep(forTimeInterval: 1.6) // past the card's lock cap
        try XCTUnwrap(button("leaveKeep")).tap()
        let s1 = waitFor(3) { $0["leave_card"] as? Bool == false }
        XCTAssertEqual(s1["screen"] as? String, "pause"); shot("r11 (b) back to the menu after Chơi tiếp")
        try XCTUnwrap(button("resume")).tap()
        let s2 = waitFor(3) { $0["screen"] as? String == "play" }
        XCTAssertEqual(s2["screen"] as? String, "play", "resumed")
        XCTAssertEqual(s2["beat"] as? Int, beat, "the same beat: the run is intact")
    }

    /// (c) Only the card's "Về bản đồ" leaves, to the title (no map screen yet, TASK-025).
    func test_c_the_cards_to_the_map_leaves_to_the_title() throws {
        launch(["-startScreen", "pause", "-beat", "2", "-stage", "leave"])
        _ = waitFor(3) { $0["leave_card"] as? Bool == true }
        Thread.sleep(forTimeInterval: 1.6)
        try XCTUnwrap(button("leaveGo")).tap()
        let s = waitFor(3) { $0["screen"] as? String == "title" }
        XCTAssertEqual(s["screen"] as? String, "title", "Về bản đồ left the run")
        XCTAssertEqual(s["leave_card"] as? Bool, false)
        shot("r11 (c) the title after the card's Về bản đồ")
    }

    /// (e) For QC (iOS QC r10 couldn't assess "home from pause"; in r11 that path is the leave card): from a run in
    /// play, real taps only: pause → the menu's "Về bản đồ" → (after the card's lock) the card's "Về bản đồ" → the
    /// title, with the run discarded (Start begins at the intro again).
    func test_e_leaving_from_the_pause_menu_by_real_taps_reaches_the_title() throws {
        launch(["-startScreen", "play", "-beat", "2"])
        Thread.sleep(forTimeInterval: 0.8)
        try XCTUnwrap(button("pause")).tap()
        _ = waitFor(3) { $0["screen"] as? String == "pause" }
        try XCTUnwrap(button("pauseMap")).tap()
        XCTAssertEqual(waitFor(3) { $0["leave_card"] as? Bool == true }["leave_card"] as? Bool, true, "the card opened")
        Thread.sleep(forTimeInterval: 1.6) // past the card's lock cap
        try XCTUnwrap(button("leaveGo")).tap()
        let s = waitFor(3) { $0["screen"] as? String == "title" }
        XCTAssertEqual(s["screen"] as? String, "title", "the card's Về bản đồ reached the title")
        shot("r11 (e) the title after leaving from the pause menu")
        Thread.sleep(forTimeInterval: 0.8)
        try XCTUnwrap(button("start")).tap()
        let s2 = waitFor(3) { $0["screen"] as? String == "intro" }
        XCTAssertEqual(s2["screen"] as? String, "intro", "a new run starts at the intro: the old run was discarded")
        XCTAssertEqual(s2["story_line"] as? Int, 0)
    }

    /// (f) iOS-R10-01 fix, smoothness: with the sim on the press clock, a 3 s walk (▶ held) runs one step a frame as
    /// steadily as the r10 clock did. The app counts frames by steps run, on this clock and on a shadow clock fed
    /// SpriteKit's currentTime (r10); 0 or 2+ steps in a frame is a judder frame at 60 Hz. Recorded, and this clock
    /// must not judder more than the shadow by more than a frame or two.
    func test_f_a_walk_runs_one_step_a_frame_on_the_press_clock() throws {
        for (beat, name) in [("1", "walk"), ("4", "training walk")] {
            launch(["-startScreen", "play", "-beat", beat])
            Thread.sleep(forTimeInterval: 1)
            func hist() -> (sys: [Int], ct: [Int]) {
                let h = state()["step_hist"] as? [String: [Int]] ?? [:]
                return (h["sys"] ?? [0, 0, 0, 0], h["ct"] ?? [0, 0, 0, 0])
            }
            let a = hist(), x0 = state()["hero_x"] as? Double
            pad("right").press(forDuration: 3)
            Thread.sleep(forTimeInterval: 0.3)
            let b = hist(), x1 = state()["hero_x"] as? Double
            let sys = zip(b.sys, a.sys).map { $0 - $1 }, ct = zip(b.ct, a.ct).map { $0 - $1 }
            let judder = { (h: [Int]) in h[0] + h[2] + h[3] }
            note("\(name): frames by steps 0/1/2/3+", "press clock (r11): \(sys), judder frames \(judder(sys))\ncurrentTime (r10): \(ct), judder frames \(judder(ct))\nhero x \(x0 ?? -1) → \(x1 ?? -1)")
            XCTAssertGreaterThan(sys[1], 100, "\(name): the walk ran")
            XCTAssertLessThanOrEqual(judder(sys), judder(ct) + 2, "\(name): no more judder than the r10 clock")
            quit()
        }
    }

    /// (d) W20: "Keep reading" is on the right, "Skip anyway" on the left; each does its own thing.
    func test_d_skip_warning_keep_reading_on_the_right_skip_anyway_on_the_left() throws {
        launch(["-startScreen", "intro", "-resetProgress", "YES"]) // a saved medal would skip without the warning
        Thread.sleep(forTimeInterval: 0.8)
        try XCTUnwrap(button("skip")).tap()
        // the warning's buttons are published on the frame after it opens
        let s = waitFor(3) { ($0["buttons"] as? [String: [Double]])?["keepReading"] != nil }
        let b = try XCTUnwrap(s["buttons"] as? [String: [Double]])
        let keep = try XCTUnwrap(b["keepReading"]), skip = try XCTUnwrap(b["skipAnyway"])
        XCTAssertGreaterThan(keep[0], skip[0], "Keep reading is on the right (W20)")
        XCTAssertEqual(keep[1], skip[1], accuracy: 0.01, "one row")
        Thread.sleep(forTimeInterval: 0.7)
        point(keep).tap()
        let s1 = waitFor(3) { $0["skip_warning"] as? Bool == false }
        XCTAssertEqual(s1["screen"] as? String, "intro", "the right-hand button kept reading")
        let line = s1["story_line"] as? Int
        quit()
        launch(["-startScreen", "intro", "-resetProgress", "YES"]) // a saved medal would skip without the warning
        Thread.sleep(forTimeInterval: 0.8)
        try XCTUnwrap(button("skip")).tap()
        _ = waitFor(3) { $0["skip_warning"] as? Bool == true }
        Thread.sleep(forTimeInterval: 0.7)
        try XCTUnwrap(button("skipAnyway")).tap()
        let s2 = waitFor(3) { $0["skip_warning"] as? Bool == false }
        XCTAssertTrue(s2["screen"] as? String != "intro" || s2["story_line"] as? Int != line, "the left-hand button skipped the section")
    }

    /// r11 screen pass (evidence, game-dev-ios pre-freeze): the fist pad, the training banner pad, the skip warning,
    /// the pause menu and the leave card (VI and EN), and the card mid-slide (×0.1).
    func test_r11_screens_fist_skip_warning_pause_and_leave_card() throws {
        for lang in ["vi", "en"] {
            launch(["-startScreen", "play", "-beat", "3"], lang: lang)
            _ = waitFor(3) { ($0["pads"] as? [String: [Double]])?["special"] != nil }
            Thread.sleep(forTimeInterval: 0.5); shot("r11 hold-meter fist pad \(lang)"); quit()
            launch(["-startScreen", "intro", "-stage", "skipwarning"], lang: lang)
            _ = waitFor(3) { $0["skip_warning"] as? Bool == true }
            Thread.sleep(forTimeInterval: 0.5); shot("r11 skip warning \(lang)"); quit()
            launch(["-startScreen", "pause", "-beat", "2"], lang: lang)
            _ = waitFor(3) { $0["screen"] as? String == "pause" }
            Thread.sleep(forTimeInterval: 0.5); shot("r11 pause menu \(lang)"); quit()
            launch(["-startScreen", "pause", "-beat", "2", "-stage", "leave"], lang: lang)
            _ = waitFor(3) { $0["leave_card"] as? Bool == true }
            Thread.sleep(forTimeInterval: 0.5); shot("r11 leave card \(lang)"); quit()
        }
        launch(["-startScreen", "play", "-beat", "4", "-stage", "finish"], lang: "vi")
        _ = waitFor(3) { ($0["pads"] as? [String: [Double]])?["special"] != nil }
        Thread.sleep(forTimeInterval: 0.5); shot("r11 training finish banner pad"); quit()
        // the slide, ×0.1: the menu, then Về bản đồ, a shot ~40% of the way in
        launch(["-startScreen", "pause", "-beat", "2", "-timeScale", "0.1"], lang: "vi")
        _ = waitFor(3) { $0["screen"] as? String == "pause" }
        try XCTUnwrap(button("pauseMap")).tap()
        _ = waitFor(3) { $0["leave_card"] as? Bool == true }
        Thread.sleep(forTimeInterval: 0.6); shot("r11 leave card sliding in (×0.1)")
    }
}
