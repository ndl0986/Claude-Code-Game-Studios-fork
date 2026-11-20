# Story 005: The row lift, the horizon lift during a parade, and Reduce Motion

> **Epic**: Scene: Time of Day & Weather (`production/epics/scene/EPIC.md`)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/scene-time-weather.md`
**Requirement**: `TR-scene-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Stage runtime; ADR-0002: Modules, seams and Kotlin-mappable types
**ADR Decision Summary**: One `SKView` per window with D1's fixed layers and zPositions; the stage root carries Reveal Stage F1's fit; the display-link frame driver calls `tick(now:)`; Reduce Motion read live (D6); ppi for hit sizes (D7).
**ADR Version**: ADR-0006 2026-11-18; ADR-0002 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: Reduce Motion is read live and applied at the next reveal (ADR-0006 D6)
- Required: evidence for every player-observable change is a retained screenshot (coding-standards.md)

---

## Acceptance Criteria

*From GDD `design/gdd/scene-time-weather.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-13 With the keyboard row on, the hills and ground move up by `row_lift` on the next frame.
- [ ] AC-14 During a parade at Dusk the horizon stop reaches the F5 colour within 0.6 s and returns within 0.6 s after; at 16:07 the target is the F5 mix.
- [ ] AC-15 Reduce Motion: clouds still, rain and snow at half count and half speed with the tilt kept, stars at constant alpha.

---

## Implementation Notes

*Derived from ADR-0006 and the epic:*

One `SKView` per window with D1's fixed layers and zPositions; the stage root carries Reveal Stage F1's fit; the display-link frame driver calls `tick(now:)`; Reduce Motion read live (D6); ppi for hit sizes (D7).

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/LetterMorph/Stage/SceneNodes.swift`
- `production/qa/evidence/<TASK>/<sha>/scene/`

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

- Depends on: `production/epics/scene/story-004-scene-drawing.md`, `production/epics/parade/story-002-walk-positions-clock.md`
- Unlocks: None
