# Story 003: Jittered clearances, static slots, the widest creature, never empty

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
**Requirement**: `TR-hints-001`, `TR-hints-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0003: Content pipeline
**ADR Decision Summary**: KidCore holds the pure rules with injected clocks (D3) and seeded streams (D4); the app reaches it only through the D6 seams and `tick(now:)`, in D7's call orders.
**ADR Version**: ADR-0002 2026-11-18; ADR-0003 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Forbidden: never hard-code tuning values; timing and knobs are bundled data (ADR-0001 D6)

---

## Acceptance Criteria

*From GDD `design/gdd/hint-letters.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-4 Over 100,000 seeded spawns no jittered centre violates an F4 clearance; drifted hit circles never overlap each other or the moon over their lives.
- [ ] AC-5 Every slot passes F4 at zero jitter with no creature (build check); L1 152.1 from the moon, R1 142.0 from the nearest token.
- [ ] AC-6 With the widest shipped creature held, the inner slots are blocked and 3 hints still spawn outside.
- [ ] AC-7 Over 10,000 simulated minutes with the widest creature, at k 1.0 / 1.10 / 1.2: never without a hint for more than one gap, no overlap; at 1.2 at most 2 on screen.

---

## Implementation Notes

*Derived from ADR-0002 and the epic:*

The moon is the Parent Gate's (next milestone) but its clearance stays in the slot table so the slots don't move later. TR-hints-003 is Partial (no ADR names the validator rule).

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

- Depends on: `production/epics/hint-letters/story-001-spawn-and-exclusions.md`, `production/epics/key-table/story-001-dinosaurs-theme-data.md`
- Unlocks: `production/epics/hint-letters/story-006-size-data-look.md`
