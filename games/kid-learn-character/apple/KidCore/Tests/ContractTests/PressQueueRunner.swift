import ContractKit
import Foundation
import KidCore
import XCTest

/// press-queue-v2, KidCore layer (ADR-0004 D3; stories press-queue/001-005). Registered in `ContractHarness.runners`
/// and in the registry (`runner: PressQueueRunner`, press-queue/005): every case runs. The fake Stage stands in for
/// the Reveal Stage and Key Table, and the runner plays the Reveal Stage's part for freeze, panel and background
/// (pausing the play clock and telling the queue, architecture §3).
struct PressQueueRunner: ContractRunner {
    static let contract = "press-queue-v2"
    static let declaration = ContractDeclaration(
        givenFields: ["reveal", "knobs", "accessibility"],
        events: ["press": ["key", "source", "origin", "stampLag"], "tick": [], "formed": ["revealId"], "freeze": [],
                 "resume": [], "panelOpen": [], "panelClose": [], "background": [], "foreground": [],
                 "accessibilityChanged": ["reduceMotion"]])

    /// The knob defaults spec.md lists under `given.knobs`; a case's `knobs` override them.
    static let specKnobs = PressQueueKnobs(holdS: 3.0, queueMax: 3, formedTimeoutS: 1.0, wordOffsetS: 0.25,
                                           holdExtMaxS: 1.5, wordLenMaxS: 1.5)

    static func kind(out: String, field: String) -> String? { field == "r0" ? "time" : nil }
    /// spec.md Field kinds: `holdEff`, `formedAt` and `restingSince` are `time`.
    /// spec.md State: `current` has named members (`revealId`, `key`, `holdEff`, `formed`, `formedAt`), so a case
    /// checks only the members it writes (case-schema-v1 §4 note, TASK-149).
    static func stateIsRecord(_ name: String) -> Bool { name == "current" }
    static func stateKind(name: String, field: String) -> String? {
        ["holdEff", "formedAt", "restingSince"].contains(field) ? "time" : nil
    }

    /// The fake Reveal Stage and Key Table: answers from the case's `reveal` table and records its calls.
    final class Stage: PressQueueStage {
        let table: [String: JSONValue]
        var calls: [JSONValue] = []
        /// The first key the queue started that `given.reveal` has no answer for; the step throws on it, so a typo
        /// can't pass on default lengths.
        var missing: String?
        init(table: [String: JSONValue]) { self.table = table }
        /// Reduce Motion as the stage reads it (Reveal Stage R9): `given.accessibility`, then `accessibilityChanged`.
        var reduceMotion = false
        func startReveal(revealId: Int, key: String, source: PressSource, origin: PressOrigin?, r0: Double) -> RevealStart {
            calls.append(.object(["out": .string("startReveal"), "revealId": .int(Int64(revealId)), "key": .string(key),
                                  "source": .string(PressQueueRunner.sourceText(source)),
                                  "origin": origin.map { .array([.double($0.x), .double($0.y)]) } ?? .null,
                                  "r0": .double(r0)]))
            // With Reduce Motion the entry's `reduced` lengths are used (spec.md `given`); a missing `reduced` is a missing key.
            let set = reduceMotion ? table[key]?["reduced"] : table[key]
            guard let e = table[key], let f = set?["formedS"]?.number, let l = set?["revealLen"]?.number, let c = e["castId"]?.string else {
                if missing == nil { missing = key }
                return RevealStart(formedS: 0, revealLen: 0, hasWord: false, wordLen: nil, castId: "")
            }
            return RevealStart(formedS: f, revealLen: l, hasWord: e["hasWord"] == .bool(true), wordLen: e["wordLen"]?.number, castId: c)
        }
    }

    /// Every debug line is the output `{out: log}`, in the stage's call order (spec.md Outputs).
    final class Log: DebugLog {
        let stage: Stage
        init(stage: Stage) { self.stage = stage }
        func log(_ line: String) { stage.calls.append(.object(["out": .string("log")])) }
    }

    final class Clock: UptimeClock {
        var t = 0.0
        func now() -> Double { t }
    }

    static func sourceText(_ s: PressSource) -> String {
        switch s {
        case .hardwareKey: return "hardwareKey"
        case .hint(let id): return "hint(\(id))"
        case .keyboardRow: return "keyboardRow"
        }
    }

    static func source(_ text: String) throws -> PressSource {
        if text == "hardwareKey" { return .hardwareKey }
        if text == "keyboardRow" { return .keyboardRow }
        if text.hasPrefix("hint("), text.hasSuffix(")") { return .hint(String(text.dropFirst(5).dropLast())) }
        throw ContractError("unknown source \(text)")
    }

    let stage: Stage
    let clock = Clock()
    /// The play clock over the case's uptime (R8a): paused by freeze and background.
    let play: PlayClock
    var queue: PressQueue

    init(given: [String: JSONValue], draws: DrawQueues) throws {
        var k = Self.specKnobs
        if case .object(let o)? = given["knobs"] {
            k = PressQueueKnobs(holdS: o["hold_s"]?.number ?? k.holdS, queueMax: o["queue_max"]?.number.map { Int($0) } ?? k.queueMax,
                                formedTimeoutS: o["formed_timeout_s"]?.number ?? k.formedTimeoutS,
                                wordOffsetS: o["word_offset_s"]?.number ?? k.wordOffsetS,
                                holdExtMaxS: o["hold_ext_max_s"]?.number ?? k.holdExtMaxS,
                                wordLenMaxS: o["word_len_max_s"]?.number ?? k.wordLenMaxS)
        }
        var table: [String: JSONValue] = [:]
        if case .object(let r)? = given["reveal"] { table = r }
        stage = Stage(table: table)
        stage.reduceMotion = given["accessibility"]?["reduceMotion"] == .bool(true)
        play = PlayClock(uptime: clock)
        queue = PressQueue(knobs: k, stage: stage, clock: play, log: Log(stage: stage))
    }

    mutating func step(uptime: Double, event e: [String: JSONValue]) throws -> Outputs {
        clock.t = uptime
        stage.calls = []
        defer { stage.missing = nil }
        switch e["type"]?.string {
        case "press":
            let p = Press(key: e["key"]?.string ?? "", source: try Self.source(e["source"]?.string ?? ""),
                          time: uptime - (e["stampLag"]?.number ?? 0), origin: try Self.origin(e["origin"]))
            let outcome = queue.press(p)
            try checkStage()
            switch outcome {
            case .started(let id, let r0, let castId):
                return stage.calls + [.object(["out": .string("started"), "revealId": .int(Int64(id)), "r0": .double(r0),
                                               "castId": .string(castId)])]
            case .queued(let index): return [.object(["out": .string("queued"), "index": .int(Int64(index))])]
            case .ignored: return [.object(["out": .string("ignored")])]
            }
        case "tick":
            queue.tick(now: play.play(uptime))
            try checkStage()
            return stage.calls
        case "accessibilityChanged":
            stage.reduceMotion = e["reduceMotion"] == .bool(true)
            return []
        case "formed":
            queue.formed(revealId: Int(e["revealId"]?.number ?? 0))
            return []
        // The Reveal Stage's part (architecture §3): it pauses and resumes the play clock and tells the queue.
        case "freeze":
            play.pause(.freeze, at: uptime)
            queue.freeze()
            return []
        case "resume":
            play.resume(.freeze, at: uptime)
            queue.resume()
            return []
        case "panelOpen":
            // A correct answer opens the panel: the settle is at the (frozen) play time, then the freeze ends.
            queue.settle()
            play.resume(.freeze, at: uptime)
            return []
        case "panelClose":
            return []
        case "background":
            queue.settle()
            play.pause(.background, at: uptime)
            return []
        case "foreground":
            play.resume(.background, at: uptime)
            return []
        default:
            throw ContractError("event \(e["type"]?.string ?? "?") is not a press-queue-v2 event")
        }
    }

    /// Throws when the queue started a key `given.reveal` doesn't answer.
    func checkStage() throws {
        if let k = stage.missing { throw ContractError("given.reveal has no \(k)") }
    }

    /// A press's `origin`: `[x, y]` (stage point) or absent / null.
    static func origin(_ v: JSONValue?) throws -> PressOrigin? {
        guard let v, v != .null else { return nil }
        guard let a = v.array, a.count == 2, let x = a[0].number, let y = a[1].number else {
            throw ContractError("origin must be [x, y], got \(v)")
        }
        return PressOrigin(x: x, y: y)
    }

    /// spec.md State: `current` (a record), `queueKeys`, `restingSince` (R10), `nextRevealId`.
    func state(_ name: String) throws -> JSONValue {
        switch name {
        case "queueKeys": return .array(queue.queue.map { .string($0.key) })
        case "nextRevealId": return .int(Int64(queue.nextRevealId))
        case "restingSince": return queue.restingSince.map { .double($0) } ?? .null
        case "current":
            guard let c = queue.current else { return .null }
            return .object(["revealId": .int(Int64(c.revealId)), "key": .string(c.key), "holdEff": .double(c.holdEff),
                            "formed": .bool(c.formed), "formedAt": c.formedAt.map { .double($0) } ?? .null])
        default: throw ContractError("expectState.\(name) is not press-queue-v2 state (spec.md State)")
        }
    }
}

/// press-queue-v2's runner self-tests (ADR-0004 V2): planted cases the real file can't hold. The real file runs in
/// `ContractHarnessTests` through the registry row (`runner: PressQueueRunner`, story press-queue/005).
final class PressQueueContractTests: XCTestCase {
    /// One planted case through the harness: a press of `key` from a hint at `origin`, with `D` the only reveal.
    func planted(key: String, origin: String, expectOrigin: String) throws -> String? {
        let text = """
        {"id": "planted", "source": "gdd: press-queue.md R12", "given": {"reveal": {"D": {"formedS": 2.5, "revealLen": 3.0,
         "hasWord": true, "wordLen": 0.5, "castId": "tb_d_item_01"}}}, "draws": {}, "steps": [{"t": {"uptime": 10.0},
         "event": {"type": "press", "key": "\(key)", "source": "hint(h1)", "origin": \(origin)},
         "expect": [{"out": "startReveal", "revealId": 1, "key": "\(key)", "source": "hint(h1)", "origin": \(expectOrigin), "r0": 10.0},
                    {"out": "started", "revealId": 1, "r0": 10.0, "castId": "tb_d_item_01"}]}]}
        """
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("pq-\(UUID().uuidString).json")
        try text.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        return ContractHarness.runCase(try Fixture.load(url), contract: "press-queue-v2", runner: PressQueueRunner.self,
                                       fixtures: [:], tolerances: ["time": 1e-9])
    }

    func test_the_runner_passes_origin_through_as_x_y() throws {
        XCTAssertNil(try planted(key: "D", origin: "[400.0, 200.0]", expectOrigin: "[400.0, 200.0]"))
        let f = try planted(key: "D", origin: "[400.0, 200.0]", expectOrigin: "[400.0, 201.0]")
        XCTAssertTrue(f?.contains("steps[0].expect[0].origin[1]: expected 201") ?? false, f ?? "passed")
    }

    func test_the_runner_fails_a_key_missing_from_given_reveal() throws {
        let f = try planted(key: "E", origin: "null", expectOrigin: "null")
        XCTAssertTrue(f?.contains("given.reveal has no E") ?? false, f ?? "passed")
    }
}
