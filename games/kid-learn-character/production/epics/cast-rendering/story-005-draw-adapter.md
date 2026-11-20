# Story 005: Draw the 36 creatures through the render path: sizes, silhouettes, outline colour, glyph swap, dust cap

> **Epic**: Cast Rendering (`production/epics/cast-rendering/EPIC.md`)
> **Status**: Blocked — BLOCKED: ADR-0009 is Proposed — accept it with `/architecture-decision accept ADR-0009` once decided (device rows P-2, M-13)
> **Layer**: Core
> **Type**: Visual/Feel
> **Estimate**: L
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/cast-rendering.md`
**Requirement**: `TR-cast-001`, `TR-cast-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009: Render path (**Proposed**); ADR-0006: Stage runtime
**ADR Decision Summary**: (Proposed) One `CastFigure` adapter with two backends behind `RenderSink`, both reading the same baked file; the A-candidate outline in an `SKEffectNode`; A / B / mix decided by the device run.
**ADR Version**: ADR-0009 2026-11-18; ADR-0006 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: (pending) ADR-0009: one `CastFigure` adapter, two backends behind `RenderSink`; parse once at load; never hard-wire A or B
- Forbidden: never SwiftUI `SpriteView`; the adapter only maps the render plan onto nodes, no rule lives in the scene (ADR-0006 D1)
- Required: one stage root with fixed layer children and zPositions (z0 … z80); never rely on child order within a layer (ADR-0006 D1)

**Device rows that close it** (`production/qa/device-checks-plan.md`): P-2, M-13

---

## Acceptance Criteria

*From GDD `design/gdd/cast-rendering.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-1 One member of each family at `stage`, `list` and `parade`, on Dusk and Day (retained screenshots); `detail` absent at `parade`.
- [ ] AC-2 Each all-white render at 64 px matches its golden image, and a human review names each and tells it from its siblings.
- [ ] AC-3 / AC-8 Outline pixels equal Ink at 80% over the body (±2/255); the solid glyph's outline and MorphCore's start points overlay within 1 px at the swap.
- [ ] AC-10 50 specks of alpha 1 on one pixel never exceed `C_cap`; a 60 s mash keeps the dust layer under it; a pixel already above the cap is left unchanged.

---

## Implementation Notes

*Derived from ADR-0009 and the epic:*

Build both backends behind `RenderSink` until ADR-0009 decides; the A-candidate outline is the `SKEffectNode` (TASK-127 H-2). Needs key-table/001's baked Dinosaurs art.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/LetterMorph/Stage/CastFigure.swift`
- `production/qa/evidence/<TASK>/<sha>/cast-looks/`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY-READY skipped — Lean mode).

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: Visual/Feel: a retained screenshot in `production/qa/evidence/` + lead sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/cast-rendering/story-002-parts-idles-willform.md`, `production/epics/key-table/story-001-dinosaurs-theme-data.md`
- Unlocks: `production/epics/cast-rendering/story-006-device-measurement.md`, `production/epics/reveal-stage/story-005-morph-on-stage.md`, `production/epics/parade/story-007-parade-and-meter-look.md`, `production/epics/accessibility/story-004-flash-g4-offline.md`
