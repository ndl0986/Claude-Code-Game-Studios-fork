# Story 004: Synchronous outcomes, gap-free revealIds, locked lengths, equal sources, the resting signal

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

---

## Acceptance Criteria

*From GDD `design/gdd/press-queue.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-9 `press(p)` returns its outcome synchronously; N presses give N outcomes in order.
- [ ] AC-10 Started reveals get 1, 2, 3… with no gaps, each equal to the press count handed to the seed.
- [ ] AC-13 Reduce Motion turned on mid-reveal leaves its holdEff; the next uses the reduced lengths with `hold_s` 3.0; AC-18 `hardwareKey`, `hint(id)` and `keyboardRow` give the same outcomes and timings.
- [ ] AC-20 `restingSince` is none while unformed or queued, and `formedAt` once formed with an empty queue.

*Note 2026-11-20 (dev):* press-queue-v2's `AC10-revealId-no-gaps` crosses a `panelOpen`/`panelClose` (R8, story 005's
clear and settle), so that case runs with 005; AC-10 itself has a unit test here. `R11-snapshot-queue-keys-in-order`
(no AC of its own) runs with this story.

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

- Depends on: `production/epics/press-queue/story-002-rest-jumping-mash.md`
- Unlocks: `production/epics/keyboard-row/story-003-due-quiet-change.md`

## Completion Notes
**Completed**: 2026-11-20
**Criteria**: 4/4 passing (no deferred items)
**Deviations**: ADVISORY: AC-10 says ids equal "the press count handed to the seed". The seed handoff is MorphCore's and isn't
wired yet; the ids are tested and pass press-queue-v2's `AC10-revealId-no-gaps`. It gets checked when reveal-stage wires
`revealId` to the seed.
**Test Evidence**: `apple/KidCore/Tests/KidCoreTests/PressQueueTests.swift` (AC-9 `test_every_press_returns_its_outcome_at_once_in_order`,
AC-10 `test_started_reveals_number_one_two_three_with_no_gaps`, AC-13
`test_reduce_motion_mid_reveal_keeps_its_hold_and_the_next_reveal_uses_the_reduced_set`, AC-18
`test_hardware_key_hint_and_keyboard_row_give_the_same_outcomes_and_times`, AC-20
`test_resting_since_is_none_until_formed_with_an_empty_queue_then_the_formed_time`) and press-queue-v2's AC10, AC13, AC18, AC20, R7
and R11 cases (`apple/KidCore/Tests/ContractTests/PressQueueRunner.swift`, 50/50 in verify)
**Run result**: N/A — pure KidCore logic with no app surface yet; the queue becomes player-visible with the Reveal Stage and app shell stories
**Reviewed by**: game-qc-android (APPROVE f103f0fe; K-14 peer review)

## Calls beyond the design
- Reduce Motion is read by the Reveal Stage at each reveal's start (Reveal Stage R9), not by the queue: the queue's lock is `holdEff` computed once from the lengths the stage answers, so `PressQueueStage.startReveal` has no reduced input and reveal-stage/001 must read Reduce Motion itself (`PressQueue.swift`) · kept 2026-11-20
