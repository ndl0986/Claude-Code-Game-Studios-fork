# UX Spec: Quiz and Results (stars and medal)

> **Status**: In Review · Task: TASK-021 · Author: game-art-content
> **Template**: UX Spec
> **Platform Target**: Android + iOS phones, landscape, touch only (`project.yaml` goal mobile; no gamepad or keyboard). Accessibility tier: Basic+ (`design/accessibility-requirements.md`).
> **Records what's built.** Sources: Quiz & stars Rules 2–10 (P-05), F1; Hero progression Rule 10;
> Mission flow Rule 15 (the medal); Input Rules 8, 12, 13 (QC r2 B4); Audio Rules 3, 6; art
> bible §2 (quiz mood), §4; assets ASSET-001–023, 036–037.

## 1. Purpose & Player Need

"I remember this!": three picture cards per question, retry until right, then stars and the
medal. Nothing is timed, and nothing shames a wrong pick.

## 2–4. Context, Navigation, Entry & Exit

Entry: the ending's last Tiếp. Quiz → (each question) → results → unlock (if a hero opened) or
the title. Pause is available (P-05).

## 5. Layout Specification

### 5.1 Quiz wireframe

```
┌──────────────────────────────────────────────────────────────────┐
│ [⏸][🔊]              Câu 2/5  ● ● ○ ○ ○                          │
│   Prompt (quiz_prompt: 980, 40 px, weight 600, ≤ 2 lines)        │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐                      │
│  │ picture  │   │ picture  │   │ picture  │   cards ≥ 72 pt,      │
│  │  choice  │   │  choice  │   │  choice  │   choices 360 / 37 px │
│  └──────────┘   └──────────┘   └──────────┘                      │
│        why line (after the right pick) (820, 37 px, ≤ 3 lines)    │
│                                                  [ Tiếp ▶ ]       │
└──────────────────────────────────────────────────────────────────┘
```

### 5.2 Small-k quiz layout (when the reference cards would reach Tiếp's row)

**The switch is geometric, not a fixed k** (r8c; both apps test exactly this). With
P = `pad_min / k` (world px) and the reference layout stacked from the corner block down:

- prompt top = `corner_bottom` + 8, prompt height 108 (2 × 40 × 1.35, no padding);
- cards top = prompt bottom + 8, card height 290, so **cards_bottom = `corner_bottom` + 414**;
- **Tiếp top = 702 − P** (bottom 702 = `safe_bottom` − 18, height `pad_min` = P, on the story row).
  **Width, fixed world px on both apps** (leader's call, r8c): **340** in the reference layout
  (x 922–1262), **450** in the small layout (x 812–1262, the ASSET-323 pill). This is the quiz's
  Tiếp only; the story-screen Tiếp is unchanged.

**small = cards_bottom > tiep_top** (strict; at equality the cards touch Tiếp's top with a 0 gap
and the reference layout stays). With **`corner_bottom` = 18 + P** (the spec value, `hud.md`
§3.3, the symmetric 18 margin; leader's call, r8c: Android draws it, iOS moves its corner block
down 10 px in r8) that is 432 + P > 702 − P ⇔ **P > 135 ⇔ k < 72/135 ≈ 0.5333**.

- **Every test device uses the small layout** (device k confirmed r8d): the iOS QC iPhone 18 Pro
  k 0.517 (cards' bottom 571.3 vs Tiếp's top 562.7), the dev-ios phone k 0.529 (568.1 vs 565.9),
  both Android AVDs (pixel_7 1080×2400 @ 2.625, devandroid002 and mp17863, k ≈ 0.488), and the
  floor (0.40). There is no Android device at 0.527.
- **The reference layout is for k ≥ ≈ 0.534** (bigger screens, e.g. tablets and large-display
  phones). It is covered by the unit sweep (AC10), not by a reference-phone capture.
- The old "k < 0.48" bound was too low: between 0.48 and 0.533 the reference cards ran into
  Tiếp's row (Android at 0.488 pushed Tiếp ≈ 13 px past 720). An app may keep a `k < 0.48`
  clause ORed in; it is redundant.

**The reference layout** (not small): prompt, cards (y `corner_bottom` + 124 … + 414, e.g.
≈ 277–567 at k 0.534), the why line under them, Tiếp (340 wide) on the bottom row. **When small**, the tall
corner block and the tall Tiếp row leave too little room for cards that need a picture plus a
2-line label (≈ 100 + 103) above Tiếp. Of the three options, this spec takes **(c), Tiếp over spent cards, with two
guards for young children**: Tiếp never appears while a child can still choose, and the right
card is never covered. Card pictures and 2-line labels keep their reference size (options a and
b would shrink the picture or cut Luan's text to one line).

**While choosing** (`question_open`, `wrong_feedback`): **Tiếp isn't on screen** (as at every
k, it appears only after the right pick plus `feedback_time`). So the cards may use the Tiếp
row's height, and they keep the reference card size.

**After the right pick** (`right_feedback` → `why_shown`), in this order, all within
`feedback_time` (0.9 s) and before Tiếp appears:
1. The wrong cards (greyed or never picked) **fade out over 0.2 s** and are removed. They're
   inert already (Quiz Rule 5), and they're gone before Tiếp shows, so Tiếp never sits on a card
   that looks choosable.
2. The right card keeps its tick, green border and "Đúng rồi!" bar, and **glides to the left slot
   over 0.3 s** if it isn't there already (no flash, no bounce over 3 Hz).
3. The why line appears to the right of it, and Tiếp appears bottom-right after `feedback_time`.
   Both sit where the wrong cards were, never over the right card.

**In the small layout nothing moves vertically:** the prompt and the cards keep their
reference y. Only the wrong cards go, the right card glides sideways to the left slot (same y),
and the why line and Tiếp take the freed area to its right.

**Worked numbers** (world px; `corner_bottom` = 18 + P; `safe_bottom` 720; geometry as in
GameCore `QuizLayout`, checked with game-dev-ios, approved by game-dev-android):

| Element | k 0.40 (P 180, corner_bottom 198) | k 0.488 (P 147.5, corner_bottom 165.5) | k 0.527, a geometry example only, no test device (P 136.6, corner_bottom 154.6) |
|---|---|---|---|
| Prompt (980 box, x 150–1130, ≤ 2 lines, 40 px) | y 206–314 | y 173.5–281.5 | y 162.6–270.6 |
| Cards while choosing (380 × 290; slots x 40–420, 450–830, 860–1240) | y 322–612 | y 289.5–579.5 | y 278.6–568.6 |
| Tiếp top (702 − P) vs reference cards' bottom | 522 < 612 → **small** | 554.5 < 579.5 → **small** | 565.4 < 568.6 → **small** |
| Right card after the pick | left slot x 40–420, y 322–612 | x 40–420, y 289.5–579.5 | x 40–420, y 278.6–568.6 |
| Why line (box 750, region x 450–1240, ≤ 3 lines, 37 px, height 135; every TQT why fits 2 lines even at 600, F1) | y 322–457 | y 289.5–424.5 | y 278.6–413.6 |
| Tiếp (`pad_min` tall, 450 wide, x 812–1262) | y 522–702 | y 554.5–702 | y 565.4–702 |

The right card is 30 px clear of the why line and 392 px left of Tiếp; the why line ends
≥ 65 px above Tiếp's top (65 at 0.40, 130 at 0.488, 152 at 0.527). Nothing goes below y 702. Counter and dots
stay top-centre in the free band right of the corner block.

### 5.1b Results wireframe

```
│                ★ ★ ☆   (this run)       best: ★★★                │
│                🏅 medal (gold) / outline + "Đọc hết câu chuyện…"  │
│                [ Tiếp ▶ ]                                        │
```

### 5.3 Component Inventory

| Component | Spec | Source |
|---|---|---|
| Answer card | cream default (ASSET-017); **wrong:** a pale lavender fill `#E6E1F0` with a `#9C8FB8` 10 px border (ASSET-018), the circular-arrow icon (ASSET-020), an ink label (10.7:1) and a 0.5 s shake. *Today: Android draws the wrong card at 50% alpha; iOS a solid lavender. Both change after QC r3.* **right:** a pale green fill `#D9F2D0` with a `#3FA34D` 10 px **border** and a drawn **tick** (ASSET-019, ASSET-021), ink label (11.5:1), and a green "Đúng rồi!" bar (as Android draws it). The leader's "#3FA34D plus a tick" means the border and the tick, not a solid fill. The tick is the colour-blind-safe signal. **Rule:** card labels are ink on a pale or mid fill; colour, border and icon carry the meaning (`design/accessibility-requirements.md`). Icons carry a thick ink outline. Fallback for any label on a saturated fill: deep ink `#1A120C`. iOS's solid green with white text changes after QC r3 | Quiz Rules 4–5; Luan's rule 3 |
| Card order | shuffled per question (Mulberry32, Fisher–Yates) | Quiz Rule 3 |
| Why line | shown after the right pick; Tiếp appears after `feedback_time` (0.9 s) and never auto-advances | Quiz Rule 5 (P-05) |
| Prompt | `quiz_prompt`: box 980, 40 px, **weight 600** (semi-bold, the body weight), ≤ 2 lines. The content contract (005h, `rules.json` `fit.fields.quiz_prompt`) sets the weight; 600 is right, not 800 | Language F1; 005h |
| Pause, sound | top-left, as on every screen (Input Rule 3; TASK-020 W7). *An app that draws it elsewhere today moves it (dev ticket, after r3)* | Input Rule 3 |
| Counter | "Câu n/N" label, ≥ 28 px, top-centre with the progress dots | Language Rule 11 |
| Results stars | filled (ASSET-022) / outline (ASSET-023), popping in one by one; "best" shown if higher | Quiz Rule 9; Hero progression Rule 10 |
| Medal | earned: gold (ASSET-036) plus `ui.medal.earned` only in the run that earns it; otherwise outline (ASSET-037) plus `ui.medal.missing` | Hero progression Rule 10 |

## 6. States & Variants

| State | Behaviour |
|---|---|
| `question_open` | Cards active |
| `wrong_feedback` (0.5 s shake) | **All card taps dropped, not queued** (B4) |
| Greyed card | Can't be picked again; a tap does nothing and isn't a retry (D-11) |
| `why_shown` | Tiếp appears after 0.9 s. **In the small layout** (§5.2, k < ≈ 0.533, which includes every test device): the wrong cards have faded out and the right card sits in the left slot first (§5.2) |
| Results: no next hero | `ui.results.more_heroes`, then the title |

## 7. Interaction Map

Cards fire on release inside (P-01); Tiếp is debounced (B1); **the quiz (entered from the ending), results
and unlock take the screen-entry lock** (rolling: `screen_enter_lock` 0.6 s of no pressing, capped at `screen_enter_lock_max` 1.5 s; Input Rule 13b; QC r6 B7):
cards and Tiếp show at once but take no input during it, so a tap carried over from the ending
never picks a card and a fast double tap on the last Tiếp never skips results. Question to
question within the quiz keeps only the debounce, **except in the small layout** (§5.2: reference cards' bottom > Tiếp's
top, k < ≈ 0.533, so on every test device too), where Tiếp lies over the third card slot and each new question takes the lock
too. **The lock follows the same flag** as the layout (iOS `quizLocksPerQuestion = QuizLayout.small`),
never a separate k test; one tone per card press (the
right/wrong sound is its tone; O6 and the Android fix). Language switch through pause keeps the
greyed cards and retries.

## 8. Data Requirements

`quiz.json`; retries (in memory); best stars and medal (Hero progression, stored by Save).

## 9. Events Fired

"answer right/wrong", and "quiz finished {stars}" to Mission flow, which sends the one "mission
completed {hero, stars, medal_earned}" to Hero progression before results show (Mission flow
Rule 15; TASK-020 W4). Results show what Hero progression returns.

## 10. Transitions

The right glow and chime are bigger than the wrong shake and boop (≥ 6 dB, Audio Rule 3). Results
fanfare 3–4 s. No flashing over 3 Hz.

## 12. Accessibility

Right/wrong by icon, motion and sound as well as colour (accessibility audit). Stars and medal by
fill vs outline. No timers.

## 14. Acceptance Criteria

1. **GIVEN** a wrong pick, **WHEN** captured, **THEN** the card is lavender with a circular-arrow icon,
   and no red is on screen.
2. **GIVEN** a card shaking, **WHEN** another card is tapped within the 0.5 s, **THEN** the tap is
   dropped and no card turns lavender afterwards (B4).
3. **GIVEN** the right pick, **WHEN** 0.5 s pass, **THEN** no Tiếp is visible; after 0.9 s it appears,
   and nothing advances without it.
4. **GIVEN** a run with 2 retries and no skipped story, **WHEN** results show, **THEN** 2 filled and 1
   outline stars, a gold medal and `ui.medal.earned`.
5. **GIVEN** a replay scoring lower than the best, **WHEN** results show, **THEN** this run's stars
   and "best" with the higher value; the saved stars stay.
6. **GIVEN** the lowest target Android phone, **WHEN** a card is tapped, **THEN** its feedback starts within 100 ms; layouts checked on the narrowest phone and a 20:9 phone.
7. **GIVEN** a phone or emulator at k 0.40, the Android AVDs (k 0.488) and the iOS phones (k 0.517, 0.529), all small layout, **WHEN** each TQT question is captured in VI and EN (a) while choosing, (b) after a wrong pick and (c) 1 s after the right pick, with the right answer in each of the three slots, **THEN** (a)–(b) no Tiếp is on screen and the cards are 380 × 290 with the full picture and a 2-line label; (c) only the right card remains, in the left slot, with its tick; the why line and Tiếp don't overlap it or each other; nothing is above `corner_bottom` + 8, and **Tiếp's settled (at-rest) box** ends at y 702; **every animated pixel** (the idle pulse's scale, rim and shadow) stays ≤ `safe_bottom` 720 (r11; Android's pulse reaches ≈ 706 rim, ≈ 710 shadow, which passes). **The iOS phones (k 0.517 QC, 0.529 dev) are expected to show the small layout too** and are captured under this AC the same way; the reference layout (k ≥ ≈ 0.534) is covered by the unit sweep in AC10, not by a capture. In the small layout Tiếp is 450 wide (x 812–1262).
10. **GIVEN** the layout test, **WHEN** run for P = `pad_min / k` from k 0.40 to 0.75, **THEN** the small layout is chosen exactly when the reference cards' bottom > Tiếp's top (with `corner_bottom` = 18 + P: P > 135, k < 72/135 ≈ 0.5333), the per-question lock is on exactly when the small layout is, at P = 135 (gap 0) the reference layout stays, every test device (k 0.488, 0.517, 0.529) comes out small, and the reference layout's Tiếp is 340 wide (x 922–1262) and the small layout's 450 (x 812–1262), both `pad_min` tall.
8. **GIVEN** k 0.40, 0.488, 0.517 or 0.529 (small layout) and the right pick, **WHEN** frame-stepped, **THEN** the wrong cards are fully gone before Tiếp's first frame, and a tap where a wrong card was does nothing until Tiếp shows.
9. **GIVEN** the ending's last Tiếp tapped twice 0.3 s apart, **WHEN** the quiz appears, **THEN** the second tap picks no card. **GIVEN** k 0.40, 0.488, 0.517 or 0.529 (all small layout), **WHEN** Tiếp is tapped twice 0.3 s apart on a question, **THEN** the second tap picks no card on the next question. The no-lock case (reference layout, k ≥ ≈ 0.534: question to question only the debounce) is covered by the unit sweep in AC10.
