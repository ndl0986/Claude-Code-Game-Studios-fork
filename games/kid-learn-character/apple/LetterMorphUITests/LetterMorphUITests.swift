import XCTest

/// Launches the app. On the iPad simulator this runs headless; on macOS it takes the screen, so it runs only in a
/// MAC FREE slot (K-34).
final class LetterMorphUITests: XCTestCase {
    func test_app_launches_to_the_title() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }
}
