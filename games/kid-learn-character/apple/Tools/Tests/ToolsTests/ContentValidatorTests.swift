import ContractKit
import Foundation
import KidCore
import ToolsCore
import XCTest

/// `kidtools validate` (TASK-079 S2, P7): a test theme built on disk from key-table-schema-v1's fixtures passes; a
/// wrong-case file (V7) and a missing SVG source (staleness stub) each fail; an empty content folder is "0 themes".
final class ContentValidatorTests: XCTestCase {
    var content: URL!

    override func setUpWithError() throws {
        content = FileManager.default.temporaryDirectory.appendingPathComponent("content-\(UUID().uuidString)")
        let cases = try Fixture.contractsRoot(from: #filePath).appendingPathComponent("key-table-schema-v1/cases.json")
        let fx = try JSONSerialization.jsonObject(with: Data(contentsOf: cases)) as! [String: Any]
        let fixtures = fx["fixtures"] as! [String: Any]
        let theme = fixtures["theme"] as! [String: Any], assets = fixtures["assets"] as! [String: Any]
        var glyphSet = fixtures["glyphSet"] as! [String: Any]
        let glyphPaths = glyphSet.removeValue(forKey: "glyphPaths") as! [String: String]
        let root = content.appendingPathComponent("themes/\(theme["id"] as! String)")
        let fm = FileManager.default
        func write(_ data: Data, _ rel: String, in dir: URL) throws {
            let url = dir.appendingPathComponent(rel)
            try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url)
        }
        func pathFile(_ d: String) throws -> Data { try JSONSerialization.data(withJSONObject: ["d": d]) }
        try write(JSONSerialization.data(withJSONObject: theme), "theme.json", in: root)
        let sil = assets["silhouettePaths"] as! [String: String]
        for f in assets["files"] as! [String] {
            try write(sil[f].map(pathFile) ?? Data(), f, in: root)
            for (dir, src) in [("cast/", "src/art/"), ("sil/", "src/sil/")] where f.hasPrefix(dir) {
                try write(Data("<svg/>".utf8), src + (f as NSString).lastPathComponent.replacingOccurrences(of: ".json", with: ".svg"), in: root)
            }
        }
        let gdir = content.appendingPathComponent("glyphs/\(glyphSet["id"] as! String)")
        try write(JSONSerialization.data(withJSONObject: glyphSet), "glyphs.json", in: gdir)
        let glyphs = glyphSet["glyphs"] as! [String: String]
        for (k, f) in glyphs { try write(pathFile(glyphPaths[k]!), f, in: gdir) }
    }

    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: content) }

    func test_the_test_theme_passes() {
        let r = ContentValidator.run(contentDir: content)
        XCTAssertEqual(r.themes, ["testbase"])
        XCTAssertEqual(r.findings, [])
    }

    func test_a_wrong_case_file_fails_V7() throws {
        let dir = content.appendingPathComponent("themes/testbase/cast")
        try FileManager.default.moveItem(at: dir.appendingPathComponent("cast_tb_d_item_01.json"), to: dir.appendingPathComponent("Cast_tb_d_item_01.json"))
        let r = ContentValidator.run(contentDir: content)
        XCTAssertEqual(r.findings.map(\.rule), ["V7"], "\(r.findings)")
    }

    func test_a_missing_source_fails_the_staleness_stub() throws {
        try FileManager.default.removeItem(at: content.appendingPathComponent("themes/testbase/src/sil/sil_tb_d_item_01.svg"))
        let r = ContentValidator.run(contentDir: content)
        XCTAssertEqual(r.findings.map(\.rule), ["stale"], "\(r.findings)")
    }

    func test_no_themes_is_zero_themes_and_passes() throws {
        let empty = FileManager.default.temporaryDirectory.appendingPathComponent("empty-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: empty) }
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        let r = ContentValidator.run(contentDir: empty)
        XCTAssertEqual(r.themes, [])
        XCTAssertTrue(r.pass)
    }
}
