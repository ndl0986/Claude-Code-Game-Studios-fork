# Story 003: Creature taps and cooldown, settle on background, Reduce Motion, and the Scene flags

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
**Requirement**: `TR-reveal-002`, `TR-reveal-005`, `TR-reveal-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0006: Stage runtime; ADR-0004: Contracts, fixtures and harness
**ADR Decision Summary**: KidCore holds the pure rules with injected clocks (D3) and seeded streams (D4); the app reaches it only through the D6 seams and `tick(now:)`, in D7's call orders.
**ADR Version**: ADR-0002 2026-11-18; ADR-0006 2026-11-18; ADR-0004 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Required: Reduce Motion is read live and applied at the next reveal (ADR-0006 D6)

---

## Acceptance Criteria

*From GDD `design/gdd/reveal-stage.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-9 Taps at 10.0, 10.5, 11.0: hop + E10 at 10.0 and 11.0, sparkle only at 10.5; a tap on the leaving creature or a walker sparkles only.
- [ ] AC-11 Background mid-morph: drawn formed at rest, specks and halo gone, the queue cleared, the next press after return starts at once (the panel half is next milestone).
- [ ] AC-14 Reduce Motion: no glyph-rise scale above 1, pop ≤ 1.0, the leaving creature does not move, reduced times for E6–E9.
- [ ] AC-17 `haloOn` exactly for `letter_in < s ≤ glow`; `mashing` on a `queued` outcome, while non-empty, off 1 s after the last `ignored` with an empty queue; both false after a settle.

---

## Implementation Notes

*Derived from ADR-0002 and the epic:*

The gate freeze (AC-10) is the next milestone.

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

- Depends on: `production/epics/reveal-stage/story-001-start-reveal-timeline.md`
- Unlocks: `production/epics/accessibility/story-001-reduce-motion-flag.md`
