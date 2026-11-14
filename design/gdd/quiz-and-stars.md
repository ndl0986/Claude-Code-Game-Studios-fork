# Quiz & Stars

> **Status**: In Review
> **Author**: game-art-content (Luan decides)
> **Last Updated**: 2026-11-14
> **Last Verified**: 2026-11-14
> **Implements Pillar**: Học mà vui (Learn by playing), Nhỏ chơi được (Small hands can do it), Đúng sự thật (True to history)
> **Task**: TASK-008 · Tier: standard (Player Fantasy and Tuning Knobs skipped by tier; rules live in `content/data/rules.json`)

## Summary

After each mission the child answers 3–5 picture questions about the story they just played.
A wrong pick turns soft lavender-grey and the child tries again, so every question ends on the
right answer and its short "why" line. Stars (1–3) count how many wrong picks there were across
the whole quiz. Finishing always unlocks the next hero.

> **Quick reference** — Layer: `Core` · Priority: `Vertical Slice` · Key deps: `Content data & claims, Language & text, Save & progress` · Started by: `Mission flow & beat types`

## Overview

The quiz turns "I played it" into "I remember it".

- **Pillars:**
  - *Learn by playing*: passing it unlocks the next hero.
  - *Small hands can do it*: it can't be failed. A wrong pick never ends anything; it only
    costs a star.
  - *True to history*: every question tests a signed-off claim from the hero's content. An
    invented detail is never asked, and a legend is asked as "the story says".
- **Where its numbers come from:** the star rule is Luan's decision of 2026-11-14 (retry until
  right), stored in `content/data/rules.json` `quiz_stars` and checked by
  `content/fixtures/quiz-stars.json` and `quiz-scoring.json`.

## Detailed Design

### Core Rules

1. **Start.** Mission flow starts the quiz after the ending. The quiz asks the questions in
   `content/data/heroes/<hero>/quiz.json`, in file order (3–5, schema). Question count is
   decided by content; `tuning.json` `quiz_count` is only an upper cap, set to 5 (D-11, done in data/TASK-005d @ f94f463).
2. **A question screen** shows:
   - the progress dots and "Câu n/N / Question n/N";
   - the `prompt`, with its optional `picture_id`;
   - three large choice cards, each with a picture (`picture_id`) and a short `text`;
   - the pause button. VI|EN is switched from the pause menu (P-04; in the vertical slice it is on the title and pause screens only).
3. **Choice order** (new: the prototype didn't shuffle). The three cards are shuffled once
   when the question appears, and the right answer is tracked by identity, not position. The
   shuffle uses **its own RNG per question**, never the game's play stream: the fight's
   particles use that stream, so the order would depend on play and differ between apps.
   - RNG: Mulberry32, seeded with `seed + question_index` (`seed` from `tuning.json`;
     `question_index` 0-based).
   - Fisher–Yates: from the last index down to 1, swap `i` with `j = floor(rng() × (i + 1))`.
   - Both apps must give the orders in the shared fixture `content/fixtures/quiz-shuffle.json`
     (seed, question index → order).
4. **Wrong pick.** The card:
   - shakes for 0.5 s;
   - turns soft lavender-grey (art bible §4 "Try again", `#9C8FB8`, with a circular-arrow
     icon);
   - plays a soft sound and shows "Thử lại nhé! / Try again!".

   The card then stays greyed and **can't be picked again**. The question stays open.
   `retries` goes up by 1. During the 0.5 s shake, taps on any card are ignored (P-05, AC6).
5. **Right pick.** The card glows rice-green with a tick, "Đúng rồi! / That's right!" plays,
   and then the `why` line shows (with voice) beside the beat's picture. After at least
   `feedback_time`, a "Tiếp / Next" button appears. The child taps it to go on. The game never
   auto-advances past a `why` line, because the child must be able to hear it. **This is the
   vertical-slice rule too** (P-05: the slice follows this GDD rather than the prototype's
   0.9 s auto-advance).
6. **Retry limit per question.** With the greyed card disabled, a question costs at most 2
   retries, and the third pick is always right. So the quiz always ends, and
   `retries ≤ 2 × N`.
7. **Stars.** When the last question is answered right, stars come from the **total** retries
   (F1, `rules.json`): 0 gives 3★, 1–2 gives 2★, 3 or more gives 1★.
8. **Unlock.** Finishing the quiz always reports "mission completed" with its stars to Hero
   progression, which unlocks `next_hero`. Stars never gate the unlock.
9. **Replays.** A replayed quiz can raise a hero's saved stars but never lower them (best of).
   Save & progress owns storage; this system reports only the result of the run.
10. **No timers.** No question has a time limit, and nothing changes if the child waits.

**Question-writing rules** (for game-art-content, who writes `quiz.json`; validation enforces the
ones marked R):
- Q1. Each question cites at least one claim. It never cites an **invented** claim (R6).
- Q2. A question about a **legend** claim begins with a marker from `markers.json` (VI "Truyện
  kể rằng…", EN "The story says…") in the prompt (R4). A `fact_as_recorded` claim may use "Sử
  chép rằng… / The chronicle says…".
- Q3. One idea per question. Each choice must be recognisable from its picture alone, so a
  6-year-old who can't read yet can answer.
- Q4. Wrong choices are clearly wrong, but plausible to a child. They are never mocking,
  never a real person, and never another hero's sacred detail.
- Q5. The `why` line restates the right answer as a fact from the story, never "You were wrong
  because…". At most 120 chars, within the EN `quiz_why` budget.
- Q6. Questions follow the story order of the beats, so the quiz retells the mission.
- Q7. No question about death, injury or numbers of dead.

### States and Transitions

| State | Leaves to | Trigger |
|---|---|---|
| `question_open` | `wrong_feedback` / `right_feedback` | Tap (on release, P-01) on an enabled card |
| `wrong_feedback` | `question_open` | 0.5 s shake ends (taps on cards are ignored during the shake) |
| `right_feedback` | `why_shown` | The glow and "Đúng rồi!" play |
| `why_shown` | `question_open` (next) / `done` | "Tiếp" after ≥ `feedback_time`; `done` after the last question |
| `done` | (Mission flow → `results`) | Stars computed (F1); "mission completed" sent |

### Interactions with Other Systems

| System | In | Out | Owner |
|---|---|---|---|
| Mission flow & beat types | "start quiz for hero X" | "quiz finished", stars | Mission flow GDD |
| Content data & claims | `quiz.json`, `rules.json` `quiz_stars`, `markers.json`, claim status | (none) | Content contract |
| Language & text | current language, language-changed event | Text ids | Language GDD |
| Hero progression & unlock | (none) | "mission completed (hero, stars)" | Progression GDD |
| Save & progress | the previous best stars, for display | the run's stars (best-of applied by Save) | Save GDD |
| Audio & voice-over | (none) | line ids (prompt, why), sounds for right and wrong | Audio GDD |

## Formulas

The F1 (stars) formula is defined as:

`R = Σ_q wrong_picks_q`; `stars = 3 if R ≤ t3; 2 if R ≤ t2; else 1`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| wrong_picks_q | int | 0–2 | calculated | Wrong picks before the right one on question q (Rule 6) |
| R | int | 0–2N (0–10) | calculated | Total retries across the quiz |
| t3 | int | 0 | data file (`rules.json` `quiz_stars.thresholds[stars=3].max_retries`) | Retries allowed for 3★ |
| t2 | int | 2 | data file (`rules.json`, stars=2) | Retries allowed for 2★ |
| N | int | 3–5 | data file (`quiz.json` question count) | Questions in the quiz |

**Output Range:** 1–3, always ≥ 1, because finishing gives at least 1★. A broken threshold (t2
< t3) would make 2★ impossible, so validation must fail when t2 < t3.
**Example:** wrong picks [0, 1, 0, 1, 0] gives R = 2, so 2★.

The F2 (chance of stars by guessing) formula is defined as:

`P(stars ≥ s) = P(R ≤ t_s)`, where each `wrong_picks_q` is uniform on {0, 1, 2} for a child
picking at random among enabled cards.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| N | int | 3–5 | data file | Questions |
| t_s | int | t3 = 0, t2 = 2 | data file | Thresholds |

**Output Range:**
- N = 5: P(3★) = 1/243 = 0.4%; P(≥ 2★) = 21/243 = 8.6%.
- N = 3: P(3★) = 1/27 = 3.7%; P(≥ 2★) = 10/27 = 37%.

So with 3 questions, random tapping earns 2★ about a third of the time; with 5, rarely. That
is the reason to prefer **5 questions per hero**.
**Example:** N = 5, number of {0,1,2}⁵ outcomes with sum ≤ 2: 1 (sum 0) + 5 (sum 1) + 15 (sum 2)
= 21, and 21 / 3⁵ = 8.6%.

The F3 (quiz time) formula is defined as:

`T_quiz ≈ N × (T_prompt + T_pick + T_why) + R × 0.5`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| T_prompt | float (s) | 3–6 | constant ⟨tuning: from VO⟩ | Prompt read aloud |
| T_pick | float (s) | 2–8 | constant ⟨playtest⟩ | Child choosing |
| T_why | float (s) | max(`feedback_time`, VO length) + tap | data file (`feedback_time` 0.9) / VO | Hearing the why line |
| R | int | 0–2N | calculated | Retries; each costs a 0.5 s shake |

**Output Range:** 40–110 s for N = 5, inside the session target with the mission (Mission flow F1).
**Example:** 5 × (4 + 4 + 5) + 2 × 0.5 = 66 s.

## Edge Cases

- **If the child taps a greyed (wrong) card again**: nothing happens. It does not count as a
  retry (Rule 4). Note: `content/fixtures/quiz-scoring.json` case "same wrong twice counts
  twice" contradicted this and the prototype. Fixed in D-11 (data/TASK-005d @ f94f463): the
  repeat tap is ignored.
- **If the child taps two cards at once** (two fingers): the first release in a frame wins.
  Every other release is ignored until the state returns to `question_open`.
- **If the child taps a card during the 0.5 s shake**: the tap is ignored, so a frantic
  double-tap doesn't cost two retries.
- **If the language switches mid-question** (from the pause menu): prompt, choices and `why` re-render in the new
  language. Greyed cards stay greyed, `retries` is unchanged, and the shuffle order is kept.
- **If the app is backgrounded during the quiz**: it pauses. On return, the same question and
  state are restored.
- **If the app is killed during the quiz**: nothing is saved (Mission flow rule 14), and the
  next start begins the mission at its intro. Accepted, because a mission is 3–5 min.
- **If `quiz.json` has fewer questions than `quiz_count`**: all of them are asked. If it has
  more (only possible up to 5), the first `quiz_count` are asked. `quiz_count` is 5 (D-11), so
  content decides.
- **If a question cites a pending claim in a release build**: the whole mission is hidden by
  the claim gate (R12), so the quiz can't start. In a debug build, it shows `UNSIGNED Cxx`.
- **If R is greater than 2N**: impossible with Rule 4. If it happens, it's a bug, logged in
  debug; stars stay at 1.
- **If the child replays and scores lower**: the saved stars stay at the best (Rule 9), and the
  results screen shows "best ★★★" beside this run's stars.
- **If `next_hero` is null**: finishing still reports "mission completed". Mission flow skips
  the unlock screen.

## Dependencies

| System | Direction | Hard/Soft | Interface |
|---|---|---|---|
| Content data & claims | this depends on it | Hard | `quiz.json`, `rules.json`, `markers.json`; R4, R6, R12 |
| Language & text | this depends on it | Hard | Text rendering, language-changed event |
| Save & progress | this depends on it | Hard | Best-stars storage |
| Mission flow & beat types | depends on this (it starts it) | Hard | Start; "quiz finished + stars" |
| Hero progression & unlock | depends on this | Hard | "mission completed (hero, stars)" |
| Audio & voice-over | depends on this | Soft | VO line ids, sounds |

Mission flow lists Quiz & stars in its Dependencies (`design/gdd/mission-flow.md`).

## Visual/Audio Requirements

Art-director lens (art bible §2 "quiz", §4, §7):
- **Mood:** flat, even light; the background a softened still of the mission; big cream answer
  cards with nothing competing (§2).
- **Wrong:** soft lavender-grey `#9C8FB8` with a circular-arrow icon, and a gentle wobble. Never
  red, no buzzer, no "X" (§4, Luan's approved rule).
- **Right:** rice-green `#3FA34D`, a tick icon, a little star burst, and a chime.
- **Pictures:** every choice has a picture with no text inside it (R10). The pictures needed for
  Trần Quốc Toản are listed in `design/narrative/heroes/tran-quoc-toan.md` §4.
- **Stars on results:** the gold stars pop in one by one. Unearned stars are outlines (§4
  colour-blind backup: fill vs. outline).
- **Audio:** prompt and `why` voiced (Audio GDD); a soft "boop" for wrong, a chime for right.

📌 **Asset Spec**: after approval, run `/asset-spec system:quiz-and-stars` for the cards,
icons, choice pictures, star states and the results screen.

## Game Feel

- A tap on a card reacts on release, within a frame.
- The wrong shake is short (0.5 s) and soft, so it never feels like a punishment.
- The right answer gets the biggest feedback in the quiz (glow, burst, chime), so success
  is louder than failure.
- The child controls the pace: there is no auto-advance past `why`, and nothing is timed.

## UI Requirements

- Three cards in one row (landscape), each at least `pad_min` and in practice about a third of
  the width. The prompt sits above them, and "Tiếp" bottom-right after a right pick.
- Progress dots and "Câu n/N" top-left, pause top-right (VI|EN lives in the pause menu).
- Results: stars, this run's and the best, plus "Tiếp".
- Strings: `ui.quiz.retry`, `ui.quiz.correct`, `ui.quiz.question`, `ui.results.done`
  (`content/data/strings.json`).

📌 **UX Flag — Quiz & Stars**: run `/ux-design` for the quiz screen and results screen before
writing epics.

## Cross-References

| This doc references | Where | What |
|---|---|---|
| Rules and fixtures | `content/data/rules.json` `quiz_stars`, `content/fixtures/quiz-stars.json`, `quiz-scoring.json` | Star thresholds; expected outcomes |
| Content contract | `content/README.md` (R4, R6, R8, R12), `content/schema/quiz.schema.json` | Question shape, marker and claim rules |
| Mission flow | `design/gdd/mission-flow.md` | Start and finish, no mid-mission save |
| Hero content | `design/narrative/heroes/tran-quoc-toan.md` §4 | The 5 draft questions, the D5 decision |
| Art bible | `design/art/art-bible.md` §2, §4 | Quiz mood, wrong-answer colour, star states |
| Decisions | `production/team/decisions.md` (stars: decided 2026-11-14), D-11, P-01, P-05 | Star rule, fixture and count fixes, tap on release, slice follows Rule 5 and the pause button |
| Prototype | `203d73e` `index.html` `answer()`, `finishQuiz()` | Greyed card ignored, retry count |

## Acceptance Criteria

Criteria 1–8 need automated unit tests (shared fixtures where noted); 9–11 need QC screenshots
or a playtest.

1. **GIVEN** the `quiz-stars.json` cases, **WHEN** each `wrong_picks_per_question` list is
   scored, **THEN** both apps return exactly the expected `total_retries` and `stars`, with
   `unlocks_next_hero` true in every case.
2. **GIVEN** R = 0 / 2 / 3 (boundaries), **WHEN** the quiz ends, **THEN** stars are 3 / 2 / 1.
3. **GIVEN** a question with one greyed card, **WHEN** the greyed card is tapped, **THEN**
   `retries` doesn't change and the question stays open.
4. **GIVEN** a question, **WHEN** the two wrong cards are picked, **THEN** the third card is
   the only enabled one, and picking it shows `why`. Retries for that question are 2.
5. **GIVEN** a right pick, **WHEN** `feedback_time` has not elapsed, **THEN** no "Tiếp"
   button is visible. After it appears, nothing advances until it is tapped.
6. **GIVEN** a card shaking, **WHEN** another card is tapped within 0.5 s, **THEN** the tap is
   ignored.
7. **GIVEN** a quiz finished with 1★ and a saved best of 3★, **WHEN** results show, **THEN**
   the saved value stays 3★ and the next hero is unlocked.
8. **GIVEN** each case in `content/fixtures/quiz-shuffle.json` (seed, question index),
   **WHEN** the shuffle runs (Mulberry32 + Fisher–Yates, Rule 3), **THEN** both apps return
   exactly the expected order, whatever happened in the fight before the quiz.
9. **GIVEN** a wrong pick, **WHEN** captured, **THEN** the card is lavender-grey with a
   circular-arrow icon, and no red appears anywhere on screen (screenshot per platform).
10. **GIVEN** the language switched to EN after one wrong pick, **WHEN** the screen re-renders,
    **THEN** the same card is still greyed and all text is EN within the `quiz_choice` and
    `quiz_prompt` budgets (screenshot).
11. **GIVEN** the Trần Quốc Toản quiz (5 questions), **WHEN** a tester reads it,
    **THEN** every legend question begins with "Truyện kể rằng / The story says", and no
    question cites C12 (validation output attached).

## Open Questions

| # | Question | Owner | By |
|---|---|---|---|
| D-11 | Done in data/TASK-005d @ f94f463: the `quiz-scoring.json` repeat-tap case now ignores the tap; `quiz_count` 5; validation R16 fails if t2 < t3 | game-dev-android (game-dev-ios reviews) | Done; merge with schema 1.1 |
| — | `content/fixtures/quiz-shuffle.json` (new fixture for Rule 3 and AC8) | game-dev-android | Before the slice quiz story closes |
| — | Should results show "best" stars beside this run's? (Rule 9 and the edge case assume yes) | Luan | With the `/ux-design` results screen |
| — | The prototype auto-advanced after 0.9 s; Rule 5 waits for "Tiếp" so the `why` line can be heard. Check in the playtest that children don't find it slow | game-art-content, after the slice playtest | Playtest |
