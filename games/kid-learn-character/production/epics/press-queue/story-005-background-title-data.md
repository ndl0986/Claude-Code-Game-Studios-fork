# Story 005: Background, panel and gate logic, the first press after the Title, the theme switch, and the data checks

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

**Contracts**: press-queue-v1 (`not-started: story:press-queue` → `runner:` with story 005, the epic's last logic story)

---

## Acceptance Criteria

*From GDD `design/gdd/press-queue.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-15 / AC-14 (logic) Background or panel open mid-morph with 3 queued: queue empty, current formed (settle once), no outcome or sound for the dropped presses, the next press after return or close starts at once.
- [ ] AC-17 Play entered by a key: the first press starts at once with revealId 1; AC-16 (logic) after a theme switch the next started item comes from the new theme.
- [ ] AC-23 (logic) A reveal at s 1.0 with 2 queued, the gate challenge for 20 s then a timeout: still 2 queued, play clock advanced 0 s, the first starts at play time `r0 + holdEff`; a correct answer clears the queue and settles. The press-queue-v1 cases all pass and its row flips to `runner:`.
  *Note 2026-11-20 (TASK-147):* the contract is **press-queue-v2** (v1 is superseded). All 50 v2 cases pass and its
  row is `runner: PressQueueRunner`. The play clock (`PlayClock`, KidCore, ADR-0002 D3) and the queue's `freeze()`,
  `resume()` and `settle()` are this story's; the Reveal Stage will own pausing the clock (architecture §3), which the
  runner plays for now.
- [ ] AC-21 The build fails for `hold_s`, `queue_max` or `formed_timeout_s` missing, non-numeric or out of range, and when the F1 build check fails; no timing literal in the queue's code.
  *Note 2026-11-20 (leader's option a):* `content/data/press-queue.json` (ADR-0003 D1) holds `hold_s` 3.0, `queue_max`
  3 and `formed_timeout_s` 1.0; `kidtools validate` (verify) fails a value missing, not a number or outside its Tuning
  Knobs range (KidCore `PressQueueData.problems`). F1's build checks (`PressQueueData.f1BuildCheck`) are built and
  unit-tested, but on the real content they print **NOT ASSESSED** until MorphCore's timing data
  (`content/data/morph-timing.json`, morphcore/001) and Audio & Voice's data exist. `PressQueue.swift` has no timing
  literal.

---

## Implementation Notes

*Derived from ADR-0002 and the epic:*

The whole state machine is KidCore (Module Ownership). Tests use an injected clock, a fake Reveal Stage and fixed `voiceDurations`. (Freeze/resume, panel and theme-switch **logic** is in Demo 1 so the contract runner passes every case; only their UI and device checks are next milestone — game-qc-android, TASK-140.) AC-19 (hint on overflow) is press-queue/006.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

- `apple/KidCore/Sources/KidCore/PlayClock.swift`
- `apple/KidCore/Sources/KidCore/PressQueue.swift`
- `apple/KidCore/Sources/KidCore/PressQueueData.swift`
- `apple/KidCore/Tests/KidCoreTests/PressQueueTests.swift`
- `apple/KidCore/Tests/KidCoreTests/PressQueueDataTests.swift`
- `apple/KidCore/Tests/ContractTests/PressQueueRunner.swift`
- `apple/KidCore/Tests/ContractTests/ContractHarness.swift`
- `apple/Tools/Sources/ToolsCore/ContentValidator.swift`
- `apple/Tools/Sources/kidtools/main.swift`
- `apple/Tools/Tests/ToolsTests/DataValidatorTests.swift`
- `content/data/press-queue.json`
- `contracts/README.md`
- `contracts/kidcore-api.md`
- `design/gdd/press-queue.md`

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
- Unlocks: `production/epics/press-queue/story-006-hint-on-overflow.md`
