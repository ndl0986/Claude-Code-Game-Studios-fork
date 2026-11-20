# Tools (build-time, never shipped)

`kidtools` (ADR-0002 V4, ADR-0003):

- `kidtools api-surface [--check] <symbol-graph-dir> <module> <file.md>`: the public API surface of a core.
- `kidtools bake <content-dir>`: the SVG-subset bake (ADR-0003 D4, TR-cast-001). Every theme's `src/art/<stem>.svg`
  becomes `cast/<stem>.json` and `src/sil/<stem>.svg` becomes `sil/<stem>.json`. Output is byte-stable (sorted keys, up to
  3 decimals, LF, tool name and version in each file). A rejected SVG names element, attribute and line, writes nothing
  and makes the command exit 1. Not done yet: the check that every part the family's idle names exists (no idle data),
  and the silhouette raster check (silhouette vs body+outline within 1 px). Layout and choices: see `SVGBake.swift`.
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
