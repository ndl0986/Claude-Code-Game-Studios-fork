/// The morph's timing for one reveal, in seconds; lengths in unit-box units (morph-contract-v1 §1, MorphCore F1).
/// There is no `hold`: the hold belongs to the Press Queue (MorphCore Rule 7).
public struct MorphSpec: Equatable, Sendable {
    /// Particle count N.
    public var count: Int
    /// The seed for this reveal's draws (contract §4).
    public var seed: UInt64
    /// The glyph glows; particles still on the glyph.
    public var glow: Double
    /// Particles drift off the glyph.
    public var dissolve: Double
    /// Particles fly to the silhouette (staggered by up to `spread`).
    public var travel: Double
    /// The largest per-particle start delay inside `travel`.
    public var spread: Double
    /// The largest drift per axis while dissolving.
    public var drift: Double
    /// The curve's bow, as a fraction of the flight's length.
    public var swirl: Double

    /// A spec from its fields.
    public init(count: Int, seed: UInt64, glow: Double, dissolve: Double, travel: Double, spread: Double,
                drift: Double, swirl: Double) {
        self.count = count; self.seed = seed; self.glow = glow; self.dissolve = dissolve; self.travel = travel
        self.spread = spread; self.drift = drift; self.swirl = swirl
    }

    /// `glow + dissolve + travel`: the time T at which every particle has landed.
    public var duration: Double { glow + dissolve + travel }
}

/// One glyph → silhouette morph (morph-contract-v1). Everything is decided in `init` from the two point sets and the
/// seed, so `position(_:at:)` is a pure function of time.
///
/// Recipe (a port must follow it exactly to match the fixture):
/// 1. `from` = `SVGPath.sample(glyph, N)`, `to` = `SVGPath.sample(silhouette, N)` (both unit-box normalised).
/// 2. RNG = SplitMix64(seed). Pairing: Fisher–Yates over `perm = [0..N-1]`, for i = N−1 down to 1:
///    j = floor(nextUnit() × (i + 1)), swap perm[i], perm[j]. Particle i flies from from[i] to to[perm[i]].
/// 3. Then for i = 0..N−1, four draws in order: driftX = (2r−1)·drift, driftY = (2r−1)·drift, delay = r·spread,
///    bow = (2r−1)·swirl.
/// 4. Position at time s, with smooth(u) = u²(3 − 2u) and u clamped to [0, 1]:
///    - s ≤ glow: from[i].
///    - dissolve: a = from[i] + drift · smooth((s − glow) / dissolve).
///    - travel: u = smooth((s − glow − dissolve − delay) / (travel − spread)); start a = from[i] + drift,
///      control c = (a + to)/2 + bow · (−(to.y − a.y), to.x − a.x); quadratic Bézier a → c → to at u.
public struct Morph: Sendable {
    /// The spec this morph was built from.
    public let spec: MorphSpec
    /// Start points (on the glyph) and end points (on the silhouette), unit box.
    public let from: [Pt], to: [Pt]
    /// Particle i flies to `to[pairing[i]]`.
    public let pairing: [Int]
    /// Per-particle drift, start delay and bow (contract §4 step 3).
    public let drift: [Pt], delay: [Double], bow: [Double]

    /// A morph between two path strings in the v1 subset.
    public init(spec: MorphSpec, glyphPath: String, silhouettePath: String) throws {
        self.init(spec: spec, from: try SVGPath.sample(glyphPath, count: spec.count),
                  to: try SVGPath.sample(silhouettePath, count: spec.count))
    }

    /// A morph between two sampled point sets of `spec.count` points each.
    public init(spec: MorphSpec, from: [Pt], to: [Pt]) {
        precondition(from.count == spec.count && to.count == spec.count)
        self.spec = spec; self.from = from; self.to = to
        var rng = SplitMix64(seed: spec.seed), perm = Array(0..<spec.count)
        if spec.count > 1 {
            for i in stride(from: spec.count - 1, through: 1, by: -1) {
                let j = Int(rng.nextUnit() * Double(i + 1)); perm.swapAt(i, j)
            }
        }
        var d: [Pt] = [], dl: [Double] = [], b: [Double] = []
        for _ in 0..<spec.count {
            let dx = (2 * rng.nextUnit() - 1) * spec.drift, dy = (2 * rng.nextUnit() - 1) * spec.drift
            d.append(Pt(dx, dy)); dl.append(rng.nextUnit() * spec.spread); b.append((2 * rng.nextUnit() - 1) * spec.swirl)
        }
        pairing = perm; drift = d; delay = dl; bow = b
    }

    @inline(__always) static func smooth(_ u: Double) -> Double { let v = min(1, max(0, u)); return v * v * (3 - 2 * v) }

    /// Particle i at time s (seconds from the press).
    public func position(_ i: Int, at s: Double) -> Pt {
        let p = from[i], q = to[pairing[i]], dr = drift[i]
        if s <= spec.glow { return p }
        if s <= spec.glow + spec.dissolve {
            let k = Self.smooth((s - spec.glow) / spec.dissolve)
            return Pt(p.x + dr.x * k, p.y + dr.y * k)
        }
        let a = Pt(p.x + dr.x, p.y + dr.y)
        let u = Self.smooth((s - spec.glow - spec.dissolve - delay[i]) / (spec.travel - spec.spread))
        let c = Pt((a.x + q.x) / 2 - bow[i] * (q.y - a.y), (a.y + q.y) / 2 + bow[i] * (q.x - a.x))
        let w = 1 - u
        return Pt(w * w * a.x + 2 * w * u * c.x + u * u * q.x, w * w * a.y + 2 * w * u * c.y + u * u * q.y)
    }

    /// All particles at time s.
    public func positions(at s: Double) -> [Pt] { (0..<spec.count).map { position($0, at: s) } }
}
