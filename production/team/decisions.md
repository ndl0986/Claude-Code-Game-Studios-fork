# Decisions for Luan

Open questions that need Luan's call, each with the flow it sits in, the steps, the options and a
recommendation. Luan reads this file and decides here or in chat; the leader records the answer
and moves the item to **Decided**. Newest open items first. The leader owns this file.

Status values: **Open** (needs Luan) · **Proposed** (the team applied a default; Luan can overturn
it) · **Decided** (Luan's call, with the date).

---

## Open

### D-11 Quiz data fixes (for the devs)

- **Flow:** Quiz & stars GDD (`eaf221b`) → `content/fixtures/quiz-scoring.json`, `tuning.json`,
  validation → both apps.
- **What:** (a) a repeat tap on an already-greyed wrong card is ignored and not counted (as in the
  prototype), so the quiz always ends; (b) `quiz_count` = 5, so each hero's content decides 3–5
  questions (random tapping earns ≥2★ 37% of the time with 3 questions, 8.6% with 5);
  (c) validation fails if `rules.json` t2 < t3.
- **Status:** Done, merged in `3074d43` (data/TASK-005d). Raised by game-art-content.

### D-10 A "Special" (banner) move in combat

- **Flow:** combat GDD (`design/gdd/side-scroll-combat.md`, rule 16) → a 4th button, the banner
  ("Cờ / Banner") → both apps. It ties combat to the six-word banner story (C08).
- **What it does (proposed):** a tap raises the banner and pushes nearby enemies back
  (`special_push` 170 px), then a 6 s cooldown. No damage, no violence.
- **Steps it affects:** a 4th thumb pad on screen (crowding on small phones), a new hint step,
  new art and sound, two tuning keys.
- **Options:** A. add it in the slice (with D-08 C or B) · B. add it later, with the training beat
  (D-08 B) · C. no Special in combat; the banner stays a story/training moment only.
- **Recommendation:** B. Keep the slice to three pads; bring the banner move in with the training
  beat that teaches it.
- **Status:** Open. Raised by game-art-content (TASK-008).

### D-09 Two new tuning keys and two content checks (for the devs): AGREED by both devs + art-content (schema 1.1, data/TASK-005d)

- **Flow:** combat GDD → `content/data/tuning.json` (game-dev-android edits) → both apps.
- **What:** 14 of the GDD's proposed keys already exist (TASK-005b); the GDD switches to those
  names. New: `special_push` 170 px, `special_cooldown` 6 s, `advance_debounce` 0.25 s (story-box tap debounce), `bump_stop` 0.5 s (walk-beat bump stop); checks: fail if
  `attack_range < enemy_reach − stand_gap`, warn if `telegraph < 0.8 s`.
- **Status:** Open (the two devs + game-art-content agree; Luan only if they disagree).

### D-08 Vertical-slice beat set for Trần Quốc Toản

- **Flow:** TASK-008 mission-flow GDD defines 5 beat types → content `mission.json` → TASK-006/007
  native slice → playtest on real phones.
- **Steps it affects:** which beat types the iOS and Android slices must build now, and which
  `mission.json` the slice bundles.
- **Options:**
  - A. **Keep 4 fight beats** (the TASK-003 prototype, P-02). Least new code; the story is told
    only by captions, so the orange and the banner are not played.
  - B. **The approved structure:** walk (riverbank) → hold-meter (orange) → training (banner) →
    reach-the-flag with encounters (battle). It tests *Live the story* properly, but means 3 more
    beat types in both apps.
  - C. **A + one new type:** fights, but beat 2 is a hold-meter (the orange). It tests the
    riskiest idea, a non-combat story beat, for the cost of one type.
- **Recommendation:** C for the slice, then B before Alpha. The slice should prove that a
  non-fight story moment is fun, which A cannot show.
- **Status:** Open. Raised by game-art-content (TASK-008, `design/gdd/mission-flow.md`).

### D-07 Skipping story boxes on a replay

- **Flow:** mission → intro / beat cards / ending (story boxes, one sentence each, tap "Tiếp").
- **Steps it affects:** the story screen UI; replays for a missing star.
- **Options:**
  - A. **No skip ever:** the child taps through every box (each tap advances one box).
  - B. **Skip on replay only:** after a hero's mission has been finished once, a "Bỏ qua / Skip
    story" button appears on story screens.
  - C. Skip always.
- **Recommendation:** B. A first play keeps the story, which is pillar 1. A replay for stars
  shouldn't make a child sit through it again, and the quiz still checks what they remember.
- **Status:** Open. Raised by game-art-content (TASK-008).

### D-06 Content schema: params for training and reach-the-flag: AGREED (option A, schema 1.1) by both devs + art-content

- **Flow:** mission-flow GDD → `content/schema/mission.schema.json` (schema change needs both devs
  + game-art-content) → `mission.json`.
- **What's missing:**
  - `training` has only `dummies`. The approved beat 3 also needs `blocks` (practice strikes to
    block, 1–5) and `finish_special` (bool: special tap ends it).
  - `reach-the-flag` has only `length_screens`. Beat 4 needs optional `encounters[]`, each
    `{at_screen, enemies, max_active, from_left}`, where enemy groups lock the camera on the way.
- **Options:** A. add both, as a MINOR schema bump (optional fields) · B. make beat 4 two beats
  (a fight, then a reach-the-flag), so only training changes.
- **Recommendation:** A. It keeps one beat per story moment, as in the hero doc.
- **Status:** Open (for the devs and game-art-content to agree; Luan only if they disagree).

### D-01 Monetization

- **Flow:** concept → first release → store listing. It decides store category, privacy forms and
  whether any purchase or ad code exists.
- **Steps it affects:**
  1. Store listing (Google Play "Designed for Families", Apple Kids category).
  2. Privacy forms (data safety, App Privacy): no data collected stays simplest.
  3. Code: none needed for "paid" or "free"; purchases need StoreKit/Play Billing and a parental gate.
- **Options:**
  - A. **Free, no ads, no purchases** (sponsor, school or government funded).
  - B. **Paid up front** (one price, everything included).
  - C. Free with a one-time "unlock all heroes" purchase behind a parental gate.
  - D. Ads: not recommended for children; conflicts with the "Safe for kids" pillar.
- **Recommendation:** A or B for the first release (no purchase code, simplest kids-category review).
  Decide before the first-release store setup; it doesn't block the vertical slice.
- **Status:** Open.

### D-02 Timeline: "weeks" covers the MVP, not a store release

- **Flow:** MVP (~3–5 weeks) → vertical slice on real phones (~6–8 weeks) → first release with
  2 heroes + 1 storybook (~2–3 months, from the concept).
- **Steps:** confirm the target date for the first release, so `/sprint-plan` can size sprints.
- **Options:** A. accept ~2–3 months for the first release · B. cut scope to 1 hero for an earlier
  release (`/cut` proposes cuts) · C. name a fixed date and let the team cut to fit.
- **Recommendation:** B or C once the native slice shows real speed on both apps.
- **Status:** Open.

### D-03 Sign off Trần Quốc Toản's claims C01–C11 and confirm sources

- **Flow:** game-art-content drafts → Luan signs off each claim → the claim's `signoff` becomes
  `approved` in content/ → a release build allows the mission. Until then release builds refuse it
  (debug builds show an "UNSIGNED Cxx" badge).
- **Steps:**
  1. Read `design/narrative/heroes/tran-quoc-toan.md` (claim register C01–C12).
  2. Confirm source locations: Kết nối tri thức Lịch sử và Địa lí (grade, lesson, page), whether
     the Tiếng Việt book has the reading, the Toàn thư translation edition.
  3. Approve or correct each claim. C06/C08 become `fact_as_recorded` only if the Toàn thư 1282
     passage is confirmed.
- **Recommendation:** do it before the vertical slice is shown to anyone outside the team.
- **Status:** Open (blocks real content in release builds, not the slice itself).

### D-04 Save data ADR

- **Flow:** stars, unlocked heroes and language live on the device only (pillar "Safe for kids").
  The slice uses UserDefaults / SharedPreferences.
- **Steps:** an ADR that fixes the saved fields, versioning and migration, so iOS and Android store
  the same things the same way.
- **Recommendation:** game-dev-ios writes it after the slice (TASK-009), game-dev-android reviews.
- **Status:** Open (not urgent).

### D-05 A "Native" engine row in the studio template

- **Flow:** the template only knows Godot, Unity, Unreal and Web, so `/setup-engine`, engine
  specialists, `/test-setup` and `/smoke-check` report NOT ASSESSED for this project (ADR-0001).
- **Options:** A. leave it (accept NOT ASSESSED on those checks) · B. add a native row to
  `.claude/engines/engines.tsv` and native run/test guides, so the studio checks work.
- **Recommendation:** A for now; B later if the gates become noisy.
- **Status:** Open.

---

## Proposed (applied by the team; Luan can overturn)

### P-05 Quiz in the slice follows the Quiz & stars GDD

- **Flow:** quiz question → answer → feedback → next question.
- **What the team applied (both apps):** after the right answer and its "why" line, the child taps
  **Tiếp / Next** (no automatic advance, so there's time to read or hear it); a wrong answer shakes
  for 0.5 s and ignores taps meanwhile; the quiz screen has a **pause** button (the only place to
  switch VI|EN during the quiz); answer cards are shuffled per question with a seeded order shared
  by both apps (a fixture tests it). The browser prototype auto-advanced and didn't shuffle.
- **Status:** Proposed.

### P-04 Both apps behave identically: parity rules (TASK-006/007)

- **Flow:** prototype spec (203d73e) → shared `content/` data → iOS and Android read the same values
  and rules → shared fixtures test both.
- **What the team applied:**
  1. 17 numbers the prototype hard-coded (enemy timings and distances, camera, ground, beat spacing,
     first spawn delay) move into `content/data/tuning.json`, owned by game-dev-android's one edit.
  2. The prototype's **results** screen (stars, then Next) stays: title → intro → play → caption →
     ending → quiz → results → unlock.
  3. Saved on the device only: `lang`, `stars.<hero>` (best ever, never lowered), `unlocked` heroes.
  4. Firing rules as in P-01, with quiz answer cards firing on release; one tap tone per menu press.
  5. Sample pictures are drawn in code in debug builds; the picture-id check applies to real data.
  6. Quiz shows 3–5 questions (the first N available); the stall hint resets on a hit or caption close.
- **Status:** Proposed. The combat, mission-flow and quiz GDDs (TASK-008) formalise them.

### P-01 Menu buttons fire on release, gameplay pads on press

- **Flow:** touch → button. The browser prototype fired everything on press.
- **What the team applied:** menus and quiz answers fire when the finger lifts inside the button
  (so a stray palm or a child's second finger doesn't start things); the move/attack/defend pads
  fire on press (so play feels immediate).
- **Status:** Proposed (both apps). TASK-008's hints/input GDD will formalise it.

### P-02 Stubbed beat types play as fights in the slice

- **Flow:** content beat types (walk, hold-meter, training, reach-the-flag) → the app's beat engine.
- **What the team applied:** the slice implements `fight`; other types play as fights until their
  GDD (TASK-008, mission flow) defines them.
- **Status:** Proposed.

### P-03 Enemy "hurt" lasts 0.35 s

- A literal in the prototype, not in its config. Both apps use it; TASK-008's combat GDD sets it as
  a tuning value.
- **Status:** Proposed.

---

## Decided

| Date | Decision |
| --- | --- |
| 2026-11-14 | Native per platform: iOS Swift + SpriteKit (game-dev-ios), Android Kotlin + Android SDK only (game-dev-android); Godot shelved. Luan accepts the risk of two codebases (ADR-0001). |
| 2026-11-14 | Android draws with a SurfaceView/Canvas loop and SoundPool; kotlinx.serialization is the one dependency. |
| 2026-11-14 | Android targetSdk 35 for now; raise to 36 before any Play upload (pre-release item). |
| 2026-11-14 | TASK-006/007 are a native vertical slice; TASK-008 runs `/map-systems` + key GDDs; then the studio pipeline (gate-check → epics → stories → sprints). |
| 2026-11-14 | Browser testing stopped; TASK-003 closed as the design reference. |
| 2026-11-14 | Systems index approved (13 systems; VS GDDs first). TASK-004 merged before TASK-008. |
| 2026-11-14 | Quiz stars: retry until right (3★ all first try, 2★ ≤2 retries total, 1★ finished). |
| 2026-11-14 | Art references: Đông Hồ / Đông Sơn motifs + Kim Đồng picture books; 4 art rules approved. |
| 2026-11-14 | Sources: Kết nối tri thức textbook first, then Toàn thư; legends labelled; his death one calm line. Landscape. |
| 2026-11-14 | Platform owners: game-dev-ios owns the iOS app, game-dev-android owns the Android app. |
