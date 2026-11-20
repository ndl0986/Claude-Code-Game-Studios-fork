# Epic: Hint Letters

> **Layer**: Feature
> **GDD**: design/gdd/hint-letters.md
> **Architecture Module**: KidCore (spawn, slots, jitter, clearances, life, drift, originFor) + app (bubble drawing)
> **Milestone**: Demo 1 (`production/milestones/demo-1.md`, K-48)
> **Status**: Ready
> **Stories**: Not yet created — after TASK-131's control manifest lands, run `/create-stories hint-letters`

## Overview

Floating letter bubbles that invite a press or a tap, kept clear of the creature, the meter and the moon.

## Governing ADRs

| ADR | Status | Decision Summary | Engine Risk |
|-----|--------|------------------|-------------|
| ADR-0002: Modules, seams and Kotlin-mappable types | Accepted | D4/D6 random stream, DisplayMetrics | LOW |
| ADR-0004: Contracts, fixtures and harness | Accepted | hint-letters-v1 | LOW |
| ADR-0006: Stage runtime | Accepted | D7 18 mm hit size | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage | Demo 1 |
|-------|-------------|--------------|--------|
| TR-hints-001 | Spawn, clearances, life, originFor, freeze and Dimmed (R2-R9, F1-F4) | ADR-0002 D4/D6; ADR-0004 hint-letters-v1 ✅ | in |
| TR-hints-002 | Hit diameter at least 18 mm from ppi, with bubble scale k (R11, F5) | ADR-0006 D7; ADR-0002 D6 DisplayMetrics ✅ | in |
| TR-hints-003 | Hint knobs data-validated at build, slots pass F4 (AC-21) | ⚠️ Partial: ADR-0003 D1 (data/ knob files) | in |

**Requirements covered by Accepted ADRs**: 2 / 3
**Untraced Requirements**: TR-hints-003 (Proposed-only or Partial; see the coverage column)

## Device Rows That Gate Story Closure

(`production/qa/device-checks-plan.md`; a spike run is ADR evidence, never AC evidence.)

- **M-10 (ppi readout)**: hit diameter ≥ 18 mm from the device ppi (TR-hints-002)

## Contracts

(`contracts/README.md` registry; `story:<x>` is the story stem that starts the runner.)

- hint-letters-v1 (`not-started: story:hint-letters`)

## Notes

- TR-hints-003 is Partial: no validator rule decides the hint knobs and slots yet (Known Gaps).

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every Demo 1 acceptance criterion of design/gdd/hint-letters.md verified (criteria of out-of-Demo-1 requirements stay open for the next milestone)
- Logic and Integration stories have passing tests in the test root; each contract above runs (`runner:` row) instead of `not-started`
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/` (a lead sign-off too for Visual/Feel)
- Each device row above that gates a story is PASS on the production app, or the story records it NOT ASSESSED with the reason
