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
| TASK-006 | Native vertical slice (iOS): Swift + SpriteKit, ios/, XCTest | dev | game-dev-ios | full structure + D-07 + D-16 built (61 tests); frozen build `b9c946b`; iOS QC r1 + code review (game-dev-android) running | `feat/TASK-006-ios-native` | 2026-11-14 |
| TASK-007 | Native vertical slice (Android): Kotlin + Android SDK, android/, JUnit | dev | game-dev-android | QC r2 closed FAIL (B1/B3/B4, fixed); **frozen r3 `77c862c`** (89 tests, incl. the Bình Than dialogue + G2) in QC r3 | `setup/TASK-007-android-kotlin` | 2026-11-14 |
| TASK-008 | `/map-systems` + key system GDDs | design | game-art-content | MERGED (`383d90c`): index + 4 approved slice GDDs; next `/review-all-gdds` (after TASK-009), then hero progression | `design/TASK-008-systems` | 2026-11-14 |
| TASK-009 | Trần Quốc Toản real content as data (mission, quiz, claims pending; 16 placeholder pictures; mission-full in content/drafts/) | content | game-art-content | MERGED (`f80b595`); validated by game-dev-ios | `content/TASK-009-tqt-data` | 2026-11-14 |
| TASK-010 | `/review-all-gdds` across the 4 slice GDDs | design | game-art-content | MERGED: CONCERNS, 0 blockers; fixes C1–C5, S2 applied; D-13..D-15 to Luan | `design/TASK-010-gdd-review` | 2026-11-14 |
| TASK-011 | Slice plays the full structure (D-08 B): full mission in data; skip + medal strings (D-07) | content | game-art-content | MERGED; validated by game-dev-ios | `content/TASK-011-tqt-full-beats` | 2026-11-14 |
| TASK-012 | Hero progression & medal GDD + mission-flow D-07/parity updates | design | game-art-content | MERGED (`da7435c`), peer-approved by game-dev-android | `design/TASK-012-progression-medal` | 2026-11-14 |
| TASK-014 | `/asset-spec` for the vertical slice | design | game-art-content | MERGED (`2c15f03`): 87 asset specs + manifest + D-18 look sheet; final art waits for D-18 | `design/TASK-014-asset-spec` | 2026-11-14 |
| TASK-015 | GDDs: Language & text, Save & progress, Audio & voice-over | design | game-art-content | MERGED (`60e779a`) | `design/TASK-015-gdds` | 2026-11-14 |
| TASK-016 | Bình Than scene (D-25): shorter walk + asking-to-join dialogue + orange; script, dialogue beat, schema 1.4, data, portrait specs | design | game-art-content | MERGED (GDD `d113f7d`, schema `c6004a8`, data `23699c4`); apps building the dialogue beat | `design/TASK-016-binhthan-scene` | 2026-11-14 |
| TASK-017 | G2 fight-zone, auto-face, swing facing (reach-the-flag fix) | design | game-art-content | MERGED (`b9f8544`) | `design/TASK-017-fight-zone` | 2026-11-14 |
| TASK-018 | Map & timeline GDD (modern map incl. Hoàng Sa, Trường Sa; hero pins; timeline; QC G5) | design | game-art-content | MERGED (`5218e2f`); map art waits for D-28 | `design/TASK-018-map` | 2026-11-14 |
| TASK-019 | Input & touch controls GDD (safe rect + mandatory gesture insets, per-pointer identity, first-owner, keep-pad-until-up, clear-all, debounce, dropped input) + Hints Rule 3 step order | design | game-art-content (+ android review) | MERGED (`5741e91`); vertical-slice GDDs 10/10 approved | `design/TASK-019-input` | 2026-11-14 |
| TASK-013 | Full-screen layout on both apps: backdrop + HUD to the screen edges, gameplay stays 1280×720 (fixes the 20:9 letterbox) | dev | both devs | after the slice's first QC pass | — | 2026-11-14 |
| TASK-005b | Tuning parity keys (19) in content/data/tuning.json | data | game-dev-android | MERGED (`012114c`) | `data/TASK-005b-tuning-parity` | 2026-11-14 |
| TASK-005c | 24 UI strings VI/EN in content/data/strings.json | data | game-dev-android (+ art-content review) | MERGED (`a2109fe`) | `data/TASK-005c-ui-strings` | 2026-11-14 |
| TASK-005d | Schema 1.1: beat params (D-06), R13–R16, tuning (D-09), quiz fixes (D-11), rng + quiz-shuffle fixtures | data | game-dev-android (+ ios review, art ACK) | MERGED (`3074d43`) | `data/TASK-005d-beat-params` | 2026-11-14 |
| TASK-005e | R13 without special on reach-the-flag, dummy_spacing, dialog budget 60 | data | game-dev-android (+ ios review) | MERGED (`3861c09`) | `data/TASK-005e-slice-keys` | 2026-11-14 |
| TASK-005f | R17 unique timeline_order, R18 next_hero by index order | data | game-dev-android (+ ios review) | MERGED | `data/TASK-005f-r17-r18` | 2026-11-14 |
| TASK-005g | ADR-0002 follow-up: themes.json sky bands, assets width/height (schema 1.2), R19a/R19b/R20 | data | game-dev-ios (+ android review) | MERGED | `data/TASK-005g-assets-themes` | 2026-11-14 |
| TASK-005j | Shared sim trace fixture content/fixtures/trace-tqt.json (cross-app parity; Android generates + replays) | data | game-dev-android (+ ios replay) | MERGED (`b661802`); iOS replay test after iOS r3 freeze | `data/TASK-005j-trace` | 2026-11-14 |
| TASK-005k | pad_gap + drag_threshold tuning keys (TASK-019), no schema change | data | game-dev-android (+ ios load-check) | MERGED | `data/TASK-005k-input-keys` | 2026-11-14 |
| TASK-020 | /review-all-gdds across the 11 approved GDDs (independent reader) | design | game-dev-android (fixes: art-content) | MERGED report (1c1edc4): FAIL, 2 doc-only blockers, 21 W, 15 A; Luan items → D-31..D-35; GDD fixes → TASK-020a | `design/TASK-020-gdd-review` | 2026-11-14 |
| TASK-020a | Apply TASK-020 GDD fixes (B1 Hints dialogue row, B2 beatX/F5 everywhere, GDD-tagged warnings/advisories) | design | game-art-content (+ android review) | MERGED (`abd7b72`); blockers B1/B2 fixed; app tickets queued post-QC | `design/TASK-020a-gdd-fixes` | 2026-11-14 |
| TASK-005l | Data: per-beat `cheer` (schema 1.5 MINOR), R8d text_limits.min_px + class (banner 28→37), R14b training-zone guard | data | game-dev-android (+ ios review) | MERGED (bcbe6b8); trace 1.1 (005m) MERGED (f2f4f74), green on both cores | `data/TASK-005l-*` | 2026-11-14 |
| TASK-023 | App tickets from TASK-020a (both apps): 15b training camera cap (+trace regen), W7 pause top-left, W12 pads per step, W17 fist icon, W18 leave card, W19 title disabled until preload, W20 skip icons, W21 cheer | dev | both devs | after each app's QC round | — | 2026-11-14 |
| TASK-021 | UX specs for slice screens + design/accessibility-requirements.md + interaction-patterns | design | game-art-content (+ ios review) | MERGED (`a3fed9d`); card rule ink on pale fill; apps update after QC r3 | `design/TASK-021-ux` | 2026-11-14 |
| TASK-022 | Architecture blueprint (/create-architecture) + critical-ADR list; then ADR-0003 save (Proposed) | docs | game-dev-ios (+ android review) | MERGED (31a6b0a); approved by game-dev-android; ADR-0003 Proposed → Luan (D-30) | `docs/TASK-022-architecture` | 2026-11-14 |
| TASK-003b | Mission beat types from TASK-004: Special button, walk / hold-meter / training / reach-the-flag beats, arrows; BEAT_TYPES dispatch table first; art fixes: wrong-answer #9C8FB8 + circular-arrow icon, tangerine attack icon (not a pickaxe), vermilion only as a tunic accent; quiz to 5 questions once claims are signed | dev | unassigned | CANCELLED (browser); beat types and art fixes move to native tasks | — | 2026-11-14 |
| TASK-024 | Concept fixes for the Concept → Systems Design gate: native-stack technical sections, concept /design-review, stale text, Luan as history reviewer, D-14 A + D-35 A. **Committed as TASK-022, 022b–022e** (ID collided with the architecture TASK-022) | design | game-art-content | MERGED (`3f61e4b`, `8a54606`, `ef25ac5`, `3f41886`, `523421d`); gate PASS 2026-11-17 | `design/TASK-022*-concept-*` | 2026-11-17 |
| TASK-025 | Start-screen map (D-36): Map & Hometowns GDD, `design/ux/start-map.md`, claims C17–C20, schema MINOR (places.json, hero.hometown). **Branch named TASK-021** (ID collided with the UX TASK-021) | design | game-art-content | pushed `522d833`, not merged; waits on a dev review of the schema MINOR + D-36 (e)–(g); build after the VS gate | `design/TASK-021-start-map` | 2026-11-16 |
| TASK-026 | TestFlight prep (iOS): Release config, version 0.1.0, bundle ID (Luan), app icon slot, PrivacyInfo, export compliance, App Store Connect answers, Luan's click-steps + archive/upload commands; placeholder icon from game-art-content (+ Android adaptive icon) | dev | game-dev-ios (+ art-content icon) | plan requested; signing/upload wait for Luan's Apple Developer enrollment | `feat/TASK-026-testflight-prep` | 2026-11-17 |

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

**After Android QC r3 (dev-android):** first-owner tie-break in PadHolds; 4% press squash; noisy/route clear; pad_gap (TASK-005k); rounded-corner insets (TASK-013); merge b661802 so TraceTest runs.
**iOS QC r3 (2026-11-14):** 9b0470a CLOSED FAIL (evidence qa/TASK-006-ios-r3 @ 9e412fe): R2-03 still sticks ~1/3 with moves; R3-02..06 layout + empty intro pictures. dev-ios fixing → r4. Trace replay: iOS matches Android on all 149 snapshots (GameCore 73). After iOS r3: second-pointer-ignored fix in TouchPads (TASK-019 Rule 6).
**Leader correction (2026-11-14):** clear-all follows Input GDD Rule 11 only (cancel, focus loss, pause, background, audio route). A screen/beat change cancels only a pressed menu button, not held pads. iOS r3 over-clears on phase change; relax after r3.
**Training softlock (2026-11-14, both apps):** holding ▶ through training strands dummies behind the camera. Fix: lock camera over training area like a fight zone (Combat GDD rule in TASK-020a) → Android implements + regenerates trace after its QC r3 → iOS replays/builds after r4.
**Devices:** QC iOS = iPhone 18 Pro Simulator E9F515E9-58F2-4A92-ABEF-C5CD59CE8183 (QC only). Dev iOS = "iPhone 18 Pro – dev-ios" FB836E51-D39E-42C3-A60E-96159EE6516C via `simdev` (headless, never `booted`). QC Android = emulator-5554 (mp17863). Dev Android = emulator-5556 via `adbdev`.
**Android QC r3 (2026-11-14):** 77c862c CLOSED FAIL (evidence qa/TASK-007-android-r3 @ 69dbe01): B1 double-tap still skips on intro/card/dialogue (3rd round); B3b hint hand on Defend; B5 heading over medallions. All else PASS incl. G2 ≤60 s, Bình Than beat. dev-android r4 plan approved (B1 root cause: sim-clock debounce under frame stalls → press timestamps; parity check sent to iOS).
**Host load:** QC emulator segfaulted 21:05; both iOS simulators dropped. Avoid builds during QC rounds; one dev sim/emulator booted only while in use.
**iOS QC r4 (2026-11-14):** frozen 0602974 (79 tests), app fingerprint c7f62c3e… (computed from the game-dev-001 root, relative path). Press-time debounce fixed on iOS too (same sim-clock bug). game-qc-ios on E9F515E9.
**Android QC r4 (2026-11-14):** frozen c00c5e0 (101 tests), APK sha256 107c882d…1bfc verified. B1 press-time debounce, B3b, B5, first-owner, UX calls, mute saved. game-qc-android on emulator-5554. iOS r4 touch blocked on macOS Accessibility (Luan to toggle Orca Computer Use).
**r5 scope (both apps):** 15b training camera cap (+ trace regen on data/TASK-005m-trace-15b, merge when iOS replays green), 005l code (cheer, R8d, R14b, banner 37), W12 training pads per step, W7 pause/sound top-left. iOS r4 part 1 (non-touch) PASS @ b2463cc; touch waits on Accessibility toggle.
**QC erratum (2026-11-14):** Android r2/r3 B1 FAILs and r2 B4 withdrawn — sendevent taps were 0.55 s apart on the loaded host. New streaming injector (getevent-verified 0.186 s). Rule for QC: record measured input timing with every timing-sensitive case. The press-time debounce fix stays (real stall hole, proven by iOS failing test).
**Android QC r4 PASS (2026-11-14):** c00c5e0, evidence qa/TASK-007-android-r4 @ 2fc436c; kernel-verified input timing (fastmt.py). First Android QC pass. Next: r5 (15b, W12, W7, 005l/n, banner sky band, placeholders at spec height).
**Merged (2026-11-14):** TASK-005n goal box 880; W9 banner sky-band spec (hud.md §3.3, AC9–13). Both apps build in r5.
**Android QC r5 (2026-11-14):** frozen f02c0d6 (107 tests), APK sha256 b5d00847…0283 verified; game-qc-android testing. D-27 A (title hero card) → title.md spec → r6 both apps. D-28 A decided; D-28b map source: art-content proposes.
**iOS QC r5 (2026-11-14):** frozen 1a8c443 (96 tests), app fingerprint 02fb413a… (from game-dev-001 root). Replaces r4 (r4: non-touch PASS, touch NOT ASSESSED). Touch still blocked on Accessibility toggle.
**Merged (2026-11-14):** D-27 title card spec + hud §3.3 k-band (df22e4a). r6 both apps: title card/row/Start, chip at pad_min, plates narrowing for 0.32 ≤ k < 0.48, TASK-005o data.
**iOS touch QC path (2026-11-14):** Device Hub + Accessibility keeps re-blocking. Plan: XCUITest UI-test target (no macOS permission; frozen .xctestrun run by QC via test-without-building on E9F515E9), debug-only `debugState` element; added to iOS r6. Multi-finger cases stay unit tests.
**Android QC r5 PASS with findings (2026-11-14):** f02c0d6, evidence qa/TASK-007-android-r5 @ b6c2e50. 15b, W12, W7, banner AC9–12 PASS; findings B6 (sound button over story frame corner), AC13 strike contact not visible, pop contrast 1.95:1 on camp, banner gold-on-red 2.6:1. iOS r5 part 1 FAIL R5-01 (EN banner overflow). Both → r6 + small spec follow-up.

## Release checklist items (collected; becomes /release-checklist input)
- Claims C01–C16 signed off (D-03); release gate R12 must pass.
- Map content appraisal (thẩm định) by Cục Đo đạc, Bản đồ và Thông tin địa lý — confirm whether it applies (D-28b).
- Minimum supported landscape height ≈ 288 dp after insets (k 0.40; ≥ 512 dp wide); QC's narrowest phone ≥ k 0.40.
- Android targetSdk 35 → 36 before any Play upload.
- D-22 platform backup decision before a Kids-category submission (Android manifest change if "allow").
**Android QC r6 (2026-11-14):** frozen 7790ee9 (107 tests), APK sha256 2fed0ba2…9181. D-27 title card, full-bleed story, pad_min buttons, AC13 contact, outlines, line pitch 1.35 em. Quiz small-k spec merged → r7.
**iOS QC r6 (2026-11-14):** frozen fa163d3 (GameCore 105, app 4, UI 5), app fingerprint 9a3b1bd8…, folder 47303622…. First run of the XCUITest touch harness (tools/qa/ios-touch-tests.sh). Release byte-identical with/without debug harness code.
**iOS QC r6 FAIL (2026-11-14):** fa163d3, evidence qa/TASK-006-ios-r6 @ bc448a0. Touch harness 5/5 PASS (first iOS touch pass: R2-03, slide, hold across beat, B1 @0.050 s, 15b). Bugs: R6-01 flat bar under full-bleed story pictures (home-indicator inset); R6-02 two-line quiz prompt under sound button. → r7.
**Merged (2026-11-14):** B7 screen-entry lock spec (Input Rule 13b, rolling 0.6 s, cap 1.5 s, every ending box; AC17–21). Data 005p merged; 005q (cap key) in ios review. Both apps have r7 code ready; freeze after Android QC r6.
**Android QC r6 FAIL on B7 only (2026-11-15):** 7790ee9, evidence qa/TASK-007-android-r6 @ 9308bd3. B7 also cost a medal (◀ tap landed on Bỏ qua as training card appeared). All else PASS (D-27 title, full-bleed story, dialogue, contrast, AC13, line pitch, regression). Host cleared for r7 builds.
**Android QC r7 (2026-11-15):** frozen ce119bf (117 tests), APK sha256 658826b8…ae26. B7 rolling lock (every ending box, card-entry ◀ case), small-k quiz, skip-warning spacing. iOS r7 building.
**Android QC r7 PASS (2026-11-15):** ce119bf, evidence qa/TASK-007-android-r7 @ 4c03f08. B7 fixed (ending boxes hold ≥1.5 s under mash; card-entry ◀ no skip warning; medal earned under mashing). Open design Q → r8: dialogue lines 2–9 still advance at mash pace.
**iOS QC r7 (2026-11-15):** frozen b53cfde (GameCore 111, app 4, UI touch 10), exe sha256 0cbd2d6f…3294. B7 rolling lock, R6-01/02 fixes, small-k quiz, ink "Đúng rồi!" pill over the picture, 10-case touch harness; Release byte-check clean (no debug symbols). Host: ~300 s XCTest crash-report check per UI case (suite ≈ 60 min). r8 spec (bd97ea8) review by ios: REVISE (table break, placeholder vs beat dots/Part label, arrow edge fallback) → game-art-content.
**r8 spec MERGED (2026-11-15):** 4495f7f (design/r8-picture-arrow-telegraph @ 219f732, approved by game-dev-ios). Rolling lock on every story box + dialogue line; story placeholder portrait (256 / 208, min 192), no play sprites or top stack on story screens; gold stuck arrow + edge fallback; "!" beside head. Both devs: r8 plan first. Android quiz pill already in (4fd6725).
**r8 plans APPROVED (2026-11-15):** iOS (8f09d52 base) and Android (eb88815 base). Leader calls: dialogue screens also drop play sprites; flag hidden on cards/captions; Android adds the "Phần n / Part n" label to match iOS (ios sends source); same small-k quiz threshold. Doc follow-up r8b → game-art-content.
**r8b spec MERGED (2026-11-15):** design/r8b-story-sprites @ e1fda56 (approved by game-dev-android): dialogue AC9 no play sprites, story AC12 extended, part label rule + AC13 (star gold #FFC531, ink outline ≥ 2 px, 28 px).
**Quiz small-k boundary (r8, 2026-11-15):** spec §5.2 "k < 0.48" is wrong — reference cards bottom (422 + P) passes Tiếp top (702 − P) for k < ≈ 0.514 (P = pad_min/k; dev-ios). Android at k 0.488 ran Tiếp ≈ 13 px past 720, also in QC-passed r7 evidence (missed). Fix: both apps use the geometric switch (iOS already; Android adds it in r8 → 5556 small, mp17863 reference); spec fix r8c → game-art-content. r8 QC checks every quiz element bottom ≤ 720 and the small layout at 0.488.
**Leader calls (r8c, 2026-11-15):** corner_bottom = 18 + P on both apps (spec hud §3.3; iOS moves its corner block down 10 px from 8 + P). Geometric quiz switch → small for k < ≈ 0.533, so both reference phones (iOS 0.517, Android 0.488 — corrected) use the small quiz layout; the reference layout is unit-tested. Quiz Tiếp: 340 reference, 450 small. r8c amend → game-art-content.
**r8c MERGED (2026-11-15):** 01c6a3d. **Android QC r8 (2026-11-15):** frozen ea70edb (134 JVM tests), APK sha256 4c1b1bb9…67e8 (leader-checked), gate fails R12 only. Scope: rolling lock every box/line, story/dialogue without play layer + placeholder + part label, cues below the bar, geometric small quiz (mp17863 now small). → game-qc-android.
**iOS QC r7 PASS (2026-11-15):** b53cfde, evidence qa/TASK-006-ios-r7 @ 6c02e5a. Harness 9 pass / 1 skipped (3155 s). B7, R6-01, R6-02, small quiz (iPhone 17e, k ≈ 0.51), pill, regression, AC13 PASS. NOT ASSESSED → r8: ◀ training-card case (tap landed at 0.695 s), medal under mash in a full run, pause/sound exempt during lock, day camp sky pop outline (r5 N1; cream would be 1.28:1).
**Android QC r8 PASS (2026-11-15):** ea70edb, evidence qa/TASK-007-android-r8 @ df537bf. Rolling lock (all 9 Bình Than lines 1.73–1.82 s under 0.35 s mash), small quiz (Tiếp clip fixed), story/dialogue screens, banner cues incl. live flag arrow, ink pop outline, regression (3★ + medal). r9: flag cloth over the banner bar (→ props under bar, as iOS), pop outline by sky (e6cf65a). Open: ASSET-016 ending still missing on both apps (AC12) → game-art-content; mp17863 measured k ≈ 0.488 (not 0.527) → device map to confirm.
**Device k confirmed (2026-11-15):** both Android AVDs (5556 devandroid002, 5554 mp17863) are pixel_7 1080×2400 @ 2.625 → k ≈ 0.488; no Android device at 0.527. iOS QC iPhone 18 Pro 0.517, dev-ios 0.529. **Flag call:** on banner beats the whole goal flag sits below the bar (top ≥ 276), scaled to fit (Android 120); Android red-on-red was cloth behind the 92% bar. Spec r8d → game-art-content; iOS asked for its numbers.
**Flag parity (2026-11-15):** banner-beat goal flag on both apps = box y 290–470 (pole top 290, foot 470); iOS cloth 92×60 separate. Android 0941491 (r9); iOS in r8 before freeze. **Gap → iOS r9:** iOS draws no raised banner on the training finish special (spec: mission-flow training (c), TQT beat 3, ASSET-108); Android draws a placeholder 110 beside the hero (top ≥ 276 on banner beats).
**r8d MERGED (2026-11-15):** design/r8d-ending-still @ e1f7ae7 (approved by game-dev-android): redrawn pic.scene_tqt_ending (subject png y 47–170), ending-only background fallback, AC14 bundle/decode test, flag rule AC18, device k labels, iOS cover-crop margin. Android ending-picture bug (Renderer never read ending.picture_id) → r9 with R10b. iOS draws the ending correctly.
**r8e MERGED (2026-11-15):** docs/r8e-geometry-k @ e3cd4c2 (approved by game-dev-android): device labels, k 0.527 = geometry example only. **Android r9 code done:** e6cf65a pop outline, 0941491 flag, b5df861 ending still + R10b/AC14 (144 JVM).
**Android QC r9 (2026-11-15):** frozen f92e1d2 (145 JVM), APK sha256 439aca57…8020 (leader-checked), gate R12 only (R10b passes). Pop outline by sky, flag 290–470, raised banner beside the hero, ending still + R10b/AC14. → game-qc-android. Design Qs → game-art-content: banner-raise hold time (only a fraction of a second today), hint hand in the bar band, hill-aware pop outline.
**r9 design MERGED (2026-11-15):** design/r9-finish-hint-pop @ 70069fc (approved by game-dev-android): finish_hold 1.5 s on the training beat (beat 4) with partner re-entry and slice placeholder, hints ≥ 276 on banner beats, double pop outline when cream wins. Data TASK-005r (finish_hold) MERGED (9ce9253, approved by game-dev-ios). Builds in r10 on both apps.
**Android QC r9 PASS (2026-11-15):** f92e1d2, evidence qa/TASK-007-android-r9 @ 669cbf8. Ending still, flag 290–470, raised banner clear of the face, pop outlines to spec, full regression (dialogue lines 1.75–1.80 s, 3★ + medal). Observations (all specified for r10): banner visible ≈ 0.57 s, Cờ hint 42 px into the bar, cream pop ≈ 1.5:1 over camp mint hills. Android r10 plan requested.
**Android r10 coded (2026-11-15):** 47a9051 (finish hold, hints ≥ 276, double pop outline; 155 JVM with trace 1.2). **Data TASK-005s trace 1.2** (0704e79, 159 snapshots): Android branch only; merges to docs when iOS r9 replays it green (005m rule).
**Android QC r10 (2026-11-15):** frozen d8403dd (155 JVM incl. trace 1.2 on branch), APK sha256 6f72822b…ee79 (leader-checked), gate R12 only. → game-qc-android. Watch: pause/resume banner-up 0.7 s in dev shot vs AC32 ≥ 0.8 s (dev asked).
**Android QC r10 FAIL on B8 (2026-11-15):** d8403dd, evidence qa/TASK-007-android-r10 @ cdd9987. B8: real flow, hero near the right edge → partner re-enters from the left under the banner (cloth over its face) and faces the hero. All else PASS (hold 1.50–1.52 s, resume → end 0.823 s, hands ≥ 276, double pop, regression). Leader calls → Rule 7c amend (game-art-content) + Android r11 + iOS r9: partner on the hero front side if it fits, else beyond the banner, never overlapping; faces the banner; EVERY resume restarts the hold; training props removed before the next background. Trace → 1.3 (005t), Android branch only until iOS replays.
**r10 design MERGED (2026-11-15):** design/r10-finish-placement @ 48bda7a (approved by game-dev-android): Rule 7c placement, linear outward walk-in (1.2 × enemy_reach) with on-screen fade, every resume restarts, AC32–34 (fallback only near the left edge facing left).
**Android QC r11 (2026-11-15):** frozen 742a230 (157 JVM; trace 1.3 = 005t 2aa5f8a on branch only, supersedes 1.2/005s), APK sha256 2e112eb9…92e9 (leader-checked), gate R12 only. B8 fix (placement, linear walk-in, faces banner, every resume restarts, dummies cleared). → game-qc-android, real-flow B8 retest first.
**Android QC r11 PASS (2026-11-15):** 742a230, evidence qa/TASK-007-android-r11 @ 4321a86. B8 fixed in the real flow (partner in front, no overlap, linear walk-in, hold 1.518 s); case (d) 12 px clear; N=1/2/3 pauses 0.82 s; AC34 no props on the night camp; full regression. Backlog (minor): hero at old screen x for 1 frame on the first night-camp frame; quiz Tiếp idle pulse reaches y ≈ 706/710 shadow (≤ 720, past AC7 702 line) → design to clarify AC7.
**iOS QC r8 (2026-11-15):** frozen c388736 (GameCore 134; UI 6/6 on frozen build, 12+2-fixed/14 on pre-flag build), exe sha256 55913c29…0e35 (leader-checked), Release byte check clean, gate R12. r8/r8b/r8c/r8d spec + flag below bar + r7 NOT ASSESSED cases + SkyContrast. → game-qc-ios. iOS r9 plan requested (Rule 7c + trace 1.3, Hints Rule 6, double outline, AC14, raised banner). Art: ending flag pole top under the corner block → game-art-content.
**Look parity (leader call, 2026-11-15; placeholders pending D-18):** hero raised banner = #D64A2E cloth + ≈ 4 px gold #E8A93B border (Android drew #D9342B, no border); training partner = follower look (tunic #D8C9A3, sash #B9705C, plain topknot, no headband/tails, scale 0.62), not a mini-hero copy (Android today). iOS r9 + Android next round; spec → game-art-content.
**r11 docs MERGED (2026-11-15):** design/r11-ending-pole-ac7 @ be1d08d (approved by game-dev-android): ending pole clear of the corner block, AC7/AC10 at-rest rule, slice looks (banner #D64A2E + #E8A93B border; partner = follower). D-18 (11) added: final follower height.
**Trace 1.3 MERGED (2026-11-15):** data/TASK-005t-trace-1.3 @ 2aa5f8a, green on both cores (Android r11, iOS GameCore 159 snapshots @ 1e-6). Supersedes 1.2/005s (never on docs). iOS GameCore Rule 7c done (FinishHoldTests 7/7). Android r12 plan approved (banner/partner looks, camera cut at the beat change; may need trace 1.4).
**PAUSED (2026-11-15, Luan):** all branches pushed; checkpoint in production/progress.md (top entry). iOS r8 QC stopped incomplete; re-run on resume.
**RESUMED (2026-11-16, Luan):** all 5 members resumed. game-qc-ios re-runs iOS r8 QC (c388736) + open manual items + teardown timing; game-dev-android r12 pre-freeze on 5556 → freeze; game-dev-ios read-only r9 review, no builds during iOS QC; game-qc-android r12 checklist ready, waits for the hash.
**Hint pad-square fix MERGED (2026-11-16):** docs/r12-hint-pad-square @ 26142bc → 0f90158. Hints Rule 6, AC12, hud.md:136: the hand never covers a pad's visible square (touch slop excluded); the hand takes no touches. Wording only.
**D-36 opened (2026-11-16, Luan):** start screen = Vietnam map, pins at heroes' hometowns, tap a place → vertical hero list (short description, info, earned medals). Sub-questions (a)–(d) on recommendations in decisions.md. game-art-content: plan for GDD + UX spec revision (TASK-021). Build after the slice gate (rec. D-36 d A).
**iOS-R8-01 (2026-11-16):** NOT A BUG, test flake (3/3 PASS on re-run); dev-ios hardens the case in r9. **Android 93e2770:** partner 0.62 × hero height (same fix as iOS 162b14c).
**iOS QC r8 DONE (2026-11-16):** qa/TASK-006-ios-r8 @ f887948 on c388736. All assessed items PASS (UI 13/14, the 14th = iOS-R8-01 flake, 3/3 on re-run; 18 Pro quiz layout VI/EN; pill 6.33:1; mash holds ≥ 1.5 s; regression). NOT ASSESSED (no simulator tap: Device Hub AX blocked): quiz glide ≤ 720 in motion, per-question lock, deliberate 0.6 s tap, real-run medal under mash → r9 XCUITest cases. Open: a fresh install showed 3★ + medal before seeding → dev-ios investigates (debug path must never write the save). Teardown fixed (cases 6.8–65 s). GO given: iOS r9 build/freeze, Android r12 screen pass/freeze.
**TASK-021 docs written (2026-11-16):** design/TASK-021-start-map @ 522d833 (pushed, not merged): Map & Hometowns GDD (19 ACs), new design/ux/start-map.md (14 ACs), claims C17–C20 + S8–S10 pending, proposed schema MINOR (places.json, hero.hometown, hero.blurb; NOT BUILT), tools/content/check_content.py in the repo (0 errors, 10 warnings, baseline). Merge after a dev schema review (after the r9/r12 freezes). Waits on Luan: D-36 (e) hometown, (f) blurb, (g) no title row.
**Android r12 FROZEN (2026-11-16):** 1ae1560, APK sha256 08e0e942…9737 (leader-checked); JVM 165/165, trace 1.3 identical, release gate fails only R12. Adds partner 0.62 × hero height (93e2770) and the debug-save fix (debug jumps write no progress; same bug as iOS, DebugSaveTest). Sent to game-qc-android.
**iOS r9 FROZEN (2026-11-16):** 9c12a4a (branch @ 00eebf7), Debug exe sha256 d97a9302…1fae2 (leader-checked); GameCore 149/149 (DebugSaveTests mutation-checked); UI 22/22 from the frozen folder; Release byte check clean (no debug strings/symbols; exe 41c12614…c1af); gate R12. Adds the medal fix (debug jumps write no progress) and cases A–D (quiz glide ≤ 720 in motion, two Tiếp taps, 0.6 s tap, real-run mash medal). Partner case (c) not reached on the dev sim. Sent to game-qc-ios.
**iOS QC r9 PASS (2026-11-16):** 9c12a4a, qa/TASK-006-ios-r9 @ fc43e7d. UI 22/22 (timing cases re-run alone at load 7–11: hold 1.517 s, C 0.6 s rule, D mash median 0.398 s keeps medal + 3★, A glide max bottom 575.7). Spec checks, debug-save fix, regression PASS. NOT ASSESSED (covered by GameCore only): partner (c) off-screen start, 7c with 2–3 pauses / pause during the rise, AC14 fallback with a removed picture. Backlog for game-dev-ios (non-blocking): N1 banner-up after resume 0.800 s vs ≈ 0.83 expected (AC32 ≥ 0.8 passes, no margin); N2 guide says jumps never write seen_open (they do; harmless).
**Resume-dt parity (2026-11-16):** both apps' frame loops credit pre-press time to the first frame after an in-game resume (hold ends up to ≈ 33 ms early in wall time; core correct). Next round (iOS r10 / Android r13): a FrameClock helper resets on resume (dt = 0, acc = 0), with a unit test. iOS guide N2 fixed (ddd23c7).
**Android QC r12 PASS (2026-11-16):** 1ae1560, qa/TASK-007-android-r12 @ 25ce9c9. B8 real flow (partner 54 px clear, walk-in 0.684 s, hold 1.517 s), looks (cloth #D64A2E + #E8A93B border, follower, 0.622 × hero), camera cut (no lag), pauses 0.832–0.837 s, hints ≥ 276 and clear of pad squares, debug-save fix, release gate R12 only, regression (rolling lock 1.65–1.77 s, quiz ≤ 710.6, ending pole). Minors: (a) partner skin #F5C9A0 vs look sheet #F1C9A0; (b) the stuck pulse's outline touches the drawn Cờ rim at its largest (passes AC12); (c) border 3–4 world px. Not assessed: sound, low-end phone.
**FEATURE PARITY (2026-11-16):** iOS r9 (9c12a4a) PASS + Android r12 (1ae1560) PASS → vertical-slice /gate-check.

- 2026-11-17 — /gate-check Concept → Systems Design: **CONCERNS** (report production/gate-checks/2026-11-17-concept-to-systems-design.md). Stage stays Concept. TASK-022 → game-art-content: fix the concept's engine text, then /design-review it. Luan to decide D-14 and D-35, then the gate is re-run.
- 2026-11-17 — TASK-022 merged (12bc968): concept technical sections now native stack; concept /design-review APPROVED (log design/gdd/reviews/game-concept-review-log.md). Gate concerns 1 and 4 closed. D-35 widened to cover the pillar-5 design test too. Remaining for gate re-run: Luan's D-14 and D-35.
- 2026-11-17 — TASK-022b merged (f677c87): concept content owner, Next Steps ticked with proof, medal (D-07) in rewards, first-launch language pending D-20. Item (2) unblocked: Luan signs off history (his TASK-004 answer, cabf824).
- 2026-11-17 — TASK-022c merged (e05daf6): concept names Luan as the history reviewer (his TASK-004 answer).
- 2026-11-17 — Luan decided D-14: A (stars = story recall; star payoff sub-choice still open) and D-35: A. TASK-022d → game-art-content: remove both 'unless Luan decides' clauses. Then re-run the gate.
- 2026-11-17 — TASK-022d merged (3f41886): no 'unless' left in concept (D-35 A); stars = story recall, never reaction time (D-14 A). Gate re-run in progress (producer + TD).
- 2026-11-17 — Gate Concept → Systems Design re-run **PASS**; Luan approved, stage advanced to **Systems Design** (project.yaml + stage.txt). TASK-022e merged (37e38a7). Next gate: Systems Design → Technical Setup.
- 2026-11-17 — ID fix: the start-map work (branch design/TASK-021-start-map) is now **TASK-025**, and the concept gate fixes (committed as TASK-022, 022b–e) are now **TASK-024**. The earlier TASK-021 (UX) and TASK-022 (architecture) keep their IDs.
- 2026-11-17 — Luan: GO on the next app round + TestFlight prep. iOS r10 (FrameClock resume fix) → then TASK-026; Android r13 (FrameClock + partner skin #F1C9A0); devs cross-review plans. game-art-content: placeholder app icon (iOS 1024 + Android adaptive). Blocker for TestFlight upload: Luan's Apple Developer enrollment ($99/yr).
- 2026-11-17 — r13 FROZEN 3183874 (FrameClock + skin #F1C9A0; 171/171) → game-qc-android. iOS r10 plan → game-dev-android review (skin parity approved). TASK-026 icon merged (e564529). Luan decided D-37 B: preview build type on both apps for phone installs. D-38 bundle ID and D-39 Kids age band opened.
- 2026-11-17 — Luan decided D-38: keep com.galaxyandsun.daidatanhhung (both apps; preview adds .preview).
- 2026-11-17 — **Android QC r13 PASS** on 3183874 (evidence 8a64802): FrameClock 0.837–0.850 s, skin #F1C9A0 everywhere, r12 suite PASS. Parity question: the Android hint hand is a white glove (no skin), while iOS draws it in skin; sent to game-art-content. Next: preview build + phone-install script (D-37).
- 2026-11-17 — Hint hand: the spec (ASSET-033, look-sheet L72) says skin #F1C9A0 with a cream #FFF6E3 cuff. Android's white glove + red cuff → fix in r14; iOS to confirm its cuff in r10.
- 2026-11-17 — Android preview FROZEN 73efb30 (on 3183874): package .preview, not debuggable, local key at ~/.config/daidatanhhung/ (Luan keeps it), UNSIGNED badges shown, release gate untouched; phone-install.sh + frametime.sh + README. → game-qc-android short check.
- 2026-11-17 — **Android preview QC PASS 8/8** on 73efb30 (evidence 588000e). Ready for Luan's phone (USB or sideload).
- 2026-11-17 — Android r14 first freeze a5e8c37 (hint hand to spec). Folding TASK-023 W17 (fist glyph) + W20 (skip-warning icons/order) into r14 → refreeze, then one QC. W18 leave card waits for game-art-content's strings. Correction: iOS r10 also has the white glove + red cuff → fixed in r10. TASK-023 already done on Android: 15b, W7, W12, W19, W21.
- 2026-11-17 — TASK-023 W18 strings merged (e77899d; ACK game-dev-android, JVM 175/175). Android r14 now: hint hand + W17 + W20 (c1c8fbe) + W18 leave card → refreeze → QC. iOS gets W17/W18/W20 in a later round.
- 2026-11-17 — Android r14 FROZEN beea731 (hand + W17 + W20 + W18; JVM 182/182; debug + preview APKs) → game-qc-android.
- 2026-11-17 — iOS r10 FROZEN 760a5b2 (FrameClock N1, skin #F1C9A0, hint hand per ASSET-033; GameCore 155/155, UI 22/22, release byte check clean) → game-qc-ios. game-dev-ios starts TASK-026 from 760a5b2. iOS r11 queued: W17, W20, W18 (parity with Android r14).
- 2026-11-17 — TASK-026 READY 0b813aa (from 760a5b2): Preview config (.preview, gate skipped, UNSIGNED strip, allowsUnsigned runtime switch), AppIcon, 0.1.0, PrivacyInfo, export compliance, release-check/install-device/archive-upload scripts, Luan's guide production/releases/ios-device-and-testflight.md. Waits for Luan: Apple ID in Xcode (Personal Team ID) + iPhone paired + Developer Mode. iOS Preview short QC after r10. game-dev-ios → r11 plan.
- 2026-11-17 — **iOS QC r10 FAIL** on 760a5b2 (evidence efa043c): iOS-R10-01, after a resume the hold ends 0.816–0.833 s from the resume frame (6/9 runs under 0.828; target 0.833–0.850). Skin, hint hand and regression PASS. Likely cause (QC): the log is stamped with systemUptime while FrameClock credits SpriteKit currentTime. → game-dev-ios to fix in r11.
- 2026-11-17 — **Android QC r14 PASS** on beea731 (evidence 57e1cde): hint hand, W17, W20 (medal rules hold), W18 leave card (nothing written on leave), preview, and FrameClock at real speed (51 frames, 4/4). The slow-0.1 check is NOT ASSESSED (emulator stalls, r13 too); real speed is the bound, accepted. The Android preview to install on Luan's phone is now beea731-preview.
- 2026-11-17 — iOS r11 FROZEN 86ddce0 (branch feat/TASK-006-ios-native @ e8d5c9a, not pushed). Debug + Preview (Simulator) builds. iOS-R10-01 fix: the clock is SpriteKit currentTime minus the largest lead it has shown over systemUptime. The hold after a resume is 0.849 s of wall time, 5/5 runs. Walk smoothness is identical to SpriteKit's own clock; the systemUptime-only try (8233026) juddered and is superseded. Also W17, W20, W18 leave card → title, R8 checks the string's "field", rowH = max(110, pad_min), Preview inside. Results: GameCore 164/164, UI 29/29 (1 opt-in skipped), Preview check 1/1, release byte check clean. Note for QC: the skip-warning medal grazes the first text line (since r9). → game-qc-ios.
- 2026-11-17 — Luan asked to commit and push everything. QC Android helper scripts were committed (3951442). All 72 team task and QC branches are now on origin. Left out on purpose: raw iOS .xcresult bundles (about 130 MB, never tracked), member session logs, and QC iOS r11 work in progress (QC commits it when done).
- 2026-11-17 — TASK-027 demo video for Luan's bosses → game-qc-android: the r14 preview build played end to end, about 2–3 min, with a title card and key-frame PNGs, on branch demo/TASK-027-video.
- 2026-11-17 — **TASK-027 demo video DONE** (demo/TASK-027-video @ 90167ce, pushed): 3:12, 1080p, 8.7 MB, r14 preview played through; 6 key frames + README. Emulator shut down for the iOS r11 timing checks.
- 2026-11-17 — **iOS QC r11 PASS** on 86ddce0 + Preview (evidence 190fbe0, pushed; merge into docs waits for Luan's OK). iOS-R10-01 is fixed: 0.849 s of wall time in 7/7 runs, no judder. W17, W20, W18, R8 field, pad_min, Preview and regression all PASS. New bug iOS-R11-01 (S4/P3, not a blocker): on the VI skip warning the medal drum has a 0 px gap to the first text line. → game-dev-ios, next round.
- 2026-11-17 — iOS-R11-01 fixed on feat/TASK-006-ios-native @ 9af55da (pushed, not frozen): the VI skip-warning text moves down 8 world px, and the ring now clears the circumflex by about 10 px. QC'd in the next iOS round.
- 2026-11-17 — **iOS Preview INSTALLED on Luan's iPhone 17 Pro** (iOS 27.2): 9af55da, team 4KRK8K334N (free). The profile expires 2026-11-24 12:15 UTC; rerun install-device.sh before then. Waits for Luan's developer trust tap; then game-dev-ios takes the ADR-0002 device numbers.
- 2026-11-17 — **Luan: Dải Đất Anh Hùng goes ON HOLD; a new game is next.** The current iOS version (9af55da Preview) is on his iPhone and waits for his trust tap. TASK-028: move all of this game into games/dai-dat-anh-hung/ (merge the iOS + Android + docs branches into one; the studio framework stays at the root). game-dev-ios writes the plan (chore/TASK-028-move-plan) and game-dev-android reviews the Android parts. Nothing moves until the plan is reviewed.
- 2026-11-17 — iOS Preview 9af55da LAUNCHED on Luan's iPhone 17 Pro after his trust tap. The free-team signing fix to install-device.sh is 55cbbe6 (pushed). Reinstall before 2026-11-24 12:15 UTC: TEAM_ID=4KRK8K334N DEVICE="Luan's iPhonex" tools/ios/install-device.sh. ADR-0002: idle memory snapshot only; frame time while playing is deferred until the game comes off hold.
