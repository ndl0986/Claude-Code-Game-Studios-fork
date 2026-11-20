# Story 007: Sound off from the stored mute: every answer is still visual

> **Epic**: Audio & Voice (`production/epics/audio-voice/EPIC.md`)
> **Status**: Ready
> **Layer**: Core
> **Type**: UI
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/audio-voice.md`
**Requirement**: `TR-audio-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0005: Settings persistence
**ADR Decision Summary**: KidCore holds the pure rules with injected clocks (D3) and seeded streams (D4); the app reaches it only through the D6 seams and `tick(now:)`, in D7's call orders.
**ADR Version**: ADR-0002 2026-11-18; ADR-0005 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: MEDIUM
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: evidence for every player-observable change is a retained screenshot (coding-standards.md)
- Required: one synchronous settings read at launch, before the first frame (ADR-0005 D2, D9)

---

## Acceptance Criteria

*From GDD `design/gdd/audio-voice.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-18 With `muted` true in the stored settings record (seeded through the Settings Store test seam, since the panel that sets it is next milestone), a full reveal, an overflow press, a tap and the parade still show their visual answers (retained screenshots).

---

## Implementation Notes

*Derived from ADR-0002 and the epic:*

Leader call (TASK-140): covered from the stored setting. Accessibility AC-14 (device muted) is accessibility/006.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `production/qa/evidence/<TASK>/<sha>/sound-off/`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY-READY skipped — Lean mode).

---

## Test Evidence

**Story Type**: UI
**Required evidence**: UI: a retained screenshot of each screen touched, in `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/audio-voice/story-003-hold-and-fallbacks.md`, `production/epics/reveal-stage/story-004-stage-view-layers-fit.md`, `production/epics/settings/story-002-store-behaviours.md`
- Unlocks: None
