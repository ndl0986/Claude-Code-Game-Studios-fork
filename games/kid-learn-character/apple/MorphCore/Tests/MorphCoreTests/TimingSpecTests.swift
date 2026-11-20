import XCTest
@testable import MorphCore

/// morphcore/001: the timing loader (AC-6, AC-7, AC-8). Values come from the GDD's Tuning Knobs table.
final class TimingSpecTests: XCTestCase {
    static let normal: [String: TimingValue] = [
        "letter_in_s": .number(0.45), "glow_s": .number(0.35), "dissolve_s": .number(0.4), "flow_s": .number(0.9),
        "spread_s": .number(0.35), "drift": .number(0.06), "swirl": .number(0.35), "particles": .number(240),
        "morph_speed": .number(1),
    ]
    static let reduced: [String: TimingValue] = [
        "letter_in_s": .number(0.25), "glow_s": .number(0.15), "dissolve_s": .number(0.2), "flow_s": .number(0.5),
        "spread_s": .number(0.1), "drift": .number(0.02), "swirl": .number(0), "particles": .number(240),
        "morph_speed": .number(1),
    ]
    static let box = "M0 0 L1 0 L1 1 L0 1 Z"

    func load(normal: [String: TimingValue] = TimingSpecTests.normal,
              reduced: [String: TimingValue] = TimingSpecTests.reduced) -> Result<TimingData, TimingRejection> {
        TimingData.load(normal: normal, reduced: reduced)
    }

    func data() throws -> TimingData { try load().get() }

    // MARK: AC-6

    func test_normal_set_maps_to_the_f1_contract_spec() throws {
        let s = try data().morphSpec(reducedMotion: false, seed: 1)
        XCTAssertEqual(s.count, 240); XCTAssertEqual(s.seed, 1)
        XCTAssertEqual(s.glow, 0.8, accuracy: 1e-9); XCTAssertEqual(s.dissolve, 0.4, accuracy: 1e-9)
        XCTAssertEqual(s.travel, 1.25, accuracy: 1e-9); XCTAssertEqual(s.spread, 0.35, accuracy: 1e-9)
        XCTAssertEqual(s.travel - s.spread, 0.9, accuracy: 1e-9, "flight = travel - spread = flow_s (F2)")
        XCTAssertEqual(s.duration, 2.45, accuracy: 1e-9)
        XCTAssertEqual(s.drift, 0.06, accuracy: 1e-12); XCTAssertEqual(s.swirl, 0.35, accuracy: 1e-12)
    }

    func test_morph_speed_scales_every_time_but_not_drift_or_swirl() throws {
        var n = Self.normal; n["morph_speed"] = .number(2)
        let s = try load(normal: n).get().morphSpec(reducedMotion: false, seed: 0)
        XCTAssertEqual(s.duration, 2.45 / 2, accuracy: 1e-9)
        XCTAssertEqual(s.travel - s.spread, 0.45, accuracy: 1e-9)
        XCTAssertEqual(s.drift, 0.06, accuracy: 1e-12); XCTAssertEqual(s.swirl, 0.35, accuracy: 1e-12)
    }

    func test_reduced_set_maps_to_the_gdd_worked_example() throws {
        let s = try data().morphSpec(reducedMotion: true, seed: 0)
        XCTAssertEqual(s.glow, 0.4, accuracy: 1e-9); XCTAssertEqual(s.dissolve, 0.2, accuracy: 1e-9)
        XCTAssertEqual(s.travel, 0.6, accuracy: 1e-9); XCTAssertEqual(s.travel - s.spread, 0.5, accuracy: 1e-9)
        XCTAssertEqual(s.duration, 1.2, accuracy: 1e-9)
    }

    // MARK: AC-7

    func test_every_knob_has_the_range_from_tuning_knobs() {
        let table: [TimingKnob: ClosedRange<Double>] = [
            .letterIn: 0.1...1.5, .glow: 0...1.5, .dissolve: 0.1...1.5, .flow: 0.2...2.5, .spread: 0...1,
            .drift: 0...0.15, .swirl: 0...1, .particles: 100...900, .morphSpeed: 0.5...2,
        ]
        XCTAssertEqual(Set(TimingKnob.allCases), Set(table.keys))
        for k in TimingKnob.allCases { XCTAssertEqual(k.range, table[k], k.rawValue) }
    }

    func test_range_ends_are_accepted_for_every_knob() {
        for k in TimingKnob.allCases {
            for edge in [k.range.lowerBound, k.range.upperBound] {
                var n = Self.normal; n[k.rawValue] = .number(edge)
                XCTAssertNoThrow(try load(normal: n).get(), "\(k.rawValue)=\(edge)")
            }
        }
    }

    func test_a_value_below_its_range_rejects_the_set_for_every_knob() {
        for k in TimingKnob.allCases {
            let low = k.range.lowerBound - 0.01
            var n = Self.normal; n[k.rawValue] = .number(low)
            XCTAssertEqual(load(normal: n), .failure(TimingRejection(set: "normal", knob: k, reason: .belowMinimum(low))))
        }
    }

    func test_a_value_above_its_range_rejects_the_set_for_every_knob() {
        for k in TimingKnob.allCases {
            let high = k.range.upperBound + 0.01
            var r = Self.reduced; r[k.rawValue] = .number(high)
            XCTAssertEqual(load(reduced: r), .failure(TimingRejection(set: "reduced", knob: k, reason: .aboveMaximum(high))))
        }
    }

    func test_a_missing_value_rejects_the_set_for_every_knob() {
        for k in TimingKnob.allCases {
            var n = Self.normal; n.removeValue(forKey: k.rawValue)
            XCTAssertEqual(load(normal: n), .failure(TimingRejection(set: "normal", knob: k, reason: .missing)))
        }
    }

    func test_a_non_numeric_value_rejects_the_set_for_every_knob() {
        for k in TimingKnob.allCases {
            for bad in [TimingValue.notNumber, .number(.nan), .number(.infinity)] {
                var n = Self.normal; n[k.rawValue] = bad
                XCTAssertEqual(load(normal: n), .failure(TimingRejection(set: "normal", knob: k, reason: .notANumber)), k.rawValue)
            }
        }
    }

    func test_a_fractional_particle_count_rejects_the_set() {
        var n = Self.normal; n["particles"] = .number(240.5)
        XCTAssertEqual(load(normal: n), .failure(TimingRejection(set: "normal", knob: .particles, reason: .notWholeNumber(240.5))))
    }

    func test_one_bad_set_rejects_the_whole_data_and_no_morph_spec_exists() {
        var r = Self.reduced; r["flow_s"] = .number(0.1)
        let result = load(reduced: r)
        guard case .failure(let why) = result else { return XCTFail("expected rejection") }
        XCTAssertEqual(why.message, "reduced.flow_s: 0.1 is below the minimum 0.2")
        XCTAssertNil(try? result.get(), "no TimingData, so no MorphSpec and no Morph, even for the good normal set")
    }

    func test_rejection_messages_name_the_set_knob_and_reason() {
        func msg(_ k: TimingKnob, _ r: TimingRejectionReason) -> String { TimingRejection(set: "normal", knob: k, reason: r).message }
        XCTAssertEqual(msg(.drift, .missing), "normal.drift: missing")
        XCTAssertEqual(msg(.swirl, .notANumber), "normal.swirl: not a number")
        XCTAssertEqual(msg(.swirl, .aboveMaximum(2)), "normal.swirl: 2.0 is above the maximum 1.0")
        XCTAssertEqual(msg(.particles, .notWholeNumber(1.5)), "normal.particles: 1.5 is not a whole number")
    }

    // MARK: AC-8

    func test_reduced_motion_on_gives_the_reduced_set_for_a_new_morph() throws {
        let d = try data()
        XCTAssertEqual(d.timing(reducedMotion: true), d.reduced)
        XCTAssertEqual(d.timing(reducedMotion: false), d.normal)
        XCTAssertEqual(d.morphSpec(reducedMotion: true, seed: 9).duration, 1.2, accuracy: 1e-9)
        XCTAssertEqual(d.morphSpec(reducedMotion: false, seed: 9).duration, 2.45, accuracy: 1e-9)
    }

    func test_a_morph_already_built_keeps_its_spec_when_the_flag_flips() throws {
        let d = try data()
        let before = d.morphSpec(reducedMotion: false, seed: 5)
        let old = try Morph(spec: before, glyphPath: Self.box, silhouettePath: Self.box)
        let sample = old.positions(at: 1.0)
        let new = try Morph(spec: d.morphSpec(reducedMotion: true, seed: 5), glyphPath: Self.box, silhouettePath: Self.box)
        XCTAssertEqual(old.spec, before)
        XCTAssertEqual(old.spec.duration, 2.45, accuracy: 1e-9)
        XCTAssertEqual(new.spec.duration, 1.2, accuracy: 1e-9)
        XCTAssertEqual(old.positions(at: 1.0), sample)
    }
}
