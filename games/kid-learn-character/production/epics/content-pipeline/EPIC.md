# Epic: Content Pipeline (Tools)

> **Layer**: Foundation
> **GDD**: design/gdd/key-table-theme-data.md, design/gdd/cast-rendering.md R2/R7, design/gdd/morphcore.md, design/gdd/audio-voice.md R8
> **Architecture Module**: apple/Tools (ToolsCore + `kidtools`: bake tool, voice bake, validator; build-time only, nothing in the bundle)
> **Milestone**: Demo 1 (`production/milestones/demo-1.md`, K-48)
> **Status**: Ready
> **Stories**: Not yet created — after TASK-131's control manifest lands, run `/create-stories content-pipeline`

## Overview

The build-time tools that turn the 36 Dinosaurs items into shipped content: the SVG-subset bake for creatures and glyphs, the voice bake (Kokoro, K-41: pre-rendered, AAC mono, loudness target, voiceDurations), and the validator.

## Governing ADRs

| ADR | Status | Decision Summary | Engine Risk |
|-----|--------|------------------|-------------|
| ADR-0003: Content pipeline | Accepted | D1 layout, D3 validator, D4 SVG bake, D5/D6 voice and loudness | HIGH |
| ADR-0011: Build, verify and PKC gates | Accepted | verify.sh runs the validator | LOW |
| ADR-0013: Flash safety | Accepted | G1 data lints | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage | Demo 1 |
|-------|-------------|--------------|--------|
| TR-keytable-001 | Bundled themes validated at build and at load; unknown versions refused (V1-V17, sections 5-6) | ADR-0003 D2/D3; ADR-0004 key-table-schema-v1 ✅ | in (Tools side); closed by key-table |
| TR-keytable-004 | Voice and sfx pipeline: pre-rendered TTS, AAC mono, loudness target, voiceDurations from data (V12, V15) | ADR-0003 D5/D6 ✅ | in (voice bake); closed by key-table |
| TR-cast-001 | SVG subset bake tool; one baked file and one draw interface for both render options (R2, R7, R11) | ADR-0003 D1/D4 ✅ | in (SVG bake); closed by cast-rendering |
| TR-morph-002 | UI-free math; glyph and silhouette paths in the v1 SVG subset, glyphs baked from the OFL font | ADR-0001 D6; ADR-0003 D4 ✅ | in (glyph bake); closed by morphcore |
| TR-audio-006 | Voice source, licence and no run-time TTS (R8, Q8, L-09) | ADR-0003 D5/D6; ADR-0010 D10 ✅ | in (no run-time TTS, licence); closed by audio-voice |
| TR-hints-003 | Hint knobs data-validated at build, slots pass F4 (AC-21) | ⚠️ Partial: ADR-0003 D1 (data/ knob files) | in (validator rule); closed by hint-letters |

**Requirements covered by Accepted ADRs**: 5 / 6
**Untraced Requirements**: TR-hints-003 (Proposed-only or Partial; see the coverage column)

## Device Rows That Gate Story Closure

(`production/qa/device-checks-plan.md`; a spike run is ADR evidence, never AC evidence.)

- None: this epic closes on automated tests and its contract.

## Contracts

(`contracts/README.md` registry; `story:<x>` is the story stem that starts the runner.)

- key-table-schema-v1 (file layer: `runner:` Tools.KeyTableFileLayer)

## Notes

- Shares its TR-IDs with the systems that own them (key-table, cast-rendering, morphcore, audio-voice, hint-letters): this epic builds their Tools side.
- Its inputs are TASK-133's 36 asset specs and the art.

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every Demo 1 acceptance criterion of design/gdd/key-table-theme-data.md, design/gdd/cast-rendering.md R2/R7, design/gdd/morphcore.md, design/gdd/audio-voice.md R8 verified (criteria of out-of-Demo-1 requirements stay open for the next milestone)
- Logic and Integration stories have passing tests in the test root; each contract above runs (`runner:` row) instead of `not-started`
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/` (a lead sign-off too for Visual/Feel)
- Each device row above that gates a story is PASS on the production app, or the story records it NOT ASSESSED with the reason
