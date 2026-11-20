# Epic: Input & Key Filter

> **Layer**: Foundation
> **GDD**: design/gdd/input-key-filter.md
> **Architecture Module**: KidCore (classifier on normalized events, held set, routing, hit tests) + app (UIKit presses, AppKit key monitor, touch/click adapters)
> **Milestone**: Demo 1 (`production/milestones/demo-1.md`, K-48)
> **Status**: Ready
> **Stories**: Not yet created — after TASK-131's control manifest lands, run `/create-stories input`

## Overview

Every press, from a hardware key or a touch, becomes one normalized event; only letters and digits count, held keys and repeats are swallowed, system keys are left alone. Both adapters (iPad hardware keyboard, Mac key monitor) feed the same classifier.

## Governing ADRs

| ADR | Status | Decision Summary | Engine Risk |
|-----|--------|------------------|-------------|
| ADR-0002: Modules, seams and Kotlin-mappable types | Accepted | D5 normalized events, D6 seams, D7 call order | LOW |
| ADR-0004: Contracts, fixtures and harness | Accepted | input-filter-v2 | LOW |
| ADR-0006: Stage runtime | Accepted | D7 hit sizes from ppi | HIGH |
| ADR-0007: Input adapters | **Proposed** | Platform key adapters, HID position map, Mac key-state read and TCC | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage | Demo 1 |
|-------|-------------|--------------|--------|
| TR-input-001 | Classify normalized key events: character first, position fallback, modifiers, held set, chord (R2-R6) | ADR-0002 D5; ADR-0004 input-filter-v2 ✅ | in |
| TR-input-002 | Touch layers, batch sort and hint hit radius (R7, F1) | ADR-0002 D6; ADR-0004; ADR-0006 D7 ✅ | in |
| TR-input-003 | Kiosk command-key exception and the Mac chord under kioskModeOn (R5, R6) | ❌ No Accepted ADR (ADR-0007 Proposed); matrix: ADR-0002 D7; ADR-0007 D3 (Proposed) | out: the kiosk command-key exception and the Mac chord under `kioskModeOn` serve Child Lock-in and the Parent Gate (next milestone) |
| TR-input-004 | Platform adapters: UIKit presses and AppKit key monitor produce normalized events; HID position map; Input Monitoring prompt (AC-1k6) | ❌ No Accepted ADR (ADR-0007 Proposed); matrix: ADR-0007 (Proposed) | in |
| TR-input-005 | Only letters and digits count; held keys, repeats and all other keys swallowed, system keys untouched (R4, R5) | ADR-0002 D5; ADR-0004 input-filter-v2; ADR-0007 D2/D3 ✅ | in |

**Requirements covered by Accepted ADRs**: 3 / 5
**Untraced Requirements**: TR-input-003, TR-input-004 (Proposed-only or Partial; see the coverage column)

## Device Rows That Gate Story Closure

(`production/qa/device-checks-plan.md`; a spike run is ADR evidence, never AC evidence.)

- **M-1**: Input AC-1k6: no Input Monitoring prompt on the Mac (release-blocking); ADR-0007
- **M-3, Keys half only (lock off)**: Mac hardware keys: every key normalizes, key-ups under ⌘, system keys left alone (ADR-0007's keyboard part; TR-input-004/005). Pulled into Demo 1 (leader, TASK-132); runs in TASK-134 Mac session 1 on DeviceSpike. The lock-on half stays with Child Lock-in
- **P-15**: Input R1–R4 on a real iPad hardware keyboard; ADR-0007. NOT ASSESSED until Luan has an iPad hardware keyboard
- **P-4, media-keys half only**: iPad media keys swallowed (ADR-0007's keyboard part). In Demo 1 (leader, TASK-132); NOT ASSESSED until an iPad hardware keyboard is available. The Guided Access half stays with Child Lock-in
- **M-2; M-3 lock-on half**: ADR-0007 acceptance with the lock on (chord, ⌘ window): next milestone, not a Demo 1 story

## Contracts

(`contracts/README.md` registry; `story:<x>` is the story stem that starts the runner.)

- input-filter-v2 (`not-started: story:input`)

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every Demo 1 acceptance criterion of design/gdd/input-key-filter.md verified (criteria of out-of-Demo-1 requirements stay open for the next milestone)
- Logic and Integration stories have passing tests in the test root; each contract above runs (`runner:` row) instead of `not-started`
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/` (a lead sign-off too for Visual/Feel)
- Each device row above that gates a story is PASS on the production app, or the story records it NOT ASSESSED with the reason
