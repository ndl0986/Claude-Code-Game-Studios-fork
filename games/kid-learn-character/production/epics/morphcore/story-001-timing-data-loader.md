# Story 001: Load and validate the morph timing data; Reduce Motion picks the reduced set for new morphs

> **Epic**: MorphCore (`production/epics/morphcore/EPIC.md`)
> **Status**: In Progress
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: 2026-11-20
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/morphcore.md` — (AC-6, AC-7, AC-8)
**Requirement**: `TR-morph-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0004: Contracts, fixtures and harness; ADR-0003: Content pipeline
**ADR Decision Summary**: ADR-0001 D6 / ADR-0003: timing is bundled data with a reduced set chosen by Reduce Motion; MorphCore's timing-spec loader validates every range and builds no morph on a bad set.
**ADR Version**: ADR-0002 2026-11-18; ADR-0004 2026-11-18; ADR-0003 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Plain Swift value types (ADR-0002 D2).

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: MorphCore depends on nothing; Swift standard library and Foundation value types only (ADR-0002 D1/D2)
- Required: a reduced timing set in the same data, chosen by Reduce Motion (ADR-0001 D6)
- Forbidden: never `Date`, `Float`, `CGFloat` or JSON coding in the cores (ADR-0002 D2)

**Contracts**: morph-contract-v1 (Accepted; AC-1, AC-2, AC-5 already pass in ContractV1Tests / MorphCoreTests)

---

## Acceptance Criteria

*From GDD `design/gdd/morphcore.md`, scoped to this story:*

- [ ] Loading the timing data gives the contract spec of F1: normal glow 0.8, dissolve 0.4, travel 1.25, spread 0.35, flight 0.9, T 2.45 (AC-6).
- [ ] Each Tuning Knobs range rule has a test: an out-of-range, missing or non-numeric value rejects the set and the loader builds no morph; a build-time test validates the shipped normal and reduced sets (AC-7).
- [ ] With the reduced-motion flag injected on, a new morph uses the reduced set; a morph already built keeps its spec (AC-8).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0002 first):*

The loader takes already-decoded numbers (JSON is decoded at the edge). The shipped data file lives under `content/data/` (ADR-0003 D1).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- morphcore/002: empty paths, seed policy, purity

---

## Files

- `apple/MorphCore/Sources/MorphCore/TimingSpec.swift` — created (timing loader and validator, reduced-motion selection)
- `apple/MorphCore/Tests/MorphCoreTests/TimingSpecTests.swift` — created (14 tests: AC-6, AC-7, AC-8)
- `apple/Tools/Tests/ToolsTests/MorphTimingDataTests.swift` — created (3 tests: the shipped sets are valid, a broken copy fails, the file is byte-stable)
- `content/data/morph-timing.json` — created (shipped normal and reduced sets, from the GDD Tuning Knobs)
- `contracts/morphcore-api.md` — regenerated (52 added lines for the new public types; ADR-0002 V4)

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
- Unlocks: `production/epics/morphcore/story-002-empty-paths-seed-purity.md`
