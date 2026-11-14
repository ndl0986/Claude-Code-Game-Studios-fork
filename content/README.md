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


- **Text** `{id, vi, en, claims[]}` is every story, scene, intro, ending, banner and quiz line.
  - `claims` holds at least one claim ID; invented (C12) counts.
  - Scene text is a list of Text, one sentence per box.
  - The `id` is stable and dotted, e.g. `tqt.b2.scene.1` or `tqt.quiz.q3.why`.
- **UiText** `{id, vi, en}` is used only in `strings.json`. UI strings carry no claims.
- **Claim** `{id, vi, en, label, sources[], relabel_condition?, signoff{status, by?, date?}}`.
  - `label` is one of fact, fact_as_recorded, interpretation, legend or invented.
- **Source** `{id, citation, kind, location, status}`.
  - `kind` is textbook, chronicle or literature.
  - `status` is to_confirm or confirmed.
- **Mission** `{hero{id, name, timeline_order, place}, next_hero, intro[], banner?, beats[], ending{lines[], picture_id}}`.
  - The banner is defined once as Text, a text layer that is never baked into art. A beat with `uses_banner` shows it.
- **Beat** `{id, type, theme, buttons[], title, scene[], goal, uses_banner?, params}`.
  - `type` is one of fight, walk, hold-meter, training or reach-the-flag.
  - `buttons` is a subset of move, attack, defend and special.
  - `params` are per type. A fight's are `enemies[]`, `max_active` and `from_left[]`, as in the prototype.
- **Quiz** has 3–5 questions; `tuning.json` `quiz_count` is 5, so the file's question count decides (D-11b). Each has `prompt`, an optional `picture_id`, 3 choices `{text, picture_id}`, `correct_index` and `why` (shown after the right answer).
- **Stars** (`rules.json`):
  - Retries are wrong picks before the right one, counted as a **total across the whole quiz**: 0 earns 3★, 2 or fewer earns 2★, more earns 1★.
  - A wrong card is greyed; a repeat tap on it is ignored and doesn't count (D-11a), so a question has at most 2 retries and the quiz always ends.
  - Finishing always unlocks the next hero.
- **Tuning** (`tuning.json`): the prototype's `config.js` values in snake_case. Each entry is `{value, min, max, unit}`, in a 1280×720 world.
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
| R5 | A fact or fact_as_recorded claim can't be `approved` while any of its sources is `to_confirm`. R5b: only an invented claim may have no sources. |
| R6 | An invented claim is never cited by quiz text. |
| R7 | All text is Unicode NFC. |
| R8 | No vi or en line is over 120 characters (schema), and EN fits `rules.json` `text_limits.en_budget` for its field type. |
| R9 | Text ids are unique across the bundle. |
| R10 | Every `picture_id` and asset id resolves in `assets.json` and the file exists. |
| R11 | An app refuses a `schema_version` with a newer MAJOR number at **build** time. A newer MINOR number is fine. |
| R12 | **Claim gate:** see below. |
| R13 | Buttons per beat type (schema 1.1, D-06). Minimum: walk {move}; hold-meter {special}; fight {move, attack}; training {move, attack} + defend if `blocks` > 0 + special if `finish_special`; reach-the-flag {move} + attack if `encounters` is non-empty. `special` is allowed only on hold-meter and training with `finish_special`; never on walk, fight or reach-the-flag (D-10 B: no Special in fights or encounters for now). Defend is optional on a fight (blocking is taught, never required). |
| R13b | reach-the-flag `encounters` are sorted by `at_screen`, strictly ascending, each `0 < at_screen < length_screens`. |
| R14 | `tuning.json`: `attack_range` ≥ `enemy_reach` − `stand_gap`, so the hero can reach the enemy in front of him (error). |
| R15 | `tuning.json`: `telegraph` < 0.8 s is a **warning**, not an error. |
| R16 | `rules.json`: each lower star's `max_retries` is ≥ the higher star's (2★ ≥ 3★); `null` means no limit. |

### Claim gate (R12)

- **Release build:** a Gradle task (Android) or an Xcode build phase (iOS) fails the build if any claim cited by bundled Text is `pending`.
- **Run time, release:** a quiet guard hides a mission whose claims are not all approved and logs it. It never crashes.
- **Debug build:** the mission plays, and each Text with a pending claim shows an `UNSIGNED Cxx` badge. QC tests debug builds.
- The expected outcomes are in `fixtures/claim-gate.json`.

## Shared fixtures

`fixtures/quiz-stars.json`, `quiz-scoring.json`, `quiz-shuffle.json` (P-05 card order), `rng.json` (mulberry32), `claim-gate.json` and `validity.json` are
input plus expected output, and both apps' unit tests run every case. Feel (timing on screen,
knock-back, button size and touch) is not a fixture; it is checked by per-platform QC.

## Planned (later phases)

- `pictures.json` registry: ids that follow the art bible § 8 naming, alt text `{vi, en}`, the asset spec and status.
- An optional `vo {vi, en}` voice-over clip id per Text.
- Sign-off scope: a claim's sign-off covers the fact. A wording change goes through content review and Luan's `content:approved`.
