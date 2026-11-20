# TASK-139 evidence: contract section drift at 713dae86

`drift139.sh <rev>` (run from the repo root) prints, for every `contracts/*/sources.lock` line whose section hash at
`<rev>` differs from the lock, the first commit after the lock's commit that changed it. Observations only.

The reference for content-pipeline/006 (`tools/contracts/source-drift.sh`, ADR-0004 D6). Two traps it handles:
- section names contain spaces, so a lock line is split on its **last** space;
- the whole section name is matched ("Decision" is a prefix of "Decision Makers").

It also flags a lock path that isn't repo-relative (parade-v2's, fixed in TASK-141). The fixture lines it led to are
TASK-139b's.
