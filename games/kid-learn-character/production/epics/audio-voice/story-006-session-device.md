# Story 006: Session behaviour on the device: interruptions, silent mode, latency

> **Epic**: Audio & Voice (`production/epics/audio-voice/EPIC.md`)
> **Status**: Blocked — BLOCKED: ADR-0010 is Proposed — accept it with `/architecture-decision accept ADR-0010` once decided (device rows P-1, P-8, P-9)
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/audio-voice.md`
**Requirement**: `TR-audio-002`, `TR-audio-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Audio engine (**Proposed**)
**ADR Decision Summary**: (Proposed) `.soloAmbient` session; a graph of 7 primed players built once; one serial queue; cuts only below −60 dBFS; freeze resumes with a rewind; nothing created on a press.
**ADR Version**: ADR-0010 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: (pending) ADR-0010: graph built and started once; nothing attached, created or stopped on a press; one serial `.userInteractive` queue

**Device rows that close it** (`production/qa/device-checks-plan.md`): P-1, P-8, P-9

---

## Acceptance Criteria

*From GDD `design/gdd/audio-voice.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-15 After an interruption that ends with "should resume", the next press chimes; after a route change and a media-services reset the buffers re-prime and the next press chimes; events during re-priming are skipped and logged.
- [ ] AC-16 On the child's iPad (built-in or wired), TASK-033 240 fps procedure: the chime's onset is no more than one display frame after the first frame answering the press.
- [ ] AC-20 iPad silent mode: no sound for any event, every visual answer still shown, other apps' music stopped (`.soloAmbient`).

---

## Implementation Notes

*Derived from ADR-0010 and the epic:*

Device-only; spike runs are ADR evidence, the production app closes the ACs.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `production/qa/evidence/<TASK>/<sha>/audio-device.md`

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
