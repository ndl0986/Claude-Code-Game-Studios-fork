# Story 006: The reveal and its sounds on a real iPad

> **Epic**: Reveal Stage (`production/epics/reveal-stage/EPIC.md`)
> **Status**: Blocked — BLOCKED: ADR-0010 is Proposed — accept it with `/architecture-decision accept ADR-0010` once decided (device rows P-1); also needs reveal-stage/005 (ADR-0009)
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/reveal-stage.md`
**Requirement**: `TR-reveal-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Audio engine (**Proposed**); ADR-0009: Render path (**Proposed**)
**ADR Decision Summary**: (Proposed) `.soloAmbient` session; a graph of 7 primed players built once; one serial queue; cuts only below −60 dBFS; freeze resumes with a rewind; nothing created on a press.
**ADR Version**: ADR-0010 2026-11-18; ADR-0009 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: evidence for every player-observable change is a retained screenshot (coding-standards.md)

**Device rows that close it** (`production/qa/device-checks-plan.md`): P-1

---

## Acceptance Criteria

*From GDD `design/gdd/reveal-stage.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-16 The reveal and its sounds on the child's iPad, TASK-033 procedure (press → picture and press → sound), with a lead sign-off.

---

## Implementation Notes

*Derived from ADR-0010 and the epic:*

(Proposed) `.soloAmbient` session; a graph of 7 primed players built once; one serial queue; cuts only below −60 dBFS; freeze resumes with a rewind; nothing created on a press.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `production/qa/evidence/<TASK>/<sha>/reveal-feel.md`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY-READY skipped — Lean mode).

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: Visual/Feel: a retained screenshot in `production/qa/evidence/` + lead sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/reveal-stage/story-005-morph-on-stage.md`, `production/epics/audio-voice/story-004-engine-adapter.md`
- Unlocks: None
