# Story 001: Spawn sequence, gap from the attempt, and the key exclusions

> **Epic**: Hint Letters (`production/epics/hint-letters/EPIC.md`)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/hint-letters.md`
**Requirement**: `TR-hints-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0004: Contracts, fixtures and harness
**ADR Decision Summary**: KidCore holds the pure rules with injected clocks (D3) and seeded streams (D4); the app reaches it only through the D6 seams and `tick(now:)`, in D7's call orders.
**ADR Version**: ADR-0002 2026-11-18; ADR-0004 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Forbidden: never let output depend on `Set` or `Dictionary` iteration order — a review rule (ADR-0002 D2)
- Required: every runner calls only the core's public API; hand-written cases from the GDD; never edit a merged `cases.json` (ADR-0004 D4–D6)

**Contracts**: hint-letters-v1 (`not-started: story:hint-letters` → `runner:` with this story)

---

## Acceptance Criteria

*From GDD `design/gdd/hint-letters.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-1 Play entered at hintTime 0: spawns at 0, 0.7 and 1.4 s, none more while 3 are on screen.
- [ ] AC-2 Every slot blocked at 2.0 s: no spawn, next attempt at 2.7 s.
- [ ] AC-3 Over 10,000 seeded spawns no new hint's key equals one on screen, the current or a queued key; with the pool fixed each key's frequency is 1/|pool| ± 2%.
- [ ] AC-23 The hint-letters-v1 fixtures match exactly (ids, keys, slots, centres, life, phase, attempt frames, draws used).

---

## Implementation Notes

*Derived from ADR-0002 and the epic:*

KidCore holds the pure rules with injected clocks (D3) and seeded streams (D4); the app reaches it only through the D6 seams and `tick(now:)`, in D7's call orders.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/HintLetters.swift`
- `apple/KidCore/Tests/KidCoreTests/HintLettersTests.swift`
- `apple/KidCore/Tests/ContractTests/HintLettersRunner.swift`

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

- Depends on: `production/epics/press-queue/story-001-start-queue-ignore.md`
- Unlocks: `production/epics/hint-letters/story-002-life-drift-outcomes.md`, `production/epics/hint-letters/story-003-clearances-slots.md`
