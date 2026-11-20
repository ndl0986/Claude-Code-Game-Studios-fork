# Story 003: F1 holdEff, the formed rules and the fallback lengths

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

- [ ] AC-7 For each F1 row holdEff equals the table within 1e-9; a missing `voiceDurations` entry gives `formedS + 1.5` and one log line.
- [ ] AC-11 A `formed` for a non-current id or a second `formed` is ignored; with none, formed at `r0 + revealLen + 1.0` with one log line.
  *Note 2026-11-20 (K-53, TASK-147):* the missing-entry bound is now `formedS + word_offset_s + word_len_max_s`
  (1.75 s with the shipped knobs, was 1.5); press-queue-v2's `F1-no-voiceDurations-entry` expects 4.20.
- [ ] AC-12 Fallback `{formedS, revealLen}` are used for holdEff; AC-24 `hasWord` false gives `holdEff = max(hold_s, revealLen)`.

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

- Depends on: `production/epics/press-queue/story-001-start-queue-ignore.md`
- Unlocks: `production/epics/audio-voice/story-003-hold-and-fallbacks.md`, `production/epics/press-queue/story-005-background-title-data.md`

## Completion Notes
**Completed**: 2026-11-20
**Criteria**: 3/3 passing (no deferred items)
**Deviations**: ADVISORY: AC-7's text says `formedS + 1.5`; K-53 (TASK-147) made the missing-entry bound
`formedS + word_offset_s + word_len_max_s` (1.75 with the shipped knobs). The code and press-queue-v2 follow K-53; a dated note
in the story says so.
**Test Evidence**: `apple/KidCore/Tests/KidCoreTests/PressQueueTests.swift` (AC-7 `test_hold_follows_the_F1_table_rows`,
`test_a_missing_word_length_uses_the_bound_and_writes_one_log_line`; AC-11
`test_a_reveal_never_formed_is_formed_by_the_timeout_at_exactly_its_bound`, `test_the_timeout_and_the_advance_happen_in_one_tick`,
`test_formed_for_another_reveal_or_twice_changes_nothing`; AC-12 `test_fallback_lengths_from_the_stage_set_the_hold`; AC-24
`test_no_word_gives_the_longer_of_hold_and_reveal`) and press-queue-v2's F1 (11), AC11, AC12, AC24, R5 and F4 cases
(`apple/KidCore/Tests/ContractTests/PressQueueRunner.swift`, 50/50 in verify)
**Run result**: N/A — pure KidCore logic with no app surface yet; the queue becomes player-visible with the Reveal Stage and app shell stories
**Reviewed by**: game-qc-android (APPROVE fd045607; K-14 peer review)

## Calls beyond the design
- A reveal with no word line (`hasWord` false) writes no missing-`voiceDurations` log line: no word plays, so no entry is needed (`PressQueue.swift`, start) · kept 2026-11-20
