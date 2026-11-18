# ADR-0004: Behaviour contracts, fixture rules and verification harness

## Status

Accepted (Luan, 2026-11-18; recorded by game-leader on Luan's explicit acceptance)

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**

## Date

2026-11-18

## Last Verified

2026-11-18, against:
- `docs/architecture/architecture.md` (v1, TASK-059): Cross-platform contracts, fixture rules (a)–(g), the scaffold
  story;
- ADR-0001 (Accepted; tests are XCTest), ADR-0002 (Accepted, a674686b: D2–D7), morph-contract-v1 (Accepted);
- the GDDs at `origin/docs/kid-learn-character-plan` @ 1b547689.

## Decision Makers

- Luan (accepts).
- game-qc-android (author, TASK-064).
- game-dev-ios (plan review and independent read; owner of the ADR-0002 seams).
- game-leader (answered the plan's Q1–Q5).

## Summary

The toy's rules live in `KidCore` and `MorphCore`, and a later Kotlin app must behave the same. Without shared,
GDD-sourced cases, the two platforms would each pass their own tests and still disagree. This ADR fixes the 13
cross-platform behaviour contracts and what each covers. It also fixes the case-file schema (typed events, seam
state, raw draws per stream, ordered expectations, per-field tolerances), the verification harness on Apple
(XCTest) and later Kotlin (JUnit 5), the versioning and GDD-drift rules, who writes and runs the cases, and the order
in which they are written.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | None from the template's table (`engine.name` unset, ADR-0001, K-28). Swift 6.4, Xcode 27.1; tests are XCTest (ADR-0001) |
| **Domain** | Core (verification) |
| **Layer** | Foundation |
| **Knowledge Risk** | LOW. Plain XCTest, `swift test`, file reads in a test target, and JSON decoding in test targets and Tools only |
| **References Consulted** | `docs/engine-reference-local/native-apple/VERSION.md`, `current-best-practices.md` (Structure: "tested with `swift test`"); `docs/architecture/architecture.md`; ADR-0002 |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | The scaffold story's harness self-test (Validation Criteria 1–4) |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Accepted); ADR-0002 (Accepted, a674686b); morph-contract-v1 (Accepted with ADR-0001) |
| **Enables** | ADR-0003 (content data and pipeline: key-table-schema-v1 is its validator's case set); ADR-0005 (settings persistence: settings-record-v1); ADR-0007 (input adapters: input-filter-v1); ADR-0011 (build, CI and verification: runs this harness); ADR-0012 (Android: the Kotlin harness) |
| **Blocks** | The first scaffold story's check (c) (the harness), and every `KidCore` system story (its definition of done includes its contract passing) |
| **Ordering Note** | Written before ADR-0003, because the content validator's cases are contract cases (architecture.md, Required ADRs) |

## Context

### Problem Statement

Every rule of the toy is pure code in two Swift packages, and the Android app will port them later (K-03). The
GDDs state the numbers: F-tables, worked examples, ACs. Unless those numbers become one shared set of
machine-readable cases, each platform tests its own reading of the GDD, and a disagreement is found by a child, not
a test. morph-contract-v1 already proved the approach for one system: the Kotlin port matched the Swift case bit for
bit. The other systems need the same, decided before the scaffold story writes the harness.

### Constraints

- **ADR-0002 D2:** the cores import only the standard library and Foundation, and may not use `JSONDecoder`,
  `JSONEncoder` or JSON `Codable`. Test targets and `apple/Tools` may.
- **ADR-0002 D3 and D4:** four clocks, with play derived in `KidCore`, and one `RandomSource` per stream. Fixtures
  feed draws, not seeds.
- **K-28:** CI is local: `swift test` on Luan's Mac under the leader's MAC FREE, and QC runs the suites.
- **The studio rule:** a check that cannot report that it did not run is not a check
  (`.claude/rules/skill-authoring.md`).

### Requirements

- Every number a GDD states is a case with a source tag (architecture.md rule (a)).
- The same case files drive both platforms, with no platform library in the code under test.
- A failure names its case, and a missing or unknown contract fails rather than being skipped.
- A GDD edit that changes a cited number is caught at review.

## Decision

### D1. The contracts

Contracts live in `games/kid-learn-character/contracts/<name>-vN/`, each with `spec.md`, `cases.json`,
`sources.lock` and, optionally, `cases-generated.json` (generated cases only, same schema and version). `contracts/README.md` is the index, naming the current version of each contract. morph-contract-v1
stays at `docs/architecture/morph-contract-v1.md` and `content/fixtures/morph-contract-v1.json` (architecture.md),
and the README points to it.

| Contract | Owner GDD(s) | In | Out (where it is tested instead) | Minimum v1 case set |
|---|---|---|---|---|
| morph-contract-v1 (exists) | morphcore.md | positions, T, phases | — | the existing fixture |
| key-table-schema-v1 | key-table-theme-data.md | validator verdicts V1–V17; the §4 pick (F1) with draws, no immediate repeat; peek changes nothing; the D4 u helper; `titleCastId`; `rowWords` (V17) | loading off the main thread (AC 7, unit test); toddler-safe review (AC 12, manual); voice-duration measurement (Tools) | V1–V17 one pass and one fail each; F1's examples; ACs 8, 10, 13, 15, 16, 17 |
| settings-record-v1 | settings-store.md | bytes → record (defaults, closed list, one invalid field, garbage, migration); record → exact bytes; F1 round-half-away; F2 gain; reset; one notification; `childLock` stored only as ON, `childLockActive` as the run value (R8) | backend atomicity (AC-8, ADR-0005); backups; AC-16/17 (build, device) | AC-1, 3, 4, 5, 6, 7, 12, 13, 14, 15b |
| input-filter-v1 | input-key-filter.md | R2 resolution (character first, position fallback, numpad); R3 modifiers; R4 held/repeat; R5 swallowing on `kioskModeOn` (AC-1k, k2); R6 the exact chord with Fn/Shift/Caps (AC-1j); the ⌘-release stale-key rule via `modifiersChanged` (k3), with `KeyStateQuery` present and absent; Title / challenge routing incl. Cancel/Esc → origin (k4); moon slop geometry (k5); R7 touch layers, F1 hit radius, batch sort; F2 re-press gap | adapter mappings (ADR-0007); AC-1k6 (the TCC prompt, Mac) | the ACs named in **In**, plus F1 and F2's examples |
| press-queue-v1 | press-queue.md | AC-1–13, 20, 22, 23 (gate freeze), 24 (`hasWord`); F1 table, F3 mash, F4 waiting, F5 Reduce Motion | AC-19 (integration with hints); AC-17 (app-shell-v1) | those ACs and F1's table |
| reveal-timing-v1 | reveal-stage.md; cast-rendering.md F1, F2, F4, F5, F7 | `startReveal` → {formedS, revealLen, hasWord} with F5 fallbacks; formed/shown once; origins; F1 stage fit; F2–F4 curves; F6 tap cooldown; freeze/resume/settle on the play clock; published boxes; `haloOn`, `mashing`; Cast Rendering role/tier, halo, cap, idle/hop, late-art wait | the E-times (audio-plan-v1); draw order (AC-13, screenshot); feel (AC-16, device) | Reveal Stage AC-1, 2, 3, 9, 10, 11, 17; each F-row's example |
| scene-look-v1 | scene-time-weather.md; cast-rendering.md F8; K-25 | F1 look and `lookBlend` at the boundaries; the 3 s jump fade; F2 `skyMidL` and the edge switch with ±0.005 hysteresis (2.57:1 / 2.53:1); the 160-case build data; F4 counts; mashing thinning; the two clocks; F5 horizon lift; F3 weather motion, with draws from the `scene-weather` stream (D4) | drawing; device cost (AC-19) | AC-1, 3, 4, 5, 9, 11, 14; F2's examples |
| parade-v1 | parade.md | F1 batches (a repeat counts once) and arming; glyph-only not met; F2 start and Armed; order; F3 walk; own clock and gate freeze; next batch; panel/background count as played; per theme; art wait; Reduce Motion bob ×0.5; no cap | the tune (audio-plan-v1); looks (AC-18) | AC-1–13, 17, 19 |
| app-shell-v1 | app-shell-title.md | the state machine; F1 launch, with `ready` = first frame, chord installed, window covers its display; Title start; not reveal 1; a single pending start; F3 30 min on the **away** clock; F4 memory escalation | windows (AC-10), scans (AC-12), device (AC-13) | AC-1, 3, 5, 6, 7, 8, 11 |
| hint-letters-v1 | hint-letters.md | F1 pick with draws; the 0 / 0.7 / 1.4 s sequence and the gap; F4 slots and jittered clearances with the documented redraw order; F2 alpha and scale; F3 drift; outcomes and `originFor`; fading still counts; pulse; challenge, panel and Dimmed, incl. Frozen → Dimmed; background; Reduce Motion; F5 and `k` | AC-7's 10,000-minute simulation (a per-platform unit test: too large for a case file); Android insets (AC-20, a later version); the look (AC-22) | AC-1–6, 8–16, 18, 18b, 19 |
| audio-plan-v1 | audio-voice.md | E1–E12 times from formedS and hasWord (owns E6–E9); press sounds; speech never stacks; player cap; F6 `word_end` hold; F3 mash with `chime_window_s`; nothing stops on a press; F1 gain chain, mute and volume; F2 duck; fallbacks; chirp count; gate-freeze pause and resume | latency, no-click, interruptions (device); loudness (build tool); the silent-mode adapter | AC-1, 2, 4, 5, 7, 8, 10, 14, 17, 19, 21 |
| gate-logic-v1 | parent-gate-panel.md | F1 hold; a second pointer on the moon; the code from the `gate-code` stream (D4) → words; one keypad pointer, the 0.15 s lift grace, three pointers; hardware digits; the first wrong digit; the timeout and the 10 s moon sleep on the **away** clock, incl. background; lift before refill; confirm hold; auto-close, burst and the 300 s cap; Cancel/Esc | AC-04's statistics (a per-platform seeded unit test); UI, VoiceOver, Dynamic Type | AC-01, 02, 05–10, 12, 17, 18, 25, 29, 36, 37 |
| keyboard-row-v1 | onscreen-keyboard-row.md | F1 layout for n letters; F2 hit rect and size; F3 light, incl. a hardware press; F4 word draw with no immediate repeat; due / change / play entry; quiet moment; freeze; fallback | looks (AC-18); Android insets (AC-19) | AC-2, 3, 5, 7–13, 16 |

**Excluded, with reasons:**
- Child Lock-in: Apple-only; its `KidCore` state machine gets XCTest unit tests.
- Privacy & Kids Compliance: build scans (ADR-0011).
- Accessibility F1/F2: QC tools, unit-tested in `apple/Tools`.
- Cast Rendering F3: speck looks, per platform (R6).
- Cast Rendering F6: residency, which depends on ADR-0009.
- Seeds: per platform (ADR-0002 D4).
- Render-path drawing and the audio graph: per platform.

**One owner per number.** Each expected value lives in exactly one contract; another contract may use it only as an
input:
- E6–E9 times: audio-plan-v1.
- `startReveal` outputs, stage fit and boxes: reveal-timing-v1.
- Slop geometry: input-filter-v1; the gate's reaction: gate-logic-v1.
- `rowWords` validity (V17): key-table-schema-v1; the word draw: keyboard-row-v1.

### D2. Random streams used by contracts

ADR-0002 D4 gives each stream its own `RandomSource`, and its list is not closed. ADR-0004 names the two streams
that D4 leaves unnamed, under the same per-stream rule:

| Stream | Draws | Owner GDD | Contract |
|---|---|---|---|
| `key-variety` | the item pick (§4) | key-table-theme-data.md | key-table-schema-v1 |
| `hints` | key, slot order, jitter, life, phase, in R5's documented order | hint-letters.md | hint-letters-v1 |
| `keyboard-row` | the word pick (F4) | onscreen-keyboard-row.md | keyboard-row-v1 |
| `morph-seed` | the seed from (key, revealId) | morphcore.md | morph-contract-v1 (its own SplitMix64) |
| **`gate-code`** (new) | the four digits, one draw each (G3) | parent-gate-panel.md | gate-logic-v1 |
| **`scene-weather`** (new) | rain and snow spawn x, per-flake fall speed (F3) | scene-time-weather.md | scene-look-v1 |

### D3. Harness layers

The code under test for each case must run inside the harness that runs it.
- **settings-record-v1:** the canonical writer and reader are hand-written String/UTF-8 code in `KidCore`:
  - UTF-8, sorted keys, no whitespace, integers written as numbers;
  - no JSON library, which D2 forbids anyway.
  All cases (bytes → record, record → bytes, compared byte for byte) run in the `KidCore` harness. Kotlin mirrors
  the reader and writer one-to-one.
- **key-table-schema-v1:** each case carries `layer`.
  - `"model"`: a decoded model → validator verdict, pick, peek or the u helper. Runs in the `KidCore` harness.
  - `"file"`: theme-file bytes → the decoded model, or a decode error. Runs in a test target in `apple/Tools`, which
    reads the same `cases.json` and uses Tools' decoder.
  Each harness runs only its own layer and reports a count per layer. A layer with 0 cases where `spec.md` says it
  has some is a FAIL.
- **morph-contract-v1:** `MorphCore`.
- **Every other contract:** `KidCore`.
- Every `spec.md` names its layer(s) and the code under test.

### D4. The case-file schema

`contracts/case-schema-v1.md` defines the file. It is a written spec, not a JSON Schema document: PKC-03(a) allows
no remote package pins, even in test targets, so no third-party schema validator is used.
- **Enforcement is a strict structural check, hand-written in each harness.** The harness parses the file with the
  platform's own JSON parser (`JSONSerialization` in the Apple test targets), then walks every object against
  `case-schema-v1.md`'s tables of allowed and required keys and value kinds. It applies every FAIL rule below
  before decoding into typed case structs, so a key the typed decoder would silently ignore still FAILs.
- The Kotlin harness implements the same check by hand (ADR-0012 picks its JSON parser).
- A schema error is a FAIL, raised before any case runs.
- **Self-test:** every rule in `case-schema-v1.md` has a negative fixture in the harness's own tests that must
  FAIL (Validation Criteria 4). A rule added to the spec without its negative fixture is REVISE at review.

```
{ "contract": "press-queue-v1", "schema": 1, "uint64AsString": true,
  "units": { "time": "s", "space": "stage units" },
  "tolerance": { "time": 1e-9, "geometry": 1e-6 },            // per field kind; see rules
  "streams": ["hints"],                                      // consumption order documented in spec.md
  "cases": [ {
    "id": "F1-word-extends-hold",                            // stable, unique in the file
    "source": "gdd: press-queue.md F1",                      // or "generated"
    "layer": "model",                                        // key-table-schema only
    "note": "free text",
    "given": { "displayMetrics": { "windowPx": [2388, 1668], "pxPerPt": 2, "safeAreaInsetsPx": [0,0,0,0],
                                   "ppiX": 264, "ppiY": 264, "gestureInsetsPx": [0,0,0,0] },
               "accessibility": { "reduceMotion": false, "guidedAccessEnabled": false },
               "settings": { … } | "settingsBytes": "<UTF-8 text>",
               "uptime": 0.0, "away": 0.0, "wall": { "minutesOfDay": 600.0, "dayKey": 20261118 },
               "knobs": { … }, "state": { … } },
    "draws": { "hints": ["9007199254740993", "…"] },
    "steps": [ { "t": { "uptime": 1.25 },
                 "event": { "type": "key", "kind": "down", "character": "D", "positionKey": "D",
                            "modifiers": 0, "isRepeat": false, "physicalId": "k4" },
                 "expect": [ { "out": "press", "key": "D", "source": "hardware" },
                             { "out": "started", "revealId": 1 } ],
                 "expectState": { … } } ],
    "expect": { … },
    "tolerance": { "outputs[1].at": 1e-6 }, "toleranceReason": "gdd: … / ADR-…"
  } ] }
```

**Event types** (a closed list in the schema; each runner states which it accepts, and any other is a FAIL):

| Group | Types |
|---|---|
| Input (ADR-0002 D5) | `key` (kind `down`, `up`, `cancel`, `modifiersChanged`), `touch` |
| Frames | `tick` (the uptime value comes from `t`) |
| Freeze chain (D7.2) | `freeze`, `resume`, `settle` |
| Panel | `panelOpen`, `panelClose` |
| AppLifecycle (D6) | `foreground`, `background`, `active`, `inactive`, `windowKeyGained`, `windowKeyLost`, `screenChanged`, `memoryWarning` |
| Launch and lock (D7.3) | `ready`, `kioskModeOnSet`, `kioskModeOnCleared`, `themeReady` |
| Settings | `settingsChanged` (the whole record) |
| Seam changes | `displayMetricsChanged`, `accessibilityChanged` |
| Contract-local | entry points such as `press`, `startReveal`, `shown`, each declared in that contract's `spec.md` |

**Rules:**
- **`expect` is an ordered list** of emitted outputs, compared for exact sequence and count, never as a set.
  `expectState` (optional) checks the state after the step.
- **One time per step.** A step's time is `t.uptime`. Events carry no `time` field: the harness fills D5's
  `KeyEvent.time` / `TouchEvent.time` from `t.uptime`, and an event `time` in a case is a schema FAIL.
- **The play clock is never given.** Cases give `uptime` (and `away` or `wall` where named) plus `freeze`, `resume`
  and `settle` events, and assert the play-clock results (play times in outputs, `s`, ages). A `play` field in `t`
  or `given` is a schema FAIL.
- **Each runner states the `given` fields it reads.** An unknown field is a FAIL.
- **Draws are raw `UInt64` decimal strings** (rule (e)), handed out in order by a test `RandomSource` for each
  stream. The core converts them with ADR-0002 D4's u helper, the one used in production. A precomputed `u` in a case
  is a schema FAIL; a readable value belongs in `note`. **A case that runs out of draws, or ends with draws left, is a
  FAIL**, which proves the documented consumption order. This refines the example in architecture.md rule (f).
- **Tolerances are per field.** The file sets defaults by field kind, from rule (g): time 1e-9 s, geometry in stage or
  unit space 1e-6, morph positions 1e-3. Integers, strings, booleans and bytes are exact. A case may override a field
  path only with a `toleranceReason` citing a GDD or an ADR; without one it is a schema FAIL.
- **Order independence** (ADR-0002 D2): a case may name `"permute": ["<input list path>"]`. The harness then runs
  every permutation (at most 720; a larger list must state a deterministic subset in `spec.md`), and each must give
  the same `expect`.
- **Sources:** a hand-written case's `source` is `"gdd: <file> <section>"` (rule (a)). A generated case says
  `"generated"`, comes on top of the hand-written ones, and is reviewed once (rule (b)).

### D5. The harness

**Apple** (`apple/KidCore/Tests/ContractTests`, a test target; JSON decoding is allowed there):
- `ContractHarness` finds `games/kid-learn-character/contracts/` by walking up from the test file's `#filePath`.
  SwiftPM resources cannot sit outside the package, and CI is local (K-28).
- It enumerates every `*-v*/cases.json` (and `cases-generated.json` where present), runs the strict structural
  check (D4) on each, and then runs each file through the runner registered for that contract name.
- **FAIL, never a skip:**
  - a contract directory with no registered runner;
  - a runner whose file has 0 cases;
  - a `cases-generated.json` that is present but has 0 cases (absent is fine). Hand-written and generated counts
    are reported separately;
  - an unreadable or invalid file;
  - a layer with 0 cases where `spec.md` lists cases for it (D3).
- *Note 2026-11-18 (K-40, TASK-079 S2; status stays Accepted):* contracts are written before their code, so a
  contract may be **accepted but not started**. `contracts/README.md`'s `## Registry` table is the only list: every
  `*-v*/` directory has exactly one row, `runner: <Name>[ + <Name>]`, `not-started: <story id>` or
  `superseded-by: <contract-vN+1>`, with its declared case count. The harnesses keep no list of their own.
  - **Every** cases.json is structure-checked (case-schema-v1; a not-started contract gets the generic rules, since
    its `spec.md` declarations have no runner yet), and its case count must equal the row's. Reported on its own line:
    `structure: <ok>/<all> contracts OK (<n> cases well-formed)`.
  - The result line is separate: `contracts: <a> run PASS (…), <b> NOT ASSESSED (not-started: …), <c> SUPERSEDED,
    <d> FAIL`. A not-started contract reads `NOT ASSESSED <contract>: not started (story <id>); structure OK, 0 of <n>
    cases run`; a superseded one `SUPERSEDED <contract> → <next>: not run (<n> cases)`. Neither is ever PASS.
  - **FAIL**, besides this section's list: a directory with no row; a row with no directory; a case count other than
    the declared one; a not-started row with a registered runner, or whose story is Done (a `production/` story file
    naming the id with `Status: Done`); a superseded row whose target has no directory or no runner / not-started
    row, whose runner is still registered, or that code under `apple/*/Sources` cites.
  - **Gates:** `verify.sh --release` (every release candidate) FAILs while any row is not-started; so does the
    Production gate. **`/story-done` must refuse to close a system's story while its contract is not-started:** that
    check belongs to the studio skill, not the harness (routed by the leader).
  - Story ids are placeholders (`story:<system>`) until /create-epics and /create-stories exist.
- Each case runs in its own `XCTContext.runActivity` named `<contract>/<caseId>`. A failure reads:
  `<contract>/<caseId> [<source>] <field path>: expected E, got A (tol T)`.
  The run ends with a pass/fail count per contract (and per layer).
- `MorphCore`'s existing fixture test keeps running in `apple/MorphCore/Tests` and is listed in the README.
- `apple/Tools` has its own test target for key-table-schema-v1's `"file"` layer, with the same discovery and
  failure format.

**Kotlin** (ADR-0012; **NOT ASSESSED** until an Android build exists):
- JUnit 5 `@TestFactory` in the `kidcore` and `morphcore` test source sets, with dynamic tests named
  `<contract>/<caseId>`.
- It reads the same directory through a `contracts.dir` Gradle property, with the same schema check, failure format
  and no-skip rules.

**When results disagree** (platform vs platform, or code vs case), **the GDD decides** (rule (c)). Either the code is
fixed, or the case is corrected in a version bump citing the GDD section. A tolerance is never loosened to make a run
pass without a GDD or ADR reason.

### D6. Versioning and GDD drift

- **`<name>-vN/` is immutable once merged.** Any change to `spec.md`'s rules or to `cases.json` (a case added,
  removed or changed) creates `<name>-v(N+1)/` (rule (d)). The README names the current version.
- The previous version directory is removed once every existing platform passes the new one (today, Apple), and the
  README records the removal.
- morph-contract-v1 keeps its own rule: a v2 only.
- **`sources.lock`**: when a version is cut, it records the `Reviewed-Section-Hash` lines from
  `.claude/scripts/review-receipts.sh sections-hash <gdd>`, kept only for the `##` sections the cases cite.
- **`tools/contracts/source-drift.sh`** runs `sections-check` for every contract and prints observations only: the
  contracts whose cited section has changed since their version was cut. It never gives a verdict (CLAUDE.md:
  helpers emit observations).
  - The granularity is `##`, the script's unit (for example Formulas, Acceptance Criteria, Detailed Design). An F1
    edit therefore flags every contract citing that GDD's Formulas. That's coarser than one F-row, but nothing slips
    through. A case's `source` still names the row.
- **Review rule:** a PR that changes a GDD section listed in any `sources.lock` must say, in that GDD's review-log
  entry, `fixture: <contract>-v(N+1)` or `fixture: none (<reason>)` for each flagged contract. The QC reviewer runs
  the helper and checks that every flagged contract has its line. A PR missing a line is REVISE.

### D7. Who writes and who runs

- **Writing:** QC (game-qc-ios or game-qc-android) writes the hand-written cases from the GDDs, independently of the
  implementer. The system's dev reviews them. The dev may propose generated cases; QC reviews those once.
- **Running** (local CI, K-28):
  - A dev runs `swift test` for the package they touch before opening a PR.
  - QC runs the full `swift test` for `KidCore`, `MorphCore` and the `apple/Tools` tests, under the leader's MAC
    FREE. This happens on every PR touching `apple/KidCore`, `apple/MorphCore`, `apple/Tools`, `contracts/`,
    `content/fixtures/`, or a GDD section in any `sources.lock`.
  - QC posts a results table (contract, cases, pass, fail, failing case ids) on the PR. Any FAIL blocks the merge.
- **Android later:** QC runs `./gradlew :kidcore:test :morphcore:test` the same way (ADR-0012).
- ADR-0011 owns the rest of CI: `xcodebuild`, the PKC scans, content validation in the build, and GitHub runners
  later.

### D8. Fixture work plan

1. **The scaffold story** (architecture.md check (c)):
   - `contracts/README.md`, including the morph pointer;
   - `contracts/case-schema-v1.md` and the harness's structural check;
   - `ContractHarness`, plus the empty runner registry;
   - morph-contract-v1 passing within ±1e-3;
   - the harness self-test (Validation Criteria 2–3).
2. **Next, before the ADR-0003 and ADR-0005 stories:** key-table-schema-v1 (both layers) and settings-record-v1.
3. **Then each system's story lands its contract cases first** (test-first, by QC; D7). The story is done when its
   contract passes. The MVP order: input-filter-v1, press-queue-v1, reveal-timing-v1, audio-plan-v1,
   hint-letters-v1, parade-v1, gate-logic-v1, app-shell-v1. Then the Vertical Slice: scene-look-v1, keyboard-row-v1.
4. **Generated cases** come only after a contract's hand-written cases pass, reviewed once.

### Architecture Diagram

```
 design/gdd/*.md (F-tables, ACs) ──QC writes──▶ contracts/<name>-vN/{spec.md, cases.json, sources.lock}
        │                                              │ (case-schema-v1.md)  
        │ sections-hash                                ├──▶ apple/KidCore/Tests/ContractTests ──▶ KidCore
        ▼                                              ├──▶ apple/Tools tests (key-table "file") ──▶ Tools decoder
 tools/contracts/source-drift.sh (observations)        ├──▶ apple/MorphCore/Tests (morph-contract-v1) ──▶ MorphCore
                                                       └──▶ (later) kidcore / morphcore JUnit 5 ──▶ Kotlin cores
```

### Key Interfaces

- `contracts/case-schema-v1.md`: the file format of D4, enforced by each harness's strict structural check.
- `ContractHarness` (test target): `register(contract: String, runner: ContractRunner)`, `runAll()`.
- `ContractRunner`: `acceptedEvents`, `givenFields`, `layers`, `run(case) → [Output]`. Every runner calls only the
  public API of the core it tests (ADR-0002, `contracts/kidcore-api.md` / `morphcore-api.md`).
- `TestRandomSource(draws: [UInt64])`: a D4 `RandomSource` that fails the case when it runs out, and reports
  leftovers at the end.

### Implementation Guidelines

- Every number a GDD states **must** be a hand-written case with a `"gdd: …"` source. A generated case **must** be
  marked `"generated"`.
- Each expected value **must** have exactly one owning contract.
- A merged `cases.json` or `spec.md` **must never** be edited in place. Make a new `-vN`.
- The harness **must never** skip: an unknown, empty or unreadable contract is a FAIL.
- Cases **must never** carry a precomputed `u`, a `play` clock value or a seed (morph-contract-v1 excepted).
- `expect` **must** be compared as an ordered list.
- A tolerance **must never** be widened without a `toleranceReason` that cites a GDD or an ADR.
- Code under test **must** run in the harness that runs its cases. The settings bytes are written in `KidCore`; the
  key-table `"file"` layer is tested in `apple/Tools`.

## Alternatives Considered

### Alternative 1: Per-platform hand-written tests only
- **Description:** each platform writes its own unit tests from the GDDs.
- **Pros:** no shared format to design.
- **Cons:** two readings of each GDD, and nothing shows that they agree.
- **Rejection Reason:** this is exactly the failure the contracts exist to catch (architecture.md principle 2).

### Alternative 2: Fixtures generated from the Swift implementation
- **Description:** run the Swift code and record its outputs as the cases.
- **Pros:** cheap, and covers many inputs.
- **Cons:** circular on Apple (the code checks itself), and a Swift bug becomes the contract.
- **Rejection Reason:** the GDD must be the source (rule (a)). Generated cases are allowed only on top of the
  hand-written ones (rule (b)).

### Alternative 3: Seeds instead of draw lists
- **Description:** cases give each stream's seed, and both platforms implement the same generator.
- **Pros:** shorter case files.
- **Cons:** it ties every platform to one generator, and one extra draw shifts every later value without saying why.
- **Rejection Reason:** ADR-0002 D4 keeps seeding per platform. Draw lists with exhaustion checks prove the
  consumption order. Only morph-contract-v1 keeps SplitMix64, because its contract specifies the generator.

## Consequences

### Positive
- One machine-readable source of truth per system, traceable to a GDD row.
- The Kotlin port gets a ready acceptance suite.
- A GDD number change cannot pass review unnoticed.
- The chains (clocks, freeze/settle, `kioskModeOn`) are tested as ordered event sequences, not as isolated calls.

### Negative
- QC must write the cases before each system story, which is real authoring work on the critical path.
- Every case change needs a version directory, so the files churn while systems are young.
- `sources.lock` works at `##` granularity, so some flags will be false positives (an F2 edit flags F1's contract).

### Neutral
- The `apple/Tools` test target exists because of key-table-schema-v1's `"file"` layer.

## Risks

- **The case files grow large:** hint-letters and gate-logic have many ACs. Mitigation: generated cases go in the
  optional `cases-generated.json` (D1), under the same schema and version, so reviews of the hand-written file stay
  small.
- **`#filePath` walk-up breaks if the repo layout changes.** Mitigation: the harness fails loudly with the path it
  tried (self-test 3), and ADR-0011 may later pass an explicit path.
- **The two new streams (D2) change the gate and scene code:** both GDDs said "seeded", but neither named a stream.
  Mitigation: the registry lists both as `random_source` consumers. Their contracts are written test-first at the
  start of each system's story (D8), and the stream is built in the same story.
- **The Kotlin harness is unverified:** it is NOT ASSESSED until ADR-0012.
- **Engine validation: NOT ASSESSED** (`engine.name` unset in `project.yaml`, ADR-0001). The native-apple reference
  folder covers only `swift test`, not harness specifics. TD-ADR was skipped (lean review mode): game-dev-ios's
  independent read stands in for it.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| morphcore.md | positions within ±1e-3 on every platform | morph-contract-v1, unchanged, in the harness |
| key-table-theme-data.md | V1–V17, the §4 pick, u from UInt64, V17 rowWords | key-table-schema-v1, model and file layers |
| settings-store.md | the same bytes on both platforms; F1, F2; run-only OFF (R8) | settings-record-v1, with the writer and reader in KidCore |
| input-key-filter.md | AC-1j, 1k, k2–k5; F1, F2 | input-filter-v1, with typed `key`/`touch` events and `KeyStateQuery` both ways |
| press-queue.md | F1–F5; the gate freeze; hasWord | press-queue-v1 |
| reveal-stage.md, cast-rendering.md | startReveal, stage fit, cooldown, play clock; CR F1, F2, F4, F5, F7 | reveal-timing-v1 |
| scene-time-weather.md, cast-rendering.md F8 | look, lookBlend, skyMidL, edge switch (K-25), counts, lift, F3 weather | scene-look-v1, with the `scene-weather` stream |
| parade.md | F1–F3, freeze, no cap | parade-v1 |
| app-shell-title.md | launch, ready set, F3 away 30 min, F4 | app-shell-v1, on the away clock |
| hint-letters.md | F1–F5, freezes, Dimmed | hint-letters-v1 |
| audio-voice.md | E1–E12, F1–F3, F6 | audio-plan-v1 |
| parent-gate-panel.md | F1, G1–G4, G8, G10, lift grace, away-clock timers | gate-logic-v1, with the `gate-code` stream |
| onscreen-keyboard-row.md | F1–F4 | keyboard-row-v1 |

## Performance Implications

- **CPU:** tests only. No runtime cost.
- **Memory:** tests only. No runtime cost.
- **Load Time:** none. Contracts are not bundled.
- **Network:** none. Local files.

## Migration Plan

None: nothing exists yet besides morph-contract-v1, which stays where it is. The scaffold story creates
`contracts/` and the harness (D8 step 1).

## Validation Criteria

1. The scaffold story's check (c): morph-contract-v1 passes within ±1e-3, and the harness picks up every
   `contracts/<name>-vN/cases.json` present.
2. **Self-test (the gate is watched failing):** each of these makes `swift test` FAIL, naming the cause:
   - a case with a wrong expected value (the message names `<contract>/<caseId>` and the field);
   - a contract directory with no runner;
   - an empty `cases.json`;
   - a case with a leftover draw;
   - a case with a `play` field;
   - an unordered `expect`.
   Each fixture is then restored.
3. With `contracts/` moved, the harness fails, printing the path it searched.
4. The structural check rejects the bad cases from 2, plus one negative fixture per `case-schema-v1.md` rule
   (an unknown key, an event `time`, a `u` field, a `play` field, a non-string UInt64, an override without
   `toleranceReason`), before any runner starts.
5. Once two contracts exist, `source-drift.sh` reports a section edit to one cited GDD, and nothing for an edit to an
   uncited section.

## Related

- ADR-0001 (stack; XCTest), ADR-0002 (types, clocks, streams, events, seams, chains), morph-contract-v1.
- `docs/architecture/architecture.md`: Cross-platform contracts, the scaffold story.
- ADR-0003 (content: uses key-table-schema-v1), ADR-0005 (settings: uses settings-record-v1), ADR-0007 (input
  adapters: input-filter-v1), ADR-0011 (CI: runs this harness), ADR-0012 (Android: the Kotlin harness).
- `.claude/scripts/review-receipts.sh` (`sections-hash`, `sections-check`).
