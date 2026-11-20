# Epic: Scene: Time of Day & Weather

> **Layer**: Feature
> **GDD**: design/gdd/scene-time-weather.md
> **Architecture Module**: KidCore (F1–F5 looks, weather, build-check data) + app (sky, hills, ground, weather drawing)
> **Milestone**: Demo 1 (`production/milestones/demo-1.md`, K-48)
> **Status**: Ready
> **Stories**: Not yet created — after TASK-131's control manifest lands, run `/create-stories scene`

## Overview

The stage's sky follows the wall clock (dawn to night) with light weather, under caps the device run measures.

## Governing ADRs

| ADR | Status | Decision Summary | Engine Risk |
|-----|--------|------------------|-------------|
| ADR-0002: Modules, seams and Kotlin-mappable types | Accepted | D3 WallClock, D7 | LOW |
| ADR-0004: Contracts, fixtures and harness | Accepted | scene-look-v1 | LOW |
| ADR-0006: Stage runtime | Accepted | D1 layer 0 | HIGH |
| ADR-0001: Native Apple stack | Accepted | D8 | HIGH |
| ADR-0011: Build, verify and PKC gates | Accepted | no network | LOW |
| ADR-0009: Render path | **Proposed** | weather cost in the device run | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage | Demo 1 |
|-------|-------------|--------------|--------|
| TR-scene-001 | Wall-clock looks, lookBlend, jump fade, weather pick (R2-R9, F1, F3) | ADR-0002 D3 WallClock; ADR-0004 scene-look-v1 ✅ | in |
| TR-scene-002 | Weather element draw within caps and device cost F6 worst case (R3, AC-4, AC-19) | ⚠️ Partial: ADR-0006 D1 layer 0; ADR-0004 scene-look-v1; ADR-0009 (Proposed) | in |
| TR-scene-003 | Contrast build check: 160 cases with the F8 edge model (R5, AC-5) | ADR-0004 scene-look-v1 ✅ | in |
| TR-scene-004 | Two clocks; freeze stops elements, look follows wall clock (AC-11) | ADR-0002 D3/D7 ✅ | in |
| TR-scene-005 | No network, location or audio from the Scene (AC-18; K-08) | ADR-0001 D8; ADR-0011 ✅ | in |

**Requirements covered by Accepted ADRs**: 4 / 5
**Untraced Requirements**: TR-scene-002 (Proposed-only or Partial; see the coverage column)

## Device Rows That Gate Story Closure

(`production/qa/device-checks-plan.md`; a spike run is ADR evidence, never AC evidence.)

- **P-2 decisive / M-13**: with Scene F6's worst-case weather (TR-scene-002)

## Contracts

(`contracts/README.md` registry; `story:<x>` is the story stem that starts the runner.)

- scene-look-v1 (`not-started: story:scene`)

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every Demo 1 acceptance criterion of design/gdd/scene-time-weather.md verified (criteria of out-of-Demo-1 requirements stay open for the next milestone)
- Logic and Integration stories have passing tests in the test root; each contract above runs (`runner:` row) instead of `not-started`
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/` (a lead sign-off too for Visual/Feel)
- Each device row above that gates a story is PASS on the production app, or the story records it NOT ASSESSED with the reason
