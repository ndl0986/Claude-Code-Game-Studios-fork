# Story 001: Cast math: the 6 px rule, halo, specks and hop as pure functions

> **Epic**: Cast Rendering (`production/epics/cast-rendering/EPIC.md`)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/cast-rendering.md`
**Requirement**: `TR-cast-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Contracts, fixtures and harness; ADR-0002: Modules, seams and Kotlin-mappable types
**ADR Decision Summary**: The system's numbers are hand-written contract cases from the GDD, run by a runner over the public API; the not-started registry row becomes `runner:` when its story lands.
**ADR Version**: ADR-0004 2026-11-18; ADR-0002 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Forbidden: never hard-code tuning values; timing and knobs are bundled data (ADR-0001 D6)
- Forbidden: never `SKEmitterNode` or unseeded SpriteKit/GameplayKit randomness on the stage (ADR-0013 Impl.)

**Contracts**: reveal-timing-v1 F1/F2/F4/F5/F7 (`story:reveal-stage`; its runner lands in reveal-stage/001)

---

## Acceptance Criteria

*From GDD `design/gdd/cast-rendering.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-6 F1: a 10-unit spot is kept at `stage` and left out at `list` with `stage_to_px` 1.87 and 2.32.
- [ ] AC-7 F2: blur 100% at t 0.114 s and 60% at 0.341 s (±1%); glyph fill alpha constant; Reduce Motion blur constant 80%.
- [ ] AC-9 Fixed seed gives the same speck looks every run; 70% ± 5% gold over 240 specks for 100 seeds; specks above 3.2 units are stars.
- [ ] AC-12 F5 hop: 26 units at τ 0.225 s, 0 at 0.45 s; 13 with Reduce Motion.

---

## Implementation Notes

*Derived from ADR-0004 and the epic:*

These are reveal-timing-v1's Cast cases (F1, F2, F4, F5, F7), run by the reveal-stage runner (reveal-stage/001).

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/CastMath.swift`
- `apple/KidCore/Tests/KidCoreTests/CastMathTests.swift`

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
- Unlocks: `production/epics/cast-rendering/story-002-parts-idles-willform.md`, `production/epics/cast-rendering/story-004-per-look-edge.md`, `production/epics/reveal-stage/story-001-start-reveal-timeline.md`
