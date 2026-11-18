# Privacy & Kids Compliance

> **Status**: Approved (text review by game-qc-android, merged 2026-11-18; Luan's calls L-01…L-09 open)
> **Author**: game-qc-ios for Luan (TASK-040); plan reviewed by game-qc-android
> **Last Updated**: 2026-11-18
> **Last Verified**: 2026-11-18 (official sources read raw on 2026-11-18, except [C3], read 2026-11-17 for TASK-034)
> **Implements Pillar**: Pillar 5 (Safe by Design); keeps the anti-pillar "NOT ads, in-app purchases, accounts, network or analytics"

## Summary

This system has no screen and no runtime code of its own. It is the list of rules every build of the
game must pass before release, on every platform: no network, no data, no third-party code, nothing
but play in front of the child, and store declarations that say so. (The OS may still back up the
settings to the user's own account, K-12; the app itself sends nothing.) Each rule says how it is checked
on the built app, on Apple now and on Android when that app exists, and the release gate combines
the checks into one verdict.

> **Quick reference**: Layer `Foundation` · Priority `MVP` · Key deps: none. It constrains every
> other system. The owners named in the systems index are security-engineer and release-manager; QC
> runs the checks.

---

## Overview

The player is 2.5–3 years old and can't read. The parent hands over an iPad or a Mac and needs to
trust that nothing can reach the child, and that the app sends nothing about the child off the device
(OS backups of the settings are the user's own and are allowed, K-12). The
concept already decided how (Pillar 5, its design test: "a feature that needs the network or data,
or none → none"). ADR-0001 §8 made it technical: no network, no `com.apple.security.network.client`
entitlement on macOS, and no third-party runtime or SDK without its own ADR. K-08 (revised after
TASK-034) removed the last feature that wanted the network: the weather is picked by hand behind the
parent gate.

This GDD turns those decisions into **PKC rules** (PKC-01…PKC-14). Each rule has:
- its official source;
- an **Apple check** that QC runs on the Release build;
- an **Android check**, which reads `NOT ASSESSED: no Android build (K-03)` until that app exists.

Store answers (App Privacy, Data safety, the Kids age band, the privacy policy) and any legal reading
are **Luan's calls**. This document gives the engineering position and the evidence for them.

## Player Fantasy

The player is the parent. *"I can hand it over and walk to the kitchen."* There is nothing to buy,
nothing to sign in to, no ad and no button that opens the web. The settings sit behind a gate a
toddler can't open. Under the App Store's privacy heading the listing is meant to say "Data Not
Collected" (Luan's answer, L-05, made once this gate passes).

The child never sees this system. Its only visible result is that nothing unexpected ever happens.

---

## Detailed Design

### Core Rules

**How to read the table.**
- Each rule is one row. A build passes a rule only when its check passes on that build.
- "Release build" means the archived app as uploaded: iPadOS `.ipa` / `.app`, the macOS `.app`, the
  Android universal `.apk` made from the release `.aab` (route below).
- **The Android release APK route.** Nothing installed on the QC machine can turn an `.aab` into an
  APK (no `bundletool`; installing one needs Luan's OK). Release evidence uses route **(b)**: the
  **signed universal APK downloaded from Play Console's App bundle explorer**, supplied by Luan like
  the store screenshots. Route **(a)**, `bundletool build-apks --mode=universal`, is used only with
  Luan's OK to install bundletool. Until the Android ADR names the route, every Android cell is NOT
  ASSESSED.
- **Android tools** are the SDK's own, from the build-tools version the Android ADR pins (35.0.1 is
  the reference here): `aapt2`, `dexdump`, `apkanalyzer`, `adb`. R8 doesn't rename framework calls,
  so `dexdump` finds `Landroid/…` references in a minified build.
- **Android checks always read the merged manifest** of the release APK (what `aapt2` prints from the
  built APK), never only the source `AndroidManifest.xml`, because libraries add permissions when the
  manifests merge.
- Helper scripts print observations; QC reads them and records the verdict (studio rule: scripts
  emit observations, never verdicts).
- **The Apple API scan** (used wherever a row says "API scan") runs on **every Mach-O in the bundle**
  in two passes, because `nm` can't see Objective-C selectors:
  1. `nm -um` for classes, C functions and constants (for example `NSWorkspace`, `mach_absolute_time`,
     `NSURLCreationDateKey`);
  2. `otool -ov` (Objective-C selector and class references) plus `strings -a` for selectors and
     Swift-bridged methods (for example `openURL:`, `identifierForVendor`, `systemUptime`,
     `requestReview`).

  "No X" means neither pass finds X. **The scan is proven before its first use as release evidence**:
  run it on a fixture binary that calls every API named in PKC-01…12 and in Edge Cases, and it must list each one. It is
  proven again when Xcode or the scan script changes. The script matches whole selector and symbol names (`strings -a` alone also matches substrings such as
  `stat`). A hit is read by a person: a hit inside a system stub is noted, and a hit from our code is a
  FAIL.
- **Rules marked *team rule*** are stricter than their source. The source allows more (for example a
  link out behind a parental gate), and the team chose less.

| ID | Rule | Source | Apple: how verified (Release build, iPadOS and macOS) | Android: how verified |
|---|---|---|---|---|
| **PKC-01** | **No network, of any kind, started by the app.** No HTTP, sockets, app-initiated iCloud/CloudKit or sync, push, Game Center, local network or Bonjour. Time of day comes from the device clock and weather is hand-picked (K-08). | Pillar 5; ADR-0001 §8; Guideline 1.3 [A1] | (a) `codesign -d --entitlements - <app>` shows no `com.apple.security.network.client`/`.server` (macOS: `com.apple.security.app-sandbox` true) and no iCloud/CloudKit/key-value, `aps-environment`, Game Center or associated-domains entitlement (no app-initiated iCloud or sync; OS device backups are allowed, K-12). The entitlements must equal the allowlist in §Tuning Knobs. (b) the API scan: no `URLSession`, `NSURLConnection`, `NWConnection`/`nw_*`, `CFStream…ToHost`, `WKWebView`, `CKContainer`. (c) Runtime: `nettop -p <pid> -x -L 0` for the scripted session (§Tuning Knobs: every key, a parade, every setting changed, Start over) shows **0 bytes in and out**. On macOS also count sandbox `deny network-outbound` lines for the process in `log show` (expected 0: zero attempts, not just zero bytes). The iPad device run uses an Instruments network trace. | **NOT ASSESSED: no Android build (K-03).** When it exists: `aapt2 dump permissions app.apk`: no `android.permission.INTERNET` and no `ACCESS_NETWORK_STATE`. `adb shell dumpsys netstats detail` for the app's uid after the same scripted session: rx 0 and tx 0 bytes. |
| **PKC-02** | **No ads, analytics, in-app purchases, accounts or sign-in, links out, share sheets or review prompts.** The only things a grown-up can reach are behind the parent gate (PKC-07), and none of them leave the app. *Team rule:* Guideline 1.3 allows links out and purchases behind a parental gate; the team allows neither, and share sheets and review prompts aren't named in 1.3. | Anti-pillars; Guideline 1.3 and 5.1.4 [A1]; Kids page [A3]; Families policy [G1] | `otool -L`: no `StoreKit`, `AdSupport`, `AppTrackingTransparency`, `AuthenticationServices`, `SafariServices`, `GameKit`, `MessageUI`. API scan: no `openURL`/`open(_:options:)` (`UIApplication`), no `NSWorkspace open`, no `SKStoreReviewController`/`requestReview`, no `UIActivityViewController`/`NSSharingService`. QC play: no tap anywhere in the child area opens Safari, a web view, the App Store or another app. | **NOT ASSESSED: no Android build (K-03).** When it exists: `aapt2 dump permissions`: no `com.android.vending.BILLING`. `apkanalyzer dex packages --defined-only` (with the mapping, as in PKC-03): no `com.android.billingclient`, no ads or analytics package (`com.google.android.gms.ads`, `com.google.firebase.analytics`, …). `adb logcat` during the scripted session: **no `START` of another package** by ActivityTaskManager. Static backstop: `dexdump -d classes*.dex` shows no `Landroid/content/Intent;-><init>` built with `android.intent.action.VIEW`, and no `const-string` `market://`, `http://` or `https://` passed to it. |
| **PKC-03** | **No third-party runtime or SDK in the app** without its own ADR (ADR-0001 §8). If one is ever approved, its ADR carries the Rive `loadCdn: false` lesson, a privacy-manifest check and a Kids/Families approval check. Build-time tools that leave nothing in the bundle (for example the TTS pre-render, K-13) are out of scope here; their output licence is Luan's (K-13). | ADR-0001 §8; Guideline 1.3 [A1]; Families "APIs and SDKs" [G1] | (a) **Project dependencies** (catches static linking, which `otool -L` can't see): **no remote package**: `Package.resolved` is absent or has no pins, and `project.pbxproj` has no `XCRemoteSwiftPackageReference`. The local package references are only `KidCore` (plus `MorphCore` if it is its own package; ADR-0001 allows it as a target of `KidCore`). There is no `Podfile`, `Cartfile` or binary `.xcframework` outside our own. (b) `otool -L` on every binary lists only `/System/Library/…`, `/usr/lib/…` and our own frameworks. (c) `Frameworks/` (macOS: `Contents/Frameworks/`) is empty or holds only our own frameworks, and no third-party `PrivacyInfo.xcprivacy` or `.bundle` appears. (d) The Swift module names in the binary's symbols (mangled `$s<len><Module>` prefixes in `nm`) show only Apple's modules, the app target, `KidCore` and `MorphCore`. (A statically linked C-only library has no Swift module name; (a) is the backstop for it.) | **NOT ASSESSED: no Android build (K-03).** When it exists: `apkanalyzer dex packages --defined-only --proguard-mappings mapping.txt app.apk`, with the `mapping.txt` from **the same release build** (kept as evidence): every top-level package is in the **approved list** (our own package, `kotlin`/`kotlinx`, the AndroidX packages the Android ADR names). Anything else fails until an ADR adds it. **Without that build's mapping (R8 minify renames classes), this row is NOT ASSESSED, not PASS.** |
| **PKC-04** | **No location.** No device location, no IP-based lookup, no city picker. | K-08; Guideline 5.1.5 [A1]; COPPA 312.2 (9) [C1]; Families "may not request location permission" [G1] | `plutil -p Info.plist`: no `NSLocation*` key. `otool -L`: no `CoreLocation`. macOS entitlements: no `com.apple.security.personal-information.location`. | **NOT ASSESSED: no Android build (K-03).** When it exists: no `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` or `ACCESS_BACKGROUND_LOCATION` (aapt2). |
| **PKC-05** | **No identifiers and no age signal.** No IDFA or IDFV, no generated install or user ID, no device serial, and no call to the Declared Age Range API (the child's age is not needed). The Settings Store keeps only its listed fields (Settings Store R1–R4, TASK-039). | Guideline 1.3 "IDFA … their devices" [A1]; COPPA 312.2 (7) [C1]; Families data practices [G1][G2] | API scan: no `ASIdentifierManager`, `identifierForVendor`, `DeclaredAgeRange`; `strings` on the binary: no `UUID().uuidString` written to storage (code review of the Settings Store is the real check, because a UUID API also has harmless uses). The app's preferences domain, read back with `defaults read` on macOS or from the simulator container, holds exactly one app-written key, `settings` (Settings Store R4), whose decoded value holds only the R1 fields. Keys the OS writes itself (for example window frames on macOS) are listed and ignored. | **NOT ASSESSED: no Android build (K-03).** When it exists: no `com.google.android.gms.permission.AD_ID`, `READ_PHONE_STATE` or `ACCESS_WIFI_STATE` (aapt2). `dexdump -d` on every `classes*.dex` (`apkanalyzer dex references` only counts references) shows none of: `Landroid/provider/Settings$Secure;->getString` near a `const-string` `"android_id"`; `Landroid/telephony/TelephonyManager;->getImei`, `getDeviceId`, `getLine1Number`, `getSimSerialNumber`; `Landroid/os/Build;->getSerial`; `Landroid/net/wifi/WifiInfo;->getMacAddress`, `getBSSID`, `getSSID`; `com/google/android/gms/ads/identifier/AdvertisingIdClient`. |
| **PKC-06** | **No microphone and no camera,** on every platform. | Families "microphone and camera sensor data" [G1]; COPPA 312.2 (8) audio/photo [C1]; Apple usage keys [A6] | `plutil -p Info.plist`: no `NSMicrophoneUsageDescription`, no `NSCameraUsageDescription` (Apple: "This key is required if your app uses APIs that access the device's microphone", and the same for the camera [A6]). macOS entitlements: no `com.apple.security.device.audio-input`, no `com.apple.security.device.camera` [A7]. API scan: no `AVCaptureDevice`, `AVCaptureSession`, `AVAudioRecorder`, `SFSpeechRecognizer`; no `AVAudioEngine` input node use (code review: the engine is output-only). | **NOT ASSESSED: no Android build (K-03).** When it exists: no `RECORD_AUDIO` and no `CAMERA` (aapt2). |
| **PKC-07** | **A parent gate before anything that isn't play.** The gate covers the grown-up panel, settings (volume, weather, theme, keyboard row), the Mac kiosk exit and the privacy text. The Parent Gate GDD (#12) designs the gate; this rule only says what must be behind it. The **privacy policy is shown as bundled text inside the panel**, not as a link, so PKC-01/02 hold. A gated link instead would be a PKC-13 change: it needs a named exception to PKC-01 and PKC-02 (L-04). | Guideline 1.3 "behind a parental gate" [A1]; Kids page "Provide parental gates" [A3]; 5.1.4 privacy policy [A1]; Play User Data "within the app itself" [G5] | QC play: from every child-area screen, every grown-up item needs the gate first. Every key and every touch target was tried; none opens a grown-up item. The privacy text is reachable in the panel with no network. | The same QC play on the Android build. NOT ASSESSED: no Android build (K-03). |
| **PKC-08** | **The app's declarations list only what it needs.** Expected: no permission usage strings at all, no URL schemes, no queried schemes, no App Transport Security exceptions. | Guideline 5.1.1 (iii) data minimization [A1] | `plutil -p Info.plist`: no `NS*UsageDescription`, `NSUserTrackingUsageDescription`, `NSLocalNetworkUsageDescription`, `NSBonjourServices`, `NSAppTransportSecurity`, `CFBundleURLTypes`, `LSApplicationQueriesSchemes`. | **NOT ASSESSED: no Android build (K-03).** When it exists: `aapt2 dump permissions` lists **no** permission beyond the allowlist in §Tuning Knobs (none of the dangerous or network permissions; the Android ADR pins any library-merged signature permission) and no `QUERY_ALL_PACKAGES`; `aapt2 dump xmltree --file AndroidManifest.xml app.apk` shows no `<queries>` element. |
| **PKC-09** | **Privacy manifest** `PrivacyInfo.xcprivacy` in the app bundle: `NSPrivacyTracking` false; `NSPrivacyTrackingDomains` empty; `NSPrivacyCollectedDataTypes` empty; `NSPrivacyAccessedAPITypes` holds `NSPrivacyAccessedAPICategoryUserDefaults` with reason **`CA92.1`** (Settings Store), and `NSPrivacyAccessedAPICategorySystemBootTime` with reason **`35F9.1`** ("to measure the amount of time that has elapsed between events that occurred within the app" [A5]) **if and only if** our code calls `systemUptime` or `mach_absolute_time()`. Input & Key Filter R8 carries event times on the uptime clock, so this entry is **expected**; the API scan decides. **No `FileTimestamp`, `DiskSpace` or `ActiveKeyboards` category: the app reads no file timestamps, no free disk space and no keyboard list.** The same file ships in the macOS app (see Edge Cases). | Apple Privacy manifest files [A4]; Required-reason API [A5] | `plutil -p <app>/PrivacyInfo.xcprivacy` (macOS: `Contents/Resources/`) matches the content above exactly. Xcode Organizer "Generate Privacy Report" on the archive shows no collected data and only the declared reasons. API scan: no `creationDate`, `modificationDate`, `fileModificationDate`, `stat`/`fstat`/`lstat`/`getattrlist` (file timestamps), no `statfs`/`volumeAvailableCapacity*` (disk space), no `activeInputModes` (keyboards) from our own code. The 35F9.1 entry is present exactly when the scan finds `systemUptime` or `mach_absolute_time`. Note (V1, game-dev-ios checked Apple's page 2026-11-18): the continuous clock (App Shell R6, `ContinuousClock` / `mach_continuous_time`) is not a listed required-reason API (Apple lists only `ProcessInfo.systemUptime` and `mach_absolute_time` under System boot time); it would be covered by the existing 35F9.1 entry if Apple adds it. | N/A: Android has no privacy manifest. Its counterpart is the Data safety form (PKC-10). |
| **PKC-10** | **Store privacy labels say nothing is collected.** Apple App Privacy: "Data Not Collected". Google Play Data safety: no data collected or shared (the form is required even then). | App privacy details [A2]; Data safety [G4] | QC compares the App Store Connect answers (screenshot from Luan) with PKC-01…06 and PKC-09: no row may contradict them. | NOT ASSESSED: no Android build (K-03). When it exists, QC compares the Play Console Data safety answers (screenshot from Luan) the same way. |
| **PKC-11** | **Audience declared as small children only.** Apple Kids category age band **"5 and under"** (offered when the calculated age rating is 4+ or 9+). Google target audience **"Ages 5 & Under" only**. | Kids page age bands [A3]; age-rating help [A8]; Families target audience [G1][G3] | QC checks the App Store Connect age-rating screen (screenshot from Luan): "Made for Kids", "5 and under". **macOS:** if the screenshot shows "Made for Kids" is not offered for the Mac version (L-01), PKC-11 is PASS for macOS on that screenshot, recorded as "not offered"; the Mac app still meets every other PKC rule. | NOT ASSESSED: no Android build (K-03). Later: the Play Console target-audience screenshot shows only "Ages 5 & Under". |
| **PKC-12** | **Bundle-only content.** Themes, glyphs, art, sounds and voice files ship in the app bundle and are never downloaded (key-table §5). | Key Table & Theme Data §5; PKC-01 | Covered by PKC-01 (no network APIs). Plus: every theme file the validator lists is inside the bundle. There is no On-Demand Resources / Background Assets use (API scan: no `NSBundleResourceRequest`, `BackgroundAssets`). The app donates nothing to the OS: API scan finds no `NSUserActivity` `isEligibleForHandoff`/`isEligibleForSearch`, `CoreSpotlight`/`CSSearchableItem`, `INInteraction donate` or `AppIntents` donations. | `apkanalyzer` / bundle check: no Play Asset Delivery or dynamic feature modules. NOT ASSESSED: no Android build (K-03). |
| **PKC-13** | **A change that would add the network, location, data or an SDK re-opens this GDD before release.** Live weather in any form (WeatherKit, an API, a city picker that fetches) or any new feature like it needs, before it ships: its own ADR; Luan's decision on the COPPA position (§COPPA position) and the store labels (PKC-10); and new checks for PKC-01, 04, 05 and 09. TASK-034 stays on file as the starting point for weather. | K-08 (revised); Pillar 5 design test; COPPA position (below) | Review gate: any PR whose diff adds an entitlement, an `Info.plist` usage key, a `PrivacyInfo` entry, a linked framework or a package dependency is flagged by QC and blocked until the ADR and Luan's decision exist. | The same, for any diff that adds a permission or a Gradle dependency outside the approved list. NOT ASSESSED: no Android build (K-03). |
| **PKC-14** | **Release builds never log the child's input or the device's accessibility settings.** No key, letter, word, touch position or timing pattern, and no accessibility setting (Reduce Motion, VoiceOver, Guided Access, Smart Invert or any other; Accessibility A11), goes to the console or to disk in a release build; none is ever sent (PKC-01). Debug builds may log to the platform console only (never to a file), and never off the device. | *Team rule*, from Pillar 5 (COPPA says nothing about local logs) | **The real check is a code scan:** no `print`, `debugPrint`, `NSLog`, `os_log` or `Logger` call that carries a key, word, touch point, event time **or an accessibility setting** (`reduceMotion`, `isVoiceOverRunning`, `isGuidedAccessEnabled`, `guidedAccessEnabled` and the like) outside `#if DEBUG`. Supporting run: `log stream --process <name> --level debug` on the release build during the scripted session shows no such line. (A clean run alone proves little: release logs redact dynamic strings as `<private>`, and `print` goes to stdout.) | Code scan: no `Log.*`/`println` with input outside the debug build type. Supporting run: `adb logcat --pid <pid>` on the release APK. NOT ASSESSED: no Android build (K-03). |

**Why so strict (one line per pillar or anti-pillar).**
- Pillar 5's design test chooses "none" over "a little".
- Guideline 1.3 says a Kids app "will need to continue to meet these guidelines in subsequent
  updates, even if you decide to deselect the category" [A1]. A rule relaxed later can't be undone
  by leaving the category.

### The COPPA position

COPPA (16 CFR Part 312) covers online services directed to children under 13. The game is directed to
children, so this position **assumes COPPA applies** until Luan answers L-02.

**What COPPA counts as personal information** (312.2, eCFR current text [C1], quoted in short):
- (1) a first and last name;
- (2) a home or other physical address;
- (3) online contact information, (4) a screen or user name that works like it, and (5) a phone number;
- (6) a government-issued identifier;
- (7) "A persistent identifier that can be used to recognize a user over time and across different
  websites or online services", including "an Internet Protocol (IP) address … or unique device
  identifier";
- (8) "A photograph, video, or audio file where such file contains a child's image or voice";
- (9) "Geolocation information sufficient to identify street name and name of a city or town";
- (10) "A biometric identifier that can be used for the automated or semi-automated recognition of an
  individual, such as fingerprints; … voiceprints; gait patterns; facial templates; or faceprints". This
  item was added by the 2025 amendments, published in the Federal Register on **2025-04-22**
  (FR Doc. 2025-05904) [C2].
- (11) other information that is collected from the child and combined with one of the above.

**Dates** [C2]: "Effective date: The amended Rule is effective June 23, 2025." "Compliance date:
Except with respect to Sec. 312.11(d)(1), (d)(4), and (g), regulated entities have until April 22,
2026 to comply." 

**The team's position** (wording agreed with game-qc-android):

> The app is designed to collect no personal information from children. While PKC-01 and the
> identifier and permission rules (PKC-04, PKC-05, PKC-06) pass in a given build, no
> parental-consent flow is built. This is the team's engineering position, not legal advice; whether
> COPPA applies is Luan's call. If any rule fails, or a feature adds collection (PKC-13), the
> position is re-opened before release.

Why the rules map to COPPA's list:
- No network (PKC-01) means nothing in the list can be "collected online", the IP address (7)
  included.
- No microphone or camera (PKC-06) rules out (8) and (10).
- No location (PKC-04) rules out (9).
- No identifiers (PKC-05) rules out (7) at the device level too.
- The FTC FAQ F.5 supports the on-device settings: "You are not collecting personal information
  simply because your app interacts with personal information that is stored on the device and is
  never transmitted" (TASK-034 B-09, [C3]). The Settings Store holds no personal information anyway.

### States and Transitions

This system has no runtime states. It has one process state per platform release:

| State | Meaning | Moves to |
|---|---|---|
| **Not assessed** | No check has run on this build, or the platform has no build (Android today) | Checked |
| **Checked** | Every PKC row has a verdict on this build | Gate verdict (below) |
| **Re-opened** | PKC-13 fired: a change adds network, location, data or an SDK | Not assessed, after the ADR and Luan's decision |

### The release gate

- **One gate per platform release** (iPadOS, macOS, later Android). Each PKC row gets a verdict on
  that platform's Release build: **PASS**, **FAIL** or **NOT ASSESSED**.
- The verdicts combine in the order **FAIL > NOT ASSESSED > PASS**:
  - any FAIL → the gate is **FAIL**;
  - otherwise, any NOT ASSESSED → the gate is **NOT ASSESSED**, and that **blocks the release** just
    like a FAIL (studio rule: NOT ASSESSED never counts as a pass);
  - only when every row is PASS → the gate is **PASS**.
- An Android NOT ASSESSED row doesn't block an Apple release, and the reverse: each platform has its
  own gate.
- The store rows (PKC-10, PKC-11) are PASS only with Luan's screenshot of the store form on file as
  evidence.
- Evidence goes to `production/qa/evidence/<task>/privacy-gate/` as the raw tool output (`codesign`,
  `otool`, `nm`, `plutil`, `nettop`, `aapt2`, `apkanalyzer`, `dumpsys`) plus one `results.md` with
  the row verdicts.

### Interactions with Other Systems

| System | What this GDD requires of it |
|---|---|
| Settings Store (#4) | Stores only R1 fields; uses `UserDefaults` (CA92.1) / SharedPreferences; no sync, no identifier; logs the field name, never a value (PKC-05, 09, 14) |
| Input & Key Filter (#2) | No input is logged in release (PKC-14) |
| Audio & Voice (#6) | Output only; no microphone, no speech recognition (PKC-06); bundled files (PKC-12) |
| Key Table & Theme Data (#1), Theme Packs (#18) | Bundle-only content (PKC-12). A downloadable theme pack would trigger PKC-13 |
| Parent Gate & Grown-up Panel (#12) | Everything that isn't play is behind it, including the bundled privacy text (PKC-07) |
| Child Lock-in (#13) | Kiosk exit is behind the gate (PKC-07); no extra entitlement beyond the allowlist |
| Scene: Time of Day & Weather (#15) | Clock and hand-picked weather only; any live weather → PKC-13 |
| App Shell & Title (#14) | No review prompt, no "more apps", no links (PKC-02) |
| Localization (#19) | A second voice is still bundled audio (PKC-12) |

---

## Formulas

Not applicable. This system defines no numeric rules: every threshold is an absolute zero (bytes,
permissions, SDKs, collected data types). The gate's combination order is a rule, given above.

---

## Edge Cases

- **Device backups (Luan, K-12, 2026-11-18): ALLOWED, settings only.** The Settings Store record
  holds no personal information, so the app doesn't exclude it.
  - Apple: "When iCloud Backup is in an enabled state, it periodically creates a backup of the user's
    device, including your app's data" [A9].
  - Android: Auto Backup "automatically backs up a user's data from apps that target and run on
    Android 6.0 (API level 23) or higher", uploading it "to the user's Google Drive", and by default
    includes "Shared preferences files" [G7].
  - A backup is the OS saving the user's own device to the user's own account. The app makes no
    request and receives nothing. QC's reading: this is not "collection" by the app (Apple's
    definition of collect is "transmitting data off the device" by "you and/or your third-party
    partners" [A2]). **Not verified** on an official page that names OS backups explicitly; Luan's
    call (L-07).
- **OS crash reports (platform-collected, opt-in).**
  - Apple: "The Crashes organizer presents crash reports from customers who share diagnostic and
    usage information" [A10]. TestFlight testers share crash reports automatically [A10].
  - Google: Android vitals "Data is collected from users who have opted in to automatically share
    usage and diagnostics data" [G6].
  - The app adds no crash SDK and sends nothing itself (PKC-01, PKC-03). **NOT SOURCEABLE:** neither
    Apple's App Privacy page nor Google's Data safety page, as read, says whether OS-collected crash
    reports must be declared. App privacy details lists "Crash Data" as a type to declare when *you
    or your partners* collect it [A2]. Luan's call (L-07).
- **A debug build that logs.** Allowed only in the console and only in debug (PKC-14). A debug log
  file in the container would also need a FileTimestamp entry if anything read its dates. Don't
  write one.
- **macOS and the privacy manifest.** Apple requires collected-data types "on all platforms" but
  required-reason APIs only "on iOS, iPadOS, tvOS, visionOS, and watchOS" [A4]. The Mac app ships the
  same `PrivacyInfo.xcprivacy` anyway: one file for both, and no harm in declaring CA92.1 on macOS.
- **A Mac build outside the Kids category.** If Apple doesn't offer "Made for Kids" for macOS
  (unverified, L-01), the Mac app still meets every PKC rule. One design, the stricter bar (TASK-034
  Part A's working rule).
- **Kids category is permanent.** "You can't change this selection once your app is approved by App
  Review. The app and all subsequent updates will need to follow the Kids category guidelines" [A8].
  Choosing it is Luan's call (L-03) and binds every later update.
- **A third-party SDK proposed later** (Rive, Lottie, an analytics kit). PKC-03 and PKC-13 apply: it
  needs its own ADR first. Rive's legacy Apple API defaults `loadCdn` to `true` and made a network
  request on file load in the TASK-033 spike (ADR-0001 §8).
- **The TTS voice pre-render** (K-13) runs at build time on the team's machines. Only its audio files
  ship. It is not an SDK in the app, and the voice-licence question stays with Luan (K-13).
- **A system framework opens a connection that our code never asked for.** PKC-01's runtime check is
  the backstop. Any byte attributed to the app's process is a FAIL, whatever caused it; QC records
  the host and the framework, and the fix is decided before release (remove the framework use, or
  re-open under PKC-13).
- **Accessibility features** (VoiceOver, Guided Access) are the OS's, not the app's. They add no
  data the app collects.
- **OS features the app could feed by default** (Handoff, Spotlight, Siri suggestions, state
  restoration). The app donates nothing: no `NSUserActivity` advertised for Handoff or search, no `CoreSpotlight`, no
  `Intents`/`AppIntents` donations (checked under PKC-12). macOS window-frame autosave and state
  restoration are turned off (Settings Store R2); anything the OS still keeps stays on the device.

---

## Dependencies

- **Constrains every system** (see Interactions). Hard dependency for: Settings Store, Parent Gate &
  Grown-up Panel, Child Lock-in, Scene: Time of Day & Weather, Theme Packs, App Shell.
- **Built on:** game-concept.md (Pillar 5, anti-pillars); ADR-0001 §8 (network none, no SDK without
  an ADR, the Rive rules); decisions K-08 (revised), K-12 (backups) and K-13 (build-time TTS);
  key-table-theme-data.md §5 (bundle-only themes); TASK-034 (`design/compliance/TASK-034-kids-weather-rules.md`,
  the Apple and COPPA readings).
- **Later:** the Android ADR takes the Android column of PKC-01…14 and the approved package list
  (§Tuning Knobs) as requirements.
- Android Families detail: `qa/TASK-032-kids-store-rules-android` @ ac7b97b (**detail, draft; unpushed
  WIP**, local to the QC worktree, so a reader may not be able to open it). It is not a source for
  any rule here.

## Tuning Knobs

The "knobs" are allowlists. **Safe range: exactly the values shown.** Any addition is a PKC-13
change. They control what the build is allowed to do, not anything the child sees or plays.

| Knob | Value now | Who changes it |
|---|---|---|
| Apple entitlements allowlist (release) | iPadOS: only the signing defaults. macOS: those plus `com.apple.security.app-sandbox` = true. Nothing else. **The exact signing-default keys are pinned by release-manager from the first Release archive, before AC1 first runs (not verified yet):** for example `com.apple.application-identifier` on macOS, `get-task-allow` false or absent, `beta-reports-active` on TestFlight builds | An ADR + Luan |
| Privacy manifest `NSPrivacyAccessedAPITypes` | `UserDefaults` / `CA92.1` (+ `SystemBootTime` / `35F9.1` only if used) | Lead programmer, checked by QC |
| Android permission allowlist (merged manifest) | none of the dangerous or network permissions above. Not verified: AndroidX core may merge `<package>.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, a signature permission of our own package; the Android ADR pins the list | The Android ADR + Luan |
| Android approved package list (dex) | our package, `kotlin`, `kotlinx`, the AndroidX packages named in the Android ADR | The Android ADR |
| Scripted session for runtime checks | 10 minutes, in this order: all 36 keys; a parade; the parent panel opened; **every setting changed once**; the panel closed; the app backgrounded and resumed; **snapshot of the preferences domain** (AC7 reads this); then the panel's **"Start over"** (Settings Store R9) and a second snapshot | QC |

---

## Platform notes

### macOS and the Kids category (L-01): not verified

- **Verified now** [A8]: "If your calculated rating is 4+ or 9+ and you want your app to also display
  in the Kids category on the App Store, under Age Categories and Override, choose Made for Kids and
  from the menu, select the appropriate age range for your app." And: "You can't select the Made for
  Kids option for visionOS apps, and apps in the Kids category can't be made available on visionOS
  apps." So visionOS is excluded by name. **macOS is not named either way.**
- **To verify:** Luan opens the age-rating screen of the macOS platform version in App Store Connect
  and records whether "Made for Kids" is offered.

### Android (for its later ADR)

- The PKC table's Android column is the requirement list.
- In short: no `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `AD_ID`, `READ_PHONE_STATE`,
  location, `CAMERA`, `RECORD_AUDIO` or `BILLING` permission in the **merged** manifest. No billing,
  ads or analytics packages. No start of another app.
- Families policy, verbatim [G1]:
  - "Apps that solely target children must not transmit Android advertising identifier (AAID), SIM
    Serial, Build Serial, BSSID, MAC, SSID, IMEI, and/or IMSI."
  - "Apps solely targeted to children should not request AD_ID permission when targeting Android API
    33 or higher."
  - "Apps that solely target children may not request location permission, or collect, use, and
    transmit precise location."
  - "Apps that solely target children must not contain any APIs or SDKs that are not approved for use
    in primarily child-directed services."
- [G2]: "By updating to target API level 33 and not including the permission, AAID will automatically
  be disabled (set to a string of zeros)."

---

## Luan's calls (legal and store)

| # | Call | Recommendation | Source |
|---|---|---|---|
| L-01 | Is the Kids category offered for the **macOS** app? | Check App Store Connect (above) | [A8] |
| L-02 | **COPPA position**: accept the engineering position above, or get legal advice | Accept while the PKC rows pass; re-open on PKC-13 | [C1][C2] |
| L-03 | **Apple age band and rating**: "Made for Kids", "5 and under". It is permanent once approved | Choose it; the game meets the rules already | [A3][A8] |
| L-04 | **Privacy policy**: write it; put its URL in App Store Connect and Play Console; in the app, as bundled text behind the gate | Bundled text (keeps PKC-01/02 clean). A gated link instead is a PKC-13 change with a named exception to PKC-01/02 | 5.1.4 [A1]; [G3][G4][G5] |
| L-05 | **App Privacy answers**: "Data Not Collected" | Yes, if the gate passes | [A2] |
| L-06 | **Google Play**: target audience "Ages 5 & Under" only; Data safety "No data collected" (the form is required even then); privacy policy in Play Console and in the app; **Teacher Approved** optional; the Play developer account | As listed | [G1][G3][G4][G5] |
| L-07 | Are OS device backups and OS crash reports outside "collection" for the labels and COPPA? | QC's reading: yes (Edge Cases); not stated on an official page | [A2][A9][A10][G6][G7] |
| L-08 | Laws beyond COPPA (GDPR / UK Age Appropriate Design Code, Vietnam) | Out of scope here (TASK-034 F-09). Families says to comply with "COPPA, E.U. General Data Protection Regulation (GDPR), and any other applicable laws" [G1] | [G1] |
| L-09 | The voice licence for the pre-rendered TTS, and the later human re-record | Open (K-13) | K-13 |

Google wording for L-06, verbatim:
- [G4]: "Even developers with apps that do not collect any user data must complete this form and
  provide a link to their privacy policy."
- [G5]: "Have a valid privacy policy in both the app's store listing and within the app itself."
- [G3]: "For example, an app designed for toddlers should only have the age group "Ages 5 and under"
  selected." The Families policy page writes it as "Ages 5 & Under" [G1].
- [G1]: "All apps that comply with Google Play Families policies can opt in to be rated for the
  Teacher Approved program, but we cannot guarantee that your app will be included".

---

## Acceptance Criteria

Each criterion is checked on the **Release build** of the platform being released, and its evidence
is retained under `production/qa/evidence/`. For Android every criterion is NOT ASSESSED until an
Android build exists (K-03).

1. **AC-01 · PKC-01 entitlements:** the release entitlements equal the allowlist exactly: no
   `network.client`/`network.server`, no iCloud, push, Game Center or associated domains (macOS:
   app-sandbox true). Android: the merged-manifest permission list is empty of `INTERNET` and
   `ACCESS_NETWORK_STATE`.
2. **AC-02 · PKC-01 runtime:** GIVEN the 10-minute scripted session, THEN `nettop` attributes **0 bytes** in
   and out to the app, and macOS logs **0** sandbox network denials for it. Android: `dumpsys
   netstats` rx/tx 0 for the uid.
3. **AC-03 · PKC-01/02/04/05/06/09/12 API scan:** the scan was first proven on the fixture binary (it lists
   every named API, `openURL:` and `systemUptime` included). On the release build, both passes
   (`nm -um`; `otool -ov` + `strings -a`) and `otool -L` on every Mach-O show none of the APIs and frameworks named in those rows (PKC-12 includes the Handoff, Spotlight and Siri donation APIs). Any hit is read by a person: a hit in a system stub is noted, and
   a hit from our code is a FAIL.
4. **AC-04 · PKC-02 child area:** every key A–Z and 0–9, and every touch target in the child area (the
   hint letters, cast members, the parade, the keyboard row when on, and any other target in QC's screen inventory `production/qa/privacy-gate/touch-targets.md`, which QC writes from the Reveal Stage, Hint Letters, Parade and keyboard row GDDs before the first gate run), tried once each: nothing opens Safari, a web view, the App Store, a share sheet, a review prompt or another
   app. Android: no `START` of another package in logcat.
5. **AC-05 · PKC-03 third-party code:** no remote package (`Package.resolved` absent or without pins, no
   `XCRemoteSwiftPackageReference`), the local packages are only `KidCore` (and `MorphCore`), and there
   is no Pods/Carthage/binary framework; `otool -L` lists only system paths and our own frameworks;
   the Swift module names in the binary are Apple's, the app target's or ours. The bundle holds no
   third-party framework or third-party privacy manifest. Android: `apkanalyzer dex packages --defined-only --proguard-mappings` (the same build's `mapping.txt`, kept) shows every package in the approved list; without that mapping, NOT ASSESSED.
6. **AC-06 · PKC-04/06/08 Info.plist:** no `NS*UsageDescription` key of any kind, no URL types, no queried
   schemes, no ATS exceptions. Android: no location, `CAMERA` or `RECORD_AUDIO` permission and no
   `<queries>`.
7. **AC-07 · PKC-05 stored data:** in the scripted session's first snapshot (after every setting changed),
   the app's preferences domain holds exactly one app-written key, `settings`, whose decoded value
   holds only the Settings Store R1 fields: no UUID, no identifier, no timestamp, no date. In the
   second snapshot (after "Start over"), no app-written key remains, or only an empty record. OS-written
   keys are listed and ignored.
8. **AC-08 · PKC-07 gate:** from each child-area screen, every grown-up item (settings, weather, theme,
   keyboard row, kiosk exit, privacy text) is reachable only after the gate, and the privacy text
   opens with no network.
9. **AC-09 · PKC-09 manifest:** `PrivacyInfo.xcprivacy` in the built app has `NSPrivacyTracking` false, no
   tracking domains, no collected data types, `UserDefaults`/`CA92.1`, no `FileTimestamp`, `DiskSpace`
   or `ActiveKeyboards`; and
   `SystemBootTime`/`35F9.1` is present if and only if our code calls `systemUptime` or
   `mach_absolute_time`. The Xcode privacy report agrees.
10. **AC-10 · PKC-10/11 store forms:** Luan's screenshots show App Privacy "Data Not Collected" and "Made for
    Kids", "5 and under" (macOS: or "Made for Kids" not offered, recorded as such; Android later: Data safety "No data collected", target audience "Ages 5 &
    Under" only). QC finds no PKC row that contradicts them.
11. **AC-11 · PKC-12 content:** every file the theme validator lists is inside the bundle, and the binary has
    no On-Demand Resources or Background Assets use and makes no Handoff, Spotlight or Siri donation.
12. **AC-12 · PKC-13 change gate:** a test PR that adds one entitlement (or one Android permission, or one
    package dependency) is flagged by QC's review checklist and not merged before an ADR and Luan's
    decision exist. (A checklist dry run; the PR is not merged.)
13. **AC-13 · PKC-14 logs:** the code scan finds no `print`, `debugPrint`, `NSLog`, `os_log` or `Logger` call
    carrying a key, word, touch point, event time or an accessibility setting outside `#if DEBUG` (Android:
    outside the debug build type). Supporting: during the scripted session on the release build, the console at debug
    level shows no such line.
14. **AC-14 · Release gate:** the platform's `results.md` lists every PKC row with a verdict, and the gate
    verdict follows FAIL > NOT ASSESSED > PASS. A gate with any NOT ASSESSED row is not a release.

---

## Open Questions / not verified

| # | Question | Status |
|---|---|---|
| Q1 | Kids category on macOS | Not verified; L-01 |
| Q2 | Do OS backups and OS crash reports count as collection for labels and COPPA? | Not stated on an official page; L-07 |
| Q3 | Does a privacy notice shown behind the parent gate meet COPPA 312.4(d) "prominent … on the home or landing page"? It matters only if COPPA's notice duty applies when nothing is collected | Not verified (TASK-034 F-08); L-02/L-04 |
| Q4 | The iPad runtime network check: an Instruments network trace on the device vs `nettop` on the simulator. Which is release evidence? | QC proposes: the device trace for release, the simulator `nettop` for every build |
| Q5 | The Android approved package list | Set by the Android ADR |

---

## Sources (all read raw on 2026-11-18 unless marked)

- [A1] Apple, App Review Guidelines ("Last Updated: October 16, 2026"), sections 1.3, 5.1.1, 5.1.4, 5.1.5: https://developer.apple.com/app-store/review/guidelines/
- [A2] Apple, App privacy details on the App Store: https://developer.apple.com/app-store/app-privacy-details/
- [A3] Apple, Design safe and age-appropriate experiences (Kids category, age bands, parental gates): https://developer.apple.com/app-store/kids-apps/
- [A4] Apple, Privacy manifest files: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- [A5] Apple, Describing use of required reason API, and NSPrivacyAccessedAPIType (CA92.1, 35F9.1, the file-timestamp APIs): https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api ; https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype
- [A6] Apple, NSCameraUsageDescription, NSMicrophoneUsageDescription: https://developer.apple.com/documentation/bundleresources/information-property-list/nscamerausagedescription ; …/nsmicrophoneusagedescription
- [A7] Apple, entitlements `com.apple.security.network.client`, `com.apple.security.device.camera`, `com.apple.security.device.audio-input` (macOS): https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.network.client (and siblings)
- [A8] Apple, App Store Connect Help, Set an app age rating ("Made for Kids", visionOS exclusion, permanence): https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating
- [A9] Apple, Optimizing your app's data for iCloud Backup: https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup
- [A10] Apple, Acquiring crash reports and diagnostic logs: https://developer.apple.com/documentation/xcode/acquiring-crash-reports-and-diagnostic-logs
- [C1] eCFR, 16 CFR 312.2 Definitions (current text, version 2026-11-13, via the eCFR API): https://www.ecfr.gov/current/title-16/chapter-I/subchapter-C/part-312/section-312.2
- [C2] Federal Register, Children's Online Privacy Protection Rule, FR Doc. 2025-05904, 90 FR 16918, published 2025-04-22 (DATES section): https://www.federalregister.gov/documents/2025/04/22/2025-05904/childrens-online-privacy-protection-rule
- [C3] FTC, Complying with COPPA: Frequently Asked Questions (F.5; read 2026-11-17 for TASK-034): https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions
- [G1] Google, Play Console Help, Google Play Families Policies (answer 9893335): https://support.google.com/googleplay/android-developer/answer/9893335
- [G2] Google, Play Console Help, Data practices in Families apps (answer 11043825): https://support.google.com/googleplay/android-developer/answer/11043825
- [G3] Google, Play Console Help, Manage target audience and app content settings (answer 9867159): https://support.google.com/googleplay/android-developer/answer/9867159
- [G4] Google, Play Console Help, Provide information for Google Play's Data safety section (answer 10787469): https://support.google.com/googleplay/android-developer/answer/10787469
- [G5] Google, Play Console Help, User Data (answer 10144311): https://support.google.com/googleplay/android-developer/answer/10144311
- [G6] Google, Play Console Help, Monitor your app's technical quality with Android vitals (answer 9844486): https://support.google.com/googleplay/android-developer/answer/9844486
- [G7] Android Developers, Back up user data with Auto Backup: https://developer.android.com/identity/data/autobackup
