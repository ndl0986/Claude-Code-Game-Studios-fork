# Story 001: Demo 1 signed Release builds pass the static PKC checks: entitlements, Info.plist, privacy manifest

> **Epic**: Privacy & Kids Compliance (`production/epics/privacy/EPIC.md`)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Config/Data
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/privacy-kids-compliance.md` — (AC-01, AC-06, AC-09)
**Requirement**: `TR-pkc-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Build, verify and PKC gates; ADR-0005: Settings persistence; ADR-0001: Native Apple stack
**ADR Decision Summary**: ADR-0011 D3/D5: scans run on signed Release products and `pkc-scan.sh` prints only OBSERVED lines; QC writes every verdict. ADR-0005 D6: `CA92.1`.
**ADR Version**: ADR-0011 2026-11-18; ADR-0005 2026-11-18; ADR-0001 2026-11-17

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: System command-line tools only.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: scanned Release builds are signed; `pkc-scan.sh` prints only `OBSERVED …` lines; QC writes every PKC verdict (ADR-0011 D1, D3, D5)
- Forbidden: never a script that prints PASS/FAIL for PKC rows; never `CODE_SIGNING_ALLOWED=NO` for a scanned build (ADR-0011 Alt 2, D3)

---

## Acceptance Criteria

*From GDD `design/gdd/privacy-kids-compliance.md`, scoped to this story:*

- [ ] Release entitlements equal the allowlist exactly (macOS app-sandbox true; no network, iCloud, push, Game Center, associated domains) (AC-01).
- [ ] No `NS*UsageDescription` key, URL type, queried scheme or ATS exception (AC-06).
- [ ] `PrivacyInfo.xcprivacy` has tracking false, no domains or collected types, UserDefaults/`CA92.1`, and `SystemBootTime`/`35F9.1` iff our code calls `systemUptime` (AC-09).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0011 first):*

The scans exist (TASK-079). This story runs them on the Demo 1 candidate (Letterlings, TASK-130 IDs) and retains QC's verdicts.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- privacy/002: binary and code scans
- privacy/003: runtime

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `production/qa/evidence/<TASK>/<sha>/pkc-static.txt`
- `production/qa/evidence/<TASK>/<sha>/results.md (QC)`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY-READY skipped — Lean mode).

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**: Config/Data: smoke check pass (`production/qa/smoke-*.md`); here also `kidtools validate content` PASS on the shipped data

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/settings/story-001-userdefaults-backend.md`
- Unlocks: `production/epics/privacy/story-002-release-code-scans.md`, `production/epics/privacy/story-003-runtime-network-and-storage.md`
