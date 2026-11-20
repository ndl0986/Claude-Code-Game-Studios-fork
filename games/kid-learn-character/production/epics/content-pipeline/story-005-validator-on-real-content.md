# Story 005: The validator on the real Dinosaurs content: verify.sh fails naming theme, rule and item

> **Epic**: Content Pipeline (Tools) (`production/epics/content-pipeline/EPIC.md`)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/key-table-theme-data.md` — (AC-4)
**Requirement**: `TR-keytable-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Content pipeline; ADR-0011: Build, verify and PKC gates; ADR-0004: Contracts, fixtures and harness
**ADR Decision Summary**: ADR-0003 D3: one validator, the V-rules written once in KidCore over the `ContentProbe` seam; Tools runs it at build with a file-system probe. ADR-0011: verify.sh runs it before every push.
**ADR Version**: ADR-0003 2026-11-18; ADR-0011 2026-11-18; ADR-0004 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Plain Swift; file-system probe in Tools only.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: the V-rules are written once, in KidCore, as pure functions over decoded models and the `ContentProbe` seam; Tools and the app call them, never copy them (ADR-0003 D3)
- Forbidden: never keep separate validators for build and load (ADR-0003 Alt 3)
- Required: `tools/ci/verify.sh` before every push; a failing gate means nothing is pushed (ADR-0011 D2)

**Contracts**: key-table-schema-v1 (already `runner:`; keep it green)

---

## Acceptance Criteria

*From GDD `design/gdd/key-table-theme-data.md`, scoped to this story:*

- [ ] On the real Dinosaurs content (key-table/001), removing one shipped file makes `kidtools validate` and verify.sh fail naming theme, rule and file (Key Table AC-4).
- [ ] The staleness stub is replaced by content-pipeline/004's re-bake comparison in the same run, and a theme in progress (TASK-125) still reports NOT ASSESSED, never PASS.

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0003 first):*

**Already proved, credited:** `ContentValidator.run` calls `KeyTable.validate` (V1–V18) with a file-system `FileProbe` (ContentValidator.swift:68), and key-table-schema-v1 runs in both runners (KeyTableModelRunner + Tools.KeyTableFileLayer), which covers Key Table AC-17 and AC-18 and the V-rule verdicts. This story only proves the validator on the real shipped content.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- key-table/001: the Dinosaurs data itself

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/Tools/Sources/ToolsCore/ContentValidator.swift`
- `apple/Tools/Tests/ToolsTests/ContentValidatorTests.swift`

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

- Depends on: `production/epics/content-pipeline/story-004-loudness-durations-staleness.md`, `production/epics/key-table/story-001-dinosaurs-theme-data.md`
- Unlocks: `production/epics/key-table/story-001-dinosaurs-theme-data.md`, `production/epics/key-table/story-002-app-theme-load.md`
