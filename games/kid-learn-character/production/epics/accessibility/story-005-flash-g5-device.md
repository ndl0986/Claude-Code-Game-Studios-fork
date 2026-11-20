# Story 005: ADR-0013 G5: the Debug frame dump and the device flash gate

> **Epic**: Accessibility (`production/epics/accessibility/EPIC.md`)
> **Status**: Blocked — BLOCKED: needs accessibility/004 (the stage; ADR-0009 Proposed)
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M
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

**Device rows that close it** (`production/qa/device-checks-plan.md`): P-3, M-12

---

## Acceptance Criteria

*From GDD `design/gdd/accessibility.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-08 (device half) The same scenarios on the child's iPad and a Mac at the display's refresh rate through the Debug `FlashDump`: no FAIL; the Release scan finds no `FlashDump` symbol.
- [ ] AC-09 (capture half) The capture's per-pixel R/(R+G+B) maximum stays < 0.8 over pixels with R + G + B ≥ 0.1.

---

## Implementation Notes

*Derived from ADR-0013 and the epic:*

G1 idle-rate lint, G2 red-flash palette check and G3 detector self-test run on every push (buildable now); G4 renders the busy stage headless via `SKRenderer`; G5 dumps device frames in Debug only.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/LetterMorph/Debug/FlashDump.swift`
- `production/qa/evidence/<TASK>/<sha>/flash-device.md`

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

- Depends on: `production/epics/accessibility/story-004-flash-g4-offline.md`
- Unlocks: None
