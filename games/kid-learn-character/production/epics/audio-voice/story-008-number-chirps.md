# Story 008: Number chirps: digits 1–9 chirp that many times, 0 one soft chirp

> **Epic**: Audio & Voice (`production/epics/audio-voice/EPIC.md`)
> **Status**: Ready
> **Layer**: Core
> **Type**: Config/Data
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/audio-voice.md`
**Requirement**: `TR-audio-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Content pipeline
**ADR Decision Summary**: Content and tuning are bundled data validated at build and load (D1–D3); the bake and voice pipeline is build-time only.
**ADR Version**: ADR-0003 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Forbidden: never hard-code tuning values; timing and knobs are bundled data (ADR-0001 D6)

---

## Acceptance Criteria

*From GDD `design/gdd/audio-voice.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-19 Each digit item's sfx for 1–9 has exactly that many chirps (checked by ear in the content review) and is ≤ 2.0 s; the 0 item has one soft chirp.

---

## Implementation Notes

*Derived from ADR-0003 and the epic:*

The ≤ 2.0 s limit is content-pipeline/004's sfx check; the count is the content reviewer's, recorded with key-table/001's toddler review.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `content/themes/dinosaurs/sfx/`
- `production/qa/evidence/<TASK>/<sha>/number-chirps.md`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY-READY skipped — Lean mode).

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**: Config/Data: smoke check pass (`production/qa/smoke-*.md`)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/content-pipeline/story-004-loudness-durations-staleness.md`, `production/epics/key-table/story-001-dinosaurs-theme-data.md`
- Unlocks: None
