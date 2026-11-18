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
| settings-record-v1 | v1 | settings-store.md | KidCore | first cases (TASK-068) |

Not yet written (ADR-0004 D8, each landing with its system's story): input-filter-v1, press-queue-v1,
reveal-timing-v1, audio-plan-v1, hint-letters-v1, parade-v1, gate-logic-v1, app-shell-v1, scene-look-v1,
keyboard-row-v1.

## Drift check

`sources.lock` holds `Reviewed-Section-Hash` lines from `.claude/scripts/review-receipts.sh sections-hash`, for the
cited `##` sections only. To see which contracts cite a section that has changed since their version was cut, run
`.claude/scripts/review-receipts.sh sections-check <contract>/sources.lock <gdd>` from the repo root (ADR-0004 D6's
`tools/contracts/source-drift.sh` will wrap this). The output is observations only. A PR that changes a cited
section says in that GDD's review log `fixture: <contract>-v(N+1)` or `fixture: none (<reason>)`.
