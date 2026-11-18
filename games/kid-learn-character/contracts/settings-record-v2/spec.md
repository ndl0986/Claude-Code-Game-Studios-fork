# settings-record-v2

**Owner GDD:** `design/gdd/settings-store.md` (including R6a, "The canonical record", TASK-072). **ADR:** ADR-0004 (D1, D3), ADR-0002 (D2 rounding, D8 same bytes).
**Cases:** hand-written by game-qc-android (TASK-068; v2 TASK-091), reviewed by game-dev-android.

## What changed from v1 (TASK-091)

v2 supersedes settings-record-v1 (K-40). It is v1 with two changes; every other case is byte-for-byte the same:
- **`F1-slider-release-7.5` fixed:** the stored volume is 5, not 8. In v1 the release (7.5 → 8) left the record
  unchanged, so R6a's no-op rule says no write and no notification, yet the case expected both. With 5 → 8 it is a
  real change and still tests round-half-away-from-zero on the slider. Found by game-dev-android's KidCore runner.
- **Added `F1-slider-non-finite-NaN`, `-Infinity`, `--Infinity`** (settings-store F1, TASK-082): `volume` stays
  unchanged, with no write, no notification and one `log` for `volume`.

All 76 cases are re-derived by an independent model of the GDD, with 0 mismatches. The model also flags v1's case,
and only that one.

## What it covers

- **Reading:** bytes → the in-memory record and `childLockActive`. This covers defaults with no record (R5), the
  closed list (R1, R2), per-field validation (R6), garbage, a missing or newer `schemaVersion` (R7), `childLock`
  off macOS, and unknown keys.
- **Writing:** a change → the **exact written bytes**, then one notification (R4, R10). This covers the slider
  release (F1), the run-only child-lock OFF (R8: a notification, no write), Reset (R9) and a relaunch.
- **F1:** round half away from zero (the ADR-0002 D2 helper) and the slider clamp. **F2:** gain.

**Not covered here, and why:**
- **Atomic writes (AC-8):** the backend's job (ADR-0005).
- **No sync (AC-16), the relaunch screenshot (AC-17), launch holding play (AC-18):** a build check, a device check
  and App Shell's.
- **Child Lock-in's engage order (AC-15):** Child Lock-in's unit tests and app-shell-v1.
- **Key Table's in-memory Dinosaurs fallback (AC-10's launch half):** key-table-schema-v1 and App Shell. This
  contract checks only that the store keeps the `themeId`.

## Layer

**KidCore** (ADR-0004 D3). The canonical writer and reader are hand-written String/UTF-8 code in `KidCore`, with no
JSON library. Kotlin mirrors them one-to-one, so both platforms write the same bytes.

## Canonical bytes (ADR-0002 D8)

- UTF-8 JSON.
- One object, members **sorted by key** (byte order).
- **No whitespace.**
- Integers written as numbers with no fraction.
- Booleans `true` / `false`.
- The written record has `schemaVersion` plus exactly the R1 fields for the platform: `childLock` only on macOS
  (AC-3), and the app's own version (R7).

Strings escape **only** `"` → `\"`, `\` → `\\` and U+0000–U+001F as lowercase `\u00xx`; everything else, `/` and
non-ASCII included, is raw UTF-8 (R6a). The reader accepts every JSON escape.

## `given` fields

- `platform`: `"macOS"`, `"iPadOS"` or `"android"`.
- `settingsBytes`: the stored value as UTF-8 text, or `null` for no record.

## Entry points (contract-local events)

| Event | Fields | Emits |
|---|---|---|
| `read` | — | one `log` per field fallback, then `record` (no notification, AC-14) |
| `change` | `field`, `value` | `write`, then `notify` |
| `sliderRelease` | `x`: a number, or one of the strings `"NaN"`, `"Infinity"`, `"-Infinity"` for a non-finite value (JSON has no non-finite numbers) | `write` (volume = F1 of `x`), then `notify`; nothing if the level is unchanged (R6a); a non-finite `x`: `log` (`volume`) only |
| `setChildLock` | `on` | ON: `write`, then `notify`. OFF: `notify` only (R8) |
| `reset` | — | `remove`, then `notify` with the defaults and `childLockActive` false (R9) |
| `relaunch` | — | `record`: a fresh store reading what is stored now |
| `gain` | — | `gain` (F2) |
| `roundHalfAwayFromZero` | `x` | `value` |

## Outputs

| `out` | Fields |
|---|---|
| `record` | `record` (the in-memory record), `childLockActive` |
| `write` | `bytes`: the exact written text |
| `remove` | none |
| `notify` | `record`, `childLockActive` (R10: the whole record plus the run value) |
| `gain` | `value` |
| `value` | `value` |
| `log` | `field`: the R1 field name, or `"record"` when the whole record is unreadable (the reason text is not compared) |

**Field kinds:** `gain.value` is `gain` (1e-12). `value.value` is exact. No other doubles.

## Answers from the GDD owner (settings-store.md R6a, TASK-072)

The first draft's questions are now rules, and the cases follow them:
- **SS-Q1:** the escaping above (`R6a-escape-*`: quote, backslash, `\t` read and written as `\u0009`, é read raw or
  as `\u00e9` and written raw).
- **SS-Q2:** any JSON number token is a number: `8.0` → 8, `1e1` → 10, `-0` → 0 (`R6a-number-token-*`).
- **SS-Q3:** a bare `NaN` or `Infinity` makes the whole record unreadable (`R6a-bare-*-unreadable`). A slider NaN
  is covered in v2 now that F1 states it (TASK-082): `F1-slider-non-finite-*`.
- **SS-Q4:** rounding writes no log (`F1-read-6.6-rounds-to-7`, the number-token cases).
- **SS-Q5:** several bad fields log in R1's table order (`R6a-log-order-R1`).
- **SS-Q6:** a duplicate key makes the record unreadable (`R6a-duplicate-key-unreadable`).
- **SS-Q7:** a no-op change does nothing (`R6a-no-op-*`, `R6a-lock-on-when-active-is-no-op`). ON while the stored
  value is true but `childLockActive` is false is a real change (`R6a-lock-on-after-run-only-off-is-a-change`).

A missing field takes its default and logs one line, like any R6 fallback (`R7-missing-schemaVersion-is-v1`).
