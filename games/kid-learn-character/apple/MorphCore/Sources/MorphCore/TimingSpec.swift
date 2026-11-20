/// One already-decoded value from the timing data, as the edge decoder (the app or Tools) hands it in. MorphCore never
/// decodes JSON (ADR-0002 D2): the edge maps a JSON number to `.number` and anything else (string, bool, null,
/// array, object) to `.notNumber`. A knob that is absent from the data is simply absent from the dictionary.
public enum TimingValue: Equatable, Sendable {
    /// A number. NaN and infinities count as "not a number" for validation.
    case number(Double)
    /// Present in the data but not a number.
    case notNumber
}

/// The tuning knobs of the morph timing data (MorphCore GDD, Tuning Knobs), in a fixed order so rejections are
/// deterministic. The raw value is the key in `content/data/morph-timing.json`.
public enum TimingKnob: String, CaseIterable, Sendable {
    case letterIn = "letter_in_s", glow = "glow_s", dissolve = "dissolve_s", flow = "flow_s", spread = "spread_s"
    case drift, swirl, particles, morphSpeed = "morph_speed"

    /// The allowed range, both ends inclusive (Tuning Knobs table).
    public var range: ClosedRange<Double> {
        switch self {
        case .letterIn: return 0.1...1.5
        case .glow: return 0...1.5
        case .dissolve: return 0.1...1.5
        case .flow: return 0.2...2.5
        case .spread: return 0...1.0
        case .drift: return 0...0.15
        case .swirl: return 0...1
        case .particles: return 100...900
        case .morphSpeed: return 0.5...2
        }
    }
}

/// Why a timing set was rejected.
public enum TimingRejectionReason: Equatable, Sendable {
    /// The knob is absent from the set.
    case missing
    /// The knob is present but is not a (finite) number.
    case notANumber
    /// The number is below the knob's range.
    case belowMinimum(Double)
    /// The number is above the knob's range.
    case aboveMaximum(Double)
    /// `particles` is not a whole number.
    case notWholeNumber(Double)
}

/// A rejected timing set: which set, which knob and why. A rejected set builds no morph (MorphCore Rule 9).
public struct TimingRejection: Error, Equatable, Sendable {
    /// `"normal"` or `"reduced"`.
    public let set: String
    /// The offending knob.
    public let knob: TimingKnob
    /// Why it was rejected.
    public let reason: TimingRejectionReason

    /// A rejection of `knob` in `set` for `reason`.
    public init(set: String, knob: TimingKnob, reason: TimingRejectionReason) {
        self.set = set; self.knob = knob; self.reason = reason
    }

    /// A one-line message for debug logs, e.g. `reduced.flow_s: 0.1 is below the minimum 0.2`.
    public var message: String {
        let name = "\(set).\(knob.rawValue)"
        switch reason {
        case .missing: return "\(name): missing"
        case .notANumber: return "\(name): not a number"
        case .belowMinimum(let v): return "\(name): \(v) is below the minimum \(knob.range.lowerBound)"
        case .aboveMaximum(let v): return "\(name): \(v) is above the maximum \(knob.range.upperBound)"
        case .notWholeNumber(let v): return "\(name): \(v) is not a whole number"
        }
    }
}

/// One validated timing set: the designer-facing knobs, turned into the contract's spec by Formula F1.
/// Only `TimingData.load` makes one, so a `TimingSpec` is always in range.
public struct TimingSpec: Equatable, Sendable {
    /// Particle count N.
    public let particles: Int
    /// Seconds the glyph rises from its key.
    public let letterIn: Double
    /// Seconds the glyph glows.
    public let glow: Double
    /// Seconds the glyph dissolves.
    public let dissolve: Double
    /// One particle's flight time, before `morphSpeed`.
    public let flow: Double
    /// Largest start delay, before `morphSpeed`.
    public let spread: Double
    /// Largest dissolve drift per axis, unit-box units.
    public let drift: Double
    /// Flight curve, unitless.
    public let swirl: Double
    /// Time multiplier; 2 is twice as fast.
    public let morphSpeed: Double

    /// F1: the contract spec for a new morph with `seed` (the caller's seed; its policy is not MorphCore's).
    /// `glow = (letter_in + glow)/speed`, `dissolve = dissolve/speed`, `spread = spread/speed`,
    /// `travel = (flow + spread)/speed`, so one flight is `travel - spread = flow/speed` (F2).
    ///
    ///     let spec = timing.morphSpec(seed: 42)   // spec.duration is F3's T
    public func morphSpec(seed: UInt64) -> MorphSpec {
        MorphSpec(count: particles, seed: seed, glow: (letterIn + glow) / morphSpeed, dissolve: dissolve / morphSpeed,
                  travel: (flow + spread) / morphSpeed, spread: spread / morphSpeed, drift: drift, swirl: swirl)
    }

    /// Validates one set. Knobs are checked in `TimingKnob.allCases` order; the first failure is returned.
    static func validate(_ values: [String: TimingValue], set: String) -> Result<TimingSpec, TimingRejection> {
        var v: [TimingKnob: Double] = [:]
        for knob in TimingKnob.allCases {
            func reject(_ r: TimingRejectionReason) -> Result<TimingSpec, TimingRejection> {
                .failure(TimingRejection(set: set, knob: knob, reason: r))
            }
            guard let raw = values[knob.rawValue] else { return reject(.missing) }
            guard case .number(let x) = raw, x.isFinite else { return reject(.notANumber) }
            if x < knob.range.lowerBound { return reject(.belowMinimum(x)) }
            if x > knob.range.upperBound { return reject(.aboveMaximum(x)) }
            if knob == .particles, x.truncatingRemainder(dividingBy: 1) != 0 { return reject(.notWholeNumber(x)) }
            v[knob] = x
        }
        return .success(TimingSpec(particles: Int(v[.particles]!), letterIn: v[.letterIn]!, glow: v[.glow]!,
                                   dissolve: v[.dissolve]!, flow: v[.flow]!, spread: v[.spread]!, drift: v[.drift]!,
                                   swirl: v[.swirl]!, morphSpeed: v[.morphSpeed]!))
    }
}

/// The validated timing data: the normal and the reduced set (ADR-0001 D6). There are no hard-coded fallback
/// timings: if either set is invalid there is no `TimingData`, so no spec and no morph can come from it.
public struct TimingData: Equatable, Sendable {
    /// The normal set.
    public let normal: TimingSpec
    /// The reduced set, used when Reduce Motion / "Remove animations" is on.
    public let reduced: TimingSpec

    /// Validates both sets, already decoded by the edge, as a whole. On failure returns the first rejection
    /// (normal before reduced) and nothing else; the stage then gets "no morph" (MorphCore Rule 9).
    ///
    ///     switch TimingData.load(normal: n, reduced: r) {
    ///     case .success(let data): spec = data.morphSpec(reducedMotion: flag, seed: seed)
    ///     case .failure(let why): log(why.message)   // no morph
    ///     }
    public static func load(normal: [String: TimingValue], reduced: [String: TimingValue]) -> Result<TimingData, TimingRejection> {
        switch TimingSpec.validate(normal, set: "normal") {
        case .failure(let e): return .failure(e)
        case .success(let n):
            switch TimingSpec.validate(reduced, set: "reduced") {
            case .failure(let e): return .failure(e)
            case .success(let r): return .success(TimingData(normal: n, reduced: r))
            }
        }
    }

    /// The set for a NEW morph. `reducedMotion` is injected: MorphCore never reads platform state.
    public func timing(reducedMotion: Bool) -> TimingSpec { reducedMotion ? reduced : normal }

    /// The contract spec for a new morph. A `MorphSpec` is a value copied into the `Morph` at build, so a morph
    /// already built keeps its spec when the flag later changes.
    ///
    ///     let spec = data.morphSpec(reducedMotion: true, seed: 7)
    public func morphSpec(reducedMotion: Bool, seed: UInt64) -> MorphSpec {
        timing(reducedMotion: reducedMotion).morphSpec(seed: seed)
    }
}
