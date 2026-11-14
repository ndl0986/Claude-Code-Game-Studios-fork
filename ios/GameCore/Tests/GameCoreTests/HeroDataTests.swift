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
