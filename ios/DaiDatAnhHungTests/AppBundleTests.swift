import XCTest
import GameCore
@testable import DaiDatAnhHung

/// The app bundle: content/data as `data/`, the debug sample, the font, and a scene that boots.
final class AppBundleTests: XCTestCase {
    func test_bundle_has_data_samples_and_font_and_content_loads() throws {
        let b = Bundle.main.bundleURL
        XCTAssertTrue(FileManager.default.fileExists(atPath: b.appendingPathComponent("data/fonts/nunito.ttf").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: b.appendingPathComponent("samples/heroes/sample/mission.json").path), "debug builds bundle the sample")
        XCTAssertFalse(FileManager.default.fileExists(atPath: b.appendingPathComponent("schema").path), "schema is test-only")
        let c = try ContentSet.load(dataRoot: b.appendingPathComponent("data"))
        XCTAssertEqual(c.ui("ui.app.title", .en), "Land of Heroes")
    }

    func test_the_scene_boots_with_a_hero() throws {
        XCTAssertNotNil(Boot.makeScene())
        XCTAssertNotEqual(Font.name, "", "Nunito registered")
    }
}
