import XCTest
@testable import DaiDatAnhHung

/// The app bundles content/data as a folder named `data`.
final class AppBundleTests: XCTestCase {
    func test_app_bundle_contains_the_content_data_folder_with_strings() throws {
        let strings = try XCTUnwrap(ContentBundle.main.strings())
        XCTAssertEqual(strings.string("ui.app.title")?.en, "Land of Heroes")
    }
}
