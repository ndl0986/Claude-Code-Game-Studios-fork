# Child Lock-in

> **Status**: In Review
> **Author**: game-dev-android for Luan (TASK-052); plan reviewed by game-qc-ios
> **Last Updated**: 2026-11-18
> **Last Verified**: 2026-11-18, against ADR-0001 Decision 9 (a–c), the TASK-033 spike report (Child lock-in),
> Input & Key Filter R5/R6 and its Gate challenge state, Settings Store R1/R8 (TASK-050, K-21), App Shell & Title
> (TASK-051) R1/R7, the Parent Gate & Grown-up Panel interface (TASK-048: G2, G7, G8, G11, `panelWillOpen` /
> `panelDidClose`), Privacy & Kids Compliance PKC-07, decisions K-10, K-12, K-19, K-21, K-23
> **Implements Pillar**: Pillar 5 (Safe by Design)

## Summary

Child Lock-in keeps a toddler inside the app. On the Mac, when a grown-up turns on "Child lock", it puts the app in
a kiosk: the Dock and menu bar hide, app switching, Force Quit, logout and the Apple menu are disabled, and other
displays are covered. It engages only when the way out already works, and it never traps the parent. On the iPad an
app can't lock itself, so this system explains Guided Access in the grown-up panel and reports whether it is on.
Android's screen pinning comes with the later Android app.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Input & Key Filter` (chord, kiosk-on
> mode), `Parent Gate & Grown-up Panel` (the switch, the ways out); reads `Settings Store` (`childLockActive`),
> `App Shell & Title` ("ready", the window)

## Overview

The worst moment of Luan's browser playtest was a control key switching apps (brief After-play; concept CM 6).
Inside the app, Input & Key Filter already swallows every key that isn't a letter or digit. What it cannot stop is
what the operating system handles before the app sees it. The TASK-033 spike showed that on macOS a set of
`NSApplication` presentation options blocks ⌘H, ⌘Q and ⌘Space and hides the Dock and menu bar (ADR-0001 9b), and
that on the iPad only Apple's Guided Access can hold a child in one app (ADR-0001 9c). This GDD turns those findings
into rules: what the kiosk applies, exactly when it engages and disengages, how it behaves with other displays and
sleep, what is still unproven on a physical keyboard, and what the iPad and later Android builds do instead.

## Player Fantasy

The child doesn't know this system exists: whatever they press, the toy stays on screen. The grown-up gets "I can
walk away for a minute": with the lock on, the Mac stays on the toy until they come back, use the chord and answer
the gate. And the grown-up is never locked out of their own computer: the lock starts only once the way out works,
gives up quietly if it can't start, and comes off the moment they turn it off or quit.

## Detailed Design

### Core Rules

**R1. Ownership.**

| Concern | Owner |
|---|---|
| Applying and removing the macOS presentation options; the extra-display covers; the engage and disengage order; failure handling; `engage_timeout_s`; the in-memory failure flag; the iPad's `guidedAccessEnabled`; the Guided Access guidance text | **Child Lock-in** |
| The "Child lock" switch, its notices ("Child lock is OFF", "Child lock couldn't turn on", "Guided Access is on"), the Quit button, the gate | Parent Gate & Grown-up Panel (TASK-048) |
| `childLock` (stored, only as ON) and `childLockActive` (runtime) | Settings Store (R1, R8; K-21) |
| Swallowing keys, the ⌃⌥⌘Q chord, the kiosk-on mode | Input & Key Filter (R5, R6) |
| The window, full screen, the "app is ready" signal | App Shell & Title (R1, R7) |

**R2. The macOS kiosk: what it applies** (ADR-0001 9b; TASK-033).

- `NSApplication.presentationOptions = [.hideDock, .hideMenuBar, .disableProcessSwitching, .disableForceQuit,
  .disableSessionTermination, .disableHideApplication, .disableAppleMenu]`, plus `.disableScreenCornerInteractions`
  on macOS 27 and later.
- Input's **kiosk-on mode**: ⌘-combinations are swallowed too (Input R5). **While `childLockActive` is true they are
  swallowed in every Input state**, Play, the Gate challenge and Panel open, so ⌘Q in the panel can never skip the
  Quit button's 1.5 s hold (Parent Gate G8/G11). *(Input change, queued by the leader as a follow-up; not edited
  here.)*
- The main window covers its display (App Shell R7). If App Shell uses native full screen, the options are supplied
  through the window delegate's `window(_:willUseFullScreenPresentationOptions:)` instead of set directly; a
  borderless window at the screen's frame sets them directly. Which one is **NOT ASSESSED** until the Mac build
  (App Shell R7).
- Extra displays are covered (R6).
- **Tested** (TASK-033, keys posted at the HID event tap, `evidence/TASK-033/lockin/`, in a sandboxed build): ⌘H,
  ⌘Q and ⌘Space escape without the kiosk and are blocked with it; the Dock and menu bar hide.
- **NOT ASSESSED** (need a physical keyboard and trackpad on a real Mac): ⌘Tab; ⌥⌘Esc (Force Quit); Mission
  Control and Spaces (F3, ⌃↑, ⌃←/→); three- and four-finger trackpad swipes; Notification Center (the trackpad edge
  swipe, the clock); hot corners; the Globe/fn key; Touch ID; a short press of the power key; fast user switching.
  The injected keys did not trigger these even without the kiosk, so the spike proves nothing about them.
- **Never blockable, by design:** a long press of the power key forces a shutdown. That is the grown-up's hardware
  way out of last resort.

**R3. When it engages.** The kiosk is applied only when **all** of these hold (App Shell's "ready" is the first
four; Child Lock-in adds 5 and 6):

1. the first frame has been drawn;
2. the ⌃⌥⌘Q chord handler is installed (Input R6);
3. Input's kiosk-on mode is set;
4. the main window covers its display (App Shell R7);
5. the app is active (frontmost);
6. `childLockActive` is true (Settings Store R8).

- **At launch:** `childLockActive` = the stored `childLock` (K-12, K-21). Waiting starts at the settings read.
- **Turned ON in the panel:** `childLockActive` = true and `childLock: true` is written (Settings Store R8). The kiosk
  engages on `panelDidClose`, including the panel's 60 s auto-close (K-19), not while the panel is open, so the
  grown-up sees the result. Waiting starts at `panelDidClose`.
- **Already on when the panel opens:** it stays applied the whole time the panel is open.
- **ON then OFF before the panel closes:** nothing is applied.

**R4. When it disengages, and the order.** Disengaging always runs: (1) set the presentation options to `[]` (or
stop supplying them); (2) remove the extra-display covers; (3) turn Input's kiosk-on mode off. The options come off
before the keys are released, so there is never a moment with ⌘-keys live and the Dock hidden.

| Trigger | `childLockActive` | Stored `childLock` | Kiosk |
|---|---|---|---|
| Turned **OFF** in the panel (K-21) | false, one notification, **no write** | stays true | off **at once**, with the panel still open; the panel later shows "Child lock is OFF" |
| **Reset** (Settings Store R9) | false | removed | off |
| **Quit** from the panel (Parent Gate G8/G11) | — | unchanged | disengage (1–3), **then** terminate |
| The app **resigns active** (another app or process takes focus, R5) | unchanged | unchanged | **Suspended**: options removed; re-applied on `didBecomeActive` if R3 still holds (K-23) |
| The engage timeout passes (R7) | unchanged | unchanged | never applied; Off with the failure flag |

**R5. Never trap the grown-up; never lock before the way out.**

- **The ways out while locked:**
  1. the chord (⌃⌥⌘Q) or the moon hold → the gate's number challenge → the panel → **Quit** with its hold (Parent
     Gate G8/G11);
  2. the panel → turn the lock **OFF** → ⌘Q (K-21);
  3. a long press of the power key, always (R2).
- **The chord, as the gate defines it** (Parent Gate G2): it counts only when **exactly** ⌃⌥⌘Q is down, read from the
  OS key state (Input R6: the held set is empty when Q goes down); it works on the Title and in Play; it does nothing
  during the gate's 10 s moon sleep after a wrong or timed-out code (K-20, K-21); it is ignored while the challenge or
  the panel shows. **Note: a mistyped code delays the chord by 10 s.**
- **No lock before the way out works:** preconditions 1–3 of R3 are the way out; the kiosk is never applied before
  them.
- **Give up rather than half-lock:** if R3 is not met within `engage_timeout_s` (R7), the kiosk is never applied.
- **Only another app or process takes the lock away:** the lock is released on `NSApplication.didResignActive` and
  re-applied on `didBecomeActive`. A window's `didResignKey` while the app stays active does **not** release it (one
  debug log line). This holds because of the next rule.
- **Overlays only** (a requirement on Parent Gate & Grown-up Panel and App Shell R7): the challenge, the panel, its
  confirm and the privacy page are drawn **inside the main window** as overlays. No separate `NSWindow`, sheet,
  popover or `NSAlert` is used while `childLockActive` can be true, so the app's own UI never moves key focus away
  from the main window. The only other windows are R6's extra-display covers, which can never become key or main.
- **A crash with the kiosk on:** presentation options belong to the process, so macOS is expected to restore the
  Dock and menu bar when the process ends. **NOT ASSESSED** (a kill -9 test on a real Mac, AC-15). App Shell R9 relies
  on it.

**R6. Extra displays, sleep and the lid** (K-23).

- **Extra displays:** while locked, each display other than the main window's is covered by a **borderless dusk
  window** (the Dusk sky's mid colour, `#46558f`, as App Shell's launch screen) at the main window's level. It
  swallows clicks, and it has **`canBecomeKey` = false and `canBecomeMain` = false**, so a click on it never moves key
  or main status and never activates another app.
  - The covers are created when the kiosk engages, removed when it disengages (R4 step 2), and **rebuilt on
    `NSApplication.didChangeScreenParametersNotification`** (a display plugged in or removed while locked).
  - The main window stays on its display; moving it is App Shell's and is blocked by the full-screen kiosk.
  - **NOT ASSESSED** until run with two displays on a real Mac.
- **Display sleep, the screen saver, closing the lid, waking:** nothing special. If the system shows its own lock
  screen on wake, that is the Mac's login, not a way out for the child. After wake the app becomes active again and
  R4 re-applies the options.

**R7. The engage timeout and the failure flag** (K-23 Q3; game-qc-ios).

- `engage_timeout_s` (5 s) counts from when Waiting begins (at launch: the settings read; after the panel:
  `panelDidClose`) and **only while the app is active**. An app that is inactive (launched behind another app, or the
  grown-up clicked away) is **Suspended**, not failing: its timer pauses.
- When the timer passes with R3 still unmet: the state goes to **Off** with the **failure flag** set. The flag is
  **in memory only** (Settings Store R2: nothing else is stored), and it is cleared on the next engage attempt (the
  next launch, or the lock turned ON again).
- The child sees nothing. The next time the panel opens it reads the flag and shows "Child lock couldn't turn on"
  (K-23; the panel's text).
- One debug log line names the missing precondition.

**R8. iPad: Guided Access** (ADR-0001 9c; TASK-033).

- **No app-side lock.** An app can't block the iPad's system shortcuts (⌘Tab, ⌘H or Globe+H, ⌘Space, Globe): the
  system gets them first, and `wantsPriorityOverSystemBehavior` only reorders against text input and focus. Single
  App Mode needs a supervised (MDM) device, so it isn't for a family iPad. The `childLock` key does not exist on the
  iPad (Settings Store R1).
- **Guidance text** on the panel's lock page (laid out by the Parent Gate & Grown-up Panel), **text only, no link**
  (PKC: nothing leaves the app):
  > To keep your child in the app, use Guided Access: open Settings → Accessibility → Guided Access, turn it on and
  > set a passcode. Then, in this app, triple-click the top button and tap Start. Triple-click again and enter the
  > passcode to end it.
  (English until Localization; the steps follow Apple's guide, support.apple.com/en-us/111795, cited here, not
  linked in the app.)
- **`guidedAccessEnabled`:** Child Lock-in publishes `UIAccessibility.isGuidedAccessEnabled`, updated on
  `UIAccessibility.guidedAccessStatusDidChangeNotification`. The panel's G7 reads it and shows "Guided Access is on"
  (K-23 Q2). Nothing else changes: the moon and the gate stay as they are, so a grown-up can still change the volume
  or theme during Guided Access.
- The app adds **no timed prompt that needs a reply** (Guided Access may also time-limit the app; the panel's 60 s
  auto-close is not a prompt).
- **NOT ASSESSED:** whether hardware-keyboard shortcuts escape Guided Access (Apple doesn't say); checked on the
  child's iPad with its keyboard.

**R9. Android (the later Android app).** Screen pinning: an app can call `startLockTask()`, and without device-owner
status the system asks the user to confirm the pin; or the app shows guidance text, as on the iPad. The Android ADR
chooses. Back is already a no-op callback (Input R5). **NOT ASSESSED.**

### States and Transitions (macOS)

| State | Meaning | Leaves to |
|---|---|---|
| **Off** | `childLockActive` false, or the engage timeout passed (failure flag set) | Waiting (`childLockActive` becomes true: launch, or `panelDidClose` after ON) |
| **Waiting** | `childLockActive` true; some R3 precondition missing; the timer runs while active | Locked (R3 met); Off + flag (timer passes); Off (turned OFF, Reset) |
| **Locked** | the options and covers applied; Input's kiosk-on mode set | Suspended (app resigns active); Off (OFF, Reset, Quit) |
| **Suspended** | locked, but the app is inactive: options and covers removed, Input's mode kept | Locked (`didBecomeActive`, R3 met); Off (OFF, Reset) |

### Interactions with Other Systems

| System | Direction | Interface |
|---|---|---|
| Settings Store | in | `childLockActive` and its change notification (R8 there); never writes |
| App Shell & Title | in | "ready" (first frame, chord, kiosk mode, window covering its display; its R1); the window and full-screen mode (R7); `didResignActive` / `didBecomeActive` |
| Input & Key Filter | out / in | sets and clears the kiosk-on mode; relies on the chord (R6) and on ⌘ swallowing in every state while locked |
| Parent Gate & Grown-up Panel | in / out | in: the switch (ON, OFF), Quit, `panelWillOpen` / `panelDidClose`; out: the failure flag, `guidedAccessEnabled` (G7), the guidance text |
| Privacy & Kids Compliance | evidence | the kiosk exit is behind the gate (PKC-07); no entitlement beyond the allowlist |
| Reveal Stage, Audio, everything in Play | none | the kiosk never changes play |

## Formulas

**F1. Engage time.**
```
t_engage = max(t_firstFrame, t_chordInstalled, t_kioskModeOn, t_windowCovers, t_active)     if childLockActive
engaged  = t_engage − t_waitStart ≤ engage_timeout_s     (time counted only while the app is active)
```
Example: launch, settings read at 0.00 s, first frame 0.45 s, chord 0.30 s, kiosk mode 0.31 s, window covers 0.60 s,
active throughout → engaged at 0.60 s. If the chord handler never installs → at 5.00 s active time, Off with the
flag. If the app was inactive from 0.2 s to 10.2 s and everything else was ready at 0.6 s → engaged at 10.2 s, not
failed (the timer counted 0.2 s).

## Edge Cases

| Case | What happens |
|---|---|
| **Lock stored ON, the app launches** | Waiting from the settings read; Locked once R3 holds (F1). |
| **Lock ON, the chord handler fails to install** | Never Locked; after 5 s Off with the flag; the panel shows "Child lock couldn't turn on" (R7). |
| **The grown-up clicks another app during launch** | Suspended: the timer pauses; Locked when the app is active again. |
| **Turned ON in the panel** | Locked after `panelDidClose` (R3). |
| **Turned OFF in the panel** | Off at once, panel still open; at the next launch it is ON again (K-21). |
| **ON then OFF in one panel visit** | Nothing applied. |
| **The panel opens while locked** | Stays Locked; ⌘-keys stay swallowed; ⌘Q does nothing (R2). |
| **The gate challenge opens while locked** | Stays Locked (overlay in the main window, R5). |
| **A wrong code, then the chord at once** | The chord does nothing for 10 s (Parent Gate G2, R5 note). |
| **A system alert or Notification Center takes focus** | Suspended: options removed; re-applied on return (K-23 Q4); nothing shown to the child. |
| **A click on an extra display's cover** | Swallowed; the main window stays key; still Locked (R6). |
| **A display is plugged in while locked** | Covers rebuilt on the screen-parameters notification (R6). |
| **Sleep, lid closed, then wake** | The app becomes active again; options re-applied (R6). |
| **The app crashes while Locked** | The OS is expected to restore the Dock and menu bar (NOT ASSESSED, R5); the next launch locks again once ready. |
| **Reset in the panel while locked** | Off; the stored flag removed; the next launch is unlocked (Settings Store R9). |
| **Quit from the panel** | Disengage (options, covers, Input mode), then terminate (R4). |
| **iPad: Guided Access turned on or off during play** | `guidedAccessEnabled` updates; the panel's page reflects it next time it is shown. |
| **iPad: the child presses ⌘Tab or Globe** | The system handles it; the app can't stop it; Guided Access is the answer (R8). |

## Dependencies

- **Upstream:**
  - Settings Store (`design/gdd/settings-store.md`): `childLock` stored only as ON, `childLockActive` at run time,
    Reset (R1, R8, R9; TASK-050, K-21).
  - Input & Key Filter (`design/gdd/input-key-filter.md`): the chord (R6, exactly ⌃⌥⌘Q with nothing else held,
    TASK-050), the kiosk-on mode (R5), the Gate challenge state. **Follow-up (queued by the leader):** ⌘-combinations
    swallowed in every state while `childLockActive` is true.
  - App Shell & Title (TASK-051): "ready" and the window (its R1, R7); **requirement:** overlays only while the lock
    can be on (R5), and the full-screen choice (R2).
- **Peers / downstream (each must name Child Lock-in):**
  - Parent Gate & Grown-up Panel (TASK-048): the switch, Quit (G8/G11), the chord (G2), `panelDidClose`, G7 reads
    `guidedAccessEnabled`, the failure-flag notice; **requirement:** overlays only (R5).
  - Privacy & Kids Compliance: its Child Lock-in row (PKC-07).
- **Documents:** ADR-0001 Decision 9; TASK-033 spike report and `evidence/TASK-033/lockin/`; decisions K-10, K-12,
  K-19, K-21, K-23.

## Tuning Knobs

| Knob | Value | Safe range | Source | Effect |
|---|---|---|---|---|
| `engage_timeout_s` | 5 s | 2–15 | K-23 ("about 5 s") | how long the lock waits for its preconditions before giving up |
| cover colour | `#46558f` | a sky mid colour | K-23, App Shell launch colour | what an extra display shows while locked |
| the option set | R2 | fixed (ADR-0001 9b) | ADR-0001 | what the kiosk blocks |

## Acceptance Criteria

Logic tests use a fake `NSApplication` options setter, fake window and screen sources, a fake Settings Store and an
injected clock. Real-Mac runs need **MAC FREE** from the leader before anything runs on Luan's Mac; screenshots are
retained in `production/qa/evidence/`.

- **AC-1 Order:** the options are never applied before all six R3 preconditions hold, in any order of arrival
  (permutation test); the applied set equals R2's (with `.disableScreenCornerInteractions` only on macOS 27+).
- **AC-2 Disengage order:** on OFF, Reset and Quit, the options are cleared before the covers are removed and before
  Input's kiosk-on mode is turned off; Quit terminates only after all three.
- **AC-3 childLockActive:** engage and disengage follow `childLockActive`, never the stored value: OFF in the panel
  disengages at once with no Settings write; a relaunch engages again (K-21).
- **AC-4 Panel ON:** turning ON in the panel applies nothing while the panel is open and engages on
  `panelDidClose` (and on the 60 s auto-close); ON then OFF in one visit applies nothing.
- **AC-5 Panel while locked:** with the lock on, open the challenge, then the panel, then its confirm: the options
  stay applied at every step (the seam logs them); `didResignKey` without `didResignActive` changes nothing.
- **AC-6 ⌘ in the panel:** with the lock on and the panel open, ⌘Q, ⌘H and ⌘Tab do nothing; the app stays open and
  frontmost (integration, after the Input follow-up).
- **AC-7 Suspend:** `didResignActive` removes the options and covers; `didBecomeActive` re-applies them when R3
  holds; Input's kiosk-on mode stays set throughout.
- **AC-8 Timeout:** with precondition 2 (chord handler) missing, at 5.0 s of active time the state is Off, the
  failure flag is set and no options were ever applied; with the app inactive for those 5 s it is still Waiting; the
  flag clears on the next engage attempt.
- **AC-9 F1 examples:** the three F1 cases give engaged at 0.60 s, Off with the flag at 5.00 s, and engaged at
  10.2 s.
- **AC-10 Covers:** with two fake screens, engaging creates one cover on the non-main screen with `canBecomeKey` and
  `canBecomeMain` false; a screen-parameters change rebuilds them; disengaging removes them.
- **AC-11 Overlays only (code review + test):** no `NSWindow`, sheet, popover or `NSAlert` is presented by the gate,
  panel or App Shell while `childLockActive` can be true; the only other windows are R6's covers, and each reports
  `canBecomeKey` and `canBecomeMain` false.
- **AC-12 iPad:** `guidedAccessEnabled` follows a fake Guided Access status and its notification; the guidance text
  contains no link (code review); no `childLock` key exists on the iPad.
- **AC-13 Real Mac, keys (NOT ASSESSED until run):** on a physical keyboard and trackpad, with the lock on: ⌘H, ⌘Q,
  ⌘Space blocked (repeat of TASK-033); and each R2 NOT ASSESSED item recorded as blocked or not, with a screenshot.
- **AC-14 Real Mac, two displays (NOT ASSESSED until run):** the second display shows the dusk cover; clicks on it do
  nothing; the app stays frontmost.
- **AC-15 Real Mac, crash (NOT ASSESSED until run):** `kill -9` on the locked app restores the Dock and menu bar and
  a usable desktop.
- **AC-16 Real Mac, sleep:** lid closed and opened (or display sleep): after wake and login the lock is applied again.
- **AC-17 Ways out (real Mac):** chord → challenge → panel → Quit with its hold ends the app with the desktop usable;
  panel → OFF → ⌘Q quits; a wrong code makes the chord do nothing for 10 s.

**NOT ASSESSED:** every R2 item marked so; AC-13 to AC-17 until run on a real Mac; native full screen vs borderless
(App Shell); iPad hardware-keyboard shortcuts under Guided Access; Android screen pinning.

## Open Questions

- None open.
- **Decided (Luan, K-23, 2026-11-18):** extra displays covered by a plain dusk window that swallows clicks; with
  Guided Access on the moon and gate stay and the panel shows "Guided Access is on"; if the lock can't engage within
  about 5 s, stay unlocked, show the child nothing, and the next panel open shows "Child lock couldn't turn on"; on
  inactive, release and re-apply on return with nothing shown. Also K-12 (lock after the app is ready) and K-21 (OFF
  lasts the run).
- **Accepted by the leader (2026-11-18):** the engage timeout counts only while the app is active; an inactive app is
  Suspended, not failed.
