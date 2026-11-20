# Story 002: Parts and pivots, idles at rest, `willForm`, and a platform-free draw interface

> **Epic**: Cast Rendering (`production/epics/cast-rendering/EPIC.md`)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/cast-rendering.md`
**Requirement**: `TR-cast-005`, `TR-cast-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0013: Flash safety
**ADR Decision Summary**: KidCore holds the pure rules with injected clocks (D3) and seeded streams (D4); the app reaches it only through the D6 seams and `tick(now:)`, in D7's call orders.
**ADR Version**: ADR-0002 2026-11-18; ADR-0013 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Forbidden: never hard-code a periodic animation rate in Swift; every rate comes from data G1 reads (ADR-0013 Impl.)
- Forbidden: never `Date`, `Float`, `CGFloat`, `Character` or JSON coding in the cores (ADR-0002 D2)

---

## Acceptance Criteria

*From GDD `design/gdd/cast-rendering.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-5 Rotating a part 10° about its pivot moves the pivot by 0 and a point 100 units away by 17.4 (±0.1).
- [ ] AC-11 At `idleTime` 0 every part is at rest; Reduce Motion halves every amplitude (the ≤ 1 Hz build check is ADR-0013 G1, accessibility/002).
- [ ] AC-13 `willForm` is true for valid art and false for missing art, and that reveal draws the glyph sparkle-out and reports no word.
- [ ] AC-16 The draw interface uses only stage units, seconds and ids (code review).

---

## Implementation Notes

*Derived from ADR-0002 and the epic:*

The draw list is KidCore's; the adapter (story 005) maps it to nodes. **Credited:** AC-4 (bake tool rejections) to content-pipeline/001.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/CastFigurePlan.swift`
- `apple/KidCore/Tests/KidCoreTests/CastFigurePlanTests.swift`

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
- Unlocks: `production/epics/cast-rendering/story-003-residency-late-art.md`, `production/epics/cast-rendering/story-005-draw-adapter.md`
