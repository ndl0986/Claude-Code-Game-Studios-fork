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
| `why_shown` | Tiếp appears after 0.9 s |
| Results: no next hero | `ui.results.more_heroes`, then the title |

## 7. Interaction Map

Cards fire on release inside (P-01); Tiếp is debounced (B1); one tone per card press (the
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
