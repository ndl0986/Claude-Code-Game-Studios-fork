# Story 001: Wall-clock looks: F1 boundaries, the first frame, clock jumps and the two clocks

> **Epic**: Scene: Time of Day & Weather (`production/epics/scene/EPIC.md`)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/scene-time-weather.md`
**Requirement**: `TR-scene-001`, `TR-scene-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0004: Contracts, fixtures and harness
**ADR Decision Summary**: KidCore holds the pure rules with injected clocks (D3) and seeded streams (D4); the app reaches it only through the D6 seams and `tick(now:)`, in D7's call orders.
**ADR Version**: ADR-0002 2026-11-18; ADR-0004 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Required: every runner calls only the core's public API; hand-written cases from the GDD; never edit a merged `cases.json` (ADR-0004 D4–D6)

**Contracts**: scene-look-v1 (`not-started: story:scene` → `runner:` with this story; includes Cast Rendering F8)

---

## Acceptance Criteria

*From GDD `design/gdd/scene-time-weather.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-1 F1 gives the table's phase and weight for 15:55, 16:07, 16:15, 23:00 and 06:05.
- [ ] AC-2 Launching at 16:07 draws the 0.467 blend on the first frame, no fade.
- [ ] AC-3 12:00 → 21:00 while in front fades to Night over 3 s (± a frame); the same change in the background shows Night on the first frame back.
- [ ] AC-11 Under a 20 s `freeze()` element positions are unchanged and the look's weight follows the wall clock (16:00 → 16:00:20 moves w 0 → 0.022).

---

## Implementation Notes

*Derived from ADR-0002 and the epic:*

KidCore holds the pure rules with injected clocks (D3) and seeded streams (D4); the app reaches it only through the D6 seams and `tick(now:)`, in D7's call orders.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/Scene.swift`
- `apple/KidCore/Tests/KidCoreTests/SceneTests.swift`
- `apple/KidCore/Tests/ContractTests/SceneLookRunner.swift`

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
- Unlocks: `production/epics/scene/story-002-weather-model.md`, `production/epics/scene/story-003-contrast-check-privacy.md`, `production/epics/app-shell/story-001-launch-order-first-frame.md`
