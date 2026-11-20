# Story 006: The F6 worst-case weather inside the device run

> **Epic**: Scene: Time of Day & Weather (`production/epics/scene/EPIC.md`)
> **Status**: Blocked — BLOCKED: ADR-0009 is Proposed — accept it with `/architecture-decision accept ADR-0009` once decided (device rows P-2, M-13)
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/scene-time-weather.md`
**Requirement**: `TR-scene-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009: Render path (**Proposed**)
**ADR Decision Summary**: (Proposed) One `CastFigure` adapter with two backends behind `RenderSink`, both reading the same baked file; the A-candidate outline in an `SKEffectNode`; A / B / mix decided by the device run.
**ADR Version**: ADR-0009 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Guardrail: 60 fps cap, frame p99 within 16.7 ms; a dropped frame is a bigger time step, never caught up (ADR-0006 D3)
- Required: (pending) ADR-0009: one `CastFigure` adapter, two backends behind `RenderSink`; parse once at load; never hard-wire A or B

**Device rows that close it** (`production/qa/device-checks-plan.md`): P-2, M-13

---

## Acceptance Criteria

*From GDD `design/gdd/scene-time-weather.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-19 The F6 worst case is part of Cast Rendering's device run (R11, AC-17).

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

- `production/qa/evidence/<TASK>/<sha>/r11-measurement.md`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY-READY skipped — Lean mode).

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: Integration: an integration test (path under Files) OR a documented run in `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/cast-rendering/story-006-device-measurement.md`, `production/epics/scene/story-004-scene-drawing.md`
- Unlocks: None
