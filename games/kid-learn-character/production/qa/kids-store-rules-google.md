# Kid Learn Character: Google Play Families + COPPA rules, and the first Android test cases

**Task:** TASK-032 (Android half). **Owner:** game-qc-android. **Written:** 2026-11-17.
**Based on:** `design/game-brief.md` @ 3eabe74. The Apple half is game-qc-ios's file.
**Status:** desk work. Nothing here has been run, because no build exists yet. Every row below
is a plan for checking something, not a result.

## How to read this file

- **Verdicts per check:** PASS / FAIL / NOT ASSESSED (with the reason). A check that has no
  evidence file is **NO EVIDENCE**, not PASS. A FAIL outranks NOT ASSESSED.
- **Sources:** each policy row names the Google or FTC page it comes from (list at the end). These
  pages change, and several were more than 1,000 days old when found. **Re-read the live page
  before each store submission** and record the date read in the results file. If a row cannot
  be tied to a current page, it is **NOT SOURCEABLE** and its check reports NOT ASSESSED.
- **QC is not legal review.** QC checks that the build and the store listing do what the brief
  promises. Whether the app meets COPPA, GDPR-K or other laws is Luan's call, with advice if
  he wants it. Those rows are marked **Luan** in the "who decides" column.
- **Tools** (already in `~/Android/sdk`, nothing new to install): `adb`, `build-tools/35.0.1/aapt2`,
  `cmdline-tools/*/bin/apkanalyzer`. Network checks use the emulator's own traffic stats
  (`adb shell dumpsys netstats`, `/proc/net/xt_qtaguid` or `cat /proc/<pid>/net/dev`), not a new proxy.

## The design choice that makes most checks easy

The brief says: **no network, no ads, no in-app purchases, no accounts, no links out, no data
collected**. The strongest single check follows from that: **the APK must not request
`android.permission.INTERNET`**. Without that permission the app cannot send anything, so most
data rows below reduce to "the permission is absent, and no SDK is bundled". If the team ever
adds the INTERNET permission (for example for a crash reporter), every data row must be
re-checked from scratch, and that change needs a decision recorded in `decisions.md` first.

---

## Part A: Google Play Families policy checklist

| # | Rule (short) | Source | How QC verifies it | Evidence file | Who decides |
|---|---|---|---|---|---|
| F-01 | **Target audience = "Ages 5 & Under" only.** Google's guidance: toddler and preschool apps pick only that group. Picking older groups as well needs a reason. | [S4], [S2] | Screenshot of Play Console → App content → Target audience. Check that only "5 & Under" is ticked. | `F-01-target-audience.png` | Luan (QC checks it matches) |
| F-02 | **The app follows the Families policies** because children are the target audience. | [S2] | This whole Part A. Each row has its own verdict. | `results.md` | QC |
| F-03 | **No ads.** If ads were ever added, only Families self-certified ad SDK versions are allowed, with no interest-based ads or remarketing to children. | [S1], [S2] | (a) `apkanalyzer dex packages app.apk`: search for ad SDK package names (`com.google.android.gms.ads`, `com.applovin`, `com.unity3d.ads`, `com.facebook.ads`, `com.ironsource`, `com.vungle`, `com.chartboost`, `com.mopub`) and any other `*ads*` package. (b) `aapt2 dump xmltree app.apk --file AndroidManifest.xml`: no `com.google.android.gms.ads.APPLICATION_ID` meta-data, no `AD_ID` permission. (c) Play through every key and confirm no ad appears. | `F-03-dex-packages.txt`, `F-03-manifest.txt` | QC |
| F-04 | **No analytics or other SDK that sends data** (Firebase Analytics, Crashlytics, Facebook SDK, Adjust, AppsFlyer and similar). Families apps must disclose any data that SDKs collect, and must not send device IDs from children (next row). | [S3], [S2] | Same `apkanalyzer dex packages` dump: list every third-party top-level package. Each package not in the team's approved list is a FAIL until the dev explains it. The list is kept in `results.md`. | `F-04-third-party-packages.txt` | QC; adding any SDK is Luan's decision |
| F-05 | **No device identifiers sent from children**: AAID, SIM serial, build serial, BSSID, MAC, SSID, IMEI, IMSI. | [S3] | (a) No `INTERNET` permission (row F-06), so nothing can be sent. (b) No `com.google.android.gms.permission.AD_ID` permission in the merged manifest. (c) No `READ_PHONE_STATE`, `ACCESS_WIFI_STATE` or `ACCESS_FINE/COARSE_LOCATION`. | `F-05-permissions.txt` | QC |
| F-06 | **No network at all** (brief rule). | brief | (a) `aapt2 dump permissions app.apk`: `android.permission.INTERNET` and `ACCESS_NETWORK_STATE` absent. (b) Play for 5 minutes on the emulator and read the app's traffic: `adb -s <serial> shell dumpsys netstats detail` for the app's UID shows 0 bytes. | `F-06-permissions.txt`, `F-06-netstats.txt` | QC |
| F-07 | **Only the permissions the game needs.** The expected list is empty, or only harmless ones (`VIBRATE`, `WAKE_LOCK`). No camera, microphone, contacts, location, storage or notifications. | [S2], brief | `aapt2 dump permissions app.apk` compared with the approved list in `results.md`. Any extra permission is a FAIL until a decision allows it. | `F-07-permissions.txt` | QC |
| F-08 | **No in-app purchases.** | brief, [S2] | No `com.android.vending.BILLING` permission and no `com.android.billingclient` package in the dex dump. Play Console shows "No in-app products". | `F-08-billing.txt` | QC |
| F-09 | **No links out of the app** (web, store, social), and no cross-promotion. If a link is ever added, it sits behind the parent gate. | brief, [S2] | (a) Play all 36 keys and the parent area: no tap opens a browser or the Play Store (watch `adb logcat` for `ActivityTaskManager: START` of another package). (b) Search the strings: `aapt2 dump strings app.apk` plus `apkanalyzer dex packages` for `http`/`market://` URLs. | `F-09-logcat.txt`, `F-09-strings.txt` | QC |
| F-10 | **Parent gate** in front of anything that is not play (settings, language, the privacy policy link). A toddler must not get past it by mashing. | brief, [S2] | Test cases TC-20 to TC-22 below. | `TC-20…22-*.png` | QC; the gate design is the devs' and Luan's |
| F-11 | **Content fits the youngest group**: no scary images or sounds for a 2-year-old, no violence. A roaring dinosaur must not be frightening (volume, picture). | [S2], [S4] | Screenshot and watch every one of the 36 keys; note any picture or sound a parent might find scary. QC flags it; it does not judge it alone. | `TC-01-<key>.png` (36 files) | game-art-content + Luan |
| F-12 | **Store listing fits Families**: the icon, screenshots and text suit children, and the listing does not claim things the app does not do (such as "Teacher Approved" before it is). | [S2] | Read the draft listing before submission; screenshots must come from the real build. | `F-12-listing.png` | Luan |
| F-13 | **Data safety form is filled in**, even though the app collects nothing: "No data collected, no data shared". | [S5] | Screenshot of Play Console → App content → Data safety. Compare each answer with rows F-03 to F-08. If any SDK or permission was found, the form must declare it, so that is a FAIL. | `F-13-data-safety.png` | Luan fills it in; QC compares it with the build |
| F-14 | **Privacy policy link** in Play Console **and** inside the app (link or text). It must say that no data is collected. Inside the app it sits behind the parent gate. | [S6] | (a) Screenshot of the Play Console field. (b) In the app, open the policy through the parent gate. (c) The policy text matches the build (no SDKs, no data). | `F-14-console.png`, `F-14-in-app.png` | Luan writes it; QC checks that it exists and matches |
| F-15 | **Teacher Approved basics** (optional and not guaranteed, rated by Google's reviewers): design, appeal, enrichment, age fit, ads, in-app purchases, cross-promotion, audio and language quality, navigation for the age, visual quality. | [S7], [S8] | QC can't grant this. QC checks what it can see: voice clear at the default volume (TC-02), no text the child must read (TC-03), keys big enough (TC-30 to TC-33), and no ads, purchases or cross-promotion (F-03, F-08, F-09). | covered by those TCs | Google decides; Luan chooses whether to opt in |

## Part B: COPPA basics (US law, children under 13)

COPPA applies to apps aimed at children under 13 that **collect personal information**. Kid
Learn Character is designed to collect none, so the QC job is to prove that is still true in
each build. The FTC amended the rule in 2025 (published 2025-04-22, effective 60 days later,
most changes with about one year to comply). **NOT SOURCEABLE:** QC did not find the exact
compliance date stated by the FTC; it is about 2026-04-22 by calculation. Luan should confirm it
if the app ever collects anything. Sources: [S9], [S10], [S11].

| # | COPPA point | How QC verifies it for this app | Who decides |
|---|---|---|---|
| C-01 | **No personal information collected**: no name, email, phone, photo, voice, location, persistent identifiers, and (since 2025) no biometric identifiers. | Rows F-05, F-06, F-07: no INTERNET permission, no camera or microphone permission, no ID permissions. The app does not ask the child to type a name. | QC |
| C-02 | **No disclosure to third parties.** Since 2025 this needs separate parental consent, including for targeted ads. | F-03 and F-04: no ad or analytics SDK, and no network. | QC |
| C-03 | **No verifiable parental consent flow needed**, *because* nothing is collected. If that changes, a full consent flow is needed before release. | Recorded as an assumption in `results.md`; it holds while C-01 and C-02 PASS. | Luan |
| C-04 | **Data kept on the device only** (for example a parent's language setting) stays on the device and never leaves it. | After using the parent settings, check `adb -s <serial> shell run-as <pkg> ls -R` shows only settings files; F-06 shows no traffic. Also check backup: `android:allowBackup` and `dataExtractionRules` in the manifest. If backup is on, the device's Google backup copies the settings; note it for Luan. | QC notes; Luan decides |
| C-05 | **Written data retention policy** (new in 2025) applies only to collected personal information. Nothing collected means nothing to keep; the privacy policy says so. | Part of F-14's text check. | Luan |

---

## Part C: First Android test cases for the core loop

**Devices:** emulator mp17863 (API level written in each results file) as a phone; a tablet AVD
(10-inch, landscape) when one exists. **No new AVD or system image is installed without Luan's
OK.** A real low-end phone and a tablet with a Bluetooth keyboard are added when available.
**Every device command names its target** (`adb -s <serial>`).

**Content set under test:** A–Z and 0–9 (36 keys) from the data table owned by game-art-content
(TASK-029). QC reads the expected picture and words from that JSON, not from memory.

### C1. Key → picture + sound (touch)

| ID | Steps | Expected | Evidence |
|---|---|---|---|
| TC-01 | Tap each of the 36 on-screen keys once, with a pause between taps. | Each tap shows that key's picture full screen with its animation, plays the object sound (if it has one) and says the letter or number plus the word ("D… dinosaur"; "one"). The picture matches the data table. | `TC-01-<key>.png` per key; one screen recording of the full run |
| TC-02 | Note the time from tap to picture and to the first sound, using frame timing and `adb logcat` timestamps. | The picture appears "within a moment" (target set by the devs; QC proposes ≤ 150 ms to first frame and ≤ 250 ms to sound, for the leader to confirm). The voice is clear at the default media volume. | `TC-02-latency.txt` |
| TC-03 | Look at every screen a child can reach without the parent gate. | No text the child must read to play, no timer, no score, no fail screen. Letters and numbers shown as the subject are fine. | `TC-03-<screen>.png` |
| TC-04 | Start the app with the device on mute (media volume 0), then raise the volume while a picture shows. | No crash. The picture still shows. The sound works for the next key press. | `TC-04.png` |
| TC-05 | Start the app in airplane mode (cold start). | It starts and plays every key. All pictures and sounds are inside the app. | `TC-05-airplane.png` |

### C2. Hardware / Bluetooth keyboard

| ID | Steps | Expected | Evidence |
|---|---|---|---|
| TC-10 | Emulator with the host keyboard (`hw.keyboard=yes` in the AVD settings): press A–Z and 0–9. | Same result as TC-01 for each key. | `TC-10-<key>.png` (spot-check 6 keys plus a recording of all) |
| TC-11 | Press the same keys with **Shift** and with **Caps Lock** on. | "a" and "A" give the same result. Shifted digits (`!`, `@`…) do whatever the devs decide (ignored or mapped to the digit). QC records it; the rule must be in the data table. | `TC-11.txt` |
| TC-12 | Press the numeric keypad digits (`KEYCODE_NUMPAD_0…9`), sent with `adb -s <serial> shell input keyevent`. | Same as the top-row digits. | `TC-12.txt` |
| TC-13 | Press keys that are not in the set: Space, Enter, Tab, arrows, F-keys, Esc, Ctrl, Alt, the Search/Meta key, media keys. | Nothing breaks. No crash, no leaving the app. Esc and Back must not leave the app without the parent gate (see TC-23). | `TC-13.txt` |
| TC-14 | Plug in or remove the keyboard while a picture shows (emulator: switch the keyboard setting; device: Bluetooth on and off). | No restart of the activity (the `keyboard`/`keyboardHidden` config change is handled), no lost state, no crash. | `TC-14.png` |
| TC-15 | Real Android tablet + Bluetooth keyboard (when available). | Same as TC-10 and TC-13. Device and keyboard model recorded. Until a device exists: **NOT ASSESSED — no tablet or Bluetooth keyboard**. | `TC-15-<key>.png` |
| TC-16 | With a hardware keyboard attached, check whether the on-screen keyboard (IME) appears. | The system soft keyboard never pops up over the game. | `TC-16.png` |

### C3. Mashing

| ID | Steps | Expected | Evidence |
|---|---|---|---|
| TC-20 | Tap random on-screen keys as fast as possible for 60 s. Use touch events streamed through one `cat` into the touch device, not one `sendevent` per event, so the timing is real. Also mash with several fingers at once. | The latest key press always wins at once. Sounds do not stack into noise (one voice at a time, or the design's stated limit). No freeze, no ANR, no crash. Memory does not grow without limit. | `TC-20-before.png`, `TC-20-after.png`, `TC-20-meminfo.txt` (`dumpsys meminfo <pkg>` at start and end) |
| TC-21 | Hardware keyboard mash: hold a key down (auto-repeat) for 10 s, then roll the whole hand across the keyboard. | Auto-repeat does not queue hundreds of sounds. The game stays responsive and shows the last key. | `TC-21.png`, `TC-21-logcat.txt` |
| TC-22 | Mash on the parent gate and near the settings button for 60 s. | The gate is never passed by mashing. Settings are never opened. | `TC-22.png` |

### C4. Back / Home mid-sound

| ID | Steps | Expected | Evidence |
|---|---|---|---|
| TC-23 | Press **Back** (and the back gesture) while a sound plays. | The game does what the parent-gate design says (most likely stays in the game, or asks the grown-up check). It never leaves with sound still playing. | `TC-23.png` |
| TC-24 | Press **Home** while a sound plays. | The sound stops at once (audio focus released, no sound playing over the home screen). | `TC-24.png`, `TC-24-audio.txt` (`dumpsys audio` shows no active player for the app) |
| TC-25 | After TC-24, open the app again from Recents. | It comes back to the keyboard (or the last picture), with no doubled sound, no crash and no blank screen. | `TC-25.png` |
| TC-26 | Open Recents, swipe the app away, and start it again. | Clean cold start. | `TC-26.png` |
| TC-27 | Lock the screen with the power key while a sound plays, then unlock. | The sound stops when locked. The game works after unlock. | `TC-27.png` |
| TC-28 | Audio focus: start music in another app, then open the game and press a key. Also play a fake incoming call or alarm (`adb emu gsm call` on the emulator) while a sound plays. | The game asks for audio focus correctly. The call or alarm wins, and the game is quiet during it. | `TC-28.png` |

### C5. Screen pinning

| ID | Steps | Expected | Evidence |
|---|---|---|---|
| TC-29 | Turn on Settings → Security → App pinning, pin the game, and mash all keys and gestures. | The game plays normally while pinned. Back, Home and Recents do not leave it. Unpinning needs the grown-up gesture (and the PIN, if set). | `TC-29-pinned.png` |
| TC-29b | If the devs add a "lock the game" button (`startLockTask`), test it behind the parent gate. | Same as TC-29. Without device-owner rights, Android asks the user to confirm. | `TC-29b.png` |

### C6. Tablet and phone sizes

| ID | Steps | Expected | Evidence |
|---|---|---|---|
| TC-30 | Phone, portrait and landscape (emulator mp17863). | All 36 keys are visible without scrolling, and each is big enough for a toddler's finger (target from the devs; QC proposes ≥ 64 dp). The picture fills the screen. | `TC-30-portrait.png`, `TC-30-landscape.png` |
| TC-31 | Tablet 10-inch, landscape (tablet AVD, when Luan approves creating one; otherwise **NOT ASSESSED — no tablet AVD**). | Same as TC-30, with no stretched or blurry pictures. | `TC-31.png` |
| TC-32 | Small phone (about 5-inch, 720p) and a large display font size (Settings → Display size and font size at the maximum). | Keys still fit and do not overlap. The layout does not break. | `TC-32.png` |
| TC-33 | Rotate while a picture shows and while a sound plays. | No restart of the sound, no crash, no lost picture. | `TC-33.png` |
| TC-34 | Split screen / multi-window (if the app allows it), and a display cutout (notch). | Keys stay inside the safe area. If multi-window is not supported, the manifest says `resizeableActivity="false"` and QC records it. | `TC-34.png` |

---

## Open questions for the leader (they do not block this file)

1. **Latency target** for TC-02 and **key size** for TC-30: the brief says "within a moment" and
   "big keys". QC proposed numbers; the devs or Luan should set them.
2. **Back behaviour** (TC-23) and the **parent gate design** (F-10): the gate must be chosen
   before TC-22 and TC-23 can PASS or FAIL.
3. **A tablet AVD and a Bluetooth keyboard**: creating a tablet AVD downloads nothing new if it
   reuses an installed system image, but it still needs Luan's OK. Without it, TC-15 and TC-31
   are NOT ASSESSED.

## Sources (read 2026-11-17; re-read before each submission)

- [S1] Families Self-Certified Ads SDK Policy: https://support.google.com/googleplay/android-developer/answer/12918983
- [S2] Google Play Families Policies: https://support.google.com/googleplay/android-developer/answer/9893335
- [S3] Data practices in Families apps: https://support.google.com/googleplay/android-developer/answer/11043825
- [S4] Manage target audience and app content settings: https://support.google.com/googleplay/android-developer/answer/9867159
- [S5] Provide information for Google Play's Data safety section: https://support.google.com/googleplay/android-developer/answer/10787469
- [S6] User Data policy (privacy policy in Play Console and in the app): https://support.google.com/googleplay/android-developer/answer/10144311
- [S7] Build Teacher Approved apps: https://play.google.com/console/about/programs/teacherapproved/
- [S8] Find family-friendly content in Google Play: https://support.google.com/googleplay/answer/6209531
- [S9] FTC, Complying with COPPA: FAQ: https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions
- [S10] FTC press release on the 2025 COPPA changes: https://www.ftc.gov/news-events/news/press-releases/2025/01/ftc-finalizes-changes-childrens-privacy-rule-limiting-companies-ability-monetize-kids-data
- [S11] 16 CFR Part 312, COPPA final rule amendments: https://www.ftc.gov/legal-library/browse/federal-register-notices/16-cfr-part-312-coppa-final-rule-amendments
