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

### K-09 Theme content rules (Luan, 2026-11-18, TASK-036 questions)

- **Real names stay**, even the hard ones (quetzalcoatlus, wuerhosaurus, juravenator…).
- **The child must hear the letter's usual sound in the word** (K-07 still lets it sit anywhere in
  the name): silent or shifted letters (P in pteranodon, X in xenoceratops) get replacements, which
  game-art-content proposes and Luan picks. G = gallimimus is fine (hard g).
- **Production variety: 4–5 items per key per theme**; default pick rule: uniform with no immediate
  repeat (to confirm when the GDD is reviewed).
- **Numbers follow the theme:** "three… three baby dinosaurs" in Dinosaurs, "three little cars" in a
  vehicles theme; 0 = the theme's "empty" item.
- T stays "tee… tee rex"; F = fossil and N = nest stay (theme-world objects are allowed).
- Letter-sound picks (TASK-036): **P = Tapejara** (replaces pteranodon); **X = Xenoceratops kept as the
  one recorded exception** to the letter-sound rule; Triceratops, Oviraptor, Utahraptor and
  Quetzalcoatlus kept.

### K-10 Input rules (Luan, 2026-11-18, TASK-037 questions)

- **Keyboard layout: by the character printed on the key** (character first, folded to A–Z/0–9),
  with a US-QWERTY position fallback for keys that give no A–Z/0–9 (AZERTY digit row, non-Latin).
- **Parent chord: ⌃⌥⌘Q on the Mac only.** An iPad with a keyboard has no chord; the moon hold is the
  way in.
- Swallowed keys do nothing at all; a tap on the empty stage sparkles (from Luan's play notes).
- **Title screen:** any letter or digit key starts play (like the play button), from TASK-037's question.

### K-11 Morph choices (Luan, 2026-11-18, TASK-038 questions)

- **240 stardust particles** to start (measured on Mac/Simulator); raise only after the real-iPad
  measurement.
- **A different morph on every press** (seed from the key and the press count, reproducible in debug).

### K-12 Settings (Luan, 2026-11-18, TASK-039 questions)

- An in-app **volume slider** (default 0.8) plus mute.
- The hand-picked **weather is kept until changed** (no date stored).
- **Mac child lock comes back on after a relaunch, but only once the app is ready** (after the first
  frame, with the ⌃⌥⌘Q chord working), because the kiosk blocks force-quit and shutdown.
- **Device backups allowed** for the settings (settings only, nothing personal).

### K-13 Audio and voice (Luan, 2026-11-18, TASK-041 questions)

- The **word plays 0.25 s after the cast sound** (cast ducked) and a waiting key **does not cut it**
  (the hold extends to the word's end, capped +1.5 s; with 3 queued the last reveal waits ~2.7 s
  longer).
- An overflow press (queue full) gives the **softer ping**.
- **Voice: TTS pre-rendered at build time** into the same file pipeline; a human re-record for release
  and the TTS licence stay open.
- **Respect the device's silent switch** (device silent → game silent).
- Loudness targets as proposed (voice −16 LUFS, cast −20, chime −26, ping −30, parade −22,
  ≤ −1 dBTP), tuned in play.
- Numbers: **one chirp per item**, counting along up to 9.

### K-08 Time of day and weather in the scene (Luan, 2026-11-17, /art-bible Section 2)

- **Time of day from the system clock:** a morning scene in the morning, day, then evening/dusk and
  night, following the device's clock. No network and no permission needed.
- **Weather: picked by hand, no network** (revised by Luan after TASK-034, 2026-11-17). A grown-up
  picks today's weather (clear, cloudy, light rain, snow, windy) behind the parent gate; the app makes
  **no network call** and uses **no location**. Pillar 5 (Safe by Design) and the no-network
  anti-pillar stay as they are. TASK-034 (`design/compliance/TASK-034-kids-weather-rules.md`) found a
  third-party weather API is not allowed in the Kids category and precise location needs verifiable
  parental consent; its WeatherKit + parent-picked-city design is kept on file if live weather is
  ever revisited.
- **Reveal glow pulse stays ~2.2 Hz** as in the prototype (Luan), over the art-director's "≤ 1 Hz"
  proposal.

### K-07 Themes and the key database (Luan, 2026-11-17, prototype play)

A **theme** (Dinosaurs first) covers **every key**: any letter A–Z or digit 0–9 shows a creature or
thing from that theme, and the letter may sit anywhere in its name (C = triceratops). Numbers show
that many items (3 = three baby dinosaurs). **Demo:** one fixed item per key per theme.
**Production:** a small database with several items per key per theme, enough for variety.

### K-15 Press Queue rules (Luan, 2026-11-18, TASK-043 questions)

- Opening the grown-up panel **clears the queue**; the current reveal settles to formed under the dim.
- App to background mid-reveal: **clear the queue**, the creature is shown formed on return; the next
  press starts at once.
- Reduce Motion keeps the **3 s hold** (it changes motion, not pace).
- A hint touched while the queue is full (ignored) **stays** on screen.

### K-14 Merge authority (Luan, 2026-11-18)

The leader merges a finished task into `docs/kid-learn-character-plan` and pushes **without asking
again**, once the task's peer or independent review is APPROVE; the leader reports merges after the
fact. Design, content, ADR acceptance, engine, store, money and legal calls still go to Luan. Merges
into `main` still need Luan's go.

### K-03 Platforms (Luan, 2026-11-17)

**Fully native on every platform, Apple first.** iPadOS and macOS come first (Swift), then iPhone.
Android (Kotlin) comes after, as its own native app. No cross-platform engine.
Reaffirmed in /brainstorm (2026-11-17): Luan knows Unity, but this game stays native Swift.

### K-00 Process (Luan, 2026-11-17)

Follow the original Claude Code Game Studios process: /start → /brainstorm (game-concept) →
/setup-engine → /art-bible → /map-systems → /gate-check, and so on. The game folder is its own
studio project (it links `.claude/` and `CLAUDE.md`). The leader runs the Concept-stage skills
with Luan, and the team members get the later stages.
