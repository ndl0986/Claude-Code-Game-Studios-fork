import Foundation

/// What a contract's `spec.md` declares, as its runner registers it (case-schema-v1 §2–§4).
public struct ContractDeclaration: Sendable {
    /// The `given` fields `spec.md` lists (S8). A case may omit any of them.
    public let givenFields: Set<String>
    /// Contract-local entry points and their fields (S18), added to the shared event list.
    public let events: [String: Set<String>]
    /// The layers `spec.md` defines, or empty when it defines none (S7).
    public let layers: Set<String>

    public init(givenFields: Set<String>, events: [String: Set<String>], layers: Set<String> = []) {
        self.givenFields = givenFields
        self.events = events
        self.layers = layers
    }

    /// The shared event list (ADR-0004 D4). Their fields are not declared here, so a contract that uses one lists
    /// it in `events` with its fields.
    public static let sharedEventTypes: Set<String> = [
        "key", "touch", "tick", "freeze", "resume", "settle", "panelOpen", "panelClose", "foreground", "background",
        "active", "inactive", "windowKeyGained", "windowKeyLost", "screenChanged", "memoryWarning", "ready",
        "kioskModeOnSet", "kioskModeOnCleared", "themeReady", "settingsChanged", "displayMetricsChanged",
        "accessibilityChanged",
    ]
}

/// One schema error: `<file> <JSON path>: <rule S#>` (case-schema-v1 §7).
public struct SchemaError: Error, Equatable, CustomStringConvertible, Sendable {
    public let file: String
    public let path: String
    public let rule: String
    public var description: String { "\(file) \(path): \(rule)" }
}

/// The strict structural check of case-schema-v1, run on a whole file before any case runs (ADR-0004 D4).
public enum StructuralCheck {
    static let topKeys: Set<String> = ["contract", "schema", "uint64AsString", "units", "tolerance", "streams", "fixtures", "cases"]
    static let caseKeys: Set<String> = ["id", "source", "layer", "note", "given", "draws", "steps", "expect", "tolerance", "toleranceReason", "permute"]
    static let forbidden: Set<String> = ["play", "u", "seed"]

    /// Every schema error in `root`, the decoded `cases.json` of directory `directory` (for example `press-queue-v1`).
    /// With no `declaration` (a contract whose code is not started, K-40) the generic rules run and the
    /// `spec.md`-specific ones (S7's layer names, S8's given fields, S18's event types and fields) are skipped.
    public static func check(_ root: JSONValue, directory: String, file: String, declaration: ContractDeclaration?) -> [SchemaError] {
        var errors: [SchemaError] = []
        func fail(_ path: String, _ rule: String) { errors.append(SchemaError(file: file, path: path, rule: rule)) }
        guard case .object(let top) = root else { fail("$", "top level is not an object"); return errors }

        for k in top.keys.sorted() where !topKeys.contains(k) { fail("$.\(k)", "S4 unknown top-level key") }
        if top["contract"]?.string != directory { fail("$.contract", "S1 contract must equal the directory name") }
        if top["schema"] != .int(1) { fail("$.schema", "S2 schema must be 1") }
        if top["uint64AsString"] != .bool(true) { fail("$.uint64AsString", "required true") }
        for k in ["units", "tolerance"] where !isObject(top[k]) { fail("$.\(k)", "required object") }
        var streams = Set<String>()
        if let s = top["streams"]?.array, s.allSatisfy({ $0.string != nil }) { streams = Set(s.compactMap(\.string)) } else {
            fail("$.streams", "required string array")
        }
        var fixtures: [String: JSONValue] = [:]
        if let f = top["fixtures"] { if case .object(let o) = f { fixtures = o } else { fail("$.fixtures", "must be an object") } }
        guard let cases = top["cases"]?.array, !cases.isEmpty else { fail("$.cases", "S3 at least one case"); return errors }

        var ids = Set<String>()
        for (i, c) in cases.enumerated() {
            let p = "$.cases[\(i)]"
            guard case .object(let o) = c else { fail(p, "case is not an object"); continue }
            for k in o.keys.sorted() where !caseKeys.contains(k) { fail("\(p).\(k)", "S12 unknown case key") }
            if let id = o["id"]?.string, !id.isEmpty {
                if !ids.insert(id).inserted { fail("\(p).id", "S5 duplicate id \(id)") }
            } else { fail("\(p).id", "S5 id required") }
            if let s = o["source"]?.string, validSource(s) {} else { fail("\(p).source", "S6 source format") }
            if let declaration {
                if declaration.layers.isEmpty {
                    if o["layer"] != nil { fail("\(p).layer", "S7 layer where spec.md defines none") }
                } else if let l = o["layer"]?.string, declaration.layers.contains(l) {} else { fail("\(p).layer", "S7 layer missing or unknown") }
            } else if o["layer"] != nil && o["layer"]?.string == nil { fail("\(p).layer", "S7 layer must be a string") }
            if case .object(let g)? = o["given"] {
                for k in g.keys.sorted() where declaration.map({ !$0.givenFields.contains(k) }) ?? false { fail("\(p).given.\(k)", "S8 unknown given field") }
                for (k, v) in g { checkFixtureRefs(v, fixtures, "\(p).given.\(k)", fail) }
            } else { fail("\(p).given", "given required object") }
            if case .object(let d)? = o["draws"] {
                for (k, v) in d.sorted(by: { $0.key < $1.key }) {
                    if !streams.contains(k) { fail("\(p).draws.\(k)", "S9 stream not listed at the top level") }
                    for (j, x) in (v.array ?? []).enumerated() where !validUInt64(x) { fail("\(p).draws.\(k)[\(j)]", "S10 not a UInt64 decimal string") }
                    if v.array == nil { fail("\(p).draws.\(k)", "S10 must be an array") }
                }
            } else { fail("\(p).draws", "draws required object") }
            if o["tolerance"] != nil && o["toleranceReason"]?.string == nil { fail("\(p).tolerance", "S11 tolerance needs toleranceReason") }
            forbiddenKeys(c, p, fail)
            guard let steps = o["steps"]?.array, !steps.isEmpty else { fail("\(p).steps", "at least one step"); continue }
            var last = -Double.infinity
            for (j, s) in steps.enumerated() {
                let sp = "\(p).steps[\(j)]"
                guard let up = s["t"]?["uptime"]?.number else { fail("\(sp).t.uptime", "S16 uptime required"); continue }
                if up < last { fail("\(sp).t.uptime", "S16 uptime decreases") }
                last = up
                guard case .object(let e)? = s["event"], let type = e["type"]?.string else { fail("\(sp).event", "S18 event type required"); continue }
                if e["time"] != nil { fail("\(sp).event.time", "S17 events carry no time") }
                guard let declaration else { if s["expect"]?.array == nil { fail("\(sp).expect", "expect must be an ordered list") }; continue }
                guard let fields = declaration.events[type] else { fail("\(sp).event.type", "S18 undeclared event type \(type)"); continue }
                for k in e.keys.sorted() where k != "type" && k != "time" && !fields.contains(k) { fail("\(sp).event.\(k)", "S18 undeclared event field") }
                for (k, v) in e { checkFixtureRefs(v, fixtures, "\(sp).event.\(k)", fail) }
                if s["expect"]?.array == nil { fail("\(sp).expect", "expect must be an ordered list") }
            }
        }
        return errors
    }

    static func isObject(_ v: JSONValue?) -> Bool { if case .object? = v { return true } else { return false } }

    static func validSource(_ s: String) -> Bool {
        if s == "generated" { return true }
        guard s.hasPrefix("gdd: ") else { return false }
        if let r = s.range(of: "; adr: ") { return !s[r.upperBound...].isEmpty }
        return s.utf8.count > 5
    }

    static func validUInt64(_ v: JSONValue) -> Bool {
        guard let s = v.string, !s.isEmpty, s.utf8.allSatisfy({ $0 >= 48 && $0 <= 57 }) else { return false }
        return UInt64(s) != nil
    }

    static func forbiddenKeys(_ v: JSONValue, _ path: String, _ fail: (String, String) -> Void) {
        switch v {
        case .object(let o):
            for (k, x) in o.sorted(by: { $0.key < $1.key }) {
                if forbidden.contains(k) { fail("\(path).\(k)", "S13 forbidden field \(k)") }
                forbiddenKeys(x, "\(path).\(k)", fail)
            }
        case .array(let a): for (i, x) in a.enumerated() { forbiddenKeys(x, "\(path)[\(i)]", fail) }
        default: break
        }
    }

    static func checkFixtureRefs(_ v: JSONValue, _ fixtures: [String: JSONValue], _ path: String, _ fail: (String, String) -> Void) {
        guard case .object(let o) = v else {
            if case .array(let a) = v { for (i, x) in a.enumerated() { checkFixtureRefs(x, fixtures, "\(path)[\(i)]", fail) } }
            return
        }
        guard let name = o["$fixture"]?.string else {
            for (k, x) in o { checkFixtureRefs(x, fixtures, "\(path).\(k)", fail) }
            return
        }
        guard let base = fixtures[name] else { fail(path, "S14 unknown fixture \(name)"); return }
        do { _ = try Patch.apply(o["patch"]?.array ?? [], to: base) } catch { fail("\(path).patch", "S15 \(error)") }
    }
}

/// Resolves `{ "$fixture", "patch" }` references (case-schema-v1 §3; RFC 6901 pointers).
public enum Patch {
    public struct Failure: Error, CustomStringConvertible { public let description: String }

    /// `value` with every fixture reference replaced by its patched copy.
    public static func resolve(_ value: JSONValue, fixtures: [String: JSONValue]) throws -> JSONValue {
        switch value {
        case .object(let o):
            if let name = o["$fixture"]?.string {
                guard let base = fixtures[name] else { throw Failure(description: "unknown fixture \(name)") }
                return try apply(o["patch"]?.array ?? [], to: base)
            }
            return .object(try o.mapValues { try resolve($0, fixtures: fixtures) })
        case .array(let a): return .array(try a.map { try resolve($0, fixtures: fixtures) })
        default: return value
        }
    }

    public static func apply(_ ops: [JSONValue], to base: JSONValue) throws -> JSONValue {
        var doc = base
        for op in ops {
            guard let kind = op["op"]?.string, let path = op["path"]?.string else { throw Failure(description: "op and path required") }
            let tokens = try pointer(path)
            switch kind {
            case "replace": doc = try edit(doc, tokens[...]) { cur, last in
                guard try get(cur, last) != nil else { throw Failure(description: "replace: no target \(path)") }
                return try set(cur, last, op["value"] ?? .null, insert: false)
            }
            case "add": doc = try edit(doc, tokens[...]) { cur, last in try set(cur, last, op["value"] ?? .null, insert: true) }
            case "remove": doc = try edit(doc, tokens[...]) { cur, last in try remove(cur, last, path) }
            case "remove-value":
                doc = try edit(doc, tokens[...] + [""]) { cur, _ in
                    guard case .array(var a) = cur, let i = a.firstIndex(of: op["value"] ?? .null) else {
                        throw Failure(description: "remove-value: value not in \(path)")
                    }
                    a.remove(at: i); return .array(a)
                }
            default: throw Failure(description: "unknown op \(kind)")
            }
        }
        return doc
    }

    static func pointer(_ p: String) throws -> [String] {
        if p.isEmpty { return [] }
        guard p.hasPrefix("/") else { throw Failure(description: "bad pointer \(p)") }
        return p.dropFirst().split(separator: "/", omittingEmptySubsequences: false).map {
            $0.replacingOccurrences(of: "~1", with: "/").replacingOccurrences(of: "~0", with: "~")
        }
    }

    /// Walks to the parent of the last token and applies `f(parent, lastToken)`.
    static func edit(_ doc: JSONValue, _ tokens: ArraySlice<String>, _ f: (JSONValue, String) throws -> JSONValue) throws -> JSONValue {
        guard let first = tokens.first else { throw Failure(description: "empty path") }
        if tokens.count == 1 { return try f(doc, first) }
        guard let child = try get(doc, first) else { throw Failure(description: "no target at \(first)") }
        return try set(doc, first, try edit(child, tokens.dropFirst(), f), insert: false)
    }

    static func get(_ doc: JSONValue, _ t: String) throws -> JSONValue? {
        switch doc {
        case .object(let o): return o[t]
        case .array(let a): guard let i = Int(t), i >= 0, i < a.count else { return nil }; return a[i]
        default: return nil
        }
    }

    static func set(_ doc: JSONValue, _ t: String, _ v: JSONValue, insert: Bool) throws -> JSONValue {
        switch doc {
        case .object(var o): o[t] = v; return .object(o)
        case .array(var a):
            if insert {
                if t == "-" { a.append(v); return .array(a) }
                guard let i = Int(t), i >= 0, i <= a.count else { throw Failure(description: "bad index \(t)") }
                a.insert(v, at: i)
            } else {
                guard let i = Int(t), i >= 0, i < a.count else { throw Failure(description: "bad index \(t)") }
                a[i] = v
            }
            return .array(a)
        default: throw Failure(description: "not a container at \(t)")
        }
    }

    static func remove(_ doc: JSONValue, _ t: String, _ path: String) throws -> JSONValue {
        switch doc {
        case .object(var o): guard o.removeValue(forKey: t) != nil else { throw Failure(description: "remove: no target \(path)") }; return .object(o)
        case .array(var a): guard let i = Int(t), i >= 0, i < a.count else { throw Failure(description: "remove: no target \(path)") }; a.remove(at: i); return .array(a)
        default: throw Failure(description: "remove: no target \(path)")
        }
    }
}
