# Story 002: Audio plan: speech never stacks, the 7-player cap and the mash ceiling

> **Epic**: Audio & Voice (`production/epics/audio-voice/EPIC.md`)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/audio-voice.md`
**Requirement**: `TR-audio-001`, `TR-audio-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0004: Contracts, fixtures and harness
**ADR Decision Summary**: KidCore holds the pure rules with injected clocks (D3) and seeded streams (D4); the app reaches it only through the D6 seams and `tick(now:)`, in D7's call orders.
**ADR Version**: ADR-0002 2026-11-18; ADR-0004 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Forbidden: never let output depend on `Set` or `Dictionary` iteration order — a review rule (ADR-0002 D2)

---

## Acceptance Criteria

*From GDD `design/gdd/audio-voice.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-4 At most one voice line plays at any moment; E6 always stops a line still playing (the click-free cut itself is story 005).
- [ ] AC-5 Under 10 presses/s for 60 s: never more than 7 sounds, never more than 4 on the ui bus, and the oldest ui sound is reused.
- [ ] AC-8 F3 gives m 1.0, 0.67, 0.40, 0.35 for n 0, 1, 3, 9; the ui bus never exceeds the single-chime gain; ten presses in one batch at one timestamp get n 0…9 in delivery order.

---

## Implementation Notes

*Derived from ADR-0002 and the epic:*

Pure policy in the plan; TR-audio-003's "nothing decoded on a press" is the engine's (story 004).

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/AudioPlan.swift`
- `apple/KidCore/Tests/KidCoreTests/AudioPlanTests.swift`

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

- Depends on: `production/epics/audio-voice/story-001-event-schedule.md`
- Unlocks: `production/epics/audio-voice/story-004-engine-adapter.md`
