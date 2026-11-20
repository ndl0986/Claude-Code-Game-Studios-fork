# Story 002: Title starts, the first reveal, the away rule and cold launch

> **Epic**: App Shell & Title (`production/epics/app-shell/EPIC.md`)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/app-shell-title.md`
**Requirement**: `TR-shell-001`, `TR-shell-002`, `TR-shell-006`
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

*From GDD `design/gdd/app-shell-title.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-5 D, 7 and a tap at (200, 200) each start play; Space and Esc do not (the moon tap needs the Parent Gate).
- [ ] AC-6 After a start by D the queue is empty with no current; D's repeat and up make no press; the next D down is reveal 1.
- [ ] AC-8 Away 10 min → Play with the settled creature and three fresh hints; away 31 min → the Title; an 8 h sleep (continuous clock advanced, uptime not) → the Title.
- [ ] AC-9 After the process is ended in the background, the next launch shows the Title with nothing restored.

---

## Implementation Notes

*Derived from ADR-0002 and the epic:*

AC-12 (no collection APIs) is checked by privacy/002's scan.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/AppShell.swift`
- `apple/KidCore/Tests/KidCoreTests/AppShellTests.swift`

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

- Depends on: `production/epics/app-shell/story-001-launch-order-first-frame.md`, `production/epics/input/story-002-repress-and-title.md`
- Unlocks: `production/epics/app-shell/story-004-memory-warnings.md`
