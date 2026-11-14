import XCTest
@testable import GameCore

/// Every case in content/fixtures: the rules both apps must agree on.
final class FixtureTests: XCTestCase {
    func test_quiz_stars_fixture() throws {
        let content = try Repo.contentSet()
        let rule = StarRule(content.rules.quizStars)
        for c in try Repo.fixture("quiz-stars") {
            let picks = c["wrong_picks_per_question"] as! [Int]
            let exp = c["expected"] as! [String: Any]
            let total = picks.reduce(0, +)
            XCTAssertEqual(total, exp["total_retries"] as? Int, c["name"] as! String)
            XCTAssertEqual(rule.stars(totalRetries: total), exp["stars"] as? Int, c["name"] as! String)
            XCTAssertTrue(content.rules.quizStars.finishingUnlocksNextHero)
        }
    }

    func test_quiz_scoring_fixture() throws {
        let sample = try Repo.contentSet().heroes[0].quiz
        for c in try Repo.fixture("quiz-scoring") {
            // a one-question quiz whose correct card is the case's
            let q = sample.questions[0]
            let one = QuizFile.Question(id: q.id, prompt: q.prompt, pictureId: nil, choices: q.choices, correctIndex: c["correct_index"] as! Int, why: q.why)
            var s = QuizSession(quiz: QuizFile(schemaVersion: "1.0", heroId: "t", questions: [one, one, one]), count: 3, seed: 1)
            var got: [String] = []
            for p in c["picks"] as! [Int] {
                got.append(s.pick(original: p).rawValue)
                s.update(QuizSession.shakeDuration) // the shake ends before the next tap
            }
            XCTAssertEqual(got, c["expected"] as! [String], c["name"] as! String)
        }
    }

    func test_claim_gate_fixture() throws {
        for c in try Repo.fixture("claim-gate") {
            let claims = (c["claims"] as! [String: String]).mapValues { $0 == "approved" }
            let r = ClaimGate.evaluate(claims: claims, textClaims: c["text_claims"] as! [[String]])
            let exp = c["expected"] as! [String: Any]
            XCTAssertEqual(r.releaseBuild.rawValue, exp["release_build"] as? String, c["name"] as! String)
            XCTAssertEqual(r.runtimeRelease.rawValue, exp["runtime_release"] as? String, c["name"] as! String)
            XCTAssertEqual(r.debugBadges, exp["debug_badges"] as? [String], c["name"] as! String)
        }
    }

    func test_rng_fixture_matches_the_prototype_bit_for_bit() throws {
        for c in try Repo.fixture("rng") {
            // compare the exact 32-bit outputs: Foundation's JSON parser can be 1 ulp off on a printed double
            var r = Mulberry32(seed: c["seed"] as! Int)
            let expected = (c["first"] as! [Double]).map { UInt32(($0 * 4_294_967_296).rounded()) }
            let got = expected.map { _ in UInt32(r.next() * 4_294_967_296) }
            XCTAssertEqual(got, expected, "seed \(c["seed"]!)")
        }
    }

    func test_quiz_shuffle_fixture() throws {
        for c in try Repo.fixture("quiz-shuffle") {
            let o = QuizSession.shuffle(n: c["n"] as! Int, seed: c["seed"] as! Int, questionIndex: c["question_index"] as! Int)
            XCTAssertEqual(o, c["expected_order"] as! [Int], "\(c)")
        }
    }

    func test_validity_fixture() throws {
        let markers = try Repo.contentSet().markers
        for c in try Repo.fixture("validity") {
            let rule = c["rule"] as! String, name = c["name"] as! String, exp = c["expected"] as! String
            var findings: [ContentValidator.Finding] = []
            func text(_ o: Any?) -> Text {
                let d = o as! [String: Any]
                return Text(id: d["id"] as! String, vi: d["vi"] as! String, en: d["en"] as! String, claims: d["claims"] as! [String])
            }
            func labels() -> [String: Claim.Label] {
                (c["claims"] as! [String: [String: String]]).mapValues { Claim.Label(rawValue: $0["label"]!)! }
            }
            switch rule {
            case "R4": findings = ContentValidator.legendMarker(text(c["text"]), labels: labels(), markers: markers)
            case "R4b":
                let scope = (c["scope_sentences"] as! [Any]).map { text($0) }
                findings = ContentValidator.legendLabel(text(c["text"]), scope: scope, labels: labels(), markers: markers)
            case "R5":
                let d = c["claim"] as! [String: Any]
                let data = try JSONSerialization.data(withJSONObject: d.merging(["vi": "x", "en": "x"]) { a, _ in a })
                let claim = try ContentJSON.decode(Claim.self, from: data)
                let src = (c["sources"] as! [String: String]).mapValues { Source.Status(rawValue: $0)! }
                findings = ContentValidator.sourceGate(claim, sources: src)
            case "R6":
                let l = labels()
                findings = (c["quiz_claims"] as! [String]).filter { l[$0] == .invented }.map { .init(rule: "R6", message: $0) }
            case "R7": let t = text(c["text"]); findings = ContentValidator.nfc([t.vi, t.en], id: t.id)
            case "R8":
                let budgets = try Repo.contentSet().rules.textLimits.enBudget
                findings = ContentValidator.enBudget(c["en"] as! String, fieldType: c["field_type"] as! String, budgets: budgets)
            case "R9": let ids = c["ids"] as! [String]; if Set(ids).count != ids.count { findings = [.init(rule: "R9", message: "dup")] }
            case "R10":
                if !(c["asset_ids"] as! [String]).contains(c["picture_id"] as! String) { findings = [.init(rule: "R10", message: "missing")] }
            case "R11": findings = ContentValidator.schemaMajor(file: c["file_version"] as! String, app: c["app_supports"] as! String)
            case "R13", "R13b":
                let b = c["beat"] as! [String: Any]
                let params = try ContentJSON.decode(BeatParams.self, from: JSONSerialization.data(withJSONObject: b["params"]!))
                findings = ContentValidator.beatButtons(type: b["type"] as! String, buttons: b["buttons"] as! [String], params: params)
            case "R14", "R15": findings = ContentValidator.tuningRules((c["tuning"] as! [String: NSNumber]).mapValues(\.doubleValue))
            case "R17", "R18":
                let hs = (c["heroes"] as! [[String: Any]]).map { (id: $0["id"] as! String, order: $0["timeline_order"] as! Int, next: $0["next_hero"] as? String) }
                findings = ContentValidator.timeline(hs).filter { $0.rule == rule }
            case "R16":
                let th = (c["thresholds"] as! [[String: Any]]).map { RulesFile.StarThreshold(stars: $0["stars"] as! Int, maxRetries: $0["max_retries"] as? Int) }
                findings = ContentValidator.starOrder(th)
            default: XCTFail("no handler for \(rule)"); continue
            }
            let errors = findings.filter { !$0.isWarning }, warnings = findings.filter(\.isWarning)
            switch exp {
            case "valid", "build_passes": XCTAssertTrue(findings.isEmpty, "\(name): \(findings)")
            case "invalid", "build_fails": XCTAssertFalse(errors.isEmpty, name)
            case "warn": XCTAssertTrue(errors.isEmpty && !warnings.isEmpty, "\(name): \(findings)")
            default: XCTFail("unknown expectation \(exp)")
            }
        }
    }
}
