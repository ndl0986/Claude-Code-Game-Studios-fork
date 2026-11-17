# Decisions for Luan: Kid Learn Character

Status values: **Open** (needs Luan) · **Proposed** (the team applied a default; Luan can overturn
it) · **Decided** (Luan's call, with the date). The leader owns this file.

---

## Open

### K-01 2D or 3D pictures

- **Options:** A. 2D illustrations with simple animation (cheapest, fastest, smallest app) ·
  B. 3D models that turn and move (most "wow", costs more to make and to run) · C. 2D now, 3D
  later for a few favourites.
- **Input coming:** art sourcing and cost (TASK-029), and what each app needs for 3D
  (TASK-030, TASK-031).
- **Status:** Open. Luan said "we will define later".

### K-02 Language of the voice

- **Options:** A. English only · B. Vietnamese only · C. both, chosen by the parent.
- **Status:** **Proposed A** (English first, Vietnamese added later). Luan's examples were English.

### K-05 Voice: US or UK English; letter name or letter sound

- From game-art-content (TASK-029 draft): US ("zee") or UK ("zed")? Say the letter name first
  ("D… dinosaur") or the letter sound ("duh…")?
- **Status:** Open. It goes into /brainstorm.

### K-04 Name of the game

- **Status:** Open. The working title is "Kid Learn Character" (folder `kid-learn-character`).

## Decided

### K-03 Platforms (Luan, 2026-11-17)

**Fully native on every platform, Apple first.** iPadOS and macOS come first (Swift), then iPhone.
Android (Kotlin) comes after, as its own native app. No cross-platform engine.

### K-00 Process (Luan, 2026-11-17)

Follow the original Claude Code Game Studios process: /start → /brainstorm (game-concept) →
/setup-engine → /art-bible → /map-systems → /gate-check, and so on. The game folder is its own
studio project (it links `.claude/` and `CLAUDE.md`). The leader runs the Concept-stage skills
with Luan, and the team members get the later stages.
