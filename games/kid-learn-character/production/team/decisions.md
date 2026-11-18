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

### K-37 App identifiers, signing and the SVG layer-id note (Luan, 2026-11-18)

- **Bundle ID follows the previous game's pattern** (com.galaxyandsun.daidatanhhung), with only the game part changed:
  `com.galaxyandsun.lettermorph`, target `LetterMorph` (working name until K-04; changeable before the first store
  upload). Tests/preview suffixes as in the previous game.
- **Signing: Luan's Personal Team** (already signed in to Xcode; used for the previous game on iPhone). Automatic signing;
  the team ID stays in an untracked local config, never committed.
- **ADR-0003 D4 / art bible §8:** layer groups are identified by an id ending in `_body`, `_outline` or `_detail`
  (`<part>_<layer>`, unique in the file); a dated clarification note, ADR status stays Accepted.

### K-36 espeak-ng as a build-time tool only (Luan, 2026-11-18)

- espeak-ng (GPL-3.0) may be used **only on the build machine** as the phonemiser when rendering voice files; it is
  never bundled, linked or shipped. The app ships only the rendered WAV/audio files. Record under Privacy L-09 and the
  ADR-0003 D6 TTS note when the K-33 voice pick lands.

### K-35 Hard dinosaur names are respelled in the voice script (Luan, 2026-11-18)

- When the TTS engine does not say a name the common US way (e.g. quetzalcoatlus, both engines in TASK-073), the voice
  script carries a **respelled input** (e.g. "ket sul koh AT lus") for that line only; the displayed name and the Key
  Table name stay spelled correctly. Each respelled line is listened to and approved before it is baked.
- Applies whichever engine is picked (K-33 pick still pending: Luan listens to the TASK-073 samples).

### K-34 Device-time rule and an ADR-0002 correction (Luan, 2026-11-18)

- **MAC FREE applies to anything that takes the Mac's screen, keyboard or focus** (launching the macOS app, macOS
  UI tests, the kiosk, key injection, nettop / log stream sessions, Simulator windows). **Headless runs do not need
  it:** swift test, xcodebuild build, and tests on the developer's own headless simulator, at nice 10 and stopping
  if load exceeds ~40.
- **ADR-0002's unknown-device ppi rule was inverted:** to never shrink a physical target, assume the **highest** ppi
  in the device class, not the lowest. Recorded as a dated amendment note in ADR-0002 (status stays Accepted); ADR-0006
  D7 states the corrected rule.

### K-33 TTS engine for the pre-rendered voice (Luan, 2026-11-18)

- From a licence survey (code AND voice-model licences; non-commercial licences excluded): Luan wants **both
  Kokoro-82M `af_heart` (Apache-2.0 code and weights) and Piper `en_US-ljspeech` (MIT code, public-domain LJSpeech
  data; pin the archived MIT rhasspy/piper, not the GPL fork) tried**; sample clips of both, then Luan picks.
- Rejected on licence: Coqui XTTS-v2 (CPML), F5-TTS (CC-BY-NC), Piper `lessac` (research-only data), StyleTTS2
  (synthetic-speech disclosure condition), Chatterbox (watermark). Attribution line goes in the app's acknowledgements.
  L-09 closes once Luan picks and the chosen licence and commit are recorded.

### K-32 Monetisation and voice licence (Luan, 2026-11-18)

- **No ads, reaffirmed.** Luan asked about a free release with ads; after the conflicts were laid out (concept
  "Monetization: None", PKC-02/05, App Store Kids category Guideline 1.3, Google Families ad rules, COPPA), Luan
  chose to **keep the game ad-free**. Free, no ads, no in-app purchases (concept unchanged).
- **The TTS voice still needs a licence that allows public distribution of the rendered audio**, even for a free
  app; L-09 stays open until the engine is chosen. Until then the pipeline uses placeholder files (ADR-0003 D6).

### K-31 Build tools (Luan, 2026-11-18, TASK-066 Q2)

- **Own Swift build tools, no third-party build tools:** SVG parsing (XMLParser), loudness (BS.1770 in Swift),
  AAC encoding (AVFoundation), glyph baking (CoreText). No ffmpeg, sox or SVG libraries (keeps licences and the
  supply chain out of the build; PKC-03).
- TTS engine (L-09): still open. Luan asked whether a free, ad-supported release needs a commercial licence —
  answered 2026-11-18 (yes: free + ads is commercial use); the ads question itself is raised separately.

### K-30 Accessibility scope (game-leader, 2026-11-18, TASK-061; within K-29 and the art bible)

- **Smart Invert: the stage opts out** (`accessibilityIgnoresInvertColors = true` on the stage view), because
  inverting breaks art bible §4 contrast and colour meanings; the grown-up panel follows Smart Invert. Classic
  Invert / macOS Invert are OS-wide and the user's choice.
- **MVP scope confirmed:** Reduce Transparency has no effect (no system blur/vibrancy); Increase Contrast is not
  supported in the MVP (art bible §4 floors are the contrast design); Bold Text applies to the panel only (the child
  side has no text); no captions (the child cannot read; the glyph and creature are the visual equivalent).
- Note for the art bible owner: the red-flash palette check (Accessibility F2b) passes Letter Gold at 0.781 against
  the 0.8 saturated-red limit; any warmer gold must re-run F2b.

### K-29 Keyboard Row and Accessibility (Luan, 2026-11-18, TASK-060 / TASK-061 questions)

- **Keyboard row keys: as random as possible, drawn from common words/names.** The row shows a short, common
  word or name (≤ 8 letters, the cap TASK-060 set to stay clear of edge insets at the 18 mm floor), picked at random from a per-theme pool of the most
  common/familiar words and names — not necessarily the full theme word ("DINOSAUR") or anything longer, as in
  the first prototype. Luan approved TASK-060's proposal (same day): a per-theme `rowWords` pool; Dinosaurs =
  REX, EGG, NEST, ROAR, DINO, BABY, MOM, DAD, SUN, MOON, STAR, CAT, DOG, BALL, HAT, BUS (no people's given
  names); a seeded uniform pick with no immediate repeat; **the word changes once every key of it has been
  pressed at least once, and on each entry to Play**, only at a quiet moment (no finger on the row, stage
  resting), with a 0.3 s fade.
- Keyboard row: shown whenever the grown-up turned it on, even with a hardware keyboard; stays fully visible and
  active during a parade (not dimmed like hints); hidden on the Title, fades in on Play; a hardware press of a row
  letter also lights that row key.
- **Reduce Motion: the stardust twinkle holds steady** (fixed alpha, no twinkle), like the halo.
- **Switch Control / AssistiveTouch grown-ups:** accepted for the MVP and documented (Mac: the chord; iPad: pause
  Switch Control to open the gate).
- **Mid-session Reduce Motion toggle:** reveal-locked parts change from the next reveal; ambient motion (clouds,
  hints, parade, idling creature) changes on the next frame.

### K-28 Architecture setup choices (Luan, 2026-11-18, TASK-059 questions)

- **CI: local first** (xcodebuild / swift test on the Mac under MAC FREE; QC runs the suites); GitHub macOS
  runners later if needed (paid minutes).
- **Signing for device spikes: a free Personal Team** on Luan's Apple ID (7-day provisioning, Luan's own iPad);
  the paid Apple Developer account waits for TestFlight / store.
- **A native-apple engine reference** (now at `docs/engine-reference-local/native-apple/`) may be added (docs only: versions and proven/Apple-sourced API notes) so
  /create-architecture can run; `engine.name` stays unset (ADR-0001). Luan, same day: **keep it inside this game's
  folder** (the game's docs/engine-reference/ is a symlink to the template's shared folder; nothing goes there).

### K-26 Busy moments and favourite keys (Luan, 2026-11-18, TASK-055 cross-review)

- **Hints dim while a parade walks:** during the parade's Walking state the hint letters fade to a lower
  opacity and hold still (no drift, no new spawns); they stay tappable. Weather is unchanged.
- **Accepted on purpose:** a child who only presses one or two favourite keys never sees a parade (K-17 counts a
  repeat once). The parade rewards trying new keys; hint letters invite them.
- Leader call (B-1): the Mac chord follows Input R6 as owner: exactly ⌃⌥⌘ + Q, Shift ignored, **Fn disqualifies**
  (a palm on a laptop's bottom-left row hits fn next to ⌃). Parent Gate G2 drops "Fn is not another key".

### K-25 Glyph contrast during sky crossfades (Luan, 2026-11-18, TASK-054b review; corrected same day)

- **The glyph's edge switches with the sky:** cream above / amber below the equal-contrast sky-mid luminance
  L_x ≈ 0.308, with a **1 s time cross-dissolve** (wall clock) at the switch — not a colour blend over sky L
  (a mixed edge drops to ~1.4:1). The build check skips that 1 s window.
- **Correction (exact hexes):** with amber #8a4b12 (L 0.105) and cream drawn at 85%, the minimum was ~2.32:1,
  not the 2.55 first reported. Luan chose to **darken the amber edge to #80450f** (L 0.089) and draw the
  **cream edge at 100%**: minimum 2.57:1; Morning/Day contrast also rises (≈ 4.3 → 4.8, 3.9 → 4.4). Art bible
  §2/§4's #8a4b12 gets a dated amendment.
- **Dated exception to art bible rule 2 (≥ 3:1):** ≥ 3:1 at the looks themselves (w = 0 and 1); ≥ 2.5:1 inside
  a 15-min boundary crossfade or the 3 s jump fade, for a few minutes around 16:04–16:12 and 06:04–06:13.
- Rejected: an Ink outline on the glyph (breaks art bible §5), a faster sky crossfade (only shortens the dip),
  lowering the floor to 2.3:1.

### K-24 Scene: Time of Day & Weather (Luan, 2026-11-18, TASK-053 questions)

- **A weather change from the panel fades in over ~2 s** while the panel is open (not the art
  bible's 15-min crossfade, which is for time of day), so the parent sees it on close.
- **Reduce Motion:** clouds hold still; rain and snow at half count and half speed (windy tilt kept);
  stars steady, no twinkle.
- **No weather or ambient sound** (Audio's no-music-bed rule stands).
- Team proposals accepted: the 15-min time-of-day crossfade starts at the boundary (16:00 → fully
  Dusk 16:15); a clock / time-zone / DST jump fades to the new look over 3 s; rain and snow show 2–3
  pale clouds; the horizon warms during a parade (peach by day, amber by night, within the caps); the
  Title shows the weather too.

### K-23 Child Lock-in (Luan, 2026-11-18, TASK-052 questions)

- **Extra displays on a locked Mac** are each covered by a plain dusk window that swallows clicks.
- **iPad with Guided Access on:** the moon and the gate stay as they are; the panel's lock page
  shows "Guided Access is on".
- **The Mac lock can't engage** (a precondition still missing after ~5 s): stay unlocked, show the
  child nothing; the next panel open shows "Child lock couldn't turn on". Never lock without a way out.
- **App goes inactive while locked** (system alert, Notification Center): the options are released
  and re-applied on return, with nothing shown to the child.

### K-22 App Shell & Title (Luan, 2026-11-18, TASK-051 questions)

- **Long background:** returning after more than 30 min away (process still alive; measured on the
  continuous clock, which counts device sleep, in memory only) goes to the Title; a shorter absence returns to Play with the settled creature (K-15).
- **Title start by touch: any tap except the moon** (as played); letter and digit keys too (K-10).
- **No text on the Title** (no wordmark, no control hints); only the grown-up panel has text.
- **One title creature per theme** (Dinosaurs: T-Rex, as played): a Key Table field `titleCastId`.

### K-21 Gate risk and Mac child lock (Luan, 2026-11-18, TASK-048 revised plan)

- **Correction to K-20's risk figure:** with 4 number words and a 10 s moon sleep, the hourly pass
  risk is ≤ ~0.1% at a realistic ≤ 10 accidental openings per hour, and ~3% per hour if a child mashes
  the gate nonstop (~307 attempts/h). Luan keeps **4 words + 10 s**; F2 states both figures.
- **Mac child lock turned OFF in the panel reverts to ON at the next launch** (it engages once the
  app is ready, K-12). OFF lasts for this run only; closing the panel shows "Child lock is OFF" for
  a few seconds. This changes Settings Store R1/R8 (`childLock` is not persisted as false).

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
