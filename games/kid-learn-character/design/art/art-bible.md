# Art Bible: Letter Morph (working title; K-04 open)

> **Status**: Approved (all 9 sections approved one by one by Luan, 2026-11-17)
> **Owned By**: art-director
> **Last Updated**: 2026-11-18 (K-25 glyph edge and crossfade contrast in §2, §4; K-16 amendments in §2, §4, §5, §7, §8; earlier the same day: §8 says where silhouette path data lives)
> **Art Director Sign-Off (AD-ART-BIBLE)**: SKIPPED 2026-11-17 — lean mode

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
| Morning | 06:00 | `#7f9fd6` / `#c7cde6` / `#f0c9b0` | `#8a9fc4` / `#9fb9b4` · `#f2dfc6` | Soft warm peach; low pale sun `#ecd29a`, no rays; 3–5 faint stars fading out | fill 1.1:1, so the amber outline ~~`#8a4b12`~~ `#80450f` carries it: ~~4.3:1~~ **4.8:1** *(K-25)* |
| Day | 10:00 | `#6a9ad6` / `#a8c8e8` / `#c4d6e2` | `#7fa3c0` / `#8fb89a` · `#efe2c6` | Neutral, slightly cool; high sun `#ecd29a`; no stars | outline ~~`#8a4b12`~~ `#80450f`: ~~3.9:1~~ **4.4:1** *(K-25)* |
| Dusk (home) | 16:00 | `#1f2a55` / `#46558f` / `#b8a0c8` | `#5a6a9c` / `#6f8aa6` · `#efe2c6` | Cool blue, lilac horizon; the prototype's stars | fill **5.0:1** |
| Night | 19:30 | `#121833` / `#232d57` / `#3e4a7a` | `#2f3a63` / `#3d4d75` · `#a89d88` | Deep cool blue, moonlit; more stars, twinkling at ≤ 0.35 Hz | fill **9.3:1** |

Contrast is WCAG relative luminance against the glyph's colours: top `#fff1b8` (L 0.88), middle
`#ffd36e` (L 0.69), bottom `#f6a93b` (L 0.48).

### The glyph stays first, in every look and every weather

- **Sky brightness cap:** no sky stop, sun, moon, cloud or snowflake is brighter than the glyph's
  middle colour (L 0.69). **Frame cap:** nothing on screen is brighter than the glyph's top colour.
- **Morning and day:** the glyph's cream outline becomes a deep amber outline (~~`#8a4b12`~~ `#80450f`, 6 px;
  K-25) and its halo a saturated amber, so it stays the warmest thing against a pale sky.
- **Night:** the glyph drops its palest stop and its halo shrinks to 70%; the creature and ground
  take a 15% ambient dim. The glyph itself never dims. Night stays dim and calm for play before bed.
- *(Amendment 2026-11-18, K-25: glyph edge and contrast during sky crossfades.)*
  - **The edge switches with the sky:** the glyph's edge is **cream `#f8efdc` drawn at 100%** (no longer 85%) on
    skies whose mid band is darker than **L_x ≈ 0.308**, and the **deep amber `#80450f`** (was `#8a4b12`; L 0.089)
    on lighter ones, with a **1 s wall-clock cross-dissolve** at the switch. A colour blend between the two over a
    range of sky would drop to about 1.4:1, so it is never used.
  - **Exception to rule 2 of Section 4 (≥ 3:1):** at the looks themselves the glyph is ≥ 3:1; **inside** a 15-min
    time-of-day crossfade (or the 3 s clock-jump fade) it is **≥ 2.5:1** (2.57:1 at the crossover, sky L 0.307; the
    edge actually shown can be the worse one by the switch's ±0.005 hysteresis, so the shown-edge floor is **2.53:1**),
    below 3:1 for about **16:06–16:10 and 06:06–06:09 in clear weather**, a little wider with a weather tint. The halo behind the glyph still carries it, and the child
    never watches a crossfade happen. The 1 s switch dissolve is outside the check.
  - **The saturated amber halo** of Morning and Day is `rgba(246, 169, 59, 0.95)`: `#f6a93b`, the glyph's own
    bottom stop, so it stays part of the letter (Cast Rendering R5, F8).
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
   play button at ~~0.48~~ **0.38 Hz**). *(Amendment 2026-11-18, TASK-062: App Shell keeps the as-played 0.38 Hz,
   the one-shot's `sin(2.4t)`; leader's call.)*
3. **Brightness ceiling while mashing:** extra presses add sparks, never more brightness.
4. **A reveal ends quieter than it began:** that is what "settles" means in the visual rule.
5. **Only the parade has foreground sideways motion and a warm horizon.** Slow weather drift is
   background motion and is allowed.

*(Amendment 2026-11-18, K-16: recorded exceptions to rule 2, alongside the glyph halo's ~2.2 Hz in rule 1.
The **stardust twinkle (~1.4 Hz)** and the **parade's step bob** stay as played in the one-shot. Both are below
the three-flashes-per-second threshold, and the twinkle changes the specks' size and alpha, not the scene's
brightness. Every other pulse stays ≤ 1 Hz.)*

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
| **Letter Gold** | fill `#fff1b8` / `#ffd36e` / `#f6a93b`; outline `#8a4b12` (the glyph's Morning/Day edge is `#80450f`, K-25); token ink `#b9631c` | "A letter or number lives here." The glyph, hints, queued tokens and the title's play button (their door, Section 2). Nothing else is gold. |
| **Starlight** | `#fbeec8` (L 0.86) | "I heard you." Sparkles, pale stardust specks, sky stars at ≤ 80% alpha; also the moon's progress ring. |
| **Ink** | `#2a2340`; creature outline at **80%** in every look | "A hero" (Section 3): outlines, pupils, smiles. |
| **Stage Cream** | stage `#efe2c6` → `#e3d1ae`; highlight `#f8efdc` (L 0.87); bone `#f3e6c8`; card `#fbf4e6` | Ground, token bubbles, horns, toes, eye whites. |
| **Shared constants** | nest `#a8743f`, fossil rock `#6e4a2c`, moon `#e6d6a4` | The same object in every theme and look. |

Section 2's frame cap (L 0.88) applies to these tokens too: the prototype's stars `#fff6da`,
stardust `#fff8e8`, hint bubble and eye whites (L 0.92–0.99) move to Starlight and highlight
cream. The grown-up card is exempt: it sits under the 55% navy dim.

*(Amendment 2026-11-18, K-16: the **stardust stays as played**: about **70% of the specks are gold**, the rest
Starlight. This is a recorded exception to "Nothing else is gold" in the Letter Gold row: the stardust **is** the
letter, broken up on its way to becoming the creature, so the gold still means "a letter lives here". Once the
creature has formed, the stardust fades out and no gold stays on the cast member.)*

### Per-look stage palettes

Section 2's table holds every stage hex. A look or a weather tint is valid when all three hold:
1. every sky stop, sun, moon, cloud and flake stays at or below L 0.69;
2. the glyph reaches ≥ 3:1 against the sky's mid band, through its fill or its amber outline *(K-25 exception:
   ≥ 2.5:1 inside a sky crossfade; see Section 2, "The glyph stays first")*;
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

**No avatar: the child is the player, and the creatures are the cast.** There is no player
character on screen; the child's own finger or keyboard is the actor (Pillar 1). Every figure is a
*theme cast member*: a creature or object that a letter or number becomes. There are no enemies
and no NPC roles, so telling characters apart means telling **the 26 cast members of a theme**
apart (Section 3: family plus one outline trait; Section 4: hue slots) and telling **the cast from
the UI**: cast members have an ink outline and never glow; UI tokens glow and have no outline.

**Expression: friendly, awake, never scary** (Pillar 3, Calm Magic). Eyes are large with a
highlight, looking forward and right. Mouths are closed or a small smile; teeth appear only as tiny
rounded nubs (the T-Rex), never bared. No claws aimed at the viewer, no angry brows, no open
roaring jaws wider than the head.
*Design test: when a pose or face could read as fierce to a 3-year-old, choose the softer one,
even for the T-Rex.*

**Motion is the character, not detail.** Each family has one signature idle, slow and at most
1 Hz: sauropod neck sway, raptor head look, ankylosaurus tail wag, rex jaw nod, nest egg wobble
with a peek, flyer wing flap; everyone has a breathing bob. Two moves are shared by every cast
member: the **tap hop** (tap → hop → its own sound again, iteration 4) and the **parade walk**. No
other actions: no eating, fighting or sleeping animations in the MVP.

*(Amendment 2026-11-18, K-16: the **MVP keeps these per-part idles** as in the prototype (neck sway, jaw nod,
wing flap…), so each cast SVG carries **named part groups with a pivot** (Section 8). Under Reduce Motion the
idles soften (Section 7).)*

**Pose:** side view, facing right, standing on the stage line, filling ≥ 60% of the stage box.
Flyers are the one exception: a flyer may hover, anchored by its ground shadow.

**Detail per size (the 2D equivalent of LOD):**

| Size | Where | Height on the 1280×720 stage | What survives |
|---|---|---|---|
| Stage | reveal / idle | ~280–360 px | everything: markings, spots, toes, blush |
| Figures / grown-up list | reference | ~70–90 px | outline trait, eye, main colour areas |
| Parade | the walk | ~75–95 px | outline trait, eye, body colour; spots, stripes and blush are dropped |

*Design test: if a marking is under 6 px at the size it is shown, leave it out at that size.*

**Numbers:** the baby dinosaurs are one shared, simpler cast member (round body, big head), varied
only by colour, so the **count** is what reads.

## 6. Environment Design Language

**A stage, not a world.** There is no architecture, culture or history to show: the environment is
a theatre set that belongs to the toy, not to the theme (Section 1). Three layers, back to front:
**sky** (the time-of-day gradient, stars, sun or moon, hand-picked weather; Section 2), **hills**
(two long overlapping bands) and **stage** (a shallow cream floor where the cast stands). A new
theme never adds scenery.
*Design test: when a theme asks for a backdrop of its own (a volcano, a city), say no; the cast
carries the theme.*

**Flat fills, no texture** (Pillars 2 and 3). Only the sky and ground use a vertical gradient;
every other shape is a flat fill. No noise, grain, painted brush texture or PBR materials: texture
would compete with the stardust, which is the only "texture" in the game. Cast members keep their
ink outline; the environment has none (Section 3).

**Prop density: zero on the stage.** The stage is empty except for the cast member, its soft
ground shadow and, now and then, the parade on the hill ridge. Sky elements are limited by count:
stars ≤ 50, clouds 2–4, and the weather caps in Section 2. Hint letters live in the sky band only
(Section 4).
*Design test: if an element is neither sky, hill, stage nor cast, it does not belong.*

**Environmental storytelling without text.** The time of day tells the child where the day is:
the morning sun rising, the evening dimming, the night quiet with stars (night is the "bedtime"
cue, with no words). The parade on the hill ridge says "all your friends", with no score. The moon
in the corner is scenery that a grown-up knows to hold.

## 7. UI/HUD Visual Direction

### Art view

**No HUD for the child.** The child sees only the hint letters (floating in the sky, almost part
of the scene), the queue tokens, the play button and the moon; plus, if a grown-up turns it on,
the on-screen keyboard row (below). The grown-up panel is the only screen with text.

**Typography: the glyph is the UI.** One bundled OFL rounded, heavy sans (the prototype uses Arial
Rounded as a stand-in; production bundles the font TASK-033 baked the glyphs from). Letters are
uppercase; digits are plain "school" forms, with no decorative serifs or ligatures. Sizes on the
1280×720 stage: the glyph about 330 px tall, hint letters about 80 px, queue tokens about 30 px.
The grown-up panel uses the same family, regular weight, 15–22 pt.

**Icons:** one only, the play triangle. Everything else is a letter, a creature or the moon.

**UI motion:** hints fade and scale in over 0.6 s and drift slowly; tokens appear without bounce;
the glyph rises from where it was pressed with an ease-out.

### UX view

- **Every press is answered:** a chime plus a sparkle; an ignored press still sparkles; with the
  sound off, everything still reads visually.
- **Flash safety:** the glyph's ~2.2 Hz halo pulse (K-08) is below the three-flashes-per-second
  threshold and changes blur, not brightness.
- **Target size:** a hint is about 120 px on the stage, roughly 75–80 pt on an 11" iPad: well above
  44 pt and sized for small fingers.
- **Reduce Motion (rule):** follow the iOS/macOS Reduce Motion setting with a shorter morph, no hint
  drift and a calmer parade. *(Amendment 2026-11-18, K-16: it also **softens**: idles at **half amplitude**, a
  **smaller tap hop**, and the glyph halo **holds steady** with no pulse.)*
- **Keyboard-only grown-ups on the Mac (rule):** the grown-up panel also opens from the parent key
  chord (as in the TASK-033 kiosk), not only by holding the moon with a mouse.

### Conflicts and how they were decided (Luan, 2026-11-17)

1. **Hints drift and fade after ~6 s; a slow 2.5-year-old aim can miss.** Decided: hints keep a slow
   drift and fade, but **a touch on a fading hint still counts and the hint holds still once
   touched**, and the touch area is a little larger than the drawn bubble.
2. **Touch-only play reaches only the 3 random hints, so the child cannot choose a favourite.**
   Decided: an **optional on-screen keyboard row** (big letter keys along the bottom, as in the
   first prototype), **off by default**, turned on by a grown-up in the panel. When it is on, the
   stage's ground line moves up to make room; hints stay in the sky.

## 8. Asset Standards

### Art view

- **Source format:** every cast member is a layered **SVG** on a 640×440 artboard, anchor at the
  feet (320, 410), facing right. Layers: `body`, `outline`, `detail` (`detail` is hidden at parade
  size, Section 5). One **silhouette** path is exported per cast member (a single compound path, no
  strokes) for MorphCore: the TASK-033 contract (glyphs pre-baked to paths from the bundled OFL
  font; each silhouette baked to its own path file, `sil/sil_….json`, which the key table names in its
  `silhouette` field: Key Table & Theme Data). *(Clarification 2026-11-18: the wording was "silhouettes as SVG
  path data in the key table".)*
- **Part groups** *(amendment 2026-11-18, K-16)*: on top of the `body`, `outline` and `detail` layers, each
  cast SVG carries **named part groups**, one per moving part its family's idle needs (for example `neck`,
  `jaw`, `wing`, `tail`), and **each group has a pivot point** in artboard coordinates. The per-part idles of
  Section 5 rotate or move these groups about their pivots. The group and pivot names are listed per family in
  the Cast Rendering data.
- **SVG subset** *(amendment 2026-11-18, TASK-045)*: cast art uses **only Cast Rendering's SVG subset**
  (`design/gdd/cast-rendering.md` R2, TASK-044). **Allowed:** paths (basic shapes and arcs are converted by the
  bake tool), solid fill with fill opacity, strokes with round joins and caps, group opacity, and
  translate / rotate / scale transforms. **Not allowed:** filters, masks, clip paths, gradients, text, CSS and
  embedded images; the bake tool **rejects them loudly**. The one exception is the **Letter Gold gradient on the
  glyph**.
- **Naming** (`[category]_[theme]_[key]_[name]_[variant].[ext]`):
  - `cast_dino_c_triceratops_01.svg`, `sil_dino_c_triceratops_01.svg`
  - `glyph_<font>_<char>.json`
  - `sfx_dino_c_triceratops_01.m4a`
  - `vo_en-us_letter_c.m4a`, `vo_en-us_word_triceratops.m4a`
- **Animation:** idles are **parameters in data** (sway amplitude and rate per family), not frame
  sequences. No sprite sheets in the MVP.
- **Audio:** creature sounds ≤ 2 s; every sound and voice line loudness-matched (the level is set
  with the audio direction).

### Technical view

- **Stack:** native Swift + SpriteKit (ADR-0001). There is no engine reference in the repo for this
  stack, so importer behaviour is **unverified until a build proves it**.
- **No performance budgets are set** in `project.yaml` (frame time, memory, app size). Proposed:
  60 fps (16.7 ms) on the oldest supported iPad; the rest set with `/project-settings` after the
  architecture step.
- **Memory rule:** on the largest iPad a stage creature is about 775 px tall, so ≤ 1024 px per
  creature texture if rasterized. All 26 loaded at once would be ≈ 100 MB, so **load on demand**:
  the current creature, the one leaving, and the parade at a small 256 px tier.
- **Particles:** ~~420~~ **240 per morph by default** *(amendment 2026-11-18, K-11 via K-16: 240 is the count
  TASK-033 measured; it is raised only after the real-iPad measurement)*; TASK-033 measured the SpriteKit morph
  fine on the iPad Simulator and the Mac. **On a real device: NOT ASSESSED** until Luan runs TASK-033's iPad
  procedure.
- **Audio:** AAC `.m4a` mono for storage, decoded to PCM at load so a press plays at once
  (TASK-033: stop + schedule + play costs 3–10 ms on the main thread).

### Conflict: how the SVG art reaches the screen (Luan, 2026-11-17: record both, decide in architecture)

- **Ideal (art):** draw the vector live, crisp at any size, small files.
- **Constrained (technical):** SpriteKit has no SVG renderer; live paths (SKShapeNode) have an
  **unverified** cost for 26 detailed creatures. Rasterizing the SVG to PNG at build time in 3 tiers
  (stage, list, parade) is fast and proven, at the cost of a larger app and a re-export on every
  art change.
- **Decision path:** the source is always SVG either way. Which one renders is decided by an ADR in
  `/create-architecture`, backed by a measurement on a real iPad.

## 9. Reference Direction

**Four references, each pointing a different way:** one for the press, one for the figure, one for
the light, one for the system. Only the first, Typer Shark, is Luan's; the other three are the
art-director's proposals, accepted by Luan on 2026-11-17.

### Typer Shark (PopCap, typing game): Luan's reference, for the press

- **Take:** the key press is the fun. Each press shows on screen the instant it is made, at the
  letter, so the child sees cause and effect with no wait (Pillar 1): the spark at the press point
  and the glyph rising from where it was pressed (Sections 2 and 7).
- **Avoid:** everything that turns it into a test: the approaching threat, the timer and air meter,
  the miss, the score, the dark water, the sharks and teeth. Here there is no wrong press, and
  nothing swims toward the child.

### Dick Bruna's picture books (Miffy): the figure

- **Take:** one figure, centred, on an almost empty ground; flat fills with no shading; one heavy,
  even outline around the whole figure. That is "a stage, not a world" and "an outline marks a
  hero" (Sections 3 and 6).
- **Avoid:** the front-facing pose (our cast faces right, side view), dot eyes (ours are large with
  a highlight), a pure black outline (ours is Ink at 80%) and the small primary palette (ours is the
  eight hue slots). Never his characters.

### Fantasia (Disney, 1940), the "Nutcracker Suite" fairies: the light

- **Take:** light as something *applied*: small glows drift onto a form, touch it and fade, and the
  form stays lit. That is "the light gently settles into the thing": the stardust lands on the
  silhouette and gets quieter as it lands (Section 2, rule 4).
- **Avoid:** the painted naturalism, detailed plants and rendered depth (we use flat fills and no
  texture), the fast sweeping passes, and any fairy or character figure. The light has no character
  of its own.

### Isotype (Otto Neurath, Gerd Arntz): the system

- **Take:** two rules. A set of figures is drawn to one shared system, each differing by the one
  element that defines it: our family plus one outline trait (Section 3). A larger quantity is shown
  by *more* identical figures, never by a bigger one: how the number babies count (Section 5).
- **Avoid:** the hard cut-paper edges, the strict grid, the black-and-red print palette and the
  statistics subjects. We use Isotype's rules, not its look.

**How these are used:** each reference answers one question (how the press feels, how a figure
sits, how light moves, how a set holds together). They guide technique only; no character, artwork,
name or layout from any of them is copied into the game.
