# iOS: the game on Luan's iPhone, then TestFlight (TASK-026)

> **TASK-028 (2026-11-17):** the game moved to `games/dai-dat-anh-hung/`. Every path in this guide is relative to that
> folder; run the commands from there (e.g. `cd games/dai-dat-anh-hung`).

Two paths. **A** puts the Preview build on Luan's own iPhone with his free Apple ID (no enrolment). **B** is
TestFlight, after enrolling in the Apple Developer Program. game-dev-ios runs every command. Luan's part is the
clicks marked **Luan**.

| | Path A: Preview on Luan's iPhone | Path B: TestFlight |
|---|---|---|
| Account | Free Apple ID ("Personal Team") | Apple Developer Program (paid) |
| Build | `Preview` config (D-37) | `Release` config |
| Bundle ID | `com.galaxyandsun.daidatanhhung.preview` | `com.galaxyandsun.daidatanhhung` (D-38, final) |
| Name on the home screen | Dải Đất Anh Hùng (preview) | Dải Đất Anh Hùng |
| History claims C01–C16 | Unsigned is allowed; `UNSIGNED Cxx` badges show | Must be signed: the R12 gate stops the archive otherwise |
| Lifetime | 7 days, then reinstall (same command) | 90 days per TestFlight build |
| Script | `tools/ios/install-device.sh` | `tools/ios/archive-upload.sh` |

Preview is Release-optimised with every `#if DEBUG` block compiled out: no debug jumps, no sample hero, no debug
state. `tools/qa/ios-release-check.sh` proves it byte for byte. Preview is never archived or uploaded.

## Path A: Preview on Luan's iPhone (free)

### Luan, once

1. **Xcode → Settings → Accounts → +** → Apple Account, and sign in with his Apple ID. Xcode lists a team called
   "*Name* (Personal Team)". Send game-dev-ios its **Team ID**: select the team, and the ID shows in the
   detail pane or in the first signing's log.
2. **Connect the iPhone to this Mac with a cable** and unlock it. When the phone asks **"Trust This Computer?"**,
   tap **Trust** and enter the passcode.
3. In Xcode, open the **Device Hub** (Window menu). Select the iPhone and follow the pairing prompts. The Device Hub
   says when Developer Mode is needed.
4. **Developer Mode** (per Apple's "Enabling Developer Mode on a device"; the switch appears only after the phone
   has been paired with a Mac):
   **Settings → Privacy & Security → Developer Mode** → on → tap **Restart**. After the restart, swipe up, tap
   **Enable**, and enter the passcode.
5. Optional, for Wi-Fi installs later: in the Device Hub, turn on the iPhone's network connection while it is still
   on the cable. After that, installs work over the same Wi-Fi network if the phone is awake and unlocked.
   (Not yet confirmed with a free team: the first run checks it.)

### game-dev-ios, each install (first time, then weekly)

```bash
TEAM_ID=<Personal Team ID> DEVICE="<iPhone name or UDID>" LAUNCH=1 tools/ios/install-device.sh
```

- It builds `Preview` for a real device, signs it with Xcode's automatic signing (`-allowProvisioningUpdates`
  creates the free App ID and profile), and installs it with `xcrun devicectl device install app`.
- It prints the profile's **expiry date**: 7 days for a free team, after which the app no longer opens.
- It prints the **connection type**: `wired`, or `localNetwork` for Wi-Fi.
- Reinstalling over the old app keeps the saved progress (stars, medal, language).
- `xcrun devicectl list devices` shows the name and UDID to use for `DEVICE`.
- It refuses Simulators, the Release config, and a missing `TEAM_ID`. `--dry-run` prints the commands only.

### Luan, the first launch only

6. The first launch is blocked as an untrusted developer. Open **Settings → General → VPN & Device Management**,
   tap the **Apple Development: *his Apple ID*** entry under Developer App, then tap **Trust**. Open the game again.
   (This path is from current guides, not an Apple page; the first run confirms it on his iOS version.)

Free-team limits, from Apple's "Compare memberships" page: up to 10 App IDs and 3 devices, each expiring after
7 days; up to 3 apps per device; profiles expire 7 days after they are issued. The app uses no capability a
free team can't sign (it has no entitlements).

### The first device run also measures ADR-0002's open checks

These are frame time on a real iPhone, and decoded memory. They are measured with Instruments (`xctrace`:
Animation Hitches or Game Performance for frame time, Allocations / VM Tracker for memory) over one full mission,
on the Preview build. If profiling needs a debuggable signature, the numbers are taken from a `CONFIG=Debug`
install, which has bundle `….debug` and is unoptimised; the evidence then names which build each number came from.
Evidence goes to `production/qa/evidence/TASK-026/device-run-1/`.

## Path B: TestFlight (after enrolment)

### Luan, once

1. **Enrol** at developer.apple.com/programs: **Individual** or **Organization**. An Organization needs a D-U-N-S
   number, and the choice decides the seller name on the store (Luan decides).
2. **Xcode → Settings → Accounts**: the paid team now appears next to the Personal Team. Send game-dev-ios its
   **Team ID**.
3. **App Store Connect → Apps → + → New App**:
   - Platform iOS. Name **Dải Đất Anh Hùng** (it must be unique on the App Store).
   - Primary language **Vietnamese**.
   - Bundle ID **com.galaxyandsun.daidatanhhung**. If it isn't in the list yet, the first archive registers it
     through automatic signing, or add it under Certificates, Identifiers & Profiles → Identifiers.
   - SKU `daidatanhhung-ios`.
4. **TestFlight → Internal Testing → +** to create a group (e.g. "Team"), and **add himself** as a tester. He is the
   account holder, so he is already a user. Install the **TestFlight** app on the iPhone.
5. Optional: **Users and Access → Integrations → App Store Connect API → +** for a key with the App Manager role.
   Keep the `.p8` file in `~/.appstoreconnect/private_keys/`, never in the repo, and give game-dev-ios the Key ID
   and Issuer ID. Without a key, the Apple ID signed in to Xcode is used.
6. **History sign-off:** C01–C16 must be signed before the first archive. The Release build stops at the R12 gate
   until then.

### game-dev-ios, each upload

```bash
TEAM_ID=<paid team ID> tools/ios/archive-upload.sh            # UPLOAD=0 exports an .ipa only
```

1. `tools/qa/ios-release-check.sh Release`: no debug code in Release (A1 = A2 = B, strings/nm clean).
2. `xcodebuild archive … -configuration Release DEVELOPMENT_TEAM=… CURRENT_PROJECT_VERSION=<N>`, with version
   **0.1.0** and build number **N = `git rev-list --count HEAD`** on main.
3. `xcodebuild -exportArchive -exportOptionsPlist <copy of ios/Config/ExportOptions.plist>`: method
   `app-store-connect`, destination `upload`, automatic signing, symbols uploaded. The teamID is set at run time.

The build appears in App Store Connect → TestFlight after processing. Internal testers need no Beta App Review.

### Answers expected in App Store Connect

| Question | Answer | Why |
|---|---|---|
| Export compliance | No non-exempt encryption | `ITSAppUsesNonExemptEncryption = NO` is in the Info.plist, so the question is skipped. No networking, no crypto |
| App Privacy | **Data Not Collected** | No network, analytics, ads or accounts. Progress stays on the device |
| Privacy manifest | `PrivacyInfo.xcprivacy` | No tracking, no collected data. Required-reason APIs: UserDefaults (CA92.1, the app's own save) and system boot time (35F9.1, the tap lock's elapsed time) |
| Age rating | Every questionnaire item "None", giving **4+** | No violence beyond cartoon training with a staff (answer "Infrequent/Mild Cartoon or Fantasy Violence" if Apple's wording counts it; that still rates 4+), no purchases, no web, no chat |
| Category | **Kids**, age band **D-39** (6–8 or 9–11, Luan decides) | Needs no third-party analytics or ads (none), and no links out or purchases without a parental gate (none) |
| Privacy policy URL | Needed for the App Store listing and for external TestFlight | Not needed for internal testing. Luan provides a URL later |

## Checks done without an account (TASK-026 branch)

- Preview builds for the Simulator and, unsigned, for a device (arm64, iOS 17.0+). Its Info.plist has bundle
  `…preview`, display name "(preview)", version 0.1.0 and `ITSAppUsesNonExemptEncryption` false. The privacy
  manifest is in the bundle and `Assets.car` holds the AppIcon.
- Preview's title shows Trần Quốc Toản's card and Start; the debug line is gone.
- `tools/qa/ios-release-check.sh`: Release and Preview each have A1 = A2 = B, with `strings` and `nm` clean.
  Release stops at R12 as designed.
- Both scripts: `--dry-run` prints the exact commands, and the refusals work (Simulator, Release on a device, no
  team).
