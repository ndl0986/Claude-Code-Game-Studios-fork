/// The press queue's bundled data (GDD R13; AC-21): `content/data/press-queue.json` holds `hold_s`, `queue_max` and
/// `formed_timeout_s`. JSON is decoded at the edge (Tools' validator, the app's loader); these checks take the decoded
/// numbers. The ranges are the GDD's Tuning Knobs safe ranges, written here once as the build's rule.
public enum PressQueueData {
    /// The three knobs this file holds, by their data names.
    public static let names = ["hold_s", "queue_max", "formed_timeout_s"]

    /// The Tuning Knobs safe ranges (inclusive). `queue_max` must also be a whole number.
    public static let ranges: [String: ClosedRange<Double>] = [
        "hold_s": 2.95...6.0,
        "queue_max": 0...5,
        "formed_timeout_s": 0.5...2.0,
    ]

    /// Every problem with the decoded values, one line each: a name missing (nil), out of range, or `queue_max` not a
    /// whole number. An empty list means the values may ship.
    public static func problems(_ values: [String: Double?]) -> [String] {
        var out: [String] = []
        for n in names {
            guard let v = values[n] ?? nil else { out.append("\(n): missing or not a number"); continue }
            if let r = ranges[n], !r.contains(v) { out.append("\(n): \(v) is outside \(r.lowerBound)…\(r.upperBound)") }
            if n == "queue_max", roundHalfAwayFromZero(v) != v { out.append("queue_max: \(v) is not a whole number") }
        }
        return out
    }

    /// One timing set's reveal lengths (MorphCore F5; normal and reduced).
    public struct TimingSet: Equatable, Sendable {
        public var name: String
        /// `formedS` (T): when `formed` is reported.
        public var formedS: Double
        /// The visible reveal length.
        public var revealLen: Double
        public init(name: String, formedS: Double, revealLen: Double) {
            self.name = name; self.formedS = formedS; self.revealLen = revealLen
        }
    }

    /// F1's build checks on the shipped data, for each timing set: 1. the cap never cuts a word
    /// (`hold_s + hold_ext_max_s ≥ formedS + word_offset_s + word_len_max_s`); 2. the base hold covers the visible
    /// reveal (`hold_s ≥ revealLen`). Returns one line per failed check; empty when both hold for every set.
    public static func f1BuildCheck(_ k: PressQueueKnobs, sets: [TimingSet]) -> [String] {
        var out: [String] = []
        for s in sets {
            let need = s.formedS + k.wordOffsetS + k.wordLenMaxS
            if k.holdS + k.holdExtMaxS < need {
                out.append("F1 check 1 (\(s.name)): hold_s + hold_ext_max_s = \(k.holdS + k.holdExtMaxS) < formedS + word_offset_s + word_len_max_s = \(need); the cap would cut a word")
            }
            if k.holdS < s.revealLen {
                out.append("F1 check 2 (\(s.name)): hold_s \(k.holdS) < revealLen \(s.revealLen)")
            }
        }
        return out
    }
}
