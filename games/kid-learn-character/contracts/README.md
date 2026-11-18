# Behaviour contracts

Cross-platform behaviour contracts for Kid Learn Character (ADR-0004). Each contract is one directory,
`<name>-vN/`, holding `spec.md` (what it covers and the entry points), `cases.json` (the cases, in the format of
[`case-schema-v1.md`](case-schema-v1.md)) and `sources.lock` (the GDD sections the cases cite, for drift checks).

**Rules** (ADR-0004 D6):
- **A merged `<name>-vN/` is never edited in place.** Any change makes `<name>-v(N+1)/`.
- **The GDD decides.** When a platform and a case disagree, fix the code, or fix the case in a new version that
  cites the GDD.
- **QC writes the hand-written cases, and the system's dev reviews them** (ADR-0004 D7).

## Current versions

| Contract | Version | Owner GDD | Layers | Status |
|---|---|---|---|---|
| morph-contract-v1 | v1 | morphcore.md | MorphCore | Accepted. It lives at `docs/architecture/morph-contract-v1.md` and `content/fixtures/morph-contract-v1.json` and moves here only with a v2 |
| key-table-schema-v1 | v1 | key-table-theme-data.md | model (KidCore), file (apple/Tools) | first cases (TASK-068) |
| settings-record-v1 | v1 | settings-store.md | KidCore | first cases (TASK-068). **Pending v2:** the non-finite slider case (settings-store F1, TASK-082), batched with the next settings change |
| input-filter-v1 | v1 | input-key-filter.md | KidCore | batch 2 (TASK-081) |
| press-queue-v1 | v1 | press-queue.md | KidCore | batch 2 (TASK-081) |
| reveal-timing-v1 | v1 | reveal-stage.md; cast-rendering.md F1, F2, F4, F5, F7 | KidCore | batch 3 (TASK-086) |
| audio-plan-v1 | v1 | audio-voice.md | KidCore | batch 3 (TASK-086) |

Not yet written (ADR-0004 D8; order in `production/team/TASK-080-contracts-plan.md`): hint-letters-v1, parade-v1, gate-logic-v1, app-shell-v1, scene-look-v1,
keyboard-row-v1.

## Registry

The **only** list of contracts and their states (K-40; ADR-0004 D5 note, 2026-11-18). Every `*-v*/` directory has
exactly one row; the harnesses read this table and keep no list of their own. A row is one of:
- `runner: <Name>[ + <Name>]`: run by that runner (a `Tools.` name runs in the apple/Tools harness, every other in
  KidCore's `ContractTests`). Reported PASS or FAIL.
- `not-started: <story id>`: the contract is accepted and its code is not written. Structure-checked, reported
  `NOT ASSESSED <contract>: not started (story <id>); structure OK, 0 of <n> cases run`, never PASS. FAIL if a runner
  is registered for it or its story is Done. The Production gate and every release-candidate verify FAIL while any
  row is not-started.
- `superseded-by: <contract-vN+1>`: replaced. The target must exist with its own runner or not-started row; reported
  `SUPERSEDED <contract> → <next>: not run (<n> cases)`, never PASS; FAIL if a runner is still registered for it or
  code cites it.

`Cases` is the declared count; the file must hold exactly that many. **Story ids are placeholders**
(`story:<system>`) until /create-epics and /create-stories write the real ones; a placeholder names no story file, so
it is never Done.

| Contract | Row | Cases |
|---|---|---|
| audio-plan-v1 | not-started: story:audio-voice | 30 |
| input-filter-v1 | not-started: story:input-key-filter | 86 |
| key-table-schema-v1 | runner: KeyTableModelRunner + Tools.KeyTableFileLayer | 93 |
| press-queue-v1 | not-started: story:press-queue | 46 |
| reveal-timing-v1 | not-started: story:reveal-stage | 60 |
| settings-record-v1 | runner: SettingsRecordRunner | 73 |

## Drift check

`sources.lock` holds `Reviewed-Section-Hash` lines from `.claude/scripts/review-receipts.sh sections-hash`, for the
cited `##` sections only. To see which contracts cite a section that has changed since their version was cut, run
`.claude/scripts/review-receipts.sh sections-check <contract>/sources.lock <gdd>` from the repo root (ADR-0004 D6's
`tools/contracts/source-drift.sh` will wrap this). The output is observations only. A PR that changes a cited
section says in that GDD's review log `fixture: <contract>-v(N+1)` or `fixture: none (<reason>)`.
