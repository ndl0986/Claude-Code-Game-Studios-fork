# Story 001: The batch of 6 distinct keys and the K-45 start rule

> **Epic**: Parade (`production/epics/parade/EPIC.md`)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/parade.md`
**Requirement**: `TR-parade-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Contracts, fixtures and harness; ADR-0002: Modules, seams and Kotlin-mappable types
**ADR Decision Summary**: The system's numbers are hand-written contract cases from the GDD, run by a runner over the public API; the not-started registry row becomes `runner:` when its story lands.
**ADR Version**: ADR-0004 2026-11-18; ADR-0002 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Required: every runner calls only the core's public API; hand-written cases from the GDD; never edit a merged `cases.json` (ADR-0004 D4–D6)
- Forbidden: never hard-code tuning values; timing and knobs are bundled data (ADR-0001 D6)

**Contracts**: parade-v2 (`not-started: story:parade` → `runner:` with this story)

---

## Acceptance Criteria

*From GDD `design/gdd/parade.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-1 D, C, D, T, 3, C, A, B gives the batch D, C, T, 3, A, B, Armed after B.
- [ ] AC-2 `shown(glyphOnly)` adds nothing.
- [ ] AC-3 The 6th key's reveal at r0 0 (formed 2.45): Armed at 2.45, Waiting for art at 3.95, not earlier; reduced set at 2.7.
- [ ] AC-4 A press at 3.0 starts a reveal; the parade still enters Waiting for art at 3.95 and the reveal plays in front.

---

## Implementation Notes

*Derived from ADR-0004 and the epic:*

The system's numbers are hand-written contract cases from the GDD, run by a runner over the public API; the not-started registry row becomes `runner:` when its story lands.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/Parade.swift`
- `apple/KidCore/Tests/KidCoreTests/ParadeTests.swift`
- `apple/KidCore/Tests/ContractTests/ParadeRunner.swift`

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

- Depends on: `production/epics/reveal-stage/story-001-start-reveal-timeline.md`
- Unlocks: `production/epics/parade/story-002-walk-positions-clock.md`, `production/epics/parade/story-005-meter-fill-full.md`
