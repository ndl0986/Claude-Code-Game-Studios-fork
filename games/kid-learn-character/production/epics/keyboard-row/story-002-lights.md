# Story 002: Key lights: any press, an ignored press, and hardware keys

> **Epic**: On-screen Keyboard Row (`production/epics/keyboard-row/EPIC.md`)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/onscreen-keyboard-row.md` (as merged by TASK-135, 5647a15f)
**Requirement**: `TR-kbrow-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Contracts, fixtures and harness; ADR-0006: Stage runtime
**ADR Decision Summary**: The system's numbers are hand-written contract cases from the GDD, run by a runner over the public API; the not-started registry row becomes `runner:` when its story lands.
**ADR Version**: ADR-0004 2026-11-18; ADR-0006 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Required: Reduce Motion is read live and applied at the next reveal (ADR-0006 D6)

---

## Acceptance Criteria

*From GDD `design/gdd/onscreen-keyboard-row.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-5 Any press of a row key sets its glow to 0.5 on the same frame and back to 0 after 0.35 s; Reduce Motion keeps scale 1.
- [ ] AC-6 With the queue full a row press lights the key, shows the sparkle burst and requests E2.
- [ ] AC-7 With EGG showing a hardware G lights both G keys; the glyph rises from the leftmost G unless a G hint is on screen.

---

## Implementation Notes

*Derived from ADR-0004 and the epic:*

TASK-135 (K-49) is **merged at 5647a15f**; the ACs here are the merged GDD's (identical to 180228bf, checked).

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/KeyboardRow.swift`
- `apple/KidCore/Tests/KidCoreTests/KeyboardRowTests.swift`

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

- Depends on: `production/epics/keyboard-row/story-001-layout-size-origin.md`
- Unlocks: `production/epics/keyboard-row/story-003-due-quiet-change.md`
