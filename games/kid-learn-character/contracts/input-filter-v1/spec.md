# input-filter-v1

**Owner GDD:** `design/gdd/input-key-filter.md`. **Layer:** KidCore. **ADR:** ADR-0004 (D1, D4), ADR-0002 (D3, D5,
D6).
**Cases:** hand-written by game-qc-android (TASK-081), reviewed by game-dev-ios (the GDD's author).

## What it covers

- **R2** key resolution: the character fold (`a` → A); the position fallback (AZERTY digit row, Cyrillic); accents
  not stripped; non-keys resolve to nothing.
- **R3** modifiers: Ctrl, Alt and Fn always swallow. ⌘ swallows on iPadOS and follows R5 on macOS. Shift, Caps Lock
  and Num Lock are ignored.
- **R4** the held set: repeats and second downs ignored; clears on cancel, focus loss, panel open/close and
  Inactive; an up for an unheld key; distinct `physicalId`s.
- **R5** ⌘ and the one signal `kioskModeOn`: swallowed in every state while the mode is on, passed on while it's
  off (including after the engage timeout). The ⌘ exception is macOS-only: on iPadOS a ⌘-combination is swallowed
  (IF-Q11).
- **R6** the Mac chord:
  - exact ⌃⌥⌘Q, with Shift and Caps ignored and Fn disqualifying;
  - blocked by a held key;
  - the OS key-state read (`KeyStateQuery`) both present and absent;
  - **⌘ release empties the held set** (IF-Q9), in both orders of AC-1k3;
  - where it works: Title and Play, ignored in the challenge and the panel.
- **R7** touch layers: hint (hit radius boundaries, fading, off stage, over the moon, nearest centre), row key, moon
  (`gateTouch` began/ended, cancel, the slop in points), cast member, sparkle; moves and lifts classify nothing;
  multi-touch delivered one pointer at a time.
- **R8** delivery order with each event's own stamp; nothing dropped; `origin` nil for a hardware key.
- **States:**
  - Title (`startPlay`, the held set kept into Play, touches go to App Shell except the moon);
  - Gate challenge (`gateDigit`, `gateCancel`, everything else swallowed, touches emit nothing);
  - Panel open (Input emits nothing; non-⌘ keys pass to the panel);
  - Inactive.
- **F1** hit radius (75 at the provisional scale); **F2** re-press gap, including the boundary.
- **AC-1a–l, n–s; AC-2; AC-3a–f; AC-8** (the sparkle).

**Not covered here, and why:**
- **Hardware system keys and AC-1m:** they never become a `KeyEvent` (IF-Q2). AC-1m is tested in the **adapter
  suites** (the iOS, macOS and Android adapter tests), with device checks P-4 and M-3 as the on-hardware confirmation.
- **The numpad and Esc mappings:** the adapters give a keypad key `character` nil plus its digit `positionKey`
  (IF-Q1), and Esc `character` "\u001b" (IF-Q8). Those mappings are tested in the adapter suites; KidCore's cases
  start from the adapter's output.
- **The iPad touch-batch sort:** done by the adapter in window px (IF-Q10). KidCore receives touches one at a time.
- **AC-1k6** (the TCC prompt): device check M-1. **AC-4** is a property of every press here. **AC-5–7:**
  integration and device.
- **Pixel → stage conversion:** reveal-timing-v1 (Reveal Stage F1). Cases use a 1280 × 720 px window with no
  insets, so stage units equal px. Only `pxPerPt` varies, for the slop in points.
- **What the Parent Gate does with `openPanel` during its moon sleep:** gate-logic-v1 (Input still emits it).

## `given` fields

- `platform`: `"iPadOS"`, `"macOS"` or `"android"`.
- `state`: `Title`, `Play`, `GateChallenge`, `PanelOpen` or `Inactive`.
- `kioskModeOn`: the R5 signal at the start.
- `displayMetrics`: ADR-0002 D6.
- `keyState`: optional. Absent means no `KeyStateQuery`. Present, it's the list of non-modifier `physicalId`s the OS
  reports down, used by R6.
- `knobs`: `repress_min_s` (default 0); the hint hit scale is 1.25 (provisional).
- `regions`: the published hit regions in stage units:
  - `hints [{id, key, centre, drawRadius, onStage, opacity?}]` (`opacity` is not an input to the hit test);
  - `rowKeys [{key, rect: [x, y, w, h]}]`;
  - `moon {centre, radius}`;
  - `cast {centre, radius} | null`.

## Events

| Event | Fields |
|---|---|
| `key` | ADR-0002 D5 `KeyEvent`: `kind` (`down`, `up`, `cancel`, `modifiersChanged`), `character` (string or null), `positionKey` (`A`–`Z`, `0`–`9` or null), `modifiers` (names: `shift`, `caps`, `ctrl`, `alt`, `cmd`, `fn`, `numLock`; the harness maps them to D5's bitmask), `isRepeat`, `physicalId`, and `stampLag`? (the event's stamp is `t.uptime − stampLag`, the one way to state an out-of-order stamp) |
| `touch` | ADR-0002 D5 `TouchEvent`: `pointerId`, `phase` (`began`, `moved`, `ended`, `cancelled`), `xPx`, `yPx` |
| `setState` | `value`: the owner (App Shell, Parent Gate) switches Input's state. The held set clears on entering or leaving `GateChallenge`, `PanelOpen` and `Inactive`; it is **kept from Title into Play** |
| `windowKeyLost`, `windowKeyGained` | focus loss clears the held set |
| `kioskModeOnSet`, `kioskModeOnCleared` | Child Lock-in sets or clears the R5 signal |

## Outputs

Each step's outputs are compared in order.

| `out` | Fields | Notes |
|---|---|---|
| `press` | `key`, `source` (`hardwareKey`, `hint(<id>)`, `keyboardRow`), `origin` (stage point or null), `time` | R8 |
| `startPlay` | — | Title |
| `openPanel` | — | the chord |
| `gateDigit` | `digit`, `anotherKeyHeld` | Gate challenge (R8). `anotherKeyHeld` is true only when another held key **resolved to 0–9** (Space held plus 4 is false) |
| `gateCancel` | — | Esc in the Gate challenge (IF-Q8) |
| `gateTouch` | `phase` (`began`, `ended`), `pointerId` | the moon; `ended` once per pointer |
| `creatureTap` | `point` | |
| `sparkle` | `point` | |
| `disposition` | `value`: `consume` (not passed on) or `pass` (to the system, the menus or the panel's responders) | **always last**, once for every key `down`; ups, cancels and `modifiersChanged` have none |

**State (`expectState`):** `heldSet` (the `physicalId`s, compared as a set).
**Field kinds:** `time` is `time` (1e-9); `origin` and `point` are `geometry` (1e-6).

## Answers from the GDD author (IF-Q1–Q11, game-dev-ios; written into input-key-filter.md by TASK-083 @ 915a9331)

- **Q1:** a numpad key has `character` nil and `positionKey` = its digit; Num Lock is only a modifier bit (adapter
  rule).
- **Q2:** hardware system keys are adapter-only.
- **Q3 → Q9:** **⌘ release empties the held set**, whatever went down when. This is safe because a key still
  physically down gives only repeats or its up. AC-1k3 holds as written.
- **Q4:** `gateDigit(digit, anotherKeyHeld)`, resolved by R2, with R3/R4 applying.
- **Q5:** Panel open: Input emits nothing. A non-⌘ key passes; ⌘ follows R5.
- **Q6:** after `gateTouch(ended)` there's no new `began` for that pointer.
- **Q7 / Q10:** the adapter sorts a batch; KidCore keeps delivery order.
- **Q8:** Esc is `character` "\u001b". With Ctrl, Alt or Fn it's swallowed; Shift+Esc cancels; a repeat or a held
  Esc does nothing. In the Gate challenge a non-digit, non-Esc key is swallowed.
- **Q11 (corrected):** on iPadOS every ⌘-combination, ⌃⌥⌘Q included, is swallowed. The ⌘ exception is macOS
  with the kiosk mode off only. Ctrl, Alt and Fn are swallowed everywhere.

The cases follow the merged GDD text, and sources.lock is cut on it.
