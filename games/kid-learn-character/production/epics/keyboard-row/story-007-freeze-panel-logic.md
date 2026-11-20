# Story 007: The row under the gate freeze and the panel, and on/off from settings (logic)

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
**Requirement**: `TR-kbrow-001`, `TR-kbrow-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Contracts, fixtures and harness; ADR-0005: Settings persistence
**ADR Decision Summary**: The system's numbers are hand-written contract cases from the GDD, run by a runner over the public API; the not-started registry row becomes `runner:` when its story lands.
**ADR Version**: ADR-0004 2026-11-18; ADR-0005 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: MEDIUM
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Required: every runner calls only the core's public API; hand-written cases from the GDD; never edit a merged `cases.json` (ADR-0004 D4–D6)

**Contracts**: keyboard-row-v2 (TASK-141; `not-started` → `runner:` with this story, the epic's last logic story; v1 is superseded)

---

## Acceptance Criteria

*From GDD `design/gdd/onscreen-keyboard-row.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-13 Under the gate freeze a running light and word fade hold their values and continue after `resume()`.
- [ ] AC-15 (logic) Turning `keyboardRow` on shows the row with a 0.3 s fade after the panel closes and lifts the ground from the next reveal; off with a keyboard present removes the rects at once and fades out; off with none leaves `shown` unchanged.
- [ ] AC-23 / AC-14 (panel half, logic) A disconnect under the panel or the challenge shows nothing under the dim and fades in with a new word on close; under the panel a touch on the row is not a press. All keyboard-row-v2 cases pass and its row flips to `runner:`.

---

## Implementation Notes

*Derived from ADR-0004 and the epic:*

TASK-135 (K-49) is **merged at 5647a15f**; the ACs here are the merged GDD's (identical to 180228bf, checked). (Freeze/resume, panel and theme-switch **logic** is in Demo 1 so the contract runner passes every case; only their UI and device checks are next milestone — game-qc-android, TASK-140.) **Out:** AC-19 (Android insets) waits for the Android build.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/KeyboardRow.swift`
- `apple/KidCore/Tests/KidCoreTests/KeyboardRowTests.swift`
- `apple/KidCore/Tests/ContractTests/KeyboardRowRunner.swift`

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

- Depends on: `production/epics/keyboard-row/story-005-auto-on-keyboard-presence.md`
- Unlocks: None
