# Story 003: Residency cap and the late-art wait that never moves the queue

> **Epic**: Cast Rendering (`production/epics/cast-rendering/EPIC.md`)
> **Status**: Blocked — BLOCKED: ADR-0009 is Proposed — accept it with `/architecture-decision accept ADR-0009` once decided (device rows P-2, M-13)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/cast-rendering.md`
**Requirement**: `TR-cast-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009: Render path (**Proposed**); ADR-0002: Modules, seams and Kotlin-mappable types
**ADR Decision Summary**: (Proposed) One `CastFigure` adapter with two backends behind `RenderSink`, both reading the same baked file; the A-candidate outline in an `SKEffectNode`; A / B / mix decided by the device run.
**ADR Version**: ADR-0009 2026-11-18; ADR-0002 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Required: (pending) ADR-0009: one `CastFigure` adapter, two backends behind `RenderSink`; parse once at load; never hard-wire A or B

**Device rows that close it** (`production/qa/device-checks-plan.md`): P-2, M-13

---

## Acceptance Criteria

*From GDD `design/gdd/cast-rendering.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-14 With a seam delaying the load: formed at `formedS`; no key waiting → specks hold 0.5 s then fade in; a key queued → 0.05 s wait; a load that never finishes sparkles out with one log line; a fade-in started while a key waits ends ≤ `r0 + holdEff`.
- [ ] AC-15 Across a 60 s mash never more than `2 + queue_max` stage sets plus the parade set resident (instrumented count).

---

## Implementation Notes

*Derived from ADR-0009 and the epic:*

The F6 residency policy and F7 wait are KidCore behind `ResidencySink` (ADR-0002 D6, Accepted); TR-cast-002's coverage is ADR-0009 D5 (loading off main, resident only when every part is ready).

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/Residency.swift`
- `apple/KidCore/Tests/KidCoreTests/ResidencyTests.swift`

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

- Depends on: `production/epics/cast-rendering/story-002-parts-idles-willform.md`
- Unlocks: None
