# Story 005: Automatic row: shown without a hardware keyboard, hidden with one (K-49)

> **Epic**: On-screen Keyboard Row (`production/epics/keyboard-row/EPIC.md`)
> **Status**: Blocked — BLOCKED: blocked-by TASK-135 (180228bf pending merge) and input/006 (keyboard presence; ADR-0007 Proposed for the platform read)
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/onscreen-keyboard-row.md` (TASK-135 revision 180228bf, pending merge)
**Requirement**: `TR-kbrow-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Contracts, fixtures and harness; ADR-0005: Settings persistence; ADR-0007: Input adapters (**Proposed**)
**ADR Decision Summary**: The system's numbers are hand-written contract cases from the GDD, run by a runner over the public API; the not-started registry row becomes `runner:` when its story lands.
**ADR Version**: ADR-0004 2026-11-18; ADR-0005 2026-11-18; ADR-0007 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)

---

## Acceptance Criteria

*From GDD `design/gdd/onscreen-keyboard-row.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-1 With `keyboardRow` false: with a keyboard no key drawn and no rects; with none, Play entry fades the row in with a new word; on the Mac (`keyboardPresent` constant true) never drawn.
- [ ] AC-20 / AC-21 Connected at t: unchanged at t + 0.49, rects gone at t + 0.5, Hidden at t + 0.8, next draw uses the old word as `last`; disconnected at t: a word drawn and Fading in at t + 0.5, Showing at t + 0.8.
- [ ] AC-22 true / false / true at t, t + 0.2, t + 0.4: nothing until t + 0.9, then hidden.
- [ ] AC-24 With `keyboardRow` true, connecting and disconnecting change nothing.

---

## Implementation Notes

*Derived from ADR-0004 and the epic:*

TASK-135 at 180228bf (K-49) is **pending merge** (approved by game-dev-ios, waiting on game-qc-android): the ACs here are copied from that revision of the GDD; re-check them against the merged text before `/story-readiness`. The `keyboardPresent` signal is input/006.

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

- Depends on: `production/epics/keyboard-row/story-004-words-draw-fallback.md`, `production/epics/input/story-006-keyboard-presence-signal.md`
- Unlocks: `production/epics/keyboard-row/story-006-row-look-device.md`
