# Asset Specs — System: Side-scroll Movement & Combat

> **Source**: design/gdd/side-scroll-combat.md (Core Rules 6, 10–12; States and Transitions; Visual/Audio; Game Feel)
> **Art Bible**: design/art/art-bible.md
> **Generated**: 2026-11-14 · Task: TASK-014
> **Review**: lean mode. art-director wrote the specs; technical-artist was skipped, so technical constraints were not validated. Sizes follow art bible §8 as set by game-art-content.
> **Portrayal sign-off**: Luan (D-18) before any final art. Trần-era details are ⟨placeholder⟩.
> **Status**: 12 assets specced / 0 approved / 0 in production / 0 done

**Shared conventions for enemies** (apply to ASSET-201, 203, 205):
- **Scale:** 512×512 cells at 2× (256 at 1×), pivot bottom-centre (256, 480). The hero is 360 px tall at 2×. **No enemy pixel, including helmet knob, weapon and pennant, rises above 340 px from the baseline at 2×.** That keeps every enemy shorter than the hero (§3).
- **Facing:** authored **facing left** (toward the hero, §3), and mirrored by the engine for `from_left` spawns. `flee` is authored facing **right** (running away from a hero on the left), and mirrored the same way.
- **Look (⟨placeholder⟩: Mông–Nguyên armour to be sourced):** bean or pear bodies, wide at the bottom. A rounded **dome helmet** `#5F5A7A` with a small round knob, never conical. Padded coat-armour in slate-violet `#7A7395` with lighter panels `#9893AD` and quilted padding `#B8B0A0`. **Faces use the hero's style and skin tones** (`#F1C9A0` / `#DDA982`): dot eyes, a simple mouth, expressions from mildly grumpy to surprised. They are identified only by armour shape, colour and banner. Derived hexes (`#5F5A7A`, `#9893AD`, `#B8B0A0`) are proposals within the §4 `#7A7395` family.
- **States → rows** (from the GDD states table): `walk` (enter + approach; enter plays at 320/140 = 2.3× rate), `windup`, `strike`, `rest`, `hurt`, `flee`. The art bible §5 list (`idle`, `attack`, `knockback`, `run_home`) maps to `rest`, `strike`, `hurt` and `flee`.
- **Weapon reach is a world length, matched to the tuning** (TASK-020 W9 banner review): the
  weapon tip in `strike` reaches **`enemy_reach − stand_gap` = 140 world px** (280 at 2×) in front
  of the enemy's pivot, and the hero's swing arc reaches **`attack_range` = 175** (350 at 2×). If
  a body is scaled to spec height, the weapon keeps this length, so a strike that lands never
  looks like a miss. Final art is authored to it.
- **Body height is a hard cap:** the enemy body (helmet included) ≤ 170 world px (340 at 2×),
  feet on `ground_y`; placeholders follow it too (`design/ux/hud.md` §3.3). Only the weapon and
  pennant may rise above it.
- **Weapons are blunt and padded:** wrapped cloth balls or rounded ends, never a point or edge. They are held across the body or toward the hero, never toward the viewer.
- **Glow, "!" and swirl** are separate VFX (ASSET-207, 208, 212) and are not drawn into frames.

## ASSET-201 — Spear soldier (sprite sheet, all states)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 30 frames, 512×512 cells at 2×; sheet 4096×3072 at 2× (8 cols × 6 rows); figure about 320 px tall at 2× |
| Format | PNG (sRGB, alpha) |
| Naming | `enemy_spear_sheet.png` + frames `enemy_spear_[state]_[nn].png`: walk 01–08 (loop, 83 ms) · windup 01–05 (01–03 build 3 × 80 ms, 04–05 hold loop 2 × 150 ms for the rest of `telegraph` 1.1 s) · strike 01–03 (one-shot over `strike_time` 0.25 s, the jab peaks on 02) · rest 01–04 (loop, 200 ms; `enemy_rest` 1.6 s) · hurt 01–04 (one-shot over `hurt_recover` 0.35 s) · flee 01–06 (loop, 67 ms, no weapon) |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A round bean-shaped soldier with a dome helmet and knob, carrying a padded spear: a short shaft `#8E7E6A` with a big cloth ball `#D9D2C3` on the end, held angled forward-up so the ball stays under the 340 px line. **Windup:** he leans back and draws the spear in, with the cheeks puffed and the brows set (a clear "getting ready" shape). **Strike:** a short forward poke toward the hero. **Hurt:** leans back with the helmet wobbling left, right, then settling, and a surprised "o" mouth. **Flee:** he has turned away, has empty hands, flails his arms and takes big comic steps.

**Art Bible Anchors:**
- §3 Enemy silhouettes: bean shape, rounded dome helmet, blunt oversized weapon, dot eyes, never taller than the hero, faces left.
- §3 / Luan rule 1: no ethnic caricature; identified by armour shape and colour only.
- §5: slow windup pose before every attack, a telegraph a child can read; no defeated or lying-down pose.
- Combat GDD Rules 10–12: windup → strike; hit cancels windup; the last hit leads to the weapon drop and flee.

**Generation Prompt:** Character animation key poses, side view facing left, a round bean-shaped cartoon foot soldier of an invading army in 13th-century Asia, rounded dome helmet #5F5A7A with a small round knob, padded quilted coat-armour in desaturated slate-violet #7A7395 with lighter panels #9893AD, holding a short spear #8E7E6A that ends in a big soft cloth ball #D9D2C3. Simple friendly face, dot eyes, warm skin #F1C9A0, same face style as a Vietnamese kids' cartoon hero, mildly grumpy. Poses: walking, leaning back to get ready, short poke, resting, leaning back surprised with a wobbling helmet, running away with arms flailing and no weapon. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428. Cool soft ambient light, transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, narrow slanted eyes, moustache caricature, sharp spear point, blade, teeth, claws, spikes, red colours, glaring eyes, lying down, falling over, taller than a child hero.

**Status:** Needed

## ASSET-202 — Spear soldier dropped weapon

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 512×256 at 2× (256×128 at 1×), 1 frame |
| Format | PNG (sRGB, alpha) |
| Naming | `prop_drop_spear_01.png`; lies on `ground_y`; the engine fades alpha (not drawn) |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** The padded spear from ASSET-201 lying flat on the ground, angled slightly as if just dropped, with the cloth ball end resting on the ground. There is a soft contact shadow ellipse under it and no break or damage.

**Art Bible Anchors:**
- §3: weapons blunt and oversized like props.
- Combat GDD Rule 12: the weapon stays on the ground and fades.
- §4: no vermilion near an enemy's defeat or on the ground.

**Generation Prompt:** Single prop, slight top-down side view, a short wooden spear #8E7E6A with a big soft cloth ball end #D9D2C3 lying flat on the ground as if just dropped, small soft shadow underneath. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428. Transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, broken weapon, sharp point, hands, person.

**Status:** Needed

## ASSET-203 — Shield soldier (sprite sheet, all states)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 30 frames, 512×512 cells at 2×; sheet 4096×3072 at 2×; figure about 310 px tall at 2× |
| Format | PNG (sRGB, alpha) |
| Naming | `enemy_shield_sheet.png` + `enemy_shield_[state]_[nn].png`; same rows, frame counts and timings as ASSET-201 (walk 8, windup 5, strike 3, rest 4, hurt 4, flee 6) |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A pear-shaped, slightly stouter soldier behind a tall rounded-rectangle wooden shield `#6E6888` with a plain round boss. The shield reaches about 75% of his height, and his helmet and eyes show above it. **Strike** is a shield shove, pushing the shield forward with a little hop. **Hurt** tips the shield back and wobbles the helmet. In **flee** the shield has been dropped, and he runs with his arms flailing. He takes 3 hits, so his hurt frames look sturdier and less startled than the spear soldier's.

**Art Bible Anchors:**
- §3 Enemy silhouettes: pear shape, wide at the bottom, no points; shield rounded at every corner.
- §5: telegraph a child can read (the shield is pulled back in windup).
- Luan rule 1: identified by armour, colour and banner, never facial features.

**Generation Prompt:** Character animation key poses, side view facing left, a pear-shaped cartoon soldier of an invading army in 13th-century Asia behind a tall rounded wooden shield #6E6888 with a plain round boss, rounded dome helmet #5F5A7A with a small knob, padded slate-violet coat-armour #7A7395, simple friendly face with dot eyes, warm skin #F1C9A0, same face style as a Vietnamese kids' cartoon hero. Poses: walking, pulling the shield back to get ready, shield shove, resting, tipping back surprised with a wobbling helmet, running away with arms flailing and no shield. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428. Cool soft light, transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, emblem or writing on shield, spikes, metal studs, sharp corners, red colours, glaring eyes, lying down, taller than a child hero.

**Status:** Needed

## ASSET-204 — Shield soldier dropped shield

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 512×256 at 2× (256×128 at 1×), 1 frame |
| Format | PNG (sRGB, alpha) |
| Naming | `prop_drop_shield_01.png`; lies on `ground_y`; the engine fades it |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** The ASSET-203 shield lying face-up on the ground, tilted slightly toward the camera so the plain boss reads. It is intact, with a soft contact shadow.

**Art Bible Anchors:**
- Combat GDD Rule 12: the dropped weapon stays and fades.
- §4: no red on the ground or near a defeat.

**Generation Prompt:** Single prop, slight top-down side view, a tall rounded wooden shield #6E6888 with a plain round boss lying flat on the ground, intact, soft shadow underneath. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428. Transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, broken, cracked, emblem, writing, person.

**Status:** Needed

## ASSET-205 — Leader (sprite sheet, all states)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 30 frames, 512×512 cells at 2×; sheet 4096×3072 at 2×; figure about 330 px tall (pennant included, ≤ 340) and about 1.4× the spear soldier's width |
| Format | PNG (sRGB, alpha) |
| Naming | `enemy_leader_sheet.png` + `enemy_leader_[state]_[nn].png`; same rows and counts as ASSET-201; walk plays at 0.75× rate (`leader_speed_mul`); windup hold loops for 1.32 s (× 1.2); hurt lean is half the spear soldier's (`leader_knock_mul` 0.5) |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A wide, round dumpling-shaped officer: wider, never taller. He has a broader dome helmet with a slightly larger knob, a quilted coat-armour with a darker belly panel `#5F5A7A`, and a small plain cloth pennant `#5F5A7A` on a short back pole that stays under 340 px. His weapon is a padded club `#8E7E6A` with a cloth-wrapped round head `#D9D2C3`. The windup is a slow, big wind-back so the longer telegraph reads. Hurt is a heavy rock-back with a helmet wobble, and flee is a waddling run, arms flailing, with the pennant bouncing.

**Art Bible Anchors:**
- §3: "a big enemy grows wider, not taller"; dumpling shape; banner as identifier (plain cloth, no symbol).
- Combat GDD Visual/Audio "Leader": wider, not taller (TASK-003 QC rework).
- Luan rule 2: any banner is plain cloth with no painted words.

**Generation Prompt:** Character animation key poses, side view facing left, a wide round dumpling-shaped cartoon officer of an invading army in 13th-century Asia, short and broad, rounded dome helmet #5F5A7A with a small knob, quilted slate-violet coat-armour #7A7395 with a darker belly panel #5F5A7A, small plain cloth pennant on a short pole on his back, holding a padded club #8E7E6A with a soft cloth-wrapped head #D9D2C3. Simple face with dot eyes, warm skin #F1C9A0, same face style as a Vietnamese kids' cartoon hero, mildly grumpy. Poses: waddling walk, slow big wind-back, club bonk, resting, rocking back surprised with a wobbling helmet, waddling away with arms flailing and no club. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428. Cool soft light, transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, tall, towering, looming, symbol or writing on pennant, spiked club, horns, fur cape, beard or moustache caricature, red colours, lying down.

**Status:** Needed

## ASSET-206 — Leader dropped club

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 512×256 at 2× (256×128 at 1×), 1 frame |
| Format | PNG (sRGB, alpha) |
| Naming | `prop_drop_club_01.png`; lies on `ground_y`; the engine fades it |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** The ASSET-205 padded club lying on its side, with the cloth-wrapped head on the ground. It is intact, with a soft contact shadow.

**Art Bible Anchors:**
- §3: blunt, prop-like weapons.
- Combat GDD Rule 12.

**Generation Prompt:** Single prop, slight top-down side view, a short wooden club #8E7E6A with a big soft cloth-wrapped round head #D9D2C3 lying on the ground, intact, soft shadow. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428. Transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, spikes, nails, broken, person.

**Status:** Needed

## ASSET-207 — Telegraph glow ring

| Field | Value |
|-------|-------|
| Category | VFX |
| Dimensions | 6 frames, 512×512 cells at 2× (sits behind the enemy, centred on its body) |
| Format | PNG (sRGB, alpha) |
| Naming | `vfx_telegraph_ring_loop_01…06.png`; loop, 6 × 92 ms (≈ 0.55 s pulse, 2 pulses per 1.1 s telegraph) |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A soft round halo in warm yellow `#FFD54F` ⟨proposed⟩ with a pale cream core `#FFF6E3`, which pulses from 85% to 100% scale and back. It has a smooth radial fade and no rays or spikes. It must read on both the bright river set and the storm-indigo camp set.

**Art Bible Anchors:**
- Combat GDD Visual/Audio: pulsing glow ring, yellow-gold, never red, visible at thumbnail size.
- §4 Red must never read as blood; §7 nothing flashes (a slow pulse, not a strobe).

**Generation Prompt:** Game VFX sprite, a soft round glowing halo ring in warm yellow #FFD54F with a pale cream centre #FFF6E3, smooth radial fade, gentle and friendly, centred, front view. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients. Transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, red, orange, fire, lightning, spikes, sharp rays, lens flare.

**Status:** Needed

## ASSET-208 — Telegraph "!" bubble

| Field | Value |
|-------|-------|
| Category | VFX |
| Dimensions | 4 frames, 256×256 cells at 2×; anchored above the helmet knob |
| Format | PNG (sRGB, alpha) |
| Naming | `vfx_telegraph_bang_01…04.png`; 01–02 pop-in (2 × 50 ms), 03–04 bob loop (2 × 200 ms) |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A round speech-bubble shape in `#FFD54F` with a thick ink-brown `#4A3428` outline and a short rounded tail pointing down at the enemy. Inside is the "!" **drawn as a shape**: a fat rounded-end vertical bar over a round dot, in ink brown. It is not a font glyph. It pops in with a squash and bobs gently.

**Art Bible Anchors:**
- Combat GDD Visual/Audio: "!" bubble visible at thumbnail size, yellow-gold, never red.
- §1 Principle 3 / no text in art: the mark is an icon shape, not a letter.
- §4 Colour-blind safety: shape plus colour, never colour alone.

**Generation Prompt:** Game icon sprite, a round cartoon alert bubble in warm yellow #FFD54F with a thick ink-brown outline #4A3428 and a short rounded tail at the bottom, containing a simple drawn exclamation shape made of a fat rounded vertical bar above a round dot, in ink brown. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients. Front view, centred, transparent background.
Negative: text, letters, font, typography, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, red, triangle warning sign, skull, spikes.

**Status:** Needed

## ASSET-209 — Hit spark (wood-coloured)

| Field | Value |
|-------|-------|
| Category | VFX |
| Dimensions | 5 frames, 256×256 cells at 2×; spawned at the staff's contact point |
| Format | PNG (sRGB, alpha) |
| Naming | `vfx_hit_spark_01…05.png`; one-shot, 5 × 40 ms (0.2 s) |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A small burst of 6–8 rounded teardrop puffs in staff-wood `#A8743F` with light `#E0B57A` highlights. They pop outward from a soft centre, then shrink and fade. The puffs are round-ended, not sharp, and there is no impact star, crack or mark.

**Art Bible Anchors:**
- Combat GDD Visual/Audio "Hit": a soft spark burst in the colour of the staff's wood; no impact marks or injury frames.
- §3: no sharp shapes on things a child looks at closely.
- §4: never red near an enemy at a defeat.

**Generation Prompt:** Game VFX sprite sheet, a soft small burst of rounded teardrop-shaped puffs in warm wood brown #A8743F with light tan highlights #E0B57A, popping outward from a centre then fading, playful and gentle. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428 on the outer puffs only. Transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, red, sharp shards, splinters, cracks, sparks of fire, comic "POW" burst.

**Status:** Needed

## ASSET-210 — Block spark (white)

| Field | Value |
|-------|-------|
| Category | VFX |
| Dimensions | 5 frames, 256×256 cells at 2×; spawned at the hero's shield rim |
| Format | PNG (sRGB, alpha) |
| Naming | `vfx_block_spark_01…05.png`; one-shot, 5 × 40 ms |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A crisp white `#FFFFFF` ring flash with 4–5 short rounded ticks around it and a faint cream `#FFF6E3` outer glow. It expands and fades, and is clearly brighter and more "ting" than the wood hit spark. The "Đỡ được! / Blocked!" pop is a separate text layer.

**Art Bible Anchors:**
- Combat GDD Visual/Audio "Block": a white spark between shield and weapon; the words are a text layer.
- §1 Principle 3: no painted text.

**Generation Prompt:** Game VFX sprite sheet, a crisp white ring flash #FFFFFF with four short rounded ticks around it and a faint cream glow #FFF6E3, expanding and fading, clean and friendly. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients. Transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, red, fire, lightning bolt, sharp shards.

**Status:** Needed

## ASSET-211 — Flee dust puff

| Field | Value |
|-------|-------|
| Category | VFX |
| Dimensions | 6 frames, 256×256 cells at 2×; spawned at the enemy's feet on entering `flee`, and every 2nd step while fleeing |
| Format | PNG (sRGB, alpha) |
| Naming | `vfx_flee_dust_01…06.png`; one-shot, 6 × 60 ms |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** 2–3 round cloud puffs in warm beige `#D9CDB5` with soft shading `#BFB197`. They kick up behind the feet, drift opposite to the run direction, grow and fade. It is a light, comic "zoom away" puff, not smoke.

**Art Bible Anchors:**
- §3: defeat shown as a round "poof" or run-off.
- Combat GDD Rule 12 / Visual/Audio "Run away".

**Generation Prompt:** Game VFX sprite sheet, a few small round cartoon dust cloud puffs in warm beige #D9CDB5 with soft shading #BFB197, kicked up from the ground and drifting backward, growing and fading. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428. Side view, transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, black smoke, fire, explosion, debris.

**Status:** Needed

## ASSET-212 — Dizzy swirl (hurt and flee overlay)

| Field | Value |
|-------|-------|
| Category | VFX |
| Dimensions | 6 frames, 256×256 cells at 2×; anchored on the helmet top |
| Format | PNG (sRGB, alpha) |
| Naming | `vfx_dizzy_swirl_loop_01…06.png`; loop, 6 × 83 ms; shown in `hurt` and `flee` |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A flat oval orbit above the head with three small round dots and one curly spiral in cream `#FFF6E3`, outlined in ink brown, circling around it. It uses **no stars**, because stars mean reward (§3 UI shape grammar). It is shared by all three enemy kinds.

**Art Bible Anchors:**
- Combat GDD States ("hurt: knocked back, leans, dizzy") and Visual/Audio ("dizzy swirl").
- §3 UI shape grammar: stars are reserved for rewards.

**Generation Prompt:** Game VFX sprite sheet, a small cartoon dizzy effect, a flat oval orbit ring with three little round dots and a curly spiral circling it, cream #FFF6E3 with thin ink-brown outlines #4A3428, playful. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients. Side view, transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, stars, birds, red, head, person.

**Status:** Needed
