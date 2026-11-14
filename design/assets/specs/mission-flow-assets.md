# Asset Specs — System: Mission Flow & Beat Types

> **Source**: design/gdd/mission-flow.md (Core Rules 6, 7, 7c; Visual/Audio; Game Feel); design/narrative/heroes/tran-quoc-toan.md §3, §7
> **Art Bible**: design/art/art-bible.md
> **Generated**: 2026-11-14 · Task: TASK-014
> **Review**: lean mode. art-director wrote the specs; technical-artist was skipped, so technical constraints were not validated. Sizes follow art bible §8 as set by game-art-content.
> **Portrayal sign-off**: Luan (D-18) before any final art. Trần-era details are ⟨placeholder⟩.
> **Backgrounds (ASSET-307–322)**: shipped per ADR-0002 (2880×1320 at 1.5×, sky band in code from `content/data/themes.json`), updated 2026-11-14 (TASK-014a).
> **Status**: 32 assets specced / 0 approved / 0 in production / 0 done

**Shared conventions:**
- **Props** use the hero's scale (hero 360 px tall at 2×), a bottom-centre pivot and the feet line at `ground_y`.
- **Backgrounds** (theme ids `river`, `village`, `camp` from `mission.json`): layers are authored at 3840×2160 (or wider) and exported at 2× (as authored) and 1× (half). The ground top edge sits at **y = 1410 at 2× / 705 at 1×** (`ground_y` 470 of 720). Edge hierarchy per §3: **far sky and far layers have no outlines, mid has soft thin outlines, and play has the bold `#4A3428` top edge.** Every set is a **stand-in, not a depiction of a real place**. All architecture and boats are ⟨placeholder⟩.
- **Foreground** layers stay below y = 1500 at 2× (under the feet line), at 60–80% opacity, and never cover the hero or an enemy (§6).

## ASSET-301 — Straw training dummy

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 9 frames, 512×512 cells at 2×; dummy about 260 px tall at 2× (≈ 72% of the hero); **it is a body, not a prop: cap 170 world px (340 at 2×)**, placeholders included (`design/ux/hud.md` §3.3) |
| Format | PNG (sRGB, alpha) |
| Naming | `prop_dummy_idle_01.png`; `prop_dummy_wobble_01…08.png` (one-shot on each hit, 8 × 60 ms, ends back on idle); placed at `dummy_spacing` 300 px |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A round bundle of straw `#D8B86A` on a wooden post `#A8743F` set in a small earth mound. It has a ball-shaped straw head with **no face** and a crossbar of straw for arms, all bound with rope `#8E6B45`. On a hit it rocks back about 20°, overshoots forward, then settles. A few straw wisps flick and settle back, and nothing breaks off or falls.

**Art Bible Anchors:**
- Mission-flow Visual/Audio "Training": dummies wobble and spring back and never break apart.
- §6 Beat 3: a home courtyard with straw dummies (C12 invented).
- §3: simple icon-like props.

**Generation Prompt:** Single game prop, side view, a round friendly straw training dummy on a wooden post #A8743F, ball-shaped straw head with no face, straw crossbar arms, bound with rope #8E6B45, golden straw #D8B86A, standing in a small earth mound. Wobble key poses: tilting back, overshooting, settling. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428, Vietnamese motifs as accents. Clear morning light, transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, face on dummy, enemy uniform, broken dummy, flying straw debris, scarecrow with hat, creepy.

**Status:** Needed

## ASSET-302 — Practice partner

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 25 frames, 512×512 cells at 2×; sheet 4096×3072 at 2×; figure about 320 px tall (shorter than the hero); **body cap 180 world px (360 at 2×)**, placeholders included (`design/ux/hud.md` §3.3); the practice stick reaches `enemy_reach − stand_gap` = 140 world px in front, like an enemy weapon |
| Format | PNG (sRGB, alpha) |
| Naming | `char_partner_sheet.png` + `char_partner_[state]_[nn].png`: idle 01–04 (loop 150 ms) · windup 01–05 (as combat: 3 build + 2 hold for `telegraph` 1.1 s) · strike 01–03 (`strike_time` 0.25 s) · rest 01–04 · blocked 01–03 (a small hop back on `block_knock`, smiling) · cheer 01–06. Authored facing **left** (toward the hero) |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A friendly older village youth in the team colour: a desaturated vermilion `#B9705C` headband and sash, a straw-beige tunic `#D8C9A3` and trousers `#7A6250`, with the same skin and face style as the hero. There is no helmet and no slate-violet anywhere, so the child never reads them as an enemy. They hold a padded practice stick `#A8743F` with fat cream cloth ends `#F3E6C8`. The windup is a big, slow, playful wind-back with an encouraging smile, and a blocked strike gets a proud "well done" nod.

**Art Bible Anchors:**
- Mission-flow Visual/Audio: the partner wears the hero's team colour, never read as an enemy.
- §5 Followers/allies: the team colour desaturated.
- Mission-flow Rule 7c: windup and strike timing as combat.

**Generation Prompt:** Character animation key poses, side view facing left, a friendly smiling Vietnamese village youth from 13th-century Đại Việt as a sparring partner, muted vermilion headband and sash #B9705C, straw-beige tunic #D8C9A3, brown trousers #7A6250, warm skin #F1C9A0, holding a padded wooden practice stick #A8743F with fat cream cloth ends #F3E6C8. Poses: ready stance, playful slow wind-back, gentle tap forward, rest, small hop back with a proud smile, cheering. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428, Vietnamese motifs as accents. Clear morning light, transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, helmet, armour, slate or violet colours, angry face, sharp stick, taller than the hero.

**Status:** Needed

## ASSET-303 — Trần army flag (reach-the-flag goal)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 9 frames, 1024×1024 cells at 2× (512 at 1×); pole about 760 px tall at 2× |
| Format | PNG (sRGB, alpha) |
| Naming | `prop_tranflag_fly_loop_01…08.png` (loop, 8 × 100 ms); `prop_tranflag_touched_01.png` (a full snap on touch); the "interactive" glow pulse is an engine effect |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** **⟨placeholder: the Trần army flag's design is to be sourced and signed off⟩.** The proposal is a tall wooden pole with a rounded finial and a large rectangular cloth in bronze gold `#E8A93B` with a vermilion `#D64A2E` border band and a short tassel. It is plain cloth with no characters, emblem or symbol, and is clearly different from the hero's vermilion banner. It flies strongly in the camp wind and sits planted in a small earth mound with two stakes.

**Art Bible Anchors:**
- §4 Semantic usage: bronze gold means interactive/reward, with a glow pulse.
- §3 Props: a single readable form with a bounce or glow when interactive.
- Luan rule 2 / no text in art: plain cloth.

**Generation Prompt:** Single game prop, side view, a tall wooden flagpole with a rounded top finial planted in a small earth mound, carrying a large plain rectangular cloth flag in bronze gold #E8A93B with a vermilion border band #D64A2E and a short tassel, flying strongly in the wind to the right, no symbols. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428, Vietnamese motifs as accents. Warm light breaking through a stormy sky, transparent background.
Negative: text, letters, characters, calligraphy, emblem, symbol, star, dragon, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, spear tip on the pole, modern flag.

**Status:** Needed

## ASSET-304 — The orange, with squeeze sequence and juice droplets

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 6 orange frames + 5 droplet frames, 256×256 cells at 2× |
| Format | PNG (sRGB, alpha) |
| Naming | `prop_orange_squeeze_01…06.png` (scrubbed with the hero's ASSET-107 frame, attached at the hand anchor); `vfx_orange_juice_01…05.png` (one-shot, 5 × 60 ms, spawned at the 25/50/75/100% pulses) |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A round orange `#F29A2E` ⟨proposed⟩ with a small stem and one leaf `#7CB342`. Across 01–06 it squashes from round to a flattened, crinkled shape inside his fist, staying recognisable as an orange. Juice is 3–5 small round droplets in light yellow-orange `#FFD27A` ⟨proposed⟩ that spray **away from him** and fade in the air before reaching the ground. There is no drip on him and no puddle.

**Art Bible Anchors:**
- Hero doc Beat 2: the orange is squeezed (juice, no mess on him); legend (C06).
- §4 Red must never read as blood: the juice is light yellow-orange, never red, and never pools.
- §5: the anger beat is puffed cheeks, not violence.

**Generation Prompt:** Game prop sprite sheet, a round bright orange fruit #F29A2E with a small green leaf #7CB342, six stages from round to squashed and crinkled, plus a separate set of a few small round light yellow-orange juice droplets #FFD27A spraying outward and fading. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428. Side view, transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, red juice, dark juice, splatter, puddle, drips, pulp mess, hand.

**Status:** Needed

## ASSET-305 — The banner (furled, raising, flying)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 15 frames, 1024×1024 cells at 2× (512 at 1×); pole about 860 px; flying cloth about 640×400 at 2× with a **flat text-safe zone of 480×280** inset from the pole edge |
| Format | PNG (sRGB, alpha) |
| Naming | `prop_banner_furled_01.png`; `prop_banner_raising_01…06.png` (one-shot, matched to ASSET-108's pole angle); `prop_banner_flying_loop_01…08.png` (loop, 8 × 100 ms). The text-safe zone rectangle is listed per frame in the frame list |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A wooden pole `#A8743F` with a rounded cap and a plain rectangular cloth in vermilion `#D64A2E` with a thin bronze-gold `#E8A93B` border. **Furled:** the cloth is wrapped around the pole and tied. **Raising:** it unrolls and catches the wind. **Flying:** it ripples only along the trailing edge, so the text-safe zone stays flat and evenly lit for the VI/EN text layer (the six words). The cloth is plain, with no painted marks. ⟨placeholder: the period form of the banner is to be sourced⟩.

**Art Bible Anchors:**
- §3 Historical banner text / Luan rule 2: plain shape and colour, with the words as a localised layer.
- §4: vermilion as a flat, clean, shaped area (the hero's banner).
- Mission-flow Rule 6: the banner's Text is a text layer on the prop.

**Generation Prompt:** Single game prop, side view, a wooden pole #A8743F with a rounded cap carrying a plain rectangular cloth banner in vermilion #D64A2E with a thin bronze-gold border #E8A93B, shown in three states: furled and tied around the pole, unrolling, and flying with a gentle ripple only at the far edge while the main area stays flat and blank. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428, Vietnamese motifs as accents. Clear morning light, transparent background.
Negative: text, letters, characters, calligraphy, words, symbols, emblem, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, dark crimson, stains, torn cloth, heavy folds across the centre.

**Status:** Needed

## ASSET-306 — Beat-end cheer sparkle

| Field | Value |
|-------|-------|
| Category | VFX |
| Dimensions | 6 frames, 256×256 cells at 2×; plays on the HUD beat progress dot |
| Format | PNG (sRGB, alpha) |
| Naming | `vfx_beat_sparkle_01…06.png`; one-shot, 6 × 50 ms (0.3 s, within §7's 0.15–0.3 s) |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** Three to five soft rounded-tip stars in star gold `#FFC531`, with ink-brown `#3A2A20` outlines and a small cream `#FFF6E3` core flash. They pop outward from the dot, twinkle once and fade. It pops; it does not flash or strobe.

**Art Bible Anchors:**
- Mission-flow Visual/Audio "Beat end": a small star sparkle on the beat progress dots.
- §3 UI shape grammar: soft five-point stars with rounded tips; §4 UI palette `#FFC531`, `#3A2A20`.
- §7: bouncy and short, nothing flashes.

**Generation Prompt:** Game UI VFX sprite sheet, a small burst of soft five-point stars with rounded tips in gold #FFC531 with thick ink-brown outlines #3A2A20 and a small cream centre glow #FFF6E3, popping outward and fading, cheerful. Modern kids' cartoon, soft rounded shapes, flat colours. Front view, transparent background.
Negative: text, letters, numbers, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, sharp star points, fireworks explosion, lens flare, strobe.

**Status:** Needed

## ASSET-307 — River set: far sky

| Field | Value |
|-------|-------|
| Category | Environment |
| Dimensions | Author 3840×1760 (2×); ship **2880×1320 at 1.5×** as two tiles of 1440×1320, or parallax strips ≤ 2048 wide (ADR-0002). Taller authoring is cropped at export. Tileable horizontally |
| Format | PNG (sRGB, alpha) |
| Naming | `bg_river_sky.png` |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1.5× shipped (ADR-0002: author 2×, ship 1.5×); R19b ≤ 1440×1320 per tile file |

**Visual Description:** A clear morning sky graded from light blue at the top to a pale warm haze at the horizon, with a soft sun disc and 3–4 long horizontal cloud bands. It is the lowest detail and contrast of the set, with no outlines.

**Sky band and safe area (ADR-0002):** above this tile the game draws a vertical gradient band from `themes.json` `river.sky_band` (top `#9CCBEA` → bottom `#BFE0F2`). The tile's **top ~10% (≈130 px at 1.5×) fades into `#BFE0F2`**, so there's no seam. Key elements (sun, cloud bands, sun shafts) stay **below ~15% from the tile's top**. No vertical parallax.

**Art Bible Anchors:**
- §2 Mission beat: clear morning sun, bright, open, breezy.
- §6 Far sky: lowest detail, lowest contrast.

**Generation Prompt:** Wide horizontally tileable side-scrolling game background layer, clear morning sky, soft gradient from light river blue to pale warm haze at the horizon, a soft sun disc, a few long flat cloud bands. Modern kids' cartoon, flat colours with soft gradients, no outlines, low contrast. Palette anchors #3E8FC4 (softened), #F3E6C8. The top 10% fades smoothly into flat #BFE0F2; sun, clouds and light shafts stay in the lower 85%.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, characters, birds, red or orange sky, dark clouds, outlines, visible seams.

**Status:** Needed

## ASSET-308 — River set: far

| Field | Value |
|-------|-------|
| Category | Environment |
| Dimensions | Author 3840×1760 (2×); ship **2880×1320 at 1.5×** as two tiles of 1440×1320, or parallax strips ≤ 2048 wide (ADR-0002). Taller authoring is cropped at export. Tileable horizontally |
| Format | PNG (sRGB, alpha) |
| Naming | `bg_river_far.png` |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1.5× shipped (ADR-0002: author 2×, ship 1.5×); R19b ≤ 1440×1320 per tile file |

**Visual Description:** Low rolling blue-green hills and a wide river bend glinting in simple light bands, with faint rice-field strips on the far bank. The silhouettes are soft, aerial-perspective pale and outline-free, with no buildings that could be read as a claimed place.

**Anchoring (ADR-0002):** the layer is anchored to the ground line (bottom of the tile); the code-drawn sky band, not this layer, fills any height above 1320.

**Art Bible Anchors:**
- §4 Per-area temperature "River": cool and fresh, blue-greens, simple band reflections.
- §6 Far: low detail, low contrast.

**Generation Prompt:** Wide horizontally tileable side-scrolling game background layer, distant low rolling blue-green hills and a wide calm river bend with simple light-band reflections, faint rice field strips, pale hazy morning colours, transparent sky area. Modern kids' cartoon, flat colours with soft gradients, no outlines, low contrast. Palette anchors #3E8FC4, #7CB342 (softened).
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, characters, citadel, temples, pagodas, detailed buildings, outlines, seams.

**Status:** Needed

## ASSET-309 — River set: mid (wharf and boats)

| Field | Value |
|-------|-------|
| Category | Environment |
| Dimensions | Author 3840×1760 (2×); ship **2880×1320 at 1.5×** as two tiles of 1440×1320, or parallax strips ≤ 2048 wide (ADR-0002). Taller authoring is cropped at export. Tileable horizontally |
| Format | PNG (sRGB, alpha) |
| Naming | `bg_river_mid.png` |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1.5× shipped (ADR-0002: author 2×, ship 1.5×); R19b ≤ 1440×1320 per tile file |

**Visual Description:** A busy wharf: a timber jetty on posts, 2–3 moored wooden boats with woven-bamboo canopies, bamboo clumps, banana plants and a few curved-eave thatched or tiled roofs. All architecture and boat forms are ⟨placeholder⟩. Water is drawn in simple flat bands and it uses soft thin outlines. Everything stays above the ground line so the play band is clear.

**Anchoring (ADR-0002):** the layer is anchored to the ground line (bottom of the tile); the code-drawn sky band, not this layer, fills any height above 1320.

**Art Bible Anchors:**
- §6 Beat 1: a busy wharf with boats; Vietnamese first (bamboo, banana leaves, wide rivers).
- §3 Environment geometry: long horizontals with bamboo vertical rhythm; gentle curved eaves.
- §6 Mid: medium detail and contrast.

**Generation Prompt:** Wide horizontally tileable side-scrolling game background layer, a lively Vietnamese riverside wharf in the 13th century: timber jetty on posts, two or three moored wooden boats with woven bamboo canopies, bamboo clumps, banana plants, a few low houses with gently upswept roof eaves, calm river in flat bands. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, soft thin warm-brown outlines #4A3428, Vietnamese motifs as accents. Clear morning light, medium contrast, transparent sky.
Negative: text, letters, signs, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, people, modern boats, motors, Chinese or Japanese temple styles, seams.

**Status:** Needed

## ASSET-310 — River set: play ground

| Field | Value |
|-------|-------|
| Category | Environment |
| Dimensions | Author 3840×1760 (2×); ship **2880×1320 at 1.5×** as two tiles of 1440×1320, or parallax strips ≤ 2048 wide (ADR-0002). Taller authoring is cropped at export. Tileable horizontally |
| Format | PNG (sRGB, alpha) |
| Naming | `bg_river_ground.png` |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1.5× shipped (ADR-0002: author 2×, ship 1.5×); R19b ≤ 1440×1320 per tile file |

**Visual Description:** A packed-earth riverbank path `#C9A57A` ⟨proposed⟩ with a bold, continuous rice-green `#7CB342` grass lip on its top edge and a slightly darker earth band below. It is sparse: a few pebbles only, and nothing that looks like a hazard. It has the highest contrast in the set, and the HUD pads sit over its lower half.

**Anchoring (ADR-0002):** the layer is anchored to the ground line (bottom of the tile); the code-drawn sky band, not this layer, fills any height above 1320.

**Art Bible Anchors:**
- §3 Environment geometry: one clear continuous walkable band with a bold top edge.
- §6 Play: clear edges, highest contrast, sparse props.

**Generation Prompt:** Horizontally tileable side-scrolling game ground strip, a smooth packed-earth riverbank path #C9A57A with a bold continuous green grass edge #7CB342 on top, a few small pebbles, darker earth below, flat and level. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, bold warm ink-brown top outline #4A3428. Clear morning light, transparent above the ground.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, holes, rocks, puddles, slopes, clutter, seams.

**Status:** Needed

## ASSET-311 — River set: foreground (optional)

| Field | Value |
|-------|-------|
| Category | Environment |
| Dimensions | Author 3840×1760 (2×); ship **2880×1320 at 1.5×** as two tiles of 1440×1320, or parallax strips ≤ 2048 wide (ADR-0002). Taller authoring is cropped at export. Tileable horizontally |
| Format | PNG (sRGB, alpha) |
| Naming | `bg_river_fg.png` |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1.5× shipped (ADR-0002: author 2×, ship 1.5×); R19b ≤ 1440×1320 per tile file |

**Visual Description:** Sparse clumps of reeds and grass tips along the bottom edge, at 60–80% opacity, softly blurred and outline-free. They are spaced at least one screen-third apart.

**Art Bible Anchors:**
- §6 Foreground: low detail, partly transparent, must never hide the hero or an enemy.

**Generation Prompt:** Horizontally tileable foreground overlay strip for a side-scrolling game, a few sparse clumps of river reeds and grass tips along the bottom edge only, soft and slightly blurred, muted green, transparent elsewhere. Modern kids' cartoon, flat colours with soft gradients, no outlines. Palette anchor #7CB342 (darkened).
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, tall plants, dense coverage, flowers, characters.

**Status:** Needed

## ASSET-312 — River set: meeting gate and royal canopy (end set-piece)

| Field | Value |
|-------|-------|
| Category | Environment |
| Dimensions | Author 3840×1760 (2×); ship **2880×1320 at 1.5×** as two tiles of 1440×1320, or parallax strips ≤ 2048 wide (ADR-0002). Taller authoring is cropped at export. Tileable horizontally |
| Format | PNG (sRGB, alpha) |
| Naming | `bg_river_gate.png` |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1.5× shipped (ADR-0002: author 2×, ship 1.5×); R19b ≤ 1440×1320 per tile file |

**Visual Description:** A **closed** timber gate with upswept eaves and two solid doors, and behind it, half-visible, a raised royal canopy on dark lacquer-brown posts `#7A3B2A` ⟨proposed; kept off vermilion so the hero stays the warmest accent⟩ with a bronze-gold `#E8A93B` roof trim. Both are ⟨placeholder: the Trần court setting is to be sourced; no specific building is claimed⟩. It is dignified and calm, and the gate is wide enough that the hero stops before it. The guards are separate characters (not specced here).

**Anchoring (ADR-0002):** the layer is anchored to the ground line (bottom of the tile); the code-drawn sky band, not this layer, fills any height above 1320.

**Art Bible Anchors:**
- §6 Beat 2: a closed gate with a royal canopy; no specific building claimed as historical.
- §1 Principle 1: respect and dignity for the court.
- §4 Budget: the hero should usually carry the vermilion; the set-piece doesn't compete.

**Generation Prompt:** Side-scrolling game set-piece, side view, a closed wooden gate with gently upswept roof eaves and two solid doors, and behind it a raised royal canopy pavilion on dark lacquer-brown posts #7A3B2A with bronze-gold roof trim #E8A93B, by a riverbank, dignified and calm, 13th-century Vietnamese style. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428, Vietnamese motifs as accents. Clear morning light, transparent background.
Negative: text, letters, signs, plaques, calligraphy, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, people, open gate, Chinese imperial palace, Japanese torii, dragons.

**Status:** Needed

## ASSET-313 — Village set: far sky

| Field | Value |
|-------|-------|
| Category | Environment |
| Dimensions | Author 3840×1760 (2×); ship **2880×1320 at 1.5×** as two tiles of 1440×1320, or parallax strips ≤ 2048 wide (ADR-0002). Taller authoring is cropped at export. Tileable horizontally |
| Format | PNG (sRGB, alpha) |
| Naming | `bg_village_sky.png` |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1.5× shipped (ADR-0002: author 2×, ship 1.5×); R19b ≤ 1440×1320 per tile file |

**Visual Description:** A warm late-morning sky that is softer and warmer than the river sky: pale blue graded to a straw-gold haze, with round puffy clouds. It has no outlines and low contrast.

**Sky band and safe area (ADR-0002):** above this tile the game draws a vertical gradient band from `themes.json` `village.sky_band` (top `#A9D3EC` → bottom `#CDE6EE`). The tile's **top ~10% (≈130 px at 1.5×) fades into `#CDE6EE`**, so there's no seam. Key elements (sun, cloud bands, sun shafts) stay **below ~15% from the tile's top**. No vertical parallax.

**Art Bible Anchors:**
- §4 Per-area temperature "Countryside": warm-neutral, soft sky, the "home" palette.
- §6 Far sky.

**Generation Prompt:** Wide horizontally tileable side-scrolling game background layer, warm late-morning countryside sky, soft gradient from pale blue to straw-gold haze, a few round puffy clouds. Modern kids' cartoon, flat colours with soft gradients, no outlines, low contrast. Palette anchors #3E8FC4 (pale), #E8A93B (pale haze). The top 10% fades smoothly into flat #CDE6EE; sun, clouds and light shafts stay in the lower 85%.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, red or orange sky, storm, characters, outlines, seams.

**Status:** Needed

## ASSET-314 — Village set: far

| Field | Value |
|-------|-------|
| Category | Environment |
| Dimensions | Author 3840×1760 (2×); ship **2880×1320 at 1.5×** as two tiles of 1440×1320, or parallax strips ≤ 2048 wide (ADR-0002). Taller authoring is cropped at export. Tileable horizontally |
| Format | PNG (sRGB, alpha) |
| Naming | `bg_village_far.png` |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1.5× shipped (ADR-0002: author 2×, ship 1.5×); R19b ≤ 1440×1320 per tile file |

**Visual Description:** Flat green rice fields in long horizontal strips, low blue hills beyond and a distant line of bamboo groves. It is soft, pale and outline-free.

**Anchoring (ADR-0002):** the layer is anchored to the ground line (bottom of the tile); the code-drawn sky band, not this layer, fills any height above 1320.

**Art Bible Anchors:**
- §3 Environment geometry: long calm horizontals (rice fields).
- §6 Far layer.

**Generation Prompt:** Wide horizontally tileable side-scrolling game background layer, wide green rice fields in long horizontal strips, low soft blue hills beyond, a distant line of bamboo groves, hazy and pale. Modern kids' cartoon, flat colours with soft gradients, no outlines, low contrast. Palette anchors #7CB342, #3E8FC4 (softened).
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, people, buildings, citadel, outlines, seams.

**Status:** Needed

## ASSET-315 — Village set: mid (home and courtyard edge)

| Field | Value |
|-------|-------|
| Category | Environment |
| Dimensions | Author 3840×1760 (2×); ship **2880×1320 at 1.5×** as two tiles of 1440×1320, or parallax strips ≤ 2048 wide (ADR-0002). Taller authoring is cropped at export. Tileable horizontally |
| Format | PNG (sRGB, alpha) |
| Naming | `bg_village_mid.png` |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1.5× shipped (ADR-0002: author 2×, ship 1.5×); R19b ≤ 1440×1320 per tile file |

**Visual Description:** The family home: a timber house with a curved tiled roof `#B5673F` ⟨proposed terracotta⟩ and a veranda, a low bamboo fence, banana plants, a lotus pot and an areca palm. Architecture is ⟨placeholder⟩. It has soft thin outlines and warm-neutral colour, with everything above the ground line.

**Anchoring (ADR-0002):** the layer is anchored to the ground line (bottom of the tile); the code-drawn sky band, not this layer, fills any height above 1320.

**Art Bible Anchors:**
- §6 Setting: a family home and courtyard; Vietnamese first (bamboo, banana leaves, lotus).
- §6 Beat 3: a home courtyard.

**Generation Prompt:** Wide horizontally tileable side-scrolling game background layer, a warm Vietnamese family home of the 13th century: timber house with a gently curved tiled roof #B5673F and a veranda, low bamboo fence, banana plants, an areca palm, a lotus pot. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, soft thin warm-brown outlines #4A3428, Vietnamese motifs as accents. Late-morning warm light, transparent sky.
Negative: text, letters, signs, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, people, modern house, palace, Chinese or Japanese temple, seams.

**Status:** Needed

## ASSET-316 — Village set: play ground (training courtyard)

| Field | Value |
|-------|-------|
| Category | Environment |
| Dimensions | Author 3840×1760 (2×); ship **2880×1320 at 1.5×** as two tiles of 1440×1320, or parallax strips ≤ 2048 wide (ADR-0002). Taller authoring is cropped at export. Tileable horizontally |
| Format | PNG (sRGB, alpha) |
| Naming | `bg_village_ground.png` |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1.5× shipped (ADR-0002: author 2×, ship 1.5×); R19b ≤ 1440×1320 per tile file |

**Visual Description:** A swept, packed-earth courtyard `#D2B48A` ⟨proposed⟩ with a bold top edge and a few faint broom-sweep arcs. It has a lighter, even area where the dummies (ASSET-301, every 300 px) and the banner pole (ASSET-305) stand, and no other props.

**Anchoring (ADR-0002):** the layer is anchored to the ground line (bottom of the tile); the code-drawn sky band, not this layer, fills any height above 1320.

**Art Bible Anchors:**
- §3: one clear continuous walkable band with a bold top edge.
- §6 Play: sparse props, highest contrast.

**Generation Prompt:** Horizontally tileable side-scrolling game ground strip, a smooth swept packed-earth courtyard #D2B48A with faint broom-sweep arcs, bold continuous top edge, flat and level, nothing on it. Modern kids' cartoon, flat colours with soft gradients, bold warm ink-brown top outline #4A3428. Warm morning light, transparent above the ground.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, props, stones, puddles, slopes, seams.

**Status:** Needed

## ASSET-317 — Village set: foreground (optional)

| Field | Value |
|-------|-------|
| Category | Environment |
| Dimensions | Author 3840×1760 (2×); ship **2880×1320 at 1.5×** as two tiles of 1440×1320, or parallax strips ≤ 2048 wide (ADR-0002). Taller authoring is cropped at export. Tileable horizontally |
| Format | PNG (sRGB, alpha) |
| Naming | `bg_village_fg.png` |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1.5× shipped (ADR-0002: author 2×, ship 1.5×); R19b ≤ 1440×1320 per tile file |

**Visual Description:** An occasional banana-leaf tip and a low tuft of grass at the bottom edge, at 60–80% opacity, softly blurred and outline-free.

**Art Bible Anchors:**
- §6 Foreground: partly transparent, never hides the hero or an enemy.

**Generation Prompt:** Horizontally tileable foreground overlay strip for a side-scrolling game, a few sparse banana leaf tips and low grass tufts along the bottom edge only, soft and slightly blurred, muted green, transparent elsewhere. Modern kids' cartoon, flat colours with soft gradients, no outlines.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, dense foliage, tall plants, characters.

**Status:** Needed

## ASSET-318 — Camp set: far sky (storm)

| Field | Value |
|-------|-------|
| Category | Environment |
| Dimensions | Author 3840×1760 (2×); ship **2880×1320 at 1.5×** as two tiles of 1440×1320, or parallax strips ≤ 2048 wide (ADR-0002). Taller authoring is cropped at export. Tileable horizontally |
| Format | PNG (sRGB, alpha) |
| Naming | `bg_camp_sky.png` |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1.5× shipped (ADR-0002: author 2×, ship 1.5×); R19b ≤ 1440×1320 per tile file |

**Visual Description:** A windy, dramatic sky of storm-indigo `#3B3F6B` clouds stretched diagonally, with 2–3 broad gold `#E8A93B` sun shafts breaking through toward the ground. The clouds are soft-edged and rounded, not jagged. The sky has no red, orange or lightning in it.

**Sky band and safe area (ADR-0002):** above this tile the game draws a vertical gradient band from `themes.json` `camp.sky_band` (top `#2E3156` → bottom `#3B3F6B`). The tile's **top ~10% (≈130 px at 1.5×) fades into `#3B3F6B`**, so there's no seam. Key elements (sun, cloud bands, sun shafts) stay **below ~15% from the tile's top**. No vertical parallax.

**Art Bible Anchors:**
- §2 Battle beat: a cool world with a storm-indigo sky, gold shafts lighting the hero; never a red sky.
- §3 Battle variant: clouds stretch diagonally.

**Generation Prompt:** Wide horizontally tileable side-scrolling game background layer, a windy dramatic sky with soft rounded storm-indigo clouds #3B3F6B stretched diagonally, broad warm gold sun shafts #E8A93B breaking through, brave and exciting rather than frightening. Modern kids' cartoon, flat colours with soft gradients, no outlines. The top 10% fades smoothly into flat #3B3F6B; sun, clouds and light shafts stay in the lower 85%.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, red sky, orange sky, fire, smoke, lightning, jagged clouds, darkness, seams.

**Status:** Needed

## ASSET-319 — Camp set: far

| Field | Value |
|-------|-------|
| Category | Environment |
| Dimensions | Author 3840×1760 (2×); ship **2880×1320 at 1.5×** as two tiles of 1440×1320, or parallax strips ≤ 2048 wide (ADR-0002). Taller authoring is cropped at export. Tileable horizontally |
| Format | PNG (sRGB, alpha) |
| Naming | `bg_camp_far.png` |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1.5× shipped (ADR-0002: author 2×, ship 1.5×); R19b ≤ 1440×1320 per tile file |

**Visual Description:** Dark blue-grey hills and a wide, dark river with a few tiny plain banner silhouettes on poles along the far bank. The banners are ⟨placeholder⟩, plain cloth with no symbols, and stand for the army ahead. It is low contrast and outline-free.

**Anchoring (ADR-0002):** the layer is anchored to the ground line (bottom of the tile); the code-drawn sky band, not this layer, fills any height above 1320.

**Art Bible Anchors:**
- §4 Per-area temperature "Battle": the world shifts cool, with a dark river.
- §6 Far layer; Luan rule 2 (banners plain).

**Generation Prompt:** Wide horizontally tileable side-scrolling game background layer, distant cool blue-grey hills and a wide dark river under a stormy sky, a few tiny plain banner silhouettes on poles along the far bank, hazy. Modern kids' cartoon, flat colours with soft gradients, no outlines, low contrast. Palette anchors #3B3F6B, #3E8FC4 (darkened).
Negative: text, letters, symbols on banners, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, soldiers, fire, smoke, burning, ruins, seams.

**Status:** Needed

## ASSET-320 — Camp set: mid (windswept riverbank)

| Field | Value |
|-------|-------|
| Category | Environment |
| Dimensions | Author 3840×1760 (2×); ship **2880×1320 at 1.5×** as two tiles of 1440×1320, or parallax strips ≤ 2048 wide (ADR-0002). Taller authoring is cropped at export. Tileable horizontally |
| Format | PNG (sRGB, alpha) |
| Naming | `bg_camp_mid.png` |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1.5× shipped (ADR-0002: author 2×, ship 1.5×); R19b ≤ 1440×1320 per tile file |

**Visual Description:** A wind-whipped river with rounded curling wave crests, and reeds, bamboo and grass all leaning in one direction (to the right). It includes a pair of beached wooden boats ⟨placeholder⟩ and gold light catching the wave tops. The colours are cool, it uses soft thin outlines, and there are no figures.

**Anchoring (ADR-0002):** the layer is anchored to the ground line (bottom of the tile); the code-drawn sky band, not this layer, fills any height above 1320.

**Art Bible Anchors:**
- §2 Battle mood carrier: the wind (water lines and grass lean one way).
- §3 Battle variant: wave crests curl, while the ground band stays level.
- §6 Beat 4: an open riverbank under a windy sky; no damage, fire or bodies.

**Generation Prompt:** Wide horizontally tileable side-scrolling game background layer, a wind-whipped river with rounded curling wave crests, reeds, bamboo and tall grass all leaning to the right, two beached wooden boats, warm gold light catching the wave tops under a storm-indigo sky #3B3F6B. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, soft thin warm-brown outlines #4A3428, Vietnamese motifs as accents. Transparent sky.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, people, wrecked boats, fire, smoke, arrows, red water, seams.

**Status:** Needed

## ASSET-321 — Camp set: play ground

| Field | Value |
|-------|-------|
| Category | Environment |
| Dimensions | Author 3840×1760 (2×); ship **2880×1320 at 1.5×** as two tiles of 1440×1320, or parallax strips ≤ 2048 wide (ADR-0002). Taller authoring is cropped at export. Tileable horizontally |
| Format | PNG (sRGB, alpha) |
| Naming | `bg_camp_ground.png` |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1.5× shipped (ADR-0002: author 2×, ship 1.5×); R19b ≤ 1440×1320 per tile file |

**Visual Description:** An open, **level** riverbank of damp earth `#A88A68` ⟨proposed⟩ with a bold grass lip whose blades lean right. It is lit warm along the top edge so the band reads against the cool background. The Trần flag (ASSET-303) is placed on it at the beat's end, and there are no other props.

**Anchoring (ADR-0002):** the layer is anchored to the ground line (bottom of the tile); the code-drawn sky band, not this layer, fills any height above 1320.

**Art Bible Anchors:**
- §3 Battle variant: the ground band stays level and readable.
- §2: cool world, warm hero. The warm rim light on the hero is an engine lighting task for the technical-artist, not painted here.

**Generation Prompt:** Horizontally tileable side-scrolling game ground strip, an open level riverbank of damp earth #A88A68 with a bold continuous grass edge leaning right in the wind, warm gold light along the top edge, flat and level, nothing on it. Modern kids' cartoon, flat colours with soft gradients, bold warm ink-brown top outline #4A3428. Transparent above the ground.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, mud splashes, debris, dropped weapons, holes, slopes, red, seams.

**Status:** Needed

## ASSET-322 — Camp set: foreground (optional)

| Field | Value |
|-------|-------|
| Category | Environment |
| Dimensions | Author 3840×1760 (2×); ship **2880×1320 at 1.5×** as two tiles of 1440×1320, or parallax strips ≤ 2048 wide (ADR-0002). Taller authoring is cropped at export. Tileable horizontally |
| Format | PNG (sRGB, alpha) |
| Naming | `bg_camp_fg.png` |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1.5× shipped (ADR-0002: author 2×, ship 1.5×); R19b ≤ 1440×1320 per tile file |

**Visual Description:** Sparse windswept grass tufts and a few drifting leaves along the bottom edge, all leaning right, at 60–80% opacity, softly blurred and outline-free.

**Art Bible Anchors:**
- §6 Foreground: partly transparent, never hides the hero or an enemy.
- §2 Battle: everything in the environment moves.

**Generation Prompt:** Horizontally tileable foreground overlay strip for a side-scrolling game, a few sparse windswept grass tufts and drifting leaves along the bottom edge only, leaning right, soft and slightly blurred, cool muted green, transparent elsewhere. Modern kids' cartoon, flat colours with soft gradients, no outlines.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, dense coverage, tall plants, arrows, sparks, embers.

**Status:** Needed

---

*ASSET-323–326 written by game-art-content (TASK-014 follow-up, the leader's request), in the same lean format.*

## ASSET-323 — Story buttons: "Tiếp / Next" and "Bỏ qua / Skip"

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | Tiếp: 9-slice pill, base 360×144 at 2×; Bỏ qua: 9-slice pill, base 240×104 at 2× (smaller) |
| Format | PNG (sRGB, alpha) |
| Naming | ui_btn_next.png, ui_btn_next_pressed.png, ui_btn_skip.png, ui_btn_skip_pressed.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** "Tiếp" is a bold pill in star gold `#FFC531` with a thick ink outline
`#3A2A20` and a small right-pointing arrow icon at its right end, so it reads as "go on" without
words. "Bỏ qua" is a smaller, quieter pill in panel cream `#FFF6E3` with a thin ink outline and a
double-chevron icon, so the child's eye goes to "Tiếp" first (mission-flow UI: Skip smaller and
bottom-left, Tiếp bottom-right). **"Smaller" means narrower and quieter, not shorter:** both pills
are drawn ≥ `pad_min` tall on the same row (Input Rule 4; `design/ux/story-screens.md` §5.2). The pressed states squash 4% and darken 8%. Labels are text layers.

**Art Bible Anchors:**
- §7 UI: rounded pills, thick outlines, icons with a distinct shape; no text in art
- §4 UI palette: star gold `#FFC531` for the primary action, panel cream for the secondary

**Generation Prompt:** Two mobile game UI buttons on a transparent background, modern kids' cartoon,
flat colours with soft gradients, thick warm ink-brown outline (#3A2A20). Left: a small rounded pill
in cream (#FFF6E3) with a double right-chevron icon at one end. Right: a larger rounded pill in warm
golden yellow (#FFC531) with a single right-pointing arrow icon at its right end and an empty
centre for a text label. Soft top highlight, gentle drop shadow. Negative: text, letters, numbers,
watermark, red, metallic chrome, sharp corners, photorealistic, anime.

**Status:** Needed

---

## ASSET-324 — Skip-warning card

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 9-slice card, base 960×560 at 2×, centred over the story screen with a 40% dim behind |
| Format | PNG (sRGB, alpha) |
| Naming | ui_card_skip_warning.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A rounded panel-cream card with a thin bronze-drum ring border (frame
motif, §3) and the outline medal (ASSET-037/`ui_medal_missing`) at its top centre, so a pre-reader
sees "this is about the medal". It has room for one line (`ui.story.skip_warning`) and two
buttons: "Đọc tiếp / Keep reading" (gold, big, right, the default) and "Vẫn bỏ qua / Skip anyway"
(cream, smaller, left). No red, no warning triangle, no exclamation mark: the tone is gentle
(mission-flow Core Rule 15).

**Art Bible Anchors:**
- §2 story-scene mood (warm, hushed); §3 drum ring as a frame; §4 UI palette, no red
- §7 hierarchy: the default action is the most prominent

**Generation Prompt:** A mobile game dialog card on a transparent background, modern kids' cartoon,
flat colours with soft gradients. A large rounded rectangle in warm cream (#FFF6E3) with a thick
ink-brown outline (#3A2A20) and a thin decorative bronze-drum concentric ring band (#E8A93B) inset
along its border. At the top centre, a round medal shown as an outline only (#B9802A), with a
short ribbon. Large empty space in the middle for text and two empty button slots at the bottom.
Negative: text, letters, numbers, red, warning sign, exclamation mark, skull, watermark, sharp
corners, photorealistic, anime.

**Status:** Needed

---

## ASSET-325 — Training checklist icons (dummy, shield, banner)

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 3 icons × 2 states (empty / done), 128×128 each at 2× |
| Format | PNG (sRGB, alpha) |
| Naming | ui_check_dummy_empty.png, ui_check_dummy_done.png, ui_check_shield_empty.png, ui_check_shield_done.png, ui_check_banner_empty.png, ui_check_banner_done.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** Three small round badges shown in a row under the goal line during the
training beat (mission-flow UI): a straw dummy, a round shield, and a banner on a pole. Empty is an
ink outline on cream; done is filled with colour (dummy straw `#D8B86A`, shield rattan `#C9A15E`,
banner vermilion accent `#D64A2E`), plus a small rice-green tick. Fill versus outline is the
colour-blind backup (§4). No words.

**Art Bible Anchors:**
- §4 colour-blind safety: fill vs outline plus a tick shape
- §7 icons: filled, rounded, illustrated; no thin outline-only icons in the done state

**Generation Prompt:** A set of six small round mobile game icons on a transparent background,
modern kids' cartoon, flat colours, thick warm ink-brown outlines (#4A3428). Three subjects: a
straw training dummy, a round rattan shield, a small cloth banner on a pole. Each shown twice:
once as an outline only on cream (#FFF6E3), once filled with colour (straw #D8B86A, rattan
#C9A15E, vermilion #D64A2E) with a small green tick (#3FA34D) at the lower right. Negative: text,
letters, numbers, watermark, blood, weapons with blades, photorealistic, anime.

**Status:** Needed

---

## ASSET-326 — Hold-meter fill pulse and done flash

| Field | Value |
|-------|-------|
| Category | VFX |
| Dimensions | 6-frame ring pulse, 256×256 per frame at 2× (fits around the special pad ASSET in mission-hud) |
| Format | PNG (sRGB, alpha) sprite sheet |
| Naming | vfx_meter_pulse_01.png … vfx_meter_pulse_06.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A soft gold `#E8A93B` glow that expands slightly from the meter ring at
25/50/75/100% (mission-flow Game Feel), then fades in about 0.3 s. At 100% it adds a few small
lotus-petal sparkles. It is soft and slow, never flashing faster than 3 Hz (accessibility).

**Art Bible Anchors:**
- §4 bronze gold means reward / interactive
- §2 mission beat mood; §7 UI animation 0.15–0.3 s; no flashing

**Generation Prompt:** Sprite sheet of six frames on a transparent background, a soft golden glow
ring (#E8A93B) expanding gently outward and fading, the last frames with a few small soft lotus
petal sparkles, modern kids' cartoon VFX, flat soft gradients, no outlines. Negative: text,
lightning, fire, explosion, red, harsh flash, photorealistic, anime.

**Status:** Needed

---

*ASSET-327–332 added by game-art-content for TASK-016, the Bình Than exchange scene (`dialogue` beat). The script was approved by Luan on 2026-11-14.*

## ASSET-327 — Portrait: Trần Quốc Toản (neutral, pleading, determined)

| Field | Value |
|-------|-------|
| Category | Sprite / UI |
| Dimensions | Author 512×512 (2×); ship 384×384 at 1.5× (ADR-0002) |
| Format | PNG (sRGB, alpha) |
| Naming | portrait_tqt_hero.png, portrait_tqt_hero_pleading.png, portrait_tqt_hero_determined.png → ids `pic.portrait_tran-quoc-toan_hero[_pleading/_determined]` |
| Replaces | new |
| Texture Res | 1.5× shipped; R19b ≤ 2048 |

**Visual Description:** A head-and-shoulders bust of the same boy as the hero sheet (ASSET-101):
round face, topknot, vermilion headband with its two tails, cream tunic ⟨placeholder⟩, facing
**right** (he stands on the left of the dialogue). Neutral is calm and attentive. Pleading has
raised brows, hands together at the chest, and an earnest open mouth. Determined has set brows,
a firm mouth and a chin up: brave, never angry at anyone. **Determined means eyes fully open,
brows down and in, mouth set**; never half-closed or narrowed eyes, which read as sleepy
(Android QC r3, on the placeholder). **Use on the title hero card (D-27):** the slice card uses
`…_hero_determined`; the neutral `…_hero` replaces it on the card when final art lands
(`design/ux/title.md` §5.5). Same proportions and palette as the
sprite sheet, so the child sees one character.

**Art Bible Anchors:**
- §5 expressions: earnest and brave, never goofy or scary
- §4 vermilion as an accent only (headband, sash); skin `#F1C9A0` (D-18)

**Generation Prompt:** Modern kids' cartoon character portrait, head and shoulders, a brave
13th-century Vietnamese boy of about 15 with a big round head, kind eyes, a black topknot and a
vermilion headband (#D64A2E) with two flowing tails, cream cross-collar tunic (#F3E6C8) with gold
trim (#E8A93B), facing right, soft rounded shapes, flat colours with soft gradients, warm
ink-brown outlines (#4A3428), transparent background. Three expressions: calm; pleading with
hands together at the chest; determined with chin up. Negative: text, letters, watermark, anime,
photorealistic, angry snarl, tears, weapons, scary face.

**Status:** Needed

---

## ASSET-328 — Portrait: palace guard

| Field | Value |
|-------|-------|
| Category | Sprite / UI |
| Dimensions | Author 512×512 (2×); ship 384×384 at 1.5× |
| Format | PNG (sRGB, alpha) |
| Naming | portrait_tqt_guard.png → id `pic.portrait_tran-quoc-toan_guard` |
| Replaces | new |
| Texture Res | 1.5× shipped |

**Visual Description:** A friendly, sturdy Trần palace guard, facing **left**: a round face, a
small kind moustache, and a simple helmet or cap of the **Trần side**. It is clearly **not** the
enemy dome-helmet family (ASSET-201–206), and it has no slate-violet. His uniform is in the hero's
team colours, muted: straw `#D8C9A3` with a muted vermilion `#B9705C` sash ⟨placeholder⟩. A spear
is held **upright**, its tip out of frame. His expression is firm but kind, a gentle "not now"
with one hand raised palm out. Never rough or mocking.

**Art Bible Anchors:**
- §5 neutral NPCs are friendly; guards raise a hand, not a weapon
- §3 no weapon pointed at the viewer; Luan's rule 1 (faces in the same style as everyone)

**Generation Prompt:** Modern kids' cartoon character portrait, head and shoulders, a kind sturdy
Vietnamese palace guard of the Trần dynasty era, round face, small moustache, simple rounded cap,
straw-coloured tunic (#D8C9A3) with a muted red sash (#B9705C), one hand raised palm-out in a
gentle "stop" gesture, an upright spear tip out of frame, facing left, firm but friendly
expression, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines
(#4A3428), transparent background. Negative: text, letters, watermark, angry face, shouting,
weapon pointed at viewer, dome helmet, conical hat, purple, anime, photorealistic.

**Status:** Needed

---

## ASSET-329 — Portrait: the king (symbolic, Trần Nhân Tông)

| Field | Value |
|-------|-------|
| Category | Sprite / UI |
| Dimensions | Author 512×512 (2×); ship 384×384 at 1.5× |
| Format | PNG (sRGB, alpha) |
| Naming | portrait_tqt_king.png (+ portrait_tqt_king_smiling.png for line 8) → ids `pic.portrait_tran-quoc-toan_king[_smiling]` |
| Replaces | new |
| Texture Res | 1.5× shipped |

**Visual Description:** **A symbolic image, not a likeness** (Luan, 2026-11-14): a dignified,
warm king facing **left**. He has a **Trần-era royal headdress** ("vương miện"; the period form
is ⟨placeholder⟩ until a source is checked, and it must **never** be a European crown), a full
neat beard, **thick brows**, kind eyes and calm authority. His robe is in rich gold `#E8A93B`
with a deep lacquer-brown `#7A3B2A` trim; the motif and the form are ⟨placeholder⟩. The neutral
pose is upright and composed. The smiling variant (line 8, praising Quốc Toản) has warm eyes and
a gentle smile, never comic.

**Art Bible Anchors:**
- §5 respectful portrayal: dignified, never comic; a teacher must be comfortable
- §4 gold for honour; no red dominance
- Pillar *True to history*: a symbolic image, and every period detail is ⟨placeholder⟩

**Generation Prompt:** Modern kids' cartoon portrait, head and shoulders, a dignified and kind
Vietnamese king of the 13th-century Trần dynasty, symbolic and not a real likeness, a
traditional Vietnamese royal headdress (not a European crown), full neat black beard, thick
eyebrows, warm calm eyes, a rich gold robe (#E8A93B) with deep lacquer-brown trim (#7A3B2A),
facing left, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines
(#4A3428), transparent background. Variant: gentle proud smile. Negative: text, letters,
watermark, European crown, Chinese emperor costume, stern scary face, comic, anime,
photorealistic, real person likeness.

**Status:** Needed

---

## ASSET-330 — Dialogue boxes (speaker and narrator)

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 9-slice; speaker box base 720×200 and narrator box 880×200, in world px at 1× (`dialogue_line` field); author 2× |
| Format | PNG (sRGB, alpha) |
| Naming | ui_dialogue_speaker_left.png, ui_dialogue_speaker_right.png, ui_dialogue_narrator.png |
| Replaces | new |
| Texture Res | 1.5× shipped |

**Visual Description:** Speaker boxes are rounded cream `#FFF6E3` panels with a thick ink outline
and a small tail pointing to the portrait's side. Narrator boxes are centred, with no tail and
the warm paper frame of the story screen (ASSET-035), so narration reads differently from speech.
No text in art.

**Art Bible Anchors:**
- §7 UI rounded panels; the story frame motif (§3 drum ring) on the narrator box only

**Generation Prompt:** Three mobile game dialogue boxes on a transparent background, modern kids'
cartoon UI, cream rounded panels (#FFF6E3) with thick warm ink-brown outlines (#3A2A20): one with
a small speech tail on the left, one with the tail on the right, and one centred panel with no
tail and a thin bronze-drum ring border (#E8A93B). Empty centres for text. Negative: text,
letters, red, sharp corners, photorealistic.

**Status:** Needed

---

## ASSET-331 — Ask button ("Xin vào! / Let me in!")

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 9-slice pill, base 400×150 at 2× (bigger than "Tiếp", ASSET-323) |
| Format | PNG (sRGB, alpha) |
| Naming | ui_btn_ask.png, ui_btn_ask_pressed.png |
| Replaces | new |
| Texture Res | 1.5× shipped |

**Visual Description:** A big, inviting pill in star gold `#FFC531` with a thick ink outline and
an icon of two hands raised together (asking), on the left. The label is a text layer; the words
are story Text, Quốc Toản's own speech. Pressed: a 4% squash. It gently pulses when the hint
fires (Hints GDD).

**Art Bible Anchors:**
- §7 UI: the primary action is the most prominent; one icon plus a distinct shape

**Generation Prompt:** A large rounded pill button on a transparent background, warm golden
yellow (#FFC531), thick warm ink-brown outline (#3A2A20), a small icon of two hands raised
together at the left end, an empty centre for a label, a soft highlight. Modern kids' cartoon UI.
Negative: text, letters, red, sharp corners, photorealistic.

**Status:** Needed

---

## ASSET-332 — Meeting-gate scene background (dialogue)

| Field | Value |
|-------|-------|
| Category | Environment |
| Dimensions | Uses the river set's play layers with the gate set-piece (ASSET-312) centred; no new tile |
| Format | — (composition note) |
| Naming | — |
| Replaces | — |
| Texture Res | — |

**Visual Description:** The dialogue plays over the closed meeting gate and royal canopy
(ASSET-312), dimmed 30% behind the boxes and portraits so the faces read first. No new art is
needed; this is a layout note for `/ux-design`.

**Status:** Needed (layout only)

## ASSET-333 — Skip-warning button icons (open book, skip arrow)

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 1× 48×48, 2× 96×96 each, drawn inside the ASSET-323 pills beside the label |
| Format | PNG (sRGB, alpha) |
| Naming | ui_icon_keep_reading.png, ui_icon_skip_anyway.png |
| Replaces | new (TASK-020 W20) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** Two simple icons that let a pre-reader tell the skip-warning buttons
apart without the words (Language Rule 12). **Keep reading:** an open book, seen from the front,
cream pages with two short ink lines per page (no letters). **Skip anyway:** a double chevron
pointing right (»), plain ink. Both use the thick ink-brown outline and no colour that implies a
warning. The book sits on the gold default button; the arrow on the smaller cream one.

**Art Bible Anchors:**
- §4 UI palette, no red; §7 icons back up text
- Mission flow UI (skip warning), `design/ux/story-screens.md`

**Generation Prompt:** Flat mobile game UI icons, modern kids' cartoon style, soft rounded shapes, flat colours, thick warm ink-brown outline (#3A2A20). Two separate icons on a transparent background: (1) a small open book seen from the front, cream pages (#FFF6E3) with two short plain ink lines on each page; (2) a chunky rounded double chevron pointing right, ink-brown. Centred, flat light. Negative: text, letters, numbers, red, warning sign, exclamation mark, watermark, photorealistic, anime, thin line icon, sharp corners.

**Status:** Needed

## ASSET-334 — Leave-the-story card ("Về bản đồ?")

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | Reuses the ASSET-324 9-slice card (960×560 at 2×) with a different top picture; the top picture 1× 120×120, 2× 240×240 |
| Format | PNG (sRGB, alpha) |
| Naming | ui_card_leave_top.png (the card itself is `ui_card_skip_warning.png`) |
| Replaces | new (TASK-020 W18) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** The pause menu's "Về bản đồ" opens this card over the dimmed pause
menu. The top picture is a small folded map with a dotted path running back to a house shape, so
a pre-reader sees "going home". Below it: one line (`ui.pause.leave_confirm`, proposed string)
and two buttons: "Chơi tiếp / Keep playing" (gold, big, right, the default, with the ▶ play icon)
and "Về bản đồ / To the map" (cream, smaller, left, with a small map icon). No red, no warning
sign.

**Art Bible Anchors:**
- §4 UI palette, no red; §7 hierarchy: the default action is the most prominent
- Mission flow Rule 11, `design/ux/pause.md`

**Generation Prompt:** Flat mobile game UI icon, modern kids' cartoon style, soft rounded shapes, flat colours with a soft gradient, thick warm ink-brown outline (#3A2A20). A small folded paper map in cream (#FFF6E3) with soft green and blue areas and a dotted ink path leading back to a tiny rounded house shape. Centred, transparent background, flat light. Negative: text, letters, numbers, red, warning sign, exclamation mark, compass rose with letters, watermark, photorealistic, anime, sharp corners.

**Status:** Needed

## ASSET-335 — Special pad icon: clenched fist (hold-meter)

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | Icon layer inside ASSET-027, 1× 56×56, 2× 112×112 |
| Format | PNG (sRGB, alpha) |
| Naming | ui_pad_special_icon_fist.png (training keeps the banner icon) |
| Replaces | new (TASK-020 W17, A3) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** The special pad's icon is set per beat type (Mission flow Rule 7c). On a
hold-meter beat it is a **small clenched fist** seen from the front, a child's hand, cream with an
ink outline, so holding the pad reads as "squeeze hard" rather than "hold the flag" before the
banner exists. The pad's star-edged rim and gold fill (ASSET-027) are unchanged. Whether the
fist is right for the orange moment's tone (anger or determination, claim C06) is Luan's call
(D-34); the icon is neutral, never an angry face.

**Art Bible Anchors:**
- §5 "never a scary face"; §7 one icon per pad
- ASSET-027, `design/ux/hud.md`

**Generation Prompt:** Flat mobile game UI icon, modern kids' cartoon style, soft rounded shapes, flat colours, thick warm ink-brown outline (#3A2A20). A small child's clenched fist seen from the front, warm cream skin tone, chunky rounded fingers. Centred, transparent background, flat light. Negative: text, letters, numbers, blood, injury, weapon, angry face, punching motion lines, watermark, photorealistic, anime, sharp corners, adult hand.

**Status:** Needed
