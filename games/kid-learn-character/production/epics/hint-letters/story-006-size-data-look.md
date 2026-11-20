# Story 006: Hit size from ppi, the knob checks, and the look on Day and Night

> **Epic**: Hint Letters (`production/epics/hint-letters/EPIC.md`)
> **Status**: Ready
> **Layer**: Feature
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/hint-letters.md`
**Requirement**: `TR-hints-002`, `TR-hints-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Stage runtime; ADR-0003: Content pipeline
**ADR Decision Summary**: One `SKView` per window with D1's fixed layers and zPositions; the stage root carries Reveal Stage F1's fit; the display-link frame driver calls `tick(now:)`; Reduce Motion read live (D6); ppi for hit sizes (D7).
**ADR Version**: ADR-0006 2026-11-18; ADR-0003 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: ppi from the bundled model table (iPad) or `CGDisplayScreenSize` (Mac); unknown → the class's highest ppi (ADR-0006 D7)
- Forbidden: never hard-code tuning values; timing and knobs are bundled data (ADR-0001 D6)
- Required: evidence for every player-observable change is a retained screenshot (coding-standards.md)

**Device rows that close it** (`production/qa/device-checks-plan.md`): M-10

---

## Acceptance Criteria

*From GDD `design/gdd/hint-letters.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-19 For each F5 row `hit_d_mm` and `k` match within 0.1 mm / 0.01; at k > 1 bubble, `hitRadius` and clearances scale by k.
- [ ] AC-21 The build fails for each knob missing, non-numeric or out of range, and for a slot failing F4 statically.
- [ ] AC-22 Screenshots on Day and Night at the 11" iPad and a 16:9 Mac window: the widest creature, 3 hints and 3 tokens with no overlap; one Reduce Motion frame; the full-queue case where a touched hint stays (Press Queue AC-19).

---

## Implementation Notes

*Derived from ADR-0006 and the epic:*

Demo 1 has no moon, so the moon in AC-22's worst case is absent; the screenshot notes it.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/HintLetters.swift`
- `apple/KidCore/Tests/KidCoreTests/HintLettersTests.swift`
- `apple/LetterMorph/Stage/HintNodes.swift`
- `production/qa/evidence/<TASK>/<sha>/hints/`

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

- Depends on: `production/epics/hint-letters/story-003-clearances-slots.md`, `production/epics/reveal-stage/story-004-stage-view-layers-fit.md`
- Unlocks: `production/epics/accessibility/story-006-invert-touch-sound-colour.md`
