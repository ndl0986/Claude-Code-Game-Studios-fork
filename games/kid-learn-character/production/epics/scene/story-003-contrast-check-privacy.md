# Story 003: The 160-case contrast build check, and no network or sound from the Scene

> **Epic**: Scene: Time of Day & Weather (`production/epics/scene/EPIC.md`)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/scene-time-weather.md`
**Requirement**: `TR-scene-003`, `TR-scene-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Contracts, fixtures and harness; ADR-0001: Native Apple stack; ADR-0011: Build, verify and PKC gates
**ADR Decision Summary**: The system's numbers are hand-written contract cases from the GDD, run by a runner over the public API; the not-started registry row becomes `runner:` when its story lands.
**ADR Version**: ADR-0004 2026-11-18; ADR-0001 2026-11-17; ADR-0011 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: no network call, no location (ADR-0001 D8)
- Forbidden: never hard-code tuning values; timing and knobs are bundled data (ADR-0001 D6)

---

## Acceptance Criteria

*From GDD `design/gdd/scene-time-weather.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-5 The check runs R5's 160 cases with F8's edge model and passes the shipped data (lowest 4.36:1 at w 0/1, 2.68:1 inside, 2.57:1 at L_x); a cloud at L 0.72, a look below 3:1 at w 1, or the old edge fails naming the case.
- [ ] AC-18 The Scene's code calls no network or location API and requests no audio (code review and a build check over its sources).

---

## Implementation Notes

*Derived from ADR-0004 and the epic:*

The system's numbers are hand-written contract cases from the GDD, run by a runner over the public API; the not-started registry row becomes `runner:` when its story lands.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/Tools/Sources/ToolsCore/SceneContrastCheck.swift`
- `apple/Tools/Tests/ToolsTests/SceneContrastCheckTests.swift`

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

- Depends on: `production/epics/scene/story-001-looks-and-clocks.md`, `production/epics/cast-rendering/story-004-per-look-edge.md`
- Unlocks: None
