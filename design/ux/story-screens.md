# UX Spec: Story Screens (intro, beat card, caption, ending) and the Skip Warning

> **Status**: In Review · Task: TASK-021 · Author: game-art-content
> **Template**: UX Spec
> **Platform Target**: Android + iOS phones, landscape, touch only (`project.yaml` goal mobile; no gamepad or keyboard). Accessibility tier: Basic+ (`design/accessibility-requirements.md`).
> **Records what's built.** Sources: Mission flow Rules 2, 10, 15 (D-07), states table; P-06
> (the step's background); Input Rules 8, 12, 13 (QC r2 B1); Audio Rules 17, 22; Language
> field types; art bible §2 (story and calm-ending moods); assets ASSET-035, 323, 324.

## 1. Purpose & Player Need

The story is told one sentence at a time, at the child's own pace. The child can skip, but is
gently told that skipping costs this story's medal.

## 2. Player Context on Arrival

- The intro after Start.
- A beat card before a non-fight beat.
- A caption after a fight.
- The ending after the last beat.

## 3–4. Navigation, Entry & Exit

| Screen | Entry | Exit |
|---|---|---|
| Intro | `gate_check` passed | the last box's Tiếp → `walk_to[0]` |
| Beat card | `walk_to[i]` (non-fight) | Tiếp → `beat_play[i]` |
| Caption | `beat_end[i]` (fight) | Tiếp → `walk_to[i+1]` or the ending |
| Ending | the last beat's end | Tiếp → quiz |
| Skip warning | Skip (medal not earned yet, no "Skip anyway" yet this run) | "Đọc tiếp" → the same box; "Vẫn bỏ qua" → past this screen |

## 5. Layout Specification

### 5.1 ASCII Wireframe

```
┌──────────────────────────────────────────────────────────────────┐
│ [⏸]                                                              │
│        (picture: the current step's background, P-06;            │
│         the ending has its own still, calm-ending mood)          │
│  ┌─ paper frame, drum-ring border (ASSET-035) ───────────────┐   │
│  │  Title (beat cards only, heading)                         │   │
│  │  One sentence, ≤ 2 lines (scene/intro/ending field)       │   │
│  └───────────────────────────────────────────────────────────┘   │
│  [Bỏ qua]  (smaller, bottom-left)              [ Tiếp ▶ ]        │
└──────────────────────────────────────────────────────────────────┘
```

### 5.2 Boxes: the panel clear of the pause/sound corner (QC r5)

QC r5 (both apps): the top-left pause/sound block, at `pad_min`, covered the top-left corner of
the story picture's frame and of the beat-card panel. Boxes are world px in the 1280×720 world
fitted to the safe rect (Input F1), so `safe_bottom` = 720 on the reference phones.

- **Corner block** (pause + sound, Input Rule 3): x 18 … `corner_right`, y 18 … `corner_bottom`,
  with `corner_bottom` = 18 + `pad_min / k` (155 at the Android reference, k 0.527) and
  `corner_right` = 18 + 2 × `pad_min / k` + `pad_gap / k` (≈ 315), as in `design/ux/hud.md` §3.3.
- **The story picture is full-bleed** (P-06: the step's background fills the screen behind
  everything), so it has no frame corner to collide with. An app that draws the picture inside
  a frame starts that frame at **y ≥ `corner_bottom` + 8** (ref ≥ 163), never under the block.
- **Bottom row:** "Tiếp" (right) and "Bỏ qua" (left) sit on `safe_bottom` − 18 and are **both
  ≥ `pad_min` tall** (Input Rule 4), on the same row (ref y 565–702). "Bỏ qua" is smaller only
  in **width** and weight (a cream pill, ASSET-323), never in height: at the reference it is
  137 tall, not the 84 Android drew in r5.
- **The paper frame (ASSET-035), the text panel of intro, caption and ending, and the
  beat-card panel** are centred on x 640, width = text box + 2 × 32 (box 880 → x 168–1112; box
  1000 → x 108–1172), and sit **bottom-anchored above the button row**:
  - bottom = Tiếp top − 8 (ref 557);
  - height H: 32 + (beat cards: title 60 + 8) + body 2 lines (103) + 32 → **H = 235** for a beat
    card, **167** for intro, caption and ending;
  - **top ≥ `corner_bottom` + 8 is required.** At the reference: beat card y 322–557, other boxes
    y 390–557, all clear of the block (which ends at y 155).
- **Fit condition:** `2 × pad_min / k + 52 + H ≤ safe_bottom`. For a beat card (H 235) that holds
  down to k ≈ 0.33 with `safe_bottom` 720, and k ≈ 0.40 with a large bottom inset
  (`safe_bottom` ≈ 646). This sets the **shared supported floor, k ≥ 0.40**, for every screen (`hud.md` §3.3,
  `title.md`). The text box can't narrow to buy room: at 720 wide, 6 TQT story lines overflow
  2 lines (F1, measured), so the panel never slides beside the block.
- **Dialogue screens** follow the same rule: the portrait and the box start below
  `corner_bottom` + 8 (`dialogue.md`).

### 5.3 Component Inventory

| Component | Spec | Source |
|---|---|---|
| Text box | `intro`/`scene`/`ending` field: box 880–1000, 38 px, weight 600, ≤ 2 lines (R8c) | Language F1 |
| Beat-card title | `beat_title` heading, 44 px, 1 line, centred at the top of the paper frame. **No emblems or ornaments beside it**: the frame's drum-ring border (ASSET-035) is the only motif (Luan's rule 4: one motif). An app that draws emblems either side of the title is off-spec | 005h |
| Goal (the beat card's last box) | `goal` field | Mission flow Rule 2 |
| Tiếp | gold pill, ≥ 72 pt (ASSET-323), release-inside, **0.25 s press-time debounce** | Input Rules 8, 12 (B1) |
| Bỏ qua | cream pill, bottom-left, away from Tiếp (ASSET-323); **≥ `pad_min` tall, on Tiếp's row**; smaller than Tiếp in width and visual weight only | Mission flow UI; Input Rule 4 |
| Skip warning card | ASSET-324: cream card, outline medal at the top, one line (`ui.story.skip_warning`, dialog field), "Đọc tiếp" (gold, big, right, default, **open-book icon**) and "Vẫn bỏ qua" (cream, small, left, **skip-arrow icon**) (ASSET-333; TASK-020 W20). The icons let a pre-reader tell the buttons apart; the line is voiced once VO exists (Audio Rule 17). No red, no warning sign | Mission flow Rule 15 |
| Legend marker | Sentences citing a legend start "Truyện kể rằng… / The story says…" | R4, R4b |

## 6. States & Variants

| State | Behaviour |
|---|---|
| Normal | Tiếp advances one box |
| Skip, medal not yet earned, no "Skip anyway" yet | The warning opens (input is locked while it opens; taps are dropped, Input Rule 13) |
| Skip after "Skip anyway" this run | Skips at once, no warning |
| Skip with the medal already earned | Skips at once, no warning |
| Ending | No Skip-induced loss beyond the medal; quiz next |

## 7. Interaction Map

- Tiếp: release-inside; a second press within 0.25 s is ignored. **QC r2 B1:** two taps 0.17 s
  apart used to skip a line, and now advance one.
- Bỏ qua: release-inside → the warning or an immediate skip (above).
- The debounce also applies across a screen change (Input edge case), so a double tap on the
  last caption box never skips the next screen's first line.
- No timers: nothing advances by itself (Mission flow).

## 8. Data Requirements

Text ids per box; `story_skipped` (in memory); whether the medal is already earned (Save).

## 9. Events Fired

"box shown" (Audio: VO when it exists), "box advanced", "story skipped" (→ no medal this run).

## 10. Transitions & Animations

A 0.1–0.15 s page slide per box (Mission flow Game Feel). *NOT YET BUILT: iOS, Android (boxes swap instantly).* The warning card slides in with a
soft bell (Audio `sfx_skip_warning_open`; the bell is not built yet, see the patterns file). Last beat →
ending: a 3 s music crossfade, never a hard cut. *NOT YET BUILT: iOS, Android (no music yet on
either app).*

## 11–13. Input, Accessibility, Localization

- Touch only; every button ≥ 72 pt.
- Captions are the text itself (Audio Rule 22).
- VI/EN within budgets; one sentence per box.

## 14. Acceptance Criteria

1. **GIVEN** a beat card on line 1, **WHEN** Tiếp is tapped twice 0.17 s apart, **THEN** only line 2
   shows (B1).
2. **GIVEN** the first Skip in a run and no medal, **WHEN** tapped, **THEN** the warning card shows
   with "Đọc tiếp" as the default. "Đọc tiếp" returns to the same box, and the next Skip warns
   again.
3. **GIVEN** "Vẫn bỏ qua", **WHEN** tapped, **THEN** the rest of this screen is skipped, and later
   Skips in the run skip at once.
4. **GIVEN** any story screen, **WHEN** captured in VI and EN, **THEN** each box is one sentence
   within its box, with no red anywhere on the warning card.
5. **GIVEN** the last caption box, **WHEN** Tiếp is double-tapped across the screen change, **THEN** the next screen's first line is not skipped.
6. **GIVEN** the lowest target Android phone, **WHEN** Tiếp is tapped, **THEN** the next box shows within 150 ms; checked on the narrowest phone and a 20:9 phone.
7. **GIVEN** the skip warning, **WHEN** captured in VI and EN, **THEN** "Đọc tiếp" shows the open-book icon and "Vẫn bỏ qua" the skip-arrow icon.
8. **GIVEN** a beat card, **WHEN** captured, **THEN** the title has no emblem on either side, and pause and sound sit top-left.
9. **GIVEN** the Android (k 0.527) and iOS (k 0.517) reference phones and a k 0.40 phone or emulator, with pause and sound at `pad_min`, **WHEN** a beat card, an intro box, a caption and the ending are captured in VI and EN, **THEN** no pixel of the paper frame, the beat-card panel or a framed picture lies inside the pause/sound block (x ≤ `corner_right`, y ≤ `corner_bottom`); the panel's top is ≥ `corner_bottom` + 8 and its bottom ≤ Tiếp's top − 8.
10. **GIVEN** any story screen on the reference phones and at k 0.40, **WHEN** captured, **THEN** "Bỏ qua" is ≥ `pad_min` tall (≥ 137 world px at k 0.527, ≥ 180 at k 0.40), its top and bottom match Tiếp's, and it stays left of Tiếp with ≥ `pad_gap` between them.
