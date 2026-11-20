# Story 002: Store behaviours: theme kept on failure, migration, reset, one notification per change

> **Epic**: Settings Store (`production/epics/settings/EPIC.md`)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/settings-store.md` — (AC-10, AC-12, AC-13, AC-14)
**Requirement**: `TR-settings-001`, `TR-settings-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Settings persistence; ADR-0004: Contracts, fixtures and harness
**ADR Decision Summary**: ADR-0005: reads never write; one notification per change on the main thread; Reset removes the record (R9); migration to the app's version on the next write.
**ADR Version**: ADR-0005 2026-11-18; ADR-0004 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Plain Swift over the injected backend.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: one synchronous read at launch, before the first frame (ADR-0005 D9)
- Forbidden: never a JSON library in the settings-record writer/reader (ADR-0004 D3)

---

## Acceptance Criteria

*From GDD `design/gdd/settings-store.md`, scoped to this story:*

- [ ] With `themeId` "vehicles" stored and not bundled, launch loads Dinosaurs and the stored `themeId` is still "vehicles" after a later volume write (AC-10).
- [ ] A v1 fixture migrates to the expected record; a record with `schemaVersion` 99 and an unknown key uses the known fields and, after a volume change, is written at the app's version without the unknown key (AC-12).
- [ ] Reset gives all defaults and the first-launch state with exactly one notification; one field change gives exactly one notification on the main thread carrying the whole record, and the launch read gives none (AC-13, AC-14).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0005 first):*

Check first which of these the existing `SettingsStore` and settings-record-v2 cases already prove; write only the missing tests and code. **TASK-135 (K-49):** the `keyboardRow` default in AC-1 may change; re-read AC-1 after TASK-135 merges.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- settings/003: launch order and holding play

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/SettingsStore.swift`
- `apple/KidCore/Tests/KidCoreTests/SettingsStoreTests.swift`

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
- Unlocks: None
