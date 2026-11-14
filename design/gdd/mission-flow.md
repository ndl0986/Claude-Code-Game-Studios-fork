# Mission Flow & Beat Types

> **Status**: In Review
> **Author**: game-art-content (Luan decides)
> **Last Updated**: 2026-11-14
> **Last Verified**: 2026-11-14
> **Implements Pillar**: Sống lại câu chuyện (Live the story), Nhỏ chơi được (Small hands can do it)
> **Task**: TASK-008 · Tier: standard (Player Fantasy and Tuning Knobs skipped by tier; tuning lives in `content/data/tuning.json`)

## Summary

A mission plays one hero's famous story in a fixed order: story intro, then 3–4 beats in story
order, then a calm ending, then the quiz. Every beat is one of five types: walk, hold-meter,
training, fight and reach-the-flag. A beat can't be failed; it only ends when its goal is met.

> **Quick reference** — Layer: `Core` · Priority: `Vertical Slice` · Key deps: `Side-scroll movement & combat, Content data & claims, Language & text`

## Overview

The mission is the player's main unit of play. It is one hero, one story, about five minutes, and
it always ends at the quiz and then the map.

- **What this system owns:** the order of screens inside a mission, the beat types, which
  buttons each beat shows, how a beat starts and ends, and pause/resume.
- **What it does not own:**
  - how fighting works (Side-scroll movement & combat);
  - how the quiz scores (Quiz & stars);
  - what text says (content data in `content/data/heroes/<hero>/mission.json`, written from
    `design/narrative/heroes/<hero>.md`);
  - how hints are shown (Hints & onboarding).
- **Pillars:**
  - *Live the story*: the beat order *is* the story order, and a moment that isn't a fight (the
    orange) gets its own beat type rather than being forced into combat.
  - *Small hands can do it*: there are no lives, no game over and no timers that end a beat.

## Detailed Design

### Core Rules

1. **Fixed order.** A mission always runs in this order:
   1. `intro` (the story scene);
   2. the beats, in array order;
   3. `ending`;
   4. the quiz;
   5. results;
   6. unlock (when there is a `next_hero`);
   7. the map.
   The player can't reorder or skip beats.
2. **One beat at a time.** Each beat runs three phases:
   1. **Beat card:** the beat `title`, then its `scene` lines, one sentence per box, the child
      tapping "Tiếp / Next" for each. The `goal` line is shown last and stays on the HUD
      during play.
   2. **Play:** the type's rules below.
   3. **Beat end:** a short pause of `end_pause` with a cheer pose. If more beats follow, the
      next beat card comes next; after the last beat, the ending.
3. **No failure.** No beat type has lives, health, a timer that ends it, or a lose screen.
   Mistakes cost time and give a small knock-back only (combat GDD). A beat ends only when its
   goal is met.
4. **Only the beat's buttons are shown.** The HUD shows exactly the pads in the beat's
   `buttons`. Others are **hidden**, not greyed out, so a child never presses a button that
   does nothing. Pause, sound and the VI|EN switch are always shown.
5. **New buttons are taught where they first appear.** The first beat in a mission that lists a
   button teaches it. Hints & onboarding owns *how*; this system tells Hints which buttons are
   new in the beat.
6. **Banner.** A beat with `uses_banner: true` shows the mission's `banner` Text as a text layer
   on the banner prop, in the current language. It is never part of the art (art bible §3, §7).
7. **Five beat types** (`type` in `mission.schema.json`):

| Type | Buttons (typical) | The child does | Goal met when | Params (content) |
|---|---|---|---|---|
| `walk` | move | Moves right through a place with no enemies. Bumping a prop or animal stops the hero briefly | The hero reaches the beat's end, `length_screens` widths from the start | `length_screens` |
| `hold-meter` | special | Holds the special pad; a meter fills **only while held** and does **not drain** on release | The meter is full: `hold_seconds` of total holding | `hold_seconds` |
| `training` | move, attack, defend, special | (a) hits `dummies` straw dummies; (b) blocks `blocks` padded practice strikes from a friendly partner; (c) taps special once to finish (e.g. raise the banner) | All three parts done, in that order | `dummies`; **proposed:** `blocks`, `finish_special` (D-06) |
| `fight` | move, attack, defend | Fights a group of enemies as the combat GDD defines | Every enemy in `enemies` has run away | `enemies`, `max_active`, `from_left` |
| `reach-the-flag` | move, attack, defend, special | Moves right to a flag; optional enemy groups on the way lock the camera until they run away | The hero touches the flag | `length_screens`; **proposed:** optional `encounters[]` of fight params (D-06) |

8. **Special in combat beats.** Special in `reach-the-flag` (the banner wave) makes followers
   cheer and gives a short push, as the combat GDD defines. It is never required to finish the
   beat.
9. **Stand-in rule for the vertical slice.** Proposed P-02 stays: an app that does not implement
   a type yet plays it as a `fight` with the beat's text and logs a warning. That is debug only.
   A release build fails validation if any beat uses a type the app does not implement.
10. **Ending.** The `ending.lines` show one per box over `ending.picture_id`, a still picture
    with no animation of injury or death (art bible §2 "calm ending"). There is no gameplay.
    "Tiếp / Next" goes to the quiz.
11. **Pause.** Pause works in every phase. It freezes play timers, enemy states and the hold
    meter. The menu offers: keep playing, sound, VI|EN, and back to the map. Leaving discards
    mission progress (see Edge Cases).
12. **Language switch.** VI|EN can be switched at any moment. On-screen Text re-renders in the
    new language in the same frame. A voice line that is playing stops, and the current box's
    line replays in the new language.
13. **Claim gate.** Before the intro, the mission asks Content data whether it may run (rule R12
    in `content/README.md`).
    - In a release build, a mission with any pending claim is hidden from the map, so it
      never starts.
    - In a debug build, the mission runs and pending lines show `UNSIGNED Cxx`.
14. **Saving.** Nothing is saved mid-mission. Results are saved only when the quiz finishes
    (Quiz & stars, Save & progress). A mission is short (Formula F1), so a restart costs little.

### States and Transitions

| State | Entered from | Leaves to | Trigger |
|---|---|---|---|
| `gate_check` | map (hero tapped) | `intro` / back to map | Claim gate passes / fails. A release map already hides a failing hero, so this is a safety re-check. Debug always passes |
| `intro` | `gate_check` | `beat_card[0]` | Last intro box's "Tiếp / Next" |
| `beat_card[i]` | `intro` or `beat_end[i-1]` | `beat_play[i]` | Last scene box's "Tiếp / Next" |
| `beat_play[i]` | `beat_card[i]` | `beat_end[i]` | The type's goal is met |
| `beat_end[i]` | `beat_play[i]` | `beat_card[i+1]` or `ending` | `end_pause` elapsed |
| `ending` | `beat_end[last]` | `quiz` | Last ending box's "Tiếp / Next" |
| `quiz` | `ending` | `results` | Quiz & stars: last question answered right |
| `results` | `quiz` | `unlock` / `map` | "Tiếp / Next"; `unlock` only if `next_hero` is not null |
| `unlock` | `results` | `map` | "Về bản đồ / Back to the map" |
| `paused` | any state above | the same state / `map` | "Chơi tiếp / Keep playing" / "Về bản đồ" |

Story boxes (`intro`, `beat_card`, `ending`) advance only on a tap on "Tiếp / Next", which fires
on release (P-01). They never advance on a timer, because a child reads or listens at their
own pace.

### Interactions with Other Systems

| System | Data in | Data out | Owner of the interface |
|---|---|---|---|
| Content data & claims | `mission.json` (hero, intro, banner, beats, ending), claim status | gate result request | Content (schema `content/schema/mission.schema.json`) |
| Side-scroll movement & combat | goal-met event for fight, reach-the-flag, walk and training; hero position | beat type, params, button set, camera lock zones | Combat GDD |
| Input & touch controls | pad press/hold/release events | visible pad set per beat | Input GDD |
| Hints & onboarding | (none) | "new buttons in this beat", "beat started", "no progress for `hint_delay` s" (`tuning.json`, 5 s) | Hints GDD |
| Language & text | current language, language-changed event | Text ids to render | Language GDD |
| Audio & voice-over | (none) | line id to voice, state changes for music | Audio GDD |
| Quiz & stars | quiz finished + stars | "start quiz for hero X" | Quiz GDD |
| Hero progression & unlock | `next_hero` from content | "mission completed" after the quiz | Progression GDD |

## Formulas

The F1 (mission length estimate) formula is defined as:

`T_mission = T_intro + Σ_i (T_card_i + T_play_i + end_pause) + T_ending`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| T_intro, T_card_i, T_ending | float (s) | 5–40 | calculated: boxes × T_box | Story time; T_box ≈ voice length of a box |
| T_box | float (s) | 3–8 | constant ⟨tuning: measure from the first voice-over⟩ | One sentence of ≤120 chars read aloud |
| T_play_i | float (s) | 10–90 | calculated per type (F2–F4; fight from combat GDD) | Play time of beat i |
| end_pause | float (s) | 0–3 | `tuning.json` `end_pause` (0.6) | Pause after a beat |

**Output Range:** target 3–5 minutes before the quiz, so a mission plus its quiz fits a
5–15 minute session (concept). Above 6 minutes, cut scene boxes before cutting beats.
**Example:** 3 intro boxes, 4 beats with 2 boxes each, 2 ending boxes, T_box 5 s gives
65 s of story. Play: walk 12 s + hold 3 s + training 40 s + reach-the-flag 90 s = 145 s.
end_pause 4 × 0.6 = 2.4 s. T_mission ≈ 212 s ≈ 3.5 min.

The F2 (walk time) formula is defined as:

`T_walk = length_screens × world_width / hero_speed`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| length_screens | float | 0–10 (schema); use 2–4 | data file (beat params) | Beat length in screen widths |
| world_width | int (px) | 1280 | constant (`tuning.json` world) | One screen width in world units |
| hero_speed | float (px/s) | 120–600 | data file (`tuning.json` `hero_speed`, 330) | Hero walk speed |

**Output Range:** 2–4 screens takes 7.8–15.5 s at 330 px/s, which is short enough for a
6-year-old to stay engaged. A bump stop adds at most 0.5 s each ⟨tuning⟩.
**Example:** 3 × 1280 / 330 = 11.6 s.

The F3 (hold meter) formula is defined as:

`meter = min(1, held_total / hold_seconds)`, where `held_total` grows by `dt` only while the special pad is down, and never decreases.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| held_total | float (s) | 0–hold_seconds | calculated | Total time the pad has been held in this beat |
| hold_seconds | float (s) | 0–10 (schema); use 1.5–4 | data file (beat params) | Holding needed to fill the meter |
| dt | float (s) | frame time | engine | Time since the last frame |

**Output Range:** 0 to 1. The beat ends when it reaches 1. With hold_seconds ≤ 0 the schema
already rejects it (exclusiveMinimum 0).
**Example:** hold_seconds 2.5. The child holds 1.2 s, lets go and holds again for 1.3 s, so
meter = 2.5 / 2.5 = 1 and the beat ends.

The F4 (training time estimate) formula is defined as:

`T_training ≈ dummies × (attack_time + attack_cooldown + walk_gap) + blocks × (telegraph + strike_time + enemy_rest) + T_special`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| dummies | int | 1–10 (schema); use 3 | data file (beat params) | Straw dummies to hit |
| blocks | int | 1–5 (proposed); use 3 | data file (beat params, D-06) | Practice strikes to block |
| attack_time, attack_cooldown | float (s) | see tuning | `tuning.json` (0.28, 0.12) | One swing and its gap |
| walk_gap | float (s) | 1–3 | constant ⟨tuning⟩ | Walking to the next dummy |
| telegraph, strike_time, enemy_rest | float (s) | see tuning | `tuning.json` (1.1, 0.25, 1.6) | The partner's practice strike cycle |
| T_special | float (s) | 1–3 | constant ⟨tuning⟩ | Tapping special and the banner rising |

**Output Range:** 15–40 s with the suggested values.
**Example:** 3 × (0.28 + 0.12 + 2) + 3 × (1.1 + 0.25 + 1.6) + 2 = 7.2 + 8.85 + 2 ≈ 18 s, plus
first-time hint pauses.

Fight and reach-the-flag encounter times come from the Side-scroll movement & combat GDD.

## Edge Cases

- **If a beat lists a button its type never uses** (e.g. `walk` with `attack`): the pad is shown
  and does its normal action, but nothing requires it. Validation **warns** (it doesn't fail),
  because a content writer may add it for feel.
- **If a beat's `buttons` lacks a button its goal needs** (e.g. `hold-meter` without
  `special`): validation **fails** the bundle. The goal could never be met.
- **If the child releases special at meter 0.99**: the meter holds at 0.99 (no drain), and the
  next press finishes it.
- **If special is pressed during training before the dummies and blocks are done**: the special
  pose plays, nothing finishes, and the hint shows the step still to do. Special completes
  training only as the last step.
- **If the hero is pushed back during walk or reach-the-flag**: progress is position-based, so
  the child walks forward again. Nothing resets.
- **If the app goes to the background mid-beat**: the game enters `paused` automatically and
  stays there when the app comes back. Nothing advances while it is backgrounded.
- **If the app is killed mid-mission**: the next launch opens the map, and the mission starts
  again from `intro`. No mid-mission state is saved (Core Rule 14).
- **If the language switches during a voice line**: the line stops, and the same box replays in
  the new language. The box index doesn't change.
- **If the language switches while the hold meter is filling**: the meter keeps filling. The
  switch is a UI tap on the VI|EN toggle and does not release the special pad on another finger.
- **If a beat's `scene` is empty**: the beat card shows only `title` and `goal` for one tap.
  Schema allows this, and it is fine for a pure-action beat.
- **If `next_hero` is null** (the last hero shipped): `results` goes straight to `map`, with a
  "Còn nhiều anh hùng nữa sắp đến / More heroes are coming" UI string.
- **If a release build finds a pending claim at `gate_check`**: the hero's place on the map is
  hidden. This is never a crash or an error screen in front of a child (R12).
- **If a mission has 1 or 2 beats**: it is allowed (schema minItems 1). The design target stays
  3–4 beats per hero.
- **If a story box line is over the EN budget**: the build fails validation (R8). Text never
  shrinks to fit.

## Dependencies

| System | Direction | Hard/Soft | Interface |
|---|---|---|---|
| Content data & claims | this depends on it | Hard | `mission.json` per `content/schema/mission.schema.json`; claim gate R12 |
| Side-scroll movement & combat | this depends on it | Hard | Runs `fight` and the encounters in `reach-the-flag`; movement for `walk`; goal-met events |
| Language & text | this depends on it | Hard | Renders every Text; language-changed event |
| Input & touch controls | this depends on it | Hard | Pad events; pad visibility per beat |
| Hints & onboarding | depends on this | Soft (for this) | New-button list, beat start, no-progress signal |
| Audio & voice-over | depends on this | Soft | Line ids to voice; music state |
| Quiz & stars | depends on this (it is started by this) | Hard (for the loop) | "start quiz", "quiz finished + stars" |
| Hero progression & unlock | depends on this | Hard | "mission completed", `next_hero` |
| Save & progress | indirect, through Quiz & stars | — | Nothing saved mid-mission |

The combat, quiz, hints, language, audio, input and progression GDDs must each list Mission
flow in their own Dependencies (bidirectional rule).

## Visual/Audio Requirements

Art-director lens (art bible §§2–7):
- **Story boxes** (`intro`, `beat_card`, `ending`) use the art bible §2 "story scene" mood: a
  warm paper frame with the bronze-drum ring, the picture above and the text box below.
- **Ending** uses §2 "calm ending": a still picture, soft dawn or dusk haze, one warm light that
  stays. There is no death scene and no fallen figure (D3 in the hero doc).
- **Beat themes** (`village`, `bamboo`, `river`, `camp`) are stand-in background sets (§6),
  and no theme is a history claim. A real place needs a sourced claim and the map system.
- **Hold-meter:** the meter is a ring around the special pad that fills in gold (§4 bronze
  gold). The hero's pose builds with it (in the orange beat: puffed cheeks, clenched fist; §5
  "never a scary face").
- **Training:** straw dummies wobble and spring back. They never break apart. The practice
  partner wears the hero's team colour, so the child never reads them as an enemy (§5).
- **Banner:** the banner shape is plain cloth (§3), and the text layer sits on it.
- **Beat end:** a cheer pose, plus a small star sparkle on the beat progress dots.
- **Audio:**
  - each story box plays its voice line, by Text id (Audio GDD, planned `vo`);
  - music changes per state: story (soft), walk or training (light), fight or flag (drums),
    ending (quiet), as art bible §2 sets the mood;
  - each pad press gives one tone (QC O6).

📌 **Asset Spec**: after this GDD is approved, run `/asset-spec system:mission-flow` for the
story frame, the meter ring, the dummies, the practice partner, the flag and the beat-end
sparkle.

## Game Feel

- **Story boxes:** the tap advances on release with a 0.1–0.15 s soft page slide. A double tap
  never skips two boxes, so taps within 0.25 s of an advance are ignored ⟨tuning⟩.
- **Hold-meter:** the meter rises smoothly with no steps. A light pulse (and haptic, where
  available) fires at 25/50/75/100% ⟨tuning⟩.
- **Beat end:** a short beat of quiet (`end_pause` 0.6 s, the prototype's value) before the
  cheer. Keep it under 1 s so it never feels like waiting. Not yet checked by a playtest.
- **No dead time:** from a goal being met to the next card is under 1.5 s in total.

## UI Requirements

- **Story screen:** picture, one text box (one sentence), "Tiếp / Next" on the right, and the
  VI|EN toggle top-right. The box fits the EN budget (`rules.json` `scene` 120).
- **HUD during play:**
  - pause and sound, top-left;
  - beat progress dots, top-centre (one per beat, filled when done);
  - VI|EN, top-right;
  - the `goal` line under the dots (`goal` budget 60);
  - the beat's pads, bottom (Input GDD, `pad_min` 72 pt/dp).
- **Hold-meter ring** around the special pad, and a training checklist of three icons
  (dummies, shield, banner) that fill as each part is done. Icons only, no words.
- **Pause menu:** keep playing, sound, VI|EN, back to the map.

📌 **UX Flag — Mission Flow**: this system has UI requirements. In Pre-Production, run
`/ux-design` for the story screen, the mission HUD and the pause menu before writing epics.

## Cross-References

| This doc references | Where | What |
|---|---|---|
| Game concept | `design/gdd/game-concept.md` | Mission structure, pillars, session length |
| Content data contract | `content/README.md`, `content/schema/mission.schema.json`, `content/data/tuning.json`, `content/data/rules.json` | Beat fields, params, text limits, claim gate R12 |
| Art bible | `design/art/art-bible.md` §§2–7 | Moods per state, banner text layer, no injury |
| Hero content | `design/narrative/heroes/tran-quoc-toan.md` §3, §6 | The approved 4-beat structure for Trần Quốc Toản |
| Side-scroll movement & combat | `design/gdd/side-scroll-combat.md` (next GDD) | Fight rules, encounter time, special in combat |
| Quiz & stars | `design/gdd/quiz-and-stars.md` (planned) | Quiz start and finish |
| Hints & onboarding | `design/gdd/hints-and-onboarding.md` (planned) | Teaching new buttons, the no-progress hint |
| Decisions | `production/team/decisions.md` P-01, P-02, D-06, D-07 | Press/release, stand-in types, schema params, story skip |
| Prototype evidence | `203d73e` `prototypes/tqt-mission/config.js`; QC r3 (Android) | Tuning values, `end_pause`, one tone per press |

**Trần Quốc Toản's approved structure maps to types like this** (hero doc §6):
- Beat 1, riverbank → `walk`
- Beat 2, the orange → `hold-meter`
- Beat 3, the banner → `training` (`uses_banner`)
- Beat 4, battle → `reach-the-flag` with encounters (`uses_banner`)

## Acceptance Criteria

1. **GIVEN** a mission with 4 beats, **WHEN** the child plays it through, **THEN** the screens
   appear in exactly this order: intro → card 1 → play 1 → card 2 → … → play 4 → ending → quiz
   → results → unlock → map.
2. **GIVEN** any beat in play, **WHEN** the hero is hit any number of times, **THEN** no lose
   screen, life counter or restart appears, and the beat stays in play until its goal is met.
3. **GIVEN** a beat with `buttons: [move]`, **WHEN** it is in play, **THEN** only the move pads
   (plus pause, sound and VI|EN) are visible.
4. **GIVEN** a `walk` beat with `length_screens` 3, **WHEN** the hero holds move right without
   bumping, **THEN** the beat ends after 11.6 s ± 0.5 s (F2 at `hero_speed` 330).
5. **GIVEN** a `hold-meter` beat with `hold_seconds` 2.5, **WHEN** the child holds 1.2 s,
   releases for 3 s and holds again, **THEN** the meter stays at 48% during the release and the
   beat ends after 1.3 s more of holding (F3).
6. **GIVEN** a `training` beat with dummies 3 and blocks 3, **WHEN** the child taps special
   before hitting all 3 dummies, **THEN** the beat does not end, and it ends only after 3 hits,
   3 blocks and then a special tap.
7. **GIVEN** a `reach-the-flag` beat with one encounter, **WHEN** the hero reaches the
   encounter zone, **THEN** the camera locks until every enemy in it has run away, and the beat
   ends when the hero touches the flag.
8. **GIVEN** a beat with `uses_banner: true`, **WHEN** the language is switched, **THEN** the
   banner text changes language in the same frame, and the banner picture has no text in it
   (checked with the text layer hidden).
9. **GIVEN** any story box, **WHEN** the child taps "Tiếp" twice within 0.25 s, **THEN** only
   one box advances.
10. **GIVEN** the hold meter at 60% and play in progress, **WHEN** the app goes to the
    background and returns, **THEN** the game is paused, the meter still reads 60%, and no
    enemy acted while it was backgrounded.
11. **GIVEN** a release build and a mission with one pending claim, **WHEN** the map loads,
    **THEN** that hero cannot be started, and no error is shown to the child. **GIVEN** a debug
    build, **THEN** the mission plays and pending lines show `UNSIGNED Cxx`.
12. **GIVEN** a voice line playing in VI, **WHEN** the child switches to EN, **THEN** the VI
    line stops within 0.1 s and the same box's EN line plays.
13. **GIVEN** the app killed during beat 3, **WHEN** it relaunches, **THEN** the map opens and
    starting the hero begins at the intro.
14. **GIVEN** the Trần Quốc Toản mission data, **WHEN** it is played, **THEN** the total time
    before the quiz is 3–5 minutes for an adult tester playing straight through (F1 target).
    This is a playtest check, recorded in `production/qa/evidence/`.

## Open Questions

| # | Question | Owner | By |
|---|---|---|---|
| D-06 | Schema params: training needs `blocks` and `finish_special`; reach-the-flag needs optional `encounters[]`. A schema change needs both devs and game-art-content | game-dev-ios + game-dev-android, game-art-content | Before TASK-003b content goes into `mission.json` |
| D-07 | Story skip: on the first play every box is tapped through; on a replay, offer a "Bỏ qua / Skip story" button? | Luan | Before the vertical-slice playtest |
| D-08 | The vertical slice beat set: keep the 4 fights from TASK-003 (P-02), or build the approved 4-beat structure (walk, hold-meter, training, reach-the-flag)? | Luan | Before TASK-006/007 content freeze |
| — | T_box: measure real voice-over length per box once the first VO is recorded, then re-check F1 | audio-director / game-art-content | First VO recording |
