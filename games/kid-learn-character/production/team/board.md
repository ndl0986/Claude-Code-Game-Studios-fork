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
| TASK-033 | Spike: 2D animation runtime for the letter morph: SpriteKit vs Rive for one letter (latency, authoring effort, app size, Android reuse); research Unity as a Library + LibGodot from official sources (Kids/COPPA data, licence) | spike | game-dev-ios (review: game-dev-android) | DONE `db66f74` (report design/tech/TASK-033-anim-runtime.md): SpriteKit + MorphCore, no Rive, no engine-as-library; child lock-in. game-dev-android APPROVED (Kotlin port matched the fixture bit for bit). Merged 2026-11-17; ADR-0001 changes → TASK-035 | `spike/TASK-033-anim-runtime` | 2026-11-17 |
| TASK-034 | Research: Apple Kids category + COPPA rules for an opt-in weather feature (network + location) behind the parent gate in a kids app; what is allowed, what consent, which APIs (e.g. WeatherKit) and data flows are acceptable; official sources only | qa | game-qc-ios | DONE `759f8b3`, merged 2026-11-17. Luan chose weather by hand, no network (K-08 revised) | `qa/TASK-034-kids-weather-rules` | 2026-11-17 |
| TASK-035 | Update ADR-0001 with TASK-033's six changes (MorphCore + fixture contract; baked glyphs + SVG silhouettes; third-party runtime rule incl. Rive loadCdn; rejected alternatives; child lock-in; audio note) + art bible §8 SVG rendering open question; Proposed → ready for Luan's Accepted | adr | game-dev-ios (review: game-dev-android) | SENT 2026-11-17: plan first | `docs/TASK-035-adr-0001-update` | 2026-11-17 |

## Leader log

- 2026-11-17: Luan started the new game. Brief, board and decisions written; TASK-029…032 sent.
  Plans only this round: no app code until Luan picks K-01 and approves the tech plans.
- 2026-11-17: K-00: Luan chose the original studio process; the game folder became its own
  studio project (links `.claude/` + `CLAUDE.md`, own `project.yaml`). K-03: fully native, Apple
  first (iPadOS + macOS). TASK-029…032 paused, wip pushed. Next: the leader restarts in the game
  folder and runs /start → /brainstorm with Luan.
- 2026-11-17: /start (stage Concept, rigor standard, goal mobile, automation guided) and
  /brainstorm open with Luan: concept **Letter Morph** written to `design/gdd/game-concept.md`.
  Decided K-01 (2D first), K-02 (English first), K-05 (US, letter name + word), K-06 (concept);
  K-03 reaffirmed (native Swift, not Unity). Next: /setup-engine → /prototype → /art-bible.
- 2026-11-17: /setup-engine: ADR-0001 native Apple (Swift, SpriteKit in SwiftUI, one `apple/`
  project, KidCore, min OS 26), Proposed; commented engine block in project.yaml. Luan asked about
  combining a graphics engine with native: TASK-033 spike sent to game-dev-ios. Next: /prototype.
- 2026-11-17: /prototype letter-morph-dinosaur: one-shot + iterations 1–2 (hint letters, keys locked,
  Dinosaurs theme for A–Z and 0–9). Luan's verdict: PROCEED (Keep: the dinosaur parade). Worst:
  OS shortcuts switch app / steal focus: a native-app requirement (child lock-in). K-07 decided.
  Next: /art-bible.
- 2026-11-17: /art-bible sections 1–3 written. TASK-034 done and merged; K-08 revised: weather picked by hand, no network.
- 2026-11-17: TASK-033 merged (Luan). Art bible sections 4–8 written. TASK-035 sent.
