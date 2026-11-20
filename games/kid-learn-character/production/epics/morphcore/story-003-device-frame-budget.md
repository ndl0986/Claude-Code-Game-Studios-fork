# Story 003: Frame time p99 within one refresh with 240 specks on the device

> **Epic**: MorphCore (`production/epics/morphcore/EPIC.md`)
> **Status**: Blocked — BLOCKED: ADR-0009 is Proposed — accept it with `/architecture-decision accept ADR-0009` once decided (device rows P-2, M-13); it also needs the reveal stage (Core/Feature batch)
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/morphcore.md` — (AC-11)
**Requirement**: `TR-morph-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009: Render path (**Proposed**); ADR-0006: Stage runtime
**ADR Decision Summary**: ADR-0009 D1 (Proposed): the render path is decided by the device run, frame p99 within one refresh and creature load ≤ 1.2 s.
**ADR Version**: ADR-0009 2026-11-18; ADR-0006 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: Measured on the production app, not the spike (spike runs are ADR evidence only).

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Guardrail: 60 fps cap, frame p99 within 16.7 ms (ADR-0006 D3); device cost measured under ADR-0009
- Required: (pending) ADR-0009: build behind `RenderSink`, never hard-wire option A or B

**Device rows that close it** (`production/qa/device-checks-plan.md`): P-2 (child's iPad; decisive oldest-iPad run at release prep, K-47); M-13

---

## Acceptance Criteria

*From GDD `design/gdd/morphcore.md`, scoped to this story:*

- [ ] With the default particle count (240), frame time p99 during a reveal is at or below one display refresh on the child's iPad, measured with `production/qa/evidence/TASK-033/procedure-ipad.md` (AC-11; the oldest-iPad run is decided at release prep, K-47).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0009 first):*

TASK-127/129 measured frame pacing on DeviceSpike, not render cost; this story measures the production app.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- None

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `production/qa/evidence/<TASK>/<sha>/morph-frame-p99.md`

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

- Depends on: `production/epics/morphcore/story-002-empty-paths-seed-purity.md`
- Unlocks: None
