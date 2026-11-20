# Story 007: Sfx bake: render the 36 Dinosaurs creature sounds from the prototype's synth recipes, AAC mono

> **Epic**: Content Pipeline (Tools) (`production/epics/content-pipeline/EPIC.md`)
> **Status**: In Progress (on story 003's branch; this story builds the D5 meter, leader 2026-11-20)
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: 2026-11-20
> **Milestone**: Demo 1 (K-48)
> **Owner**: game-art-content · **Review**: game-dev-android

## Context

**GDD**: `design/gdd/audio-voice.md`: E8, E10, E11 (the cast sound, and the number sound counting along), R7 A1–A3
and A7, F4 (cast sounds −20 LUFS, ≤ −1 dBTP), AC-19. `design/gdd/key-table-theme-data.md`: the Dinosaurs SFX column
and Numbers table, V12 (sfx ≤ 2.0 s), the `sfx` path of each item.
**Requirement**: `TR-keytable-004` (the voice **and sfx** pipeline: AAC mono, loudness target)
*(Requirement text lives in `docs/architecture/tr-registry.yaml`; read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Content pipeline
**ADR Decision Summary**: ADR-0003 D1: sfx live at `sfx/sfx_<prefix>_<key>_<name>_<nn>.m4a` beside `theme.json`.
D5: mono AAC `.m4a` via AVFoundation in Tools (K-31); every sfx ≤ 2.0 s (V12); loudness by ITU-R BS.1770 within
±1 LU of the class target, ≤ −1 dBTP. Alt 2: no ffmpeg or third-party tools.
**ADR Version**: ADR-0003 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, Foundation + AVFoundation in `apple/Tools`,
Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: the AAC encode and its priming and padding are the HIGH-risk part (ADR-0003 Knowledge Risk). This
story **reuses story 003's encoder and its priming proof** rather than a second encoder.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: Tools use only Apple frameworks and our own code (K-31); the loudness meter and encoder are own Swift.
- Required: loudness by ITU-R BS.1770 within ±1 LU of the class target; sfx ≤ 2.0 s.
- Required: baked output is byte-stable and committed with its source.
- Forbidden: never ffmpeg or other third-party tools in the pipeline (ADR-0003 Alt 2).

---

## Acceptance Criteria

*From the GDDs above, scoped to this story:*

- [ ] All 36 Dinosaurs items have `sfx/sfx_dino_<key>_<name>_01.m4a`, named exactly as the item's `sfx` field, and
  each decodes as **AAC mono** in the voice bake's format (story 003: AAC-LC, 48 000 Hz, 64 kbit/s), with priming and
  padding stripped by the same code path (story 003's priming test covers it, and this story adds one sfx case).
- [ ] Each sound is the **Key Table SFX recipe** for its key, rendered from the prototype's synth recipes
  (`prototypes/letter-morph-dinosaur/index.html` `roar` / `chirps` / `crack` / thump; `config.js` recipe values),
  with the recipes as **data** in `content/themes/dinosaurs/src/sfx/recipes.json`, not in code.
- [ ] **Numbers (Audio E11, AC-19):** digit `n` (1–9) has **exactly n chirps** (counting along; no cap at 5); 0 has
  one soft chirp. A test counts the onsets in the rendered PCM.
- [ ] **Length (V12, A3):** every file is ≤ 2.0 s decoded, including 9 chirps; the build fails naming the file
  otherwise.
- [ ] **The D5 meter (built here; story 004 reuses it):** `Loudness.swift` measures ITU-R BS.1770-4 integrated loudness
  (K-weighting, 400 ms blocks, absolute and relative gating), the momentary maximum (400 ms), and true peak (4×
  oversampled), and passes the **EBU Tech 3341** reference signals it can express in mono within **±0.1 LU** (a test).
- [ ] **Loudness (F4, A7):** every file is normalised to the cast class, **−20 LUFS ±1 LU** (the momentary maximum for
  sounds under 0.4 s), with true peak ≤ −1 dBTP, by that meter.
- [ ] **Toddler-safe (A1, A2):** every sound starts with an attack of ≥ 10 ms (no click at the start); roars stay
  "a grumble, not a scream": a by-ear check in the content review, retained as evidence.
- [ ] **Deterministic:** two runs give byte-identical PCM and the same files. The noise comes from the prototype's
  fixed LCG (seed 12345), never a random source.
- [ ] **Provenance:** `sfx/provenance.json` records the recipe file's hash, the synth version, the encode settings and
  the loudness each file was normalised to, written byte-stably.

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0003 first):*

- **The synth** (`SfxBake.swift`) ports the prototype's Web Audio graph sample by sample, at 48 kHz in Float32:
  - oscillators (sine, triangle, sawtooth) with linear and exponential frequency ramps;
  - the prototype's `env` (a linear attack, a hold to 45 %, an exponential decay to −80 dB);
  - RBJ biquads in Web Audio's formulas (lowpass with Q, highpass);
  - the noise buffer from the prototype's LCG;
  - the four kinds: `roar` (low-passed noise plus a vibrato sawtooth), `chirp` / `honk` (triangle, or a sawtooth
    through a 1200 Hz lowpass, swept f0 → f1 → 0.9 f0, 0.17 s apart), `crack` (three high-passed noise ticks, then the
    two-note peep), and `thump` (two low sines plus a soft roar ×0.6).
  The output gain is set by the loudness step, never by the prototype's `roar_volume`.
- **Numbers:** the prototype capped the chirps at 5 (`Math.min(d, 5)`). Audio Q6 (Luan) counts up to 9, so the recipe
  is `chirp {f0 1200, f1 1700, n: d}`. 9 chirps at 0.17 s spacing end at 8 × 0.17 + 0.16 = 1.52 s, within 2.0 s.
- **The pipeline:** recipe → PCM (48 kHz) → **normalise** (the D5 meter built here: integrated LUFS, or the momentary
  maximum under 0.4 s, then true peak) → **encode** (story 003's `encode`, the same settings and priming handling) →
  `sfx/`. Stage to a temp folder and copy only on success (story 003's pattern), so a failure writes nothing.
- **Commands:** `kidtools bake sfx` (or the name story 003 settles on), run by hand on the build Mac. `verify.sh`
  doesn't re-render; the staleness check (story 004) compares the committed files with an in-memory re-bake.

---

## Out of Scope

*Handled by neighbouring stories; do not implement here:*

- story-003: the AAC encoder and its priming proof (reused).
- story-004: the loudness **gate** on every voice and sfx file, `voiceDurations` and the staleness check. They reuse
  this story's meter (leader, 2026-11-20).
- Real recorded or sourced creature sounds: later. The prototype recipes stand in, as the Key Table says.
- UI sounds (chime, ping, twinkle, parade tune): a separate story.

---

## Files

- `apple/Tools/Sources/ToolsCore/Loudness.swift` (new: the ADR-0003 D5 BS.1770-4 meter, integrated, momentary max and true peak)
- `apple/Tools/Sources/ToolsCore/SfxBake.swift` (new: recipe parser, synth, normalise, bake, onset counter, container-timestamp zeroing)
- `apple/Tools/Sources/kidtools/main.swift` (modified: the `bake-sfx <theme-dir>` command)
- `apple/Tools/Tests/ToolsTests/LoudnessTests.swift` (new: 8 tests, EBU Tech 3341 mono cases)
- `apple/Tools/Tests/ToolsTests/SfxBakeTests.swift` (new: 9 tests)
- `content/themes/dinosaurs/src/sfx/recipes.json` (new: the 36 recipes and the synth constants, as data)
- `production/qa/evidence/story-007-sfx-render/` (bake log, loudness table, verify run, README)
- `content/themes/dinosaurs/sfx/` (generated: 36 `.m4a` + `provenance.json`; held out until `theme.json` lands, see the evidence README)

## QA Test Cases

*N/A: no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY-READY skipped, lean
mode).

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: Integration: the tests under Files plus a documented bake run in
`production/qa/evidence/story-007-sfx-render/`; the by-ear A1/A2 check retained there.

**Status**: [ ] Not yet created

---

## Dependencies

- **Depends on:**
  - `story-003-voice-render-encode.md`: the AAC encoder and its priming proof, to be reused. In progress, on
    feat/key-table-001-dinosaurs-theme, not merged yet.
  - **Decided (leader, 2026-11-20, option a):** this story **builds the D5 meter**; story 004 reuses it for its gates.
    Branched on story 003's branch (feat/content-pipeline-003-voice-bake @ 6721257a); merge order 001 → 002 → 003 →
    007.
- **Unlocks:** `production/epics/key-table/story-001-dinosaurs-theme-data.md` (every item's `sfx` resolves).
