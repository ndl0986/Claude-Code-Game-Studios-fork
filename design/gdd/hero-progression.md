# Hero Progression & Unlock

> **Status**: Approved (peer review: game-dev-android, 2026-11-14)
> **Author**: game-art-content (Luan decides)
> **Last Updated**: 2026-11-14
> **Last Verified**: 2026-11-14
> **Implements Pillar**: Học mà vui (Learn by playing), Nhỏ chơi được (Small hands can do it), Đúng sự thật (True to history)
> **Task**: TASK-012 · Tier: standard (Player Fantasy and Tuning Knobs skipped by tier)

## Summary

Heroes come in historical order. The first hero is open from the start. Finishing a hero's quiz
opens the next hero, always, whatever the stars. Each hero keeps its best quiz stars (1–3) and a
**medal** earned by hearing the whole story without skipping (D-07). Nothing is ever lost or
locked again.

> **Quick reference** — Layer: `Feature` · Priority: `Vertical Slice` (results and unlock only) / `Alpha` (full, with the map) · Key deps: `Quiz & stars, Mission flow & beat types, Save & progress, Content data & claims`

## Overview

Progression is how the child moves through Vietnamese history, one hero at a time.

- **What this system owns:**
  - which heroes are open;
  - the order they open in (`timeline_order`, the order they lived);
  - each hero's saved best stars and medal;
  - the "completed" record that drives unlocking.
- **What it does not own:**
  - how stars are scored (Quiz & stars);
  - when the medal is earned (Mission flow Core Rule 15);
  - how the map draws heroes (Map & timeline, Alpha);
  - how data is stored on the device (Save & progress, ADR D-04).
- **Pillars:**
  - *Small hands can do it*: there is no gate on skill. Finishing always opens the next hero.
  - *Learn by playing*: mastery shows as stars (remembering) and medals (hearing the whole story).
  - *True to history*: order follows the timeline, and a hero whose claims aren't signed off never
    appears in a release build (R12).

Content arrives over time in timed app updates (concept), so progression must stay correct when
a new hero is added after a child has already finished the previous one.

## Detailed Design

### Core Rules

1. **Order.** Heroes are ordered by `hero.timeline_order` in their `mission.json` (ascending,
   unique; validation R17). It is an **integer numbered in gaps of 10** (10, 20, 30…), so a
   hero who lived in between can be inserted (e.g. 15) without renumbering. There is no year
   field: legends have none, and heroes can share a year. If the map needs an era, it is a
   Text. The order in `index.json` doesn't matter. Trần Quốc Toản is 10. The test-only
   sample hero is 999, and samples are excluded from the uniqueness check.
2. **First hero.** The hero with the lowest `timeline_order` among playable heroes (Rule 7) is
   always open.
3. **Completed.** A hero is **completed** once its quiz finishes in any run (Quiz Rule 8). Saved
   as `completed.<hero_id>` = true, never cleared.
4. **Unlock is derived, not stored.** A hero is **open** if it is the first hero (Rule 2), **or**
   the playable hero just before it in `timeline_order` is completed. Deriving it (instead of
   saving an `unlocked` list) keeps progression right after a content update:
   - **A new hero added at the end** opens at once for a child who has finished the previous last
     hero.
   - **A hero added in the middle** of the timeline (a hero who lived earlier) opens when the hero
     before it is completed. Heroes already open stay open (Rule 5).
5. **Never locked again.** Once a hero has been open, it stays open: a hero is open if
   `seen_open.<hero_id>` is set **or** Rule 4 holds. A content update never takes a hero away
   from a child. **When `seen_open` is written:** for **every** open hero, (a) whenever the
   title screen (the map after Alpha) loads, and (b) at quiz finish, together with
   `completed`, `stars` and `medal`.
6. **`next_hero` in content.** Validation (R18, at build time, claims ignored) checks that
   `next_hero` equals the next hero **in `index.json`** by `timeline_order`, or null for the
   last one. At run time, Rule 4 decides unlocking, and the unlock screen names the hero that
   **actually opened**, which can differ from `next_hero` if that hero isn't playable (Rule 7).
7. **Playable.** A hero is playable if its folder is in `index.json` and, in a release build, all
   its cited claims are approved (R12). Unplayable heroes are skipped in Rules 2 and 4, as if
   they weren't there. Debug builds treat every bundled hero as playable.
8. **Best stars.** On quiz finish, `stars.<hero_id>` = max(saved, this run). Never lowered (Quiz
   Rule 9).
9. **Medal.** When Mission flow reports `medal_earned` (no story screen skipped this run),
   `medal.<hero_id>` = true. Never cleared. A later run with skips doesn't remove it (Mission flow
   Rule 15).
10. **Results and unlock screens** (after the quiz):
    1. **Results:** this run's stars, the best stars (if higher), and the medal: gold if earned in
       this or any run, otherwise an outline and `ui.medal.missing`. `ui.medal.earned` ("Nhận được
       huy hiệu! / You earned the medal!") shows **only in the run that earns it**, first play or
       replay. The same string is reused; there's no separate "new medal" string.
    2. **Unlock**, only when this finish opened a hero that wasn't open before: "Mở khoá anh hùng
       tiếp theo! / Next hero unlocked!" plus the hero's name.
    3. If no next playable hero exists: `ui.results.more_heroes`, then the title screen (the map
       after Alpha).
11. **What is saved** (all on the device, nothing else, pillar *Safe for kids*):
    `completed.<hero_id>`, `seen_open.<hero_id>`, `stars.<hero_id>` (1–3), `medal.<hero_id>`,
    and `lang` (Language GDD). The format and migration belong to the D-04 save ADR. This changes
    P-04 (3)'s `unlocked` list into `completed` + `seen_open` (D-16).

### States and Transitions

Per hero: `hidden` (not playable) → `locked` (playable, not open) → `open` → `completed`. Stars
(1–3) and medal (yes/no) live alongside `completed`.
- `locked` → `open`: the previous playable hero is completed (Rule 4), or it is the first hero.
- `open` → `completed`: its quiz finishes.
- `completed` stays `completed`. Replays update only stars (up) and medal (to yes).
- `hidden` ↔ playable can change only with a content update or a sign-off. A hero once `open`
  keeps `seen_open` (Rule 5), so if it becomes hidden it reappears as open.

### Interactions with Other Systems

| System | In | Out | Owner |
|---|---|---|---|
| Quiz & stars | "quiz finished (hero, stars)" | (none) | Quiz GDD |
| Mission flow & beat types | `medal_earned`; asks which heroes are open and if the medal is already earned (for the skip warning) | open and completed state, medal state | Mission flow GDD |
| Save & progress | saved keys | writes `completed`, `seen_open`, `stars`, `medal` | Save GDD / D-04 ADR |
| Content data & claims | `index.json`, each `mission.json` `hero` (`timeline_order`, `next_hero`), claim status (R12) | (none) | Content contract |
| Map & timeline (Alpha) | (none) | per hero: state, stars, medal, place | Map GDD |

## Formulas

The F1 (open heroes) formula is defined as:

`open(h) = playable(h) ∧ (h = first(P) ∨ completed(prev_P(h)) ∨ seen_open(h))`, where `P` is the list of playable heroes sorted by `timeline_order`, `first(P)` its first element and `prev_P(h)` the hero just before `h` in `P`.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| playable(h) | bool | — | calculated (Rule 7: index + claim gate) | Can this hero appear |
| completed(h) | bool | — | save (`completed.<id>`) | Quiz finished at least once |
| seen_open(h) | bool | — | save (`seen_open.<id>`) | Was open before (never re-lock) |
| timeline_order | int | ≥ 1, unique | data file (`mission.json`) | Historical order |

**Output Range:** boolean per hero. With N playable heroes, between 1 and N are open. At least
the first is always open, so a child can always play.
**Example:** heroes A(10), B(20), C(30). A is completed, so A and B are open and C is locked.
An update adds A2(15) between them. A2 opens (A is completed), and B stays open (`seen_open`).

The F2 (collection progress) formula is defined as:

`stars_total = Σ_h stars(h)` over completed heroes; `medals_total = Σ_h medal(h)`; shown as `stars_total / (3 × N_playable)` and `medals_total / N_playable`.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| stars(h) | int | 1–3 (0 if not completed) | save | Best stars |
| medal(h) | int | 0–1 | save | Medal earned |
| N_playable | int | ≥ 1 | calculated | Playable heroes |

**Output Range:** 0 to 3N stars, 0 to N medals. When N grows with an update, the fractions drop
but the counts never do, so show counts ("★ 7 · 🏅 2") rather than percentages.
**Example:** 3 heroes with best stars 3, 2, 1 and medals 1, 0, 1 gives ★ 6 / 9 and medals 2 / 3.

## Edge Cases

- **If a release build has no playable hero** (every claim still pending, D-03 open): the title
  screen shows no hero to start. Behaviour matches R12's quiet guard; this is a known gate until
  Luan signs off, never an error screen.
- **If a content update removes a hero's folder**: it isn't playable, so it is skipped. Its saved
  keys stay (harmless), and the next hero opens from the hero before it (Rule 4).
- **If two heroes share a `timeline_order`**: validation fails (Rule 1, unique).
- **If `next_hero` disagrees with the timeline**: validation fails (Rule 6).
- **If a hero's claims are un-approved after release** (a correction): it becomes hidden in
  release builds until it is fixed. Its saved stars and medal stay. Heroes after it open from the
  playable hero before it (Rule 7).
- **If the quiz finishes on a replay of an already completed hero**: no unlock screen (nothing new
  opened). Results show best stars and the medal state.
- **If the medal is earned on a replay**: results celebrate it with `ui.medal.earned`, even though
  the hero was already completed (Rule 10).
- **If the app is killed between the quiz finishing and the results screen**: Save writes
  `completed`, `stars` and `medal` at quiz finish (before results), so nothing is lost.
- **If saved data is missing or unreadable**: start fresh (the first hero open, no stars). Never
  crash. The format belongs to the D-04 ADR.

## Dependencies

| System | Direction | Hard/Soft | Interface |
|---|---|---|---|
| Quiz & stars | this depends on it | Hard | Quiz finished with stars |
| Mission flow & beat types | this depends on it (medal), and it depends on this (open state, medal known) | Hard | `medal_earned`; open and medal state |
| Save & progress | this depends on it | Hard | The saved keys (Rule 11); storage rules in `design/gdd/save-and-progress.md` |
| Content data & claims | this depends on it | Hard | `timeline_order`, `next_hero`, R12 |
| Map & timeline | depends on this | Hard (Alpha) | Per-hero state, stars, medal |
| Language & text | this depends on it | Hard | Hero names, results, unlock and medal text (`design/gdd/language-and-text.md`) |

Quiz & stars and Mission flow both list Hero progression as a dependent (bidirectional).

## Visual/Audio Requirements

- **Medal:** a round bronze-drum medal (art bible §3 bronze-drum ring, §4 bronze gold) with a
  ribbon in the hero's colour. Not earned is an outline in the same shape (§4 colour-blind
  backup: fill vs outline). No text in the art. Drawn in code in the slice;
  `/asset-spec system:hero-progression` makes the real art.
- **Unlock:** the next hero's silhouette lifts from shadow into colour, with a chime. Calm, not
  flashy (no flashing faster than 3 Hz).
- **Results:** stars pop one by one (Quiz GDD), then the medal settles in with a soft drum.

## UI Requirements

- **Results:** this run's stars, best stars, the medal, and "Tiếp".
- **Unlock:** the hero's name (a Text from content), `ui.unlock.title`, and "Về bản đồ / To the
  map" (the title screen in the slice).
- **Title (slice) and map (Alpha):** each hero's state (locked, open, completed), stars and medal.
- 📌 **UX Flag — Hero Progression**: the results and unlock screens go into `/ux-design` with the
  quiz screen.

## Cross-References

| This doc references | Where | What |
|---|---|---|
| Quiz & stars | `design/gdd/quiz-and-stars.md` Rules 8–9 | Finish always unlocks; best-of stars |
| Mission flow | `design/gdd/mission-flow.md` Core Rules 14–15 | Nothing saved mid-mission; the medal rule |
| Content | `content/schema/mission.schema.json` (`hero.timeline_order`, `next_hero`), `content/README.md` R12 | Order, link, claim gate |
| Strings | `content/data/strings.json` `ui.unlock.*`, `ui.results.*`, `ui.medal.*` | Screen text |
| Concept | `design/gdd/game-concept.md` | Historical order; timed app updates |
| Decisions | `production/team/decisions.md` D-03, D-04, D-07, P-04 (3), D-16 (new) | Sign-off gate, save ADR, medal, saved keys |

## Acceptance Criteria

Criteria 1–8 and 11–12 are logic and need unit tests (shared fixtures recommended); 9–10 need
QC screenshots.

1. **GIVEN** a fresh install with heroes A(10), B(20), **WHEN** the title loads, **THEN** A is open
   and B is locked.
2. **GIVEN** A's quiz finished with 1★, **WHEN** progression updates, **THEN** B is open and the
   unlock screen names B.
3. **GIVEN** A completed and a content update adds C(30) after B(20), **WHEN** B is not completed,
   **THEN** C is locked. **WHEN** B is then completed, **THEN** C opens.
4. **GIVEN** A(10) completed and B(20) open (the title loaded once, so `seen_open.B` is set),
   **WHEN** an update inserts A2(15) between them, **THEN** A2 is open and B stays open.
5. **GIVEN** saved best 3★ for A, **WHEN** a replay finishes with 1★, **THEN** `stars.A` stays 3
   and no unlock screen shows.
6. **GIVEN** `medal.A` = true, **WHEN** a replay skips a story screen, **THEN** `medal.A` stays
   true.
7. **GIVEN** a release build where B has a pending claim, **WHEN** A is completed, **THEN** B is
   not shown, and the results show `ui.results.more_heroes` if no later playable hero exists.
8. **GIVEN** two bundled heroes with the same `timeline_order`, or a `next_hero` that isn't the
   next hero in `index.json` by `timeline_order`, **WHEN** content is validated, **THEN**
   validation fails (R17 / R18). Samples are excluded.
9. **GIVEN** results after a full-story run, **WHEN** captured, **THEN** the gold medal shows. After
   a skipped run, the outline medal and `ui.medal.missing` show, with no red (screenshot).
10. **GIVEN** the app killed right after the last quiz answer, **WHEN** it relaunches, **THEN** the
    hero is completed, its stars are saved, and the next hero is open.
11. **GIVEN** A(10) open but not completed (the title loaded once), **WHEN** an update inserts
    Z(5) before A, **THEN** Z is open (the first hero) **and A stays open** (`seen_open.A`).
12. **GIVEN** any title-screen load, **WHEN** it finishes, **THEN** `seen_open` is saved for
    every hero shown as open.

## Open Questions

| # | Question | Owner | By |
|---|---|---|---|
| D-16 | Saved keys: replace P-04 (3)'s `unlocked` list with `completed.<id>` + `seen_open.<id>` (+ `medal.<id>`), so unlocks are derived and survive content updates (Rules 4–5) | game-dev-ios + game-dev-android (D-04 ADR) | Before the save ADR |
| — | Should a hero's medal give anything beyond the badge, e.g. open its "Did you know?" fact page (linked to D-14, what stars measure)? | Luan | With D-14 |
| — | ~~`timeline_order` type~~ **Decided (devs and leader, 2026-11-14):** an integer in gaps of 10, with no year field. R17 and R18 come on a data branch after approval | game-dev-android | Closed |
