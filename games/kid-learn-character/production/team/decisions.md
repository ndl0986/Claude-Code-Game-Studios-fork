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

### K-20 Reveal Stage and gate hardening (Luan, 2026-11-18, TASK-048 review + TASK-049 questions)

- **Gate hardening (adds to K-19):** after a wrong answer or a timed-out challenge, the moon "sleeps"
  for 10 s (a knob; nothing is stored, no visible lockout); step 2 uses **four** number words
  (e.g. "four · one · seven · two"). Hourly pass risk for a mashing child stays below ~0.1%.
- **Challenge open freezes play:** the reveal, the queue and the hints freeze while the number
  challenge shows; a wrong answer or timeout resumes them. Only a correct answer opens the panel, and
  K-15's queue clear applies then.
- **Stage fit:** contain the 1280×720 safe stage and **extend the sky and ground** to fill the screen.
  No bars, nothing cropped. iPads get more sky and ground; wide Mac windows get wider hills (the
  parade walks farther). Hints and queue tokens stay in the safe stage. Reveal Stage owns the transform.
- **Reduce Motion for the reveal softens:** the glyph rises straight with no scale overshoot, the
  creature appears with no pop overshoot, and the leaving creature fades without sinking.

### K-19 Parent gate (Luan, 2026-11-18, TASK-048 questions)

- **Two steps:** hold the moon ~1.5 s, then a **number written in words** ("Enter four · one · seven")
  on a 0–9 keypad, new each time. Never spoken by the game's voice; English text until Localization.
- **Mac chord ⌃⌥⌘Q replaces the moon hold but still shows step 2** (one gate everywhere).
- **The panel auto-closes after 60 s** with no input (a knob).
- **"Play the parade now" is debug-build only;** release builds have no such button (also K-17).

### K-18 Hint letters (Luan, 2026-11-18, TASK-047 questions; team proposals accepted)

- A hardware key that matches an on-screen hint **consumes that hint** and the glyph rises from it
  (as played).
- A new hint never repeats a key on screen, the current reveal's key, **or a queued key**.
- Hints pulse gently until the first press (as played), reset on each entry to Play.
- An ignored hint that stays **restarts its life** from that touch (full opacity).
- Panel open: hints freeze under the dim and carry on after close. Background: hints clear; three
  fresh ones spawn on return.
- **The Mac shows hints too** (clickable).
- Reduce Motion: no drift, no pulse, no scale-in; the consume burst becomes a plain fade.

### K-17 Parade (Luan, 2026-11-18, TASK-046 questions)

- **A parade every 6 creatures met** (changes the brief's 8). **A key pressed again within the same
  batch counts once.** Parades keep coming for as long as the child plays (no cap at 32/36).
- **Letters and digits both count;** a digit walks as its group (e.g. three babies) at parade size.
- **A press mid-parade:** the parade keeps walking behind, the new reveal plays in front (as played).
  **Panel open or background:** the parade fades out, counts as played, and is not replayed.
- **The count is per theme;** a parade never mixes themes.
- Reduce Motion: the same 11 s walk, step bob ×0.5. Art not ready: wait ≤ 0.5 s, then walk without
  the missing figure. Tapping a walking figure only sparkles.
- No "Play the parade" button in release builds (debug only).
- Leader defaults (not asked): the unit is the key, not the castId; a glyph-only fallback (art
  missing) does not count as met.
- Cast Rendering note accepted: in a mash at the normal set with no word extension, K-16's 0.5 s
  late-art wait is in practice 0.05 s (art is prefetched, so it is rare).

### K-16 Cast rendering choices (Luan, 2026-11-18, TASK-044 questions)

- **Reduce Motion softens:** idles at half amplitude, a smaller tap hop, the glyph halo holds steady
  (no pulse).
- **MVP keeps per-part idles** as in the prototype (neck sway, jaw nod, wing flap…): each SVG carries
  named part groups with a pivot.
- **Stardust stays as played** (70% gold specks, ~1.4 Hz twinkle; the parade's step bob too): a
  recorded exception to the art bible's "gold only for letters" and "other pulses ≤ 1 Hz" rules.
- **Art not loaded in time:** the stardust holds the shape up to 0.5 s, then the creature fades in.

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
