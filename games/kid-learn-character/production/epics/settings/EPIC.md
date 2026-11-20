# Epic: Settings Store

> **Layer**: Foundation
> **GDD**: design/gdd/settings-store.md
> **Architecture Module**: KidCore (record v1, validation, migration, F1/F2, notifications, behind `SettingsBackend`) + app (`UserDefaults` backend, one JSON key)
> **Milestone**: Demo 1 (`production/milestones/demo-1.md`, K-48)
> **Status**: Ready
> **Stories**: 3 stories (TASK-137)

## Overview

The one settings record, read before the first frame and written atomically. Demo 1 reads it and runs on its defaults; the grown-up panel that writes it comes in the next milestone.

## Governing ADRs

| ADR | Status | Decision Summary | Engine Risk |
|-----|--------|------------------|-------------|
| ADR-0005: Settings persistence | Accepted | one record under one key, atomic write, read before the first frame | MEDIUM |
| ADR-0004: Contracts, fixtures and harness | Accepted | settings-record-v2 | LOW |
| ADR-0002: Modules, seams and Kotlin-mappable types | Accepted | D2/D8 same bytes on both platforms | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage | Demo 1 |
|-------|-------------|--------------|--------|
| TR-settings-001 | One record, atomic write, per-field validation, migration (R1-R7) | ADR-0005 D1-D3; ADR-0004 settings-record-v2 ✅ | in |
| TR-settings-002 | Device only, no sync, one app-written key (R3; PKC-01, 05, 09) | ADR-0005 D5/D6/D8 ✅ | in |
| TR-settings-003 | Settings read before the first frame (R5) | ADR-0005 D9; ADR-0004 app-shell-v1 ✅ | in |
| TR-settings-004 | childLock stored only as ON; OFF is run-only (R8, K-21); Reset removes the record (R9) | ADR-0005 D4, D2 remove() ✅ | out: childLock is Child Lock-in's (next milestone); the record field exists and is validated, its UI does not |
| TR-settings-005 | Same bytes on both platforms; F1 rounding, F2 gain | ADR-0004 settings-record-v2; ADR-0002 D2/D8 ✅ | in |

**Requirements covered by Accepted ADRs**: 5 / 5
**Untraced Requirements**: None

## Device Rows That Gate Story Closure

(`production/qa/device-checks-plan.md`; a spike run is ADR evidence, never AC evidence.)

- **M-8**: one app-written key on the Mac (ADR-0005 V2)
- **P-12, M-9**: settings changed through the panel survive a relaunch; childLock round trip: next milestone (the panel is out of Demo 1)

## Contracts

(`contracts/README.md` registry; `story:<x>` is the story stem that starts the runner.)

- settings-record-v2 (`runner:` SettingsRecordRunner)

## Depends on

- **TASK-135** (K-49): the `keyboardRow` default changes with the row's auto-on rule.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [The `UserDefaults` backend: one value under one key, nil writes, no autosave or restoration](story-001-userdefaults-backend.md) | Integration | Ready | ADR-0005, ADR-0002, ADR-0011 |
| 002 | [Store behaviours: theme kept on failure, migration, reset, one notification per change](story-002-store-behaviours.md) | Logic | Ready | ADR-0005, ADR-0004 |
| 003 | [Settings read before the first frame; play waits until the theme is ready](story-003-launch-read-holds-play.md) | Integration | Ready | ADR-0005, ADR-0004 |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every Demo 1 acceptance criterion of design/gdd/settings-store.md verified (criteria of out-of-Demo-1 requirements stay open for the next milestone)
- Logic and Integration stories have passing tests in the test root; each contract above runs (`runner:` row) instead of `not-started`
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/` (a lead sign-off too for Visual/Feel)
- Each device row above that gates a story is PASS on the production app, or the story records it NOT ASSESSED with the reason
