# Story 001: One Reduce Motion flag: injected, never stored, applied at the right moment, re-read on return

> **Epic**: Accessibility (`production/epics/accessibility/EPIC.md`)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/accessibility.md`
**Requirement**: `TR-a11y-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0006: Stage runtime; ADR-0005: Settings persistence
**ADR Decision Summary**: KidCore holds the pure rules with injected clocks (D3) and seeded streams (D4); the app reaches it only through the D6 seams and `tick(now:)`, in D7's call orders.
**ADR Version**: ADR-0002 2026-11-18; ADR-0006 2026-11-18; ADR-0005 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: Reduce Motion is read live and applied at the next reveal (ADR-0006 D6)
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)

---

## Acceptance Criteria

*From GDD `design/gdd/accessibility.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-01 With the flag injected on, every A3 system applies its rule; with the OS API mocked to another value, they follow the flag (no system reads the OS directly).
- [ ] AC-02 After toggling Reduce Motion and relaunching, the settings record has no new field.
- [ ] AC-03 A reveal in progress keeps its set and twinkle; the next uses the reduced set; clouds, hints, parade bob and idles change on the next frame.
- [ ] AC-04 Changed in the background, the flag reflects the new value before the next frame back.

---

## Implementation Notes

*Derived from ADR-0002 and the epic:*

`AccessibilityState` seam (ADR-0002 D6).

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/LetterMorph/AccessibilityAdapter.swift`
- `apple/LetterMorphTests/AccessibilityAdapterTests.swift`

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

- Depends on: `production/epics/reveal-stage/story-003-taps-settle-flags.md`
- Unlocks: None
