# Story 001: The `UserDefaults` backend: one value under one key, nil writes, no autosave or restoration

> **Epic**: Settings Store (`production/epics/settings/EPIC.md`)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/settings-store.md` — (AC-3, AC-8, AC-16)
**Requirement**: `TR-settings-001`, `TR-settings-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Settings persistence; ADR-0002: Modules, seams and Kotlin-mappable types; ADR-0011: Build, verify and PKC gates
**ADR Decision Summary**: ADR-0005 D1/D2/D5/D6: one `Data` value under `"settings"` in `UserDefaults.standard`, the exact bytes of KidCore's canonical writer; `write` returns nil; window-frame autosave and state restoration off; privacy manifest `CA92.1` only.
**ADR Version**: ADR-0005 2026-11-18; ADR-0002 2026-11-18; ADR-0011 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: MEDIUM
**Engine Notes**: On-disk atomicity of one key is not sourced (ADR-0005 Knowledge Risk): the atomic-write AC uses the test seam.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: one value under `"settings"` in `UserDefaults.standard`; `read()` returns the bytes byte for byte; `write` returns nil on Apple; all backend calls on the main thread (ADR-0005 D1, D2)
- Forbidden: never an app group, `suiteName:`, a file, `register(defaults:)`, `synchronize()`, KVO, `@AppStorage` or iCloud (ADR-0005 D1–D8)
- Required: turn off window-frame autosave and window/scene state restoration (ADR-0005 D5)

**Contracts**: settings-record-v2 (already `runner:`; keep it green)

**Device rows that close it** (`production/qa/device-checks-plan.md`): M-8 (one app-written key on the Mac)

---

## Acceptance Criteria

*From GDD `design/gdd/settings-store.md`, scoped to this story:*

- [ ] The record's keys are exactly `schemaVersion` plus the platform's R1 fields, no value is a date, UUID or identifier, and the store is the only code calling the preferences API (build check) (AC-3).
- [ ] Given stored record A, a write of B interrupted before commit (test seam) reads back A or B in full, and the record is one value under one key (AC-8).
- [ ] No `NSUbiquitousKeyValueStore`, CloudKit or network API for the store; the privacy manifest lists UserDefaults with `CA92.1` and no file-timestamp category (AC-16).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0005 first):*

KidCore's `SettingsStore`, canonical writer/reader and settings-record-v2 runner exist (TASK-079). This story adds the app's backend and the build checks. The M-8 device row (one app-written key) is its device proof.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- settings/002: KidCore store behaviours

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/LetterMorph/UserDefaultsBackend.swift`
- `apple/LetterMorphTests/UserDefaultsBackendTests.swift`
- `apple/LetterMorph/PrivacyInfo.xcprivacy`

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

- Depends on: None
- Unlocks: `production/epics/settings/story-003-launch-read-holds-play.md`, `production/epics/privacy/story-001-release-static-checks.md`
