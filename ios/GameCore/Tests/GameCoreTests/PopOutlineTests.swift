import XCTest
@testable import GameCore

/// hud §3.3 / accessibility-requirements (QC r5 N1, r7 NOT ASSESSED): a pop's outline is chosen by the sky it sits on,
/// not by the theme's name: ink #3A2A20 on light skies, cream #FFF6E3 on dark ones, whichever reads better against
/// both ends of the sky band.
final class PopOutlineTests: XCTestCase {
    func test_the_outline_follows_the_skys_colour() throws {
        let c = try ContentSet.load(dataRoot: Repo.data), themes = try XCTUnwrap(c.themes?.themes)
        for (id, t) in themes {
            let o = SkyContrast.popOutline(skyTop: t.skyBand.top, skyBottom: t.skyBand.bottom)
            XCTAssertEqual(o, id == "camp" ? .cream : .ink, "\(id): \(t.skyBand.top)–\(t.skyBand.bottom)")
        }
        XCTAssertEqual(SkyContrast.popOutline(skyTop: "#C6E2EE", skyBottom: "#C6E2EE"), .ink, "QC's day camp sky gets ink, not cream (1.28:1)")
        XCTAssertEqual(SkyContrast.popOutline(skyTop: "#2E3156", skyBottom: "#3B3F6B"), .cream, "the night camp keeps cream")
    }

    func test_contrast_ratios() {
        XCTAssertEqual(SkyContrast.ratio("#FFFFFF", "#000000"), 21, accuracy: 0.01)
        XCTAssertEqual(SkyContrast.ratio("#FFF6E3", "#C6E2EE"), 1.260, accuracy: 0.005, "cream on the day sky (QC quoted ≈ 1.28)")
        XCTAssertEqual(SkyContrast.ratio("#3A2A20", "#A9D3EC"), 8.627, accuracy: 0.005, "ink on the village top")
        XCTAssertEqual(SkyContrast.ratio("#FFF6E3", "#3B3F6B"), 9.266, accuracy: 0.005, "cream on the camp bottom")
        XCTAssertGreaterThanOrEqual(SkyContrast.ratio("#3A2A20", "#C6E2EE"), 3, "ink on the day sky reads")
    }
}
