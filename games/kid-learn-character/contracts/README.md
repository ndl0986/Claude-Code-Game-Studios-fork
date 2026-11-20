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
| settings-record-v1 | v1 | settings-store.md | KidCore | superseded by settings-record-v2 (see Registry; TASK-091: `F1-slider-release-7.5` contradicted R6a) |
| settings-record-v2 | v2 | settings-store.md | KidCore | TASK-091: v1's slider case fixed; the non-finite slider cases added (F1, TASK-082) |
| input-filter-v1 | v1 | input-key-filter.md | KidCore | superseded-by: input-filter-v2 (K-40; TASK-098 added `gateDigitUp`) |
| input-filter-v2 | v2 | input-key-filter.md | KidCore | TASK-099: v1 + `gateDigitUp` (3 cases updated, 8 AC-1t cases) |
| press-queue-v1 | v1 | press-queue.md | KidCore | batch 2 (TASK-081) |
| reveal-timing-v1 | v1 | reveal-stage.md; cast-rendering.md F1, F2, F4, F5, F7 | KidCore | batch 3 (TASK-086) |
| audio-plan-v1 | v1 | audio-voice.md | KidCore | batch 3 (TASK-086) |
| hint-letters-v1 | v1 | hint-letters.md | KidCore | batch 4 (TASK-089) |
| keyboard-row-v1 | v1 | onscreen-keyboard-row.md | KidCore | superseded-by: keyboard-row-v2 (K-40; TASK-135 K-49 changed what `keyboardRow` false means) |
| keyboard-row-v2 | v2 | onscreen-keyboard-row.md (TASK-135) | KidCore | TASK-141: v1 + `keyboardPresent`, the 0.5 s settle, AC-1, AC-15, AC-20 to AC-24 |
| gate-logic-v1 | v1 | parent-gate-panel.md (G13) | KidCore | batch 5 (TASK-094) |
| app-shell-v1 | v1 | app-shell-title.md | KidCore | batch 5 (TASK-094) |
| parade-v1 | v1 | parade.md | KidCore | superseded-by: parade-v2 (K-40; K-45 removed the rest) |
| parade-v2 | v2 | parade.md (TASK-120) | KidCore | TASK-122: K-45 start, K-44 meter, K-46 light |
| scene-look-v1 | v1 | scene-time-weather.md; cast-rendering.md F8 | KidCore | batch 6 (TASK-101) |

All ADR-0004 D8 contracts are written (order in `production/team/TASK-080-contracts-plan.md`).

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
| app-shell-v1 | not-started: story:app-shell | 26 |
| audio-plan-v1 | not-started: story:audio-voice | 30 |
| gate-logic-v1 | not-started: story:parent-gate | 48 |
| hint-letters-v1 | not-started: story:hint-letters | 58 |
| input-filter-v1 | superseded-by: input-filter-v2 | 86 |
| input-filter-v2 | not-started: story:input | 95 |
| key-table-schema-v1 | runner: KeyTableModelRunner + Tools.KeyTableFileLayer | 93 |
| keyboard-row-v1 | superseded-by: keyboard-row-v2 | 36 |
| keyboard-row-v2 | not-started: story:keyboard-row | 57 |
| parade-v1 | superseded-by: parade-v2 | 30 |
| parade-v2 | not-started: story:parade | 46 |
| press-queue-v1 | not-started: story:press-queue | 46 |
| reveal-timing-v1 | not-started: story:reveal-stage | 60 |
| scene-look-v1 | not-started: story:scene | 42 |
| settings-record-v1 | superseded-by: settings-record-v2 | 73 |
| settings-record-v2 | runner: SettingsRecordRunner | 76 |

## Drift check

`sources.lock` holds `Reviewed-Section-Hash` lines from `.claude/scripts/review-receipts.sh sections-hash`, for the
cited `##` sections only. To see which contracts cite a section that has changed since their version was cut, run
`.claude/scripts/review-receipts.sh sections-check <contract>/sources.lock <gdd>` from the repo root (ADR-0004 D6's
`tools/contracts/source-drift.sh` will wrap this). The output is observations only. A PR that changes a cited
section says in that GDD's review log `fixture: <contract>-v(N+1)` or `fixture: none (<reason>)`.
