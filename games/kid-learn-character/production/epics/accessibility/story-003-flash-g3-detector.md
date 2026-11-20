# Story 003: ADR-0013 G3: the F2 detector and its field math (buildable now)

> **Epic**: Accessibility (`production/epics/accessibility/EPIC.md`)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/accessibility.md`
**Requirement**: `TR-a11y-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0013: Flash safety
**ADR Decision Summary**: G1 idle-rate lint, G2 red-flash palette check and G3 detector self-test run on every push (buildable now); G4 renders the busy stage headless via `SKRenderer`; G5 dumps device frames in Debug only.
**ADR Version**: ADR-0013 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: flash gates: one detector for G3–G5, windowing by timestamps; G4 headless through `SKRenderer` on a synthetic clock, seeded, at each class's native size and ppi floor (ADR-0013 D1–D6)
- Forbidden: never a second detector, frame counting for time, downsampling, wall clock in G4, or raising a threshold to fix a FAIL (ADR-0013)

---

## Acceptance Criteria

*From GDD `design/gdd/accessibility.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-06 For ppi 264, 254 and 109 `field_px` is 545.6, 524.9 and 225.3 and `area_max` 58,449, 54,105 and 9,964 px (from the unrounded field).
- [ ] AC-07 A full-screen 4 Hz black/white flash FAILs; the same within 20% of a field passes; 3 Hz passes at every phase offset at 60 and 120 Hz; 3.5 Hz FAILs; ΔL 0.08 flicker, ±0.04 noise and L 0.85↔1.0 pass.

---

## Implementation Notes

*Derived from ADR-0013 and the epic:*

One detector, shared by G3–G5, windowing by timestamps.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/Tools/Sources/ToolsCore/FlashDetector.swift`
- `apple/Tools/Tests/ToolsTests/FlashDetectorTests.swift`

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
- Unlocks: `production/epics/accessibility/story-004-flash-g4-offline.md`
