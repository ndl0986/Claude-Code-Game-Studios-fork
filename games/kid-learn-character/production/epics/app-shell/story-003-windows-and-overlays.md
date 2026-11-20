# Story 003: Windows on iPad and Mac, and the iPad status bar and home indicator

> **Epic**: App Shell & Title (`production/epics/app-shell/EPIC.md`)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/app-shell-title.md`
**Requirement**: `TR-shell-003`, `TR-shell-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Stage runtime
**ADR Decision Summary**: One `SKView` per window with D1's fixed layers and zPositions; the stage root carries Reveal Stage F1's fit; the display-link frame driver calls `tick(now:)`; Reduce Motion read live (D6); ppi for hit sizes (D7).
**ADR Version**: ADR-0006 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: Mac, kiosk off: one resizable window, minimum 960 × 540 pt (ADR-0006 D4)
- Required: iPad status bar hidden (27: `.toolbarVisibility(.hidden, for: .statusBar)`, 26: `.statusBarHidden(true)`); home indicator and edge deferral follow `edgeDeferral` (ADR-0006 D4 note)
- Required: evidence for every player-observable change is a retained screenshot (coding-standards.md)

**Device rows that close it** (`production/qa/device-checks-plan.md`): M-10, P-11, P-16

---

## Acceptance Criteria

*From GDD `design/gdd/app-shell-title.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-10 iPad full screen in both landscape and both portrait directions (K-39), Split View narrow and Stage Manager; a Mac window at the minimum and at full screen: the safe stage whole and inside the safe area, portrait shows more sky and ground, no bars (screenshots).
- [ ] AC-14 (Demo 1 half) On the Title and in Play the status bar and home indicator are hidden; a single swipe up or down from an edge leaves the app in front, a second acts; checked with Guided Access off.

---

## Implementation Notes

*Derived from ADR-0006 and the epic:*

TR-shell-004 is Partial (only ADR-0006 D4's note names it). The panel half of AC-14 and the kiosk window are the next milestone.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/LetterMorph/LetterMorphApp.swift`
- `production/qa/evidence/<TASK>/<sha>/windows/`

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

- Depends on: `production/epics/reveal-stage/story-004-stage-view-layers-fit.md`
- Unlocks: None
