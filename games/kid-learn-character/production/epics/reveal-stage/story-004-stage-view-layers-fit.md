# Story 004: The SpriteKit stage: fixed layers, frame driver and the contain-and-extend fit

> **Epic**: Reveal Stage (`production/epics/reveal-stage/EPIC.md`)
> **Status**: Ready
> **Layer**: Feature
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/reveal-stage.md`
**Requirement**: `TR-reveal-003`, `TR-reveal-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Stage runtime; ADR-0002: Modules, seams and Kotlin-mappable types
**ADR Decision Summary**: One `SKView` per window with D1's fixed layers and zPositions; the stage root carries Reveal Stage F1's fit; the display-link frame driver calls `tick(now:)`; Reduce Motion read live (D6); ppi for hit sizes (D7).
**ADR Version**: ADR-0006 2026-11-18; ADR-0002 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Forbidden: never SwiftUI `SpriteView`; the adapter only maps the render plan onto nodes, no rule lives in the scene (ADR-0006 D1)
- Required: one stage root with fixed layer children and zPositions (z0 … z80); never rely on child order within a layer (ADR-0006 D1)
- Guardrail: 60 fps cap, frame p99 within 16.7 ms; a dropped frame is a bigger time step, never caught up (ADR-0006 D3)
- Required: ppi from the bundled model table (iPad) or `CGDisplayScreenSize` (Mac); unknown → the class's highest ppi (ADR-0006 D7)

**Device rows that close it** (`production/qa/device-checks-plan.md`): M-10, P-11

---

## Acceptance Criteria

*From GDD `design/gdd/reveal-stage.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-12 The four F1 rows give the listed `s_fit` and visible rect; screenshots on an 11" iPad, a 13" iPad and a 21:9 Mac window show no bars, nothing cropped, hints and tokens inside the safe stage.
- [ ] AC-13 During a parade with a creature on stage and a key queued: walkers behind the creature, specks and glyph in front, tokens and hints above (screenshot; the node-tree snapshot test is ADR-0006 Validation 2).

---

## Implementation Notes

*Derived from ADR-0006 and the epic:*

StageFit already exists in KidCore (TASK-079); this wires the `SKView`, layers, display link and `displayMetricsChanged`.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/LetterMorph/StageView.swift`
- `apple/LetterMorph/Stage/StageScene.swift`
- `apple/LetterMorphTests/StageLayerOrderTests.swift`

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

- Depends on: `production/epics/reveal-stage/story-001-start-reveal-timeline.md`
- Unlocks: `production/epics/audio-voice/story-007-sound-off-from-stored-mute.md`, `production/epics/reveal-stage/story-005-morph-on-stage.md`, `production/epics/hint-letters/story-006-size-data-look.md`, `production/epics/parade/story-007-parade-and-meter-look.md`, `production/epics/scene/story-004-scene-drawing.md`, `production/epics/keyboard-row/story-006-row-look-device.md`, `production/epics/app-shell/story-003-windows-and-overlays.md`, `production/epics/accessibility/story-006-invert-touch-sound-colour.md`
