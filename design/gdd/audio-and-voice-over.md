# Audio & Voice-over

> **Status**: In Review
> **Author**: game-art-content, with the audio-director and sound-designer agents (Luan decides)
> **Last Updated**: 2026-11-14
> **Last Verified**: 2026-11-14
> **Implements Pillar**: Sống lại câu chuyện (Live the story), An toàn cho trẻ (Safe for kids), Nhỏ chơi được (Small hands can do it)
> **Task**: TASK-015 · Tier: standard (Player Fantasy and Tuning Knobs skipped by tier)

## Summary

A warm modern kids' score with Vietnamese instruments as accents. Each game state has its own
music, crossfaded. Soft, friendly sound effects confirm every action, and success is always
louder than a mistake. There is one sound on/off setting. Voice-over reads every story line and
quiz line in VI and EN. It is planned and optional until the vertical slice is signed off: the
slice ships with text only.

> **Quick reference** — Layer: `Presentation` · Priority: `Vertical Slice` · Key deps: `Content data & claims, Language & text, Save & progress` · Used by: `Mission flow, Combat, Quiz, Hints, Hero progression` (as event sources)

## Overview

- **What this system owns:** the sonic identity, music per state, the SFX event list, the mix
  (buses, levels, ducking, voice limits), the sound setting, and the voice-over rules (narrator,
  pacing, file mapping).
- **What it does not own:** when events happen (each source GDD), or the words (content).
- **Source of the direction:** the audio-director and sound-designer agents (TASK-015), checked
  against the GDDs and the TASK-003 QC record.

## Detailed Design

### Core Rules

**Sonic identity**

1. **Bronze heart, modern body.**
   - The score is warm and modern: soft piano or marimba, light strings, pad, clean percussion.
   - Vietnamese instruments are featured accents, **at most 2 per cue**: trống đồng (bronze-drum)
     hits, sáo trúc (bamboo flute), đàn tranh (zither); đàn bầu (monochord) only for the title
     motif and the calm ending.
   - Everything is in **one pentatonic family**, so UI chimes never clash with the music.
   - Design test: with the traditional instruments muted the cue still works; with them on, a
     Vietnamese listener hears "Vietnamese" within 5 s.
2. **Brave, never frightening.**
   - No human pain sounds: no screams, grunts or cries.
   - No flesh or blade impacts, no breaking, no horror dissonance, no sub-bass below 60 Hz, no
     sudden loud stingers.
   - A hit is a **drum**, not an impact. Enemies leave on a comic "run away" jingle.
   - Design test: would it fit a cartoon for 4-year-olds, with a teacher in the room?
3. **Success is louder than failure.**
   - Every right or done sound is **≥ 6 dB louder** and longer than its wrong or try-again
     counterpart.
   - Wrong is soft, short and low; it's never a buzzer.
   - Getting pushed is a soft bonk, never a hurt sound.
4. **The voice is the reader.** Voice-over and text always win the mix. The score is never a
   history claim: trống đồng as colour does not mean the Trần army played it.

**Music per state** (time-based crossfades in the slice). **Looping (all platforms):** m4a/AAC can't loop gaplessly on Android's platform player (encoder priming and padding), so each loop is **authored with a ~0.5 s overlap tail** (the end flows into the start) and the apps loop it with a **self-crossfade of two players** (0.5 s). Cue-to-cue crossfades use the same two players.

| State (mission flow) | Mood (art bible §2) | Tempo | Instruments | Loop |
|---|---|---|---|---|
| Title (and map) | Welcoming, "my country" | 96 BPM | Piano/marimba, light strings, hero motif on sáo answered by đàn bầu | 40 s |
| Story screens (intro, beat card, caption) | Hushed, "sit close" | 72 BPM | Pad, felt piano, sparse đàn tranh; no drums | 53 s |
| Walk, training | Breezy journey | 108 BPM | Marimba ostinato, pizzicato, hand percussion, sáo melody | 71 s |
| Hold-meter (the orange) | Building determination, not anger | follows walk | A **layer** over the walk bed: a sáo sustain plus đàn tranh tremolo rising with the meter; a pluck at 25/50/75%; at 100% one trống đồng hit; holds its level on release (no drain) | 18 s layer |
| Fight, reach-the-flag | Windswept, heroic | 124 BPM | Trống đồng plus toms (mid-range attack), strings, pad, sáo melody. Base layer always; top layer only while enemies are active | 62 s |
| Beat end | Small win | — | 1.5 s cheer sting | one-shot |
| Calm ending | Still, reverent, gentle | free or 60 | Đàn bầu solo over a soft pad, one soft bronze-drum "bell". Major-leaning, no percussion pattern | 60 s (intro, then loop) |
| Quiz | Calm focus | 88 BPM | Sparse marimba and pad, nothing in the 1–4 kHz voice band | 44 s |
| Results, medal, unlock | Golden peak, warm hold | 88 BPM | 3–4 s fanfare, star plucks rising, soft bronze drum for the medal, calm unlock chime | 44 s |
| Paused | — | — | Music bus −12 dB over 0.3 s; SFX and voice paused | — |

Key crossfades: title → intro 1.5 s; walk → fight 0.75 s plus a drum pickup; last beat → calm
ending **3.0 s** (never a hard cut); ending → quiz 2.0 s; quiz → results 0.3 s, then the fanfare.

**Sound effects**

5. **The SFX event list**, with each event's trigger in its source GDD:

| Event id | Trigger (source) | Character | Prio |
|---|---|---|---|
| `sfx_attack_swing` | A swing starts (combat frame step 4) | Airy padded swoosh, 4 variants | 2 |
| `sfx_attack_hit` | A hit lands (combat F5; once per swing) | Warm low bronze-drum "dum", 4 variants | 2 |
| `sfx_block_clang` | A strike is blocked (combat F6; training blocks) | Rounded wood "tok-clang" | 1 |
| `sfx_hero_pushed` | An unblocked strike (combat Rule 5) | Soft comic bonk, surprise not pain | 1 |
| `sfx_enemy_windup` | Entry into `windup`; again when a telegraph restarts on resume | Warm rising two-note woodblock "get ready", lower for the leader | 1 |
| `sfx_enemy_strike` | Entry into `strike` (dropped if a clang or bonk plays that frame) | Short soft whoosh | 3 |
| `sfx_enemy_flee` + `sfx_weapon_drop` | Last hit, entering `flee` (combat Rule 12) | Cheeky 3–4 note jingle, then a dull wooden clatter | 2 / 3 |
| `sfx_bump_stop` | A walk-beat bump (mission flow F2) | Soft "boop" | 2 |
| `sfx_meter_fill_loop` / `sfx_meter_pulse` / `sfx_meter_done` | Hold-meter rising / at 25/50/75% / full | Rising shimmer / stepped bronze "ting" / warm "ta-da" | 2 / 2 / 1 |
| `sfx_dummy_hit` / `sfx_training_step_done` / `sfx_banner_raise` | A dummy hit / a training part done / the banner raised | Straw "fwump" / small rising "tick-ding" / cloth flap plus a drum | 2 / 1 / 1 |
| `sfx_flag_reached` | Flag touched (reach-the-flag goal) | Flag flap plus a bright 3-note rise | 1 |
| `sfx_beat_end_cheer` | Every beat end, after `end_pause` | Short small-group "yay" plus sparkle | 2 |
| `sfx_ui_next` / `sfx_ui_skip` / `sfx_skip_warning_open` / `sfx_ui_tap` | Tiếp / a Skip that skips / a Skip that opens the warning / other menu buttons | Page turn / quick riffle / gentle card slide plus a soft bell (no "uh-oh") / soft tap | 1 |
| `sfx_quiz_wrong` / `sfx_quiz_right` / `sfx_quiz_why` | `wrong_feedback` / `right_feedback` / `why_shown` (quiz) | Soft low "boop-boo" (−12 dB UI) / bright rising chime (−6 dB) / paper unfold | 1 / 1 / 2 |
| `sfx_star_pop` ×3 / `sfx_star_empty` | Results stars | Rising plucks (do, mi, sol) / a neutral wooden "tuk" | 1 |
| `sfx_medal_earned` / `sfx_medal_missing` | Results medal (Hero progression Rule 10) | Soft deep bronze drum plus shimmer / a gentle encouraging two-note lift | 1 / 2 |
| `sfx_unlock_reveal` | Unlock screen | Slow calm rising chime | 1 |
| `sfx_ui_pause_open` / `_close` / `sfx_ui_sound_on` / `sfx_ui_lang_toggle` | Pause, resume, sound turned on, VI/EN | Soft ticks; sound-on is a two-note "ding-dong" | 1 |

6. **One tone per press (QC O6; corrects the earlier mission-flow wording).**
   - **Menu buttons** (Tiếp, Skip, pause, the language chip, quiz cards, title buttons) give
     **exactly one** sound per press. Where the press has its own sound (quiz right or wrong,
     skip warning), that sound is the press's tone.
   - **Play pads** (move, attack, defend, flag) play **no tap tone**. Only their action sounds
     (swing, block…) play, as in the QC'd prototype ("the movement and fight pads play no tap
     tone").
   - Taps that do nothing are silent: inside `advance_debounce`, on a greyed card, during the
     shake.
7. **Audio starts before the first sound (QC O8).**
   - Audio is started and every SFX preloaded **before the first sound can play**. Native apps
     do this **at launch**, with no gesture needed. A platform that needs a user gesture
     (the browser prototype) does it at that gesture, before the gesture's own sound.
   - Input that would play a sound isn't accepted until the preload is done.
   - Audio resumes after backgrounding or a route change before the next sound.
8. **Anti-spam.**
   - The swing sound plays only when a swing starts, so at most one per 0.40 s (combat).
   - The hit sound plays once per swing.
   - Round-robin variants never repeat the last one.
   - A sound can have at most 2 instances at once, with a 50 ms minimum retrigger.
9. **Both-way backup.**
   - Every event that carries gameplay or learning information has a sound: telegraph, hit,
     block, pushed, flee, quiz right or wrong, stars, medal, meter marks, training steps, goals.
   - Every sound has a visual twin, so the game is fully playable with sound off.
   - Pairs (right/wrong, earned/empty) differ in **contour**, not only pitch.
   - Hints stay visual-only in the slice (Hints GDD).

**Mix**

10. **Buses** Master → {Music, SFX, UI, Voice}. Levels relative to Voice (0 dB): SFX −4 dB, UI
    −6 dB (wrong −12 dB), Music −10 dB in play, −14 dB on story, quiz and ending screens, and
    −8 dB in fights.
11. **Ducking:** music −9 dB and SFX −4 dB under voice (attack 80 ms, hold 250 ms, release 600 ms).
    One voice line at a time; a new line or "Tiếp" stops the current one with a 50 ms fade.
12. **Phone speakers:** high-pass the music at 120 Hz; drums carry their energy in 200 Hz–2 kHz;
    keep 1–4 kHz clear for the voice. The master target is **−16 LUFS**, true peak −1 dBTP, with
    a gentle limiter.
13. **Voice limit (low-end Android):** 12 total: music 2, hold layer 1, voice 1, SFX 6, UI 2.
    When full, the lowest priority drops first (Voice > UI > prio-1 SFX > prio-2 > prio-3).
    On Android, SFX, UI and the hold layer share one SoundPool (maxStreams 9, priorities mapped);
    music and VO use separate players.
14. **Sound setting:**
    - One toggle, on the HUD and in the pause menu, default **on**.
    - Muting fades the master in 0.2 s; un-muting resumes the music in place.
    - Saved as `sound` (Save GDD).
    - Separate volume sliders come after the slice.
15. **Formats** (content contract: m4a AAC or wav, never OGG):
    - Music is m4a AAC-LC, 44.1 kHz stereo, 128 kbps, streamed.
    - SFX and UI are **wav PCM 16-bit mono**, preloaded, so there's no decode delay on a tap.
    - VO is m4a AAC-LC mono, 64 kbps.
    - That's about 10 MB per hero with both languages (F2).
16. **Interruptions:** a phone call, an alarm, Siri or losing audio focus → pause. Unplugging
    headphones → pause. Backgrounding → stop and pause (Mission flow).

**Voice-over** (planned; optional until the vertical slice is signed off)

17. **What is voiced:** every story box (intro, beat card, caption, ending), the quiz prompt and
    the quiz `why`. Not voiced: buttons, HUD and quiz choices (choices are pictures with
    labels).
18. **Narrators:**
    - **One per language**, voicing every line: warm, "kind teacher or older relative", never
      baby talk or cartoonish, reverent in the ending, never scary in fights.
    - **VI accent:** one standard, kept for every hero (D-23).
    - **EN:** clear and neutral, about 10% slower than VI. **Vietnamese names are said in
      Vietnamese** (a pronunciation sheet per hero, signed off with the content).
19. **Pacing:** VI ≈ **11 characters per second** (cap 13), EN ≈ **10 cps** (cap 12), so a 6-year-old
    can follow while reading (F1).
20. **Recording:**
    - 48 kHz / 24-bit mono, dry, noise floor ≤ −60 dBFS, normalised to −16 LUFS ±1.5 LU.
    - 150 ms of silence before each line and 300 ms after.
    - Record **only after `content:approved`**, in one batch per hero. A wording change means
      re-recording both languages.
21. **Mapping (planned `vo {vi, en}` field on Text):**
    - The clip id is `vo.<lang>.<text_id>` (e.g. `vo.vi.tqt.b2.scene.1`). Each id resolves in
      `assets.json` to a file such as `vo/vi/tqt-b2-scene-1.m4a` (lowercase; dots become hyphens
      in the file name).
    - Validation (R10) checks that every `vo` id resolves.
    - **A missing clip is a warning**: the text shows and plays silently, never a crash.
22. **Playback:**
    - A line plays when its box appears, and stops on "Tiếp", Skip or pause.
    - After a language switch in pause, the current box's line plays in the new language
      (Mission flow Rule 12).
23. **Scratch TTS:** text-to-speech may be used only as a timing scratch track in development.
    It never ships (many Android phones have no Vietnamese voice).

### States and Transitions

Music follows the Mission flow states (table above):
- the crossfade starts on the state change;
- `paused` ducks the music and pauses SFX and voice;
- muting overrides everything.

A voice line is `idle` → `playing` (box shown) → `idle` (it ends, "Tiếp", Skip or pause).

### Interactions with Other Systems

| System | In | Out | Owner |
|---|---|---|---|
| Mission flow & beat types | state changes, box shown and advanced, Skip, pause, the meter value | (none) | Mission flow GDD |
| Side-scroll movement & combat | swing, hit, block, pushed, windup, strike, flee events | (none) | Combat GDD |
| Quiz & stars | wrong, right, why, star results | (none) | Quiz GDD |
| Hero progression & unlock | medal earned or missing, unlock | (none) | Progression GDD |
| Language & text | current `lang` (VO choice) | (none) | Language GDD |
| Save & progress | the saved `sound` | the new `sound` on a toggle | Save GDD |
| Content data & claims | `vo` ids (planned), `assets.json` sound entries | (none) | Content contract |

## Formulas

The F1 (voice-over length) formula is defined as:

`T_vo = chars / cps + 0.45`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| chars | int | 1–120 | content (NFC) | Characters in the line |
| cps | float | VI 11 (cap 13), EN 10 (cap 12) | constant (Rule 19) | Narration pace |
| 0.45 | float (s) | — | constant (150 ms head + 300 ms tail) | Silence around the line |

**Output Range:** 0.5–12.5 s. This replaces Mission flow F1's `T_box` estimate once voice-over
exists. Story boxes at or under **100 VI characters** stay under ~9.5 s (a recommendation to
content).
**Example:** a 90-character VI box: 90 / 11 + 0.45 ≈ 8.6 s. The same line in EN (75 characters):
75 / 10 + 0.45 ≈ 8.0 s.

The F2 (audio size per hero) formula is defined as:

`MB ≈ music_s × 128 kbps / 8 + Σ_lang lines × T_vo × 64 kbps / 8 + sfx`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| music_s | float (s) | ~350 | estimate (7 cues × ~50 s) | Music length |
| lines | int | ~40 | content | Voiced lines per language |
| sfx | float (MB) | ~0.9 | estimate (wav) | Effects |

**Output Range:** about 8–10 MB for the first hero. Music (~5.6 MB) and SFX (~0.9 MB) are shared, so each **further** hero adds about 3.2 MB of VO, plus up to 15 MB of art. **Against ADR-0002's 60 MB download cap that's about 3 heroes**, so revisit the cap (or on-demand packs) before hero 4.
**Example:** 5.6 MB music + 2 × 1.6 MB VO + 0.9 MB SFX ≈ 9.7 MB.

## Edge Cases

- **If the iOS silent switch is on**: behaviour depends on D-23 (ambient respects it; playback
  ignores it). Text always carries the content, so nothing is lost.
- **If a VO clip is missing**: the line shows silently, and a debug warning is logged (Rule 21).
- **If the language switches mid-line**: only possible through pause, so the line has already
  stopped; on resume the new language plays (Rule 22).
- **If the child mashes Tiếp**: each advance stops the current line with a 50 ms fade, and the
  debounce stops double advances, so voices never overlap.
- **If many SFX fire in one frame** (two enemies hit, a clang): the voice limit and priorities
  decide; prio-3 sounds drop first.
- **If sound is off**: no audio at all, including VO. The game stays fully playable from visuals
  and text (Rule 9).
- **If audio focus is lost** (a call): the game pauses (Rule 16), and audio resumes only when the
  child taps "Chơi tiếp".
- **If the device is very slow to start audio**: input waits for the preload (O8). The title
  screen shows normally while it loads.

## Dependencies

| System | Direction | Hard/Soft | Interface |
|---|---|---|---|
| Content data & claims | this depends on it | Hard | Sound assets, `vo` ids (planned) |
| Language & text | this depends on it | Hard (VO) | `lang` |
| Save & progress | this depends on it | Soft | `sound` |
| Mission flow, Combat, Quiz & stars, Hero progression | they send events to this | Soft (for them) | Events per the table in Rule 5 |
| Hints & onboarding | (post-slice voice prompts) | Soft | Prompt ids |

## Visual/Audio Requirements

This system is the audio requirement. Visual twins for each sound are in the source GDDs (Rule 9).
Music and SFX need an `/asset-spec` audio pass: descriptions only, no generation prompts.

## UI Requirements

- The sound toggle is on the HUD and in the pause menu (ASSET-030, `mission-hud-assets.md`).
- A one-time picture hint for the iOS silent switch, if D-23 = ambient (a `/ux-design` item).

## Cross-References

| This doc references | Where | What |
|---|---|---|
| Art bible | `design/art/art-bible.md` §2 | Moods per state |
| Mission flow | `design/gdd/mission-flow.md` Rules 11, 12, 15; F1 | States, pause, language, skip, T_box |
| Combat | `design/gdd/side-scroll-combat.md` Rules 2–12, frame order | SFX triggers |
| Quiz & stars | `design/gdd/quiz-and-stars.md` Rules 4–7 | Right, wrong, why, stars |
| Hero progression | `design/gdd/hero-progression.md` Rule 10 | Medal and unlock sounds |
| Save & progress | `design/gdd/save-and-progress.md` Rule 1 | `sound` |
| QC | `qa/TASK-003-android` r3 (O6, O8) | One tone per press, pads silent; audio before the first sound |
| Content | `content/README.md` (formats, planned `vo`) | m4a/wav, never OGG |

## Acceptance Criteria

Criteria 1–6 are logic (unit tests on the audio event layer); 7–10 are QC on devices.

1. **GIVEN** any menu button, **WHEN** pressed once, **THEN** exactly one sound plays. **GIVEN** a
   play pad, **WHEN** pressed, **THEN** no tap tone plays (only its action sound, if any).
2. **GIVEN** attack mashed for 2 s, **WHEN** counted, **THEN** at most 5 swing sounds play (one per
   0.40 s) and at most one hit sound per swing.
3. **GIVEN** a quiz wrong then right, **WHEN** measured, **THEN** the right sound's peak is ≥ 6 dB
   above the wrong sound's.
4. **GIVEN** a voice line playing, **WHEN** measured, **THEN** the music is 9 ± 1 dB lower than
   without voice.
5. **GIVEN** sound off, **WHEN** the mission is played through, **THEN** no audio plays, every
   event still has its visual feedback, and after a relaunch sound is still off.
6. **GIVEN** a `vo` id with no file (post-slice), **WHEN** its box shows, **THEN** the text shows,
   nothing crashes and a debug warning is logged.
7. **GIVEN** a fresh launch, **WHEN** the first tap on the title screen happens, **THEN** its sound
   plays in full, never cut or late (O8).
8. **GIVEN** the lowest target Android phone, **WHEN** the attack pad is pressed, **THEN** the swing
   sound starts within 150 ms (recording).
9. **GIVEN** a phone call during a fight, **WHEN** it ends, **THEN** the game is paused, silent until
   "Chơi tiếp", and the enemy telegraph restarts on resume.
10. **GIVEN** every cue and effect, **WHEN** reviewed by the content reviewer, **THEN** none contains
    a scream, a pain sound, a blade or flesh impact, or a frightening sting (Rule 2).

## Open Questions

| # | Question | Owner | By |
|---|---|---|---|
| D-23 | (a) iOS audio session: ambient (respects the silent switch and the family's mute; recommended) or playback (always plays). (b) VI narrator accent: Northern standard (textbook audio; recommended) or Southern; one for every hero | Luan | Before VO recording |
| — | The planned `vo {vi, en}` field (schema) and the `vo/` folder in `assets.json` | devs + game-art-content | When VO starts |
| — | Bar-synced music transitions (post-slice polish) instead of time crossfades | audio-director | After the slice |
| — | `/asset-spec` audio pass: music cues and SFX descriptions | game-art-content | After this GDD is approved |
