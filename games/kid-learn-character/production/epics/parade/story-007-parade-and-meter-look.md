# Story 007: The parade and the meter on the iPad: walkers on the hill band, meter states

> **Epic**: Parade (`production/epics/parade/EPIC.md`)
> **Status**: Blocked — BLOCKED: ADR-0009 is Proposed — accept it with `/architecture-decision accept ADR-0009` once decided (device rows P-2, M-13)
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/parade.md`
**Requirement**: `TR-parade-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009: Render path (**Proposed**); ADR-0006: Stage runtime
**ADR Decision Summary**: (Proposed) One `CastFigure` adapter with two backends behind `RenderSink`, both reading the same baked file; the A-candidate outline in an `SKEffectNode`; A / B / mix decided by the device run.
**ADR Version**: ADR-0009 2026-11-18; ADR-0006 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: (pending) ADR-0009: one `CastFigure` adapter, two backends behind `RenderSink`; parse once at load; never hard-wire A or B
- Required: one stage root with fixed layer children and zPositions (z0 … z80); never rely on child order within a layer (ADR-0006 D1)
- Required: evidence for every player-observable change is a retained screenshot (coding-standards.md)

**Device rows that close it** (`production/qa/device-checks-plan.md`): P-2, M-13

---

## Acceptance Criteria

*From GDD `design/gdd/parade.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-18 A walk at pt ≈ 5 on the iPad: 6 small figures on the hill band behind the stage creature, facing right, no gold (screenshot).
- [ ] AC-30 The meter empty, at 3 of 6 and full, Day and Night: no text, no gold, inside the safe stage top right, clear of 3 tokens; one light mid-flight above the hints (screenshots).

---

## Implementation Notes

*Derived from ADR-0009 and the epic:*

(Proposed) One `CastFigure` adapter with two backends behind `RenderSink`, both reading the same baked file; the A-candidate outline in an `SKEffectNode`; A / B / mix decided by the device run.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/LetterMorph/Stage/ParadeNodes.swift`
- `production/qa/evidence/<TASK>/<sha>/parade/`

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

- Depends on: `production/epics/parade/story-006-meter-light.md`, `production/epics/cast-rendering/story-005-draw-adapter.md`, `production/epics/reveal-stage/story-004-stage-view-layers-fit.md`
- Unlocks: `production/epics/accessibility/story-004-flash-g4-offline.md`
