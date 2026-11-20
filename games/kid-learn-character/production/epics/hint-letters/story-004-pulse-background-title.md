# Story 004: The first-press pulse, background return, and no hints on the Title

> **Epic**: Hint Letters (`production/epics/hint-letters/EPIC.md`)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/hint-letters.md`
**Requirement**: `TR-hints-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types
**ADR Decision Summary**: KidCore holds the pure rules with injected clocks (D3) and seeded streams (D4); the app reaches it only through the D6 seams and `tick(now:)`, in D7's call orders.
**ADR Version**: ADR-0002 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)

---

## Acceptance Criteria

*From GDD `design/gdd/hint-letters.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-13 The pulse runs until the first press of a Play entry and restarts on the next entry from the Title; a background return does not restart it.
- [ ] AC-16 Background and return: old hints gone, three new ones at 0, 0.7, 1.4 s after the return.
- [ ] AC-17 No hint exists or spawns on the Title.

---

## Implementation Notes

*Derived from ADR-0002 and the epic:*

Gate and panel freezes (AC-14, AC-15) are the next milestone.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/HintLetters.swift`
- `apple/KidCore/Tests/KidCoreTests/HintLettersTests.swift`

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

- Depends on: `production/epics/hint-letters/story-002-life-drift-outcomes.md`
- Unlocks: None
