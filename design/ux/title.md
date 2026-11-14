# UX Spec: Title Screen (the slice's "map")

> **Status**: In Review · Task: TASK-021 · Author: game-art-content
> **Template**: UX Spec
> **Platform Target**: Android + iOS phones, landscape, touch only (`project.yaml` goal mobile; no gamepad or keyboard). Accessibility tier: Basic+ (`design/accessibility-requirements.md`).
> **Records what's built**, plus two **PENDING** variants waiting for Luan (D-27, D-20).
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
│      ┌──────────────── PENDING D-27 ────────────────┐            │
│      │ [portrait] Trần Quốc Toản   ★★☆   🏅(outline) │            │
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
| **PENDING D-27: progress card** | hero portrait, name, best stars (filled vs outline), medal (gold vs outline) | Hero progression Rule 10; QC G5 |
| Debug only | `ui.debug.*` subtitle "Bản chơi thử / Test build" | TASK-005c |

### 5.4 Information Hierarchy

Start → (the progress card) → title → language and sound.

## 6. States & Variants

| State | What shows |
|---|---|
| Fresh install | Start (the card, if D-27, shows the hero open with outline stars and medal) |
| After completing | (D-27) Best stars and medal on the card. **Today, without D-27: no progress shows (QC G5, open).** |
| Release build, no playable hero (claims pending) | Title, "Còn nhiều anh hùng nữa sắp đến / More heroes are coming" (`ui.results.more_heroes`); Start hidden |
| **PENDING D-20:** first launch | A picture-only language picker (lotus = Tiếng Việt, book = English) before this screen |

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
4. **GIVEN** D-27 accepted and the hero completed with 2★ and no medal, **WHEN** the title shows,
   **THEN** the card shows 2 filled and 1 outline star and an outline medal.
5. **GIVEN** the lowest target Android phone, **WHEN** the app launches, **THEN** the title is interactive within 2 s (after the SFX preload, Audio Rule 7).
6. **GIVEN** the narrowest supported phone and a 20:9 phone, **WHEN** captured in VI and EN, **THEN** no element overlaps and all text fits (R8c).

## 15. Open Questions

| # | Question | Owner |
|---|---|---|
| D-27 | Show the progress card on the title until the map exists? | Luan |
| D-20 | First-launch language picker? | Luan |
