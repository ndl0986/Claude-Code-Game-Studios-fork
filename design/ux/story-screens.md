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

### 5.3 Component Inventory

| Component | Spec | Source |
|---|---|---|
| Text box | `intro`/`scene`/`ending` field: box 880–1000, 38 px, weight 600, ≤ 2 lines (R8c) | Language F1 |
| Beat-card title | `beat_title` heading, 44 px, 1 line | 005h |
| Goal (the beat card's last box) | `goal` field | Mission flow Rule 2 |
| Tiếp | gold pill, ≥ 72 pt (ASSET-323), release-inside, **0.25 s press-time debounce** | Input Rules 8, 12 (B1) |
| Bỏ qua | cream pill, smaller, bottom-left, away from Tiếp (ASSET-323) | Mission flow UI |
| Skip warning card | ASSET-324: cream card, outline medal at the top, one line (`ui.story.skip_warning`, dialog field), "Đọc tiếp" (gold, big, right, default) and "Vẫn bỏ qua" (cream, small, left). No red, no warning sign | Mission flow Rule 15 |
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
