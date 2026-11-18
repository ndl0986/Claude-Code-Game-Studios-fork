# Input & Key Filter

> **Status**: Approved (lean review APPROVED 2026-11-18, TASK-037; independent read by game-dev-android APPROVE; merged 2026-11-18)
> **Author**: game-dev-ios (TASK-037); decisions by Luan; plan reviewed by game-dev-android
> **Last Updated**: 2026-11-18 (TASK-056a cross-review fixes)
> **Last Verified**: 2026-11-18, against ADR-0001 (Accepted), art bible §7, the TASK-033 spike
> (`prototypes/TASK-033-anim-runtime/Spike/Input.swift`) and the one-shot `prototypes/letter-morph-dinosaur/`
> **Implements Pillar**: 1 (Every Press Answers), 5 (Safe by Design)

## Summary

Input & Key Filter is the only way a press enters the game. It turns a hardware key, a touch on a hint letter, a
touch on the optional keyboard row, or a Mac click into **one kind of press event**, or into a non-press action
(a sparkle, a cast-member tap, a moon hold, the parent chord), or into nothing at all.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None` (it reads hit regions that
> Hint Letters, the On-screen Keyboard Row, the Parent Gate and the Reveal Stage publish)

## Overview

A 2.5-year-old will press everything: letters, Space, Esc, ⌘, several keys at once, and the same key held down.
This system decides which of those presses count. Only a letter A–Z or a digit 0–9, pressed without Ctrl,
Alt/Option, Cmd/Meta or Fn, becomes a press. It counts once per key-down, never on repeat. Every other key is
**swallowed**: it does nothing, and it is never passed on to the system or another control. Touches are sorted by
what they land on. The filter is a pure function in `KidCore` with a unit test (ADR-0001 Decision 9a), so iPad, Mac
and later Android share one rulebook; each platform only adapts its own events into it.

The system has no visuals or sound of its own. What a press looks and sounds like belongs to the Press Queue and
the Reveal Stage.

## Detailed Design

### Core Rules

**R1. Sources.** Every input arrives as one of these candidate events. The platform code adapts it; the rules
below decide what it becomes.

| Source | iPadOS | macOS | Android (for its own ADR) |
|---|---|---|---|
| Hardware key down / up | `pressesBegan` / `pressesEnded` on the first responder | a local `keyDown` / `keyUp` monitor | `onKeyDown` / `onKeyUp` (the Android ADR should catch keys in the Activity's `dispatchKeyEvent`, before focus and IME routing) |
| Touch down | `touchesBegan` (each `UITouch`) | `mouseDown`, `rightMouseDown`, `otherMouseDown` (each counts as a touch down) | `ACTION_DOWN` / `ACTION_POINTER_DOWN` (each pointer id) |
| Cancel / focus loss | `pressesCancelled`, `touchesCancelled`, scene leaves foreground | window resigns key, app resigns active | `onWindowFocusChanged(false)`, `onPause`, `FLAG_CANCELED`, `ACTION_CANCEL` |

Hover, mouse-move, scroll and drag events are ignored. A touch counts on its **down**; moving or lifting it
changes nothing, except a moon touch, whose end the Parent Gate needs (R7).

**R2. What a hardware key resolves to** (Luan, 2026-11-18: by the character printed on the key, with a position
fallback). For each key-down, in this order:
1. **Numpad digit** (a keypad 0–9 by its physical position) → that digit, whether Num Lock is on or off.
   **The adapters do this** *(TASK-083, IF-Q1)*: a keypad 0–9 key arrives as `positionKey` = its digit with
   `character = nil` (Num Lock is only the `numLock` bit, which R3 ignores), so the fold below never sees it and the
   position fallback gives the digit. No KeyEvent field marks a numpad key (ADR-0002 D5 unchanged).
2. **Character first:** take the key's **base-level character**, the character it types with no modifiers:
   - iPadOS `UIKey.charactersIgnoringModifiers`;
   - macOS `NSEvent.charactersIgnoringModifiers`;
   - Android `KeyCharacterMap.get(keyCode, 0)`.
   Apple's two APIs still apply Shift; the fold below makes that harmless. **Fold:** if it is exactly one
   character and, after ASCII upper-casing, it is `A`–`Z` or `0`–`9`, that is the key. Accents are not stripped:
   `é` is not `E`.
3. **Position fallback (US QWERTY):** otherwise, if the key sits where a US QWERTY keyboard has a letter or a
   top-row digit, use that letter or digit. The position comes from iPadOS `UIKeyboardHIDUsage`, macOS `keyCode`,
   and Android `scanCode` read through the US evdev map (`KEY_A` = 30 → A …), or `keyCode` when `scanCode` is 0. This gives the AZERTY digit row (`&é"'(`… → 1 2 3 4 5…) and
   non-Latin layouts (Cyrillic `в` → D) all 36 keys.
4. Otherwise the key resolves to **nothing** (Space, Esc, Tab, Return, arrows, F-keys, punctuation, dead keys,
   Globe).
   **Esc** arrives as `character = "\u{1b}"` on every platform (the Android adapter maps `KEYCODE_ESCAPE` to it
   explicitly, since `KeyCharacterMap` can give 0). It resolves to nothing here; only the Gate challenge reads it
   (`gateCancel`, R8) *(TASK-083, IF-Q8)*.

So the child gets the letter printed on the keycap: AZERTY's A key is A, and QWERTZ's Z key is Z.

**R3. Modifiers.**
- **Disqualifying:** any of Ctrl, Alt/Option, Cmd/Meta, Fn (where the platform reports Fn). A key resolved to A–Z/0–9 with any of them held is
  not a press; it is swallowed (R5), unless it is the parent chord (R6).
- **Ignored:** Shift, Caps Lock, Num Lock. `d`, `D` and Shift+D are all D.

**R4. Held keys and repeats.** A press is **the first down of a key**.
- The filter keeps a **held set** of physical key ids (iPad `UIKeyboardHIDUsage`, Mac `keyCode`, Android
  `scanCode` if non-zero, else `keyCode`). It uses physical ids, not characters, because the character can change
  between down and up. Android's fallback exists because injected keys (`adb input keyevent`, accessibility
  services, IMEs, some virtual keyboards) often carry `scanCode` 0, and would otherwise all share id 0. The id
  records which of the two it is (scan or key), so a `scanCode` and a `keyCode` with the same number never match.
- A down whose key is already in the held set, or that the platform marks as a repeat (`NSEvent.isARepeat`,
  Android `repeatCount > 0`), is **ignored**: no press, nothing emitted, and it is not passed on.
- A down for a key that is still in the held set because its up was missed is ignored until that key's up or a
  clear.
- An up removes the key from the held set. An up for a key that is not held is ignored.
- **Clear:** the held set empties on every cancel or focus loss in R1, when the app goes to the background, and
  when the grown-up panel opens or closes.
- A key must come up before it can count again. The knob `repress_min_s` (default 0, off) can add a minimum gap
  between two presses of the same key (Tuning Knobs).

**R5. Swallowed means nothing** (Luan's play notes: "các phím còn lại… sẽ bị mất tác dụng"). A key-down that is
not a press, not a repeat and not the parent chord:
- emits **nothing**: no sparkle, no sound, no queue entry;
- is **never passed on**: iPadOS handles `pressesBegan` without calling `super`; the macOS monitor returns `nil`;
  Android `onKeyDown` returns `true`.
- **One signal for ⌘: Input's kiosk-on mode, `kioskModeOn`** *(TASK-056 W-1)*. Child Lock-in sets it when the lock
  starts waiting to engage and clears it when the lock is Off (its R4, R7), including after an engage timeout. The
  Parent Gate's G7 shows Quit exactly while it is on, i.e. whenever ⌘Q doesn't work. **With the mode off**,
  ⌘-combinations go on to the menus (⌘Q quits, as any Mac app) and are not presses (ADR-0001 Decision 9). **With the
  mode on**, ⌘-combinations are swallowed **in every state**: Play, Title, Gate challenge and Panel open. They never
  reach the menus, so ⌘Q in the panel can never skip the Quit button's 1.5 s hold (Parent Gate G8/G11, Child Lock-in
  R2) *(TASK-054 I3)*. With the lock OFF for this run, or after an engage timeout, the mode is off and ⌘Q quits as usual (K-21's
  second way out). Input reads nothing else for this: not `childLockActive`, not the kiosk's presentation options.
  **The mode-off exception is macOS only** *(TASK-083, IF-Q11)*: on iPadOS every ⌘-combination is an ordinary
  disqualified key, swallowed (R3) in every state, whatever the mode; iPadOS keeps ⌘Tab, ⌘H and Globe before the app
  sees them anyway (below).
- **Hardware system keys always pass:** volume up/down, mute, power, camera and brightness are never presses
  and never swallowed; they go to the system untouched (Android `onKeyDown` returns `false` / calls `super`, so
  the volume rocker keeps working; iPadOS calls `super`). On the Mac, media keys arrive as system-defined events,
  not `keyDown`, so the monitor likely never sees them. iPad hardware-keyboard media keys: NOT ASSESSED.
  **They never reach `KidCore`** *(TASK-083, IF-Q2)*: the adapters pass them on before building a KeyEvent, so
  this rule is tested in the adapter suites (AC-1m), and `KidCore` has no system-key cases.
- **Not this system's job:** keys the operating system keeps before the app sees them (iPad ⌘Tab, ⌘H, Globe; Mac
  Mission Control; Android Home and Recents) belong to Child Lock-in and the platform. Android Back is handled
  there as an `OnBackPressedCallback` that does nothing.

**R6. The parent chord** (Luan, 2026-11-18). "Open the grown-up panel" is an abstract action with a binding per
platform.
- **macOS:** **⌃⌥⌘Q**, exactly those three modifiers plus Q, as in the TASK-033 kiosk. **Shift and Caps Lock are
  ignored; Fn disqualifies** *(TASK-056 B-1, leader call in K-26: on a laptop fn sits next to ⌃, so a palm on the
  bottom-left row hits it)*: ⌃⌥⌘Q with Fn held is not the chord, as R3 already treats Fn. It counts
  **only when no other key is held**: the held set (R4) is **empty when Q goes down** (⌃⌥⌘ are read from the
  modifier flags; on the Mac they arrive as `flagsChanged` and are not in the held set). ⌃⌥⌘Q with D still down is not
  the chord *(TASK-050)*.
- **A stale held key never blocks the chord** *(safety, TASK-054 I1; Parent Gate AC-27)*. macOS can drop the key-up
  of a key released while ⌘ is held, which would leave it in the held set for good. So:
  - **the chord check reads the OS key state at the Q down**, not the held set: `CGEventSource.keyState(
    .combinedSessionState, key:)` for every non-modifier virtual key code other than Q; the chord counts when none is
    down (Parent Gate G2: exactly ⌃⌥⌘Q, from the OS key state);
  - and, to keep the held set itself honest, **when ⌘ is released** (`modifiersChanged` with the cmd bit clearing;
    `flagsChanged` on the Mac) **the held set empties**, on every platform *(TASK-083, IF-Q9, safety)*. macOS can
    drop the up of any key released under ⌘, whenever that key went down, so every key is cleared, not only those
    pressed under ⌘.
  - **A key still physically down when ⌘ goes up** is out of the held set but cannot become a second press: its
    next events are repeats (ignored, R4) or its up (an up for a key not held is ignored). Modifiers, Fn included,
    live in `modifiers`, not in the held set, so R3 and the Fn rule (K-26) are unchanged. In the Gate challenge such
    a key no longer counts for `gateDigit`'s `anotherKeyHeld` (R8).
  - **The ⌘-release rule alone passes AC-27's stale-key case** (AC-1k3): a key lost under ⌘ leaves the held set the
    moment ⌘ is released, so the next ⌃⌥⌘Q counts.
  - **The key-state read is a build decision, with a release check** (PKC: no system dialog may appear in a Kids
    app). The read ships only if it triggers **no Input Monitoring prompt**. Check on a clean Mac: `tccutil reset
    ListenEvent <bundle id>`, first launch with the lock on, then press ⌃⌥⌘Q. Pass: no prompt appears, and the app
    is not listed under System Settings › Privacy & Security › Input Monitoring. If it prompts, the read is removed
    from the build, and the chord uses the held set alone, kept honest by the ⌘-release rule (AC-1k6). There is no
    run-time fallback: a prompt at the first chord would already be in front of the child or the grown-up.
  - **Limit of the held set alone:** if ⌘ stays down without a break, a stale key keeps blocking the chord until ⌘ is
    released; **releasing ⌘ and pressing the chord again always clears it**, whenever the stale key went down.
- The chord replaces the moon hold only: the gate's second step (the number in words) still shows (K-19).
- **iPadOS: no chord**, even with a hardware keyboard. Holding the moon is the only way in. ⌃⌥⌘Q on an iPad is
  an ordinary disqualified key: swallowed (R3, R5), like every ⌘-combination on iPadOS.
- **Android:** chosen by its ADR.
- The chord works with the kiosk on and off. It is never a press and emits only `openPanel`, which **starts the
  gate's second step** (K-19); the panel itself opens only after the correct answer.
- **During the gate challenge** (K-20) no key or touch reaches play: no press, no sparkle, no creature tap. Keys
  and touches go to the challenge only (what it accepts is the Parent Gate GDD's). A wrong answer or a timeout
  returns to **the state the gate was opened from** (Title or Play), with the held set cleared as for the panel
  *(TASK-050; TASK-054 I4)*.
- **Where the chord works** *(TASK-054 I4; Parent Gate G2)*: in **Play and on the Title**; it is **ignored** in the
  Gate challenge and in Panel open, and during the gate's 10 s moon sleep (the Parent Gate ignores `openPanel`
  then).
- **Order of checks for a key-down:** hardware system key → pass to the system (R5) → repeat / held (R4) →
  parent chord (R6) → disqualifying modifiers, with the
  macOS kiosk-off ⌘ exception (R3, R5) → resolve the key (R2). So ⌃⌥⌘Q opens the panel even with the kiosk off,
  where other ⌘-combinations go to the menus.

**R7. Touch classification.** A touch down is tested against these layers, top first; the first hit wins:

| Order | Layer (who publishes the hit region) | Becomes |
|---|---|---|
| 1 | Hint letter (Hint Letters): circle of `hitRadius` (Formulas); counts while the hint is on stage, **even while fading** | a **press** of that hint's key, `source = hint(id)`; the hint is marked touched and holds still (art bible §7) |
| 2 | Keyboard-row key (On-screen Keyboard Row, only when a grown-up turned it on): the drawn key rectangle | a **press** of that key, `source = keyboardRow` |
| 3 | The moon (Parent Gate) | `gateTouch(began)` with its pointer id, then `gateTouch(ended)` on its up, its cancel, **or when that pointer moves outside the moon's region plus `moon_slop_pt` (20 pt on screen; Parent Gate G1)** *(TASK-054 I2)*, whichever comes first, once. Not a press |
| 4 | A cast member on stage (Reveal Stage) | `creatureTap(point)`: the hop and its sound. Not a press |
| 5 | Anything else on the stage | `sparkle(point)` (decided: as played in the one-shot) |

- **Multi-touch:** every touch down (each pointer id) is classified on its own. Two fingers on two hints are two
  presses.
- **Order within one touch batch:** iPadOS `touchesBegan` delivers an unordered `Set`, so the **adapter** sorts the
  batch by timestamp, then x, then y, all ascending, in window pixels with exact equality, and hands the touches to
  `KidCore` one at a time *(TASK-083, IF-Q7, IF-Q10)*. F1 is one positive scale plus an offset, so this is the stage
  order too; touches equal in all three classify the same, so their order cannot matter. `KidCore` has no sort cases. Android delivers one pointer down per event
  and the Mac one click per event, so their order is the delivery order.
- **A hint touched again** while it is still on stage is another press of its key, like pressing a key twice. The
  Press Queue decides what plays.
- **Overlapping hints:** the hint whose centre is nearest the touch wins.

**R8. The press event contract** (what Input emits to the Press Queue).

| Field | Type | Meaning |
|---|---|---|
| `key` | one character, `"A"`–`"Z"` or `"0"`–`"9"` | the same key format as the key table (Key Table & Theme Data) |
| `source` | `hardwareKey` · `hint(id)` · `keyboardRow` | where it came from |
| `time` | seconds, double | the event's own timestamp on the platform's **monotonic uptime clock** (iOS/macOS event `timestamp` = `systemUptime`; Android `getEventTime() / 1000`), never the wall clock |
| `origin` | stage point, or `nil` | where a touch landed (the hint's centre for a hint, the key's centre for a row key); **`nil` from Input for a hardware key**: the Play router sets it from Hint Letters' `originFor(key)` before `press(p)` (K-18: a matching hint is consumed and the glyph rises from it). The glyph rises from here (art bible §7) |

- **Order:** events go out in **delivery order**, synchronously in the platform's event callback. A tie or an
  out-of-order timestamp never reorders or drops an event; `time` is carried for the Queue's use only.
- **No dropping:** Input never drops or rate-limits a press. The mash rule (3 queued, extras sparkle) is the
  Press Queue's.
- **Other outputs:** `sparkle(point)`, `creatureTap(point)`, `gateTouch(began | ended, pointerId)`,
  `openPanel`, on the title screen only `startPlay`, and in the Gate challenge only `gateDigit(digit, anotherKeyHeld)`,
  `gateDigitUp(digit)` and `gateCancel` *(TASK-083, TASK-098)*. A swallowed or ignored key emits nothing.
- **Gate outputs** *(TASK-083, IF-Q4, IF-Q8; TASK-098)*. None is a press; none reaches the Press Queue.
  - `gateDigit(digit, anotherKeyHeld)`: a key-down in the Gate challenge that R2 resolves to 0–9 (main row or
    numpad, Num Lock on or off; AZERTY's digit row by position), with no disqualifying modifier (R3), not a repeat
    and not held (R4). `digit` is "0"–"9". `anotherKeyHeld` is true when another key that resolved to 0–9 is in the
    held set at that down (the held set keeps each key's resolved value from its down); the Parent Gate judges two
    digit keys down at once as wrong.
  - `gateDigitUp(digit)` *(TASK-098; Parent Gate G13 B7)*: emitted in the Gate challenge whenever a key that
    produced a `gateDigit` **leaves the held set**: (1) by its key-up; (2) by a clear on cancel or focus loss (R4)
    while the challenge shows; (3) by the ⌘-release clear (R6). One per such key, with the `digit` its `gateDigit`
    carried, in the order the keys went down. **Nothing** is emitted for a key that never produced a `gateDigit` (a
    non-digit, a disqualified, repeated or held down, or a key held from before the challenge), nor on the clear
    when **leaving** the challenge (the gate is gone then). Two physical keys giving the same digit (main row and
    numpad) each get their own up. So the Parent Gate can keep a **count of digit keys down** (+1 per `gateDigit`,
    −1 per `gateDigitUp`) and judge a keypad touch made while it is above 0 (its B7). After a ⌘-release clear the
    count is 0 even if a digit key is still physically down: that key's later repeats and up emit nothing (R6), so
    a keypad touch then is not judged wrong; accepted, as R6 accepts it for the chord. No KeyEvent field is needed
    (ADR-0002 D5 unchanged).
  - `gateCancel`: Esc (`character` "\u{1b}", R2) going down in the Gate challenge, with Shift or Caps Lock or
    none, not a repeat and not held. Esc with ⌃, ⌥, ⌘ or Fn is swallowed instead (⌘ per R5).
  - Every other key-down in the Gate challenge is swallowed. A key held from before the challenge (the held set
    clears on enter) or across a ⌘ release (R6) is not in the held set: it does not count for `anotherKeyHeld`, and
    its repeats and up emit nothing.

### States and Transitions

| State | Hardware keys | Touches | Enter / leave |
|---|---|---|---|
| **Play** | R2–R6 | R7 | entered from the title (play button or a letter/digit key); left by the panel opening or the app leaving the foreground |
| **Gate challenge** (K-20) | nothing reaches Play or the queue; **digit keys go only to the challenge's keypad** as `gateDigit`, and their release as `gateDigitUp` (also on a clear, R8), Esc emits `gateCancel` (R8), every other key emits nothing (system keys still pass, R5) | **go only to the keypad**; anywhere else emits nothing | entered by `openPanel` (chord or moon hold); a wrong answer, a timeout, **Cancel or Esc** → **the state it was opened from** (Title or Play) *(TASK-056 W-2)*, a correct answer → Panel open; the held set clears on enter and on leave. ⌘-combinations swallowed while the kiosk-on mode is on (R5); the chord ignored (R6) |
| **Panel open** | the filter is off; keys go to the grown-up panel as normal input (Input emits nothing; a non-⌘ key passes to the panel's responders, TASK-083 IF-Q5), **except ⌘-combinations while the kiosk-on mode is on**, which are swallowed and never reach the menus (R5, TASK-054 I3); the chord is ignored (R6). Only the panel's own close returns to the state the gate was opened from | go to the panel | entered by `openPanel` (chord or moon hold); the held set clears on enter and on leave |
| **Title** | a key-down that would be a press in Play (R2–R6: resolves to A–Z/0–9, no disqualifying modifier, not a repeat or held) emits `startPlay`, the same as the play button, and **is not a press** (no reveal for that key); every other key emits nothing (system keys still pass, R5), except the Mac chord, which emits `openPanel` (R6) | belong to App Shell (the moon goes to the Parent Gate, layer 3) | entered and left by the App Shell; the held set is **kept** from Title into Play, so the starting key's repeats and up are ignored and only its next down is a press (Luan, 2026-11-18) |
| **Inactive** (background, window not key) | nothing emitted; held set cleared | — | the App Shell switches states |

### Interactions with Other Systems

- **Press Queue:** receives every press event (R8) and owns the mash rule and the timing that uses `time`.
- **Hint Letters:** publishes each hint's centre, drawn radius, visibility and id; receives "touched" so the hint
  holds still for `hint_hold_s`.
- **On-screen Keyboard Row:** publishes its key rectangles when on; a row touch is a press here, not in the row.
- **Parent Gate & Grown-up Panel:** receives `gateTouch`, `openPanel`, and in the Gate challenge `gateDigit` and `gateCancel` (TASK-083); owns how long the moon must be held.
  Tells Input when the panel opens and closes. On iPad the moon is the only way in (R6).
- **Child Lock-in:** owns the macOS kiosk switch, which changes R5's ⌘ exception, and the system keys Input
  never sees.
- **Reveal Stage:** publishes the cast member's hit shape; receives `creatureTap`; uses `origin` for where the
  glyph rises, and chooses a start point when `origin` is `nil`.
- **Settings Store:** keeps whether the keyboard row is on. The chord binding is not a setting (R6).

## Formulas

**F1. Hint hit radius.**

`hitRadius = drawRadius × hint_hit_scale`; a touch at point `t` hits hint `h` when
`sqrt((t.x − h.x)² + (t.y − h.y)²) ≤ hitRadius`.

| Variable | Meaning | Range |
|---|---|---|
| `drawRadius` | the hint bubble's drawn radius, in stage units (1280 × 720 stage) | ~60 (a 120 px bubble, art bible §7) |
| `hint_hit_scale` | how much larger the touch area is than the bubble | 1.0–1.5; **1.25 provisional** |
| `t`, `h` | the touch point and the hint centre, both in stage units | on stage |

Example: `drawRadius = 60`, scale 1.25 → `hitRadius = 75`. A touch 70 units from the centre counts (70 ≤ 75); one
at 80 does not and falls through to the next layer (R7). On an 11" iPad a 120 px bubble is about 75–80 pt (art
bible §7), so the touch area is about 94–100 pt across.

**F2. Re-press gap (off by default).** A down of key `k` at `time = t₂` counts only if
`t₂ − t₁ ≥ repress_min_s`, where `t₁` is the time of the last counted press of `k`. With the default
`repress_min_s = 0` every first down counts. Example: with 0.08 s, presses of D at 10.00 s and 10.05 s → only the
first counts; at 10.00 s and 10.10 s → both count.

## Edge Cases

- **If a key is held while the panel opens and is released inside the panel:** the held set cleared on open, so
  its up is ignored (R4), and the next down of that key after the panel closes is a press.
- **If the app goes to the background while a key is down:** the held set clears; the up never arrives; the next
  down is a press.
- **If an up is missed without a cancel** (a rare platform quirk): that key's downs are ignored until its up or
  the next clear. Any focus change recovers it.
- **If a key is still physically down when ⌘ is released:** the held set empties anyway (R6); that key's repeats and
  up emit nothing, it is never pressed twice, and in the Gate challenge it no longer counts for `anotherKeyHeld`
  *(TASK-083, IF-Q9)*.
- **If two keys go down in the same event batch:** each is its own press, in delivery order (R8).
- **If the child presses the volume rocker or another hardware system key:** the system handles it (volume
  changes); no press, no sparkle (R5).
- **If keys are injected** (`adb input keyevent`, an accessibility service) on Android with `scanCode` 0: the
  held set uses `keyCode` (R4), and the position fallback uses `keyCode` (R2.3).
- **If one key is held and another is pressed repeatedly:** the held key stays ignored; each new down of the
  other key is a press.
- **If the child mashes ten keys at once:** ten presses go to the Press Queue, which keeps 3 and sparkles the rest.
  Input drops none.
- **If Caps Lock is on:** no effect (R3).
- **If a Shift is stuck** (held by the child's elbow): no effect. A stuck Ctrl, Option or ⌘ makes every key
  swallowed until it is released; this is accepted, since the key gives nothing (R5) and lifting it restores play.
- **If the parent chord is part-pressed** (⌃⌥ + Q without ⌘): it is not the chord; Q with disqualifying modifiers
  is swallowed.
- **If a numpad key is pressed with Num Lock off:** it is still its digit (R2.1).
- **If a key prints a non-Latin character** (Cyrillic, Greek, Arabic): the position fallback gives its US
  letter (R2.3).
- **If the keyboard is AZERTY:** the letter keys play the printed letter; the unshifted digit row plays its digit
  by position.
- **If a touch lands on a fading hint in the frame it is removed:** it counts if the hint was on stage when the
  touch was classified, otherwise it falls to the next layer.
- **If a touch lands where a hint and the moon overlap:** the hint wins (R7). Hints drift, so the moon is free a
  moment later.
- **If two fingers touch the same hint:** two presses of that key.
- **If a Mac user right-clicks:** it is a touch down like any click; no context menu opens.
- **If a Bluetooth keyboard connects or disconnects mid-session, or two keyboards are used:** the rules are per
  event, so nothing changes in design. Device behaviour is NOT ASSESSED.
- **If an input method or IME is active** (Japanese, Vietnamese Telex): no text field is focused, so keys should
  arrive raw. NOT ASSESSED.

## Dependencies

**Upstream:** none. Input is a Foundation system. It reads hit regions that other systems publish (R7), but does
not depend on their rules.

**Downstream** (each of their GDDs must name Input & Key Filter):

| System | What it takes from Input |
|---|---|
| Press Queue | the press event (R8) |
| Parent Gate & Grown-up Panel | `openPanel`, `gateTouch`, `gateDigit`, `gateCancel` (TASK-083); panel open/close back to Input |
| Child Lock-in | R5's swallowing; the kiosk switch changes the ⌘ exception |
| Hint Letters | hint touches become presses here; "touched" back to the hint |
| On-screen Keyboard Row | row touches become presses here |
| Reveal Stage | `creatureTap`, `sparkle`, the press `origin` |
| App Shell & Title | `startPlay` and the Title's touches; the Title, Play and Inactive states it switches *(TASK-056 W-9)* |

**Systems index:** Hint Letters and the On-screen Keyboard Row list Input & Key Filter among their dependencies
(their touches reach the Queue through Input); this was a leader note and is done *(TASK-056 W-9)*.

**Architecture:** ADR-0001 (Accepted) Decision 4 (`KidCore` has no UI imports) and Decision 9a (the filter in
`KidCore` with a unit test). The platform adapters live in the app target.

## Tuning Knobs

All values are data, not code.

| Knob | Default | Safe range | Affects | Owner |
|---|---|---|---|---|
| `hint_hit_scale` | **1.25 (provisional)** | 1.0–1.5 | how forgiving a hint touch is; above ~1.5 nearby hints and the moon start to steal each other's touches | Input (F1) |
| `moon_slop_pt` | 20 pt | 10–40 | how far a finger may slide off the moon before the hold ends (layer 3, Parent Gate G1) *(TASK-054 I2)* | **Input** (owns the value and the range; Parent Gate cites it, TASK-056 W-8) |
| `hint_hold_s` | **1.0 s (provisional)** | 0.5–3.0 s | how long a touched hint stays still and visible before it hands over to the glyph | Hint Letters (listed here because the touch rule sets it) |
| `repress_min_s` | **0 (off)** | 0–0.15 s | filters a bouncy keyboard or a double-hit; above ~0.15 s a deliberate quick re-press is lost (Pillar 1) | Input (F2) |
| Parent chord (macOS) | **⌃⌥⌘Q (decided)** | — | the grown-up's keyboard way into the panel | Luan, 2026-11-18; fixed in code, not a setting |

The two provisional values are tuned in play (leader, 2026-11-18).

## Game Feel

- **No added delay:** a press is emitted in the same event callback that delivered it. Input never waits, batches
  or debounces (with `repress_min_s = 0`).
- **What the child feels:** every letter or digit answers; everything else is silent. The silence is the design
  (R5): a toddler learns that only letter keys do anything.

## Cross-References

- ADR-0001 Native Apple (Accepted): Decisions 4 and 9; Validation Criteria; Open follow-up 4.
- Art bible §7: hint touch rule, target size, keyboard row, parent chord for keyboard-only grown-ups.
- Game concept: Core Mechanics 1 (key input) and 6 (parent gate and lock-in); Pillars 1 and 5.
- TASK-033 report `design/tech/TASK-033-anim-runtime.md` and `Spike/Input.swift` (character-based filter, held
  set); the one-shot `prototypes/letter-morph-dinosaur/index.html` (position-based `isLetterOrDigit`,
  `preventDefault` on all keys, held set cleared on `blur`).

## Acceptance Criteria

**Unit tests in `KidCore` (automated, BLOCKING):**

- **AC-1 `KeyFilterTests` (ADR-0001 Decision 9a):**
  - **a.** GIVEN a US layout, WHEN each of A–Z, a–z, 0–9 and numpad 0–9 goes down once with no modifiers, THEN
    each resolves to its key ("a" → "A") and emits exactly one press.
  - **b.** GIVEN no modifiers, WHEN each of Space, Esc, Tab, Return, Backspace, the four arrows, F1–F12, `-`,
    `=`, `[`, `;`, `'`, `,`, `.`, `/` and a dead key goes down, THEN nothing is emitted and each is marked
    swallowed (not passed on). (Hardware system keys are not in this list; see m.)
  - **c.** GIVEN the letter D, WHEN it goes down with each of Ctrl, Option, ⌘ and Fn, alone and in pairs, THEN
    nothing is emitted (swallowed); WHEN it goes down with Shift or Caps Lock, THEN one press of "D". The ⌘ cases
    are swallowed on iPadOS always and on macOS with the kiosk-on mode on; on macOS with the mode off they pass to the
    system (k) *(TASK-083, IF-Q11)*.
  - **d.** GIVEN D is down, WHEN a repeat-flagged down or a second down of D arrives before its up, THEN nothing
    is emitted; WHEN D goes up and down again, THEN one more press.
  - **e.** GIVEN D is held, WHEN a cancel / focus loss / panel open-or-close clears the set and D goes down again
    without an up, THEN one press.
  - **f.** GIVEN an up for a key that is not held, THEN nothing changes.
  - **g.** GIVEN an AZERTY layout, WHEN the keys printed A, Z, Q, M and the unshifted digit-row keys (`&`, `é`,
    `"` …) go down, THEN they give A, Z, Q, M and 1, 2, 3 …; GIVEN QWERTZ, the Z key gives Z.
  - **h.** GIVEN a Cyrillic layout, WHEN the key at the US D position goes down (base character `в`), THEN one
    press of "D".
  - **i.** GIVEN Num Lock off, WHEN numpad 7 goes down, THEN one press of "7". (`KidCore` sees `character` nil,
    `positionKey` "7", R2.1; the adapter mapping is an adapter test, TASK-083.)
  - **j.** GIVEN macOS, WHEN ⌃⌥⌘Q goes down, THEN `openPanel` and no press; WHEN ⌃⌥Q (no ⌘) goes down, THEN
    nothing. GIVEN iPadOS, WHEN ⌃⌥⌘Q goes down, THEN nothing (no chord on iPad). GIVEN macOS with D held, WHEN
    ⌃⌥⌘Q goes down, THEN no `openPanel` (TASK-050). GIVEN macOS, WHEN ⌃⌥⌘Q goes down with Fn held, THEN no
    `openPanel` (swallowed, R3); with Shift or Caps Lock held, THEN `openPanel` (TASK-056 B-1). GIVEN the gate challenge showing, WHEN D goes down or the
    stage is touched, THEN no press and no sparkle (K-20).
  - **k.** *(TASK-054 I3; one signal, TASK-056 W-1)* GIVEN macOS with Input's kiosk-on mode **off**, WHEN ⌘Q goes
    down, THEN "pass to system". GIVEN the mode **on**, WHEN ⌘Q, ⌘H or ⌘W goes down in Play, the Title, the Gate
    challenge or Panel open, THEN swallowed (never passed to the menus) in each state. GIVEN `childLockActive` true
    but the mode off (after Child Lock-in's engage timeout), WHEN ⌘Q goes down, THEN "pass to system".
  - **k3.** *(TASK-054 I1, Parent Gate AC-27)* GIVEN macOS, D down, ⌘ down, D up lost (no key-up delivered), WHEN ⌘ is
    released, THEN D is no longer in the held set; WHEN ⌃⌥⌘Q then goes down with the OS key state showing only Q,
    THEN `openPanel`. GIVEN the OS key state showing D still physically down, THEN no `openPanel`. The same holds
    for the order ⌘ down, D down, D up lost. GIVEN D still physically down after ⌘ is released, WHEN D's repeats and
    its up arrive, THEN nothing is emitted *(TASK-083, IF-Q9)*.
  - **k4.** *(TASK-054 I4)* GIVEN the Title, WHEN ⌃⌥⌘Q goes down, THEN `openPanel`; GIVEN the gate opened from the
    Title, WHEN the answer is wrong or times out, or Cancel or Esc is pressed, THEN the Title state (TASK-056 W-2); GIVEN Panel open or the Gate challenge, WHEN
    ⌃⌥⌘Q goes down, THEN no `openPanel`.
  - **k5.** *(TASK-054 I2)* GIVEN a pointer down on the moon, WHEN it moves to 19 pt outside the moon's region, THEN
    no `gateTouch(ended)`; WHEN it moves to 21 pt outside, THEN exactly one `gateTouch(ended)`, and none again on its up.
  - **k6.** *(TASK-054 I1; release-blocking for the macOS build; real Mac, NOT ASSESSED until run, needs MAC FREE)*
    On a clean Mac (`tccutil reset ListenEvent <bundle id>`), first launch with the child lock on, press ⌃⌥⌘Q: THEN
    no system prompt appears, the gate opens, and the app is not listed under Privacy & Security › Input Monitoring.
    If a prompt appears, the build removes the key-state read and k3 is re-run on the held-set-only path. This is
    evidence for Parent Gate AC-27 and Privacy & Kids Compliance (no system dialog in front of the child).
  - **l.** GIVEN `repress_min_s = 0.08`, WHEN D is pressed at 10.00 s and 10.05 s, THEN one press; at 10.00 s and
    10.10 s, THEN two; at 10.000 s and 10.080 s, THEN two (F2 boundary: a gap equal to `repress_min_s` counts; the
    test compares with a 1e-9 s tolerance so floating-point rounding can't flip it).
  - **m.** *(adapter suites, TASK-083 IF-Q2)* GIVEN Play, WHEN volume up, volume down, mute, power, camera or
    brightness goes down, with or without modifiers, THEN no KeyEvent reaches `KidCore` and the adapter passes it
    to the system. The adapter suites also check: a keypad 0–9 key gives `character` nil and `positionKey` its
    digit; Esc gives `character` "\u{1b}" (Android `KEYCODE_ESCAPE` included); an unordered iPad touch batch comes
    out sorted by timestamp, x, y (R7).
  - **n.** GIVEN Android ids, WHEN key-downs arrive with `scanCode` 0 and `keyCode`s for D and B, THEN two
    presses (D, B); WHEN D's second down arrives before its up, THEN nothing; WHEN a key with `scanCode` 32 and one
    with `scanCode` 0 / `keyCode` 32 are both down, THEN they are two different held keys.
  - **o.** GIVEN the Title state, WHEN D goes down, THEN `startPlay` and no press; WHEN D repeats or goes up
    after the switch to Play, THEN nothing; WHEN D goes down again, THEN one press of "D". GIVEN Title, WHEN
    Space or ⌘D goes down, THEN nothing.
  - **p.** *(TASK-083)* GIVEN the Gate challenge, WHEN 4 on the main row, numpad 4 with Num Lock off, or AZERTY's
    `'` key goes down alone, THEN `gateDigit("4", false)` and no press; WHEN 7 goes down while 4 is still held,
    THEN `gateDigit("7", true)`; WHEN D, Space, ⌃4 or a repeat of 4 goes down, THEN nothing; GIVEN macOS with the
    kiosk-on mode on, WHEN ⌘4 goes down, THEN swallowed.
  - **q.** *(TASK-083)* GIVEN the Gate challenge, WHEN Esc or Shift+Esc goes down, THEN `gateCancel`; WHEN ⌃Esc or a
    repeat of Esc goes down, THEN nothing. GIVEN Play or the Title, WHEN Esc goes down, THEN nothing.
  - **r.** *(TASK-083)* GIVEN Panel open, WHEN D or 4 goes down, THEN nothing is emitted and the key passes to the
    panel; GIVEN macOS with the kiosk-on mode on, WHEN ⌘Q goes down, THEN swallowed.
  - **s.** *(TASK-083, IF-Q9)* GIVEN D down and then ⌘ down, WHEN ⌘ is released, THEN the held set is empty; GIVEN
    ⌘ down and then D down, likewise.
  - **t.** *(TASK-098)* GIVEN the Gate challenge, WHEN 4 goes down and up, THEN `gateDigit("4", false)` then
    `gateDigitUp("4")`; WHEN 4 (main row) and numpad 4 go down, then up in either order, THEN two `gateDigitUp("4")`;
    WHEN D goes down and up, or ⌃4 goes down and up, THEN no `gateDigitUp`; GIVEN 4 and 7 down, WHEN a focus loss
    clears the held set, THEN `gateDigitUp("4")` then `gateDigitUp("7")`; GIVEN macOS, 4 down and ⌘ down, WHEN ⌘ is
    released, THEN `gateDigitUp("4")` (and 4's later up emits nothing); GIVEN 4 down, WHEN the challenge is left
    (correct, wrong, timeout, Cancel), THEN no `gateDigitUp`; GIVEN a digit key held from before the challenge, WHEN
    it goes up, THEN nothing.
- **AC-2 Order:** GIVEN three key-downs delivered in the order D (t = 5.002), B (t = 5.001), 3 (t = 5.001), WHEN
  they are filtered, THEN the presses come out D, B, 3 in delivery order with their own `time` values, none
  dropped.
- **AC-3 Touch classification (stage geometry, no UI):**
  - **a.** GIVEN a hint at (400, 200) with `drawRadius` 60 and scale 1.25, WHEN touches land 74.9 and 75.0 units
    away, THEN both are presses of its key with `source = hint(id)` and `origin` = (400, 200); WHEN at 75.1, THEN
    it falls to the next layer.
  - **b.** GIVEN the hint is fading (opacity 0.1), WHEN it is touched, THEN it is a press and the hint is marked
    touched.
  - **c.** GIVEN a hint overlapping the moon, WHEN the overlap is touched, THEN a press, no `gateTouch`.
  - **d.** GIVEN no hint, row key, moon or cast member at the point, WHEN touched, THEN `sparkle(point)`.
  - **e.** GIVEN two pointers going down on two hints in one event, THEN two presses in delivery order; GIVEN
    touches handed to `KidCore` one at a time, THEN each is classified in that order (the iPad batch sort is an
    adapter test, AC-1m; TASK-083 IF-Q10).
  - **f.** GIVEN the keyboard row off, WHEN its (hidden) area is touched, THEN it is not a row press.
- **AC-4 Contract:** every emitted press has `key` in "A"–"Z" / "0"–"9" (one character), a `source`, a finite
  `time`, and `origin` `nil` exactly when `source = hardwareKey`.

**Integration and on-device (screenshot or recorded observation in `production/qa/evidence/`):**

- **AC-5:** GIVEN the app in Play on the iPad Simulator and on a Mac, WHEN all 36 keys are typed on a hardware
  keyboard and the same letters are touched as hints, THEN each gives the same reveal (ADR-0001 Validation:
  "a hardware keyboard … plays the same as touch").
- **AC-6:** GIVEN the Mac kiosk on, WHEN ⌘H, ⌘Q and ⌘Space are pressed on a **physical** keyboard, THEN the app
  stays in front and nothing plays; WHEN the parent chord is pressed, THEN the grown-up panel opens.
- **AC-7:** GIVEN Play, WHEN Space, Esc and the arrows are pressed, THEN nothing visible or audible happens
  (screen recording plus audio).
- **AC-8:** GIVEN Play, WHEN the empty stage is tapped, THEN a sparkle appears at the tap.

**NOT ASSESSED, carried open (not claimed by this GDD):**

- macOS physical keyboard: ⌘Tab, ⌘⌥Esc, Mission Control, Spaces, Globe/fn, hot corners (ADR-0001 Open
  follow-up 4).
- iPad: whether hardware-keyboard shortcuts escape Guided Access.
- IME / input sources active while playing (incl. Vietnamese Telex, Japanese).
- Bluetooth keyboard connect/disconnect mid-session; two keyboards at once.
- Android: `keyCode` as a position on an AZERTY device (`scanCode` is the physical one; check on a device);
  which real devices and keyboards send `scanCode` 0 (the `keyCode` fallback of R2.3 and R4); the US evdev map
  on non-US hardware keyboards; Back/Home handling (Child Lock-in).
- Hardware system keys: iPad hardware-keyboard media keys; Mac media keys (expected to arrive as system-defined
  events, outside the key monitor).

## Open Questions

- None open.
- **Decided, recorded here:**
  - Title screen: any letter or digit key starts play, like the play button; it is not itself a press (Luan,
    2026-11-18; States table).
  - Layout: character first, position fallback (Luan, 2026-11-18).
  - Parent chord: ⌃⌥⌘Q on the Mac only; no chord on iPad, the moon hold only (Luan, 2026-11-18).
  - Swallowed keys give nothing (Luan's play notes, via the leader, 2026-11-18).
  - An empty-stage tap sparkles (as played in the one-shot; the leader, 2026-11-18).
  - `hint_hit_scale` 1.25 and `hint_hold_s` are provisional data, tuned in play (the leader, 2026-11-18).
