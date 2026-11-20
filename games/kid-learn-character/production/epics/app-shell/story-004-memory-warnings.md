# Story 004: Memory-warning shedding order, and the gate and panel states of the shell (logic)

> **Epic**: App Shell & Title (`production/epics/app-shell/EPIC.md`)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/app-shell-title.md`
**Requirement**: `TR-shell-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0004: Contracts, fixtures and harness
**ADR Decision Summary**: KidCore holds the pure rules with injected clocks (D3) and seeded streams (D4); the app reaches it only through the D6 seams and `tick(now:)`, in D7's call orders.
**ADR Version**: ADR-0002 2026-11-18; ADR-0004 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)

**Contracts**: app-shell-v1 (`not-started: story:app-shell` → `runner:` with this story, the epic's last logic story)

---

## Acceptance Criteria

*From GDD `design/gdd/app-shell-title.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-11 A warning sheds prefetched, leaving and list textures in that order, never the current creature or the decoded audio; a second within 30 s also ends a walking parade, counted as played.
- [ ] The app-shell-v1 cases driven by gate and panel events (Title / Play / Gate / Panel / Background transitions) pass on the KidCore state machine; with them all the cases pass and its row flips to `runner:`.

---

## Implementation Notes

*Derived from ADR-0002 and the epic:*

(Freeze/resume, panel and theme-switch **logic** is in Demo 1 so the contract runner passes every case; only their UI and device checks are next milestone — game-qc-android, TASK-140.) **Out:** AC-3 and AC-4 (the Mac kiosk order and K-21 relaunch) are Child Lock-in's, next milestone; if app-shell-v1 holds kiosk-only cases they need the Child Lock-in logic, so record them in the registry note rather than leave them silently unrun.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/AppShell.swift`
- `apple/KidCore/Tests/ContractTests/AppShellRunner.swift`
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

- Depends on: `production/epics/app-shell/story-002-title-start-return.md`, `production/epics/parade/story-002-walk-positions-clock.md`
- Unlocks: None
