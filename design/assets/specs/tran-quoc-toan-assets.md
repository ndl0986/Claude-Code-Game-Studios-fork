# Asset Specs — Character: Trần Quốc Toản

> **Source**: design/narrative/heroes/tran-quoc-toan.md (§3 beats, §7 data); design/gdd/side-scroll-combat.md; design/gdd/mission-flow.md
> **Art Bible**: design/art/art-bible.md
> **Generated**: 2026-11-14 · Task: TASK-014
> **Review**: lean mode. art-director wrote the specs; technical-artist was skipped, so technical constraints were not validated. Sizes follow art bible §8 as set by game-art-content.
> **Portrayal sign-off**: Luan (D-18) before any final art. Trần-era details are ⟨placeholder⟩.
> **Status**: 11 assets specced / 0 approved / 0 in production / 0 done

**Shared conventions for this file** (apply to every ASSET below):
- **Scale:** the world is 1280×720 (1×). The hero is about 180 px tall at 1× (25% of screen height) and 360 px at 2×. Cells are 512×512 at 2× (256×256 at 1×). The pivot sits bottom-centre at (256, 480) at 2×, with the feet on that baseline in every frame.
- **Sheet:** `char_tranquoctoan_sheet.png` is 4096×4096 at 2× (2048×2048 at 1×): 8 columns × 8 rows, one row per animation, left-aligned, empty cells transparent. A frame list ships with it (`char_tranquoctoan_frames` ⟨format per engine⟩): row, frame, duration, and the hand anchor for props (banner, orange, staff).
- **Proposed outfit (⟨placeholder⟩, all Trần-era):** a knee-length cross-collar tunic in paper cream `#F3E6C8` with bronze-gold `#E8A93B` collar and hem trim, a vermilion `#D64A2E` headband with two tails, a vermilion sash, trousers `#6B4A36` and cloth shoes `#4A3428`. Skin is `#F1C9A0` with `#DDA982` shading, and the hair is a topknot in `#33241C`. *Today's stand-in (red tunic, red headband) breaks the §4 vermilion budget. The proposal keeps vermilion to the headband and sash, which are the team colour. The choice is on the D-18 look sheet.*
- **Proposed props (⟨placeholder⟩):** a staff in wood `#A8743F` with padded cream cloth ends, and a round rattan shield `#C9A15E` with one bronze-gold ring band (the only motif on him).
- **Signature accent (§3):** the topknot plus the two headband tails sweeping up and back. They must survive a solid-black fill at 48 px tall.
- Engine effects such as the hurt flash tint and the warm rim light are **not drawn into frames**. Those are for the technical-artist.

## ASSET-101 — Hero turnaround and proportion sheet

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 3072×1536 at 2× (3 views × 1024 wide); figure 360 px tall at 2× |
| Format | PNG (sRGB, alpha) |
| Naming | `char_tranquoctoan_turnaround_2x.png` |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 2× only (reference sheet, not shipped in the app) |

**Visual Description:** He is shown front, side (facing right) and back, standing neutral on a shared baseline, with horizontal guide lines at each head height. He is 3 heads tall: the head is one-third of his height, the body is a rounded trapezoid, and the limbs are short and soft. He carries the staff in his right hand and the rattan shield on his left arm. The outfit follows the shared proposal above and is labelled only by line position, since the picture holds no text.

**Art Bible Anchors:**
- §5 Character: about 3 heads tall, big readable eyes, child-sized hero, period dress suggested by 2–3 shapes (headband, collar, sash).
- §3 Hero silhouette: circles with one upward accent (topknot and headband tails) that survives a black fill.
- §4 Red must never read as blood: vermilion only as flat shaped areas (headband, sash).
- §8: one consistent proportion sheet per hero.

**Generation Prompt:** Character turnaround sheet of a brave 12-year-old Vietnamese boy hero from 13th-century Đại Việt: front view, side view facing right, back view, standing in a row on one baseline, with faint horizontal guide lines. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428, Vietnamese motifs as accents. 3 heads tall, big round head, big kind eyes, calm determined smile, topknot, vermilion headband #D64A2E with two tails flowing up and back. Knee-length cross-collar tunic in cream #F3E6C8 with bronze-gold #E8A93B trim, vermilion sash, brown trousers #6B4A36. He holds a wooden staff #A8743F with padded cloth ends, and a round woven rattan shield #C9A15E with one gold ring band. Warm skin #F1C9A0. Even soft daylight, no cast shadows, plain white background.
Negative: text, letters, numbers, labels, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, realistic anatomy, sharp spear tip, armour plates, all-red outfit, muscular, adult proportions.

**Status:** Needed

## ASSET-102 — Hero expression sheet

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 2048×512 at 2× (4 heads × 512×512) |
| Format | PNG (sRGB, alpha) |
| Naming | `char_tranquoctoan_expressions_2x.png`; heads in order: determined, surprised, joyful, puffed |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 2× only (reference sheet; the faces are used in ASSET-103–110) |

**Visual Description:** Four head-and-shoulder views in 3/4 side view facing right. **Determined:** level brows and a small firm mouth (the default). **Surprised:** round eyes, an "o" mouth and raised brows (used for the hit pose). **Joyful:** closed happy eyes and an open smile (cheer). **Puffed:** round puffed cheeks, brows down and lips pressed, which reads as upset but not scary (the orange beat). There are no tears and no teeth bared.

**Art Bible Anchors:**
- §5 Expression: determination, surprise and joy; anger only as puffed cheeks and clenched fists, never tears of rage or a scary face.
- §1 Principle 1: choose the dignified version, so the faces are earnest, never goofy or smirking.

**Generation Prompt:** Expression sheet, four head-and-shoulder portraits of the same Vietnamese boy hero in a row, 3/4 side view facing right: determined, surprised, joyful with eyes closed, and upset with puffed round cheeks. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428, Vietnamese motifs as accents. Topknot, vermilion headband #D64A2E with tails, cream tunic collar #F3E6C8 with gold trim #E8A93B, warm skin #F1C9A0, simple big eyes. Soft even light, transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, tears, crying, teeth bared, glaring, smirk, goofy face, red face.

**Status:** Needed

## ASSET-103 — Hero idle

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 6 frames, 512×512 cells at 2× |
| Format | PNG (sRGB, alpha) |
| Naming | `char_tranquoctoan_idle_01…06.png`; sheet row 1; loop, 6 × 100 ms |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 (256 / 512 cells) |

**Visual Description:** An upright, alert stance facing right, with the staff held upright at his side and the shield on his forearm. The loop is a gentle breath: a 2–3% squash-and-stretch of the body, with the headband tails swaying. The face is determined.

**Art Bible Anchors:**
- §3 Hero silhouette: open, forward-leaning stance facing right.
- §1 Principle 1: upright posture and calm eyes.

**Generation Prompt:** Side view facing right, full body, the same Vietnamese boy hero (3 heads tall, topknot, vermilion headband #D64A2E with tails, cream tunic #F3E6C8 with gold trim #E8A93B, vermilion sash, brown trousers #6B4A36) standing alert and calm, wooden staff #A8743F held upright, round rattan shield #C9A15E on his arm. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428, Vietnamese motifs as accents. Clear morning light, transparent background, centred, feet on the bottom guide.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, front view, cast shadow, background scenery.

**Status:** Needed

## ASSET-104 — Hero run

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 8 frames, 512×512 cells at 2× |
| Format | PNG (sRGB, alpha) |
| Naming | `char_tranquoctoan_run_01…08.png`; sheet row 2; loop, 8 × 67 ms, 2 steps per loop |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** An eager forward-leaning run facing right, with the staff carried diagonally and the shield tucked in. There is a light bounce, with the contact frames on 01 and 05. The headband tails stream back. It is used for walk, walk_to, the run home after the orange, and the move-only beats.

**Art Bible Anchors:**
- §3 Hero silhouette: forward lean and upward accent.
- §5 Animation set: `run`.
- §2 Mission beat: a steady forward rhythm.

**Generation Prompt:** Side view facing right, full body, the same Vietnamese boy hero running eagerly, leaning forward, staff #A8743F carried diagonally, shield #C9A15E tucked to his side, vermilion headband #D64A2E tails streaming behind, cream tunic #F3E6C8 with gold trim #E8A93B. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428, Vietnamese motifs as accents. Run cycle key poses, light bounce, transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, motion blur, speed lines baked in, background scenery.

**Status:** Needed

## ASSET-105 — Hero attack (staff swing)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 6 frames, 512×512 cells at 2× |
| Format | PNG (sRGB, alpha) |
| Naming | `char_tranquoctoan_attack_01…06.png`; sheet row 3; one-shot, 0.28 s (`attack_time`), ~47 ms per frame; **contact frame 03** (hit at 45% = 0.126 s) |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** 01: the staff draws back over the shoulder. 02: a short anticipation squash. 03: a flat forward-upward sweep at chest height with the body stretched, and the padded end reaching the cell's right edge (the contact frame). 04–06: follow-through and recovery to the idle stance. The swing moves outward and upward and never points at the viewer. The face is determined.

**Art Bible Anchors:**
- §3 Hero silhouette: attack poses extend outward and upward.
- §5 Animation set: `attack`, one swing. (§5 says "about 0.3 s wind-up". The GDD's whole swing is 0.28 s, so the frames follow the GDD.)
- Combat GDD Game Feel: the hit reads as instant (0.126 s).

**Generation Prompt:** Side view facing right, full body, the same Vietnamese boy hero swinging a padded wooden staff #A8743F forward in a smooth horizontal-upward arc, body stretched, determined face, vermilion headband #D64A2E tails flying, cream tunic #F3E6C8, rattan shield #C9A15E on his other arm. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428, Vietnamese motifs as accents. Squash-and-stretch key poses, wind-up, contact, follow-through, transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, sharp blade, spear tip, angry snarl, impact marks, opponent in frame.

**Status:** Needed

## ASSET-106 — Hero defend (shield up, held)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 4 frames, 512×512 cells at 2× |
| Format | PNG (sRGB, alpha) |
| Naming | `char_tranquoctoan_defend_01…04.png`; sheet row 4; 01–02 raise (2 × 50 ms), 03–04 hold loop (2 × 200 ms) while defend is held; reverse 02→01 on release |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** He crouches slightly with the round rattan shield raised in front of his chest and face, peeking over the rim with firm eyes. The silhouette becomes a compact round mass, with the staff tucked behind. The hold loop is a tiny steady breath, so the shield edge stays still. The block spark (ASSET-210) appears at the shield's front rim.

**Art Bible Anchors:**
- §3 Hero silhouette: defend poses become a compact round shield shape.
- §4 Semantic usage: defend is calm, but the hero stays warm. River blue belongs to the UI pad, not the costume.

**Generation Prompt:** Side view facing right, full body, the same Vietnamese boy hero crouching slightly behind a raised round woven rattan shield #C9A15E with one gold ring band #E8A93B, peeking over the rim with brave calm eyes, staff #A8743F tucked behind, vermilion headband #D64A2E, cream tunic #F3E6C8. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428, Vietnamese motifs as accents. Compact round silhouette, transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, fearful face, cowering, metal shield, spikes.

**Status:** Needed

## ASSET-107 — Hero special-hold (the orange)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 6 frames, 512×512 cells at 2× |
| Format | PNG (sRGB, alpha) |
| Naming | `char_tranquoctoan_specialorange_01…06.png`; sheet row 5; **scrubbed by the meter**, frame = 1 + floor(meter × 5), holds on release (the meter does not drain) |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** He stands facing right, holding the orange (ASSET-304, attached at the hand anchor) in one hand at chest height. The staff and shield are not carried in this beat. Across 01→06 the feeling rises: the shoulders lift, the free fist clenches, the cheeks puff, the brows lower and the body stretches up on its toes. Frame 06 is the peak, a puffed-cheek "upset" face that is never scary. It is followed by the run home (ASSET-104).

**Art Bible Anchors:**
- §5 Expression: anger shown with puffed cheeks and clenched fists only.
- Mission-flow Visual/Audio: the hero's pose builds with the gold meter.
- §1 Principle 1: bad feelings shown, never shamed or made silly.

**Generation Prompt:** Side view facing right, full body, the same Vietnamese boy hero standing and holding a round orange in one hand at chest height, his feelings rising: shoulders lifting, other fist clenched, cheeks puffed, brows down, rising onto his toes. Six key poses from calm to peak. Vermilion headband #D64A2E, cream tunic #F3E6C8 with gold trim #E8A93B, warm skin #F1C9A0, no staff, no shield. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428, Vietnamese motifs as accents. Soft warm light, transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, tears, crying, shouting, teeth, red face, steam from head, juice on clothes, mess.

**Status:** Needed

## ASSET-108 — Hero special (banner raise, training)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 8 frames, 512×512 cells at 2× (the banner pole extends beyond the cell; it is a separate prop) |
| Format | PNG (sRGB, alpha) |
| Naming | `char_tranquoctoan_specialbanner_01…08.png`; sheet row 6; one-shot, 8 × 83 ms (0.67 s), holds 08; per-frame hand anchor in the frame list |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** Two hands grip the banner pole (ASSET-305, drawn separately, attached at the hand anchor). He lifts it from a low crouch (01–03), pushes it up (04–06) and plants it overhead with his chest out and a joyful, determined face (07–08). The staff and shield are on his back. The pole angle per frame matches the banner's "raising" frames.

**Art Bible Anchors:**
- §3 Hero silhouette: the raised banner as the upward signature.
- §3 Historical banner text and §7: the banner is plain cloth, with the words as a game text layer.
- §2 Victory: mood carrier is "the unfurling banner".

**Generation Prompt:** Side view facing right, full body, the same Vietnamese boy hero gripping a tall wooden pole with both hands and raising it overhead in stages, from crouch to proud stretch, joyful determined face, vermilion headband #D64A2E tails flying, cream tunic #F3E6C8 with gold trim #E8A93B, staff and round rattan shield on his back. Pole only, no cloth. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428, Vietnamese motifs as accents. Golden morning light, transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, flag cloth, writing on banner, spear tip on pole.

**Status:** Needed

## ASSET-109 — Hero hit (surprised flash pose)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 4 frames, 512×512 cells at 2× |
| Format | PNG (sRGB, alpha) |
| Naming | `char_tranquoctoan_hit_01…04.png`; sheet row 7; one-shot over `hurt_time` 0.5 s (100 / 150 / 150 / 100 ms); the flash tint is applied by the engine |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** 01: a startled squash with the surprised face (ASSET-102). 02: a small hop back with the feet off the baseline by about 20 px at 2×. 03: lands and blinks. 04: recovers to the determined face. There is no pain, wince, mark, dust on the body or fall. The child keeps control, so the pose must blend back to idle or run. The same frames are used for the walk-beat "bump" stop.

**Art Bible Anchors:**
- §5 Animation set: `hit` is a small knock-back hop and a blink, no injury shown.
- Combat GDD Visual/Audio "Pushed": surprise only, no pain face.

**Generation Prompt:** Side view facing right, full body, the same Vietnamese boy hero doing a small startled hop backwards, round surprised eyes, "o" mouth, arms out for balance, staff #A8743F and rattan shield #C9A15E held, vermilion headband #D64A2E, cream tunic #F3E6C8. Light comic surprise, not hurt. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428, Vietnamese motifs as accents. Transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, pain, wince, tears, bruise, falling down, lying down, impact star on body.

**Status:** Needed

## ASSET-110 — Hero cheer

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 6 frames, 512×512 cells at 2× |
| Format | PNG (sRGB, alpha) |
| Naming | `char_tranquoctoan_cheer_01…06.png`; sheet row 8; 01–04 one-shot (4 × 83 ms), then 05–06 loop (2 × 150 ms) until the walk-on |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A small jump with the staff raised high in one hand and the free fist up, and the joyful face. He lands upright and proud, and the loop is a gentle double fist-pump. The beat-end sparkle (ASSET-306) plays on the HUD, not on him.

**Art Bible Anchors:**
- §5 Animation set: `cheer` at the end of a beat.
- §2 Victory: the hero standing tall, pride and joy.

**Generation Prompt:** Side view facing right, full body, the same Vietnamese boy hero cheering, small jump, wooden staff #A8743F raised high, free fist up, eyes closed in a big happy smile, vermilion headband #D64A2E tails flying, cream tunic #F3E6C8 with gold trim #E8A93B, rattan shield #C9A15E on his arm. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428, Vietnamese motifs as accents. Golden light, transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, defeated enemies, gloating, taunting.

**Status:** Needed

## ASSET-111 — Followers (band of 3 villager-soldiers)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 3 variants (a, b, c) × 18 frames, 512×512 cells at 2×; figures about 270–290 px tall at 2× (75–80% of the hero) |
| Format | PNG (sRGB, alpha) |
| Naming | `char_follower_[a\|b\|c]_[idle 01…04 \| run 01…08 \| cheer 01…06].png`; sheet `char_follower_[a\|b\|c]_sheet.png` 4096×1536 at 2× (rows idle, run, cheer); run matches the hero's 67 ms timing |
| Replaces | "new" (no placeholder exists; the apps draw these in code today) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** Three smaller, rounder village youths who walk behind the hero and cheer. They wear the team colour as a desaturated vermilion `#B9705C` headband and sash over straw-beige tunics `#D8C9A3` and trousers `#7A6250`. Each one is told apart by shape: (a) round and stocky with a short padded stick, (b) tall-thin but still shorter than the hero, with a bamboo pole and no tip, (c) a girl with a hair bun and a rice-straw shield. Same skin tones as the hero, simple faces, no gold trim.

**Art Bible Anchors:**
- §5 Followers: smaller and rounder than the hero; the hero's team colour, desaturated; walk behind and cheer.
- §3 Hero vs. supporting shapes: simpler silhouettes and lower saturation; only the hero has full-saturation warm accents.

**Generation Prompt:** Side view facing right, full body, three friendly Vietnamese village youths from 13th-century Đại Việt, rounder and shorter than the hero: one stocky with a short padded stick, one slim with a bamboo pole, one girl with a hair bun and a small straw shield. Muted vermilion headbands and sashes #B9705C, straw-beige tunics #D8C9A3, brown trousers #7A6250, warm skin #F1C9A0. Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines #4A3428, Vietnamese motifs as accents. Idle, running and cheering key poses, transparent background.
Negative: text, letters, watermark, blood, gore, injury, weapons pointed at viewer, scary faces, exaggerated ethnic features, conical hat, photorealistic, anime, bright red clothes, gold trim, taller than the hero, sharp weapons, armour.

**Status:** Needed
