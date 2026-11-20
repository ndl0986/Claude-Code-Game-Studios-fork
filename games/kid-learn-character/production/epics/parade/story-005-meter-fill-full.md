# Story 005: The parade meter: fill, full, handover, launch, Reduce Motion, flash data

> **Epic**: Parade (`production/epics/parade/EPIC.md`)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/parade.md`
**Requirement**: `TR-parade-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Contracts, fixtures and harness; ADR-0013: Flash safety
**ADR Decision Summary**: The system's numbers are hand-written contract cases from the GDD, run by a runner over the public API; the not-started registry row becomes `runner:` when its story lands.
**ADR Version**: ADR-0004 2026-11-18; ADR-0013 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Forbidden: never hard-code a periodic animation rate in Swift; every rate comes from data G1 reads (ADR-0013 Impl.)

---

## Acceptance Criteria

*From GDD `design/gdd/parade.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-22 / AC-23 D at 9.25, C, D: `filled` 1 then 2; cell 0 `litAt` 10.0 with alpha 0.25 / 0.81 / 1 at 10.0 / 10.2 / 10.4; the 6th at 19.25 gives `armed`, `fullAt` 20.0, glow 0 / 0.215 / 0.45 at 20.0 / 20.2 / 20.5, Waiting for art at 20.75.
- [ ] AC-24 Walking entry with held [K]: `filled` 1, cells 1–5 reach 0.25 at +0.6 s, glow 0 at +0.6 s.
- [ ] AC-26 (launch half) A fresh launch: `filled` 0; AC-27 Reduce Motion: no breathe, the 0.4 s ramp and a steady 0.40.
- [ ] AC-29 G1 reads `meter_pulse_hz` 0.5 and passes; the G2 palette check includes the meter's colours.

---

## Implementation Notes

*Derived from ADR-0004 and the epic:*

Drawn by the Reveal Stage at z 70 beside the tokens (ADR-0006 D1 note).

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/Parade.swift`
- `apple/KidCore/Tests/KidCoreTests/ParadeTests.swift`

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

- Depends on: `production/epics/parade/story-001-batch-and-start.md`, `production/epics/accessibility/story-002-flash-g1-g2.md`
- Unlocks: `production/epics/parade/story-006-meter-light.md`
