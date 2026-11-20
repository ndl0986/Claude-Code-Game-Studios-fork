# Story 006: `tools/contracts/source-drift.sh`: report contracts whose cited GDD section changed (observations only)

> **Epic**: Content Pipeline (Tools) (`production/epics/content-pipeline/EPIC.md`)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-20
> **Last Updated**: —
> **Milestone**: Demo 1 (K-48)

## Context

**GDD**: `design/gdd/ADR-0004` — D6 (no GDD system: the contract harness)
**Requirement**: `TR-contracts-??? (no registry entry: ADR-0004 D6 tooling, no GDD requirement)`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Contracts, fixtures and harness; ADR-0011: Build, verify and PKC gates
**ADR Decision Summary**: ADR-0004 D6: `source-drift.sh` runs `review-receipts.sh sections-check` for every contract's `sources.lock` and prints observations only — the contracts whose cited `##` section changed since their version was cut. It never gives a verdict.
**ADR Version**: ADR-0004 2026-11-18; ADR-0011 2026-11-18

**Engine**: Native Apple, no studio engine (ADR-0001 D7): Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1 | **Risk**: LOW
**Engine Notes**: Bash over `.claude/scripts/review-receipts.sh`.

**Control Manifest Rules** (`docs/architecture/control-manifest.md`, v2026-11-20):
- Required: helpers in `.claude/scripts/` and `tools/` emit observations, never verdicts (CLAUDE.md; ADR-0004 D6)
- Required: gate order in verify.sh per ADR-0011 D4; this script adds an OBSERVED line, it does not gate

---

## Acceptance Criteria

*From GDD `design/gdd/ADR-0004`, scoped to this story:*

- [ ] For every `contracts/*/sources.lock`, each `Reviewed-Section-Hash: <gdd>#<section> <hash>` line is checked; a changed section prints `OBSERVED drift <contract>: <gdd>#<section>`, an unchanged one nothing, a missing GDD or section `OBSERVED missing …` — never PASS or FAIL.
- [ ] **Section names contain spaces** (`#Detailed Design`, `#Acceptance Criteria`): the line is split on the last space only, and a test lock with a spaced name is read correctly.
- [ ] **The whole section name is matched**, never a prefix: "Decision" must not match "Decision Makers" (a test GDD with both headings, editing only "Decision Makers", reports nothing for a lock citing "Decision").
- [ ] verify.sh echoes each line as `OBSERVED …` and its exit code is unchanged by drift; with two contracts, an edit to one cited section is reported and an edit to an uncited section is not (ADR-0004 Validation 5).

---

## Implementation Notes

*Derived from the governing ADRs (ADR-0004 first):*

game-qc-android's scratch reference: `drift139.sh` (TASK-139; ask QC for it). The receipt format is `review-receipts.sh sections-hash`. A drift line is a prompt for the review rule (the GDD's review log must say the contract was re-checked), not a failure.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- None

---

## Files

*Planned; `/dev-story` replaces this list with the files it changed. Roots are ADR-0001 D3 / ADR-0002 D1 (`apple/`); `engine.name` is unset by design.*

- `tools/contracts/source-drift.sh`
- `tools/contracts/tests/source-drift-test.sh`
- `tools/ci/verify.sh`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY-READY skipped — Lean mode).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: Logic: a unit test in the package's test target (path under Files) — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: None
