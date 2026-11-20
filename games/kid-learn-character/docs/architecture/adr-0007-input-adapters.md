# ADR-0007: Input adapters (iPad presses, Mac key monitor, the key-state read, touches)

## Status

Proposed (TASK-102, 2026-11-18). **Acceptance waits for the device rows M-1, M-2, M-3 (its keyboard part), P-15 and
P-4's keyboard part** (Decision rule below); the rule is fixed now, before any row runs.

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**

## Date

2026-11-18

## Last Verified

2026-11-18, against Input & Key Filter as merged (R1–R8, the States table, AC-1a–t; TASK-083 adapter rules, TASK-098
`gateDigitUp`, R6's ⌘-release clear), input-filter-v2 (95 cases), Child Lock-in (R2, R5), Parent Gate (G2), ADR-0002
(D2, D5, D6 `KeyStateQuery`), ADR-0006 (D2), the TASK-075 plan, the device-checks plan and the Xcode 27.1 SDK
headers (Sources).

## Decision Makers

Luan (accepts, after the rows); game-dev-ios (author, TASK-102); game-dev-android (independent review; ADR-0012 maps
the neutral rules); game-qc-ios (rows and evidence); game-leader.

## Summary

Input & Key Filter decides what every key and touch means; ADR-0002 D5 fixed the normalized `KeyEvent` and
`TouchEvent` that `KidCore` receives. This ADR fixes the Apple adapters that produce them: a thin platform reader
feeding a pure, tested mapper; on the iPad the first responder's `pressesBegan/Ended/Cancelled`, on the Mac an
`NSEvent` local monitor for key-down, key-up and `flagsChanged`; the adapter rules Input names (numpad, Esc, system
keys, the touch-batch sort); the synchronous consume/pass answer; and `KeyStateQuery`, wired **only if** M-1 shows no
Input Monitoring prompt. Each decision is a platform-neutral **Rule** plus its **Apple** form.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | None from the template's table (ADR-0001, K-28). Swift 6.4, Xcode 27.1, SDKs iOS 27.1 / macOS 27.0, deployment 26 |
| **Domain** | Input |
| **Layer** | Platform adapters (app target), feeding `KidCore`'s Input |
| **Knowledge Risk** | HIGH for the Mac key-state read and TCC (M-1); MEDIUM for iPad hardware-keyboard delivery (P-15) |
| **References Consulted** | `docs/engine-reference-local/native-apple/` (`modules/uikit-input.md`, `modules/appkit-kiosk.md`); the SDK headers below; TASK-033; `prototypes/DeviceSpike` (TASK-078: Keys screen, `SpikeKit.KeyMap`) |
| **Post-Cutoff APIs Used** | none beyond those proven in TASK-033 (`NSEvent` local monitor, `pressesBegan` / `UIKey`) |
| **Verification Required** | Validation H-1–H-4 (headless), rows M-1, M-2, M-3, P-15, P-4 (keyboard) |

### Sources (Xcode 27.1 SDK headers, read 2026-11-18)
- `AppKit/NSEvent.h`, `addLocalMonitorForEventsMatchingMask:handler:`: "receives events before they are dispatched by
  -[NSApplication sendEvent:]. In this case, your block should either return a valid NSEvent … to cause the event to
  be dispatched, or it may return nil to stop dispatching of the event. Note that your handler will not be called for
  events that are consumed by nested event-tracking loops such as control tracking, menu tracking, or window
  dragging." And for `addGlobal…`: "Key-related events may only be monitored if accessibility is enabled or if your
  application is trusted for accessibility access" — **this ADR uses no global monitor**.
- `CoreGraphics/CGEventSource.h`, `CGEventSourceKeyState`: "Return a Boolean value indicating the current keyboard
  state of a Quartz event source." *The header says nothing about TCC*; whether reading it raises an Input Monitoring
  prompt is **unsourced** and is M-1's question.
- `IOKit/hidsystem/IOHIDLib.h`, `kIOHIDRequestTypeListenEvent`: "Request to listen to event through
  IOHIDManager/IOHIDDevice API. Access must be granted by the user" — the Input Monitoring permission this app must
  never trigger (PKC: no system dialog).
- `UIKit/UIKey.h`: `charactersIgnoringModifiers`, `modifierFlags`, `keyCode` (`UIKeyboardHIDUsage`).
- `UIKit/UIResponder.h`, `pressesBegan:withEvent:`: "all responders which do custom press handling should override
  all four of these methods. Your responder will receive either pressesEnded:withEvent or pressesCancelled:withEvent:
  for each press it is handling … You must handle cancelled presses".

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Accepted); ADR-0002 (Accepted: D2, D5, D6 `KeyStateQuery`); ADR-0006 (Accepted: D2 the window-px → stage transform) |
| **Enables** | The Input adapter stories (iPad, Mac); ADR-0008 (the chord is the kiosk's way out); input-filter-v2's cases run against the real adapters |
| **Blocks** | The adapter stories; the macOS release (Input AC-1k6 via M-1) |
| **Ordering Note** | With ADR-0008 (shared Mac session: "lock and keys") |

## Context

### Problem Statement
`KidCore`'s Input filter takes `KeyEvent`s and `TouchEvent`s and answers each key-down with a disposition (consume or
pass) and outputs (presses, `gateDigit`, `gateDigitUp`, `openPanel`, …). Nothing yet says how the platforms produce
those events, which key ids and tables they use, where the adapter rules Input delegates live (numpad, Esc, system
keys, the batch sort), how the disposition reaches the platform in time, or whether the Mac's OS key-state read can
be used without a permission prompt.

### Constraints
- No system dialog in front of the child (PKC); no accessibility trust, no global monitor, no event tap.
- `UIKey` cannot be constructed in a test; `NSEvent.keyEvent(...)` can.
- The disposition must be known **inside** the platform callback (UIKit calls `super` or not; the monitor returns the
  event or nil).

### Requirements
- Every Input rule, case for case (input-filter-v2), from the adapters' real output.
- The way out: ⌃⌥⌘Q on the Mac at any time the kiosk is on (Child Lock-in R5, Parent Gate G2).

## Decision

### D1. Reader → mapper → `KidCore`
**Rule.** Each platform has a **thin reader** (it only copies the platform's fields) and a **pure mapper** from those
fields to D5's `KeyEvent` / `TouchEvent`. The mapper holds every table and adapter rule and is unit-tested without a
device; the reader is too small to be wrong without the mapper's tests catching it on a device (P-15, M-3).
**Apple.** iPad reader: `(UIKey.keyCode, charactersIgnoringModifiers, modifierFlags, phase)`; Mac reader:
`(NSEvent.keyCode, charactersIgnoringModifiers, modifierFlags, isARepeat, type)`. The mapper is the production form
of `SpikeKit.KeyMap` (TASK-078), rewritten to standards, in the app target (it knows platform key codes; `KidCore`
never does, ADR-0002 D6).

### D2. Key ids, characters and the adapter rules Input names
**Rule.**
- `physicalId` is the platform's **layout-independent** physical key id, prefixed by platform (`hid:<usage>`,
  `mac:<keyCode>`; Android's scanCode, Input R4); Input's held set keys on it (R4).
- `character` is the base-level character (Input R2.2). `positionKey` is the US-QWERTY position of the 26 letters
  and the top-row digits (R2.3).
- **Numpad (TASK-083, IF-Q1):** a keypad 0–9 key arrives as `character = nil`, `positionKey` = its digit, whatever
  Num Lock says; Num Lock is only the `numLock` modifier bit.
- **Esc (IF-Q8):** `character = "\u{1b}"` on every platform.
- **Hardware system keys (IF-Q2):** never become a `KeyEvent`; the reader passes them to the system before the
  mapper (volume, mute, brightness, media, power, camera).
- **Modifiers:** shift, caps, ctrl, alt, cmd, fn (where the platform reports it), numLock, as D5's bitmask.
**Apple.**
- iPad: HID usages 0x04–0x1D letters, 0x1E–0x27 digits, 0x59–0x62 keypad 1–0, 0x29 Esc; system keys are the HID
  consumer usages and any usage the mapper's table marks system (the reader calls `super` for them, P-4 records what
  a hardware keyboard's media keys actually deliver). `UIKeyModifierFlags`: `.shift`, `.alphaShift`, `.control`,
  `.alternate`, `.command`, `.numericPad` (keypad indicator, not Num Lock). The iPad reports no Fn flag (P-15
  records whether Globe/Fn ever arrives).
- Mac: ANSI key codes (A 0, S 1, … the table in `SpikeKit.KeyMap.macPositions`), keypad 82–92, Esc 53;
  `NSEvent.ModifierFlags`: `.shift`, `.capsLock`, `.control`, `.option`, `.command`, `.function`, `.numericPad`. Media
  keys arrive as system-defined events, not key-down, so the monitor never sees them (Input R5).

### D3. Delivery and the disposition
**Rule.** Events go to `KidCore` **synchronously, on the main thread, in delivery order**, inside the platform
callback; `KidCore` returns the key-down's disposition (consume / pass) before the callback returns, and the reader
applies it. Ups, cancels and modifier changes carry no disposition (input-filter-v2).
**Apple.**
- iPad: a first-responder view in the stage overrides all four `presses…` methods (header: handle cancelled
  presses). The disposition is **per press**: the reader calls `super` with **only the passed presses** of the
  `Set<UIPress>`, the consumed ones never. A `pressesCancelled` becomes `kind: cancel` (Input R4: clears the held
  set). Focus loss (the scene leaving active) is App Shell's `AppLifecycle` → Input's Inactive. UIKit sends no repeats
  through `pressesBegan` (a held key is one began), so on the iPad R4's repeat rule works through the held set alone.
- **First responder** (game-dev-android): the stage's responder **stays first responder through the gate challenge**
  (the SwiftUI keypad overlay is touch-only and never takes focus), so `gateDigit` / `gateDigitUp` / `gateCancel` keep
  arriving. When **Panel open** begins (Input States: keys pass to the panel's responders), the stage responder
  resigns so the panel's own controls can take keys; when the panel closes it becomes first responder again. Input's
  held set clears on both edges anyway (R4).
- Mac: one `NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged])` (app-wide, so no
  responder hand-off is needed; in Panel open a passed key reaches the panel's responders); consume = return `nil`,
  pass = return the event; **focus loss** (the window resigns key, or the app resigns active) is delivered as Input
  R1's focus loss / Inactive (the held set clears); `flagsChanged` → `kind: modifiersChanged` with the new mask (R6's ⌘-release clear runs on
  it in `KidCore`, ADR-0002 D5). The monitor is installed before the first frame (App Shell R1 step 3; Child Lock-in
  R3: "the chord handler installed" is this monitor). It is never called during menu tracking (header); with the
  kiosk on, the menu bar is hidden, and with it off ⌘-combinations pass to the menus anyway (Input R5).
- Whether macOS delivers a key's **up** to the local monitor while ⌘ is held is **not sourced**; Input's R6 clears the
  held set on ⌘-up either way, and M-3's Keys log records which happens.

### D4. `KeyStateQuery` (the Mac's OS key-state read): conditional on M-1
**Rule.** The chord check may read the OS key state ("is any non-modifier key down except Q") **only if** that read
raises no permission prompt on a clean machine; otherwise the seam is absent and Input judges the chord from its held
set, kept honest by R6's ⌘-release clear (already the GDD's fallback, AC-1k3 on the held-set path).
**Apple.** `anyNonModifierDown(except:)` = `CGEventSourceKeyState(.combinedSessionState, key)` over the virtual key
codes 0–127 except the modifiers (54–63) and the excepted key. **Wired only if M-1 passes**; if M-1 shows a prompt,
or lists the app under Privacy & Security › Input Monitoring, the read is **removed from the build** (not switched
off at run time: a prompt at the first chord would already be in front of the grown-up or the child). DeviceSpike
keeps the read behind a switch that is off by default (TASK-078 minimal check item 6), so M-1's first launch is clean; M-1
then turns it on and the Keys log counts the calls, so the row proves the read ran.

### D5. Touches
**Rule.** A touch arrives as D5's `TouchEvent` in **window pixels** with its pointer id and phase; `KidCore` converts
it through ADR-0006 D2. An unordered batch of touch-downs is **sorted by the adapter** by timestamp, then x, then y,
ascending, exact equality, and delivered one at a time (Input R7, IF-Q10).
**Apple.** iPad: `touchesBegan/Moved/Ended/Cancelled` on the stage view, points × `pxPerPt` (ADR-0006 D2), the
`Set<UITouch>` batch sorted as above; the pointer id is stable per `UITouch` for its life. Mac: every mouse button is a
touch (Input R1): the primary as pointer 0, the secondary (`rightMouseDown`) as pointer 1, others (`otherMouseDown`)
as 2 + `buttonNumber`; down / dragged / up, in window pixels (backing scale).

### D6. Hardware keyboard presence (note 2026-11-20, TASK-138; K-49, TASK-135)
**Rule.** The Onscreen Keyboard Row shows in Play when no hardware keyboard is attached (its R8: `shown = keyboardRow
OR NOT keyboardPresent`, with its own 0.5 s settle). The adapter **reports presence only**; the row owns the rule, the
settle and every timing (R8). Presence is never stored (Settings Store, TASK-135).
- **Delivery.** One value, `keyboardPresent: Bool`, passed into `KidCore` through the keyboard row's own declared
  entry point (contracts/case-schema-v1 allows a contract to add one; keyboard-row-v2 declares it as the `keyboard
  {present}` event and a `given` field). It is delivered synchronously on the main thread, like D3's events:
  - **at launch, before the first frame** (after the settings read, before App Shell's `ready`; ADR-0002 D7's launch
    order is otherwise unchanged);
  - **on every return to the foreground** (the row's background rule relies on this read);
  - **on every change** while the app runs.
- **No new seam.** Presence is a value the adapter pushes into one `KidCore` entry point, as `accessibilityChanged`
  and `displayMetricsChanged` are; `KidCore` never queries the platform for it. So ADR-0002 D6's seam table is not
  changed (leader, TASK-138). The entry point's exact name is the keyboard-row story's, in `contracts/kidcore-api.md`.
- **Separate from key input.** Presence never changes how keys are read or filtered (D1–D3): the reader and Input &
  Key Filter neither read nor depend on it.

**Apple.**
- **iPadOS:** `GCKeyboard.coalesced != nil` (Game Controller framework), read at launch and on each foreground
  return, then `GCKeyboardDidConnect` / `GCKeyboardDidDisconnect`. Sourced from the 27.1 SDK header `GCKeyboard.h`:
  `coalescedKeyboard` and both notifications are `ios(14.0)` / `macos(11.0)`, and "all connected keyboards are
  coalesced into one keyboard object, so notification about connection/disconnection will only be delivered once
  until last keyboard disconnects", which is exactly "present while any is attached". The header does not say which
  queue posts the notifications, so the adapter hops to the main thread before calling `KidCore`. The adapter installs **no** `GCKeyboardInput` handler
  (keys stay on D3's `pressesBegan` path) and sets no game-controller Info.plist keys. At launch `coalesced` may be
  nil for a moment with a keyboard attached and the connect may follow; the row's settle and Play-only display cover
  it (TASK-135 review). Not sourced: the exact launch timing of the first connect; AC-25 (attach and detach on a real
  iPad) measures it.
- **macOS:** the constant `true`, delivered once at launch; no detection (the row's R9: every Mac has a keyboard).
- **iPadOS only, by construction:** the one `import GameController` sits inside `#if os(iOS)` in the iPad presence
  reader, and the target adds no `GameController.framework` to its link phase (Swift links an imported module
  automatically, so the import is the only link). The Mac binary therefore never links it.
- **Privacy and build (PKC).** `GameController.framework` is an Apple system framework (`/System/Library/…`), so
  PKC-03 (b) holds, and it is not on PKC-02's list (`GameKit` is; `GameController` is not). It reads no network,
  location or identifier and has no required-reason API (PKC-09 unchanged). **But it is a new linked framework, so
  PKC-13's review gate applies:** the PR that links it is flagged by QC and needs this ADR note and Luan's
  decision. **Decided: Luan approved linking GameController on iPadOS only (K-51, 2026-11-20).**
- **The `otool -L` expectation is two-sided** (QC's PKC-02/03 observation): `GameController.framework` **present**
  in the iPadOS app binary and **absent** from the macOS one. Either way round is a finding.
- **Fallback if Luan declines the framework:** no public UIKit signal is known that reports a keyboard before its
  first key press (not sourced: none found in the 27.1 SDK headers' UIKit key and press APIs), so the row would fall back to K-49's predecessor (shown only when `keyboardRow` is on) on the iPad; that
  is a design change for Luan, not an adapter choice.

### Decision rule (fixed before the rows run)
| Row | Pass (decides this ADR) | If it fails |
|---|---|---|
| **M-1** Input Monitoring | `tccutil reset ListenEvent com.galaxyandsun.devicespike`; launch with the read's switch **off** (the clean baseline); turn the switch **ON**; press ⌃⌥⌘Q and a few ⌘ combinations; the Keys log must show **"key-state read called (n=…)" with n > 0** (otherwise the row tested nothing); then **no prompt** and the app **not listed** under Privacy & Security › Input Monitoring (screenshot). The result holds for DeviceSpike's bundle id only (TCC is per bundle); the production AC-1k6 repeats it for the app (game-qc-ios) | `KeyStateQuery` is **removed** from the build (D4); input-filter-v2's AC-1k3 runs on the held-set path; the ADR records "absent" |
| **M-2** ⌘ window before the chord | the launch log shows settings read → monitor installed within `engage_timeout_s` (5 s); ⌘-keys swallowed meanwhile is accepted (Child Lock-in Edge Cases) | a longer window is a defect in the launch order (App Shell R1), not in this ADR's choice |
| **M-3** (keyboard part) physical keyboard, lock on | ⌘H, ⌘Q, ⌘Space never reach the system; every key in the Keys log normalizes as input-filter-v2 expects; the log records whether ups arrive under ⌘ | a wrong normalization is a table fix in the mapper (D2), not a design change; a ⌘-combination that escapes the monitor goes to ADR-0008 (the options set) |
| **P-15** iPad hardware keys | all 36 keys, the numpad (Num Lock on and off), Shift / Caps / ⌘ / ⌥ / ⌃ (Fn / Globe where reported) arrive through `pressesBegan` and normalize as input-filter-v2 expects; repeats and ups recorded | a key not delivered at all is recorded as a platform limit (Input's NOT ASSESSED list); a wrong normalization is a table fix |
| **P-4** (keyboard part) iPad media keys | volume, mute, brightness, play/pause never become presses and keep their system function | any that arrives in `pressesBegan` is added to the reader's pass-to-system list (D2) |
Acceptance needs all rows passing (M-1 either way: it decides D4), or Luan accepting a recorded exception. **Spike
rows decide this ADR; Input AC-1k6 (M-1) and the Input ACs re-run on the production app** (device-checks plan, Spike
runs).

### Architecture Diagram
```
UIKit presses / touches ─┐                         ┌─ consume → no super / nil
AppKit monitor / mouse ──┼─ reader ─ mapper (D2) ──┼─▶ KidCore Input (R1–R8) ─▶ outputs (press, gateDigit, …)
                         │        tables, numpad,  │        │
                         │        Esc, system keys │        └─ disposition, synchronously (D3)
                         └─ KeyStateQuery (D4, only if M-1 passes)
```

### Key Interfaces
- `KeyEvent`, `TouchEvent` (ADR-0002 D5); `KeyStateQuery` (D6, optional, D4 here); the disposition is the return
  value of `KidCore`'s key entry point (consume / pass).
- `keyboardPresent: Bool` into the keyboard row's entry point (this ADR's D6, note 2026-11-20; not ADR-0002 D6).

### Implementation Guidelines
- One reader per platform, nothing else in the app reads keys; the gate's keypad and the panel use Input's outputs
  and the platform's own controls (Input States: Panel open passes keys to the panel's responders).
- No global monitor, no event tap, no accessibility trust, no `IOHID…` API (PKC).
- The mapper's tables are data in code with tests per layout (US, AZERTY, QWERTZ, Cyrillic) and per platform.

## Alternatives Considered

### Alternative 1: `UIKeyCommand`s on the iPad
- **Rejected**: one command per key and modifier set, no ups, and `wantsPriorityOverSystemBehavior` cannot win
  against system shortcuts anyway (Child Lock-in R8); `pressesBegan` gives every key with its up.

### Alternative 2: A global monitor or an event tap on the Mac
- **Rejected**: both need accessibility trust or Input Monitoring (headers), i.e. a system dialog (PKC).

### Alternative 3: Override `NSWindow.sendEvent` / `keyDown` instead of a local monitor
- **Rejected for now**: the local monitor sees events before `sendEvent` for the whole app, including the overlays,
  and was proven in TASK-033; a window override would miss events routed elsewhere. Kept as the fallback if M-3
  shows a key the monitor misses.

## Consequences

### Positive
- Every Input rule is checked against real adapter output by the same cases (input-filter-v2) on both platforms.
- No permission is ever asked for; the key-state read is all-or-nothing by build.

### Negative
- Without `KeyStateQuery` (if M-1 fails) a stale key after a long unbroken ⌘ can block the chord until ⌘ is released
  (Input R6's accepted limit).
- iPad shortcuts the system keeps (⌘Tab, Globe) never reach the app; Guided Access is the answer (ADR-0008).

### Neutral
- Fn is reported on the Mac only.

## Risks
- **`CGEventSourceKeyState` triggers Input Monitoring** on some macOS version. Mitigation: D4 is decided by M-1 per
  build, and the production re-run of AC-1k6 repeats it (TCC is per bundle id).
- **A hardware keyboard delivers an unexpected HID usage** (layouts, media keys). Mitigation: P-15, P-4; table fixes
  are mapper data.
- **Key-ups lost under ⌘** (AppKit). Mitigation: Input R6's ⌘-release clear, AC-1k3/AC-1s, the M-3 log.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| input-key-filter.md R1–R4 | TR-input-001: classify by character, position, modifiers, held set | D1, D2 (ids, tables, numpad, Esc) |
| input-key-filter.md R5 | swallow vs pass; system keys untouched | D2 (system keys before the mapper), D3 (disposition) |
| input-key-filter.md R6, AC-1j/k/k3/k6 | the chord, the ⌘-release clear, the key-state read | D3 (`flagsChanged` → `modifiersChanged`), D4 |
| input-key-filter.md R7 | touches, the batch sort | D5 |
| input-key-filter.md R8 (gateDigit, gateDigitUp, gateCancel) | outputs from adapter events | D2, D3 (ups and cancels carry the events KidCore needs) |
| child-lock-in.md R3, R5 | the chord handler installed before the lock | D3 (the monitor at launch) |

## Performance Implications
- **CPU**: one table lookup and one `KidCore` call per event; the optional key-state read is 118 calls on a chord only.
- **Memory / Load / Network**: none.

## Migration Plan
None in `apple/`. `prototypes/DeviceSpike`'s Keys screen and `SpikeKit.KeyMap` are the spike; the adapter stories
rewrite them.

## Validation Criteria
Per K-34: headless runs need no MAC FREE; anything on the Mac's screen or keyboard does. Ask the leader before any
build (TASK-102).

**Headless (done):**
- **H-1** `SpikeKit` (TASK-078): 7 tests pass, including the ASCII fold, AZERTY / Cyrillic / numpad positions and the
  chord's modifier rule (`production/qa/evidence/TASK-078/2f2803d7/test.txt`).
- **H-2** `DeviceSpike` (Keys screen, the key-state read behind an off switch) builds for the iOS Simulator and macOS
  with no warnings (`production/qa/evidence/TASK-087/e606ad36/`); the minimal spike check's item 6 confirms the read
  is off by default (`production/qa/evidence/TASK-078/ea51346e/spike-check-devicespike.txt`).

**Headless (to run with the adapter story, or before the rows on the leader's OK):**
- **H-3** The mapper over input-filter-v2's key cases: every case's raw tuple (HID usage or Mac key code, characters,
  flags) maps to the case's `KeyEvent`, for the iPad and Mac tables.
- **H-4** Mac host test: synthesized `NSEvent.keyEvent(...)` and `flagsChanged` events through the local monitor reach
  the mapper and honour the disposition (nil swallows).

**With the D6 presence read (note 2026-11-20):**
- **H-5** On the iPadOS Release product, `otool -L` lists `GameController.framework`; on the macOS product it does not
  (D6, K-51).
- **P-15 and the Keyboard Row's AC-25 run on a build that includes D6's presence read.** P-15's key comparison
  against input-filter-v2 then also proves the presence read leaves presses unchanged. AC-25 (attach and detach a
  hardware keyboard on a real iPad) measures the launch timing of the first connect that D6 leaves unsourced.

**Device rows (pending; the decision rule above):** M-1 (`mac-1/M-1/`), M-2 (`mac-1/M-2/`), M-3 (`mac-1/M-3/`, the
keyboard part), P-15 (`ipad-1/P-15/`), P-4 (`ipad-1/P-4/`, the keyboard part), as in
`production/qa/device-checks-plan.md`.

## Related
- ADR-0002 (D5, D6); ADR-0006 (D2); ADR-0008 (the kiosk; shared Mac session); ADR-0012 (Android: the neutral rules).
- Input & Key Filter, Child Lock-in, Parent Gate GDDs; contracts `input-filter-v2`.
- `docs/engine-reference-local/native-apple/modules/uikit-input.md` (updated with the Sources above).
