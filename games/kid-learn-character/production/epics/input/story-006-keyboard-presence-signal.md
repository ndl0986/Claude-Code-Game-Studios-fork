# Story 006: Keyboard presence from the platform adapter: `GCKeyboard` on iPad, constant true on the Mac

> **Epic**: Input & Key Filter (`production/epics/input/EPIC.md`)
> **Status**: Blocked — BLOCKED: ADR-0007 is Proposed — accept it with `/architecture-decision accept ADR-0007` once decided (device rows P-15; the attach/detach check needs an iPad hardware keyboard)
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/onscreen-keyboard-row.md` — (Interface needed: keyboard presence, TASK-135)
**Requirement**: `TR-input-004`, `TR-kbrow-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Input adapters (**Proposed**); ADR-0002: Modules, seams and Kotlin-mappable types
**ADR Decision Summary**: TASK-135 (K-49, merged 5647a15f): the Apple platform adapter that delivers key events also reports `keyboardPresent` with a change notification; KidCore's key filter neither reads nor changes it. The platform read sits under ADR-0007.
**ADR Version**: ADR-0007 2026-11-18; ADR-0002 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: MEDIUM
**Engine Notes**: `GCKeyboard` (Game Controller framework) is not named in any ADR yet: prove it on the device.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: (pending) ADR-0007: a thin platform reader; platform types only in the app target (ADR-0002 D1)
- Required: a new seam only by a new or superseding ADR (ADR-0002 D6) — `keyboardPresent` is an adapter output to the row, not a new KidCore seam

**Device rows that close it** (`production/qa/device-checks-plan.md`): P-15

---

## Acceptance Criteria

*From GDD `design/gdd/onscreen-keyboard-row.md`, scoped to this story:*

- [ ] iPadOS: `keyboardPresent` = `GCKeyboard.coalesced != nil`, read before the first frame and again on every return to the foreground, then updated from `GCKeyboardDidConnect` / `GCKeyboardDidDisconnect`; present while any keyboard is connected.
- [ ] macOS: `keyboardPresent` is constant `true` (Keyboard Row R9), never detected.
- [ ] The adapter only reports: the 0.5 s settle and the show/hide rule are the row's (keyboard-row stories), and input-filter-v2's cases are unaffected.

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0007 first):*

From the merged Keyboard Row GDD's Interface section (TASK-135). The row behaviour (AC-1, AC-20–AC-25) is keyboard-row's; the device attach/detach check is keyboard-row AC-25.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- None

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/LetterMorph/Input/KeyboardPresence.swift`
- `apple/LetterMorphTests/KeyboardPresenceTests.swift`

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
- Unlocks: None
