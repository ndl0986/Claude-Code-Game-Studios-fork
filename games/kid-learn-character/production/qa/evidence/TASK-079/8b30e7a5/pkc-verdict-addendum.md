# TASK-079 MAC FREE addendum: the three items left open in `../270198ea/pkc-verdict.md`

**Who and when:** game-qc-ios, 2026-11-18. MAC FREE was granted by Luan through game-leader.

**Checkout:** a clean checkout of `8b30e7a5` (docs/kid-learn-character-plan). The scaffold code is unchanged since 270198ea.

**Builds:** `nice -n 10`, with load ~3 to 8 and no other `xcodebuild` running. No simulator was used.

**Masking:**
- The Personal Team id is set only in the untracked, gitignored `apple/Config/Signing.local.xcconfig`.
- It is masked as `<team>` in every file here. The Apple ID is `<apple-id>`; certificate hashes are `<hash>`.
- `$HOME`, the scratch checkout and temp paths are masked as `~`, `<qc-checkout>`, `<scratch>` and `<tmp>`.

## Items

| # | Item | Result | Evidence |
|---|---|---|---|
| 1 | **First signed build** (Personal Team, automatic signing, K-37), iOS and macOS Release, then PKC-01 on the signed products | **PASS** | `build-signed-macos.txt` and `build-signed-ios.txt` (both `** BUILD SUCCEEDED **`, `-allowProvisioningUpdates`, no keychain or password dialog); `codesign-signed.txt` (`codesign -dv --entitlements`, `--verify --strict` OK on both, `TeamIdentifier=<team>`); `pkc-scan-signed.txt` |
| 2 | **macOS launch + `title-macos.png`** (run-and-observe) | **PASS** | `title-macos.png`: the signed Release app's own window only (`screencapture -l <window id>`, no desktop), 960 × 572 pt. It shows the blank Title, with Dusk sky filling the window, as `s1/title-ipad.png` does on the iPad. The app was quit through Apple Events, with 0 processes left. |
| 3 | **macOS UI test** (`LetterMorphUITests`, `test_app_launches_to_the_title`) | **PASS** | `ui-test-macos-run2.txt`: `Executed 1 test, with 0 failures`, `** TEST SUCCEEDED **`. Run 1 (`ui-test-macos-run1.txt`) failed with `Timed out while enabling automation mode`: macOS needs user authentication to enable Automation Mode. Run 2 was the single agreed re-run, with Luan at the Mac authenticating the prompt. No system setting was changed, and `automationmodetool` still reports Automation Mode disabled afterwards. |

## PKC-01 on the signed products (pkc-scan `--static`, OBSERVED lines)

**macOS (`Release/LetterMorph.app`):**
- signed by a team (team id masked);
- entitlements: `com.apple.security.app-sandbox` true and `com.apple.security.get-task-allow` true;
- `CODE_SIGN_ENTITLEMENTS` declares `app-sandbox` only.

**iOS (`Release-iphoneos/LetterMorph.app`):**
- signed by a team, with `embedded.mobileprovision` present;
- entitlements: `application-identifier` (`<team>.com.galaxyandsun.lettermorph`), `com.apple.developer.team-identifier` (`<team>`) and `get-task-allow` true.

**Reading: PASS.** Neither product has a network-client, network-server, iCloud, push, location or any other capability entitlement. The entitlements Xcode added at signing are only the identity entitlements and `get-task-allow`. `get-task-allow` comes from development signing; App Store distribution signing removes it, and the submission build is checked again at release (PKC-01, release gate). This closes the "Xcode-added entitlements NOT ASSESSED" and "iOS unsigned" parts of PKC-01 in `../270198ea/pkc-verdict.md`.

**Still open:** PKC-01c, the runtime check, stays NOT ASSESSED → M-11 / P-5.

## Observations (not verdicts)

- **Fill colour:** the Dusk fill reads RGB (61, 77, 129) in the macOS window capture and (70, 85, 143) in the iPad simulator capture (`s1/title-ipad.png`). That's most likely the Mac display's colour profile applied by `screencapture`, against the simulator's sRGB. Colour accuracy is not part of these items; the art and colour rows (Accessibility F2b, the art bible) decide it.
- **Scheme:** the `LetterMorph` scheme's Test action does not include `LetterMorphUITests`. `-only-testing:LetterMorphUITests` fails with "isn't a member of the specified test plan or scheme". The shared `LetterMorphUITests` scheme runs it. That's fine for the K-34 MAC FREE split; recorded so later runs use that scheme.

## Verdict

**All three MAC FREE items: PASS.** With `../270198ea/pkc-verdict.md`, the TASK-079 scaffold has no item left NOT ASSESSED except the runtime and device rows already routed to the device-checks plan: PKC-01c, PKC-05 live read, PKC-07, PKC-10/11, PKC-13 and PKC-14 log stream.
