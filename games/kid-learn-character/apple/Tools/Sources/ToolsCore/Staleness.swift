import AVFoundation
import CryptoKit
import Foundation
import KidCore

// MARK: theme.json write-back

/// The one tool-written part of `theme.json`: `voiceDurations` (ADR-0003 D4). Nobody hand-edits it.
public enum ThemeFile {
    /// `bytes` with the top-level `voiceDurations` object replaced by `durations` (locale → line id → seconds, sorted keys,
    /// 3 decimals, the D4 stable formatting). Every other byte of the file is kept: the object is located by a string-aware
    /// scan, not by re-serialising the file. Continuation lines of the new object are indented like the key's line.
    /// Throws a `VoiceBakeError` naming `theme.json` when the key or its object is not found.
    ///
    /// Example:
    /// ```swift
    /// let out = try ThemeFile.replacingVoiceDurations(in: bytes, with: ["en-us": ["letter_a": 0.512]])
    /// ```
    public static func replacingVoiceDurations(in bytes: [UInt8], with durations: [String: [String: Double]]) throws -> [UInt8] {
        func bad(_ r: String) -> VoiceBakeError { VoiceBakeError(file: "theme.json", reason: r) }
        let n = bytes.count
        func skipSpace(_ i: Int) -> Int { var j = i; while j < n, [0x20, 0x09, 0x0A, 0x0D].contains(bytes[j]) { j += 1 }; return j }
        func endOfString(_ open: Int) -> Int? {   // index of the closing quote
            var j = open + 1
            while j < n { if bytes[j] == 0x5C { j += 2; continue }; if bytes[j] == 0x22 { return j }; j += 1 }
            return nil
        }
        var depth = 0, i = 0
        var range: Range<Int>?
        scan: while i < n {
            switch bytes[i] {
            case 0x22:
                guard let close = endOfString(i) else { throw bad("unterminated string") }
                if depth == 1, String(decoding: bytes[(i + 1)..<close], as: UTF8.self) == "voiceDurations" {
                    let colon = skipSpace(close + 1)
                    if colon < n, bytes[colon] == 0x3A {
                        let v = skipSpace(colon + 1)
                        guard v < n, bytes[v] == 0x7B else { throw bad("voiceDurations is not an object") }
                        var d = 0, j = v
                        while j < n {
                            if bytes[j] == 0x22 { guard let c = endOfString(j) else { throw bad("unterminated string") }; j = c }
                            else if bytes[j] == 0x7B || bytes[j] == 0x5B { d += 1 }
                            else if bytes[j] == 0x7D || bytes[j] == 0x5D { d -= 1; if d == 0 { range = v..<(j + 1); break scan } }
                            j += 1
                        }
                        throw bad("voiceDurations object is not closed")
                    }
                }
                i = close + 1
            case 0x7B, 0x5B: depth += 1; i += 1
            case 0x7D, 0x5D: depth -= 1; i += 1
            default: i += 1
            }
        }
        guard let r = range else { throw bad("no top-level voiceDurations key") }
        var lineStart = r.lowerBound
        while lineStart > 0, bytes[lineStart - 1] != 0x0A { lineStart -= 1 }
        let indent = String(decoding: bytes[lineStart..<r.lowerBound].prefix { $0 == 0x20 || $0 == 0x09 }, as: UTF8.self)
        var text = durations.isEmpty ? "{}" : String(decoding: JSONValue.object(durations.mapValues { lines in
            JSONValue.object(lines.mapValues { .number($0) })
        }).render(), as: UTF8.self)
        if text.hasSuffix("\n") { text.removeLast() }
        text = text.replacingOccurrences(of: "\n", with: "\n" + indent)
        return Array(bytes[..<r.lowerBound]) + Array(text.utf8) + Array(bytes[r.upperBound...])
    }
}

// MARK: Staleness

/// The build-only staleness check on baked audio (ADR-0003 D3, D4; story 004). Pure reads; thread-safe.
///
/// - **sfx:** every recipe in `src/sfx/recipes.json` is re-rendered in memory with `SfxBake` and its CAF bytes compared with
///   the committed `sfx/sfx_<castId>.caf` (byte-stable under K-52). Any difference, or a missing file, is stale.
/// - **voice:** Kokoro cannot run in `validate`, so each line's render INPUTS are hashed instead (`VoiceBake.inputHash`) and
///   compared with `inputSha256` in `voice/<locale>/provenance.json`; the committed file's SHA-256 is compared with
///   `fileSha256`; and `theme.json`'s `voiceDurations` is re-measured against the files (exact to 3 decimals, as the tool writes it).
///
/// A theme without `src/sfx/recipes.json` (or without `src/voice-scripts/<locale>.json`) has no source to be stale
/// against: that part is skipped, as the ContentValidator's other source checks are.
public enum Staleness {
    /// One message per stale file or line, naming it. Empty when nothing is stale.
    ///
    /// Example:
    /// ```swift
    /// let msgs = Staleness.check(themeDir: dir, theme: model)   // ["sfx/sfx_dino_a_01.caf: differs from a re-render of src/sfx/recipes.json"]
    /// ```
    public static func check(themeDir: URL, theme: ThemeModel) -> [String] {
        var out: [String] = []
        let fm = FileManager.default
        // sfx
        let recipesLabel = "src/sfx/recipes.json"
        if let data = fm.contents(atPath: themeDir.appendingPathComponent(recipesLabel).path) {
            do {
                let recipes = try SfxRecipes.parse(data, label: recipesLabel)
                for r in recipes.recipes {
                    guard let have = fm.contents(atPath: themeDir.appendingPathComponent(r.path).path) else {
                        out.append("\(r.path): missing (recipe \(r.castId) in \(recipesLabel))"); continue
                    }
                    do {
                        if try SfxBake.renderedBytes(recipe: r, constants: recipes.synth) != have {
                            out.append("\(r.path): differs from a re-render of \(recipesLabel)")
                        }
                    } catch { out.append("\(r.path): cannot re-render: \(error)") }
                }
            } catch { out.append("\(recipesLabel): \(error)") }
        }
        // voice
        for loc in theme.voiceLocales {
            let label = "src/voice-scripts/\(loc).json"
            guard let data = fm.contents(atPath: themeDir.appendingPathComponent(label).path) else { continue }
            let script: VoiceScript, lines: [VoiceBake.Line]
            do { script = try VoiceScript.parse(data, label: label); lines = try VoiceBake.lines(theme: theme, script: script) }
            catch { out.append("\(label): \(error)"); continue }
            let provLabel = "voice/\(loc)/provenance.json"
            guard let pdata = fm.contents(atPath: themeDir.appendingPathComponent(provLabel).path),
                  let po = (try? JSONSerialization.jsonObject(with: pdata)) as? [String: Any] else {
                out.append("\(provLabel): missing or not JSON (voice not baked)"); continue
            }
            let perLine = (po["perLine"] as? [String: Any]) ?? [:]
            for line in lines {
                let rel = KeyTable.voicePath(loc, line.kind, line.id)
                let rec = perLine[line.lineId] as? [String: Any]
                if rec == nil { out.append("\(rel): line \(line.lineId) is not in \(provLabel)") }
                else if (rec?["inputSha256"] as? String) != VoiceBake.inputHash(line: line, script: script) {
                    out.append("\(rel): stale, line \(line.lineId) inputs (text, engine, trim or tool version) changed since the bake")
                }
                guard let bytes = fm.contents(atPath: themeDir.appendingPathComponent(rel).path) else { out.append("\(rel): missing"); continue }
                if let rec, (rec["fileSha256"] as? String) != SHA256.hash(data: bytes).map({ String(format: "%02x", $0) }).joined() {
                    out.append("\(rel): stale, the file differs from the one the bake wrote")
                }
                if let f = try? AVAudioFile(forReading: themeDir.appendingPathComponent(rel)) {
                    let m = (Double(f.length) / f.processingFormat.sampleRate * 1000).rounded() / 1000
                    if let d = theme.voiceDurations[loc]?[line.lineId], abs(d - m) > 0.0005 {
                        out.append("\(rel): stale voiceDurations \(d) s, measured \(m) s (re-bake writes it)")
                    }
                }
            }
        }
        return out
    }
}
