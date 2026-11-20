# Story 003: Voice bake: render every Dinosaurs line with Kokoro (K-41) and write CAF LPCM mono (K-52)

> **Epic**: Content Pipeline (Tools) (`production/epics/content-pipeline/EPIC.md`)
> **Status**: In Progress
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-20
> **Last Updated**: 2026-11-20
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/audio-voice.md` — (R8); key-table-theme-data.md (AC-4)
**Requirement**: `TR-keytable-004`, `TR-audio-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Content pipeline
**ADR Decision Summary**: ADR-0003 D5/D6: voice is pre-rendered at build time through an engine-agnostic TTS adapter (engine Kokoro, K-41, build machine only), encoded mono, named by line id; no run-time speech synthesis. *(K-52, 2026-11-20: CAF linear PCM 16-bit, not AAC.)*
**ADR Version**: ADR-0003 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: HIGH
**Engine Notes**: *(K-52, 2026-11-20: the AAC encoding and priming risks are moot; CAF LPCM, 16-bit mono 48 kHz.)* Formerly: `AVAudioConverter` AAC encoding settings and the priming/padding values are HIGH-risk (ADR-0003 Knowledge Risk): verify by running.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: voice files named by line id from the engine-agnostic TTS adapter (K-41 engine) (Tooling, ADR-0003 D5/D6)
- Required: approved libraries: none at run time; the K-41 TTS engine is a build-machine-only exception (ADR-0003 D6 note)
- Forbidden: never ffmpeg or other third-party tools in the pipeline (ADR-0003 Alt 2)

---

## Acceptance Criteria

*From GDD `design/gdd/audio-voice.md`, scoped to this story:*

- [ ] Every voice line the Dinosaurs theme names, for each locale in `voiceLocales`, is rendered and written as CAF linear PCM, 16-bit mono 48 kHz (K-52), under `voice/<locale>/…` named by line id, and resolves in the bundle (Key Table AC-4).
- [ ] The TTS engine is behind the adapter: swapping the engine changes no file layout or name (ADR-0003 D6).
- [ ] Nothing in the app target links a speech-synthesis API (Audio R8; ADR-0010 D10 is also checked by the PKC scan).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0003 first):*

Voice scripts already exist in `content/themes/dinosaurs/src/voice-scripts/en-us.json` (TASK-110). Kokoro runs on the build Mac only; record its version and voice in the bake log. Loudness and `voiceDurations` are story 004.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- story-004: loudness, `voiceDurations`, staleness

---

## Files

- `apple/Tools/Sources/ToolsCore/VoiceBake.swift` (new: TTSEngine adapter, KokoroProcessEngine, CAF LPCM encode, provenance, SpeechAPIScan)
- `apple/Tools/tts/kokoro_render.py` (new: build-machine helper; **not yet run**)
- `apple/Tools/Sources/kidtools/main.swift` (`kidtools bake-voice <content-dir> [--python] [--helper]`)
- `apple/Tools/README.md` (voice bake + the venv recipe from game-art-content's TASK-073/108/110 runs, not yet reproduced)
- `apple/Tools/Tests/ToolsTests/VoiceBakeTests.swift` (7 test functions, fake engine)
- **Pending:** the real Dinosaurs render into `content/themes/dinosaurs/voice/en-us/` — after key-table/001's theme.json draft (leader, option A) and the venv

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
- Unlocks: `production/epics/content-pipeline/story-004-loudness-durations-staleness.md`, `production/epics/key-table/story-001-dinosaurs-theme-data.md`
