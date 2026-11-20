# Story 002: Life and fades, drift, press outcomes and `originFor`

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

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0004: Contracts, fixtures and harness
**ADR Decision Summary**: KidCore holds the pure rules with injected clocks (D3) and seeded streams (D4); the app reaches it only through the D6 seams and `tick(now:)`, in D7's call orders.
**ADR Version**: ADR-0002 2026-11-18; ADR-0004 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)

---

## Acceptance Criteria

*From GDD `design/gdd/hint-letters.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-8 Every life is 4.8–7.2 s; alpha and scale match F2 at the example ages within 1e-6; removed at age = life.
- [ ] AC-9 Position is a pure function of (spawn data, age); |offset| ≤ 12.8.
- [ ] AC-10 A hint touch `started`/`queued` consumes it; `ignored` keeps it, holds it still, alpha 1 at once; a matching hardware key consumes on started/queued and leaves it on ignored.
- [ ] AC-11 `originFor` returns the matching hint's current centre or none; `source` unchanged.

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

- Depends on: `production/epics/hint-letters/story-001-spawn-and-exclusions.md`
- Unlocks: `production/epics/hint-letters/story-004-pulse-background-title.md`, `production/epics/hint-letters/story-005-parade-dim-reduce-motion.md`
