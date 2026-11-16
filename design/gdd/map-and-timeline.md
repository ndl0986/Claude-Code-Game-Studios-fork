# Map & Hometowns

> **Status**: In Review (TASK-021, D-36 revision of the approved TASK-018 Map & Timeline)
> **Author**: game-art-content (Luan decides)
> **Last Updated**: 2026-11-16
> **Last Verified**: 2026-11-16
> **Implements Pillar**: Học mà vui (Learn by playing), Đúng sự thật (True to history), Nhỏ chơi được (Small hands can do it)
> **Task**: TASK-021 (was TASK-018) · Tier: standard (Player Fantasy and Tuning Knobs skipped by tier)
> **Build timing (D-36 d):** spec now, **build right after the vertical-slice gate**. Until then the slice
> keeps the D-27 hero card on the title (`design/ux/title.md`). Screen spec: `design/ux/start-map.md`.

## Summary

The start screen is a map of today's Vietnam. Each pin marks a **place that is a hero's hometown**.
The child taps a pin to pick that place, and the right-hand column lists the place's heroes from
top to bottom, earliest first. Each row shows the hero's portrait, name, a short description, the
best stars and the medal. Tapping an open hero's row starts the mission. A medal total sits at the
top of the map. The map only **shows** progress; Hero progression decides what is open.

> **Quick reference** — Layer: `Feature` · Priority: `Alpha` (built after the VS gate; the slice keeps the D-27 card) · Key deps: `Hero progression & unlock, Content data & claims, Save & progress, Language & text`

## Overview

The concept's long-term loop is "the map of Vietnam fills region by region". This system is
that map. D-36 (Luan, 2026-11-16) changed what a pin means: it is the hero's **hometown**, not
the place the story happened, and one place can hold several heroes.

- **What it owns:** the start screen's layout, the place pins and their states, the place's hero
  list, the medal total's placement, the region glow, and the tap that starts a mission.
- **What it does not own:** which heroes are open, which hero is current, or the medal total's
  count (Hero progression F1, F2); stars and medals (Quiz, Save); place names, hometowns and
  descriptions (content claims).
- **What changed from TASK-018:** pins are per place, not per hero; the timeline column became the
  place's hero list (D-36 b); every row shows best stars and the medal and the map shows a medal
  total (D-36 c); the map box moved right so it clears the sound block (Rule 1). `hero.place`
  (where the story happens) stays for story text, but no longer makes a pin.

## Detailed Design

### Core Rules

1. **Start screen layout.** Landscape, world px in the 1280×720 world fitted in the safe rect
   (Input Rule 1). `P = pad_min / k` (Input F1): 139.3 on the iOS QC phone (k 0.517), ≈ 147.5 on
   the Android AVDs (k ≈ 0.488), 180 at the k 0.40 floor (`design/ux/hud.md` §3.3).
   - The whole country fits on screen, with **no pinch, no zoom and no map scroll**, because a
     6-year-old shouldn't have to navigate a map.
   - **Sound** is top-left, the same position and size as on every screen (x 18–18 + P,
     y 18–18 + P). **No pause:** there is nothing to pause here (leader's call, TASK-021).
   - **The map box** is **x 214–724, y 20–700** (510 × 680). Its left edge is the floor sound
     block's right edge (198) + 16. *Why not x 40 as before:* with Hoàng Sa and Trường Sa the map
     art spans about lon 102–118 × lat 7.5–23.4, close to square, so Vietnam's north-west (Lai
     Châu, Điện Biên) sits in the box's top-left corner and would be under the sound button. The
     art is fitted keeping its aspect (≈ 510 × 537, centred near y 92–628; final numbers come with
     the map art, D-28b).
   - **The medal total** sits in the map's empty **north-east sea corner** (east of the Gulf of
     Tonkin), ref box **x 500–724, y 100–150** (F4).
   - **The VI|EN chip** is top-right, as on the title (height P, width ≤ 1.6 × height, right
     edge 1262).
   - **The hero list column** is **x 744–1262**, from the chip's bottom + 16 down to 720 (Rule 5).
   - **No app-title row** on the map (default; the leader is asking Luan). The game's name lives
     on the icon and splash.
2. **The map shows modern Vietnam** (D-28).
   - The outline is traced from an **authoritative source** (an official administrative map;
     Luan names it, D-28b).
   - It **includes the Hoàng Sa and Trường Sa archipelagos**, as maps published in Vietnam must.
   - **Historical borders are never drawn.** Đại Việt in the 13th century was smaller; drawing
     era borders would be a history claim of its own.
   - Each place is shown at its **modern location**. Its `about` line names today's province
     using the **post-2025** units (Nghị quyết 202/2025/QH15, S10), e.g. "Quê gốc họ Trần, nay
     thuộc Ninh Bình". The modern location is a pending claim.
3. **Pins are per place.** One pin per place that has **at least one playable** hero (Hero
   progression Rule 7). A hero's place is `hero.hometown.place`; the pin is at that place's
   `map {x, y}` (F1).
   - **Face:** the portrait of the place's current hero (Rule 6) if it is here; otherwise its
     earliest open or completed hero in `timeline_order`; otherwise a silhouette.
   - **State** is the best state among the place's heroes: **open > completed > locked**:

| Pin state | When | Pin shape | Colour |
|---|---|---|---|
| hidden | no playable hero has this place | none | — |
| locked | every hero here is locked | silhouette with a **padlock** shape | muted |
| open | at least one hero here is open and not completed | the portrait in a **round** drum-ring frame, gentle pulse | full colour |
| completed | every playable hero here is completed | the portrait in a **gold** drum-ring frame with a small **star** shape | full colour |

   - **Count badge:** a place with more than one playable hero shows a badge (a people icon plus a
     text-layer number, never a number in the art).
   - **Selected:** the selected place's pin gets a **larger ring and a pointer** toward the column.
   - States and selection differ by **shape** (padlock / round / gold ring with star / larger ring
     with pointer), never by colour alone.
   - **Tapping a pin selects that place** (the column changes to it). It **never starts a
     mission**. Tapping the already-selected pin does nothing more.
4. **Region glow (decoration only).** The map has three regions: North, Central and South.
   - Each warms in tone as its heroes are completed (F3).
   - It never gates anything and is never a history claim.
   - The region is **data on the place**: `place.region` (`north` | `central` | `south`), set by
     game-art-content. A hero's region is its hometown's region.
5. **The place's hero list (D-36 b).** The right column shows the **selected place's** playable
   heroes, one row each, **earliest first** (`timeline_order`, top to bottom).
   - A **place header** on top: the place's `name` (1 line) and its `about` line (1–2 lines).
   - Each **row** shows the hero's portrait, `name`, `blurb` (the short description), best stars and
     the medal (row states: Rule 6). The row is the button.
   - **One hero or many is the same UI**: one hero is a one-row list. There is no pop-up.
   - With more rows than fit, the column scrolls **vertically**. This is the **only** scrolling on
     the screen. On arrival it auto-scrolls so the current hero's row is in view.
   - **Tap vs drag:** a touch that moves more than ~10 pt (`drag_threshold`) is a drag that
     scrolls; it never starts a mission. Only a touch that stays within it, and lifts inside the
     row, is a tap.
6. **Row states and the current hero.**
   - **Current hero** = the **last open hero in `timeline_order`**, with open as defined by Hero
     progression F1. Both this GDD and the start-map spec cite F1 only (this fixes TASK-018's
     "first open and not completed", which disagreed with the title spec).

| Row state | Portrait frame | Under the portrait | Stars and medal | Tap |
|---|---|---|---|---|
| locked | silhouette + **padlock**, muted | padlock badge | hidden (the padlock says "not yet") | soft wobble + an arrow from the row toward the **current hero's pin**; no mission (tap feedback owned by this system, not a Hints hint) |
| open | **round** drum-ring frame, full colour, gentle pulse | **play-triangle** badge | 3 outline stars + outline medal | starts the mission (`gate_check`) |
| completed | **gold** drum-ring frame | play-triangle badge | best stars filled vs outline; medal gold vs outline | starts the mission (a replay) |

   - The **current** row also has a **thick ink border with a notch** pointing toward the map.
   - A locked row still shows its name and blurb: the hero is playable, so its claims are signed.
   - **No dates** and **no new save data** (D-36 c). Stars and the medal are read from Save.
7. **Selection on arrival (never an empty list).**
   - On every arrival the selected place is the **current hero's hometown**.
   - If no hero is current (all playable heroes completed), it is the hometown of the **latest
     completed hero** in `timeline_order`.
   - The selection lasts until the child taps another pin, or the screen is left.
8. **Rules come from Hero progression.**
   - Open and locked are derived (Hero progression Rule 4, F1); the map never computes or stores
     unlocks.
   - Every map load writes `seen_open` for every open hero (Hero progression Rule 5; Save).
   - Stars and the medal are read from Save.
9. **Arrival after a mission.** Returning from results:
   - The selected place is set by Rule 7 (usually the just-finished hero's place, or the newly
     opened hero's).
   - The just-finished hero's row plays its stars and medal settling in (if improved), and the
     medal total counts up (F4).
   - If a hero was just unlocked in **another place**, that place's pin plays the unlock reveal
     (Hero progression Rule 10), then the column crossfades to that place.
   - All of this runs under 3 s, with no flashing faster than 3 Hz.
10. **First launch.**
    - If D-20 is accepted, the language picker comes first, then the map.
    - The first time the map shows, the hint hand points at the **current hero's row** (the place
      is pre-selected, so one tap starts), until a row is tapped (Hints Rule 4, "map: first view").
11. **Text.**
    - Place names, `about` lines, hero names, blurbs and the medal total are VI/EN text layers
      (Language & text), never in the map art.
    - Fields: `place` (place name), `place_about`, `hero_name`, `blurb`, `ui` (the medal total),
      each with an R8c fit budget (start-map spec §13).
    - A hometown that is not a recorded birthplace says so in its `about` line. For Trần Quốc
      Toản's recommended place: **"Quê gốc họ Trần / Home of the Trần family"**, never "nơi sinh /
      birthplace" (leader's call, TASK-021).
    - Pin labels may shift or hide while two overlap (F2), but the pin itself always shows.
12. **No map features beyond this:** no free exploration, no zoom, no collectibles hidden on the
    map. The map is a menu with meaning (pillar *Small hands can do it*).

### States and Transitions

The screen is `loading` (progression derived, `seen_open` written) → `idle` (a place selected,
Rule 7) → (`arrival` after a mission, ≤ 3 s, then `idle`) → `starting` (an open or completed row
tapped, Mission flow `gate_check`).
- Per hero: `hidden` / `locked` / `open` / `completed`, from Hero progression. Per place: the pin
  state of Rule 3.
- A pin tap changes only the selection (a 0.2 s crossfade of the column).
- A hero's state changes only between screen visits, plus the arrival animation.

### Interactions with Other Systems

| System | In | Out | Owner |
|---|---|---|---|
| Hero progression & unlock | per hero: hidden / locked / open / completed; just-unlocked hero; F1 (open, so the current hero); F2 (`medals_total / N_playable`) | "map loaded" (triggers `seen_open` writes) | Hero progression GDD |
| Save & progress | best stars, medal | (none; writes go through progression) | Save GDD |
| Content data & claims | `places.json` (`name`, `about`, `map`, `region`, claims); `hero.hometown`, `hero.blurb`, `hero.name`, `timeline_order`, portraits | (none) | Content contract (proposed schema MINOR, below) |
| Mission flow & beat types | "returned from results" | "start mission X" (→ `gate_check`) | Mission flow GDD |
| Language & text | current language | (none) | Language GDD |
| Hints & onboarding | (none) | "first map view", the current row's position, row tapped | Hints GDD |
| Input & touch controls | taps and drags (Input Rule 16) | (none) | Input GDD |
| Audio & voice-over | (none) | pin tap, row tap, unlock reveal, star and medal settle | Audio GDD |

**Proposed content schema MINOR (not built; the devs review it in the PR).** It replaces the
TASK-018 proposal (`hero.map {x, y, region}`, `hero.era`), which was never built. Draft data:
`content/drafts/start-map-tqt.json`.
- New file **`content/data/places.json`**: `{schema_version, places: [{id: "place.<slug>", name:
  Text (field place), about: Text (field place_about), map: {x, y} (0–1 on the map art), region:
  north | central | south, claims: [Claim]}]}`. One coordinate per place, so heroes from the same
  place can never drift apart. Place-level claims (e.g. a place's modern location, once several
  heroes share it) live in the place's own `claims` array, with the same Claim shape as
  `claims.json` (leader's call).
- **`hero.hometown`**: `{place: "place.<slug>", claims: [ClaimId]}`. The place id is the grouping;
  the coordinates live on the place.
- **`hero.blurb`**: Text, field `blurb`, with claims.
- **Validation:** the place id exists; `map.x` and `map.y` are in 0–1; every playable hero has a
  hometown and a blurb; the claim gate (R12) covers the hometown, the place's and the blurb's
  claims, so a hero whose hometown claim is pending is hidden in a release build.
- **Nothing new is saved.** The medal total is computed (F4).

## Formulas

The F1 (pin position) formula is defined as:

`pin_px = art_origin + (x, y) × art_size`, where the map art is fitted inside the map box keeping its aspect, `art_origin` is its drawn top-left and `art_size` its drawn size, and `(x, y)` is `place.map` in 0–1.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| x, y | float | 0–1 | data file (`places.json` `map`; proposed) | Place on the map art |
| art_origin | (px, px) | layout | the map box x 214–724, y 20–700 and the art's aspect | Top-left of the drawn map |
| art_size | (px, px) | layout | the same | Drawn map size |

**Output Range:** inside the map box. Content validation rejects x or y outside 0–1.
**Example:** a place at (0.36, 0.17) on art drawn at origin (214, 92), size 510 × 537 → pin at
(214 + 0.36 × 510, 92 + 0.17 × 537) = (397.6, 183.3) ⟨coordinates are placeholders until the map
art exists⟩.

The F2 (pin size, clusters and labels) formula is defined as:

`pin_world = pad_min / k`, where k is the pt/dp per world px defined once in Input F1. Place pins whose centres are closer than `pin_world` merge into **one cluster pin** at their average position, built by this **exact procedure**, so both apps build identical clusters (pairwise closeness isn't transitive): walk the places in order of **each place's earliest playable hero** (`timeline_order`); a place joins the **first** existing cluster that has **any** member within `pin_world` of it, otherwise it starts a new cluster; each cluster's position is the average of its members. Tapping a cluster selects **all** its places: the column shows one place header per place, groups ordered by their earliest hero, each group's rows earliest first. A cluster's state and face follow Rule 3 over all its heroes, and its count badge counts all its heroes. **Labels:** each pin's label (the place name; a cluster shows its first place's name plus "+N") sits under the pin. When two labels overlap, the later one (in the walk order) shifts down by `label_offset`; if they still overlap, the lower-priority label hides (priority: **selected** > open > completed > locked). The selected place's label never hides. Labels are clamped inside the map box and never cover the sound block or the medal total.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| pad_min | float (pt/dp) | 44–120 | data file (`tuning.json` `pad_min`, 72) | Minimum touch target |
| k | float (pt/dp per world px) | device | calculated (Input F1) | Converts touch size to world px (≈ 0.488 on the Android AVDs, 0.517 on the iOS QC phone; 0.40 the floor) |
| pin_world | float (world px) | ≈ 139–180 on supported devices | calculated | Pin touch target in world px |
| label_offset | float (world px) | 40–80 | constant ⟨UX⟩ | How far a label moves |

**Output Range:** pins mark real places and never move on their own. Only clustering merges
them, and only labels shift or hide. Both apps compute clusters from the same numbers, so they
match. Northern places that sit close together (e.g. Thăng Long, Tức Mặc, Bình Than) will
almost always cluster at phone sizes.
**Example** (Android AVD, k 0.488): `pad_min` 72 gives `pin_world` ≈ 147.5. Two places 80 world px
apart merge into one cluster with a badge counting both places' heroes; tapping it shows two
place headers. A place 160 px away stays separate, and its label shifts down 60 px if it overlaps.
At k 0.40 (`pin_world` 180) a place 160 px away **merges**, so the shared fixture names k for each case.

The F3 (region glow) formula is defined as:

`glow(region) = completed_in_region / playable_in_region` (0 when the region has no playable hero); tone = lerp(base_tone, warm_tone, glow). A hero counts in its hometown's `place.region`.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| completed_in_region | int | ≥ 0 | calculated (progression + `place.region`) | Completed heroes in the region |
| playable_in_region | int | ≥ 0 | calculated | Playable heroes in the region |

**Output Range:** 0–1. Decoration only, and never shown as a number.
**Example:** North has 2 playable heroes and 1 completed → glow 0.5, a half-warm tone.

The F4 (medal total) formula is defined as:

`medal_total = medals_total / N_playable`, exactly Hero progression F2 (`medals_total = Σ medal(h)` over playable heroes). Shown as "Huy hiệu {n}/{total} / Medals {n}/{total}" (`ui.map.medals`), a text layer next to the medal icon (ASSET-036).

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| medals_total | int | 0–N_playable | calculated (Hero progression F2; Save `medal.<id>`) | Medals earned on playable heroes |
| N_playable | int | ≥ 0 | calculated (Hero progression Rule 7) | Playable heroes (hidden heroes excluded) |

**Output Range:** 0 ≤ n ≤ total. With N_playable = 0 the total is not shown (the more-heroes line shows instead).
**Example:** 12 playable heroes, medals on 1 → "Huy hiệu 1/12". A medal earned on a hero later hidden by the claim gate is not counted (it isn't playable), and counts again when the hero is playable again.

## Edge Cases

- **If a playable hero has no `hero.hometown`, or names a place that doesn't exist:** validation
  fails (content error), so it never ships. A debug build shows the hero in no place and logs it.
- **If a place has no playable hero** (all its heroes hidden by the claim gate): no pin.
- **If one place holds several heroes:** one pin with a count badge; the column lists them
  earliest first (Rule 5). If they overflow, the column scrolls.
- **If two or more places fall within `pin_world` of each other:** they merge into a cluster pin
  (F2); tapping it lists every place's heroes under its own header.
- **If the same data clusters differently on different devices:** expected. Clusters depend on
  the device's k (`pin_world = pad_min / k`). Each device is consistent with itself, and the
  fixture fixes k per case.
- **If the current hero's place is inside a cluster:** the cluster is selected on arrival and
  the column scrolls to the current row.
- **If no hero is playable in a release build** (claims pending): the map shows the outline only,
  with a gentle "Còn nhiều anh hùng nữa sắp đến / More heroes are coming" line in the column, no
  medal total and no pins. No error.
- **If the child taps a locked row repeatedly:** each tap wobbles the row (debounced) and the
  arrow points to the current hero's pin. There's no other penalty.
- **If the child taps a pin during the arrival animation:** dropped (taps during a transition are
  dropped, Input Rule 13); the selection set by Rule 7 stands.
- **If a hero's hometown is disputed or unknown (D-36 a):** game-art-content proposes sourced
  candidates as pending claims and Luan picks one. The pin uses the recommended candidate until
  then; the `about` line says what the place is to the hero (e.g. "Quê gốc họ Trần").
- **If a content update adds a hero while the app is open:** impossible. Content ships in app
  updates, which restart the app.
- **If the screen is very wide or very narrow:** the world is fitted in the safe rect (Input
  Rule 1), so the map art keeps its aspect inside the map box and the column keeps x 744–1262. It
  is tested at the k 0.40 floor.

## Dependencies

| System | Direction | Hard/Soft | Interface |
|---|---|---|---|
| Hero progression & unlock | this depends on it | Hard | Per-hero state, F1 (current hero), F2 (medal total), just-unlocked hero |
| Save & progress | this depends on it | Hard | Best stars, medal |
| Content data & claims | this depends on it | Hard | `places.json`, `hero.hometown`, `hero.blurb`, names, portraits, `timeline_order` (proposed schema MINOR) |
| Language & text | this depends on it | Hard | Labels, field budgets (`place`, `place_about`, `hero_name`, `blurb`, `ui`) |
| Mission flow & beat types | both ways | Hard | Start mission; return from results ("the map") |
| Hints & onboarding | depends on this | Soft | First-view hand on the current hero's row (Hints Rule 4 map row) |
| Input & touch controls | this depends on it | Hard | Tap vs drag (`drag_threshold`), pin and row size (`pad_min`, Input F1) |
| Audio & voice-over | depends on this | Soft | Map sounds |

Hero progression already lists Map as a dependent (`design/gdd/hero-progression.md`).

## Visual/Audio Requirements

- **Map art** (`/asset-spec system:map-and-timeline`):
  - modern Vietnam traced from the source Luan names (D-28b), **including Hoàng Sa and Trường
    Sa**, in the art bible's map palette (§4: rice greens, river blues);
  - drawn so the **north-east sea corner** (east of the Gulf of Tonkin, north of Hoàng Sa) stays
    empty for the medal total;
  - drum-ring motif on the frames only;
  - **no text in the art**: every name is a text layer.
- **Pins and rows** reuse the hero portraits (ASSET-327 family) in drum-ring frames, the padlock
  shape, the play-triangle badge, and the stars and medal (ASSET-022–023, 036–037). New: the
  count-badge people icon and the selected-pin pointer ring (to spec with `/asset-spec`).
- **Region glow:** a soft warm wash, never flashing.
- **Audio:** a soft tap on a pin, a menu tone on a row, the unlock reveal and the star/medal
  settle sounds (Audio GDD).

## UI Requirements

- Pins and rows ≥ `pad_min`; rows are 180 world px tall (≥ `pad_min / k` at every k ≥ 0.40).
- 📌 **UX spec:** `design/ux/start-map.md` (TASK-021): zones, rows, header, pins, labels,
  arrival, states, ACs.

## Cross-References

| This doc references | Where | What |
|---|---|---|
| Hero progression | `design/gdd/hero-progression.md` Rules 4–7, 10; F1, F2 | Derived unlocks, current hero, medal total, `seen_open`, playable, unlock reveal |
| Mission flow | `design/gdd/mission-flow.md` Rule 1, States | "The map", `gate_check` |
| Save & progress | `design/gdd/save-and-progress.md` Rule 1 | Stars, medal |
| Language & text | `design/gdd/language-and-text.md` Rules 3, 6, 8 | D-20 picker, minimum sizes, field types |
| Art bible | `design/art/art-bible.md` §2 (map mood), §4 | Map palette, states by shape |
| Start-map UX | `design/ux/start-map.md` | The screen spec |
| Title UX | `design/ux/title.md` | The slice's D-27 card, kept until the VS gate |
| Systems index | `design/gdd/systems-index.md` row 11 | QC G5 |
| Decisions | `production/team/decisions.md` D-20, D-27, D-28, D-36 | Picker, slice stub, the map source, hometowns |

## Acceptance Criteria

Criteria 1–13 are logic (unit tests on the shared fixtures `content/fixtures/start-map-*.json`,
which hold multi-hero places and clusters, since only one real hero exists); 14–19 need QC
screenshots.

1. **GIVEN** heroes A(10) and C(30) with hometown P1 and B(20) with hometown P2, **WHEN** the map
   loads, **THEN** there are exactly 2 place pins; P1's badge counts 2; selecting P1 lists A then C.
2. **GIVEN** a place whose heroes are completed + open, **WHEN** the map loads, **THEN** its pin is
   open (round, pulsing); with all completed, gold with the star; with all locked, the padlock.
3. **GIVEN** A(10, completed) and B(20, open), **WHEN** the map loads, **THEN** the current hero is
   B (last open in `timeline_order`, Hero progression F1), B's hometown is selected and B's row
   has the notched border.
4. **GIVEN** every playable hero completed, **WHEN** the map loads, **THEN** the selected place is
   the hometown of the completed hero with the highest `timeline_order`, and the list isn't empty.
5. **GIVEN** 12 playable heroes with medals on 1 and a medal saved on a hidden hero, **WHEN** the
   map loads, **THEN** the total reads 1/12 (F4).
6. **GIVEN** a hero hidden by the claim gate in a release build (including a pending hometown
   claim), **WHEN** the map loads, **THEN** it has no row, adds nothing to the badge or the total,
   and a place with no other playable hero has no pin.
7. **GIVEN** any map load, **WHEN** it finishes, **THEN** `seen_open` is written for every open
   hero (Hero progression AC12).
8. **GIVEN** a locked row, **WHEN** tapped, **THEN** no mission starts, the row wobbles and the
   arrow points to the current hero's pin.
9. **GIVEN** any pin, **WHEN** tapped, **THEN** the column shows that place and no mission starts.
10. **GIVEN** an open or completed row, **WHEN** tapped and released inside, **THEN** Mission flow
    `gate_check` starts that hero.
11. **GIVEN** the list, **WHEN** a touch moves 15 pt before lifting, **THEN** the column scrolls and
    no mission starts; **WHEN** a touch moves 5 pt, **THEN** it's a tap.
12. **GIVEN** the cluster fixture (two places 80 world px apart, a third 160 px away), **WHEN**
    built at k 0.488, **THEN** the first two form one cluster and the third stays separate; at
    k 0.40 all three merge; tapping a cluster shows one header per place, groups ordered by their
    earliest hero; both apps produce the same clusters.
13. **GIVEN** content with a hero whose `hometown.place` doesn't exist, a place with `map.x` 1.2,
    or a playable hero with no `blurb`, **WHEN** content is validated, **THEN** validation fails.
14. **GIVEN** the map, **WHEN** captured, **THEN** the outline matches the named source and **shows
    Hoàng Sa and Trường Sa**, and no historical border is drawn (content reviewer sign-off, D-28).
15. **GIVEN** the map in VI and EN, **WHEN** captured, **THEN** all names, about lines, blurbs and
    the total are text layers within their boxes (R8c), and the map art contains no letters.
16. **GIVEN** the return from a results screen that unlocked a hero in another place, **WHEN** the
    map shows, **THEN** the reveal and the column change finish within 3 s, with no flashing over 3 Hz.
17. **GIVEN** the greyscale and colour-blind simulations, **WHEN** captured, **THEN** locked, open,
    completed, current and selected are still distinguishable by shape.
18. **GIVEN** the Android AVD (k ≈ 0.488), the iOS QC phone (k 0.517) and a k 0.40 emulator,
    **WHEN** the map is captured in VI and EN, **THEN** the zones of Rule 1 hold, the map art's
    left edge is ≥ x 214 (clear of the sound block), and no pin, label or the total overlaps
    another element (start-map spec §14 has the box list).
19. **GIVEN** a place labelled from a hometown candidate that is not a recorded birthplace, **WHEN**
    captured, **THEN** its about line says what the place is to the hero (e.g. "Quê gốc họ Trần")
    and the word "nơi sinh / birthplace" appears nowhere.

## Open Questions

| # | Question | Owner | By |
|---|---|---|---|
| D-36 a | Trần Quốc Toản's hometown: A Tức Mặc, Thiên Trường, "Quê gốc họ Trần" (C17, **recommended**; the pin uses it until Luan picks) · B làng Triệt (C18, Wikipedia lead only) · C Thăng Long (C19) · D Bình Than, the story place (C20). Draft: `content/drafts/start-map-tqt.json` | Luan | Before the build |
| — | TQT's blurb: "Cậu bé thời Trần tự lập đội quân nhỏ đi đánh giặc. / A Trần-era boy who raised a band to fight the invaders." (C01, C07, C09; no age, no legend claim so no marker needed) | Luan | Before the build |
| — | No app-title row on the map (default)? | Luan (leader asking) | Before the build |
| D-28b | The map source: which official administrative map to trace (with Hoàng Sa and Trường Sa)? | Luan | Before the map art |
| — | The proposed schema MINOR (`places.json`, `hero.hometown`, `hero.blurb`, fields `place_about` and `blurb`, the validation rules) | game-dev-ios + game-dev-android | PR review |
| — | `drag_threshold` (~10 pt) as a tuning key | devs | With the schema MINOR |
| — | Shared fixtures `content/fixtures/start-map-*.json` (grouping, current hero, clusters at fixed k, medal total) | game-art-content + devs | With the schema MINOR |
