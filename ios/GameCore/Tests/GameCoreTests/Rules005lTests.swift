import XCTest
@testable import GameCore

/// TASK-005l rules before the data lands: R8d, R14b, R21 with the case values agreed with
/// game-dev-android for validity.json (the fixture handlers call these same functions).
final class Rules005lTests: XCTestCase {
    let minPx: [String: Double] = ["heading": 44, "body": 37, "button": 34, "label": 28]

    func test_R8d_size_class_minimums() {
        XCTAssertFalse(ContentValidator.minSize(field: "f", sizeClass: "body", fontPx: 30, minPx: minPx).isEmpty, "below body")
        XCTAssertTrue(ContentValidator.minSize(field: "f", sizeClass: "body", fontPx: 37, minPx: minPx).isEmpty, "at body")
        XCTAssertTrue(ContentValidator.minSize(field: "f", sizeClass: "label", fontPx: 28, minPx: minPx).isEmpty, "at label")
        XCTAssertFalse(ContentValidator.minSize(field: "f", sizeClass: "tiny", fontPx: 40, minPx: minPx).isEmpty, "unknown class")
        XCTAssertFalse(ContentValidator.minSize(field: "f", sizeClass: nil, fontPx: 40, minPx: minPx).isEmpty, "no class")
    }

    /// The shipped fit fields with the agreed class mapping pass once banner is 37, and fail at 28.
    func test_R8d_the_current_fit_fields_pass_with_the_class_mapping_and_banner_37() throws {
        let rules = try Repo.json("data/rules.json") as! [String: Any]
        let fields = ((rules["text_limits"] as! [String: Any])["fit"] as! [String: Any])["fields"] as! [String: [String: Any]]
        let cls = ["hero_name": "heading", "beat_title": "heading", "button": "button", "ui": "label", "place": "label"]
        for banner in [37.0, 28] {
            var f: [ContentValidator.Finding] = []
            for (name, v) in fields {
                let px = name == "banner" ? banner : (v["font_px"] as! NSNumber).doubleValue
                f += ContentValidator.minSize(field: name, sizeClass: cls[name] ?? "body", fontPx: px, minPx: minPx)
            }
            XCTAssertEqual(f.map(\.message), banner == 37 ? [] : ["banner font_px 28.0 < body minimum 37.0"])
        }
    }

    func test_R14b_training_zone_is_computed() {
        func z(_ n: Int, _ s: Double) -> Bool { ContentValidator.trainingZone(beat: "b", dummies: n, spacing: s, enemyReach: 150, edge: 70, worldWidth: 1280).isEmpty }
        XCTAssertFalse(z(4, 300)); XCTAssertTrue(z(3, 300)); XCTAssertTrue(z(3, 330), "exactly 990"); XCTAssertFalse(z(3, 331)); XCTAssertTrue(z(0, 300))
    }

    func test_R21_cheer_false_on_a_fight_beat_warns() {
        let w = ContentValidator.cheerOnFight(beat: "b", type: "fight", cheer: false)
        XCTAssertEqual(w.count, 1); XCTAssertTrue(w[0].isWarning)
        XCTAssertTrue(ContentValidator.cheerOnFight(beat: "b", type: "walk", cheer: false).isEmpty)
        XCTAssertTrue(ContentValidator.cheerOnFight(beat: "b", type: "fight", cheer: nil).isEmpty)
    }

    /// TASK-005o ahead of the data: every TQT goal is 1 line and the banner ≤ 2 lines at the narrow 720 box.
    func test_R8c_tqt_goals_and_banner_fit_the_narrow_720_box() throws {
        let metrics = try Repo.json("metrics/nunito-advances.json") as! [String: Any]
        let adv = ((metrics["weights"] as! [String: Any])["800"] as! [String: NSNumber]).mapValues(\.doubleValue)
        let m = realHero(try Repo.contentSet()).mission
        for t in m.beats.compactMap(\.goal) { for s in [t.vi, t.en] {
            XCTAssertEqual(ContentValidator.wrapLines(s, advances: adv, fontPx: 37, box: 720, allowance: 0.03), 1, s)
        } }
        for s in [m.banner!.vi, m.banner!.en] { XCTAssertLessThanOrEqual(ContentValidator.wrapLines(s, advances: adv, fontPx: 37, box: 720, allowance: 0.03) ?? 99, 2, s) }
    }

    /// R8c at the new banner size: EN 2 lines, VI 1 line (880 px, weight 800, 37 px).
    func test_R8c_the_tqt_banner_fits_at_37() throws {
        let metrics = try Repo.json("metrics/nunito-advances.json") as! [String: Any]
        let adv = ((metrics["weights"] as! [String: Any])["800"] as! [String: NSNumber]).mapValues(\.doubleValue)
        let m = realHero(try Repo.contentSet()).mission
        XCTAssertEqual(ContentValidator.wrapLines(m.banner!.en, advances: adv, fontPx: 37, box: 880, allowance: 0.03), 2)
        XCTAssertEqual(ContentValidator.wrapLines(m.banner!.vi, advances: adv, fontPx: 37, box: 880, allowance: 0.03), 1)
    }
}
