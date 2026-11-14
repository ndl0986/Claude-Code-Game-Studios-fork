# Save & Progress

> **Status**: Approved (peer review: game-dev-ios, 2026-11-14)
> **Author**: game-art-content (Luan decides)
> **Last Updated**: 2026-11-14
> **Last Verified**: 2026-11-14
> **Implements Pillar**: An toàn cho trẻ (Safe for kids), Nhỏ chơi được (Small hands can do it)
> **Task**: TASK-015 · Tier: standard (Player Fantasy and Tuning Knobs skipped by tier)

## Summary

The game remembers, only on the device: the language, and per hero whether the quiz was finished,
whether the hero was ever open, the best stars and the medal. Progress only ever goes up. It is
written at a few safe moments, all at once, and damaged data means a quiet fresh start, never a
crash. Nothing about the child is collected or sent anywhere.

> **Quick reference** — Layer: `Foundation` · Priority: `Vertical Slice` · Key deps: `None` · Used by: `Hero progression, Quiz & stars, Language & text, Audio & voice-over, Mission flow`

## Overview

This GDD states **what** must be saved and **the rules the storage must keep**. It feeds the
save ADR (D-04, game-dev-ios), which picks the storage technology (e.g. UserDefaults or
SharedPreferences), the file format and the migration code. Pillar *Safe for kids*: no
accounts, no network, no analytics, no identifiers. A child's progress belongs to the device it
was played on.

## Detailed Design

### Core Rules

1. **Saved keys** (D-16, Hero progression Rule 11), with nothing else:

| Key | Type | Written when | Meaning |
|---|---|---|---|
| `save_version` | int | every write | Format version, for migration (Rule 8) |
| `lang` | `vi` \| `en` | on a language switch (and the first-launch pick, if D-20) | Current language |
| `sound` | bool | on the sound toggle | Sound on or off (Audio GDD). New for both apps; persisted once the D-04 ADR lands. Defaults: `lang = vi`, `sound = true` |
| `completed.<hero_id>` | bool | quiz finish | Quiz finished at least once |
| `seen_open.<hero_id>` | bool | title load, and quiz finish | Hero was open at least once |
| `stars.<hero_id>` | int 1–3 | quiz finish | Best stars (F1) |
| `medal.<hero_id>` | bool | quiz finish, if `medal_earned` | Medal earned (never cleared) |

2. **Only up.** `completed`, `seen_open` and `medal` go false → true only. `stars` only rises
   (F1). No code path lowers or clears them, except a full reset (Rule 9).
3. **Nothing mid-mission** (Mission flow Rule 14). Beat progress, the hold meter,
   `story_skipped` and quiz retries live only in memory.
4. **Quiz-finish write is one unit.** At quiz finish, before the results screen shows, the game
   writes `completed`, `stars`, `medal` (if earned) and `seen_open` for every open hero
   **together**. Either all of them are stored or none (an atomic write, or write-then-rename).
   If the app is killed mid-write, the previous state survives intact.
5. **Title-load write.** Each time the title screen (the map after Alpha) loads, `seen_open` is
   set for every open hero (Hero progression Rule 5).
6. **Settings writes.** `lang` and `sound` are written immediately on change.
7. **Read once at launch.** All keys are read at launch into memory. Gameplay never blocks on
   storage, and writes don't stall a frame visibly (≤ 1 frame on the main thread, or done in the
   background).
8. **Versioning.** `save_version` starts at 1. A newer app reading an older version migrates
   forward (the ADR defines the steps). An older app that finds a **newer** version starts fresh
   **in memory** and does **not** overwrite the file. This only happens if a child installs an
   older build. **Read-only means no writes at all**, including `lang` and `sound`. Settings
   changed in that session live in memory only.
9. **Damaged or missing data.** If the save is missing, unreadable or fails validation (a wrong
   type, stars outside 1–3), start fresh: `lang = vi`, `sound = true`, no progress. Keep any
   individually valid key (e.g. a good `lang`) where the storage allows reading keys one by one.
   Never crash, and never show an error to the child; log it in debug.
10. **Unknown heroes.** Keys for a hero that's no longer bundled stay stored and are ignored
    (Hero progression edge cases). They're never deleted automatically, so a hero restored in a
    later update keeps its progress.
11. **Privacy.**
    - No personal data: no name, no photo, no voice recording, no device id, no location.
    - No network.
    - Saved values are game flags only.
    - Platform device backups (iCloud or Google backup of app data) are the parent's own
      backups. Whether to opt out is a question for the ADR (D-22).
12. **Reset.** There's no in-game reset in the slice. Deleting the app clears everything. A
    parent-area reset (Settings & parent area, Full Vision) would clear every key except `lang`
   and `sound`.

### States and Transitions

The save file is `absent` → `valid` (first write) → `valid` (later writes). Any read failure
counts as `absent` (Rule 9). A `newer-version` file is read-only for this app (Rule 8).

### Interactions with Other Systems

| System | In | Out | Owner |
|---|---|---|---|
| Hero progression & unlock | completed, seen_open, stars, medal to write | stored values at launch | Hero progression GDD (rules); this GDD (storage rules) |
| Quiz & stars | (via Hero progression) the run's stars | the best stars for the results screen | Quiz GDD |
| Mission flow | `medal_earned` (via progression) | whether the medal is already earned (for the skip warning) | Mission flow GDD |
| Language & text | `lang` on a switch | `lang` at launch | Language GDD |
| Audio & voice-over | `sound` on a toggle | `sound` at launch | Audio GDD |
| D-04 save ADR | (none) | these requirements | game-dev-ios |

## Formulas

The F1 (best stars) formula is defined as:

`stars_saved' = clamp(max(stars_saved, stars_run), 1, 3)`, applied at quiz finish; with no saved value, `stars_saved' = clamp(stars_run, 1, 3)`.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| stars_saved | int | 1–3 or none | save | Best before this run |
| stars_run | int | 1–3 | Quiz F1 | This run's stars |

**Output Range:** 1–3, never lower than before. A corrupt stored value outside 1–3 is treated
as missing (Rule 9), so it can't stick.
**Example:** saved 2, run 1 → stays 2. Saved 2, run 3 → becomes 3.

The F2 (save size) formula is defined as:

`bytes ≈ base + heroes × per_hero`, with base ≈ 64 B (version, lang, sound) and per_hero ≈ 4 keys × ~40 B.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| heroes | int | 1–100 | content | Heroes ever bundled |
| per_hero | int (B) | ~160 | constant (estimate) | Four keys with names |

**Output Range:** under 20 KB even at 100 heroes, so storage size is never a concern.
**Example:** 10 heroes ≈ 64 + 1600 ≈ 1.7 KB.

## Edge Cases

- **If the app is killed between the last quiz answer and the results screen**: the quiz-finish
  write happened first (Rule 4), so progress is kept (Hero progression AC10).
- **If the app is killed during the write**: the atomic write keeps the previous state. At most
  that one run's improvement is lost, never older progress.
- **If storage is full**: the write fails quietly, play continues, and the change is retried on
  the next write moment. Never crash.
- **If two writes race** (title load while a quiz-finish write is in progress): writes are
  serialised on one queue, in order.
- **If the child changes the language and then the app is killed**: `lang` was written at once
  (Rule 6), so the next launch uses it.
- **If the device clock changes**: nothing depends on time in the slice. (Storybook date unlocks
  later read the device date, not the save; Storybook GDD.)
- **If a migration fails**: start fresh in memory, keep the old file untouched for a later
  build's migration, and log it in debug.

## Dependencies

| System | Direction | Hard/Soft | Interface |
|---|---|---|---|
| Hero progression & unlock | depends on this | Hard | All progress keys |
| Quiz & stars | depends on this | Hard | Best stars (via progression) |
| Mission flow & beat types | depends on this (indirect) | Soft | Medal-known for the skip warning |
| Language & text | depends on this | Hard | `lang` |
| Audio & voice-over | depends on this | Soft | `sound` |

## Visual/Audio Requirements

None. Saving is silent and invisible. There's no "saving…" indicator (writes are instant and
safe).

## UI Requirements

None in the slice. The parent-area reset (Full Vision) needs a confirmation screen behind a
parental gate.

## Cross-References

| This doc references | Where | What |
|---|---|---|
| Hero progression | `design/gdd/hero-progression.md` Rules 3–5, 8, 9, 11 | What is saved and when |
| Mission flow | `design/gdd/mission-flow.md` Rule 14 | Nothing mid-mission |
| Quiz & stars | `design/gdd/quiz-and-stars.md` Rule 9 | Best-of stars |
| Language & text | `design/gdd/language-and-text.md` Rules 2–3 | `lang` |
| Decisions | `production/team/decisions.md` D-04, D-16, P-04 (3), D-22 (new) | Save ADR, keys, backups |

## Acceptance Criteria

All are logic (unit tests with a fake store) except 8 (a device check).

1. **GIVEN** no save, **WHEN** the app launches, **THEN** `lang = vi`, `sound = true`, the first
   hero is open, and nothing is completed.
2. **GIVEN** saved stars 3, **WHEN** a run finishes with 1★, **THEN** the stored value stays 3 (F1).
3. **GIVEN** a quiz finish, **WHEN** the write is interrupted after `completed` but before
   `stars` (simulated), **THEN** on reload either all the quiz-finish keys are updated or none are.
4. **GIVEN** a save with `stars.X = 7`, **WHEN** it loads, **THEN** that key is treated as missing,
   and the other valid keys load.
5. **GIVEN** an unreadable save file, **WHEN** the app launches, **THEN** it starts fresh with no
   crash and no error UI.
6. **GIVEN** a save with `save_version` higher than the app supports, **WHEN** it launches,
   **THEN** it runs fresh in memory and the file is unchanged afterwards.
7. **GIVEN** `medal.X = true`, **WHEN** any later run happens (with or without skips), **THEN**
   `medal.X` is still true.
8. **GIVEN** the slice on a device, **WHEN** the network is off for the whole session, **THEN**
   everything saves and loads normally, and no network request is made (QC with network logs).
9. **GIVEN** the language switched to EN, **WHEN** the app is force-quit at once and relaunched,
   **THEN** it starts in EN.

## Open Questions

| # | Question | Owner | By |
|---|---|---|---|
| D-04 | The save ADR: storage tech, file format, atomic write, migration steps, built from Rules 1–12 | game-dev-ios (game-dev-android reviews) | After the slice |
| D-22 | Platform backups: allow the default iCloud/Google backup of the save (the parent's own backup; progress survives a new phone), or exclude it? | Luan (privacy), with the devs | With D-04 |
