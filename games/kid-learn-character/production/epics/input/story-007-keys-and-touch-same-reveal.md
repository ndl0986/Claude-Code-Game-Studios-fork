# Story 007: All 36 keys and the same letters as hints give the same reveal; other keys and empty taps do nothing visible

> **Epic**: Input & Key Filter (`production/epics/input/EPIC.md`)
> **Status**: Blocked — BLOCKED: ADR-0007 is Proposed (adapters), and it needs the reveal stage from the Core/Feature batch
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/input-key-filter.md` — (AC-5, AC-7, AC-8)
**Requirement**: `TR-input-001`, `TR-input-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Input adapters (**Proposed**); ADR-0002: Modules, seams and Kotlin-mappable types
**ADR Decision Summary**: ADR-0001 Validation: a hardware keyboard plays the same as touch; the adapters (ADR-0007) feed one classifier.
**ADR Version**: ADR-0007 2026-11-18; ADR-0002 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: MEDIUM
**Engine Notes**: Needs the reveal stage (Core/Feature batch) to observe a reveal.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: evidence for every player-observable change is a retained screenshot (coding-standards.md)

---

## Acceptance Criteria

*From GDD `design/gdd/input-key-filter.md`, scoped to this story:*

- [ ] In Play on the iPad and on the Mac, all 36 keys typed on a hardware keyboard and the same letters touched as hints each give the same reveal (AC-5).
- [ ] Space, Esc and the arrows in Play give nothing visible or audible (screen recording with audio) (AC-7).
- [ ] Tapping the empty stage shows a sparkle at the tap (AC-8).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0007 first):*

Runs once the Reveal Stage, Hint Letters and Audio stories exist (second batch).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- None

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `production/qa/evidence/<TASK>/<sha>/input-same-reveal.md`

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

- Depends on: `production/epics/input/story-004-ipad-key-adapter.md`, `production/epics/input/story-005-mac-key-adapter.md`, `production/epics/input/story-003-touch-classification.md`
- Unlocks: None
