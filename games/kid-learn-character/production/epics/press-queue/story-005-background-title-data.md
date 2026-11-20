# Story 005: Background clear and settle, the first press after the Title, and the data checks

> **Epic**: Press Queue (`production/epics/press-queue/EPIC.md`)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/press-queue.md`
**Requirement**: `TR-queue-001`, `TR-queue-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0004: Contracts, fixtures and harness
**ADR Decision Summary**: KidCore holds the pure rules with injected clocks (D3) and seeded streams (D4); the app reaches it only through the D6 seams and `tick(now:)`, in D7's call orders.
**ADR Version**: ADR-0002 2026-11-18; ADR-0004 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Required: every runner calls only the core's public API; hand-written cases from the GDD; never edit a merged `cases.json` (ADR-0004 D4–D6)
- Forbidden: never hard-code tuning values; timing and knobs are bundled data (ADR-0001 D6)

---

## Acceptance Criteria

*From GDD `design/gdd/press-queue.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-15 Background mid-morph with 3 queued: queue empty, current formed (settle once), no outcome or sound for the dropped presses, the next press after return starts at once.
- [ ] AC-17 Play entered by a key: the first press starts at once with revealId 1.
- [ ] AC-21 The build fails for `hold_s`, `queue_max` or `formed_timeout_s` missing, non-numeric or out of range, and when the F1 build check fails; no timing literal in the queue's code.

---

## Implementation Notes

*Derived from ADR-0002 and the epic:*

The whole state machine is KidCore (Module Ownership). Tests use an injected clock, a fake Reveal Stage and fixed `voiceDurations`. The panel clear (AC-14), theme switch (AC-16) and gate freeze (AC-23) are the next milestone.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/PressQueue.swift`
- `apple/KidCore/Tests/KidCoreTests/PressQueueTests.swift`

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

- Depends on: `production/epics/press-queue/story-003-hold-and-formed-rules.md`
- Unlocks: None
