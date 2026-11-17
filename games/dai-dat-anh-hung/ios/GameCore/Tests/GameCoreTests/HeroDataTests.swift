import XCTest
@testable import GameCore

/// Every hero listed in data/index.json: schema, loader, cross-file rules, the claim gate.
final class HeroDataTests: XCTestCase {
    func test_every_bundled_hero_loads_validates_and_is_gated() throws {
        let content = try ContentSet.load(dataRoot: Repo.data)
        let schema = try MiniSchema(dir: Repo.content.appendingPathComponent("schema"))
        for id in content.index.heroes {
            for (f, s) in [("mission", "mission"), ("quiz", "quiz"), ("claims", "claims")] {
                XCTAssertEqual(schema.validate(try Repo.json("data/heroes/\(id)/\(f).json"), file: "\(s).schema.json"), [], "\(id)/\(f)")
            }
        }
        let findings = ContentValidator(content: content, checkPictures: true).validate()
        print("HERODATA findings:", findings.map(\.description))
        XCTAssertEqual(findings.filter { !$0.isWarning }, [])
        for hero in content.heroes {
            let g = ClaimGate.evaluate(hero)
            print("HERODATA gate", hero.mission.hero.id, g.releaseBuild, g.runtimeRelease, g.debugBadges)
        }
    }
}

/// content/drafts/: not bundled, but held to the same schema and cross-file rules, against the
/// hero's claims.json in data/.
final class DraftsTests: XCTestCase {
    func test_draft_missions_match_the_schema_and_rules() throws {
        let drafts = Repo.content.appendingPathComponent("drafts/heroes")
        guard let ids = try? FileManager.default.contentsOfDirectory(atPath: drafts.path) else { return }
        let schema = try MiniSchema(dir: Repo.content.appendingPathComponent("schema"))
        let content = try ContentSet.load(dataRoot: Repo.data)
        for id in ids {
            let dir = drafts.appendingPathComponent(id)
            for f in try FileManager.default.contentsOfDirectory(atPath: dir.path) where f.hasPrefix("mission") && f.hasSuffix(".json") {
                let url = dir.appendingPathComponent(f)
                XCTAssertEqual(schema.validate(try JSONSerialization.jsonObject(with: Data(contentsOf: url)), file: "mission.schema.json"), [], "\(id)/\(f)")
                guard let hero = content.heroes.first(where: { $0.mission.hero.id == id || $0.claims.heroId == id }) else { continue }
                let mission = try ContentJSON.decode(Mission.self, from: Data(contentsOf: url))
                let swapped = HeroContent(mission: mission, quiz: hero.quiz, claims: hero.claims)
                let set = ContentSet(index: content.index, strings: content.strings, sources: content.sources, markers: content.markers,
                                     rules: content.rules, tuning: content.tuning, assets: content.assets, themes: content.themes, heroes: [swapped])
                XCTAssertEqual(ContentValidator(content: set, checkPictures: true).validate().filter { !$0.isWarning }, [], "\(id)/\(f)")
            }
        }
    }
}
