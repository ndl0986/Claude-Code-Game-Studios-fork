# Story 001: Author the Dinosaurs theme: 36 keys, items, words, sounds, hue slots, rowWords, titleCastId

> **Epic**: Key Table & Theme Data (`production/epics/key-table/EPIC.md`)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Config/Data
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/key-table-theme-data.md`
**Requirement**: `TR-keytable-003`, `TR-keytable-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Content pipeline; ADR-0001: Native Apple stack
**ADR Decision Summary**: ADR-0001 D6 / ADR-0003 D1–D2: every key, picture, sound and line is bundled JSON data in the theme folder layout; schema v2 per Key Table §2.
**ADR Version**: ADR-0003 2026-11-18; ADR-0001 2026-11-17

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Data only.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: `content/` layout per ADR-0003 D1; file names use the theme's `assetPrefix` (`dino`); paths relative, lowercase, exact case
- Forbidden: never hard-code keys, pictures, sounds, lines or tuning values (ADR-0001 D6)

---

## Acceptance Criteria

*From GDD `design/gdd/key-table-theme-data.md`, scoped to this story:*

- [ ] The validator reports 36/36 keys for Dinosaurs, each with exactly 1 item, and no other key (Key Table AC-1).
- [ ] Every letter item's word contains its letter and has `sound` set; only X has `"exception"` and is the only key in `soundExceptions` (AC-2); no hue slot holds more than 4 items and no siblings share one (AC-5).
- [ ] Dinosaurs passes with `titleCastId` = the T-Rex's castId and its 16 `rowWords` (AC-16, AC-17 Dinosaurs half).
- [ ] A content reviewer signs the T1–T8 toddler-safe checklist for every item, and every `sound` value was set by that listening check (AC-12).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0003 first):*

Needs TASK-133's 36 asset specs and the art, baked by content-pipeline 001–002, and the voice by 003–004. Turns `content/themes/dinosaurs/` from "theme in progress" (TASK-125) into a validated theme.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- key-table/002: loading it in the app

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `content/themes/dinosaurs/theme.json`
- `content/themes/dinosaurs/{cast,sil,sfx,voice}/ (baked)`
- `production/qa/evidence/<TASK>/<sha>/toddler-review.md`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY-READY skipped — Lean mode).

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**: Config/Data: smoke check pass (`production/qa/smoke-*.md`); here also `kidtools validate content` PASS on the shipped data

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/content-pipeline/story-001-cast-svg-bake.md`, `production/epics/content-pipeline/story-002-glyph-bake.md`, `production/epics/content-pipeline/story-003-voice-render-encode.md`, `production/epics/content-pipeline/story-004-loudness-durations-staleness.md`, `production/epics/content-pipeline/story-005-validator-full-build.md`
- Unlocks: None
