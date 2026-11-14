# Team board

Open decisions for Luan: `production/team/decisions.md`.

Fallback tracker until GitHub Issues are enabled on `ndl0986/Claude-Code-Game-Studios-fork`
and `gh` has write access (`.claude/skills/game-team-lead/SKILL.md` § 1). Each task moves to
an issue once Issues are on. The leader owns this file.

| ID | Task | Type | Owner | Status | Branch | Updated |
|---|---|---|---|---|---|---|
| TASK-001 | `/brainstorm`: game concept for the Vietnamese-heroes mobile game | design | game-dev-ios | done (merged `b41d157`) | `design/TASK-001-game-concept` @ `6dcf8ba` | 2026-11-14 |
| TASK-002 | `/setup-engine godot`: pin Godot 4 for the game (SHELVED 2026-11-14: Luan chose native per platform) | setup | game-dev-ios | done (awaiting merge; Luan's installs pending) | `setup/TASK-002-engine-godot` @ `dda2ca7` | 2026-11-14 |
| TASK-003 | `/prototype --path html`: one side-scrolling Trần Quốc Toản mission (placeholder beats) + quiz | dev | game-dev-android | CLOSED as design reference (Luan stopped browser testing 2026-11-14; Android r3 partial, iOS not run) | `proto/TASK-003-mission-prototype` @ `203d73e` | 2026-11-14 |
| TASK-004 | `/art-bible` draft + Trần Quốc Toản mission beats and quiz, sourced | design | game-art-content | MERGED (`2f6e661`); claims C01–C11 pending (decisions D-03) | `design/TASK-004-art-bible-tqt-beats` @ `4d7aca2` | 2026-11-14 |
| TASK-005 | ADR: native per platform (Swift iOS, Kotlin Android); shared content as data in content/; project.yaml engine block | design | game-dev-ios | MERGED (`908e2e9`); ADR-0001 Accepted | `docs/TASK-005-adr-native` | 2026-11-14 |
| TASK-006 | Native vertical slice (iOS): Swift + SpriteKit (SwiftUI shell), ios/, XCTest; spec = prototype 203d73e | dev | game-dev-ios | building (plan approved + parity rules P-04) | `feat/TASK-006-ios-native` | 2026-11-14 |
| TASK-007 | Native vertical slice (Android): Kotlin + Android SDK, android/, JUnit | dev | game-dev-android | first build `bfe3890` plays the real hero (42 tests, release gate works); QC r1 + code review running; next: full structure (D-08 B) + skip/medal (D-07) | `setup/TASK-007-android-kotlin` | 2026-11-14 |
| TASK-008 | `/map-systems` + key system GDDs | design | game-art-content | MERGED (`383d90c`): index + 4 approved slice GDDs; next `/review-all-gdds` (after TASK-009), then hero progression | `design/TASK-008-systems` | 2026-11-14 |
| TASK-009 | Trần Quốc Toản real content as data (mission, quiz, claims pending; 16 placeholder pictures; mission-full in content/drafts/) | content | game-art-content | MERGED (`f80b595`); validated by game-dev-ios | `content/TASK-009-tqt-data` | 2026-11-14 |
| TASK-010 | `/review-all-gdds` across the 4 slice GDDs | design | game-art-content | MERGED: CONCERNS, 0 blockers; fixes C1–C5, S2 applied; D-13..D-15 to Luan | `design/TASK-010-gdd-review` | 2026-11-14 |
| TASK-011 | Slice plays the full structure (D-08 B): promote mission-full to data; skip + medal strings (D-07) | content | game-art-content | next | `content/TASK-011-tqt-full-beats` | 2026-11-14 |
| TASK-005b | Tuning parity keys (19) in content/data/tuning.json | data | game-dev-android | MERGED (`012114c`) | `data/TASK-005b-tuning-parity` | 2026-11-14 |
| TASK-005c | 24 UI strings VI/EN in content/data/strings.json | data | game-dev-android (+ art-content review) | MERGED (`a2109fe`) | `data/TASK-005c-ui-strings` | 2026-11-14 |
| TASK-005d | Schema 1.1: beat params (D-06), R13–R16, tuning (D-09), quiz fixes (D-11), rng + quiz-shuffle fixtures | data | game-dev-android (+ ios review, art ACK) | MERGED (`3074d43`) | `data/TASK-005d-beat-params` | 2026-11-14 |
| TASK-003b | Mission beat types from TASK-004: Special button, walk / hold-meter / training / reach-the-flag beats, arrows; BEAT_TYPES dispatch table first; art fixes: wrong-answer #9C8FB8 + circular-arrow icon, tangerine attack icon (not a pickaxe), vermilion only as a tunic accent; quiz to 5 questions once claims are signed | dev | unassigned | CANCELLED (browser); beat types and art fixes move to native tasks | — | 2026-11-14 |

## Team changes

**Platform owners (Luan, 2026-11-14):** game-dev-ios = iOS, game-dev-android = Android. Shared game code goes to whichever dev is free.

| Item | Status | Blocks |
|---|---|---|
| New member `game-art-content` (Claude session): art designer + content/history; drafts each hero's mission beats with sources. History sign-off: Luan | Worktree ready; start with `tools/team/start-game-art-content.sh` | Final content for Trần Quốc Toản (MVP hero) until Luan signs off |

## TASK-001: Game concept

- **Goal:** turn Luan's idea into the written concept that later steps build from.
- **Idea (Luan's words):** "a mobile game about Vietnamese historical figures, the player targeting is
  starting from primary school level in Vietnam, they are able to learn about all heroes in the
  historical by playing the missions which are based on their main or famous stories".
- **Inputs:** `production/project-plan.md`, `project.yaml` (stage Concept, rigor standard, goal mobile).
- **Output:** `design/gdd/game-concept.md` (or what `/brainstorm` writes at rigor standard).
- **Acceptance:**
  - core loop, mission structure (one mission = one hero's famous story) and learning goals are written;
  - the audience is primary-school children in Vietnam: reading level, session length, safety;
  - Vietnamese first, English second; Android + iOS phones, touch-first;
  - the hero and event list is a placeholder until the team's history material and reviewer arrive;
  - Luan approved the concept (design and content decision: § 4 escalation).
- **QC:** none (design doc, no build). Android and iOS QC skipped.

**Result (2026-11-14):** `design/gdd/game-concept.md` written and approved by Luan. Concept
"Dải Đất Anh Hùng (Land of Heroes)": a map of Vietnam, one story-first, light-action mission
per hero, then a 3–5 question quiz that upgrades a hero card. Committed `a4ac513`; not pushed,
not merged. Acceptance: all 5 met (per the dev's check). Lean review skipped the director
gates (CD-PILLARS, AD-CONCEPT-VISUAL, TD-FEASIBILITY, PR-SCOPE).

**Decided (Luan, 2026-11-14, `c48a634`):** storybook content ships in timed app updates on a
content calendar with store-review lead time; fully offline, no content server; daily pages
bundled and unlocked by device date.

**Decided (Luan, 2026-11-14, `266f2f8`):** first (MVP) hero is Trần Quốc Toản; heroes are added
one at a time in historical order, and the map shows where each story happened. Mission story
beats are left out of the concept: the content member writes them.

**Decided (Luan, 2026-11-14, `ffcab9b`):** not a card game. A 2D game with side-scrolling
missions and simple actions (attack, defend, …); passing the quiz unlocks the next hero. Hero
cards and the album are removed.

**Handover (`6dcf8ba`):** `production/team/handover-TASK-001-to-art-content.md`, sent to
game-art-content, which now owns art direction and story content.

**Decided (Luan, 2026-11-14, relayed to game-art-content):** sources: primary-school SGK Lịch sử
first, then Đại Việt sử ký toàn thư; tradition details labelled legend. Trần Quốc Toản's death:
one calm line in the ending, no scene. Landscape for missions, menus and the map until the phone
prototype confirms it. Art references: game-art-content proposes 3–5, Luan picks.

**Open questions for Luan:** monetization; "weeks" covers the MVP only, not a store release.

## TASK-002: Engine setup

- **Goal:** pin Godot 4 (Luan's go, 2026-11-14) with `/setup-engine godot`: `project.yaml` engine block, `docs/engine-reference/`, the engine table rows.
- **Acceptance:** engine and version pinned in `project.yaml`; engine reference written; what must be installed (Godot, export templates, Android build tools/NDK, Java 21) listed for Luan as install steps. **The dev installs nothing**: installs are Luan's.
- **QC:** none (config). Peer review of the plan by game-dev-android.

## TASK-003: Mission prototype (browser)

- **Goal:** a playable browser prototype of one side-scrolling mission: move / attack / defend buttons, 3–4 ⟨placeholder⟩ beats, then a 3–5 question quiz that unlocks the next hero. Landscape, touch-first, VI default with an EN switch.
- **Acceptance:** plays on a phone screen in landscape; every control usable with a thumb; no violence beyond non-violent knock-back; all history text marked ⟨placeholder⟩ (content comes from TASK-004).
- **QC:** Android (Chrome on emulator `mp17863`) now; iOS NOT ASSESSED until a Simulator runtime is installed. Content review by game-art-content.

## TASK-004: Art bible + Trần Quốc Toản content

- **Goal:** `/art-bible` draft with 3–5 proposed references for Luan to pick; Trần Quốc Toản's 3–4 mission beats and 3–5 quiz questions, VI then EN, every claim cited and labelled fact / interpretation / legend / invented.
- **Sources (Luan):** primary-school SGK Lịch sử first, then Đại Việt sử ký toàn thư. Death: one calm line in the ending. Landscape.
- **Acceptance:** Luan picks the references and signs off the history (`content:approved`) before anything is final.
- **QC:** none (design docs).

**Decided (Luan, 2026-11-14):** TASK-003 ships as approved (4 combat beats, move/attack/defend);
TASK-004's extra beat types go to TASK-003b. Quiz stars: retry until right (3★ all first try,
2★ up to 2 retries, 1★ finished; finishing always unlocks the next hero).

**TASK-004 sign-off (Luan, 2026-11-14):** references kept: Đông Hồ / Đông Sơn motifs and Kim Đồng
picture books; Rayman, Kirby and Cartoon Saloon rejected. All 4 art rules approved. C06/C08 become
"fact (as the chronicle records it)" only if the Toàn thư 1282 passage confirms them. The 4-beat
structure is approved for TASK-003b. Still pending: claims C01–C11 and the source locations.

**TASK-002 result:** Godot 4.7.2, GDScript, Compatibility, sensor landscape; `project.godot` NOT VERIFIED
until Luan installs Godot and a headless import runs.

**Decided (Luan, 2026-11-14):** build the real game native per platform: iOS in Swift + SpriteKit
(game-dev-ios), Android in Kotlin (game-dev-android). Godot is shelved; the TASK-002 branch is kept, not
merged. Missions, quiz and VI/EN text are shared as data (TASK-005). The browser prototype stays as
the design reference.

**Decided (Luan, 2026-11-14):** stop all browser testing. TASK-003 closed as the design reference at `203d73e`; TASK-003b cancelled. QC moves to the native apps (TASK-006 iOS, TASK-007 Android).

**Decided (Luan, 2026-11-14):** skip the cross-platform version; TASK-006/007 rebuild the full first
mission natively on each platform, then QC tests the native builds. Android draws with pure Android
(Kotlin + Android SDK: SurfaceView/Canvas game loop, SoundPool), no game framework.

**Decided (Luan, 2026-11-14):** Android compileSdk/targetSdk 35 for now; **pre-release item:** raise to 36 (Play requires it for new apps and updates since 2026-08-31) and install `platforms;android-36` + `build-tools;36.0.0` before any Play upload. kotlinx.serialization approved as the Android app's one dependency. Emulator mp17863 is owned by game-qc-android (start/stop/wipe); devs only install, launch, log and screenshot. It was stopped from outside 3 times on 2026-11-14 (not by the game team): watch for another team's cleanup.

**Decided (Luan, 2026-11-14): follow the studio pipeline.** TASK-006/007 are a **native vertical slice**
of one mission (not yet the production codebase). In parallel TASK-008 runs `/map-systems` + the key
GDDs. Then `/gate-check`, and the full build goes through `/create-epics`, `/create-stories` and
`/sprint-plan`. Where the template has no native-engine support (setup-engine, engine specialists,
test-setup, smoke-check), those checks report NOT ASSESSED by design (ADR-0001).
