/// Compares an expected and an actual JSON value (case-schema-v1 §6). Doubles compare within the tolerance for their
/// field kind; everything else exactly. Returns the first difference as `(path, expected, actual, tolerance)`.
public enum Compare {
    public struct Difference: Equatable, Sendable {
        public let path: String
        public let expected: String
        public let actual: String
        public let tolerance: Double
    }

    /// `kindOf(path)` names the field kind for a numeric field path (for example `gain`), and `tolerances` maps
    /// kinds to values. A number with no kind compares exactly.
    public static func diff(_ e: JSONValue, _ a: JSONValue, path: String = "",
                            kindOf: (String) -> String? = { _ in nil }, tolerances: [String: Double] = [:]) -> Difference? {
        switch (e, a) {
        case (.object(let eo), .object(let ao)):
            for k in Set(eo.keys).union(ao.keys).sorted() {
                let p = path.isEmpty ? k : "\(path).\(k)"
                guard let ev = eo[k] else { return Difference(path: p, expected: "absent", actual: render(ao[k]!), tolerance: 0) }
                guard let av = ao[k] else { return Difference(path: p, expected: render(ev), actual: "absent", tolerance: 0) }
                if let d = diff(ev, av, path: p, kindOf: kindOf, tolerances: tolerances) { return d }
            }
            return nil
        case (.array(let ea), .array(let aa)):
            if ea.count != aa.count { return Difference(path: "\(path).count", expected: "\(ea.count)", actual: "\(aa.count)", tolerance: 0) }
            for i in ea.indices { if let d = diff(ea[i], aa[i], path: "\(path)[\(i)]", kindOf: kindOf, tolerances: tolerances) { return d } }
            return nil
        default:
            if let en = e.number, let an = a.number {
                let tol = kindOf(path).flatMap { tolerances[$0] } ?? 0
                let same = tol == 0 ? en == an : abs(en - an) <= tol
                return same ? nil : Difference(path: path, expected: render(e), actual: render(a), tolerance: tol)
            }
            return e == a ? nil : Difference(path: path, expected: render(e), actual: render(a), tolerance: 0)
        }
    }

    public static func render(_ v: JSONValue) -> String {
        switch v {
        case .null: return "null"
        case .bool(let b): return b ? "true" : "false"
        case .int(let i): return "\(i)"
        case .double(let d): return "\(d)"
        case .string(let s): return "\"\(s)\""
        case .array(let a): return "[" + a.map(render).joined(separator: ",") + "]"
        case .object(let o): return "{" + o.keys.sorted().map { "\"\($0)\":\(render(o[$0]!))" }.joined(separator: ",") + "}"
        }
    }
}
