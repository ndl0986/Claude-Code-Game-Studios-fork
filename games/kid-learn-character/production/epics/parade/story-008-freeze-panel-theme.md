# Story 008: Parade and meter under the gate freeze, the panel and a theme switch (logic)

> **Epic**: Parade (`production/epics/parade/EPIC.md`)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/parade.md`
**Requirement**: `TR-parade-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Contracts, fixtures and harness; ADR-0002: Modules, seams and Kotlin-mappable types
**ADR Decision Summary**: The system's numbers are hand-written contract cases from the GDD, run by a runner over the public API; the not-started registry row becomes `runner:` when its story lands.
**ADR Version**: ADR-0004 2026-11-18; ADR-0002 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Required: every runner calls only the core's public API; hand-written cases from the GDD; never edit a merged `cases.json` (ADR-0004 D4–D6)

**Contracts**: parade-v2 (`not-started: story:parade` → `runner:` with this story, the epic's last logic story)

---

## Acceptance Criteria

*From GDD `design/gdd/parade.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-19 Walking at pt 4, `freeze()` 20 s then `resume()`: every walker's x unchanged, E12 paused and resumed, the walk ends at pt 11; Armed with 0.5 s of the beat left, the parade starts 0.5 s after the resume; a correct answer fades it out. AC-9 Panel open at pt 5: alpha 0 within 0.6 s, Ended, no replay on close.
- [ ] AC-21 Armed at 10.0, panel 10.8–30.0: no parade under the panel, Waiting for art at 31.5; background 10.8–50.0: 51.5.
- [ ] AC-25 / AC-33 Under the challenge or panel a filling cell's alpha is 1 and the glow holds at 0.40; a light in flight is removed and its cell lit at once; nothing flies on close or return.
- [ ] AC-11 / AC-26 (switch half) Three keys in Dinosaurs, a switch to a test theme and back: neither is Armed mid-way, `filled` 0 on close with no fill animation, 3 back in Dinosaurs. All parade-v2 cases pass and its row flips to `runner:`.

---

## Implementation Notes

*Derived from ADR-0004 and the epic:*

(Freeze/resume, panel and theme-switch **logic** is in Demo 1 so the contract runner passes every case; only their UI and device checks are next milestone — game-qc-android, TASK-140.)

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/Parade.swift`
- `apple/KidCore/Tests/KidCoreTests/ParadeTests.swift`
- `apple/KidCore/Tests/ContractTests/ParadeRunner.swift`

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

- Depends on: `production/epics/parade/story-004-states-taps-debug.md`, `production/epics/parade/story-006-meter-light.md`
- Unlocks: None
