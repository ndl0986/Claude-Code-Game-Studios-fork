# Story 004: Word draws: no repeat, Play entry, and the v1 fallback

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
**Requirement**: `TR-kbrow-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Contracts, fixtures and harness; ADR-0003: Content pipeline
**ADR Decision Summary**: The system's numbers are hand-written contract cases from the GDD, run by a runner over the public API; the not-started registry row becomes `runner:` when its story lands.
**ADR Version**: ADR-0004 2026-11-18; ADR-0003 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Forbidden: never hard-code tuning values; timing and knobs are bundled data (ADR-0001 D6)

---

## Acceptance Criteria

*From GDD `design/gdd/onscreen-keyboard-row.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-11 With a fixed draw sequence 1,000 changes never repeat a word twice in a row, and the F4 fixture gives index 2.
- [ ] AC-12 Each Title → Play entry draws a new word (no repeat of the last) and fades the row in.
- [ ] AC-16 A v1 theme without `rowWords` shows FOSSIL (or ABC), never changes, one debug line.

---

## Implementation Notes

*Derived from ADR-0004 and the epic:*

TASK-135 (K-49) is **merged at 5647a15f**; the ACs here are the merged GDD's (identical to 180228bf, checked). TASK-141 cuts **keyboard-row-v2** to supersede v1 with the K-49 cases.

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

- Depends on: `production/epics/keyboard-row/story-003-due-quiet-change.md`
- Unlocks: `production/epics/keyboard-row/story-005-auto-on-keyboard-presence.md`
