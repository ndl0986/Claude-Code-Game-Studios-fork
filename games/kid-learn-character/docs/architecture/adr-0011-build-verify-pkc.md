# ADR-0011: Local build, verification gates and the PKC scans

## Status

Proposed

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**

## Date

2026-11-18

## Last Verified

2026-11-18, against ADR-0001 (Accepted), ADR-0002 (Accepted) Validation 1–4, ADR-0003 (Accepted) D4, D8 and
Validation, ADR-0004 (Accepted) D3 and D4, ADR-0005 (Accepted, the dev-simulator notes), architecture.md's
scaffold checks (a)–(f), Privacy & Kids Compliance PKC-01…14 and their check columns, decisions K-28, K-31 and
K-34, and the studio rule that helper scripts emit observations, never verdicts.

## Decision Makers

Luan (accepts; decided K-28 and K-34); game-dev-android (author, TASK-071); game-qc-ios (plan and independent
review); game-leader.

## Summary

Every ADR so far ends in checks: contract cases, a ban grep, staleness checks, a bundle scan, the PKC scans. This
ADR decides how they run on Luan's Mac without a CI service: which checks are gates that fail a run and which only
record what they see for QC to judge, who runs what before a push and before a merge, the exact commands on the
developer's own simulator, where the evidence goes, which runs need the leader's MAC FREE, and what is deferred
(a Linux build of the cores, GitHub runners, Android).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | None from the template's table (`engine.name` unset, ADR-0001, K-28). Swift 6.4, Xcode 27.1 |
| **Domain** | Build and verification |
| **Layer** | Tooling (nothing ships) |
| **Knowledge Risk** | LOW for `swift test`, `xcodebuild`, `xcrun simctl`, `codesign`, `otool`, `plutil` (TASK-033 used them). MEDIUM for `log stream` and `nettop` output formats on macOS 27 (NOT SOURCEABLE until run) |
| **References Consulted** | `docs/engine-reference-local/native-apple/VERSION.md`; ADR-0004 (harness); `design/gdd/privacy-kids-compliance.md` (check columns) |
| **Post-Cutoff APIs Used** | None; command-line tools only |
| **Verification Required** | Validation Criteria 1–6 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (the ban grep, the API surface), ADR-0003 (validator, staleness, bundle scan), ADR-0004 (the harness), ADR-0005 (dev-simulator use) |
| **Enables** | The first scaffold story's checks; every story's definition of done; the release checklist's PKC evidence |
| **Blocks** | The scaffold story (it writes `verify.sh`) |
| **Ordering Note** | Written after 0002–0005; 0006–0010 add their own device checks to the same evidence layout |

## Context

### Problem Statement
Without a CI service (K-28: local first), checks run only if someone runs them, and their results are only worth
something if they are tied to one commit and kept. Some checks are mechanical (a banned type is there or not);
others need a person to judge (an `otool -L` list, a log capture). Mixing the two either hides a judgement inside
a script or lets a mechanical failure pass as an opinion.

### Constraints
- K-28: CI is local; QC runs the suites; GitHub macOS runners later, if Luan decides (paid minutes).
- K-34: anything that takes the Mac's screen, keyboard or focus needs the leader's MAC FREE; headless runs do not.
- The studio rule: helper scripts emit observations, never verdicts.
- K-31: no third-party build tools.
- QC owns the simulator `E9F515E9…`; nobody else uses it.

### Requirements
- One command for all gates before a push.
- PKC evidence per commit, with QC's verdict per rule.
- Nothing in this ADR ships in the app.

## Decision

### D1. Gates and observations, never mixed
- **Gates** are mechanical, exact rules: they exit non-zero and fail the run.
  - ADR-0004: the contract harness, with per-contract and per-layer counts (a layer with 0 cases where `spec.md`
    expects some is a FAIL).
  - ADR-0002: the ban grep; the API-surface staleness check.
  - ADR-0003: the content validator; baked-output staleness; the `voiceDurations` re-measure; exact-case paths; the
    bundle-content scan (no `src/`, no `.svg`, no fixtures, no tools in the `.app`).
- **Observations** are the PKC scan suite. Its script prints `OBSERVED <pkc-id> <tool> <finding>` lines and exits 0
  unless a tool itself fails to run. **QC writes the verdict** for each PKC row in the evidence file (D6). The
  script never says PASS or FAIL.

### D2. Who runs what, and when (K-28, K-34)
- **The developer, before every push:** `tools/ci/verify.sh`, all gates. A failing gate means nothing is pushed.
- **QC, on every merge candidate:** `verify.sh`, the app test suites (D3), and `pkc-scan.sh` on a Release build,
  recorded in the evidence folder for that commit (D6).
- **The leader** merges only when QC's evidence for **that exact commit** exists.
- **MAC FREE (K-34):**
  - **Needed** for anything that takes the Mac's screen, keyboard or focus: launching the macOS app, macOS UI tests,
    the kiosk, key injection, `nettop` and `log stream` sessions, and **Simulator windows**.
  - **Not needed** for headless runs: `swift test`, `xcodebuild build`, and tests on the developer's own simulator
    booted headless (no Simulator window).
- **Every run:** `nice -n 10`; its own `-derivedDataPath` per worktree; stop if the load average goes above about
  40; build daemons stopped after use.

### D3. Commands
All paths are under `games/kid-learn-character/`.
```
swift test --package-path apple/MorphCore            # morph-contract-v1 and unit tests
swift test --package-path apple/KidCore              # unit tests and every KidCore contract
swift test --package-path apple/Tools                # key-table-schema-v1 "file" layer, validator, bake tests
xcodebuild test  -scheme <App> -destination "platform=iOS Simulator,id=$DEV_SIM_UDID" \
                 -derivedDataPath <worktree>/.build/xcode            # headless: the sim is booted with simctl, no window
xcodebuild build -scheme <App> -destination "platform=macOS" -derivedDataPath …    # headless build
xcodebuild build -scheme <App> -configuration Release …              # the build the PKC scans read
```
- `DEV_SIM_UDID` comes from an untracked, per-machine `tools/dev/apple/sim.env`. The scripts **refuse** QC's
  simulator `E9F515E9…` and refuse an empty value.
- macOS UI tests and any macOS launch need MAC FREE (D2).

### D4. `tools/ci/verify.sh`: the gates, fastest first
1. The ADR-0002 ban grep over `apple/KidCore/Sources` and `apple/MorphCore/Sources` (file and line on failure).
2. API-surface staleness: regenerate `contracts/kidcore-api.md` and `contracts/morphcore-api.md` in memory and
   compare.
3. ADR-0003 content: the validator (Tools), baked-output staleness, the `voiceDurations` re-measure, exact-case
   paths.
4. The `swift test` runs of D3.
5. After an app build: the ADR-0003 D8 bundle-content scan.

It prints one summary line per gate and writes `verify.txt` (D6). `tools/ci/` lives at the **game root**, because
its content and PKC parts are not Apple-specific and the Android build reuses them.

### D5. `tools/ci/pkc-scan.sh <path-to.app>`: observations only
One section per PKC row, taken from that row's Apple check column:
- **PKC-01:** `codesign -d --entitlements -` compared with the allowlist; the network API scan. Runtime `nettop`
  (PKC-01c) is a foreground session: MAC FREE.
- **PKC-02, 04, 06:** `otool -L` framework lists; the API scans.
- **PKC-03:** `Package.resolved` and `project.pbxproj` remote references; `otool -L` paths; `Frameworks/` empty.
- **PKC-05:** the identifier API scan; the preferences keys (`defaults read`, or the simulator data container).
- **PKC-08:** `plutil -p Info.plist` keys.
- **PKC-09:** `plutil -p PrivacyInfo.xcprivacy`; the file-timestamp and disk-space API scans; whether 35F9.1 and
  CA92.1 are present against the APIs found.
- **PKC-12:** the On-Demand Resources and donation API scans.
- **PKC-14:** the code scan for log calls carrying input or accessibility state outside `#if DEBUG`; the optional
  `log stream --level debug` capture during the scripted session (foreground: MAC FREE).
- **PKC-07, 10, 11, 13:** listed as "QC play", "screenshot" or "review", with nothing to scan.
- **Android rows:** NOT ASSESSED until an Android build exists (K-03).

### D6. Evidence
Under `production/qa/evidence/<TASK-id>/<short-sha>/`:
- `verify.txt`: the gate results;
- `pkc-scan.txt`: the raw OBSERVED lines;
- `pkc-verdict.md`: QC's table, one row per PKC-01…14, PASS / FAIL / NOT ASSESSED, each citing its observed lines,
  plus the screenshots the rows need;
- `title.png` for the scaffold story: the Title launch on the developer's simulator (check (f)).

Evidence belongs to one commit; a newer commit needs new evidence.

### D7. A Linux / Foundation-only build of the cores: later
No Linux machine is available, and Docker would add a third-party tool to the build (K-31). The check is revisited
with ADR-0012, when the Kotlin port exists, or sooner if a Foundation-only API drift is ever found. Until then the
ban grep and the committed API surface guard the cores.

### D8. GitHub macOS runners: recorded, not taken (K-28)
`verify.sh` and `pkc-scan.sh` would run unchanged on a runner, with the simulator created by name. It needs paid
minutes; the decision is Luan's, when needed.

### D9. Android (ADR-0012)
`./gradlew :kidcore:test :morphcore:test` runs the same `contracts/` cases; the Android PKC rows (`aapt2`,
`apkanalyzer`) join `pkc-scan.sh`; the same evidence layout.

### Architecture Diagram
```
developer: verify.sh (gates) ──pass──▶ push
QC:        verify.sh + app tests + Release build ──▶ pkc-scan.sh (OBSERVED lines) ──▶ pkc-verdict.md (QC)
leader:    merge only with evidence for that commit
```

### Key Interfaces
`tools/ci/verify.sh` (exit code: 0 = all gates passed); `tools/ci/pkc-scan.sh <app>` (exit 0 unless a tool
fails); the D6 evidence layout; `tools/dev/apple/sim.env` (`DEV_SIM_UDID`, untracked).

### Implementation Guidelines
- A gate **must** be mechanical and **must** fail the run; a judgement **must** be an observation for QC.
- Scripts **must never** use QC's simulator, and **must** refuse it by UDID.
- A run that takes the screen, keyboard or focus **must** wait for MAC FREE.
- `tools/ci/` **must** use only the system's command-line tools and our own code (K-31).

## Alternatives Considered

### Alternative 1: A hosted CI service now
- **Description**: GitHub macOS runners from the start.
- **Pros**: runs on every push without a person.
- **Cons**: paid minutes; simulator setup on the runner.
- **Rejection Reason**: K-28 (local first); the path stays open (D8).

### Alternative 2: Scripts that judge PKC rows
- **Description**: `pkc-scan.sh` prints PASS / FAIL.
- **Pros**: one less manual step.
- **Cons**: several rows need judgement in context; the studio rule.
- **Rejection Reason**: observations only; QC decides.

### Alternative 3: Every run under MAC FREE
- **Description**: the literal reading of K-28.
- **Pros**: simplest rule.
- **Cons**: headless runs would wait for no reason.
- **Rejection Reason**: Luan's K-34.

## Consequences

### Positive
- One command before every push; evidence tied to a commit; judgements made by QC, not hidden in scripts.

### Negative
- Discipline instead of a service: a skipped `verify.sh` is caught only at QC's merge check.

### Neutral
- GitHub runners and a Linux build are deferred, not ruled out.

## Risks
- **Output formats of `nettop` and `log stream`** on macOS 27 are NOT SOURCEABLE until run. Mitigation: they are
  observations, read by QC.
- **A developer forgets `verify.sh`.** Mitigation: QC's merge check re-runs it on the same commit.
- **Load on Luan's Mac.** Mitigation: nice 10, the load cap, daemons stopped (D2).

## GDD Requirements Addressed

TR-IDs are provisional (architecture.md baseline).

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| privacy-kids-compliance.md PKC-01…14 | TR-pkc-001: no network, SDK or identifiers; the privacy manifest; scans | D5, D6 |
| (all GDDs with contracts) | contract cases pass on both platforms | D1, D4 (ADR-0004 harness), D9 |
| key-table-theme-data.md §5, §6 | the build gate | D4 step 3 (ADR-0003) |

## Performance Implications
- **CPU**: build-time only, at nice 10.
- **Memory**: none at run time.
- **Load Time**: none.
- **Network**: none.

## Migration Plan
None: nothing exists yet. The scaffold story writes `verify.sh`, `pkc-scan.sh` and `tools/dev/apple/sim.env.example`.

## Validation Criteria
1. Every gate fails on a planted break: a `Date` in `KidCore`, a stale API file, a stale baked file, a broken V-rule,
   a zero-case contract layer, an `.svg` left in the bundle.
2. `pkc-scan.sh` with a planted `URLSession` exits 0 and prints an `OBSERVED PKC-01` line for it, without a verdict.
3. The scripts refuse QC's simulator UDID and an empty `DEV_SIM_UDID`.
4. The evidence folder for one commit holds `verify.txt`, `pkc-scan.txt` and `pkc-verdict.md` (and `title.png` for the
   scaffold story).
5. A headless `xcodebuild test` on the developer's simulator runs with no Simulator window.
6. `verify.sh` runs at nice 10 and stops on its load check.

## Related
- `docs/architecture/architecture.md` (scaffold checks); ADR-0002, ADR-0003, ADR-0004, ADR-0005.
- `design/gdd/privacy-kids-compliance.md`.
- Decisions K-28, K-31, K-34.
