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
fitted inside the safe rect (Input Rule 1; both apps, iOS from r6), so **`safe_bottom` = 720** in
world px on every supported phone (Android clamps it with `min(720, ·)`).

- **Corner block** (pause + sound, Input Rule 3): x 18 … `corner_right`, y 18 … `corner_bottom`,
  with `corner_bottom` = 18 + `pad_min / k` (155 in the geometry example, k 0.527; ≈ 165.5 on the Android AVDs, k 0.488; **"ref" numbers in
  this section are that k 0.527 geometry example**, not a device) and
  `corner_right` = 18 + 2 × `pad_min / k` + `pad_gap / k` (≈ 315), as in `design/ux/hud.md` §3.3.
- **No top stack on story screens** (game-dev-ios r8 review; leader's call). Story screens are not
  play: the beat progress dots, the goal plate and the banner bar are **hidden** on the intro, beat
  cards, captions and the ending (and on dialogue screens). Only the pause/sound corner block shows
  (`hud.md` §5, "story, dialogue screens"). *Today iOS draws the beat dots at y 30–90 on story
  screens: a dev ticket (r8).*
- **Part label** ("Phần 3 / Part 3"; r8b, from iOS r7 `GameScene.buildPlayHUD`, agreed with
  Android, which adds it in r8):
  - **Text:** the string `ui.play.beat` (vi "Phần", en "Part") + a space + **n**, where n = the
    mission beat index, **1-based**, over **all** beats (walk, hold-meter, training, dialogue,
    fight), the same index as the beat dots. TQT has 5 beats, so n is 1…5. Only " " + n is
    composed in code; the word comes from the strings file.
  - **Screens:** **beat cards and captions only**. Not on the intro, the ending, dialogue or the
    quiz. (A dialogue beat keeps its number in the count, though no label shows on it.)
  - **Type:** Nunito 800, **28 px** on both screens and both apps (label size, Language Rule 6),
    centred on x 640, 1 line.
  - **Position:** centre y = max(`corner_bottom` + 8 + 16, panel top − 24), so the box is panel
    top − 38 … panel top − 10. At the floor (k 0.40): y 241–269 over a beat card (panel 279),
    309–337 over a caption (panel 347). The `corner_bottom` clamp never binds on the supported
    range.
  - **Colour and contrast:** star gold **`#FFC531`** fill with an **ink `#3A2A20` outline ≥ 2 px**,
    as the banner motto (`design/accessibility-requirements.md`). It sits on the scene picture,
    so one of fill or outline must separate it from every background it can land on (checked
    against the theme sky bands and palette anchors, `mission-flow-assets.md`):
    | Behind the label | Gold fill vs it | Ink outline vs it |
    |---|---|---|
    | River sky `#9CCBEA`–`#BFE0F2` | 1.1 | **7.9–9.9** |
    | Village sky `#A9D3EC`–`#CDE6EE` | 1.0–1.2 | **8.6–10.5** |
    | Camp sky `#2E3156`–`#3B3F6B` | **6.3–7.9** | 1.1–1.4 |
    | Camp sun shaft `#E8A93B` | 1.3 | **6.6** |
    | Haze `#F3E6C8` / river blue `#3E8FC4` / roof `#B5673F` | 1.3 / 2.2 / 2.7 | **11.1 / 3.9 / 3.3** |
    The worst case is 3.25:1 (roof, by the outline), ≥ 3:1. Inside the glyph, gold vs ink is
    8.67:1. The iOS r7 gold `#F2B632` (7.52:1 vs ink) moves to `#FFC531`. **Never** bare gold
    without the outline: on the river and village skies it is ≈ 1.1:1 (invisible).
- **The story picture is full-bleed** (P-06: the step's background fills the screen behind
  everything), so it has no frame corner to collide with.
- **Story screens show the background only, no play sprites** (QC r6, for r8; r8b). Behind a story
  panel **nothing of the play layer is drawn**: no hero, enemies, partner or dummies, **no flag
  prop**, no fx or pops, no hints. A beat card or caption is the scene background plus the
  placeholder (or its real still), the panel, the part label, the bottom row and the pause/sound
  corner, nothing else. Dialogue screens follow the same rule (`dialogue.md` §5.2). Why: at spec height a standing figure
  (y ≈ 290–470) sits right where the panel goes, so the panel would cut him at the chest (QC saw
  it at the neck with the taller placeholder). Characters on story screens come from stills and
  portraits only, composed for the safe zone below.
- **Never only background on a story screen** (iOS r3 R3-06, "intro pictures empty"), with **one
  named exception: the ending's failure path** (r8d, leader's call; see the fallback below). Until a
  screen has its real still (per-box pictures, content schema 1.2), it shows a **placeholder
  still**: the hero's portrait (`pic.portrait_<hero_id>_hero_determined`, ASSET-327; a beat may
  name its own portrait later) in a round drum-ring frame, on the scene background, **centred on
  x 640**, wholly in the safe zone and **clear of the part label: bottom ≤ label top − 8**
  (= panel top − 46, taken at the floor, so the same world position at every k):
  - **intro and caption:** 256 × 256, **bottom ≤ 301**, so y 45–301 (label 309–337, panel 347).
    The intro has no label but uses the same position, so the stills line up;
  - **beat card:** **208 × 208**, **bottom ≤ 233**, so y 25–233 (label 241–269, panel 279). 240
    no longer fits under the label and above the top margin (y ≥ 18);
  - **minimum size 192 × 192** (≈ 77 dp at k 0.40, a face still reads). If a later layout leaves
    less room than that, the placeholder is dropped and the background alone shows, rather than
    overlap the label or panel;
  - it never enters the pause/sound block: centred, its left edge (512 or 536) stays right of
    `corner_right` + 8 (≈ 416 at k 0.40); with the top stack hidden, nothing else is above it;
  - the **ending** shows its own still, `pic.scene_tqt_ending` (ASSET-016, the mission's
    `ending.picture_id`), full-bleed behind the panel. **A placeholder of it already ships** in
    `content/data/pictures/scene_tqt_ending.png` (640 × 360, flat shapes, no figure; redrawn in
    r8d so the banner cloth and the sun sit above y 170 of 360 = world 340). An app draws that
    file, scaled to the 1280 × 720 world; "Needed" in the manifest means the real art, not that
    the ending has no picture;
  - **fallback for a missing still** (r8d): if a story screen's `picture_id` is absent or its file
    fails to load, the **intro, beat cards and captions** show the placeholder portrait at their
    own size and position (above) and log it in debug builds. **The ending is the exception:** it
    is the calm, respectful screen, and a hero face there (determined or cheerful) is the wrong
    tone, so a failed ending still shows **the scene background only**, logged in debug. This is
    a failure path, not a design state;
  - **so it never happens in practice, it is checked at build time:** content rules R2/R10
    (`content/README.md`) already require every `picture_id` to resolve in `assets.json` with its
    file present, and **each app's test suite asserts that every `assets.json` picture file is in
    the app bundle** (iOS bundle resources, Android assets) and decodes, so a missing ending
    still fails the build, not the child's screen.
  The placeholder is replaced 1:1 by the real still when it exists (same safe zone).
- **Picture safe zone:** in any picture shown behind a story panel (a background set on a story
  screen, the ending still, future per-box pictures), **faces, figures and the key subject sit
  above the panel's top at the floor (k 0.40)**: above **y 340** world px for intro, caption and
  ending (panel top 347), and above **y 270** for pictures behind a beat card (panel top 279; at
  k 0.527, the geometry example, the tops are 390 and 322). Below that line goes only ground, water, grass or
  background, which the panel may cover. Asset specs carry the rule in their own pixel sizes.
- **Crop margin (r8d):** the apps scale a full-bleed still differently. Android fits it to the
  1280 × 720 world (a 640 × 360 still at exactly × 2). iOS **cover-crops** it to the whole screen:
  on the 19.5:9 QC phone a 16:9 still is drawn ≈ 972 world px tall, so ≈ 126 world px (≈ 13% of
  its height, png y 0–47 of 360) is cut at the top and the same at the bottom, and the sides run
  past the world's edges. So the subject must sit inside **both**: below the top **13%** of the
  picture's height and above the panel line (for a 640 × 360 still: **png y ≈ 47–170**, i.e.
  world ≈ 0–333 on iOS after the crop and ≤ 340 on Android), and clear of the outer **5%** of its
  width on each side. The TQT ending placeholder passes: pole top at png y 60, banner cloth
  66–128, sun 64–144, all at x 200–510 (of 640).
- **Framed pictures:** an app that draws the picture inside a frame starts that frame at
  **y ≥ `corner_bottom` + 8** (ref ≥ 163), never under the block.
- **Bottom row:** "Tiếp" (right) and "Bỏ qua" (left) sit on `safe_bottom` − 18 and are **both
  ≥ `pad_min` tall** (Input Rule 4), on the same row (ref y 565–702). "Bỏ qua" is smaller only
  in **width** and weight (a cream pill, ASSET-323), never in height: in the k 0.527 geometry example it is
  137 tall, not the 84 Android drew in r5.
- **The paper frame (ASSET-035), the text panel of intro, caption and ending, and the
  beat-card panel** are centred on x 640, width = text box + 2 × 32 (box 880 → x 168–1112; box
  1000 → x 108–1172), and sit **bottom-anchored above the button row**:
  - bottom = Tiếp top − 8 (ref 557);
  - height H: 32 + (beat cards: title 60 + 8) + body 2 lines (103) + 32 → **H = 235** for a beat
    card, **167** for intro, caption and ending;
  - **top ≥ `corner_bottom` + 8 is required.** In the k 0.527 geometry example: beat card y 322–557, other boxes
    y 390–557, all clear of the block (which ends at y 155).
- **Fit condition:** `2 × pad_min / k + 52 + H ≤ 720`. For a beat card (H 235) it holds down to
  k ≈ 0.33; at the **shared supported floor, k ≥ 0.40** (`hud.md` §3.3, `title.md`), it is 647 ≤
  720, with 73 px to spare (the dialogue panel, H 286: 698 ≤ 720, `dialogue.md` §5.2). The text box can't narrow to buy room: at 720 wide, 6 TQT story lines overflow
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
- **Screen-entry lock, rolling (QC r6 B7, Input Rule 13b):** after a story screen (intro, beat
  card, caption, ending) or the skip-warning card is entered from a different screen or phase,
  Tiếp and Bỏ qua **show at once but take no input** until the child has stopped pressing for
  `screen_enter_lock` (0.6 s), at most `screen_enter_lock_max` (1.5 s) from entry. **Every
  box takes this lock** (intro, beat card, caption and ending boxes; Input Rule 13b, QC r7), so
  each box holds ≥ 1.5 s under a mash; `advance_debounce` still applies. Pause and sound are exempt;
  presses are dropped, not queued. An optional subtle fade-in over that time is allowed. A pointer
  already down (e.g. on the Attack pad's spot) never fires them. After the lock,
  `advance_debounce` applies as before.
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
9. **GIVEN** an Android AVD (k ≈ 0.488) and the iOS QC phone (k 0.517) and a k 0.40 phone or emulator, with pause and sound at `pad_min`, **WHEN** a beat card, an intro box, a caption and the ending are captured in VI and EN, **THEN** no pixel of the paper frame, the beat-card panel or a framed picture lies inside the pause/sound block (x ≤ `corner_right`, y ≤ `corner_bottom`); the panel's top is ≥ `corner_bottom` + 8 and its bottom ≤ Tiếp's top − 8.
10. **GIVEN** any story screen on the reference phones and at k 0.40, **WHEN** captured, **THEN** "Bỏ qua" is ≥ `pad_min` tall (≥ `pad_min`: ≈ 147.5 world px at k 0.488; ≈ 139.3 at 0.517; 180 at k 0.40), its top and bottom match Tiếp's, and it stays left of Tiếp with ≥ `pad_gap` between them.
11. **GIVEN** any story screen (intro, a beat card, a caption, the ending) and a press every 0.35 s that keeps going, **WHEN** it plays, **THEN** every box holds ≥ 1.5 s (`screen_enter_lock_max`) or until the presses pause for 0.6 s, none is skipped silently, and the next screen starts only after each box was advanced once (Input AC17, AC21).
12. **GIVEN** the intro, a beat card, a caption and the ending at the reference phones and at k 0.40, **WHEN** captured, **THEN** no hero, enemy, partner, dummy or flag sprite, fx, pop or hint is drawn; **no story screen shows only background**: no beat dots, goal plate or banner bar show (only the pause/sound corner); the intro and captions show the placeholder portrait still (256, bottom ≤ 301), beat cards show it at 208 with bottom ≤ 233, centred, clear of the pause/sound block and ≥ 8 px above the "Phần n / Part n" label, and the ending shows `pic.scene_tqt_ending` (ASSET-016, the placeholder until the real art) with the banner cloth and the warm light above the panel's top.
13. **GIVEN** each TQT beat card and caption in VI and EN, at the reference phones and at k 0.40, **WHEN** captured, **THEN** the label reads "Phần n" / "Part n" with n the beat's 1-based mission index (the same as its beat dot), 28 px, gold `#FFC531` with an ink outline ≥ 2 px, its box at panel top − 38 … − 10 (241–269 over a card, 309–337 over a caption at k 0.40); the intro, the ending, dialogue and the quiz show no label; and on the river, village and camp backgrounds the label's edge is visible in greyscale.
14. **GIVEN** each app's test suite, **WHEN** it runs, **THEN** it fails if any `picture_id` in the TQT mission (intro, beats, ending) or any `assets.json` picture file is missing from the app bundle or fails to decode. **GIVEN** a debug build with the ending still's file removed, **WHEN** the ending shows, **THEN** only the scene background shows behind the panel (no portrait) and a missing-picture log line is written; **GIVEN** the same with a caption's picture removed, **THEN** the placeholder portrait shows.
