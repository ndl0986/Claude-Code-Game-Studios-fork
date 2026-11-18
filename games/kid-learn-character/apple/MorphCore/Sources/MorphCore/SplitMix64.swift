/// The morph's random source: SplitMix64 (Steele, Lea, Flood 2014), fixed by morph-contract-v1 §4.
///
///     state = state + 0x9E3779B97F4A7C15
///     z = state
///     z = (z xor (z >>> 30)) * 0xBF58476D1CE4E5B9
///     z = (z xor (z >>> 27)) * 0x94D049BB133111EB
///     return z xor (z >>> 31)
///
/// `nextUnit()` = (next() >>> 11) × 2⁻⁵³, in [0, 1). `UInt64` is allowed here as a contract type (ADR-0002 D2).
public struct SplitMix64: Sendable {
    /// The generator's current state.
    public private(set) var state: UInt64

    /// A generator seeded with `seed`.
    public init(seed: UInt64) { state = seed }

    /// The next 64-bit output.
    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// The next draw in [0, 1): `(next() >> 11) × 2⁻⁵³`.
    public mutating func nextUnit() -> Double { Double(next() >> 11) * 0x1.0p-53 }
}
