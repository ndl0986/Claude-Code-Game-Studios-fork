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
        // QC r5 N1 / r7 NOT ASSESSED: a pop on a light (day) sky gets the ink outline: the partner's strike in the
        // training blocks step on the village sky, in slow motion
        quit()
        launch(["-startScreen", "play", "-beat", "4", "-stage", "blocks", "-timeScale", "0.1"])
        let d = waitFor(90) { $0["hero_hurt"] as? Bool == true }
        XCTAssertEqual(d["hero_hurt"] as? Bool, true, "the partner's strike landed (no block held)")
        Thread.sleep(forTimeInterval: 1.5); shot("Ối! pop on the day village sky (ink outline)")
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
        // QC r7: XCUITest's tap latency can land the first ◀ tap after the lock (0.695 s once), and then the case
        // can't tell anything. Each attempt checks, from the app's own press log, that the first Bỏ qua press came
        // while the lock was closed; up to 4 launches before it reports "not exercised".
        // iOS-R8-01 (QC r8, a flake): press 1 at +0.558 was locked and rolled the lock to ≈ +1.158; press 2 landed at
        // +1.293 under host load, a real press past the lock, and its warning failed the case. So the case stops
        // tapping once a tap could land past lock_until, and a late press past the rolled lock is not a failure.
        let latency = 0.2 // XCUITest tap latency margin (≈ 0.13 s seen under load in r8)
        let minLock = 0.6 - 1.0 / 60 // screen_enter_lock, one frame of slack
        var misses: [String] = []
        for attempt in 1...4 {
            launch(["-startScreen", "play", "-beat", "4", "-stage", "walkto"])
            let left = pad("left"), right = pad("right")
            right.press(forDuration: 0.5) // arrive: the card appears near the end of this press
            // tap ◀ only while the rolling lock can hold (its cap is 1.5 s from the card's entry); past the cap a
            // tap on the Bỏ qua spot is a real press and may open the warning, which is correct
            let cardAt = log(state()).first { $0.0.contains("beatCard") }?.1 ?? (state()["now"] as? Double ?? 0)
            while true {
                let s = state(), now = s["now"] as? Double ?? .infinity
                let lockEnd = s["lock_until"] as? Double ?? (cardAt + 0.6)
                if now - cardAt >= 1.2 || now + latency >= lockEnd { break }
                left.tap()
            }
            let s = state(), entries = log(s)
            let entered = s["entered_at"] as? Double ?? cardAt, lockUntil = s["lock_until"] as? Double
            let fires = (s["fires"] as? [[String: Any]] ?? []).filter { $0["id"] as? String == "skip" }
            func ms(_ v: Double?) -> String { v.map { String(format: "%+.0f ms", ($0 - entered) * 1000) } ?? "nil" }
            note("card mash, attempt \(attempt)", (
                [String(format: "entered_at %.3f; lock_until %@; now %@; card log %@", entered, ms(lockUntil), ms(s["now"] as? Double), ms(cardAt))]
                + fires.map { f in let t = f["t"] as? Double; return String(format: "fire skip t %.3f (%@) locked %@", t ?? 0, ms(t), "\(f["locked"] ?? "?")") }
                + entries.map { String(format: "%@ @ %.3f (%@)", $0.0, $0.1, ms($0.1)) }).joined(separator: "\n"))
            // hard: no press beats the minimum lock, whatever the tap latency
            for f in fires where f["locked"] as? Bool == false {
                XCTAssertGreaterThanOrEqual((f["t"] as? Double ?? 0) - entered, minLock, "an unlocked Bỏ qua press came inside the 0.6 s lock (attempt \(attempt))")
                if let end = lockUntil { XCTAssertGreaterThanOrEqual(f["t"] as? Double ?? 0, end - 1.0 / 60, "an unlocked Bỏ qua press came before the rolled lock's end (attempt \(attempt))") }
            }
            if let first = fires.first, first["locked"] as? Bool == true {
                if fires.allSatisfy({ $0["locked"] as? Bool == true }) {
                    XCTAssertEqual(s["skip_warning"] as? Bool, false, "no skip warning opened under the taps (attempt \(attempt))")
                } else {
                    note("late press past the lock, attempt \(attempt)", "a press landed after the rolled lock: a real press, so the warning may open (correct)")
                }
                shot("training card after the ◀ taps")
                return
            }
            misses.append(fires.first.map { String(format: "first Bỏ qua press %.2f s after the card, lock open", ($0["t"] as? Double ?? 0) - entered) } ?? "no tap reached Bỏ qua")
            quit()
        }
        throw XCTSkip("not exercised in 4 launches: " + misses.joined(separator: "; "))
    }
}

/// r8 cases: Input Rule 13b (every story box and dialogue line takes the rolling lock) and story-screens §5.2 /
/// hud §5 (placeholder still, no play sprites, no top stack on story and dialogue screens).
final class R8CasesUITests: UITestBase {
    /// Taps the Tiếp/ask spot every ~0.35 s while `inside` holds (or `limit` s pass); returns the tap count.
    func mash(_ spot: XCUICoordinate, limit: Double, while inside: ([String: Any]) -> Bool) -> Int {
        var taps = 0
        let end = Date().addingTimeInterval(limit)
        while Date() < end && inside(state()) {
            let t0 = Date(); spot.tap(); taps += 1
            let left = 0.35 - Date().timeIntervalSince(t0); if left > 0 { Thread.sleep(forTimeInterval: left) }
        }
        return taps
    }

    /// The boxes in the debug log whose place starts with `prefix`, in order, with how long each stayed (to the next
    /// logged place). The log times are when a place was first drawn, so a hold is measured to ±1 frame.
    func holds(_ entries: [(String, Double)], _ prefix: String) -> [(String, Double)] {
        // only place changes count: the "fire:<id>" press entries in the same log are skipped
        let places = entries.filter { !$0.0.hasPrefix("fire:") }
        var out: [(String, Double)] = []
        for (i, e) in places.enumerated() where e.0.hasPrefix(prefix) && i + 1 < places.count { out.append((e.0, places[i + 1].1 - e.1)) }
        return out
    }

    /// Input AC22 / dialogue AC8: the Bình Than dialogue's 9 lines (the ask lines included) under a tap every 0.35 s on
    /// the button's spot (Tiếp and the ask button share it): every line holds ≥ 1.5 s and none is skipped.
    func test_a_mash_through_the_dialogue_holds_every_line() throws {
        launch(["-startScreen", "play", "-beat", "2"])
        let spot = try XCTUnwrap(button("next"))
        let taps = mash(spot, limit: 40) { s in
            let ph = s["phase"] as? String ?? ""; return s["screen"] as? String == "play" && (ph == "dialogueLine")
        }
        let entries = log(state())
        note("dialogue mash log", entries.map { String(format: "%@ @ %.3f", $0.0, $0.1) }.joined(separator: "\n") + "\ntaps \(taps)")
        let lines = holds(entries, "play|0|dialogueLine|")
        XCTAssertEqual(lines.map { $0.0.split(separator: "|").last.map(String.init) ?? "" }, (0..<9).map(String.init), "all 9 lines, in order, none skipped")
        for (place, held) in lines { XCTAssertGreaterThanOrEqual(held, 1.5 - 0.05, "\(place) held \(held) s under the mash") }
        shot("after the dialogue mash")
    }

    /// Story AC11 / Input AC21: the intro under a tap every 0.35 s: every box holds ≥ 1.5 s.
    func test_a_mash_through_the_intro_holds_every_box() throws {
        launch(["-startScreen", "intro"])
        let spot = try XCTUnwrap(button("next"))
        let taps = mash(spot, limit: 20) { $0["screen"] as? String == "intro" }
        let entries = log(state())
        note("intro mash log", entries.map { String(format: "%@ @ %.3f", $0.0, $0.1) }.joined(separator: "\n") + "\ntaps \(taps)")
        let boxes = holds(entries, "intro|")
        XCTAssertGreaterThanOrEqual(boxes.count, 4, "every intro box shown")
        for (place, held) in boxes { XCTAssertGreaterThanOrEqual(held, 1.5 - 0.05, "\(place) held \(held) s under the mash") }
    }

    /// Input Rule 13 (QC r7 NOT ASSESSED): pause and sound are exempt from the entry lock. On an intro box, a Tiếp
    /// press advances (box 2 starts its lock), then sound and pause are tapped at once: the app's press log shows
    /// they came while the lock was closed, and both took effect (muted toggled, the pause screen open).
    func test_pause_and_sound_respond_inside_the_lock() throws {
        var misses: [String] = []
        for attempt in 1...4 {
            launch(["-startScreen", "intro"])
            Thread.sleep(forTimeInterval: 1.6) // box 1's lock is over
            let next = try XCTUnwrap(button("next")), mute = try XCTUnwrap(button("mute")), pause = try XCTUnwrap(button("pause"))
            let muted0 = state()["muted"] as? Bool ?? false
            next.tap(); mute.tap(); next.tap(); pause.tap() // the second Tiếp rolls box 2's lock (or opens box 3's)
            let s = waitFor(3) { $0["screen"] as? String == "pause" }
            let fires = s["fires"] as? [[String: Any]] ?? []
            func lockedPress(_ id: String) -> Bool? { fires.last { $0["id"] as? String == id }?["locked"] as? Bool }
            note("presses, attempt \(attempt)", fires.map { "\($0["id"] ?? "?") @ \($0["t"] ?? "?") locked \($0["locked"] ?? "?")" }.joined(separator: "\n"))
            if lockedPress("mute") == true && lockedPress("pause") == true {
                XCTAssertEqual(s["muted"] as? Bool, !muted0, "sound toggled inside the lock")
                XCTAssertEqual(s["screen"] as? String, "pause", "pause opened inside the lock")
                shot("pause opened during a locked story box")
                return
            }
            misses.append("mute locked \(lockedPress("mute").map(String.init) ?? "-"), pause locked \(lockedPress("pause").map(String.init) ?? "-")")
            quit()
        }
        throw XCTSkip("not exercised in 4 launches: " + misses.joined(separator: "; "))
    }

    /// Story AC12 / hud §5: the placeholder still where the spec puts it, no play sprites and no top stack on the
    /// intro, a beat card, a caption and the dialogue; play itself still draws both.
    func test_story_screens_show_the_placeholder_and_no_sprites_or_top_stack() throws {
        func check(_ args: [String], _ name: String, placeholder: [Double]?, story: Bool = true) {
            launch(args)
            let s = waitFor(5) { _ in false } // let a few frames publish
            if let p = placeholder { XCTAssertEqual(s["placeholder"] as? [Double], p, "\(name): the placeholder box") }
            else { XCTAssertTrue(s["placeholder"] is NSNull, "\(name): no placeholder") }
            if s["screen"] as? String == "play" {
                XCTAssertEqual(s["sprites_visible"] as? Bool, !story, "\(name): play sprites")
                XCTAssertEqual(s["dots_visible"] as? Bool, !story, "\(name): the beat dots")
            }
            shot(name); quit()
        }
        check(["-startScreen", "intro"], "intro", placeholder: [512, 45, 256, 256])
        check(["-startScreen", "play", "-beat", "1", "-stage", "card"], "beat card", placeholder: [536, 25, 208, 208])
        check(["-hero", "sample", "-startScreen", "play", "-beat", "2", "-stage", "caption"], "caption", placeholder: [512, 45, 256, 256])
        check(["-startScreen", "play", "-beat", "2", "-stage", "ask"], "dialogue", placeholder: nil)
        check(["-startScreen", "ending"], "ending", placeholder: nil)
        check(["-startScreen", "play", "-beat", "4"], "training (play)", placeholder: nil, story: false)
    }
}

/// r9 cases: Mission flow Rule 7c (AC32), the training finish's banner moment, with real touches.
final class R9CasesUITests: UITestBase {
    /// The place log's time for the first entry (not a fire) on `screen` in `phase` of beat `beat` at or after `t`
    /// (a place is "screen|storyLine|phase|beat|cardLine|captionLine|lineIndex").
    func at(_ entries: [(String, Double)], screen: String = "play", _ phase: String, beat: Int, after t: Double = 0) -> Double? {
        entries.first {
            let f = $0.0.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            return !$0.0.hasPrefix("fire:") && f.count >= 4 && f[0] == screen && f[2] == phase && f[3] == "\(beat)" && $0.1 >= t
        }?.1
    }

    /// AC32: Cờ tapped, then the Cờ spot tapped every 0.2 s through the hold: the walk starts ≥ 1.5 s after the
    /// Cờ tap and no tap carries into it.
    func test_the_finish_hold_lasts_and_drops_taps() throws {
        launch(["-startScreen", "play", "-beat", "4", "-stage", "finish"])
        let flag = pad("special")
        flag.tap()
        let end = Date().addingTimeInterval(1.7) // past finish_hold (1.5)
        while Date() < end { let t0 = Date(); flag.tap(); let left = 0.2 - Date().timeIntervalSince(t0); if left > 0 { Thread.sleep(forTimeInterval: left) } }
        let s = waitFor(3) { $0["phase"] as? String == "walkTo" }, entries = log(s)
        note("finish hold log", entries.map { String(format: "%@ @ %.3f", $0.0, $0.1) }.joined(separator: "\n"))
        let hold = try XCTUnwrap(at(entries, "beatEnd", beat: 3), "the hold started")
        let walk = try XCTUnwrap(at(entries, "walkTo", beat: 4, after: hold), "the walk started")
        XCTAssertGreaterThanOrEqual(walk - hold, 1.5 - 0.05, "the banner moment held finish_hold")
        XCTAssertEqual(s["held"] as? [String], [], "nothing held into the walk")
        shot("after the finish hold")
    }

    /// AC32: pause 0.3 s into the hold, then resume: the banner-up still lasts ≥ 0.8 s after the resume.
    func test_a_resume_restarts_the_hold_to_rise_done() throws {
        launch(["-startScreen", "play", "-beat", "4", "-stage", "finish"])
        let flag = pad("special"), pause = try XCTUnwrap(button("pause")) // looked up first, so the pause lands 0.3 s in
        flag.tap()
        Thread.sleep(forTimeInterval: 0.3)
        pause.tap()
        _ = waitFor(3) { $0["screen"] as? String == "pause" }
        shot("paused in the hold")
        try XCTUnwrap(button("resume")).tap()
        let s = waitFor(4) { $0["phase"] as? String == "walkTo" }
        let entries = log(s), fires = s["fires"] as? [[String: Any]] ?? []
        note("resume log", entries.map { String(format: "%@ @ %.3f", $0.0, $0.1) }.joined(separator: "\n"))
        XCTAssertNotNil(at(entries, screen: "pause", "beatEnd", beat: 3), "the pause opened inside the hold")
        let resumed = try XCTUnwrap(fires.last { $0["id"] as? String == "resume" }?["t"] as? Double, "resume pressed")
        let walk = try XCTUnwrap(at(entries, "walkTo", beat: 4, after: resumed), "the walk started")
        XCTAssertGreaterThanOrEqual(walk - resumed, 0.8 - 0.05, "≥ 0.8 s of banner-up after the resume")
    }
}
