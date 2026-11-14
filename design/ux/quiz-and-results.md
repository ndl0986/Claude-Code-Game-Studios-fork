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
│ Câu 2/5  ● ● ○ ○ ○                                        [⏸]    │
│        Prompt (quiz_prompt: 980, 40 px, ≤ 2 lines)               │
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
| Answer card | cream default (ASSET-017); **wrong:** lavender `#9C8FB8` (ASSET-018) plus a circular-arrow icon (ASSET-020) plus a 0.5 s shake; **right:** green `#3FA34D` (ASSET-019) plus a tick (ASSET-021) | Quiz Rules 4–5; Luan's rule 3 |
| Card order | shuffled per question (Mulberry32, Fisher–Yates) | Quiz Rule 3 |
| Why line | shown after the right pick; Tiếp appears after `feedback_time` (0.9 s) and never auto-advances | Quiz Rule 5 (P-05) |
| Counter | "Câu n/N" label, ≥ 28 px | Language Rule 11 |
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

`quiz.json`; retries (in memory); best stars and medal (Save).

## 9. Events Fired

"answer right/wrong", "quiz finished (stars)", "medal_earned" (if no skip), "mission completed".

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
