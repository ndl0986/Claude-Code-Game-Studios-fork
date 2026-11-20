# Story 004: Loudness to target, `voiceDurations` from the files, and the staleness check

> **Epic**: Content Pipeline (Tools) (`production/epics/content-pipeline/EPIC.md`)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: L
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
**Engine Notes**: *(K-52, 2026-11-20)* the baked audio is CAF LPCM: a decoded duration is its frame count ÷ 48 000, with no AAC priming or padding to remove; the staleness check may compare `.caf` bytes (byte-stable, TASK-144 evidence).

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

*Added 2026-11-20 (leader; TASK-144 / K-52 follow-ups; content-pipeline/001 follow-ups):*

- [ ] **Silence trim (leader-approved D5 detail):** before loudness normalisation, each rendered voice line is trimmed of leading and trailing audio below **−50 dBFS on the K-weighted 10 ms envelope**, keeping a **20 ms pad** each side with a **5 ms linear fade** in and out; the three values are tuning data in `src/voice-scripts/<locale>.json`. A test line with 0.4 s of silence at each end comes out within 20 ms (+ one envelope window) of the speech, and its first and last samples are 0 (no click). V15 and AC-6 measure the trimmed file.
- [ ] **No clipping (game-dev-ios, TASK-144):** the loudness and true-peak step runs before the CAF write, and the bake refuses any sample with |x| > 1.0 after normalisation, naming the file (a test feeds one).
- [ ] **Silhouette raster check (ADR-0003 D4; content-pipeline/001 follow-up):** a baked silhouette is compared with its art's body and outline at rest, at artboard scale (1 px = 1 unit), including the outer half of the 6-unit outline stroke; it passes when the symmetric difference lies within a 1 px band along the edge. A test silhouette offset by 3 units fails naming the file.
- [ ] **Idle-part check (ADR-0003 D4; content-pipeline/001 follow-up):** every part a family's idle data moves exists in that family's art with a pivot, else the bake fails naming the part and the file. *NOT ASSESSED until the Cast Rendering idle data exists (Luan's OQ-1 for four families); the check is built against a test idle file and stays skipped, saying so, for the real content.*
- [ ] **Staleness on CAF (K-52):** the staleness check re-renders a line or sound and compares the `.caf` bytes (byte-stable under K-52) and the re-measured `voiceDurations`.
- [ ] **The meter:** loudness uses story 007's `LoudnessMeter` (`apple/Tools/Sources/ToolsCore/Loudness.swift`); no second meter.

---

> **The meter is built in story 007** (leader, 2026-11-20): `apple/Tools/Sources/ToolsCore/Loudness.swift`, the
> ADR-0003 D5 BS.1770 meter with its EBU Tech 3341 self-check. This story's loudness AC reuses it for the gate on every
> voice and sfx file; it doesn't build a second meter.

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
- Unlocks: `production/epics/content-pipeline/story-005-validator-on-real-content.md`, `production/epics/key-table/story-001-dinosaurs-theme-data.md`
