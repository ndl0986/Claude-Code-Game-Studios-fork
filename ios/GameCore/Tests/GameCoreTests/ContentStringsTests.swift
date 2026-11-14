import XCTest
@testable import GameCore

/// Reads the real bundled strings file from the repo's shared content/ folder.
final class ContentStringsTests: XCTestCase {
    static let contentRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // GameCoreTests
        .deletingLastPathComponent()  // Tests
        .deletingLastPathComponent()  // GameCore
        .deletingLastPathComponent()  // ios
        .deletingLastPathComponent()  // repo root
        .appendingPathComponent("content")

    func test_strings_file_decodes_and_has_the_app_title_in_both_languages() throws {
        // Arrange
        let url = Self.contentRoot.appendingPathComponent("data/strings.json")

        // Act
        let file = try StringsFile.decode(Data(contentsOf: url))
        let title = try XCTUnwrap(file.string("ui.app.title"))

        // Assert
        XCTAssertEqual(file.schema_version.split(separator: ".").first, "1")
        XCTAssertEqual(title.text(.vi), "Dải Đất Anh Hùng")
        XCTAssertEqual(title.text(.en), "Land of Heroes")
    }
}
