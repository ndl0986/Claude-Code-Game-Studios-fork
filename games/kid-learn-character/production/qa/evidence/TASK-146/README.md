# TASK-146 — key-table-schema-v2 (K-52: `.m4a` → `.caf`)

- **Cases:** v1's 93 with every `.m4a` → `.caf` (878 places) and `contract` renamed. Checked mechanically: v2 minus
  the two new cases, with `.caf` mapped back to `.m4a`, equals v1 exactly (JSON equality).
- **New:** `V6-fail-sfx-old-m4a-extension` (V6 only) and `V7-fail-voice-file-only-as-m4a` (V7 only). They need the
  KidCore `.caf` change to pass; on v1 code they would report the opposite, which is why they are there.
- **sources.lock:** cut from the repo root on TASK-145b 71438637. Detailed Design changed (the `.caf` text); ADR-0002
  Decision changed since v1's cut (TASK-079 ContractKit, see the README Drift check note); the rest is v1's hashes.
- **verify-dev-no-xcode.log:** PASS, v2 `not-started` (structure OK, 95 cases). Its runner lands in game-dev-android's
  KidCore commit on this branch, which also flips the registry rows.
