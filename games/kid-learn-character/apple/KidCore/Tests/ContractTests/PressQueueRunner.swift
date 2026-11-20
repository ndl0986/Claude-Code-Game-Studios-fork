import ContractKit
import Foundation
import KidCore
import XCTest

/// press-queue-v2, KidCore layer (ADR-0004 D3; story press-queue/001). Covers the start / queue / formed-guard /
/// ignore rules only. Not registered in `ContractHarness.runners`: the registry row stays `not-started` until
/// press-queue/005 (ContractKit fails a registered runner on a not-started row), so `PressQueueContractTests`
/// below runs the explicit `inScope` list itself and reports every other case id as NOT ASSESSED.
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

    /// The fake Reveal Stage and Key Table: answers from the case's `reveal` table and records its calls.
    final class Stage: PressQueueStage {
        let table: [String: JSONValue]
        var calls: [JSONValue] = []
        init(table: [String: JSONValue]) { self.table = table }
        func startReveal(revealId: Int, key: String, source: PressSource, origin: PressOrigin?, r0: Double) -> RevealStart {
            let e = table[key]
            calls.append(.object(["out": .string("startReveal"), "revealId": .int(Int64(revealId)), "key": .string(key),
                                  "source": .string(PressQueueRunner.sourceText(source)),
                                  "origin": origin.map { .object(["x": .double($0.x), "y": .double($0.y)]) } ?? .null,
                                  "r0": .double(r0)]))
            return RevealStart(formedS: e?["formedS"]?.number ?? 0, revealLen: e?["revealLen"]?.number ?? 0,
                               hasWord: e?["hasWord"] == .bool(true), wordLen: e?["wordLen"]?.number,
                               castId: e?["castId"]?.string ?? "")
        }
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
        queue = PressQueue(knobs: k, stage: stage, clock: clock)
    }

    mutating func step(uptime: Double, event e: [String: JSONValue]) throws -> Outputs {
        clock.t = uptime
        stage.calls = []
        switch e["type"]?.string {
        case "press":
            let p = Press(key: e["key"]?.string ?? "", source: try Self.source(e["source"]?.string ?? ""),
                          time: uptime - (e["stampLag"]?.number ?? 0))
            let outcome = queue.press(p)
            switch outcome {
            case .started(let id, let r0, let castId):
                return stage.calls + [.object(["out": .string("started"), "revealId": .int(Int64(id)), "r0": .double(r0),
                                               "castId": .string(castId)])]
            case .queued(let index): return [.object(["out": .string("queued"), "index": .int(Int64(index))])]
            case .ignored: return [.object(["out": .string("ignored")])]
            }
        case "tick":
            queue.tick(now: uptime)
            return stage.calls
        case "formed":
            queue.formed(revealId: Int(e["revealId"]?.number ?? 0))
            return []
        default:
            throw ContractError("event \(e["type"]?.string ?? "?") is not in press-queue/001's scope")
        }
    }

    /// The part of the state `expectState` names. A field outside this story's state is an error, not a pass.
    func state(_ names: [String]) throws -> JSONValue {
        var o: [String: JSONValue] = [:]
        for n in names {
            switch n {
            case "queueKeys": o[n] = .array(queue.queue.map { .string($0.key) })
            case "nextRevealId": o[n] = .int(Int64(queue.nextRevealId))
            default: throw ContractError("expectState.\(n) is not in press-queue/001's scope")
            }
        }
        return .object(o)
    }
}

/// Runs press-queue-v2's in-scope cases (all must pass) and names every other case NOT ASSESSED by id.
final class PressQueueContractTests: XCTestCase {
    /// The cases that test nothing beyond story 001: AC-1..AC-4 and the two R3.1 conjuncts (hold passed but not
    /// formed, formed but hold not passed). Each uses only press, tick and formed on the default knobs.
    static let inScope = [
        "AC1-start-at-once", "AC2-queue-during-hold-then-advance", "AC3-formed-guard", "AC4-ignore-when-full",
        "R3-hold-passed-but-not-formed-queues", "R3-formed-but-hold-not-passed-queues",
    ]

    func test_press_queue_v2_cases_in_story_001_scope() throws {
        let file = try ContractHarness.contractsRoot().appendingPathComponent("press-queue-v2/cases.json")
        let root = try Fixture.load(file)
        var fixtures: [String: JSONValue] = [:]
        if case .object(let f)? = root["fixtures"] { fixtures = f }
        var tolerances: [String: Double] = [:]
        if case .object(let t)? = root["tolerance"] { for (k, v) in t { tolerances[k] = v.number } }
        let all = root["cases"]?.array ?? []
        let ids = all.compactMap { $0["id"]?.string }
        var pass = 0, fail = 0
        for id in Self.inScope {
            guard let c = all.first(where: { $0["id"]?.string == id }) else { XCTFail("press-queue-v2/\(id): no such case"); fail += 1; continue }
            if let msg = ContractHarness.runCase(c, contract: "press-queue-v2", runner: PressQueueRunner.self,
                                                 fixtures: fixtures, tolerances: tolerances) ?? stateFailure(c, fixtures) {
                XCTFail(msg); fail += 1
            } else { pass += 1 }
        }
        let notAssessed = ids.filter { !Self.inScope.contains($0) }
        print("CONTRACT press-queue-v2: \(pass) pass, \(fail) fail; \(notAssessed.count) NOT ASSESSED (outside story press-queue/001): \(notAssessed.joined(separator: ", "))")
    }

    /// `ContractHarness.runCase` compares `expect` only; this replays a case and compares each step's `expectState`.
    func stateFailure(_ c: JSONValue, _ fixtures: [String: JSONValue]) -> String? {
        let head = "press-queue-v2/\(c["id"]?.string ?? "?") [\(c["source"]?.string ?? "?")]"
        do {
            var given: [String: JSONValue] = [:]
            if case .object(let g)? = c["given"] { for (k, v) in g { given[k] = try Patch.resolve(v, fixtures: fixtures) } }
            var r = try PressQueueRunner(given: given, draws: DrawQueues([:]))
            for (j, s) in (c["steps"]?.array ?? []).enumerated() {
                guard case .object(let e)? = s["event"] else { return "\(head) steps[\(j)].event: missing" }
                _ = try r.step(uptime: s["t"]?["uptime"]?.number ?? 0, event: e)
                guard case .object(let want)? = s["expectState"] else { continue }
                let got = try r.state(Array(want.keys))
                if let d = Compare.diff(.object(want), got, path: "steps[\(j)].expectState") {
                    return "\(head) \(d.path): expected \(d.expected), got \(d.actual)"
                }
            }
            return nil
        } catch { return "\(head) error: \(error)" }
    }
}
