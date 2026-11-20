# Story 005: `kidtools validate` runs all of V1–V18 on the real bundle and fails the build naming theme, rule and item

> **Epic**: Content Pipeline (Tools) (`production/epics/content-pipeline/EPIC.md`)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/key-table-theme-data.md` — (AC-4, AC-17, AC-18)
**Requirement**: `TR-keytable-001`, `TR-keytable-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Content pipeline; ADR-0011: Build, verify and PKC gates; ADR-0004: Contracts, fixtures and harness
**ADR Decision Summary**: ADR-0003 D3: one validator, the V-rules written once in KidCore over decoded models and the `ContentProbe` seam; Tools runs it at build with a file-system probe, the app at load with a bundle probe. ADR-0011: verify.sh runs it before every push.
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

- [ ] Removing one shipped file makes `kidtools validate` (and so verify.sh) fail naming the file (Key Table AC-4).
- [ ] Test themes with 7 rowWords, a duplicate, a 9-letter word, a digit or lowercase word, and a schema-2 theme without rowWords each fail naming theme and rule (Key Table AC-17).
- [ ] Test themes with prefix "Dino", folder ≠ id, two themes sharing a prefix, and a case-only file match each fail naming the rule, in both the Tools and the model runner (Key Table AC-18).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0003 first):*

KidCore's `KeyTable.validate` already implements V1–V18 and key-table-schema-v1 runs (`runner:` KeyTableModelRunner + Tools.KeyTableFileLayer). This story replaces the TASK-079 stub path in `ContentValidator` (V1/V9/stale only) with the full call over a file-system `ContentProbe`, keeping TASK-125's theme-in-progress rule.

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

- Depends on: `production/epics/content-pipeline/story-001-cast-svg-bake.md`, `production/epics/content-pipeline/story-002-glyph-bake.md`
- Unlocks: `production/epics/key-table/story-001-dinosaurs-theme-data.md`, `production/epics/key-table/story-002-app-theme-load.md`
