# Story 001: Start at once, queue during the hold, the formed guard, ignore when full

> **Epic**: Press Queue (`production/epics/press-queue/EPIC.md`)
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
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

**Contracts**: press-queue-v1 (this story adds the runner file, reporting the cases not yet passing as NOT ASSESSED — it is not registered while the row is `not-started`, since ContractKit fails a registered runner on a not-started row; the row flips to `runner:` in press-queue/005)

> *Note 2026-11-20 (TASK-147, K-53):* press-queue-v1 is superseded by **press-queue-v2** (merged at plan dabc9a96); this
> story's runner targets v2. The registry row `press-queue-v2 | not-started: story:press-queue` stays until 005. The
> runner runs an explicit list of this story's case ids (AC1–AC4 at least) and lists the rest NOT ASSESSED by id,
> never because a case failed.

---

## Acceptance Criteria

*From GDD `design/gdd/press-queue.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-1 No current, D at 10.0: `started(1, 10.0, item)` and one `startReveal(…, r0 10.0)`.
- [ ] AC-2 D started at 10.0 (holdEff 3.2), B at 11.0: `queued(0)`; tick(13.199) after formed starts nothing; tick(13.2) starts B with r0 13.2.
- [ ] AC-3 B queued, D not formed, tick(13.5): nothing; formed(1) then tick(13.6): B starts.
- [ ] AC-4 Holding with 3 queued: a 4th press is `ignored`, the queue unchanged, no revealId used.

---

## Implementation Notes

*Derived from ADR-0002 and the epic:*

The whole state machine is KidCore (Module Ownership). Tests use an injected clock, a fake Reveal Stage and fixed `voiceDurations`.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

- `apple/KidCore/Sources/KidCore/PressQueue.swift`
- `apple/KidCore/Tests/KidCoreTests/PressQueueTests.swift`
- `apple/KidCore/Tests/ContractTests/PressQueueRunner.swift`
- `contracts/kidcore-api.md`

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY-READY skipped — Lean mode).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: Logic: a unit test in the package's test target (path under Files) — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: `production/epics/press-queue/story-002-rest-jumping-mash.md`, `production/epics/press-queue/story-003-hold-and-formed-rules.md`, `production/epics/reveal-stage/story-001-start-reveal-timeline.md`, `production/epics/hint-letters/story-001-spawn-and-exclusions.md`

## Completion Notes
**Completed**: 2026-11-20
**Criteria**: 4/4 passing (no deferred items)
**Deviations**: ADVISORY: the story named press-queue-v1; v1 is superseded by press-queue-v2 (TASK-147, K-53), noted in
the story; the runner targets v2, registered by press-queue/005 and passing 50/50 in verify.
**Test Evidence**: `apple/KidCore/Tests/KidCoreTests/PressQueueTests.swift` (AC-1 `test_press_with_nothing_on_stage_starts_at_once`,
AC-2 `test_press_during_hold_queues_then_starts_at_hold_end`, AC-3 `test_queued_press_waits_for_formed_even_after_hold_passed`,
AC-4 `test_fourth_press_while_holding_is_ignored_and_uses_no_reveal_id`) and press-queue-v2's AC1–AC4 cases
(`apple/KidCore/Tests/ContractTests/PressQueueRunner.swift`)
**Run result**: N/A — pure KidCore logic with no app surface yet; the queue becomes player-visible with the Reveal Stage and app shell stories
**Reviewed by**: game-qc-android (APPROVE a99454fa, 60cdc3d9; K-14 peer review)

## Calls beyond the design
- The knobs are an injected `PressQueueKnobs` with no defaults in KidCore; loaded from `content/data/press-queue.json` since press-queue/005 (`PressQueue.swift`) · kept 2026-11-20
- `Press`, `PressSource` and `PressOrigin` are defined in `PressQueue.swift` until Input's ADR-0002 D5 `KeyEvent` lands; they move there in input/001 · kept 2026-11-20
- No state enum: Empty / Revealing / Holding / Resting follow from the data (`PressQueue.swift`) · kept 2026-11-20
- F1's holdEff is computed once in the queue from the stage's answer at start (`PressQueue.holdEff`) · kept 2026-11-20
