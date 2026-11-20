import AVFoundation
import ContractKit
import CryptoKit
import Foundation
import ToolsCore
import XCTest

/// The sfx bake (TR-keytable-004 sfx half, ADR-0003 D5, content-pipeline story 007) on the real Dinosaurs recipes
/// (`content/themes/dinosaurs/src/sfx/recipes.json`, read only). Bakes go to fresh temp theme folders.
final class SfxBakeTests: XCTestCase {
    var recipesURL: URL {
        get throws { try Fixture.contractsRoot(from: #filePath).deletingLastPathComponent().appendingPathComponent("content/themes/dinosaurs/src/sfx/recipes.json") }
    }
    var recipesData: Data { get throws { try Data(contentsOf: recipesURL) } }
    var recipes: SfxRecipes { get throws { try SfxRecipes.parse(recipesData, label: "recipes.json") } }

    let castIds = ["dino_a_ankylosaurus_01", "dino_b_brachiosaurus_01", "dino_c_triceratops_01", "dino_d_diplodocus_01", "dino_e_edmontosaurus_01",
                   "dino_f_fossil_01", "dino_g_gallimimus_01", "dino_h_hadrosaurus_01", "dino_i_iguanodon_01", "dino_j_juravenator_01",
                   "dino_k_kentrosaurus_01", "dino_l_lambeosaurus_01", "dino_m_maiasaura_01", "dino_n_nest_01", "dino_o_oviraptor_01",
                   "dino_p_tapejara_01", "dino_q_quetzalcoatlus_01", "dino_r_raptor_01", "dino_s_stegosaurus_01", "dino_t_trex_01",
                   "dino_u_utahraptor_01", "dino_v_velociraptor_01", "dino_w_wuerhosaurus_01", "dino_x_xenoceratops_01", "dino_y_yutyrannus_01",
                   "dino_z_zuniceratops_01", "dino_0_nest_01"] + (1...9).map { "dino_\($0)_babies_01" }

    /// A temp theme folder holding `data` as its recipes file.
    func theme(with data: Data) throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("sfx-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir.appendingPathComponent("src/sfx"), withIntermediateDirectories: true)
        try data.write(to: dir.appendingPathComponent("src/sfx/recipes.json"))
        addTeardownBlock { try? FileManager.default.removeItem(at: dir) }
        return dir
    }

    /// The real recipes file with `edit` applied to its JSON.
    func mutated(_ edit: (inout [String: Any]) -> Void) throws -> Data {
        var o = try XCTUnwrap(try JSONSerialization.jsonObject(with: recipesData) as? [String: Any])
        edit(&o)
        return try JSONSerialization.data(withJSONObject: o, options: [.sortedKeys])
    }

    func render(_ id: String) throws -> PCMAudio {
        let r = try recipes
        return SfxSynth.render(try XCTUnwrap(r.recipes.first { $0.castId == id }), constants: r.synth)
    }

    // MARK: AC-1 / AC-2: files, names, format, recipes as data

    func test_all_36_files_are_named_by_cast_id_and_decode_as_aac_mono_48k_with_no_priming_lead() throws {
        let dir = try theme(with: try recipesData)
        let r = try SfxBake.bakeTheme(themeDir: dir)
        XCTAssertEqual(r.written, (castIds.map { "sfx/sfx_\($0).m4a" } + ["sfx/provenance.json"]).sorted())
        XCTAssertEqual(castIds.count, 36)
        for id in castIds {
            let url = dir.appendingPathComponent("sfx/sfx_\(id).m4a")
            let f = try AVAudioFile(forReading: url)
            XCTAssertEqual(f.fileFormat.settings[AVFormatIDKey] as? UInt32, kAudioFormatMPEG4AAC, id)
            XCTAssertEqual(f.fileFormat.channelCount, 1, id)
            XCTAssertEqual(f.fileFormat.sampleRate, VoiceBake.sampleRate, id)
        }
        // One sfx through the same encoder decodes with no priming lead and its length (story 003's priming test, for sfx).
        let rep = try XCTUnwrap(r.files.first { $0.castId == "dino_t_trex_01" })
        let f = try AVAudioFile(forReading: dir.appendingPathComponent("sfx/sfx_dino_t_trex_01.m4a"))
        XCTAssertLessThanOrEqual(abs(Double(f.length) - rep.duration * f.processingFormat.sampleRate), 1024)
        let buf = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: f.processingFormat, frameCapacity: AVAudioFrameCount(f.length)))
        try f.read(into: buf)
        let ch = try XCTUnwrap(buf.floatChannelData)[0]
        // The roar rises over 120 ms, so "no lead" means the first sound that is not silence (-60 dBFS) is not later than a
        // PCM render's own: compare with the source PCM's first sample above -60 dBFS.
        let source = try SfxBake.normalise(try render("dino_t_trex_01"), recipe: try XCTUnwrap(try recipes.recipes.first { $0.castId == "dino_t_trex_01" })).pcm
        let srcOnset = try XCTUnwrap(source.samples.firstIndex { abs($0) > 0.001 })
        let decOnset = try XCTUnwrap((0..<Int(buf.frameLength)).first { abs(ch[$0]) > 0.001 })
        XCTAssertLessThanOrEqual(abs(Double(decOnset - srcOnset)) / f.processingFormat.sampleRate, 0.005)
    }

    func test_the_recipes_are_data_with_the_36_cast_ids_and_digits_counting_along() throws {
        let r = try recipes
        XCTAssertEqual(r.recipes.map(\.castId), castIds.sorted())
        for d in 1...9 {
            let x = try XCTUnwrap(r.recipes.first { $0.castId == "dino_\(d)_babies_01" })
            XCTAssertEqual(x.kind, .chirp); XCTAssertEqual(x.params["n"], Double(d)); XCTAssertEqual(x.params["f0"], 1200); XCTAssertEqual(x.params["f1"], 1700)
        }
        let zero = try XCTUnwrap(r.recipes.first { $0.castId == "dino_0_nest_01" })
        XCTAssertEqual(zero.params, ["f0": 700, "f1": 900, "n": 1])
    }

    func test_the_recipes_file_is_validated_at_the_boundary() throws {
        func parseError(_ edit: (inout [String: Any]) -> Void) throws -> String {
            do { _ = try SfxRecipes.parse(try mutated(edit), label: "recipes.json"); return "" } catch let e as VoiceBakeError { return e.reason }
        }
        XCTAssertTrue(try parseError { var r = $0["recipes"] as! [String: Any]; r["dino_t_trex_01"] = ["kind": "bark"]; $0["recipes"] = r }.contains("dino_t_trex_01"))
        XCTAssertTrue(try parseError { var r = $0["recipes"] as! [String: Any]; r["dino_t_trex_01"] = ["kind": "roar", "f0": 58]; $0["recipes"] = r }.contains("recipes.dino_t_trex_01.cut"))
        XCTAssertTrue(try parseError { var r = $0["recipes"] as! [String: Any]; r["Trex"] = ["kind": "crack"]; $0["recipes"] = r }.contains("castId"))
        // An attack under 10 ms is refused (Audio R7 A1): the prototype's 3 ms crack attack cannot be restored by data.
        XCTAssertTrue(try parseError { var s = $0["synth"] as! [String: Any]; var c = s["crack"] as! [String: Any]; c["attack"] = 0.003; s["crack"] = c; $0["synth"] = s }.contains("synth.crack.attack"))
    }

    // MARK: AC-3 / AC-4: numbers, length

    func test_digit_n_has_exactly_n_onsets_for_1_to_9_and_zero_has_one_soft_chirp() throws {
        // Method: RMS of consecutive 5 ms blocks; an onset is a block >= 3 % of the loudest block after the envelope was < 1 %.
        for d in 0...9 {
            let id = d == 0 ? "dino_0_nest_01" : "dino_\(d)_babies_01", pcm = try render(id)
            XCTAssertEqual(SfxBake.onsets(in: pcm.samples, sampleRate: pcm.sampleRate), max(d, 1), id)
        }
    }

    func test_nine_chirps_are_within_2_seconds_and_a_2_1_second_recipe_fails_naming_the_file_and_writes_nothing() throws {
        let nine = try render("dino_9_babies_01")
        XCTAssertEqual(Double(nine.samples.count) / nine.sampleRate, 8 * 0.17 + 0.16, accuracy: 0.001)
        XCTAssertLessThanOrEqual(Double(nine.samples.count) / nine.sampleRate, 2.0)
        // 13 chirps: 12 * 0.17 + 0.16 = 2.2 s.
        let dir = try theme(with: try mutated { var r = $0["recipes"] as! [String: Any]; var x = r["dino_9_babies_01"] as! [String: Any]; x["n"] = 13; r["dino_9_babies_01"] = x; $0["recipes"] = r })
        XCTAssertThrowsError(try SfxBake.bakeTheme(themeDir: dir)) { e in
            XCTAssertEqual((e as? VoiceBakeError)?.file, "sfx/sfx_dino_9_babies_01.m4a")
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: dir.appendingPathComponent("sfx").path), "a failing bake writes nothing into the theme")
    }

    // MARK: AC-6: loudness

    func test_every_recipe_is_normalised_to_minus_20_lufs_with_true_peak_under_minus_1_dbtp_before_encoding() throws {
        let r = try recipes
        for x in r.recipes {
            let (pcm, report) = try SfxBake.normalise(SfxSynth.render(x, constants: r.synth), recipe: x)
            let m = LoudnessMeter.measure(pcm.samples, sampleRate: pcm.sampleRate)   // an independent measurement of the output
            XCTAssertEqual(m.classLUFS, -20, accuracy: 0.1, x.castId)
            XCTAssertLessThanOrEqual(m.truePeakDBTP, -1, x.castId)
            XCTAssertEqual(m.momentaryOnly, pcm.samples.count < 19_200, x.castId)
            XCTAssertEqual(report.loudnessAfter, m.classLUFS, accuracy: 1e-9)
        }
    }

    // MARK: AC-7: toddler-safe attack

    /// Method: on the raw render, the first sample is at most 1e-3 of the peak, and for every sample in the first 10 ms the
    /// magnitude stays under a linear ramp that reaches TWICE the peak at 10 ms (so full level cannot be reached before 5 ms; the
    /// prototype's 3 ms crack attack would break it). The recipe data also refuses any attack under 10 ms (boundary test above).
    func test_every_sound_starts_with_a_rise_of_at_least_10_ms_not_a_step() throws {
        let r = try recipes
        for x in r.recipes {
            let s = SfxSynth.render(x, constants: r.synth).samples
            let peak = Double(s.map { abs($0) }.max()!)
            XCTAssertLessThanOrEqual(Double(abs(s[0])), 1e-3 * peak, x.castId)
            for i in 0..<480 { XCTAssertLessThanOrEqual(Double(abs(s[i])), 2 * peak * Double(i) / 480 + 1e-3 * peak, "\(x.castId) sample \(i)") }
        }
    }

    // MARK: AC-8 / AC-9: deterministic, provenance

    func test_two_renders_are_bit_identical_and_two_bakes_give_the_same_files_and_provenance() throws {
        let r = try recipes
        for x in r.recipes {
            XCTAssertEqual(SfxSynth.render(x, constants: r.synth), SfxSynth.render(x, constants: r.synth), x.castId)
        }
        let a = try theme(with: try recipesData), b = try theme(with: try recipesData)
        let wa = try SfxBake.bakeTheme(themeDir: a).written, wb = try SfxBake.bakeTheme(themeDir: b).written
        XCTAssertEqual(wa, wb)
        for rel in wa {
            XCTAssertEqual(try Data(contentsOf: a.appendingPathComponent(rel)), try Data(contentsOf: b.appendingPathComponent(rel)), rel)
        }
    }

    func test_provenance_records_the_recipe_hash_synth_version_encode_settings_and_loudness_per_file() throws {
        let data = try recipesData, dir = try theme(with: data)
        _ = try SfxBake.bakeTheme(themeDir: dir)
        let text = String(decoding: try Data(contentsOf: dir.appendingPathComponent("sfx/provenance.json")), as: UTF8.self)
        let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        for needle in ["\"recipesSha256\": \"\(hash)\"", "\"synthVersion\": \"\(SfxSynth.version)\"", "\"bitRate\": 64000", "\"channels\": 1",
                       "\"sampleRate\": 48000", "\"codec\": \"aac-lc\"", "\"sfx_dino_t_trex_01.m4a\"", "\"loudnessBeforeLUFS\"", "\"loudnessAfterLUFS\": -20",
                       "\"truePeakDBTP\"", "\"measure\": \"momentaryMax\"", "\"measure\": \"integrated\"", "\"baker\": \"kidtools"] {
            XCTAssertTrue(text.contains(needle), needle)
        }
    }
}
