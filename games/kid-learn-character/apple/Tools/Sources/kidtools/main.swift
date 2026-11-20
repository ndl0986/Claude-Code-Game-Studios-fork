// kidtools: the build-time command line (ADR-0002 Validation 4, ADR-0003).
//
//   kidtools api-surface <symbol-graph-dir> <module> <out.md>   write a module's public API surface
//   kidtools api-surface --check <symbol-graph-dir> <module> <file.md>   exit 1 if <file.md> is stale
//   kidtools validate <content-dir> [--load] [--release]   V1–V18 over every theme plus the staleness stub (ADR-0003
//        D3); exit 1 on any finding. --load drops the build-only singleItemPerKey check (V2). A theme folder holding
//        only src/ is a theme in progress: NOT ASSESSED, not a finding; --release exits 1 on any (TASK-125).
//   kidtools bake <content-dir>   bake every theme's src/art/*.svg to cast/*.json and src/sil/*.svg to sil/*.json (the D4 SVG
//        subset, byte-stable output, ADR-0003 D4); a rejected SVG names element, attribute and line, writes nothing, and
//        makes the command exit 1. Skipped for now: the check that the family's idle part names exist (no idle data yet).
//   kidtools bake-glyphs <content-dir>   bake content/fonts/Fredoka-wdth-wght.ttf at wght 600 (CoreText) into
//        content/glyphs/fredoka600/: glyph_fredoka_<char>.json for the 36 keys A–Z, 0–9 plus glyphs.json (morph-v1 path
//        subset, byte-stable, ADR-0003 D4). A key with no glyph names the key and the font file, writes nothing, exit 1.
//   kidtools bake-voice <content-dir> [--python <path>] [--helper <path>]   render every voice line of each theme that has a
//        theme.json with Kokoro (K-41, out of process via tts/kokoro_render.py, build Mac only) and encode AAC mono 48 kHz
//        64 kbit/s to themes/<id>/voice/<locale>/vo_<locale>_<kind>_<id>.m4a, plus voice/<locale>/provenance.json
//        (ADR-0003 D5/D6). The interpreter is --python or $KIDTOOLS_PYTHON; --helper overrides the helper script.
//        Nothing is written unless every line renders. Loudness and voiceDurations are story 004.
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
    for f in r.findings { print(f) }
    for t in r.inProgress { print("NOT ASSESSED theme \(t): in progress (src/ only, no theme.json yet)") }
    let releaseBlocked = r.pass && !r.passes(release: release)
    let verdict = !r.pass ? "FAIL" : (releaseBlocked ? "FAIL (release: \(r.inProgress.count) theme(s) in progress)" : "PASS")
    print("validate: \(r.themes.count) theme(s)\(r.themes.isEmpty ? "" : " (" + r.themes.joined(separator: ", ") + ")"), \(r.inProgress.count) in progress, \(r.findings.count) finding(s): \(verdict)")
    exit(r.passes(release: release) ? 0 : 1)
case "bake":
    guard args.count == 2 else { fail("usage: kidtools bake <content-dir>") }
    let r = SVGBake.bakeContent(contentDir: URL(fileURLWithPath: args[1]))
    for f in r.baked { print("baked \(f)") }
    for f in r.failures { print("REJECTED \(f)") }
    print("bake: \(r.baked.count) file(s) baked, \(r.failures.count) rejected; skipped: the check that every part the family's idle names exists (no idle data yet)")
    exit(r.failures.isEmpty ? 0 : 1)
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
        for t in r.skipped { print("skipped theme \(t): no theme.json (in progress)") }
        print("bake-voice: \(r.written.count) file(s) baked, \(r.skipped.count) theme(s) skipped")
    } catch {
        print("REJECTED \(error)"); exit(1)
    }
default:
    fail("unknown command \(cmd)")
}
