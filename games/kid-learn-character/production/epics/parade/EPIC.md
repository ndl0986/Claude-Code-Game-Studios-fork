# Epic: Parade

> **Layer**: Feature
> **GDD**: design/gdd/parade.md
> **Architecture Module**: KidCore (batches, arming F2, walk F3, meter, art wait, freeze) + app (walkers through Cast Rendering)
> **Milestone**: Demo 1 (`production/milestones/demo-1.md`, K-48)
> **Status**: Ready
> **Stories**: 7 stories (TASK-140)

## Overview

The parade meter beside the queue tokens fills once per new creature; the 6th starts the parade 1.5 s after it forms, while presses keep being answered in front of it.

## Governing ADRs

| ADR | Status | Decision Summary | Engine Risk |
|-----|--------|------------------|-------------|
| ADR-0004: Contracts, fixtures and harness | Accepted | parade-v2 (K-44 meter, K-45 start, K-46 light) | LOW |
| ADR-0009: Render path | **Proposed** | walkers within the resident set | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage | Demo 1 |
|-------|-------------|--------------|--------|
| TR-parade-001 | Batches per theme, start rule, walk across the visible rect, own clock (R1-R8, F2, F3) | ADR-0004 parade-v1 ✅ | in |
| TR-parade-002 | Walkers drawn at parade detail size within the resident set; art wait (AC-12, AC-18) | ❌ No Accepted ADR (ADR-0009 Proposed); matrix: ADR-0009 D1/D5 (Proposed) | in |

**Requirements covered by Accepted ADRs**: 1 / 2
**Untraced Requirements**: TR-parade-002 (Proposed-only or Partial; see the coverage column)

## Device Rows That Gate Story Closure

(`production/qa/device-checks-plan.md`; a spike run is ADR evidence, never AC evidence.)

- **P-2 decisive / M-13**: walkers at parade detail size within the resident set (AC-12, AC-18)

## Contracts

(`contracts/README.md` registry; `story:<x>` is the story stem that starts the runner.)

- parade-v2 (`not-started: story:parade`)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [The batch of 6 distinct keys and the K-45 start rule](story-001-batch-and-start.md) | Logic | Ready | ADR-0004, ADR-0002 |
| 002 | [Walk order and positions on its own clock; no rest needed](story-002-walk-positions-clock.md) | Logic | Ready | ADR-0004, ADR-0002 |
| 003 | [The next batch, art not ready, the tune once per walk, no cap](story-003-next-batch-art-tune.md) | Logic | Ready | ADR-0004, ADR-0009 |
| 004 | [Background, Reduce Motion, walker taps and the debug start](story-004-states-taps-debug.md) | Logic | Ready | ADR-0004, ADR-0002 |
| 005 | [The parade meter: fill, full, handover, launch, Reduce Motion, flash data](story-005-meter-fill-full.md) | Logic | Ready | ADR-0004, ADR-0013 |
| 006 | [The light from each new creature to its cell](story-006-meter-light.md) | Logic | Ready | ADR-0004, ADR-0002 |
| 007 | [The parade and the meter on the iPad: walkers on the hill band, meter states](story-007-parade-and-meter-look.md) | Visual/Feel | Blocked | ADR-0009, ADR-0006 |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every Demo 1 acceptance criterion of design/gdd/parade.md verified (criteria of out-of-Demo-1 requirements stay open for the next milestone)
- Logic and Integration stories have passing tests in the test root; each contract above runs (`runner:` row) instead of `not-started`
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/` (a lead sign-off too for Visual/Feel)
- Each device row above that gates a story is PASS on the production app, or the story records it NOT ASSESSED with the reason
