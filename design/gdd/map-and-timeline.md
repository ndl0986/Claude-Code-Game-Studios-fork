# Map & Timeline

> **Status**: In Review
> **Author**: game-art-content (Luan decides)
> **Last Updated**: 2026-11-14
> **Last Verified**: 2026-11-14
> **Implements Pillar**: Học mà vui (Learn by playing), Đúng sự thật (True to history), Nhỏ chơi được (Small hands can do it)
> **Task**: TASK-018 · Tier: standard (Player Fantasy and Tuning Knobs skipped by tier)

## Summary

The home screen is a map of today's Vietnam with a timeline strip below it. Each hero appears
as a pin at the place their story happened. Locked heroes are silhouettes, open heroes glow,
and completed heroes show their best stars and medal. Heroes sit on the timeline in the order
they lived. Tapping an open hero starts the mission. The map only **shows** progress; Hero
progression decides what is open.

> **Quick reference** — Layer: `Feature` · Priority: `Alpha` (a minimal stub in the vertical slice, D-27) · Key deps: `Hero progression & unlock, Content data & claims, Save & progress, Language & text`

## Overview

The concept's long-term loop is "the map of Vietnam fills region by region". This system is
that map. It shows where each hero's story happened (geography) and when they lived (the
timeline).

- **What it owns:** the home screen's layout, the pin and timeline-card states, the region glow,
  and the tap that starts a mission.
- **What it does not own:** which heroes are open (Hero progression), stars and medals (Quiz,
  Save), or place names (content claims).
- **QC G5:** the slice's title screen showed no progress after a finished mission. This GDD's
  completed state, with stars and medal, fixes that. Until the map is built, D-27 proposes a
  stub on the slice title.

## Detailed Design

### Core Rules

1. **Home screen.** The map replaces the slice title as "the map" in Mission flow. Landscape
   layout:
   - the whole country fits on screen, with **no pinch and no scroll**, because a 6-year-old
     shouldn't have to navigate a map;
   - the map sits left of centre (Vietnam is tall and narrow);
   - the timeline strip runs along the bottom;
   - pause, sound and the VI|EN chip are top-right.
2. **The map shows modern Vietnam** (D-28).
   - The outline is traced from an **authoritative source** (an official administrative map;
     Luan names it).
   - It **includes the Hoàng Sa and Trường Sa archipelagos**, as maps published in Vietnam must.
   - **Historical borders are never drawn.** Đại Việt in the 13th century was smaller; drawing
     era borders would be a history claim of its own.
   - Each hero's place is shown at its **modern location** with a label such as "Bình Than (nay
     thuộc Bắc Ninh) / Bình Than (today in Bắc Ninh)". The modern location is a pending claim
     in the hero's `claims.json`.
3. **Pins.** One pin per **playable** hero (Hero progression Rule 7), at `hero.map {x, y}`
   (normalised 0–1 on the map art; schema request). States:

| State | Pin shape | Colour | Shows | Tap |
|---|---|---|---|---|
| hidden (not playable) | none | — | nothing | — |
| locked | silhouette with a **padlock** shape | muted | the place name only | soft wobble, plus a hint arrow pointing to the open pin |
| open | the hero's portrait in a **round** drum-ring frame | full colour, gentle pulse | name and place | starts the mission (`gate_check`) |
| completed | the portrait in a **gold** drum-ring frame | full colour | name, place, **best stars** (filled vs outline) and the **medal** (gold vs outline) | starts the mission (a replay) |

   States differ by **shape** (padlock / round / gold ring with stars), never by colour alone.

4. **Region glow (decoration only).** The map has three regions: North, Central and South.
   - Each warms in tone as its heroes are completed (F3).
   - It never gates anything and is never a history claim.
   - The region of each hero comes from `hero.map` (whichever region the pin falls in).
5. **Timeline strip.**
   - Playable heroes appear as small cards in `timeline_order`, left to right, each with the
     hero's portrait, name and an **era label** (optional `hero.era` Text, e.g. "Thế kỷ XIII /
     13th century", a pending claim).
   - Cards show the same states as the pins.
   - The current open hero (the first open and not completed in timeline order) is highlighted.
   - Tapping a card works like tapping its pin.
   - With more cards than fit, the strip scrolls sideways. This is the **only** scrolling on the
     screen, and it auto-scrolls so the highlighted card is in view.
6. **Rules come from Hero progression.**
   - Open and locked are derived (Hero progression Rule 4); the map never computes or stores
     unlocks.
   - Every map load writes `seen_open` for every open hero (Hero progression Rule 5; Save).
   - Stars and the medal are read from Save.
7. **Arrival after a mission.** Returning from results:
   - The just-finished pin plays its stars and medal settling in (if improved).
   - If a hero was just unlocked, its pin plays the unlock reveal (Hero progression Rule 10).
   - The highlight moves to the new current hero.
   - All of this runs under 3 s, with no flashing faster than 3 Hz.
8. **First launch.**
   - If D-20 is accepted, the language picker comes first, then the map.
   - The first time the map shows, the hint hand points at the only open pin (Hints GDD), until
     it is tapped.
9. **Text.**
   - Hero names, places and eras are VI/EN text layers (Language & text), never in the map art.
   - Labels use the `place` and `hero_name` field types (R8c).
   - Place labels may hide while two labels overlap (F2), but the pin itself always shows.
10. **No map features beyond this:** no free exploration, no zoom, no collectibles hidden on
    the map. The map is a menu with meaning (pillar *Small hands can do it*).

### States and Transitions

The screen is `loading` (progression derived, `seen_open` written) → `idle` → (`arrival` after a
mission, ≤ 3 s, then `idle`) → `starting` (pin tapped, Mission flow `gate_check`).
- Per pin: `hidden` / `locked` / `open` / `completed`, from Hero progression.
- A pin's state changes only between screen visits, plus the arrival animation.

### Interactions with Other Systems

| System | In | Out | Owner |
|---|---|---|---|
| Hero progression & unlock | per hero: hidden / locked / open / completed; just-unlocked hero | "map loaded" (triggers `seen_open` writes) | Hero progression GDD |
| Save & progress | best stars, medal | (none; writes go through progression) | Save GDD |
| Content data & claims | `hero.map`, `hero.era`, `hero.name`, `hero.place`, `timeline_order`, portraits | (none) | Content contract |
| Mission flow & beat types | "returned from results" | "start mission X" (→ `gate_check`) | Mission flow GDD |
| Language & text | current language | (none) | Language GDD |
| Hints & onboarding | (none) | "first map view", the open pin's position | Hints GDD |
| Audio & voice-over | (none) | pin tap, unlock reveal, star and medal settle | Audio GDD |

## Formulas

The F1 (pin position) formula is defined as:

`pin_px = map_origin + (x, y) × map_size`, where `map_size` is the drawn map's on-screen size (aspect preserved) and `(x, y)` is `hero.map` in 0–1.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| x, y | float | 0–1 | data file (`mission.json` `hero.map`; requested) | Place on the map art |
| map_origin | (px, px) | layout | UX spec | Top-left of the drawn map |
| map_size | (px, px) | layout | UX spec / map art aspect | Drawn map size |

**Output Range:** inside the map's rectangle. Content validation rejects x or y outside 0–1.
**Example:** Bình Than at (0.42, 0.14) on a map drawn at origin (80, 40), size 430 × 640 world px
→ pin at (260.6, 129.6) ⟨coordinates are placeholders until the map art exists⟩.

The F2 (pin spacing and labels) formula is defined as:

`if dist(pin_a, pin_b) < pin_min_gap: offset the later pin's label (not the pin) by label_offset; if labels still overlap, hide the lower-priority label`, where priority is: open > completed > locked.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| pin_size | float (pt/dp) | ≥ `pad_min` (72) | data file (`tuning.json` `pad_min`) | Pin touch target |
| pin_min_gap | float (world px) | ≥ pin_size | constant (= pin_size) | Below this, pins could be confused |
| label_offset | float (world px) | 40–80 | constant ⟨UX⟩ | How far a label moves |

**Output Range:** pins never move (they mark real places); only labels shift or hide. Two
heroes at the **same** place (e.g. two stories at Thăng Long) share one pin that opens a
two-hero picker. That's an edge case handled below.
**Example:** pins 50 px apart with `pad_min` 72 → the later pin's label shifts 60 px down; the
pins still both show.

The F3 (region glow) formula is defined as:

`glow(region) = completed_in_region / playable_in_region` (0 when the region has no playable hero); tone = lerp(base_tone, warm_tone, glow).

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| completed_in_region | int | ≥ 0 | calculated (progression + `hero.map`) | Completed heroes in the region |
| playable_in_region | int | ≥ 0 | calculated | Playable heroes in the region |

**Output Range:** 0–1. Decoration only, and never shown as a number.
**Example:** North has 2 playable heroes and 1 completed → glow 0.5, a half-warm tone.

## Edge Cases

- **If a hero has no `hero.map`** (old content): no pin. The timeline card still shows, and
  validation warns.
- **If two heroes share one place**: one pin with a small count badge (an icon, not a number
  in art). Tapping it opens a two-card picker.
- **If the strip has more heroes than fit**: it scrolls sideways (Rule 5) and auto-scrolls to the
  highlighted card. The map itself never scrolls.
- **If no hero is playable in a release build** (claims pending): the map shows the outline
  only, with a gentle "Còn nhiều anh hùng nữa sắp đến / More heroes are coming" line. No error.
- **If the child taps a locked pin repeatedly**: each tap wobbles the pin (debounced) and the
  arrow points to the current open hero. There's no other penalty.
- **If a content update adds a hero while the app is open**: impossible. Content ships in app
  updates, which restart the app.
- **If the screen is very wide or very narrow**: the map is scaled to fit its area keeping its
  aspect ratio, and the strip takes the rest. It is tested on the narrowest supported phone.

## Dependencies

| System | Direction | Hard/Soft | Interface |
|---|---|---|---|
| Hero progression & unlock | this depends on it | Hard | Per-hero state, just-unlocked hero |
| Save & progress | this depends on it | Hard | Best stars, medal |
| Content data & claims | this depends on it | Hard | `hero.map`, `hero.era`, names, portraits, `timeline_order` |
| Language & text | this depends on it | Hard | Labels |
| Mission flow & beat types | both ways | Hard | Start mission; return from results ("the map") |
| Hints & onboarding | depends on this | Soft | First-view hand on the open pin |
| Audio & voice-over | depends on this | Soft | Map sounds |

Hero progression already lists Map & timeline as a dependent (`design/gdd/hero-progression.md`).

## Visual/Audio Requirements

- **Map art** (`/asset-spec system:map-and-timeline`):
  - modern Vietnam traced from the source Luan names (D-28), **including Hoàng Sa and Trường
    Sa**, in the art bible's map palette (§4: rice greens, river blues);
  - drum-ring motif on the frame only;
  - **no text in the art**: every name is a text layer.
- **Pins and cards** reuse the hero portraits (ASSET-327 family) in drum-ring frames, the
  padlock shape, and the stars and medal (ASSET-021–023, 036–037).
- **Region glow:** a soft warm wash, never flashing.
- **Audio:** a soft tap on the pin, the unlock reveal and the star/medal settle sounds (Audio GDD).

## UI Requirements

- Pins and cards ≥ `pad_min`; the strip's cards are large enough to read a portrait.
- 📌 **UX Flag — Map & Timeline**: the map screen needs `/ux-design`, covering layout per aspect
  ratio, label rules and the arrival sequence.

## Cross-References

| This doc references | Where | What |
|---|---|---|
| Hero progression | `design/gdd/hero-progression.md` Rules 4–7, 10 | Derived unlocks, `seen_open`, playable, results and unlock |
| Mission flow | `design/gdd/mission-flow.md` Rule 1, States | "The map", `gate_check` |
| Save & progress | `design/gdd/save-and-progress.md` Rule 1 | Stars, medal |
| Language & text | `design/gdd/language-and-text.md` Rules 3, 8 | D-20 picker, field types |
| Art bible | `design/art/art-bible.md` §2 (map mood), §4 | Map palette, states by shape |
| Systems index | `design/gdd/systems-index.md` row 11 | QC G5 |
| Decisions | `production/team/decisions.md` D-20, D-27, D-28 | Picker, slice stub, the map source |

## Acceptance Criteria

Criteria 1–6 are logic (unit tests on map state); 7–10 need QC screenshots.

1. **GIVEN** heroes A(10, completed, 2★, medal) and B(20, open), **WHEN** the map loads, **THEN**
   A's pin and card show the gold ring, 2 filled and 1 outline stars, and the gold medal; B's
   pin is round and pulsing; B's card is highlighted.
2. **GIVEN** a hero hidden by the claim gate in a release build, **WHEN** the map loads, **THEN**
   it has no pin and no card.
3. **GIVEN** any map load, **WHEN** it finishes, **THEN** `seen_open` is written for every open
   hero (Hero progression AC12).
4. **GIVEN** a locked pin, **WHEN** tapped, **THEN** no mission starts and the hint arrow points to
   the current open hero.
5. **GIVEN** `hero.map` outside 0–1, **WHEN** content is validated, **THEN** validation fails.
6. **GIVEN** a region with 2 playable heroes and 1 completed, **WHEN** the map renders, **THEN**
   its glow is 0.5 (F3).
7. **GIVEN** the map, **WHEN** captured, **THEN** the outline matches the named source and
   **shows Hoàng Sa and Trường Sa**, and no historical border is drawn (content reviewer
   sign-off, D-28).
8. **GIVEN** the map in VI and EN, **WHEN** captured, **THEN** all names are text layers within
   their boxes (R8c), and the map art contains no letters.
9. **GIVEN** the return from a results screen that unlocked a hero, **WHEN** the map shows,
   **THEN** the reveal and the highlight move finish within 3 s, with no flashing over 3 Hz.
10. **GIVEN** the greyscale and colour-blind simulations, **WHEN** captured, **THEN** locked, open
    and completed are still distinguishable by shape.

## Open Questions

| # | Question | Owner | By |
|---|---|---|---|
| D-27 | Slice stub: show the hero card with best stars and the medal on the slice title until the map exists (QC G5)? Recommended: yes | Luan | Now |
| D-28 | The map source: which official administrative map to trace (with Hoàng Sa and Trường Sa)? | Luan | Before the map art |
| — | Schema request: `hero.map {x, y}` (0–1), optional `hero.era` Text; validation x, y in 0–1; a claim for each modern-location label | game-dev-ios + game-dev-android, game-art-content | After this GDD's review |
| — | Two heroes at one place: the picker design | game-art-content + ux | `/ux-design` |
