import XCTest
import UIKit
import GameCore
@testable import DaiDatAnhHung

/// story-screens AC14 (r8d): the suite fails if any picture the TQT mission or quiz names, or any assets.json picture
/// file, is missing from the app bundle or doesn't decode.
final class PictureBundleTests: XCTestCase {
    func test_every_picture_is_bundled_and_decodes() throws {
        let data = Bundle.main.bundleURL.appendingPathComponent("data")
        let c = try ContentSet.load(dataRoot: data)
        let pictures = c.assets.assets.filter { $0.kind == "picture" }
        XCTAssertFalse(pictures.isEmpty)
        var byId: [String: String] = [:]
        for a in pictures {
            byId[a.id] = a.file
            let url = data.appendingPathComponent(a.file)
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "\(a.id): \(a.file) is in the bundle")
            let img = UIImage(contentsOfFile: url.path)
            XCTAssertNotNil(img, "\(a.id): \(a.file) decodes")
            XCTAssertGreaterThan(img?.size.width ?? 0, 0, "\(a.id): not empty")
        }
        // every picture id the TQT content names resolves to one of those files
        for hero in c.heroes where hero.mission.hero.id == "tran-quoc-toan" {
            var named = [hero.mission.ending.pictureId]
            for q in hero.quiz.questions { named += q.choices.map(\.pictureId); if let p = q.pictureId { named.append(p) } }
            for id in named { XCTAssertNotNil(byId[id], "\(id) is an assets.json picture") }
        }
    }
}
