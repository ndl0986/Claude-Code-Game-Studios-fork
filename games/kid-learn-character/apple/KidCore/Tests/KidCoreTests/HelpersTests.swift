import XCTest
@testable import KidCore

final class HelpersTests: XCTestCase {
    func test_roundHalfAwayFromZero_matches_ADR0002_validation2() {
        // ADR-0002 Validation 2 and Settings Store F1's slider cases.
        let cases: [(Double, Double)] = [(2.5, 3), (-2.5, -3), (7.5, 8), (0.5, 1), (7.4, 7), (0.4, 0), (6.6, 7), (-0.6, -1)]
        for (x, want) in cases { XCTAssertEqual(roundHalfAwayFromZero(x), want, "\(x)") }
    }

    func test_asciiUppercased_folds_ascii_only() {
        XCTAssertEqual(asciiUppercased("abc"), "ABC")
        XCTAssertEqual(asciiUppercased("é"), "é")
        XCTAssertEqual(asciiUppercased("в"), "в")
        XCTAssertEqual(asciiUppercased("rex1"), "REX1")
    }

    func test_scalarCount_counts_scalars_not_graphemes() {
        XCTAssertEqual(scalarCount("e\u{301}"), 2) // one grapheme, two scalars
        XCTAssertEqual(scalarCount("REX"), 3)
    }

    func test_unitDraw_uses_the_top_53_bits() {
        XCTAssertEqual(unitDraw(0), 0)
        XCTAssertEqual(unitDraw(UInt64.max), Double((UInt64.max >> 11)) * 0x1.0p-53)
        XCTAssertLessThan(unitDraw(UInt64.max), 1)
    }

    func test_drawList_consumes_in_order_and_reports_leftovers() {
        var d = DrawList([1, 2, 3])
        XCTAssertEqual(d.next(), 1); XCTAssertEqual(d.next(), 2)
        XCTAssertEqual(d.remaining, 1)
    }
}
