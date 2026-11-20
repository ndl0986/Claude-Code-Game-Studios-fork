# Story 004: iPad hardware-keyboard adapter: `presses…` → `KeyEvent`, system keys passed on, touch batches sorted

> **Epic**: Input & Key Filter (`production/epics/input/EPIC.md`)
> **Status**: Blocked — BLOCKED: ADR-0007 is Proposed — accept it with `/architecture-decision accept ADR-0007` once decided (device rows P-15, P-4 media keys; M-1, M-3 Keys half)
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/input-key-filter.md` — (AC-1 m, R7)
**Requirement**: `TR-input-004`, `TR-input-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Input adapters (**Proposed**); ADR-0002: Modules, seams and Kotlin-mappable types
**ADR Decision Summary**: ADR-0007 (Proposed) D1–D3: a thin reader plus a pure, unit-tested mapper per platform; iPad uses a first responder overriding the four `presses…` methods; system keys never become a `KeyEvent`.
**ADR Version**: ADR-0007 2026-11-18; ADR-0002 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: MEDIUM (iPad hardware-keyboard delivery)
**Engine Notes**: Prove on the device (P-15); Simulator keyboard delivery is not evidence.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: (pending) ADR-0007: thin reader + pure mapper; `physicalId` `hid:<usage>`; `super` with only the passed presses
- Forbidden: (pending) never a global monitor, event tap, accessibility trust, `IOHID…` or `UIKeyCommand`s
- Required: platform types appear only in the app target (ADR-0002 D1)

**Device rows that close it** (`production/qa/device-checks-plan.md`): P-15; P-4 (media-keys half)

---

## Acceptance Criteria

*From GDD `design/gdd/input-key-filter.md`, scoped to this story:*

- [ ] Volume, mute, power, camera and brightness keys never reach KidCore and pass to the system; a keypad digit gives `character` nil and `positionKey` its digit; Esc gives "\u{1b}" (AC-1 m, adapter suite).
- [ ] An unordered iPad touch batch comes out sorted by timestamp, x, y (R7, AC-1 m).
- [ ] On the child's iPad with a hardware keyboard, all 36 keys and the numpad give their presses (P-15); media keys are swallowed (P-4 media-keys half).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0007 first):*

Device rows P-15 and P-4's media-keys half need an iPad hardware keyboard: NOT ASSESSED until one is available (K-48 follow-up).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- input/005: the Mac adapter

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/LetterMorph/Input/IPadKeyAdapter.swift`
- `apple/LetterMorph/Input/KeyMapper.swift`
- `apple/LetterMorphTests/KeyMapperTests.swift`

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

- Depends on: `production/epics/input/story-001-key-classifier.md`
- Unlocks: `production/epics/input/story-007-keys-and-touch-same-reveal.md`
