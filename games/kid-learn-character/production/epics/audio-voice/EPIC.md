# Epic: Audio & Voice

> **Layer**: Core
> **GDD**: design/gdd/audio-voice.md
> **Architecture Module**: KidCore (audio plan: E1–E12 schedule, gain chain, duck, mash, word_end, player policy) + app (`AVAudioEngine` adapter)
> **Milestone**: Demo 1 (`production/milestones/demo-1.md`, K-48)
> **Status**: Ready
> **Stories**: 6 stories (TASK-140)

## Overview

Voice (Kokoro, K-41) and creature sound for every reveal: a fixed set of primed players, nothing created or decoded on a press, no stacking speech, and no click when a sound is cut.

## Governing ADRs

| ADR | Status | Decision Summary | Engine Risk |
|-----|--------|------------------|-------------|
| ADR-0002: Modules, seams and Kotlin-mappable types | Accepted | D6/D7 seams and call order | LOW |
| ADR-0004: Contracts, fixtures and harness | Accepted | audio-plan-v1 | LOW |
| ADR-0003: Content pipeline | Accepted | D5/D6 pre-rendered voice and sfx | HIGH |
| ADR-0010: Audio engine | **Proposed** | primed players, scheduling, fades, limiter, session | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage | Demo 1 |
|-------|-------------|--------------|--------|
| TR-audio-001 | Event schedule E1-E12, no stacking speech, mash ceiling, freeze pause (R1-R4, R6) | ADR-0002 D6/D7; ADR-0004 audio-plan-v1 ✅ | in |
| TR-audio-002 | Press to chime within one frame of the first answering frame, on a device (AC-16) | ❌ No Accepted ADR (ADR-0010 Proposed); matrix: ADR-0010 D4/D9 (Proposed) | in |
| TR-audio-003 | Fixed primed players, nothing created or decoded on a press, max 7 sounds (R2, AC-5, AC-10) | ❌ No Accepted ADR (ADR-0010 Proposed); matrix: ADR-0010 D2/D4 (Proposed) | in |
| TR-audio-004 | No click on a cut; mute and volume; limiter and mash gain F1 (R2.2, R3, R4.5, AC-9, AC-13, AC-14) | ❌ No Accepted ADR (ADR-0010 Proposed); matrix: ADR-0010 D2/D5 (Proposed) | in |
| TR-audio-005 | Session category, interruptions, silent mode, route and format changes (R6, AC-15, AC-20, AC-21) | ❌ No Accepted ADR (ADR-0010 Proposed); matrix: ADR-0010 D1/D7/D8 (Proposed) | in |
| TR-audio-006 | Voice source, licence and no run-time TTS (R8, Q8, L-09) | ADR-0003 D5/D6; ADR-0010 D10 ✅ | in |

**Requirements covered by Accepted ADRs**: 2 / 6
**Untraced Requirements**: TR-audio-002, TR-audio-003, TR-audio-004, TR-audio-005 (Proposed-only or Partial; see the coverage column)

## Device Rows That Gate Story Closure

(`production/qa/device-checks-plan.md`; a spike run is ADR evidence, never AC evidence.)

- **P-1**: press → picture and press → sound latency (Audio AC-16)
- **P-7, M-14**: no click on a cut (Audio AC-9; P-7 open: TASK-127 pop, TASK-128)
- **P-8**: interruptions (AC-15)
- **P-9**: silent switch (AC-20)

## Contracts

(`contracts/README.md` registry; `story:<x>` is the story stem that starts the runner.)

- audio-plan-v1 (`not-started: story:audio-voice`)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Audio plan: the E1–E9 event schedule, press sounds and the Title](story-001-event-schedule.md) | Logic | Ready | ADR-0002, ADR-0004 |
| 002 | [Audio plan: speech never stacks, the 7-player cap and the mash ceiling](story-002-stacking-cap-mash.md) | Logic | Ready | ADR-0002, ADR-0004 |
| 003 | [The word never cut by the queue, and the missing-sound fallbacks](story-003-hold-and-fallbacks.md) | Integration | Ready | ADR-0002, ADR-0004 |
| 004 | [AVAudioEngine adapter: primed players, graph built once, decode before Active, limiter](story-004-engine-adapter.md) | Integration | Blocked | ADR-0010, ADR-0002 |
| 005 | [No click on a cut; mute and volume follow the gain chain](story-005-cuts-mute-volume.md) | Integration | Blocked | ADR-0010 |
| 006 | [Session behaviour on the device: interruptions, silent mode, latency](story-006-session-device.md) | Integration | Blocked | ADR-0010 |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every Demo 1 acceptance criterion of design/gdd/audio-voice.md verified (criteria of out-of-Demo-1 requirements stay open for the next milestone)
- Logic and Integration stories have passing tests in the test root; each contract above runs (`runner:` row) instead of `not-started`
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/` (a lead sign-off too for Visual/Feel)
- Each device row above that gates a story is PASS on the production app, or the story records it NOT ASSESSED with the reason
