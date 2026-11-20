# Story 003: Scripted session on the device: zero network bytes and one app-written key

> **Epic**: Privacy & Kids Compliance (`production/epics/privacy/EPIC.md`)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/privacy-kids-compliance.md` — (AC-02, AC-07)
**Requirement**: `TR-pkc-001`, `TR-settings-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Build, verify and PKC gates; ADR-0005: Settings persistence
**ADR Decision Summary**: ADR-0011 D5 `--runtime`: the scripted session on the device with `nettop` and the preferences snapshots; ADR-0005 D5: one app-written key.
**ADR Version**: ADR-0011 2026-11-18; ADR-0005 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Device run, MAC FREE for the Mac half (K-34).

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: MAC FREE for anything taking the screen, keyboard or focus (ADR-0011 D2)
- Required: evidence under `production/qa/evidence/<TASK>/<short-sha>/` (ADR-0011 D6)

**Device rows that close it** (`production/qa/device-checks-plan.md`): M-11; P-5; M-8

---

## Acceptance Criteria

*From GDD `design/gdd/privacy-kids-compliance.md`, scoped to this story:*

- [ ] In the 10-minute scripted session, `nettop` attributes 0 bytes in and out to the app and macOS logs 0 sandbox network denials (AC-02).
- [ ] The preferences domain holds exactly one app-written key, `settings`, with only R1 fields; after Reset no app-written key remains (AC-07; Demo 1 has no panel, so "every setting changed" is the settings the demo path changes).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0011 first):*

Device rows M-11 (Mac) and P-5 (iPad).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- None

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `production/qa/evidence/<TASK>/<sha>/runtime-session.md`

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
