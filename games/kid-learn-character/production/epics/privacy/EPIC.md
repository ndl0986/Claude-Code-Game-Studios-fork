# Epic: Privacy & Kids Compliance

> **Layer**: Foundation
> **GDD**: design/gdd/privacy-kids-compliance.md
> **Architecture Module**: no runtime module: build scans and checks (tools/ci, ADR-0011)
> **Milestone**: Demo 1 (`production/milestones/demo-1.md`, K-48)
> **Status**: Ready
> **Stories**: 3 stories (TASK-137)

## Overview

The kids-category guarantees as build gates: no network, SDKs, identifiers or location, the privacy manifest and entitlements allowlist, and no input in release logs. The gates exist from TASK-079; Demo 1's signed build runs them as a release candidate would.

## Governing ADRs

| ADR | Status | Decision Summary | Engine Risk |
|-----|--------|------------------|-------------|
| ADR-0011: Build, verify and PKC gates | Accepted | verify.sh, pkc-scan.sh, self-test; scans on signed Release products | LOW |
| ADR-0001: Native Apple stack | Accepted | D8 no network | HIGH |
| ADR-0005: Settings persistence | Accepted | D5/D8 privacy manifest reasons | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage | Demo 1 |
|-------|-------------|--------------|--------|
| TR-pkc-001 | No network, no SDK, no identifiers, no location (PKC-01..04) | ADR-0001 D8; ADR-0011 D5/D6 ✅ | in |
| TR-pkc-002 | Privacy manifest with CA92.1 / 35F9.1; entitlements allowlist (PKC-05..09) | ADR-0005 D5/D8; ADR-0011 D5 ✅ | in |
| TR-pkc-003 | No log call carrying input, code or accessibility state in release builds (PKC-14) | ADR-0011 D5/D6 ✅ | in |
| TR-pkc-004 | Scans run on signed Release products, evidence retained per release candidate | ADR-0011 D3/D5/D6 ✅ | in |

**Requirements covered by Accepted ADRs**: 4 / 4
**Untraced Requirements**: None

## Device Rows That Gate Story Closure

(`production/qa/device-checks-plan.md`; a spike run is ADR evidence, never AC evidence.)

- **M-11, P-5**: no network and no input in logs on the device (PKC-01 (c), PKC-14)

## Contracts

(`contracts/README.md` registry; `story:<x>` is the story stem that starts the runner.)

- none (the PKC rules are scans, not a contract)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Demo 1 signed Release builds pass the static PKC checks: entitlements, Info.plist, privacy manifest](story-001-release-static-checks.md) | Config/Data | Ready | ADR-0011, ADR-0005, ADR-0001 |
| 002 | [Demo 1 Release builds pass the API, third-party and log scans](story-002-release-code-scans.md) | Config/Data | Ready | ADR-0011, ADR-0001 |
| 003 | [Scripted session on the device: zero network bytes and one app-written key](story-003-runtime-network-and-storage.md) | Integration | Ready | ADR-0011, ADR-0005 |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every Demo 1 acceptance criterion of design/gdd/privacy-kids-compliance.md verified (criteria of out-of-Demo-1 requirements stay open for the next milestone)
- Logic and Integration stories have passing tests in the test root; each contract above runs (`runner:` row) instead of `not-started`
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/` (a lead sign-off too for Visual/Feel)
- Each device row above that gates a story is PASS on the production app, or the story records it NOT ASSESSED with the reason
