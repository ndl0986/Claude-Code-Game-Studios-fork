# TASK-079: the first production scaffold (plan)

> **Status:** plan v2 for review (game-qc-ios's six items and the minor one; Luan's K-37 answers). Nothing under
> `apple/` or `tools/` is written yet. One branch, reviewed at each step boundary (leader, TASK-079 Q1).
> **Author:** game-dev-android. **Date:** 2026-11-18.
> **Builds on:** ADR-0001…0006 and ADR-0011 (Accepted; ADR-0011 at fd35c14f), architecture.md "The First Scaffold
> Story" checks (a)–(f), and TASK-068's contracts (merged 12f6f474: `key-table-schema-v1`, `settings-record-v1`).
> **Out of scope:** `prototypes/` (game-dev-ios's DeviceSpike, TASK-078; the TASK-033 spike is read, never edited);
> `design/gdd/systems-index.md`; the Settings Store F1 / R7 nits (a separate small task).

## 1. Why this is staged (two steps)

ADR-0004 D5 makes the harness **FAIL, never skip**, on a contract directory with no registered runner, and two
contracts already exist. So the harness, both contracts' runners and both layers arrive **together** (game-qc-ios
item 1, option (a): the former S2 and S3 are merged). One branch, reviewed at each step boundary:

| Step | Lands | Ends with | Merge candidate? |
|---|---|---|---|
| **S1. Skeleton and gates** | packages, app targets, signing, ban grep, API surface, `verify.sh`, `pkc-scan.sh --static` with its two proven fixtures, the simulator guards, the privacy-manifest skeleton, the blank Title | `verify.sh` green **with one observation line**: `OBSERVED contracts: harness not wired until S2, 2 contracts unrun` (item 6); the iPad Title screenshot (headless) | **No** (item 6): reviewed at the boundary, never merged alone |
| **S2. Harness, both contracts, validator stub** | `ContractHarness` (D4 strict check, self-tests); the `settings-record-v1` runner and the canonical record; the `key-table-schema-v1` model layer in KidCore and file layer in Tools; the validator stub; MorphCore's fixture | every case of both contracts passes; `verify.sh` green with no observation line | **Yes**: the only merge candidate; QC evidence is for its final commit |

**Who owns which layer's count** (item 1):
- **KidCore harness** (`apple/KidCore/Tests/ContractTests`): all of `settings-record-v1`, and `key-table-schema-v1`'s
  `"model"` layer.
- **Tools harness** (`apple/Tools/Tests/ContractTests`): `key-table-schema-v1`'s `"file"` layer.
- Each harness checks **"0 cases where `spec.md` lists cases"** only for the layers it owns. The KidCore harness's
  registry also records "`key-table-schema-v1/file` → Tools harness", so no contract directory is ever without an
  owner, and the Tools harness FAILs if its own layer has 0 cases. Neither harness skips anything.
- The shared discovery and structural check live in **one test-support package, `apple/ContractKit`** (JSON allowed,
  not a core, never linked into the app), used by both test targets. It is outside the ban grep, which covers
  `KidCore/Sources` and `MorphCore/Sources` only. (ADR-0002 D1 lists four packages; a test-only package is the
  leader's call, Q5. The fallback is a duplicated harness file in Tools' test target.)

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
- **Lands:** `apple/LetterMorph.xcodeproj` with **one multiplatform app target `LetterMorph`** (iPadOS + macOS,
  deployment **26**), the local package references (KidCore, MorphCore; no remote package, PKC-03(a)),
  `LetterMorphTests` and `LetterMorphUITests`. **Bundle ids (K-37 Q2, the previous game's pattern):**
  `com.galaxyandsun.lettermorph`, `.tests`, `.uitests`, and `.preview` for a preview configuration. LetterMorph is a
  working name until K-04 and may change before the first store upload. *(2026-11-20, TASK-130: K-04 named the
  game **Letterlings**; the bundle ids are now `com.galaxyandsun.letterlings`, `.tests`, `.uitests`, `.preview`, and
  `CFBundleDisplayName` is "Letterlings"; the app's `PRODUCT_NAME` is `Letterlings` (so `Letterlings.app` and the
  macOS menu-bar name) with `PRODUCT_MODULE_NAME = LetterMorph`. The target, scheme and folder names stay `LetterMorph`. The TASK-079
  evidence logs keep the old id as recorded.)* The
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
- **Signing (K-37 Q3):** **automatic signing with Luan's Personal Team**, already signed in to Xcode. The team id
  lives only in an **untracked** `apple/Config/Signing.local.xcconfig` (`DEVELOPMENT_TEAM = …`), pulled in by the
  committed `apple/Config/Shared.xcconfig` with an optional include (`#include? "Signing.local.xcconfig"`); a
  committed `Signing.local.xcconfig.example` shows the one line, and a game-level `.gitignore` ignores
  `apple/Config/*.local.xcconfig`. Headless builds pass `-allowProvisioningUpdates`. **The first signed build runs in
  the MAC FREE slot**, in case Xcode or the keychain shows a dialog; later signed builds are headless.
- **Test hosts (item 4):** `LetterMorphTests` is **hostless on macOS** (no `TEST_HOST`, no `BUNDLE_LOADER`), so a
  macOS unit run never launches the app or takes focus (K-34); on iPadOS it is hosted on the headless dev simulator.
  Anything that needs the macOS app running (hosted macOS tests, `LetterMorphUITests` on macOS) is in the MAC FREE
  slot.
- **Headless proof:** `xcodebuild build` for `platform=macOS`; `xcodebuild test` for `platform=macOS` (hostless) and
  on the dev simulator (`--dev`, booted with `simctl`, no window).
- **Title screenshot (architecture check (f), ADR-0011 D6):** `xcrun simctl launch <dev sim> <bundle id>` then
  `xcrun simctl io <dev sim> screenshot production/qa/evidence/TASK-079/<short-sha>/title.png` on the **headless** dev
  simulator. This takes no screen or focus (K-34). Observed and retained per `.claude/docs/run-and-observe.md`.
- **MAC FREE:** the first signed build; launching the **macOS** app (its Title screenshot); the macOS UI tests and
  any hosted macOS test. One short MAC FREE slot at the end of S1; the macOS Title is NOT ASSESSED until then.

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
- **Lands:** the gates in D4's order (ban grep → API surface → content (S2) → `swift test` ×3 → bundle scan only
  with `--app <path>`); **in S1** the content gate is absent and `verify.sh` prints the observation line
  `OBSERVED contracts: harness not wired until S2, 2 contracts unrun` (item 6); one summary line per gate, `verify.txt` into the evidence folder, `nice -n 10`, a per-worktree
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
- **Two fixture binaries for the API scan (ADR-0011 Validation 7; item 2):** `tools/ci/scan-fixture/`, never run,
  only built headless:
  - `macos/`: a macOS command-line program referencing every macOS-reachable API named in PKC-01…12 and their Edge
    Cases (`NSWorkspace open`, `NSSharingService`, `URLSession`, `NWConnection`, `CKContainer`, …);
  - `ios/`: a tiny iOS framework built for `generic/platform=iOS`, referencing the iOS-only ones under `#if os(iOS)`
    (`UIApplication.open`, `identifierForVendor`, `UIActivityViewController`, `SKStoreReviewController`,
    `ASIdentifierManager`, `activeInputModes`, …);
  - **V7 passes only when the scan lists every named API in both fixtures** (and a planted `status` never matches
    `stat`). The proof is recorded as `scan-proof-xcode-<version>.txt` and re-run when Xcode or `pkc-scan.sh`
    changes.
- **Signed products (item 3):** the scans read the **Xcode-signed Release products** (`generic/platform=iOS` and
  `platform=macOS`, Personal Team, automatic signing), whose embedded entitlements are the **processed** ones,
  including anything Xcode adds. PKC-01 compares those **and** the `CODE_SIGN_ENTITLEMENTS` file with the allowlist.
  **If a product ever falls back to ad-hoc signing,** it is signed with the build's processed `.xcent` (never the raw
  source file, which would make the check circular), and its `pkc-verdict.md` row reads "file-based only;
  Xcode-added entitlements NOT ASSESSED", **never PASS**.
- **Headless proof:** ADR-0011 Validation 2 (a planted `URLSession` prints an OBSERVED line, exit 0), 7 (both
  fixtures), 8 (unsigned is reported). **In S1, V7 and V8 are run and recorded before the first scaffold
  `pkc-scan.txt`** (item 5), and every scan row cites the `scan-proof-xcode-<version>.txt` file.
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

### P7. key-table-schema-v1 and the ADR-0003 validator stub (S2)
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
  - **SVG layer-id rule (a1, K-37; ADR-0003 D4 note in TASK-084) for the bake tool:** recorded in the stub's README and
    the bake-tool story; the stub does not parse SVG yet.
- **Headless proof:** `swift test` for KidCore (model layer) and Tools (file layer): every `key-table-schema-v1` case
  passes, counts reported per layer; `verify.sh` step 3 runs `kidtools validate` and fails on a planted wrong-case
  path and on a missing source.
- **MAC FREE:** none.

## 3. What waits for MAC FREE, all in one place
| Item | Why | When |
|---|---|---|
| The first signed build (Personal Team) | Xcode or the keychain may show a dialog | the one short slot at the end of S1 |
| The macOS app launch and its Title screenshot | takes the Mac's screen and focus (K-34) | the same slot |
| macOS UI tests and any hosted macOS test (`LetterMorphUITests`) | the same | the same slot |
| Runtime PKC rows (PKC-01c, 05, 14) | ADR-0011 D2 | release-candidate sessions (M-8, M-11, P-5, S-2), not this task |
| Any Simulator **window** | K-34 | never needed here: every simulator step is headless |

## 4. The SVG layer-id rule (for the validator stub and the bake tool)
**Decided (K-37 Q4): option (a1)**, written into ADR-0003 D4 and the art bible §8 by game-art-content (TASK-084).
- A part group's id is its part name, `[a-z]+(_[a-z]+)*` (for example `root`, `neck`, `wing_far`); the segments
  `body`, `outline` and `detail` are **reserved** and never appear in a part name.
- Its layer groups are `<part>_body`, `<part>_outline` and `<part>_detail` (`root_body`, `wing_far_outline`,
  `jaw_detail`): the layer is the **last** `_`-segment, and the rest must equal the enclosing part's id (the nearest
  part `g`, the one with `data-pivot`, or the root).
- The bake fails, naming the element and the line, if a part lacks exactly one of each layer, if a prefix differs
  from its part's id, if a part name uses a reserved segment, or on any other last segment.

## 5. Evidence (item 5)
- **QC evidence is for the final merge-candidate commit only** (the end of S2): one folder
  `production/qa/evidence/TASK-079/<short-sha>/` with `verify.txt`, `pkc-scan.txt` (both Release `.app`s),
  **one** `pkc-verdict.md` (QC), `title.png` (the iPad Title on the dev simulator) and, after the MAC FREE slot,
  `title-macos.png`.
- **The scan proof first:** in S1, V7 (both fixtures) and V8 run and are recorded as `scan-proof-xcode-<version>.txt`
  before the first scaffold `pkc-scan.txt`; every scan row in `pkc-verdict.md` cites that file and its Xcode version.
- **Runtime rows** (PKC-01c, PKC-05's live read, PKC-14's `log stream`) read **NOT ASSESSED**, pointing to the
  device-checks plan sessions M-11 and P-5 (PKC-01c), M-8 and S-2 (PKC-05), M-11 (PKC-14).
- **A note for `pkc-verdict.md` (minor item):** `CA92.1` is declared before any `UserDefaults` code exists, which is
  expected (ADR-0005 will add that code); PKC-09's "present exactly when found" rule applies to `35F9.1`, not to
  `CA92.1`.
- S1's own boundary review uses developer output only (its `verify.txt` with the observation line); it is not QC
  evidence and S1 is never merged alone.

## 6. Questions
- **Q5 (leader):** the test-support package `apple/ContractKit` (§1), shared by the KidCore and Tools harnesses,
  outside ADR-0002 D1's four packages because it is test-only. OK, or duplicate the harness file in Tools' tests
  instead?
- *Answered (K-37):* Q1 one branch, reviewed at each boundary; Q2 `LetterMorph` / `com.galaxyandsun.lettermorph`;
  Q3 the Personal Team, automatic signing, the team id in an untracked xcconfig; Q4 option (a1).
