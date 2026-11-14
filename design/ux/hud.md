# HUD Design: Mission

> **Status**: In Review · Task: TASK-021 · Author: game-art-content
> **Template**: HUD Design
> **Platform Target**: Android + iOS phones, landscape, touch only (`project.yaml` goal mobile; no gamepad or keyboard). Accessibility tier: Basic+ (`design/accessibility-requirements.md`).
> **Records what's built.** Sources: Input & touch GDD Rules 1–17; Mission flow Rules 4, 7, 7b,
> 7c, 11; Combat V/A; Hints Rules 2–6; `design/accessibility-requirements.md`; QC TASK-003 r3
> (O5, O6) and TASK-006 iOS r2 (the "Ối!" placement).

## 1. HUD Philosophy

A 6-year-old sees only what the current beat needs. The pads are big and safe, everything else
is small and out of the way, and **nothing on the HUD is a number to manage**: no health, no
score, no timer. The story is the screen; the HUD frames it.

## 2. Information Architecture

| Information | Shown | Why |
|---|---|---|
| The beat's pads | Always in play (only the beat's `buttons`) | Mission flow Rule 4 |
| Goal line | During play, under the progress dots | Mission flow Rule 2 |
| Banner motto bar | Beats with `uses_banner` (training, reach-the-flag), the whole beat, **in the sky band under the goal line** in every language (§3.3) | Mission flow Rule 6; TASK-020 W9 |
| Beat progress dots | During play | Where the child is in the story |
| Pause, sound | Always | Input Rule 3 |
| Hold-meter ring | Hold-meter beats, around the special pad | Mission flow UI |
| Training checklist | Training beats (3 icons) | Mission flow UI |
| Text pops ("Ối!", "Đỡ được!", hit pops) | On the event, **beside the fighter's head at head height**, never above it (§3.3) | Combat V/A |
| Hints (hand, pulse, arrow) | When triggered | Hints GDD |
| **Never shown:** health, score, timers, enemy health, language chip in play | — | pillars; P-04 |

## 3. Layout Zones

### 3.1 Zone Diagram (landscape, the world fitted at k, HUD anchored to the safe rect)

```
┌──────────────────────────────────────────────────────────────────┐
│ [⏸][🔊]          ● ● ○ ○  (beat dots)                             │  ← top safe edge
│                  "Đẩy lùi quân giặc!" (goal line)                 │
│        ┌──── banner motto bar (uses_banner beats only) ────┐     │  ← sky band, 2-line height
│        │  Phá cường địch, báo hoàng ân                      │     │
│        └────────────────────────────────────────────────────┘     │
│                                                                  │
│                   (play area: hero, enemies,                     │
│                    telegraph "!", pops beside the head)          │
│                                                                  │
│                                              [🚩 flag]           │  ← hold-meter / training only
│  [ ◀ ][ ▶ ]                           [🛡 defend][🗡 attack]      │  ← bottom safe edge
└──────────────────────────────────────────────────────────────────┘     (above gesture insets)
```

### 3.2 Zone Specification Table

| Zone | Anchor | Contents |
|---|---|---|
| Top-left | Safe rect top-left | Pause, sound (≥ 72 pt each) |
| Top stack | **Centred in the free band x 330–1250 (centre x 790)**, right of the pause/sound block | Progress dots; the goal plate below them (`goal` field, box 880, 37 px body); on `uses_banner` beats, the banner motto bar below the goal plate (§3.3) |
| Bottom-left | Safe rect bottom-left, above the gesture inset | ◀ ▶ (`pad_gap` apart) |
| Bottom-right | Safe rect bottom-right, above the gesture inset | Defend, attack; flag above attack when present |
| Play area | The 1280×720 world | Characters, telegraph, pops |

### 3.3 The top stack and the banner motto bar (TASK-020 W9)

The banner motto (the mission's `banner` Text, `banner` field: box 880, **37 px**, weight 800,
≤ 2 lines) is drawn on a **vermilion bar in the sky band**, above the fighters' heads and below
the goal line, in **every** language. It never grows up from the ground line, where 2 EN lines
covered the fighters' legs (Android r5 evidence, `production/qa/evidence/TASK-007/android/r5-banner/`
on the Android branch @ 5d58123).

**Horizontal: the free band.** Pause and sound are ≥ `pad_min` (Input Rule 4), which is 137
world px on the Android reference phone (k 0.527, Input F1), so the top-left block covers about
x 18–315, y 18–155. A stack centred on x = 640 would collide with it. **The whole top stack
(dots, goal plate, banner bar) is centred in the free band x 330–1250, centre x 790**, on every
beat. The goal plate and the banner bar are both **920 wide** (an 880 text box plus 20 each
side), which fills the band exactly. The `goal` field's `box_width` drops **1040 → 880** in
`rules.json` (data follow-up); every TQT goal still fits on 1 line at 880 (widest: EN "Get to
the king's meeting at Bình Than!", 688 px).

**Vertical stack** (world px from the top of the 1280×720 world; drawn at `k_px`, Input F1):

| Element | Top | Height | Bottom | Rule |
|---|---|---|---|---|
| Progress dots row | (as built) | — | ≈ 92 | unchanged |
| Goal plate | dots bottom + 4 (≈ 96) | 56 (one 37 px line at 1.35 line height, plus padding); 920 wide | ≈ 152 | **moves up on every beat** so the stack is the same on every beat; today it sits at ≈ 169–225 |
| Banner bar | goal bottom + 4 (≈ 156) | **112, fixed** (two 37 px lines at 1.35 = 100, plus 6 padding top and bottom), whether the text is 1 line (VI) or 2 (EN) | ≈ 268 | text centred both ways |
| Fighters' tops | — | — | ≥ banner bottom + 8 | see below |

- **Width:** 920 (the 880 text box plus 20 each side), centred on x = 790 (the free band).
- **Clearance rule:** the banner bar's bottom stays ≥ 8 px above the highest point of every
  body: the hero, every enemy, the training partner and the straw dummies. With art at spec size (hero 180 world px tall, enemies ≤ 170, feet on
  `ground_y` 470; `side-scroll-combat-assets.md`), the highest head is at y ≈ 290 and the bar
  ends at ≈ 268: 22 px clear.
- **Placeholder rule: every placeholder is drawn at spec height**, with feet on `ground_y` 470:
  **hero ≤ 180** world px; **enemies ≤ 170**; **training partner ≤ 180** (a hero-style figure;
  spec ≈ 160); **straw dummy ≤ 170** (a body, not a prop; spec ≈ 130). Today's placeholders are
  taller (r5: hero ≈ 245, iOS dummy 206), and AC9 depends on this rule. Scaling is render-only on
  both apps: the simulation has no y, so no trace or timing changes.
- **Weapons keep their world length when bodies are scaled** (Combat V/A;
  `side-scroll-combat-assets.md`): the enemy's weapon tip reaches `enemy_reach − stand_gap` =
  **140** world px in front of it, and the hero's swing arc reaches `attack_range` = **175**, so
  a strike that lands looks like it lands. Only bodies shrink to spec height.
- **Only weapons, the pennant and the banner pole may pass behind the bar** (a raised staff, a
  spear tip, the training-finish banner pole). Bodies, heads and faces never do.
- **Z-order** (bottom to top): play layers (background, fighters, props) → **banner bar** →
  pops → hints, the telegraph "!" bubble and the hurt swirl (ASSET-212) → HUD buttons. The "!"
  sits above an enemy's head and can reach the bar's band, so it draws over the bar and always
  stays visible (Combat V/A).
- **Pops** ("Ối!", "Đỡ được!", hit pops) sit **beside the fighter's head, at head height**, on
  the side away from the other fighter, never above the head. With bodies at spec height, the
  highest head is at y ≈ 290, so a pop never reaches the bar's band (≤ 268). Both apps follow
  this (iOS does it today).
- **Colour:** vermilion `#D64A2E` with gold text `#FFC531` and an ink-brown outline on the bar,
  as built; one motif at most (Luan's rule 4).
- **When:** the whole of every `uses_banner` beat, from `beat_play` start. It hides on story
  screens, in the dialogue and on pause (pause shows the dimmed backdrop as usual).

Anchoring follows Input Rule 2: the true safe rect, with Android's **mandatory** gesture insets and
iOS's home-indicator inset (QC r3 O5: pad bottoms clear of the gesture zone).

## 4. HUD Element Specifications

| Element | Size | Asset | Behaviour |
|---|---|---|---|
| ◀ ▶ | ≥ 72 pt, gap 12 pt | ASSET-024 | Fire on press; the ◀↔▶ slide; drift forgiven (Input Rules 7, 9) |
| Attack | ≥ 72 pt | ASSET-025 (tangerine, staff icon) | Press starts a swing (auto-face, combat Rule 2) |
| Defend | ≥ 72 pt | ASSET-026 (shield, one drum-ring accent) | Held = shield up |
| Special | ≥ 72 pt | ASSET-027 + the meter ring ASSET-028 (ASSET-326 pulse); icon per beat type: **fist** (ASSET-335) on hold-meter, **banner** on training | Hold-meter: hold; training finish: press (Mission flow Rule 7c) |
| Pause, sound | ≥ 72 pt | ASSET-029–030 | Release-inside (P-01) |
| Progress dots | ~24 px each | ASSET-032 | Filled when the beat is done |
| Goal line | `goal` field (box **880**, 37 px) on a 920-wide cream plate | text layer, top at dots bottom + 4, centred on x 790 (§3.3) | Hidden on dialogue beats (no goal) |
| Banner motto bar | 920 × 112 world px, fixed, centred on x 790 (§3.3) | vermilion bar + `banner` text layer (37 px, ≤ 2 lines) | `uses_banner` beats only; never overlaps a body |
| Pops | label size | text layer | **Beside the fighter's head at head height**, away from the other fighter; never above the head, never in the top stack (§3.3; iOS r2: "Ối!" kept clear of pause and sound) |

## 5. HUD States by Gameplay Context

| Context | Pads shown | Other |
|---|---|---|
| `walk_to` | ◀ ▶ only | Dots, goal hidden |
| walk beat | ◀ ▶ | Goal |
| hold-meter | special, fist icon (with ring) | Goal; the hold hand on first view |
| training | **per step** (Mission flow Rule 7c): dummies ◀ ▶ + attack; blocks + defend; finish + special (banner icon). *Today both apps show all four from the start; a dev ticket (TASK-020 W12)* | Checklist icons; hints in step order (B3); **camera capped** at `xStart − hero_edge_margin` until `beat_end` (Combat Rule 15b) |
| fight / encounter | ◀ ▶, attack, defend | Telegraph |
| reach-the-flag (no encounter) | ◀ ▶ (attack, defend if listed) | Flag goal |
| story, dialogue screens | **none** | Pause and sound, top-left (Input Rule 3). A pad held when the screen opened gives no input and is not released (Input Rule 14) |
| paused | none (the pause menu) | All pads released (Input Rule 11) |

## 6. Information Hierarchy

| Element | Tier |
|---|---|
| Play area (hero, telegraph) | MUST KEEP |
| The beat's pads | MUST KEEP |
| Pause | MUST KEEP |
| Goal line | SHOULD KEEP (hidden on dialogue beats) |
| Progress dots, sound | SHOULD KEEP |
| Hints | CAN HIDE (only when triggered) |
| Health, score, timers, language chip in play | ALWAYS HIDE (don't exist) |

## 7. Visual Budget

At most 5 pads plus pause and sound (7 controls); one hint at a time (Hints Rule 3); no more than
2 pops at once. Controls cover ≤ 25% of the screen: the bottom corners and a thin top row; the
centre is never covered. The top stack (dots, goal, and on banner beats the motto bar) ends at
y ≈ 268, above every fighter (§3.3).

### Tuning Knobs

| Knob | Value | Source |
|---|---|---|
| `pad_min` | 72 pt | `tuning.json` |
| `pad_gap` | 12 pt | `tuning.json` (data follow-up). *NOT YET READ: iOS, Android (iOS spaces pads 10 world units; Android uses fixed offsets with no gap; the key arrives with TASK-005k)* |
| `hint_delay` | 5 s | `tuning.json` |

There are no player-adjustable HUD settings in the slice (HUD repositioning is out of scope,
accessibility requirements).

## 8. Feedback & Notification Systems

- Every pad: a 4% squash in the next frame. *NOT YET BUILT: iOS, Android (iOS changes colour only;
  Android only shows 50% alpha on disabled buttons and wrong cards)* (accessibility gaps).
- Play pads: no tap tone; their actions make the sounds (O6).
- Pops: "Ối!" (pushed) and "Đỡ được!" (blocked) as VI/EN text layers.

## 9. Platform Adaptation

The same layout on both platforms (P-04). Only the insets differ: Android mandatory gesture
insets; iOS home indicator, notch or Dynamic Island. Rounded corners wait for TASK-013.

## 10. Accessibility

- 10.1 **Colour-blind:** each pad has a distinct shape plus icon; the telegraph is shape plus sound
  (accessibility requirements, colour audit).
- 10.2 **Text scaling:** fixed validated sizes (R8c); labels ≥ 28, the goal ≥ 37.
- 10.3 **Motion:** no screen shake; pulses ≤ 3 Hz.

## Acceptance Criteria

1. **GIVEN** each beat type, **WHEN** in play, **THEN** exactly the pads in section 5 are visible.
2. **GIVEN** a 20:9 Android phone in full screen, **WHEN** captured, **THEN** every pad is above the
   gesture zone and inside the safe rect (O5). The same holds on a Dynamic Island iPhone, both ways.
3. **GIVEN** a push, **WHEN** "Ối!" pops, **THEN** it doesn't overlap pause or sound.
4. **GIVEN** a dialogue beat, **WHEN** shown, **THEN** no pads and no goal line show.
5. **GIVEN** the lowest target Android phone, **WHEN** a pad is pressed, **THEN** its action starts in the next frame (combat AC12).
6. **GIVEN** the narrowest supported phone, **WHEN** captured, **THEN** the pads keep ≥ 12 pt gaps and never overlap the goal line.
7. **GIVEN** the training beat, **WHEN** each step is current, **THEN** only that step's pads show (dummies: ◀ ▶ + attack; blocks: + defend; finish: + special with the banner icon).
8. **GIVEN** the hold-meter beat, **WHEN** captured, **THEN** the special pad shows the fist icon, not the banner.
9. **GIVEN** the training and reach-the-flag beats at k = 1 (the 1280×720 world drawn 1:1), in VI and in EN, **WHEN** each is captured with the hero and every enemy or dummy on screen (including an encounter at its closest), **THEN** no banner-bar pixel overlaps any hero or enemy body pixel (props such as a staff tip may pass behind), the bar is 112 px tall in both languages, and the goal plate and banner never overlap each other or the dots.
10. **GIVEN** any non-banner beat, **WHEN** captured, **THEN** the goal plate is at the same position as on banner beats (dots bottom + 4, centred on x 790).
11. **GIVEN** the Android reference phone (k 0.527 dp per world px) and the iOS reference phone (k 0.517), with pause and sound at `pad_min`, **WHEN** a training and a reach-the-flag beat are captured in VI and EN, **THEN** no pixel of the dots, the goal plate or the banner bar overlaps the pause or sound button.
12. **GIVEN** a push, a block and a hit during an encounter at its closest, **WHEN** captured, **THEN** each pop sits beside the fighter's head at head height and no pop pixel overlaps the banner bar.
13. **GIVEN** a hit and a strike that land at spec height, **WHEN** frame-stepped, **THEN** the hero's swing arc reaches 175 world px in front of him and the enemy's weapon tip 140, so contact is visible.
