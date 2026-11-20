# Story 006: The row on the iPad and the Mac: look, Title and background, attach and detach

> **Epic**: On-screen Keyboard Row (`production/epics/keyboard-row/EPIC.md`)
> **Status**: Blocked — BLOCKED: ADR-0007 is Proposed — accept it with `/architecture-decision accept ADR-0007` once decided (device rows P-15; AC-25 needs an iPad hardware keyboard)
> **Layer**: Feature
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/onscreen-keyboard-row.md` (as merged by TASK-135, 5647a15f)
**Requirement**: `TR-kbrow-003`, `TR-kbrow-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Stage runtime; ADR-0007: Input adapters (**Proposed**)
**ADR Decision Summary**: One `SKView` per window with D1's fixed layers and zPositions; the stage root carries Reveal Stage F1's fit; the display-link frame driver calls `tick(now:)`; Reduce Motion read live (D6); ppi for hit sizes (D7).
**ADR Version**: ADR-0006 2026-11-18; ADR-0007 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: one stage root with fixed layer children and zPositions (z0 … z80); never rely on child order within a layer (ADR-0006 D1)
- Required: evidence for every player-observable change is a retained screenshot (coding-standards.md)

**Device rows that close it** (`production/qa/device-checks-plan.md`): P-15

---

## Acceptance Criteria

*From GDD `design/gdd/onscreen-keyboard-row.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-18 On the 11" iPad and the 21:9 Mac rect, with REX and an 8-letter word: keys centred in the safe stage, cream with gold letters, no overlap with hints or tokens (screenshots).
- [ ] AC-14 (Title and background half) Hidden on the Title; during a parade drawn at full alpha and touchable; a short background and return shows REX again with R still counted.
- [ ] AC-25 On a real iPad with no keyboard Play shows the row; attaching a hardware keyboard hides it within about a second; detaching shows it again; on the Mac it never shows.

---

## Implementation Notes

*Derived from ADR-0006 and the epic:*

TASK-135 (K-49) is **merged at 5647a15f**; the ACs here are the merged GDD's (identical to 180228bf, checked). TASK-141 cuts **keyboard-row-v2** to supersede v1 with the K-49 cases. AC-25 needs an iPad hardware keyboard: NOT ASSESSED until one is available.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/LetterMorph/Stage/KeyboardRowNodes.swift`
- `production/qa/evidence/<TASK>/<sha>/keyboard-row/`

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

- Depends on: `production/epics/keyboard-row/story-005-auto-on-keyboard-presence.md`, `production/epics/reveal-stage/story-004-stage-view-layers-fit.md`
- Unlocks: None
