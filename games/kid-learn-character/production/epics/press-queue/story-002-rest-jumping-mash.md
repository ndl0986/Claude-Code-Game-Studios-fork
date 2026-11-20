# Story 002: Start from rest, no jumping, the mash batch and one advance per tick

> **Epic**: Press Queue (`production/epics/press-queue/EPIC.md`)
> **Status**: In Progress
> **Layer**: Core
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: 2026-11-20
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/press-queue.md`
**Requirement**: `TR-queue-001`, `TR-queue-002`
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

- [ ] AC-5 Formed and hold passed with an empty queue: B starts with r0 = B's time, not the next tick.
- [ ] AC-6 B queued, hold passed, no tick yet: C is `queued(1)`; the next tick starts B.
- [ ] AC-8 At rest, 10 presses in one batch: 1 started, 3 queued, 6 ignored, in press order.
- [ ] AC-22 Two queued and a tick far past both holds: only one starts.

---

## Implementation Notes

*Derived from ADR-0002 and the epic:*

The whole state machine is KidCore (Module Ownership). Tests use an injected clock, a fake Reveal Stage and fixed `voiceDurations`.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

- `apple/KidCore/Tests/KidCoreTests/PressQueueTests.swift`
- `apple/KidCore/Tests/ContractTests/PressQueueRunner.swift`

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY-READY skipped — Lean mode).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: Logic: a unit test in the package's test target (path under Files) — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/press-queue/story-001-start-queue-ignore.md`
- Unlocks: `production/epics/press-queue/story-004-ids-sources-resting.md`
