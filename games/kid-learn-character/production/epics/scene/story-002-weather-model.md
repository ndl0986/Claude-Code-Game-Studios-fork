# Story 002: Weather within caps: windy, mashing and the halo clearing

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
**Requirement**: `TR-scene-001`, `TR-scene-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0004: Contracts, fixtures and harness
**ADR Decision Summary**: KidCore holds the pure rules with injected clocks (D3) and seeded streams (D4); the app reaches it only through the D6 seams and `tick(now:)`, in D7's call orders.
**ADR Version**: ADR-0002 2026-11-18; ADR-0004 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Forbidden: never `SKEmitterNode` or unseeded SpriteKit/GameplayKit randomness on the stage (ADR-0013 Impl.)

**Contracts**: scene-look-v1 (`not-started: story:scene` → `runner:` with this story; includes Cast Rendering F8)

---

## Acceptance Criteria

*From GDD `design/gdd/scene-time-weather.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-4 For each weather, counts, opacities, speeds and sway stay within R3 on the four F4 rects; rain and snow show 2–3 clouds, clear none.
- [ ] AC-6 Windy: rain and snow tilt 15° and their clouds drift ×2; cloudy and clear unchanged.
- [ ] AC-9 Snow with a queue of 1: half the flakes within 0.5 s; full again 1 s after the queue empties; with Reduce Motion a quarter.
- [ ] AC-10 An element at the glyph box centre has alpha 0, at 0.2 × r ≤ 0.11 × base, at r or beyond full alpha.
- [ ] AC-7 (logic) A weather change to snow reaches full count within 2 s ± 0.1 s (the panel UI that picks it is next milestone). All scene-look-v1 cases pass (with Cast Rendering F8) and its row flips to `runner:`.

---

## Implementation Notes

*Derived from ADR-0002 and the epic:*

Demo 1 runs on the settings defaults (clear, not windy); the model covers every weather. (Freeze/resume, panel and theme-switch **logic** is in Demo 1 so the contract runner passes every case; only their UI and device checks are next milestone — game-qc-android, TASK-140.) **Out:** AC-8 (snow kept across a relaunch) needs the panel to pick it — next milestone. TR-scene-002's device cost is story 006.

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

- Depends on: `production/epics/scene/story-001-looks-and-clocks.md`, `production/epics/cast-rendering/story-004-per-look-edge.md`
- Unlocks: `production/epics/scene/story-004-scene-drawing.md`
