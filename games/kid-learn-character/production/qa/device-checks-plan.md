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
  PASS / FAIL / NOT ASSESSED line per check. The table's `mac-1/M-1/`-style names below are the `<check-id>` folders
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
| M-9 | **macOS childLock round trip:** lock ON → OFF for the run → volume change → bytes still `"childLock":true` → cold launch → `childLockActive` true → Reset → key absent | ADR-0005 V1 (D4); Parent Gate AC-19; Settings AC-15b | Mac (host unit test, or the Mac app) | MAC FREE | run the test | 5 min | ADR-0005 backend + KidCore Settings | `mac-1/M-9/test-log.txt` |
| M-10 | **Mac window and ppi:** resize to 960 × 540 pt, then native full screen with the kiosk off, safe stage whole; the `CGDisplayScreenSize` ppi path, including a 72-dpi result treated as unknown (class maximum + one log line) | ADR-0006 V6, V7 (Proposed); App Shell R7 | Mac (built-in display; an external display for the 72-dpi case if one reports it) | MAC FREE | resize, full-screen, screenshots, ppi log | 10 min | ADR-0006 accepted and its stage code | `mac-1/M-10/` |
| M-11 | **No network (Mac):** `nettop -p <pid>` 0 bytes over the 10-min scripted session; 0 sandbox `deny network-outbound` lines | PKC-01 (c) | Mac | MAC FREE | run the scripted session, capture both | 15 min (runs alongside M-12) | release-configuration macOS build | `mac-1/M-11/` |
| M-12 | **Flash gate (Mac):** F2 capture at the display's refresh rate, the K-26 busy case (seeded mash + parade, Night and Day, rain and snow, Reduce Motion off and on) | Accessibility AC-08, F2 | Mac | MAC FREE | screen capture, run the F2 detector | 15 min | the stage with Scene, Cast Rendering, Parade; the F2 tool | `mac-1/M-12/` |
| M-13 | **Cast Rendering measurement (Mac):** the R11 plan with Scene F6's worst case: frame time p50/p99, creature load time per role, peak memory | Cast Rendering AC-17, R11; MorphCore AC-11 | Mac | MAC FREE | run with the Metrics recorder | 10 min | both SVG options built (the SVG-rendering ADR's candidates) | `mac-1/M-13/` |
| S-1 | **Stage fit and Reduce Motion in a visible Simulator:** 11" and 13" iPad simulators and a Split View / Windowed Apps size; toggling Reduce Motion emits `accessibilityChanged` and the next reveal uses the reduced set | ADR-0006 V1, V5 | Mac (Simulator windows) | MAC FREE only | the whole run | 20 min | ADR-0006 stage code | `sim-1/S-1/` |
| S-2 | **One app-written key (Simulator):** the plist in the app's data container (`simctl get_app_container … data`) after `killall cfprefsd`; fills the Simulator allowlist (an ADR-0005 edit) | ADR-0005 V2, D5; PKC-05 | Simulator (a visible window only if the app is launched with UI; otherwise headless and out of this plan) | MAC FREE if visible | the run | 10 min | ADR-0005 backend | `sim-1/S-2/plist.txt` |
| P-1 | **Press → picture and press → sound latency** (the TASK-033 iPad procedure, ~20 min) | `production/qa/evidence/TASK-033/procedure-ipad.md`; `design/tech/TASK-033-anim-runtime.md` | **the child's iPad** (note model and iPadOS) + a 240 fps phone (F-8) | **films and taps** (the procedure is hands-on) | sets up the build, steps the video frames, fills the tables | 30 min | the spike app signed with the Personal Team (F-1–F-3) | `ipad-1/P-1/` videos + tables |
| P-2 | **Cast Rendering + MorphCore measurement (iPad):** the R11 plan combined with Scene F6's worst case on the oldest supported iPad; frame time, load time per role (within the reduced T 1.2 s), peak memory, app-size delta, crispness at ~775 px (13") | Cast Rendering AC-17, R11; MorphCore AC-11 (240 specks raised only after this) | the oldest supported iPad (and a 13" if available, for crispness) | hand over the iPad | Metrics recorder run | 15 min | both SVG options built | `ipad-1/P-2/` |
| P-3 | **Flash gate (iPad):** F2 capture at the display's refresh rate (120 Hz on ProMotion) over the K-26 busy case, Reduce Motion off and on. **Capture method to confirm before the session:** a cable screen recording may cap at 60 fps, which would not test 120 Hz | Accessibility AC-08, F2 | iPad (note ProMotion or not) | hand over the iPad; toggle Reduce Motion (F-9) | capture, run the detector | 20 min | as M-12 | `ipad-1/P-3/` |
| P-4 | **Guided Access:** start with a triple-click (F-4); the panel's lock page shows "Guided Access is on" / "off"; hardware-keyboard shortcuts (⌘Tab, ⌘H / Globe+H, ⌘Space) recorded escaping or not under Guided Access | Child Lock-in AC-12, R8 (NOT ASSESSED: shortcuts under Guided Access) | the child's iPad + its hardware keyboard | set up and start Guided Access, press the shortcuts | screenshots, fill the table | 15 min | the app with the panel and Child Lock-in R8 | `ipad-1/P-4/` |
| P-5 | **No network (iPad):** an Instruments network trace over the scripted session shows 0 bytes | PKC-01 (c), PKC Q4 (the device trace is release evidence) | iPad, cabled to the Mac | hand over the iPad | Instruments trace | 15 min (runs alongside P-2) | release-configuration iPad build | `ipad-1/P-5/` |
| P-6 | **VoiceOver on the stage during play** (what VoiceOver's own gestures do if left on) | Accessibility A8, Q4 | iPad | toggle VoiceOver | observe, screenshot | 10 min | the stage | `ipad-1/P-6/` |

## Sessions

Grouped so Luan books each device as few times as possible. Each session needs the builds named; a session runs
only the checks whose build exists, and the rest stay NOT ASSESSED for a later session.

| Session | Device | Time | Checks | Luan's part | Needs first |
|---|---|---|---|---|---|
| **Setup** | Mac + iPad | ~20 min, once | F-1 to F-4 | sign into Xcode; Developer Mode; trust; Guided Access passcode | nothing |
| **iPad session 1** | the child's iPad (+ the oldest supported iPad for P-2 if different), a 240 fps phone, the Mac for P-5 | **~90 min** | P-1, P-2 + P-5 (together), P-3, P-4, P-6 | film P-1; set up and start Guided Access; toggle Reduce Motion and VoiceOver; press the keyboard shortcuts | Setup; the spike app (P-1, now); the app build with stage, panel and Lock-in R8 (P-2–P-6); both SVG options (P-2); the F2 tool and a confirmed 120 Hz capture method (P-3) |
| **Mac session 1** | Luan's Mac (+ a second display, a trackpad) | **~2 h** (MAC FREE throughout) | M-1, M-2, M-3, M-4, M-5, M-6, M-7, M-8, M-9, M-10, M-11 + M-12 (together), M-13 | the physical keys and gestures (M-3); connect a display (M-4); close the lid and log in (M-6); type codes (M-7); OK for `tccutil` (M-1) | the macOS app with Input R6, the gate, Child Lock-in and the kiosk (ADR-0008), ADR-0005's backend, ADR-0006 accepted; a release-configuration build (M-11); the F2 tool (M-12); both SVG options (M-13) |
| **Simulator session 1** | Luan's Mac (Simulator windows) | **~30 min** (MAC FREE) | S-1, S-2 | none beyond granting MAC FREE | ADR-0006 stage code; ADR-0005 backend |

**Can be split** if the builds arrive at different times: P-1 can run now (the spike app exists, TASK-033). Mac
session 1 can split at M-9 into "lock and keys" (M-1 to M-7) and "settings, stage, measurement" (M-8 to M-13).
Simulator session 1 is the easiest to fit in: it can run in any MAC FREE window.

## What each session must produce

- `results.md` with one line per check: PASS / FAIL / NOT ASSESSED, the build's commit hash, the device model and OS
  version, the date.
- The raw evidence named in the table; no desktop screen captures outside the app's own windows are committed
  (screen recordings of the Mac desktop are kept locally and summarized, per the team's rule for Mac screenshots).
- ADR edits that the runs require: the OS-key allowlists (M-8, S-2, ADR-0005 D5); the full-screen choice (M-3 to
  M-7 feed ADR-0008); the SVG option (M-13, P-2 feed the SVG-rendering ADR).

## Not in this plan

- Headless runs (unit tests, `xcodebuild build`, the dev-simulator kill tests of ADR-0005 D3): no MAC FREE, no
  device.
- Android checks: no Android build (K-03).
- Real device backup and restore, and a restored record on a new Mac (ADR-0005 V7): these need a second device
  or a restore, which is a bigger ask; kept NOT ASSESSED for a later decision.
