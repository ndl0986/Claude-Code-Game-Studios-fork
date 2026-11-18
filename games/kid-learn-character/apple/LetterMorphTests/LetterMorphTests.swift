import KidCore
import XCTest

/// Launch-free unit tests. On macOS this bundle is hostless (no TEST_HOST), so it never launches the app (K-34).
final class LetterMorphTests: XCTestCase {
    func test_kidcore_links_into_the_app_test_bundle() {
        XCTAssertEqual(roundHalfAwayFromZero(2.5), 3)
    }
}
