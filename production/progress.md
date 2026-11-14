# Progress Log

Where the project stands, so work can resume from the repo. Newest entry first.

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

**Browser testing stopped (Luan, 2026-11-14):** TASK-003 closed as the design reference at `203d73e` (Android r3 partial, iOS not run); TASK-003b cancelled. QC waits for the native builds.

**Engine decision (Luan, 2026-11-14):** native per platform. iOS: Swift + SpriteKit (game-dev-ios). Android: Kotlin (game-dev-android), 2D approach to be picked by Luan in TASK-007. Godot shelved (TASK-002 branch kept, not merged; local tip `82c016e`). New tasks: TASK-005 ADR + shared `content/`, TASK-006 iOS setup, TASK-007 Android setup.

### Waiting on Luan

1. (Done) Orca Screen Recording: both Orca and Orca Computer Use are on; `orca computer permissions` shows both granted.
2. Go to merge TASK-002 and TASK-004 into `docs/vn-history-game-plan`.
3. Next task for game-art-content (`/asset-spec` for the mission, or hero #2).
4. Sign off claims C01–C11 in `design/narrative/heroes/tran-quoc-toan.md` and confirm textbook pages.
5. Listen to the prototype's sound on a real phone; a real iPhone and low-end Android phone when possible.
6. Open questions: monetization; "weeks" = MVP only.

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
