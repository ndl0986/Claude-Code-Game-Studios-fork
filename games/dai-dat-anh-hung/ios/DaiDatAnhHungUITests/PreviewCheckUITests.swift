import XCTest

/// TASK-026 / D-37: an opt-in look at an installed **Preview** build (`com.galaxyandsun.daidatanhhung.preview`).
/// Preview has no debug state, so this case only taps by screen position and attaches screenshots for a person to
/// judge: the title with the hero card and Start, then the first story screens with the `UNSIGNED Cxx` strip at the
/// top edge. It also checks that the debug-state element is absent (debug code compiled out).
///
/// Run: install the Preview app on the Simulator, then
///   TEST_RUNNER_PREVIEW_CHECK=1 xcodebuild test-without-building … -only-testing:DaiDatAnhHungUITests/PreviewCheckUITests
/// Without TEST_RUNNER_PREVIEW_CHECK=1 it is skipped, so the normal suite never touches the Preview app.
final class PreviewCheckUITests: XCTestCase {
    func test_preview_title_then_story_screens_show_the_unsigned_strip() throws {
        guard ProcessInfo.processInfo.environment["PREVIEW_CHECK"] == "1" else {
            throw XCTSkip("opt-in: set TEST_RUNNER_PREVIEW_CHECK=1 with the Preview app installed")
        }
        continueAfterFailure = true
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(bundleIdentifier: "com.galaxyandsun.daidatanhhung.preview")
        app.launchArguments = ["-lang", "vi", "-startScreen", "play"] // a debug jump: Preview must ignore it
        app.launch()
        Thread.sleep(forTimeInterval: 3)
        XCTAssertFalse(app.descendants(matching: .any)["debugState"].exists, "no debug state in Preview")
        shot("01 title: hero card and Start (the debug jump was ignored)")
        // Start: the centre of the title's Start button in the 1280×720 world, as a fraction of the screen
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.584)).tap()
        Thread.sleep(forTimeInterval: 2)
        shot("02 first story screen after Start: UNSIGNED strip at the top edge")
        Thread.sleep(forTimeInterval: 2)
        shot("03 the same screen 2 s later")
    }

    private func shot(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }
}
