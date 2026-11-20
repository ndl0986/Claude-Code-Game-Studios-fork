# Epic: Accessibility

> **Layer**: Presentation
> **GDD**: design/gdd/accessibility.md
> **Architecture Module**: cross-cutting: KidCore (Reduce Motion flag) + app (Smart Invert opt-out) + Tools (ADR-0013 gates)
> **Milestone**: Demo 1 (`production/milestones/demo-1.md`, K-48)
> **Status**: Ready
> **Stories**: 6 stories (TASK-140)

## Overview

Reduce Motion, Smart Invert, the 18 mm child touch floor and flash safety for the demo path. Outside viewers see this build, so ADR-0013's flash gates run on it.

## Governing ADRs

| ADR | Status | Decision Summary | Engine Risk |
|-----|--------|------------------|-------------|
| ADR-0002: Modules, seams and Kotlin-mappable types | Accepted | D6 AccessibilityState | LOW |
| ADR-0006: Stage runtime | Accepted | D5 Smart Invert, D6 Reduce Motion, D7 touch floor | HIGH |
| ADR-0005: Settings persistence | Accepted | D5 nothing stored | MEDIUM |
| ADR-0011: Build, verify and PKC gates | Accepted | D5/D6 no logs | LOW |
| ADR-0013: Flash safety | Accepted | G1–G5 flash safety | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage | Demo 1 |
|-------|-------------|--------------|--------|
| TR-a11y-001 | One Reduce Motion flag read live, never stored, re-read on return (A1, AC-01..04) | ADR-0002 D6 AccessibilityState; ADR-0006 D6; ADR-0005 ✅ | in |
| TR-a11y-002 | Smart Invert opt-out on the stage, panel inverted (A10, K-30) | ADR-0006 D5 ✅ | in (stage opt-out); panel-inverted half out (next milestone) |
| TR-a11y-003 | Flash safety: F2 flash detector gate on the busy scenario (WCAG 2.3.1), F2b red-flash palette check (AC-07..09) | ADR-0013 G2/G3/G4/G5 ✅ (G3 is the detector self-test, AC-07; Accepted K-43, the 2026-11-18 matrix row predates it) | in |
| TR-a11y-004 | Palette and idle lints in the build: F1 idle frequency, A5 contrast for hints and panel (AC-05, AC-10) | ADR-0013 G1 ✅ for F1 idle (AC-05); A5 contrast for hints ⚠️ Partial (no deciding gate yet) | in (F1 idle, A5 for hints); panel half of A5 out (next milestone) |
| TR-a11y-005 | Child touch floor at least 18 mm on each device class (AC-12) | ADR-0006 D7 ✅ | in |
| TR-a11y-006 | No accessibility value stored, sent or logged (AC-16; PKC-05, 14) | ADR-0005 D5; ADR-0011 D5/D6 ✅ | in |

**Requirements covered by Accepted ADRs**: 5 / 6
**Untraced Requirements**: TR-a11y-004 (Proposed-only or Partial; see the coverage column)

## Device Rows That Gate Story Closure

(`production/qa/device-checks-plan.md`; a spike run is ADR evidence, never AC evidence.)

- **P-3 / M-12**: flash gate on the device (AC-08)
- **P-13**: Smart Invert pair (AC-15)
- **P-6**: VoiceOver on the stage during play (A8)

## Contracts

(`contracts/README.md` registry; `story:<x>` is the story stem that starts the runner.)

- none of its own (Reduce Motion timing is in reveal-timing-v1)

## Notes

- TR-android-001 (Android port) is out of Demo 1.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [One Reduce Motion flag: injected, never stored, applied at the right moment, re-read on return](story-001-reduce-motion-flag.md) | Integration | Ready | ADR-0002, ADR-0006, ADR-0005 |
| 002 | [ADR-0013 G1 idle-rate lint and G2 red-flash palette check (buildable now)](story-002-flash-g1-g2.md) | Logic | Ready | ADR-0013, ADR-0011 |
| 003 | [ADR-0013 G3: the F2 detector and its field math (buildable now)](story-003-flash-g3-detector.md) | Logic | Ready | ADR-0013 |
| 004 | [ADR-0013 G4: the busy scenario rendered headless on every merge candidate](story-004-flash-g4-offline.md) | Integration | Blocked | ADR-0013, ADR-0006 |
| 005 | [ADR-0013 G5: the Debug frame dump and the device flash gate](story-005-flash-g5-device.md) | Integration | Blocked | ADR-0013, ADR-0006 |
| 006 | [Smart Invert, the child touch floor, sound off and no colour-only meaning](story-006-invert-touch-sound-colour.md) | UI | Ready | ADR-0006 |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every Demo 1 acceptance criterion of design/gdd/accessibility.md verified (criteria of out-of-Demo-1 requirements stay open for the next milestone)
- Logic and Integration stories have passing tests in the test root; each contract above runs (`runner:` row) instead of `not-started`
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/` (a lead sign-off too for Visual/Feel)
- Each device row above that gates a story is PASS on the production app, or the story records it NOT ASSESSED with the reason
