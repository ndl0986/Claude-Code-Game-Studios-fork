# UX Spec: Pause Menu

> **Status**: In Review · Task: TASK-021 · Author: game-art-content
> **Template**: UX Spec
> **Platform Target**: Android + iOS phones, landscape, touch only (`project.yaml` goal mobile; no gamepad or keyboard). Accessibility tier: Basic+ (`design/accessibility-requirements.md`).
> **Records what's built.** Sources: Mission flow Rules 11, 12, states (`paused`); Input Rule 11
> (clear-all); Combat edge case (the windup restarts on resume); Language Rules 2, 4; Audio Rules
> 10, 14, 16; QC iOS r2 **iOS-R2-06** (the backdrop is the screen pause came from). Note: in
> `decisions.md`, **P-06** is "story screens show the step's background", a related rule for
> story screens; this spec cites iOS-R2-06 for the pause backdrop.

## 1. Purpose & Player Need

Stop safely at any moment: keep playing, change sound or language, or go home. Nothing is lost
except the current mission run (nothing is saved mid-mission).

## 2–4. Context, Navigation, Entry & Exit

Entry: the pause button (any phase: play, story, dialogue, quiz), or automatically on background,
focus loss or an audio interruption. Exit: "Chơi tiếp / Keep playing" → the same state; "Về bản đồ
/ To the map" → the title (the run is discarded).

## 5. Layout Specification

```
┌──────────────────────────────────────────────────────────────────┐
│ (backdrop: the screen pause came from, dimmed, e.g. the quiz     │
│  stays visible behind it; iOS-R2-06)                             │
│              ┌──────────── Tạm dừng / Paused ────────────┐       │
│              │   [ Chơi tiếp / Keep playing ]  (big)      │       │
│              │   [ 🔊 Sound ]        [ VI | EN ]          │       │
│              │   [ Về bản đồ / To the map ]  (smaller)    │       │
│              └────────────────────────────────────────────┘       │
└──────────────────────────────────────────────────────────────────┘
```

| Component | Spec | Source |
|---|---|---|
| Backdrop | the screen pause came from, dimmed; **the quiz stays visible behind it** | iOS-R2-06 |
| Keep playing | the biggest button (the default), release-inside | P-01 |
| Sound | the toggle, saved | Audio Rule 14 |
| VI \| EN | the language switch (one of only two places; the other is the title) | P-04; Language Rule 2 |
| To the map | smaller, lower; returns to the title | Mission flow Rule 11 |

## 6. States & Variants

| Event | Behaviour |
|---|---|
| Pause opens | **Every held pad is released** (Input Rule 11); play timers, enemy states and the hold meter freeze; music −12 dB; SFX and voice pause |
| Language switched here | On resume, all text is in the new language; quiz state, `story_skipped` and ask taps are unchanged |
| Resume during a windup | The enemy's telegraph **restarts from 0**, so the child gets the full warning (Combat edge case, AC19) |
| Auto-pause (background, call) | Stays paused when the app returns, until "Chơi tiếp" |

## 7. Interaction Map

All buttons release-inside and debounced; one tone per press.

## 12. Accessibility

Big, clearly separated buttons; text plus icons; no timers.

## 14. Acceptance Criteria

1. **GIVEN** defend held, **WHEN** pause opens, **THEN** no pad is held after resume.
2. **GIVEN** an enemy 0.8 s into a 1.1 s windup, **WHEN** paused and resumed, **THEN** the windup lasts
   another full 1.1 s.
3. **GIVEN** the quiz with one greyed card, **WHEN** paused, **THEN** the quiz stays visible behind the
   menu; after switching to EN and resuming, the same card is greyed and the text is EN.
4. **GIVEN** the app backgrounded mid-fight, **WHEN** it returns, **THEN** the pause menu shows and
   nothing has moved.
5. **GIVEN** the lowest target Android phone, **WHEN** pause is tapped, **THEN** the menu shows within 150 ms; checked on the narrowest phone and a 20:9 phone.
