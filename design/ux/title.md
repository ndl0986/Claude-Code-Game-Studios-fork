# UX Spec: Title Screen (the slice's "map")

> **Status**: In Review · Task: TASK-021 · Author: game-art-content
> **Template**: UX Spec
> **Platform Target**: Android + iOS phones, landscape, touch only (`project.yaml` goal mobile; no gamepad or keyboard). Accessibility tier: Basic+ (`design/accessibility-requirements.md`).
> **Records what's built**, plus the **hero card (D-27: A, Luan 2026-11-14; both apps build it in
> r6)** and one **PENDING** variant waiting for Luan (D-20).
> Sources: Mission flow Rule 1 ("the map" = the title in the slice), P-04, Hero progression
> Rules 2–5 and 10, Map & timeline (the later home), Language Rule 3, QC G5.

## 1. Purpose & Player Need

The child starts or replays the hero's mission from here, and sets the language. Until the map
exists, this is home.

## 2. Player Context on Arrival

- First launch: nothing played yet.
- After a mission: back from results or unlock (Mission flow States).
- After pause → "Về bản đồ".

## 3. Navigation Position

Root. Title → mission (intro) → … → results → (unlock) → title.

## 4. Entry & Exit Points

| Entry | Exit |
|---|---|
| App launch; results; unlock; pause "Về bản đồ / To the map" | "Bắt đầu / Start" → `gate_check` → intro |

## 5. Layout Specification

### 5.1 ASCII Wireframe

```
┌──────────────────────────────────────────────────────────────────┐
│ [🔊]                                                  [VI | EN]  │
│                                                                  │
│                  DẢI ĐẤT ANH HÙNG  (ui.app.title)                │
│                                                                  │
│      ┌────────────── hero card (D-27) ──────────────┐            │
│      │ (portrait)  Trần Quốc Toản                     │            │
│      │  in frame   ★ ★ ☆    🏅(gold / outline)        │            │
│      └──────────────────────────────────────────────┘            │
│                                                                  │
│                      [   Bắt đầu / Start   ]                     │
│                 (Bản đồ sắp ra mắt / Map coming soon)            │
└──────────────────────────────────────────────────────────────────┘
```

### 5.2 Layout Zones and 5.3 Component Inventory

| Component | Size / field | Source |
|---|---|---|
| Title | heading; text layer, never in art | `ui.app.title` |
| Start button | ≥ 72 pt, release-inside | `ui.btn.start`; P-01 |
| VI \| EN chip | ≥ 72 pt; the active language bold plus underline | Language Rules 2, 4; ASSET-031 |
| Sound | ≥ 72 pt | Audio Rule 14 |
| Map stub line | label ≥ 28 px | `ui.unlock.map_stub` |
| ~~Controls legend~~ | **Removed.** The slice title shows the map-stub line, not a controls legend; the first-use hint hands teach the controls in play (Hints GDD; leader's call) | — |
| **Hero card (D-27: A)** | See §5.5. The hero's portrait, name, best stars (filled vs outline) and medal (gold vs outline), **reusing the results-screen pieces** (ASSET-022/023 stars, ASSET-036/037 medal). Display only in the slice: it is not a button | D-27; Hero progression Rule 10; QC G5 |
| Debug only | `ui.debug.*` subtitle "Bản chơi thử / Test build" | TASK-005c |

### 5.4 Information Hierarchy

Start → the hero card → title → language and sound.

### 5.5 The hero card (D-27: A)

Positions are world px in the 1280×720 world, drawn at `k_px` (Input F1); the corner buttons are
≥ `pad_min` (137 world px on the Android reference phone, k 0.527).

| Part | Spec |
|---|---|
| Place | Centred on x = 640, **x 260–1020, y 175–355** (760 × 180: 20 + portrait 140 + 20 + name box 560 + 20). It sits below the title row (y 18–155, between the sound button top-left and the VI\|EN chip top-right) and above Start, so it never touches the sound button, the chip or Start. It stays clear of the corner blocks at every supported k (k ≥ 0.32, `design/ux/hud.md` §3.3): the sound block is ≈ x 18–155, y 18–155 at k 0.527 and grows to ≈ 18–243 at k 0.32, which still ends left of x 260 |
| Plate | Cream panel `#FFF6E3`, a thin bronze-drum ring border (the story frame motif, one motif only), rounded corners, ink outline |
| Portrait | The hero's neutral portrait (`pic.portrait_<hero_id>_hero`, ASSET-327) at 140 × 140 in a **round drum-ring frame**, the same frame as the map's open pin (Map Rule 3), left side of the card, 20 from the edge |
| Name | The hero's `name` Text, `hero_name` field (box 560, 44 px heading, 1 line), right of the portrait, top row |
| Best stars | Three stars at 48 px under the name, filled (ASSET-022) up to the saved best (`stars.<hero_id>`), outline (ASSET-023) for the rest. No "best" label: on the title, the stars are always the best |
| Medal | 56 px right of the stars: gold (ASSET-036) if `medal.<hero_id>`, else outline (ASSET-037). No text line (the results screen carries `ui.medal.*`) |
| Tap | **None in the slice.** Start is the one action. A tap on the card does nothing and plays no tone; it shows no pressed state. *When the map ships, the same pieces become the timeline card (Map Rule 5), which is tappable and ≥ `pad_min` tall* |
| Motion | None. No pulse, no flashing (Start is the thing that pulses, if anything) |
| Which hero | The **current** hero: the last open hero in `timeline_order` (Hero progression F1). The slice has one, Trần Quốc Toản |

**What it shows when:**

| Situation | Card |
|---|---|
| Before the first play (fresh install, or no quiz finished yet) | Portrait and name in full colour (the hero is open), **3 outline stars** and an **outline medal**. No "new" badge, no text: outlines mean "not yet" |
| After a finish | The best stars filled, the rest outline; the medal gold if it was ever earned (never lost) |
| A replay that scores lower | Unchanged: the card shows the saved best |
| Release build with no playable hero | **No card** (and no Start); the more-heroes line shows (State table) |
| Language switched | Only the name changes; the pieces are pictures |

Data: Hero progression (open state, `stars`, `medal`), read when the title loads; the title
writes nothing for the card (`seen_open` is written by Hero progression Rule 5 as before).

## 6. States & Variants

| State | What shows |
|---|---|
| Fresh install | Start; the hero card with 3 outline stars and an outline medal (§5.5) |
| After completing | The hero card shows the best stars and the medal (§5.5). *NOT YET BUILT: both apps, r6 (fixes QC G5)* |
| Release build, no playable hero (claims pending) | Title, "Còn nhiều anh hùng nữa sắp đến / More heroes are coming" (`ui.results.more_heroes`); Start hidden |
| **PENDING D-20:** first launch | A picture-only language picker (lotus = Tiếng Việt, book = English) before this screen |
| Loading (audio preload not done) | Every button (Start, VI\|EN, sound) drawn **disabled** at 50% alpha; taps do nothing and play nothing. They enable together when the preload ends (Audio Rule 7; TASK-020 W19). Android's Start already does this |
| Phone held in portrait (any screen) | A picture-only "turn the phone" screen: a phone outline rotating to landscape, no words needed; it clears as soon as the phone is landscape. The game is landscape only (concept, decided; TASK-020 A11). Android draws it today (`Renderer.rotate`) |

## 7. Interaction Map

- Start: on release inside → Mission flow `gate_check`.
- VI|EN: on release → the language switches at once (Language Rule 4); saved.
- Sound: on release → toggle; saved.
- Each menu press gives one tone (O6). Taps during a screen transition are dropped (Input Rule 13).

## 8. Data Requirements

`lang`, `sound`; per hero: playable, open, completed, best stars, medal (Save; Hero progression).

## 9. Events Fired

"map loaded" (Hero progression Rule 5: write `seen_open`), "start mission".

## 10. Transitions & Animations

From results or unlock: a 1.5 s crossfade (Audio music crossfade). No flashing.

## 11. Input Method Completeness Checklist

Touch only; every control ≥ 72 pt; release-inside; debounced.

## 12. Accessibility

Per `design/accessibility-requirements.md`: shapes for stars and medal; text layers; sizes.

## 13. Localization Considerations

The title and every label are VI/EN text layers within the `ui` and `button` budgets (R8, R8c).

## 14. Acceptance Criteria

1. **GIVEN** a fresh install, **WHEN** the title shows, **THEN** everything is in VI, and Start begins
   the intro.
2. **GIVEN** the chip tapped, **WHEN** released inside, **THEN** all text switches to EN at once and
   stays EN after a relaunch.
3. **GIVEN** a release build with all claims pending, **WHEN** the title shows, **THEN** there's no
   Start and the more-heroes line shows, with no error.
4. **GIVEN** the hero completed with 2★ and no medal, **WHEN** the title shows,
   **THEN** the card shows 2 filled and 1 outline star and an outline medal.
4b. **GIVEN** a fresh install, **WHEN** the title shows, **THEN** the card shows the portrait and name
   in full colour, 3 outline stars and an outline medal, and no text badge.
4c. **GIVEN** a best of 3★ with the medal, **WHEN** the hero is replayed for 1★ and the title shows
   again, **THEN** the card still shows 3 filled stars and the gold medal.
4d. **GIVEN** the Android reference phone (k 0.527) and the iOS reference phone (k 0.517), with sound and
   the chip at `pad_min`, **WHEN** the title is captured in VI and EN, **THEN** the card (y 175–355) overlaps
   neither the sound button, the chip, the title text nor Start, and the name fits on 1 line.
4e. **GIVEN** the card, **WHEN** it is tapped, **THEN** nothing happens and no tone plays.
5. **GIVEN** the lowest target Android phone, **WHEN** the app launches, **THEN** the title is interactive within 2 s (after the SFX preload, Audio Rule 7).
6. **GIVEN** the narrowest supported phone and a 20:9 phone, **WHEN** captured in VI and EN, **THEN** no element overlaps and all text fits (R8c).
7. **GIVEN** a fresh launch, **WHEN** the title shows before the audio preload ends, **THEN** every button is drawn disabled and a tap does nothing; when the preload ends they all enable.
8. **GIVEN** the phone turned to portrait on any screen, **WHEN** captured, **THEN** the turn-the-phone picture shows and nothing else responds; turning back to landscape restores the same screen and state.

## 15. Open Questions

| # | Question | Owner |
|---|---|---|
| D-20 | First-launch language picker? | Luan |
