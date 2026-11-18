# TASK-079: the first production scaffold (plan)

> **Status:** plan for review (game-qc-ios). Nothing under `apple/` or `tools/` is written yet.
> **Author:** game-dev-android. **Date:** 2026-11-18.
> **Builds on:** ADR-0001…0006 and ADR-0011 (Accepted; ADR-0011 at fd35c14f), architecture.md "The First Scaffold
> Story" checks (a)–(f), and TASK-068's contracts (merged 12f6f474: `key-table-schema-v1`, `settings-record-v1`).
> **Out of scope:** `prototypes/` (game-dev-ios's DeviceSpike, TASK-078; the TASK-033 spike is read, never edited);
> `design/gdd/systems-index.md`; the Settings Store F1 / R7 nits (a separate small task).

## 1. Why this is staged

ADR-0004 D5 makes the harness **FAIL, never skip**, on a contract directory with no registered runner. Two contracts
are already in `contracts/`, so the moment the harness reads that folder it needs real runners for
`settings-record-v1` and both layers of `key-table-schema-v1`, which means real `KidCore` code (the canonical settings
record, the Key Table models, validator and pick). The scaffold therefore lands in **three steps on one branch**, each
green on its own (`verify.sh` passes at every step):

| Step | Lands | Ends with |
|---|---|---|
| **S1. Skeleton and gates** | packages, app targets, ban grep, API surface, `verify.sh`, `pkc-scan.sh --static`, the simulator guards, the privacy-manifest skeleton, the blank Title | `verify.sh` green; Title screenshot (headless) |
| **S2. Harness + settings-record-v1** | `ContractHarness` with the D4 structural check and self-tests; MorphCore's fixture; the `settings-record-v1` runner and the `KidCore` canonical record | 73 / 73 settings cases pass |
| **S3. key-table-schema-v1 + validator stub** | the Key Table models, V1–V18, the pick and peek in `KidCore`; the Tools decoder ("file" layer); the Tools validator CLI and the ADR-0003 staleness check (stub) | both layers pass; validator stub runs in `verify.sh` |

The harness registry is wired to `contracts/` only in S2, together with the first runner, so S1 never reads a
contract it cannot run. (If the leader prefers three separate stories, the same steps split cleanly: Q1.)

## 2. The pieces

Each piece lists **what lands**, **the headless proof** (K-34: `swift test`, `xcodebuild build`, tests and
`simctl` on the developer's simulator booted headless, at nice 10 under the load cap), and **what waits for MAC FREE**
(anything that takes the Mac's screen, keyboard or focus, Simulator windows included). All paths are under
`games/kid-learn-character/`.

### P1. Packages and dependency direction (S1; ADR-0002 D1)
- **Lands:**
  - `apple/MorphCore/` (Swift package): the TASK-033 MorphCore sources **copied** (not moved; the prototype stays as
    it is) into a fresh package, plus its fixture test reading `content/fixtures/morph-contract-v1.json`. The two
    spike executables (`morph-fixture`, `morph-contract-fixture`) are not copied (the fixture never changes, ADR-0003
    D4).
  - `apple/KidCore/` (Swift package, depends on MorphCore only): an empty public namespace plus the ADR-0002 helpers
    `asciiUppercased`, `asciiLetters`, `scalarCount`, `roundHalfAwayFromZero`, the `u` helper, and the D6 seam
    protocols (names only, no implementations).
  - `apple/Tools/` (Swift package, depends on both, macOS only): an empty CLI target `kidtools` and a test target.
- **Headless proof:** `swift test` for each package; `swift package show-dependencies` shows MorphCore ← KidCore ←
  Tools and nothing else; a test asserts `roundHalfAwayFromZero` on ADR-0002 Validation 2's cases (2.5 → 3, −2.5 → −3,
  7.5 → 8, 0.5 → 1) and the Settings F1 slider cases.
- **MAC FREE:** none.

### P2. The app targets (S1; ADR-0001, ADR-0006 D1–D4, App Shell R1)
- **Lands:** `apple/<App>.xcodeproj` with **one multiplatform app target** (iPadOS + macOS, deployment **26**), the
  local package references (KidCore, MorphCore; no remote package, PKC-03(a)), `<App>Tests` and `<App>UITests`. The
  app shows the **blank Title** (ADR-0006 D1: one `SKView` per window, the stage root with the fixed layers, an empty
  render plan; the Dusk launch colour `#46558f`). macOS: App Sandbox on, no network entitlement; the
  `CODE_SIGN_ENTITLEMENTS` file equals the PKC-01 allowlist. `UIRequiresFullScreen` not set (ADR-0006 D4).
  `PrivacyInfo.xcprivacy` skeleton: `NSPrivacyTracking` false, empty domains and data types, `UserDefaults` /
  **CA92.1** and `SystemBootTime` / **35F9.1** (the uptime clock adapter calls `ProcessInfo.systemUptime`;
  architecture check (e)).
- **The project file:** hand-written, modelled on the TASK-033 spike's `Spike.xcodeproj` (read, not edited; no
  XcodeGen or other tool, K-31). **NOT SOURCEABLE** until it builds: whether one multiplatform target with
  `SUPPORTED_PLATFORMS = iphoneos iphonesimulator macosx` builds clean on Xcode 27.1; the fallback is two targets
  sharing sources.
- **Headless proof:** `xcodebuild build` for `platform=macOS` and `xcodebuild test` on the dev simulator
  (`--dev`, booted with `simctl`, no window); the unit test target runs one launch-free test.
- **Title screenshot (architecture check (f), ADR-0011 D6):** `xcrun simctl launch <dev sim> <bundle id>` then
  `xcrun simctl io <dev sim> screenshot production/qa/evidence/TASK-079/<short-sha>/title.png` on the **headless** dev
  simulator. This takes no screen or focus (K-34). Observed and retained per `.claude/docs/run-and-observe.md`.
- **MAC FREE:** launching the **macOS** app (its Title screenshot) and the macOS UI tests. Planned as one short MAC
  FREE slot at the end of S1; the macOS Title is NOT ASSESSED until then.

### P3. The ADR-0002 ban grep and the API surface (S1)
- **Lands:** `tools/ci/ban-grep.sh` with ADR-0002 Validation 1's exact patterns over `apple/KidCore/Sources` and
  `apple/MorphCore/Sources` (imports; `Date`, `Calendar`, `Decimal`, `Duration`, `DispatchTime`, `UUID`; JSON coding;
  `Character`, `Float`, `CGFloat`, `Int32`, `Int8`; `UInt64` outside its allowed files; `key.count` /
  `character.count` / `word.count`; locale case mapping; unpinned rounding), printing file:line. A Tools command
  `kidtools api-surface` writes `contracts/kidcore-api.md` and `contracts/morphcore-api.md` from the symbol graph
  (`swift package dump-symbol-graph`), committed.
- **Headless proof:** ADR-0002 Validation 1 and 4: planted `Date`, `import UIKit` and `Character` each fail, the clean
  tree passes; a public signature change without regenerating fails the staleness check.
- **MAC FREE:** none.

### P4. `tools/ci/verify.sh` (S1; ADR-0011 D1–D4)
- **Lands:** the gates in D4's order (ban grep → API surface → content (S3) → `swift test` ×3 → bundle scan only
  with `--app <path>`), one summary line per gate, `verify.txt` into the evidence folder, `nice -n 10`, a per-worktree
  `-derivedDataPath`, a load check that stops above ~40, daemons stopped at the end.
- **Simulator guards (ADR-0011 D3):** `--dev` reads `DEV_SIM_UDID` from the untracked `tools/dev/apple/sim.env`
  and refuses QC's `E9F515E9…`; `--qc` reads `QC_SIM_UDID` from `tools/qa/apple/sim.env` and refuses any other;
  both refuse an empty value. `sim.env.example` files are committed.
- **Headless proof:** ADR-0011 Validation 1 (each gate fails on its planted break), 3 (the guards), 5 (a headless
  `xcodebuild test` with no Simulator window), 6 (nice 10 and the load stop).
- **MAC FREE:** none.

### P5. `tools/ci/pkc-scan.sh --static` (S1; ADR-0011 D5)
- **Lands:** the static sections for PKC-01…06, 08, 09, 12, 14 as `OBSERVED <pkc-id> <tool> <finding>` lines, exit 0
  unless a tool fails; the two-pass whole-name API scan (`nm -um`; `otool -ov` + `strings -a`); the
  `CODE_SIGN_ENTITLEMENTS` comparison; `OBSERVED PKC-01 codesign unsigned` for an unsigned product. `--runtime` is a
  stub that prints "runtime rows: see device-checks plan M-8, M-11, P-5, S-2" and exits 0.
- **The fixture binary for the API scan (ADR-0011 Validation 7):** `tools/ci/scan-fixture/`, a tiny macOS command
  line program that references every API named in PKC-01…12 and their Edge Cases (never run, only built), so the scan
  is proven before its first use. Built with `swiftc` headless.
- **Signed products:** the Release builds (`generic/platform=iOS` and `platform=macOS`) are built with
  `CODE_SIGNING_ALLOWED=NO` and then **ad-hoc signed with the entitlements applied** (`codesign -s - --entitlements
  <file>`), because an iOS device build cannot ad-hoc sign through Xcode without a team. NOT SOURCEABLE until run;
  the fallback is the Personal Team (K-28), which needs Luan's Apple ID in Xcode (Q3).
- **Headless proof:** ADR-0011 Validation 2 (a planted `URLSession` prints an OBSERVED line, exit 0), 7 (the fixture
  binary lists every API, and `status` does not match `stat`), 8 (unsigned is reported); the scaffold's own
  evidence `pkc-scan.txt` for both `.app`s, and a `pkc-verdict.md` filled by QC.
- **MAC FREE:** none for `--static`. The runtime rows wait for the release-candidate sessions (not this task).

### P6. The ADR-0004 contract harness (S2)
- **Lands:** `apple/KidCore/Tests/ContractTests` with `ContractHarness`: discovery from `#filePath` up to
  `contracts/`; the D4 strict structural check against `case-schema-v1.md` (hand-written, `JSONSerialization`, every
  rule S1–S18 with its negative fixture); the runner registry; FAIL-never-skip; per-contract and per-layer counts;
  the `<contract>/<caseId> [<source>] <field>: expected E, got A (tol T)` message. MorphCore's fixture test stays in
  `apple/MorphCore/Tests` (ADR-0004 D5).
- **First runner: settings-record-v1.** `KidCore` gets the **canonical record** (Settings Store R1, R4–R10, R6a):
  the hand-written reader and writer (sorted keys, no whitespace, minimal escaping, every JSON number token, NaN and
  duplicate keys unreadable), validation per field, migration, `childLockActive`, Reset, notifications, F1 and F2,
  behind `SettingsBackend` (an in-memory fake in tests). No UserDefaults code here (that is the app's, ADR-0005).
- **Headless proof:** `swift test --package-path apple/KidCore`: **73 / 73** settings cases; ADR-0004 Validation 2's
  self-tests (a wrong expected value, a directory with no runner, an empty file, a leftover draw, a `play` field, an
  unordered `expect`) each FAIL with their cause; morph-contract-v1 within ±1e-3.
- **MAC FREE:** none.

### P7. key-table-schema-v1 and the ADR-0003 validator stub (S3)
- **Lands:**
  - `KidCore`: the plain models (ADR-0003 D7), the V1–V18 rules as pure functions over the models and a
    `ContentProbe` (ADR-0003 D3), the §4 pick and peek with an injected `RandomSource`, the `u` helper; the
    `"model"`-layer runner.
  - `Tools`: the theme-file decoder (`JSONSerialization` → models; unknown and missing fields are decode errors, V1)
    and the `"file"`-layer runner in `apple/Tools/Tests`.
  - **The validator stub:** `kidtools validate <content dir>` runs the `KidCore` V-rules with a file-system probe
    (exact case), plus a **staleness stub**: it checks that every baked file named by a theme exists and that its
    source exists by the stem rule; byte-for-byte re-bake waits for the bake tool story (ADR-0003 D4). With no theme
    yet in `content/themes/`, it reports "0 themes" and passes; a test theme in its own test target proves it.
  - **SVG layer-id rule (a1) for the bake tool (agreed with game-dev-ios, see §4):** recorded in the stub's README and
    the bake-tool story; the stub does not parse SVG yet.
- **Headless proof:** `swift test` for KidCore (model layer) and Tools (file layer): every `key-table-schema-v1` case
  passes, counts reported per layer; `verify.sh` step 3 runs `kidtools validate` and fails on a planted wrong-case
  path and on a missing source.
- **MAC FREE:** none.

## 3. What waits for MAC FREE, all in one place
| Item | Why | When |
|---|---|---|
| The macOS app launch and its Title screenshot | takes the Mac's screen and focus (K-34) | one short slot at the end of S1 |
| macOS UI tests (`<App>UITests` on macOS) | the same | the same slot |
| Runtime PKC rows (PKC-01c, 05, 14) | ADR-0011 D2 | release-candidate sessions (device-checks plan), not this task |
| Any Simulator **window** | K-34 | never needed here: every simulator step is headless |

## 4. The SVG layer-id rule (for the validator stub and the bake tool)
TASK-077 found that nested parts make `id="body"` etc. non-unique. **Agreed with game-dev-ios: option (a1), the layer
comes from the id suffix.**
- A part group's id is its part name, `[a-z]+(_[a-z]+)*` (for example `root`, `neck`, `wing_far`); the three
  segments `body`, `outline` and `detail` are **reserved** and never appear in a part name.
- Its layer groups are `<part>_body`, `<part>_outline` and `<part>_detail` (`root_body`, `wing_far_outline`,
  `jaw_detail`): the layer is the **last** `_`-segment, and the rest must equal the enclosing part's id (the nearest
  part `g`, the one with `data-pivot`, or the root).
- The bake fails, naming the line, if a part lacks exactly one of each layer, if a prefix differs from its part's
  id, if a part name uses a reserved segment, or on any other last segment.
- This stays inside ADR-0003 D4's "`id` (part and layer names)", but D4's structure clause reads as literal ids, so
  game-dev-ios and I recommend a **one-line dated clarification note in ADR-0003 D4** (and the art bible §8), for the
  leader to take to Luan. No art changes: TASK-077's ids already follow it.

## 5. Evidence
`production/qa/evidence/TASK-079/<short-sha>/`: `verify.txt`, `pkc-scan.txt` (both `.app`s), `pkc-verdict.md` (QC),
`title.png` (the iPad Title on the dev simulator), and after the MAC FREE slot `title-macos.png`.

## 6. Questions
- **Q1 (leader):** one branch in three green steps (proposed), or three stories (TASK-079a/b/c)?
- **Q2 (Luan, via the leader):** the app's target and bundle names. K-04 (the game's name) is open. Proposal: target
  `LetterMorph` (the working title) and bundle id `<reverse-domain>.lettermorph`, with the reverse domain Luan's.
- **Q3 (Luan, via the leader):** for the signed scan products, is ad-hoc signing enough for now (proposed), or should
  the Personal Team be set up in Xcode for this task?
- **Q4 (leader, then Luan):** the ADR-0003 D4 clarification note for option (a1) (§4), agreed by game-dev-ios and me.
