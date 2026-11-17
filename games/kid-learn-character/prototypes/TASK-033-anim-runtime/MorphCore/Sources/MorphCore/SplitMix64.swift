// PROTOTYPE - NOT FOR PRODUCTION (TASK-033 spike)
/// The spike's only source of randomness: SplitMix64 (Steele, Lea, Flood 2014), chosen because it is a few lines
/// with unsigned 64-bit wrap-around arithmetic, so Kotlin (ULong) reproduces it bit for bit.
///
///     state = state + 0x9E3779B97F4A7C15
///     z = state
///     z = (z xor (z >>> 30)) * 0xBF58476D1CE4E5B9
///     z = (z xor (z >>> 27)) * 0x94D049BB133111EB
///     return z xor (z >>> 31)
///
/// `nextUnit()` = (next() >>> 11) × 2⁻⁵³, in [0, 1).
public struct SplitMix64: Sendable {
    public private(set) var state: UInt64
    public init(seed: UInt64) { state = seed }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    public mutating func nextUnit() -> Double { Double(next() >> 11) * 0x1.0p-53 }
}
