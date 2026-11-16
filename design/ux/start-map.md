# UX Spec: Start Map (hero hometowns)

> **Status**: In Review · Task: TASK-021 · Author: game-art-content
> **Template**: UX Spec
> **Platform Target**: Android + iOS phones, landscape, touch only (`project.yaml` goal mobile; no gamepad or keyboard). Accessibility tier: Basic+ (`design/accessibility-requirements.md`).
> **Replaces** `design/ux/title.md` **after the vertical-slice gate** (D-36 d). Until then the slice
> keeps the title with the D-27 hero card; nothing here is built yet.
> Sources: D-36 (Luan, 2026-11-16) with sub-answers a–d on recommendation; Map & Hometowns GDD
> (`design/gdd/map-and-timeline.md`, the rules this spec lays out); Hero progression Rules 4–7, 10,
> F1, F2; Mission flow Rule 1; Language Rules 3, 6; Input Rules 1, 3, 13, 16, F1; D-28.

## 1. Purpose & Player Need

The child arrives wanting to **pick a hero to play**, and sees where in Vietnam each hero comes
from and which medals they've earned. One tap on a place shows its heroes; one tap on a hero
starts the story.

## 2. Player Context on Arrival

- **First launch:** nothing played; the first hero's place is already selected and the hint hand
  points at its row.
- **After a mission:** back from results or unlock (Mission flow States), usually having just
  earned stars, maybe a medal, maybe a new hero somewhere else on the map.
- **After pause → "Về bản đồ / To the map"**, mid-mission.

## 3. Navigation Position

Root. Start map → mission (intro) → … → results → (unlock) → start map.

## 4. Entry & Exit Points

| Entry | Exit |
|---|---|
| App launch (after the D-20 picker, if accepted); results; unlock; pause "Về bản đồ / To the map" | An open or completed hero row → Mission flow `gate_check` → intro |

## 5. Layout Specification

### 5.1 ASCII Wireframe

```
┌───────────────────────────────────────────────────────────────────────────┐
│[🔊]  ┌──────────── map box x 214–724 ────────────┐               [VI | EN] │
│      │   ·NW Vietnam                 [🏅 Huy hiệu 1/1]  ┌ column x 744–1262 ┐│
│      │     (●) Tức Mặc ◄selected                  │     │ Tức Mặc, Thiên Trường││
│      │      ╲                                     │     │ Quê gốc họ Trần, nay ││
│      │       ╲            · Hoàng Sa              │     │ thuộc Ninh Bình      ││
│      │        ╲                                   │     ├──────────────────────┤│
│      │   (🔒) …                                   │     │(◯) Trần Quốc Toản    ││
│      │                                            │     │ ▶  Cậu bé thời Trần… ││
│      │                     · Trường Sa            │     │    ☆☆☆  ○            ││
│      │   (◯) …                                    │     ├──────────────────────┤│
│      └────────────────────────────────────────────┘     │ (next row, scrolls)  ││
└───────────────────────────────────────────────────────────────────────────┘
```

### 5.2 Layout Zones and Component Inventory

Boxes are world px in the 1280×720 world fitted in the safe rect (Input Rule 1, `safe_bottom` 720),
drawn at `k_px` (Input F1). `P = pad_min / k`: **139.3** on the iOS QC phone (k 0.517), **≈ 147.5** on
the Android AVDs (k ≈ 0.488), **180** at the supported floor k 0.40 (`design/ux/hud.md` §3.3). The
k 0.527 geometry example is not used here.

| Component | Box (world px) | Size / field | Source |
|---|---|---|---|
| Sound | top-left: x 18–18 + P, y 18–18 + P (≤ 198 at the floor) | ≥ `pad_min`; same as every screen | Audio Rule 14; Input Rule 3 |
| (no pause) | — | nothing to pause on this screen | leader's call, TASK-021 |
| VI \| EN chip | top-right: height P, width ≤ 1.6 × height, right edge 1262, y 18–18 + P | the active language bold plus underline | Language Rules 2, 4; ASSET-031 |
| **Map box** | **x 214–724, y 20–700** (510 × 680). Left edge = floor sound block right (198) + 16 | the map art fitted keeping its aspect (≈ 510 × 537, centred near y 92–628 ⟨until the map art, D-28b⟩) | GDD Rule 1 |
| **Medal total** | **x 470–724, y 100–150**, in the map's empty north-east sea corner: medal icon 44 × 44 at x 470–514 (ASSET-036, gold) + text x 522–724 | `ui.map.medals` "Huy hiệu {n}/{total} / Medals {n}/{total}", field `ui`, 28 px weight 800, 1 line in 202 | GDD F4 |
| **Pins** | at `place.map` (GDD F1), diameter `pin_world = P` (139–180); clamped so the whole pin is inside the map box | §5.6 | GDD Rule 3, F2 |
| **Pin labels** | under the pin, centred, box ≤ 240 wide, 1 line; clamped inside the map box; never over the sound block or the medal total | place `name`, field `place` at 28 px weight 800 (a cluster: first name + "+N") | GDD F2 |
| **Hero list column** | **x 744–1262**, top = chip bottom + 16 (≈ 173.3 iOS QC, ≈ 181.5 AVD, 214 floor), bottom 720 | the only scroll area on the screen (vertical) | GDD Rule 5 |
| Place header | column width, padding 12: name x 756–1250, 40 tall; `about` 1–2 lines of 36 | name field `place` 30 px weight 800 (1 line, 494); `about` field `place_about` 28 px weight 600 (≤ 2 lines, 494). Height 92 (1 about line) or 128 (2) | GDD Rule 5 |
| Hero rows | below the header + 8; each **x 744–1262 × 180**, 8 apart | §5.5 | GDD Rules 5, 6 |
| More-heroes line | in the column at its top, when no hero is playable | `ui.results.more_heroes`, body 37 px | GDD Edge Cases |

**Fit at each k (column):** header 128 at most, so the first row starts at ≈ 173.3 + 136 = 309.3
(iOS QC), ≈ 317.5 (AVD), 350 (floor); rows of 180 (8 apart) show ≈ 2.2 / 2.1 / 2.0 rows before scrolling.
The map box and the column don't depend on k; only the sound block, the chip and the column's
top do.

### 5.3 Information Hierarchy

The selected place's hero rows (current row first in view) → the map pins → the medal total →
language and sound.

### 5.4 The place header

- Line 1: the place `name` ("Tức Mặc, Thiên Trường").
- Line 2: the place `about` (what the place is today and, if needed, what it is to the hero):
  "Quê gốc họ Trần, nay thuộc Ninh Bình / Home of the Trần family, today in Ninh Bình". Never
  "nơi sinh / birthplace" unless a signed claim records the birthplace.
- A cluster selection shows one header per place, each followed by its rows (groups ordered by
  their earliest hero).
- Display only: no tap.

### 5.5 The hero row

Row box x 744–1262, 180 tall (≥ `pad_min / k` at every k ≥ 0.40). Offsets are from the row's
top-left.

| Part | Box | Spec |
|---|---|---|
| Portrait | x +12–108, y +12–108 (96 × 96) | `pic.portrait_<hero_id>_hero` in its state frame (§6 table); slice art: `…_hero_determined` (ASSET-327) |
| State badge | x +36–84, y +120–168 (48 × 48) | **play triangle** (open, completed) or **padlock** (locked) |
| Name | x +120–506, y +8–60 | `hero.name`, field `hero_name`, **44 px** weight 800 (heading minimum, Language Rule 6), 1 line in 386 |
| Blurb | x +120–506, y +62–134 | `hero.blurb`, field `blurb`, **28 px** weight 600 (label minimum), ≤ 2 lines in 386 |
| Stars and medal | y +140–176: 3 stars 32 × 32 at x +120, +160, +200; medal 36 × 36 at x +248 | filled (ASSET-022) up to the best, outline (ASSET-023) for the rest; medal gold (ASSET-036) or outline (ASSET-037). Hidden on a locked row |
| Current marker | the row's outline | a **6 px ink border with a notch** on the left edge pointing at the map |
| Tap | the whole row | release-inside; a touch moving > `drag_threshold` (~10 pt) is a scroll, never a tap |

### 5.6 Pins and labels

- **Face and state** (GDD Rule 3): portrait in a round drum-ring frame (open, pulsing), gold ring
  with a star (completed), silhouette with a padlock (locked).
- **Count badge:** top-right of the pin, a people icon plus a text-layer number (`ui` field, 28 px),
  when the place (or cluster) has more than one playable hero.
- **Selected:** a larger ring (+12 px) and a pointer triangle on the pin's right side, toward the
  column.
- **Clusters and labels:** exactly GDD F2 (walk order, merge, label shift by `label_offset`, then
  hide by priority selected > open > completed > locked; the selected label never hides).

## 6. States & Variants

| State | What shows |
|---|---|
| Fresh install | The first hero's hometown selected; its row open with 3 outline stars, outline medal and the notched border; the hint hand on that row (Hints Rule 4); total "Huy hiệu 0/N" |
| After completing | The row's best stars and medal; the total updated; selection per GDD Rule 7 |
| Several heroes in a place | One header, rows earliest first; the column scrolls if they overflow |
| A cluster selected | One header per place, each with its rows |
| Release build, no playable hero (claims pending) | The outline only, no pins, no total; the column shows the more-heroes line |
| **PENDING D-20:** first launch | The picture-only language picker before this screen |
| Loading (audio preload not done) | Every button and row drawn **disabled** at 50% alpha; taps do nothing and play nothing; they enable together when the preload ends (Audio Rule 7) |
| Phone held in portrait | The picture-only "turn the phone" screen, as on every screen (`title.md` §6) |

**Row states** (GDD Rule 6):

| Row state | Frame | Badge | Stars/medal | Tap |
|---|---|---|---|---|
| locked | silhouette + padlock, muted | padlock | hidden | wobble + arrow toward the current hero's pin; no start |
| open | round drum ring, gentle pulse | play triangle | 3 outline + outline medal | `gate_check` |
| completed | gold drum ring | play triangle | best stars, medal gold/outline | `gate_check` (replay) |
| + current | the state above plus the notched 6 px ink border | — | — | — |

**Current hero** = the last open hero in `timeline_order`, open by Hero progression F1 (the same
definition as `title.md` §5.5).

## 7. Interaction Map

- **Pin** (or cluster): on release inside → select that place (column crossfade 0.2 s); never
  starts a mission. One soft tap tone.
- **Row**, open or completed: on release inside → Mission flow `gate_check`. One menu tone.
- **Row**, locked: on release inside → wobble (debounced) + arrow toward the current pin. Soft tone.
- **Column drag** > `drag_threshold`: scrolls vertically; never taps.
- **VI|EN**: on release → the language switches at once (Language Rule 4); saved.
- **Sound**: on release → toggle; saved.
- Taps during a transition or the arrival animation are dropped (Input Rule 13).

## 8. Data Requirements

| Data | Source / owner | Update | If missing |
|---|---|---|---|
| Per hero: playable, open, completed, best stars, medal | Hero progression (F1), Save | on screen load | hidden hero → no row |
| Current hero | Hero progression F1 (last open in `timeline_order`) | on load | none current → latest completed hero's place (GDD Rule 7) |
| Medal total | Hero progression F2 | on load; counts up on arrival | N_playable 0 → not shown |
| Places: `name`, `about`, `map`, `region` | `places.json` (proposed schema MINOR) | static | validation error (never ships) |
| `hero.hometown`, `hero.blurb`, `hero.name`, portraits | hero `mission.json` (proposed) | static | validation error |
| `lang`, `sound` | Save | on change | defaults VI, on |

The screen writes nothing except `seen_open` through Hero progression Rule 5.

## 9. Events Fired

"map loaded" (Hero progression Rule 5: write `seen_open`); "place selected" (none persisted);
"start mission" (row tap); "first map view" and "row tapped" (to Hints, Rule 4).

## 10. Transitions & Animations

- From results or unlock: a 1.5 s crossfade (Audio music crossfade), then the arrival sequence
  (GDD Rule 9): stars and medal settle on the row, the total counts up, any unlock reveal on
  another place's pin, then the column crossfade to that place. All ≤ 3 s, nothing faster than
  3 Hz.
- Selecting a place: the column crossfades in 0.2 s; the selected pin's ring grows over 0.2 s.
- Auto-scroll to the current row: ≤ 0.4 s, ease-out.

## 11. Input Method Completeness Checklist

Touch only. Every control ≥ `pad_min`; release-inside; debounced; tap vs drag by `drag_threshold`;
no pinch or zoom; the column is the only scroll.

## 12. Accessibility

Per `design/accessibility-requirements.md` (Basic+):
- every state by **shape**: padlock / round ring / gold ring with star / notched border / larger
  ring with pointer; stars filled vs outline; medal gold vs outline;
- all text is a VI/EN text layer at or above the minimum sizes (heading 44, label 28; Language
  Rule 6), ink on the cream plate (contrast per the hud.md table);
- the pin pulse and arrival animations stay under 3 Hz; no flashing.

## 13. Localization Considerations

New fields for `rules.json` (with the schema MINOR), measured by the R8c fit check:

| Field | Class | Size | Box | Lines |
|---|---|---|---|---|
| `place` (header name) | label | 30 px, weight 800 | 494 | 1 |
| `place_about` | label | 28 px, weight 600 | 494 | 2 |
| `hero_name` (row) | heading | 44 px, weight 800 | 386 | 1 |
| `blurb` | label | 28 px, weight 600 | 386 | 2 |
| `ui` (the medal total, badges) | label | 28 px, weight 800 | 202 | 1 |

Measured with today's metrics (allowance 0.03): "Trần Quốc Toản" at 44 px ≈ 334 of 375 usable;
the TQT blurb wraps to 2 lines in VI and EN; every candidate place header fits 1 + ≤ 2 lines.
The pin label (field `place`, 28 px) is 1 line in ≤ 240; a longer name hides by F2 priority and
shows in the column header instead.

## 14. Acceptance Criteria

1. **GIVEN** the Android AVD (k ≈ 0.488), the iOS QC phone (k 0.517) and a k 0.40 emulator,
   **WHEN** the start map is captured in VI and EN, **THEN** sound is at x 18–18 + P, y 18–18 + P;
   the map art sits inside x 214–724, y 20–700; the medal total is inside x 470–724, y 100–150;
   the column is x 744–1262 from the chip's bottom + 16 to y 720; and no two of sound, chip, map
   art, total, pins, labels, header and rows overlap (labels and pins clamped in the map box).
2. **GIVEN** a fresh install, **WHEN** the start map shows, **THEN** the first hero's place is
   selected, its row is open with 3 outline stars, an outline medal and the notched border, the
   total reads 0/N, and the hint hand is on that row until a row is tapped.
3. **GIVEN** the fixture place with three heroes (10, 20, 30), **WHEN** its pin is tapped, **THEN**
   the header names the place and the rows read 10, 20, 30 top to bottom; at k 0.40 the column
   scrolls to show the third row, and a 15 pt drag scrolls without starting a mission.
4. **GIVEN** a locked row, **WHEN** tapped, **THEN** it wobbles, the arrow points at the current
   hero's pin and no mission starts; **GIVEN** an open row, **WHEN** tapped, **THEN** the intro starts.
5. **GIVEN** a completed hero with 2★ and no medal, **WHEN** the start map shows, **THEN** its row
   has the gold ring, 2 filled and 1 outline star and an outline medal.
6. **GIVEN** a return from results that improved stars and earned the medal, **WHEN** the map
   shows, **THEN** the row's stars and medal settle, the total counts up by 1, and it all ends
   within 3 s with no flashing over 3 Hz.
7. **GIVEN** a return from results that unlocked a hero in another place, **WHEN** the map shows,
   **THEN** that pin plays the unlock reveal and the column then shows that place with the new
   hero's row current.
8. **GIVEN** a release build with all claims pending, **WHEN** the map shows, **THEN** the outline
   shows with no pins and no total, and the column shows the more-heroes line, with no error.
9. **GIVEN** the cluster fixture at k 0.488, **WHEN** the cluster pin is tapped, **THEN** the
   column shows one header per place, each followed by its rows, ordered by earliest hero.
10. **GIVEN** greyscale and colour-blind captures, **WHEN** compared, **THEN** locked, open,
    completed, current and selected are told apart by shape alone.
11. **GIVEN** VI and EN captures, **WHEN** checked, **THEN** every text sits in its box (§13) at or
    above its minimum size, and the place about line for Trần Quốc Toản reads "Quê gốc họ Trần, nay
    thuộc Ninh Bình / Home of the Trần family, today in Ninh Bình" (while candidate A is used), with
    no "nơi sinh / birthplace".
12. **GIVEN** a fresh launch before the audio preload ends, **WHEN** the map shows, **THEN** every
    button and row is disabled and a tap does nothing; when the preload ends they all enable.
13. **GIVEN** the lowest target Android phone, **WHEN** the app launches, **THEN** the start map is
    interactive within 2 s (after the SFX preload, Audio Rule 7).
14. **GIVEN** the phone turned to portrait, **WHEN** captured, **THEN** the turn-the-phone picture
    shows; turning back restores the same selection and scroll position.

## 15. Open Questions

| # | Question | Owner |
|---|---|---|
| D-36 a | Trần Quốc Toản's hometown (A recommended; B, C, D) and the "quê gốc" wording | Luan |
| — | TQT blurb wording (pending) | Luan |
| — | No app-title row on the map (default) | Luan (leader asking) |
| D-28b | The official map to trace | Luan |
| D-20 | First-launch language picker | Luan |
| — | Final medal-total box and pin coordinates once the map art exists | game-art-content |
| — | New assets: count-badge people icon, selected-pin pointer ring, play-triangle and padlock badges (`/asset-spec`) | game-art-content |
