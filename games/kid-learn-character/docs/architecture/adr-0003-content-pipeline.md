# ADR-0003: Content data and the key-table pipeline

## Status

Proposed

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**

## Date

2026-11-18

## Last Verified

2026-11-18, against ADR-0001 (Accepted) §6 and §8, ADR-0002 (Accepted) D1, D2 and D6, ADR-0004 (Accepted),
morph-contract-v1 §2, §7 and §8, Key Table & Theme Data §2, §4–§6 and V1–V17, Cast Rendering R2, R7, R10 and R11,
Audio & Voice R8, A3, A7, F4 and Q8, Privacy & Kids Compliance PKC-03 and L-09, the art bible §8, and decisions
K-13, K-29, K-31 and K-32.

## Decision Makers

Luan (accepts; decided K-31 and K-32); game-dev-android (author, TASK-066); game-art-content (plan and independent
review, content owner); game-leader.

## Summary

Every letter's creature, sound and voice comes from bundled content files that both the Apple app and the later
Android app read unchanged. This ADR fixes where those files live and which ones ship, the theme format (schema v2),
one validator that gates the build and runs again at theme load, our own build tools that bake SVG art, silhouettes
and glyphs into the morph path format and check every audio file, how voice durations and loudness are measured,
an engine-agnostic text-to-speech step whose engine and licence stay open (L-09), and JSON decoding at the edge only.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | None from the template's table (`engine.name` unset, ADR-0001, K-28). Swift 6.4, Xcode 27.1, macOS 27 for Tools |
| **Domain** | Content pipeline (Tools) and data (`KidCore`) |
| **Layer** | Foundation (data, validator); build time (Tools) |
| **Knowledge Risk** | LOW for the data model and validator (plain Swift, ADR-0002 types). HIGH for three Tools APIs: `CTFontCreatePathForGlyph`, the AAC priming/padding values from `AVAudioFile` / `AVAudioConverter`, and `AVAudioConverter` AAC encoding settings (NOT SOURCEABLE until a build proves them; Risks) |
| **References Consulted** | `docs/engine-reference-local/native-apple/` (`VERSION.md`, `modules/avfaudio.md`); morph-contract-v1; ITU-R BS.1770; EBU Tech 3341 |
| **Post-Cutoff APIs Used** | Only in Tools (CoreText, AVFoundation, Foundation XMLParser); none in `KidCore` |
| **Verification Required** | Validation Criteria 1–10 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Accepted), ADR-0002 (Accepted: types, decoding at the edge, new seams by ADR), ADR-0004 (Accepted: the contracts named below), morph-contract-v1 |
| **Enables** | ADR-0009 (the SVG render path reads D4's baked files); ADR-0010 (audio engine reads D5's files); the content stories; ADR-0012 (Android reuses D1's files) |
| **Blocks** | Any story that adds or bakes content, and the theme-load story |
| **Ordering Note** | After ADR-0004, because its validator's cases are contract cases |

**Contracts this ADR uses, not restates (ADR-0004):** `key-table-schema-v1` (validator verdicts V1–V17, the §4
pick), `keyboard-row-v1` (the word draw; V17's verdicts live in key-table-schema-v1), and `morph-contract-v1` (the
path parser and its fixture).

## Context

### Problem Statement
The game is data: 36 keys per theme, each with art, a silhouette path, a sound and voice lines, plus glyph paths
for every key. Without one decided pipeline, each platform would bake, check and load content its own way, and a
bad file could reach a child (Key Table §5 says a theme that fails is never shown).

### Current State
Key Table & Theme Data §2 defines the format (schema v2, merged in TASK-060). morph-contract-v1 defines the path
subset and its fixture, with two glyphs baked by TASK-033's `tools/bake-glyph.swift`. There is no bake tool for art
or silhouettes, no validator code, and no audio pipeline.

### Constraints
- PKC-03: no third-party runtime in the app; build tools leave nothing in the bundle.
- K-31 (Luan): **own Swift build tools, no third-party build tools** (no ffmpeg, sox or SVG libraries).
- ADR-0002 D2: JSON is decoded at the edge; `KidCore` takes plain models.
- K-32 and Audio Q8: the TTS voice's licence must allow public distribution of the rendered audio in a kids' app,
  even though the app is free and has no ads (L-09, open).
- Android (later) cannot run Swift Tools.

### Requirements
- One set of V-rules, run at build and at load, with the same verdicts.
- Baked outputs identical on every machine and committed, so Android uses the same files.
- Every audio file measured and checked before it ships.

## Decision

### D1. Layout under `content/` (S = shipped in the bundle, B = build-only)
```
content/
  themes/<id>/                      id = folder = Settings Store themeId (Dinosaurs: themes/dinosaurs/)
    theme.json                      S
    src/art/cast_<prefix>_….svg     B  layered source (art bible §8)
    src/sil/sil_<prefix>_….svg      B  the artist's silhouette export (art bible §8)
    src/voice-scripts/              B  TTS scripts and render settings
    cast/cast_<prefix>_….json       S  baked art: the only art form the app reads (Cast Rendering R2)
    cast/<stem>/<part>@<tier>.png   S  only if ADR-0009 chooses Cast Rendering R11 option B (PNG tiers per part)
    sil/sil_<prefix>_….json         S  baked morph-v1 silhouette
    sfx/                            S
    voice/<locale>/                 S
  glyphs/<set>/                     S  glyphs.json + glyph_<font>_<char>.json
  fonts/                            S  the OFL font file and OFL.txt (panel text, hint letters, keyboard row keys, queue tokens)
  data/                             S  timing and knob files (morph timing, cast idles, queue, hints, row, scene, gate)
  fixtures/                         B  contract fixtures (ADR-0004), never shipped
```
- File names use the theme's **`assetPrefix`** (Dinosaurs: `dino`), a new Key Table field (follow-up for
  game-art-content; no schema bump, since v2 has not shipped).
- Paths are relative, lowercase, with forward slashes, and must exist in **exact case** (macOS file systems are
  case-insensitive; Android assets are not).
- An item's `art` field names the baked `cast/…json`. Its SVG source is found by rule: `src/art/` plus the same
  file stem (`.svg`). Its silhouette source likewise: `src/sil/` plus the stem of `silhouette`. (Key Table §2b, V6
  and V7 follow-up for game-art-content.)

### D2. Theme schema v2
- The format is Key Table §2 as merged: `rowWords` (V17), `titleCastId` (V16), `voiceDurations` (V15), plus
  `assetPrefix` (D1).
- **Unknown fields fail the same way at build and at load**: a V1 failure. At build the build fails; at load the
  theme is not used and the Dinosaurs fallback applies (Key Table §5).
- An unknown major `schemaVersion` is refused (V1). A v1 theme still loads, with the `rowWords` fallback (FOSSIL,
  else ABC; Key Table Edge Cases).

### D3. One validator, two runners
- The V-rules are written **once, in `KidCore`**, as pure functions over the decoded models (D7) and one injected
  seam added by this ADR (ADR-0002 D6 says new seams come by ADR):
  ```
  protocol ContentProbe {
    func exists(_ path: String) -> Bool          // exact case
    func byteSize(_ path: String) -> Int64?
    func decodedDuration(_ path: String) -> Double?   // seconds, AAC priming and padding removed
  }
  ```
- **Tools** runs the validator at build with a file-system probe. Any failure fails the build and names the theme,
  the rule and the item.
- **The app** runs the same validator at theme load, off the main thread, with a bundle probe (Key Table §5). A
  failing theme is never shown.
- **Build-only checks**, in Tools only: the SVG subset and structure (D4), the silhouette raster check (D4), the
  baked-output staleness check (D4), loudness and true peak (D5), and V15's measured durations (D5).
- Its case set is `key-table-schema-v1`; the Kotlin mirror runs the same cases (ADR-0004).

### D4. The bake tool (Tools; own Swift code, no third-party libraries; K-31)

**Art: the SVG subset (Cast Rendering R2), checked in three layers, then a structure check.**
1. **Elements allowed:** `svg`, `g`, `path`, `circle`, `ellipse`, `rect`, `line`, `polyline`, `polygon`.
   **Ignored and never baked** (normal export noise): `<title>`, `<desc>`, `<metadata>`, and an **empty**
   `<defs>`. **Rejected:** anything inside `<defs>`, and `use`, `symbol`, `pattern`, `mask`, `clipPath`,
   `filter`, any gradient, `text`, `image`, `foreignObject`, and any element not listed.
2. **Attributes allowed, per element:** `d` and the geometry attributes of each shape, `fill`, `fill-opacity`,
   `stroke`, `stroke-width`, `stroke-linejoin` and `stroke-linecap` (value `round` only), `opacity` on `g`,
   `transform`, `id` (part and layer names), and `data-pivot` (D4 structure). The `xmlns`, `version`, `width`,
   `height` and `viewBox` attributes of the root `svg`. **Rejected:** `style`, `class`, and every other
   attribute.
3. **Values:** colours are hex (`#rgb`, `#rrggbb`) or `rgb(r, g, b)`, or **`none`** for `fill` and `stroke` (the
   outline layer is usually stroke-only). **Rejected:** any `url(#…)` paint, named colours other than `none`,
   `currentColor`. Transforms are `translate`, `rotate` and `scale` only; **rejected:** `skewX`, `skewY`, and any
   `matrix` with a skew component (a matrix that is only translate, rotate and uniform or axis scale is
   accepted and decomposed). Lengths are plain numbers (no units, no percentages).
4. **Structure:** each part group (`id` = the part name used in the Cast Rendering data, e.g. `root`, `neck`,
   `head`) holds the three layer groups `body`, `outline` and `detail` (art bible §8), and every part that the
   family's idle data moves carries a pivot as **`data-pivot="x y"`** in artboard units (a `data-*` attribute, so
   the file stays valid SVG). A missing layer group, a missing part the family's idle names, or a part without its
   pivot fails the bake (Cast Rendering R2, R7).

Every rejection names the element, the attribute and the line. The Letter Gold glyph gradient is the only gradient
in the game; it lives in the glyph renderer (Cast Rendering R4), never in cast art. The bake parses with Foundation
`XMLParser`, converts shapes and arcs into `M L H V C Q Z`, applies transforms, and writes the cast JSON (parts,
pivots, layers, paths, fills and strokes, in artboard units).

**Silhouettes** (morph-contract-v1 §8):
- flattened to the **morph-v1 subset only**: arcs and `S`/`T` converted to `C`/`Q`, transforms applied, plain
  decimal numbers, and an `M` after every `Z`; it must parse with the v1 parser and pass V8;
- baked at the **idle rest pose** (Cast Rendering R7, phase 0);
- several pieces (the number babies, the empty nest) are **subpaths of one compound path**;
- **raster check** at artboard scale (1 px = 1 unit): the silhouette is compared with the art's body and outline at
  rest, including the outer half of the 6-unit outline stroke; it passes when the symmetric difference of the two
  fills lies within a 1 px band along the edge.

**Glyphs:**
- The CoreText baker (`CTFontCreatePathForGlyph`) turns the bundled Fredoka 600 (OFL 1.1) into the same subset,
  recording font name, version and licence next to each file (contract §7, §8). It replaces TASK-033's
  `tools/bake-glyph.swift` for the shipped glyph set.
- **morph-contract-v1 keeps its own committed inputs** (`glyph-D.json`, `glyph-3.json` as they are), and
  `morph-contract-v1.json` never changes. The shipped glyph set is checked by V8 and V9, not against the contract
  fixture.

**Committed, reproducible outputs:**
- The artist edits `src/…svg`, runs one bake command, and commits the source and the baked files together.
- Output is byte-stable: sorted keys, a fixed decimal format (up to 3 decimals, no exponent, no trailing zeros), LF
  line endings, and the tool name and version recorded in each file.
- A build check re-bakes in memory and **fails if any committed baked file differs** from its source's bake. It
  also **re-measures `voiceDurations`**, the one tool-written field in `theme.json` (never edited by hand; D5),
  and fails if any committed value differs from the measured one.
- Android, which cannot run Swift Tools, uses the same committed files (D9).

### D5. Voice durations and loudness (Audio A7, F4; Key Table V15)
- **Durations:** each voice line's decoded duration, with the AAC encoder priming and end padding removed (V15,
  ±0.01 s), measured in Tools with `AVAudioFile` / `AVAudioConverter` (NOT SOURCEABLE until a build proves the
  priming handling; Risks), written into `theme.json`'s `voiceDurations` with D4's stable formatting.
- **Loudness:** ITU-R BS.1770 in Swift (K-31), from the published K-weighting filter and gating:
  - integrated loudness (LUFS) and true peak (dBTP, 4× oversampled) for files of **0.4 s or longer**;
  - the **momentary maximum** (400 ms window) for files **shorter than 0.4 s** (Audio F4);
  - each file within **±1 LU** of its class target and at or below the true-peak ceiling (Audio F4, A7), or the
    build fails;
  - the meter itself is checked against the **EBU Tech 3341** reference signals within **±0.1 LU**.
- **Encoding:** mono AAC `.m4a` via AVFoundation in Tools (K-31). Every `sfx` is checked ≤ 2.0 s (V12).

### D6. TTS pre-render (K-13): engine-agnostic
- The pipeline: script (Key Table `say` / `word`) → engine adapter → WAV → normalise (D5 target) → AAC (D5) →
  `voiceDurations` (D5). File names are the line ids (Key Table §2), the same as a human re-record, so a later
  recording replaces files only.
- **The engine and its licence are open (L-09).** The licence must allow **public distribution of the rendered
  audio in a kids' app**, even though the app is free with no ads (K-32; Audio & Voice Q8). No engine is wired into
  the build until Luan decides. Until then, **placeholder** voice files go through D5 unchanged, so V15 and the
  loudness checks are proven with any files.

### D7. Decoding at the edge (ADR-0002 D2)
- JSON decoding lives only in `<App>` and Tools (`JSONSerialization` or `Codable`). `KidCore` receives plain
  models: `Theme`, `KeyEntry`, `Item`, `GlyphSet`, the knob data, under ADR-0002's type rules (String keys, `Double`
  numbers, `Int` within 32 bits).
- Durations are `Double` (3 decimals); weights are `Double`.
- A decode error is a theme failing V1 or V2, never a crash.

### D8. What ships, and what stays build-only (PKC-03)
- Only D1's S files ship: data, baked JSON, audio, the font and its licence.
- `src/`, SVGs, scripts, WAV intermediates, reports, fixtures and every tool never ship.
- The bundle holds no third-party runtime code. The PKC-03 bundle scan checks all of this.

### D9. Android (for ADR-0012)
- The same committed content files, byte-identical, go into `assets/`.
- A Kotlin decoder at the edge produces the same plain models; the `KidCore`-mirror validator runs the same
  `key-table-schema-v1` cases with an asset `ContentProbe` (exact case).
- Android never bakes or renders TTS; the staleness check runs on the Apple build.

### Architecture Diagram
```
src/*.svg ──bake (Tools)──▶ cast/*.json, sil/*.json ─┐
font (OFL) ──CoreText bake──▶ glyphs/*.json ─────────┤
scripts ──TTS adapter (open, L-09)──▶ WAV ──normalise/AAC──▶ voice/*.m4a ─┤──▶ committed content/ (S files)
                                     measure ──▶ theme.json voiceDurations ┘        │
                                                                                     ▼
                           Tools: validator (KidCore) + build-only checks ──▶ build passes or fails
                           App:   JSON decode (edge) ──▶ KidCore models ──▶ validator (bundle probe) ──▶ theme shown or fallback
```

### Key Interfaces
`ContentProbe` (D3, new); the plain models of D7; the V-rule functions (their verdicts are `key-table-schema-v1`).

### Implementation Guidelines
- The V-rules **must** exist only in `KidCore`; Tools and the app call them, never copy them.
- Tools **must** use only Apple frameworks and our own code (K-31).
- Baked files **must** be committed with their sources, and **must** be byte-stable.
- The app **must never** decode JSON inside `KidCore`, and **must never** read `src/`.

## Alternatives Considered

### Alternative 1: Bake at build time, outputs not committed
- **Description**: the Xcode build runs the bake; baked files are build products.
- **Pros**: no generated files in git.
- **Cons**: Android cannot run Swift Tools, so it would need its own baker; outputs could differ by machine.
- **Rejection Reason**: one set of files for both platforms matters more.

### Alternative 2: Third-party tools (ffmpeg, an SVG library)
- **Description**: use existing tools for loudness, encoding and SVG parsing.
- **Pros**: less of our own code.
- **Cons**: licences and supply chain in the build.
- **Rejection Reason**: Luan's call, K-31.

### Alternative 3: Separate validators for build and load
- **Description**: a Tools validator and a lighter app check.
- **Pros**: each fits its runner.
- **Cons**: two rule sets drift, and the app might accept what the build would reject.
- **Rejection Reason**: Key Table §5 asks for the same check at build and load.

## Consequences

### Positive
- One file set and one rule set on both platforms; a bad theme cannot ship and cannot be shown.
- Content changes are reviewable diffs (source and baked file together).

### Negative
- More Tools code: SVG parsing, arc conversion, BS.1770, the raster check.
- Generated files in git; the staleness check is needed to keep them honest.

### Neutral
- The TTS engine is not decided; placeholders keep the pipeline testable.

## Risks
- **AAC priming and padding values are NOT SOURCEABLE.** If `AVAudioFile` does not report them as expected, V15's
  durations are off by ~44 ms. Mitigation: Validation 7 with a file of known priming; a build proves it before any
  voice ships.
- **CoreText glyph outlines** may differ between macOS versions. Mitigation: the baked files are committed (D4), so
  a different macOS only shows up as a staleness diff, never as a silent change.
- **SVG exports vary by tool.** Mitigation: the ignored-noise list (D4) and named rejections; the artist re-exports
  with the subset.
- **L-09 stays open past the MVP.** Mitigation: placeholders; the release checklist blocks on L-09.

## GDD Requirements Addressed

TR-IDs are provisional (architecture.md baseline).

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| key-table-theme-data.md §2, §5, §6 | TR-keytable-001: themes validated at build and at load; unknown versions refused | D2, D3 (one validator, `ContentProbe`) |
| key-table-theme-data.md V15 | voice durations from data, never from playback | D5 |
| key-table-theme-data.md V17, onscreen-keyboard-row.md R2 | `rowWords` valid; v1 fallback | D2; key-table-schema-v1 |
| cast-rendering.md R2, R7, R11 | TR-cast-001: SVG subset → baked file; one form for both render options | D1 (option B room), D4 |
| morphcore.md, morph-contract-v1 §7, §8 | TR-morph-001: paths in the v1 subset; fixture unchanged | D4 (silhouettes, glyphs, contract inputs kept) |
| audio-voice.md R8, A3, A7, F4, Q8 | the TTS pipeline; loudness targets; durations | D5, D6 |
| privacy-kids-compliance.md PKC-03, L-09 | no third-party runtime; the voice licence | D8, D6 |

## Performance Implications
- **CPU**: theme validation at load is off the main thread; a few milliseconds for 36 keys.
- **Memory**: negligible for the models; audio and textures are Audio's and Cast Rendering's.
- **Load Time**: one validation pass per theme load.
- **Network**: none (PKC-01); the TTS adapter, if it ever uses a network engine, runs at build time only, and that
  engine choice is Luan's (L-09).

## Migration Plan
- Move the Dinosaurs placeholder content into `content/themes/dinosaurs/` with `assetPrefix: "dino"` (the
  content story).
- TASK-033's `tools/bake-glyph.swift` is replaced by the CoreText baker for the shipped glyph set; the contract's
  inputs stay.

## Validation Criteria
1. Every planted V-rule break fails both runners with the same verdict (`key-table-schema-v1` cases, including V17
   and the new `assetPrefix` rules).
2. The bake rejects each forbidden element, attribute and value (`style`, `class`, `use`, `symbol`, `pattern`, a
   gradient, content in `<defs>`, `url(#…)`, `skewX`, a skewed `matrix`, `text`, `image`), each named with its line
   (Cast Rendering AC-4); an export with `<title>`, `<desc>`, `<metadata>` and an empty `<defs>` bakes; `fill="none"`
   and `stroke="none"` bake.
3. A missing layer group, a missing idle part or a missing `data-pivot` fails the bake.
4. Two bake runs give byte-identical outputs; an edited SVG fails the staleness check.
5. The silhouette raster check passes for the Dinosaurs placeholder and fails on a test silhouette shifted 2 px.
6. A planted wrong-case path fails both runners; an unknown field fails at build and at load, and the app uses the
   fallback.
7. V15: a test file with known priming measures within ±0.01 s.
8. Loudness: the EBU Tech 3341 signals measure within ±0.1 LU; a 0.3 s file is measured by its momentary maximum.
9. The bundle scan finds no `src/`, no `.svg`, no fixtures and no tool.
10. morph-contract-v1 passes with its own inputs, unchanged.

## Related
- `docs/architecture/architecture.md`; ADR-0001, ADR-0002, ADR-0004; morph-contract-v1.
- `design/gdd/key-table-theme-data.md`, `cast-rendering.md`, `audio-voice.md`, `privacy-kids-compliance.md`,
  `onscreen-keyboard-row.md`.
- Decisions K-13, K-29, K-31, K-32; Luan's open call L-09.
- Follow-ups for game-art-content (Key Table): `assetPrefix` and its V-rules; `art` naming the baked `cast/…json`
  with the SVG found by rule; id = folder = themeId `dinosaurs`.
