# Story 004: ADR-0013 G4: the busy scenario rendered headless on every merge candidate

> **Epic**: Accessibility (`production/epics/accessibility/EPIC.md`)
> **Status**: Blocked — BLOCKED: needs the stage, and cast-rendering/005 and parade/007 are Blocked on ADR-0009 (Proposed; device rows P-2, M-13)
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/accessibility.md`
**Requirement**: `TR-a11y-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0013: Flash safety; ADR-0006: Stage runtime
**ADR Decision Summary**: G1 idle-rate lint, G2 red-flash palette check and G3 detector self-test run on every push (buildable now); G4 renders the busy stage headless via `SKRenderer`; G5 dumps device frames in Debug only.
**ADR Version**: ADR-0013 2026-11-18; ADR-0006 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: flash gates: one detector for G3–G5, windowing by timestamps; G4 headless through `SKRenderer` on a synthetic clock, seeded, at each class's native size and ppi floor (ADR-0013 D1–D6)
- Forbidden: never a second detector, frame counting for time, downsampling, wall clock in G4, or raising a threshold to fix a FAIL (ADR-0013)

---

## Acceptance Criteria

*From GDD `design/gdd/accessibility.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-08 (offline half) The K-26 busy scenario, Night and Day, rain and snow, Reduce Motion off and on, plus a Title idle run, rendered through `SKRenderer` at each class's native size and ppi floor: no FAIL; 27 runs × 600 frames; FAIL blocks a merge touching `apple/` or `content/`.

---

## Implementation Notes

*Derived from ADR-0013 and the epic:*

G4 waits for the stage composition (Scene, Cast Rendering, Parade, Press Queue's mash fixture) — ADR-0013 Ordering Note.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/Tools/Sources/ToolsCore/FlashRender.swift`
- `tools/ci/verify.sh (`--flash`)`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY-READY skipped — Lean mode).

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: Integration: an integration test (path under Files) OR a documented run in `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/accessibility/story-003-flash-g3-detector.md`, `production/epics/cast-rendering/story-005-draw-adapter.md`, `production/epics/scene/story-004-scene-drawing.md`, `production/epics/parade/story-007-parade-and-meter-look.md`
- Unlocks: `production/epics/accessibility/story-005-flash-g5-device.md`
