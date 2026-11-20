# Story 001: Launch order, the first frame's look, and the pending start

> **Epic**: App Shell & Title (`production/epics/app-shell/EPIC.md`)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/app-shell-title.md`
**Requirement**: `TR-shell-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Contracts, fixtures and harness; ADR-0005: Settings persistence; ADR-0002: Modules, seams and Kotlin-mappable types
**ADR Decision Summary**: The system's numbers are hand-written contract cases from the GDD, run by a runner over the public API; the not-started registry row becomes `runner:` when its story lands.
**ADR Version**: ADR-0004 2026-11-18; ADR-0005 2026-11-18; ADR-0002 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: MEDIUM
**Engine Notes**: See the governing ADR's Engine Compatibility; prove APIs by building and running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: one synchronous settings read at launch, before the first frame (ADR-0005 D2, D9)
- Required: every runner calls only the core's public API; hand-written cases from the GDD; never edit a merged `cases.json` (ADR-0004 D4–D6)
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)

**Contracts**: app-shell-v1 (this story adds the runner file, reporting the cases not yet passing as NOT ASSESSED — it is not registered while the row is `not-started`, since ContractKit fails a registered runner on a not-started row; the row flips to `runner:` in app-shell/004)

---

## Acceptance Criteria

*From GDD `design/gdd/app-shell-title.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-1 An instrumented launch logs the settings read before the first frame, the theme load after the read, and "playable" only after "theme ready".
- [ ] AC-2 At 06:30, 12:00, 17:00 and 21:00 (injected clock) the first frame is the matching look, no text (screenshots).
- [ ] AC-7 With the theme load delayed 2 s, a start at 0.1 s plays E5 at once and enters Play exactly once at 2.0 s; starts at 0.5 and 1.0 s change nothing.

---

## Implementation Notes

*Derived from ADR-0004 and the epic:*

settings/003 provides the read-before-first-frame and the theme-ready gate.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/AppShell.swift`
- `apple/LetterMorph/LetterMorphApp.swift`
- `apple/LetterMorphTests/LaunchOrderTests.swift`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY-READY skipped — Lean mode).

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: Integration: an integration test (path under Files) OR a documented run in `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/settings/story-003-launch-read-holds-play.md`, `production/epics/scene/story-001-looks-and-clocks.md`
- Unlocks: `production/epics/app-shell/story-002-title-start-return.md`, `production/epics/app-shell/story-005-launch-times-device.md`
