# Story 004: Draw the sky, hills and ground: extension, sun and no moon disc, the Title

> **Epic**: Scene: Time of Day & Weather (`production/epics/scene/EPIC.md`)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: M
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
- Required: one stage root with fixed layer children and zPositions (z0 … z80); never rely on child order within a layer (ADR-0006 D1)
- Required: evidence for every player-observable change is a retained screenshot (coding-standards.md)

---

## Acceptance Criteria

*From GDD `design/gdd/scene-time-weather.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-12 On the four F1 rects the sky and ground fill the screen, no bar, no seam at x 0 or 1280, the sky above y 0 equals the top stop (screenshots).
- [ ] AC-16 At Night no moon disc and no sun; in Morning and Day the sun `#ecd29a` and no moon disc.
- [ ] AC-17 The Title at 21:00 with snow shows the Night sky and snow, no lift.

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

- Depends on: `production/epics/scene/story-002-weather-model.md`, `production/epics/reveal-stage/story-004-stage-view-layers-fit.md`
- Unlocks: `production/epics/scene/story-005-ground-lift-reduce-motion.md`, `production/epics/scene/story-006-weather-device-cost.md`, `production/epics/accessibility/story-004-flash-g4-offline.md`
