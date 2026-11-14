# Decisions for Luan

Open questions that need Luan's call, each with the flow it sits in, the steps, the options and a
recommendation. Luan reads this file and decides here or in chat; the leader records the answer
and moves the item to **Decided**. Newest open items first. The leader owns this file.

Status values: **Open** (needs Luan) · **Proposed** (the team applied a default; Luan can overturn
it) · **Decided** (Luan's call, with the date).

---

## Open

### D-16 Saved progress keys: work out unlocks instead of storing them

- **Flow:** Hero progression GDD (`89afd10`) → D-04 save ADR → both apps' save code.
- **Change:** instead of P-04's stored `unlocked` list, save `completed.<hero>` (quiz finished) and
  `seen_open.<hero>` (never re-locks), plus `stars.<hero>` (best, never lowered),
  `medal.<hero>` (never cleared) and `lang`. Unlocks are worked out from those.
- **Why:** with timed content updates, a stored list can't open a hero added later for a child who
  already finished the previous one, and a hero inserted earlier in history breaks the chain.
- **Status:** Proposed. The leader applied it to the slice so both apps write it once; the devs' D-04
  save ADR formalises it. Luan can overturn it.

### D-13 Does combat need a mastery reason to block?

- **Flow:** combat GDD → slice playtest → hero 2+ difficulty.
- **Finding (/review-all-gdds G1):** defend never pays off: blocking stops you moving and attacking
  and makes the fight longer, while an unblocked hit only costs one step back. The "!" warning and
  the defend hint teach a skill with no reward.
- **Options:** A. accept combat as participation (stars from the quiz are the only mastery, pillar 3)
  · B. give blocking a small reward (a blocked enemy is stunned and the next hit counts double, or a
  block fills the banner meter) · C. decide after the slice playtest.
- **Recommendation:** C, then B if children ignore defend.
- **Status:** Open.

### D-14 What stars measure, and what they're for

- **Finding (G2, G3):** the concept says stars reward combat challenge and replay mastery, but stars
  come only from quiz retries; "later heroes add speed" collides with the 0.8 s telegraph floor; stars
  have no payoff beyond the map.
- **Options:** A. stars measure story recall only (fix the concept; later heroes scale by enemy count
  and hits, never reaction time) · B. stars also reflect combat. Either way: give each star a visible
  payoff (a "Did you know?" fact page per star, or a map decoration).
- **Recommendation:** A + a fact page per star. Note: Luan's new **medal** (D-07) already rewards
  playing the full story, so stars = quiz recall, medal = full story fits A well.
- **Status:** Open.

### D-15 Quiz card order repeats on every replay

- **Finding (S1):** the card shuffle seed is fixed per question, so a replay shows the same positions
  and a child can earn 3★ by memorising positions.
- **Options:** A. accept · B. reseed per run (seed + run_count + question_index); both apps stay
  identical for the same run_count, and the fixture still tests the algorithm.
- **Recommendation:** B (small change: devs + Quiz GDD rule 3).
- **Status:** Open.

### D-12 Legend markers on short labels (R4b, for the devs + art)

- **Flow:** content validation → both apps' tests.
- **What:** legend markers ("Truyện kể rằng / The story says") are required in sentences (intro,
  scene, ending, quiz prompt, why). Short labels (banner, beat title, goal, hero name, place, quiz
  choice) are exempt when the same mission or question already has a marked sentence for that
  legend claim.
- **Status:** AGREED by both devs + game-art-content: scope is the whole mission for labels, the question's prompt/why for quiz choices; "marked" = VI and EN both. game-dev-ios writes it on data/TASK-009a-r4b.

### D-11 Quiz data fixes (for the devs)

- **Flow:** Quiz & stars GDD (`eaf221b`) → `content/fixtures/quiz-scoring.json`, `tuning.json`,
  validation → both apps.
- **What:** (a) a repeat tap on an already-greyed wrong card is ignored and not counted (as in the
  prototype), so the quiz always ends; (b) `quiz_count` = 5, so each hero's content decides 3–5
  questions (random tapping earns ≥2★ 37% of the time with 3 questions, 8.6% with 5);
  (c) validation fails if `rules.json` t2 < t3.
- **Status:** Done, merged in `3074d43` (data/TASK-005d). Raised by game-art-content.

### D-09 Two new tuning keys and two content checks (for the devs): DONE (schema 1.1, merged 3074d43)

- **Flow:** combat GDD → `content/data/tuning.json` (game-dev-android edits) → both apps.
- **What:** 14 of the GDD's proposed keys already exist (TASK-005b); the GDD switches to those
  names. New: `special_push` 170 px, `special_cooldown` 6 s, `advance_debounce` 0.25 s (story-box tap debounce), `bump_stop` 0.5 s (walk-beat bump stop); checks: fail if
  `attack_range < enemy_reach − stand_gap`, warn if `telegraph < 0.8 s`.
- **Status:** Open (the two devs + game-art-content agree; Luan only if they disagree).

### D-06 Content schema: params for training and reach-the-flag: DONE (schema 1.1, merged 3074d43)

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

### P-02 Stubbed beat types play as fights in the slice (SUPERSEDED by D-08 B, 2026-11-14)

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
| 2026-11-14 | **D-08: B, the full structure** in the slice: walk (riverbank to Bình Than) → hold-meter (the orange) → training (dummies, blocks, raise the banner) → reach-the-flag with fight encounters. `mission-full.json` becomes the slice's mission. |
| 2026-11-14 | **D-10: B, later.** No Special move in fights or encounters yet; the banner button appears only in the hold-meter and training beats (R13). Combat Special comes back as its own decision. |
| 2026-11-14 | **D-07 (Luan's own option):** story boxes can be skipped, but the game warns that skipping means the mission isn't fully completed, so the child doesn't earn **that mission's medal**. A medal per mission rewards playing the full story; quiz stars stay separate. |
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
