# Story 003: Settings read before the first frame; play waits until the theme is ready

> **Epic**: Settings Store (`production/epics/settings/EPIC.md`)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/settings-store.md` — (AC-18); app-shell-title.md (R1–R6)
**Requirement**: `TR-settings-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Settings persistence; ADR-0004: Contracts, fixtures and harness
**ADR Decision Summary**: ADR-0005 D9: one synchronous read at launch before the first frame; app-shell-v1 covers the launch order.
**ADR Version**: ADR-0005 2026-11-18; ADR-0004 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: App target wiring.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: one synchronous read at launch, before the first frame (ADR-0005 D2, D9)
- Guardrail: settings record under 1 KB; launch read a few ms (ADR-0005)

---

## Acceptance Criteria

*From GDD `design/gdd/settings-store.md`, scoped to this story:*

- [ ] With a test seam delaying the theme load, pressing play on the Title does not enter Play and no press reaches the Press Queue until the theme is ready (AC-18).
- [ ] The settings record is read once, synchronously, before the first frame (launch-order log or test seam) (TR-settings-003).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0005 first):*

The App Shell epic (Presentation batch) owns the Title and the launch state machine; this story only provides the read-before-first-frame and the "theme ready" gate it consumes.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- None

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/LetterMorph/LetterMorphApp.swift`
- `apple/LetterMorphTests/LaunchOrderTests.swift`

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

- Depends on: `production/epics/settings/story-001-userdefaults-backend.md`, `production/epics/key-table/story-002-app-theme-load.md`
- Unlocks: None
