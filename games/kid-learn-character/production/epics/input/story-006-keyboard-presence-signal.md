# Story 006: Keyboard-presence signal that shows the on-screen row when no hardware keyboard is attached

> **Epic**: Input & Key Filter (`production/epics/input/EPIC.md`)
> **Status**: Blocked — BLOCKED: blocked-by TASK-135 (K-49 design change: no ACs yet), and ADR-0007 is Proposed for the platform read
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/input-key-filter.md;` — onscreen-keyboard-row.md R8 (as revised by TASK-135)
**Requirement**: `TR-input-004`, `TR-kbrow-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Input adapters (**Proposed**); ADR-0002: Modules, seams and Kotlin-mappable types
**ADR Decision Summary**: K-49: the keyboard row turns on by itself when no hardware keyboard is attached and hides when one is. The signal's rules and ACs are TASK-135's design change; the platform read is ADR-0007's.
**ADR Version**: ADR-0007 2026-11-18; ADR-0002 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: MEDIUM
**Engine Notes**: The platform API for keyboard presence is not named in any ADR yet: TASK-135 / ADR-0007 decide it.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: a new seam only by a new or superseding ADR (ADR-0002 D6)

---

## Acceptance Criteria

*From GDD `design/gdd/input-key-filter.md;`, scoped to this story:*

- [ ] *(TASK-135 writes these ACs: Keyboard Row R8 and its ACs, the Settings `keyboardRow` default, Input's keyboard-presence signal. Copy them here when TASK-135 merges; none is invented now.)*

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0007 first):*

Placeholder story so the epic shows the dependency; its criteria come from TASK-135.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- None

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/KeyboardPresence.swift (planned)`

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
- Unlocks: None
