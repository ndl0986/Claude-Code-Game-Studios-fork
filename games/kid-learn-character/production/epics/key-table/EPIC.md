# Epic: Key Table & Theme Data

> **Layer**: Foundation
> **GDD**: design/gdd/key-table-theme-data.md
> **Architecture Module**: KidCore (theme model, V-rules, pick rule, peek) + app (bundle load, off-main-thread decode); the validator also runs in Tools
> **Milestone**: Demo 1 (`production/milestones/demo-1.md`, K-48)
> **Status**: Ready
> **Stories**: Not yet created — after TASK-131's control manifest lands, run `/create-stories key-table`

## Overview

The Dinosaurs theme as data: 36 keys (A–Z, 0–9) with their items, art, voice and sound references, validated at build and at load, and the no-immediate-repeat pick with a peek for prefetch.

## Governing ADRs

| ADR | Status | Decision Summary | Engine Risk |
|-----|--------|------------------|-------------|
| ADR-0003: Content pipeline | Accepted | D1 layout (shipped vs src/), D2 schema, D3 validator at build and load | HIGH |
| ADR-0004: Contracts, fixtures and harness | Accepted | key-table-schema-v1 | LOW |
| ADR-0002: Modules, seams and Kotlin-mappable types | Accepted | D4 RandomSource for the pick | LOW |
| ADR-0001: Native Apple stack | Accepted | D6 data-driven per-key database | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage | Demo 1 |
|-------|-------------|--------------|--------|
| TR-keytable-001 | Bundled themes validated at build and at load; unknown versions refused (V1-V17, sections 5-6) | ADR-0003 D2/D3; ADR-0004 key-table-schema-v1 ✅ | in |
| TR-keytable-002 | Item pick with no immediate repeat; peek for prefetch (section 4) | ADR-0002 D4; ADR-0004 ✅ | in |
| TR-keytable-003 | Data-driven per-key database (K-07), versioned JSON schema, one validator | ADR-0001 D6; ADR-0003 D1/D2 ✅ | in |
| TR-keytable-004 | Voice and sfx pipeline: pre-rendered TTS, AAC mono, loudness target, voiceDurations from data (V12, V15) | ADR-0003 D5/D6 ✅ | in |
| TR-keytable-005 | rowWords valid with v1 fallback (V17) | ADR-0003 D2; ADR-0004 key-table-schema-v1 ✅ | in |

**Requirements covered by Accepted ADRs**: 5 / 5
**Untraced Requirements**: None

## Device Rows That Gate Story Closure

(`production/qa/device-checks-plan.md`; a spike run is ADR evidence, never AC evidence.)

- None: this epic closes on automated tests and its contract.

## Contracts

(`contracts/README.md` registry; `story:<x>` is the story stem that starts the runner.)

- key-table-schema-v1 (`runner:` KeyTableModelRunner + Tools.KeyTableFileLayer)

## Notes

- Demo 1 needs the full Dinosaurs `theme.json`; today `content/themes/dinosaurs/` holds only `src/` (TASK-125, in progress).

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every Demo 1 acceptance criterion of design/gdd/key-table-theme-data.md verified (criteria of out-of-Demo-1 requirements stay open for the next milestone)
- Logic and Integration stories have passing tests in the test root; each contract above runs (`runner:` row) instead of `not-started`
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/` (a lead sign-off too for Visual/Feel)
- Each device row above that gates a story is PASS on the production app, or the story records it NOT ASSESSED with the reason
