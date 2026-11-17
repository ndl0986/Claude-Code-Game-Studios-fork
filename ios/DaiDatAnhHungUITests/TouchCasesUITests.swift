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
    /// The app's place log (and fires); its touch-down entries ("touch:x,y:button", r9) only when `touches`.
    func log(_ s: [String: Any], touches: Bool = false) -> [(String, Double)] {
        (s["log"] as? [[String: Any]] ?? []).map { ($0["place"] as? String ?? "", $0["t"] as? Double ?? 0) }.filter { touches || !$0.0.hasPrefix("touch:") }
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

    /// A short run: Bỏ qua → the skip warning → Keep reading; the quiz answered right ×5; results 3★. The quiz is
    /// reached by a debug jump, so (r9) nothing is saved: after a relaunch the title shows 0★ and no medal.
    func test_skip_warning_keep_reading_then_a_jumped_quiz_saves_nothing() throws {
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
        // r9 (iOS QC r8 medal finding): a debug-jumped run never writes progress, so the title shows no stars and no
        // medal; a real run's save surviving a relaunch is R9CasesUITests.test_D (Start, no jumps)
        let card = t["title_card"] as? [String: Any]
        XCTAssertEqual(card?["stars"] as? Int, 0, "the jumped quiz saved no stars")
        XCTAssertEqual(card?["medal"] as? Bool, false, "and no medal")
        note("run", "quiz reached by a debug jump: nothing saved (r9)")
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

    /// AC32: pause 0.3 s into the hold, then resume: the banner-up lasts the full 0.833 s after the resume (r10 N1).
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
        // r10 N1: the frame that leaves pause credits no time, so the 50 remaining steps (0.833 s) all run after the
        // press: never early, and late by at most the press-to-frame gap plus a frame or two of logging
        let up = walk - resumed
        note("banner-up after the resume", String(format: "%.3f s (expected 0.833 ≤ t ≤ 0.850, plus logging latency)", up))
        XCTAssertGreaterThanOrEqual(up, 0.833 - 0.005, "the banner-up after a resume is never short (r9: 0.800–0.812)")
        XCTAssertLessThan(up, 0.833 + 0.1, "and not much longer")
    }

    /// r9 screen pass (evidence, game-dev-ios pre-freeze): the Cờ hint hand, the banner rise frames and the partner's
    /// placement cases (mission-flow 7c): (a) facing right, front spot; (b) near the left edge facing left, beyond the
    /// banner; (c) at the right cap facing right; (d) after a resume, full opacity. Screenshots only, plus the hold log.
    func test_r9_screens_banner_partner_and_hand() throws {
        func hx(_ s: [String: Any]) -> String { String(format: "hero_x %.0f cam %.0f (screen x %.0f)", s["hero_x"] as? Double ?? 0, s["cam"] as? Double ?? 0, (s["hero_x"] as? Double ?? 0) - (s["cam"] as? Double ?? 0)) }
        // the Cờ hand (Hints Rule 6): after hint_delay with no tap
        launch(["-startScreen", "play", "-beat", "4", "-stage", "finish"])
        Thread.sleep(forTimeInterval: 5); shot("r9 Cờ hint hand"); note("hand", "\(state()["hints"] ?? "?")"); quit()
        // (a) facing right, front spot; the rise frames at ×0.1
        launch(["-startScreen", "play", "-beat", "4", "-stage", "finish", "-timeScale", "0.1"])
        note("(a) start", hx(state())); pad("special").tap()
        for (wait, name) in [(0.6, "0.06 s: partner fading in, banner low"), (2.0, "0.26 s: fade done, banner rising"), (2.5, "0.51 s"), (2.5, "0.76 s: banner up, partner in place")] {
            Thread.sleep(forTimeInterval: wait); shot("r9 (a) rise \(name)")
        }
        quit()
        // (b) near the left edge facing left: the partner beyond the banner
        launch(["-startScreen", "play", "-beat", "4", "-stage", "finish", "-timeScale", "0.25"])
        pad("left").press(forDuration: 9); note("(b) start", hx(state())); pad("special").tap()
        Thread.sleep(forTimeInterval: 0.5); shot("r9 (b) left edge facing left, 0.1 s")
        Thread.sleep(forTimeInterval: 2.3); shot("r9 (b) left edge facing left, banner up")
        quit()
        // (c) at the right cap facing right
        launch(["-startScreen", "play", "-beat", "4", "-stage", "finish", "-timeScale", "0.25"])
        pad("right").press(forDuration: 9); note("(c) start", hx(state())); pad("special").tap()
        Thread.sleep(forTimeInterval: 0.5); shot("r9 (c) right cap facing right, 0.1 s")
        Thread.sleep(forTimeInterval: 2.3); shot("r9 (c) right cap facing right, banner up")
        quit()
        // (d) pause in the hold, resume: banner up, partner at full opacity
        launch(["-startScreen", "play", "-beat", "4", "-stage", "finish"])
        let pause = try XCTUnwrap(button("pause"))
        pad("special").tap(); Thread.sleep(forTimeInterval: 0.1); pause.tap()
        _ = waitFor(3) { $0["screen"] as? String == "pause" }
        try XCTUnwrap(button("resume")).tap(); shot("r9 (d) just after resume")
    }

    // MARK: r9 cases for the iOS QC r8 NOT ASSESSED items (no touch path on QC's Device Hub)

    func quiz(_ s: [String: Any]) -> [String: Any] { s["quiz"] as? [String: Any] ?? [:] }
    func fires(_ s: [String: Any]) -> [(id: String, t: Double, locked: Bool)] {
        (s["fires"] as? [[String: Any]] ?? []).map { ($0["id"] as? String ?? "", $0["t"] as? Double ?? 0, $0["locked"] as? Bool ?? false) }
    }
    var uptime: Double { ProcessInfo.processInfo.systemUptime } // the simulator's processes share the press clock
    func waitUntil(_ t: Double) { let d = t - uptime; if d > 0 { Thread.sleep(forTimeInterval: d) } }

    /// Answers the current question right (after the lock) and waits for Tiếp.
    func answerRight() throws -> [String: Any] {
        let s = waitFor(5) { self.quiz($0)["picked"] as? Bool == false }
        let slot = try XCTUnwrap(quiz(s)["correct_slot"] as? Int)
        Thread.sleep(forTimeInterval: 0.7) // past the entry lock
        try XCTUnwrap(button("card\(slot)")).tap()
        return waitFor(5) { self.quiz($0)["can_advance"] as? Bool == true }
    }

    /// A (quiz §5.2, small layout): a real right pick fades the wrong cards and glides the right card to the left
    /// slot, and every frame of the motion stays ≤ 720 (sampled by the app every frame, after the actions ran).
    /// A question whose right card is already in the left slot has no glide, so the case moves on to one that does.
    func test_A_quiz_fade_and_glide_stay_inside_720() throws {
        try quizMotion(slowMotion: false)
    }

    /// A, slow motion ×0.1: three screenshots mid-animation for QC (the fade, the glide, the end).
    func test_A_quiz_fade_and_glide_in_slow_motion_for_screenshots() throws {
        try quizMotion(slowMotion: true)
    }

    func quizMotion(slowMotion: Bool) throws {
        launch(["-startScreen", "quiz"] + (slowMotion ? ["-timeScale", "0.1"] : []))
        for _ in 0..<5 {
            var s = waitFor(5) { self.quiz($0)["picked"] as? Bool == false }
            let q = quiz(s), slot = try XCTUnwrap(q["correct_slot"] as? Int), index = q["index"] as? Int ?? -1
            if slot == 0 { // no glide on this one: answer and go on
                _ = try answerRight(); try XCTUnwrap(button("next")).tap()
                _ = waitFor(5) { self.quiz($0)["index"] as? Int != index }
                continue
            }
            Thread.sleep(forTimeInterval: slowMotion ? 6.5 : 0.7) // past the entry lock (sim time slowed ×0.1)
            try XCTUnwrap(button("card\(slot)")).tap()
            if slowMotion { // fade 0.2 s, glide 0.3 s → 2 s and 3 s at ×0.1
                Thread.sleep(forTimeInterval: 1.0); shot("quiz pick, slow motion: wrong cards fading")
                Thread.sleep(forTimeInterval: 2.5); shot("quiz pick, slow motion: right card gliding")
            }
            s = waitFor(slowMotion ? 20 : 5) { self.quiz($0)["can_advance"] as? Bool == true }
            if slowMotion { shot("quiz pick, slow motion: end (Tiếp)") }
            let m = try XCTUnwrap(s["quiz_motion"] as? [String: Any])
            let glide = m["glide"] as? [[Double]] ?? [], bottom = m["max_bottom"] as? Double ?? .infinity
            note("quiz motion, question \(index + 1)", "right slot \(slot); frames moving \(m["frames"] ?? "?"); max bottom \(bottom) (≤ 720); "
                 + "glide \(glide.count) positions: " + glide.map { "(\(Int($0[0])), \(Int($0[1])))" }.joined(separator: " "))
            XCTAssertEqual(m["q"] as? Int, index, "the motion was sampled on this question")
            XCTAssertGreaterThanOrEqual(glide.count, 5, "the right card glided (≥ 5 distinct positions)")
            XCTAssertLessThanOrEqual(bottom, 720, "every pixel of the motion ≤ 720")
            if !slowMotion { shot("quiz after the glide") }
            return
        }
        throw XCTSkip("no question in 5 had its right card outside the left slot")
    }

    /// B (Input Rule 13b, quiz §5.2 at small k): two quick Tiếp taps advance one question; the second tap lands on
    /// the next question's card where it overlaps Tiếp's spot, and the per-question lock drops it (no pick, no wrong
    /// mark). The taps go to the overlap band (Tiếp's top edge over the card's bottom), exported by the app.
    func test_B_two_quick_next_taps_advance_one_question_and_pick_nothing() throws {
        var misses: [String] = []
        for attempt in 1...3 {
            launch(["-startScreen", "quiz"])
            let s0 = try answerRight()
            let index = quiz(s0)["index"] as? Int ?? -1
            // the spot where Tiếp overlaps the next question's third card (small layout); Tiếp's centre lies below
            // the cards, so a tap there can never reach one
            guard (s0["buttons"] as? [String: Any])?["next"] != nil, let o = s0["quiz_overlap"] as? [Double] else {
                misses.append("no Tiếp / no overlap (small layout?)"); quit(); continue
            }
            let spot = point([o[0], o[1]])
            Thread.sleep(forTimeInterval: 0.3)
            spot.doubleTap() // two taps in one synthesized event (two tap() calls wait for idle: 1.46 s apart in r9)
            Thread.sleep(forTimeInterval: 0.8)
            let s = state(), q = quiz(s), f = fires(s).filter { $0.id == "next" || $0.id.hasPrefix("card") }.suffix(2)
            note("double Tiếp, attempt \(attempt)", f.map { String(format: "%@ t %.3f locked %@", $0.id, $0.t, "\($0.locked)") }.joined(separator: "\n")
                 + "\nindex \(index) → \(q["index"] ?? "?"); picked \(q["picked"] ?? "?"); wrong \(q["wrong"] ?? "?"); overlap \(o)\n"
                 + log(s, touches: true).suffix(12).map { String(format: "%@ @ %.3f", $0.0, $0.1) }.joined(separator: "\n"))
            // the second touch-down, from the app's touch log: within 0.6 s of the Tiếp press that advanced
            let adv = try XCTUnwrap(f.last { $0.id == "next" }, "Tiếp fired")
            let touches = log(s, touches: true).filter { $0.0.hasPrefix("touch:") && $0.1 >= adv.t - 0.3 }
            guard touches.count >= 2, let second = touches.last, second.1 - adv.t < 0.6 else {
                misses.append("\(touches.count) touches near Tiếp"); quit(); continue
            }
            // r9 finding: on this phone the band where Tiếp overlaps the next question's third card is ~1.4 world px
            // tall, and XCUITest's doubleTap lands the second touch-down in the same event batch as the first
            // release, before the next frame rebuilds the screen; that touch is on the old Tiếp, which is gone at
            // its release, so nothing fires. Either way the child-visible rule holds: one advance, no pick. The
            // per-question lock itself (a press on the new card inside 0.6 s) is covered by GameCore EveryBoxLockTests.
            note("second tap", "\(second.0) at +\(String(format: "%.3f", second.1 - adv.t)) s after Tiếp; lock reached: \(f.contains { $0.id.hasPrefix("card") && $0.t > adv.t && $0.locked })")
            XCTAssertEqual(q["index"] as? Int, index + 1, "one advance")
            XCTAssertEqual(q["picked"] as? Bool, false, "the second tap picked no card")
            XCTAssertEqual(q["wrong"] as? Int, 0, "and marked none wrong")
            XCTAssertFalse(f.contains { $0.id.hasPrefix("card") && $0.t > adv.t && !$0.locked }, "no unlocked card press after Tiếp")
            shot("next question after a double Tiếp")
            return
        }
        throw XCTSkip("not exercised in 3 launches: " + misses.joined(separator: "; "))
    }

    /// C (Input Rule 13, the deliberate tap at 0.6 s): on an intro box, a tap just before the rolling lock's end is
    /// dropped and one just after it advances. The case replays the rule (0.6 s, cap 1.5 s from the entry) on the
    /// logged press times and checks every press against it.
    func test_C_a_tap_just_before_the_lock_end_drops_and_just_after_advances() throws {
        var misses: [String] = []
        for attempt in 1...4 {
            launch(["-startScreen", "intro"])
            Thread.sleep(forTimeInterval: 1.7) // past box 0's cap
            let next = try XCTUnwrap(button("next"))
            next.tap() // → box 1: a new entry
            let s1 = waitFor(3) { $0["story_line"] as? Int == 1 }
            let e = try XCTUnwrap(s1["entered_at"] as? Double)
            let sent1 = uptime; next.tap() // tap 1: inside the lock
            let f1 = try XCTUnwrap(fires(waitFor(2) { s in self.fires(s).contains { $0.t > e && $0.id == "next" } }).last { $0.id == "next" })
            let latency = max(0, f1.t - sent1)
            var until = min(max(e + 0.6, f1.t + 0.6), e + 1.5)
            waitUntil(until - 0.1 - latency); next.tap() // tap 2: aimed 0.1 s before the lock's end
            let f2 = fires(waitFor(2) { s in self.fires(s).filter { $0.t > e && $0.id == "next" }.count >= 2 }).filter { $0.t > e && $0.id == "next" }
            if let t2 = f2.dropFirst().first, t2.locked { until = min(max(until, t2.t + 0.6), e + 1.5) }
            waitUntil(until + 0.1 - latency); next.tap() // tap 3: aimed 0.1 s after it
            let s = waitFor(3) { $0["story_line"] as? Int == 2 }
            let presses = fires(s).filter { $0.t > e && $0.id == "next" }
            // replay the rule on the logged times
            var end = e + 0.6, nearBefore = false, nearAfter = false, lines: [String] = []
            for p in presses {
                let expect = p.t < end
                lines.append(String(format: "next t %+.3f s, lock end %+.3f, locked %@ (rule: %@)", p.t - e, end - e, "\(p.locked)", "\(expect)"))
                XCTAssertEqual(p.locked, expect, String(format: "press at +%.3f s against the rule (attempt %d)", p.t - e, attempt))
                if expect { if end - p.t <= 0.2 { nearBefore = true }; end = min(max(end, p.t + 0.6), e + 1.5) }
                else { if p.t - end <= 0.25 { nearAfter = true }; break }
            }
            note("deliberate tap, attempt \(attempt)", String(format: "entered_at %.3f; tap latency %.3f s\n", e, latency) + lines.joined(separator: "\n"))
            XCTAssertEqual(s["story_line"] as? Int, 2, "the press after the lock advanced (attempt \(attempt))")
            if nearBefore && nearAfter { shot("intro box 3 after the deliberate tap"); return }
            misses.append("before \(nearBefore), after \(nearAfter)"); quit()
        }
        throw XCTSkip("not exercised in 4 launches (no press within 0.2 s before and 0.25 s after the lock end): " + misses.joined(separator: "; "))
    }

    /// D (D-07 medal, Input Rule 13): a real run from a fresh install's Start, no debug jumps. Every story box,
    /// card, caption, dialogue line and ask is tapped every ~0.35 s (a mash) and the quiz is answered by real
    /// taps; `-autoplay` plays only the play beats. The medal is earned and, after a relaunch, the title shows 3★
    /// and the medal.
    func test_D_a_mashed_real_run_keeps_the_medal_and_saves_it() throws {
        launch(["-resetProgress", "YES", "-autoplay", "YES"])
        _ = waitFor(5) { ($0["buttons"] as? [String: Any])?["start"] != nil }
        try XCTUnwrap(button("start")).tap()
        let end = Date().addingTimeInterval(400)
        var s = state(), taps = 0, warnings = 0
        while Date() < end {
            let t0 = Date()
            s = state()
            let screen = s["screen"] as? String ?? "", btns = s["buttons"] as? [String: Any] ?? [:]
            if screen == "results" { break }
            if s["skip_warning"] as? Bool == true { warnings += 1 }
            if screen == "quiz", quiz(s)["picked"] as? Bool == false, let slot = quiz(s)["correct_slot"] as? Int, btns["card\(slot)"] != nil {
                button("card\(slot)")?.tap(); taps += 1
            } else if btns["ask"] != nil { button("ask")?.tap(); taps += 1 }
            else if btns["next"] != nil { button("next")?.tap(); taps += 1 }
            let left = 0.35 - Date().timeIntervalSince(t0) // a press every ≈ 0.35 s when XCUITest allows (r9: a fixed 0.35 s sleep gave ≈ 0.73 s)
            if left > 0 { Thread.sleep(forTimeInterval: left) }
        }
        // the mash's real cadence: gaps between consecutive Tiếp/ask presses while a story box is up
        let pressTimes = log(s).filter { $0.0 == "fire:next" || $0.0 == "fire:ask" }.map(\.1)
        let gaps = zip(pressTimes.dropFirst(), pressTimes).map { $0 - $1 }.sorted()
        let median = gaps.isEmpty ? .infinity : gaps[gaps.count / 2]
        note("real run", String(format: "press gaps: median %.3f s, min %.3f s (%d presses in the log)\n", median, gaps.first ?? .infinity, pressTimes.count)
             + "taps \(taps); skip warning seen \(warnings) times; debug_jumped \(s["debug_jumped"] ?? "?")\n"
             + log(s).map { String(format: "%@ @ %.3f", $0.0, $0.1) }.joined(separator: "\n"))
        XCTAssertEqual(s["screen"] as? String, "results", "the run reached the results")
        XCTAssertEqual(s["debug_jumped"] as? Bool, false, "no debug jump")
        XCTAssertEqual(warnings, 0, "the mash never opened the skip warning")
        XCTAssertEqual(s["medal_earned"] as? Bool, true, "mashing is not skipping: the medal is earned")
        XCTAssertEqual(s["stars"] as? Int, 3)
        XCTAssertLessThan(median, 0.6, "a real mash: the median press gap is inside the 0.6 s lock (else the run proves only fast taps)")
        shot("results after a mashed real run")
        quit()
        launch([])
        let t = waitFor(5) { $0["title_card"] != nil }, card = t["title_card"] as? [String: Any]
        XCTAssertEqual(card?["stars"] as? Int, 3, "3★ saved")
        XCTAssertEqual(card?["medal"] as? Bool, true, "the medal saved")
        shot("title after relaunch: 3★ + medal")
    }
}
