# Story 001: Audio plan: the E1–E9 event schedule, press sounds and the Title

> **Epic**: Audio & Voice (`production/epics/audio-voice/EPIC.md`)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/audio-voice.md`
**Requirement**: `TR-audio-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0004: Contracts, fixtures and harness
**ADR Decision Summary**: KidCore holds the pure rules with injected clocks (D3) and seeded streams (D4); the app reaches it only through the D6 seams and `tick(now:)`, in D7's call orders.
**ADR Version**: ADR-0002 2026-11-18; ADR-0004 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Required: one per-frame entry `tick(now:)` on the uptime clock; keep D7's call orders (ADR-0002 D6, D7)
- Forbidden: never hard-code tuning values; timing and knobs are bundled data (ADR-0001 D6)

**Contracts**: audio-plan-v1 (this story adds the runner file, reporting unfinished cases as NOT ASSESSED, unregistered; the row flips to `runner:` in audio-voice/003, the epic's last logic story)

---

## Acceptance Criteria

*From GDD `design/gdd/audio-voice.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-1 Event times: for C on the normal set E6 at s 0, E7 0.8, E8 2.45, E9 2.70 (±1 ms); reduced 0 / 0.4 / 1.2 / 1.45; the sfx-without-word, art-missing, glyph-missing and invalid-set cases as the GDD lists.
- [ ] AC-2 Press sounds: an empty queue schedules E1; a full queue E2 and no chime; a swallowed key or a tap in the cooldown nothing; a `sparkle` E3.
- [ ] AC-3 Title: `startPlay` schedules E5 and no voice line.

---

## Implementation Notes

*Derived from ADR-0002 and the epic:*

The plan is KidCore (Module Ownership: E1–E12 schedule) over a fake player layer; the AVAudioEngine adapter is story 004.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/AudioPlan.swift`
- `apple/KidCore/Tests/KidCoreTests/AudioPlanTests.swift`

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

- Depends on: None
- Unlocks: `production/epics/audio-voice/story-002-stacking-cap-mash.md`
