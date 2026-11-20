# Epic: App Shell & Title

> **Layer**: Presentation
> **GDD**: design/gdd/app-shell-title.md
> **Architecture Module**: KidCore (launch order, Title/Play/Background, pending start, away clock, memory escalation) + app (scene/window lifecycle, launch screen, Title drawing)
> **Milestone**: Demo 1 (`production/milestones/demo-1.md`, K-48)
> **Status**: Ready
> **Stories**: Not yet created — after TASK-131's control manifest lands, run `/create-stories app-shell`

## Overview

Launch, the Title with its play button, Title → Play, background and the away rule, memory shedding, and on both platforms a window that keeps the stage safe. Demo 1 adds a simple grown-up exit in place of the Parent Gate.

## Governing ADRs

| ADR | Status | Decision Summary | Engine Risk |
|-----|--------|------------------|-------------|
| ADR-0004: Contracts, fixtures and harness | Accepted | app-shell-v1 | LOW |
| ADR-0005: Settings persistence | Accepted | D9 settings before the first frame | MEDIUM |
| ADR-0002: Modules, seams and Kotlin-mappable types | Accepted | D3 AwayClock, D6 AppLifecycle | LOW |
| ADR-0006: Stage runtime | Accepted | D4 windows | HIGH |
| ADR-0011: Build, verify and PKC gates | Accepted | D5 no collection APIs | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage | Demo 1 |
|-------|-------------|--------------|--------|
| TR-shell-001 | Launch order, Title starts, pending start, ready set (R1-R6, F1) | ADR-0004 app-shell-v1; ADR-0005 D9 ✅ | in |
| TR-shell-002 | Away rule counts device sleep: 30 min on the away clock (R6, F3) | ADR-0002 D3 AwayClock ✅ | in |
| TR-shell-003 | Windows on iPad and Mac, safe stage, overlays in the main window (R7) | ADR-0006 D4 ✅ | in |
| TR-shell-004 | iPad status bar and home indicator hidden, edge-swipe deferral follows the gate (R7, K-39, AC-14) | ⚠️ Partial: ADR-0006 D4 (windows only) | in |
| TR-shell-005 | Memory-warning shedding order (F4, AC-11) | ADR-0002 D6 AppLifecycle; ADR-0004 app-shell-v1 ✅ | in |
| TR-shell-006 | No collection APIs; cold launch restores nothing (AC-9, AC-12) | ADR-0011 D5; ADR-0005 ✅ | in |

**Requirements covered by Accepted ADRs**: 5 / 6
**Untraced Requirements**: TR-shell-004 (Proposed-only or Partial; see the coverage column)

## Device Rows That Gate Story Closure

(`production/qa/device-checks-plan.md`; a spike run is ADR evidence, never AC evidence.)

- **P-0**: first launch on a real iPad, observed
- **P-10, M-15**: launch times (AC-13)
- **M-10, P-11**: Mac window and ppi; iPad multitasking (ADR-0006)
- **P-16**: iPad overlays during play (AC-14, K-39)

## Contracts

(`contracts/README.md` registry; `story:<x>` is the story stem that starts the runner.)

- app-shell-v1 (`not-started: story:app-shell`)

## Notes

- TR-shell-004 is Partial (status bar, home indicator, edge deferral: no ADR names them).
- Open (milestone Q2): what the "simple grown-up exit" is; no GDD defines it.

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every Demo 1 acceptance criterion of design/gdd/app-shell-title.md verified (criteria of out-of-Demo-1 requirements stay open for the next milestone)
- Logic and Integration stories have passing tests in the test root; each contract above runs (`runner:` row) instead of `not-started`
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/` (a lead sign-off too for Visual/Feel)
- Each device row above that gates a story is PASS on the production app, or the story records it NOT ASSESSED with the reason
