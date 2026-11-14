/// mulberry32, bit-for-bit as the prototype's `rng()`: every gameplay random call reads this.
public struct Mulberry32: Sendable {
    public private(set) var state: UInt32

    public init(seed: Int) { state = UInt32(truncatingIfNeeded: seed) }

    /// The next value in [0, 1).
    public mutating func next() -> Double {
        state = state &+ 0x6D2B_79F5
        var t = (state ^ (state >> 15)) &* (state | 1)
        t ^= t &+ ((t ^ (t >> 7)) &* (t | 61))
        return Double(t ^ (t >> 14)) / 4_294_967_296
    }
}
