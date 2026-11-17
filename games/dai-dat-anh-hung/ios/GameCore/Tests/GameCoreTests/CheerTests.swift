import XCTest
@testable import GameCore

/// Schema 1.5 `cheer` (TASK-005l; Mission flow Rule 2, Audio AC13).
final class CheerTests: XCTestCase {
    /// The TQT mission with `cheer` set on the first beat of `type`.
    func beats(_ type: String, cheer: Bool?) throws -> [Beat] {
        var m = try Repo.json("data/heroes/tran-quoc-toan/mission.json") as! [String: Any]
        var bs = m["beats"] as! [[String: Any]]
        let i = bs.firstIndex { $0["type"] as? String == type }!
        bs[i]["cheer"] = cheer
        m["beats"] = bs
        return try ContentJSON.decode(Mission.self, from: JSONSerialization.data(withJSONObject: m)).beats
    }

    /// Plays the first beat (walk) to its end and returns the events of that run.
    func walkEndEvents(_ cheer: Bool?) throws -> [PlayEvent] {
        let c = try Repo.contentSet()
        var p = PlayState(tuning: c.tuning, beats: try beats("walk", cheer: cheer), seed: 1)
        var events: [PlayEvent] = [], step = 0
        while p.beat == 0 && step < 60 * 120 {
            if p.phase == .beatCard { p.cardNext(); continue }
            p.update(1.0 / 60, StepInput(held: [.right])); events += p.takeEvents(); step += 1
        }
        XCTAssertEqual(p.beat, 1, "the walk beat ends")
        return events
    }

    func test_a_beat_with_cheer_false_ends_quietly() throws {
        let e = try walkEndEvents(false)
        XCTAssertFalse(e.contains(.cheer)); XCTAssertEqual(e.filter { $0 == .quietEnd }.count, 1)
    }

    func test_cheer_absent_or_true_cheers() throws {
        for v in [nil, true] as [Bool?] {
            let e = try walkEndEvents(v)
            XCTAssertEqual(e.filter { $0 == .cheer }.count, 1, "cheer \(String(describing: v))"); XCTAssertFalse(e.contains(.quietEnd))
        }
    }

    func test_fight_beats_always_cheer() throws {
        let c = try Repo.contentSet()
        let f = Repo.sampleHero(c).mission.beats[0]
        XCTAssertEqual(f.type, "fight")
        XCTAssertTrue(f.cheers)
        var m = try Repo.json("samples/heroes/sample/mission.json") as! [String: Any]
        var bs = m["beats"] as! [[String: Any]]; bs[0]["cheer"] = false; m["beats"] = bs
        let b = try ContentJSON.decode(Mission.self, from: JSONSerialization.data(withJSONObject: m)).beats[0]
        XCTAssertTrue(b.cheers, "cheer: false is ignored on a fight beat")
    }
}
