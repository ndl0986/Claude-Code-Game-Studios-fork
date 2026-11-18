# UX Spec: Title Screen

> **Status**: In Design
> **Author**: game-dev-android (TASK-112), from App Shell & Title (`design/gdd/app-shell-title.md`) and K-39
> **Last Updated**: 2026-11-18
> **Journey Phase(s)**: first contact at every cold launch, and every return after more than 30 min away (App Shell R6, F3); no journey map exists yet (Open Questions)
> **Platform Target**: iPadOS 26+ (touch, optional hardware keyboard; any orientation and window shape, K-39) and macOS 26+ (keyboard, mouse or trackpad; resizable window, min 960 × 540 pt); Android NOT ASSESSED
> **Template**: UX Spec

> **Source rule.** Every behaviour here is App Shell's or another GDD's, cited; this spec adds no rule. Anything the
> GDDs leave open is in Open Questions.

---

## Purpose & Player Need

The Title is "a door left ajar" (art bible §2, Title state, energy 2): the screen a child meets when the toy opens,
already in the colour of the hour, with a creature breathing on the hill and one warm play button. Its job is to be
**ready**: anything the child presses or taps (except the moon) starts the toy, and nothing has to be read or found
(App Shell Player Fantasy, R2, R3). For the grown-up it is the proof the app is safe: it opens fast, with no ad,
prompt, link or login (App Shell R1; PKC-01, 02, 05).

---

## Player Context on Arrival

- **The child** (2.5–3, cannot read) arrives at a cold launch, or after more than `title_after_s` (30 min) away,
  counted on the continuous clock so device sleep counts (App Shell R6, F3, K-22). They may already be pressing
  keys; presses before the first frame do nothing (App Shell Edge Cases).
- **The grown-up** has just opened the app, or the panel was closed from a gate that was opened on the Title
  (App Shell R5).
- **The look** already matches the time of day and the weather from the very first frame (App Shell R1 step 4; art
  bible §2). Silent until the first input (Audio R6).

---

## Navigation Position

```
Launch screen (#46558f) ──▶ TITLE ──start──▶ Play ──(> 30 min away)──▶ TITLE
                              │                ▲
                              └─moon / chord──▶ Gate ──correct──▶ Panel
                                    (Cancel, Esc, wrong, timeout, close → back to the Title)
```
The Title is the root state after launch (App Shell States). It is not reached by a menu: only by launching or by
F3 on a return.

---

## Entry & Exit Points

| Entry | From | Rule |
|---|---|---|
| Cold launch | the OS (launch screen `#46558f`) | App Shell R1 steps 1–4 |
| Return after > 30 min | Background (from Play) | App Shell R6, F3 |
| Return from Background | Background (from the Title, or a gate / panel opened from the Title) | App Shell R6 (AS-Q6): always the Title; a pending start is dropped |
| Gate or panel closed | Gate / Panel opened from the Title | App Shell R5; Parent Gate G9 |

| Exit | To | Trigger |
|---|---|---|
| Play | Play (empty stage) | a start (P3) once the theme is ready (App Shell R3, R4) |
| Gate | the number challenge | the moon hold (P4) or, on the Mac, ⌃⌥⌘Q (Parent Gate G1, G2) |
| Background | Background | the app leaves the foreground (App Shell R6) |

---

## Layout Specification

### ASCII Wireframe

Landscape, on the 1280 × 720 safe stage (stage units), fitted by contain-and-extend (Reveal Stage R10). Portrait or a
narrow window shows the same safe stage with more sky above and more ground below; never letterbox bars (App Shell
R7, K-39, K-20).

```
┌─────────────────────────────────────────────────────────────────┐  ← extra sky (portrait / narrow window)
│ ☾ moon (66,62)                                                  │
│                                                                 │
│                    sky: time of day + weather                   │
│                       (Scene backdrop)                          │
│                                                                 │
│                                                                 │
│                                                                 │
│                          ( ▶ )  play button (640,520)           │
│              🦖  title creature, feet on the ground line        │
│        ~~~~~~~~~~~~~~ hill / ground line (y 558) ~~~~~~~~~~~~~~  │
│                         ground                                  │
└─────────────────────────────────────────────────────────────────┘  ← extra ground (portrait / narrow window)
   no text anywhere · no status bar / home indicator (iPad) · no keyboard row · no hints
```

### Layout Zones

| Zone | Content | Source |
|---|---|---|
| Backdrop (full window) | the Scene for the time of day and weather, extended past the safe stage | App Shell R2; Scene; Reveal Stage R10 |
| Moon (top left) | the Parent Gate's moon at (66, 62), radius 50 | Parent Gate G1; Hint Letters R5 (values used until Parent Gate publishes its circle) |
| Centre | the play button at (640, 520) | App Shell R2, Tuning Knobs |
| Ground line | the title creature at the `stage` role | App Shell R2; Cast Rendering; Key Table `titleCastId` |

### Component Inventory

| Component | Owner | Interactive | Notes |
|---|---|---|---|
| Scene backdrop | Scene: Time of Day & Weather | no | first frame already in the right look |
| Title creature | Cast Rendering (`stage` role) | a tap on it is a start (any tap except the moon, App Shell R3) | the theme's `titleCastId` (Dinosaurs: the T-Rex, K-22); idles as in Play (Cast Rendering R7) |
| Play button | App Shell | not a separate target: any tap starts (App Shell R3; Accessibility A7) | the one icon (art bible §7); light gathers on it: gold glow at dusk and night, its amber outline in morning and day |
| Moon | Parent Gate | the moon hold / VoiceOver element (P4) | Input layer 3 |

### Information Hierarchy

1. **The play button**: the single cue that something can start (the one icon, art bible §7), breathing gently.
2. **The title creature**: company, not a control.
3. **The sky**: the hour and weather.
4. **The moon**: for grown-ups only, no label.

---

## States & Variants

| State / variant | What differs | Source |
|---|---|---|
| Waiting (silent) | everything idles; no sound | App Shell R2; Audio R6 |
| Starting, theme ready | E5 chime, the play button lights fully, Play is entered | App Shell R3, R4 |
| Starting, theme still loading | E5 and the lit button at once; one pending start; Play when the theme is ready; extra starts absorbed | App Shell R3, AC-7 |
| Theme failed at launch | Dinosaurs in memory; its title creature shows | App Shell Edge Cases; Key Table §5 |
| Time of day | Morning, Day, Dusk, Night looks; the play button's light per state | art bible §2; App Shell AC-2 |
| Reduce Motion on | breathe amplitude halves (±2%); the creature's idle softens | App Shell R2, F2; Cast Rendering R7 |
| Orientation / window shape (iPad) | more sky and ground; layout in stage units unchanged | App Shell R7; K-39 |
| Mac window | resizable, min 960 × 540 pt; full screen or kiosk fill | App Shell R7 |
| Mac, lock stored on | the kiosk engages once the app is ready | App Shell R1 step 5; K-21 |

---

## Interaction Map

| Input | Where | Result | Source |
|---|---|---|---|
| Letter or digit key | anywhere | a start (P3); not reveal 1 | App Shell R3; Input Title state |
| Other key (Space, Esc, …) | — | nothing (system keys pass) | App Shell R3, AC-5; Input R5 |
| Tap / click | anywhere but the moon | a start (P3) | App Shell R3 |
| Touch-and-hold | the moon | the Parent Gate hold (P4) | App Shell R3; Parent Gate G1 |
| ⌃⌥⌘Q (Mac) | — | opens the gate challenge | Parent Gate G2; Input R6 |
| A start while in any other state | — | ignored (guard) | App Shell R3 (AS-Q2) |

---

## Data Requirements

| Data | From | Used for |
|---|---|---|
| time of day and weather look | Scene (and Settings Store `weather`, `windy`) | the backdrop and the play button's light |
| `titleCastId` | Key Table & Theme Data (active theme) | the title creature |
| "theme ready" | Key Table & Theme Data | when a start may enter Play |
| `reduceMotion` | Accessibility A1 | breathe amplitude |
| window size, safe-area insets | the platform → App Shell → Reveal Stage | the stage fit (contain-and-extend) |
| `gateOverlayShown` | Parent Gate (G13) | edge-gesture deferral off while the gate shows |

---

## Events Fired

| Event | When | Consumer | Source |
|---|---|---|---|
| `startPlay` | a letter / digit key on the Title | App Shell | Input Title state |
| E5 title chime | on a start | Audio & Voice | App Shell R3; Audio E5 |
| enter Play (in order: Input, Press Queue, Reveal Stage, Hint Letters) | the theme is ready after a start | those systems | App Shell R4 |
| `edgeDeferral {on}` | the Title's first frame; then on a change | the iPad adapter | App Shell R7 (TASK-095) |
| `statusBarHidden {true}` | once, at the first frame (iPadOS) | the iPad adapter | App Shell R7 |
| "the app is ready" (Mac) | first frame + chord handler + window covering its display | Child Lock-in | App Shell R1 step 5 |

---

## Transitions & Animations

- **Into the Title:** the first frame is already the right look; there is no intro animation (App Shell R1 step 4;
  art bible §2).
- **Play button breathe:** `scale(t) = 1 + k · 0.04 · sin(2π · 0.38 · t)`, k = 0.5 with Reduce Motion (App Shell
  F2); ≤ 1 Hz (Accessibility A4).
- **On a start:** the play button lights fully with the E5 chime (App Shell R3).
- **Title → Play:** Play opens on an empty stage; the keyboard row, if on, fades in over 0.3 s (Keyboard Row R7);
  fresh hints appear at 0 / 0.7 / 1.4 s (Hint Letters R6). The visual handover of the Title itself (the play
  button and title creature leaving) is not stated (Open Questions).

---

## Input Method Completeness Checklist

- [x] **Touch (iPad):** any tap except the moon starts (App Shell R3); the moon hold opens the gate (P4).
- [x] **Hardware keyboard (iPad and Mac):** any letter or digit starts; other keys do nothing (App Shell R3).
- [x] **Mouse / trackpad (Mac):** a click anywhere but the moon starts; click-and-hold on the moon opens the gate
  (Input R1: every mouse button is a touch).
- [x] **Mac grown-up shortcut:** ⌃⌥⌘Q (Parent Gate G2).
- [ ] **Gamepad:** not supported (not in ADR-0001's inputs).
- [ ] **Android:** NOT ASSESSED (its ADR).

---

## Accessibility

Against `design/accessibility-requirements.md` (tier: Standard, Luan, K-42):
- **No text** on the Title (App Shell R2; K-22), so nothing needs text sizing or captions.
- **Reduce Motion:** breathe amplitude halves; the creature's idle softens (A3); applied on the next frame (A2).
- **Motor:** no touch floor needed for the play button (any tap starts, A7); the moon is ≥ 44 pt with 20 pt slop
  (A7; Parent Gate G1).
- **VoiceOver:** the moon is one element, "Grown-ups", "Double-tap and hold to open settings" (A8). The rest of the
  child's stage is not designed for VoiceOver; its behaviour there is NOT ASSESSED (Accessibility Q4).
- **Colour:** the play button's light is not the only cue (it is the one icon, and any tap starts); the moon ring's
  length and hold time carry its progress (A6).
- **Smart Invert:** the stage opts out (A10; K-30).
- **Photosensitivity:** the Title's motion is the 0.38 Hz breathe and ≤ 1 Hz idles (A4 pulses table).
- **Silent mode:** respected; the Title is silent until a start (Audio R6).

---

## Localization Considerations

- **None on the child's side:** the Title has no text (App Shell R2). The voice locale does not appear on the Title
  (the E5 chime is not speech).
- **The moon's VoiceOver label and hint** ("Grown-ups", "Double-tap and hold to open settings") are the only
  strings reachable from the Title; they are the Parent Gate's to localize (Localization system, post-MVP).

---

## Acceptance Criteria

- [ ] At 06:30, 12:00, 17:00 and 21:00 (injected clock) the first frame is the matching look, with no text on screen (screenshots; App Shell AC-2).
- [ ] D, 7 and a tap at (200, 200) each start play; Space, Esc and a tap on the moon do not (App Shell AC-5).
- [ ] After a start by D, the Press Queue has no current and an empty queue; D's repeat and up make no press; the next D down is reveal 1 (App Shell AC-6).
- [ ] With the theme load delayed by 2 s, a start at 0.1 s plays E5 at once and enters Play exactly once at 2.0 s; starts at 0.5 s and 1.0 s change nothing (App Shell AC-7).
- [ ] Away 31 min returns to the Title; a simulated 8 h sleep returns to the Title (App Shell AC-8).
- [ ] iPad full screen in both landscape and both portrait directions, Split View and Stage Manager; Mac at the minimum window, full screen and with the kiosk: the safe stage is whole, portrait shows more sky and ground, no letterbox bars (screenshots; App Shell AC-10).
- [ ] On the Title the status bar and home indicator are not shown (screenshot); a single edge swipe leaves the app in front (device, NOT ASSESSED until run; App Shell AC-14).
- [ ] With Reduce Motion on, the play button's scale at a quarter period is 1.02 (1.04 off) (App Shell F2).
- [ ] VoiceOver focuses the moon as one element reading "Grown-ups" with its hint (Parent Gate AC-24).

---

## Open Questions

| # | Question | Owner |
|---|---|---|
| OQ-1 | The title creature's exact position on the ground line (App Shell R2 says "anchored on the ground line"; Reveal Stage R10 gives the Play anchor (640, 600) and the ground line y 558). It **stands on** the line (feet anchor, art bible §8) and, per game-art-content's review, should stay **out of the play button's column at x 640**; the x value is the owner's | App Shell owner |
| OQ-2 | The Title → Play handover: do the play button and title creature fade, and over how long? | App Shell owner / art |
| OQ-3 | ~~The play button's size and drawing (only its position, light and breathe are stated)~~ **Closed (TASK-117):** art bible §7 "Play button": 140 × 92 units, radius 40, Letter Gold with a cream triangle, the light per look | art (art bible §7) |
| OQ-4 | The moon ring's geometry on the Title (see `interaction-patterns.md` OQ-1) | Parent Gate owner / art |
| OQ-5 | Player journey map not yet created (`design/player-journey.md`); author it from `.claude/docs/templates/player-journey.md` | producer / UX |
