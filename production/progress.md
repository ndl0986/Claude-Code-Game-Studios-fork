# Progress Log

Where the project stands, so work can resume from the repo. Newest entry first.

## 2026-11-15 — PAUSE (Luan): checkpoint to resume

**Status:** native vertical slice (Trần Quốc Toản mission) in QC rounds, both apps nearly at feature
parity. Paused on Luan's instruction; all branches committed and pushed (hashes below). Detailed
history: `production/team/board.md` (bottom = newest). Open decisions: `production/team/decisions.md`.

### Where each app stands

| App | Last QC PASS | Frozen / in flight | Next |
|---|---|---|---|
| Android (`setup/TASK-007-android-kotlin`) | **r11** 742a230 (evidence `qa/TASK-007-android-r11` @ 4321a86) | **r12** coded @ e24855a, NOT frozen: hero banner #D64A2E + #E8A93B border, partner = follower look, camera cut at the beat change (158 JVM) | pre-freeze pass on 5556 → freeze → QC |
| iOS (`feat/TASK-006-ios-native`) | **r7** b53cfde (evidence `qa/TASK-006-ios-r7` @ 6c02e5a) | **r8** frozen c388736 (build folder `production/qa/builds/TASK-006-ios-c388736/` in game-dev-001); **QC INCOMPLETE** (stopped for the pause, `qa/TASK-006-ios-r8`). **r9** core done (8eeef44, GameCore 145, trace 1.3 green); app side written, NOT compiled | re-run r8 QC from the start → r9 build/freeze → QC |

r9 (iOS) / r12 (Android) bring both apps to the same spec: Rule 7c finish hold (finish_hold 1.5 s,
partner placement, every resume restarts), Hints Rule 6, double pop outline (AC15), AC14 picture
bundle test, follower look and hero banner. When both PASS → **/gate-check** (vertical slice).

### Docs branch `docs/vn-history-game-plan` (pushed)

Merged this stretch: r8 (4495f7f), r8b, r8c (quiz small-layout switch, corner_bottom 18 + P), r8d
(ending still + AC14), r8e (device k labels), r9 design (finish hold, hints ≥ 276, double outline),
r10 (partner placement, AC32–34), r11 (ending pole, AC7/AC10 at rest, slice looks), data 005r
(finish_hold), 005t (trace 1.3, green on both cores).

### Resume steps

1. Start the sessions (`tools/team/start-*.sh`), `ListAgents`, tell each member "resume".
2. game-qc-ios: re-run iOS r8 QC from the start on E9F515E9. DiagnosticReports was cleared
   2026-11-15 (122 reports) to fix the ~300 s XCTest teardown — check per-case durations; if it is
   still slow, restart the Mac between QC rounds.
3. After iOS r8 reports: game-dev-ios compiles r9, screen pass, full suite, Release byte check,
   freeze. game-dev-android: r12 pre-freeze pass on 5556 (adbdev), freeze. Both to QC (one at a
   time on the host if load is high).
4. Queued doc fix (game-art-content): Hints Rule 6 / AC12 / hud.md:136 — "never covers the pad's
   visible square (touch slop excluded); the hand takes no touches".
5. Known minors / backlog: none blocking. Not yet assessed on either app: sound, a real low-end phone.

### Waiting on Luan (nothing blocks the slice)

- **D-18** character looks — "D-18 all as recommended" or list changes; new (11) final follower height.
- **C01–C16** history claims: release builds stop at gate R12 until signed off.
- Other open decisions in `production/team/decisions.md` (D-20, D-22, D-23, D-29–D-35, D-28b …).
- Release checklist items on the board (map thẩm định, Android targetSdk 36, k ≥ 0.40 floor, D-22).

### Branches at pause (all pushed to origin)

| Worktree | Branch | Hash |
|---|---|---|
| repo root (leader) | docs/vn-history-game-plan | (this commit) |
| game-dev-001 | feat/TASK-006-ios-native | 70f2cd1 (r9 app side wip, not compiled) |
| game-dev-002 | setup/TASK-007-android-kotlin | e24855a (r12, carries trace 1.3) |
| game-qc-ios | qa/TASK-006-ios-r8 | PENDING (r8 QC incomplete) |
| game-qc-android | qa/TASK-007-android-r11 | 4321a86 |
| game-art-content | design/r11-ending-pole-ac7 (merged) | be1d08d |
| (backup) | setup/TASK-002-engine-godot-local | 82c016e (old Godot setup, diverged; origin/setup/TASK-002-engine-godot left as is) |

All other local task branches (content/*, data/*, design/*, docs/*) are merged into the docs branch, so their commits are on origin.

## 2026-11-14 (afternoon) — Team running, prototype in QC

**Status:** Concept stage. Concept approved; Godot 4.7.2 pinned; art bible and first hero's content drafted; the browser prototype of the first mission is in QC. Orca Screen Recording granted live (adding Orca.app itself fixed it); no restart was needed.

**Main doc:** [Dải Đất Anh Hùng — Development Roadmap](https://claude.ai/artifact/E2dscdjUpVJLj63i4et2uz). Live task board: `production/team/board.md` (GitHub Issues are off). Team rules: `.claude/skills/game-team-lead/SKILL.md`.

### Team (one Claude Code session each; worktrees under `~/orca/workspaces/Claude-Code-Game-Studios-fork/<name>`)

| Session | Role | Start with |
| --- | --- | --- |
| game-leader (repo root) | Leader (`/game-team-lead`); never implements | `tools/team/start-leader.sh` (fixed name `game-leader`, which the member scripts message) |
| game-dev-ios | Developer, iOS owner | `tools/team/start-game-dev-ios.sh` |
| game-dev-android | Developer, Android owner | `tools/team/start-game-dev-android.sh` |
| game-art-content | Art + content/history (Luan signs off history) | `tools/team/start-game-art-content.sh` |
| game-qc-android | Android QC (emulator `mp17863`) | `tools/team/start-game-qc-android.sh` |
| game-qc-ios | iOS QC (Simulator) | `tools/team/start-game-qc-ios.sh` |

### Tasks and branches (none pushed unless noted)

| Task | Branch @ commit | State |
| --- | --- | --- |
| TASK-001 concept | merged into `docs/vn-history-game-plan` as `b41d157` (pushed) | Done |
| TASK-002 Godot 4.7.2 | `setup/TASK-002-engine-godot` @ `d44bb07` local (GitHub still has `6dcdbce`: the amended `5063c5d` needs Luan's force push) | Done; toolchain installed at Luan's request: Godot 4.7.2 at ~/Applications/Godot.app (`godot` on PATH), JDK 17, Android build-tools 35.0.1 + android-35, iOS 27.1 runtime; headless import passes. Export templates 4.7.2 installed (sha512 OK). `d44bb07`: gdUnit4 6.2.2 + tests/ + CI workflow (runner 2/2 pass, proven to fail when broken). Editor Java/Android SDK paths and JAVA_HOME/ANDROID_HOME set. Left: first empty iOS export in the Simulator (dev-ios shows Luan the main scene + preset first); Android debug keystore not created yet (dev-android); squash decision at the end. Not merged |
| TASK-003 browser prototype | `proto/TASK-003-mission-prototype` @ `203d73e` | Code + content review approved. Android: r1 FAIL (low) → r2 FAIL (B4 fullscreen race) → fixed in `c7f1173` → r3 partial (`qa/TASK-003-android` @ `c52a2e9`): B4 PASS 18/18; O5, O6, VI|EN side effect and smoke not run yet. O6 fixed by dev-android in `203d73e`; finish r3 on `203d73e`. iOS: NOT ASSESSED (`qa/TASK-003-ios` @ `18eff46`) |
| TASK-003b beat types, Special button, arrows, art fixes | — | Ready; starts after TASK-003 (likely dev-ios) |
| TASK-004 art bible + Trần Quốc Toản content | `design/TASK-004-art-bible-tqt-beats` @ `4d7aca2` | Art + structure signed off; claims C01–C11 and source pages not signed; not merged |

**Process (Luan, 2026-11-14):** TASK-006/007 = native vertical slice; TASK-008 = /map-systems + key GDDs (game-art-content), then /gate-check → epics/stories/sprints for the full build. Android: pure Android SDK (SurfaceView/Canvas, SoundPool) + kotlinx.serialization; targetSdk 35 now, 36 before Play.

**Browser testing stopped (Luan, 2026-11-14):** TASK-003 closed as the design reference at `203d73e` (Android r3 partial, iOS not run); TASK-003b cancelled. QC waits for the native builds.

**Engine decision (Luan, 2026-11-14):** native per platform. iOS: Swift + SpriteKit (game-dev-ios). Android: Kotlin (game-dev-android), 2D approach to be picked by Luan in TASK-007. Godot shelved (TASK-002 branch kept, not merged; local tip `82c016e`). New tasks: TASK-005 ADR + shared `content/`, TASK-006 iOS setup, TASK-007 Android setup.

### Waiting on Luan

1. (Done) Orca Screen Recording: both Orca and Orca Computer Use are on; `orca computer permissions` shows both granted.
2. Go to merge TASK-002 and TASK-004 into `docs/vn-history-game-plan`.
3. Next task for game-art-content (`/asset-spec` for the mission, or hero #2).
4. Sign off claims C01–C11 in `design/narrative/heroes/tran-quoc-toan.md` and confirm textbook pages.
5. Listen to the prototype's sound on a real phone; a real iPhone and low-end Android phone when possible.
6. Open questions: monetization; "weeks" = MVP only.

> **Warning (2026-11-14):** closing a workspace in Orca deletes its worktree folder and local branch. That happened to all 5 member worktrees once. They were recreated with plain `git worktree add` at the same paths (so `--resume` finds each member's conversation), on: game-dev-001 → `setup/TASK-002-engine-godot` (`82c016e`, unpushed), game-dev-002 → `setup/TASK-007-android-kotlin`, game-qc-android → `qa/TASK-003-android`, game-qc-ios → `qa/TASK-003-ios`, game-art-content → `design/TASK-004-art-bible-tqt-beats`. Close member **sessions** (the terminal), not the Orca workspace. Push work before closing anything.

### Resume here (after the Orca restart)

1. Start the leader: `tools/team/start-leader.sh`. It resumes the saved leader conversation (id in the gitignored `production/session-state/leader-session.txt`) under the fixed name `game-leader`; `--fresh` starts a new one.
2. Check permissions: `orca computer permissions --json` → `accessibility` and `screenshots` both `granted`.
3. `ListAgents`; start any missing member with its script above: add `--resume` to continue its last conversation under the same name, or omit it for a fresh session that replies "ready" to `game-leader`. Close old duplicates (`game-dev-ios-1e`, `game-dev-android-46`). Tell game-dev-ios to resume the TASK-002 leftovers.
4. (Superseded: browser testing stopped.) Next QC is on the native builds from TASK-006/007 (iPhone Duo, safe-area caveat). Android QC must first restart its web server, adb reverse/forward and the DevTools watcher; the emulator runs `-gpu host`. Each QC branch already holds its earlier evidence.
5. When both platforms pass, ask Luan's go to merge TASK-003 into `docs/vn-history-game-plan`, then hand out TASK-003b.

## 2026-11-14 — Repo set up, project plan drafted

**Status:** Planning. No engine chosen in config, no game code yet. Waiting on team material.

### Done

- Cloned the template, forked it to `ndl0986/Claude-Code-Game-Studios-fork`, and renamed the local folder to `Claude-Code-Game-Studios-fork`.
- Git remotes (SSH host alias `github-ndl0986-learn-algo`):
  - `origin` → `ndl0986/Claude-Code-Game-Studios-fork` (push here)
  - `upstream` → `Donchitos/Claude-Code-Game-Studios` (template updates)
- Wrote the project plan:
  - Repo copy: [`production/project-plan.md`](project-plan.md)
  - Shared doc for the team: https://claude.ai/artifact/7s8ww63BC5EFXhKJ4xXqLx (the doc and the file don't sync; update both)
- Committed the plan on branch `docs/vn-history-game-plan` (from `main`). **Not pushed, no PR yet.**

### Decisions so far (proposed, not final)

| Decision | Proposal | Status |
| --- | --- | --- |
| Engine | Godot 4 (Unity if ads or in-app purchases matter) | Open: waiting on the business model answer (comment in the shared doc) |
| Rigor | `modes.rigor=standard`, history and narrative at `full` | Proposed, not yet set in `project.yaml` |
| Languages | Vietnamese first, English second | Proposed |
| Platforms | Android + iOS phones | Agreed |

### Not done yet

- `/start` and `/setup-engine` have not been run, so `project.yaml` has no engine or `modes` block.
- Android Studio and Godot are not installed. Xcode is installed, but `xcodebuild` errors: open Xcode once and accept the license.
- No Apple Developer or Google Play Console accounts yet.

### Waiting on

The team material listed in the plan: historical figures, key events, sources and reviewer, audience, style references, art direction, business model, team, launch date and budget.

### Resume here

1. Open Claude Code **from the repo root** so hooks and rules load:
   ```bash
   cd ~/self-projects/Claude-Code-Game-Studios-fork && claude
   ```
2. Check out the plan branch: `git switch docs/vn-history-game-plan`. Push it and open a PR if you want it on `main`.
3. Answer the engine question (business model), then run `/start` → `/setup-engine godot 4.x` → `/project-settings modes.rigor=standard`.
4. Install Android Studio and Godot, fix the Xcode license, and build an empty project on a real Android and iOS phone (phase 0).
5. When the team material arrives, update the plan (both the doc and `production/project-plan.md`) and start phase 1 with `/brainstorm` and `/prototype`.
6. Add a new entry at the top of this file at the end of each session.
