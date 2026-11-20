# Story 002: Walk order and positions on its own clock; no rest needed

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

- [ ] AC-5 Walkers are the batch in the order met, leader first, each with the castId from its `shown`.
- [ ] AC-6 n 6, W 1280, gap 150, parade_s 11: speed 216.4 u/s ±0.1, x_0(0) −100, x_5(11) 1530, alpha 0 / 1 / 0 at 0, 0.6, 11; the wide-Mac rect: 274.5 u/s, −420, 1850.
- [ ] AC-7 A press and a new reveal after the walk starts change no walker's x; it ends at pt 11.
- [ ] AC-20 A new distinct key every 3.0 s for 30 s: Waiting for art exactly 1.5 s after the 6th `shown`, a parade for every 6 keys.

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

- Depends on: `production/epics/parade/story-001-batch-and-start.md`
- Unlocks: `production/epics/parade/story-003-next-batch-art-tune.md`, `production/epics/parade/story-004-states-taps-debug.md`, `production/epics/scene/story-005-ground-lift-reduce-motion.md`, `production/epics/app-shell/story-004-memory-warnings.md`
