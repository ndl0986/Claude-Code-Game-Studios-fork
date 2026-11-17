import XCTest
@testable import GameCore

/// The shared cross-app trace (content/fixtures/trace-tqt.json): replays the Android-generated input
/// script on the iOS core and compares every snapshot. A mismatch is a parity bug (fixed in whichever
/// app disagrees with the GDD).
final class TraceTests: XCTestCase {
    /// `withCam`: trace schema 1.1 adds the camera x (Combat Rule 15b parity; agreed with game-dev-android).
    func snapshot(_ p: PlayState, frame: Int, withCam: Bool = false) -> [String: Any] {
        let beat = p.currentBeat
        var enemies: [[String: Any]] = p.enemies.map {
            ["id": $0.id, "kind": $0.kind.rawValue, "state": $0.state.rawValue, "x": $0.x, "face": Int($0.face), "hits": $0.hits]
        }
        if let pt = p.partner { enemies.append(["id": 0, "kind": "partner", "state": pt.state.rawValue, "x": pt.x, "face": Int(pt.face), "hits": pt.hits]) }
        enemies.sort { ($0["id"] as! Int) < ($1["id"] as! Int) }
        var out: [String: Any] = [
            "frame": frame, "phase": p.phase.rawValue, "beat": p.beat, "beat_id": beat?.id ?? NSNull(),
            "hero": ["x": p.hero.x, "face": Int(p.hero.face), "attacking": p.hero.atk >= 0, "defending": p.hero.def],
            "lock_x": p.locked ? p.lockX : NSNull(), "line": p.lineIndex, "asks": p.asksDone,
            "training_step": beat?.type == "training" ? p.trainingStage.rawValue : NSNull(),
            "held_total": p.heldTotal, "enemies": enemies, "rng_draws": p.rng.draws, "mission_done": p.finished,
        ]
        if withCam { out["cam"] = p.cam }
        return out
    }

    /// The first difference between two JSON values, as a path, or nil.
    func diff(_ a: Any, _ b: Any, _ path: String, tol: Double) -> String? {
        if let da = a as? [String: Any], let db = b as? [String: Any] {
            for k in Set(da.keys).union(db.keys).sorted() {
                guard let va = da[k], let vb = db[k] else { return "\(path).\(k) missing on one side" }
                if let d = diff(va, vb, "\(path).\(k)", tol: tol) { return d }
            }
            return nil
        }
        if let aa = a as? [Any], let ab = b as? [Any] {
            if aa.count != ab.count { return "\(path) count \(aa.count) vs \(ab.count)" }
            for i in aa.indices { if let d = diff(aa[i], ab[i], "\(path)[\(i)]", tol: tol) { return d } }
            return nil
        }
        if a is NSNull || b is NSNull { return (a is NSNull && b is NSNull) ? nil : "\(path) \(a) vs \(b)" }
        if let na = a as? NSNumber, let nb = b as? NSNumber, !(a is String), !(b is String) {
            if CFGetTypeID(na) == CFBooleanGetTypeID() || CFGetTypeID(nb) == CFBooleanGetTypeID() { return na == nb ? nil : "\(path) \(na) vs \(nb)" }
            return abs(na.doubleValue - nb.doubleValue) <= tol ? nil : "\(path) \(na) vs \(nb)"
        }
        if let sa = a as? String, let sb = b as? String { return sa == sb ? nil : "\(path) \(sa) vs \(sb)" }
        if let ba = a as? Bool, let bb = b as? Bool { return ba == bb ? nil : "\(path) \(ba) vs \(bb)" }
        if let ia = a as? Int, let ib = b as? Int { return ia == ib ? nil : "\(path) \(ia) vs \(ib)" }
        if let xa = a as? Double, let xb = b as? Double { return abs(xa - xb) <= tol ? nil : "\(path) \(xa) vs \(xb)" }
        return "\(path) type \(type(of: a)) vs \(type(of: b))"
    }

    func test_shared_trace_replays_identically() throws {
        guard FileManager.default.fileExists(atPath: Repo.content.appendingPathComponent("fixtures/trace-tqt.json").path) else { return }
        let t = try Repo.json("fixtures/trace-tqt.json") as! [String: Any]
        let c = try ContentSet.load(dataRoot: Repo.data)
        var p = PlayState(tuning: c.tuning, beats: realHero(c).mission.beats, seed: t["seed"] as! Int)
        let withCam = (t["schema_version"] as? String ?? "1.0").compare("1.1", options: .numeric) != .orderedAscending
        let dt = t["dt"] as! Double, every = t["snapshot_every"] as! Int, tol = t["tolerance"] as! Double
        let expected = Dictionary(uniqueKeysWithValues: (t["expected"] as! [[String: Any]]).map { ($0["frame"] as! Int, $0) })
        var frame = 0
        func actions(_ names: Any?) -> Set<PadAction> { Set((names as? [String] ?? []).compactMap(PadAction.init(rawValue:))) }
        for entry in t["script"] as! [[String: Any]] {
            if let cmd = entry["cmd"] as? String {
                let before = "\(p.phase)|\(p.lineIndex)|\(p.cardLine)|\(p.captionLine)|\(p.beat)"
                switch cmd {
                case "card_next": p.cardNext()
                case "caption_next": p.captionNext()
                case "dialogue_next": p.dialogueNext()
                case "dialogue_ask": p.dialogueAsk()
                default: XCTFail("unknown cmd \(cmd)")
                }
                let after = "\(p.phase)|\(p.lineIndex)|\(p.cardLine)|\(p.captionLine)|\(p.beat)"
                if before == after { XCTFail("cmd \(cmd) refused after frame \(frame) (\(before))"); return }
                continue
            }
            let n = entry["frames"] as! Int, held = actions(entry["hold"]), tap = actions(entry["tap"])
            for k in 0..<n {
                p.update(dt, StepInput(held: held, tapped: k == 0 ? tap : []))
                frame += 1
                if frame % every == 0, let exp = expected[frame] {
                    if let d = diff(snapshot(p, frame: frame, withCam: withCam), exp, "frame \(frame)", tol: tol) { XCTFail("first mismatch: \(d)"); return }
                }
            }
        }
        if let d = diff(snapshot(p, frame: frame, withCam: withCam), t["final"]!, "final", tol: tol) { XCTFail("first mismatch: \(d)") }
    }
}
