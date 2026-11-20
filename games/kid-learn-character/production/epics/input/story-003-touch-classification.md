# Story 003: Classify touches on the stage: hints within their radius, sparkle on empty stage

> **Epic**: Input & Key Filter (`production/epics/input/EPIC.md`)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/input-key-filter.md` — (AC-3 a, b, d, e, f)
**Requirement**: `TR-input-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0006: Stage runtime; ADR-0004: Contracts, fixtures and harness
**ADR Decision Summary**: ADR-0002 D5/D6 and ADR-0006 D7: touches arrive as `TouchEvent` in window px with `pxPerPt`; hit sizes from ppi; layers checked top-down.
**ADR Version**: ADR-0002 2026-11-18; ADR-0006 2026-11-18; ADR-0004 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore geometry.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: touches go out as `TouchEvent` in window px with the published `pxPerPt`, no stage transform in the adapter (ADR-0006 D2)
- Required: ordered state is an array or explicitly sorted (ADR-0002 D2)

---

## Acceptance Criteria

*From GDD `design/gdd/input-key-filter.md`, scoped to this story:*

- [ ] A hint at (400, 200), `drawRadius` 60, scale 1.25: touches at 74.9 and 75.0 are presses of its key with `source = hint(id)` and its origin; at 75.1 it falls through; a fading hint (opacity 0.1) is still a press and marked touched (AC-3 a, b).
- [ ] A touch on no hint, row key, moon or cast member gives `sparkle(point)`; two pointers on two hints in one event give two presses in delivery order (AC-3 d, e).
- [ ] With the keyboard row off, its hidden area is not a row press (AC-3 f).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0002 first):*

AC-3 c (a hint over the moon) needs the Parent Gate's moon: next milestone.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- None

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/TouchClassifier.swift`
- `apple/KidCore/Tests/KidCoreTests/TouchClassifierTests.swift`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY-READY skipped — Lean mode).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: Logic: a unit test in the package's test target (path under Files) — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/input/story-001-key-classifier.md`
- Unlocks: `production/epics/input/story-007-keys-and-touch-same-reveal.md`
