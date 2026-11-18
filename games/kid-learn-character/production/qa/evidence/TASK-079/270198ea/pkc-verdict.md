# TASK-079 QC evidence: scaffold at 270198ea

**Who and when:** game-qc-ios, 2026-11-18.

**Checkout:** a clean checkout of `270198ea`, detached. The tree was clean before and after the run (`dirty=0`).

**Environment:**
- Xcode 27.1, Swift 6.4, macOS 27.2.
- Headless. Every step was gated on load ≤ 10 with no other `xcodebuild` running, at `nice -n 10`.

**Simulator:** QC iPad simulator `475D45B4…`, set as `QC_SIM_UDID` in `tools/qa/apple/sim.env`.
- It was booted headless, with no Simulator.app running.
- It was shut down after the run.

**Paths:** `$HOME` and the scratch checkout are masked as `~`, `<qc-checkout>`, `<scratch>` and `<tmp>`.

**Supersedes:** none. This is the only QC evidence for TASK-079.
- A dry run on d8f67715 was not committed.
- A run on b93ecf2b stopped on load before verify finished and was not committed. It found the STOP-prints-PASS bug that 270198ea fixes.

## Files

| File | What |
|---|---|
| `verify.txt` | `tools/ci/verify.sh --qc --app <macOS Release> --app <iOS Release> --evidence .` (exit 0). `verify-console.txt` is the same output. |
| `build-release-macos.txt` | Release build for `generic/platform=macOS`, ad-hoc signed through `Shared.xcconfig` (exit 0). |
| `build-release-ios.txt` | Release build for `generic/platform=iOS` with `CODE_SIGNING_ALLOWED=NO`, because there's no Personal Team yet (exit 0). |
| `codesign.txt` | `codesign -dv` on both products. |
| `scan-proof-xcode-27.1.txt` | `pkc-scan.sh --prove` (V7): `listed: 104; missing: 0`. |
| `pkc-scan.txt` | `pkc-scan.sh --static` on both Release products. It records observations only. |
| `self-test.txt` | `tools/ci/self-test.sh`: `self-test: PASS`. This includes `caught verify stopped by load is not a PASS` and the `sim-guard --qc` cases for the iPad and iPhone simulators. |

## verify.sh lines (copied verbatim)

```
PASS ban-grep (ADR-0002 V1)
PASS api-surface (ADR-0002 V4)
PASS kidtools validate content (ADR-0003 D3)
PASS swift test MorphCore
PASS swift test KidCore
OBSERVED structure: 12/12 contracts OK (727 cases well-formed)
OBSERVED key-table-schema-v1 [model]: 86 pass, 0 fail
OBSERVED settings-record-v2: 76 pass, 0 fail
OBSERVED NOT ASSESSED app-shell-v1: not started (story story:app-shell); structure OK, 0 of 26 cases run
OBSERVED NOT ASSESSED audio-plan-v1: not started (story story:audio-voice); structure OK, 0 of 30 cases run
OBSERVED NOT ASSESSED gate-logic-v1: not started (story story:parent-gate); structure OK, 0 of 48 cases run
OBSERVED NOT ASSESSED hint-letters-v1: not started (story story:hint-letters); structure OK, 0 of 58 cases run
OBSERVED SUPERSEDED input-filter-v1 → input-filter-v2: not run (86 cases)
OBSERVED NOT ASSESSED input-filter-v2: not started (story story:input); structure OK, 0 of 95 cases run
OBSERVED NOT ASSESSED keyboard-row-v1: not started (story story:keyboard-row); structure OK, 0 of 36 cases run
OBSERVED NOT ASSESSED press-queue-v1: not started (story story:press-queue); structure OK, 0 of 46 cases run
OBSERVED NOT ASSESSED reveal-timing-v1: not started (story story:reveal-stage); structure OK, 0 of 60 cases run
OBSERVED SUPERSEDED settings-record-v1 → settings-record-v2: not run (73 cases)
OBSERVED contracts: 2 run PASS (key-table-schema-v1, settings-record-v2), 8 NOT ASSESSED (not-started: app-shell-v1, audio-plan-v1, gate-logic-v1, hint-letters-v1, input-filter-v2, keyboard-row-v1, press-queue-v1, reveal-timing-v1), 2 SUPERSEDED, 0 FAIL
PASS swift test ContractKit
PASS swift test Tools
OBSERVED key-table-schema-v1 [file]: 7 pass, 0 fail
PASS xcodebuild build macOS
PASS xcodebuild test macOS (hostless unit tests)
PASS xcodebuild test iPad simulator (--qc, headless)
PASS bundle-content scan LetterMorph.app
PASS bundle-content scan LetterMorph.app
verify: PASS at 270198ea
```

`verify.sh --release` was not run here. It FAILs by design while any contract is not started (K-40); game-dev-android's `s2/verify-release-check.txt` shows that.

## PKC rows (privacy-kids-compliance.md): QC reading of this run

The order of precedence is FAIL > NOT ASSESSED > PASS. NOT ASSESSED never counts as a pass.

| Row (GDD title) | macOS Release | iOS Release | Reading | Basis / where it's decided |
|---|---|---|---|---|
| PKC-01 no network | adhoc: `app-sandbox` true, `get-task-allow` true (ad-hoc build); **no network-client or other entitlement**; no network API in the scan | **unsigned**, entitlements unread; no network API in the scan | static API: **PASS** both. Entitlements: macOS **PASS** for the file-based ones, Xcode-added ones **NOT ASSESSED**; iOS **NOT ASSESSED**. Runtime (PKC-01c): **NOT ASSESSED** | First Personal Team build (K-37), then pkc-scan on the signed product; PKC-01c on M-11 / P-5. |
| PKC-02 no ads, analytics, IAP, accounts, links out, share, review prompts | none found | none found | **PASS** (static) | Two-pass API scan, V7 proof 104/0. |
| PKC-03 no third-party runtime or SDK | `Frameworks/` absent; Swift modules are KidCore, MorphCore, LetterMorph, SwiftUI and CoreGraphics; `Package.resolved` absent; local packages only | the same | **PASS** | |
| PKC-04 no location | no location API | no location API | **PASS** (static) | Note: the macOS binary weakly links `libswiftCoreLocation.dylib`, a Swift overlay the toolchain adds automatically; no CoreLocation framework and no location API. Keep watching it. |
| PKC-05 no identifiers, no age signal | none found | none found | static **PASS**; live read **NOT ASSESSED** | M-8 / S-2. |
| PKC-06 no microphone, no camera | no API; no usage strings | the same | **PASS** (static) | |
| PKC-07 parent gate before anything that isn't play | gate not built yet | the same | **NOT ASSESSED** | Parent-gate story and S-4. |
| PKC-08 declarations list only what's needed | no `NS*UsageDescription` keys; nothing beyond the expected keys | the same | **PASS** | Key list in `pkc-scan.txt`. |
| PKC-09 privacy manifest | `NSPrivacyTracking` false, no tracking domains, no collected data types; UserDefaults **CA92.1**; SystemBootTime **35F9.1** | the same | **PASS** | The scan found `systemUptime` (ADR-0002 SystemUptimeClock), so 35F9.1 is required and present. CA92.1 covers app-only UserDefaults. |
| PKC-10 store privacy labels / PKC-11 audience | n/a | n/a | **NOT ASSESSED** | App Store Connect screenshots from Luan. |
| PKC-12 bundle-only content | no network API (PKC-01/02) | the same | **PASS** (static) | |
| PKC-13 re-open on change | n/a | n/a | **NOT ASSESSED** here | Diff review per story. |
| PKC-14 no logging of input or accessibility settings | `log-call scan done`, no call found | the same | static **PASS**; log stream **NOT ASSESSED** | M-11. |

## MAC FREE items: NOT ASSESSED pending Luan (K-34)

- First signed build (Personal Team, K-37), then PKC-01 on the signed iOS and macOS products.
- macOS launch and `title-macos.png` (run-and-observe).
- macOS UI test.

These are not waived. They stay NOT ASSESSED until Luan's MAC FREE slot and block release.

## QC verdict

**TASK-079 scaffold at 270198ea: PASS for merge, with the NOT ASSESSED items above carried open.**

- Every gate verify.sh runs passes, including the iPad simulator test on the QC iPad simulator under `--qc`.
- Contract reporting matches K-40: 2 contracts run and pass, 8 are not started, 2 are superseded, and none fail.
- The static privacy scan finds nothing outside the PKC rules.
- iPad run-and-observe exists in the dev evidence (`s1/title-ipad.png` and `s2/title-ipad-portrait-k39.png`).
- The macOS launch screenshot is NOT ASSESSED. The scaffold has no player-facing feature beyond the title stub, and the macOS build and hostless tests pass. So QC accepts a merge before the MAC FREE slot, on two conditions:
  1. the three MAC FREE items stay open on the board as release-blocking;
  2. no story whose Done criteria need a macOS run-and-observe closes until they're done.
