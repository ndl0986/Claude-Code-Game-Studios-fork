/// The hand-written JSON reader and canonical writer for the settings record (Settings Store R6a; ADR-0002 D8,
/// ADR-0004 D3). No JSON library (ADR-0002 D2): UTF-8 bytes in, bytes out, so Kotlin can mirror it one-to-one.
public enum CanonicalJSON {
    /// A JSON value as the reader sees it. Every number token is a `Double` (R6a, SS-Q2). Object members keep their
    /// order; a duplicate key never gets here (the reader rejects it, SS-Q6).
    public indirect enum Value: Equatable, Sendable {
        case null
        case bool(Bool)
        case number(Double)
        case string(String)
        case array([Value])
        case object([(key: String, value: Value)])

        public static func == (a: Value, b: Value) -> Bool {
            switch (a, b) {
            case (.null, .null): return true
            case (.bool(let x), .bool(let y)): return x == y
            case (.number(let x), .number(let y)): return x == y
            case (.string(let x), .string(let y)): return x == y
            case (.array(let x), .array(let y)): return x == y
            case (.object(let x), .object(let y)):
                return x.count == y.count && zip(x, y).allSatisfy { $0.key == $1.key && $0.value == $1.value }
            default: return false
            }
        }
    }

    /// Why bytes are unreadable (R6: the whole record falls back). The reason text is never logged with values.
    public enum ReadError: Error, Equatable, Sendable { case empty, syntax(Int), duplicateKey, invalidUTF8 }

    /// Parses one JSON value spanning all of `bytes` (whitespace allowed around it). Strict RFC 8259 grammar: a bare
    /// `NaN` or `Infinity` is a syntax error (SS-Q3); a duplicate object key is an error (SS-Q6).
    public static func parse(_ bytes: [UInt8]) throws -> Value {
        var p = Parser(b: bytes)
        p.skipSpace()
        if p.i >= bytes.count { throw ReadError.empty }
        let v = try p.value(depth: 0)
        p.skipSpace()
        if p.i != bytes.count { throw ReadError.syntax(p.i) }
        return v
    }

    /// Writes a string with R6a's escaping: only `"`, `\` and U+0000–U+001F (as lowercase `\u00xx`) are escaped;
    /// everything else is raw UTF-8.
    public static func appendString(_ s: String, to out: inout [UInt8]) {
        out.append(0x22)
        for c in s.utf8 {
            switch c {
            case 0x22: out.append(contentsOf: [0x5C, 0x22])
            case 0x5C: out.append(contentsOf: [0x5C, 0x5C])
            case 0x00...0x1F:
                let hex: [UInt8] = Array("0123456789abcdef".utf8)
                out.append(contentsOf: [0x5C, 0x75, 0x30, 0x30, hex[Int(c >> 4)], hex[Int(c & 0x0F)]])
            default: out.append(c)
            }
        }
        out.append(0x22)
    }

    /// Writes an integer with no fraction.
    public static func appendInt(_ n: Int, to out: inout [UInt8]) { out.append(contentsOf: Array(String(n).utf8)) }

    struct Parser {
        let b: [UInt8]
        var i = 0

        mutating func skipSpace() { while i < b.count, b[i] == 0x20 || b[i] == 0x09 || b[i] == 0x0A || b[i] == 0x0D { i += 1 } }

        mutating func value(depth: Int) throws -> Value {
            guard depth < 64, i < b.count else { throw ReadError.syntax(i) }
            switch b[i] {
            case 0x7B: return try object(depth: depth)
            case 0x5B: return try array(depth: depth)
            case 0x22: return .string(try string())
            case 0x74: try literal("true"); return .bool(true)
            case 0x66: try literal("false"); return .bool(false)
            case 0x6E: try literal("null"); return .null
            default: return .number(try number())
            }
        }

        mutating func literal(_ word: String) throws {
            let w = Array(word.utf8)
            guard i + w.count <= b.count, Array(b[i..<(i + w.count)]) == w else { throw ReadError.syntax(i) }
            i += w.count
        }

        mutating func object(depth: Int) throws -> Value {
            i += 1
            var members: [(key: String, value: Value)] = []
            var seen = Set<String>()
            skipSpace()
            if i < b.count, b[i] == 0x7D { i += 1; return .object(members) }
            while true {
                skipSpace()
                guard i < b.count, b[i] == 0x22 else { throw ReadError.syntax(i) }
                let k = try string()
                if !seen.insert(k).inserted { throw ReadError.duplicateKey }
                skipSpace()
                guard i < b.count, b[i] == 0x3A else { throw ReadError.syntax(i) }
                i += 1
                skipSpace()
                members.append((k, try value(depth: depth + 1)))
                skipSpace()
                guard i < b.count else { throw ReadError.syntax(i) }
                if b[i] == 0x2C { i += 1; continue }
                if b[i] == 0x7D { i += 1; return .object(members) }
                throw ReadError.syntax(i)
            }
        }

        mutating func array(depth: Int) throws -> Value {
            i += 1
            var items: [Value] = []
            skipSpace()
            if i < b.count, b[i] == 0x5D { i += 1; return .array(items) }
            while true {
                skipSpace()
                items.append(try value(depth: depth + 1))
                skipSpace()
                guard i < b.count else { throw ReadError.syntax(i) }
                if b[i] == 0x2C { i += 1; continue }
                if b[i] == 0x5D { i += 1; return .array(items) }
                throw ReadError.syntax(i)
            }
        }

        mutating func hex4() throws -> Int {
            guard i + 4 <= b.count else { throw ReadError.syntax(i) }
            var v = 0
            for _ in 0..<4 {
                let c = b[i]
                let d: Int
                switch c {
                case 0x30...0x39: d = Int(c) - 0x30
                case 0x41...0x46: d = Int(c) - 0x41 + 10
                case 0x61...0x66: d = Int(c) - 0x61 + 10
                default: throw ReadError.syntax(i)
                }
                v = v * 16 + d
                i += 1
            }
            return v
        }

        static func appendUTF8(_ cp: Int, _ out: inout [UInt8]) {
            switch cp {
            case 0..<0x80: out.append(UInt8(cp))
            case 0x80..<0x800: out.append(contentsOf: [UInt8(0xC0 | (cp >> 6)), UInt8(0x80 | (cp & 0x3F))])
            case 0x800..<0x10000:
                out.append(contentsOf: [UInt8(0xE0 | (cp >> 12)), UInt8(0x80 | ((cp >> 6) & 0x3F)), UInt8(0x80 | (cp & 0x3F))])
            default:
                out.append(contentsOf: [UInt8(0xF0 | (cp >> 18)), UInt8(0x80 | ((cp >> 12) & 0x3F)),
                                        UInt8(0x80 | ((cp >> 6) & 0x3F)), UInt8(0x80 | (cp & 0x3F))])
            }
        }

        mutating func string() throws -> String {
            i += 1
            var out: [UInt8] = []
            while true {
                guard i < b.count else { throw ReadError.syntax(i) }
                let c = b[i]
                if c == 0x22 { i += 1; break }
                if c < 0x20 { throw ReadError.syntax(i) }
                if c != 0x5C { out.append(c); i += 1; continue }
                i += 1
                guard i < b.count else { throw ReadError.syntax(i) }
                let e = b[i]
                i += 1
                switch e {
                case 0x22, 0x5C, 0x2F: out.append(e)
                case 0x62: out.append(0x08)
                case 0x66: out.append(0x0C)
                case 0x6E: out.append(0x0A)
                case 0x72: out.append(0x0D)
                case 0x74: out.append(0x09)
                case 0x75:
                    var cp = try hex4()
                    if cp >= 0xD800 && cp < 0xDC00 {
                        guard i + 6 <= b.count, b[i] == 0x5C, b[i + 1] == 0x75 else { throw ReadError.syntax(i) }
                        i += 2
                        let lo = try hex4()
                        guard lo >= 0xDC00 && lo < 0xE000 else { throw ReadError.syntax(i) }
                        cp = 0x10000 + ((cp - 0xD800) << 10) + (lo - 0xDC00)
                    } else if cp >= 0xDC00 && cp < 0xE000 { throw ReadError.syntax(i) }
                    Parser.appendUTF8(cp, &out)
                default: throw ReadError.syntax(i)
                }
            }
            let s = String(decoding: out, as: UTF8.self)
            if Array(s.utf8) != out { throw ReadError.invalidUTF8 }
            return s
        }

        mutating func number() throws -> Double {
            let start = i
            if i < b.count, b[i] == 0x2D { i += 1 }
            guard i < b.count, b[i] >= 0x30 && b[i] <= 0x39 else { throw ReadError.syntax(i) }
            if b[i] == 0x30 { i += 1 } else { while i < b.count, b[i] >= 0x30 && b[i] <= 0x39 { i += 1 } }
            if i < b.count, b[i] == 0x2E {
                i += 1
                guard i < b.count, b[i] >= 0x30 && b[i] <= 0x39 else { throw ReadError.syntax(i) }
                while i < b.count, b[i] >= 0x30 && b[i] <= 0x39 { i += 1 }
            }
            if i < b.count, b[i] == 0x65 || b[i] == 0x45 {
                i += 1
                if i < b.count, b[i] == 0x2B || b[i] == 0x2D { i += 1 }
                guard i < b.count, b[i] >= 0x30 && b[i] <= 0x39 else { throw ReadError.syntax(i) }
                while i < b.count, b[i] >= 0x30 && b[i] <= 0x39 { i += 1 }
            }
            guard let d = Double(String(decoding: b[start..<i], as: UTF8.self)) else { throw ReadError.syntax(start) }
            return d
        }
    }
}
