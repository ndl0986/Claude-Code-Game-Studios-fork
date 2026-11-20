# Story 004: Per-look edge, halo colour and creature factor (F8, K-25)

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
**Requirement**: `TR-cast-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Contracts, fixtures and harness; ADR-0002: Modules, seams and Kotlin-mappable types
**ADR Decision Summary**: The system's numbers are hand-written contract cases from the GDD, run by a runner over the public API; the not-started registry row becomes `runner:` when its story lands.
**ADR Version**: ADR-0004 2026-11-18; ADR-0002 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Required: every runner calls only the core's public API; hand-written cases from the GDD; never edit a merged `cases.json` (ADR-0004 D4–D6)

**Contracts**: scene-look-v1 F8 (`story:scene`; runner lands in scene/001)

---

## Acceptance Criteria

*From GDD `design/gdd/cast-rendering.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-18 At the F8 table's times the edge, halo colour and scale, top stop and creature factor match (±1/255); cream when `skyMidL` falls to 0.303, amber when it rises to 0.313, each a 1 s wall-clock dissolve; 0.304–0.312 oscillation causes no switch; `castDim` 0.85 multiplies linear RGB; the glyph fill is never dimmed.
- [ ] AC-3 Sampled outline pixels of a stage render equal Ink `#2a2340` at 80% over the body (within 2/255) — the colour math here, the pixel sample in story 005.

---

## Implementation Notes

*Derived from ADR-0004 and the epic:*

scene-look-v1's F8 cases run under the scene runner (scene/001).

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/CastLook.swift`
- `apple/KidCore/Tests/KidCoreTests/CastLookTests.swift`

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

- Depends on: `production/epics/cast-rendering/story-001-cast-math.md`
- Unlocks: `production/epics/scene/story-003-contrast-check-privacy.md`
