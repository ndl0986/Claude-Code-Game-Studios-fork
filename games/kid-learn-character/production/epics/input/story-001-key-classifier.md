# Story 001: Classify normalized key events: letters and digits count, everything else swallowed, held keys and repeats once

> **Epic**: Input & Key Filter (`production/epics/input/EPIC.md`)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/input-key-filter.md` — (AC-1 a–i, AC-2, AC-4)
**Requirement**: `TR-input-001`, `TR-input-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0004: Contracts, fixtures and harness
**ADR Decision Summary**: ADR-0002 D5: KidCore classifies `KeyEvent`s (character first, position fallback, modifiers, held set) with no platform types; input-filter-v2 is the contract.
**ADR Version**: ADR-0002 2026-11-18; ADR-0004 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore; platform adapters are stories 003–004.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: use `KeyEvent` and `TouchEvent` exactly as ADR-0002 D5 defines them; adapters own every platform mapping
- Required: keys and characters are `String`; case folding only through `asciiUppercased` (ADR-0002 D2)
- Forbidden: never `Character` or `.count`/`for … in` directly on a `String` in the cores (ADR-0002 D2)

**Contracts**: input-filter-v2 (`not-started: story:input` → `runner:` when this story lands; the gate/kiosk cases stay NOT ASSESSED until the next milestone)

---

## Acceptance Criteria

*From GDD `design/gdd/input-key-filter.md`, scoped to this story:*

- [ ] A–Z, a–z, 0–9 and numpad 0–9 each give one press of their key; Space, Esc, Tab, Return, Backspace, arrows, F-keys, punctuation and dead keys are swallowed; D with Ctrl/Option/⌘/Fn is swallowed, with Shift or Caps Lock one press (AC-1 a–c; ⌘ on macOS with kiosk-on off passes to the system).
- [ ] A repeat or second down of a held key gives nothing; a cleared held set re-arms it; an up of a key not held changes nothing (AC-1 d–f).
- [ ] AZERTY, QWERTZ and Cyrillic layouts resolve by base character then position; numpad 7 with Num Lock off gives "7" (AC-1 g–i).
- [ ] Presses come out in delivery order with their own times, none dropped; every press has a one-character `key` in A–Z/0–9, a source, a finite time, and `origin` nil exactly for hardware keys (AC-2, AC-4).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0002 first):*

Only the Demo 1 states: Title and Play. The gate states (AC-1 j, k3–k5, p–r, t) and kiosk-on mode (k) are the next milestone with the Parent Gate and Child Lock-in.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- input/002: timing and the Title switch
- input/003, 004: adapters

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/KeyFilter.swift`
- `apple/KidCore/Tests/ContractTests/InputFilterRunner.swift`
- `apple/KidCore/Tests/KidCoreTests/KeyFilterTests.swift`

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

- Depends on: None
- Unlocks: `production/epics/input/story-002-repress-and-title.md`, `production/epics/input/story-003-touch-classification.md`, `production/epics/input/story-004-ipad-key-adapter.md`, `production/epics/input/story-005-mac-key-adapter.md`, `production/epics/input/story-006-keyboard-presence-signal.md`
