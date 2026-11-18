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

/// The KidCore harness (ADR-0004 D5, with the K-40 note). Every failure is a message; an empty list is a pass.
/// The list of contracts and their states is `contracts/README.md`'s registry, never a list here; this file only maps
/// a registry runner name to the runner type that implements it.
enum ContractHarness {
    /// The runner types this harness implements, found by the name the registry row gives.
    static let runners: [ContractRunner.Type] = [SettingsRecordRunner.self, KeyTableModelRunner.self]

    struct Report {
        var failures: [String] = []
        var counts: [String: (pass: Int, fail: Int)] = [:]
        /// The K-40 lines: `structure: …`, `NOT ASSESSED …`, `SUPERSEDED …`, `contracts: …`.
        var lines: [String] = []
    }

    static func name(_ r: ContractRunner.Type) -> String { String(describing: r) }

    /// Runs every `contracts/*-v*/` under `root` by its registry row (K-40).
    static func runAll(root: URL, runners: [ContractRunner.Type] = runners) -> Report {
        var report = Report()
        let fm = FileManager.default
        let gameRoot = root.deletingLastPathComponent()
        let readme = (try? String(contentsOf: root.appendingPathComponent("README.md"), encoding: .utf8)) ?? ""
        let registry = ContractRegistry(readme: readme)
        report.failures += registry.problems
        let dirs = ContractRegistry.directories(root: root)
        for k in registry.entries.keys.sorted() where !dirs.contains(k) { report.failures.append("registry \(k): no such directory") }

        var structureOK = 0, wellFormed = 0, passed: [String] = [], notStarted: [String] = [], superseded: [String] = [], failed = Set<String>()
        for dir in dirs {
            guard let entry = registry.entries[dir] else {
                report.failures.append("\(dir): no registry row in contracts/README.md (K-40)"); failed.insert(dir); continue
            }
            let file = root.appendingPathComponent(dir).appendingPathComponent("cases.json")
            let fname = "\(dir)/cases.json"
            guard let json = try? Fixture.load(file) else { report.failures.append("\(fname): unreadable"); failed.insert(dir); continue }
            let mine: [ContractRunner.Type]
            if case .runner(let names) = entry.row { mine = runners.filter { names.contains(name($0)) } } else { mine = [] }
            let errors = StructuralCheck.check(json, directory: dir, file: fname, declaration: mine.first?.declaration)
            let n = json["cases"]?.array?.count ?? 0
            if !errors.isEmpty { report.failures += errors.map(\.description); failed.insert(dir); continue }
            if n != entry.cases { report.failures.append("\(dir): \(n) cases, the registry declares \(entry.cases) (K-40)"); failed.insert(dir); continue }
            structureOK += 1; wellFormed += n
            let claimed = runners.filter { $0.contract == dir }
            switch entry.row {
            case .notStarted(let story):
                if !claimed.isEmpty { report.failures.append("\(dir): not-started but runner \(claimed.map(name).joined(separator: ", ")) is registered (K-40)"); failed.insert(dir); continue }
                if ContractRegistry.storyIsDone(story, gameRoot: gameRoot) { report.failures.append("\(dir): not-started but story \(story) is Done (K-40)"); failed.insert(dir); continue }
                report.lines.append("NOT ASSESSED \(dir): not started (story \(story)); structure OK, 0 of \(n) cases run")
                notStarted.append(dir)
            case .supersededBy(let next):
                var bad: [String] = []
                switch registry.entries[next]?.row {
                case .runner?, .notStarted?: if !dirs.contains(next) { bad.append("\(next) has no directory") }
                default: bad.append("\(next) has no runner: or not-started: row")
                }
                if !claimed.isEmpty { bad.append("runner \(claimed.map(name).joined(separator: ", ")) still registered") }
                let cites = ContractRegistry.sourcesCiting(dir, gameRoot: gameRoot)
                if !cites.isEmpty { bad.append("cited by \(cites.joined(separator: ", "))") }
                if !bad.isEmpty { report.failures.append("\(dir): superseded-by \(next): \(bad.joined(separator: "; ")) (K-40)"); failed.insert(dir); continue }
                report.lines.append("SUPERSEDED \(dir) → \(next): not run (\(n) cases)")
                superseded.append(dir)
            case .runner(let names):
                for r in claimed where !names.contains(name(r)) { report.failures.append("\(dir): runner \(name(r)) is not in its registry row (K-40)"); failed.insert(dir) }
                let unknown = names.filter { n in !n.hasPrefix("Tools.") && !runners.contains { name($0) == n } }
                if !unknown.isEmpty { report.failures.append("\(dir): no runner named \(unknown.joined(separator: ", ")) in this harness"); failed.insert(dir); continue }
                let before = report.failures.count
                for r in mine {
                    for fileName in ["cases.json", "cases-generated.json"] {
                        let url = root.appendingPathComponent(dir).appendingPathComponent(fileName)
                        if fileName == "cases-generated.json" && !fm.fileExists(atPath: url.path) { continue }
                        run(file: url, directory: dir, runner: r, into: &report)
                    }
                }
                if report.failures.count > before { failed.insert(dir) } else if !mine.isEmpty { passed.append(dir) }
            }
        }
        report.lines.insert("structure: \(structureOK)/\(dirs.count) contracts OK (\(wellFormed) cases well-formed)", at: 0)
        let passText = passed.isEmpty ? "" : " (\(passed.joined(separator: ", ")))"
        let nsText = notStarted.isEmpty ? "" : " (not-started: \(notStarted.joined(separator: ", ")))"
        report.lines.append("contracts: \(passed.count) run PASS\(passText), \(notStarted.count) NOT ASSESSED\(nsText), \(superseded.count) SUPERSEDED, \(failed.count) FAIL")
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
        // CONTRACTS_ROOT points the run at another contracts folder (a review of a branch's contracts).
        let override = ProcessInfo.processInfo.environment["CONTRACTS_ROOT"].map { URL(fileURLWithPath: $0) }
        let report = ContractHarness.runAll(root: try override ?? ContractHarness.contractsRoot())
        if let first = report.lines.first { print("CONTRACT \(first)") }
        for (k, v) in report.counts.sorted(by: { $0.key < $1.key }) { print("CONTRACT \(k): \(v.pass) pass, \(v.fail) fail") }
        for l in report.lines.dropFirst() { print("CONTRACT \(l)") }
        for f in report.failures { XCTFail(f) }
    }
}
