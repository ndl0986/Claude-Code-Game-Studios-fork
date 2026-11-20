# Story 002: No morph for empty paths, the per-press seed policy, and the purity checks

> **Epic**: MorphCore (`production/epics/morphcore/EPIC.md`)
> **Status**: In Progress
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: 2026-11-20
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/morphcore.md` — (AC-3, AC-4, AC-9, AC-12)
**Requirement**: `TR-morph-001`, `TR-morph-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0004: Contracts, fixtures and harness
**ADR Decision Summary**: ADR-0002 D1/D4: MorphCore is pure (no UI, no clock) and the morph seed derives from (key, revealId) in `UInt64`; morph-contract-v1 declares its contract id.
**ADR Version**: ADR-0002 2026-11-18; ADR-0004 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Plain Swift.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: `UInt64` only in `RandomSource`, MorphCore contract types and the morph-seed derivation (ADR-0002 D2)
- Forbidden: never a UI or platform import in KidCore/MorphCore (ADR-0002 D1)

---

## Acceptance Criteria

*From GDD `design/gdd/morphcore.md`, scoped to this story:*

- [ ] An empty or unparsable glyph or silhouette builds no morph and never throws to the stage; the result says which side was missing (AC-9).
- [ ] Two presses of the same key in one session give different seeds; the same (key, press count) gives the same seed; debug builds log key, count and seed per reveal (AC-12).
- [ ] The implementation declares "morph-v1" and a test fails if it differs from the fixture's `contract`; MorphCore builds with no UI/platform import and reads no clock, and building the same morph twice gives identical results (AC-3, AC-4).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0002 first):*

The ban grep already covers the import half of AC-4; the determinism half is a unit test.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- morphcore/003: device performance

---

## Files

- `apple/MorphCore/Sources/MorphCore/Morph.swift` — modified (`Morph.build` non-throwing with `MissingSide`; `morphContractID` "morph-v1"; `morphSeed(key:pressCount:)`)
- `apple/MorphCore/Tests/MorphCoreTests/MorphCoreTests.swift` — 7 new test functions (AC-9, AC-3, AC-4, AC-12 ×4)
- `contracts/morphcore-api.md` — regenerated (12 added lines; ADR-0002 V4)

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY-READY skipped — Lean mode).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: Logic: a unit test in the package's test target (path under Files) — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/morphcore/story-001-timing-data-loader.md`
- Unlocks: `production/epics/morphcore/story-003-device-frame-budget.md`
