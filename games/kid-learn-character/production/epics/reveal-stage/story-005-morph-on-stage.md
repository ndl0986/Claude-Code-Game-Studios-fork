# Story 005: The morph drawn on the stage: no jump at the swap, the leaving creature, late art

> **Epic**: Reveal Stage (`production/epics/reveal-stage/EPIC.md`)
> **Status**: Blocked — BLOCKED: depends on cast-rendering/005, which is Blocked on ADR-0009 (Proposed; device rows P-2, M-13)
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/reveal-stage.md`
**Requirement**: `TR-reveal-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Stage runtime; ADR-0009: Render path (**Proposed**)
**ADR Decision Summary**: One `SKView` per window with D1's fixed layers and zPositions; the stage root carries Reveal Stage F1's fit; the display-link frame driver calls `tick(now:)`; Reduce Motion read live (D6); ppi for hit sizes (D7).
**ADR Version**: ADR-0006 2026-11-18; ADR-0009 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: one stage root with fixed layer children and zPositions (z0 … z80); never rely on child order within a layer (ADR-0006 D1)
- Required: (pending) ADR-0009: one `CastFigure` adapter, two backends behind `RenderSink`; parse once at load; never hard-wire A or B
- Required: evidence for every player-observable change is a retained screenshot (coding-standards.md)

**Device rows that close it** (`production/qa/device-checks-plan.md`): P-2, M-13

---

## Acceptance Criteria

*From GDD `design/gdd/reveal-stage.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-6 The glyph's outline and the specks' start points, and the creature's outline and the specks' end points, overlay within 1 px.
- [ ] AC-7 With the art delayed, `formed` at `formedS`, the fade-in starts when the art arrives within F7, the idle starts at rest.
- [ ] AC-8 When reveal 2 starts, reveal 1's creature fades over 0.45 s, sinking 12 units and shrinking 8%; with Reduce Motion it only fades.

---

## Implementation Notes

*Derived from ADR-0006 and the epic:*

One `SKView` per window with D1's fixed layers and zPositions; the stage root carries Reveal Stage F1's fit; the display-link frame driver calls `tick(now:)`; Reduce Motion read live (D6); ppi for hit sizes (D7).

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/LetterMorph/Stage/StageScene.swift`
- `production/qa/evidence/<TASK>/<sha>/reveal-morph/`

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

- Depends on: `production/epics/reveal-stage/story-004-stage-view-layers-fit.md`, `production/epics/cast-rendering/story-005-draw-adapter.md`
- Unlocks: `production/epics/reveal-stage/story-006-reveal-feel-device.md`
