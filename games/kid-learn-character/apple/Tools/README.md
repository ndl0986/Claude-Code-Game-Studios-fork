# Tools (build-time, never shipped)

`kidtools` (ADR-0002 V4, ADR-0003):

- `kidtools api-surface [--check] <symbol-graph-dir> <module> <file.md>`: the public API surface of a core.
- `kidtools bake <content-dir>`: the SVG-subset bake (ADR-0003 D4, TR-cast-001). Every theme's `src/art/<stem>.svg`
  becomes `cast/<stem>.json` and `src/sil/<stem>.svg` becomes `sil/<stem>.json`. Output is byte-stable (sorted keys, up to
  3 decimals, LF, tool name and version in each file). A rejected SVG names element, attribute and line, writes nothing
  and makes the command exit 1. Not done yet: the check that every part the family's idle names exists (no idle data),
  and the silhouette raster check (silhouette vs body+outline within 1 px). Layout and choices: see `SVGBake.swift`.
- `kidtools bake-glyphs <content-dir>`: the glyph bake (ADR-0003 D4, TR-morph-002). CoreText's
  `CTFontCreatePathForGlyph` turns `content/fonts/Fredoka-wdth-wght.ttf` (OFL 1.1, licence `content/fonts/OFL.txt`) at
  `wght` 600 into `content/glyphs/fredoka600/glyph_fredoka_<char>.json` for the 36 keys A–Z, 0–9, each
  `{"d", "tool", "version"}`, plus `glyphs.json` (Key Table §2c; font name and version read from the font). Paths are
  morph-v1 (`M L C Q Z`, the SVG bake's number format), in font units with y flipped to y down and the baseline at 0,
  like the morph contract's `glyph-D.json`/`glyph-3.json`. Byte-stable; a key with no glyph names the key and the font
  file and writes nothing. CoreText outlines may change between macOS versions: the output is committed and records the
  tool version. Layout and choices: see `GlyphBake.swift`.
- `kidtools validate <content-dir> [--load]`: KidCore's V1–V18 over every `content/themes/*/theme.json`, run with a
  file-system `ContentProbe` (exact case on every path component), plus the **staleness stub**. `verify.sh` runs it on
  `content/`; with no theme yet it reports `0 theme(s)` and passes. `ContentValidatorTests` proves it on a test theme
  built from key-table-schema-v1's fixtures: the theme passes, a wrong-case file fails V7, a missing SVG source fails
  the staleness stub.

- **A theme in progress** (TASK-125): a `content/themes/<id>/` folder holding **only** `src/` (build inputs, ADR-0003
  D1's B files, such as voice scripts before the theme file exists) and no `theme.json` is reported
  `NOT ASSESSED theme <id>: in progress`, not a finding, so it does not fail a merge. `kidtools validate --release`
  (run by `verify.sh --release`) **fails** on any theme in progress. A folder with anything else in it (a shipped
  `cast/`, `sil/`, `sfx/` or `voice/` folder, a stray file) or an empty folder still fails V1 for its missing
  `theme.json`.

## What the stub does not do yet (the bake tool story, ADR-0003 D4)

- **Staleness** checks only that each baked `cast/…json` and `sil/…json` has its source by the stem rule
  (`src/art/<stem>.svg`, `src/sil/<stem>.svg`). Re-baking in memory and comparing bytes waits for the bake tool.
- **Baked path format:** V8 reads a baked silhouette or glyph file's top-level `"d"` string. This is **provisional**;
  the bake tool story fixes the baked format and updates `FileProbe.pathText`.
- The SVG subset and structure, the silhouette raster check, loudness and true peak (ADR-0003 D4, D5) are not run.
- Durations come from `AVAudioFile` (decoded length, AAC priming excluded); V15's ±0.01 s rule is unproven on real
  files until the TTS render story (ADR-0003 D5).

## The SVG layer-id rule (a1; K-37, ADR-0003 D4 note in TASK-084), for the bake tool

Every layer group in a cast SVG has `id="<part>_<layer>"`:
- `<layer>` is the **last** `_`-separated segment and is one of `body`, `outline`, `detail`;
- `<part>` is everything before it and matches `[a-z]+(_[a-z]+)*`; the words `body`, `outline` and `detail` are
  reserved and never appear inside a part name.

Examples: `head_body`, `left_arm_outline`, `tail_tip_detail`. Rejected: `head` (no layer), `Head_body` (case),
`body_detail_outline` (reserved word in the part). (`head_shadow` reads as a part named `head_shadow`, which then fails
for its missing layer groups.) The bake tool enforces this rule and names the element and line on a rejection.

## Voice bake (`kidtools bake-voice`, content-pipeline story 003, ADR-0003 D5/D6)

`kidtools bake-voice <content-dir> [--python <path>] [--helper <path>]` renders every voice line of each theme that
has a `theme.json` (a `src/`-only theme is skipped) for every locale in `voiceLocales`, and writes
`themes/<id>/voice/<locale>/vo_<locale>_<kind>_<id>.m4a` (`KeyTable.voicePath`) plus
`voice/<locale>/provenance.json` (engine settings, versions the helper reported, espeak-ng as a build-time tool, encode
settings, bake tool, line ids; byte-stable). Line text is the item's `word` (kind `word`) or `say` (other kinds);
`respell["<kind>_<id>"]` in `src/voice-scripts/<locale>.json` replaces it for the TTS only (K-35).

- **Encoding:** AAC-LC, mono, 48 000 Hz, 64 000 bit/s, `AVAudioFile` (Apple frameworks only). Engine output at another
  rate (Kokoro 24 kHz) is resampled with `AVAudioConverter`. No trim, no loudness change: story 004.
- **Engine behind an adapter:** `TTSEngine` (ToolsCore). Real engine: `KokoroProcessEngine` runs `tts/kokoro_render.py`
  out of process through `--python` or `$KIDTOOLS_PYTHON`. One helper process per line. Tests use fake engines and
  never run Python.
- **No speech synthesis in the app:** `SpeechAPIScan` (tested) text-scans `apple/LetterMorph` for `AVSpeechSynthesizer`,
  `NSSpeechSynthesizer`, `AVSpeechUtterance`.

### Recreating the build venv (build Mac only; never in git, K-36)

Source: game-art-content's TASK-073/108/110 runs; **not yet reproduced by this bake, and the helper has never been run
end to end** (the real Dinosaurs `theme.json` does not exist yet). Unconfirmed items are marked.

1. Python 3.11 venv in a short path outside the repo. Run everything under `nice -n 10`.
2. `pip install kokoro==0.9.4 soundfile`. misaki 0.9.4 and its English extras come in with it (confirm `misaki[en]==0.9.4`);
   install `en_core_web_sm==3.8.0` explicitly from the spacy-models release (never fetched at run time). torch is
   whatever kokoro pulls: record what pip resolves (TASK-073 used 2.15.0).
3. espeak-ng 1.52.0 (GPL-3.0, build machine only) built from source: CMake Release, `BUILD_SHARED_LIBS=ON`, mbrola,
   libsonic, libpcaudio, speechplayer and async off, Klatt on. Install to a SHORT path (the home-path buffer is 160
   chars). The pip `espeakng-loader` wheel cannot load on macOS (compiled-in data path), so the helper monkeypatches it.
4. Environment: `ESPEAK_LIB` (the dylib), `ESPEAK_REL_DATA` (data dir relative to `ESPEAK_CWD`), `ESPEAK_CWD`,
   `HF_HOME`, and `HF_HUB_OFFLINE=1` at bake time.
5. One-off weights fetch (network): `python tts/kokoro_render.py --fetch --revision f3ff3571791e39611d31c381e3a41a3af07b4987`
   (`config.json`, `kokoro-v1_0.pth`, `voices/af_heart.pt`). Never at bake time.
6. Not yet confirmed: the helper checks the weights' SHA-256 by the 16-digit PREFIXES in
   `production/qa/evidence/TASK-073/README.md` (full digests are not recorded there); `KModel(config=, model=)` /
   `KPipeline(model=)` local loading is unverified against the kokoro 0.9.4 source; the espeak-ng version read via
   `espeak_Info` is unverified (provenance says "not reported" if it fails).
