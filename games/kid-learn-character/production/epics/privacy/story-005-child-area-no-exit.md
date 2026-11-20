# Story 005: Every key and touch target in the child area stays in the app

> **Epic**: Privacy & Kids Compliance (`production/epics/privacy/EPIC.md`)
> **Status**: Blocked — BLOCKED: depends on parade/007 and keyboard-row/006, which are Blocked on ADR-0009 and ADR-0007 (Proposed); the rest of the child area can be inventoried meanwhile
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/privacy-kids-compliance.md` — AC-04 (PKC-02)
**Requirement**: `TR-pkc-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Build, verify and PKC gates; ADR-0001: Native Apple stack
**ADR Decision Summary**: ADR-0011 D5: QC runs the PKC rows on the signed Release product and writes every verdict; ADR-0001 D8: no network, no link out of the app.
**ADR Version**: ADR-0011 2026-11-18; ADR-0001 2026-11-17

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: A device run on the production app; MAC FREE for the Mac half (K-34).

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: no network call, no location (ADR-0001 D8)
- Required: QC writes every PKC verdict; evidence under `production/qa/evidence/<TASK>/<short-sha>/` (ADR-0011 D5, D6)
- Required: MAC FREE for anything taking the screen, keyboard or focus (ADR-0011 D2)

**Device rows that close it** (`production/qa/device-checks-plan.md`): run on the Demo 1 candidate on the child's iPad and the Mac (with P-0 and the Mac launch)

---

## Acceptance Criteria

*From GDD `design/gdd/privacy-kids-compliance.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-04 (PKC-02 child area): every key A–Z and 0–9, and every touch target in the child area — the hint letters, cast members, the parade and the parade meter, the keyboard row when shown, and every other target in QC's inventory `production/qa/privacy-gate/touch-targets.md` — leaves the app in front and opens no other app, browser, store page or system sheet.
- [ ] QC writes the inventory `production/qa/privacy-gate/touch-targets.md` from the Reveal Stage, Hint Letters, Parade and Keyboard Row GDDs before the run, and the run covers each row in it.

---

## Implementation Notes

*Derived from ADR-0011 and the epic:*

Not gate-dependent (game-qc-android, TASK-137 review), so it is in Demo 1; it moved from the Foundation batch to this one because it needs the child area built. The moon (Parent Gate) is not in Demo 1, so it is absent from the inventory until the next milestone. The verdict feeds privacy/004's Demo 1 results.md.

---

## Out of Scope

- AC-08 (every grown-up item only behind the gate): out of Demo 1 scope (next milestone), as privacy/004 records.

---

## Files

*Planned; `/dev-story` replaces this list.*

- `production/qa/privacy-gate/touch-targets.md` (QC)
- `production/qa/evidence/<TASK>/<sha>/pkc-02-child-area.md`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY-READY skipped — Lean mode).

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: Integration: a documented run in `production/qa/evidence/` (screen recording or screenshots per target class)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/reveal-stage/story-004-stage-view-layers-fit.md`, `production/epics/hint-letters/story-006-size-data-look.md`, `production/epics/parade/story-007-parade-and-meter-look.md`, `production/epics/keyboard-row/story-006-row-look-device.md`, `production/epics/privacy/story-001-release-static-checks.md`
- Unlocks: `production/epics/privacy/story-004-demo1-results.md`
