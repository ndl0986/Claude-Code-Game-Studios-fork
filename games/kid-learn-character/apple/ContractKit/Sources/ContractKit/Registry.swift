import Foundation

/// The contract registry in `contracts/README.md` (K-40; ADR-0004 D5 note). It is the only list: every `*-v*/`
/// directory has exactly one row, in the `## Registry` table, `| <contract> | <row> | <cases> |`, where the row is
/// `runner: <Name>[ + <Name>…]`, `not-started: <story id>` or `superseded-by: <contract-vN+1>`.
public struct ContractRegistry: Sendable {
    public enum Row: Equatable, Sendable {
        /// Runner names; a name starting `Tools.` is run by the apple/Tools harness, every other by KidCore's.
        case runner([String])
        case notStarted(story: String)
        case supersededBy(String)
    }

    public struct Entry: Equatable, Sendable {
        public let row: Row
        /// The declared case count (K-40: checked against the file).
        public let cases: Int
    }

    public let entries: [String: Entry]
    /// Problems in the table itself (a duplicate or unreadable row): each one a FAIL.
    public let problems: [String]

    /// Parses the `## Registry` table of `readme`.
    public init(readme: String) {
        var entries: [String: Entry] = [:], problems: [String] = []
        var inTable = false
        for raw in readme.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("## ") { inTable = line.hasPrefix("## Registry"); continue }
            guard inTable, line.hasPrefix("|") else { continue }
            let cells = line.split(separator: "|", omittingEmptySubsequences: false).dropFirst().dropLast()
                .map { $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "`", with: "") }
            guard cells.count >= 3, cells[0].range(of: #"^[a-z0-9-]+-v[0-9]+$"#, options: .regularExpression) != nil else { continue }
            let name = cells[0], spec = cells[1]
            guard let cases = Int(cells[2]) else { problems.append("registry \(name): case count \(cells[2]) is not a number"); continue }
            let row: Row
            if spec.hasPrefix("runner:") {
                let names = spec.dropFirst(7).split(separator: "+").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                row = .runner(names)
            } else if spec.hasPrefix("not-started:") {
                row = .notStarted(story: spec.dropFirst(12).trimmingCharacters(in: .whitespaces))
            } else if spec.hasPrefix("superseded-by:") {
                row = .supersededBy(spec.dropFirst(14).trimmingCharacters(in: .whitespaces))
            } else { problems.append("registry \(name): row '\(spec)' is not runner:, not-started: or superseded-by:"); continue }
            if entries[name] != nil { problems.append("registry \(name): more than one row") }
            entries[name] = Entry(row: row, cases: cases)
        }
        self.entries = entries
        self.problems = problems
    }

    /// The `*-v*` directories under `root`, sorted.
    public static func directories(root: URL) -> [String] {
        ((try? FileManager.default.contentsOfDirectory(atPath: root.path)) ?? [])
            .filter { $0.range(of: #"^[a-z0-9-]+-v[0-9]+$"#, options: .regularExpression) != nil }
            .sorted()
    }

    /// Whether `story` names a story whose file under `production/` says `Status: Done` (K-40). Placeholder ids
    /// (`story:<system>`) resolve to no file until /create-stories exists, so they are never Done.
    public static func storyIsDone(_ story: String, gameRoot: URL) -> Bool {
        let fm = FileManager.default
        guard let e = fm.enumerator(at: gameRoot.appendingPathComponent("production"), includingPropertiesForKeys: nil) else { return false }
        for case let url as URL in e where url.pathExtension == "md" {
            guard let text = try? String(contentsOf: url, encoding: .utf8), text.contains(story) else { continue }
            let mentionsId = text.range(of: "(Story|ID)[^\\n]*\(NSRegularExpression.escapedPattern(for: story))", options: .regularExpression) != nil
            if mentionsId && text.range(of: #"(?m)^\**Status\**:\**\s*Done"#, options: .regularExpression) != nil { return true }
        }
        return false
    }

    /// Code under `apple/*/Sources` that names `contract` (a superseded version must not be cited as current, K-40).
    public static func sourcesCiting(_ contract: String, gameRoot: URL) -> [String] {
        let apple = gameRoot.appendingPathComponent("apple")
        var hits: [String] = []
        for pkg in (try? FileManager.default.contentsOfDirectory(atPath: apple.path)) ?? [] {
            let src = apple.appendingPathComponent(pkg).appendingPathComponent("Sources")
            guard let e = FileManager.default.enumerator(at: src, includingPropertiesForKeys: nil) else { continue }
            for case let url as URL in e where url.pathExtension == "swift" {
                if let t = try? String(contentsOf: url, encoding: .utf8), t.contains(contract) { hits.append("apple/\(pkg)/Sources/\(url.lastPathComponent)") }
            }
        }
        return hits.sorted()
    }
}
