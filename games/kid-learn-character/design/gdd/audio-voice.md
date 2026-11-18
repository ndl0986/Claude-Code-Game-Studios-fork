# Audio & Voice

> **Status**: In Review
> **Author**: game-art-content for Luan (TASK-041)
> **Last Updated**: 2026-11-18 (volume aligned with the Settings Store, K-12)
> **Last Verified**: 2026-11-18
> **Implements Pillar**: Pillar 1 (Every Press Answers) and Pillar 3 (Calm Magic); serves Pillar 2 (The Letter Comes Alive)

## Summary

Audio & Voice plays every sound in the toy: the press chime, the soft ping, the twinkle as the letter turns to
stardust, the cast member's own sound, the spoken letter (or number) and word, the creature-tap sound and the
parade tune. It decides **when** each sound fires against the reveal timeline, how sounds share a small fixed set
of players, how speech never stacks, how loud everything is, and what happens when a file is missing or the device
interrupts audio. It reads its files from Key Table & Theme Data and its volume and mute from the Settings Store.
How the platform audio graph is built is the audio ADR's job (ADR-0001, open follow-up 3).

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `Key Table & Theme Data` (also reads Settings
> Store and the press events; read by Reveal Stage, Press Queue, Parade, Accessibility, Localization)

## Overview

A toddler presses C. A soft chime answers at once. A warm voice says "C." The letter glows, and as it breaks into
stardust a little run of bell notes twinkles. When the triceratops has formed it gives a gentle grumble, and a
moment later the voice says "triceratops" over it. If the child taps the triceratops it grumbles again. Mashing ten
keys never makes it louder: the first presses chime, the extra ones only ping softly, and the voice never talks
over itself.

This GDD owns:
- the **sound event table** (R1): every sound, what triggers it and at what time;
- the **players and buses** (R2): how many sounds can play at once, what cuts what, and that nothing clicks;
- the **mashing loudness ceiling** (R3), the audio twin of the art bible's brightness ceiling;
- **priming and loading** (R4), **volume and mute** (R5), **session and interruptions** (R6);
- the **toddler-safe audio rules** (R7) and the **loudness targets** (F4, decided by Luan, tuned in play).

It does **not** own: which files exist and their names (Key Table & Theme Data), when a reveal starts and how long
it holds (Press Queue), when the parade starts (Parade), the stored volume and mute values (Settings Store), or the
AVAudioEngine graph and the Android equivalent (the audio ADRs).

## Player Fantasy

**"Every press is answered by a soft voice that never shouts."** The child hears that they were heard, every time,
within a blink. The voice is calm and close, like a grown-up reading on the sofa, and it always finishes the word.
The dinosaurs sound friendly: a grumble, a honk, a chirp, never a scream. The parent in the next room hears a toy
that stays quiet while the child mashes, rather than one that gets louder the harder it is hit.

## Detailed Design

### Core Rules

**R1. The sound event table.** Times are seconds since the reveal started (`s`, the clock MorphCore uses), except
press-time events, which fire when Input delivers the event. `glow` and `T` are the **active** timing set's values
(MorphCore F1, F3): normal glow 0.8 s, T 2.45 s; reduced glow 0.4 s, T 1.2 s (Reduce Motion).

| # | Event | Trigger (owner) | When | Bus / player | Notes |
|---|---|---|---|---|---|
| E1 | **Press chime** | a press the Press Queue accepts: it starts a reveal or is queued | at the press | ui pool | Mash factor F3 applies. |
| E2 | **Ping** | a press the Press Queue **ignores** because the queue is full (decided, Luan Q2) | at the press | ui pool | Softer and shorter than the chime (F4). Mash factor F3 applies. |
| E3 | **Ping** | `sparkle(point)` from Input: a tap on the empty stage (K-10) | at the tap | ui pool | Same sound as E2. |
| E4 | **Silence** | a swallowed or ignored key (Input R4/R5, K-10), a creature tap inside the cooldown | — | — | Nothing plays. A tap inside the cooldown still sparkles (Reveal Stage). |
| E5 | **Title chime** | `startPlay` from a key or the play button on the title screen (K-10) | at the press | ui pool | The chime only; **no letter voice**, because the title key is not a press. |
| E6 | **Letter / number voice** | reveal start (Reveal Stage) | `s = 0` | voice | `vo_<locale>_letter_<id>` or `vo_<locale>_number_<id>`. Always cuts any line still playing (R2.3). |
| E7 | **Twinkle** | the glyph starts to dissolve | `s = glow` | ui pool | One per reveal; not mash-scaled. |
| E8 | **Cast sound** | the reveal is formed | `s = T` | cast | The item's `sfx` (≤ 2 s). Skipped if `sfx` is null or missing. |
| E9 | **Word voice** | the reveal is formed | `s = T + word_offset_s` (0.25 s, decided, Luan Q1) | voice | `vo_<locale>_word_<id>`. The cast sound is ducked under it (F2). **A waiting key does not cut it** (F6). |
| E10 | **Creature-tap sound** | `creatureTap` on the formed cast member, outside the cooldown (Reveal Stage) | at the tap | cast | The same `sfx` again; cuts the cast player's current sound (R2.4). During the word it is ducked like E8 (F2): the word stays on top. |
| E11 | **Number sound** | a digit reveal is formed | `s = T` | cast | The digit item's `sfx`: **one chirp per baby, counting along up to 9** (decided, Luan Q6); 0 (the empty nest) is one soft chirp. The file stays ≤ 2 s (A3), so chirps are ≤ 0.22 s apart for 9. It runs on the cast player, so the next reveal cuts it (R2.4). |
| E12 | **Parade tune** | the parade starts (Parade GDD owns the trigger) | at parade start | music | Ducked under any voice line (F2). Stops with a fade when the parade ends or the panel opens. |

For a digit, E6 says the number ("three") and E9 says the counted words ("three baby dinosaurs"), following the
theme (K-09). A creature tap never replays the word; only its sound (as played in the one-shot).

**Worked timeline** (normal set, C = triceratops, word line 0.9 s):

| s | Sound |
|---|---|
| press | chime (E1) |
| 0 | "C." (E6), about 0.5 s |
| 0.8 | twinkle (E7) |
| 2.45 | grumble (E8), 0.9 s |
| 2.70 | "triceratops" (E9), grumble ducked; ends at 3.60 |

**R2. Players, buses and cuts.**
1. **Fixed players, created once.** The engine and every player are created **and started at launch**, silent, and
   **keep running**.
   Nothing is created, stopped or torn down on a press. A sound is started by scheduling a primed buffer that
   interrupts whatever that player was playing (on Apple, `scheduleBuffer(_:at:options: .interrupts)`); the
   mechanism is the audio ADR's.

   | Bus | Players | Plays |
   |---|---|---|
   | voice | 1 | E6, E9 |
   | cast | 1 | E8, E10, E11 |
   | ui | pool of 4 | E1–E3, E5, E7 |
   | music | 1 | E12 |

   **At most 7 sounds play at once**, whatever the input.
2. **No click on a cut.** Any sound that is cut, by another sound, mute, the panel or a theme switch, ends without
   an audible click or pop. The requirement is the result (AC-9); how (a short fade, a ramp, a zero-crossing) is the
   audio ADR's. The proposed fade is `cut_fade_s` (Tuning Knobs).
3. **Speech never stacks.** The voice bus has one player, so two lines can never overlap. E6 always replaces any
   line still playing. Under the hold rule (F6) and the word-length build check (AC-6) that never happens in
   normal play; the cut is a safety net, and it is never because a key was waiting.
4. **One cast sound at a time.** E8, E10 and E11 replace each other on the cast player. A new reveal's E6 also cuts
   the cast player, so a long grumble or a chirp run never spills into the next letter.
5. **The ui pool steals the oldest.** If all 4 ui players are busy, the one that started earliest is cut (R2.2) and
   reused.

**R3. The mashing loudness ceiling.** More presses never mean more sound (art bible §2: "extra presses add sparks,
never more brightness"; Pillar 3).
- A press the queue ignores gets the softer ping, not the chime (E2, decided).
- Chimes and pings that come close together get quieter, down to a floor (F3).
- The ui pool caps how many can sound at once (R2.5), and a peak limiter on the main mix (R4.5) caps the sum.

**R4. Priming, loading and format.**
1. **Decoding is part of the theme load.** Key Table & Theme Data loads a theme whole, off the main thread (its
   Core Rules). Decoding that theme's `.m4a` files (sfx and every voice line for the active locale) to PCM is part
   of that same load. **A theme becomes Active only when its audio is decoded too.** Nothing is ever decoded on a
   press. The fixed sounds (chime, ping, twinkle, parade tune) are decoded once at start-up.
2. **Decode at the engine's output format.** Buffers are decoded (or converted once) to the output's sample rate,
   mono, so playback needs no conversion at press time.
3. **Off the main thread.** Scheduling a sound happens off the main thread; the main thread only posts the event.
   The spike measured 3–10 ms for stop + schedule + play **on the main thread, Mac and Simulator only** (ADR-0001);
   this rule removes that cost from the frame.
4. **Re-prime on a format change.** If the output's sample rate or channel layout changes (a route change, a
   configuration change), the buffers are converted again to the new format, off the main thread. Until that is
   done, sounds are skipped (the visuals still answer; debug builds log it).
5. **A peak limiter on the main mix.** Everything passes a peak limiter at `limiter_ceiling_dbtp` before the
   output. F1 sets bus trims so the limiter acts only in the worst case.

**R5. Volume and mute (Settings Store).**
- The Settings Store holds **`volume`**, an integer 0–10 (default 8, K-12), and **`muted`** (default off), changed
  only in the grown-up panel. It hands Audio one linear **`gain = muted ? 0 : volume / 10`** (Settings Store F2).
  Audio & Voice applies it; it stores nothing.
- **Slider preview:** while the grown-up drags the volume slider, the panel sends a preview gain (the same F2 from
  the slider's position) straight to Audio, which applies it at once, ramped over `cut_fade_s` so the drag never
  clicks. On release the store writes the level and Audio gets the final gain.
- The gain is applied through F1 to the main mix. **Mute** ramps the main mix to silence and cuts the voice and cast
  players (R2.2). Unmuting affects the next event; nothing resumes mid-line.
- **With sound off, everything still reads visually** (art bible §7): every event in R1 also has a visual answer,
  owned by Reveal Stage.

**R6. Session, interruptions and configuration changes.** (Apple names; the Android ADR maps them.)
- **Silent mode is respected** (decided, Luan Q4): when the iPad is in silent mode (the side switch on older
  iPads, Control Center on current ones), the toy is silent, and **no other app's audio is mixed in**. On Apple
  that requirement is the `.soloAmbient` session category (`.ambient` would mix); the audio ADR confirms it by
  build and run. macOS has no silent mode. **Consequence:** in silent mode the child hears nothing, so every event
  must still read visually (R5, art bible §7). iOS has **no public API to read silent mode**, so the app cannot
  detect it: the grown-up panel shows a **static hint** instead ("No sound? Check silent mode and the volume";
  wording and layout are the Parent Gate & Grown-up Panel GDD's). Android audio focus and usage stay with its ADR.
- **Interruption** (a call, Siri, an alarm): the engine stops. When it ends with "should resume", the engine is
  restarted and the buffers re-primed at once. Without that flag, it is restarted on the **next press**; that
  press's chime may come late by the engine's start time (NOT ASSESSED) or be skipped. The visual answer is never
  delayed.
- **Route or configuration change** (headphones in or out, a Bluetooth speaker, a sample-rate change): restart the
  engine if it stopped and re-prime (R4.4). Headphones removed: the cast and voice players are cut (R2.2); nothing
  jumps to the speaker mid-line.
- **Media services reset:** rebuild the whole engine graph and re-prime every buffer.
- **Background / the panel:** going to the background cuts every player and pauses the engine; coming back
  follows the interruption rule. Opening the grown-up panel cuts the voice, cast and music players; the panel is
  quiet.
- **No sound before the first input** at launch: the engine is already running (R2.1), but **nothing is
  scheduled** until a key or a tap, so the title screen is silent and the first chime pays no engine-start time.

**R7. Toddler-safe audio rules.** Content review checks A1–A6 by ear; A7–A8 are build checks.

| # | Rule |
|---|---|
| A1 | **No sudden loud.** No sound starts at full level: an attack of at least 10 ms, and nothing is louder than the voice (F4). |
| A2 | **No scary sounds.** Roars stay low, soft and short: a grumble, not a scream. No growl peaks, no shrieks, no human screams, no thunder (art bible §2: no lightning). |
| A3 | **Short.** Cast sounds ≤ 2.0 s (art bible §8, Key Table V12). Word lines ≤ `word_len_max_s` (F6). Letter and number lines ≤ `letter_len_max_s` (1.0 s). |
| A4 | **No reward for mashing.** Extra presses get quieter, never louder (R3). |
| A5 | **No music bed under play.** The only music is the parade tune (E12). |
| A6 | **Calm voice.** The voice says the letter name, then the word (K-05, Key Table T6), at a steady, warm pace; never "letter C", never a shout. |
| A7 | **Loudness matched.** Every file is within ±1 LU of its class target and at or below the true-peak ceiling (F4). |
| A8 | **Every voice line exists for every locale** in `voiceLocales` (Key Table V7), and every line passes A3. |

**R8. Voice source (decided, Luan 2026-11-18, Q3).** The MVP voice is **text-to-speech rendered at build time**
into the same `.m4a` pipeline: the same file names and line ids (`vo_<locale>_<kind>_<id>.m4a`), loudness-matched
like any other file. The app never synthesises speech at run time and never uses the network (the app is offline, ADR-0001). The script is
the Key Table's `say` and `word` fields ("A." for A, because a TTS voice read "ay" as "eye" in the one-shot).
Swapping in a recorded voice later replaces files only. Open: whether to re-record with a human voice for release,
and that the TTS licence allows a commercial kids' app (Open Questions).

### States and Transitions

| State | Entered when | Sounds | Left when |
|---|---|---|---|
| **Running, nothing scheduled yet** | launch: the engine is started and primed (R2.1, R4.1) | none (R6: no sound before input) | the first key or tap schedules its sound → Running |
| **Running** | the first input | every R1 event | interruption, background, media reset |
| **Interrupted** | an interruption began, or background | none; events are skipped | "should resume" → Running (re-prime); otherwise the next press restarts it |
| **Re-priming** | a format change or a media reset | none; events are skipped and logged | buffers ready → Running |
| **Muted** | mute on (Settings Store) | none; the engine keeps running | mute off → Running |

Theme loading is the Key Table's state: until the new theme is Active (R4.1), the old theme's buffers keep
playing.

### Interactions with Other Systems

| System | Direction | What passes |
|---|---|---|
| Key Table & Theme Data | in | the item's `sfx` path; voice paths built from `voiceLocales` + line ids; decoding is part of its off-main-thread theme load (R4.1) |
| Input & Key Filter | in (via Press Queue / Reveal Stage) | the press event (R8 there), `sparkle`, `creatureTap`, `startPlay`; their `time` stamps |
| Press Queue | in | accepted (E1) or ignored (E2) for each press. **Out: the hold constraint F6** |
| Reveal Stage | in | reveal start (`s = 0`), the active `glow` and `T`, formed, creature tap outside the cooldown |
| MorphCore | in (via Reveal Stage) | `glow` and `T` of the active timing set |
| Parade | in | parade start and end (E12) |
| Settings Store | in | `volume` (0–10) and `muted` as one gain (its F2), and the slider preview gain (R5); later the voice locale |
| Accessibility | in | the reduced-motion flag changes `glow` and `T`, so the voice timings follow (R1) |
| Parent Gate & Grown-up Panel | in | panel open → cut players (R6) |
| Localization | out | a new locale is files only; the same checks (A7, A8) per locale |

## Formulas

**F1. Gain chain.** The level of a sound at the output, before the limiter:
```
g = g_master(v) × g_head × g_bus × g_event × m × d
g_master(v) = v²     (v = the Settings Store's gain, volume / 10, 0 when muted; v² follows loudness better than v)
```
| Variable | Meaning | Value / range |
|---|---|---|
| `v` | the gain from the Settings Store (its F2) | 0–1 in steps of 0.1; default level 8 → v 0.8 → g_master 0.64 (−3.9 dB) |
| `g_head` | fixed headroom trim | −3 dB (0.708) |
| `g_bus` | bus trim (Tuning Knobs) | voice 0 dB, cast −4 dB, ui −10 dB, music −8 dB (provisional) |
| `g_event` | per-event trim | ping −6 dB vs chime; 1 otherwise |
| `m` | mash factor (F3) | 0.35–1, ui bus only |
| `d` | duck factor (F2) | 0.355 or 1 |

**Headroom (everything at once).** Files peak at most at −1 dBTP (0.89). The worst case is all 7 players peaking
together: voice 0.89 + cast (ducked) 0.89 × 0.63 × 0.355 = 0.20 + ui 0.89 × 0.32 × 2.57 (F3's loudest four) = 0.72
+ music (ducked) 0.89 × 0.40 × 0.355 = 0.13, a sum of **1.94** (+5.8 dB); with `g_head` it is 1.37. At the default
level 8 (g_master 0.64) the aligned sum is **0.88**, below full scale, so the limiter never acts at the default
volume or below. At levels 9–10 (g_master 0.81–1.0) the aligned worst case reaches 1.11–1.37 and the limiter (R4.5)
holds the ceiling. Peaks rarely align, so this is a bound, not a typical level.

**F2. Ducking.** While a voice line plays, the cast and music buses duck:
```
d_cast = d_music = 10^(duck_db / 20)     duck_db = −9 dB → 0.355
attack = duck_attack_s (0.05 s), release = duck_release_s (0.25 s), both linear in dB
```
The ui bus is not ducked (a chime during a word stays audible, it is already quiet). Example: the grumble starts
at T at its trim; at T + 0.25 the word starts and the grumble falls 9 dB over 50 ms; when the word ends it comes
back over 250 ms (if still playing).

**F3. Mash factor (ui bus).**
```
m = max(mash_floor, 1 / (1 + mash_k × n))
n = the number of E1/E2/E3 sounds started in the last mash_window_s before this one
```
| | n | m | level |
|---|---|---|---|
| single press | 0 | 1.0 | 0 dB |
| 2 presses in a second | 1 | 0.67 | −3.5 dB |
| 4 presses in a second | 3 | 0.40 | −8 dB |
| 10 presses/s | 9 | max(0.35, 0.18) = **0.35** | −9 dB (floor) |

With `mash_k` 0.5, `mash_floor` 0.35, `mash_window_s` 1.0. Each extra press is quieter than the first. The ui bus
sum is bounded too: at most 4 ui sounds play (R2.5), and the loudest four in a row are a fresh press and the next
three (m = 1 + 0.67 + 0.5 + 0.4 = **2.57** × one chime, +8.2 dB if their peaks align). In a steady mash at
10 presses/s every m sits at the floor, so the sum is 4 × 0.35 = 1.4 (+2.9 dB).

**F4. Loudness targets (decided, Luan Q5; tuned in play).** Measured per file as integrated loudness (ITU-R BS.1770,
LUFS) and true peak (dBTP). Each file is normalised to its class target at build time, ±1 LU (A7).

| Class | Target | Why |
|---|---|---|
| voice (letter, number, word) | −16 LUFS | the loudest, clearest thing: the learning content |
| cast sounds | −20 LUFS | under the voice; they are ducked anyway |
| parade tune | −22 LUFS | a short celebration, not a bed |
| chime, twinkle | −26 LUFS | "I heard you", not a sting |
| ping | −30 LUFS | the quietest answer |
| every file | ≤ −1 dBTP | A1; the limiter ceiling matches |

Short sounds (< 0.4 s) measure loudness unreliably; for those the build check uses the momentary maximum (400 ms
window) against the same target.

**F5. Decoded memory per theme.**
```
bytes = Σ (file duration in s) × output_rate × 4 (32-bit float) × 1 (mono)
```
Dinosaurs, estimated: 36 cast sounds × ~1.2 s = 43 s; 36 letter/number lines × ~0.6 s = 22 s; 36 word lines ×
~1.0 s = 36 s; total ~101 s. At 48 kHz: 101 × 48 000 × 4 ≈ **19.4 MB** per theme and locale, plus ~1 MB for the
fixed sounds. Only the Active theme is decoded. The real iPad memory budget is not set (ADR-0001: budgeted when
sizes are known); this is an input to it.

**F6. The word and the hold (a constraint on the Press Queue GDD; decided, Luan Q1).** Audio & Voice does not
hold anything. It states the time the word ends, and the Press Queue must not start the next reveal before it:
```
word_end   = T_active + word_offset_s + word_len
hold_eff  ≥ min( max(hold, word_end), hold + hold_ext_max_s )
```
- `T_active` is the active timing set's T (normal 2.45 s; reduced 1.2 s).
- `word_len` comes **from data, never from playback**: the build records each word line's duration, and a build
  check enforces `word_len ≤ word_len_max_s = hold_ext_max_s − word_offset_s = 1.5 − 0.25 = 1.25 s` (AC-6). Until
  the Key Table carries a per-line duration (follow-up for that GDD), the Press Queue may use the bound
  `T_active + 1.5 s` for every word.
- With the bound, `word_end ≤ T + 1.5`, which is always within `hold + 1.5`, so the cap never has to cut a word.

| Case | word_end | hold 3.0 → effective | extra |
|---|---|---|---|
| "nest" 0.5 s, normal | 2.45 + 0.25 + 0.5 = 3.20 | 3.20 | +0.20 s |
| "triceratops" 0.9 s, normal | 3.60 | 3.60 | +0.60 s |
| "quetzalcoatlus" 1.15 s, normal | 3.85 | 3.85 | **+0.85 s** |
| any word ≤ 1.25 s, reduced (T 1.2) | ≤ 2.70 | 3.00 | 0 |

**Cost:** with long words, each queued reveal waits up to about +0.9 s, so with 3 keys queued the last one starts
about **2.7 s** later than with a plain 3.0 s hold. Luan accepted this for a word that is always heard whole.

## Edge Cases

| Case | What happens |
|---|---|
| **sfx missing or failed to decode** | E8/E10/E11 skipped; the rest plays (Key Table fallback). Debug log. |
| **Word voice missing** | E9 skipped; the letter line only. The Press Queue uses the plain hold for that reveal. |
| **Letter voice missing too** | The chime only (E1). |
| **Fixed sound missing** (chime, ping, twinkle, parade) | A build check makes this impossible; at run time it is skipped and logged. Never a crash. |
| **A locale in `voiceLocales` has no files** | The build fails (A8, Key Table V7). |
| **10 keys at once, nothing on stage** | 4 accepted presses chime (E1: one starts a reveal, 3 are queued), 6 ping (E2), all mash-scaled (F3); at most 4 ui sounds at once. One letter line plays. |
| **Mash at 10 presses/s for 60 s** | The ui level stays at the floor (F3); voice and cast play once per reveal; ≤ 7 players. |
| **A creature tap inside the cooldown** | No sound, a sparkle only (E4). |
| **A creature tap during the word** | The tap sound plays, ducked (F2); the word continues on top. |
| **A creature tap after the next reveal started** | Not possible: the old cast member is gone (Reveal Stage). |
| **The next reveal starts while a number's chirps play** | E6 cuts the cast player (R2.4). |
| **Mute toggled during a line** | The line is cut without a click; unmute plays from the next event. |
| **Volume at 0 vs mute** | Both are silent; the engine runs in both. They are separate settings (Settings Store). |
| **The panel opens during a reveal** | Voice, cast and music cut (R6). Closing the panel replays nothing. |
| **Theme switch** | Takes effect on the next reveal (Key Table). The old buffers play until the new theme is Active (R4.1). |
| **Reduce Motion changes during a reveal** | The running reveal keeps its timings (MorphCore); the next one uses the new T for E7–E9. |
| **Parade starts while a word plays** | Not possible: the parade waits for an empty queue and a formed creature (Parade GDD). If a press comes during the parade, the parade tune is ducked under its voice lines. |
| **Headphones pulled out mid-word** | The voice and cast are cut (R6); nothing jumps to the speaker mid-line. |
| **Bluetooth output** | Adds output latency (often 100–200 ms). **NOT ASSESSED**; the press still answers visually at once. |
| **Interruption ends without "should resume"** | The next press restarts the engine; its chime may be late or skipped (R6). |
| **Two presses in the same frame** | Both are handled in delivery order (Input R8); each gets E1 or E2. |

## Dependencies

**Upstream (Audio & Voice reads):**
- **Key Table & Theme Data:** `sfx` paths, `voiceLocales`, voice line ids, the off-main-thread theme load that
  includes decoding (R4.1). Follow-up for that GDD: a per-line voice duration (F6).
- **Settings Store:** `volume` 0–10 (default 8) and `muted`, handed over as one gain (its F2), plus the slider preview
  (R5); later the voice locale.
- **Input & Key Filter (TASK-037):** the press event and `sparkle`, `creatureTap`, `startPlay`, through the Press
  Queue and Reveal Stage.
- **MorphCore:** `glow` and `T` of the active set, through Reveal Stage.

**Downstream (depend on Audio & Voice):**
- **Press Queue:** must honour F6 (hold ≥ word end, capped +1.5 s) and report accepted / ignored per press.
- **Reveal Stage:** reports reveal start, formed and creature taps; owns the visual answer to every sound.
- **Parade:** owns the parade trigger; E12 plays its tune.
- **Accessibility:** relies on R1 following the active timing set, and on every sound having a visual answer.
- **Localization:** a new locale adds files only and passes A7, A8.
- **Parent Gate & Grown-up Panel:** shows the volume and mute controls (stored by the Settings Store).

**Normative references:** ADR-0001 (audio note, open follow-up 3: the audio ADR); art bible §2 (brightness
ceiling, calm), §7 UX view (every press answered; works with sound off), §8 (mono AAC `.m4a`, PCM at load,
loudness-matched, sfx ≤ 2 s).

## Tuning Knobs

All values are bundled data (ADR-0001 Decision 6). "One-shot" means Luan played that value.

| Knob | Value | Safe range | Source | Effect |
|---|---|---|---|---|
| `volume` default | level 8 (gain 0.8) | 0–10 | Settings Store (K-12; owned there) | starting volume; the grown-up changes it |
| `g_head` | −3 dB | −6 – 0 dB | F1 | headroom so the limiter is idle at the default level |
| `word_offset_s` | 0.25 | 0–0.6 | decided (Luan Q1) | gap between the cast sound and the word; larger = longer hold (F6) |
| `word_len_max_s` | 1.25 | 0.8–1.25 | F6 | longest word line allowed; above 1.25 the cap would cut words |
| `letter_len_max_s` | 1.0 | 0.6–1.0 | proposed | longest letter or number line ("double you" is the longest); fixed, so it does not move with MorphCore's provisional reduced set. At 1.0 it ends before the reduced T (1.2 s) and well before the normal T (2.45 s) |
| `hold_ext_max_s` | 1.5 | 0–1.5 | decided (Luan Q1) | longest hold extension for a word (Press Queue constraint) |
| `tap_cooldown_s` | 0.9 | 0.2–3 | one-shot | taps closer than this only sparkle (owned by Reveal Stage; listed for the sound) |
| `duck_db` | −9 | −15 – −3 | proposed | how far the cast sound and music drop under the voice |
| `duck_attack_s` / `duck_release_s` | 0.05 / 0.25 | 0.01–0.2 / 0.1–0.6 | proposed | how fast the duck comes and goes |
| `mash_k` | 0.5 | 0.2–1.5 | proposed | how fast close presses get quieter (F3) |
| `mash_floor` | 0.35 | 0.2–0.7 | proposed | the quietest a mashed chime gets |
| `mash_window_s` | 1.0 | 0.5–2 | proposed | how far back presses count for F3 |
| `cut_fade_s` | 0.03 | 0.01–0.08 | proposed | fade on any cut; long enough for no click (AC-9) |
| bus trims | voice 0, cast −4, ui −10, music −8 dB | ±6 dB each | proposed; one-shot ratios `roar_volume` 0.35, `chime_volume` 0.12 | balance between classes; F1 headroom |
| `limiter_ceiling_dbtp` | −1 | −3 – −0.5 | decided (Luan Q5) | the output ceiling |
| loudness targets | F4 | ±4 LU | decided (Luan Q5), tuned in play | per-class loudness |

The one-shot's `voice_rate` (0.85) and `voice_pitch` (1.15) are inputs to the TTS **render** at build time (R8),
not run-time knobs.

**Interactions:** raising `word_offset_s` or `word_len_max_s` lengthens every hold with waiting keys (F6).
Lowering `duck_db` (deeper) makes the word clearer but can make the cast sound vanish under long words.

## Visual/Audio Requirements

Every sound has a visual twin, drawn by Reveal Stage: E1 the starlight at the press point (art bible §4 "I heard
you"); E2/E3 a sparkle; E7 the dissolve; E8/E9 the formed creature; E10 the hop; E12 the parade. With the sound off
or muted, the toy reads the same.

Sound design brief for the real files (sourcing is not in this GDD): soft bell chime (the one-shot used 1568 + 2093
Hz sines); a higher, shorter ping; a rising five-note twinkle; per-family creature sounds as in the Key Table's SFX
column (grumble, honk, chirp, screech kept gentle, thump, crack), all within A1–A3; number sounds with one chirp
per item (1–9; the prototype capped them at 5); a light 12-note parade tune.

## UI Requirements

None of its own. The grown-up panel shows the volume slider and the mute switch; the Settings Store stores them and
the Parent Gate & Grown-up Panel GDD lays them out.

## Cross-References

- `design/gdd/systems-index.md`: system #6; dependents Reveal Stage (#9) and Localization (#19).
- `design/gdd/key-table-theme-data.md`: item `sfx` and `voice`, voice paths, V7, V12, T5–T7, per-asset fallbacks.
- `design/gdd/morphcore.md`: F1, F3, F6 (`glow`, `T`, phases), the reduced set.
- `design/gdd/input-key-filter.md` (TASK-037): R8 press event, `sparkle`, `creatureTap`, `startPlay`.
- `production/team/decisions.md`: K-02, K-05, K-09, K-10, K-11.
- `design/art/art-bible.md`: §2, §4 (feedback table), §7 UX view, §8.
- `docs/architecture/adr-0001-native-apple.md`: audio note, open follow-ups 2 and 3.
- The one-shot `prototypes/letter-morph-dinosaur/` (`chime`, `ping`, `twinkleSound`, `paradeTune`, `say`, tuning).

## Acceptance Criteria

Logic criteria run with an injected clock and a fake player layer (no audio hardware). Device criteria are marked.

1. **AC-1 Event times.** For a reveal of C with the normal set, the scheduled events are: E6 at s = 0, E7 at
   s = 0.8, E8 at s = 2.45, E9 at s = 2.70 (each ±1 ms in the logic test). With the reduced set: 0, 0.4, 1.2, 1.45.
2. **AC-2 Press sounds.** GIVEN an empty queue, a press schedules E1. GIVEN a full queue, a press schedules E2 (the
   ping) and no chime. A swallowed key and a tap inside the cooldown schedule nothing. A `sparkle` schedules E3.
3. **AC-3 Title.** `startPlay` schedules E5 and **no** voice line.
4. **AC-4 Speech never stacks.** In any sequence of events, at most one voice line plays at any moment; E6 always
   stops any line still playing, without a click (AC-9).
5. **AC-5 Player cap.** Under 10 presses/s for 60 s (logic test), never more than 7 sounds play at once, never more
   than 4 on the ui bus, and the oldest ui sound is the one reused.
6. **AC-6 Line length (build).** The build fails if any word line is longer than `word_len_max_s` (1.25 s) or any
   letter/number line is longer than `letter_len_max_s` (1.0 s), for every locale.
7. **AC-7 Hold constraint.** With the Press Queue in the loop (integration test), a key queued during the word of
   "quetzalcoatlus" (1.15 s) starts its reveal no earlier than s = 3.85 and no later than s = 4.5; the word is
   never cut.
8. **AC-8 Mash ceiling.** F3 gives m = 1.0, 0.67, 0.40 and 0.35 for n = 0, 1, 3, 9; the ui bus gain is never above
   the single-chime gain for each ui sound with n > 0, and the sum of the 4 ui players' m never exceeds 2.57.
9. **AC-9 No click on a cut (device).** Cutting a playing voice line, cast sound and parade tune (by a new reveal,
   mute, the panel and headphones out) shows no discontinuity above −60 dBFS in an output capture; listened on the
   built-in speaker, no click is heard.
10. **AC-10 Nothing stops on a press.** Instrumented build: across a 60 s mash, no engine or player is created,
    stopped or reconnected on a press; only buffers are scheduled. No decoding happens after the theme is Active.
11. **AC-11 Theme load.** A theme is not reported Active until all its sfx and active-locale voice lines are
    decoded at the output format; decoding never runs on the main thread (thread assertion in debug).
12. **AC-12 Loudness (build).** Every shipped file is within ±1 LU of its class target (F4) and ≤ −1 dBTP; the build
    fails otherwise.
13. **AC-13 Limiter and headroom.** With all 7 players driven by test tones peaking at −1 dBTP at v = 1, the output never
    exceeds `limiter_ceiling_dbtp`; at the default level 8 (v = 0.8) the limiter applies no gain reduction.
14. **AC-14 Mute and volume.** Mute silences the output within `cut_fade_s` and cuts the voice and cast players;
    unmute plays nothing until the next event. At level 8 the main gain is 0.64 × 0.708 = 0.45 (F1). During a slider
    drag the output follows the preview gain within `cut_fade_s`, without a click.
15. **AC-15 Interruptions (device).** After a simulated interruption that ends with "should resume", the next press
    chimes; after a route change and a media-services reset, the buffers are re-primed and the next press after
    re-priming chimes. During re-priming, events are skipped and logged, never crashing.
16. **AC-16 Latency (device, NOT ASSESSED).** On the child's iPad with built-in or wired output, measured with the
    TASK-033 240 fps procedure (`procedure-ipad.md`): the chime's onset is no more than **one display frame** after
    the first frame that answers the press. The TASK-033 Mac/Simulator figures are estimates only. Bluetooth is
    NOT ASSESSED and is not held to this criterion.
17. **AC-17 Fallbacks.** With a test theme missing an sfx, a word line, and both voice lines for one key, the
    reveals play as in Edge Cases (skip, letter only, chime only), each with one debug log line and no crash.
18. **AC-18 Sound off.** With mute on, a full reveal, an overflow press, a tap and the parade still show their
    visual answers (screenshot evidence, Reveal Stage).
19. **AC-19 Number chirps (content + build).** Each digit item's sfx for 1–9 has exactly that many chirps (checked by
    ear in the content review) and is ≤ 2.0 s; the 0 item has one soft chirp.
20. **AC-20 Silent mode (iPad only).** With the iPad in silent mode, no sound is heard for any event, a full reveal
    still shows every visual answer, and music playing in another app is stopped, not mixed (`.soloAmbient`
    behaviour). macOS has no silent mode and is not tested here.

## Open Questions

- **Q7. Human voice for release.** The MVP uses build-time TTS (R8). Whether to re-record with a human voice
  (adult actor, licence buy-out) before release stays open.
- **Q8. TTS licence (open item).** The chosen TTS voice's licence must allow its rendered audio in a commercial
  app for children. To be checked before the voice files are rendered for release.
- **Q9. Memory budget.** F5's ~20 MB per theme needs the real iPad memory budget (ADR-0001).

**Resolved (Luan, 2026-11-18), now in the rules:** Q1 the word plays 0.25 s after the cast sound, ducked over it,
and a waiting key does not cut it (E9, F6); Q2 an overflow press gets the softer ping (E2); Q3 the MVP voice is
TTS pre-rendered at build time (R8); Q4 silent mode is respected (R6); Q5 the loudness targets as
proposed, tuned in play (F4); Q6 one chirp per baby, counting along up to 9 (E11).
**Panel follow-up:** silent mode is not detectable on iOS, so the panel shows a static hint (Parent Gate & Grown-up
Panel GDD).
