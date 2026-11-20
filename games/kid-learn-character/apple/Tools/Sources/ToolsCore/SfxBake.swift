import AVFoundation
import CryptoKit
import Foundation

// MARK: Recipes (data)

/// One sound recipe: a kind plus its numbers, from `content/themes/<id>/src/sfx/recipes.json`.
public struct SfxRecipe: Equatable, Sendable {
    /// The four prototype sound kinds; `honk` is a `chirp` on a low-passed sawtooth.
    public enum Kind: String, Sendable { case roar, chirp, honk, crack, thump }
    /// The item's `castId`, which also names the file: `sfx/sfx_<castId>.caf`.
    public var castId: String
    public var kind: Kind
    /// The recipe's own numbers (`f0 f1 n` for chirp and honk; `f0 cut dur vol vib` for roar and thump; none for crack).
    public var params: [String: Double]

    /// The file path relative to the theme folder.
    public var path: String { "sfx/sfx_\(castId).caf" }
}

/// The synth's graph constants, also data (`synth` in recipes.json): the prototype's numbers at `roar_volume` 0.35.
public struct SfxSynthConstants: Equatable, Sendable {
    public var noiseSeed: Int, noiseSeconds: Double
    public var roarVolume, envFloor, holdFraction, defaultQdB: Double
    public var roar: [String: Double], chirp: [String: Double], crack: [String: Double], thump: [String: Double]
    /// Every attack time in the constants must be at least this (Audio R7 A1: no sound starts at full level).
    public static let minAttackSeconds = 0.010
}

/// The parsed recipes file.
public struct SfxRecipes: Equatable, Sendable {
    public var synth: SfxSynthConstants
    /// Sorted by castId.
    public var recipes: [SfxRecipe]

    static let roarKeys = ["noiseQdB", "noiseCutStart", "noiseCutPeak", "noiseCutEnd", "cutPeakAt", "noiseGain", "noiseAttack",
                           "sawStart", "sawPeak", "sawEnd", "lfoDepth", "sawCut", "sawGain", "sawAttack", "tail"]
    static let chirpKeys = ["spacing", "rise", "fall", "fallRatio", "envDur", "attack", "stop", "level", "honkCut"]
    static let crackKeys = ["ticks", "spacing", "highpass", "envDur", "level", "attack", "noiseStep", "stop", "peepAt", "peepF0", "peepF1", "peepN"]
    static let thumpKeys = ["tone1Freq", "tone1Dur", "tone1Level", "tone1At", "tone2Freq", "tone2Dur", "tone2Level", "tone2At",
                            "toneAttack", "toneTail", "roarScale"]

    /// Parses and validates the file bytes; every error names the field. `label` names the file in errors. Unknown and
    /// missing fields, non-positive numbers and any attack under 10 ms are errors.
    ///
    /// Example:
    /// ```swift
    /// let recipes = try SfxRecipes.parse(Data(contentsOf: url), label: "src/sfx/recipes.json")
    /// ```
    public static func parse(_ data: Data, label: String) throws -> SfxRecipes {
        func bad(_ r: String) -> VoiceBakeError { VoiceBakeError(file: label, reason: r) }
        guard let top = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { throw bad("not a JSON object") }
        /// Reads numbers out of one object, then rejects whatever was not read.
        struct Fields {
            let d: [String: Any], path: String, bad: (String) -> VoiceBakeError
            func num(_ k: String, positive: Bool = true) throws -> Double {
                guard let v = d[k] as? Double, v.isFinite else { throw bad("\(path)\(k): missing or not a number") }
                if positive && v <= 0 { throw bad("\(path)\(k): must be > 0") }
                return v
            }
            func obj(_ k: String) throws -> Fields {
                guard let o = d[k] as? [String: Any] else { throw bad("\(path)\(k): missing or not an object") }
                return Fields(d: o, path: path + k + ".", bad: bad)
            }
            func block(_ keys: [String], zeroOK: Set<String> = []) throws -> [String: Double] {
                var out: [String: Double] = [:]
                for k in keys { out[k] = try num(k, positive: !zeroOK.contains(k)) }
                if let extra = d.keys.sorted().first(where: { !keys.contains($0) }) { throw bad("\(path)\(extra): unknown field") }
                return out
            }
        }
        let root = Fields(d: top, path: "", bad: bad)
        guard (top["schemaVersion"] as? Int) == 1 else { throw bad("schemaVersion is not 1") }
        if let extra = top.keys.sorted().first(where: { !["schemaVersion", "note", "synth", "recipes"].contains($0) }) {
            throw bad("\(extra): unknown field")
        }
        let s = try root.obj("synth")
        let noise = try s.obj("noise").block(["seed", "seconds"]), env = try s.obj("envelope").block(["floor", "holdFraction"])
        let roar = try s.obj("roar").block(roarKeys), chirp = try s.obj("chirp").block(chirpKeys)
        let crack = try s.obj("crack").block(crackKeys), thump = try s.obj("thump").block(thumpKeys, zeroOK: ["tone1At"])
        if let extra = s.d.keys.sorted().first(where: { !["noise", "envelope", "roar", "chirp", "crack", "thump", "roarVolume", "defaultQdB"].contains($0) }) {
            throw bad("synth.\(extra): unknown field")
        }
        for (name, block) in [("roar", roar), ("chirp", chirp), ("crack", crack), ("thump", thump)] {
            for (k, v) in block.sorted(by: { $0.key < $1.key }) where k.lowercased().hasSuffix("attack") && v < SfxSynthConstants.minAttackSeconds {
                throw bad("synth.\(name).\(k): attack \(v) s is under 0.010 s (Audio R7 A1)")
            }
        }
        let constants = SfxSynthConstants(noiseSeed: Int(noise["seed"]!), noiseSeconds: noise["seconds"]!, roarVolume: try s.num("roarVolume"),
                                          envFloor: env["floor"]!, holdFraction: env["holdFraction"]!, defaultQdB: try s.num("defaultQdB"),
                                          roar: roar, chirp: chirp, crack: crack, thump: thump)
        guard let rs = top["recipes"] as? [String: Any], !rs.isEmpty else { throw bad("recipes: missing or empty") }
        var out: [SfxRecipe] = []
        for id in rs.keys.sorted() {
            let parts = id.split(separator: "_", omittingEmptySubsequences: false)
            guard parts.count == 4, parts[1].count == 1, parts[3].count == 2, parts[3].allSatisfy(\.isNumber),
                  parts.allSatisfy({ !$0.isEmpty && $0.allSatisfy { $0.isASCII && ($0.isLowercase || $0.isNumber) } }) else {
                throw bad("recipes.\(id): not a castId <prefix>_<key>_<name>_<nn>")
            }
            guard let o = rs[id] as? [String: Any] else { throw bad("recipes.\(id): not an object") }
            let f = Fields(d: o, path: "recipes.\(id).", bad: bad)
            guard let kindText = o["kind"] as? String, let kind = SfxRecipe.Kind(rawValue: kindText) else {
                throw bad("recipes.\(id).kind: missing or not one of roar, chirp, honk, crack, thump")
            }
            let keys: [String]
            switch kind { case .roar, .thump: keys = ["f0", "cut", "dur", "vol", "vib"]; case .chirp, .honk: keys = ["f0", "f1", "n"]; case .crack: keys = [] }
            var params: [String: Double] = [:]
            for k in keys { params[k] = try f.num(k) }
            if let n = params["n"], n != n.rounded() { throw bad("recipes.\(id).n: not a whole number") }
            if let extra = o.keys.sorted().first(where: { !keys.contains($0) && $0 != "kind" && $0 != "label" }) { throw bad("recipes.\(id).\(extra): unknown field") }
            out.append(SfxRecipe(castId: id, kind: kind, params: params))
        }
        return SfxRecipes(synth: constants, recipes: out)
    }
}

// MARK: Synth

/// A deterministic port of the prototype's Web Audio sound graph (`prototypes/letter-morph-dinosaur/index.html`:
/// `env`, `tone`, `roar`, `chirps`, `crack`, the thump branch of `creatureSound`) to plain sample loops at 48 kHz.
/// Double precision inside, Float32 out. No randomness except the prototype's fixed LCG noise buffer. Not thread-safe
/// to share state (there is none): every call is a pure function of its arguments.
///
/// What differs from a browser, on purpose: oscillators are sine, a naive triangle and a PolyBLEP sawtooth (Web Audio
/// uses band-limited tables); filters are the Web Audio RBJ lowpass/highpass formulas with Q in dB, their coefficients
/// recomputed every sample where the cutoff moves; automation is evaluated analytically per sample instead of per
/// render quantum.
///
/// Example:
/// ```swift
/// let recipes = try SfxRecipes.parse(data, label: "recipes.json")
/// let pcm = SfxSynth.render(recipes.recipes[0], constants: recipes.synth)   // relative levels, not normalised
/// ```
public enum SfxSynth {
    /// Written to provenance. Change it whenever the PCM for an unchanged recipe file changes.
    public static let version = "sfx-synth-1"
    static let sr = VoiceBake.sampleRate

    enum Wave { case sine, triangle, sawtooth }

    /// The prototype's `env`: setValue floor at 0, linear ramp to `v` over `attack`, hold to `max(attack, dur*0.45)`,
    /// exponential ramp back to the floor at `dur`; the floor after.
    static func envelope(_ t: Double, dur: Double, v: Double, attack: Double, _ c: SfxSynthConstants) -> Double {
        let floor = c.envFloor, hold = max(attack, dur * c.holdFraction)
        if t < attack { return floor + (v - floor) * t / attack }
        if t < hold { return v }
        if t < dur { return v * pow(floor / v, (t - hold) / (dur - hold)) }
        return floor
    }

    /// Web Audio's lowpass (Q in dB, `10^(Q/20)`).
    static func lowpass(_ f: Double, qDB: Double) -> Biquad {
        let w = 2 * Double.pi * f / sr, cs = cos(w), alpha = sin(w) / (2 * pow(10, qDB / 20)), a0 = 1 + alpha
        return Biquad(b0: (1 - cs) / 2 / a0, b1: (1 - cs) / a0, b2: (1 - cs) / 2 / a0, a1: -2 * cs / a0, a2: (1 - alpha) / a0)
    }

    /// Web Audio's highpass (Q in dB).
    static func highpass(_ f: Double, qDB: Double) -> Biquad {
        let w = 2 * Double.pi * f / sr, cs = cos(w), alpha = sin(w) / (2 * pow(10, qDB / 20)), a0 = 1 + alpha
        return Biquad(b0: (1 + cs) / 2 / a0, b1: -(1 + cs) / a0, b2: (1 + cs) / 2 / a0, a1: -2 * cs / a0, a2: (1 - alpha) / a0)
    }

    /// The prototype's noise buffer: `s = (s*1103515245 + 12345) & 0x7fffffff; d = s/0x3fffffff - 1`, seeded 12345 (exact
    /// integer arithmetic; the prototype's JS evaluated the product in doubles, which rounds above 2^53).
    static func noiseBuffer(_ c: SfxSynthConstants) -> [Double] {
        var s = UInt64(c.noiseSeed)
        return (0..<Int(c.noiseSeconds * sr)).map { _ in
            s = (s &* 1103515245 &+ 12345) & 0x7fffffff
            return Double(s) / Double(0x3fffffff) - 1
        }
    }

    /// One oscillator voice, `stop` seconds long, with its gain envelope and an optional fixed lowpass.
    static func oscillator(_ wave: Wave, stop: Double, freq: (Double) -> Double, level: Double, envDur: Double, attack: Double,
                           lowpassCut: Double?, _ c: SfxSynthConstants) -> [Double] {
        let n = Int(stop * sr)
        var phase = 0.0
        var lp = lowpassCut.map { BiquadRunner(lowpass($0, qDB: c.defaultQdB)) }
        return (0..<n).map { k in
            let t = Double(k) / sr, f = freq(t), dt = f / sr
            var x: Double
            switch wave {
            case .sine: x = sin(2 * Double.pi * phase)
            case .triangle: x = phase < 0.25 ? 4 * phase : (phase < 0.75 ? 2 - 4 * phase : 4 * phase - 4)
            case .sawtooth:
                let q = (phase + 0.5).truncatingRemainder(dividingBy: 1)   // 0 at the downward jump
                var blep = 0.0
                if q < dt { let u = q / dt; blep = u + u - u * u - 1 } else if q > 1 - dt { let u = (q - 1) / dt; blep = u * u + u + u + 1 }
                x = 2 * q - 1 - blep
            }
            phase += dt; phase -= phase.rounded(.down)
            if lp != nil { x = lp!.process(x) }
            return x * envelope(t, dur: envDur, v: level, attack: attack, c)
        }
    }

    /// The prototype's `chirps(p, type, at)`: `n` swept tones `spacing` apart, summed into `out` from `at`.
    static func chirps(into out: inout [Double], wave: Wave, f0: Double, f1: Double, n: Int, at: Double, _ c: SfxSynthConstants) {
        let p = c.chirp
        for i in 0..<n {
            let voice = oscillator(wave, stop: p["stop"]!, freq: { t in
                if t < p["rise"]! { return f0 * pow(f1 / f0, t / p["rise"]!) }
                if t < p["fall"]! { return f1 * pow(f0 * p["fallRatio"]! / f1, (t - p["rise"]!) / (p["fall"]! - p["rise"]!)) }
                return f0 * p["fallRatio"]!
            }, level: p["level"]!, envDur: p["envDur"]!, attack: p["attack"]!, lowpassCut: wave == .sawtooth ? p["honkCut"]! : nil, c)
            mix(&out, voice, at: at + Double(i) * p["spacing"]!)
        }
    }

    /// The prototype's `roar(p, scale)` from `at` = 0: low-passed noise plus a vibrato sawtooth.
    static func roar(into out: inout [Double], f0: Double, cut: Double, dur: Double, vol: Double, vib: Double, scale: Double,
                     noise: [Double], _ c: SfxSynthConstants) {
        let p = c.roar, level = vol * c.roarVolume * scale, stop = dur + p["tail"]!, n = Int(stop * sr)
        func ramp(_ t: Double, _ a: Double, _ b: Double, _ cc: Double) -> Double {   // a at 0, b at cutPeakAt*dur, cc at dur, then hold
            let pk = dur * p["cutPeakAt"]!
            if t < pk { return a + (b - a) * t / pk }
            if t < dur { return b + (cc - b) * (t - pk) / (dur - pk) }
            return cc
        }
        var filter = BiquadRunner(lowpass(cut * p["noiseCutStart"]!, qDB: p["noiseQdB"]!))
        let noiseVoice: [Double] = (0..<n).map { k in
            let t = Double(k) / sr
            filter.c = lowpass(ramp(t, cut * p["noiseCutStart"]!, cut * p["noiseCutPeak"]!, cut * p["noiseCutEnd"]!), qDB: p["noiseQdB"]!)
            return filter.process(noise[k]) * envelope(t, dur: dur, v: level * p["noiseGain"]!, attack: p["noiseAttack"]!, c)
        }
        let sawVoice = oscillator(.sawtooth, stop: stop, freq: { t in
            ramp(t, f0 * p["sawStart"]!, f0 * p["sawPeak"]!, f0 * p["sawEnd"]!) + f0 * p["lfoDepth"]! * sin(2 * Double.pi * vib * t)
        }, level: level * p["sawGain"]!, envDur: dur, attack: p["sawAttack"]!, lowpassCut: cut * p["sawCut"]!, c)
        mix(&out, noiseVoice, at: 0); mix(&out, sawVoice, at: 0)
    }

    static func mix(_ out: inout [Double], _ voice: [Double], at seconds: Double) {
        let off = Int((seconds * sr).rounded())
        if out.count < off + voice.count { out += [Double](repeating: 0, count: off + voice.count - out.count) }
        for i in 0..<voice.count { out[off + i] += voice[i] }
    }

    /// Renders one recipe to mono PCM at 48 kHz at the prototype's relative levels (peaks well under 1.0; the bake sets
    /// the level by loudness normalisation).
    public static func render(_ r: SfxRecipe, constants c: SfxSynthConstants) -> PCMAudio {
        let noise = noiseBuffer(c), p = r.params
        var out: [Double] = []
        switch r.kind {
        case .roar:
            roar(into: &out, f0: p["f0"]!, cut: p["cut"]!, dur: p["dur"]!, vol: p["vol"]!, vib: p["vib"]!, scale: 1, noise: noise, c)
        case .chirp:
            chirps(into: &out, wave: .triangle, f0: p["f0"]!, f1: p["f1"]!, n: Int(p["n"]!), at: 0, c)
        case .honk:
            chirps(into: &out, wave: .sawtooth, f0: p["f0"]!, f1: p["f1"]!, n: Int(p["n"]!), at: 0, c)
        case .crack:
            let k = c.crack
            for i in 0..<Int(k["ticks"]!) {
                let start = Int((Double(i) * k["noiseStep"]! * sr).rounded()), len = Int(k["stop"]! * sr)
                var hp = BiquadRunner(highpass(k["highpass"]!, qDB: c.defaultQdB))
                let tick: [Double] = (0..<len).map { j in
                    hp.process(noise[start + j]) * envelope(Double(j) / sr, dur: k["envDur"]!, v: k["level"]!, attack: k["attack"]!, c)
                }
                mix(&out, tick, at: Double(i) * k["spacing"]!)
            }
            chirps(into: &out, wave: .sine, f0: k["peepF0"]!, f1: k["peepF1"]!, n: Int(k["peepN"]!), at: k["peepAt"]!, c)
        case .thump:
            let k = c.thump
            for i in ["tone1", "tone2"] {
                let f = k[i + "Freq"]!, dur = k[i + "Dur"]!
                mix(&out, oscillator(.sine, stop: dur + k["toneTail"]!, freq: { _ in f }, level: k[i + "Level"]!, envDur: dur,
                                     attack: k["toneAttack"]!, lowpassCut: nil, c), at: k[i + "At"]!)
            }
            roar(into: &out, f0: p["f0"]!, cut: p["cut"]!, dur: p["dur"]!, vol: p["vol"]!, vib: p["vib"]!, scale: k["roarScale"]!, noise: noise, c)
        }
        return PCMAudio(samples: out.map { Float($0) }, sampleRate: sr)
    }
}

// MARK: Bake

/// What the bake measured and wrote for one sound.
public struct SfxFileReport: Equatable, Sendable {
    public var castId: String
    /// `sfx/sfx_<castId>.caf`
    public var path: String
    public var duration: Double
    /// True when judged by the momentary maximum (under 0.4 s), false when by the integrated loudness.
    public var momentaryOnly: Bool
    /// The class figure (LUFS) before and after the gain, the gain (dB) and the true peak (dBTP) after it.
    public var loudnessBefore, loudnessAfter, gainDB, truePeakDBTP: Double
    /// Onsets counted in the PCM (`SfxBake.onsets`): for a chirp recipe, the number of chirps.
    public var onsets: Int
}

/// The sfx bake (TR-keytable-004 sfx half; ADR-0003 D5): recipes (data) → deterministic synth → loudness normalisation by
/// the D5 meter → `VoiceBake.encode` (the one encoder: uncompressed 16-bit LPCM in CAF, mono, 48 kHz, K-52; byte-stable)
/// → `sfx/sfx_<castId>.caf` plus byte-stable `sfx/provenance.json`.
///
/// Every file is normalised by ONE gain to the cast class, -20 LUFS (integrated, or the momentary maximum under 0.4 s),
/// and must then have a true peak of at most -1 dBTP: a file that does not fails the bake, naming it (no limiter). A
/// file over 2.0 s (V12), rendered or decoded, fails the bake naming it. Output is staged in a temp folder and copied to
/// the theme only when every file succeeded.
///
/// Example:
/// ```swift
/// let r = try SfxBake.bakeTheme(themeDir: URL(fileURLWithPath: "content/themes/dinosaurs"))
/// // r.written == ["sfx/provenance.json", "sfx/sfx_dino_a_ankylosaurus_01.caf", …], r.files[0].loudnessAfter ≈ -20
/// ```
public enum SfxBake {
    /// The cast class target (Audio F4, A7), its tolerance (LU), the true-peak ceiling (dBTP), the length limit (s, V12).
    public static let targetLUFS = -20.0, toleranceLU = 1.0, truePeakCeilingDBTP = -1.0, maxSeconds = 2.0

    /// Normalises `pcm` to `targetLUFS` by one gain and checks the ceiling; `rel` names the file in errors.
    public static func normalise(_ pcm: PCMAudio, recipe: SfxRecipe) throws -> (pcm: PCMAudio, report: SfxFileReport) {
        let rel = recipe.path
        let duration = Double(pcm.samples.count) / pcm.sampleRate
        if duration > maxSeconds { throw VoiceBakeError(file: rel, reason: "\(duration) s is over \(maxSeconds) s (V12)") }
        let before = LoudnessMeter.measure(pcm.samples, sampleRate: pcm.sampleRate, truePeak: false)
        guard before.classLUFS.isFinite else { throw VoiceBakeError(file: rel, reason: "silent or fully gated: no loudness to normalise") }
        let gainDB = targetLUFS - before.classLUFS, g = pow(10, gainDB / 20)
        let out = PCMAudio(samples: pcm.samples.map { Float(Double($0) * g) }, sampleRate: pcm.sampleRate)
        let after = LoudnessMeter.measure(out.samples, sampleRate: out.sampleRate, truePeak: false)
        let truePeak = LoudnessMeter.truePeak(out.samples)
        guard abs(after.classLUFS - targetLUFS) <= toleranceLU else {
            throw VoiceBakeError(file: rel, reason: "\(after.classLUFS) LUFS after normalising, outside \(targetLUFS) ±\(toleranceLU) LU")
        }
        guard truePeak <= truePeakCeilingDBTP else {
            throw VoiceBakeError(file: rel, reason: "true peak \(truePeak) dBTP is over \(truePeakCeilingDBTP) dBTP at \(targetLUFS) LUFS")
        }
        return (out, SfxFileReport(castId: recipe.castId, path: rel, duration: duration, momentaryOnly: after.momentaryOnly,
                                   loudnessBefore: before.classLUFS, loudnessAfter: after.classLUFS, gainDB: gainDB,
                                   truePeakDBTP: truePeak, onsets: onsets(in: out.samples, sampleRate: out.sampleRate)))
    }

    /// The exact bytes `bakeTheme` writes for `recipe` (synth → normalise → CAF), rendered in memory (a temp file is used
    /// for the encoder and removed). Byte-stable under K-52, so staleness compares it with the committed file.
    public static func renderedBytes(recipe: SfxRecipe, constants: SfxSynthConstants) throws -> Data {
        let (pcm, _) = try normalise(SfxSynth.render(recipe, constants: constants), recipe: recipe)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("sfxstale-\(UUID().uuidString).caf")
        defer { try? FileManager.default.removeItem(at: url) }
        try VoiceBake.encode(pcm, to: url)
        return try Data(contentsOf: url)
    }

    /// Counts sound onsets by an envelope threshold: the RMS of consecutive 5 ms blocks; an onset is a block at or above
    /// 3 % of the loudest block (-30 dB) after the envelope has been below 1 % (-40 dB), or at the start. Counts chirps
    /// (each decays below -40 dB before the next starts); it is not a general onset detector.
    public static func onsets(in samples: [Float], sampleRate: Double) -> Int {
        let block = Int(0.005 * sampleRate)
        var rms: [Double] = []
        var i = 0
        while i + block <= samples.count {
            var s = 0.0
            for j in i..<(i + block) { s += Double(samples[j]) * Double(samples[j]) }
            rms.append((s / Double(block)).squareRoot()); i += block
        }
        let peak = rms.max() ?? 0
        guard peak > 0 else { return 0 }
        var armed = true, count = 0
        for r in rms {
            if armed && r >= 0.03 * peak { count += 1; armed = false }
            if !armed && r < 0.01 * peak { armed = true }
        }
        return count
    }

    /// `sfx/provenance.json` bytes: recipes hash, synth version, encode settings, targets and per-file measurements. Sorted
    /// keys, 3 decimals, no timestamps.
    static func provenance(recipesData: Data, files: [SfxFileReport]) -> [UInt8] {
        let hash = SHA256.hash(data: recipesData).map { String(format: "%02x", $0) }.joined()
        var perFile: [String: JSONValue] = [:]
        for f in files {
            perFile[String(f.path.dropFirst("sfx/".count))] = .object([
                "durationSeconds": .number(f.duration), "gainDB": .number(f.gainDB),
                "loudnessAfterLUFS": .number(f.loudnessAfter), "loudnessBeforeLUFS": .number(f.loudnessBefore),
                "measure": .string(f.momentaryOnly ? "momentaryMax" : "integrated"), "truePeakDBTP": .number(f.truePeakDBTP),
            ])
        }
        return JSONValue.object([
            "baker": .string("\(SVGBake.toolName) \(SVGBake.toolVersion)"),
            "encode": .object(["bitDepth": .number(Double(VoiceBake.bitDepth)), "channels": .number(Double(VoiceBake.channels)),
                               "codec": .string("lpcm"), "container": .string("caf"), "sampleRate": .number(VoiceBake.sampleRate)]),
            "files": .object(perFile),
            "recipesFile": .string("src/sfx/recipes.json"),
            "recipesSha256": .string(hash),
            "synthVersion": .string(SfxSynth.version),
            "target": .object(["classLUFS": .number(targetLUFS), "maxSeconds": .number(maxSeconds),
                               "toleranceLU": .number(toleranceLU), "truePeakCeilingDBTP": .number(truePeakCeilingDBTP)]),
        ]).render()
    }

    /// Bakes `<themeDir>/src/sfx/recipes.json` into `<themeDir>/sfx/`. Returns the written paths relative to `themeDir`
    /// (sorted) and a report per sound (sorted by castId). Nothing is written to the theme unless every sound succeeds.
    public static func bakeTheme(themeDir: URL) throws -> (written: [String], files: [SfxFileReport]) {
        let fm = FileManager.default
        let label = "src/sfx/recipes.json"
        guard let data = fm.contents(atPath: themeDir.appendingPathComponent(label).path) else { throw VoiceBakeError(file: label, reason: "missing") }
        let recipes = try SfxRecipes.parse(data, label: label)
        let stage = fm.temporaryDirectory.appendingPathComponent("sfxbake-\(UUID().uuidString)")
        try fm.createDirectory(at: stage.appendingPathComponent("sfx"), withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: stage) }
        var staged: [String] = [], reports: [SfxFileReport] = []
        for r in recipes.recipes {
            let (pcm, report) = try normalise(SfxSynth.render(r, constants: recipes.synth), recipe: r)
            let url = stage.appendingPathComponent(r.path)
            try VoiceBake.encode(pcm, to: url)
            let decoded: AVAudioFile
            do { decoded = try AVAudioFile(forReading: url) } catch { throw VoiceBakeError(file: r.path, reason: "cannot decode the encoded file: \(error)") }
            let seconds = Double(decoded.length) / decoded.processingFormat.sampleRate
            if seconds > maxSeconds { throw VoiceBakeError(file: r.path, reason: "decoded length \(seconds) s is over \(maxSeconds) s (V12)") }
            staged.append(r.path); reports.append(report)
        }
        let prov = "sfx/provenance.json"
        try Data(provenance(recipesData: data, files: reports)).write(to: stage.appendingPathComponent(prov))
        staged.append(prov)
        for rel in staged {
            let dest = themeDir.appendingPathComponent(rel)
            try fm.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
            if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }
            try fm.copyItem(at: stage.appendingPathComponent(rel), to: dest)
        }
        return (staged.sorted(), reports)
    }
}
