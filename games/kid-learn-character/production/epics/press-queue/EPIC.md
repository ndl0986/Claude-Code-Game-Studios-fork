# Epic: Press Queue

> **Layer**: Core
> **GDD**: design/gdd/press-queue.md
> **Architecture Module**: KidCore (the whole state machine; no app part)
> **Milestone**: Demo 1 (`production/milestones/demo-1.md`, K-48)
> **Status**: Ready
> **Stories**: 6 stories (TASK-140)

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

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Start at once, queue during the hold, the formed guard, ignore when full](story-001-start-queue-ignore.md) | Logic | Complete | ADR-0002, ADR-0004 |
| 002 | [Start from rest, no jumping, the mash batch and one advance per tick](story-002-rest-jumping-mash.md) | Logic | Complete | ADR-0002, ADR-0004 |
| 003 | [F1 holdEff, the formed rules and the fallback lengths](story-003-hold-and-formed-rules.md) | Logic | Complete | ADR-0002, ADR-0004 |
| 004 | [Synchronous outcomes, gap-free revealIds, locked lengths, equal sources, the resting signal](story-004-ids-sources-resting.md) | Logic | Complete | ADR-0002, ADR-0004 |
| 005 | [Background, panel and gate logic, the first press after the Title, the theme switch, and the data checks](story-005-background-title-data.md) | Logic | Ready | ADR-0002, ADR-0004 |
| 006 | [A touched hint on a full queue sparkles, pings and stays](story-006-hint-on-overflow.md) | Integration | Ready | ADR-0002, ADR-0004 |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every Demo 1 acceptance criterion of design/gdd/press-queue.md verified (criteria of out-of-Demo-1 requirements stay open for the next milestone)
- Logic and Integration stories have passing tests in the test root; each contract above runs (`runner:` row) instead of `not-started`
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/` (a lead sign-off too for Visual/Feel)
- Each device row above that gates a story is PASS on the production app, or the story records it NOT ASSESSED with the reason
