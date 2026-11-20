# Story 003: The next batch, art not ready, the tune once per walk, no cap

> **Epic**: Parade (`production/epics/parade/EPIC.md`)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/parade.md`
**Requirement**: `TR-parade-001`, `TR-parade-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Contracts, fixtures and harness; ADR-0009: Render path (**Proposed**)
**ADR Decision Summary**: The system's numbers are hand-written contract cases from the GDD, run by a runner over the public API; the not-started registry row becomes `runner:` when its story lands.
**ADR Version**: ADR-0004 2026-11-18; ADR-0009 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Required: (pending) ADR-0009: one `CastFigure` adapter, two backends behind `RenderSink`; parse once at load; never hard-wire A or B

---

## Acceptance Criteria

*From GDD `design/gdd/parade.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-8 Keys shown during the walk form the next batch; reaching 6 during the walk arms it at Ended and it starts 1.5 s after.
- [ ] AC-12 2 of 6 walkers never resident: the walk starts at the wait's end with 4; 4 of 6 missing: skipped, still Armed, one debug line, retried 1.5 s after the next formed reveal.
- [ ] AC-16 E12 is requested exactly once per walk at pt 0; a skipped parade requests none.
- [ ] AC-17 40 distinct-key batches give 40 parades.

---

## Implementation Notes

*Derived from ADR-0004 and the epic:*

AC-12's residency comes from cast-rendering/003 (ADR-0009 D5): test it against the `ResidencySink` fake now.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/Parade.swift`
- `apple/KidCore/Tests/KidCoreTests/ParadeTests.swift`

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

- Depends on: `production/epics/parade/story-002-walk-positions-clock.md`
- Unlocks: None
