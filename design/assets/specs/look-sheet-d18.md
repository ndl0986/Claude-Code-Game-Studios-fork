# Asset Specs — Character: Look sheet for D-18 (hero and enemies)

> **Source**: design/assets/specs/tran-quoc-toan-assets.md, side-scroll-combat-assets.md, mission-flow-assets.md
> **Art Bible**: design/art/art-bible.md
> **Generated**: 2026-11-14 · Task: TASK-014
> **Review**: lean mode. art-director wrote the specs; technical-artist was skipped, so technical constraints were not validated. Sizes follow art bible §8 as set by game-art-content.
> **Portrayal sign-off**: Luan (D-18) before any final art. Trần-era details are ⟨placeholder⟩.
> **Status**: 0 assets specced (summary sheet) / 0 approved / 0 in production / 0 done

## Hero: Trần Quốc Toản (ASSET-101–111)
A brave, earnest boy about 3 heads tall, with a big round head and kind eyes, facing right. He is
the warmest thing on screen. He is never goofy, and his "angry" face is puffed cheeks only.
- **Clothing** ⟨placeholder⟩: a cross-collar knee-length tunic in cream `#F3E6C8`, gold trim `#E8A93B`, trousers `#6B4A36`.
- **Colours:** vermilion `#D64A2E` only on the headband and sash (the team colour); skin `#F1C9A0`.
- **Headwear** ⟨placeholder⟩: a topknot and a vermilion headband whose two tails are his signature shape.
- **Weapon** ⟨placeholder⟩: a staff `#A8743F` with padded ends; a round rattan shield `#C9A15E` with one gold ring.
- **Followers:** 3 smaller youths in muted vermilion `#B9705C` sashes on straw-beige tunics.

**Luan, please answer:**
1. Red tunic (today's stand-in) or a cream tunic with vermilion accents only? *Recommended: accents only (§4 budget).*
2. Staff or short spear? *Recommended: staff (blunt, matches the "padded" rule).*
3. Topknot and headband: is that right for a Trần youth, or what should he wear on his head?
4. Is one follower being a girl acceptable for the story (his "family and followers")?

## Enemies: Mông–Nguyên soldiers (ASSET-201–206)
They are round, bottom-heavy and mildly grumpy, never scary, and always shorter than the hero. Their faces are
drawn in **the same style and skin tones as the hero**. They are identified only by armour shape,
colour and a plain banner.
- **Shared:** a rounded dome helmet `#5F5A7A` with a small knob (**no conical hat**); padded coat-armour in slate-violet `#7A7395` ⟨placeholder⟩.
- **Spear** (2 hits): a bean shape with a short spear ending in a cloth ball `#D9D2C3`.
- **Shield** (3 hits): a pear shape behind a tall rounded wooden shield `#6E6888`, plain boss, no emblem.
- **Leader** (3 hits): about 1.4× wider, never taller; a padded club; a small plain pennant on his back.
- **Defeat:** he leans back, his helmet wobbles, he drops his weapon and runs home. Nobody ever lies down.

**Luan, please answer:**
5. Is a dome helmet with a knob plus quilted coat-armour acceptable as a ⟨placeholder⟩ for Mông–Nguyên troops?
6. Is the slate-violet family right, or should it be more grey?
7. Should the leader's pennant stay (it is the "banner" identifier) or be dropped?

## Story props
- **Hero's banner:** plain vermilion cloth with a gold border; the six words are a VI/EN text layer.
- **Trần army flag** ⟨placeholder⟩: gold cloth with a vermilion border, no symbols. 8. Is this a reasonable stand-in?

## Palette additions for Luan's approval (outside the art bible §4 palette)

The art bible fixes 7 primary colours and a UI palette. The specs need these extra colours. They
are all proposals; approve them as a whole or change a row.

**New meaning (need a decision):**
| Swatch | Hex | Used for | Why / risk |
|---|---|---|---|
| warm yellow | `#FFD54F` | Enemy telegraph glow and "!" bubble | Keeps "warning" apart from bronze gold `#E8A93B`, which means reward/interact. Never red |
| enemy slate light | `#9893AD` | Lighter panels on enemy armour | Close to the wrong-answer lavender `#9C8FB8`. They're on different screens, but check that it doesn't confuse |
| enemy helmet | `#5F5A7A` | Dome helmets | The darker slate family for enemies |
| ending haze | `#9FB8C8` | Calm-ending sky haze | Soft, cool, respectful (§2 "calm ending") |
| medal bronze | `#B9802A` | Medal ring detail | A darker bronze so the medal reads as metal, not a star |

**Sky bands** (code-drawn above each background, `content/data/themes.json`, ADR-0002):
| Theme | Top → bottom | Matches |
|---|---|---|
| river | `#9CCBEA` → `#BFE0F2` | Clear morning sky (ASSET-307) |
| village (and the unused bamboo) | `#A9D3EC` → `#CDE6EE` | Warm late-morning sky (ASSET-313) |
| camp | `#2E3156` → `#3B3F6B` | Storm-indigo battle sky (ASSET-318) |

**Skin, hair and people:**
| Hex | Used for |
|---|---|
| `#F1C9A0` | Skin for **everyone**: hero, followers, enemies, the hint hand (one tone, so no group is marked by skin) |
| `#33241C` | Hair (topknot) |
| `#6B4A36` / `#7A6250` | Trousers (hero / others) |
| `#D8C9A3` · `#B9705C` | Follower tunic · follower sash (desaturated vermilion) |

**Quiz picture colours:**
| Hex | Used for |
|---|---|
| `#D9A441` · `#6FA8D6` · `#C98B6B` | Q1 flags: Trần ochre-gold · Lý sky blue · Lê clay (balanced so the right answer doesn't stand out; QC G4) |
| `#5F8A8B` · `#8B7A66` | Helmet b teal-grey · helmet c taupe (Q5 distractors) |
| `#F29A2E` | The orange: the **same** in the quiz picture and the beat-2 prop |
| `#F5D04A` · `#8E9A4A` | Banana · coconut (muted olive, so no green competes with "correct") |
| `#C9A66B` | Quiz child's straw tunic |

**Materials (earth, wood, straw, buildings), to approve as a family:**
`#A8743F` staff wood · `#C9A15E` rattan · `#8E7E6A` / `#8E6B45` shafts and rope · `#D9D2C3` padded
cloth ball · `#B8B0A0` / `#BFB197` quilting · `#D8B86A` straw · `#D2B48A` / `#C9A57A` / `#A88A68`
ground · `#B5673F` roof tiles · `#7A3B2A` lacquer-brown posts · `#D9CDB5` / `#E0B57A` / `#DDA982`
clouds and light · `#FFD27A` juice · `#FFFFFF` block spark.

9. **Approve these palette additions** (or mark the rows to change)?

## The Bình Than exchange scene (TASK-016): portraits (ASSET-327–329)

- **Quốc Toản:** the same boy as the hero sheet, in three expressions (calm, pleading,
  determined), facing right.
- **Guard:** a kind, sturdy Trần guard in the hero's team colours (never the enemy dome-helmet or
  slate-violet family). One hand raised palm-out; the spear upright and out of frame.
- **King (Trần Nhân Tông):** a **symbolic image, not a likeness** (Luan, 2026-11-14): a Trần-era
  royal headdress ⟨placeholder; never a European crown⟩, a full beard, thick brows, warm eyes, a
  gold robe with lacquer-brown trim. There's a smiling variant for his praise line.

10. **Approve the three portraits' direction?** In particular: the king's headdress form (to be
    sourced; what should it look like?), and the guard's cap (Trần side, distinct from the
    enemies).
