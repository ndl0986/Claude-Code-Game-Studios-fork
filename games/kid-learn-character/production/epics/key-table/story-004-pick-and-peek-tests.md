# Story 004: Per-platform pick distribution, peek purity and no saved progress

> **Epic**: Key Table & Theme Data (`production/epics/key-table/EPIC.md`)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/key-table-theme-data.md` — (AC-8, AC-9, AC-15)
**Requirement**: `TR-keytable-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0004: Contracts, fixtures and harness
**ADR Decision Summary**: ADR-0002 D4: each system draws from its own seeded `RandomSource` stream (key variety); ADR-0004: the key-table-schema-v1 F1 cases run on both apps.
**ADR Version**: ADR-0002 2026-11-18; ADR-0004 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Plain XCTest.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: `protocol RandomSource`; one stream per source with its own seed; a draw is `Double(x >> 11) · 2⁻⁵³` through one helper (ADR-0002 D4)
- Forbidden: never use one global random generator (ADR-0002 Alt 3)

---

## Acceptance Criteria

*From GDD `design/gdd/key-table-theme-data.md`, scoped to this story:*

- [ ] With a fixed seed, `n = 5` and no weights: 10,000 reveals of one key give no immediate repeat and each item between 18% and 22%; with `n = 1`, or `n = 2` with `last` set, no draw is consumed (AC-8, per-platform half).
- [ ] With a fixed seed, `n = 5` and `last` set, `peek(D)` 10 times returns the same item, equal to the next `resolve(D)`, and `lastShown` and the stream position are unchanged; with `n = 1`, `peek` returns item 0 and draws nothing (AC-15).
- [ ] After quit and relaunch, no file written by this system exists (`lastShown` is in memory only) (AC-9).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0002 first):*

The contract half of AC-8 already passes (key-table-schema-v1). This adds the platform unit tests.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- key-table/003: launch fallback

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Tests/KidCoreTests/KeyVarietyTests.swift`

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
- Unlocks: None
