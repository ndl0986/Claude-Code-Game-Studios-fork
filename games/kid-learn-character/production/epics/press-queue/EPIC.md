# Epic: Press Queue

> **Layer**: Core
> **GDD**: design/gdd/press-queue.md
> **Architecture Module**: KidCore (the whole state machine; no app part)
> **Milestone**: Demo 1 (`production/milestones/demo-1.md`, K-48)
> **Status**: Ready
> **Stories**: Not yet created — after TASK-131's control manifest lands, run `/create-stories press-queue`

## Overview

Accept, queue (up to 3) or ignore each press; report `formed` exactly once per reveal, so a child mashing keys gets a steady, answered stream.

## Governing ADRs

| ADR | Status | Decision Summary | Engine Risk |
|-----|--------|------------------|-------------|
| ADR-0002: Modules, seams and Kotlin-mappable types | Accepted | seams and the three chains | LOW |
| ADR-0004: Contracts, fixtures and harness | Accepted | press-queue-v1, reveal-timing-v1 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage | Demo 1 |
|-------|-------------|--------------|--------|
| TR-queue-001 | Accept, queue (max 3), ignore; holdEff; timeout (R3-R7, F1) | ADR-0002; ADR-0004 press-queue-v1 ✅ | in |
| TR-queue-002 | formed reported exactly once; Press Queue and Reveal Stage contract (R6, R7, R11) | ADR-0004 press-queue-v1, reveal-timing-v1 ✅ | in |
| TR-queue-003 | Gate freeze, panel and background clear and settle (R8, R9, AC-20..24) | ADR-0004 press-queue-v1; ADR-0002 D7 ✅ | out: gate freeze and panel clear are the Parent Gate's (next milestone); background clear and settle are in Demo 1 |

**Requirements covered by Accepted ADRs**: 3 / 3
**Untraced Requirements**: None

## Device Rows That Gate Story Closure

(`production/qa/device-checks-plan.md`; a spike run is ADR evidence, never AC evidence.)

- None: this epic closes on automated tests and its contract.

## Contracts

(`contracts/README.md` registry; `story:<x>` is the story stem that starts the runner.)

- press-queue-v1 (`not-started: story:press-queue`)

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every Demo 1 acceptance criterion of design/gdd/press-queue.md verified (criteria of out-of-Demo-1 requirements stay open for the next milestone)
- Logic and Integration stories have passing tests in the test root; each contract above runs (`runner:` row) instead of `not-started`
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/` (a lead sign-off too for Visual/Feel)
- Each device row above that gates a story is PASS on the production app, or the story records it NOT ASSESSED with the reason
