# Art Bible: Letter Morph (working title; K-04 open)

> **Status**: Draft
> **Owned By**: art-director
> **Last Updated**: 2026-11-17
> **Art Director Sign-Off (AD-ART-BIBLE)**: [Not yet reviewed]

`/art-bible` writes these nine sections in this order and replaces each
section's `[To be designed]` line as that section is approved. A section still
holding its placeholder is incomplete; a later run fills only those.

## 1. Visual Identity Statement

**Visual rule:** *The letter is light, and the light gently settles into the thing.*

This sharpens the brainstorm anchor ("Stardust Storybook: every letter is made of light, and the
light becomes the thing") rather than replacing it. "Becomes" left room for a fast, flashy
transformation, the ambiguity most likely to bite later; "gently settles" builds Calm Magic into
the rule itself. "The thing" is theme-neutral, so the rule holds for dinosaurs, vehicles or
apples. The browser prototype (`prototypes/letter-morph-dinosaur/`, played 2026-11-17) confirmed
the idea: glowing letter, then stardust in the letter's outline, then a flat creature.

**Supporting principles**

1. **The glyph gets the first look** (serves Pillar 2, The Letter Comes Alive). The letter or
   number is the brightest, largest, warmest element on screen, and the stardust keeps its
   outline before it becomes the creature.
   *Design test: when the background, creature or effect competes with the glyph, dim or shrink
   the competitor.*
2. **One flat, friendly silhouette** (serves Pillar 4, Things the Child Loves). Every creature or
   object is a hand-drawn, rounded, flat shape that a 3-year-old can name from its outline alone,
   in friendly colours and with no fine detail. Never emoji, never plain circles.
   *Design test: when the choice is more detail or a cleaner silhouette, choose the silhouette.*
3. **Drift, never flash** (serves Pillar 3, Calm Magic). Light fades up, glows and drifts; nothing
   strobes, pops or jumps in brightness. Pillar 1 still holds: the glow starts on the press, so
   calm shapes the motion and never delays the answer.
   *Design test: when the choice is a faster, brighter burst or a slower glow, choose the slower
   glow.*

**Theme-swap check** *(amended 2026-11-17, K-08)*: the stage follows the player's clock (morning,
day, dusk, night) and, when a grown-up turns it on, the weather; Section 2 defines both. A theme
never changes the stage or the behaviour of the light: it changes only the silhouettes and their
colours. A vehicle that needs a different sky to look right, or a sky that needs a theme
recoloured, is breaking principle 1 or 2.

## 2. Mood & Atmosphere

**The stage follows the clock; the light follows the glyph.** The sky shows the device's local time
(morning, day, dusk or night), and a grown-up can add calm weather on top, picked by hand (K-08). Each game state
looks different because of *where the light gathers, how much there is, and how fast it moves*;
the time of day only sets the backdrop. Dusk is the home look and keeps the prototype's palette.

### Time of day

The boundaries are config values; the times below are the art-director's proposal, to be tuned
in play. A change between looks crossfades over 15 minutes of wall-clock time, so a child never
sees it happen during a session; when the game opens or resumes, the first frame is already in
the right look.

| Look | From | Sky top / mid / horizon | Hills back / front · ground | Light and sky elements | Glyph vs the sky's mid band |
|---|---|---|---|---|---|
| Morning | 06:00 | `#7f9fd6` / `#c7cde6` / `#f0c9b0` | `#8a9fc4` / `#9fb9b4` · `#f2dfc6` | Soft warm peach; low pale sun `#ecd29a`, no rays; 3–5 faint stars fading out | fill 1.1:1, so the amber outline `#8a4b12` carries it: **4.3:1** |
| Day | 10:00 | `#6a9ad6` / `#a8c8e8` / `#c4d6e2` | `#7fa3c0` / `#8fb89a` · `#efe2c6` | Neutral, slightly cool; high sun `#ecd29a`; no stars | outline `#8a4b12`: **3.9:1** |
| Dusk (home) | 16:00 | `#1f2a55` / `#46558f` / `#b8a0c8` | `#5a6a9c` / `#6f8aa6` · `#efe2c6` | Cool blue, lilac horizon; the prototype's stars | fill **5.0:1** |
| Night | 19:30 | `#121833` / `#232d57` / `#3e4a7a` | `#2f3a63` / `#3d4d75` · `#a89d88` | Deep cool blue, moonlit; more stars, twinkling at ≤ 0.35 Hz | fill **9.3:1** |

Contrast is WCAG relative luminance against the glyph's colours: top `#fff1b8` (L 0.88), middle
`#ffd36e` (L 0.69), bottom `#f6a93b` (L 0.48).

### The glyph stays first, in every look and every weather

- **Sky brightness cap:** no sky stop, sun, moon, cloud or snowflake is brighter than the glyph's
  middle colour (L 0.69). **Frame cap:** nothing on screen is brighter than the glyph's top colour.
- **Morning and day:** the glyph's cream outline becomes a deep amber outline (`#8a4b12`, 6 px) and
  its halo a saturated amber, so it stays the warmest thing against a pale sky.
- **Night:** the glyph drops its palest stop and its halo shrinks to 70%; the creature and ground
  take a 15% ambient dim. The glyph itself never dims. Night stays dim and calm for play before bed.
- **The moon (the parent gate)** is dimmed to `#e6d6a4` (L 0.68), and shown at 70% opacity as a
  "daytime moon" in morning and day (Luan, 2026-11-17). It meets the sky cap and draws less of the
  child's attention; parents still find it.

### Weather (picked by a grown-up behind the parent gate; K-08)

A grown-up **picks today's weather by hand** behind the parent gate; there is no network and no
location (K-08, revised after TASK-034). When weather is off, the scene is clear; a change of
weather uses the same slow crossfade. Weather is drawn behind the glyph and creature, fades
to nothing inside the glyph's halo, and counts as sky for the brightness cap.

- **Clear:** no overlay.
- **Cloudy:** 2–4 flat, rounded clouds drifting at ≤ 8 px/s, tinted to the current look, never
  darker than the sky's top colour.
- **Light rain:** 40–70 thin streaks at ≤ 35% opacity, cool grey-blue matched to the look; the sky
  loses 10% saturation.
- **Snow:** ≤ 60 round flakes `#cfd6e3`, falling at 20–40 px/s with a sway of ≤ 0.3 Hz.
- **Windy:** a modifier on rain or snow: a tilt of ≤ 20°, clouds drift twice as fast, no gusts.
- **Never:** lightning, thunder flashes or dark storm clouds.

### Rules across states

1. **The glyph pulse stays ~2.2 Hz** (Luan, K-08, as in the prototype). Only the halo's blur pulses,
   between 60% and 100%; the letter's fill never pulses. This is below the WCAG
   three-flashes-per-second threshold, and it changes blur rather than flashing brightness.
2. **Every other pulse is ≤ 1 Hz** (the prototype complies: the creature breathes at 0.33 Hz, the
   play button at 0.48 Hz).
3. **Brightness ceiling while mashing:** extra presses add sparks, never more brightness.
4. **A reveal ends quieter than it began:** that is what "settles" means in the visual rule.
5. **Only the parade has foreground sideways motion and a warm horizon.** Slow weather drift is
   background motion and is allowed.

| State | Emotional target | Light (time-of-day aware) | Energy (0–5) |
|---|---|---|---|
| Title | A door left ajar | Light gathers on the play button: a gold glow at dusk and night, carried by its amber outline in morning and day | 2 |
| Reveal | Wonder, then settling | Light gathers on the glyph: it fades up, its halo pulses at ~2.2 Hz, it becomes stardust, and it ends with only the look's ambient light on the creature | 3 |
| Idle | Quiet company | No gathered light; the current look and its weather drift gently; hints drift at the edges | 1 |
| Mashing | Answered, never overwhelmed | A small spark at each press, total added light capped; weather particles halve | 3 |
| Parade | Celebration (the parent's favourite, Keep) | The only energy-4 moment: sideways motion plus a warm horizon lift (peach in morning and day, amber at dusk and night) | 4 |
| Grown-up panel | The adult's quiet room | The scene dims under navy at 55% in every look and weather; flat cream card, no glow | 1 |

## 3. Shape Language

Everything is rounded. The only pointed shapes are small accents (plates, horns, teeth) with soft
tips. The four-point star is the unit of stardust. The order of shapes matches the order of light:
**glyph, then creature, then UI, then environment.**

### Creature silhouettes

- **The silhouette is the morph.** The stardust samples each creature's all-white render (the
  prototype's `MONO` pass), so a muddy outline gives a muddy morph. *Test:* that white render, 64 px
  tall, must still be nameable and distinct from its family siblings.
- **A body family plus one signature trait on the outline.** Families give a theme its rhythm.
  Within a family, each variant owns one trait that changes the outline, not just the markings
  inside it:
  - Sauropods: neck up (B) or neck forward (D).
  - Duckbills: duck bill, bump, thumb spike, hatchet crest, brow with a baby (E, H, I, L, M).
  - Horned: the count and layout of the horns (C, X, Z).
  - Plated: plates, spikes or low plates (S, K, W).
  - Raptors: fuzz, stripes with brows, arm feathers with a crest, a long snout (J, R, U, V).
  - Rex: plain or feathered (T, Y). Flyers: in flight or standing (P, Q).

  Stripes and speckles are only ever a second cue.
- **Friendly proportions.** The head is about a quarter to a third of the body; each eye is large
  with a highlight; legs are stubby and toes are cream, with no claws facing the viewer. Even the
  T-Rex smiles.
- **A shared pose.** Side view, facing right (the reading direction and the parade's direction),
  standing on the stage line. Each creature fills at least 60% of the common stage box in height or
  width, so a small one is never lost.
- **The vehicles test.** The same grammar holds for a vehicles theme: the family is the body type
  (car, truck, bus, digger, train, plane, boat) and the signature trait sits on the outline (a
  ladder, a scoop, a chimney, wings). Wheels may be circles; a body never is.

### Environment geometry

Long, low, wide curves: two overlapping bands of hills meet a shallow cream stage that curves up
gently like a smile. No straight lines and no vertical shapes such as trees or rocks, so the glyph
and the creature are the only upright things on screen: a clean separation of figure from ground.
The environment belongs to the toy, not to the theme. Weather shapes (Section 2) are soft too:
rounded clouds, thin streaks, round flakes.

### UI shape grammar

| Element | Shape | Meaning |
|---|---|---|
| Hint letter | Rounded square (corner radius about 36%), one twinkle at its top-right corner, drifting | "A letter you can touch" |
| Queued letter | **A small circle in a still row at the top right** (Luan, 2026-11-17; the prototype still draws a smaller rounded square) | "Waiting its turn" |
| Moon gate | A crescent with no bubble and no letter; a thin ring fills while it is held | Scenery that happens to be a control: it should not invite a child's tap |
| Play button | A rounded pill with a soft right-pointing triangle | The game's only icon |
| Sparkle | A four-point star | "I heard you" |
| Grown-up card | A rounded rectangle with plain rectangular controls | Adult layout; the only text-heavy shapes in the game |

The rule against plain circles applies to creatures only; circles are allowed in the UI. Hint and
queued letters differ in **shape, size, position and motion**, never in colour alone.

### Hero and supporting shapes

The heroes are the glyph (largest, centred, heaviest weight) and the creature, which carries the
ink outline. The supporting shapes are the hints (about a third of the glyph's height), the queue
(about half a hint), the sparkles and the moon. The environment has no outlines at all: **an
outline marks a hero.**

## 4. Color System

**Colour rule: gold is a letter, and every other colour makes room for it.** No colour means
danger, failure or reward. There is no wrong press, so the game never uses red for wrong, green for
right, or gold for "well done": every press is answered the same way.

### Fixed hues (the same in every look)

| Token | Hexes | Meaning and use |
|---|---|---|
| **Letter Gold** | fill `#fff1b8` / `#ffd36e` / `#f6a93b`; outline `#8a4b12`; token ink `#b9631c` | "A letter or number lives here." The glyph, hints, queued tokens and the title's play button (their door, Section 2). Nothing else is gold. |
| **Starlight** | `#fbeec8` (L 0.86) | "I heard you." Sparkles, pale stardust specks, sky stars at ≤ 80% alpha; also the moon's progress ring. |
| **Ink** | `#2a2340`; creature outline at **80%** in every look | "A hero" (Section 3): outlines, pupils, smiles. |
| **Stage Cream** | stage `#efe2c6` → `#e3d1ae`; highlight `#f8efdc` (L 0.87); bone `#f3e6c8`; card `#fbf4e6` | Ground, token bubbles, horns, toes, eye whites. |
| **Shared constants** | nest `#a8743f`, fossil rock `#6e4a2c`, moon `#e6d6a4` | The same object in every theme and look. |

Section 2's frame cap (L 0.88) applies to these tokens too: the prototype's stars `#fff6da`,
stardust `#fff8e8`, hint bubble and eye whites (L 0.92–0.99) move to Starlight and highlight
cream. The grown-up card is exempt: it sits under the 55% navy dim.

### Per-look stage palettes

Section 2's table holds every stage hex. A look or a weather tint is valid when all three hold:
1. every sky stop, sun, moon, cloud and flake stays at or below L 0.69;
2. the glyph reaches ≥ 3:1 against the sky's mid band, through its fill or its amber outline;
3. it uses no Letter Gold, and any stage yellow stays pale, like the sun `#ecd29a`.

**Temperature:** the glyph is the warmest thing in every look. *Morning:* cool at the top, warmth
only in the peach horizon band. *Day:* neutral to cool; warmth comes only from the glyph and the
creatures. *Dusk (home):* cool blue with a lilac horizon. *Night:* the coolest look; the moon is
the only warm sky element, and it is desaturated. Weather is picked by hand by a grown-up behind
the parent gate, and it only cools or greys the scene (rain takes 10% saturation off; snow is
`#cfd6e3`). The parade's horizon lift is the only allowed warming.

### Creature palettes

Each creature's body takes one of eight hue **slots**. A slot holds at most 4 creatures per theme.
Siblings in one family never share a slot, and never use leaf and mint together (they read as one
green). F and N are objects and use the shared constants.

| Slot | Hue | Dinosaurs (applied 2026-11-17) |
|---|---|---|
| Rose | 320–355° | L, O |
| Coral | 5–32° | C, Q, U, Y |
| Ochre | 33–50°, S ≤ 60% | G, I, K, V |
| Leaf | 65–130° | B, R, S, Z |
| Mint | 130–165° | H |
| Teal | 165–200° | P, W, D |
| Blue | 200–235° | A, E, J, X |
| Violet | 250–290° | M, T |

- **Band:** body relative luminance 0.20–0.47, HSL saturation 35–65%; accents (plates, frills,
  crests) up to 75%.
- **Ochre, never gold:** creature yellows stay at ≤ 60% saturation and lean toward brown (`#c99a52`,
  `#e0c08a`; baby `#d8b87a`). The prototype's `#f2b04f`, `#f2d06a`, `#f6c14b`, `#e2bb4f`,
  `#e7c45a` move to these.
- **Greyscale stage test, every look (and with snow).** A creature passes when it separates from
  both the sky's mid band and the front hill: body ≥ 1.5:1 or outline ≥ 3:1. At night the body
  carries it; at dusk the body carries it against the sky; in morning, day and against the dusk
  front hill only the outline carries it (a mid-tone body is ~1.05:1 on the dusk hill, ~1.2:1 on
  the day sky). That is why the outline is 80%: 3.2:1 on the dusk hill and 3.9:1 on the day hill,
  against 2.3:1 and 2.6:1 at the prototype's 55%.
- **Number babies:** nine pastels, one per slot plus a second coral (apricot), always in the same
  order so neighbouring babies differ.

### UI palette

- **Hints and queued tokens:** Letter Gold ink `#b9631c` on highlight cream (about 4:1; the
  prototype's `#e0892a` was about 2.5:1). Hints spawn **in the sky only**: on the cream ground a
  cream bubble loses its edge and crowds the creature's ground line.
- **"Seen" letters get no mark** (Luan, 2026-11-17): the parade already shows progress, and a mark
  would introduce a reward colour.
- **Grown-up panel and moon ring:** panel controls in Dusk Blue `#46558f` (6.5:1 on the card) and
  the moon's progress ring in Starlight (Luan, 2026-11-17), so gold means only letters. Trade-off:
  the ring is weaker on the day sky (~2.5:1); its length and the hold time carry it.

### Colourblind safety

| Meaning | Colour | Backup cue |
|---|---|---|
| A letter or number | Letter Gold | Largest, centred, outlined, spoken |
| I heard you | Starlight | Four-point star at the press point, plus a chime |
| Hint vs waiting | Same gold on cream | Drifting rounded square vs a small circle in a still row |
| Which creature | Slot | Silhouette trait and spoken name |
| Moon gate progress | Ring | Ring length and hold time |

Under deuteranopia leaf, ochre and coral converge, so raptors R, U and V become one brown. Their
outline traits (Section 3) tell them apart, which is why markings are never the only difference.

## 5. Character Design Direction

[To be designed] — the player character's visual archetype, how players tell
enemies, NPCs and allies apart at a glance, expression and pose style, and how
much detail survives at game camera distance (LOD philosophy).

## 6. Environment Design Language

[To be designed] — architectural style and its tie to the world's culture,
texture philosophy (painted, PBR or stylised, and why), prop density rules per
area type, and environmental storytelling guidelines.

## 7. UI/HUD Visual Direction

[To be designed] — diegetic versus screen-space HUD, typography (personality,
weight, size hierarchy, minimum readable size), iconography style, UI animation
feel, and any art-direction versus readability conflict and how it was decided.

## 8. Asset Standards

[To be designed] — file formats, naming convention, texture resolution tiers,
LOD levels, export settings, and the engine's hard limits (poly budgets per
asset category, texture memory, material slots). Where an art preference and a
technical limit disagree, record both and the trade-off chosen.

## 9. Reference Direction

[To be designed] — 3–5 references (games, films, art styles or artists). For
each: the specific element to take from it, and what to avoid so the result
does not read as a copy.
