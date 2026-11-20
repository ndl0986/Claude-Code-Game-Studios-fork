# Story 002: ADR-0013 G1 idle-rate lint and G2 red-flash palette check (buildable now)

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
**Requirement**: `TR-a11y-003`, `TR-a11y-004`, `TR-cast-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0013: Flash safety; ADR-0011: Build, verify and PKC gates
**ADR Decision Summary**: G1 idle-rate lint, G2 red-flash palette check and G3 detector self-test run on every push (buildable now); G4 renders the busy stage headless via `SKRenderer`; G5 dumps device frames in Debug only.
**ADR Version**: ADR-0013 2026-11-18; ADR-0011 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Forbidden: never hard-code a periodic animation rate in Swift; every rate comes from data G1 reads (ADR-0013 Impl.)
- Forbidden: never a second detector, frame counting for time, downsampling, wall clock in G4, or raising a threshold to fix a FAIL (ADR-0013)

---

## Acceptance Criteria

*From GDD `design/gdd/accessibility.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-05 The F1 lint over the shipped data passes; a fixture idle at 1.2 Hz fails naming the animation; 3.0 Hz fails even on the exception list (also Cast Rendering AC-11's ≤ 1 Hz build check).
- [ ] AC-09 (palette half) The palette check over every art-bible hex reports the highest R/(R+G+B) (0.604 / 0.781 linear) and passes; adding `#ff0000` fails it; it runs on the palette, theme data and SVG fills.
- [ ] In verify.sh's gate order after the content gates (ADR-0011 D4 note).

---

## Implementation Notes

*Derived from ADR-0013 and the epic:*

ADR-0013: G1–G3 can be built now (no stage needed).

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/Tools/Sources/ToolsCore/FlashLint.swift`
- `apple/Tools/Tests/ToolsTests/FlashLintTests.swift`
- `tools/ci/verify.sh`

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
- Unlocks: `production/epics/parade/story-005-meter-fill-full.md`
