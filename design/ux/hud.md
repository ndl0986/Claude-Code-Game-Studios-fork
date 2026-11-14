# HUD Design: Mission

> **Status**: In Review · Task: TASK-021 · Author: game-art-content
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
| Beat progress dots | During play | Where the child is in the story |
| Pause, sound | Always | Input Rule 3 |
| Hold-meter ring | Hold-meter beats, around the flag pad | Mission flow UI |
| Training checklist | Training beats (3 icons) | Mission flow UI |
| Text pops ("Ối!", "Đỡ được!") | On the event, over the hero | Combat V/A |
| Hints (hand, pulse, arrow) | When triggered | Hints GDD |
| **Never shown:** health, score, timers, enemy health, language chip in play | — | pillars; P-04 |

## 3. Layout Zones

### 3.1 Zone Diagram (landscape, the world fitted at k, HUD anchored to the safe rect)

```
┌──────────────────────────────────────────────────────────────────┐
│ [⏸][🔊]          ● ● ○ ○  (beat dots)                             │  ← top safe edge
│                  "Đẩy lùi quân giặc!" (goal line)                 │
│                                                                  │
│                   (play area: hero, enemies,                     │
│                    telegraph "!", pops below the HUD row)        │
│                                                                  │
│                                              [🚩 flag]           │  ← hold-meter / training only
│  [ ◀ ][ ▶ ]                           [🛡 defend][🗡 attack]      │  ← bottom safe edge
└──────────────────────────────────────────────────────────────────┘     (above gesture insets)
```

### 3.2 Zone Specification Table

| Zone | Anchor | Contents |
|---|---|---|
| Top-left | Safe rect top-left | Pause, sound (≥ 72 pt each) |
| Top-centre | Safe rect top, centred | Progress dots; the goal line below them (`goal` field, 37 px body) |
| Bottom-left | Safe rect bottom-left, above the gesture inset | ◀ ▶ (`pad_gap` apart) |
| Bottom-right | Safe rect bottom-right, above the gesture inset | Defend, attack; flag above attack when present |
| Play area | The 1280×720 world | Characters, telegraph, pops |

Anchoring follows Input Rule 2: the true safe rect, with Android's **mandatory** gesture insets and
iOS's home-indicator inset (QC r3 O5: pad bottoms clear of the gesture zone).

## 4. HUD Element Specifications

| Element | Size | Asset | Behaviour |
|---|---|---|---|
| ◀ ▶ | ≥ 72 pt, gap 12 pt | ASSET-024 | Fire on press; the ◀↔▶ slide; drift forgiven (Input Rules 7, 9) |
| Attack | ≥ 72 pt | ASSET-025 (tangerine, staff icon) | Press starts a swing (auto-face, combat Rule 2) |
| Defend | ≥ 72 pt | ASSET-026 (shield, one drum-ring accent) | Held = shield up |
| Flag | ≥ 72 pt | ASSET-027 + the meter ring ASSET-028 (ASSET-326 pulse) | Hold-meter: hold; training finish: press |
| Pause, sound | ≥ 72 pt | ASSET-029–030 | Release-inside (P-01) |
| Progress dots | ~24 px each | ASSET-032 | Filled when the beat is done |
| Goal line | `goal` field (box 1040, 37 px) | text layer | Hidden on dialogue beats (no goal) |
| Pops | label size | text layer | Above the hero's head, **below the HUD row** (iOS r2: "Ối!" kept clear of pause and sound) |

## 5. HUD States by Gameplay Context

| Context | Pads shown | Other |
|---|---|---|
| `walk_to` | ◀ ▶ only | Dots, goal hidden |
| walk beat | ◀ ▶ | Goal |
| hold-meter | flag (with ring) | Goal; the hold hand on first view |
| training | ◀ ▶, attack, defend, flag (flag shown from the start, active at the finish step) | Checklist icons; hints in step order (B3) |
| fight / encounter | ◀ ▶, attack, defend | Telegraph |
| reach-the-flag (no encounter) | ◀ ▶ (attack, defend if listed) | Flag goal |
| story, dialogue screens | **none** | Pause only |
| paused | none (the pause menu) | All pads released (Input Rule 11) |

## 6. Information Hierarchy

1. The hero and the telegraphed enemy (the play area).
2. The pads in use.
3. The goal line.
4. Dots, pause and sound (small, peripheral).

## 7. Visual Budget

At most 5 pads plus pause and sound; one hint at a time (Hints Rule 3); no more than 2 pops at
once.

## 8. Feedback & Notification Systems

- Every pad: a 4% squash in the next frame. *NOT YET BUILT on Android* (accessibility gaps).
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
