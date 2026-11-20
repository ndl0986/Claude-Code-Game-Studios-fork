# Story 004: AVAudioEngine adapter: primed players, graph built once, decode before Active, limiter

> **Epic**: Audio & Voice (`production/epics/audio-voice/EPIC.md`)
> **Status**: Blocked — BLOCKED: ADR-0010 is Proposed — accept it with `/architecture-decision accept ADR-0010` once decided (device rows P-1, M-14)
> **Layer**: Core
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/audio-voice.md`
**Requirement**: `TR-audio-003`, `TR-audio-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Audio engine (**Proposed**); ADR-0002: Modules, seams and Kotlin-mappable types
**ADR Decision Summary**: (Proposed) `.soloAmbient` session; a graph of 7 primed players built once; one serial queue; cuts only below −60 dBFS; freeze resumes with a rewind; nothing created on a press.
**ADR Version**: ADR-0010 2026-11-18; ADR-0002 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: (pending) ADR-0010: graph built and started once; nothing attached, created or stopped on a press; one serial `.userInteractive` queue
- Forbidden: (pending) ADR-0010: never `AVAudioPlayer` per sound, `.ambient`/`.playback`, a hard stop/pause cut, or scheduling on the main thread

**Device rows that close it** (`production/qa/device-checks-plan.md`): P-1, M-14

---

## Acceptance Criteria

*From GDD `design/gdd/audio-voice.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-10 Instrumented build: across a 60 s mash no engine or player is created, stopped or reconnected on a press; only buffers are scheduled; no decoding after the theme is Active.
- [ ] AC-11 A theme is not Active until its sfx and active-locale voice lines are decoded at the output format; decoding never runs on the main thread (debug thread assertion).
- [ ] AC-13 With all 7 players at −1 dBTP test tones at v 1, the output never exceeds `limiter_ceiling_dbtp`; at level 8 the limiter applies no gain reduction.

---

## Implementation Notes

*Derived from ADR-0010 and the epic:*

One adapter type owns AVFAudio (ADR-0010 Impl.); `playAudio()`/`connectNode` on 27, `play()`/`connect` on 26 via `#available`.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/LetterMorph/Audio/AudioEngineAdapter.swift`
- `apple/LetterMorphTests/AudioEngineAdapterTests.swift`

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

- Depends on: `production/epics/audio-voice/story-002-stacking-cap-mash.md`
- Unlocks: `production/epics/audio-voice/story-005-cuts-mute-volume.md`, `production/epics/audio-voice/story-006-session-device.md`, `production/epics/reveal-stage/story-006-reveal-feel-device.md`
