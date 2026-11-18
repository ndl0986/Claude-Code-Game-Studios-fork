import KidCore
import XCTest

/// Reveal Stage F1's table, plus K-39's portrait iPad (contain, never letterbox).
final class StageFitTests: XCTestCase {
    func test_ipad_11_landscape() {
        let f = StageFit(width: 2388, height: 1668)
        XCTAssertEqual(f.scale, 2388.0 / 1280.0, accuracy: 1e-12)
        XCTAssertEqual(f.visibleX, 0, accuracy: 1e-9)
        XCTAssertEqual(f.visibleY.rounded(), -87)
        XCTAssertEqual(f.visibleWidth, 1280, accuracy: 1e-9)
        XCTAssertEqual(f.visibleHeight.rounded(), 894)
    }

    func test_ipad_13_landscape() {
        let f = StageFit(width: 2752, height: 2064)
        XCTAssertEqual(f.scale, 2.15, accuracy: 1e-12)
        XCTAssertEqual(f.visibleY, -120, accuracy: 1e-9)
        XCTAssertEqual(f.visibleHeight, 960, accuracy: 1e-9)
    }

    func test_mac_16_9_and_21_9() {
        let a = StageFit(width: 2560, height: 1440)
        XCTAssertEqual(a.scale, 2); XCTAssertEqual(a.visibleX, 0); XCTAssertEqual(a.visibleY, 0)
        let b = StageFit(width: 3440, height: 1440)
        XCTAssertEqual(b.scale, 2); XCTAssertEqual(b.visibleX, -220); XCTAssertEqual(b.visibleWidth, 1720)
    }

    func test_portrait_ipad_contains_by_width_and_extends_sky_and_ground() {
        let f = StageFit(width: 1668, height: 2388)
        XCTAssertEqual(f.scale, 1668.0 / 1280.0, accuracy: 1e-12)
        XCTAssertEqual(f.visibleX, 0, accuracy: 1e-9)
        XCTAssertLessThan(f.visibleY, 0)
        XCTAssertEqual(f.visibleHeight, 2388.0 / f.scale, accuracy: 1e-9)
        let corner = f.toWindow(x: 1280, y: 720)
        XCTAssertEqual(corner.x, 1668, accuracy: 1e-9)
        XCTAssertEqual(corner.y, f.offsetY + 720 * f.scale, accuracy: 1e-9)
    }
}
