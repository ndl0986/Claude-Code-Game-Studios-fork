# Story 006: Smart Invert, the child touch floor, sound off and no colour-only meaning

> **Epic**: Accessibility (`production/epics/accessibility/EPIC.md`)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/accessibility.md`
**Requirement**: `TR-a11y-002`, `TR-a11y-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Stage runtime
**ADR Decision Summary**: One `SKView` per window with D1's fixed layers and zPositions; the stage root carries Reveal Stage F1's fit; the display-link frame driver calls `tick(now:)`; Reduce Motion read live (D6); ppi for hit sizes (D7).
**ADR Version**: ADR-0006 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: the `SKView` sets `accessibilityIgnoresInvertColors = true` on iPad; the panel does not (ADR-0006 D5)
- Required: ppi from the bundled model table (iPad) or `CGDisplayScreenSize` (Mac); unknown → the class's highest ppi (ADR-0006 D7)
- Required: evidence for every player-observable change is a retained screenshot (coding-standards.md)

**Device rows that close it** (`production/qa/device-checks-plan.md`): P-13

---

## Acceptance Criteria

*From GDD `design/gdd/accessibility.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-15 (stage half) With Smart Invert on, the stage's pixels are unchanged (screenshot pair; the panel half is next milestone).
- [ ] AC-12 On every MVP device class a hint's hit diameter and a row key's hit rect are ≥ 18 mm.
- [ ] AC-14 With the device muted, a 2-minute seeded session's screenshots show a visual answer for every Audio R1 event (also Audio AC-18).
- [ ] AC-11 A greyscale screenshot still shows the backup cue for hint vs queued token (the moon ring is next milestone).

---

## Implementation Notes

*Derived from ADR-0006 and the epic:*

**Out:** AC-13 (grown-up panel targets) is next milestone; AC-17 (Android) waits for the Android build (K-03); AC-16 is privacy/002's scan.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `production/qa/evidence/<TASK>/<sha>/a11y/`

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

- Depends on: `production/epics/reveal-stage/story-004-stage-view-layers-fit.md`, `production/epics/hint-letters/story-006-size-data-look.md`, `production/epics/keyboard-row/story-001-layout-size-origin.md`
- Unlocks: None
