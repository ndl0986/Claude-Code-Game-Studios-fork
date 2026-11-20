# Story 002: Bake the 36 glyphs (A–Z, 0–9) from the OFL font into the v1 SVG subset

> **Epic**: Content Pipeline (Tools) (`production/epics/content-pipeline/EPIC.md`)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
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

The font and its OFL licence file are inputs under `content/glyphs/<set>/src/` (build-only, ADR-0003 D1); only the baked glyph JSON ships.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- story-001: cast/silhouette SVG

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/Tools/Sources/ToolsCore/GlyphBake.swift`
- `apple/Tools/Tests/ToolsTests/GlyphBakeTests.swift`

---

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
