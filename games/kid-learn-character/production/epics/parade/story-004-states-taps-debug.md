# Story 004: Background, Reduce Motion, walker taps and the debug start

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
- Required: Reduce Motion is read live and applied at the next reveal (ADR-0006 D6)

---

## Acceptance Criteria

*From GDD `design/gdd/parade.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-10 Background at pt 5: nothing drawn, Ended on return, no replay.
- [ ] AC-13 Reduce Motion: path and `parade_s` unchanged, bob amplitude halved.
- [ ] AC-14 A touch on a walker gives a sparkle, no creature tap, hop or sound.
- [ ] AC-15 Debug `startParade(manual)` with a batch of 2 walks 6 (the 2, then canonical-order keys); ignored while Walking; no entry point in Release.

---

## Implementation Notes

*Derived from ADR-0004 and the epic:*

Panel and gate cases (AC-9, AC-19, AC-21, AC-25, AC-33) and the theme switch (AC-11, AC-26 switch half) are the next milestone.

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

- Depends on: `production/epics/parade/story-002-walk-positions-clock.md`
- Unlocks: None
