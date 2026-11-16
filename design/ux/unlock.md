# UX Spec: Hero Unlock and the Map Stub

> **Status**: In Review · Task: TASK-021 · Author: game-art-content
> **Template**: UX Spec
> **Platform Target**: Android + iOS phones, landscape, touch only (`project.yaml` goal mobile; no gamepad or keyboard). Accessibility tier: Basic+ (`design/accessibility-requirements.md`).
> **Records what's built.** Sources: Hero progression Rules 4–6, 10; Mission flow states
> (`unlock`); Map & Hometowns Rule 9 (the later arrival sequence; `start-map.md` §10); Audio (`sfx_unlock_reveal`); assets
> ASSET-038 (the reveal glow).

## 1. Purpose & Player Need

"A new hero is waiting!": a calm reveal of the next hero the moment the child's quiz opens them,
then home.

## 2–4. Context, Navigation, Entry & Exit

Entry: results → Tiếp, **only** when this finish opened a hero that wasn't open before (Hero
progression Rule 10). Otherwise results go straight to the title. Exit: "Về bản đồ / To the map" →
the title in the slice (the map later).

## 5. Layout Specification

```
┌──────────────────────────────────────────────────────────────────┐
│               Mở khoá anh hùng tiếp theo!  (ui.unlock.title)      │
│                                                                  │
│              [ silhouette → colour: next hero ]                  │
│                    hero name (hero_name field)                   │
│                                                                  │
│               (Bản đồ sắp ra mắt / Map coming soon)              │
│                     [ Về bản đồ / To the map ]                   │
└──────────────────────────────────────────────────────────────────┘
```

| Component | Spec | Source |
|---|---|---|
| Title | `ui.unlock.title` | strings |
| Hero reveal | the hero's portrait lifts from silhouette to colour over ~1.5 s with a soft glow (ASSET-038); no flashing over 3 Hz | Hero progression V/A |
| Name | the hero's `name` Text (hero_name field, 44 px heading) | 005h |
| Map stub line | `ui.unlock.map_stub` (label) | strings |
| Button | **one** button: `ui.btn.to_map`, ≥ 72 pt, release-inside. There's no "Chơi lại / Play again"; replaying starts from the title (leader's call) | P-01 |

## 6. States & Variants

| State | Behaviour |
|---|---|
| A hero opened this run | This screen |
| Replay (nothing new opened) | Skipped; results → title |
| `next_hero` null (Trần Quốc Toản today) | Skipped; results show `ui.results.more_heroes` → title |

## 7. Interaction Map

The button on release inside; taps during the reveal animation are dropped (Input Rule 13).

## 12. Accessibility

The reveal is shape and colour together (silhouette → full); the name is text plus the planned VO.
Calm, with no stingers (Audio).

## 14. Acceptance Criteria

1. **GIVEN** the first completion of a hero whose next hero is playable, **WHEN** results Tiếp is
   tapped, **THEN** this screen shows the next hero's reveal and name.
2. **GIVEN** a replay, **WHEN** results finish, **THEN** this screen does not show.
3. **GIVEN** Trần Quốc Toản (next_hero null), **WHEN** results finish, **THEN** the more-heroes line
   shows and the game returns to the title.
4. **GIVEN** the reveal, **WHEN** frame-stepped, **THEN** it lasts ≤ 3 s with nothing over 3 Hz.
5. **GIVEN** the narrowest supported phone and a 20:9 phone, **WHEN** captured in VI and EN, **THEN** the name and title fit their boxes and the button is ≥ 72 pt.
