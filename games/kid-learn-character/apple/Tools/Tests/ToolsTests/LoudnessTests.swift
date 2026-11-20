import Foundation
import ToolsCore
import XCTest

/// The ADR-0003 D5 meter (`LoudnessMeter`, content-pipeline story 007) against EBU Tech 3341 reference signals, within
/// ±0.1 LU. The meter is mono and Tech 3341's values are stereo, so each case is ADAPTED to what one channel can express and
/// its expected value is derived here, not copied: a single channel carrying a signal reads 10·log10(2) = 3.01 dB lower than
/// the same signal on both channels, and a 1 kHz sine at X dBFS peak reads X LUFS on two channels (Tech 3341 case 1 is
/// -23.0 dBFS = -23.0 LUFS), so the mono reading is X - 3.01 LUFS. The signals are re-synthesised from their descriptions,
/// not the EBU's own WAV files (not in the repo); the case numbers are from the author's reading of Tech 3341 and should be
/// checked against the published table.
final class LoudnessTests: XCTestCase {
    let rate = 48_000.0
    let mono = -10 * log10(2.0)   // -3.0103 dB: one channel against two

    /// A sine of `amplitudeDB` dBFS peak.
    func sine(_ amplitudeDB: Double, seconds: Double, hz: Double = 1000, rate: Double = 48_000, phase: Double = 0) -> [Float] {
        let a = pow(10, amplitudeDB / 20)
        return (0..<Int((seconds * rate).rounded())).map { Float(a * sin(2 * Double.pi * hz * Double($0) / rate + phase)) }
    }

    /// Tech 3341 case 1: 20 s of 1 kHz at -23.0 dBFS (stereo -23.0 LUFS). Mono: -23.0 - 3.01 = -26.01 LUFS, integrated and
    /// momentary maximum alike.
    func test_ebu3341_case1_mono_sine_minus_23_dbfs_reads_minus_26_01_lufs() {
        let r = LoudnessMeter.measure(sine(-23, seconds: 20), sampleRate: rate)
        XCTAssertEqual(try XCTUnwrap(r.integratedLUFS), -23 + mono, accuracy: 0.1)
        XCTAssertEqual(r.momentaryMaxLUFS, -23 + mono, accuracy: 0.1)
        XCTAssertFalse(r.momentaryOnly)
    }

    /// Tech 3341 case 2: the same at -33.0 dBFS (stereo -33.0 LUFS). Mono: -36.01 LUFS.
    func test_ebu3341_case2_mono_sine_minus_33_dbfs_reads_minus_36_01_lufs() {
        let r = LoudnessMeter.measure(sine(-33, seconds: 20), sampleRate: rate)
        XCTAssertEqual(try XCTUnwrap(r.integratedLUFS), -33 + mono, accuracy: 0.1)
    }

    /// Tech 3341 case 3 (relative gate): 20 s at -36 dBFS, 40 s at -23 dBFS, 20 s at -36 dBFS. The quiet parts are 13 LU below
    /// the loud one, more than the 10 LU relative gate under the mean (which is about -12 LU), so only the loud part counts:
    /// mono -23 - 3.01 = -26.01 LUFS. Without the relative gate the reading would be about 2 LU lower (asserted).
    func test_ebu3341_case3_relative_gate_ignores_the_quiet_parts() throws {
        let x = sine(-36, seconds: 20) + sine(-23, seconds: 40) + sine(-36, seconds: 20)
        let r = LoudnessMeter.measure(x, sampleRate: rate)
        let integrated = try XCTUnwrap(r.integratedLUFS)
        XCTAssertEqual(integrated, -23 + mono, accuracy: 0.1)
        // The ungated mean power of the same signal, in LUFS: (40 s at 0 dB, 40 s at -13 dB) → -3.0 dB under the loud part.
        let ungated = -23 + mono + 10 * log10((40 + 40 * pow(10, -1.3)) / 80)
        XCTAssertGreaterThan(integrated - ungated, 2.0, "the relative gate must matter in this signal")
    }

    /// Tech 3341 case 4 idea (absolute gate -70 LUFS), adapted: 5 s of tone at mono -75 LUFS (amplitude -71.99 dBFS) is wholly
    /// below the gate, so there is no integrated loudness (a uniform signal is not touched by the relative gate, so only the
    /// absolute gate can do this); 5 s at mono -69.5 LUFS is above it and reads -69.5.
    func test_ebu3341_case4_absolute_gate_at_minus_70_lufs() throws {
        let below = LoudnessMeter.measure(sine(-75 - mono, seconds: 5), sampleRate: rate)
        XCTAssertNil(below.integratedLUFS)
        XCTAssertEqual(below.momentaryMaxLUFS, -75, accuracy: 0.1, "the momentary maximum has no gate")
        let above = LoudnessMeter.measure(sine(-69.5 - mono, seconds: 5), sampleRate: rate)
        XCTAssertEqual(try XCTUnwrap(above.integratedLUFS), -69.5, accuracy: 0.1)
    }

    /// Tech 3341 case 15 (true peak), adapted to one channel: a sine at fs/4 (12 kHz) with phase 45° and amplitude -6.0 dBFS has
    /// every sample at ±0.707 of the amplitude (sample peak -9.03 dBFS) but a true peak of -6.0 dBTP. The Tech 3341 tolerance for
    /// the true-peak cases is +0.2 / -0.4 dB.
    func test_ebu3341_case15_true_peak_sees_the_inter_sample_peak() throws {
        let x = sine(-6, seconds: 5, hz: 12_000, phase: Double.pi / 4)
        let samplePeak = 20 * log10(Double(x.map { abs($0) }.max()!))
        XCTAssertEqual(samplePeak, -6 + 20 * log10(0.5.squareRoot()), accuracy: 0.01)
        let tp = LoudnessMeter.measure(x, sampleRate: rate).truePeakDBTP
        XCTAssertGreaterThanOrEqual(tp, -6 - 0.4)
        XCTAssertLessThanOrEqual(tp, -6 + 0.2)
    }

    /// A tone of 0.2 s is shorter than one 400 ms block: it is measured padded with silence to 400 ms, so its mean square is
    /// 0.2/0.4 of the same tone held: at -20 dBFS mono that is -20 - 3.01 (mono) - 3.01 (half the block) = -26.02 LUFS. No
    /// integrated loudness.
    func test_momentary_max_of_a_sound_under_400_ms_is_measured_padded_to_400_ms() {
        let r = LoudnessMeter.measure(sine(-20, seconds: 0.2), sampleRate: rate)
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

    /// The coefficients derived from the analog prototype reproduce the published 48 kHz table, and give the same reading at
    /// 44.1 kHz (where the derived ones are used).
    func test_k_weighting_derivation_matches_the_published_48k_table_and_other_rates_agree() throws {
        let published = LoudnessMeter.kWeighting(sampleRate: 48_000), derived = LoudnessMeter.derivedKWeighting(sampleRate: 48_000)
        for (a, b) in [(published.shelf, derived.shelf), (published.highpass, derived.highpass)] {
            for (x, y) in [(a.b0, b.b0), (a.b1, b.b1), (a.b2, b.b2), (a.a1, b.a1), (a.a2, b.a2)] { XCTAssertEqual(x, y, accuracy: 1e-7) }
        }
        let r = LoudnessMeter.measure(sine(-23, seconds: 20, rate: 44_100), sampleRate: 44_100)
        XCTAssertEqual(try XCTUnwrap(r.integratedLUFS), -23 + mono, accuracy: 0.1)
    }
}
