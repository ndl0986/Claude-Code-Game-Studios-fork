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
- **Quiz** has 3–5 questions. Each has `prompt`, an optional `picture_id`, 3 choices `{text, picture_id}`, `correct_index` and `why` (shown after the right answer).
- **Stars** (`rules.json`):
  - Retries are wrong picks before the right one, counted as a **total across the whole quiz**: 0 earns 3★, 2 or fewer earns 2★, more earns 1★.
  - Finishing always unlocks the next hero.
- **Tuning** (`tuning.json`): the prototype's `config.js` values in snake_case. Each entry is `{value, min, max, unit}`, in a 1280×720 world.
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
| R5 | A fact or fact_as_recorded claim can't be `approved` while any of its sources is `to_confirm`. R5b: only an invented claim may have no sources. |
| R6 | An invented claim is never cited by quiz text. |
| R7 | All text is Unicode NFC. |
| R8 | No vi or en line is over 120 characters (schema), and EN fits `rules.json` `text_limits.en_budget` for its field type. |
| R9 | Text ids are unique across the bundle. |
| R10 | Every `picture_id` and asset id resolves in `assets.json` and the file exists. |
| R11 | An app refuses a `schema_version` with a newer MAJOR number at **build** time. A newer MINOR number is fine. |
| R12 | **Claim gate:** see below. |

### Claim gate (R12)

- **Release build:** a Gradle task (Android) or an Xcode build phase (iOS) fails the build if any claim cited by bundled Text is `pending`.
- **Run time, release:** a quiet guard hides a mission whose claims are not all approved and logs it. It never crashes.
- **Debug build:** the mission plays, and each Text with a pending claim shows an `UNSIGNED Cxx` badge. QC tests debug builds.
- The expected outcomes are in `fixtures/claim-gate.json`.

## Shared fixtures

`fixtures/quiz-stars.json`, `quiz-scoring.json`, `claim-gate.json` and `validity.json` are
input plus expected output, and both apps' unit tests run every case. Feel (timing on screen,
knock-back, button size and touch) is not a fixture; it is checked by per-platform QC.

## Planned (later phases)

- `pictures.json` registry: ids that follow the art bible § 8 naming, alt text `{vi, en}`, the asset spec and status.
- An optional `vo {vi, en}` voice-over clip id per Text.
- Sign-off scope: a claim's sign-off covers the fact. A wording change goes through content review and Luan's `content:approved`.
