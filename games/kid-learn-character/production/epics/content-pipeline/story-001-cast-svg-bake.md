# Story 001: Bake cast and silhouette SVG (D4 subset) to the shipped path files

> **Epic**: Content Pipeline (Tools) (`production/epics/content-pipeline/EPIC.md`)
> **Status**: In Progress
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: 2026-11-20
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/cast-rendering.md` — (R2, R7); key-table-theme-data.md (AC-3)
**Requirement**: `TR-cast-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Content pipeline; ADR-0002: Modules, seams and Kotlin-mappable types
**ADR Decision Summary**: ADR-0003 D4: the bake tool accepts only the SVG subset (elements, attributes, values, `<part>_<layer>` ids with body/outline/detail, `data-pivot`), rejects anything else naming element, attribute and line, and writes byte-stable baked JSON committed with its source. One baked file feeds both render options.
**ADR Version**: ADR-0003 2026-11-18; ADR-0002 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH (ADR-0003: Tools APIs); the SVG part is plain Swift: LOW
**Engine Notes**: Own Swift parser only (K-31): no SVG library, no ffmpeg (ADR-0003 Alt 2).

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: cast SVG accepted only in D4's subset, every rejection naming element, attribute and line; baked output byte-stable and committed with its source (Tooling, ADR-0003 D4)
- Forbidden: never `<defs>` content, `use`, `symbol`, `pattern`, `mask`, `clipPath`, `filter`, gradients, `text`, `image`, `style`, `class`, `url(#…)` paint, skew, units or percentages (ADR-0003 D4)
- Forbidden: never third-party tools in the content pipeline (ADR-0003 Alt 2)

---

## Acceptance Criteria

*From GDD `design/gdd/cast-rendering.md`, scoped to this story:*

- [ ] A cast SVG inside D4's subset bakes to its `cast/…json` / `sil/…json` file; baking the same source twice gives identical bytes (ADR-0003 D4).
- [ ] Each out-of-subset construct listed in D4 (one test file each) fails the bake naming the element, attribute and line (ADR-0003 D4).
- [ ] Every baked silhouette parses with the morph-v1 reference parser, has ≥ 1 subpath of 2+ points and total length > 0; a test file with an `A` arc command fails naming the file (Key Table AC-3).
- [ ] Part ids follow `<part>_<layer>` with layer body/outline/detail, and `data-pivot` is carried into the baked file (ADR-0003 D4; Cast Rendering R2).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0003 first):*

Input is the team-authored layered SVG of art bible §8 (TASK-133 specs). Baked batch-1 output is not committed here (leader, option A): key-table/001 commits the bake together with `theme.json`. The baked file is the one draw interface for both ADR-0009 options, so it must not encode a render choice. `kidtools bake` is the entry point; the staleness check (story 004) re-bakes in memory and compares bytes.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- story-002: the glyph bake from the font
- story-005: running the V-rules over the baked files

---

## Files

- `apple/Tools/Sources/ToolsCore/SVGBake.swift` (new: subset/structure checks, cast and silhouette bake, JSON writer, content bake)
- `apple/Tools/Sources/ToolsCore/SVGGeometry.swift` (new: numbers, transforms, path data, arcs, shapes → path)
- `apple/Tools/Sources/kidtools/main.swift` (`kidtools bake <content-dir>`)
- `apple/Tools/README.md` (bake command)
- `apple/Tools/Tests/ToolsTests/SVGBakeTests.swift` (50 test functions)
- Baked output for batch 1 (6 `cast/…json`, 6 `sil/…json`): produced and byte-stable, **not committed** pending the leader's call (they make `dinosaurs/` fail V1 without a `theme.json`, TASK-125)

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
