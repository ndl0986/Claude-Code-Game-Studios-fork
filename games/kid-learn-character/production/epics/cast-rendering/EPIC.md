# Epic: Cast Rendering

> **Layer**: Core
> **GDD**: design/gdd/cast-rendering.md
> **Architecture Module**: KidCore (F1–F8 math, residency policy, late-art wait) + app (draw adapters for the ADR-0009 path; texture residency)
> **Milestone**: Demo 1 (`production/milestones/demo-1.md`, K-48)
> **Status**: Ready
> **Stories**: Not yet created — after TASK-131's control manifest lands, run `/create-stories cast-rendering`

## Overview

The 36 creatures drawn from their baked layered SVG (art bible §8, TASK-133): role and tier, halo, specks, idle and hop, residency with a late-art wait that never moves the queue, through one draw interface for either render option.

## Governing ADRs

| ADR | Status | Decision Summary | Engine Risk |
|-----|--------|------------------|-------------|
| ADR-0003: Content pipeline | Accepted | D1/D4 SVG-subset bake, one baked file | HIGH |
| ADR-0002: Modules, seams and Kotlin-mappable types | Accepted | D6 RenderSink, ResidencySink | LOW |
| ADR-0004: Contracts, fixtures and harness | Accepted | reveal-timing-v1, scene-look-v1 | LOW |
| ADR-0013: Flash safety | Accepted | G1 idles ≤ 1 Hz | LOW |
| ADR-0009: Render path | **Proposed** | render path (A-candidate preferred; B-load fallback) | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage | Demo 1 |
|-------|-------------|--------------|--------|
| TR-cast-001 | SVG subset bake tool; one baked file and one draw interface for both render options (R2, R7, R11) | ADR-0003 D1/D4 ✅ | in |
| TR-cast-002 | Load on demand, resident cap, late-art wait that never moves the queue (R10, F6, F7, AC-15) | ❌ No Accepted ADR (ADR-0009 Proposed); matrix: ADR-0002 D6 ResidencySink; ADR-0009 D5 (Proposed) | in |
| TR-cast-003 | Per-look edge switch on skyMidL, halo, dim (F8, K-25) | ADR-0004 scene-look-v1; ADR-0009 D2 ✅ | in |
| TR-cast-004 | Render-path decision (live paths, textures or a mix) backed by a device measurement (R11, AC-17) | ❌ No Accepted ADR (ADR-0009 Proposed); matrix: ADR-0009 (Proposed) | in |
| TR-cast-005 | Draw interface carries no platform types (R12, AC-16) | ADR-0002 D6 RenderSink; ADR-0009 D2 ✅ | in |
| TR-cast-006 | Speck cap F4, 6 px rule F1, tap hop F5 as pure functions (F1, F4, F5, F7) | ADR-0004 reveal-timing-v1 ✅ | in |
| TR-cast-007 | Shipped idles at or under 1 Hz (AC-11): a build check on the data | ADR-0013 G1 ✅ (Accepted K-43; the 2026-11-18 matrix row predates it) | in |

**Requirements covered by Accepted ADRs**: 5 / 7
**Untraced Requirements**: TR-cast-002, TR-cast-004 (Proposed-only or Partial; see the coverage column)

## Device Rows That Gate Story Closure

(`production/qa/device-checks-plan.md`; a spike run is ADR evidence, never AC evidence.)

- **P-2 decisive / M-13**: Cast Rendering AC-17, R11 (ADR-0009 D1; the decisive iPad is decided at release prep, K-47)
- **P-3 / M-12**: flash gate on the production render (Accessibility AC-08)

## Contracts

(`contracts/README.md` registry; `story:<x>` is the story stem that starts the runner.)

- reveal-timing-v1 F1/F2/F4/F5/F7 (`not-started: story:reveal-stage`)
- scene-look-v1 F8 (`not-started: story:scene`)

## Notes

- ADR-0009 is Proposed: stories that depend on the render path are Blocked until it is Accepted, or proceed on the A-candidate with Luan's OK.

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every Demo 1 acceptance criterion of design/gdd/cast-rendering.md verified (criteria of out-of-Demo-1 requirements stay open for the next milestone)
- Logic and Integration stories have passing tests in the test root; each contract above runs (`runner:` row) instead of `not-started`
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/` (a lead sign-off too for Visual/Feel)
- Each device row above that gates a story is PASS on the production app, or the story records it NOT ASSESSED with the reason
