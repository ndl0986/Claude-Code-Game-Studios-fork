# Story 003: The word never cut by the queue, and the missing-sound fallbacks

> **Epic**: Audio & Voice (`production/epics/audio-voice/EPIC.md`)
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/audio-voice.md`
**Requirement**: `TR-audio-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0004: Contracts, fixtures and harness
**ADR Decision Summary**: KidCore holds the pure rules with injected clocks (D3) and seeded streams (D4); the app reaches it only through the D6 seams and `tick(now:)`, in D7's call orders.
**ADR Version**: ADR-0002 2026-11-18; ADR-0004 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Required: every runner calls only the core's public API; hand-written cases from the GDD; never edit a merged `cases.json` (ADR-0004 D4–D6)

---

## Acceptance Criteria

*From GDD `design/gdd/audio-voice.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-7 With the Press Queue in the loop, a key queued during "quetzalcoatlus" (1.15 s) starts no earlier than s 3.85 and no later than 4.5; the word is never cut.
- [ ] AC-17 A test theme missing an sfx, a word line, and both voice lines for one key: the reveals skip, play the letter only, or the chime only, each with one debug log line and no crash.

---

## Implementation Notes

*Derived from ADR-0002 and the epic:*

Integration of the audio plan with the Press Queue (press-queue/003's F1 hold).

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Tests/KidCoreTests/AudioQueueIntegrationTests.swift`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY-READY skipped — Lean mode).

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: Integration: an integration test (path under Files) OR a documented run in `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/audio-voice/story-001-event-schedule.md`, `production/epics/press-queue/story-003-hold-and-formed-rules.md`
- Unlocks: None
