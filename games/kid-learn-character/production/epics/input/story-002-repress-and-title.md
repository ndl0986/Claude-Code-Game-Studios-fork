# Story 002: Re-press window and the Title → Play switch; ⌘ release clears the held set

> **Epic**: Input & Key Filter (`production/epics/input/EPIC.md`)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/input-key-filter.md` — (AC-1 l, o, s)
**Requirement**: `TR-input-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0004: Contracts, fixtures and harness
**ADR Decision Summary**: ADR-0002 D3/D5: times are `Double` seconds on the uptime clock; the classifier routes by state (Title/Play).
**ADR Version**: ADR-0002 2026-11-18; ADR-0004 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: time is `Double` seconds; each module names the clock it reads (ADR-0002 D2, D3)

---

## Acceptance Criteria

*From GDD `design/gdd/input-key-filter.md`, scoped to this story:*

- [ ] With `repress_min_s = 0.08`: D at 10.00 and 10.05 s gives one press, at 10.00 and 10.10 s two, at 10.000 and 10.080 s two (1e-9 s tolerance) (AC-1 l).
- [ ] In the Title, D gives `startPlay` and no press; its repeat or up after the switch gives nothing; D again gives one press; Space or ⌘D gives nothing (AC-1 o).
- [ ] D down then ⌘ down (or the reverse), then ⌘ released: the held set is empty (AC-1 s).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0002 first):*

`repress_min_s` is tuning data (ADR-0001 D6), not a literal.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- None

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/KeyFilter.swift`
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

- Depends on: `production/epics/input/story-001-key-classifier.md`
- Unlocks: None
