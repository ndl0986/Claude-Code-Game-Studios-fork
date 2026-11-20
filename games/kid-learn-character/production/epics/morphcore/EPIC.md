# Epic: MorphCore

> **Layer**: Foundation
> **GDD**: design/gdd/morphcore.md
> **Architecture Module**: apple/MorphCore (pure; no app part)
> **Milestone**: Demo 1 (`production/milestones/demo-1.md`, K-48)
> **Status**: Ready
> **Stories**: Not yet created — after TASK-131's control manifest lands, run `/create-stories morphcore`

## Overview

The morph math every reveal uses: the morph-contract-v1 parser, sampler, `position(i, s)`, T and phase, and the timing-spec loader. The package and its first tests exist from the TASK-079 scaffold; this epic finishes it against the contract and the 240-speck frame budget.

## Governing ADRs

| ADR | Status | Decision Summary | Engine Risk |
|-----|--------|------------------|-------------|
| ADR-0002: Modules, seams and Kotlin-mappable types | Accepted | MorphCore depends on nothing; Kotlin-mappable types; SplitMix64 per stream | LOW |
| ADR-0004: Contracts, fixtures and harness | Accepted | morph-contract-v1 fixture run on every platform | LOW |
| ADR-0003: Content pipeline | Accepted | glyphs baked from the OFL font into the v1 SVG subset (D4) | HIGH |
| ADR-0009: Render path | **Proposed** | TR-morph-003 frame time p99 is judged by the render-path run | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage | Demo 1 |
|-------|-------------|--------------|--------|
| TR-morph-001 | Morph positions within 1e-3 of the shared fixture on every platform | ADR-0002 D1/D2/D4; ADR-0004; morph-contract-v1 ✅ | in |
| TR-morph-002 | UI-free math; glyph and silhouette paths in the v1 SVG subset, glyphs baked from the OFL font | ADR-0001 D6; ADR-0003 D4 ✅ | in |
| TR-morph-003 | Frame time p99 within one refresh with 240 specks (AC-11) | ❌ No Accepted ADR (ADR-0009 Proposed); matrix: ADR-0009 D1 (Proposed) | in |

**Requirements covered by Accepted ADRs**: 2 / 3
**Untraced Requirements**: TR-morph-003 (Proposed-only or Partial; see the coverage column)

## Device Rows That Gate Story Closure

(`production/qa/device-checks-plan.md`; a spike run is ADR evidence, never AC evidence.)

- **P-2 decisive (oldest supported iPad, K-47: decided at release prep) / M-13**: MorphCore AC-11, TR-morph-003

## Contracts

(`contracts/README.md` registry; `story:<x>` is the story stem that starts the runner.)

- morph-contract-v1 (Accepted; `docs/architecture/morph-contract-v1.md`, `content/fixtures/morph-contract-v1.json`)

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every Demo 1 acceptance criterion of design/gdd/morphcore.md verified (criteria of out-of-Demo-1 requirements stay open for the next milestone)
- Logic and Integration stories have passing tests in the test root; each contract above runs (`runner:` row) instead of `not-started`
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/` (a lead sign-off too for Visual/Feel)
- Each device row above that gates a story is PASS on the production app, or the story records it NOT ASSESSED with the reason
