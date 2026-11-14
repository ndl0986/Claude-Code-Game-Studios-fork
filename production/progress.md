# Progress Log

Where the project stands, so work can resume from the repo. Newest entry first.

## 2026-11-14 (afternoon) — Team running, prototype in QC

**Status:** Concept stage. Concept approved; Godot 4.7.2 pinned; art bible and first hero's content drafted; the browser prototype of the first mission is in QC. Paused for an Orca restart (macOS Screen Recording grant for iOS QC).

**Main doc:** [Dải Đất Anh Hùng — Development Roadmap](https://claude.ai/artifact/E2dscdjUpVJLj63i4et2uz). Live task board: `production/team/board.md` (GitHub Issues are off). Team rules: `.claude/skills/game-team-lead/SKILL.md`.

### Team (one Claude Code session each; worktrees under `~/orca/workspaces/Claude-Code-Game-Studios-fork/<name>`)

| Session | Role | Start with |
| --- | --- | --- |
| game-leader (repo root) | Leader (`/game-team-lead`); never implements | `tools/team/start-leader.sh` (fixed name `game-leader`, which the member scripts message) |
| game-dev-001 | Developer, iOS owner | `tools/team/start-game-dev-001.sh` |
| game-dev-002 | Developer, Android owner | `tools/team/start-game-dev-002.sh` |
| game-art-content | Art + content/history (Luan signs off history) | `tools/team/start-game-art-content.sh` |
| game-qc-android | Android QC (emulator `mp17863`) | `tools/team/start-game-qc-android.sh` |
| game-qc-ios | iOS QC (Simulator) | `tools/team/start-game-qc-ios.sh` |

### Tasks and branches (none pushed unless noted)

| Task | Branch @ commit | State |
| --- | --- | --- |
| TASK-001 concept | merged into `docs/vn-history-game-plan` as `b41d157` (pushed) | Done |
| TASK-002 Godot 4.7.2 | `setup/TASK-002-engine-godot` @ `6dcdbce` (wip) | Done; toolchain installed at Luan's request: Godot 4.7.2 at ~/Applications/Godot.app (`godot` on PATH), JDK 17, Android build-tools 35.0.1 + android-35, iOS 27.1 runtime; headless import passes. Left: export templates (download stops on restart: rerun), editor SDK paths, JAVA_HOME, squash the wip, /test-setup. Not merged |
| TASK-003 browser prototype | `proto/TASK-003-mission-prototype` @ `203d73e` | Code + content review approved. Android: r1 FAIL (low) → r2 FAIL (B4 fullscreen race) → fixed in `c7f1173` → r3 partial (`qa/TASK-003-android` @ `c52a2e9`): B4 PASS 18/18; O5, O6, VI|EN side effect and smoke not run yet. O6 fixed by dev-002 in `203d73e`; finish r3 on `203d73e`. iOS: NOT ASSESSED (`qa/TASK-003-ios` @ `18eff46`) |
| TASK-003b beat types, Special button, arrows, art fixes | — | Ready; starts after TASK-003 (likely dev-001) |
| TASK-004 art bible + Trần Quốc Toản content | `design/TASK-004-art-bible-tqt-beats` @ `4d7aca2` | Art + structure signed off; claims C01–C11 and source pages not signed; not merged |

### Waiting on Luan

1. Orca Screen Recording: add `/Applications/Orca.app` (the helper `Orca Computer Use` is already on, but macOS checks the parent), Quit & Reopen.
2. Go to merge TASK-002 and TASK-004 into `docs/vn-history-game-plan`.
3. Next task for game-art-content (`/asset-spec` for the mission, or hero #2).
4. Sign off claims C01–C11 in `design/narrative/heroes/tran-quoc-toan.md` and confirm textbook pages.
5. Listen to the prototype's sound on a real phone; a real iPhone and low-end Android phone when possible.
6. Open questions: monetization; "weeks" = MVP only.

### Resume here (after the Orca restart)

1. Start the leader: `tools/team/start-leader.sh` (it opens at the repo root as `game-leader` and runs `/game-team-lead`).
2. Check permissions: `orca computer permissions --json` → `accessibility` and `screenshots` both `granted`.
3. `ListAgents`; start any missing member with its script above (each script prompts the member to reply "ready" to `game-leader`). Close old duplicates (`game-dev-001-1e`, `game-dev-002-46`). Tell game-dev-001 to resume the TASK-002 leftovers.
4. Re-send Android QC the 4 unfinished r3 items (O6 is fixed in `203d73e`), and iOS QC its cases, on `203d73e` (iPhone Duo, safe-area caveat). Android QC must first restart its web server, adb reverse/forward and the DevTools watcher; the emulator runs `-gpu host`. Each QC branch already holds its earlier evidence.
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
