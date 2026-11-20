# Story 005: Dim during the parade, Reduce Motion, and fading hints still count

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

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0006: Stage runtime
**ADR Decision Summary**: KidCore holds the pure rules with injected clocks (D3) and seeded streams (D4); the app reaches it only through the D6 seams and `tick(now:)`, in D7's call orders.
**ADR Version**: ADR-0002 2026-11-18; ADR-0006 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Required: Reduce Motion is read live and applied at the next reveal (ADR-0006 D6)

**Contracts**: hint-letters-v1 (`not-started: story:hint-letters` → `runner:` with this story, the epic's last logic story)

---

## Acceptance Criteria

*From GDD `design/gdd/hint-letters.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-18b Three hints at ages 1, 2, 3 s and `paradeWalking` on for 11 s: alpha 0.5 × F2 after 0.6 s, positions and ages unchanged, nothing spawns or expires, a dimmed hint is still a press; off: back over 0.6 s, ages resume.
- [ ] AC-18 Reduce Motion: no drift, no pulse, scale 1, a consume fades over 0.3 s without sparks; turning it on mid-life freezes the offsets.
- [ ] AC-12 A touch inside `hitRadius` at alpha 0.1 is a press.
- [ ] AC-14 / AC-15 (logic) Gate challenge or panel at hintTime 3.0: hintTime stops, nothing moves, ages or spawns; after 8 s of uptime every hint resumes at its age from 3.0 and the 0 / 0.7 / 1.4 sequence does not replay. All hint-letters-v1 cases pass and its row flips to `runner:`.

---

## Implementation Notes

*Derived from ADR-0002 and the epic:*

(Freeze/resume, panel and theme-switch **logic** is in Demo 1 so the contract runner passes every case; only their UI and device checks are next milestone — game-qc-android, TASK-140.) **Out:** AC-20 (Android gesture insets) waits for the Android build (K-03).

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/HintLetters.swift`
- `apple/KidCore/Tests/KidCoreTests/HintLettersTests.swift`
- `apple/KidCore/Tests/ContractTests/HintLettersRunner.swift`

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

- Depends on: `production/epics/hint-letters/story-002-life-drift-outcomes.md`, `production/epics/hint-letters/story-004-pulse-background-title.md`
- Unlocks: None
