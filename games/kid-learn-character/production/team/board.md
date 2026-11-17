# Team board: Kid Learn Character

Kickoff notes: `production/team/kickoff-notes.md` (input for /brainstorm). Open decisions:
`games/kid-learn-character/production/team/decisions.md`. The leader owns this file.

Every path for this game is under `games/kid-learn-character/`. Base branch:
`docs/kid-learn-character-plan`.

| ID | Task | Type | Owner | Status | Branch | Updated |
|---|---|---|---|---|---|---|
| TASK-029 | Content list A–Z and 0–9 (object, picture idea, object sound, spoken word, toddler-safe check) + 2D vs 3D art and sound sourcing options with cost and licence | design | game-art-content | PAUSED (K-00): wip `dddd373` pushed; feeds /brainstorm + GDDs | `design/TASK-029-content-list` | 2026-11-17 |
| TASK-030 | iOS tech plan: on-screen keyboard + hardware keys, audio, 2D (SpriteKit) vs 3D (SceneKit/RealityKit), Kids category rules, project layout | plan | game-dev-ios (review: game-dev-android) | PAUSED (K-00): no commits; becomes /setup-engine + /create-architecture | `plan/TASK-030-ios-tech` | 2026-11-17 |
| TASK-031 | Android tech plan: on-screen keyboard + hardware keys, audio, 2D vs 3D (e.g. Filament/SceneView), Families policy, project layout | plan | game-dev-android (review: game-dev-ios) | PAUSED (K-00): wip notes `45b9fe1` pushed; Android comes after Apple (K-03) | `plan/TASK-031-android-tech` | 2026-11-17 |
| TASK-032 | Store rules checklist for kids apps: Apple Kids category (game-qc-ios) and Google Play Families + COPPA (game-qc-android), plus a first test-case list for the core loop | qa | game-qc-ios + game-qc-android | PAUSED (K-00): Google draft `ac7b97b` pushed (qa/TASK-032-kids-store-rules-android); Apple half not started; feeds /qa-plan | `qa/TASK-032-kids-store-rules` | 2026-11-17 |

## Leader log

- 2026-11-17: Luan started the new game. Brief, board and decisions written; TASK-029…032 sent.
  Plans only this round: no app code until Luan picks K-01 and approves the tech plans.
- 2026-11-17: K-00: Luan chose the original studio process; the game folder became its own
  studio project (links `.claude/` + `CLAUDE.md`, own `project.yaml`). K-03: fully native, Apple
  first (iPadOS + macOS). TASK-029…032 paused, wip pushed. Next: the leader restarts in the game
  folder and runs /start → /brainstorm with Luan.
