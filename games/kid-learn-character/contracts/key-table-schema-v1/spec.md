# key-table-schema-v1

**Owner GDD:** `design/gdd/key-table-theme-data.md` (schema 2). **ADR:** ADR-0004 (D1, D3), ADR-0002 (D2, D4).
**Cases:** hand-written by game-qc-android (TASK-068), reviewed by game-art-content.

## What it covers

- The validator's verdicts, V1–V17 (§6), each with at least one pass and one fail.
- The §4 / F1 item pick with raw draws from the `key-variety` stream, the D4 u helper, `resolve`, `peek`, and the
  `lastShown` reset on a theme change.
- `titleCastId` and its fallback.
- `rowWords` validity (V17). The word *draw* is keyboard-row-v1's.
- The canonical key order.
- Decoding theme-file bytes into the model.

**Not covered here, and why:**
- **Loading off the main thread (AC 7):** a unit test.
- **The toddler-safe review (AC 12, T1–T8):** manual.
- **Measuring decoded voice durations and sfx lengths:** Tools. This contract takes the measured values as inputs.
- **The keyboard row's v1 / invalid fallback word:** keyboard-row-v1 owns the row (Edge Cases, On-screen Keyboard
  Row R2).
- **The real Dinosaurs theme passing the validator (AC 1, 2, 3, 4, 5, 14, 16, 17):** ADR-0003's build-time content
  validation on the shipped content. These cases use a synthetic test theme, so they don't depend on the content's
  state.

## Layers (ADR-0004 D3)

- **`model`** (KidCore harness): a decoded model goes in, and a verdict or a result comes out.
- **`file`** (apple/Tools test target): theme-file bytes go in, and a decoded model or a decode error comes out.
  It uses Tools' decoder and reads this same `cases.json`.

Each harness runs only its own layer. The current file has 66 `model` cases and 3 `file` cases.

## Fixtures

- **`theme`**: a synthetic, schema-2, 36-key test theme `testbase` with one item per key, built to pass V1–V17:
  - every letter item: word `<letter>item`, sound `start`, its own family and variant, hue slots cycling through the
    eight slots (at most 4 per slot);
  - digits 1–9: `<number word> test toy(s)`; 0: the empty item `an empty box`, all with hue slot `shared`;
  - `rowWords` are Dinosaurs' 16 words from the GDD;
  - `voiceDurations` 0.5 s for every line.
  It depends on question KT-Q7 (whether `shared` counts in V10).
- **`assets`**: what the validator needs to know about the files, as measured upstream:
  - `files`: the relative paths present;
  - `silhouettePaths`: path → morph-v1 path string;
  - `sfxDurations`: path → seconds;
  - `voiceMeasured`: voice path → decoded seconds.
  These are inputs to V7, V8, V12 and V15.
- **`glyphSet`**: the glyph set model (§2c), plus `glyphPaths`: key → path string, for V8 and V9.

## `given` fields

`theme`, `assets`, `glyphSet` (each usually a `$fixture` with a `patch`); `state` (`{ "lastShown": { key: index } }`);
`themeBytes` (file layer: the theme file as UTF-8 text, key order as written).

## Entry points (contract-local events)

| Event | Fields | Emits |
|---|---|---|
| `validate` | — | `verdict` |
| `pick` | `n`, `last`?, `weights`? | `picked` (F1 on its own, one `key-variety` draw unless `n` = 1) |
| `nextU` | `stream` | `u`: the D4 helper on the stream's next draw |
| `resolve` | `key` | `item`; consumes one draw when the key has ≥ 2 items (but see KT-Q2) |
| `peek` | `key` | `item`; reads the stream's next value **without consuming it**, and leaves `lastShown` alone (§4.5) |
| `themeChanged` | `theme` | nothing; resets `lastShown` |
| `keysInOrder` | — | `keys` |
| `titleCast` | — | `item`, preceded by one `log` when it falls back to key A's item 0 |
| `decodeTheme` (file layer) | — | `model` or `decodeError` |

## Outputs

| `out` | Fields |
|---|---|
| `verdict` | `pass` (bool), `failedRules`: the V-rule ids that fail, in rule-number order (messages are not compared) |
| `picked` | `index` |
| `u` | `value` (double; exact) |
| `item` | `castId` |
| `keys` | `value`: the 36 keys in canonical order |
| `log` | none (one debug log line) |
| `model` | `equalsFixture`: the named fixture the decoded model must equal; `keyOrder`?: the model's key order; `without`?: fixture fields that must be absent |
| `decodeError` | `field`: the field the error names |

**State:** `lastShown`. **Field kinds:** none. `u.value` has no kind, so it is compared exactly (case-schema-v1 §6). There is no other double output.

## Stream `key-variety`

One draw per `resolve` of a key with ≥ 2 items, taken when the reveal resolves (§4.1). `pick` draws the same way.
`n` = 1 draws nothing. `peek` reads the next value but never consumes it. The u conversion is ADR-0002 D4's.

## Pending (not guessed; cases come in a later version)

- **ADR-0003 `assetPrefix`** and the **`id` = "dinosaurs"** rule, with the Key Table follow-up. Until then, V6 is
  tested for `castId` uniqueness only, not for the naming pattern, and the asset-naming part of V6 is not tested.

## Questions for the GDD owner (game-art-content)

None of these is guessed in a case. A case that depends on an answer says so in its `note`.

- **KT-Q1.** F1's last paragraph and AC 8 still say the variety stream is SplitMix64 with one shared seed, so that
  a fixture checks both apps. ADR-0002 D4 and ADR-0004 D4 make seeding per platform and feed raw draws instead.
  This contract follows the ADRs. Can F1 and AC 8 be updated? AC 8's 10,000-reveal statistics stay a per-platform
  unit test.
- **KT-Q2.** With `n` ≥ 2 and only one candidate (`n` = 2 with `last` set, so C = {the other}), is a draw consumed?
  F1 says only that `n` = 1 draws nothing. This decides the stream's consumption order, so there is no case for it
  yet.
- **KT-Q3.** A missing key fails V2. Does V3 ("Keys are exactly A–Z, 0–9") also fire? `V2-fail-key-missing`
  expects V2 only.
- **KT-Q4.** V2's "MVP themes have exactly 1": how does the validator know a theme is an MVP theme (a build
  setting, a field)? The exact-1 clause has no case yet.
- **KT-Q5.** V5 for key 1: "contains `countedItem.singular`". The plural contains the singular ("test toys"
  contains "test toy"). Must key 1's word *not* contain the plural? The cases avoid this.
- **KT-Q6.** V6's `castId` pattern `<theme>_<key>_<name>_<variant>`: is `<variant>` the two-digit index (`01`), as
  in every example, or the item's `variant` field (`tri-horn`)? Is `<theme>` the asset prefix? See also ADR-0003.
- **KT-Q7.** V10: does hue slot `shared` count toward the per-slot cap and the sibling rule? In Dinosaurs, F and N
  are both family `object` and `shared`, so they would break the sibling rule if it counted. The `theme` fixture
  assumes `shared` is outside both, and gives digits `shared`.
- **KT-Q8.** V17's "every letter is a key of this theme" can't fail while V2 passes. Is it intentionally redundant?
  There is no case for it.
- **KT-Q9.** File layer: is an unknown field in `theme.json` ignored or a decode error? Which layer reports a
  missing required field other than `rowWords` (a decode error, or the validator)? There are no cases for either
  yet.
