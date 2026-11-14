# Mission Flow & Beat Types

> **Status**: Approved (peer review: game-dev-ios, 2026-11-14)
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
   7. the map. **Vertical slice:** there is no map yet, so "the map" means the **title
      screen** everywhere in this GDD until the Map & timeline system ships.
   The player can't reorder or skip beats.
2. **One beat at a time.** Where the beat's `scene` lines go depends on the type:
   - **`fight` beats** (the prototype order, P-04): the hero walks into the fight, and the
     `goal` line shows on the HUD. Then comes play, then `end_pause`, then the **caption**:
     the `scene` lines, one sentence per box, each advanced by "Tiếp / Next". The caption
     retells the moment just played, and a fight needs no set-up to start.
   - **Non-fight beats** (`walk`, `hold-meter`, `training`, `reach-the-flag`): a **beat
     card** comes **before** play. It shows the `title`, then the `scene` lines one per box,
     then the `goal`, which stays on the HUD. These beats are story moments that make no sense
     without their set-up: a child can't know why to hold the orange unless the story says so
     first.
   - **Beat end, every type:** `end_pause`, then a fight goes to its caption, and every other
     type gets a cheer and the hero walks on.
   - After a fight's caption (or a non-fight beat's end), the hero walks right to the next beat's
     start `beatX(i+1)` (F5). After the last beat comes the ending.
   - **Pads by phase:** during `walk_to` only move is shown; in play and beat end, the beat's
     `buttons`; on story screens, no pads.
3. **No failure.** No beat type has lives, health, a timer that ends it, or a lose screen.
   Mistakes cost time and give a small knock-back only (combat GDD). A beat ends only when its
   goal is met.
4. **Only the beat's buttons are shown.** The HUD shows exactly the pads in the beat's
   `buttons`. Others are **hidden**, not greyed out, so a child never presses a button that
   does nothing. Pause and sound are always shown. VI|EN is on the title screen and in the
   pause menu only (P-04).
5. **New buttons are taught where they first appear.** The first beat in a mission that lists a
   button teaches it. Hints & onboarding owns *how*; this system tells Hints which buttons are
   new in the beat.
6. **Banner.** A beat with `uses_banner: true` shows the mission's `banner` Text as a text layer
   on the banner prop, in the current language. It is never part of the art (art bible §3, §7).
7. **Six beat types** (`type` in `mission.schema.json`; `dialogue` added by TASK-016, schema 1.4 requested):

| Type | Buttons (typical) | The child does | Goal met when | Params (content) |
|---|---|---|---|---|
| `walk` | move | Moves right through a place with no enemies. Bumping a prop or animal stops the hero briefly | The hero reaches the beat's end, `length_screens` widths from the start | `length_screens` |
| `hold-meter` | special | Holds the special pad; a meter fills **only while held** and does **not drain** on release | The meter is full: `hold_seconds` of total holding | `hold_seconds` |
| `dialogue` | none (no pads) | Reads an illustrated exchange: one line per box with the speaker's portrait (hero, guard, king…) or narrator text, tapping "Tiếp". At `ask.at_line` a big ask button (e.g. "Xin vào! / Let me in!") replaces "Tiếp"; each tap plays the next line, `ask.taps` times | The last line is advanced | `lines[]` of {`speaker`, `text`}; optional `ask` {`button` (UiText id), `taps` 1–3, `at_line`} |
| `training` | move, attack, defend, special | (a) hits `dummies` straw dummies; (b) blocks `blocks` padded practice strikes from a friendly partner; (c) taps special once to finish (e.g. raise the banner) | All three parts done, in that order | `dummies`; `blocks`, `finish_special` (schema 1.1, D-06) |
| `fight` | move, attack, defend | Fights a group of enemies as the combat GDD defines | Every enemy in `enemies` has run away | `enemies`, `max_active`, `from_left` |
| `reach-the-flag` | move, attack, defend | Moves right to a flag; optional enemy groups on the way lock the camera until they run away | The hero touches the flag | `length_screens`; optional `encounters[]` (schema 1.1, D-06) |

7b. **Minimum buttons per type (validation R13, schema 1.1 / D-06).** A beat's `buttons` must
    include at least:
    - `walk`: {move};
    - `hold-meter`: {special};
    - `training`: {move, attack}, + defend if `blocks` > 0, + special if `finish_special`;
    - `fight`: {move, attack}. Defend is optional, because blocking is taught, never required
      (combat GDD);
    - `reach-the-flag`: {move}, + attack if it has any encounter;
    - `dialogue`: **none**. `buttons` must be empty, and no pads are shown.

    `special` is allowed only on hold-meter and training with `finish_special` (D-10: B, Luan
    2026-11-14). R13 in `content/README.md` must match: no special on reach-the-flag.
7c. **Training and hold-meter details** (devs' parity review):
    - **Training dummies** stand at `x_start + (k + 1) × dummy_spacing` for k = 0 … dummies−1
      (`dummy_spacing` in `tuning.json`, 300 px).
    - **Training partner** (for `blocks`): it stands at `enemy_reach − stand_gap` in front of the
      hero. Its first windup starts after `approach_min_time`, with the normal `telegraph`, and
      the strike resolves as in combat. **A block counts only if defend is held when the strike
      resolves** (combat F6). An unblocked practice strike is a small push, as in combat, and
      doesn't count.
    - **Hold-meter:** `held_total` is capped at `hold_seconds` (F3). Hints' no-progress timer
      resets on every frame the meter rises.
7d. **Dialogue beats** (TASK-016, Luan's Bình Than exchange):
    - **Order:** a dialogue beat has **no** separate beat card. Its `title` shows as the heading
      over its first line, and its lines are the story. There's no caption either.
    - **Speakers:** each line's `speaker` is `narrator` (no portrait, centred box) or a speaker
      id with a portrait asset per hero (`pic.portrait_<hero>_<speaker>`). The portrait sits on
      the speaker's side (hero left, others right). Mood variants (e.g. pleading, puffed cheeks)
      are separate picture ids.
    - **Ask button:** at `ask.at_line` the "Tiếp" button is replaced by the ask button (UiText,
      `button` field type). Each tap advances to the next line; after `ask.taps` taps "Tiếp"
      returns. The ask is the child's action in the scene: it's never failed, and it can't be
      skipped except by Skip (Rule 15).
    - **Skip and medal:** Skip works as on every story screen (Rule 15). Skipping a dialogue
      beat sets `story_skipped`, so no medal this run.
    - **Legend marker (R4c, requested):** spoken lines of a dialogue beat that cite a legend
      claim don't each need a marker, if the beat's **first line** is a narrator line carrying
      a legend marker (VI and EN) that cites the same claim or claims. Narration inside the beat
      is covered the same way.
    - **Language switch** mid-dialogue (from pause): the same line shows in the new language;
      ask taps already made stay counted.
    - **Hints:** if the ask button isn't tapped for `hint_delay`, the hint hand points at it
      (Hints GDD, stuck hint for the current action).
8. **No special in combat beats** (D-10: B, Luan 2026-11-14). Fights and reach-the-flag
   encounters use move, attack and defend only. The banner pad appears only in hold-meter and
   training. A banner wave in combat may come later (combat GDD Rule 16).
9. **All five types are built for the slice** (D-08: B, Luan 2026-11-14; P-02 is superseded).
   While an app is still building a type, a debug build may play it as a `fight` with the beat's
   text and log a warning. A release build fails validation if any beat uses a type the app does
   not implement.
10. **Ending.** The `ending.lines` show one per box over `ending.picture_id`, a still picture
    with no animation of injury or death (art bible §2 "calm ending"). There is no gameplay.
    "Tiếp / Next" goes to the quiz.
11. **Pause.** Pause works in every phase. It freezes play timers, enemy states and the hold
    meter. **Pause releases every held pad** (move, defend, special). On resume nothing is held
    until the child presses again. Combat restarts a current windup's telegraph from 0 on resume
    (combat GDD, edge cases), so the child always gets the full warning. The menu offers: keep playing, sound, VI|EN, and back to the map (the title screen in
    the slice). Leaving discards mission progress (see Edge Cases).
12. **Language switch.** VI|EN is switched on the title screen or in the pause menu, which can
    be opened at any moment. On resume, all on-screen Text is in the new language. **Voice-over
    (planned `vo`, not in the slice):** a voice line playing when pause opens stops, and on resume
    the current box's line plays in the new language.
13. **Claim gate.** Before the intro, the mission asks Content data whether it may run (rule R12
    in `content/README.md`).
    - In a release build, a mission with any pending claim is hidden from the map, so it
      never starts.
    - In a debug build, the mission runs and pending lines show `UNSIGNED Cxx`.
14. **Saving.** Nothing is saved mid-mission. Results are saved only when the quiz finishes
    (Quiz & stars, Save & progress). A mission is short (Formula F1), so a restart costs little.
15. **Skipping the story and the medal** (D-07, Luan's decision 2026-11-14):
    - Every story screen (`intro`, `beat_card`, `caption`, `ending`) shows **"Bỏ qua / Skip"**
      on **every** play, first play included. Not on the quiz `why` line, which belongs to the quiz.
    - A Skip tap opens a short, kind **warning**: skipping means this story's medal isn't
      earned this time. It offers "Đọc tiếp / Keep reading" (the bigger, default button) and
      "Vẫn bỏ qua / Skip anyway". Nothing is shamed and nothing else is lost.
    - "Keep reading" closes the warning and returns to the same box. The warning **comes back
      on the next Skip tap**.
    - "Skip anyway" jumps past the remaining boxes **of that story screen only** (e.g. the rest
      of the intro) and marks the run `story_skipped = true`. Only "Skip anyway" stops the
      warnings: later Skip taps in the same run skip at once, because the medal is already out
      of reach for this run.
    - If the hero's medal is **already earned**, Skip never warns. It just skips, because the
      medal can't be lost.
    - Play, the quiz, stars and the unlock are **unaffected** by skipping. The medal is separate
      from the stars: stars measure the quiz, the medal rewards hearing the whole story.
    - **Medal rule:** when the quiz finishes, if `story_skipped` is false (every box was advanced
      with "Tiếp"), Mission flow reports `medal_earned` to Hero progression, which saves
      `medal.<hero_id>` once, never lost (Hero progression GDD). A box counts as read when
      advanced by "Tiếp"; reading speed is not checked.

### States and Transitions

| State | Entered from | Leaves to | Trigger |
|---|---|---|---|
| `gate_check` | map (hero tapped) | `intro` / back to map | Claim gate passes / fails. A release map already hides a failing hero, so this is a safety re-check. Debug always passes |
| `intro` | `gate_check` | `walk_to[0]` | Last intro box's "Tiếp / Next" |
| `walk_to[i]` | `intro`, or the end of beat i−1 | `beat_card[i]` (non-fight) / `beat_play[i]` (fight) | Hero x ≥ `beat_start_x + i × beat_gap` |
| `beat_card[i]` | `walk_to[i]` (non-fight only) | `beat_play[i]` | Last card box's "Tiếp / Next" |
| `beat_play[i]` | `beat_card[i]` or `walk_to[i]` | `beat_end[i]` | The type's goal is met |
| `dialogue_line[i][k]` | `walk_to[i]` (dialogue beats; no card) | the next line, or `beat_end[i]` after the last | "Tiếp", or an ask tap at `ask.at_line` |
| `beat_end[i]` | `beat_play[i]` | `caption[i]` (fight) / `walk_to[i+1]` or `ending` (non-fight) | `end_pause` elapsed |
| `caption[i]` | `beat_end[i]` (fight only) | `walk_to[i+1]` or `ending` | Last caption box's "Tiếp / Next" |
| `ending` | `beat_end[last]` | `quiz` | Last ending box's "Tiếp / Next" |
| `quiz` | `ending` | `results` | Quiz & stars: last question answered right |
| `results` | `quiz` | `unlock` / `map` | "Tiếp / Next"; `unlock` only if `next_hero` is not null |
| `unlock` | `results` | `map` | "Về bản đồ / To the map" |
| `paused` | any state above | the same state / `map` | "Chơi tiếp / Keep playing" / "Về bản đồ" |
| `skip_warning` | any story screen (Skip tapped, medal not yet earned, no "Skip anyway" yet this run) | the same box / the next non-story state | "Đọc tiếp / Keep reading" / "Vẫn bỏ qua / Skip anyway" (sets `story_skipped`) |

In the vertical slice, every `map` in this table is the **title screen**.

Story boxes (`intro`, `beat_card`, `caption`, `ending`) advance only on a tap on "Tiếp / Next", or
past the whole screen with "Bỏ qua / Skip" (Core Rule 15). Both fire on release (P-01). They never advance on a timer, because a child reads or listens at their
own pace.

### Interactions with Other Systems

| System | Data in | Data out | Owner of the interface |
|---|---|---|---|
| Content data & claims | `mission.json` (hero, intro, banner, beats, ending), claim status | gate result request | Content (schema `content/schema/mission.schema.json`) |
| Side-scroll movement & combat | goal-met event for fight, reach-the-flag, walk and training; hero position | beat type, params, button set, camera lock zones | Combat GDD |
| Input & touch controls | pad press/hold/release events | visible pad set per beat | Input GDD |
| Hints & onboarding | (none) | "new buttons in this beat", "beat started", card or caption closed, progress events (hero moved, meter rose, training step done). Hints owns the no-progress timer and `hint_delay` | Hints GDD |
| Language & text | current language, language-changed event | Text ids to render | Language GDD |
| Audio & voice-over | (none) | line id to voice, state changes for music | Audio GDD |
| Quiz & stars | quiz finished + stars | "start quiz for hero X" | Quiz GDD |
| Hero progression & unlock | `next_hero` from content; whether the medal is already earned | "mission completed" after the quiz, plus `medal_earned` when no story screen was skipped | Progression GDD |

## Formulas

The F1 (mission length estimate) formula is defined as:

`T_mission = T_intro + Σ_i (T_card_i + T_play_i + end_pause) + T_ending`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| T_intro, T_card_i, T_ending | float (s) | 5–40 | calculated: boxes × T_box | Story time; T_box ≈ voice length of a box |
| T_box | float (s) | 3–8 | estimate only, not a runtime value (re-measure when voice-over exists) | One sentence of ≤120 chars read aloud or read by the child |
| T_play_i | float (s) | 10–90 | calculated per type (F2–F4; a fight or encounter set per combat F3: a 20–60 s child target, ≤ 60 s for an adult not blocking, combat AC14) | Play time of beat i |
| end_pause | float (s) | 0–3 | `tuning.json` `end_pause` (0.6) | Pause after a beat |

**Output Range:** target 3–5 minutes before the quiz, so a mission plus its quiz fits a
5–15 minute session (concept). Above 6 minutes, cut scene boxes before cutting beats.
**Example:** 3 intro boxes, 4 beats with 2 boxes each, 2 ending boxes, T_box 5 s gives
65 s of story. Play: walk 12 s + hold 3 s + training 40 s + reach-the-flag 90 s = 145 s.
end_pause 4 × 0.6 = 2.4 s. T_mission ≈ 212 s ≈ 3.5 min.

The F2 (walk time) formula is defined as:

`T_walk = length_screens × world_width / hero_speed`

The walk beat **starts** at `x_start` = the hero's x when play begins (at the beat start, `beat_start_x + i × beat_gap`). It **ends** when hero x ≥ `x_start + length_screens × world_width`.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| length_screens | float | 0–10 (schema); use 2–4 | data file (beat params) | Beat length in screen widths |
| world_width | int (px) | 1280 | constant (`tuning.json` world) | One screen width in world units |
| hero_speed | float (px/s) | 120–600 | data file (`tuning.json` `hero_speed`, 330) | Hero walk speed |

**Output Range:** 2–4 screens takes 7.8–15.5 s at 330 px/s, which is short enough for a
6-year-old to stay engaged. A bump stop adds at most `bump_stop` (`tuning.json`, 0.5 s) each.
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
| blocks | int | 0–5 (schema 1.1); use 3 | data file (beat params, D-06) | Practice strikes to block |
| attack_time, attack_cooldown | float (s) | see tuning | `tuning.json` (0.28, 0.12) | One swing and its gap |
| walk_gap | float (s) | ≈ 0.9 | estimate: `dummy_spacing` / `hero_speed` = 300 / 330 | Walking to the next dummy |
| telegraph, strike_time, enemy_rest | float (s) | see tuning | `tuning.json` (1.1, 0.25, 1.6) | The partner's practice strike cycle |
| T_special | float (s) | 1–3 | estimate only, not a runtime value | Tapping special and the banner rising |

**Output Range:** 15–40 s with the suggested values.
**Example:** 3 × (0.28 + 0.12 + 0.9) + 3 × (1.1 + 0.25 + 1.6) + 2 = 3.9 + 8.85 + 2 ≈ 15 s, plus
first-time hint pauses.

Fight and reach-the-flag encounter times come from the Side-scroll movement & combat GDD.

The F5 (beat positions) formula is defined as:

`beatX(0) = beat_start_x`; `beatX(i+1) = beatX(i) + extent(i) + beat_gap`, where
`extent(i) = length_screens × world_width` (walk, reach-the-flag), `(dummies + 1) × dummy_spacing` (training), or `0` (fight, hold-meter, dialogue).

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| beat_start_x | float (px) | see tuning | data file (`tuning.json`, 900) | Where beat 0 starts |
| beat_gap | float (px) | see tuning | data file (`tuning.json`, 1600) | Walk between beats |
| length_screens | float | 0–10 | data file (beat params) | Walk / flag beat length |
| world_width | int (px) | 1280 | constant (`tuning.json` world) | One screen |
| dummies | int | 1–10 | data file (beat params) | Training dummies |
| dummy_spacing | float (px) | see tuning | data file (`tuning.json`, 300) | Gap between dummies |

**Output Range:** strictly increasing, since every term is ≥ 0 and `beat_gap` > 0. Beats never
overlap, and a multi-screen beat pushes the next one along.
**Example:** the Trần Quốc Toản slice (walk 3, hold-meter, training 3 dummies, flag 4):
beatX(0) = 900; beatX(1) = 900 + 3840 + 1600 = 6340; beatX(2) = 6340 + 0 + 1600 = 7940;
beatX(3) = 7940 + 1200 + 1600 = 10740. The flag beat then spans to 10740 + 5120 = 15860.

The F6 (dialogue time) formula is defined as:

`T_dialogue = lines × T_box + ask_taps × T_ask`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| lines | int | 2–12 | content (beat params) | Lines in the dialogue |
| T_box | float (s) | 3–8 | estimate (F1); later Audio F1 when VO exists | Reading or listening time per line |
| ask_taps | int | 0–3 | content (`ask.taps`) | Ask button taps |
| T_ask | float (s) | ~1 | estimate | Finding and tapping the ask button |

**Output Range:** 6–100 s. Keep a dialogue at **≤ 10 lines** (≈ 50 s), because it adds to the
mission's F1 total.
**Example:** the Bình Than exchange: 9 lines × 5 s + 2 × 1 s ≈ 47 s. With beat 1 shortened to 1
screen (−7.7 s) and `beat_gap` 800 (−2.4 s per walk_to), the mission grows by about 25 s and
stays within F1's 3–5 min.

## Edge Cases

- **If a beat lists a button its type never uses** (e.g. `walk` with `attack`): the pad is shown
  and does its normal action, but nothing requires it. Validation **warns** (it doesn't fail),
  because a content writer may add it for feel.
- **If a beat's `buttons` lacks a button its goal needs** (e.g. `hold-meter` without
  `special`): validation **fails** the bundle under R13 (Core Rule 7b). The goal could never be met.
- **If the child releases special at meter 0.99**: the meter holds at 0.99 (no drain), and the
  next press finishes it.
- **If special is pressed during training before the dummies and blocks are done**: the special
  pose plays, nothing finishes, and the hint shows the step still to do. Special completes
  training only as the last step.
- **If the hero is pushed back during walk or reach-the-flag**: progress is position-based, so
  the child walks forward again. Nothing resets.
- **If the app goes to the background mid-beat**: the game enters `paused` automatically and
  stays there when the app comes back. Nothing advances while it is backgrounded.
- **If the app is killed mid-mission**: the next launch opens the map (the title screen in the slice), and the mission starts
  again from `intro`. No mid-mission state is saved (Core Rule 14).
- **If the language switches during a voice line** (post-slice, once `vo` exists): the line stops, and the same box replays in
  the new language. The box index doesn't change.
- **If the language switches while the hold meter is filling**: the meter keeps filling. The
  switch is made in the pause menu, and pause freezes the meter. A held pad is released on
  pause, and the meter keeps its value (no drain).
- **If a beat's `scene` is empty**: the beat card shows only `title` and `goal` for one tap.
  Schema allows this, and it is fine for a pure-action beat.
- **If `next_hero` is null** (the last hero shipped): `results` goes straight to `map`, with a
  "Còn nhiều anh hùng nữa sắp đến / More heroes are coming" UI string.
- **If a release build finds a pending claim at `gate_check`**: the hero's place on the map is
  hidden. This is never a crash or an error screen in front of a child (R12).
- **If a mission has 1 or 2 beats**: it is allowed (schema minItems 1). The design target stays
  3–4 beats per hero.
- **If the child taps Skip, then "Keep reading"**: they return to the same box. `story_skipped`
  stays false, and the next Skip tap warns again.
- **If the child skips only the ending**: `story_skipped` is true, so no medal this run. The
  quiz runs as normal.
- **If the app is killed after "Skip anyway"**: nothing is saved (Rule 14). The next run starts
  with `story_skipped` false.
- **If the medal was earned on an earlier play and the child skips now**: no warning, and the
  saved medal stays (never lost).
- **If the language is switched mid-story**: no effect on `story_skipped`. Boxes already
  advanced still count.
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
  never skips two boxes, so taps within `advance_debounce` (`tuning.json`, 0.25 s) of an advance
  are ignored. The page slide is a feel constant, not data.
- **Hold-meter:** the meter rises smoothly with no steps. A light pulse (and haptic, where
  available) fires at 25/50/75/100%. These are feel constants, not data.
- **Beat end:** a short beat of quiet (`end_pause` 0.6 s, the prototype's value) before the
  cheer. Keep it under 1 s so it never feels like waiting. Not yet checked by a playtest.
- **No dead time:** from a goal being met to the next card is under 1.5 s in total.

## UI Requirements

- **Story screen:** picture, one text box (one sentence), "Tiếp / Next" on the right, and the
  pause top-right. The box fits the EN budget (`rules.json` `scene` 120).
- **HUD during play:**
  - pause and sound, top-left;
  - beat progress dots, top-centre (one per beat, filled when done);
  - the `goal` line under the dots (`goal` budget 60);
  - the beat's pads, bottom (Input GDD, `pad_min` 72 pt/dp).
- **Hold-meter ring** around the special pad, and a training checklist of three icons
  (dummies, shield, banner) that fill as each part is done. Icons only, no words.
- **Pause menu:** keep playing, sound, VI|EN, back to the map (the title screen in the slice).
- **Skip:** a small "Bỏ qua / Skip" button on every story screen, smaller than "Tiếp" and away
  from it (bottom-left vs bottom-right), so a child doesn't tap it by accident.
- **Skip warning:** a small card over the story with the medal picture, one short line
  (`ui.story.skip_warning`), "Đọc tiếp / Keep reading" (big, default, right) and "Vẫn bỏ qua / Skip
  anyway" (smaller, left). There is no red and no warning sign; the tone is gentle.
- **Medal on results:** earned shows the gold medal and `ui.medal.earned`. Not earned shows an
  outline medal and `ui.medal.missing`, which is encouraging, never a scold.

📌 **UX Flag — Mission Flow**: this system has UI requirements. In Pre-Production, run
`/ux-design` for the story screen, the mission HUD and the pause menu before writing epics.

## Cross-References

| This doc references | Where | What |
|---|---|---|
| Game concept | `design/gdd/game-concept.md` | Mission structure, pillars, session length |
| Content data contract | `content/README.md`, `content/schema/mission.schema.json`, `content/data/tuning.json`, `content/data/rules.json` | Beat fields, params, text limits, claim gate R12 |
| Art bible | `design/art/art-bible.md` §§2–7 | Moods per state, banner text layer, no injury |
| Hero content | `design/narrative/heroes/tran-quoc-toan.md` §3, §6 | The approved 4-beat structure for Trần Quốc Toản |
| Side-scroll movement & combat | `design/gdd/side-scroll-combat.md` | Fight rules, encounter time; no special in combat (D-10) |
| Quiz & stars | `design/gdd/quiz-and-stars.md` (planned) | Quiz start and finish |
| Hints & onboarding | `design/gdd/hints-and-onboarding.md` (planned) | Teaching new buttons, the no-progress hint |
| Decisions | `production/team/decisions.md` P-01, D-06, D-07, D-08, D-10 (P-02 superseded) | Press/release, schema params, story skip, slice beat set, no special in combat |
| Prototype evidence | `203d73e` `prototypes/tqt-mission/config.js`; QC r3 (Android) | Tuning values, `end_pause`, one tone per press |

**Trần Quốc Toản's approved structure maps to types like this** (hero doc §6):
- Beat 1, riverbank → `walk`
- Beat 2, the orange → `hold-meter`
- Beat 3, the banner → `training` (`uses_banner`)
- Beat 4, battle → `reach-the-flag` with encounters (`uses_banner`)

## Acceptance Criteria

1. **GIVEN** a mission with 4 `fight` beats, **WHEN** it is played through, **THEN** the screens
   appear in exactly this order: intro → (walk) play 1 → caption 1 → … → play 4 → caption 4 →
   ending → quiz → results → unlock → title screen (slice). **GIVEN** a non-fight beat,
   **THEN** its beat card appears **before** its play, and no caption follows it.
2. **GIVEN** any beat in play, **WHEN** the hero is hit any number of times, **THEN** no lose
   screen, life counter or restart appears, and the beat stays in play until its goal is met.
3. **GIVEN** a beat with `buttons: [move]`, **WHEN** it is in play, **THEN** only the move pads
   (plus pause and sound) are visible.
4. **GIVEN** a `walk` beat with `length_screens` 3 and play starting with the hero at rest at
   `x_start`, **WHEN** the hero holds move right without bumping, **THEN** the beat ends when hero
   x ≥ `x_start` + 3840, after 11.6 s ± 0.1 s (F2 at `hero_speed` 330, dt 1/60).
5. **GIVEN** a `hold-meter` beat with `hold_seconds` 2.5, **WHEN** the child holds 1.2 s,
   releases for 3 s and holds again, **THEN** the meter stays at 48% during the release and the
   beat ends after 1.3 s more of holding (F3).
6. **GIVEN** a `training` beat with dummies 3 and blocks 3, **WHEN** the child taps special
   before hitting all 3 dummies, **THEN** the beat does not end, and it ends only after 3 hits,
   3 blocks and then a special tap.
7. **GIVEN** a `reach-the-flag` beat with one encounter, **WHEN** the hero reaches the
   encounter zone, **THEN** the camera locks until every enemy in it has run away, and the beat
   ends when the hero touches the flag.
8. **GIVEN** a beat with `uses_banner: true`, **WHEN** the language is switched in the pause
   menu and play resumes, **THEN** the banner text is in the new language, and the banner picture has no text in it
   (checked with the text layer hidden).
9. **GIVEN** any story box, **WHEN** the child taps "Tiếp" twice within 0.25 s, **THEN** only
   one box advances.
10. **GIVEN** the hold meter at 60% and play in progress, **WHEN** the app goes to the
    background and returns, **THEN** the game is paused, the meter still reads 60%, and no
    enemy acted while it was backgrounded.
11. **GIVEN** a release build and a mission with one pending claim, **WHEN** the map loads,
    **THEN** that hero cannot be started, and no error is shown to the child. **GIVEN** a debug
    build, **THEN** the mission plays and pending lines show `UNSIGNED Cxx`.
12. **DEFERRED (not testable in the slice; needs `vo`):** **GIVEN** a voice line playing in VI,
    **WHEN** the child switches to EN in the pause menu and resumes, **THEN** the VI line has
    stopped and the same box's EN line plays.
13. **GIVEN** the app killed during beat 3, **WHEN** it relaunches, **THEN** the title screen
    (slice) or map opens and
    starting the hero begins at the intro.
14. **GIVEN** the Trần Quốc Toản mission data, **WHEN** it is played, **THEN** the total time
    before the quiz is 3–5 minutes for an adult tester playing straight through (F1 target).
    This is a playtest check, recorded in `production/qa/evidence/`.
15. **GIVEN** content where a `hold-meter` beat's `buttons` lacks `special` (or any R13 minimum),
    **WHEN** content is validated, **THEN** validation fails with R13 (`content/fixtures/validity.json`).

16. **GIVEN** a first play, **WHEN** the child taps Skip on the intro, **THEN** the warning shows
    with "Keep reading" as the default. **WHEN** they tap "Keep reading", **THEN** the same box
    shows and `story_skipped` is false.
17. **GIVEN** the warning, **WHEN** "Skip anyway" is tapped, **THEN** the rest of that story
    screen is skipped and `story_skipped` is true. **WHEN** Skip is tapped on a later caption,
    **THEN** it skips with no warning.
18. **GIVEN** a run where every story box was advanced with "Tiếp", **WHEN** the quiz finishes
    (any stars), **THEN** `medal_earned` is reported and results show the gold medal. **GIVEN**
    one skipped screen, **THEN** no medal is reported, and stars and the unlock are unchanged.
19. **GIVEN** the medal already earned for this hero, **WHEN** Skip is tapped, **THEN** no
    warning shows and the saved medal stays earned after the run.

20. **GIVEN** the Trần Quốc Toản slice with `tuning.json` defaults, **WHEN** the mission loads,
    **THEN** the beat starts are at x = 900, 6340, 7940, 10740 (F5).
21. **GIVEN** a training beat with blocks 3, **WHEN** the child presses and releases defend during
    the partner's windup and isn't holding it when the strike resolves, **THEN** that block does
    not count.
23. **GIVEN** a `dialogue` beat with `ask` {taps 2, at_line 2}, **WHEN** it plays, **THEN** lines 1–2
    advance with "Tiếp", the ask button replaces "Tiếp" for exactly 2 taps (each showing the next
    line), "Tiếp" returns for the rest, and no pads are shown at any point.
24. **GIVEN** a `dialogue` beat whose first line is a marked narrator line citing C14, **WHEN**
    validated, **THEN** its spoken lines citing C14 pass without their own marker (R4c). **GIVEN**
    the first line unmarked, **THEN** validation fails R4.
25. **GIVEN** a `dialogue` beat skipped with "Skip anyway", **WHEN** the quiz finishes, **THEN** no
    medal is reported for that run.

## Open Questions

| # | Question | Owner | By |
|---|---|---|---|
| D-06 | Done: schema 1.1 merged (TASK-005d, 3074d43) | — | Closed |
| D-07 | **Decided (Luan, 2026-11-14):** skip is allowed on any play, with a warning; skipping means no medal for that mission this run (Core Rule 15) | — | Closed |
| — | Walk-beat props (`bump_stop`): who places them and where? Proposal: a `props` list in walk params (`at_screen`, kind), authored by game-art-content per story, with a schema change by the devs. The slice ships with no props, so F2's bump term is 0 | game-art-content + devs | Before Alpha content |
| D-08 | **Decided (Luan, 2026-11-14): B**, the full structure (walk, hold-meter, training, reach-the-flag) in the slice | — | Closed |
| — | T_box: measure real voice-over length per box once the first VO is recorded, then re-check F1 | audio-director / game-art-content | First VO recording |
| — | Done (D-09): `advance_debounce` 0.25 s and `bump_stop` 0.5 s are in `tuning.json`. Feel constants that are not data: page slide 0.1–0.15 s, meter pulse points. Estimates that are not runtime values: T_box, walk_gap, T_special | — | Closed |
