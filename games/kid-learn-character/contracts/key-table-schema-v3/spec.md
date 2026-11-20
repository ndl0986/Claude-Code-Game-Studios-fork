# key-table-schema-v3

**Owner GDD:** `design/gdd/key-table-theme-data.md` (schema 2) after TASK-147 (K-53: word lines ≤ 1.5 s). **ADR:** ADR-0004 (D1, D3), ADR-0002 (D2, D4).
**Cases:** hand-written by game-qc-android (TASK-068; v2 TASK-146; v3 TASK-147), reviewed by game-art-content.

## What changed from v2 (TASK-147)

v3 supersedes key-table-schema-v2 (K-40). Under K-53 the word-line limit in V15 is **1.5 s** (it was 1.25 s);
letter and number lines stay at 1.0 s.
- **Retired:** `V15-fail-word-line-over-1.25`. Its 1.3 s word line passes now, so its verdict flips.
- **New boundary cases** (both limits are inclusive, `≤`):
  - `V15-fail-word-line-over-1.5` (1.51 s, V15) and `V15-pass-word-line-at-1.5` (1.5 s);
  - `V15-pass-letter-line-at-1.0` (1.0 s), `V15-fail-letter-line-just-over-1.0` (1.01 s, V15) and
    `V15-fail-number-line-just-over-1.0` (1.01 s, V15): the word limit doesn't leak to letter or number lines.
- **v2's other 94 cases and the fixtures are unchanged.** v2 itself was v1 with `.m4a` → `.caf` (K-52, TASK-146)
  plus `V6-fail-sfx-old-m4a-extension` and `V7-fail-voice-file-only-as-m4a`.

## What it covers

- The validator's verdicts, V1–V18 (§6), each with at least one pass and one fail.
- The §4 / F1 item pick with raw draws from the `key-variety` stream, the D4 u helper, `resolve`, `peek`, and the
  `lastShown` reset on a theme change.
- `titleCastId` and its fallback.
- `rowWords` validity (V17). The word *draw* is keyboard-row-v2's.
- The canonical key order.
- Decoding theme-file bytes into the model.

**Not covered here, and why:**
- **Loading off the main thread (AC 7):** a unit test.
- **The toddler-safe review (AC 12, T1–T8):** manual.
- **Measuring decoded voice durations and sfx lengths:** Tools. This contract takes the measured values as inputs.
- **The keyboard row's v1 / invalid fallback word:** keyboard-row-v2 owns the row (Edge Cases, On-screen Keyboard
  Row R2).
- **The real Dinosaurs theme passing the validator (AC 1, 2, 3, 4, 5, 14, 16, 17):** ADR-0003's build-time content
  validation on the shipped content. These cases use a synthetic test theme, so they don't depend on the content's
  state.

## Layers (ADR-0004 D3)

- **`model`** (KidCore harness): a decoded model goes in, and a verdict or a result comes out.
- **`file`** (apple/Tools test target): theme-file bytes go in, and a decoded model or a decode error comes out.
  It uses Tools' decoder and reads this same `cases.json`.

Each harness runs only its own layer. The current file has 92 `model` cases and 7 `file` cases.

## Fixtures

- **`theme`**: a synthetic, schema-2, 36-key test theme, `id` `testbase` with `assetPrefix` `tb`, one item per key,
  built to pass V1–V18. Every castId and asset name uses the prefix (`tb_d_item_01`, `cast/cast_tb_d_item_01.json`, `sfx/sfx_tb_d_item_01.caf`):
  - every letter item: word `<letter>item`, sound `start`, its own family and variant, hue slots cycling through the
    eight slots (at most 4 per slot);
  - digits 1–9: `<number word> test toy(s)`; 0: the empty item `an empty box`, all with hue slot `shared`;
  - `rowWords` are Dinosaurs' 16 words from the GDD;
  - `voiceDurations` 0.5 s for every line.
  `shared` is outside V10 (KT-Q7), so the digits use it.
- **`themeV1`** / **`assetsV1`**: the same theme at schema 1, with no `assetPrefix` and no `rowWords`, so its castIds
  use the `id` (V6).
- **`themePrefix9`** / **`assetsPrefix9`**: the same theme with a 9-letter `assetPrefix`, used consistently everywhere
  (V18's format).
- **`assets`**: what the validator needs to know about the files, as measured upstream:
  - `folder`: the theme's folder name (V18);
  - `otherThemePrefixes`: the `assetPrefix` of every other bundled theme (V18);
  - `files`: the relative paths present, in exact case (V7);
  - `silhouettePaths`: path → morph-v1 path string;
  - `sfxDurations`: path → seconds;
  - `voiceMeasured`: voice path → decoded seconds.
  These are inputs to V7, V8, V12 and V15.
- **`glyphSet`**: the glyph set model (§2c), plus `glyphPaths`: key → path string, for V8 and V9.

## `given` fields

`theme`, `assets`, `glyphSet` (each usually a `$fixture` with a `patch`); `buildSettings` (`{ "singleItemPerKey": bool }`:
present means a build-time run, absent a load-time run; V2, KT-Q4); `state` (`{ "lastShown": { key: index } }`);
`themeBytes` (file layer: the theme file as UTF-8 text, key order as written).

## Entry points (contract-local events)

| Event | Fields | Emits |
|---|---|---|
| `validate` | — | `verdict` |
| `pick` | `n`, `last`?, `weights`? | `picked` (F1 on its own; one `key-variety` draw only when \|C\| ≥ 2) |
| `nextU` | `stream` | `u`: the D4 helper on the stream's next draw |
| `resolve` | `key` | `item`; consumes one draw only when there are ≥ 2 candidates (KT-Q2) |
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

One draw per `resolve` when there are **≥ 2 candidates** (\|C\| ≥ 2, KT-Q2), taken when the reveal resolves (§4.1).
`pick` draws the same way. `n` = 1, and `n` = 2 with `last` set, draw nothing. `peek` reads the next value but never consumes it. The u conversion is ADR-0002 D4's.

## Answers from the GDD owner (key-table-theme-data.md, TASK-069)

The questions in the first draft are now rules in the GDD, and the cases follow them:
- **KT-Q1:** per-platform seeds, and the fixture feeds raw draws (F1, AC 8).
- **KT-Q2:** a draw is consumed only when \|C\| ≥ 2 (`F1-n2-last-set-draws-nothing`).
- **KT-Q3:** a missing key is V2 only; V3 is an extra or malformed key.
- **KT-Q4:** "exactly 1" is the build setting `singleItemPerKey`, not checked at load (`V2-fail-singleItemPerKey-at-build`,
  `V2-pass-two-items-at-load`).
- **KT-Q5:** V5 is an exact match on `<number word> <singular|plural>` (`V5-fail-key1-plural`,
  `V5-fail-double-space`).
- **KT-Q6:** V6 is `^<prefix>_<key>_<name>_<nn>$`, where nn is the item's two-digit position and the prefix is the
  `assetPrefix` (the `id` for a v1 theme). Covered by the `V6-*` cases.
- **KT-Q7:** `shared` is outside V10 (the base fixture).
- **KT-Q8:** V17's key clause is intentionally redundant, so it has no case.
- **KT-Q9:** an unknown field and a missing required field are decode errors. `rowWords` and `assetPrefix` decode as
  absent and are checked by V17 and V18 (the `file-*` cases).

## Not covered yet

- V7's build-only check that each baked file's source exists (`src/art/…svg`): that is the bake tool's run
  (ADR-0003), not a theme-decode or validator case.
- AC 18's "prefix `Dino`" example: an uppercase prefix also breaks V6's lower-case naming, so this contract tests V18's format
  with a 9-letter prefix instead (`V18-fail-prefix-nine-letters`). AC 18's wrong-case `art` path is tested from the
  file side (`V7-fail-wrong-case-file`) for the same reason.
