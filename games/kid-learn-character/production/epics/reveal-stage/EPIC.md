# Epic: Reveal Stage

> **Layer**: Feature
> **GDD**: design/gdd/reveal-stage.md
> **Architecture Module**: KidCore (router, startReveal, timeline, play clock, stage fit, cooldown, boxes) + app (SpriteKit scene graph, draw order, frame driver)
> **Milestone**: Demo 1 (`production/milestones/demo-1.md`, K-48)
> **Status**: Ready
> **Stories**: Not yet created — after TASK-131's control manifest lands, run `/create-stories reveal-stage`

## Overview

The morph reveal: a press becomes a letter that morphs into its creature on the stage, with the shared timeline, play clock, stage fit and the tap-the-creature hop.

## Governing ADRs

| ADR | Status | Decision Summary | Engine Risk |
|-----|--------|------------------|-------------|
| ADR-0004: Contracts, fixtures and harness | Accepted | reveal-timing-v1 | LOW |
| ADR-0002: Modules, seams and Kotlin-mappable types | Accepted | D3/D7 clocks and call order | LOW |
| ADR-0006: Stage runtime | Accepted | D1 layers, D2 fit, D3 frame driver, D6 Reduce Motion | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage | Demo 1 |
|-------|-------------|--------------|--------|
| TR-reveal-001 | startReveal lengths, formed and shown, timeline, shared transforms (R3-R5) | ADR-0004 reveal-timing-v1 ✅ | in |
| TR-reveal-002 | Play clock, freeze, resume, settle (R8) | ADR-0002 D3/D7 ✅ | in |
| TR-reveal-003 | Stage fit contain-and-extend; published rects and boxes (R10, F1) | ADR-0006 D1/D2; ADR-0004 reveal-timing-v1 ✅ | in |
| TR-reveal-004 | Fixed draw-order layers; SpriteKit scene behind RenderSink; display-link frame driver | ADR-0006 D1/D3 ✅ | in |
| TR-reveal-005 | Reduce Motion timing set picked at start (R9) | ADR-0006 D6; ADR-0004 ✅ | in |
| TR-reveal-006 | Tap-the-creature hop and cooldown (F6) | ADR-0004 reveal-timing-v1 ✅ | in |

**Requirements covered by Accepted ADRs**: 6 / 6
**Untraced Requirements**: None

## Device Rows That Gate Story Closure

(`production/qa/device-checks-plan.md`; a spike run is ADR evidence, never AC evidence.)

- **P-1**: Reveal Stage AC-16 timing on the device
- **P-13**: Smart Invert: stage pixels unchanged (stage half; Reveal R1, K-30)
- **P-11, M-10**: multitasking and Mac window/ppi under the stage fit (ADR-0006)

## Contracts

(`contracts/README.md` registry; `story:<x>` is the story stem that starts the runner.)

- reveal-timing-v1 (`not-started: story:reveal-stage`)

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every Demo 1 acceptance criterion of design/gdd/reveal-stage.md verified (criteria of out-of-Demo-1 requirements stay open for the next milestone)
- Logic and Integration stories have passing tests in the test root; each contract above runs (`runner:` row) instead of `not-started`
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/` (a lead sign-off too for Visual/Feel)
- Each device row above that gates a story is PASS on the production app, or the story records it NOT ASSESSED with the reason
