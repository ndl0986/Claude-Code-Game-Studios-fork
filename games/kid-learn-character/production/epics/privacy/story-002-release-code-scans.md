# Story 002: Demo 1 Release builds pass the API, third-party and log scans

> **Epic**: Privacy & Kids Compliance (`production/epics/privacy/EPIC.md`)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/privacy-kids-compliance.md` — (AC-03, AC-05, AC-11, AC-13)
**Requirement**: `TR-pkc-001`, `TR-pkc-003`, `TR-pkc-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Build, verify and PKC gates; ADR-0001: Native Apple stack
**ADR Decision Summary**: ADR-0011 D5/D6: `nm`/`otool`/`strings` scans on the signed Release product, first proven on the fixture binary; no third-party code (ADR-0001 D8); no input in release logs (PKC-14).
**ADR Version**: ADR-0011 2026-11-18; ADR-0001 2026-11-17

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: System command-line tools only.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: no third-party runtime or SDK without its own ADR (ADR-0001 D8)
- Required: `DebugLog` uses `Logger` at `.debug`; release builds log no child input (ADR-0002 D6, PKC-14)

---

## Acceptance Criteria

*From GDD `design/gdd/privacy-kids-compliance.md`, scoped to this story:*

- [ ] Both scan passes and `otool -L` on every Mach-O show none of the named APIs and frameworks; any hit is read by a person (AC-03).
- [ ] No remote package, Pods, Carthage or binary framework; only system and our own frameworks (AC-05).
- [ ] Every file the validator lists is in the bundle; no On-Demand Resources, Background Assets, Handoff, Spotlight or Siri donation (AC-11); no log call carrying a key, word, touch point, event time or accessibility setting outside `#if DEBUG` (AC-13).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0011 first):*

Run on the same candidate as story 001.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- None

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `production/qa/evidence/<TASK>/<sha>/pkc-scan-signed.txt`

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

- Depends on: `production/epics/privacy/story-001-release-static-checks.md`
- Unlocks: `production/epics/privacy/story-004-demo1-results.md`
