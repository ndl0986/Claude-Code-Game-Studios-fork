# Key Table & Theme Data

> **Status**: Approved (independent review by game-dev-ios, merged 2026-11-18)
> **Author**: game-art-content (TASK-036), with Luan's answers via game-leader; plan reviewed by game-dev-ios
> **Last Updated**: 2026-11-18 (TASK-050 cross-GDD follow-ups)
> **Last Verified**: 2026-11-18
> **Implements Pillar**: Pillar 1 (Every Press Answers), Pillar 4 (Things the Child Loves), Pillar 5 (Safe by Design)

## Summary

The key table is the game's content. For each theme it maps every key A–Z and 0–9 to a cast member:
its silhouette for the stardust morph, its art, its sound and its spoken lines. It is bundled JSON,
checked at build time and loaded whole before use. It holds no game state.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None` (consumed by Audio & Voice, Cast Rendering, Reveal Stage, Hint Letters, Theme Packs, Localization; MorphCore reads its paths)

## Overview

A **theme** (Dinosaurs first) covers **every key** (K-07). Each letter A–Z becomes a cast member
whose name contains the letter, and the child can **hear** the letter's usual sound in the spoken
word (Luan, Q3). Each digit 1–9 becomes that many of the theme's counted item, and 0 becomes the
theme's "empty" item (Luan, Q4). The theme is data, not code (ADR-0001 Decision 6). The demo and
MVP fix **one item per key**. Production holds **4–5 items per key** and picks one per reveal (Luan, Q1).
Luan's content decisions for this GDD (Q1–Q6, 2026-11-18) are listed under **Decisions** below.

This system owns:
1. the data model (theme, key entry, item, glyph set);
2. the rule that picks an item for a key;
3. the validation rules, which are the build gate;
4. the toddler-safe content rules;
5. the first content set, the Dinosaurs table.

It does **not** own:
- morph timings, the morph seed or the "reduced" timing set (Reveal Stage / MorphCore data, ADR-0001 Decision 6);
- how art is drawn (Cast Rendering ADR);
- how sound is played (Audio & Voice);
- what a press is (Input & Key Filter).

## Player Fantasy

*Advisory at `standard`.* "Every key I press is someone I know." The child doesn't see a table. They
meet a world where the C key is always a friendly three-horned creature that grumbles, and the 3 key
is always three little babies. In production, C might also bring a different horned friend, which
gives a small surprise. Because of this table, every one of the 36 keys answers with a creature from
the same world, in the same voice.

## Detailed Design

### Core Rules

#### 1. Keys

1. The key set is fixed: **"A"–"Z" and "0"–"9"**, uppercase, exactly one character. This is the same
   value the Input & Key Filter press event carries (TASK-037). A lowercase key never reaches this
   system, because the filter uppercases it.
2. The **canonical key order** is A–Z, then 0–9. It is a constant in the app, not taken from the
   JSON object's key order. JSON object order is not reliable: a JS engine lists digit keys first.
   Lists that need an order use this constant, such as the grown-up cast list and validator reports.

#### 2. Data model

There are three kinds of file, all JSON, bundled in the app, and read with plain relative paths
(no platform asset-catalog names; ADR-0001 Decision 6). Run time never fetches them (K-08, Pillar 5).

**a. Theme** (`content/themes/<theme_id>/theme.json`)

| Field | Type | Rule |
|---|---|---|
| `schemaVersion` | integer | The data format's major version. The app **refuses** a value it doesn't know (Edge Cases). Starts at `1`. |
| `contentVersion` | string | The theme's content version, e.g. `"1.0.0"`. Informational: the app never rejects on it. |
| `id` | string | Lowercase, `[a-z]+`. Used in asset names (`dino`). |
| `name` | string | The grown-up panel name ("Dinosaurs"). |
| `voiceLocales` | string[] | Locales this theme has voice for, e.g. `["en-us"]` (K-02, K-05). The first is the default. |
| `glyphSet` | string | The id of the glyph set the theme uses (c below). |
| `families` | object | Family id → `{ idle: <idle param id> }`. The idle parameters themselves live in Cast Rendering data (art bible §5, §8). |
| `countedItem` | object | The thing numbers count and the "empty" item for 0: `{ castId, singular, plural, emptyCastId, emptyWord }`, e.g. `baby dinosaur` / `baby dinosaurs`, `dino_0_nest_01` / `an empty nest`. |
| `soundExceptions` | object | Key → the decision that allows it to break T5, e.g. `{ "X": "K-09, Luan 2026-11-18" }`. Empty by default. |
| `voiceDurations` | object | Locale → line id → **duration in seconds** (number, 3 decimals), for every voice line the theme uses, e.g. `{ "en-us": { "letter_c": 0.512, "word_triceratops": 0.904, "number_3": 0.430, "word_three_baby_dinosaurs": 1.180 } }`. **Written by the build tool** from the rendered files, never by hand; checked by V15. Read by Audio & Voice (F6) and the Press Queue to hold a waiting key until the word ends, without reading the file at play time. |
| `keys` | object | Key ("A"…"9") → key entry (b). All 36 keys are required. |

**b. Key entry and item**

A key entry is `{ "items": [ item, … ] }`. The demo and MVP have exactly 1 item; production has 4–5
(Q1). An item:

| Field | Type | Rule |
|---|---|---|
| `castId` | string | `<theme>_<key>_<name>_<variant>`, e.g. `dino_c_triceratops_01`. Unique within the theme. Stable: the Parade counts cast members by this id. |
| `name` | string | Display name for the grown-up list ("Triceratops"). The child never needs to read it. |
| `word` | string | The words the voice says after the letter, e.g. `"triceratops"`, `"three baby dinosaurs"`. |
| `say` | string | The letter or number name spelled the way it sounds, the script for recording and for any TTS fallback: `"see"`, `"double you"`, `"zee"` (US, K-05), `"three"`. A is `"A."` because the prototype's voice read "ay" as "eye". Never "letter C" (concept §3). |
| `sound` | string | How the letter's usual sound is heard in the word: `"start"`, `"inside"` or `"end"` (K-07, K-09), or `"exception"` for a key Luan recorded as an exception (theme `soundExceptions`). Not set on digit items. |
| `family` | string | A family id from the theme (`horned`, `sauropod`…; art bible §3). |
| `variant` | string | The family variant: the one outline trait (`tri-horn`, `neck-up`…). Siblings in a family never share one. |
| `hueSlot` | string | One of `rose coral ochre leaf mint teal blue violet`, or `shared` for objects that use the shared constants (art bible §4). |
| `art` | string | Relative path of the layered SVG: `art/cast_dino_c_triceratops_01.svg`. |
| `silhouette` | string | Relative path of the baked silhouette path file: `sil/sil_dino_c_triceratops_01.json`. It holds one compound path in the morph-v1 subset (contract §2, §8). |
| `sfx` | string \| null | Relative path of the cast member's own sound: `sfx/sfx_dino_c_triceratops_01.m4a`; `null` means none. |
| `voice` | object | Voice **line ids**, not paths: `{ "letter": "c", "word": "triceratops" }`. For digits: `{ "number": "3", "word": "three_baby_dinosaurs" }`. |
| `weight` | number | Optional, production only; default `1` (Formulas). |

**Voice paths are built, not stored** (game-dev-ios point 10):
`voice/<locale>/vo_<locale>_<kind>_<id>.m4a`, e.g. `voice/en-us/vo_en-us_letter_c.m4a` or
`voice/en-us/vo_en-us_word_triceratops.m4a`. Letter and number lines (`letter_c`, `number_3`) are the
same in every theme. Word lines belong to the theme. Adding a locale (K-02, Localization) adds files
and one `voiceLocales` entry, without editing any item.

**Asset formats:** SVG for art, JSON for path data, mono AAC `.m4a` for sound and voice. These are
platform-neutral: the same files serve iOS, macOS and later Android (game-dev-ios point 11).

**c. Glyph set** (`content/glyphs/<glyph_set_id>/glyphs.json`)

The glyph is the morph's start shape. It depends only on the font, not on the theme, so one glyph set
serves every theme (game-dev-ios point 3). This GDD owns its format. The baking tool belongs to
MorphCore / tools (contract §8).

| Field | Rule |
|---|---|
| `id` | e.g. `fredoka600` |
| `font` | `{ "name": "Fredoka", "version": "2.001", "weight": 600, "licence": "OFL-1.1", "licenceFile": "OFL.txt" }` (contract §7) |
| `baker` | Tool name and version that baked the paths |
| `glyphs` | Key → relative path `glyph_<font>_<char>.json` (art bible §8). All 36 keys are required. |

**d. Asset naming** follows art bible §8, `[category]_[theme]_[key]_[name]_[variant].[ext]`, in
lowercase with underscores:
- letters: `cast_dino_c_triceratops_01.svg`, `sil_dino_c_triceratops_01.json`, `sfx_dino_c_triceratops_01.m4a`;
- digits, under the same pattern: `sil_dino_3_babies_01.json` is **three babies as one compound path**, and `sil_dino_0_nest_01.json` is the empty nest (game-dev-ios point 5);
- voice: `vo_en-us_letter_c.m4a`, `vo_en-us_number_3.m4a`, `vo_en-us_word_triceratops.m4a`.

**Example item (C, Dinosaurs):**

```json
"C": { "items": [ {
  "castId": "dino_c_triceratops_01", "name": "Triceratops", "word": "triceratops",
  "say": "see", "sound": "inside", "family": "horned", "variant": "tri-horn", "hueSlot": "coral",
  "art": "art/cast_dino_c_triceratops_01.svg",
  "silhouette": "sil/sil_dino_c_triceratops_01.json",
  "sfx": "sfx/sfx_dino_c_triceratops_01.m4a",
  "voice": { "letter": "c", "word": "triceratops" }
} ] }
```

#### 3. Numbers (Luan, Q4)

1. A digit d (1–9) shows **d of the theme's counted item** in **one** silhouette (one compound path),
   so the morph lands on the whole group. Their order and colours follow the art bible's baby pastels
   (§4: nine pastels in a fixed order, so neighbouring babies differ). The babies are one shared, simpler
   cast member (§5), so the count is what reads.
2. **0** is the theme's **"empty" item**: the empty nest in Dinosaurs.
3. The voice says the number name, then the counted words: "three… three baby dinosaurs"; "one… one
   baby dinosaur"; "zero… an empty nest". The counted item comes from the theme, not always dinosaurs:
   a vehicles theme would say "three… three little cars". Every digit item writes out its own `word`,
   because plurals and articles differ by language and theme. `countedItem` exists so the validator can
   check them.
4. Q1 applies to every key, digits included: in production a digit may have 4–5 items, e.g. other
   counted items from the same theme ("three… three little eggs").

#### 4. Picking the item for a key (production variety)

1. The item is **resolved when the reveal is shown, not when the key is pressed** (game-dev-ios
   point 7). A press queued under one theme shows the item of the theme active when its reveal starts.
2. With one item, it is always that item. With two or more, the pick rule in Formulas applies:
   uniform with no immediate repeat (Luan, Q1, 2026-11-18).
3. **No saved progress.** Nothing about which items were seen is saved. The only state is
   `lastShown[key]`, kept in memory for this run and lost on quit. Settings Store saves nothing from
   this system.
4. **Variety seed:** one random 64-bit seed per launch, injectable in tests (game-dev-ios point 8). It
   is a separate stream from the morph seed, which is not in this table.
5. **`peek(key)` for prefetch** *(TASK-050)*. Returns the item `resolve(key)` would pick **now**, without
   changing anything: `lastShown` is not updated and the variety stream is **not advanced** (F1 is run on
   the stream's next value, read but not consumed). Cast Rendering prefetches the peeked item when a key
   is queued (its prefetch rule; Reveal Stage R5). The prediction is exact with one item per key (MVP).
   With several items it can differ from the later `resolve` if another reveal resolves in between or the
   theme changes; the reveal still uses `resolve`, and Cast Rendering drops the wrong prefetch.

#### 5. Build time and run time (game-dev-ios point 2)

- **Build time:** the validator (section 6) runs in CI on every theme and the glyph set. Any error fails
  the build, so a bad theme never ships.
- **Run time:**
  - Themes ship in the app bundle only.
  - A theme is **loaded and checked whole, off the main thread, before it is used**. The app checks
    `schemaVersion`, all 36 keys, every referenced file, and every path parsing under morph-v1.
  - A theme that fails is **never shown**. The app stays on the current theme and writes one debug log
    line. The child sees nothing.
  - **At launch there is no current theme yet.** If the stored `themeId` (Settings Store) names a theme
    that is not bundled or that fails the check, **Dinosaurs loads in memory instead and the stored
    `themeId` is kept**: this system never writes it back (Settings Store R6). One debug log line. A
    theme that fails once is not lost from the grown-up's choice, and the child still gets a working
    theme.
  - The default theme (Dinosaurs) is checked the same way. If it fails, the build gate has already
    failed, so this cannot ship (Edge Cases).

#### 6. Validation rules (the build gate; also run at load)

| # | Rule |
|---|---|
| V1 | `schemaVersion` is a known major. |
| V2 | All 36 keys are present, each with ≥ 1 item; MVP themes have exactly 1. |
| V3 | Keys are exactly `A`–`Z`, `0`–`9`; no other key appears. |
| V4 | Every letter item's `word` contains its letter (case-insensitive) **and** its `sound` field is set (K-07, K-09). `"exception"` is allowed only for a key listed in the theme's `soundExceptions`. Whether the sound is really audible is a human content check (Toddler-safe rule T5); the field records the reviewer's answer. |
| V5 | Every digit item's `word` begins with the number word (`one`…`nine`) and contains `countedItem.singular` for 1 and `.plural` for 2–9 (MVP edition); key `0`'s item is `countedItem.emptyCastId` with `emptyWord`. |
| V6 | `castId` is unique in the theme and follows the naming pattern; `art`, `silhouette`, `sfx` follow art bible §8 naming. |
| V7 | Every referenced file exists: art, silhouette, sfx (if not null), and every voice line for **every** locale in `voiceLocales`. |
| V8 | Every silhouette and every glyph **parses with a morph-v1 parser** and has **≥ 1 subpath of 2+ points** and **total length > 0** (contract §2–3; game-dev-ios point 4). The bake tool's rule stays: plain decimals, `M` after every `Z`. |
| V9 | The glyph set has all 36 keys and records font name, version and licence. |
| V10 | Hue slots: at most **4 items per slot** per theme; family siblings never share a slot; leaf and mint never in one family (art bible §4). Counted over the items in one "edition" (Edge Cases: production variety). |
| V11 | Family + variant pairs are unique within a theme. |
| V12 | Every sfx is ≤ 2.0 s long (art bible §8). |
| V13 | `family` exists in the theme's `families`. |
| V14 | Every `weight`, when present, is > 0 (F1 needs a positive total). |
| V15 | `voiceDurations` has an entry for **every** voice line of every item, for every locale in `voiceLocales`, and no other entries. Each value **matches its file's decoded duration within ±0.01 s**: the **decoded length with the AAC encoder priming and end padding removed** (the sample count the app's decoder returns, which Audio & Voice schedules), **not** the container's duration; AAC priming alone is about 2112 samples, ≈ 44 ms at 48 kHz, which would break ±0.01 s. The build tool measures it with the same trimming the app's decoder applies. **Word lines ≤ 1.25 s** (Audio & Voice `word_len_max_s`, F6) and **letter and number lines ≤ 1.0 s** (`letter_len_max_s`, Audio A3). |

#### 7. Toddler-safe content rules (every theme)

| # | Rule |
|---|---|
| T1 | **Friendly, never scary** (art bible §5): no bared teeth, no claws at the viewer, no angry brows, no jaws open wider than the head. When in doubt, pick the softer pose. |
| T2 | **No weapons, fire, blood, skulls, death or danger** as a cast member or a word. A fossil is a friendly bone, not a skeleton of a death. |
| T3 | **No brands, no known characters**: no real-world logo, product or character look-alike. |
| T4 | **Recognisable**: the silhouette at 64 px stays nameable and distinct from its family siblings (art bible §3 test). |
| T5 | **The letter's usual sound is audible** in the spoken word (K-09, Luan 2026-11-18), at the start, inside or at the end (K-07). A silent letter (**p**teranodon) fails. A content reviewer listens to every word and sets `sound`. **Recorded exception: X = xenoceratops** (X says "z"; X has few options; Luan, 2026-11-18). Any other exception needs Luan's decision and a `soundExceptions` entry. |
| T6 | The voice says the letter **name**, then the word (K-05): "C… triceratops", never "letter C". |
| T7 | Sounds are short (≤ 2 s) and gentle: roars stay low and soft (prototype `roar_volume` 0.35; level set by Audio & Voice). |
| T8 | Real names are kept even when long (Luan, Q2): quetzalcoatlus, wuerhosaurus and others stay. |

### States and Transitions

This system has no runtime state machine. The data is immutable once loaded. The only states are:

| State | Meaning | Goes to |
|---|---|---|
| Unloaded | No theme in memory | Loading (launch, or a theme picked in the grown-up panel) |
| Loading | Reading and checking a theme off the main thread | Active (pass), or back to the previous theme (fail; debug log) |
| Active | The current theme serves item lookups | Loading (a different theme picked) |

Next to Active, the in-memory `lastShown[key]` map exists. It is reset when the app launches and when
the theme changes.

### Interactions with Other Systems

| System | Direction | What crosses |
|---|---|---|
| Input & Key Filter (TASK-037) | in | The key value "A"–"Z" / "0"–"9" (shared format, Rule 1). |
| Press Queue | — | Queues keys, not items. Whether closing the grown-up panel clears the queue is **Press Queue's / Reveal Stage's call** (dependency stated, not decided here). |
| Reveal Stage | out | At reveal start: `resolve(key) → item` (pick rule). For prefetch: `peek(key) → item`, no state change (Rule 4.5). |
| MorphCore | out | The glyph path (glyph set) and the silhouette path (item). The morph seed and timings are not here. |
| Cast Rendering | out | `art`, `family`, `variant`, `hueSlot`; idle params by family id. |
| Audio & Voice | out | `sfx` path; voice paths built from `voiceLocales` + line ids. |
| Hint Letters | out | The 36 keys in canonical order (which keys can be hinted). |
| Parade | out | Stable `castId` for "8 new cast members met" (in-memory, per run). |
| Parent Gate & Grown-up Panel | in | The theme picked; takes effect on the next reveal. |
| Theme Packs | out | This format is what a theme pack ships. |
| Localization | out | `voiceLocales` and line ids; new locales add files only. |
| Settings Store | in | Only the chosen theme id (and voice locale, later). Nothing from this system's own state. |

## Formulas

### F1. Item pick for one reveal

Inputs:

| Variable | Meaning | Range |
|---|---|---|
| `n` | number of items for the key in the active theme | 1–5 (MVP 1; production 4–5, Q1) |
| `w_i` | weight of item i (`weight`, default 1) | 0.1–10; default 1 |
| `last` | index shown last time for this key in this run, or none | — |
| `u` | uniform random number in [0, 1) from the variety stream | — |

Rule (**uniform, no immediate repeat**; Luan, Q1, 2026-11-18):

```
if n == 1:            pick 0
C = all i in 0..n-1, except last (if last is set and n >= 2)
W = sum of w_i over C
pick the first i in C (in data order) where (sum of w_j for j in C up to and including i) > u * W
```

With all weights 1, every candidate has probability `1 / |C|`: `1/(n−1)` after the first reveal, and
`1/n` on the first reveal of that key in this run.

Random numbers: **SplitMix64**, the same generator as morph contract §4. It is seeded with the
per-launch variety seed, and its 64-bit output is turned into `u = (x >> 11) * 2^-53`. Using the same
generator lets a shared test fixture check both apps with one seed.

Examples:
- `n = 1`: always item 0. No random number is drawn.
- `n = 5`, all weights 1, no `last`: each item 1/5. With `u = 0.43`, `W = 5`, target 2.15: the running
  sums go 1, 2, 3, so the pick is item 2.
- `n = 5`, `last = 2`, all weights 1: C = {0, 1, 3, 4}, each 1/4. With `u = 0.43`, target 1.72: the
  running sums go 1, 2, so the pick is item 1.
- `n = 2`, `last = 0`: C = {1}, so it alternates 0, 1, 0, 1… (deterministic once started).
- Weights `[2, 1, 1, 1, 1]`, no `last`: item 0 has 2/6 = 33%, the others 1/6 each.

Degenerate inputs: every weight must be > 0 (V14), so W > 0
whenever C is non-empty. C is never empty: n ≥ 1, and `last` is only excluded when n ≥ 2.

## Edge Cases

| Case | What happens |
|---|---|
| A key has 0 items | Fails V2 at build. It never ships. At run time a theme with this flaw fails the load check and is never shown. |
| A key has 1 item | Always that item. F1 draws no random number. |
| `schemaVersion` unknown (newer major) | The theme is refused at load and the app stays on the current theme. If it is the default theme, it can't ship: the build validator uses the same version list. |
| A theme fails the load check when picked in the panel | It is not shown. The current theme stays, with one debug log line. No message to the child. The grown-up panel may grey out the theme (Parent Gate GDD's call). |
| The stored theme fails the check **at launch** (or is not bundled) | Dinosaurs loads in memory; the stored `themeId` is kept, not rewritten (Settings Store R6). One debug log line. The next launch tries the stored theme again. |
| A `voiceDurations` entry is missing or wrong at run time (despite V15) | The Press Queue uses the bound `T + 1.5 s` for that word (Audio & Voice F6). One debug log line. Playback never measures the file. |
| Silhouette or art missing at run time (despite the gate) | Per asset, nothing shown to the child, one debug log line. **The glyph glows and sparkles out** instead of morphing, and the letter voice plays if present (game-dev-ios point 6). |
| Glyph missing | No morph: the cast member fades in, with the voice (matches TASK-038). |
| sfx missing | Skipped. The rest of the reveal plays. |
| Word voice missing | The letter (or number) line only. |
| Letter voice missing too | The chime only (Audio & Voice). |
| Theme changed while presses are queued | The new theme applies from the **next reveal**. The item is resolved at reveal start, so queued keys show the new theme's items. `lastShown` resets. Whether the panel clears the queue is Press Queue's call. |
| Theme changed during a reveal | The running reveal finishes with the item it already resolved. |
| Same key pressed many times (mash) | Each reveal resolves again with F1. With 1 item, it is the same cast member every time, as intended for the MVP. |
| Two-word word ("tee rex", "three baby dinosaurs") | Allowed. `word` is free text, and its voice line id uses underscores (`tee_rex`). |
| Production variety vs hue-slot caps | The art bible's "≤ 4 per slot" was written for 26 one-per-key creatures. With 4–5 items per key, V10 counts per **edition** (item index 0 across all keys is one edition, index 1 the next…). This interpretation is **proposed**; art-director to confirm when production content is drawn. |
| Locale added with missing files | Fails V7 at build. At run time a locale with missing lines falls back per line, as above. |
| JSON key order (digits first in JS) | Ignored. The app uses the canonical order (Rule 1.2). |
| Lowercase or non-key press | Never reaches this system (Input & Key Filter). |

## Dependencies

**Depends on:** nothing at run time (Foundation). It is built on:
- **morph contract v1** (`docs/architecture/morph-contract-v1.md`): path subset, tokenizer, sampling;
  V8 uses its parser;
- **art bible** §3 (families, one outline trait), §4 (hue slots, baby pastels), §5 (cast, friendly
  faces, numbers), §8 (asset naming, SVG source, silhouette export, sfx ≤ 2 s);
- **ADR-0001** Decision 6 (bundled JSON, baked glyphs, silhouettes, reduced set kept elsewhere).

**Depended on by** (each GDD must link back to this one when written; noted, not edited here):

| System | Uses |
|---|---|
| Input & Key Filter (TASK-037) | Shares the key value format (Rule 1). |
| Audio & Voice (`design/gdd/audio-voice.md`, TASK-041) | sfx path; voice paths from `voiceLocales` + line ids; `voiceDurations` (its F6); decoding its audio is part of this system's off-main-thread theme load, and a theme is Active only when that is done (its R4.1). |
| Cast Rendering | art, family, variant, hueSlot; idle params per family. |
| MorphCore | glyph and silhouette path data (morph-v1). |
| Reveal Stage | `resolve(key)` at reveal start; the missing-asset fallbacks. |
| Press Queue | Whether a theme change clears the queue (decided there); `voiceDurations` for the word-end hold (Audio & Voice F6). |
| Hint Letters | The 36 keys in canonical order. |
| Parade | Stable `castId`. |
| Parent Gate & Grown-up Panel | Theme pick; the cast list by `name`. |
| Theme Packs | This format. |
| Localization | `voiceLocales`, line ids. |
| Settings Store (`design/gdd/settings-store.md`) | Stores only the chosen `themeId`; hands it over at launch and on change. At launch a failing stored theme → Dinosaurs in memory, `themeId` kept (its R6; section 5 here). |

## Tuning Knobs

| Knob | Default | Safe range | Affects | Owner |
|---|---|---|---|---|
| Items per key (production) | 4–5 (Q1) | 1–5 | Variety; art cost (36 × n cast members per theme) | Luan |
| Pick rule | uniform, no immediate repeat (Q1) | uniform / uniform-no-repeat / weighted | How often a favourite comes back | Luan |
| `weight` per item | 1 | 0.1–10 | A favourite shows more often | Luan / content |
| Repeat-avoid | on | on/off | Off allows the same item twice in a row | Luan |

Morph timings, the particle count and the reduced set are **not** knobs here (Reveal Stage / MorphCore).

## Visual/Audio Requirements

From the art bible and the prototype, per item: an SVG on a 640×440 artboard (anchor (320, 410),
facing right), one compound silhouette path, a gentle sound ≤ 2 s, and voice lines loudness-matched
(Audio & Voice sets the level). The Dinosaurs prototype used synthesised sounds; real sounds and the
recorded voice are not sourced yet (systems index high-risk row: Audio & Voice).

## UI Requirements

None for the child. The grown-up panel lists the theme's cast by `name` in canonical order and offers
the theme pick (Parent Gate & Grown-up Panel GDD).

## Cross-References

- `design/gdd/game-concept.md`: Core Mechanics 1a and 3; MVP; Scope Tiers.
- `production/team/decisions.md`: K-02, K-05, K-07, K-08.
- `design/art/art-bible.md`: §3, §4, §5, §8.
- `docs/architecture/morph-contract-v1.md`; `docs/architecture/adr-0001-native-apple.md` Decision 6.
- `prototypes/letter-morph-dinosaur/config.js` `KEY_TABLE` (the played table; prototype code, not referenced by production).

## The Dinosaurs theme (first content set)

From the played prototype (iterations 1–4). Families, variants and hue slots follow art bible §3–§4.
SFX kinds are the prototype's synth recipes, which stand in until real sounds are sourced. **Flag
column:** ✅ passes T5; ✳ recorded exception (K-09).

### Letters

| Key | Name | Word (spoken) | Say | Sound heard | Family / variant | Hue slot | SFX (prototype) | Flag |
|---|---|---|---|---|---|---|---|---|
| A | Ankylosaurus | ankylosaurus | A. | start, short a | ankylosaur / club-tail | blue | thump | ✅ |
| B | Brachiosaurus | brachiosaurus | bee | start | sauropod / neck-up | leaf | deep roar | ✅ |
| C | Triceratops | triceratops | see | inside, soft c /s/ | horned / tri-horn | coral | grumble | ✅ (C1: kept) |
| D | Diplodocus | diplodocus | dee | start | sauropod / neck-forward | teal | deep roar | ✅ |
| E | Edmontosaurus | edmontosaurus | ee | start, short e | duckbill / duck-bill | blue | honk | ✅ |
| F | Fossil | fossil | eff | start | object / fossil | shared | crack | ✅ (Q6: kept) |
| G | Gallimimus | gallimimus | jee | start, **hard g /g/**, G's usual sound | ornithomimid / gallimimus | ochre | chirp | ✅ (Q3: stated) |
| H | Hadrosaurus | hadrosaurus | aitch | start | duckbill / bump | mint | honk | ✅ |
| I | Iguanodon | iguanodon | eye | start, short i | duckbill / thumb-spike | ochre | honk | ✅ |
| J | Juravenator | juravenator | jay | start, /dʒ/ (US) | raptor / fuzz | blue | screech | ✅ |
| K | Kentrosaurus | kentrosaurus | kay | start | plated / spikes | ochre | grumble | ✅ |
| L | Lambeosaurus | lambeosaurus | el | start | duckbill / hatchet-crest | rose | honk | ✅ |
| M | Maiasaura | maiasaura | em | start | duckbill / brow-baby | violet | honk | ✅ |
| N | Nest | nest | en | start | object / nest | shared | crack | ✅ (Q6: kept) |
| O | Oviraptor | oviraptor | oh | start, long o | ornithomimid / oviraptor | rose | chirp | ✅ (C2: kept) |
| P | Tapejara | tapejara | pee | inside, /p/ ("ta-peh-JAR-a") | flyer / in-flight | teal | screech | ✅ (P1: replaces pteranodon) |
| Q | Quetzalcoatlus | quetzalcoatlus | cue | start, /k/ ("KET-sal") | flyer / standing | coral | screech | ✅ (C3: kept) |
| R | Raptor | raptor | are | start | raptor / stripes-brows | leaf | raptor chirp | ✅ |
| S | Stegosaurus | stegosaurus | ess | start | plated / plates | leaf | grumble | ✅ |
| T | T-Rex | tee rex | tee | start | rex / plain | violet | big roar (soft) | ✅ (Q5: kept) |
| U | Utahraptor | utahraptor | you | start, long u /juː/ | raptor / arm-feathers-crest | coral | raptor chirp | ✅ (C2: kept) |
| V | Velociraptor | velociraptor | vee | start | raptor / long-snout | ochre | raptor chirp | ✅ |
| W | Wuerhosaurus | wuerhosaurus | double you | start, /w/ | plated / low-plates | teal | grumble | ✅ |
| X | Xenoceratops | xenoceratops | ex | "z" sound: **exception** | horned / xeno-horns | blue | grumble | ✳ (X1: K-09 exception) |
| Y | Yutyrannus | yutyrannus | why | start, /j/ | rex / feathered | coral | big roar (soft) | ✅ |
| Z | Zuniceratops | zuniceratops | zee | start | horned / zuni-horns | leaf | grumble | ✅ |

Hue-slot count (art bible §4, current table): rose 2, coral 4, ochre 4, leaf 4, mint 1, teal 3,
blue 4, violet 2. All are within the cap of 4. Tapejara takes pteranodon's place in teal, so the
counts are unchanged.

### Numbers

Counted item: `baby dinosaur` / `baby dinosaurs`. Empty item: the nest (the same art as N, shown empty).

| Key | Say | Word (spoken) | Silhouette | SFX (prototype) |
|---|---|---|---|---|
| 0 | zero | an empty nest | `sil_dino_0_nest_01` | one soft chirp |
| 1 | one | one baby dinosaur | `sil_dino_1_babies_01` | chirp ×1 |
| 2 | two | two baby dinosaurs | `sil_dino_2_babies_01` | chirp ×2 |
| 3 | three | three baby dinosaurs | `sil_dino_3_babies_01` | chirp ×3 |
| 4 | four | four baby dinosaurs | `sil_dino_4_babies_01` | chirp ×4 |
| 5 | five | five baby dinosaurs | `sil_dino_5_babies_01` | chirp ×5 |
| 6 | six | six baby dinosaurs | `sil_dino_6_babies_01` | chirp ×5 |
| 7 | seven | seven baby dinosaurs | `sil_dino_7_babies_01` | chirp ×5 |
| 8 | eight | eight baby dinosaurs | `sil_dino_8_babies_01` | chirp ×5 |
| 9 | nine | nine baby dinosaurs | `sil_dino_9_babies_01` | chirp ×5 |

The prototype capped the chirps at 5, so 6–9 don't sound longer than 5. Whether the sound should
count along is Audio & Voice's call.

### Letter-sound picks (Luan, 2026-11-18)

Under K-09 (hear the letter's usual sound), game-art-content listed options for every key where the
sound was silent, shifted or borderline. Luan picked:

| # | Key | Pick | Why / note |
|---|---|---|---|
| P1 | P | **Tapejara** replaces pteranodon | /p/ heard inside the name ("ta-peh-JAR-a"); stays a flyer in flight, so the art bible's flyer pair (P, Q) and the teal slot don't change. Not picked: Tupandactylus, Protoceratops, Parasaurolophus. |
| X1 | X | **Keep Xenoceratops** as a recorded exception to T5 | X has few options (no toddler word starts with /ks/; T-Rex stays at T). The voice still says "ex… xenoceratops". The theme lists `"X"` in `soundExceptions`. Not picked: Alxasaurus, Mixosaurus. |
| C1 | C | **Keep Triceratops** | Soft c /s/ is one of C's usual sounds; it is Luan's own K-07 example. |
| C2 | O, U | **Keep Oviraptor, Utahraptor** | The long vowel (the letter's name) counts as a usual sound. |
| C3 | Q | **Keep Quetzalcoatlus** | The q is heard as /k/. |

## Decisions (Luan, 2026-11-18)

| # | Question | Decision |
|---|---|---|
| Q1 | Production variety | **4–5 items per key**, every key including digits. Pick rule **uniform, no immediate repeat** (F1). |
| Q2 | Hard real names | **Keep the real names** (quetzalcoatlus, wuerhosaurus, juravenator…). |
| Q3 | Letter sound (K-09) | **The child must hear the letter's usual sound** in the word, anywhere in the name (K-07). G = gallimimus passes: hard g /g/ is G's usual sound. Picks: **P = Tapejara** (replaces pteranodon); **X = Xenoceratops kept as the one recorded exception**; C, O, U, Q kept (see Letter-sound picks). |
| Q4 | Numbers | Like the prototype: **"three… three baby dinosaurs"**. The counted item and the line are **per-theme data** (a vehicles theme: "three little cars"); 0 = the theme's "empty" item. |
| Q5 | T = "tee rex" | **Keep** T = "tee… tee rex": the T-Rex is the dinosaur toddlers know best. |
| Q6 | Objects in a creature theme | **Keep** F = fossil and N = nest: theme-world objects are allowed (the hatching baby is a favourite). |

## Open Questions

- **Hue slots with variety:** V10 counts per edition (proposed; art-director to confirm when
  production content is drawn).

## Acceptance Criteria

Each criterion is checked by the validator on the data, or by a unit test with fixed inputs.

1. **36 keys:** for the Dinosaurs theme, the validator reports 36/36 keys present, each with exactly 1
   item (MVP), and no other key.
2. **Words:** every letter item's `word` contains its letter, and every letter item has `sound` set;
   only X has `"exception"`, and X is the only key in `soundExceptions`.
   0 failures.
3. **Paths:** every silhouette (36) and every glyph (36) parses with the morph-v1 reference parser,
   has ≥ 1 subpath of 2+ points and total length > 0. 0 failures. A test file with an `A` arc command
   makes the validator fail with the file name.
4. **Files:** every art, silhouette, sfx and voice path (built for each locale in `voiceLocales`)
   resolves to a file in the bundle. 0 missing. Removing one file makes the build fail and names it.
5. **Hue slots:** no slot holds more than 4 items, and no two siblings share a slot (validator output).
6. **Schema:** a theme with `schemaVersion: 2` is refused by an app that knows only 1, and the app
   keeps the current theme (unit test).
7. **Load off the main thread:** loading a theme runs off the main thread (test asserts the thread),
   and a theme that fails the check is never made active (unit test with a broken fixture).
8. **Pick rule:** with seed S from the shared fixture, `n = 5` and no weights, 10,000 reveals of one
   key give no immediate repeat and each item between 18% and 22% (unit test, both apps; F1).
   With `n = 1`, no random number is drawn.
9. **No saved progress:** after quitting and relaunching, no file written by this system exists
   (`lastShown` is in memory only).
10. **Theme switch:** with key D queued and the theme switched in the panel, the next reveal shows the
    new theme's D item (integration test).
11. **Missing asset:** with the silhouette of D removed from a debug build, pressing D shows the glyph
    glowing and sparkling out with the letter voice, no crash, and one debug log line. With the word
    voice removed, only "dee" plays.
12. **Toddler-safe review:** a content reviewer signs a checklist for T1–T8 for every item of a theme
    before it ships. Every letter item's `sound` value was set by that listening check.
13. **Launch fallback:** with the stored `themeId` naming a broken test theme, launch shows Dinosaurs,
    the stored record still holds the broken theme's id afterwards, and one debug log line is written
    (unit test with an injected Settings Store).
14. **Voice durations:** the validator reports a `voiceDurations` entry for every voice line in every
    locale, each within ±0.01 s of its file; a test word line of 1.30 s and a test letter line of 1.10 s
    each fail the build and name the file.
15. **Peek changes nothing:** with a fixed seed, `n = 5` and `last` set, calling `peek(D)` 10 times returns
    the same item each time and equals the next `resolve(D)`; `lastShown` and the stream position are
    unchanged after the peeks (unit test). With `n = 1`, `peek` returns item 0 and draws nothing.
