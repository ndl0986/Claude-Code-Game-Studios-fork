import Foundation
import ToolsCore
import XCTest

/// The ADR-0003 D5 meter (`LoudnessMeter`, content-pipeline story 007) against EBU Tech 3341 (2023) Table 1; ITU-R BS.1770-5
/// (11/2023) Annex 1 and Annex 2. Tech 3341 v4.0 (2023-11): https://tech.ebu.ch/files/live/sites/tech/files/shared/tech/tech3341.pdf;
/// BS.1770-5: https://www.itu.int/dms_pubrec/itu-r/rec/bs/R-REC-BS.1770-5-202311-I!!PDF-E.pdf. Cases are named by their
/// Table 1 numbers. Loudness within ±0.1 LU; true peak within +0.2 / -0.4 dB (the Table 1 tolerance for cases 15-19).
///
/// Loudness (cases 1-5): Tech 3341's signals are stereo (the same 1 kHz sine on both channels) and the meter is mono, so each
/// signal is synthesised on ONE channel and its expected value derived: a single channel reads 10·log10(2) = 3.01 dB lower
/// than the same signal on two, so a stereo expectation of -23.0 LUFS is -26.01 LUFS mono. Amplitudes are dBFS peak per
/// channel, as in Table 1.
/// True peak (cases 15-19) is measured per channel, so its expected values (-6.0 and +3.0 dBTP) apply to the mono signal
/// unchanged: no -3.01 adjustment.
///
/// Not covered: cases 20-23 (true peak of the EBU's own downloadable test files, not in the repo), and the multichannel,
/// short-term and loudness-range cases a mono integrated/momentary meter cannot express.
final class LoudnessTests: XCTestCase {
    let rate = 48_000.0
    let mono = -10 * log10(2.0)   // -3.0103 dB: one channel against two

    /// A 1 kHz sine (continuous phase) through consecutive segments of (dBFS peak, seconds).
    func tone(_ segments: [(Double, Double)], hz: Double = 1000, rate: Double = 48_000) -> [Float] {
        var out: [Float] = [], n = 0
        for (db, seconds) in segments {
            let a = pow(10, db / 20)
            for _ in 0..<Int((seconds * rate).rounded()) { out.append(Float(a * sin(2 * Double.pi * hz * Double(n) / rate))); n += 1 }
        }
        return out
    }

    func integrated(_ x: [Float], rate: Double = 48_000) throws -> Double {
        try XCTUnwrap(LoudnessMeter.measure(x, sampleRate: rate, truePeak: false).integratedLUFS)
    }

    /// Case 1: 20 s at -23.0 dBFS → stereo -23.0 LUFS, mono -26.01 (integrated and momentary maximum).
    func test_ebu3341_case1_mono_sine_minus_23_dbfs_reads_minus_26_01_lufs() throws {
        let r = LoudnessMeter.measure(tone([(-23, 20)]), sampleRate: rate, truePeak: false)
        XCTAssertEqual(try XCTUnwrap(r.integratedLUFS), -23 + mono, accuracy: 0.1)
        XCTAssertEqual(r.momentaryMaxLUFS, -23 + mono, accuracy: 0.1)
        XCTAssertFalse(r.momentaryOnly)
    }

    /// Case 2: 20 s at -33.0 dBFS → stereo -33.0, mono -36.01.
    func test_ebu3341_case2_mono_sine_minus_33_dbfs_reads_minus_36_01_lufs() throws {
        XCTAssertEqual(try integrated(tone([(-33, 20)])), -33 + mono, accuracy: 0.1)
    }

    /// Case 3 (relative gate): 10 s at -36, 60 s at -23, 10 s at -36 dBFS → stereo -23.0, mono -26.01. Ungated, the same
    /// signal would read 10·log10((60 + 20·10^-1.3) / 80) = -1.18 dB under the loud part (asserted: the gate matters).
    func test_ebu3341_case3_relative_gate_ignores_the_quiet_parts() throws {
        let i = try integrated(tone([(-36, 10), (-23, 60), (-36, 10)]))
        XCTAssertEqual(i, -23 + mono, accuracy: 0.1)
        let ungated = -23 + mono + 10 * log10((60 + 20 * pow(10, -1.3)) / 80)
        XCTAssertGreaterThan(i - ungated, 1.0)
    }

    /// Case 4 (absolute and relative gate): 10 s -72, 10 s -36, 60 s -23, 10 s -36, 10 s -72 dBFS → stereo -23.0, mono -26.01.
    func test_ebu3341_case4_absolute_and_relative_gates() throws {
        XCTAssertEqual(try integrated(tone([(-72, 10), (-36, 10), (-23, 60), (-36, 10), (-72, 10)])), -23 + mono, accuracy: 0.1)
    }

    /// Our adaptation, not a Table 1 case: the absolute gate (-70 LUFS) alone. 5 s of tone at mono -75 LUFS (amplitude
    /// -71.99 dBFS) is wholly below the gate, so there is no integrated loudness (a uniform signal is untouched by the relative
    /// gate, so only the absolute gate can do this); 5 s at mono -69.5 LUFS is above it and reads -69.5.
    func test_adapted_absolute_gate_at_minus_70_lufs() throws {
        let below = LoudnessMeter.measure(tone([(-75 - mono, 5)]), sampleRate: rate, truePeak: false)
        XCTAssertNil(below.integratedLUFS)
        XCTAssertEqual(below.momentaryMaxLUFS, -75, accuracy: 0.1, "the momentary maximum has no gate")
        XCTAssertEqual(try integrated(tone([(-69.5 - mono, 5)])), -69.5, accuracy: 0.1)
    }

    /// Case 5 (relative gate): 20 s -26, 20.1 s -20, 20 s -26 dBFS → stereo -23.0, mono -26.01.
    func test_ebu3341_case5_relative_gate_with_a_louder_middle() throws {
        XCTAssertEqual(try integrated(tone([(-26, 20), (-20, 20.1), (-26, 20)])), -23 + mono, accuracy: 0.1)
    }

    /// Cases 15-19: a sine with a 10 ms linear fade-in and fade-out, 1 s, at `fraction` of fs, `amplitude` FFS, `phaseDeg`.
    func truePeakSignal(fraction: Double, amplitude: Double, phaseDeg: Double) -> [Float] {
        let n = Int(rate), fade = Int(0.010 * rate)
        return (0..<n).map { i in
            let g = Double(min(i, n - 1 - i, fade)) / Double(fade)
            return Float(g * amplitude * sin(2 * Double.pi * fraction * Double(i) + phaseDeg * Double.pi / 180))
        }
    }

    func assertTruePeak(_ fraction: Double, _ amplitude: Double, _ phaseDeg: Double, expected: Double, _ label: String) {
        let tp = LoudnessMeter.truePeak(truePeakSignal(fraction: fraction, amplitude: amplitude, phaseDeg: phaseDeg))
        XCTAssertGreaterThanOrEqual(tp, expected - 0.4, label)
        XCTAssertLessThanOrEqual(tp, expected + 0.2, label)
    }

    func test_ebu3341_case15_true_peak_fs4_phase_0_reads_minus_6_dbtp() { assertTruePeak(1.0 / 4, 0.5, 0, expected: -6, "case 15") }
    func test_ebu3341_case16_true_peak_fs4_phase_45_reads_minus_6_dbtp() {
        // Every sample is at ±0.707 of the amplitude (sample peak -9.03 dBFS): only the oversampling sees -6.
        let x = truePeakSignal(fraction: 0.25, amplitude: 0.5, phaseDeg: 45)
        XCTAssertEqual(20 * log10(Double(x.map { abs($0) }.max()!)), -6.02 - 3.01, accuracy: 0.01)
        assertTruePeak(1.0 / 4, 0.5, 45, expected: -6, "case 16")
    }
    func test_ebu3341_case17_true_peak_fs6_phase_60_reads_minus_6_dbtp() { assertTruePeak(1.0 / 6, 0.5, 60, expected: -6, "case 17") }
    func test_ebu3341_case18_true_peak_fs8_phase_67_5_reads_minus_6_dbtp() { assertTruePeak(1.0 / 8, 0.5, 67.5, expected: -6, "case 18") }
    func test_ebu3341_case19_true_peak_fs4_1_41_ffs_phase_45_reads_plus_3_dbtp() { assertTruePeak(1.0 / 4, 1.41, 45, expected: 3, "case 19") }

    /// A tone of 0.2 s is shorter than one 400 ms block: it is measured padded with silence to 400 ms, so its mean square is
    /// 0.2/0.4 of the same tone held: at -20 dBFS mono that is -20 - 3.01 (mono) - 3.01 (half the block) = -26.02 LUFS. No
    /// integrated loudness.
    func test_momentary_max_of_a_sound_under_400_ms_is_measured_padded_to_400_ms() {
        let r = LoudnessMeter.measure(tone([(-20, 0.2)]), sampleRate: rate)
        XCTAssertTrue(r.momentaryOnly)
        XCTAssertNil(r.integratedLUFS)
        XCTAssertEqual(r.momentaryMaxLUFS, -20 + 2 * mono, accuracy: 0.1)
        XCTAssertEqual(r.classLUFS, r.momentaryMaxLUFS)
    }

    func test_silence_has_no_loudness_and_no_peak() {
        let r = LoudnessMeter.measure([Float](repeating: 0, count: 48_000), sampleRate: rate)
        XCTAssertNil(r.integratedLUFS)
        XCTAssertEqual(r.momentaryMaxLUFS, -.infinity)
        XCTAssertEqual(r.truePeakDBTP, -.infinity)
    }

    /// The coefficients derived from the analog prototype reproduce the published 48 kHz table (BS.1770-5 Annex 1), and
    /// give the same reading at 44.1 kHz, where the derived ones are used.
    func test_k_weighting_derivation_matches_the_published_48k_table_and_other_rates_agree() throws {
        let published = LoudnessMeter.kWeighting(sampleRate: 48_000), derived = LoudnessMeter.derivedKWeighting(sampleRate: 48_000)
        for (a, b) in [(published.shelf, derived.shelf), (published.highpass, derived.highpass)] {
            for (x, y) in [(a.b0, b.b0), (a.b1, b.b1), (a.b2, b.b2), (a.a1, b.a1), (a.a2, b.a2)] { XCTAssertEqual(x, y, accuracy: 1e-7) }
        }
        XCTAssertEqual(try integrated(tone([(-23, 5)], rate: 44_100), rate: 44_100), -23 + mono, accuracy: 0.1)
    }
}
