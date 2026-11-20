import Foundation

// MARK: Biquad

/// One second-order section, normalised so `a0 == 1`: `y[n] = b0 x[n] + b1 x[n-1] + b2 x[n-2] - a1 y[n-1] - a2 y[n-2]`.
public struct Biquad: Equatable, Sendable {
    public var b0, b1, b2, a1, a2: Double
    public init(b0: Double, b1: Double, b2: Double, a1: Double, a2: Double) {
        self.b0 = b0; self.b1 = b1; self.b2 = b2; self.a1 = a1; self.a2 = a2
    }
}

/// A biquad plus its state (transposed direct form II, Double). One runner per signal; not thread-safe.
struct BiquadRunner {
    var c: Biquad
    private var z1 = 0.0, z2 = 0.0
    init(_ c: Biquad) { self.c = c }
    @inline(__always) mutating func process(_ x: Double) -> Double {
        let y = c.b0 * x + z1
        z1 = c.b1 * x - c.a1 * y + z2
        z2 = c.b2 * x - c.a2 * y
        return y
    }
}

// MARK: Report

/// What the meter measured for one sound (mono).
///
/// Example:
/// ```swift
/// let r = LoudnessMeter.measure(samples, sampleRate: 48_000)
/// if r.classLUFS < -20.1 || (r.truePeakDBTP ?? 0) > -1 { /* out of tolerance */ }
/// ```
public struct LoudnessReport: Equatable, Sendable {
    /// Length in seconds.
    public var duration: Double
    /// True when the sound is shorter than one 400 ms block: it has no integrated loudness and is judged by its
    /// momentary maximum (ADR-0003 D5).
    public var momentaryOnly: Bool
    /// Gated integrated loudness (LUFS), ITU-R BS.1770-5 (11/2023) Annex 1. `nil` when `momentaryOnly`, or when every block is gated out.
    public var integratedLUFS: Double?
    /// The loudest 400 ms window (LUFS); `-infinity` for silence. A sound shorter than 400 ms is measured padded with
    /// digital silence to 400 ms (so a 0.2 s burst reads 3.01 dB below the same tone held for 400 ms).
    public var momentaryMaxLUFS: Double
    /// True peak (dBTP), 4x oversampled; `-infinity` for silence; `nil` when the caller asked for loudness only.
    public var truePeakDBTP: Double?
    /// The one figure compared with a class target: the integrated loudness (`-infinity` if fully gated) for a sound
    /// of 400 ms or longer, the momentary maximum for a shorter one (ADR-0003 D5).
    public var classLUFS: Double { momentaryOnly ? momentaryMaxLUFS : (integratedLUFS ?? -.infinity) }
}

// MARK: Meter

/// The ADR-0003 D5 loudness meter: ITU-R BS.1770-5 (11/2023), https://www.itu.int/dms_pubrec/itu-r/rec/bs/R-REC-BS.1770-5-202311-I!!PDF-E.pdf, in our own Swift (K-31, no third-party code). **Mono only**: one
/// channel, weight 1.0 (a stereo meter would sum two channels; EBU Tech 3341's stereo values read 10 log10(2) = 3.01 dB
/// higher than a single channel carrying the same signal). Pure functions, no state, thread-safe.
///
/// - K-weighting (BS.1770-5 Annex 1, Tables 1 and 2): the two published 48 kHz biquads (shelf, then RLB high-pass), used as published. Any other sample
///   rate gets coefficients derived from the same analog prototype (shelf f0 1681.97 Hz, G +4.0 dB, Q 0.707; high-pass
///   f0 38.14 Hz, Q 0.5003) by the bilinear transform, so no resampling is done. The derivation reproduces the 48 kHz
///   table to 1e-9 (a test).
/// - Gating (BS.1770-5 Annex 1, section 5): blocks of 400 ms, 75 % overlap (100 ms hop), whole blocks only. Absolute gate -70 LUFS, relative gate -10 LU below
///   the absolute-gated mean, `L = -0.691 + 10 log10(mean square)`.
/// - True peak: 4x oversampling with the BS.1770-5 Annex 2 polyphase FIR (48 taps, 4 phases of 12), taken as at least
///   the sample peak. The filter is designed for 48 kHz; it is used unchanged at other rates.
///
/// Example:
/// ```swift
/// let tone = (0..<48_000).map { Float(0.1 * sin(2 * Double.pi * 1000 * Double($0) / 48_000)) }
/// let r = LoudnessMeter.measure(tone, sampleRate: 48_000)   // integratedLUFS ≈ -23.01, truePeakDBTP ≈ -20.0
/// ```
public enum LoudnessMeter {
    /// Block and hop length (s), the absolute gate (LUFS), the relative gate (LU) and the BS.1770 offset (LU).
    public static let blockSeconds = 0.4, hopSeconds = 0.1, absoluteGateLUFS = -70.0, relativeGateLU = -10.0, offsetLU = -0.691

    /// The two K-weighting stages for `sampleRate`: the high shelf, then the RLB high-pass.
    public static func kWeighting(sampleRate: Double) -> (shelf: Biquad, highpass: Biquad) {
        if sampleRate == 48_000 {
            return (Biquad(b0: 1.53512485958697, b1: -2.69169618940638, b2: 1.19839281085285, a1: -1.69065929318241, a2: 0.73248077421585),
                    Biquad(b0: 1, b1: -2, b2: 1, a1: -1.99004745483398, a2: 0.99007225036621))
        }
        return derivedKWeighting(sampleRate: sampleRate)
    }

    /// The analog-prototype derivation, for any rate (public so a test can compare it with the published 48 kHz table).
    public static func derivedKWeighting(sampleRate: Double) -> (shelf: Biquad, highpass: Biquad) {
        let g = 3.999843853973347, q1 = 0.7071752369554196, f1 = 1681.974450955533
        let vh = pow(10, g / 20), vb = pow(vh, 0.4996667741545416)
        var k = tan(Double.pi * f1 / sampleRate)
        var a0 = 1 + k / q1 + k * k
        let shelf = Biquad(b0: (vh + vb * k / q1 + k * k) / a0, b1: 2 * (k * k - vh) / a0, b2: (vh - vb * k / q1 + k * k) / a0,
                           a1: 2 * (k * k - 1) / a0, a2: (1 - k / q1 + k * k) / a0)
        let q2 = 0.5003270373238773, f2 = 38.13547087602444
        k = tan(Double.pi * f2 / sampleRate)
        a0 = 1 + k / q2 + k * k
        return (shelf, Biquad(b0: 1, b1: -2, b2: 1, a1: 2 * (k * k - 1) / a0, a2: (1 - k / q2 + k * k) / a0))
    }

    /// ITU-R BS.1770-5 (11/2023) Annex 2, Table 1 (https://www.itu.int/dms_pubrec/itu-r/rec/bs/R-REC-BS.1770-5-202311-I!!PDF-E.pdf): the 4x interpolation FIR as 4 phases of 12 taps. Phase `p` yields the output at
    /// `n + (p + 0.5) / 4` samples; tap `k` multiplies `x[n + 6 - k]`.
    static let truePeakPhases: [[Double]] = {
        let p0 = [0.0017089843750, 0.0109863281250, -0.0196533203125, 0.0332031250000, -0.0594482421875, 0.1373291015625,
                  0.9721679687500, -0.1022949218750, 0.0476074218750, -0.0266113281250, 0.0148925781250, -0.0083007812500]
        let p1 = [-0.0291748046875, 0.0292968750000, -0.0517578125000, 0.0891113281250, -0.1665039062500, 0.4650878906250,
                  0.7797851562500, -0.2003173828125, 0.1015625000000, -0.0582275390625, 0.0330810546875, -0.0189208984375]
        return [p0, p1, p1.reversed(), p0.reversed()]
    }()

    /// True peak in dBTP of `samples` (mono): the larger of the sample peak and the 4x-oversampled peak; `-infinity` for
    /// silence.
    public static func truePeak(_ samples: [Float]) -> Double {
        let n = samples.count
        // Zero-padded by 6 on each side so every tap is in range; the 48 taps flattened phase-major.
        var x = [Double](repeating: 0, count: n + 12)
        var peak = 0.0
        for i in 0..<n { x[i + 6] = Double(samples[i]); peak = max(peak, abs(x[i + 6])) }
        let taps = truePeakPhases.flatMap { $0 }
        x.withUnsafeBufferPointer { xp in
            taps.withUnsafeBufferPointer { h in
                let xb = xp.baseAddress!, hb = h.baseAddress!
                for i in 0..<n {
                    let c = xb + i + 12   // x[n + 6 - k] is c[-k]
                    for p in 0..<4 {
                        let hp = hb + 12 * p
                        var acc = 0.0
                        for k in 0..<12 { acc += hp[k] * c[-k] }
                        if abs(acc) > peak { peak = abs(acc) }
                    }
                }
            }
        }
        return peak > 0 ? 20 * log10(peak) : -.infinity
    }

    /// Measures `samples` (mono, Float, -1…1) at `sampleRate`. `truePeak: false` skips the (slower) true-peak pass and
    /// leaves `truePeakDBTP` nil.
    public static func measure(_ samples: [Float], sampleRate: Double, truePeak withPeak: Bool = true) -> LoudnessReport {
        let blockLen = Int((blockSeconds * sampleRate).rounded()), hop = Int((hopSeconds * sampleRate).rounded())
        let short = samples.count < blockLen
        let k = kWeighting(sampleRate: sampleRate)
        var shelf = BiquadRunner(k.shelf), rlb = BiquadRunner(k.highpass)
        // Prefix sums of the squared K-weighted signal; a sound under one block is padded with silence to one block.
        let total = max(samples.count, blockLen)
        var cum = [Double](repeating: 0, count: total + 1)
        for i in 0..<total {
            let x = i < samples.count ? Double(samples[i]) : 0
            let y = rlb.process(shelf.process(x))
            cum[i + 1] = cum[i] + y * y
        }
        var z: [Double] = []
        var s = 0
        while s + blockLen <= total { z.append((cum[s + blockLen] - cum[s]) / Double(blockLen)); s += hop }
        func lufs(_ ms: Double) -> Double { ms > 0 ? offsetLU + 10 * log10(ms) : -.infinity }
        let momentary = z.map(lufs).max() ?? -.infinity
        var integrated: Double?
        if !short {
            let absGated = z.filter { lufs($0) > absoluteGateLUFS }
            if !absGated.isEmpty {
                let threshold = lufs(absGated.reduce(0, +) / Double(absGated.count)) + relativeGateLU
                let kept = absGated.filter { lufs($0) > threshold }
                if !kept.isEmpty { integrated = lufs(kept.reduce(0, +) / Double(kept.count)) }
            }
        }
        return LoudnessReport(duration: Double(samples.count) / sampleRate, momentaryOnly: short, integratedLUFS: integrated,
                              momentaryMaxLUFS: momentary, truePeakDBTP: withPeak ? truePeak(samples) : nil)
    }
}
