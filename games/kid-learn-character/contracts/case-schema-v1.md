# Contract case files: schema v1

The written spec for every `contracts/<name>-vN/cases.json` (ADR-0004 D4). Every harness enforces it with a
**hand-written strict structural check**: it parses with the platform's own JSON parser, walks every object against
the tables below, and applies every FAIL rule **before** any case runs. No third-party schema validator is used
(PKC-03(a)). A schema error is a FAIL that names the file and the JSON path.

**Additions to ADR-0004 D4's example** (approved by the leader, 2026-11-18, TASK-068): the top-level `fixtures` map
with `$fixture` / `patch` references (section 3), so a large input isn't repeated in every case; and a `source` that
may append `"; adr: <file> <section>"` for a rule an ADR pins (section 2).

**Self-test rule:** every rule marked **(S#)** below has a negative fixture in the harness's own tests that must
FAIL. A rule added here without its negative fixture is REVISE at review (ADR-0004 D4).

## 1. Top level

| Key | Required | Type | Meaning |
|---|---|---|---|
| `contract` | yes | string | `<name>-vN`, equal to the directory name **(S1)** |
| `schema` | yes | integer | `1` (this document) **(S2)** |
| `uint64AsString` | yes | `true` | UInt64 values are decimal strings (rule (e)) |
| `units` | yes | object | informational: `{ "time": "s", … }` |
| `tolerance` | yes | object | default tolerances by field kind (section 6) |
| `streams` | yes | string[] | the random streams the contract's cases may draw from; their consumption order is in `spec.md` |
| `fixtures` | no | object | named JSON values that cases reference with `$fixture` (section 3) |
| `cases` | yes | array | at least one case **(S3)** |

Any other top-level key is a FAIL **(S4)**.

## 2. A case

| Key | Required | Type | Meaning |
|---|---|---|---|
| `id` | yes | string | stable, unique in the file **(S5)** |
| `source` | yes | string | `"gdd: <file> <section>"`, optionally followed by `"; adr: <file> <section>"` for a rule an ADR pins (for example the canonical bytes, ADR-0002 D8), or exactly `"generated"` **(S6)** |
| `layer` | only where `spec.md` defines layers | string | for example `"model"` or `"file"` (ADR-0004 D3); missing or unknown where layers exist is a FAIL **(S7)** |
| `note` | no | string | free text for the reader; never read by a runner |
| `given` | yes | object | the starting seam state and inputs. Only the fields the contract's `spec.md` lists; an unknown field is a FAIL **(S8)** |
| `draws` | yes | object | stream name → array of UInt64 decimal strings. Only streams listed at the top level **(S9)**; each value a string of digits `0`–`18446744073709551615` **(S10)** |
| `steps` | yes | array | at least one step |
| `expect` | no | object | checks after the last step (as `expectState`) |
| `tolerance` | no | object | field path → tolerance override; requires `toleranceReason` **(S11)** |
| `toleranceReason` | with `tolerance` | string | cites a GDD or an ADR |
| `permute` | no | string[] | JSON pointers into `given` naming arrays whose order must not matter; the harness runs every permutation (≤ 720) and each must give the same results |

Any other key is a FAIL **(S12)**. Fields that are forbidden everywhere in a case, at any depth **(S13)**:
- `play` (the play clock is derived in `KidCore`, never given);
- `u` (draws are raw UInt64; the core converts them with ADR-0002 D4's helper);
- `seed` (seeding is per platform; morph-contract-v1 is the one exception and does not use this schema).

## 3. `given` values and fixtures

- A `given` value may be a literal, or a fixture reference: `{ "$fixture": "<name>", "patch": [ … ] }`.
  `<name>` must exist in the top-level `fixtures` **(S14)**.
- `patch` is applied in order to a copy of the fixture. Paths are JSON Pointers (RFC 6901; `~1` is `/`,
  `~0` is `~`). Operations:
  - `{ "op": "replace", "path", "value" }`: the target must exist;
  - `{ "op": "add", "path", "value" }`: adds an object member, or inserts into an array at the index;
  - `{ "op": "remove", "path" }`: the target must exist;
  - `{ "op": "remove-value", "path", "value" }`: `path` names an array; removes the one element equal to `value`,
    which must be present.
  - A target that doesn't exist, or any other `op`, is a FAIL **(S15)**.
- A fixture reference may also appear inside an event (for example a theme handed to `themeChanged`).

## 4. Steps

`{ "t": { "uptime": <s>, "away": <s>?, "wall": { "minutesOfDay", "dayKey" }? }, "event": { "type", … }, "expect": [ … ], "expectState": { … }? }`

- **Time.** `t.uptime` is required and never decreases from one step to the next **(S16)**. `t` carries no `play`
  (S13). Events carry no `time` field: the harness fills ADR-0002 D5's `KeyEvent.time` / `TouchEvent.time` from
  `t.uptime`; an event `time` is a FAIL **(S17)**.
- **Event types.** The shared list (ADR-0004 D4): `key` (`kind`: `down`, `up`, `cancel`, `modifiersChanged`),
  `touch`, `tick`, `freeze`, `resume`, `settle`, `panelOpen`, `panelClose`, `foreground`, `background`, `active`,
  `inactive`, `windowKeyGained`, `windowKeyLost`, `screenChanged`, `memoryWarning`, `ready`, `kioskModeOnSet`,
  `kioskModeOnCleared`, `themeReady`, `settingsChanged`, `displayMetricsChanged`, `accessibilityChanged`.
  A contract may add its own entry points, each declared in its `spec.md` with its fields. Any other type, or an
  event field the declaration doesn't list, is a FAIL **(S18)**.
- **`expect`** is an **ordered list** of the outputs the step emits, `{ "out": "<kind>", … }`, compared for exact
  sequence and count, never as a set. An empty list means the step emits nothing. Each contract's `spec.md` lists
  its output kinds and their fields.
- **`expectState`** (optional) checks named state after the step. `spec.md` lists the state names a runner exposes.

## 5. Draws

The harness gives each stream in `draws` a test `RandomSource` that returns the listed values in order. A case that
asks for a draw after its list is empty FAILs, and so does a case that ends with values left in any list. That
proves the documented consumption order (ADR-0004 D4).

## 6. Comparison and tolerances

- Integers, strings, booleans, `null`, arrays and objects compare exactly, member by member.
- Doubles compare within the tolerance for their **field kind**. The file's top-level `tolerance` maps kinds to
  values. ADR-0004 D4 sets the defaults: `time` 1e-9 s; `geometry` (stage or unit space) 1e-6; `morph` positions
  1e-3. Each `spec.md` says which output fields belong to which kind. A double field with no kind compares exactly.
- A case-level `tolerance` maps a field path to a value and needs `toleranceReason` (S11).

## 7. Failure messages

`<contract>/<caseId> [<source>] <field path>: expected E, got A (tol T)`. Schema errors:
`<file> <JSON path>: <rule S#>`. Each run ends with a count per contract and per layer (ADR-0004 D5).
