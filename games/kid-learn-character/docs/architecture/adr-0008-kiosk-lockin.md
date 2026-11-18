# ADR-0008: Kiosk and child lock-in (Mac full-screen mode, options, covers; iPad Guided Access)

## Status

Proposed (TASK-102, 2026-11-18). **Acceptance waits for the device rows M-3, M-4, M-5, M-6, M-7 and P-4** (Decision
rule below); the rule, including how the full-screen mode is chosen, is fixed now, before any row runs.

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**

## Date

2026-11-18

## Last Verified

2026-11-18, against Child Lock-in (R1–R9, the States table, Edge Cases, AC-12–AC-17), Parent Gate (G2, G7, G8/G11;
AC-20, AC-27, AC-34), App Shell (R1, R7), Input (R5, R6), ADR-0002 (D6 `KioskEffects`, D7 chain 3), ADR-0006 (D1,
D4), ADR-0007, the TASK-075 plan, the device-checks plan, TASK-033's lock-in spike and the Xcode 27.1 SDK headers
(Sources).

## Decision Makers

Luan (accepts, after the rows); game-dev-ios (author, TASK-102); game-dev-android (independent review; ADR-0012 maps
the neutral rules to screen pinning); game-qc-ios (rows and evidence); game-leader.

## Summary

Child Lock-in decides when the Mac locks, what it blocks and how a grown-up always gets out; `KidCore` holds its state
machine and `KioskEffects` (ADR-0002 D6) is the seam. This ADR fixes the Apple side: the kiosk's full-screen mode,
which ADR-0006 D4 left open, **preferring a borderless window at the screen's frame** unless the Mac rows show a way
out that native full screen avoids; the exact presentation-options set on macOS 26 and 27; a kiosk window that can
always become key; the extra-display covers; activation, sleep and crash behaviour; and on the iPad, observing Guided
Access. Each decision is a platform-neutral **Rule** plus its **Apple** form.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | None from the template's table (ADR-0001, K-28). Swift 6.4, Xcode 27.1, SDKs iOS 27.1 / macOS 27.0, deployment 26 |
| **Domain** | Platform (window, system UI) |
| **Layer** | Platform adapter (app target) behind `KioskEffects` |
| **Knowledge Risk** | HIGH for physical-keyboard and trackpad ways out (M-3), two displays (M-4), crash (M-5); MEDIUM for the options set on 27 |
| **References Consulted** | `docs/engine-reference-local/native-apple/` (`modules/appkit-kiosk.md`, `modules/guided-access.md`); the SDK headers below; TASK-033 `evidence/TASK-033/lockin/`; `prototypes/DeviceSpike` (TASK-078: Lock and Guided Access screens) |
| **Post-Cutoff APIs Used** | `NSApplication.PresentationOptions.disableScreenCornerInteractions` (macOS 27.0): to be proven by M-3 on a 27 Mac |
| **Verification Required** | Validation H-1–H-3 (headless), rows M-3–M-7, P-4 |

### Sources (Xcode 27.1 SDK headers, read 2026-11-18)
- `AppKit/NSApplication.h`, `presentationOptions`: "Gets or sets the presentationOptions that should be in effect for
  the system when this application is the active application. Only certain combinations of
  NSApplicationPresentationOptions flags are allowed". Flags: `HideDock` "Dock is entirely unavailable";
  `HideMenuBar` "Menu Bar is entirely unavailable"; `DisableAppleMenu` "All Apple menu items are disabled";
  `DisableProcessSwitching` "Cmd+Tab UI is disabled"; `DisableForceQuit` "Cmd+Opt+Esc panel is disabled";
  `DisableSessionTermination` "PowerKey panel and Restart/Shut Down/Log Out disabled"; `DisableHideApplication`
  "Application "Hide" menu item is disabled"; `DisableScreenCornerInteractions` (`API_AVAILABLE(macos(27.0))`)
  "Disable screen corner interactions when the application is frontmost. `.autoHideDock` or `.hideDock` must also be
  set for this option to take effect."
- `AppKit/NSWindow.h`: `window:willUseFullScreenPresentationOptions:` (the delegate supplies the options for native
  full screen); `canBecomeKeyWindow`, `canBecomeMainWindow` (read-only, overridable). AppKit's documentation, not the
  header, states that a window without a title bar or resize bar returns `false` for `canBecomeKeyWindow`: the
  borderless kiosk window therefore needs a subclass (D3).
- `AppKit/NSApplication.h`: `NSApplicationDidChangeScreenParametersNotification` (displays added or removed).
- `UIKit/UIAccessibility.h`: `UIAccessibilityIsGuidedAccessEnabled` "Returns whether the app is running under Guided
  Access mode"; `UIAccessibilityGuidedAccessStatusDidChangeNotification`.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Accepted: 9b, 9c); ADR-0002 (Accepted: D6 `KioskEffects`, D7 chain 3); ADR-0006 (Accepted: D1 overlays in the main window, D4); ADR-0007 (Proposed: the chord, the way out) |
| **Enables** | The Child Lock-in adapter story (Mac); the panel's lock page (iPad status line) |
| **Blocks** | The macOS kiosk; Child Lock-in AC-13–AC-17 on the production app |
| **Ordering Note** | With ADR-0007 (shared Mac session: "lock and keys") |

## Context

### Problem Statement
Child Lock-in R2 names the options and R3–R7 the engage, disengage, timeout and suspend rules; App Shell R7 and
ADR-0006 D4 left the kiosk's full-screen mode open (native full screen or a borderless window at the screen's frame).
TASK-033 proved, with injected keys, that the options block ⌘H, ⌘Q and ⌘Space and hide the Dock and menu bar; it could
prove nothing about a physical keyboard and trackpad, two displays, a crash or sleep.

### Constraints
- The overlays (gate, panel, confirm) stay inside the main window, which never resigns key (Child Lock-in R5,
  ADR-0006 D1).
- The way out works before the lock and always while locked (Child Lock-in R5; ADR-0007).
- No MDM, no accessibility trust, no private API (PKC).

### Requirements
- Child Lock-in R2–R8 and AC-12–AC-17; Parent Gate G7, G8/G11, AC-20/27/34; App Shell R7.

## Decision

### D1. The full-screen mode: borderless window at the screen's frame, unless the rows say otherwise
**Rule.** While locked, the app's one window covers its display, every overlay is drawn inside it, and nothing the
app shows can take key focus from it.
**Apple.** **Preferred: a borderless window at the screen's frame** (one window, no Space transition, no full-screen
toolbar, the simplest key handling): the kiosk window's style becomes borderless, its frame the screen's frame, and the
options (D2) are set on `NSApplication` directly. **Alternative: native full screen**
(`collectionBehavior.fullScreenPrimary`, `toggleFullScreen`), the options supplied by the window delegate's
`window(_:willUseFullScreenPresentationOptions:)` as the proposed options plus D2's set. Both are built behind
`KioskEffects`; the decision rule picks one before acceptance. `windowCoversDisplay` (ADR-0002 D6) is true when the
window's frame equals its screen's frame (borderless) or its style contains `.fullScreen` (native).

### D2. The options set
**Rule.** While locked: no Dock, no menu bar, no app switching, no force-quit panel, no session-termination panel, no
Hide, no Apple menu, and no hot corners where the OS allows it.
**Apple.** `[.hideDock, .hideMenuBar, .disableAppleMenu, .disableProcessSwitching, .disableForceQuit,
.disableSessionTermination, .disableHideApplication]`, plus `.disableScreenCornerInteractions` when
`#available(macOS 27, *)` (it needs `.hideDock`, which the set has). The set is built by one pure function of the OS
version, unit-tested (H-2), and the adapter logs `currentSystemPresentationOptions` after applying it. Setting an
invalid combination raises (header), so the set is fixed, never composed at run time.

### D3. The kiosk window can always become key
**Rule.** The kiosk window can become key and main in every mode; the cover windows never can.
**Apple.** The app's main window is an `NSWindow` subclass hosting the SwiftUI root, overriding `canBecomeKey` and
`canBecomeMain` to `true` (a borderless window otherwise cannot become key, Sources). Changing the style of a window
SwiftUI owns is not enough: DeviceSpike did that for the spike, and M-3 / M-4 check that the window stays key there,
but production uses the subclass either way.

### D4. Covers on extra displays
**Rule.** Every other display shows a plain cover that swallows clicks and can never become key or main; covers are
rebuilt whenever displays change while locked (Child Lock-in R6).
**Apple.** One borderless `NSWindow` subclass per other `NSScreen`, `canBecomeKey` / `canBecomeMain` `false`,
background `#46558f`, at the main window's level, accepting mouse events (so they go nowhere); built on lock, removed
on unlock (R4 step 2), rebuilt on `NSApplication.didChangeScreenParametersNotification`; on the same notification the
**kiosk window is re-fitted** to its screen's frame (borderless mode), so `windowCoversDisplay` stays true
(game-dev-android).

### D5. Activation, suspend, sleep, quit, crash
**Rule.** The lock is applied only while the app is active and released when it is not (Suspended); it is re-applied
when the app becomes active again if R3 still holds; the order on disengage is options off, covers off, then Input's
kiosk-on mode off (R4); a crash must leave the machine usable.
**Apple.** `NSApplication.didResignActive` → remove the options (set `[]`, or the delegate stops supplying them) and
the covers; `didBecomeActive` → re-apply. A window's `didResignKey` while the app stays active releases nothing (one
debug line; R5). Sleep and wake need nothing special (the app resigns and becomes active, R6). Quit from the panel:
disengage, then terminate. Presentation options belong to the process, so macOS is expected to restore the Dock and
menu bar when it dies (M-5 verifies, both modes).

### D6. The engage timeout and the state machine stay in `KidCore`
**Rule.** The adapter applies and removes effects; it never decides when. Child Lock-in's states (Off, Waiting,
Locked, Suspended), `engage_timeout_s` and the failure flag are `KidCore`'s, driven by `KioskEffects` and the
lifecycle events (ADR-0002 D6, D7 chain 3).
**Apple.** `KioskEffects.apply()` / `remove()` / `coverDisplays(Bool)` as above; `isActive` from `NSApplication`;
`windowCoversDisplay` from D1.

### D7. iPad: observe Guided Access
**Rule.** **Never an app-built lock where the platform keeps its shortcuts; the app may request the platform's own,
user-confirmed lock where one exists, else it observes and guides** (Child Lock-in R8, R9; game-dev-android). On the
iPad the app only reports whether Guided Access is on and shows text guidance with no link; Android chooses between
screen pinning and guidance in ADR-0012.
**Apple.** `guidedAccessEnabled` = `UIAccessibility.isGuidedAccessEnabled`, refreshed on
`guidedAccessStatusDidChangeNotification`; the panel's G7 reads it. No `requestGuidedAccessSession` (it needs a
supervised device, `modules/guided-access.md`). Android's equivalent (screen pinning, Child Lock-in R9) is ADR-0012's.

### Decision rule (fixed before the rows run)
**The mode (D1):** **borderless** unless **M-3 or M-4 shows a way out or a focus loss that the borderless window has
and native full screen does not**. Both modes run M-3 and M-4; M-5 and M-6 are recorded for both.

| Row | Pass (decides this ADR) | If it fails |
|---|---|---|
| **M-3** physical keyboard and trackpad | ⌘H, ⌘Q, ⌘Space blocked; every R2 NOT ASSESSED item recorded **blocked or not** for each mode, with a screenshot; the main window stays key | an item that escapes **only** in borderless chooses native full screen (the rule above); an item that escapes in **both** is recorded as a platform limit in Child Lock-in R2 (the long power-key press is one by design) and, if it is a real way out for a child, raised to Luan |
| **M-4** two displays | the second display shows the cover, clicks on it do nothing, the app stays frontmost and the main window key (key-window log) | a focus loss only in borderless chooses native full screen; in both: fix D4 (level, mouse handling) and re-run |
| **M-5** crash with the lock on | `kill -9` restores the Dock, menu bar and a usable desktop, in both modes | a mode that leaves the Mac unusable is excluded; if both do, raised to Luan before any release (App Shell R9 relies on it) |
| **M-6** sleep and wake | after wake and login the lock is applied again, in both modes | a handler fix (D5), not a mode change |
| **M-7** ways out | chord → challenge → panel → Quit (1.5 s) ends the app with the desktop usable; panel → OFF → ⌘Q quits; a wrong code silences the chord for 10 s; the overlays keep the main window key and the options applied; ⌘Q in the panel does nothing | a failure here blocks acceptance: it is the never-trap rule (R5) |
| **P-4** Guided Access | the panel's lock page shows on / off live; hardware-keyboard shortcuts (⌘Tab, ⌘H / Globe+H, ⌘Space) recorded **escaping or not** under Guided Access | an escaping shortcut is recorded (Apple doesn't say; the app can't block it, R8); the guidance text stays |
Acceptance needs the mode chosen by the rule and M-5, M-7 passing for that mode, or Luan accepting a recorded
exception. **Spike rows decide this ADR; Child Lock-in AC-13–AC-17 and Parent Gate AC-20/27/34 pass only on the
production re-run** (device-checks plan, Spike runs).

### Architecture Diagram
```
KidCore Child Lock-in (Off / Waiting / Locked / Suspended, timeout, flag)
        │ KioskEffects (ADR-0002 D6)                          ▲ isActive, windowCoversDisplay, lifecycle
        ▼                                                     │
Apple adapter: options (D2) ─ kiosk window (D1 borderless | native, D3 key) ─ covers (D4) ─ activation (D5)
iPad: guidedAccessEnabled (D7) ──▶ panel G7
```

### Key Interfaces
- `KioskEffects`: `apply()`, `remove()`, `coverDisplays(Bool)`, `isActive`, `windowCoversDisplay` (ADR-0002 D6).
- `guidedAccessEnabled` (Child Lock-in R8) on the iPad.

### Implementation Guidelines
- The options set is a constant per OS version (D2); never composed at run time.
- No separate `NSWindow`, sheet, popover or `NSAlert` while `childLockActive` can be true (R5); the covers are the only
  other windows.
- Log one line per apply / remove / suspend / re-apply with `currentSystemPresentationOptions` (debug builds).

## Alternatives Considered

### Alternative 1: Native full screen as the default
- **Not preferred** (kept as the decision rule's alternative): a Space transition on every lock and unlock, a
  full-screen toolbar region, and full-screen Spaces that Mission Control gestures can reach; the borderless window
  avoids all three. Native full screen wins only if the rows show a way out the borderless window has.

### Alternative 2: A screen-saver-level or shielding window (`CGShieldingWindowLevel`)
- **Rejected**: it would sit above system alerts the grown-up may need, and it is not how Child Lock-in R5 lets the
  OS take the lock away (resign active → Suspended).

### Alternative 3: Single App Mode / an MDM profile
- **Rejected**: needs a supervised device (Child Lock-in R8); not for a family Mac or iPad.

## Consequences

### Positive
- One window, one options set, one adapter; the mode choice is evidence-based and both modes stay buildable.
- The grown-up's ways out are the gate's, plus the power key, always.

### Negative
- Some trackpad gestures or keys may escape in both modes (M-3 records them); the app cannot block them.
- The kiosk window must be an `NSWindow` subclass rather than SwiftUI's default window. The merged scaffold uses a
  SwiftUI `WindowGroup` with `.restorationBehavior(.disabled)`; an AppKit-created window hosting the SwiftUI root keeps
  that by **`isRestorable = false` and no frame autosave** (game-dev-android).

### Neutral
- The iPad has no app-side lock (by design, R8).

## Risks
- **A physical-keyboard or trackpad way out** (Mission Control, Spaces, hot corners on 26, Touch ID, fast user
  switching). Mitigation: M-3 per mode; the decision rule; Child Lock-in R2's list updated from the results.
- **A crash leaves the Mac locked.** Mitigation: M-5 per mode; a mode that fails is excluded.
- **`.disableScreenCornerInteractions` on 27 behaves differently from its header.** Mitigation: M-3 on a 27 Mac;
  on 26 hot corners stay a recorded limit.
- **The borderless window loses key** after the style change (SwiftUI-owned window). Mitigation: D3's subclass; M-3 /
  M-4's key-window log.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| child-lock-in.md R2 | TR-lock-001: the options set | D2 |
| child-lock-in.md R3–R5, R7 | engage, disengage, never trap, timeout | D5, D6 (state in `KidCore`), D3 (key) |
| child-lock-in.md R6 | extra displays, sleep | D4, D5 |
| child-lock-in.md R8 | Guided Access status | D7 |
| app-shell-title.md R7; ADR-0006 D4 | the kiosk's full-screen mode | D1 and the decision rule |
| parent-gate-panel.md G7, G8/G11 | Quit while `kioskModeOn`; overlays keep key | D3, D5 (overlays inside the one window) |

## Performance Implications
- **CPU / Memory**: one window subclass and up to one cover per extra display. **Load / Network**: none.

## Migration Plan
In `apple/`, the Mac target's window moves from SwiftUI's `WindowGroup` to an AppKit-created `NSWindow` subclass
hosting the same SwiftUI root (D3), with `isRestorable = false` and no frame autosave, so restoration stays off as the
scaffold has it. `prototypes/DeviceSpike`'s Lock screen (both modes, covers, chord stub, overlay stub) and its
Guided Access page are the spike; the Child Lock-in adapter story rewrites them.

## Validation Criteria
Per K-34: headless runs need no MAC FREE; anything on the Mac's screen does. Ask the leader before any build
(TASK-102).

**Headless (done):**
- **H-1** `DeviceSpike` builds for the iOS Simulator (Guided Access page) and macOS (Lock screen with both modes, the
  options set with the 27 availability branch, covers, the chord and overlay stubs) with no warnings (`production/qa/evidence/TASK-087/e606ad36/`).

**Headless (to run with the adapter story, or before the rows on the leader's OK):**
- **H-2** The options-set function: the macOS 26 set and the 27 set (with `.disableScreenCornerInteractions` and
  `.hideDock`), as values.
- **H-3** `windowCoversDisplay` for both modes from window and screen frames; cover windows report
  `canBecomeKey == false`, the kiosk window `true`.

**Device rows (pending; the decision rule above):** M-3 (`mac-1/M-3/`), M-4 (`mac-1/M-4/`), M-5 (`mac-1/M-5/`), M-6
(`mac-1/M-6/`), M-7 (`mac-1/M-7/`), P-4 (`ipad-1/P-4/`), as in `production/qa/device-checks-plan.md`. M-7's full
form needs the real gate (Parent Gate G1–G11); the spike runs it with the stub overlay and the production re-run
repeats it.

## Related
- ADR-0002 (D6, D7); ADR-0006 (D1, D4); ADR-0007 (the chord); ADR-0012 (Android screen pinning).
- Child Lock-in, App Shell & Title, Parent Gate & Grown-up Panel GDDs.
- `docs/engine-reference-local/native-apple/modules/appkit-kiosk.md`, `modules/guided-access.md` (updated).
