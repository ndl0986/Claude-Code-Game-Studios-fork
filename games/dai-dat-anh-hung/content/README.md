# content/: shared game data (ADR-0001)

The missions, quiz, VI/EN text, claims, sources, tuning and asset map that **both** native
apps read. It is written once and read by the iOS app (`ios/`) and the Android app (`android/`).
The first apps to read it (TASK-006 iOS, TASK-007 Android) are a **native vertical slice** of one mission, not yet the production codebase; mission, combat, quiz and hint rules are formalised in the GDDs (TASK-008), and this schema follows them. It is fully offline: everything is bundled at build time, and there is no content server.

## Folders

| Folder | Bundled into the apps? | What |
|---|---|---|
| `data/` | **yes**, the whole folder | `index.json`, `strings.json`, `sources.json`, `markers.json`, `rules.json`, `tuning.json`, `assets.json`, `heroes/<hero_id>/{mission,quiz,claims}.json`, `fonts/`, pictures and sounds |
| `schema/` | no (tests only) | JSON Schema 2020-12, one per file type, plus `common.schema.json` |
| `samples/` | no (tests only) | `heroes/sample/`: a full ⟨placeholder⟩ hero; the apps run it until real data lands |
| `metrics/` | no (tests only) | `nunito-advances.json`: Nunito's advance per code point at the rendered weights (800, 600), per 1000 em, generated on Android by the debug-only `FontMetricsActivity`. The font's own `hmtx` is its wght 200 default and is ~8% narrower, so R8c uses this table. |
| `fixtures/` | no (tests only) | Input plus expected output for the data rules both apps must agree on |

- **Android:** `sourceSets.main.assets.srcDirs("../../content/data")`; debug builds may add `samples/`.
- **iOS:** `data/` is a folder reference in the app target, so the folder structure is kept. Samples and fixtures go only to the test target.

## Who writes what

| File | Owner |
|---|---|
| Player text, `heroes/*/claims.json`, `sources.json`, `markers.json`, `strings.json` | game-art-content (history sign-off: Luan) |
| `schema/`, `rules.json`, `tuning.json`, `fixtures/`, `samples/` | the devs (game-dev-ios, game-dev-android) |
| `assets.json` | whoever adds the asset |

A schema change needs both devs and game-art-content to agree. A breaking change bumps
`schema_version`'s MAJOR number.

## Data model

Schema **1.1** (D-06, a MINOR bump): optional training `blocks` / `finish_special` and reach-the-flag `encounters[]`. 1.0 files stay valid.

Mission schema **1.5** (TASK-005l, MINOR): an optional beat `cheer` (default `true`). With `false`, beat_end has no cheer pose and no `sfx_beat_end_cheer`; `sfx_ui_next` (the page turn) plays once, and the progress dots still fill (Mission flow Rule 2, TASK-020 W21). It's ignored on fight beats, which end on their caption (R21 warns). Which beats set it is a content decision. 1.4 files stay valid.

`rules.json` schema **1.2** (TASK-005l, MINOR): `text_limits.min_px` {heading 44, body 37, button 34, label 28} and a `class` on every `fit.fields` entry (Language & text Rule 6): **heading** = hero_name, beat_title; **body** = dialog, goal, scene, intro, ending, banner, quiz_prompt, quiz_choice, quiz_why, dialogue_line, dialogue_narrator; **button** = button; **label** = ui, place. The banner is body text, so its `font_px` is 37 (was 28): VI fits 1 line and EN 2 lines in its 880 box. The `goal` box is **880** (was 1040; TASK-005n), so the goal plate and the banner bar share the top stack's band x 330–1250 to the right of pause and sound (hud.md §3.3); every current goal still fits 1 line.


- **Text** `{id, vi, en, claims[]}` is every story, scene, intro, ending, banner and quiz line.
  - `claims` holds at least one claim ID; invented (C12) counts.
  - Scene text is a list of Text, one sentence per box.
  - The `id` is stable and dotted, e.g. `tqt.b2.scene.1` or `tqt.quiz.q3.why`.
- **UiText** `{id, vi, en}` is used only in `strings.json`. UI strings carry no claims.
- **Claim** `{id, vi, en, label, sources[], relabel_condition?, signoff{status, by?, date?}}`.
  - `label` is one of fact, fact_as_recorded, interpretation, legend or invented.
- **Source** `{id, citation, kind, location, status}`.
  - `kind` is textbook, chronicle, literature or **secondary** (a reference work or article citing one; schema 1.3).
  - `status` is to_confirm or confirmed.
- **Mission** `{hero{id, name, timeline_order, place}, next_hero, intro[], banner?, beats[], ending{lines[], picture_id}}`.
  - The banner is defined once as Text, a text layer that is never baked into art. A beat with `uses_banner` shows it.
- **Beat** `{id, type, theme, buttons[], title, scene[], goal, uses_banner?, params}`.
  - `type` is one of fight, walk, hold-meter, training, reach-the-flag or **dialogue** (schema 1.4: `params.lines` 2–12 of {speaker, mood?, text}, optional `ask` {button: Text, taps 1–3, at_line}; `buttons` [], `scene` may be [], `goal` optional, no card or caption). Speaker `narrator` has no portrait; `hero` is reserved for the mission's hero (left); other speaker ids are on the right. Portraits are `pic.portrait_<hero_id>_<speaker>[_<mood>]` and must resolve for real heroes (R10; a missing mood variant fails). R8c field types: `dialogue_line` (speaker lines, 720/38/3/600) and `dialogue_narrator` (880/38/2/600); the ask button is a `button`.
  - `buttons` is a subset of move, attack, defend and special.
  - `params` are per type. A fight's are `enemies[]`, `max_active` and `from_left[]`, as in the prototype.
- **Quiz** has 3–5 questions; `tuning.json` `quiz_count` is 5, so the file's question count decides (D-11b). Each has `prompt`, an optional `picture_id`, 3 choices `{text, picture_id}`, `correct_index` and `why` (shown after the right answer).
- **Stars** (`rules.json`):
  - Retries are wrong picks before the right one, counted as a **total across the whole quiz**: 0 earns 3★, 2 or fewer earns 2★, more earns 1★.
  - A wrong card is greyed; a repeat tap on it is ignored and doesn't count (D-11a), so a question has at most 2 retries and the quiz always ends.
  - Finishing always unlocks the next hero.
- **Tuning** (`tuning.json`): the prototype's `config.js` values in snake_case. Each entry is `{value, min, max, unit}`, in a 1280×720 world. `pad_min`, `pad_gap` (the minimum gap between pads) and `drag_threshold` (tap vs drag on the map and timeline) are in **pt/dp**, not world px (Input GDD F1, Rule 16). `screen_enter_lock` (s): presses within this time of a story, card, dialogue, quiz or results **screen** being entered from another screen are dropped (Input Rule 13, QC r6 B7); box-to-box advances within a screen keep only `advance_debounce`. The lock rolls: each press dropped inside it restarts the window, capped at `screen_enter_lock_max` (s) from entry (QC r6 B7). `finish_hold` (s): on a training beat with `finish_special`, the banner moment after the Cờ tap lasts this long instead of `end_pause` (Mission flow Rule 7c, r9).
  - It also holds the numbers the prototype hard-coded in `index.html` (TASK-005b), so neither app
    copies them by hand: `first_spawn_delay`, `hurt_recover`, `leader_telegraph_mul`,
    `enter_to_approach_dist`, `approach_min_time`, `windup_reach_extra`, `strike_reach_extra`,
    `block_knock`, `rest_speed_mul`, `attack_hit_at`, `attack_close_range`, `attack_move_mul`,
    `flee_remove_margin`, `hero_edge_margin`, `camera_follow_offset`, `ground_y`, `beat_start_x`,
    `beat_gap`, `hero_start_x`. D-09 adds `special_push`, `special_cooldown`, `advance_debounce`
    (story-box tap debounce) and `bump_stop` (walk-beat bump stop). TASK-005e adds `dummy_spacing`
    (gap between training dummies); the training partner stands at `enemy_reach - stand_gap`
    (derived, no key).
  - Fight rules that are logic, not numbers (prototype `updateEnemies`): only one enemy is in
    windup or strike at a time; only the nearest enemy on each side may start a windup; an enemy
    stands at `enemy_reach - stand_gap + rank * queue_spacing` from the hero (rank 0 = nearest).
- **Assets** (`assets.json`) map each id to a file under `data/` with its size in bytes.
  - Pictures are png or webp. Sounds are m4a (AAC) or wav, never OGG (iOS). Fonts are ttf or otf.
  - Files are lowercase. **No text inside pictures.**
  - The font is `fonts/nunito.ttf` (SIL OFL 1.1, licence beside it) and has full Vietnamese diacritics.

## Validation rules

The JSON Schema covers structure. The rules below cross files, and each app's unit tests check
them against `data/` and `samples/`. `fixtures/validity.json` has one case per rule.

| Rule | Check |
|---|---|
| R1 | Every file is valid against its schema. |
| R2 | Every claim, source, picture and hero id that is referenced exists. |
| R3 | Every story Text has at least one claim (schema); only `strings.json` has none. |
| R4 | A Text citing a **legend** claim contains a legend marker from `markers.json`, in VI and in EN. The writer authors the marker; it is never added automatically. A Text citing a fact_as_recorded claim may use "Sử chép rằng / The chronicle says". |
| R4b | (D-12) R4 applies to **sentence** fields: intro, beat scene, ending lines, quiz prompt, quiz why. **Label** fields (hero name, place, banner, beat title, goal, quiz choice) are exempt from R4 only if, for each legend claim the label cites, a **marked** sentence citing that same claim exists in its scope. "Marked" is the R4 test: a legend marker in VI **and** in EN. Scope: any sentence of the mission for name, place, banner, title and goal; the choice's own question's prompt or why for a quiz choice. |
| R4c | (schema 1.4) Dialogue lines and the ask button citing a legend claim pass R4 if the beat's **first line** is a `narrator` line marked in VI and EN that cites the same claim. Dialogue lines count as sentences in the R4b scope. |
| R5 | A fact or fact_as_recorded claim can't be `approved` while any of its sources is `to_confirm`. R5b: only an invented claim may have no sources. |
| R6 | An invented claim is never cited by quiz text. |
| R7 | All text is Unicode NFC. |
| R8 | No vi or en line is over 120 characters (schema), and EN fits `rules.json` `text_limits.en_budget` for its field type. For `strings.json` the type is the entry's optional `field` (button, ui, dialog; D-21) if set, else it comes from the id: `ui.btn.*`, `ui.pad.*`, `ui.lang.*` and `*_confirm` / `*_keep_reading` are `button`; ids ending in `_warning` are `dialog` (60, TASK-005e); every other `ui.*` id is `ui`. |
| R8b | (D-21) VI fits `rules.json` `text_limits.vi_budget` for its field type (= floor(1.6 × en_budget), capped at 120). |
| R8c | (D-21, Language & text GDD F1) Each VI and EN line fits its field's box: advances from `content/metrics/nunito-advances.json` at the field's `weight` × `font_px` / 1000, greedy word wrap at spaces into `box_width / (1 + allowance)`, at most `max_lines`; one word wider than the box fails. Values in `text_limits.fit.fields` (world px at 1×). |
| R8c (narrow) | (rules 1.3, TASK-005o; still rule R8c, no new id) A fit field with `narrow_box_width` (goal and banner: 720) must also fit `max_lines` at that width: the narrow-phone plates, `design/ux/hud.md` §3.3 (0.32 ≤ k < 0.48). Fixture cases with `"box": "narrow"` are measured there. |
| R8d | (rules 1.2, Language & text Rule 6) Every `text_limits.fit.fields` entry has a `class` that `text_limits.min_px` names, and its `font_px` ≥ `min_px[class]`. A missing or unknown class fails. Skipped on a `rules.json` without `min_px` (1.1). |
| R9 | Text ids are unique across the bundle. |
| R10 | Every `picture_id` and asset id resolves in `assets.json` and the file exists. |
| R11 | An app refuses a `schema_version` with a newer MAJOR number at **build** time. A newer MINOR number is fine. |
| R12 | **Claim gate:** see below. |
| R13 | Buttons per beat type (schema 1.1, D-06). Minimum: walk {move}; hold-meter {special}; fight {move, attack}; training {move, attack} + defend if `blocks` > 0 + special if `finish_special`; reach-the-flag {move} + attack if `encounters` is non-empty. `special` is allowed only on hold-meter and training with `finish_special`; never on walk, fight or reach-the-flag (D-10 B: no Special in fights or encounters for now). Defend is optional on a fight (blocking is taught, never required). |
| R13b | reach-the-flag `encounters` are sorted by `at_screen`, strictly ascending, each `0 < at_screen < length_screens`. |
| R13d | (schema 1.4) A `dialogue` beat has `buttons: []`; if it has `ask`, `at_line + taps ≤ lines`. The button is the ask button while `at_line ≤ L < at_line + taps` (L = the 1-based line showing); each ask tap shows line L + 1. |
| R14 | `tuning.json`: `attack_range` ≥ `enemy_reach` − `stand_gap`, so the hero can reach the enemy in front of him (error). |
| R14b | (Combat Rule 15b) For each `training` beat, `dummies × dummy_spacing ≤ world.width − enemy_reach − 2 × hero_edge_margin` (990 with today's tuning), so the last dummy lies inside the capped training zone (error). The limit is computed from `tuning.json`, never stored. A beat without `dummies` passes. |
| R15 | `tuning.json`: `telegraph` < 0.8 s is a **warning**, not an error. |
| R16 | `rules.json`: each lower star's `max_retries` is ≥ the higher star's (2★ ≥ 3★); `null` means no limit. |
| R17 | `hero.timeline_order` is unique across the heroes in `index.json` (an integer in gaps of 10; Hero progression GDD Rule 1). Samples are excluded. |
| R18 | Each indexed hero's `next_hero` is the next hero **in `index.json`** by `timeline_order`, or null for the last one. Checked at build time; claim status is ignored (Hero progression GDD Rule 6). |
| R19a | (ADR-0002, error) A picture's `width` / `height` in `assets.json` match its PNG/WebP header. |
| R19b | (ADR-0002, **warning** until the budgets are measured) A picture is ≤ 2048 on both sides; per kind, `pic.quiz_*` ≤ 512×512 and `pic.scene_*` ≤ 1440×1320 per tile file. |
| R20 | Every theme a bundled beat uses has a `sky_band` in `themes.json`; a theme outside the mission enum (village, bamboo, river, camp) is invalid. |
| R21 | (schema 1.5) `cheer: false` on a `fight` beat is a **warning**: fights end on their caption and never cheer, so the field is ignored at run time. |

### Claim gate (R12)

- **Release build:** a Gradle task (Android) or an Xcode build phase (iOS) fails the build if any claim cited by bundled Text is `pending`.
- **Run time, release:** a quiet guard hides a mission whose claims are not all approved and logs it. It never crashes.
- **Debug build:** the mission plays, and each Text with a pending claim shows an `UNSIGNED Cxx` badge. QC tests debug builds.
- The expected outcomes are in `fixtures/claim-gate.json`.

## Shared fixtures

`fixtures/quiz-stars.json`, `quiz-scoring.json`, `quiz-shuffle.json` (P-05 card order), `rng.json` (mulberry32), `claim-gate.json` and `validity.json` are
input plus expected output, and both apps' unit tests run every case.

`fixtures/trace-tqt.json` is the **simulation trace**. It holds a fixed input script over the real
Trần Quốc Toản mission (walk, dialogue with 2 asks, hold, training, reach-the-flag with 2 encounters)
and the expected sim state every 30 updates: phase, beat, hero x and facing, lock, dialogue line,
training step, enemies and RNG draws. Its `rule` field defines how to replay it. A bot on the Android
core (`TraceTest`) generates it, and both apps replay it. A mismatch is a parity bug, fixed in
whichever app disagrees with the GDD. Trace **1.1** (TASK-005m) adds `cam` (the sim camera after each step) to every snapshot. In training, its bot first holds ▶ for 4 s into Combat Rule 15b's camera cap (xStart − 70) and the hero's right limit (xStart + 990), then walks back for the dummies. Regenerate it whenever `mission.json`, `tuning.json` or a
combat or flow rule changes on purpose.

Feel (timing on screen,
knock-back, button size and touch) is not a fixture; it is checked by per-platform QC.

## Assets (ADR-0002, Proposed)

- One resolution set: authored at 2×, shipped at **1.5×** (a 1920×1080 world). No density buckets.
- No picture larger than **2048×2048**; bigger sheets split by animation set, backgrounds into tiles.
- Backgrounds ship as 1440×1320 tiles at 1.5×. Above them, the sky band is a code-drawn **gradient** whose colours come from `themes.json` `sky_band {top, bottom}` per theme (planned). Far-sky tiles fade their top ~10% into the band; key sky elements stay below ~15% from the top.
- Lossless WebP for sprites, lossy WebP (q ≈ 85) for backgrounds; PNG still allowed.
- Atlases by what is on screen together; a mission's art loads at its start and is released at its end; ≤ 64 MB decoded per mission.
- `assets.json` is schema **1.2**: pictures carry `width` / `height` (R19a, R19b). Apps decode content leniently at run time (unknown keys ignored), so a 1.1 app still reads a 1.2 file; the content tests stay strict.
- `themes.json`: `sky_band {top, bottom}` per theme (R20). The colours are **placeholders** from the prototype (top #FFD59A, bottom #CFEEF2; camp #3B3F6B) until game-art-content sets them.

## Planned (later phases)

- `pictures.json` registry: ids that follow the art bible § 8 naming, alt text `{vi, en}`, the asset spec and status.
- An optional `vo {vi, en}` voice-over clip id per Text.
- Sign-off scope: a claim's sign-off covers the fact. A wording change goes through content review and Luan's `content:approved`.
