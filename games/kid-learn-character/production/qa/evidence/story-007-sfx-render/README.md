# Story 007 evidence: the sfx bake

- `bake-log.txt`: the real `kidtools bake-sfx content/themes/dinosaurs` run (36 files and `provenance.json`).
- `loudness-table.md`: per file, its duration, measure, loudness, gain, true peak and onset count (digits: AC-19).
- `verify-dev.txt`: `verify.sh --dev --no-xcode`, **PASS**, with the baked output held out of the tree.

**Why the baked files aren't committed yet.** `kidtools validate content` treats a theme folder holding only `src/`
as "in progress" (TASK-125). Once `sfx/` sits beside `src/` with no `theme.json`, the validator reports
`FAIL dinosaurs V1: no theme.json`, and verify fails. ADR-0011 D2 says nothing is pushed on a failing gate. So the
36 `.m4a` files and `provenance.json` from that bake are kept outside the repo until `theme.json` lands
(key-table story 001). They're reproduced exactly by re-running `kidtools bake-sfx content/themes/dinosaurs`: the bake
is deterministic, and the container timestamps are zeroed. The leader decides between that and an in-progress rule
that also allows baked folders.

**Not done here:** the by-ear content review (Audio R7 A1, A2: "a grumble, not a scream"). It needs a person listening.
