# Epic: On-screen Keyboard Row

> **Layer**: Feature
> **GDD**: design/gdd/onscreen-keyboard-row.md
> **Architecture Module**: KidCore (layout, hit rect, light, words, Due) + app (the z 35 layer)
> **Milestone**: Demo 1 (`production/milestones/demo-1.md`, K-48)
> **Status**: Ready
> **Stories**: Not yet created — after TASK-131's control manifest lands, run `/create-stories keyboard-row`

## Overview

A row of letter keys on the stage for a child without a hardware keyboard, feeding the same press path as a touch.

## Governing ADRs

| ADR | Status | Decision Summary | Engine Risk |
|-----|--------|------------------|-------------|
| ADR-0004: Contracts, fixtures and harness | Accepted | keyboard-row-v1 | LOW |
| ADR-0003: Content pipeline | Accepted | D2 rowWords | HIGH |
| ADR-0001: Native Apple stack | Accepted | 9a | HIGH |
| ADR-0006: Stage runtime | Accepted | D1 z 35, D7 18 mm | HIGH |
| ADR-0005: Settings persistence | Accepted | the keyboardRow field | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage | Demo 1 |
|-------|-------------|--------------|--------|
| TR-kbrow-001 | Layout, hit rect, light, word draw, Due and change (F1-F4) | ADR-0004 keyboard-row-v1 ✅ | in |
| TR-kbrow-002 | Row words from theme data with v1 fallback (AC-16) | ADR-0003 D2 ✅ | in |
| TR-kbrow-003 | Row is a layer at z 35 and feeds the same press path as a touch (R12) | ADR-0001 9a; ADR-0006 D1 ✅ | in |
| TR-kbrow-004 | Off by default, kept in settings; hit rect at least 18 mm (AC-1, AC-3) | ADR-0005; ADR-0004 settings-record-v2; ADR-0006 D7 ✅ | in |

**Requirements covered by Accepted ADRs**: 4 / 4
**Untraced Requirements**: None

## Device Rows That Gate Story Closure

(`production/qa/device-checks-plan.md`; a spike run is ADR evidence, never AC evidence.)

- None: this epic closes on automated tests and its contract.

## Contracts

(`contracts/README.md` registry; `story:<x>` is the story stem that starts the runner.)

- keyboard-row-v1 (`not-started: story:keyboard-row`)

## Notes

- Demo 1 behaviour (K-49, Luan): the row turns on by itself when no hardware keyboard is attached and hides when one is. That is a design change in TASK-135 (game-art-content: Keyboard Row R8 and its ACs, the Settings Store `keyboardRow` default, Input's keyboard-presence signal); this epic's stories depend on TASK-135 merging, and TR-kbrow-004 ("off by default") is re-read against it.

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every Demo 1 acceptance criterion of design/gdd/onscreen-keyboard-row.md verified (criteria of out-of-Demo-1 requirements stay open for the next milestone)
- Logic and Integration stories have passing tests in the test root; each contract above runs (`runner:` row) instead of `not-started`
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/` (a lead sign-off too for Visual/Feel)
- Each device row above that gates a story is PASS on the production app, or the story records it NOT ASSESSED with the reason
