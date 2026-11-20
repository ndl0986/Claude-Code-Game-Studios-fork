# keyboard-row-v2

**Owner GDD:** `design/gdd/onscreen-keyboard-row.md` after TASK-135 (K-49: the row shows by itself without a hardware
keyboard). **Layer:** KidCore. **ADR:** ADR-0004 (D2 stream `keyboard-row`), ADR-0002 (D3, D4). **Cases:**
hand-written by game-qc-android (TASK-141), reviewed by game-art-content (the GDD's author).

## What changed from v1 (TASK-141)

v2 supersedes keyboard-row-v1 (K-40). In v1, `keyboardRow` false meant hidden. Since K-49 it means automatic:

```
shown = keyboardRow  OR  NOT keyboardPresent        (in Play; never on the Title)
```

- **The 36 v1 cases are carried over** with `keyboardPresent: true` written out in `given`, which gives the old
  behaviour, and the new knob `row_presence_settle_s` 0.5.
- **One carried case changes:** `AC15-on-at-panel-close-off-at-once`. R8 now says a setting change under the panel
  takes effect at the panel's close. So turning the switch off under the panel leaves the row Showing (under the dim)
  until the close, and the fade-out starts at the close. v1 started the fade-out at the switch.
- **New:** the presence and its settle (R8, R9, the Interface), through a `keyboard {present}` event and an optional
  `present` on `returnFromBackground` (the foreground re-read). AC-1 is rewritten; also new: the AC-15 case with no
  keyboard, AC-20 to AC-24, the pending-change rules and the knob floor.

## What it covers

Everything in v1 (F1–F4, R2, R3, R5, R7, the gate freeze, the fallback), plus:
- **AC-1 automatic:** no keyboard → Play entry fades the row in with a new word; a keyboard (every Mac) → nothing is
  drawn and there are no hit rects.
- **The settle (R8):** a presence change applies only once it has held `row_presence_settle_s` of **uptime**,
  inclusive (AC-20: unchanged at +0.4375, the hit rects gone and Fading out at +0.5, Hidden by +0.8125). The settled
  value is the last one reported (AC-22 flapping, as the dyadic 0.25 / 0.375), and a repeated report of the same value
  doesn't restart the hold.
- **Becoming shown / hidden (R8 On / Off):** a new word drawn with `last` = the last word drawn this run (AC-20, AC-21);
  touchable from the fade-in's start; hidden drops the pressed set and the hit rects at once.
- **Deferred applies:** under the panel and during the gate challenge, at the close or `resume()` (AC-23, both
  directions at the gate, with the fade on the play clock).
- **A pending change is dropped** at the panel's close, at a Title → Play entry and at the background. The latest
  report applies at once with no settle, and nothing fires again later.
- **The background:** the return carries the platform's re-read. Still shown → the same word and pressed letters
  (R7); newly shown → a new word; no longer shown → Hidden at once with no fade, the word kept only as `last`.
- **AC-24 forced on:** `keyboardRow` true ignores the keyboard.
- **AC-15 off with no keyboard:** `shown` is unchanged, so the word, the pressed set and the hit rects stay.
- **Fading out → shown again → Fading in with a new word** (a setting change during a presence fade-out).
- **The knob floor** `row_presence_settle_s ≥ row_fade_s`, inclusive, through `knobCheck`.

**Not covered here, and why:**
- **The fade's start alpha after a reversal** ("from the current alpha", R8): v2 tests state and touchability, as
  v1 did, not alpha values. The knob floor means a presence reversal can't meet a fade on its own.
- **A keyboard hiding the row during a word change (Changing):** R8 says it takes effect at once, but which word
  becomes `last` (the old one, or the one drawn at the change's start) isn't stated. No case pins it until the GDD
  answers.
- **AC-25 (the device) and AC-18 (the look):** screenshots on a real iPad.
- **The platform read itself** (`GCKeyboard`, the Mac constant): the adapter's story (input/006). Here, presence
  arrives as events.
- **The ground lift and the reveal keeping its line (AC-20's last sentence):** Reveal Stage R10.
- **Android insets (AC-19):** a later version, with an Android build.

## `given` fields

- `knobs`: v1's (`key_w` 128, `key_h` 118, `gap` 16, `hit_pad` 8, `key_top_y` 590, `key_flash_s` 0.35,
  `press_scale` 1.08, `row_fade_s` 0.3, `word_fade_s` 0.3, `hit_floor_mm` 18) and `row_presence_settle_s` 0.5.
- `accessibility {reduceMotion}`; `keyboardRow` (the stored setting at the start); **`keyboardPresent`** (the
  platform's presence before the first frame; required, never defaulted).
- `rowWords`, `castNames` (as v1).

## Events

v1's events and outputs, with these changes:

| Event | Fields | Emits |
|---|---|---|
| `keyboard` | `present` | — (the change applies once settled, on the first event at or after the settle) |
| `returnFromBackground` | `present`? (the foreground re-read; absent = the latest report stands) | `word` when the row is newly shown |
| `setRow` | `on` | — (applied at `panelClose`) |
| `panelClose`, `gateResume` | — | `word` when the row becomes shown |
| `frame` (any event) | — | `word` when a settled change shows the row |
| `knobCheck` | `knobs {row_presence_settle_s, row_fade_s}` | `knobsValid {value}` |

**State (`expectState`):** v1's `state`, `due`, `word`, `pressed`, plus **`shown`** (the last applied R8 value) and
**`keyboardPresent`** (the settled presence). **Field kinds:** as v1. The settle runs on uptime and the fades on
the play clock. Settle boundaries are dyadic; the 0.3 s fade boundaries are checked on frames on either side.
**Draws:** the `keyboard-row` stream, raw UInt64 strings (each u used here is dyadic).

## Source

Keyboard Row R7–R9, States and Transitions, the Interface, Edge Cases, Tuning Knobs and AC-1, AC-15, AC-20 to AC-24,
as merged by TASK-135 (5647a15f), with v1's sources (KR-Q1–Q11, TASK-089a). sources.lock is cut on that text.
