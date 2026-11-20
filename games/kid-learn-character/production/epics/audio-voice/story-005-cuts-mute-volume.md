# Story 005: No click on a cut; mute and volume follow the gain chain

> **Epic**: Audio & Voice (`production/epics/audio-voice/EPIC.md`)
> **Status**: Blocked — BLOCKED: ADR-0010 is Proposed — accept it with `/architecture-decision accept ADR-0010` once decided (device rows P-7 (open), M-14)
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/audio-voice.md`
**Requirement**: `TR-audio-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Audio engine (**Proposed**)
**ADR Decision Summary**: (Proposed) `.soloAmbient` session; a graph of 7 primed players built once; one serial queue; cuts only below −60 dBFS; freeze resumes with a rewind; nothing created on a press.
**ADR Version**: ADR-0010 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: (pending) ADR-0010: graph built and started once; nothing attached, created or stopped on a press; one serial `.userInteractive` queue
- Forbidden: (pending) ADR-0010: never `AVAudioPlayer` per sound, `.ambient`/`.playback`, a hard stop/pause cut, or scheduling on the main thread

**Device rows that close it** (`production/qa/device-checks-plan.md`): P-7, M-14

---

## Acceptance Criteria

*From GDD `design/gdd/audio-voice.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-9 Cutting a playing voice line, cast sound and parade tune (by a new reveal, mute and headphones out) shows no discontinuity above −60 dBFS in an output capture; on the built-in speaker no click is heard.
- [ ] AC-14 Mute silences within `cut_fade_s` and cuts voice and cast; unmute plays nothing until the next event; at level 8 the main gain is 0.64 × 0.708 = 0.45 (F1).

---

## Implementation Notes

*Derived from ADR-0010 and the epic:*

TASK-127 P-7 is FAIL (open): a pop was heard on the iPad; TASK-128's whole-sound detector and "Tone, no event" split it at the weekend session. The panel cut and slider drag in AC-9/AC-14 are the next milestone.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/LetterMorph/Audio/AudioEngineAdapter.swift`
- `production/qa/evidence/<TASK>/<sha>/p7-m14.md`

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

- Depends on: `production/epics/audio-voice/story-004-engine-adapter.md`
- Unlocks: None
