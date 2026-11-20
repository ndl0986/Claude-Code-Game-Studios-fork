# TASK-141 evidence: keyboard-row-v2

- **verify:** `nice -n 10 bash tools/ci/verify.sh --dev --no-xcode` at fc4b2395: PASS (`verify-dev-no-xcode.log`,
  paths masked). Structure 16/16 contracts; keyboard-row-v2 NOT ASSESSED (not started: story:keyboard-row, 57 cases);
  keyboard-row-v1 SUPERSEDED; 0 FAIL.
- **Independent model:** game-qc-android's checker re-derives every step of all 57 cases from the GDD: 0 mismatches.
  v1's checker on the v2 file: 22 mismatches (expected: the new events and the AC-15 change).
- **Rule mutations** (each a one-line change to the checker; a case must fail):
  - the settle exclusive: 6 fail; no settle at all: 4;
  - the pending change kept at panel close: 2; at Title → Play entry: 1;
  - the switch's off applied at once (v1): 1; the foreground re-read ignored: 3;
  - the hold restarted by a repeated report: 1 (case `R8-repeated-report-keeps-the-hold`, added for it);
  - the gate not deferring: 1; the knob floor strict: 1; AND for OR in the rule: 25;
  - "Fading out → re-shown" removed: 0, which is an equivalent mutant (the clause is redundant in the model).
- **Structure check** (allowed keys, `source` starts "gdd: ", uptime never decreases, draws are strings on a declared
  stream, `keyboardPresent` and the settle knob in every `given`): 0 problems.
- **parade-v2 sources.lock:** paths now repo-relative; all five section hashes re-computed and unchanged.
