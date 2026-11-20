# Story 006: The light from each new creature to its cell

> **Epic**: Parade (`production/epics/parade/EPIC.md`)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/parade.md`
**Requirement**: `TR-parade-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Contracts, fixtures and harness; ADR-0002: Modules, seams and Kotlin-mappable types
**ADR Decision Summary**: The system's numbers are hand-written contract cases from the GDD, run by a runner over the public API; the not-started registry row becomes `runner:` when its story lands.
**ADR Version**: ADR-0004 2026-11-18; ADR-0002 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)

---

## Acceptance Criteria

*From GDD `design/gdd/parade.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-31 D shown at 0 with the cast box top centre (640, 300) and cell 0 at (866.5, 58): the light at (640, 300) / (696.6, 118.5) / (866.5, 58) at 0 / 0.45 / 0.9 s, alpha 1 until 0.75, 0 at 0.9; `litAt` 0.75.
- [ ] AC-32 Reduce Motion: no `flight`, `litAt` = the shown time; on mid-flight removes the light and lights the cell.
- [ ] AC-34 / AC-35 At most one `flight` at any tick in a 60 s mash; a 7th key while Armed sets none; a key shown at pt 2 lights its next-batch cell from pt 2.75, drawn above the walkers.
- [ ] AC-28 A touch on the meter gives an empty-stage sparkle, no press and no meter change.

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

- Depends on: `production/epics/parade/story-005-meter-fill-full.md`
- Unlocks: `production/epics/parade/story-007-parade-and-meter-look.md`, `production/epics/parade/story-008-freeze-panel-theme.md`
