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
| TASK-035 | Update ADR-0001 with TASK-033's six changes (MorphCore + fixture contract; baked glyphs + SVG silhouettes; third-party runtime rule incl. Rive loadCdn; rejected alternatives; child lock-in; audio note) + art bible §8 SVG rendering open question; Proposed → ready for Luan's Accepted | adr | game-dev-ios (review: game-dev-android) | CODE REVIEW: done `d615b2d` (ADR-0001 updated, morph-contract-v1.md, content/fixtures/morph-contract-v1.json); APPROVED by game-dev-android at `d568f04` (quirks A+B fixed; Kotlin port matched all cases 0.0). Merged 2026-11-18; ADR-0001 → Accepted (Luan) | `docs/TASK-035-adr-0001-update` | 2026-11-17 |
| TASK-036 | GDD: Key Table & Theme Data (`design/gdd/key-table-theme-data.md`) via /design-system | design | game-art-content (review: game-dev-ios) | DONE `c7ef996`, merged 2026-11-18 (review: game-dev-ios APPROVE after one fix) | `design/TASK-036-gdd-key-table` | 2026-11-18 |
| TASK-037 | GDD: Input & Key Filter (`design/gdd/input-key-filter.md`) via /design-system | design | game-dev-ios (review: game-dev-android) | DONE `6b3dbe2`, merged 2026-11-18 (review: game-dev-android APPROVE after A+B) | `design/TASK-037-gdd-input-key-filter` | 2026-11-18 |
| TASK-038 | GDD: MorphCore (`design/gdd/morphcore.md`) via /design-system | design | game-dev-android (review: game-dev-ios) | DONE `89fb1cc`, merged 2026-11-18 (review: game-dev-ios APPROVE) | `design/TASK-038-gdd-morphcore` | 2026-11-18 |
| TASK-039 | GDD: Settings Store (`design/gdd/settings-store.md`) via /design-system | design | game-dev-android (review: game-dev-ios) | DONE `7897eff`, merged 2026-11-18 (review: game-dev-ios APPROVE) | `design/TASK-039-gdd-settings-store` | 2026-11-18 |
| TASK-040 | GDD: Privacy & Kids Compliance (`design/gdd/privacy-kids-compliance.md`) via /design-system | design | game-qc-ios (review: game-qc-android) | DONE `8a729d8`, merged 2026-11-18 (review: game-qc-android APPROVE after REVISE); Luan calls L-01…L-09 open | `design/TASK-040-gdd-privacy-compliance` | 2026-11-18 |
| TASK-041 | GDD: Audio & Voice (`design/gdd/audio-voice.md`) via /design-system | design | game-art-content (review: game-dev-ios) | DONE `bdd3ae7`, merged 2026-11-18 (review: game-dev-ios APPROVE after rework) | `design/TASK-041-gdd-audio-voice` | 2026-11-18 |
| TASK-042 | Key Table follow-ups: launch case for a failing stored theme; per-line voice duration + validator; back-references to Audio & Settings | design | game-art-content (review: game-dev-ios) | DONE `295099d`, merged 2026-11-18 (APPROVE; V15 priming note as follow-up) | `design/TASK-042-key-table-followups` | 2026-11-18 |
| TASK-043 | GDD: Press Queue (`design/gdd/press-queue.md`) via /design-system | design | game-dev-android (review: game-dev-ios) | DONE `5a8aa5f`, merged 2026-11-18 (review: game-dev-ios APPROVE) | `design/TASK-043-gdd-press-queue` | 2026-11-18 |
| TASK-044 | GDD: Cast Rendering (`design/gdd/cast-rendering.md`) via /design-system | design | game-dev-ios (review: game-dev-android) | DONE `c05bdda`, merged 2026-11-18 (review: game-dev-android APPROVE after REVISE) | `design/TASK-044-gdd-cast-rendering` | 2026-11-18 |
| TASK-045 | Art bible K-16 amendments (stardust + parade-bob exceptions, per-part groups with pivots, Reduce Motion softening, 240 particles, SVG subset pointer) | design | game-art-content (review: game-dev-ios) | DONE `87b6af6`, merged 2026-11-18 (review: game-dev-ios APPROVE) | `design/TASK-045-art-bible-k16` | 2026-11-18 |
| TASK-046 | GDD: Parade (`design/gdd/parade.md`) via /design-system | design | game-art-content (review: game-dev-android) | DONE `155d1f3`, merged 2026-11-18 (review: game-dev-ios APPROVE after REVISE) | `design/TASK-046-gdd-parade` | 2026-11-18 |
| TASK-047 | GDD: Hint Letters (`design/gdd/hint-letters.md`) via /design-system | design | game-dev-android (review: game-qc-android) | CODE REVIEW: done `78a5b50` (lean NEEDS REVISION → fixed); game-qc-android independent read | `design/TASK-047-gdd-hint-letters` | 2026-11-18 |
| TASK-048 | GDD: Parent Gate & Grown-up Panel (`design/gdd/parent-gate-panel.md`) via /design-system | design | game-qc-ios (review: game-qc-android) | IN PROGRESS: PLAN APPROVED 2026-11-18 after REVISE (K-20, K-21) | `design/TASK-048-gdd-parent-gate-panel` | 2026-11-18 |
| TASK-049 | GDD: Reveal Stage (`design/gdd/reveal-stage.md`) via /design-system | design | game-dev-ios (review: game-dev-android) | CODE REVIEW: done `b76fa21` (lean APPROVED); game-dev-android independent read (after TASK-047) | `design/TASK-049-gdd-reveal-stage` | 2026-11-18 |
| TASK-050 | Cross-GDD follow-ups: Key Table peek resolve; Press Queue hasWord + Parade F2 + gate freeze; Input R8 origin + R6 exact chord + challenge; Audio late-art/hasWord; Settings Store childLock reverts ON at launch (K-21); Input gate-challenge state | design | game-art-content (review: game-dev-ios) | SENT 2026-11-18 | `design/TASK-050-cross-gdd-followups` | 2026-11-18 |
| TASK-051 | GDD: App Shell & Title (`design/gdd/app-shell-title.md`) via /design-system | design | game-dev-ios (review: game-dev-android) | SENT 2026-11-18 | `design/TASK-051-gdd-app-shell-title` | 2026-11-18 |

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
- 2026-11-17: /art-bible complete (9 sections, AD-ART-BIBLE skipped, lean). Next: /map-systems.
- 2026-11-17: /map-systems: design/gdd/systems-index.md (20 systems; MVP 14; one GDD per system). Next: /gate-check systems-design.
- 2026-11-18: /gate-check systems-design: CONCERNS (concept not reviewed + lags K-07/K-08; MVP schedule; ADR-0001/iPad for Pre-Production). Luan: run /design-review first; stage stays Concept.
- 2026-11-18: /design-review game-concept.md: NEEDS REVISION → revised (K-07/K-08, art bible, prototype features). TASK-035 approved by game-dev-android.
- 2026-11-18: /gate-check systems-design re-run: PASS (TD READY, Producer READY). Stage → Systems Design. TASK-035 merged; ADR-0001 Accepted by Luan.
- 2026-11-18: ADR-0001 Accepted (merged). Systems Design started: TASK-036/037/038 (first three GDDs) sent.
- 2026-11-18: Luan decided K-09 (theme content), K-10 (input), K-11 (morph). TASK-036/037 plans approved; TASK-038 drafted.
- 2026-11-18: TASK-036 (Key Table) and TASK-038 (MorphCore) merged; systems index updated (2/14 MVP approved). K-09 picks (P = Tapejara, X exception) and title-screen rule recorded.
- 2026-11-18: next GDDs in design order sent: TASK-039 Settings Store, TASK-040 Privacy & Kids Compliance, TASK-041 Audio & Voice.
- 2026-11-18: TASK-037 merged (3/14 MVP GDDs approved); ADR-0001/art-bible sil_….json wording clarified (merged).
- 2026-11-18: TASK-039/040/041 plans approved; Luan decided K-12 (settings) and K-13 (audio).
- 2026-11-18: TASK-039 Settings Store merged (4/14 MVP). Follow-ups: Settings touch-up (volume preview, .debug logs, restoration switches) → game-dev-android; Key Table §5 launch case → game-art-content; startPlay during theme load → App Shell GDD.
- 2026-11-18: Settings Store touch-up merged (K-14). GDD status lines set to Approved for the 4 merged GDDs.
- 2026-11-18: TASK-041 Audio & Voice merged (K-14), 5/14 MVP GDDs approved. Note for the voice render: "double you" may approach letter_len_max_s 1.0 s.
- 2026-11-18: next GDDs sent: TASK-043 Press Queue, TASK-044 Cast Rendering.
- 2026-11-18: TASK-042 merged (K-14). Press Queue decisions (Luan): panel open clears queue; background clears queue + creature settled; Reduce Motion hold stays 3 s; ignored hint stays.
- 2026-11-18: K-16 cast rendering choices; TASK-043 done (review); TASK-040 rework; V15 priming note awaiting confirm. Art bible needs a note for the K-16 stardust exception.
- 2026-11-18: V15 priming note and TASK-043 Press Queue merged (K-14), 6/14 MVP GDDs approved. TASK-044 plan approved; TASK-045 art bible amendments in peer check; TASK-040 rework in review.
- 2026-11-18: next GDDs sent: TASK-046 Parade (game-art-content), TASK-047 Hint Letters (game-dev-android). TASK-040 rework diff to game-qc-android.
- 2026-11-18: TASK-040 Privacy & Kids Compliance merged (K-14), 7/14 MVP GDDs approved. Store/legal calls L-01…L-09 go to Luan.
- 2026-11-18: Luan decided K-17 (Parade: every 6, per theme), K-18 (Hint Letters), K-19 (Parent gate: words-number step 2). TASK-045 merged (K-14). TASK-044 done → game-dev-android read. TASK-049 Reveal Stage sent.
- 2026-11-18: TASK-044 Cast Rendering merged (K-14), with the MorphCore when/look ownership split; 8/14 MVP GDDs approved.
- 2026-11-18: Luan decided K-20 (gate: moon sleeps 10 s + 4 number words; challenge freezes play; stage fit extends sky/ground; reveal Reduce Motion softens). TASK-046 Parade done → game-dev-ios read. TASK-049 plan approved.
- 2026-11-18: K-21 (gate risk corrected to ≤0.1%/h realistic, ~3%/h nonstop; Mac child lock OFF reverts at launch). TASK-047 and TASK-048 plans approved. TASK-046 rework after game-dev-ios read.
- 2026-11-18: TASK-046 Parade merged (K-14), 9/14 MVP GDDs approved. Nit for TASK-050: Parade Interface 6 cites a non-existent Press Queue "R8a" → point at Reveal Stage R8 / the new play-clock rule.
