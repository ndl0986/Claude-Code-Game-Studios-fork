# Story 003: F1 holdEff, the formed rules and the fallback lengths

> **Epic**: Press Queue (`production/epics/press-queue/EPIC.md`)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
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

- Depends on: `production/epics/press-queue/story-001-start-queue-ignore.md`
- Unlocks: `production/epics/audio-voice/story-003-hold-and-fallbacks.md`, `production/epics/press-queue/story-005-background-title-data.md`
