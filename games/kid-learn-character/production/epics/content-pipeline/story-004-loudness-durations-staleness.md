# Story 004: Loudness to target, `voiceDurations` from the files, and the staleness check

> **Epic**: Content Pipeline (Tools) (`production/epics/content-pipeline/EPIC.md`)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/key-table-theme-data.md` — (AC-14, V12, V15)
**Requirement**: `TR-keytable-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Content pipeline
**ADR Decision Summary**: ADR-0003 D5/D6: loudness by ITU-R BS.1770 within ±1 LU of the class target, sfx ≤ 2.0 s, `voiceDurations` measured from the files (never hand-edited); a staleness check re-bakes in memory and re-measures.
**ADR Version**: ADR-0003 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH (AVAudioFile priming/padding)
**Engine Notes**: Duration must account for AAC priming/padding (ADR-0003 Knowledge Risk).

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: loudness by ITU-R BS.1770 within ±1 LU of the class target; sfx ≤ 2.0 s (ADR-0003 D5)
- Required: a staleness check re-bakes in memory and re-measures `voiceDurations` (ADR-0003 D3–D6)
- Forbidden: never hand-edit `voiceDurations` (ADR-0003 D4)

---

## Acceptance Criteria

*From GDD `design/gdd/key-table-theme-data.md`, scoped to this story:*

- [ ] The validator reports a `voiceDurations` entry for every voice line in every locale, each within ±0.01 s of its file (Key Table AC-14).
- [ ] A test word line of 1.30 s and a test letter line of 1.10 s each fail the build and name the file (Key Table AC-14).
- [ ] Every voice and sfx file measures within ±1 LU of its class target; an sfx over 2.0 s fails naming it (ADR-0003 D5).
- [ ] Changing one source (script or SVG) without re-baking makes the staleness check fail naming the file (ADR-0003 D3).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0003 first):*

The loudness meter is our own Swift (K-31). The existing staleness stub in `ContentValidator` (missing source) is extended to compare re-baked bytes and re-measured durations.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- story-003: rendering and encoding

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `apple/Tools/Sources/ToolsCore/Loudness.swift`
- `apple/Tools/Sources/ToolsCore/ContentValidator.swift`
- `apple/Tools/Tests/ToolsTests/LoudnessTests.swift`

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

- Depends on: `production/epics/content-pipeline/story-003-voice-render-encode.md`
- Unlocks: `production/epics/key-table/story-001-dinosaurs-theme-data.md`
