import ContractKit
import Foundation
import XCTest

/// One step's outputs, as JSON values in the case's `expect` format.
typealias Outputs = [JSONValue]

/// What a contract runner provides (ADR-0004 D5): its declaration (for the structural check), the field kinds of its
/// doubles, and a fresh instance per case that runs one step at a time.
protocol ContractRunner {
    static var contract: String { get }
    static var declaration: ContractDeclaration { get }
    /// The layer this harness runs, for contracts with layers; nil runs every case.
    static var layer: String? { get }
    /// The field kind of an output field (`<out>.<field>`), for the tolerance (case-schema-v1 §6).
    static func kind(out: String, field: String) -> String?
    init(given: [String: JSONValue], draws: DrawQueues) throws
    mutating func step(uptime: Double, event: [String: JSONValue]) throws -> Outputs
}

extension ContractRunner {
    static var layer: String? { nil }
}

/// The case's `draws`, one queue per stream (case-schema-v1 §5). A draw past the end throws; the harness FAILs a
/// case that ends with values left in any queue.
final class DrawQueues {
    private(set) var queues: [String: [UInt64]]
    init(_ q: [String: [UInt64]]) { queues = q }
    struct Exhausted: Error, CustomStringConvertible { let stream: String; var description: String { "draw past the end of \(stream)" } }
    func next(_ stream: String) throws -> UInt64 {
        guard var q = queues[stream], !q.isEmpty else { throw Exhausted(stream: stream) }
        let v = q.removeFirst(); queues[stream] = q; return v
    }
    var leftover: [String: Int] { queues.filter { !$0.value.isEmpty }.mapValues(\.count) }
}

/// The KidCore harness (ADR-0004 D5). Every failure is a message; an empty list is a pass.
enum ContractHarness {
    /// The runners this harness registers. A contract directory with no runner here is a FAIL.
    static let registry: [ContractRunner.Type] = [SettingsRecordRunner.self]

    struct Report {
        var failures: [String] = []
        var counts: [String: (pass: Int, fail: Int)] = [:]
    }

    /// Runs every `contracts/*-v*/cases.json` under `root` (and `cases-generated.json` where present).
    static func runAll(root: URL, registry: [ContractRunner.Type] = registry) -> Report {
        var report = Report()
        let fm = FileManager.default
        let dirs = ((try? fm.contentsOfDirectory(atPath: root.path)) ?? [])
            .filter { $0.range(of: #"-v[0-9]+$"#, options: .regularExpression) != nil }
            .sorted()
        for dir in dirs {
            guard let runner = registry.first(where: { $0.contract == dir }) else {
                report.failures.append("\(dir): no registered runner (ADR-0004 D5)")
                continue
            }
            for name in ["cases.json", "cases-generated.json"] {
                let url = root.appendingPathComponent(dir).appendingPathComponent(name)
                if name == "cases-generated.json" && !fm.fileExists(atPath: url.path) { continue }
                run(file: url, directory: dir, runner: runner, into: &report)
            }
        }
        return report
    }

    static func run(file: URL, directory: String, runner: ContractRunner.Type, into report: inout Report) {
        let fname = "\(directory)/\(file.lastPathComponent)"
        let root: JSONValue
        do { root = try Fixture.load(file) } catch { report.failures.append("\(fname): unreadable (\(error))"); return }
        let schemaErrors = StructuralCheck.check(root, directory: directory, file: fname, declaration: runner.declaration)
        if !schemaErrors.isEmpty { report.failures += schemaErrors.map(\.description); return }
        let fixtures: [String: JSONValue]
        if case .object(let f)? = root["fixtures"] { fixtures = f } else { fixtures = [:] }
        var tolerances: [String: Double] = [:]
        if case .object(let t)? = root["tolerance"] { for (k, v) in t { tolerances[k] = v.number } }
        var pass = 0, fail = 0, ran = 0
        for c in root["cases"]?.array ?? [] {
            if let l = runner.layer, c["layer"]?.string != l { continue }
            ran += 1
            if let msg = runCase(c, contract: directory, runner: runner, fixtures: fixtures, tolerances: tolerances) {
                report.failures.append(msg); fail += 1
            } else { pass += 1 }
        }
        if ran == 0 { report.failures.append("\(fname): 0 cases for this harness (ADR-0004 D5)") }
        let key = runner.layer.map { "\(directory) [\($0)]" } ?? directory
        let prev = report.counts[key] ?? (0, 0)
        report.counts[key] = (prev.pass + pass, prev.fail + fail)
    }

    /// Runs one case; nil when it passes, else `<contract>/<caseId> [<source>] <field path>: expected E, got A (tol T)`.
    static func runCase(_ c: JSONValue, contract: String, runner: ContractRunner.Type,
                        fixtures: [String: JSONValue], tolerances: [String: Double]) -> String? {
        let id = c["id"]?.string ?? "?", source = c["source"]?.string ?? "?"
        let head = "\(contract)/\(id) [\(source)]"
        do {
            guard case .object(let g0)? = c["given"] else { return "\(head) given: not an object" }
            var given: [String: JSONValue] = [:]
            for (k, v) in g0 { given[k] = try Patch.resolve(v, fixtures: fixtures) }
            var draws: [String: [UInt64]] = [:]
            if case .object(let d)? = c["draws"] { for (k, v) in d { draws[k] = (v.array ?? []).compactMap { $0.string.flatMap { UInt64($0) } } } }
            let queues = DrawQueues(draws)
            var r = try runner.init(given: given, draws: queues)
            for (j, s) in (c["steps"]?.array ?? []).enumerated() {
                guard case .object(let e0)? = s["event"] else { return "\(head) steps[\(j)].event: missing" }
                var e: [String: JSONValue] = [:]
                for (k, v) in e0 { e[k] = try Patch.resolve(v, fixtures: fixtures) }
                let got = try r.step(uptime: s["t"]?["uptime"]?.number ?? 0, event: e)
                let want = s["expect"]?.array ?? []
                let outKinds = want.map { $0["out"]?.string ?? "" }
                if let d = Compare.diff(.array(want), .array(got), path: "steps[\(j)].expect",
                                        kindOf: { path in
                                            guard let r = path.range(of: #"\[([0-9]+)\]\.([A-Za-z]+)$"#, options: .regularExpression) else { return nil }
                                            let tail = path[r].dropFirst()
                                            guard let close = tail.firstIndex(of: "]"), let i = Int(tail[..<close]), i < outKinds.count else { return nil }
                                            return runner.kind(out: outKinds[i], field: String(tail[tail.index(close, offsetBy: 2)...]))
                                        }, tolerances: tolerances) {
                    return "\(head) \(d.path): expected \(d.expected), got \(d.actual) (tol \(d.tolerance))"
                }
            }
            let left = queues.leftover
            if !left.isEmpty { return "\(head) draws: \(left.sorted { $0.key < $1.key }.map { "\($0.key) has \($0.value) left" }.joined(separator: ", "))" }
            return nil
        } catch {
            return "\(head) error: \(error)"
        }
    }

    /// The `contracts/` folder for this test file.
    static func contractsRoot(file: String = #filePath) throws -> URL { try Fixture.contractsRoot(from: file) }
}

/// The real run over the repo's contracts (ADR-0004 D5). Each failure is its own XCTFail.
final class ContractHarnessTests: XCTestCase {
    func test_every_contract_in_the_repo() throws {
        let report = ContractHarness.runAll(root: try ContractHarness.contractsRoot())
        for (k, v) in report.counts.sorted(by: { $0.key < $1.key }) { print("CONTRACT \(k): \(v.pass) pass, \(v.fail) fail") }
        for f in report.failures { XCTFail(f) }
    }
}
