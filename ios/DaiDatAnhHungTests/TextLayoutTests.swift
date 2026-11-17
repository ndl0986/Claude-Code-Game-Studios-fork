import XCTest
import SpriteKit
@testable import DaiDatAnhHung

/// iOS QC r5 R5-01: text line height is 1.35 × the font size (Language & text GDD F1), so the EN banner's
/// 2 lines at 37/800 fit the fixed 112 bar (2 × 50 + padding), as R8c measured.
final class TextLayoutTests: XCTestCase {
    func test_line_height_is_1_35_times_the_font_size() {
        let one = Font.label("Phá cường địch", 37, .white, width: 880).frame.height
        let two = Font.label("Defeat the strong enemy, repay the king's kindness", 37, .white, width: 880).frame.height
        XCTAssertEqual(two - one, 1.35 * 37, accuracy: 2, "one line adds 1.35 × 37")
    }

    func test_the_EN_banner_text_lies_inside_the_112_bar() {
        let l = Font.label("Defeat the strong enemy, repay the king's kindness", 37, .white, width: 880)
        // the text rect, centred in the bar, stays inside it with room for the ≥ 2 px ink outline (QC r5 spec)
        XCTAssertLessThanOrEqual(l.frame.height, 112 - 2 * 2, "2 lines at 1.35 × 37 inside the 112 bar")
        XCTAssertLessThanOrEqual(l.frame.width, 880 + 0.5, "wraps at the 880 box")
    }
}
