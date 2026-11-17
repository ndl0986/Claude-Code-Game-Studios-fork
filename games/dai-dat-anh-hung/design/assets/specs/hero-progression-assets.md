# Asset Specs — System: Hero Progression & Unlock

> **Source**: design/gdd/hero-progression.md
> **Art Bible**: design/art/art-bible.md
> **Generated**: 2026-11-14 · Task: TASK-014
> **Review**: lean mode. art-director wrote the specs; technical-artist was skipped, so technical constraints were not validated. Sizes follow art bible §8 as set by game-art-content.
> **Status**: 3 assets specced / 0 approved / 0 in production / 0 done

---

## ASSET-036 — Medal: earned

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 1× 128×128, 2× 256×256 |
| Format | PNG (sRGB, alpha) |
| Naming | ui_medal_earned.png |
| Replaces | new (the slice draws the medal in code) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A round bronze-drum medal filling the upper two-thirds of the canvas, with a short two-tail ribbon below it. The disc is bronze gold `#E8A93B` with a lighter centre. It shows a raised sun-star of soft rounded rays at the centre, then one plain ring and one simple tick band, all in a darker bronze `#B9802A`. The ribbon is in the hero's colour, flat vermilion `#D64A2E` for Trần Quốc Toản, with V-notched rounded tails. Everything has a thick outline `#3A2A20`. The ray count and band pattern are ⟨placeholder⟩ until the motif is sourced. The same art is reused on the skip-warning card.

**Art Bible Anchors:**
- §3 UI shape grammar: the bronze-drum ring as the signature frame for rewards
- §4: bronze gold for reward and heritage; vermilion only as a flat, clean area
- §1 P3: no text or numerals on the medal

**Generation Prompt:** Flat mobile game reward icon, modern kids' cartoon style, soft rounded shapes, flat colours with soft gradients, thick warm ink-brown outline (#3A2A20), Vietnamese motifs as accents. A single round medal inspired by a Đông Sơn bronze drum face: a bronze-gold disc (#E8A93B) with a lighter centre, a raised central sun star with soft rounded rays, one plain ring and one simple tick band in darker bronze (#B9802A). Hanging below, a short flat vermilion (#D64A2E) ribbon with two rounded V-notched tails. Front view, centred, transparent background, flat even light with one soft highlight. Negative: text, letters, numbers, Chinese characters, watermark, blood, gore, scary faces, photorealistic, anime, birds, human figures, busy pattern, sharp star points, metallic chrome, 3D render, drop shadow.

**Status:** Needed

---

## ASSET-037 — Medal: not earned (outline)

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 1× 128×128, 2× 256×256 |
| Format | PNG (sRGB, alpha) |
| Naming | ui_medal_missing.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** The exact silhouette of ASSET-036, disc and ribbon, as a thick ink outline `#3A2A20` around a pale cream fill `#FFF6E3` at 50% opacity. Only the outer ring and the centre sun-star are kept as faint ink lines, so it reads as "a medal you can still earn". It is never greyed out, cracked or sad.

**Art Bible Anchors:**
- §4 Colour-blind safety: fill vs outline in the same shape
- Mission GDD UI: not earned is encouraging, never a scold
- §1 P3: no text

**Generation Prompt:** Flat mobile game reward icon, modern kids' cartoon style, soft rounded shapes, thick warm ink-brown outline (#3A2A20). A single round medal with a short two-tailed ribbon drawn as an empty outline with a pale translucent cream fill (#FFF6E3), keeping only a faint outer ring and a simple central sun star with rounded rays as thin ink lines. Front view, centred, transparent background, flat light. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, gold fill, grey, cracked, broken, padlock, question mark, sad face, red.

**Status:** Needed

---

## ASSET-038 — Unlock reveal glow

| Field | Value |
|-------|-------|
| Category | VFX |
| Dimensions | 1× 512×512, 2× 1024×1024 |
| Format | PNG (sRGB, alpha) |
| Naming | vfx_unlock_glow.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A soft, round, warm glow placed behind the next hero's figure: a radial falloff from bronze gold `#E8A93B` at about 70% opacity in the centre to fully transparent at the edge. A faint ring of 8 very soft, rounded light petals (lotus-like) sits at mid-radius. There are no hard edges or rays. The reveal is a single, smooth, one-way motion: the figure lifts from a solid ink-brown `#4A3428` silhouette to full colour over about 1.2 s while this glow fades up behind it and settles to a steady hold. Any breathing pulse afterwards is 0.5 Hz or slower, never faster than 3 Hz. The colour lift itself is a tint or shader effect for technical-artist.

**Art Bible Anchors:**
- Hero-progression GDD: the silhouette lifts from shadow into colour; calm, not flashy; no flashing faster than 3 Hz
- §7 Art view: UI animation is bouncy and short, and nothing flashes
- §4: bronze gold for reward

**Generation Prompt:** Game VFX sprite, modern kids' cartoon style, soft rounded shapes, flat colours with soft gradients, Vietnamese motifs as accents. A single soft round warm glow on a transparent background: a radial gradient from warm bronze gold (#E8A93B) in the centre fading smoothly to fully transparent at the edges, with a faint ring of eight very soft rounded lotus-petal shapes of light at mid-radius. Centred, no hard edges, calm and gentle. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, lens flare, light rays, sparkles, stars, hard edges, rainbow, fire, explosion, characters.

**Status:** Needed
