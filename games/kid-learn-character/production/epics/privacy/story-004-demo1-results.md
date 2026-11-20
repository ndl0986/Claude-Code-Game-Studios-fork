# Story 004: Demo 1 PKC results.md for the signed Release builds

> **Epic**: Privacy & Kids Compliance (`production/epics/privacy/EPIC.md`)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/privacy-kids-compliance.md` — (AC-14)
**Requirement**: `TR-pkc-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Build, verify and PKC gates
**ADR Decision Summary**: ADR-0011 D5/D6: QC writes every PKC verdict from the OBSERVED lines, per candidate, in results.md.
**ADR Version**: ADR-0011 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: QC-written; no script verdicts.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: QC writes every PKC verdict; evidence under `production/qa/evidence/<TASK>/<short-sha>/` (ADR-0011 D5, D6)
- Forbidden: never a script that prints PASS/FAIL for PKC rows (ADR-0011 Alt 2)

---

## Acceptance Criteria

*From GDD `design/gdd/privacy-kids-compliance.md`, scoped to this story:*

- [ ] The Demo 1 `results.md` lists every PKC row for the signed iPadOS and macOS Release builds with a verdict from privacy/001–003 (AC-14, Demo 1 form).
- [ ] The gate and panel rows (AC-08, and AC-12's change gate) read **"out of Demo 1 scope (next milestone)"**, not NOT ASSESSED; AC-10 (store forms) reads out of scope too, since Demo 1 is not distributed.
- [ ] The release rule "a gate with any NOT ASSESSED row is not a release" is not applied: **Demo 1 is not a release** (leader, TASK-137) — a demo build we install on the child's iPad and the Mac. It applies at the release milestone.

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0011 first):*

Leader's call (TASK-137): Demo 1 is installed by us, not distributed through a store.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- None

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `production/qa/evidence/<TASK>/<sha>/results.md`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY-READY skipped — Lean mode).

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: Integration: an integration test (path under Files) OR a documented run in `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/privacy/story-001-release-static-checks.md`, `production/epics/privacy/story-002-release-code-scans.md`, `production/epics/privacy/story-003-runtime-network-and-storage.md`
- Unlocks: None
