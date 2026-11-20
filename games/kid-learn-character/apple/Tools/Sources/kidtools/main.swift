// kidtools: the build-time command line (ADR-0002 Validation 4, ADR-0003).
//
//   kidtools api-surface <symbol-graph-dir> <module> <out.md>   write a module's public API surface
//   kidtools api-surface --check <symbol-graph-dir> <module> <file.md>   exit 1 if <file.md> is stale
//   kidtools validate <content-dir> [--load] [--release]   V1–V18 over every theme plus staleness (src sources, sfx re-render, voice input hashes; ADR-0003
//        D3); exit 1 on any finding. --load drops the build-only singleItemPerKey check (V2). A theme folder holding
//        only src/ is a theme in progress: NOT ASSESSED, not a finding; --release exits 1 on any (TASK-125).
//   kidtools bake <content-dir>   bake every theme's src/art/*.svg to cast/*.json and src/sil/*.svg to sil/*.json (the D4 SVG
//        subset, byte-stable output, ADR-0003 D4); a rejected SVG names element, attribute and line, writes nothing, and
//        makes the command exit 1. With --idle <file> (provisional idle data, OQ-1) it also checks every part a family's idle moves exists with a pivot; without it that check prints NOT ASSESSED.
//   kidtools bake-glyphs <content-dir>   bake content/fonts/Fredoka-wdth-wght.ttf at wght 600 (CoreText) into
//        content/glyphs/fredoka600/: glyph_fredoka_<char>.json for the 36 keys A–Z, 0–9 plus glyphs.json (morph-v1 path
//        subset, byte-stable, ADR-0003 D4). A key with no glyph names the key and the font file, writes nothing, exit 1.
//   kidtools bake-voice <content-dir> [--python <path>] [--helper <path>]   render every voice line of each theme that has a
//        theme.json with Kokoro (K-41, out of process via tts/kokoro_render.py, build Mac only) and write CAF LPCM 16-bit mono 48 kHz (K-52)
//        to themes/<id>/voice/<locale>/vo_<locale>_<kind>_<id>.caf, plus voice/<locale>/provenance.json
//        (ADR-0003 D5/D6). The interpreter is --python or $KIDTOOLS_PYTHON; --helper overrides the helper script.
//        Nothing is written unless every line renders. Each line is silence-trimmed (src/voice-scripts trim data),
//        normalised to -16 LUFS, then a lookahead true-peak limiter (src/voice-scripts limiter data; a WARNING line per
//        line reduced more than warnReductionDB), clip guard, true peak <= -1 dBTP, and the A7 gate re-run on the decoded file, and its decoded length is written into theme.json's
//        voiceDurations (only that object is replaced); provenance.json records input and file hashes for validate's staleness check.
//   kidtools bake-sfx <theme-dir>   render src/sfx/recipes.json (the prototype's synth recipes as data) to
//        <theme-dir>/sfx/sfx_<castId>.caf (16-bit LPCM CAF, mono, 48 kHz, via the voice bake's encoder; K-52), each normalised to
//        -20 LUFS (momentary max under 0.4 s) with true peak <= -1 dBTP by the D5 meter, plus sfx/provenance.json
//        (ADR-0003 D5, story 007). A file over 2.0 s or over the true-peak ceiling names itself and nothing is written.
import Foundation
import ToolsCore

func fail(_ s: String) -> Never { FileHandle.standardError.write(Data((s + "\n").utf8)); exit(2) }

let args = Array(CommandLine.arguments.dropFirst())
guard let cmd = args.first else { fail("usage: kidtools api-surface [--check] <symbol-graph-dir> <module> <file.md>") }

switch cmd {
case "api-surface":
    var rest = Array(args.dropFirst()), check = false
    if rest.first == "--check" { check = true; rest.removeFirst() }
    guard rest.count == 3 else { fail("usage: kidtools api-surface [--check] <symbol-graph-dir> <module> <file.md>") }
    let text: String
    do { text = try APISurface.render(symbolGraphDir: rest[0], module: rest[1]) } catch { fail("api-surface: \(error)") }
    let path = rest[2]
    if check {
        let old = (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
        if old != text { print("STALE \(path): regenerate with kidtools api-surface"); exit(1) }
        print("OK \(path)")
    } else {
        do { try text.write(toFile: path, atomically: true, encoding: .utf8) } catch { fail("write \(path): \(error)") }
        print("wrote \(path)")
    }
case "validate":
    var rest = Array(args.dropFirst()), load = false, release = false
    if let i = rest.firstIndex(of: "--load") { load = true; rest.remove(at: i) }
    if let i = rest.firstIndex(of: "--release") { release = true; rest.remove(at: i) }
    guard rest.count == 1 else { fail("usage: kidtools validate <content-dir> [--load] [--release]") }
    let r = ContentValidator.run(contentDir: URL(fileURLWithPath: rest[0]), singleItemPerKey: !load)
    let d = DataValidator.run(contentDir: URL(fileURLWithPath: rest[0]))
    for f in r.findings { print(f) }
    for f in d.findings { print("FAIL data \(f)") }
    for l in d.notAssessed { print(l) }
    for t in r.inProgress { print("NOT ASSESSED theme \(t): in progress (src/ only, no theme.json yet)") }
    for l in r.notAssessed { print(l) }
    let dataOK = d.findings.isEmpty
    let releaseBlocked = r.pass && dataOK && !r.passes(release: release)
    let verdict = !(r.pass && dataOK) ? "FAIL" : (releaseBlocked ? "FAIL (release: \(r.inProgress.count) theme(s) in progress)" : "PASS")
    print("validate: \(r.themes.count) theme(s)\(r.themes.isEmpty ? "" : " (" + r.themes.joined(separator: ", ") + ")"), \(r.inProgress.count) in progress, \(r.findings.count + d.findings.count) finding(s): \(verdict)")
    exit(r.passes(release: release) && dataOK ? 0 : 1)
case "bake":
    var rest = Array(args.dropFirst()), idle: URL? = nil
    if let i = rest.firstIndex(of: "--idle"), i + 1 < rest.count { idle = URL(fileURLWithPath: rest[i + 1]); rest.removeSubrange(i...(i + 1)) }
    guard rest.count == 1 else { fail("usage: kidtools bake <content-dir> [--idle <idle-data.json>]") }
    let content = URL(fileURLWithPath: rest[0])
    let r = SVGBake.bakeContent(contentDir: content)
    for f in r.baked { print("baked \(f)") }
    for f in r.failures { print("REJECTED \(f)") }
    let ip = IdlePartCheck.bakeStep(contentDir: content, idleFile: idle)
    for f in ip.failures { print("REJECTED idle-part: \(f)") }
    for l in ip.notAssessed { print(l) }
    print("bake: \(r.baked.count) file(s) baked, \(r.failures.count + ip.failures.count) rejected")
    exit(r.failures.isEmpty && ip.failures.isEmpty ? 0 : 1)
case "bake-glyphs":
    guard args.count == 2 else { fail("usage: kidtools bake-glyphs <content-dir>") }
    do {
        let written = try GlyphBake.bakeContent(contentDir: URL(fileURLWithPath: args[1]))
        for f in written { print("baked \(f)") }
        print("bake-glyphs: \(written.count) file(s) baked")
    } catch {
        print("REJECTED \(error)"); exit(1)
    }
case "bake-voice":
    var rest = Array(args.dropFirst()), python = ProcessInfo.processInfo.environment["KIDTOOLS_PYTHON"], helper: String?
    for (flag, set) in [("--python", { python = $0 }), ("--helper", { helper = $0 })] as [(String, (String) -> Void)] {
        if let i = rest.firstIndex(of: flag) {
            guard i + 1 < rest.count else { fail("bake-voice: \(flag) needs a value") }
            set(rest[i + 1]); rest.removeSubrange(i...(i + 1))
        }
    }
    guard rest.count == 1 else { fail("usage: kidtools bake-voice <content-dir> [--python <path>] [--helper <path>]") }
    guard let python else { fail("bake-voice: no interpreter: pass --python <path> or set KIDTOOLS_PYTHON (see apple/Tools/README.md)") }
    do {
        let r = try VoiceBake.bakeContent(contentDir: URL(fileURLWithPath: rest[0])) { script in
            KokoroProcessEngine(python: URL(fileURLWithPath: python),
                                helper: helper.map { URL(fileURLWithPath: $0) } ?? KokoroProcessEngine.defaultHelper, settings: script.engine)
        }
        for f in r.written { print("baked \(f)") }
        for w in r.warnings { print(w) }
        for t in r.skipped { print("skipped theme \(t): no theme.json (in progress)") }
        print("bake-voice: \(r.written.count) file(s) baked, \(r.skipped.count) theme(s) skipped, \(r.warnings.count) limiter warning(s)")
    } catch {
        print("REJECTED \(error)"); exit(1)
    }
case "bake-sfx":
    guard args.count == 2 else { fail("usage: kidtools bake-sfx <theme-dir>") }
    do {
        let r = try SfxBake.bakeTheme(themeDir: URL(fileURLWithPath: args[1]))
        for f in r.files {
            print(String(format: "baked %@  %.3f s  %@ %.2f LUFS (gain %+.2f dB)  %.2f dBTP  onsets %d", f.path, f.duration,
                         f.momentaryOnly ? "momentary max" : "integrated", f.loudnessAfter, f.gainDB, f.truePeakDBTP, f.onsets))
        }
        print("baked sfx/provenance.json")
        print("bake-sfx: \(r.files.count) sound(s) baked")
    } catch {
        print("REJECTED \(error)"); exit(1)
    }
default:
    fail("unknown command \(cmd)")
}
