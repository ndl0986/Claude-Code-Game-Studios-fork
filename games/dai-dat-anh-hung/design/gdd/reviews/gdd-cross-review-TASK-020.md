# Cross-GDD Review Report: TASK-020

Date: 2026-11-14 · Task: TASK-020 · Reviewer: game-dev-android (an independent reader; game-art-content wrote the GDDs)
Source: `docs/vn-history-game-plan` @ 427f089 (includes TASK-019)
GDDs reviewed: **10 of 10 present**: audio-and-voice-over, hero-progression, hints-and-onboarding,
input-and-touch, language-and-text, map-and-timeline, mission-flow, quiz-and-stars,
save-and-progress, side-scroll-combat. Also read: game-concept (pillars), systems-index, the content
contract (`content/README.md`, `content/schema/`, mission schema 1.4), `content/data/tuning.json`,
`rules.json`, and the Trần Quốc Toản `mission.json`, `quiz.json` and `claims.json`.
Not read: none.
Focus: **full**, covering consistency (Phase 2), design holism (Phase 3), scenarios (Phase 4), number
drift, and spec against build.
Baseline: `design/gdd/gdd-cross-review-2026-11-14.md` (TASK-010). Its findings are re-checked in the
baseline table below. Fixed ones aren't repeated as new.
Method:
- Phases 2 and 3–4 ran as two `game-designer` agents in parallel. They read the files directly
  (by section for the two GDDs over 30 KB) instead of being handed pasted excerpts, the same as
  TASK-010.
- game-dev-android did the number-drift and spec-against-build passes, and checked both Blocking
  findings against the source lines.
- Spec against build covers the Android slice (TASK-007 @ 74a158e). iOS is covered only where
  game-dev-ios has reported its behaviour.
Engine: native iOS and Android (ADR-0001); no engine reference applies.
Entity registry: empty, so the consistency checks relied on full GDD reads.

**Owner tags:**
- **GDD**: game-art-content edits a GDD.
- **content/Luan**: history content or a pending claim (C01–C16, D-24), routed to decisions.md.
- **Luan**: a design decision.
- **Android** / **iOS**: an app change.

---

## Verdict: FAIL (2 Blocking, both doc-only fixes)

Two GDD rules cite a formula or an owner that doesn't exist as written. The **apps already agree** on
both: the shared trace `trace-tqt.json` replays identically on Android and iOS. So no code changes.
The documents need correcting before the architecture and stories are built on them.

The rest is **CONCERNS**:
- 21 Warnings. The largest is the reading load of the slice for a 6-year-old with no voice-over (W1).
  The next largest is the end-of-mission hand-offs: unlock, "mission completed" and the medal
  (W3, W4).
- No anti-pillar violation was found.
- Number drift is clean.

### Required before re-running (Blocking)
1. **B1**: give the dialogue ask hint an owner in Hints.
2. **B2**: replace the linear beat-start formula with `beatX(i)` in Combat and Mission flow.

---

## Blocking

**B1. The dialogue ask hint is assigned to Hints, which has no rule for it and excludes it.** (GDD)
- mission-flow Rule 7d (L136–137) says: "if the ask button isn't tapped for `hint_delay`, the hint hand points at it (Hints GDD, stuck hint for the current action)."
- hints-and-onboarding Rule 4 has no `dialogue` row. Rule 8 (L77–78) says: "No hints on story screens… This system covers play only."
- So the cited element doesn't exist, and the rule it points to forbids it. That is a P-04 parity risk on the shipped Bình Than beat.
- Both apps already show it. Android does so when `stall > hint_delay` while the ask button shows (`Mission.kt` `askHint`).
- **Fix:** add a `dialogue` row to Hints Rule 4: progress = an ask tap or "Tiếp"; hint = the hand on the ask button after `hint_delay`. Carve dialogue out of Rule 8.

**B2. Three formulas give the beat-start position.** (GDD)
- mission-flow F5 (L298–299): `beatX(i+1) = beatX(i) + extent(i) + beat_gap`. AC20 expects 900, 2980, 3780, 4580, 6580.
- side-scroll-combat frame order step 7 (L159), which is declared mandatory for both apps, says: "Start the beat once the hero passes `beat_start_x + i × beat_gap`". The mission-flow States table (L191, `walk_to[i]`) and F2 (L247) say the same.
- An app that follows step 7 places beats at 900, 1700, 2500… and fails AC20.
- Combat L137–139 also cites "Core Rule 2 and F2" for the world layout. The positions are in F5.
- Both apps use F5, and the trace confirms it.
- **Fix:** use `beatX(i)` in Combat step 7, the MF States table and MF F2, and cite F5.

---

## Warnings

### Cross-GDD consistency

**W2. The saved-key list differs in four places.** (GDD)
- save-and-progress Rule 1 lists `save_version` and `sound`.
- hero-progression Rule 11 (L89–90) and decision D-16 omit `sound`.
- hints Rule 7 (L75–76) still says "Save keeps only `lang`, stars and unlocks, P-04". That is pre-D-16, and unlocks are derived, not saved.
- **Fix:** HP Rule 11 and D-16 should cite Save Rule 1. Point Hints Rule 7 to Save Rule 1.

**W3. When the unlock screen shows: Mission flow and Hero progression disagree.** (GDD)
- mission-flow Rule 1.6 (L46), the States table (L199) and AC1 go to `unlock` whenever `next_hero` is not null.
- hero-progression Rule 10.2 (L85) goes there "only when this finish opened a hero that wasn't open before". Its edge case (L160) says a replay shows no unlock. Rule 6 says the hero that opens can differ from `next_hero`.
- quiz Rule 8 says "Hero progression, which unlocks `next_hero`".
- MF AC1 and HP AC5 can't both pass on a replay. In a release build where `next_hero` is hidden, MF would announce a hero the child can't play.
- **Fix:** MF goes to `unlock` only when progression reports a newly opened hero. Reword Quiz Rule 8 to "reports completion; Hero progression derives the unlock".

**W4. Two senders of "mission completed", the medal sent separately, and three owners of best-of stars.** (GDD)
- quiz Interactions (L111) sends HP "mission completed (hero, stars)". mission-flow Interactions (L221) sends HP "mission completed… plus `medal_earned`".
- Save Rule 4 needs completed, stars, medal and seen_open written as **one unit**. With two events, the trigger for that write is undefined, and the medal could need a second write that a kill can lose.
- Best-of is claimed by Quiz ("applied by Save"), Save ("via Hero progression") and HP Rule 8 (max).
- **Fix:** one payload, `{hero, stars, medal_earned}`. Quiz reports to Mission flow; Mission flow reports once to HP. HP applies max(); Save stores and keeps its F1 clamp.
- Both apps already write at one point. Android's `Game` commits all keys at quiz finish, before results. The GDDs should say so.

**W5. Map assigns two hints to Hints, which defines neither and doesn't list Map.** (GDD)
- map-and-timeline Rule 8 (L98–99) says the first-view hand points at the only open pin (Hints GDD). Rule 3's locked-pin tap adds an arrow to the open pin.
- Hints has no map row, says it "covers play only", and has no Map dependency.
- **Fix:** add a "map: first view" row and a Map dependency to Hints, or make both effects Map-owned.

**W6. The narrator line's field type is wrong in Mission flow.** (GDD)
- mission-flow 7d (L115) says the `narrator` line is "field type `dialogue_line` at 880 wide".
- The contract (`content/README.md` L49), validator R8c and Language Rule 8 use `dialogue_narrator` (880/38/**2**/600). `dialogue_line` is 720/38/3.
- **Fix:** narrator lines use `dialogue_narrator` (880 wide, at most 2 lines).

**W7. The pause button and VI|EN chip positions conflict.** (GDD)
- Input Rule 3 (L49–51) says pause and sound are top-left, and the VI|EN chip is on title and pause only.
- Quiz UI (L240) says pause is top-right. Map Rule 1 (L47) puts pause, sound and the chip top-right.
- mission-flow UI puts story screens at top-right (L439) and the HUD at top-left (L441).
- **Fix:** turn Input Rule 3 into a per-screen table (HUD, story, quiz, map, title). Allow the chip on "title / map and pause". Pick one corner for pause where possible; a child looks for it in one place.
- Android today: top-left on the HUD, top-right on story screens.

**W8. The fit scale `k` has three meanings and values, and the examples don't match a real device.** (GDD)
- Input F1 and Map F2: k ≈ 0.68 pt per world px, so `pad_min` 72 pt ≈ 106 world px and `pin_world` ≈ 106.
- Language Rule 6: "k ≈ 1.28 on a 20:9 phone… 37 world px (about 18 dp)". That is about 0.49 dp per world px.
- The QC Android phone (1080×2400 at 420 dpi, safe height 996 px as in Input F2's own example) has a screen scale of 1.383 px per world px, which is **0.527 dp per world px**. So:
  - `pad_min` 72 dp = **137 world px**, which is what Android's `ScreenFit` draws;
  - `pad_gap` 12 dp = 23 world px;
  - 37 world px ≈ 19.5 dp.
- The examples understate the pad and pin footprint by about 30%. That matters for fitting pads with `pad_gap` into 720 world px, and for the pin-cluster threshold.
- **Fix:** define `k` once in Input F1 (dp per world px). Call Language's value `k_px` (screen px per world px). Recompute the examples on one named reference phone per platform.

**W9. The language size rule doesn't classify six text fields, and the banner is read text set below the body minimum.** (GDD; the banner text is content/Luan)
- Language Rule 6 defines body ≥ `text_min_body` 37 and labels ≥ `text_min_label` 28.
- `rules.json` `text_limits.fit.fields` also has fields in neither class: `button` 34, `ui` 30, `place` 30, `banner` 28, `hero_name` 44 and `beat_title` 44.
- `banner` holds the six-word motto, "Phá cường địch, báo hoàng ân". It is history text the child reads, and quiz Q4 asks about it, yet it's at 28, the label minimum.
- `text_min_body` and `text_min_label` are prose only. They aren't data keys and no validator rule checks them, so nothing enforces Rule 6.
- **Fix:** classify every R8c field type. Decide the banner's class (body is the recommendation: raise it to 37 and re-fit). Add a contract rule that each `fit.fields` `font_px` is at or above its class minimum, so both validators enforce it.

**W10. Dependency edges are still missing (systems-index and GDD tables).** (GDD)
- systems-index:
  - row 9, Hero progression, is missing 6 (Mission flow) and 2 (Language);
  - row 7, Quiz, is missing 3 (Input);
  - row 11, Map, is missing 3 and 6;
  - the Feature-layer prose for Map disagrees with row 11;
  - L69 "slow-down after a miss" contradicts the Hints open question ("no slow-down").
- Unmirrored GDD tables:
  - Save, Language and Hints have no Map row;
  - Audio has no Input or Map row;
  - Quiz has no Input row;
  - Combat's Audio row is missing windup and strike (`sfx_enemy_windup`, `sfx_enemy_strike`, Audio Rule 5).
- **Fix:** add the edges and rows. Change L69 to "stuck hint after `hint_delay`".

### Design holism (ages 6–10)

**W1. The slice puts a reading wall before the first real action, and it has no voice.** (content/Luan, and Luan for the VO scope)
- From `mission.json`: 4 intro boxes, then the walk card (title, 2 lines, goal), then about 4 s of walking, then **9 dialogue lines plus 2 ask taps**.
- That's about 15 text boxes before the first non-walk action (the hold meter). Story text totals about 26 boxes (roughly 260 VI syllables), plus about 145 in the quiz.
- mission-flow F1 assumes `T_box` 3–8 s, which is an adult or voiced pace. A child at the end of grade 1 reads roughly 40–60 syllables a minute (an estimate, worth checking against the curriculum). So the story alone is about 4–6.5 minutes, which breaks F1's 3–5 min mission and the concept's session length for a child playing alone.
- The audio Summary says "the slice ships with text only", yet Pillar 3 promises "short text with voice".
- The vocabulary sits above grade 1–2: "vương hầu", "trăm quan", "xâm lược", "hy sinh", "cường địch, hoàng ân".
- **Fix (Luan):** pick one or both of:
  - record VO for the slice's intro, dialogue and ending;
  - cut the intro to 2 boxes and the dialogue to at most 6 lines.
  Don't run playtests with 6–7-year-olds without voice unless an adult reads aloud.

**W11. The dialogue beat is not voiced and has no music state.** (GDD)
- Audio Rule 17 (L156–158) voices the intro, card, caption, ending, quiz prompt and why. It doesn't voice dialogue lines or the ask button, which TASK-016 added later.
- The music table (L59–70) has no dialogue state.
- **Fix:** add dialogue lines and `ask.button` to Rule 17, and map dialogue to the "Story screens" cue.

**W12. Training shows 5 pads at once, against Mission flow's own Rule 4.** (GDD)
- `tqt.f3` lists move, attack, defend and special, so ◀ ▶, attack, defend and the flag are all on screen from the start.
- Rule 4 hides pads "so a child never presses a button that does nothing". Here special does nothing during dummies and blocks, and defend does nothing during dummies.
- This is the baseline G5 concern, which moved from fights to training.
- **Fix:** reveal pads per training step: dummies get move and attack, blocks add defend, the finish adds the flag. Both apps would read this from the step, not from `buttons`. It's a small change.

**W13. Mashing "Tiếp" keeps the medal, while an honest Skip loses it.** (Luan)
- MF Rule 15 (L180–183): a box counts as read when advanced, and reading speed isn't checked. About 26 boxes at the 0.25 s debounce take roughly 7 s to tap through, and the medal is kept.
- Skip costs the medal, with a warning.
- The medal is described as "hearing the whole story" (HP L35), which isn't true without VO.
- **Fix (Luan):** one of:
  - (a) keep the rule and reword the medal as "turned every page";
  - (b) once VO exists, count a box only after its clip has played, or a minimum time has passed;
  - (c) drop the cost of Skip on first play.

**W14. The same card order on every replay (baseline S1, still open).** (Luan, D-15)
- Quiz Rule 3 (L45–53) seeds the shuffle with `seed + question_index` only, so the answers sit in the same places each replay and 3★ can be earned by memorising positions.
- **Fix:** add a per-run counter to the seed (both apps; the shuffle fixture tests the algorithm, not one fixed order).

**W15. Two quiz questions can't be answered from their pictures, and one gives its answer away.** (content/Luan)
- Quiz Q3's rule (L85–86) says each choice must be recognisable from its picture alone, and choices aren't voiced (Audio Rule 17).
- Q1's choices are dynasty flags (`pic.quiz_flag_ly`, `_tran`, `_le`), and Q5's are helmets (`pic.quiz_helmet_a/b/c`). A 6-year-old can't tell them apart, and the depictions need claims.
- Q1's prompt "…thời nhà nào?" sits under the hero's name, "Trần" Quốc Toản, and its why line teaches "surname = dynasty". That's wrong as a general rule. It rests on C02 (royal family) but cites only C01, and the EN why line doesn't say it.
- **Fix:** rewrite Q1. Use the helmets the child actually fought in beat 4 for Q5. Luan signs off the flag and helmet depictions.

**W16. Stars and difficulty: the concept still promises what the GDDs removed (baseline G2, still open).** (GDD, game-concept)
- Concept L106 says "1–3 stars for replay mastery". L157–158 says "later heroes add a little speed… stars reward the extra challenge".
- Quiz Rule 7 makes stars purely about quiz recall. The `telegraph` R15 floor (0.8 s) and the single global `tuning.json` leave almost no room to add speed.
- **Fix:** correct the concept. Write down encounter composition (count, kinds, sides) as the only difficulty lever across heroes (see A6).

**W17. The child crushes the orange by holding a "flag button" before the banner exists.** (content/Luan, and GDD)
- In `tqt.f2` the goal is "Giữ chặt nút lá cờ! / Hold down the flag button!". Input Rule 3 also calls special the "flag pad".
- The banner is only made in beat 3. Holding a flag icon to crush an orange breaks Pillar 1 ("I was the hero's hands").
- Also, C06 says he crushed it "without noticing" (lúc nào không biết), while here it's a deliberate 2.5 s hold. Audio calls the cue "determination, not anger" (L64), but C06 says he was angry.
- **Fix:** give the pad a per-beat icon (a fist or the orange on hold-meter) and reword the goal. Luan settles the tone (anger or determination) against C06.

**W18. "Back to the map" from pause throws away the whole mission with no confirmation, and its rule points to an edge case that doesn't exist.** (GDD)
- MF Rule 11 (L151–152) says "Leaving discards mission progress (see Edge Cases)", but there is no such edge case.
- A mistaken tap in the last encounter sends a 6-year-old back to the intro, which means W1's reading wall and the skip warning again. An OS kill of the backgrounded app on a low-end phone does the same (Rule 14). "A mission is short" assumes an adult's pace.
- **Fix:** add a confirm card with pictures. Consider resuming at the last beat start in memory, which needs no save change.

**W19. Taps during the audio preload are dropped with no feedback.** (GDD)
- Audio Rule 7 and its edge case (L254): input waits for the preload, but the title looks ready, so a child's tap does nothing.
- Android disables Start (50% alpha) until the sounds load, which is fine for that button. The rule should say every button shows disabled until then.
- **Fix:** add that to Rule 7 or the title UX.

**W20. A pre-reader can't read the skip warning.** (GDD)
- The warning's buttons, "Đọc tiếp" and "Vẫn bỏ qua" (MF UI L450–452), are text only. That goes against Language Rule 12 (icons back up text).
- **Fix:** add icons (an open book, a skip arrow), and voice the warning once VO exists.

**W21. A beat-end cheer plays right after the king sends the hero home.** (GDD; tone is content/Luan)
- MF Rule 2 (L60–61) gives every non-fight beat a cheer, so `sfx_beat_end_cheer` plays straight after "Cháu còn trẻ…".
- **Fix:** let a beat turn off its cheer (for example `cheer: false`), or use a neutral page turn after dialogue.

---

## Advisory

- **A1. Mission time:** MF F1's `T_play` range "10–90" and its "reach-the-flag 90 s" example exceed the ≤ 60 s beat cap (MF AC22, Combat AC23). Cap the range at 60 and redo the example (about 3.0 min). (GDD)
- **A2. Stale counts:** MF says "five types… 3–4 beats" in the Summary and Rule 9, but "Six beat types" in Rule 7. The hero mapping (L473–477) lists 4 beats with no dialogue. systems-index L15 says "4 side-scrolling beats". Should be six types and 3–5 beats. (GDD)
- **A3. One pad, three names:** `special` (data, MF, Hints), "flag pad" (Input) and "banner pad" (MF Rule 8). Use `special` everywhere and define the icon per beat (see W17). (GDD)
- **A4. Stale status labels:**
  - MF Cross-References still shows Quiz and Hints as "(planned)".
  - MF 7d says "R4c, requested", and Language Rule 8 says "VI (proposed, D-21)". Both rules already exist.
  - Hints AC4 says `stall` where F1 says `progress_timer`.
  - Concept L162 says "a missed beat slows down".
  (GDD)
- **A5. Small ownership gaps:**
  - Who emits the training goal (MF 7c logic vs Combat's goal-met list).
  - Save's dependency path for the medal (via HP or via Quiz).
  - Two overlapping reach-the-flag rows in Hints Rule 4.
  - Who advances `end_pause` (Combat step 11 vs MF Rule 2; baseline Info, still open).
  (GDD)
- **A6. Little difficulty headroom across heroes:** hero 1 already has the hardest pattern (two sides plus the leader). `tuning.json` is global, and the 60 s fight cap limits adding enemies. Write the curve lever down now (encounter composition, or per-encounter multipliers in mission params). (GDD, Luan)
- **A7. Spamming attack still wins every fight (baseline G1, D-13 open):** defend has no payoff. (Luan)
- **A8. Skipping everything and then guessing always unlocks the next hero:** only the why line teaches a skipper, and the play beats carry few of the 5 quiz facts. Make each beat show its fact: the orange in the hold pose, the six words on the banner, the enemy helmets. This links to the concept's Unique Hook wording (baseline, still open). (content/Luan)
- **A9. The language lint would flag the king's line:** Language Rule 10 and AC9 forbid "cháu" when addressing the child, but `tqt.d1.line.8` ("Cháu còn trẻ…") is the king speaking to the hero. Exempt speaker lines from the lint. (GDD)
- **A10. Held pad across a story phase:**
  - Input Rule 9 (TASK-019) keeps a pad held from down to up. Rule 14 hides pads on story screens, and a hidden pad is filtered, not released.
  - So a thumb that stays on ▶ through the Bình Than dialogue makes the hero walk on once `walk_to` resumes. That's intended (thumb drift is forgiven), and both apps do it, but no GDD says so.
  - **Fix:** add one edge case to Input ("a held pad hidden by a story phase acts again when it reappears, if still held"). Don't add a phase change to clear-all, which would contradict Rule 9.
  (GDD)
- **A11. Portrait or landscape is still an open question in the concept (L346):** every GDD and both apps are landscape (Android `sensorLandscape`). Android also draws a "rotate the phone" screen when the view is portrait (`Renderer.rotate`), and no GDD specifies it. Close the question and add the rotate screen to the mission HUD or title UX. (GDD)
- **A12. Map clusters depend on the device:** Map F2 clusters pins closer than `pin_world` = `pad_min / k`, so two phones can show different clusters. That's fine, but say so, and include k in the planned cluster fixture. (GDD)
- **A13. Monetization wording:** concept L67 says "no ads or purchases aimed at kids **unless Luan decides**". The *Safe for kids* pillar (L228) and anti-pillar (L240) say no ads, and no purchases aimed at kids. "Unless" leaves an opening that contradicts the pillar. Either reword it to match the pillar, or record it as an open pillar question. (Luan)
- **A14. A release build where every hero is hidden:** with C01–C16 pending, a release build would show an empty map and "More heroes are coming". In practice that can't happen, because the R12 build gate fails first (`production/qa/builds/TASK-007-release-gate.log`). D-03 is still the process gate. (content/Luan)
- **A15. D-22 (backup):** the platform backup of the save is the only way data can leave the phone. ADR-0003 now spells out the cost per platform (Android's `allowBackup` is false today). Decide before a Kids-category submission. (Luan)

---

## Number drift (tuning.json, rules.json, schema 1.4)

| Check | Result |
|---|---|
| Every `tuning.json` key is named by at least one GDD | **Pass**: all keys owned, including the TASK-005k keys `pad_gap` and `drag_threshold` (Input) |
| Every value in a GDD tuning or variable table equals `tuning.json` (value, range, unit) | **Pass**: no mismatch |
| Inline "`key` value" mentions vs data | **Pass**: 11 apparent mismatches were all legitimate (300 = `dummy_spacing`, 130 in Combat AC11's invalid-data example, 260 = `enter_to_approach_dist`, 0.8 = the R15 threshold, percent forms of the ratios) |
| Backticked identifiers in GDDs not in data or schema | Expected only: state and event names (`walk_to`, `windup_started`, `medal_earned`), save keys (`save_version`, `sound`; ADR-0003), the planned Audio `sfx_*` ids (W11 and gaps), and the Map Alpha knobs (`map_size`, `label_offset`, `pin_world`). Also `text_min_body` / `text_min_label`, which are prose-only (W9) |
| R8c field values vs Language Rule 8 line counts | **Pass**: `dialogue_line` 3 and `dialogue_narrator` 2 match. Only the MF 7d label is wrong (W6) |

## Spec vs build

| # | Area | GDD says | Android (TASK-007 @ 74a158e) | iOS (as reported) | Owner |
|---|---|---|---|---|---|
| S1 | Save (ADR-0003) | `save_version`; `sound` persisted; per-key salvage; one-unit quiz write; newer-save read-only; write survives a force-quit | Per-key SharedPreferences. No `save_version`. **Mute isn't saved**, so sound comes back on at every launch. No per-key validation. `lang` written with `apply()` (async; AC9 risk) | UserDefaults (AC9 risk, per ADR-0003) | Android + iOS, after ADR-0003 Accept |
| S2 | Audio | ~35 named cues, music states with crossfades, VO hooks, SoundPool maxStreams 9 and priorities, audio focus and AUDIO_BECOMING_NOISY clear | 7 placeholder synthesised tones, no music, no files | Synthesised placeholders | Both apps (ADR-0005) |
| S3 | Input | First-owner tie-break (Rule 6), 4% press squash (15), `pad_gap` (4), rounded-corner inset (2), route-change clear (11) | Not built (after-r3 list, on the board) | Some on iOS tip | Android |
| S4 | UX (TASK-021) | Page slide, portrait fade, ending crossfade, unlock with only "to map", title with the map-stub line and no legend | Not built. The unlock has "Play again"; the title has a controls legend | Not built (game-dev-ios) | Both apps |
| S5 | Hints | (B1) the ask hint has no Hints rule | Built (`askHint`) | Built | GDD (B1) |
| S6 | Pads per training step | (W12) not specified | Shows all 4 beat buttons | Same | GDD, then both apps |
| S7 | Rotate screen | No GDD (A11) | Built (`Renderer.rotate`) | Unknown | GDD |
| S8 | Medal only in the run that earns it | HP Rule 9 and edge case (L162) | Built (`ui.medal.earned` only in the run that first earns it) | Built | Consistent |
| S9 | Beat positions (F5) | (B2) Combat step 7 says otherwise | `beatX` = F5; the trace passes | Same; the trace passes | GDD (B2) |
| S10 | Dialogue (schema 1.4, R13d, R8c) | MF 7d | Built; the trace covers 9 lines and 2 asks | Built | Consistent |

---

## TASK-010 baseline

| Finding | Status | Now |
|---|---|---|
| C1 index edges (MF→Input, Hints→Content) | Fixed | New gaps: W10 |
| C2 stall timer owner and reset on resume | Fixed | Leftover wording: A4 |
| C3 Quiz "(R10)" for no text in pictures | Fixed | — |
| C4 Combat Rule 16 cited D-08 | Fixed | — |
| C5 Combat AC14 vs MF AC14 | Fixed | Leftover F1 range: A1 |
| Info: "proposed" tuning labels | Fixed | — |
| Info: `ui.results.more_heroes` | Not re-checked | Cited in HP Rule 10.3 and AC7 |
| Info: `end_pause` loop owner | Open | A5 |
| G1 defend dominated | Open | A7 (D-13) |
| G2 what stars measure | Open | W16 (D-14) |
| G3 stars have no payoff | Partly | Replay cost fixed by D-07; star payoff still D-14 |
| G4 Pillar 1 depends on D-08 | Closed | D-08 = B |
| G5 5th pad in fights | Closed in fights | Moved to training: W12 |
| S1 same card order on replay | Open | W14 (D-15) |
| S2 pause releases defend, telegraph restarts | Fixed | Consistent across MF, Combat, Input, Hints and Audio |
| S3 replay cost | Mostly closed | D-07 |
| S4 walk → card → walk | Open (Info) | Unchanged |
| S5 flee dead time | Open | Playtest |
| S6 best stars on results | Open | Quiz open question |
| Unique Hook wording | Open | A8 |

## Checked and consistent

- **Cross-reference numbers that resolve correctly:**
  - Save → MF 14, Quiz 9, HP 3–5/8/9/11, Language 2–3.
  - HP → MF 14–15, Quiz 8–9.
  - Audio → MF 11/12/15 and F1/F2, Combat F5/F6 and 5/12, HP 10, Save 1.
  - Input → MF 4/11/15/7d, Quiz 4 and AC6, Map 5 and F2, Audio 6/16, Combat 4.
  - Map → HP 4–7/10 and AC12.
  - MF AC22 → Combat AC23 and Rules 2/2b/15.
  - Every decision id cited exists in decisions.md.
- **Rules that agree across GDDs:**
  - pause, background and clear-all (MF, Input, Combat, Hints, Audio);
  - one tone per menu press, and play pads silent (Audio 6, Input 15/AC9; built on Android in d62d13c);
  - the 0.25 s press-time debounce, which carries across screen changes (Input F3, MF, 7d);
  - quiz shake drops taps (Quiz 4, Input 13);
  - skip and medal (MF 15, HP 9/10, Save 4/AC7);
  - save at quiz finish before results;
  - no special in fights (D-10).
- **Formula hand-offs:**
  - stars 1–3 flow from Quiz F1 to Save F1 to HP F2, and Quiz F1 matches README R16;
  - pin size comes from Input F1;
  - `drag_threshold` is used the same way in Input 16, Map 5 and Map AC12;
  - Quiz F2's guessing odds (8.6% for ≥ 2★ at N = 5) check out.
- **Safe for kids:**
  - there's no failure state: no lives, timers or lose screen;
  - the quiz always ends within 2N retries, and the hold meter never drains;
  - wrong answers are lavender, never red, and success is at least 6 dB louder than failure;
  - the death is one calm line, and Quiz Q7 bans death questions.
- **Network and data:** the GDDs have no network, download, analytics, account, ads, purchase, leaderboard, notification or upload wording. Every hit is a negation, or the offline install-time asset packs (Audio F2).
- **Cross-app parity:** `trace-tqt.json` replays identically on Android and iOS (4474 frames, 149 snapshots, 805 RNG draws).

## GDDs flagged for revision

| GDD | Findings | Priority |
|---|---|---|
| hints-and-onboarding | B1, W2, W5, A4, A5 | **Blocking** |
| side-scroll-combat | B2, W10 (Audio row), A5 | **Blocking** |
| mission-flow | B2, W3, W4, W6, W7, W12, W18, W20, W21, A1–A5 | **Blocking** (B2) |
| hero-progression | W2, W3, W4 | Warning |
| quiz-and-stars | W3, W4, W7, W14, W15 (content/Luan) | Warning |
| save-and-progress | W4, W10 | Warning |
| language-and-text | W8, W9, A9 | Warning |
| input-and-touch | W7, W8, A3, A10 | Warning |
| audio-and-voice-over | W10, W11, W19 | Warning |
| map-and-timeline | W5, W7, W8, A12 | Warning |
| game-concept | W1, W16, A11, A13 | Warning (Luan) |
| systems-index | W10, A2 | Warning |

**For Luan / decisions.md:**
- W1 (VO scope and reading load)
- W13 (what the medal means)
- W14 (D-15 shuffle)
- W15 and W17 (quiz pictures, Q1 wording, the orange beat's tone vs C06)
- A7 (D-13), A13 (monetization wording), A14 (D-03), A15 (D-22)
