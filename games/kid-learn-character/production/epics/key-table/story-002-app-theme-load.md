# Story 002: Load a theme in the app off the main thread; a failing or unknown-version theme is never made active

> **Epic**: Key Table & Theme Data (`production/epics/key-table/EPIC.md`)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/key-table-theme-data.md` — (AC-6, AC-7)
**Requirement**: `TR-keytable-001`, `TR-keytable-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Content pipeline; ADR-0002: Modules, seams and Kotlin-mappable types
**ADR Decision Summary**: ADR-0003 D2/D3/D7: the app decodes theme JSON at the edge, validates at load off the main thread with a bundle probe, and a theme failing V1 (unknown field or major schemaVersion) or V2 is never shown; KidCore receives plain models.
**ADR Version**: ADR-0003 2026-11-18; ADR-0002 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Decode in the app target only (`JSONDecoder` is banned in the cores).

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: the app validates a theme at load, off the main thread, with a bundle probe; a failing theme is never shown (ADR-0003 D3)
- Forbidden: never decode theme or content JSON in KidCore; never read `src/` from the app (ADR-0003 D7, Impl.)
- Guardrail: theme validation at load: off the main thread, one pass per load (ADR-0003 Performance)

---

## Acceptance Criteria

*From GDD `design/gdd/key-table-theme-data.md`, scoped to this story:*

- [ ] A theme with `schemaVersion: 3` is refused by an app that knows 1 and 2, and the app keeps the current theme (AC-6).
- [ ] A v1 test theme without `rowWords` loads with the row fallback (AC-6).
- [ ] Loading a theme runs off the main thread (the test asserts the thread), and a theme that fails the check is never made active (AC-7, broken fixture).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0003 first):*

A `ThemeSource` adapter in the app (ADR-0002 D6 seam) decodes with the existing `ThemeDecoder` rules, builds `ThemeAssetFacts` from a bundle probe, calls `KeyTable.validate`, and only then publishes the model on the main thread.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- key-table/003: launch fallback and title fallback

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/LetterMorph/ThemeLoader.swift`
- `apple/LetterMorphTests/ThemeLoaderTests.swift`

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

- Depends on: `production/epics/content-pipeline/story-005-validator-on-real-content.md`
- Unlocks: `production/epics/key-table/story-003-launch-and-title-fallback.md`, `production/epics/settings/story-003-launch-read-holds-play.md`
