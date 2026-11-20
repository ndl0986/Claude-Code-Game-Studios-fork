# Story 005: Launch times on the child's iPad and the Mac

> **Epic**: App Shell & Title (`production/epics/app-shell/EPIC.md`)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/app-shell-title.md`
**Requirement**: `TR-shell-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Stage runtime
**ADR Decision Summary**: One `SKView` per window with D1's fixed layers and zPositions; the stage root carries Reveal Stage F1's fit; the display-link frame driver calls `tick(now:)`; Reduce Motion read live (D6); ppi for hit sizes (D7).
**ADR Version**: ADR-0006 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: evidence for every player-observable change is a retained screenshot (coding-standards.md)

**Device rows that close it** (`production/qa/device-checks-plan.md`): P-10, M-15

---

## Acceptance Criteria

*From GDD `design/gdd/app-shell-title.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-13 Launch-to-first-frame and launch-to-playable measured on the child's iPad and the Mac, recorded (no budget set; advisory).

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

- `production/qa/evidence/<TASK>/<sha>/launch-times.md`

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

- Depends on: `production/epics/app-shell/story-001-launch-order-first-frame.md`
- Unlocks: None
