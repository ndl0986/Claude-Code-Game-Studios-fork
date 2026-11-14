# Accessibility Requirements

> **Status**: In Review
> **Author**: game-art-content (Luan decides)
> **Last Updated**: 2026-11-14
> **Task**: TASK-021
> **Scope**: project-wide. Every screen spec in `design/ux/` cites this file. (It sits outside
> `design/ux/` on purpose: the gates check it at this exact path.)

The players are Vietnamese children aged 6–10, many of whom can't read fluently yet. They play on
a parent's phone, often a low-end Android, in landscape. Accessibility here means first that **a
young child can play alone**, and second the usual visual, motor and auditory needs. Every rule
below names the GDD it comes from. Anything **not yet built** is marked so, and tracked.

## Accessibility Tier Definition

### This Project's Commitment

**Target tier: Basic, with child-specific items raised above it.**

**Rationale.** The audience is young children, not players with long-session or competitive needs.
The barriers that matter most are reading, fine motor control, frustration and photosensitivity,
and the GDDs already design against those (no lives, no timers, big pads, retry until right).
Full remapping and screen-reader menus (Standard and Comprehensive) don't fit a touch-only kids'
game with picture menus. A small team builds two native apps, so the effort goes to the
child-specific items below.

**Raised above the tier baseline:**
- **No reading required to play.** Icons, pictures and voice carry every instruction (Hints
  GDD Rule 1; Language Rule 12). *NOT YET BUILT: voice-over is planned (Audio GDD, VO optional
  until the slice is signed off). Today, story text must be read, or read aloud by a parent.*
- **No failure, no timers that block play** (Mission flow Rule 3; Quiz Rule 10; concept
  anti-pillars).
- **Colour is never the only signal** (art bible §4; every GDD).
- **Large touch targets with gaps** (Input Rule 4).

**Out of scope (see Known Intentional Limitations):** input remapping, screen-reader menus,
difficulty modes (the game has no difficulty to tune), and per-channel volume sliders in the
slice.

## Visual Accessibility

| Requirement | Rule | Source |
|---|---|---|
| Body text size | ≥ 37 world px at the fitted scale (story, goal, dialog, quiz prompt, why, choices) | Language Rule 6 |
| Label text size | ≥ 28 world px for labels beside an icon (pads, counters, map stub) | Language Rule 6 |
| Line height | ≥ 1.35 × font size; Vietnamese stacked marks never clipped | Language Rules 5, 7 |
| Text never shrinks | A line that doesn't fit fails validation (R8c); a run-time "…" is a bug | Language Rule 6, F1 |
| Contrast | Text on panels: ink `#3A2A20` on cream `#FFF6E3`, ≥ 7:1. Pads: a thick ink outline on every UI element (art bible §4 UI palette). Gameplay telegraph is a warm yellow glow plus a drawn "!" shape | art bible §4, combat V/A |
| Pops ("Ối!", "Đỡ được!", hit pops) | **Always outlined, ≥ 3 px:** ink `#3A2A20` on light skies (red fill vs ink 3.68:1; ink vs sky 7.9–10.5:1), cream `#FFF6E3` on the camp's dark sky (red vs cream 3.47:1; cream vs sky 9.3–11.6:1). A bare red pop measured 1.95:1 on navy and 2.5:1 on mint (QC r5) | `design/ux/hud.md` §3.3; QC r5 |
| Banner motto | Gold `#FFC531` on vermilion `#D64A2E` is 2.72:1 alone, so the text carries an **ink outline ≥ 2 px at 37 px**: gold vs ink 8.67:1, ink vs vermilion 3.18:1, passing 3:1 as large text | `design/ux/hud.md` §3.3; QC r5 |
| Card labels (quiz) | **Card labels are ink `#3A2A20` on a pale fill; the border, the icon and the motion carry the meaning.** Right: pale green fill `#D9F2D0` (ink **11.5:1**), a `#3FA34D` 10 px border, a drawn tick, and the green "Đúng rồi!" bar. Wrong: pale lavender fill `#E6E1F0` (ink **10.7:1**), a `#9C8FB8` 10 px border, the circular-arrow icon, and the 0.5 s shake. Icons (tick, arrow) carry a thick ink outline, so they read against the pale fills (the bare green tick on the pale green is only 2.7:1). **Fallback:** a label that must sit on a saturated fill uses deep ink `#1A120C` (5.8:1 on `#3FA34D`, 6.2:1 on `#9C8FB8`). Never white: white on `#3FA34D` is 3.2:1 and on `#9C8FB8` 3.0:1, which fail at small-phone sizes (k < 1) | Quiz Rules 4–5; TASK-021 review |
| No text in pictures | All words are text layers (VI/EN) | art bible; Luan's rule 2 |
| Flashing | Nothing flashes faster than 3 Hz (pulses, hints, unlock reveal, region glow) | Hints V/A; Map Rule 7 |
| Motion | No screen shake; knock-back is the only strong motion. Reduced-motion mode is not in scope | combat Game Feel |

### Color-as-Only-Indicator Audit

| Signal | Colour | Non-colour backup | Source |
|---|---|---|---|
| Quiz right / wrong | Green / lavender | Tick icon vs circular-arrow icon; glow pop vs gentle shake; chime vs soft "boop" | Quiz Rules 4–5; Audio Rule 9 |
| Stars earned / not earned | Gold / none | Filled vs outline shape | Quiz V/A |
| Medal earned / missing | Gold / none | Filled vs outline shape, plus a text line | Hero progression Rule 10 |
| Map pin states | Muted / colour / gold | Padlock silhouette / round frame / gold ring plus stars | Map Rule 3 |
| Pads | Tangerine / blue / gold | Distinct outer shape plus icon per pad | Input; HUD assets |
| Enemy telegraph | Warm yellow | Drawn "!" bubble plus a "get ready" sound | combat V/A; Audio |
| Hero vs enemy | Warm vs cool | Silhouette and facing direction | art bible §3 |
| Training steps | Fill colours | Outline vs filled icon plus a tick | Mission flow UI |

## Motor Accessibility

| Requirement | Rule | Source |
|---|---|---|
| Touch size | Every pad and button ≥ 72 pt/dp (`pad_min`), with ≥ 12 pt (`pad_gap`) between pads | Input Rule 4, F1 |
| Safe areas | Pads clear of the notch, rounded corners and system gesture zones | Input Rule 2 (QC r3 O5). *NOT YET BUILT: rounded-corner insets wait for TASK-013* |
| Forgiving touch | Thumb drift off a held pad doesn't release it; a second finger on the same pad is ignored | Input Rules 6, 9 |
| No stuck input | Pause, background, focus loss or cancel release every pad | Input Rule 11 |
| No precision or speed required | Telegraph ≥ 0.8 s (R15); blocking is optional; no timed input anywhere | combat F1, Rule 10 |
| Double taps | A second tap within 0.25 s never skips a line | Input Rule 12 (QC r2 B1) |
| Multi-touch | One finger to move and one to attack works; one finger alone is enough to finish (attack spam wins) | Input Rule 5; combat edge cases |

## Cognitive Accessibility

| Requirement | Rule | Source |
|---|---|---|
| One new thing at a time | Each beat teaches at most one new button, with a wordless hand hint | Mission flow Rule 5; Hints Rules 2–3 |
| Stuck help | A pulse or arrow after 5 s without progress, never a penalty | Hints Rule 4 |
| No failure states | No lives, no game over; the quiz always ends on the right answer | Mission flow Rule 3; Quiz Rule 6 |
| Only relevant controls shown | Pads not used by a beat are hidden, not greyed | Mission flow Rule 4 |
| Short sessions | A mission plus quiz takes about 5 minutes | Mission flow F1 |
| Kind language | No pronoun for the child, or "em" (D-17); no shaming words; wrong is "Thử lại nhé!" | writing guide |
| Predictable navigation | Every screen ends with "Tiếp"; nothing auto-advances past a line the child must hear | Mission flow; Quiz Rule 5 (P-05) |

## Auditory Accessibility

| Requirement | Rule | Source |
|---|---|---|
| Captions | Every voice line is shown as on-screen text at the same time (story boxes, quiz prompt and why). Voice is never the only carrier | Audio Rules 17, 22 |
| Visual twin for every sound | Every gameplay or learning sound has a visual event; the game is fully playable with sound off | Audio Rule 9 |
| Sound setting | One on/off toggle (HUD and pause), saved | Audio Rule 14. *Known limitation: no separate music, SFX or voice sliders in the slice* |
| Gentle sounds | No buzzers, alarms or harsh sounds; wrong is quieter than right | Audio Rules 2–3 |

### Gameplay-Critical SFX Audit

| Sound | Visual twin |
|---|---|
| Enemy windup | Yellow glow plus "!" bubble |
| Block / pushed | "Đỡ được!" / "Ối!" text pops; knock-back motion |
| Hit / flee | Spark, lean back; weapon drop and run |
| Quiz right / wrong | Tick and green / arrow and lavender, plus the shake |
| Meter marks / done | Ring fill and pulse |
| Medal / stars | Filled shapes popping in |

## Platform Accessibility API Integration

- **System text size:** not followed in the slice. Sizes are fixed in world px so layouts are
  validated (R8c). Revisit with the parent area.
- **Screen readers (TalkBack, VoiceOver):** out of scope for gameplay. A child-age audience with
  picture menus; noted as a limitation.
- **Device haptics setting:** respected (Input Rule 17).

## Per-Feature Accessibility Matrix

| Feature | Visual | Motor | Cognitive | Auditory |
|---|---|---|---|---|
| Story screens and dialogue | Sizes, contrast, no text in art | Tiếp ≥ 72, debounced | One sentence per box, no auto-advance | Captions = the text |
| Mission play | Telegraph by shape | Pads, drift-tolerant, no timers | One new button per beat, hints | Visual twins |
| Quiz | Icons plus colour | Big cards, shake lock (B4) | Pictures, retry until right | Text plus sounds |
| Results / unlock / title | Shapes for stars and medal | Big buttons | Stars never gate anything | Visual twins |

## Accessibility Test Plan

| Check | How | Maps to |
|---|---|---|
| Colour-blind and greyscale | Screenshots in protan, deutan, tritan and greyscale for each screen | art bible §4; Map AC10 |
| Text fit | R8c over all lines, both languages | Language AC5 |
| Diacritics | Fixture string screenshot | Language AC6 |
| Touch | Pad size and gap measured; child-thumb test | Input AC10–12 |
| Gesture zones | O5 measurement on 20:9 Android and Dynamic Island iOS | Input AC10 |
| Sound off | Full mission played muted | Audio AC5 |
| Flashing | Frame-step recording of pulses and the reveal | Map AC9 |

## Known Intentional Limitations

- No input remapping (touch only, fixed pads).
- No screen-reader support in gameplay.
- No separate volume sliders in the slice (one toggle).
- No reduced-motion mode (motion is gentle by design).
- No system text-size scaling (fixed, validated sizes).

**Known gaps today (NOT YET BUILT, tracked):**
- **Voice-over:** not recorded yet, so "no reading needed" is a later target (Audio GDD, D-23).
- **Pressed-state squash:** not built on iOS or Android (Input Rule 15). iOS changes colour only;
  Android shows 50% alpha on disabled buttons and wrong cards only.
- **Rounded-corner safe insets:** wait for TASK-013 (Input Rule 2).

## Audit History

| Date | By | Result |
|---|---|---|
| 2026-11-14 | game-art-content (from the GDDs and QC rounds) | First version; lean review pending |

## Open Questions

| Question | Owner |
|---|---|
| Separate music, SFX and voice volume, in the parent area? | Luan (Settings & parent area) |
| Follow the system text size later, with a re-validated larger layout? | game-art-content + devs |
