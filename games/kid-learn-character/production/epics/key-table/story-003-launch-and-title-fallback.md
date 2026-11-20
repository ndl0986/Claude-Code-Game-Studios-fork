# Story 003: Launch falls back to Dinosaurs for a broken stored theme; a bad titleCastId falls back to key A

> **Epic**: Key Table & Theme Data (`production/epics/key-table/EPIC.md`)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/key-table-theme-data.md` — (AC-13, AC-16)
**Requirement**: `TR-keytable-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Content pipeline; ADR-0005: Settings persistence
**ADR Decision Summary**: ADR-0003 D2: a failing theme at load is not used and Dinosaurs is the fallback; the stored record is not rewritten by the fallback (ADR-0005: reads never write).
**ADR Version**: ADR-0003 2026-11-18; ADR-0005 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Pure logic with injected Settings Store and theme source.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: every KidCore type needing time or chance takes it injected (ADR-0002 Impl.)
- Forbidden: never let output depend on `Set` or `Dictionary` iteration order (ADR-0002 D2)

---

## Acceptance Criteria

*From GDD `design/gdd/key-table-theme-data.md`, scoped to this story:*

- [ ] With the stored `themeId` naming a broken test theme, launch shows Dinosaurs, the stored record still holds the broken id afterwards, and one debug log line is written (AC-13, injected Settings Store).
- [ ] Loading a test theme with a bad `titleCastId` makes the Title show key A's item 0 and writes one debug log line (AC-16 run-time half).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0003 first):*

`KeyTable.titleCast` already returns `fellBack`; this story wires the launch choice and the log line through `DebugLog`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- settings/002: the store side of "theme kept on failure" (Settings AC-10)

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/KidCore/Sources/KidCore/ThemeChoice.swift`
- `apple/KidCore/Tests/KidCoreTests/ThemeChoiceTests.swift`

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

- Depends on: `production/epics/key-table/story-002-app-theme-load.md`
- Unlocks: None
