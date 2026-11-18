# Device checks plan: every NOT ASSESSED check that needs Luan's Mac or iPad

> **Task**: TASK-074 · **Author**: game-qc-ios · **Date**: 2026-11-18 · **Review**: game-qc-android
> Documentation only: nothing here has been run. Every row stays **NOT ASSESSED** until its session runs and
> its evidence file exists.

## How to read this

- **MAC FREE** (K-34): anything that takes the Mac's screen, keyboard or focus (the macOS app, macOS UI tests, the
  kiosk, key injection, nettop or log stream sessions, a visible Simulator window). Headless runs (`swift test`,
  `xcodebuild build`, tests on the developer's own headless simulator at nice 10, stopping above load ~40) need no
  MAC FREE and are **not** in this plan.
- **Luan does** = it needs Luan's hands, Apple ID, eyes on a physical screen, or a second device. **Worker does** =
  a QC or dev session drives it once Luan has granted MAC FREE or handed over the iPad.
- Durations are estimates for planning, including set-up, not measured.
- Evidence follows ADR-0011 D6 (Proposed): `production/qa/evidence/<run task id>/<short-sha of the build under
  test>/<check-id>/` as raw files (screenshots, logs, tool output, videos), plus one `results.md` per session with a
  PASS / FAIL / NOT ASSESSED line per check. ADR-0011 is still Proposed, so this path may change when it is
  accepted. The table's `mac-1/M-1/`-style names below are the `<check-id>` folders
  inside that path.
- QC's simulator (E9F515E9…) is never used for the dev-only kill tests (ADR-0005 D3).

## Flags: Apple ID and device settings

| # | What | Who | Where | Reversible |
|---|---|---|---|---|
| F-1 | **Luan's Apple ID** signs into Xcode for the free **Personal Team** (K-28); 7-day provisioning, so a build installed for iPad session 1 must be re-signed if the session is more than 7 days later | Luan | Xcode › Settings › Accounts | yes (remove the account) |
| F-2 | **Developer Mode on the iPad** (needed to run a Personal Team build); the iPad restarts | Luan | iPad Settings › Privacy & Security › Developer Mode | yes |
| F-3 | **Trust the developer certificate** on the iPad | Luan | iPad Settings › General › VPN & Device Management | yes |
| F-4 | **Guided Access** set up with a passcode on the child's iPad | Luan | iPad Settings › Accessibility › Guided Access | yes |
| F-5 | `tccutil reset ListenEvent <bundle id>` on the Mac (resets Input Monitoring for **this app's bundle only**) | worker, with Luan's OK | Terminal | yes (no other app affected) |
| F-6 | A **second display** connected to the Mac (AC-14) | Luan | — | yes |
| F-7 | The Mac **sleeps** (lid closed or display sleep) and needs **Luan's login** on wake (AC-16) | Luan | — | yes |
| F-8 | A phone that records **240 fps slow motion** (TASK-033 procedure) | Luan | — | — |
| F-9 | **Reduce Motion / Smart Invert** toggled in the device's Accessibility settings during the runs, then put back | worker (Mac), Luan (iPad) | Settings › Accessibility | yes |

## The checks

| ID | Check | Source | Device | Luan does | Worker does | Time | Needs first | Evidence |
|---|---|---|---|---|---|---|---|---|
| M-1 | **No Input Monitoring prompt** on a clean Mac: reset (F-5), first launch with the lock on, press ⌃⌥⌘Q; no prompt, gate opens, app not listed in Privacy & Security › Input Monitoring. If it prompts, the key-state read is removed from the build and k3 is re-run on the held-set path | Input AC-1k6 (release-blocking, macOS); Parent Gate AC-27; PKC (no system dialog) | Mac | grant MAC FREE; OK for F-5; read the screen for a prompt | run F-5, launch, press the chord, screenshot Privacy & Security | 10 min | macOS app build with Input R6 and the gate | `mac-1/M-1/` screenshots + `tccutil` output |
| M-2 | **⌘ swallowed before the chord works**: with the lock stored ON, ⌘-keys are swallowed from the settings read, possibly before the ⌃⌥⌘Q handler; record the window's length (≤ `engage_timeout_s`) | Child Lock-in Edge Cases (TASK-057 R-2) | Mac | MAC FREE | timed launch log (settings read → handler installed) | 5 min | same build, lock stored ON | `mac-1/M-2/launch-log.txt` |
| M-3 | **Physical keyboard and trackpad with the lock on:** ⌘H, ⌘Q, ⌘Space blocked; each R2 NOT ASSESSED item recorded blocked or not: ⌘Tab, ⌥⌘Esc, Mission Control and Spaces (F3, ⌃↑, ⌃←/→), 3- and 4-finger swipes, Notification Center, hot corners, Globe/fn, Touch ID, a short power-key press, fast user switching | Child Lock-in AC-13, R2 | Mac (with a trackpad; note the model) | **Luan presses the keys and gestures** (a physical keyboard is the point; injected keys proved nothing, TASK-033) | read the screen, screenshot each result, fill the table | 20 min | macOS app with the kiosk (Child Lock-in R2–R5; ADR-0008) | `mac-1/M-3/` screenshot per item + `table.md` |
| M-4 | **Two displays:** the second display shows the dusk cover; clicks on it do nothing; the app stays frontmost and the main window key | Child Lock-in AC-14, R6; Parent Gate AC-34 | Mac + second display (F-6) | connect the display; click the second screen | screenshots, the key-window log | 10 min | as M-3 | `mac-1/M-4/` |
| M-5 | **Crash with the lock on:** `kill -9` on the locked app restores the Dock and menu bar and a usable desktop | Child Lock-in AC-15, R5 | Mac | watch the desktop | run `kill -9`, screenshot | 5 min | as M-3 | `mac-1/M-5/` |
| M-6 | **Sleep and wake:** lid closed (or display sleep) and opened; after login the lock is applied again | Child Lock-in AC-16, R6 | Mac | **close the lid, log in** (F-7) | screenshots before and after | 5 min | as M-3 | `mac-1/M-6/` |
| M-7 | **Ways out:** chord → challenge → panel → Quit (held 1.5 s) ends the app with the desktop usable; panel → OFF → ⌘Q quits; a wrong code makes the chord do nothing for 10 s; the panel, challenge and confirm are overlays (the main window stays key; options stay applied); ⌘Q in the open panel does nothing | Child Lock-in AC-17; Parent Gate AC-20, AC-27, AC-34 | Mac | type the code | run the sequence, timer for the 10 s, screenshots | 10 min | as M-3, plus the gate (Parent Gate G1–G11) | `mac-1/M-7/` |
| M-8 | **One app-written key (Mac):** quit the app, `plutil -p ~/Library/Containers/<id>/Data/Library/Preferences/<id>.plist`; holds `settings` plus the allowlist; fills the Mac allowlist (an ADR-0005 edit) | ADR-0005 V2, D5; PKC-05 | Mac | MAC FREE | run the app, change every setting, quit, read the plist | 10 min | macOS app with ADR-0005's backend | `mac-1/M-8/plist.txt` |
| M-9 | **macOS childLock round trip** (the Mac app through the real backend; a macOS host unit test would be headless and out of this plan): lock ON → OFF for the run → volume change → bytes still `"childLock":true` → cold launch → `childLockActive` true → Reset → key absent | ADR-0005 V1 (D4); Parent Gate AC-19; Settings AC-15b | Mac | MAC FREE | drive the panel, quit, relaunch, read the plist | 10 min | the macOS app with ADR-0005's backend and KidCore Settings | `mac-1/M-9/` |
| M-10 | **Mac window and ppi:** resize to 960 × 540 pt, then native full screen with the kiosk off, safe stage whole; the `CGDisplayScreenSize` ppi path, including a 72-dpi result treated as unknown (class maximum + one log line) | ADR-0006 V6, V7 (Accepted, c9f7c933); App Shell R7 | Mac (built-in display; an external display for the 72-dpi case if one reports it) | MAC FREE | resize, full-screen, screenshots, ppi log | 10 min | ADR-0006's stage code (ADR-0006 Accepted) | `mac-1/M-10/` |
| M-11 | **No network and no input in logs (Mac):** `nettop -p <pid>` 0 bytes over the 10-min scripted session; 0 sandbox `deny network-outbound` lines; and, in the same session, `log stream --process <name> --level debug` shows no key, word, touch point or accessibility setting (the supporting run; the code scan is static) | PKC-01 (c); PKC-14 (supporting run); ADR-0011 D5 `--runtime` | Mac | MAC FREE | run the scripted session, capture both | 15 min (runs alongside M-12) | release-configuration macOS build | `mac-1/M-11/` |
| M-12 | **Flash gate (Mac):** F2 capture at the display's refresh rate, the K-26 busy case (seeded mash + parade, Night and Day, rain and snow, Reduce Motion off and on) | Accessibility AC-08, F2 | Mac | MAC FREE | screen capture, run the F2 detector | 15 min | the stage with Scene, Cast Rendering, Parade; the F2 tool | `mac-1/M-12/` |
| M-13 | **Cast Rendering measurement (Mac):** the R11 plan with Scene F6's worst case: frame time p50/p99, creature load time per role, peak memory | Cast Rendering AC-17, R11; MorphCore AC-11 | Mac | MAC FREE | run with the Metrics recorder | 10 min | both SVG options built (the SVG-rendering ADR's candidates) | `mac-1/M-13/` |
| S-1 | **Stage fit and Reduce Motion in a visible Simulator:** 11" and 13" iPad simulators and a Split View / Windowed Apps size; toggling Reduce Motion emits `accessibilityChanged` and the next reveal uses the reduced set. **Simulator: QC's E9F515E9** (a QC run); the window is needed for the screenshots and the Split View sizes | ADR-0006 V1, V5 (Accepted) | Mac (a visible Simulator window) | MAC FREE only | the whole run | 20 min | ADR-0006 stage code | `sim-1/S-1/` |
| S-2 | **One app-written key (Simulator), headless:** `simctl launch` on ADR-0005's **dev simulator** booted headless (no Simulator.app window; ADR-0005 D5), change every setting through a test seam, terminate, `killall cfprefsd` in the simulator, read the plist in the data container (`simctl get_app_container <dev sim> <bundle id> data`); fills the Simulator allowlist (an ADR-0005 edit). **No MAC FREE** (K-34: headless), so it is listed here for completeness and runs outside the sessions | ADR-0005 V2, D5; PKC-05 | the dev simulator, headless | none | the whole run | 10 min | ADR-0005 backend | `sim/S-2/plist.txt` |
| P-0 | **First launch on a real iPad, observed:** the app installs, launches to the Title, a press starts play and a reveal answers; retained screenshot (the run-and-observe standard; ADR-0001: no real iPad has run it yet) | ADR-0001 (Validation); coding standards "A parse check is not a run" | the child's iPad | hand over the iPad; tap | install, launch, screenshot | 10 min | Setup (F-1 to F-3); the app build | `ipad-1/P-0/` |
| P-1 | **Press → picture and press → sound latency** (the TASK-033 iPad procedure, ~20 min) | `production/qa/evidence/TASK-033/procedure-ipad.md`; `design/tech/TASK-033-anim-runtime.md`; Audio AC-16 (latency); Reveal Stage AC-16 (the device run; its feel part is a playtest item, below) | **the child's iPad** (note model and iPadOS) + a 240 fps phone (F-8) | **films and taps** (the procedure is hands-on) | sets up the build, steps the video frames, fills the tables | 30 min | the spike app signed with the Personal Team (F-1–F-3) | `ipad-1/P-1/` videos + tables |
| P-2 | **Cast Rendering + MorphCore measurement (iPad):** the R11 plan combined with Scene F6's worst case on the oldest supported iPad; frame time, load time per role (within the reduced T 1.2 s), peak memory, app-size delta, crispness at ~775 px (13"); **plus the Settings Store's real read time** (expected well under one frame) | Cast Rendering AC-17, R11; MorphCore AC-11 (240 specks raised only after this); Settings Store NOT ASSESSED (read time) | the oldest supported iPad (and a 13" if available, for crispness) | hand over the iPad | Metrics recorder run | 15 min | both SVG options built | `ipad-1/P-2/` |
| P-3 | **Flash gate (iPad):** F2 over the K-26 busy case, Reduce Motion off and on, at the display's refresh rate (120 Hz on ProMotion). **Gate input (leader decision): (a) an in-app frame dump at the display-link rate in a debug build**, the rendered frames fed straight to the F2 detector (frame-accurate, no capture cap). **(b) the 240 fps phone (F-8) is a sanity spot-check only** (camera luminance is not WCAG relative luminance). A cable screen recording may cap at 60 fps and is **not** used for the gate | Accessibility AC-08, F2 | iPad (note ProMotion or not) | hand over the iPad; toggle Reduce Motion (F-9); film the spot-check | run the frame-dump build and the detector | 20 min | as M-12, plus the debug frame-dump build | `ipad-1/P-3/` |
| P-4 | **Guided Access:** start with a triple-click (F-4); the panel's lock page shows "Guided Access is on" / "off"; hardware-keyboard shortcuts (⌘Tab, ⌘H / Globe+H, ⌘Space) recorded escaping or not under Guided Access | Child Lock-in AC-12, R8 (NOT ASSESSED: shortcuts under Guided Access); Input R5 (NOT ASSESSED: iPad hardware-keyboard media keys) | the child's iPad + its hardware keyboard | set up and start Guided Access, press the shortcuts; **press the hardware keyboard's media keys** (volume, mute, brightness, play/pause) in Play | screenshots, fill the table; media keys must never be presses and keep their system function | 20 min | the app with the panel and Child Lock-in R8 | `ipad-1/P-4/` |
| P-5 | **No network (iPad):** an Instruments network trace over the scripted session shows 0 bytes | PKC-01 (c), PKC Q4 (the device trace is release evidence) | iPad, cabled to the Mac | hand over the iPad | Instruments trace | 15 min (runs alongside P-2) | release-configuration iPad build | `ipad-1/P-5/` |
| P-6 | **VoiceOver on the stage during play** (what VoiceOver's own gestures do if left on) | Accessibility A8, Q4 | iPad | toggle VoiceOver | observe, screenshot | 10 min | the stage | `ipad-1/P-6/` |

| M-14 | **No click on a cut (Mac):** cutting a playing voice line, cast sound and parade tune (a new reveal, mute, the panel) shows no discontinuity above −60 dBFS in an output capture; no click heard on the built-in speaker | Audio AC-9 | Mac | **listens** on the built-in speaker | output capture, the analysis | 10 min | the app with Audio & Voice | `mac-1/M-14/` |
| M-15 | **Launch times (Mac):** launch-to-first-frame and launch-to-playable | App Shell AC-13 | Mac | MAC FREE | 5 cold launches with the instrumented log | 10 min | the macOS app | `mac-1/M-15/` |
| M-16 | **VoiceOver on the grown-up path (Mac):** with VoiceOver on, open the gate with the chord (the moon's VoiceOver hold is the iPad's path), focus lands on the code, the code is entered, focus returns to the stage on close | Parent Gate AC-24 (as it applies on the Mac) | Mac | toggle VoiceOver; type the code | screenshots, the focus log | 10 min | the macOS app with the gate | `mac-1/M-16/` |
| S-3 | **No colour-only meaning:** desaturated (greyscale) screenshots of each Accessibility A6 row still show the backup cue (hint vs queued token, the moon ring). **Simulator: QC's E9F515E9**, a visible window for the screenshots | Accessibility AC-11 | Mac (a visible Simulator window) | MAC FREE only | screenshots, greyscale conversion | 10 min | the stage with hints, tokens and the gate | `sim-1/S-3/` |
| S-4 | **Nothing but play in front of the child:** from every child-area screen (Title, Play, a parade), every grown-up item (settings, weather, theme, keyboard row, privacy text, Mac kiosk exit) is reachable only through the gate; every key A–Z / 0–9 and every child touch target tried once: nothing opens Safari, a web view, the App Store, a share sheet, a review prompt or another app. **Simulator: QC's E9F515E9**, a visible window (QC plays it) | PKC-07 and PKC-02 (QC play); Parent Gate AC-21; PKC AC-04, AC-08 | Mac (a visible Simulator window) | MAC FREE only | the play session, screenshots | 20 min | the app with the gate, panel and stage | `sim-1/S-4/` |
| P-7 | **No click on a cut (iPad):** as M-14, on the iPad's built-in speaker, plus headphones pulled out mid-line | Audio AC-9 | iPad, headphones | **listens**; unplugs the headphones | output capture, analysis | 10 min | the app with Audio & Voice | `ipad-1/P-7/` |
| P-8 | **Interruptions:** an interruption that ends with "should resume" (a Siri request or an alarm), a route change (unplug headphones), a media-services reset (where the build or OS offers a way to trigger it); the next press chimes after re-priming; no crash | Audio AC-15 | iPad | triggers the interruption and the route change | the log, screenshots | 15 min | as P-7 | `ipad-1/P-8/` |
| P-9 | **Silent switch:** silent mode on (Control Center): no sound for any event; every visual answer still shows; music playing in another app stops, not mixed | Audio AC-20 | iPad | **sets silent mode, starts music in another app, listens** | screenshots | 10 min | as P-7 | `ipad-1/P-9/` |
| P-10 | **Launch times (iPad):** launch-to-first-frame and launch-to-playable | App Shell AC-13 | the oldest supported iPad | hand over the iPad | 5 cold launches with the instrumented log | 10 min | the app | `ipad-1/P-10/` |
| P-11 | **Multitasking on a real iPad:** Split View, Slide Over, Stage Manager / Windowed Apps resizes; the safe stage stays whole, no bars (S-1 is the Simulator only) | App Shell NOT ASSESSED (multitasking); ADR-0006 D4 (Accepted) | iPad (Stage Manager needs a model that supports it; note the model) | **does the multitasking gestures** | screenshots per size | 15 min | ADR-0006 stage code | `ipad-1/P-11/` |
| P-12 | **Settings survive a relaunch:** volume 3, theme Dinosaurs, light rain + windy, keyboard row on; quit and relaunch; the panel shows the same values, the stage shows rain with wind and the row | Settings AC-17 | iPad | quits the app (app switcher) | retained screenshots before and after | 10 min | the app with the panel, Scene and the row | `ipad-1/P-12/` |
| P-13 | **Smart Invert pair:** with Smart Invert on (F-9), the stage's pixels are unchanged and the panel is inverted | Accessibility AC-15; Reveal Stage R1 (K-30) | iPad | toggles Smart Invert | the retained screenshot pair | 5 min | the stage view with the opt-out | `ipad-1/P-13/` |
| P-14 | **VoiceOver on the grown-up path (iPad):** double-tap-and-hold "Grown-ups" opens the challenge; focus lands on the code ("Enter four, one, seven, two"); four double-taps on the keys open the panel; focus returns to the stage on close | Parent Gate AC-24 | iPad | toggles VoiceOver, does the gestures | screenshots, the focus log | 15 min (with P-6) | the gate and panel | `ipad-1/P-14/` |

## Sessions

Grouped so Luan books each device as few times as possible. Each session needs the builds named; a session runs
only the checks whose build exists, and the rest stay NOT ASSESSED for a later session.

| Session | Device | Time | Checks | Luan's part | Needs first |
|---|---|---|---|---|---|
| **Setup** | Mac + iPad | ~20 min, once | F-1 to F-4 | sign into Xcode; Developer Mode; trust; Guided Access passcode | nothing |
| **iPad session 1** | the child's iPad (+ the oldest supported iPad for P-2 and P-10 if different), a 240 fps phone, headphones, the Mac for P-5 | **~2 h**, split into **1a** (~60 min: P-0, P-1, P-7, P-8, P-9, P-12, P-4) and **1b** (~60 min: P-2 + P-5, P-3, P-6 + P-14, P-10, P-11, P-13) | P-0 to P-14 | film P-1; Guided Access, the keyboard shortcuts and media keys; toggle Reduce Motion, VoiceOver, Smart Invert and silent mode; listen for clicks; trigger interruptions; multitasking gestures; quit and relaunch | Setup; the spike app (P-1, now); the app build (P-0, P-4, P-7 to P-14); both SVG options (P-2); the debug frame-dump build and the F2 tool (P-3) |
| **Mac session 1** | Luan's Mac (+ a second display, a trackpad) | **~2 h 30 min** (MAC FREE throughout) | M-1, M-2, M-3, M-4, M-5, M-6, M-7, M-8, M-9, M-10, M-11 + M-12 (together), M-13, M-14, M-15, M-16 | the physical keys and gestures (M-3); connect a display (M-4); close the lid and log in (M-6); type codes (M-7, M-16); listen for clicks (M-14); VoiceOver (M-16); OK for `tccutil` (M-1) | the macOS app with Input R6, the gate, Child Lock-in and the kiosk (ADR-0008), ADR-0005's backend, ADR-0006 accepted; a release-configuration build (M-11); the F2 tool (M-12); both SVG options (M-13) |
| **Simulator session 1** | Luan's Mac (visible Simulator windows, QC's E9F515E9) | **~50 min** (MAC FREE) | S-1, S-3, S-4 (S-2 is headless and runs outside the sessions) | none beyond granting MAC FREE | ADR-0006 stage code; the stage with hints and the gate |

**Can be split** if the builds arrive at different times: P-1 can run now (the spike app exists, TASK-033). Mac session 1 can split at M-9 into "lock and keys" (M-1 to M-7, M-16) and "settings, stage, audio, measurement" (M-8 to M-15). iPad session 1 splits into 1a (P-1 needs only the spike app, so 1a can start before the stage builds exist) and 1b.
Simulator session 1 is the easiest to fit in: it can run in any MAC FREE window.

## What each session must produce

- `results.md` with one line per check: PASS / FAIL / NOT ASSESSED, the build's commit hash, the device model and OS
  version, the date.
- The raw evidence named in the table; no desktop screen captures outside the app's own windows are committed
  (screen recordings of the Mac desktop are kept locally and summarized, per the team's rule for Mac screenshots).
- ADR edits that the runs require: the OS-key allowlists (M-8, S-2, ADR-0005 D5); the full-screen choice (M-3 to
  M-7 feed ADR-0008); the SVG option (M-13, P-2 feed the SVG-rendering ADR).

## Not in this plan

- **Playtest items, not device checks** (they judge how a 2.5–3-year-old experiences the toy, so they need Luan's
  child and a playtest, not a measurement); each is marked "playtest, not a device check" and stays NOT ASSESSED in
  its GDD until a /playtest-report:
  - Press Queue: how the 3 s hold and the 9–11.5 s worst wait feel;
  - Hint Letters: whether the 27 mm target and the ~6 s life suit a 2.5-year-old's aim;
  - Reveal Stage AC-16's feel part: how the reveal and its sounds feel on a real iPad (its timing part is P-1).
- **ADR-0005 D3 (d), atomicity under power loss on a device:** can't be tested safely and isn't sourceable; it stays
  NOT SOURCEABLE / NOT ASSESSED, with Settings Store R6 as the backstop.

- Headless runs (unit tests including any macOS host unit test, `xcodebuild build`, the dev-simulator kill tests of
  ADR-0005 D3, and S-2 above): no MAC FREE, no device.
- Android checks: no Android build (K-03).
- Real device backup and restore, and a restored record on a new Mac (ADR-0005 V7): these need a second device
  or a restore, which is a bigger ask; kept NOT ASSESSED for a later decision.
