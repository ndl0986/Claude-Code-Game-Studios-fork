# Story 002: Bake the 36 glyphs (A–Z, 0–9) from the OFL font into the v1 SVG subset

> **Epic**: Content Pipeline (Tools) (`production/epics/content-pipeline/EPIC.md`)
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: 2026-11-20
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/morphcore.md` — (AC-10); key-table-theme-data.md (AC-3)
**Requirement**: `TR-morph-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Content pipeline; ADR-0001: Native Apple stack
**ADR Decision Summary**: ADR-0003 D4: glyph outlines come from the bundled OFL font at build time through `CTFontCreatePathForGlyph`, flattened into the v1 path subset; nothing is rasterised at run time (ADR-0001 D6).
**ADR Version**: ADR-0003 2026-11-18; ADR-0001 2026-11-17

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: `CTFontCreatePathForGlyph` is a HIGH-risk API in ADR-0003's Knowledge Risk: prove it by building and running, never from memory (manifest, version-gated APIs).

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: Tools use only Apple frameworks and our own code (K-31; ADR-0003 D4)
- Forbidden: never rasterise a font at run time (ADR-0001 D6)
- Required: baked output byte-stable and committed with its source (ADR-0003 D4)

---

## Acceptance Criteria

*From GDD `design/gdd/morphcore.md`, scoped to this story:*

- [ ] The bake writes one glyph path per key A–Z and 0–9 into the glyph set (36 entries), byte-stable across two runs (ADR-0003 D4).
- [ ] Every glyph parses with the v1 parser and has a non-zero total length (MorphCore AC-10; Key Table AC-3).
- [ ] A key with no glyph in the font fails the bake naming the key and the font file.

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0003 first):*

The font and its OFL licence file live in `content/fonts/` (shipped, ADR-0003 D1: also used for panel text, hint letters, row keys and tokens), copied from the TASK-033 prototype's `third_party/fredoka/` (Google Fonts, OFL 1.1). *(Corrected 2026-11-20 at implementation: this note first said `content/glyphs/<set>/src/`, which D1 does not list.)*

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- story-001: cast/silhouette SVG

---

## Files

- `apple/Tools/Sources/ToolsCore/GlyphBake.swift` (new: CoreText bake at wght 600, morph-v1 subset, glyph set writer)
- `apple/Tools/Sources/ToolsCore/SVGGeometry.swift` (shared `MorphPathCheck` drawable check)
- `apple/Tools/Sources/ToolsCore/SVGBake.swift` (silhouettes use the shared check; messages unchanged)
- `apple/Tools/Sources/kidtools/main.swift` (`kidtools bake-glyphs <content-dir>`)
- `apple/Tools/README.md`
- `apple/Tools/Tests/ToolsTests/GlyphBakeTests.swift` (5 test functions)
- `content/fonts/Fredoka-wdth-wght.ttf`, `content/fonts/OFL.txt` (copies of the TASK-033 prototype's third_party files, byte-identical)
- `content/glyphs/fredoka600/glyphs.json` + 36 `glyph_fredoka_<char>.json`

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY-READY skipped — Lean mode).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: Logic: a unit test in the package's test target (path under Files) — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: `production/epics/key-table/story-001-dinosaurs-theme-data.md`

## Completion Notes
**Completed**: 2026-11-20
**Criteria**: 3/3 passing (no deferred items)
**Deviations**: None
**Test Evidence**: `apple/Tools/Tests/ToolsTests/GlyphBakeTests.swift` (`test_the_bake_writes_36_glyphs_and_a_glyph_set_byte_identical_across_two_runs`,
`test_every_baked_glyph_parses_under_the_morph_v1_parser_with_a_non_zero_length`,
`test_a_key_with_no_glyph_fails_naming_the_key_and_the_font_file_and_writes_nothing`); evidence in
`production/qa/evidence/story-002-glyph-bake/`
**Run result**: N/A — a build-time tool; the glyphs are seen when MorphCore morphs them in the app
**Reviewed by**: game-dev-ios (APPROVE; K-14 peer review)

## Calls beyond the design
- Each `glyph_fredoka_<c>.json` carries a `font` record (name, version, weight, licence); `glyphs.json` holds the font metrics (unitsPerEm 1000, capHeight 700, ascender 974) (`GlyphBake.swift`) · kept 2026-11-20
- The output folder is `content/glyphs/fredoka600/` (`GlyphBake.swift`) · kept 2026-11-20
