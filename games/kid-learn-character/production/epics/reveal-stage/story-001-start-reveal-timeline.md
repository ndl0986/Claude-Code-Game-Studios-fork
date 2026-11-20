# Story 001: `startReveal` lengths, `formed`/`shown` once, and the E6–E9 times

> **Epic**: Reveal Stage (`production/epics/reveal-stage/EPIC.md`)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/reveal-stage.md`
**Requirement**: `TR-reveal-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Contracts, fixtures and harness; ADR-0002: Modules, seams and Kotlin-mappable types
**ADR Decision Summary**: The system's numbers are hand-written contract cases from the GDD, run by a runner over the public API; the not-started registry row becomes `runner:` when its story lands.
**ADR Version**: ADR-0004 2026-11-18; ADR-0002 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Required: every runner calls only the core's public API; hand-written cases from the GDD; never edit a merged `cases.json` (ADR-0004 D4–D6)
- Forbidden: never hard-code tuning values; timing and knobs are bundled data (ADR-0001 D6)

**Contracts**: reveal-timing-v1 (this story adds the runner file, reporting the cases not yet passing as NOT ASSESSED — it is not registered while the row is `not-started`, since ContractKit fails a registered runner on a not-started row; the row flips to `runner:` in reveal-stage/003)

---

## Acceptance Criteria

*From GDD `design/gdd/reveal-stage.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-1 Normal set: morph (2.45, 2.95, true); glyph missing (1.30, 1.30, true); art missing (1.40, 1.40, false); invalid set (1.30, 1.30, true); and the F5 reduced values.
- [ ] AC-2 `formed` and `shown(…, kind)` each fire exactly once at the first frame with `s ≥ formedS`; `kind` is `glyphOnly` only for art missing; still once after a timeout or settle.
- [ ] AC-5 With `hasWord`, E6 0, E7 0.8, E8 2.45, E9 2.70 (±1 ms); sfx-without-word: E8 2.45, no E9; art missing: neither.

---

## Implementation Notes

*Derived from ADR-0004 and the epic:*

Starts the reveal-timing-v1 cases, including Cast Rendering's F1/F2/F4/F5/F7.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/RevealStage.swift`
- `apple/KidCore/Tests/KidCoreTests/RevealStageTests.swift`

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

- Depends on: `production/epics/press-queue/story-001-start-queue-ignore.md`, `production/epics/cast-rendering/story-001-cast-math.md`
- Unlocks: `production/epics/reveal-stage/story-002-origins-callback-prefetch.md`, `production/epics/reveal-stage/story-004-stage-view-layers-fit.md`, `production/epics/parade/story-001-batch-and-start.md`
