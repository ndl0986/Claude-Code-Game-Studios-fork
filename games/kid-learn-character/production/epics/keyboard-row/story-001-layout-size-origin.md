# Story 001: Row layout, hit size, origin and the published band

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
**Requirement**: `TR-kbrow-001`, `TR-kbrow-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Contracts, fixtures and harness; ADR-0006: Stage runtime
**ADR Decision Summary**: The system's numbers are hand-written contract cases from the GDD, run by a runner over the public API; the not-started registry row becomes `runner:` when its story lands.
**ADR Version**: ADR-0004 2026-11-18; ADR-0006 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Required: every runner calls only the core's public API; hand-written cases from the GDD; never edit a merged `cases.json` (ADR-0004 D4–D6)
- Required: ppi from the bundled model table (iPad) or `CGDisplayScreenSize` (Mac); unknown → the class's highest ppi (ADR-0006 D7)

**Contracts**: keyboard-row-v2 (TASK-141; supersedes v1 with the K-49 cases): this story adds the runner file, reporting unfinished cases as NOT ASSESSED, unregistered; the row flips to `runner:` in keyboard-row/007

---

## Acceptance Criteria

*From GDD `design/gdd/onscreen-keyboard-row.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-2 For REX, NEST and an 8-letter word the key centres and hit spans equal F1; every hit rect lies inside x 64…1216, y 582…716.
- [ ] AC-3 The hit rect is 144 × 134 units; on the smallest Mac window (1.5, 254 ppi) ≥ 18 mm both sides.
- [ ] AC-4 A tap on X in REX gives one press, `source = keyboardRow`, origin (784, 649); x 711.9 → E, 712.1 → X, exactly 712.0 → E.
- [ ] AC-17 The band (y ≥ 582) and key rects are published while the row is on, withdrawn when off.

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

- Depends on: `production/epics/input/story-003-touch-classification.md`
- Unlocks: `production/epics/keyboard-row/story-002-lights.md`, `production/epics/accessibility/story-006-invert-touch-sound-colour.md`
