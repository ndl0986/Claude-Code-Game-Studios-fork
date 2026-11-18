// The ADR-0002 D2 helpers: one place for rounding, case folding, string inspection and the draw rule, so the Kotlin
// port implements exactly the same behaviour.

/// Rounds half away from zero (Settings Store F1; ADR-0002 D2). The only rounding call allowed in the cores.
/// Examples: 2.5 → 3, −2.5 → −3, 7.4 → 7, 0.4 → 0.
public func roundHalfAwayFromZero(_ x: Double) -> Double {
    x.rounded(.toNearestOrAwayFromZero)
}

/// Upper-cases ASCII `a`–`z` only; every other scalar is left as it is (ADR-0002 D2: no locale or Unicode case
/// mapping). `"é"` stays `"é"`.
public func asciiUppercased(_ s: String) -> String {
    var out = String.UnicodeScalarView()
    for u in s.unicodeScalars {
        if u.value >= 97 && u.value <= 122, let up = Unicode.Scalar(u.value - 32) { out.append(up) } else { out.append(u) }
    }
    return String(out)
}

/// The number of Unicode scalars in `s` (ADR-0002 D2: never `String.count`, which counts grapheme clusters).
public func scalarCount(_ s: String) -> Int { s.unicodeScalars.count }

/// True when `s` is non-empty and every scalar is an ASCII letter `A`–`Z` (upper-case only).
public func isASCIIUpperLetters(_ s: String) -> Bool {
    guard !s.unicodeScalars.isEmpty else { return false }
    return s.unicodeScalars.allSatisfy { $0.value >= 65 && $0.value <= 90 }
}

/// The scalars of `s` that are ASCII letters, as one-scalar strings, in order (ADR-0002 D2 string inspection).
public func asciiLetters(_ s: String) -> [String] {
    s.unicodeScalars.filter { ($0.value >= 65 && $0.value <= 90) || ($0.value >= 97 && $0.value <= 122) }
        .map { String($0) }
}

/// A draw in [0, 1) from a 64-bit value: `(x >> 11) × 2⁻⁵³` (Key Table §4; ADR-0002 D4).
public func unitDraw(_ x: UInt64) -> Double { Double(x >> 11) * 0x1.0p-53 }
