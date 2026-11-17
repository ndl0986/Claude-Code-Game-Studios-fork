# Decisions for Luan: Kid Learn Character

Status values: **Open** (needs Luan) · **Proposed** (the team applied a default; Luan can overturn
it) · **Decided** (Luan's call, with the date). The leader owns this file.

---

## Open

### K-04 Name of the game

- **Status:** Open. The working title is "Kid Learn Character" (folder `kid-learn-character`).

## Decided

### K-01 2D or 3D pictures (Luan, 2026-11-17, /brainstorm)

**2D first, 3D later** for a few favourites. The MVP is 2D illustrations with one shared stardust
morph effect.

### K-02 Language of the voice (Luan, 2026-11-17, /brainstorm)

**English first** (A). Vietnamese comes later as a second voice (Scope Tier "Full Vision").

### K-05 Voice: US or UK English; letter name or letter sound (Luan, 2026-11-17, /brainstorm)

**US English** ("zee"), and the **letter name, then the word**: "D… dinosaur".

### K-06 Concept: Letter Morph (Luan, 2026-11-17, /brainstorm)

Chosen from three concepts (Theme Alphabet, Mash World, Letter Morph): every key becomes its letter
or number, which dissolves into stardust and becomes the object. Mash World (objects stay in a
scene) is Scope Tier 2, after the MVP. Mash rule: a queue of at most 3 keys, further presses
ignored, about 3 s per reveal while keys are queued. See `design/gdd/game-concept.md`.

### K-08 Time of day and weather in the scene (Luan, 2026-11-17, /art-bible Section 2)

- **Time of day from the system clock:** a morning scene in the morning, day, then evening/dusk and
  night, following the device's clock. No network and no permission needed.
- **Weather from the network, opt-in:** if internet is available and a grown-up turns it on behind
  the parent gate, the scene follows the local weather. The app must ask for network, time and
  weather (location) access. This **changes Pillar 5 (Safe by Design) and the anti-pillar "no
  network, no data"**: the concept needs that revision. Before any build, game-qc-ios checks Apple
  Kids category + COPPA rules for network and location in a kids app (TASK-034). Scope tier: not
  decided (MVP or later).
- **Reveal glow pulse stays ~2.2 Hz** as in the prototype (Luan), over the art-director's "≤ 1 Hz"
  proposal.

### K-07 Themes and the key database (Luan, 2026-11-17, prototype play)

A **theme** (Dinosaurs first) covers **every key**: any letter A–Z or digit 0–9 shows a creature or
thing from that theme, and the letter may sit anywhere in its name (C = triceratops). Numbers show
that many items (3 = three baby dinosaurs). **Demo:** one fixed item per key per theme.
**Production:** a small database with several items per key per theme, enough for variety.

### K-03 Platforms (Luan, 2026-11-17)

**Fully native on every platform, Apple first.** iPadOS and macOS come first (Swift), then iPhone.
Android (Kotlin) comes after, as its own native app. No cross-platform engine.
Reaffirmed in /brainstorm (2026-11-17): Luan knows Unity, but this game stays native Swift.

### K-00 Process (Luan, 2026-11-17)

Follow the original Claude Code Game Studios process: /start → /brainstorm (game-concept) →
/setup-engine → /art-bible → /map-systems → /gate-check, and so on. The game folder is its own
studio project (it links `.claude/` and `CLAUDE.md`). The leader runs the Concept-stage skills
with Luan, and the team members get the later stages.
