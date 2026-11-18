# Parent Gate & Grown-up Panel

> **Status**: Approved (independent read by game-qc-android, merged 2026-11-18; TASK-054a merged 2026-11-18 — Mac release ACs NOT ASSESSED until a Mac build runs AC-1k6 and the real-Mac ACs)
> **Author**: game-qc-ios for Luan (TASK-048); plan reviewed by game-qc-android
> **Last Updated**: 2026-11-18
> **Last Verified**: 2026-11-18
> **Implements Pillar**: Pillar 5 (Safe by Design); serves Pillar 1 (Every Press Answers: play is never lost to a failed gate)

## Summary

The only way a grown-up changes anything. A two-step gate: hold the moon 1.5 s (or press ⌃⌥⌘Q on a
Mac), then enter a 4-digit number shown in words ("Enter four · one · seven · two") on a keypad. It
opens a plain card with the settings, the privacy text, Start over and, on the Mac, the child lock.
A failed gate costs the child nothing: play froze while the challenge showed and simply carries on.

> **Quick reference**: Layer `Feature` · Priority `MVP` · Key deps: Settings Store, Input & Key
> Filter. Read by Child Lock-in (#13), Press Queue, Reveal Stage, Hint Letters, Parade, Audio & Voice.

---

## Overview

The player is a 2.5–3-year-old who mashes keys and screens and is learning the digits 0–9. The
grown-up needs a way in that the child can't find or brute-force, that needs no reading beyond what a
parent does at a glance, and that works with no network and no account (Pillar 5; PKC-01, PKC-07).

- **Step 1** is a hold on the moon, scenery that does not invite a tap (art bible §3), or the parent
  chord on the Mac (K-10, Input R6). It filters out stray touches.
- **Step 2** is the adult-level task Apple asks for ("adult-level tasks that must be completed in
  order to continue", Kids page, TASK-034 A-13): a number written in words. A pre-reader can't read
  it, and a child who knows numerals still can't map "seven" to the 7 key. The game never speaks it.
- The **panel** is the only screen with text (art bible §7). Every control maps to one Settings Store
  field; nothing in it leaves the app (PKC-02).

Luan's decisions: K-19 (two steps, chord replaces the hold, 60 s auto-close, parade button debug-only),
K-20 (4 words, 10 s moon sleep, play freezes during the challenge), K-21 (risk figures; the Mac child
lock turned off reverts at the next launch).

## Player Fantasy

The player here is the parent. *"I hold the moon, tap four numbers, and I'm in. My child pressing
everything never gets past it, and when they do open the number screen by accident, the dinosaur is
still there when it goes away."* The panel is boring on purpose: a card of plain controls, quick to
read at arm's length, closed with one button.

For the child the gate is invisible. The moon is just the moon.

---

## Detailed Design

### Core Rules

**G1. Step 1: the moon hold.**
- **This GDD owns the moon's hit region** and publishes it to Input as touch layer 3 (Input R7): a
  circle of `moon_hit_px` (50 stage px radius, as in the one-shot's `GATE.r`; ≥ 44 pt **diameter** on every supported screen) around the drawn crescent. A touch down on it emits `gateTouch(began, pointerId)`;
  its up or cancel emits `gateTouch(ended, pointerId)`. **Input (TASK-054 I2, landed in TASK-054a (5e1c365)):** Input also emits
  `gateTouch(ended, pointerId)` when that pointer leaves the region grown by `moon_slop_pt` (20 pt), so a finger that drifts a little keeps its hold and one that slides away resets (Input R7 layer 3;
  `moon_slop_pt` is Input's knob, safe range 10–40).
- While one pointer holds the moon, `t_held` grows (measured from the touch's event timestamp, checked
  every frame against the injected clock) and the Starlight ring fills (F1). At `t_held ≥ gate_hold_s`
  (1.5 s, K-19) the challenge opens (G3).
- **Reset:** `gateTouch(ended)` for the holding pointer (up, cancel, or leaving the slop region) sets
  `t_held = 0` at once and empties the ring. A second pointer elsewhere is classified on its own
  (Input R7) and does not cancel the hold; a second pointer *on the moon* is ignored and **does not
  take over** when the first lifts (it must lift and come down again).
- **Mac:** a mouse press-and-hold on the moon works the same way (Input R7 covers the click).
- **Lift before refill:** a pointer that was on the moon when the challenge closed must lift before a
  new hold can start (game-qc-android item 4). Its continued contact does nothing.
- **Moon sleep:** for `moon_sleep_s` (10 s, K-20) after the challenge closes by a **wrong answer** (a
  wrong digit or a second pointer) **or a timeout**, a hold does not fill the ring (F1 stays 0).
  **Cancel and Esc start no sleep**: they make no guess, and the next challenge draws a new code, so
  F2 is unchanged and a parent who backs out isn't made to wait. **Clock:** the sleep runs on the
  injected **continuous monotonic clock**, so it keeps counting while the app is in the background
  (sending the app away and back never shortens or lengthens it). A challenge closed *by*
  backgrounding starts no sleep (Edge Cases). The moon looks the
  same; there is no visible lockout and nothing is stored or counted. A hold that began during sleep counts only from the moment sleep ends (`t_held` starts at 0 then),
  so a finger kept down through sleep opens the challenge at sleep end + 1.5 s.

**G2. The Mac parent chord.** ⌃⌥⌘Q (K-10, Input R6) **replaces step 1 and still shows step 2** (K-19).
It counts only when **exactly ⌃, ⌥, ⌘ and Q are down and no other key is held** (a palm across the
corner of a keyboard holds more keys; game-qc-android item 3).
- **Input R6 owns the chord rule** (K-26): exactly ⌃⌥⌘ + Q; Shift is ignored (Input R6), as are Caps Lock and Num
  Lock (Input R3); **Fn disqualifies** it (a palm on a laptop's bottom-left row hits fn next to ⌃), like any other extra key
  (Input R6 and AC-1j, TASK-056a).
- "No other key held" is judged from **the OS's current key state at the moment Q goes down** (for
  example `CGEventSource.keyState`), not from Input's tracked downs, because macOS can drop the key-up
  of a key pressed while ⌘ is held; a stale tracked key must never disable the way out under the kiosk.
  Input: **TASK-054 I1 (safety), landed in TASK-054a (5e1c365)**. The key-state read ships only if Input AC-1k6 shows no Input
  Monitoring prompt on a clean Mac; otherwise the chord uses the held set kept honest by the ⌘-release
  rule (Input R6), which alone passes AC-27.
- **Moon sleep applies to the chord too:** during sleep the chord does nothing. The chord
  has no 1.5 s hold, so its fastest attempt is a little quicker than the moon's (F2 gives its figure). (A
  grown-up who mistyped waits 10 s.)
- The chord works with the kiosk on and off (Input R6), **on the Title screen and in Play**. It is
  ignored while the challenge or the panel shows. Whether the moon itself is drawn on the Title screen
  is App Shell & Title's (#14); the chord must work there because the Mac lock can be on at launch
  (K-12).
- There is no chord on iPadOS (Input R6) or, for now, Android.
- Input's `openPanel` output means "start the gate's second step" (Input R6 as merged in TASK-050).
- Working on Title, and returning to the state the gate opened from: **TASK-054 I4, landed in TASK-054a (5e1c365)**.

**G3. Step 2: the number challenge.**
- **Code:** four digits `d1 d2 d3 d4`, each drawn uniformly from 0–9 with an **injected seed**, a new
  code every time the challenge opens. All 10,000 codes are allowed, repeats included.
- **Shown as words**, in English until Localization (#19): `zero one two three four five six seven
  eight nine`, separated by " · ", in the panel font, for example **"Enter four · one · seven · two"**.
  Never numerals, never spoken by the game's voice or audio (VoiceOver, turned on by the parent, may
  read it).
- **Keypad:** digits 0–9 in the phone layout (1 2 3 / 4 5 6 / 7 8 9 / 0), fixed. Keys ≥ `key_size_pt`
  (60 pt) with gaps ≥ `key_gap_pt` (12 pt), for an adult finger. Below the code, 4 empty slots fill
  with dots as digits are entered (the digits themselves are never shown). A **Cancel** button sits
  apart from the keypad.
- **One touch at a time, with a lift grace** (game-qc-android's choice for Q5): a second keypad pointer
  down while the first is still down is held pending. If **the first pointer lifts within
  `overlap_grace_s` (0.15 s) of that second down**, the second counts as the next digit (entered at
  the first's lift); otherwise, at 0.15 s, it is **wrong**. A palm that stays down is therefore wrong,
  and **any third simultaneous pointer is wrong at once** (a palm can't enter an ordered sequence;
  item 2). F2 is unchanged: random digits still pass with p = 10⁻⁴. A digit is otherwise entered on its touch *down*, or on
  accessibility activation (VoiceOver double-tap, Switch Control) of the key.
- **Mac hardware digits:** keys 0–9 on the main row and the numeric keypad enter digits too
  (keyboard-only grown-ups, art bible §7). Two digit keys down at once = wrong. A key already held
  when the challenge opens is ignored until it is released. Other keys do nothing; Esc = Cancel.
- **Judging:** each digit is checked when entered. **The first wrong digit closes the challenge at
  once** (wrong). The fourth right digit opens the panel (G6).
- **Dull on purpose** (item 4): a plain grown-up card on the dimmed stage. No sound, no animation, no
  shake, no red; a key shows only its pressed state. Nothing on it is worth tapping for fun.
- **Timeout:** `challenge_timeout_s` (20 s), on the injected **continuous monotonic clock** (the play clock
  is frozen during the challenge, G5; continuous matches moon sleep, G1, and a background closes the
  challenge anyway, so uptime and continuous never differ while it shows), with no **accepted digit** (a keypad touch or digit key
  that enters a right digit), counted from the last one, or from the opening if there was none →
  closes as a timeout. Touches outside the keypad and non-digit keys don't reset it. So a challenge
  lasts at most 20 s × 4 = 80 s.

**G4. Closing a challenge without the panel** (wrong digit, second pointer, Cancel, Esc, timeout).
- The card disappears (Reduce Motion: no fade; otherwise a 0.2 s fade; it also appears with a 0.2 s
  fade, and the dim fades in over 0.2 s). Play **resumes from where it
  froze** (G5). Moon sleep starts (G1).
- **The closing touch is consumed:** its up, and any move of that pointer, never reaches Play (item 4).
  The next touch down is classified normally.
- No message, no penalty, no counter (Settings Store R2 forbids storing gate attempts).

**G5. Play freezes while the challenge shows** (K-20).
- On challenge open: the reveal, the Press Queue, the hints' timers and a running parade **freeze** in
  place. Input enters the **Gate challenge** state: touches and digit keys go to the keypad only; no
  press, hint touch, sparkle or creature tap is emitted, so **no press reaches the queue** and the
  queue is unchanged (game-qc-android AC-e).
- Sounds already playing finish, except the **parade tune, which pauses with the walk** and resumes
  with it (Audio & Voice owner and TASK-046); nothing new starts.
- Closing without the panel (G4): everything **resumes from the same frame**; nothing replays.
- A correct code: the panel opens and K-15 applies then (G6).

**G6. Opening the panel** (correct code only).
- K-15 / Press Queue R8: the queue is **cleared**, the current reveal **settles to formed**, and its
  hold counts as passed. A running parade fades out, counts as played and is not replayed (K-17).
  Audio cuts the voice, cast and music players (Audio R6); the panel is quiet.
- Hint Letters stay **frozen** under the dim while the panel shows and resume on close (Hint Letters R9);
  the freeze that began at the challenge simply continues.
- Input enters **Panel open** (its states table): keys and touches go to the panel; the held set clears.
- The panel publishes `panelWillOpen` before any of this and `panelDidClose` after G9.

**G7. The panel's contents.** A "Grown-up card" (art bible §3): rounded rectangle, plain rectangular
controls in Dusk Blue `#46558f`, the bundled family at regular weight 15–22 pt, every target ≥ 44 pt,
centred over the dimmed stage; it scrolls when Dynamic Type makes it taller than the screen.

| Row | Control | Writes / calls | Shown when |
|---|---|---|---|
| Sound | Volume slider, 11 steps 0–10 | `volume`: preview gain to Audio while dragging; store write on release (Settings Store F1, F2, R4; Audio R5) | always |
| Sound | Mute switch | `muted` | always |
| Sound | Static text: "No sound? Check silent mode and the volume." | — (no API reads the silent switch; Audio) | iPadOS |
| Theme | Theme list | `themeId`; the next reveal uses it (Key Table §4, the item pick) | more than one theme bundled (hidden in the MVP: Dinosaurs only) |
| Weather | Clear · Cloudy · Light rain · Snow, and a Windy switch | `weather`, `windy` (Windy enabled only with Light rain or Snow; kept otherwise, Settings Store R1) | once Scene: Time of Day & Weather (#15) ships |
| Keyboard | On-screen keyboard row switch | `keyboardRow` | once On-screen Keyboard Row (#16) ships |
| Child lock | Child lock switch; "Quit" button | `childLock` / `childLockActive` → Child Lock-in (G11); Quit = Child Lock-in disengages (options removed, extra-display covers removed, then Input's kiosk mode off; its R4), then the app terminates | macOS. **Quit shows exactly while `kioskModeOn` is on** (Input's kiosk-on mode, published by Child Lock-in: on in Waiting, Locked and Suspended; Child Lock-in R7, Input R5), i.e. exactly when ⌘Q doesn't work. After an engage timeout `kioskModeOn` is off, so ⌘Q works and there is no Quit row; the switch still shows ON (`childLockActive`) with "Child lock couldn't turn on" |
| Child lock | "Lock the iPad to this app" text: the Guided Access steps (ADR-0001 9c) | — (text only; no link to Settings, which would leave the app). A state line reads Child Lock-in's published `guidedAccessEnabled`: "Guided Access is on" / "Guided Access is off" (K-23) | iPadOS |
| Privacy | "Privacy" row → a page of bundled text inside the panel | — (PKC-07, L-04) | always |
| Debug | "Play the parade now" | Parade manual start (K-17); closes the panel | **debug builds only** (K-19); absent from release |
| Reset | "Start over" | Settings Store R9 (one notification); the panel stays open and every control shows its default | always |
| Close | "Back to play" | G9 | always |

- Every change writes through the Settings Store (R4) and is applied by its owner on the R10
  notification; the panel applies nothing itself (Settings Store R11).
- **"Child lock couldn't turn on"** (macOS, K-23): if Child Lock-in's in-memory engage-failure flag is set
  (a precondition still missing after its timeout), the panel shows this line at the top of the Child
  lock row the next time it opens. Nothing is stored; the flag clears when the lock next engages.
- **The challenge and the panel are drawn inside the main window** (an overlay, never a separate
  window, sheet or popover), so the main window stays key and Child Lock-in's "window stays key" rule
  never drops the lock when the gate opens (TASK-052).
- **Nothing leaves the app:** no link, web view, store, purchase, rating prompt, share sheet, "more
  apps" or Settings-app URL (PKC-02, PKC-07).

**G8. Destructive actions** (Start over, Quit, turning Child lock off).
- The trigger reveals a **"Hold to confirm"** button **at a different spot** on the card (the opposite
  side from the trigger) that must be held for `confirm_hold_s` (1.5 s); a ring fills while held.
  Lifting early cancels; the button hides again after 5 s unused. A tap on the trigger again does
  nothing extra (item 6).
- Turning Child lock **on** needs no confirm (it makes the app safer).

**G9. Closing the panel.**
- Ways: "Back to play", Esc on a hardware keyboard, Android Back (NOT ASSESSED), auto-close (G10), and
  the app leaving the foreground (Edge Cases). No tap-outside close.
- On close: Input returns to **the state the gate was opened from** (Play, or Title if the chord opened
  it there; the same for a challenge closed without the panel) with the held set cleared; the dim fades out over 0.3 s (Reduce
  Motion: instant). The settled, formed creature is on stage; the queue is empty and its hold passed,
  so **the next press starts at once** (K-15, Press Queue R8). Nothing replays.
- **"Child lock is OFF" notice** (macOS, K-21): if the lock is off when the panel closes, the words
  "Child lock is OFF" show in the top-right corner for `lock_notice_s` (3 s), then fade (Reduce Motion:
  disappear). It is parent-facing text, not a control; touches pass through it.

**G10. Auto-close** (K-19). The panel closes (as G9) after `panel_idle_s` (60 s) with no input. The timer resets only on a touch down **on a control** (or a scroll of the card) and on a key down,
**except** that a touch down that is the third or later within any 1 s window (`burst_count` 3,
`burst_window_s` 1) does not reset it (a child mashing the card doesn't keep it open; the touches
still act on controls). A slider drag resets it at its start. Touches on the card's empty area never
reset it. **Hard cap:** the panel closes `panel_max_s` (300 s) after it opened, whatever the input, so slow tapping can't keep it open; a slider drag or confirm hold in progress
finishes first. `panel_max_s` ≥ `panel_idle_s` always. A "Hold to confirm" has its own timer (G8).

**G11. The Child Lock-in interface** (`design/gdd/child-lock-in.md`, #13; this is what it relies on).
- The panel owns the **Child lock switch**, macOS only. **On** → writes `childLock = true`. **Off** (after G8's hold) → turns the lock off **for this run only**: the stored value is not set to
  false, so at the next launch the lock engages again once the app is ready (K-21, K-12, Settings Store
  R8). If the lock was never turned on, it stays off.
- **Runtime state for "off for this run" (TASK-054 S1/S2, landed in TASK-054a (5e1c365); Settings Store R8, R10):** next to the stored
  `childLock`, the store keeps an in-memory `childLockActive` (starts equal to `childLock` at launch).
  Turning the lock off sets `childLockActive = false`, **sends one R10 notification and writes
  nothing**; turning it on sets both and writes. Reset (R9) sets both to false. Child Lock-in applies `childLockActive`. Settings Store R8 and R10 now define both, and its AC-15b
  matches this GDD's AC-15.
- Child Lock-in applies `childLockActive`: a lock **already on stays on while the panel is open** (the
  panel is inside the full-screen app); turning it **off** disengages at once, with the panel still
  open; turning it **on** in the panel engages on `panelDidClose` (TASK-052).
- **While the lock is on, ⌘-combinations stay swallowed in every Input state**, including Gate
  challenge and Panel open, so ⌘Q or ⌥⌘Esc typed in the panel can't skip Quit's hold (Input R5/states, **TASK-054 I3 (safety), landed in TASK-054a (5e1c365)**).
- **The way out with the lock on:** ⌃⌥⌘Q (works with the kiosk on, Input R6) or the moon → step 2 →
  panel → **Quit** (G8 hold), or turn the lock off (G8 hold) and then ⌘Q works again (Input R5).
- Events for #13: `panelDidClose` (Child Lock-in doesn't use `panelWillOpen`, its W-10; the panel still
  publishes it for others), and the `childLockActive` changes (via Settings Store
  R10). From #13 the panel reads `guidedAccessEnabled` (iPadOS), the engage-failure flag and `kioskModeOn`
  (macOS; the Quit row, G7) (TASK-056a).
- #13 owns `presentationOptions`, the ⌘-swallow switch (Input R5), observing Guided Access on iPad and
  the wording of the Guided Access text.

**G12. Android (NOT ASSESSED: no Android build, K-03).** The moon is the only way in (no chord; Input
R6); Back closes the challenge (as Cancel) and the panel; the "lock" row shows screen-pinning steps
instead of Guided Access. The Android ADR confirms each.

### States and Transitions

| State | Entered by | Left by |
|---|---|---|
| **Idle** (play) | launch; G4; G9 | a hold reaching 1.5 s (not asleep) or the exact chord → Challenge |
| **Holding** (sub-state of Idle) | a gate touch down, not asleep, finger lifted since last close | lift/cancel/move off → Idle; F1 = 1 → Challenge |
| **Challenge** | Holding or the chord | wrong digit / second pointer / timeout → Idle + sleep; Cancel / Esc / background → Idle (no sleep); correct → Panel |
| **Panel** | correct code | G9 (button, Esc, auto-close, background) → Idle |
| **Confirm** (sub-state of Panel) | a destructive trigger | hold 1.5 s → action; lift early or 5 s unused → Panel |

Moon sleep is a timer on Idle, not a state the grown-up sees.

### Interactions with Other Systems

| System | Direction | What |
|---|---|---|
| Input & Key Filter (#2) | in / out | in: `gateTouch`, `openPanel` (chord), touches and keys in Challenge and Panel. out: enter/leave **Gate challenge** and **Panel open**. Done in **TASK-050**: the Gate challenge state, the exact chord (held set), the chord ignored during the challenge. Landed in TASK-054a (5e1c365): I1 the chord judged from OS key state if AC-1k6 passes (safety), I2 `gateTouch(ended)` on leaving the slop region, I3 ⌘ swallowed in every state while locked (safety), I4 the chord on Title and return to the origin state |
| Settings Store (#4) | out | writes `volume`, `muted`, `themeId`, `weather`, `windy`, `keyboardRow`, `childLock`; Reset (R9). K-21's "off for this run" changes R1/R8 and adds the runtime `childLockActive` with a write-free R10 notification (G11): **TASK-054 S1/S2, landed in TASK-054a (5e1c365)**; TASK-050 made OFF run-only |
| Press Queue (#7) | out | challenge open → **freeze**, close → **resume** (TASK-050); panel open → clear and settle (R8, K-15) |
| Reveal Stage (#9) | out | challenge open → **freeze/resume** pair next to settle (**TASK-049**); panel open → settle to formed |
| Hint Letters (#10) | out | challenge open → **freeze `hintTime`**, close → resume (**TASK-047**); **panel open → freeze** (under the dim), **panel close → resume** (Hint Letters R9 cites this GDD) |
| Parade (#11) | out | challenge open → **pause the walk**, close → resume (**TASK-046**); panel open → fade out, counts as played (K-17); debug manual start (K-17, K-19) |
| Audio & Voice (#6) | out | slider preview gain (R5); panel open → cut players (R6); challenge open → no cut, nothing new starts, **the parade tune pauses and resumes with the walk** (Audio owner, with TASK-046) |
| App Shell & Title (#14) | — | the chord works on the Title screen (G2); whether the moon is drawn there; backgrounding closes challenge and panel |
| Child Lock-in (#13) | out | G11 |
| Key Table & Theme Data (#1) | — | theme list; next reveal uses the new theme (Key Table §4) |
| Scene: Time of Day & Weather (#15) | in | `look` and `lookBlend` for the moon's opacity (UI Requirements; Scene R1, F1); the Scene draws no moon disc. The weather row appears when it ships |
| Keyboard Row (#16) | — | its row appears when it ships |
| Privacy & Kids Compliance (#5) | constraint | PKC-02, PKC-07, PKC-14 (no input logged in release: the code is never logged) |
| Localization (#19) | later | the number words and panel text |
| Accessibility (#17) | in | Accessibility's `reduceMotion` (its A1; never the OS API), applied on the next frame; Reduce Motion rules here (below) |

---

## Formulas

**F1. Hold progress.** `progress = asleep ? 0 : clamp(t_held / gate_hold_s, 0, 1)`; the challenge opens
when `progress = 1`, that is `t_held ≥ gate_hold_s`.

| Variable | Meaning | Range |
|---|---|---|
| `t_held` | seconds the first pointer has held the moon without a reset (injected clock) | ≥ 0 |
| `gate_hold_s` | the hold time (K-19) | 1.5 (safe 1.5–3.0) |
| `asleep` | inside `moon_sleep_s` after a failed challenge | true / false |

Examples: held 0.75 s → 0.5 (ring half full); held 1.49 s → 0.993, closed; held 1.50 s → opens; held
1.2 s then lifted → 0; held 3 s while asleep → 0. The confirm ring uses the same formula with
`confirm_hold_s`.

**F2. Chance a child passes by random tapping** (K-21).

- Per attempt: `p = 10^(−n)`, with `n` = number of words (4) → `p = 1/10,000`. Uniform random digits
  can't beat it; a second pointer or a wrong digit ends the attempt early.
- Fastest attempt: `T_min = gate_hold_s + t_tap + moon_sleep_s` (one wrong tap ends it; `t_tap` ≈ 0.2 s)
  = 1.5 + 0.2 + 10 = **11.7 s**. Maximum rate `R_max = 3600 / T_min` ≈ **307 attempts per hour**.
- Within one hour at rate `R`: `P(R) = 1 − (1 − p)^R`.

| Case | `R` per hour | `P` within 1 hour |
|---|---|---|
| Realistic: accidental openings (the moon is scenery and needs a still 1.5 s hold) | ≤ 10 | **≤ ~0.1%** (10 → 0.10%; 6 → 0.06%) |
| Nonstop mashing of the gate, every attempt as fast as possible | ~307 | **~3.0%** |
| Mac only: nonstop exact ⌃⌥⌘Q chords with nothing else held (no hold; `T` ≈ 0.3 + 0.2 + 10 = 10.5 s) | ~342 | **~3.4%** |

Luan accepted both figures with 4 words and a 10 s sleep (K-21). A pass lets the child see the panel;
every destructive action still needs a 1.5 s hold at a separate spot (G8), and the panel auto-closes
(G10). The chord row is slightly above K-21's ~3%: it needs a child to press exactly four specific keys
together with no other key, again and again, which is far rarer than holding the moon; flagged to the
leader (Open Questions Q6).

---

## Edge Cases

- **The hold starts during a reveal or a parade:** play continues while the moon is held (step 1 is
  not a freeze); the freeze begins only when the challenge opens.
- **A hint over the moon** (fallback only): Hint Letters F4 already keeps hints off the moon, so this
  shouldn't happen. If it ever did, the hint wins the touch (Input R7) and the grown-up holds again a
  moment later.
- **The app leaves the foreground during a hold:** `t_held` resets. **During the challenge:** the
  challenge closes as Cancel without moon sleep, then K-15's background rule applies to play (Press
  Queue R9). **During the panel:** the panel closes (G9) so a child picking up the device later never
  finds it open.
- **The grown-up returns from the Settings app** (after turning on Guided Access): play, panel closed.
- **A Settings Store write fails** (Settings Store edge cases): the control keeps its new value for this
  run; the panel shows nothing extra.
- **Start over while the Mac lock is on:** Reset removes the record (R9), Child Lock-in turns the kiosk
  off on the notification, and "Child lock is OFF" shows on close.
- **Turning the lock off and then relaunching:** the lock is back on once the app is ready (K-21, K-12).
- **The challenge opens while a key is held** (Mac): that key is ignored until released (G3); a held
  letter does not enter anything.
- **VoiceOver on:** the moon is one element, label "Grown-ups", hint "Double-tap and hold to open
  settings"; VoiceOver's double-tap-and-hold is a long press, so step 1 works. The code text's
  accessibility label has no "·" ("Enter four, one, seven, two"); focus lands on it when the challenge
  opens, keys are labelled with their digit and entered by double-tap, entered digits are announced as
  "dot", and focus returns to the stage when the challenge or panel closes. The game's own voice never
  says the code.
- **Dynamic Type at accessibility sizes:** the card scrolls; the keypad keeps its key size and
  spacing.
- **Two grown-up taps on a confirm trigger:** nothing more happens; only the hold confirms (G8).
- **Switch Control or AssistiveTouch users** may not be able to hold the moon for 1.5 s or hold a
  confirm button. Not solved here; noted for the Accessibility GDD (#17). Keypad keys accept
  accessibility activation (G3).
- **Two-thumb typing on an iPad** can overlap two keypad touches: accepted when the first thumb lifts
  within 0.15 s of the second's down (G3); a longer overlap is wrong.

## Dependencies

- **Settings Store** (Approved): R1 fields, R4 writes and preview, R8, R9 Reset, R10, R11. TASK-050 made
  the lock's OFF run-only (R8, K-21).
- **Input & Key Filter** (Approved): R5, R6 (chord), R7 (moon layer), states. TASK-050 added the Gate
  challenge state and the chord ignored during the challenge; TASK-054a made the exact chord judged from the
  OS key state (if AC-1k6 passes), with Fn disqualifying (K-26).
  **Audio:** the parade tune pauses and resumes with the walk (TASK-050, done).
- **Follow-up TASK-054** (`production/team/TASK-054-followups.md`). **TASK-054a** (Input and Settings
  Store; game-dev-android) is **merged** (5e1c365); **TASK-054b** is split across game-dev-ios,
  game-dev-android and game-qc-ios. 054a landed (all merged in 5e1c365):
  - **S1** an R10 notification for a run-only OFF with no write; **S2** the run value `childLockActive`
    defined in the Settings Store (at launch = stored `childLock`; OFF changes only the run value);
  - **I1 (safety)** the chord's "no other key held" judged from the OS key state;
  - **I2** `gateTouch(ended)` when the pointer leaves the moon slop region;
  - **I3 (safety)** ⌘-combinations swallowed in every Input state while the lock is on;
  - **I4** the chord on Title, and a closed gate returning to the state it opened from.
- **Release-blocking (macOS):** I1 and I3 have landed in Input (TASK-054a), so AC-27 and AC-34 are **no longer blocked by design**, but they stay **NOT ASSESSED** until a Mac build runs Input AC-1k6 (no Input
  Monitoring prompt on a clean Mac; otherwise the key-state read is removed from the build) and the
  real-Mac ACs. AC-15/19 (S1/S2), AC-26 (I2) and AC-31 (I4) now rest on merged rules.
- **Press Queue** R8 (K-15) and its new freeze/resume (TASK-050); **Reveal Stage** freeze/resume
  (TASK-049); **Hint Letters** `hintTime` freeze (TASK-047); **Parade** walk pause and debug start
  (TASK-046, K-17).
- **Audio & Voice** R5 (preview), R6 (panel cut), the silent-mode text.
- **Privacy & Kids Compliance** PKC-02, PKC-07, L-04.
- **Child Lock-in** (#13) builds on G11. **Accessibility** (#17), **Localization** (#19), **Scene**
  (#15), **Keyboard Row** (#16) as listed.
- Decisions K-08, K-10, K-12, K-15, K-17, K-19, K-20, K-21; art bible §2 (moon), §3 (moon gate, grown-up
  card), §4 (Starlight ring, Dusk Blue), §7 (panel type, keyboard-only grown-ups); ADR-0001 9b, 9c;
  TASK-034 A-01, A-13 (Kids rules); the one-shot's panel (`prototypes/letter-morph-dinosaur/index.html`,
  `config.js` `gate_hold_s` 1.5).

## Tuning Knobs

| Knob | Value | Safe range | Affects |
|---|---|---|---|
| `gate_hold_s` | 1.5 (K-19) | 1.5–3.0 | how long a grown-up holds; below 1.5 the F2 figures Luan accepted (K-21) no longer hold. At 3.0: max P ≈ 2.7%/h |
| `moon_sleep_s` | 10 (K-20) | 10–30 | maximum attempt rate; below 10 breaks K-21 (5 s → ≈ 5.2%/h). At 30: max P ≈ 1.1%/h |
| `moon_hit_px`, `moon_slop_pt` | 50 stage px, 20 pt | ≥ 44 pt diameter; 10–40 pt (Input's knob and range) | how easy the moon is to hold for an adult; a bigger region catches more stray child touches |
| `challenge_timeout_s` | 20 | 10–60 | how long an abandoned challenge keeps play frozen |
| `overlap_grace_s` | 0.15 | 0.05–0.25 | how much two-thumb overlap an adult gets on the keypad; longer lets a rolling palm enter digits |
| `key_size_pt`, `key_gap_pt` | 60, 12 | ≥ 44, ≥ 8 | adult accuracy; larger keys need a taller card |
| `panel_idle_s` | 60 (K-19) | 30–300 | how long an unattended panel stays open |
| `panel_max_s` | 300 | 120–900 | hard cap on one panel opening |
| `burst_count`, `burst_window_s` | 3, 1 | 3–5, 0.5–2 | which tapping counts as mashing for G10 |
| `confirm_hold_s` | 1.5 | 1.0–3.0 | how hard a destructive action is |
| `lock_notice_s` | 3 | 2–6 | how long "Child lock is OFF" shows |

All are build constants, not settings (nothing here is stored). The number of code words is **not** a
knob: it is fixed at 4 by K-20 (G3, AC-05); changing it is a Luan decision.

## UI Requirements

- The challenge card and the panel use the grown-up card shape, Dusk Blue controls, 15–22 pt regular.
- The moon is never highlighted, labelled on screen or animated to invite a touch; only the Starlight
  ring shows while it is held (art bible §3, §4).
- **The moon's look** (TASK-054 P1; Scene R1, merged in 09459f1): this is **the sky's only moon**; the
  Scene draws no moon disc. The gate draws it in `#e6d6a4` and takes the Scene's `look` and
  `lookBlend` (Scene F1): opacity **70% in Morning and Day** (a "daytime moon", art bible §2) and
  **100% at Dusk and Night**, crossfaded with the Scene's blend:
  `moonAlpha = (1 − w) · α(prev) + w · α(P)`, with `α(Morning) = α(Day) = 0.7`, `α(Dusk) = α(Night) = 1.0`
  and `(prev, P, w)` = `lookBlend`. Example: 16:07 (53% Day, 47% Dusk) → 0.7 · 0.533 + 1.0 · 0.467 ≈ 0.84.
  It follows the wall clock like the Scene, also under the challenge's freeze and the panel. The
  hit region (G1) and the Starlight ring (opacity 1) never change with the look.
- **Reduce Motion:** the ring still fills (it is progress, not decoration) and never pulses; the
  challenge and panel appear and leave without a fade or slide; the dim is instant; the confirm ring
  fills the same way.
- Colour never carries meaning alone: switches show On/Off text.
- Retained screenshots of the challenge, the panel (iPadOS and macOS), the confirm state and the
  notice are the UI evidence (coding standards: UI stories).

---

## Acceptance Criteria

All timers use an injected clock and the code an injected seed, so every criterion is deterministic.

1. **AC-01 · F1 hold:** GIVEN Idle, WHEN the moon is held 1.49 s THEN no challenge; WHEN held 1.50 s
   THEN the challenge opens. WHEN held 1.2 s, lifted and held again 0.5 s THEN no challenge (reset).
2. **AC-02 · second pointer on the moon:** GIVEN one pointer holding the moon at 1.0 s, WHEN a second
   pointer goes down on the moon THEN `t_held` is unchanged and the challenge opens at 1.5 s of the
   first; a second pointer elsewhere is classified by Input R7. WHEN the first lifts at 1.2 s while the
   second stays THEN the ring empties and the second does not take over.
3. **AC-03 · chord (game-qc-android AC-c):** GIVEN macOS, WHEN exactly ⌃⌥⌘Q go down THEN the challenge
   opens; WHEN ⌃⌥⌘Q go down with D also held THEN nothing opens. WHEN ⌃⌥⌘Q go down with Shift or Caps Lock on THEN the challenge opens. WHEN ⌃⌥⌘Q go down with Fn
   held THEN nothing opens (K-26). GIVEN iPadOS, ⌃⌥⌘Q → nothing.
4. **AC-04 · code (game-qc-android AC-a):** GIVEN seeded uniform random keypad taps, WHEN 200,000
   attempts are simulated THEN the number that pass lies in 7–33 (expected 20 = 200,000 × 10⁻⁴, ±3 σ; with the fixed seed the count is the same every run).
   AND for a fixed seed the code and its words are the same every run; 1,000 successive openings with one seed show between 932 and 971 distinct codes (±3 σ, σ ≈ 6.5) (expected ≈ 952 =
   10,000 × (1 − 0.9999^1000)).
5. **AC-05 · words, never numerals:** the challenge text matches `Enter (zero|one|…|nine)( · (zero|…|nine)){3}`
   and contains no digit character; no audio plays while the challenge shows.
6. **AC-06 · two pointers (game-qc-android AC-b):** GIVEN the challenge, WHEN a second keypad pointer goes
   down while one is held THEN wrong: the challenge closes and moon sleep starts.
7. **AC-07 · hardware digits:** GIVEN macOS and the challenge, WHEN 4, 1, 7, 2 are typed one at a time for
   "four · one · seven · two" THEN the panel opens; WHEN two digit keys go down together THEN wrong.
   WHEN a key held from before the opening is released and pressed again THEN it counts once, as a new
   down.
8. **AC-08 · first wrong digit:** GIVEN the code 4172, WHEN 4 then 2 are entered THEN the challenge closes
   at the 2 (no third digit is accepted).
9. **AC-09 · timeout:** GIVEN the challenge opened at t = 0 with no touch, THEN it is open at 19.9 s and
   closed at 20.0 s, with moon sleep. GIVEN a **right** first digit at 15 s, THEN it closes at 35.0 s.
   GIVEN a **wrong** first digit at 15 s, THEN it closes at 15 s (AC-08). GIVEN only touches outside
   the keypad at 5, 10 and 15 s, THEN it still closes at 20.0 s.
10. **AC-10 · moon sleep:** GIVEN a wrong answer at t = 0, WHEN the moon is held from 8.4 s to 9.9 s THEN no
    challenge (ring empty); WHEN a fresh hold runs from 10.0 s to 11.5 s THEN the challenge opens. The chord during sleep does nothing; the chord at 10.0 s opens the challenge.
    GIVEN Cancel (or Esc) at t = 0, WHEN a hold runs 0.5–2.0 s THEN the challenge opens (no sleep).
11. **AC-11 · closing touch consumed (game-qc-android AC-d):** GIVEN a wrong digit tapped over a spot where
    a hint is drawn, WHEN that touch moves and lifts THEN no press, sparkle or creature tap is emitted.
12. **AC-12 · lift before refill:** GIVEN a finger on the moon when the challenge closes, WHEN it stays
    down for 20 s THEN the ring never fills; after it lifts, a new 1.5 s hold (outside sleep) opens.
13. **AC-13 · freeze and resume (game-qc-android AC-e):** GIVEN the queue holds [B, C] and the reveal of
    A is at frame k, WHEN the challenge opens and 30 keys and touches arrive THEN the queue is still
    [B, C] and the reveal is at frame k; WHEN it closes as wrong or timeout THEN the reveal continues
    from frame k and B then C play. Hint `hintTime`, the parade walk and the parade tune are equally unchanged.
14. **AC-14 · correct code → K-15:** GIVEN the queue [B, C] and A mid-reveal, WHEN the correct code is
    entered THEN the panel shows, the queue is empty, A is formed, a running parade fades and counts as
    played; WHEN the panel closes and D is pressed THEN D's reveal starts at once.
15. **AC-15 · controls map to fields:** for each row in G7, changing the control produces exactly one
    Settings Store write of that field and one R10 notification (slider: one write on release, preview
    gains while dragging). Rows marked "once #15/#16 ships" and the theme row with one theme are absent. **Exception:**
    turning Child lock off produces one R10 notification and **no** write (G11).
16. **AC-16 · debug-only parade button:** the release build's panel has no "Play the parade now"; the debug
    build's does, and it starts a parade and closes the panel.
17. **AC-17 · destructive confirm:** GIVEN "Start over" tapped, WHEN the confirm button (on the opposite
    side) is held 1.49 s THEN nothing; held 1.50 s THEN Reset (one R9 notification). A second tap on
    "Start over" does nothing. The confirm hides after 5 s unused. The same holds for Quit and Child
    lock off.
18. **AC-18 · auto-close:** GIVEN the panel open and no input, THEN it closes at 60.0 s. GIVEN a control touched at 50 s, THEN it closes at 110 s; GIVEN only touches on the card's empty area,
    THEN it still closes at 60.0 s. GIVEN control touches at 50.0, 50.3 and 50.6 s, THEN the third does not reset
    the timer (closes at 110.3 s, from the second).
19. **AC-19 · child lock (macOS, K-21):** GIVEN the lock on, WHEN it is turned off (with the hold) and the
    panel closed THEN "Child lock is OFF" shows for 3 s; the stored `childLock` is still true; WHEN the app is relaunched THEN the lock engages once the
    app is ready. GIVEN the lock never turned on, relaunch → off.
20. **AC-20 · way out with the lock on:** GIVEN the kiosk on, WHEN ⌃⌥⌘Q, the code and Quit (held 1.5 s)
    THEN the app quits.
21. **AC-21 · nothing leaves the app:** with every panel row and the privacy page opened, no Safari, web
    view, store, share sheet or other app opens, and PKC-02's API scan finds none of those APIs.
22. **AC-22 · background:** GIVEN the challenge or the panel, WHEN the app goes to the background and
    returns THEN neither is shown, and no moon sleep is running.
23. **AC-23 · Reduce Motion:** with Reduce Motion on, the challenge and panel appear and leave with no
    fade (screen capture frame check), the dim is instant and the ring fills without a pulse.
24. **AC-24 · VoiceOver:** with VoiceOver on, a double-tap-and-hold on "Grown-ups" opens the challenge;
    focus lands on the code text, read as "Enter four, one, seven, two"; four double-taps on the right
    keys open the panel; on close, focus returns to the stage.
25. **AC-25 · Cancel and Esc:** GIVEN the challenge, WHEN Cancel is tapped (or Esc pressed) THEN it closes,
    play resumes from the frozen frame, and no sleep runs. GIVEN the panel, Esc and "Back to play" close
    it (G9).
26. **AC-26 · hold vs background and drift:** GIVEN a hold at 1.0 s, WHEN the app goes to the background
    THEN `t_held` = 0 on return. GIVEN a hold, WHEN the finger moves 15 pt outside the hit region and
    stays THEN the hold continues; WHEN it moves 25 pt outside THEN it resets.
27. **AC-27 · stale key and chord:** GIVEN the kiosk on and a key whose key-up the app missed (tracked as
    held but up in the OS key state), WHEN exactly ⌃⌥⌘Q go down THEN the challenge opens. GIVEN the
    challenge or panel showing, the chord does nothing. Evidence: Input AC-1k3 (stale key) and AC-1k6
    (real Mac, release-blocking for macOS, NOT ASSESSED until run).
28. **AC-28 · Quit row follows `kioskModeOn`:** GIVEN `kioskModeOn` on (Waiting, Locked or Suspended), the
    panel shows Quit; GIVEN it off (lock off, or after an engage timeout with the switch still ON), no Quit
    row, and ⌘Q quits.
29. **AC-29 · hard cap:** GIVEN the panel open and a control tapped every 50 s, THEN it closes at 300 s.
30. **AC-30 · no code in logs (PKC-14):** in a release build, the code scan finds no log call carrying
    the code, an entered digit or the words outside `#if DEBUG`.
31. **AC-31 · Title and chord:** GIVEN macOS on the Title screen, WHEN the chord, then Cancel THEN the
    Title screen shows again (not Play).
32. **AC-32 · Dynamic Type:** at the largest accessibility text size, the panel scrolls to every row and
    the keypad keys stay ≥ 60 pt with ≥ 12 pt gaps.
33. **AC-33 · write failure:** GIVEN the Settings Store write fails (test seam), WHEN Mute is switched on
    THEN the switch shows On, audio is muted for this run, and no error appears.
34. **AC-34 · in-window and lock (macOS):** GIVEN the lock on, WHEN the challenge, the panel, a confirm and
    the privacy page are opened THEN the main window stays key and the presentation options stay
    applied; ⌘Q in the open panel does nothing; Quit (held 1.5 s) removes the options before the app
    ends. GIVEN Child Lock-in's failure flag set, the next panel open shows "Child lock couldn't turn on".
35. **AC-35 · Guided Access line (iPadOS):** with `guidedAccessEnabled` true the lock row reads "Guided
    Access is on"; false → "Guided Access is off".
36. **AC-36 · overlap grace:** GIVEN the code 4172 and 4 entered, WHEN 1 goes down while the 4-pointer
    is still down and the 4-pointer lifts 0.10 s later THEN 1 is accepted; WHEN instead it lifts 0.5 s
    later THEN wrong at 0.15 s after the 1-down. WHEN three keypad pointers are down at once THEN wrong.
37. **AC-37 · sleep across background:** GIVEN a wrong answer at t = 0 and the app in the background
    from 2 s to 6 s, THEN a hold from 8.5 s to 10.0 s does not open, and a hold from 10.0 s to 11.5 s
    does.
38. **AC-38 · Android (NOT ASSESSED: no Android build, K-03):** Back closes the challenge as Cancel and
    closes the panel; no chord exists; the lock row shows screen-pinning text.

---

## Open Questions

| # | Question | Owner |
|---|---|---|
| Q1 | Does App Review accept this gate as an "adult-level task"? Not verified; Apple names no specific method | Luan, at first submission |
| Q2 | The number words for the Vietnamese voice release (K-02) | Localization (#19) |
| Q3 | Android: Back behaviour and screen-pinning wording | Android ADR |
| Q4 | ~~`t_tap` in F2~~ closed: with `t_tap` = 0 the maximum risk moves only from 3.0% to 3.1% per hour | — |
| Q6 | ~~Chord hold~~ closed: (a) accepted by the leader, F2 states ~3.4%/h. Was: the Mac chord's fastest-attempt risk is ~3.4%/h (F2), a little above K-21's ~3%. Accept, or require the chord to be held 1.5 s like the moon (→ ≈ 300/h, 2.96%)? | leader / Luan |
| Q5 | ~~Overlap grace~~ closed: game-qc-android chose a lift grace of 0.15 s (G3, AC-36) | — |
