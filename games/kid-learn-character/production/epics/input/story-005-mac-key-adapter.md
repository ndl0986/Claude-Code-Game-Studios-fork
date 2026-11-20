# Story 005: Mac key monitor adapter: one local monitor → `KeyEvent`, no Input Monitoring prompt

> **Epic**: Input & Key Filter (`production/epics/input/EPIC.md`)
> **Status**: Blocked — BLOCKED: ADR-0007 is Proposed — accept it with `/architecture-decision accept ADR-0007` once decided (device rows M-1, M-3 Keys half)
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/input-key-filter.md` — (AC-1 k6, AC-1 m)
**Requirement**: `TR-input-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Input adapters (**Proposed**); ADR-0002: Modules, seams and Kotlin-mappable types
**ADR Decision Summary**: ADR-0007 (Proposed) D3: one `NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged])` installed before the first frame; events reach KidCore synchronously; `KeyStateQuery` undecided (M-1).
**ADR Version**: ADR-0007 2026-11-18; ADR-0002 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH (Mac key-state read and TCC)
**Engine Notes**: M-1 decides whether the key-state read stays; do not build against `KeyStateQuery` yet (manifest pending).

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: (pending) ADR-0007: one local monitor installed before the first frame; key-down disposition returned in the callback
- Forbidden: (pending) never a global monitor, event tap or accessibility trust; do not build against `KeyStateQuery` yet

**Device rows that close it** (`production/qa/device-checks-plan.md`): M-1; M-3 (Keys half, lock off, production app)

---

## Acceptance Criteria

*From GDD `design/gdd/input-key-filter.md`, scoped to this story:*

- [ ] On a clean Mac (F-5: `tccutil reset ListenEvent com.galaxyandsun.letterlings`), first launch and typing all keys: no system prompt and the app is not listed under Input Monitoring (AC-1 k6, M-1; release-blocking for macOS).
- [ ] With the lock off, every key normalizes, key-ups under ⌘ arrive, and system keys are left alone — **M-3 Keys half repeated on the production macOS app** (DeviceSpike's TASK-134 run is ADR evidence only).
- [ ] Mac media keys do not reach KidCore (AC-1 m, Mac half).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0007 first):*

The chord ⌃⌥⌘Q and kiosk-on swallowing are the next milestone (Parent Gate, Child Lock-in).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- None

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/LetterMorph/Input/MacKeyAdapter.swift`
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
