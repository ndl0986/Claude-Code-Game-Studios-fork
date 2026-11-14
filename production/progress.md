# Progress Log

Where the project stands, so work can resume from the repo. Newest entry first.

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
