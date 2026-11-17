# Kid Learn Character: kickoff notes (input for /brainstorm)

**Status:** Concept (2026-11-17). Luan's request, written down by the leader. Working title; the
real name comes later.
**Priority:** highest. Dải Đất Anh Hùng is on hold (`games/dai-dat-anh-hung/`).

## The idea (Luan's words, cleaned up)

The players are very young children who are still learning the ABC, numbers and pictures.

The game shows a simple keyboard with the letters and the numbers. When the child touches a key
on the screen, or presses it on a real keyboard, the game shows a picture of something for that
key and plays its sound.

- Press **D**: a dinosaur appears (2D or 3D, to be decided) and roars; a voice says "D… dinosaur".
- Press **1**: the number ONE appears, and a voice says "one".

## Core loop

1. The child presses any key (screen or hardware). There is no wrong answer and no fail state.
2. Within a moment the key's picture fills the screen with a short animation, the object's sound,
   and the spoken letter or number plus the word.
3. The next key press replaces it at once. Mashing keys must never break, stack up or freeze
   the game.

## Content (first set)

- Letters **A–Z**: one object per letter, with a picture, an object sound (if it has one) and the
  spoken word.
- Numbers **0–9**: the numeral, the word ("ONE"), a count of simple objects (one apple, two
  apples…) and the spoken number.
- The list of objects is owned by game-art-content (TASK-029).

## Rules the team keeps from day one

- **Made for toddlers:** big keys, bright and calm, no text the child needs to read, no timers,
  no scores, no losing.
- **Safe:** no ads, no in-app purchases, no links out, no accounts, no network, no data collected.
  It must pass the Apple Kids category and the Google Play Families policy.
- **Parent gate:** anything that is not play (settings, language) sits behind a grown-up check.
- **Works offline,** with all pictures and sounds inside the app.
- **Hardware keyboard:** an iPad or Android tablet with a keyboard plays the same as touch.
- **Data-driven:** the key → picture → sound table is data (JSON), not code.

## Defaults the leader applied (Luan can change any of them)

| Topic | Default | Why |
|---|---|---|
| Folder | `games/kid-learn-character/` | Luan wrote `game/`; the repo already uses `games/`, so the two games sit side by side |
| Platforms | **Decided K-03:** fully native, Apple first (iPadOS + macOS), then iPhone; Android later | Luan, 2026-11-17 |
| Language | English first; Vietnamese later as a second voice | Luan's examples are English ("dinosaur", "ONE") |
| Art | Decided after TASK-029 and the tech plans compare 2D and 3D | Luan said "2D/3D, we will define later" |

## Open decisions for Luan

See `production/team/decisions.md` (K-01…).

## First tasks

See `production/team/board.md`.
