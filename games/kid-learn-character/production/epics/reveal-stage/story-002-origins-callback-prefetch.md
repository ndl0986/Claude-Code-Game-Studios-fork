# Story 002: Glyph origins, the same-callback rule, and prefetch by peek

> **Epic**: Reveal Stage (`production/epics/reveal-stage/EPIC.md`)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/reveal-stage.md`
**Requirement**: `TR-reveal-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0004: Contracts, fixtures and harness
**ADR Decision Summary**: KidCore holds the pure rules with injected clocks (D3) and seeded streams (D4); the app reaches it only through the D6 seams and `tick(now:)`, in D7's call orders.
**ADR Version**: ADR-0002 2026-11-18; ADR-0004 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure KidCore logic: LOW in practice.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.)
- Required: one per-frame entry `tick(now:)` on the uptime clock; keep D7's call orders (ADR-0002 D6, D7)

---

## Acceptance Criteria

*From GDD `design/gdd/reveal-stage.md`, scoped to this story (AC numbers are the GDD's):*

- [ ] AC-3 A hint touch rises from its centre, a row key from its centre, a hardware key with a matching hint from that hint (consumed on started/queued, kept on ignored), with no match from (640, 700).
- [ ] AC-4 For each outcome, Audio, Hint Letters and the starlight/sparkle are called inside the `press(p)` callback, never on a later frame.
- [ ] AC-15 A queued key's item is peeked without changing `lastShown`, prefetched, and released if the real resolve picks another.

---

## Implementation Notes

*Derived from ADR-0002 and the epic:*

KidCore holds the pure rules with injected clocks (D3) and seeded streams (D4); the app reaches it only through the D6 seams and `tick(now:)`, in D7's call orders.

---

## Out of Scope

- The Parent Gate, grown-up panel and Child Lock-in parts of this GDD (next milestone, K-48); the other stories of this epic.

---

## Files

*Planned; `/dev-story` replaces this list. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/RevealStage.swift`
- `apple/KidCore/Tests/KidCoreTests/RevealStageTests.swift`

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

- Depends on: `production/epics/reveal-stage/story-001-start-reveal-timeline.md`, `production/epics/key-table/story-004-pick-and-peek-tests.md`
- Unlocks: `production/epics/reveal-stage/story-003-taps-settle-flags.md`
