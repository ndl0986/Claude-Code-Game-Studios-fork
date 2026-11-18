import Foundation

/// A decoded JSON value from a contract fixture (ADR-0004). Numbers stay `Double` or `Int64` as written.
public indirect enum JSONValue: Equatable, Sendable {
    case null, bool(Bool), int(Int64), double(Double), string(String), array([JSONValue]), object([String: JSONValue])

    /// The member `key` of an object, or nil.
    public subscript(key: String) -> JSONValue? { if case .object(let o) = self { return o[key] } else { return nil } }
    /// The array's elements, or nil.
    public var array: [JSONValue]? { if case .array(let a) = self { return a } else { return nil } }
    /// The string, or nil.
    public var string: String? { if case .string(let s) = self { return s } else { return nil } }
    /// The number as a Double (an integer is widened), or nil.
    public var number: Double? {
        switch self { case .int(let i): return Double(i); case .double(let d): return d; default: return nil }
    }
}

public enum FixtureError: Error, Equatable { case notFound(String), invalidJSON(String) }

/// Loads contract fixtures from the game's `contracts/` folder.
public enum Fixture {
    /// The `contracts/` folder (the one holding README.md), found by walking up from `file` (pass `#filePath`).
    public static func contractsRoot(from file: String) throws -> URL {
        var dir = URL(fileURLWithPath: file).deletingLastPathComponent()
        while dir.path != "/" {
            let c = dir.appendingPathComponent("contracts")
            if FileManager.default.fileExists(atPath: c.appendingPathComponent("README.md").path) { return c }
            dir.deleteLastPathComponent()
        }
        throw FixtureError.notFound("contracts/ above \(file)")
    }

    /// Decodes the JSON file at `url`.
    public static func load(_ url: URL) throws -> JSONValue {
        guard let data = FileManager.default.contents(atPath: url.path) else { throw FixtureError.notFound(url.lastPathComponent) }
        let any: Any
        do { any = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) } catch {
            throw FixtureError.invalidJSON(url.lastPathComponent)
        }
        return convert(any)
    }

    static func convert(_ any: Any) -> JSONValue {
        switch any {
        case is NSNull: return .null
        case let n as NSNumber:
            if CFGetTypeID(n) == CFBooleanGetTypeID() { return .bool(n.boolValue) }
            return CFNumberIsFloatType(n) ? .double(n.doubleValue) : .int(n.int64Value)
        case let s as String: return .string(s)
        case let a as [Any]: return .array(a.map(convert))
        case let o as [String: Any]: return .object(o.mapValues(convert))
        default: return .null
        }
    }
}
