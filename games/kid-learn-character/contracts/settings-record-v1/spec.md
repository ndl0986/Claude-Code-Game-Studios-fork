# settings-record-v1

**Owner GDD:** `design/gdd/settings-store.md`. **ADR:** ADR-0004 (D1, D3), ADR-0002 (D2 rounding, D8 same bytes).
**Cases:** hand-written by game-qc-android (TASK-068), reviewed by game-dev-android.

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

String escaping is question SS-Q1; every case uses ASCII strings with nothing to escape.

## `given` fields

- `platform`: `"macOS"`, `"iPadOS"` or `"android"`.
- `settingsBytes`: the stored value as UTF-8 text, or `null` for no record.

## Entry points (contract-local events)

| Event | Fields | Emits |
|---|---|---|
| `read` | — | one `log` per field fallback, then `record` (no notification, AC-14) |
| `change` | `field`, `value` | `write`, then `notify` |
| `sliderRelease` | `x` | `write` (volume = F1 of `x`), then `notify` |
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

## Questions for the GDD owner

None of these is guessed in a case. Nothing has been asked yet, and the reviewer, game-dev-android, may answer or
forward them.

- **SS-Q1.** How does the canonical writer escape strings? A `themeId` read from a record can be any non-empty
  string, and the kept value is written back (R6). The rule must be byte-identical on both platforms: which
  characters are escaped, the `\u` form and its case, `/`, and non-ASCII. Until then, cases are ASCII only.
- **SS-Q2.** Which number forms count as an integer `volume` when reading: `8.0`, `1e1`, `-0`? A non-integer number
  inside 0–10 is rounded (R6). Are these "numbers" too? Only 6.6, 10, 10.4, 12 and −1 are tested.
- **SS-Q3.** AC-4 lists "volume NaN", but JSON has no NaN. A record containing `NaN` isn't valid JSON. Is that the
  whole record unreadable (AC-7, all defaults) or only `volume` (AC-4)? There is no NaN case.
- **SS-Q4.** Does reading 6.6 → 7 write a debug log line? R6 says "every fallback writes one debug log line".
  Rounding may not be a fallback. `F1-read-6.6-rounds-to-7` expects no log.
- **SS-Q5.** In which order are the log lines written when several fields are bad? Every case has one bad field.
- **SS-Q6.** What does the reader do with a duplicate key in the record?
- **SS-Q7.** A `change` to a field's current value: a write and a notification, or nothing? There is no case.
