# Asset Specs — System: Mission HUD

> **Source**: design/gdd/mission-flow.md
> **Art Bible**: design/art/art-bible.md
> **Generated**: 2026-11-14 · Task: TASK-014
> **Review**: lean mode. art-director wrote the specs; technical-artist was skipped, so technical constraints were not validated. Sizes follow art bible §8 as set by game-art-content.
> **Status**: 12 assets specced / 0 approved / 0 in production / 0 done

Also draws on `design/gdd/hints-and-onboarding.md` (Visual/Audio) for ASSET-033 and ASSET-034.

**Shared pad rules (ASSET-024–027):** pads are at least `pad_min` 72 pt/dp. Author them at 1× 96×96 and 2× 192×192, with about 8% transparent margin. Each pad has its own **outer shape** and its own **icon**, so nothing depends on colour (§4, §7 UX). Each in-mission pad carries **exactly one** motif accent, placed on the rim and never under the icon (Luan rule 4). The squash on press, the hint pulse and the gold hint rim are done in code, not baked in. Every pad uses a thick outline `#3A2A20` (8 px at 2×) and flat, untextured fills (§4 UI palette). Icons are filled and rounded, in panel cream `#FFF6E3` with an ink outline (§7).

---

## ASSET-024 — Move pads (◀ ▶)

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 1× 96×96, 2× 192×192 each |
| Format | PNG (sRGB, alpha) |
| Naming | ui_pad_move_left.png, ui_pad_move_right.png |
| Replaces | new (the slice draws pads in code) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A rounded "bullet" shape: a pill whose leading end is a broad, softly rounded point in the direction of travel. The fill is neutral panel cream `#FFF6E3`, and a big chunky ink-brown `#3A2A20` triangular arrow with rounded corners sits in the centre. The one motif accent is a short arc of bronze-drum tick marks in bronze gold `#E8A93B` on the rim at the tail end. The right pad is the left pad mirrored exactly.

**Art Bible Anchors:**
- §4 UI palette: move pad `#FFF6E3` with ink arrows, kept neutral so the action pads lead
- §3 / §7 UX: a distinct outer shape (directional bullet vs circle, shield and star ring)
- Luan rule 4: plain shape with one motif accent

**Generation Prompt:** Flat mobile game UI button, modern kids' cartoon style, soft rounded shapes, flat colours with a minimal soft gradient, thick warm ink-brown outline (#3A2A20), Vietnamese motifs as accents. A single chunky directional button shaped like a rounded pill with a broad softly rounded point on the left end, flat light cream fill (#FFF6E3), a big bold rounded ink-brown triangle arrow pointing left in the centre, and one short arc of small bronze-gold (#E8A93B) bronze-drum tick marks on the rim at the right end. Centred, transparent background, flat even light. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, thin outline icon, sharp corners, busy pattern, drop shadow, glossy 3D bevel.

**Status:** Needed

---

## ASSET-025 — Attack pad

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 1× 96×96, 2× 192×192 |
| Format | PNG (sRGB, alpha) |
| Naming | ui_pad_attack.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A plain circle, the round shape set aside for attack, filled tangerine `#F07F1E` with a lighter inner top highlight. The icon is a short, thick, blunt wooden staff in a diagonal swing with a small motion arc behind it, filled in panel cream with an ink outline. The one motif accent is a small bronze-drum sun-star bead (rounded rays) at the top of the rim. The hero's weapon is ⟨placeholder⟩, and the icon is a staff, not a blade.

**Art Bible Anchors:**
- §4 UI palette: attack `#F07F1E`, kept apart from the world's vermilion
- §4 Colour-blind safety: attack is round, special is a star-edged ring
- §3 Enemy silhouettes / Safe for kids: a blunt, prop-like weapon with no blade

**Generation Prompt:** Flat mobile game UI button, modern kids' cartoon style, soft rounded shapes, flat colours with a minimal soft gradient, thick warm ink-brown outline (#3A2A20), Vietnamese motifs as accents. A single round circular button, flat tangerine orange fill (#F07F1E) with a lighter top highlight. In the centre, a chunky cream (#FFF6E3) icon of a short blunt wooden staff swinging diagonally with a small soft motion arc. One small bronze-drum sun-star bead with rounded rays (#E8A93B) sits at the top of the rim. Centred, transparent background, flat even light. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, sword, blade, spear point, fist punching a face, red, sharp edges, glossy 3D bevel, drop shadow.

**Status:** Needed

---

## ASSET-026 — Defend pad

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 1× 96×96, 2× 192×192 |
| Format | PNG (sRGB, alpha) |
| Naming | ui_pad_defend.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** The pad's outer shape is a broad, rounded shield (wide, soft-cornered top, gently rounded bottom point) filled in saturated blue `#2E7FD0`. A cream shield-boss icon sits in the centre. The one motif accent is a single thin bronze-drum concentric ring in bronze gold `#E8A93B` around the boss. It is one clean ring with no inner pattern band, so it reads at 72 pt.

**Art Bible Anchors:**
- §4 UI palette: defend `#2E7FD0`; §4 semantic "calm / defend" goes with the shield icon
- §7 UX: defend is a shield shape
- Luan rule 4: one bronze-drum ring motif as the single accent (see the conflict note in the task reply on §3 "never inside a touch area")

**Generation Prompt:** Flat mobile game UI button, modern kids' cartoon style, soft rounded shapes, flat colours with a minimal soft gradient, thick warm ink-brown outline (#3A2A20), Vietnamese motifs as accents. A single button whose whole outer shape is a broad rounded shield with soft corners and a gently rounded bottom point, flat saturated blue fill (#2E7FD0). In the centre, a round cream (#FFF6E3) shield boss circled by one thin bronze-gold (#E8A93B) Đông Sơn drum ring. Centred, transparent background, flat even light. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, crest, coat of arms, cross, spikes, sharp point, busy pattern, multiple rings, glossy 3D bevel, drop shadow.

**Status:** Needed

---

## ASSET-027 — Special / banner pad

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 1× 96×96, 2× 192×192 (glow layer 1× 128×128, 2× 256×256) |
| Format | PNG (sRGB, alpha) |
| Naming | ui_pad_special.png, ui_pad_special_glow.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** The outer shape is a star-edged ring: a circle whose rim has 12 soft, rounded bumps like a drum's sun-star. It is filled star gold `#FFC531`. The icon is a small upright banner on a pole, drawn in cream with an ink outline, with a plain cloth and no marks. The star-edged rim **is** the single motif accent, so nothing else is added. A separate soft gold glow layer is shown by code only when the pad is available (hold-meter and training beats only).

**Art Bible Anchors:**
- §3 / §4 Colour-blind safety: special is a star-edged ring with a banner icon, set apart from round attack
- §4 UI palette: special `#FFC531`, glowing only when available
- Luan rule 2: the banner icon carries no words

**Generation Prompt:** Flat mobile game UI button, modern kids' cartoon style, soft rounded shapes, flat colours with a minimal soft gradient, thick warm ink-brown outline (#3A2A20), Vietnamese motifs as accents. A single round button whose rim is shaped like a Đông Sơn bronze-drum sun star with twelve soft rounded bumps, flat bright star-gold fill (#FFC531). In the centre, a chunky cream (#FFF6E3) icon of a small upright plain cloth banner on a pole. Centred, transparent background, flat even light. Negative: text, letters, numbers, Chinese characters on the banner, watermark, blood, gore, scary faces, photorealistic, anime, sharp star points, red, busy pattern, glossy 3D bevel, drop shadow.

**Status:** Needed

---

## ASSET-028 — Hold-meter ring

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 1× 128×128, 2× 256×256 (fits outside the 96/192 special pad) |
| Format | PNG (sRGB, alpha) |
| Naming | ui_meter_ring_track.png, ui_meter_ring_fill.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A thick circular ring that sits just outside the special pad's star bumps with a small clear gap. The **track** is panel cream `#FFF6E3` at 60% opacity with an ink outline. The **fill** is solid bronze gold `#E8A93B` with a lighter inner edge, drawn as a full ring that the game reveals radially, clockwise from 12 o'clock, with no steps. There are no notches or numbers. The 25/50/75/100% pulses are done in code.

**Art Bible Anchors:**
- Mission GDD Visual/Audio: a ring around the special pad that fills in gold (§4 bronze gold)
- §3 UI shape grammar: a circle, rounded ends
- §1 P3: no numbers or percentages in the art

**Generation Prompt:** Flat mobile game UI element, modern kids' cartoon style, soft rounded shapes, flat colours, thick warm ink-brown outline (#3A2A20). A single thick empty circular progress ring with a hollow transparent centre: a solid bronze-gold (#E8A93B) band with a lighter inner edge, an even ink-brown outline inside and out. Centred, transparent background, flat light. Negative: text, letters, numbers, percentage, tick marks, segments, watermark, blood, gore, scary faces, photorealistic, anime, gradient rainbow, glow, button inside.

**Status:** Needed

---

## ASSET-029 — Pause button

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 1× 72×72, 2× 144×144 |
| Format | PNG (sRGB, alpha) |
| Naming | ui_btn_pause.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A rounded square (squircle) in panel cream `#FFF6E3` with a thick ink outline. The icon is two thick, upright, round-ended ink-brown bars. It has no motif: it is a system HUD button, not an action pad, and stays the quietest element top-left.

**Art Bible Anchors:**
- §3 UI shape grammar: rounded, no sharp corners
- §4 UI palette: panel fill and outline
- §1 P2: motifs off the controls nearest the action

**Generation Prompt:** Flat mobile game UI button, modern kids' cartoon style, soft rounded shapes, flat colours, thick warm ink-brown outline (#3A2A20). A single rounded-square button with very soft corners, flat light cream fill (#FFF6E3), a pause icon of two thick upright round-ended ink-brown bars in the centre. Centred, transparent background, flat light. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, patterns, motifs, thin lines, glossy 3D bevel, drop shadow.

**Status:** Needed

---

## ASSET-030 — Sound button (on / off)

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 1× 72×72, 2× 144×144 each |
| Format | PNG (sRGB, alpha) |
| Naming | ui_btn_sound_on.png, ui_btn_sound_off.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** The same rounded square as ASSET-029. **On:** a chunky ink-brown speaker with two rounded sound arcs. **Off:** the same speaker with no arcs and one thick, round-ended diagonal slash across it. It uses a slash, not an "X", because "X" is reserved as never-used for wrong answers.

**Art Bible Anchors:**
- §3 UI shape grammar: rounded, matching pause
- §4 Colour-blind safety: the on/off states differ by icon shape, not colour
- Quiz GDD: no "X" anywhere in the feedback language

**Generation Prompt:** Flat mobile game UI button pair, modern kids' cartoon style, soft rounded shapes, flat colours, thick warm ink-brown outline (#3A2A20). Two rounded-square buttons with very soft corners, flat light cream fill (#FFF6E3). Left: a chunky rounded ink-brown speaker icon with two soft sound arcs. Right: the same speaker with no arcs and one thick round-ended diagonal slash. Each centred on its own transparent canvas, flat light. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, X mark, red, music notes, thin lines, glossy 3D bevel.

**Status:** Needed

---

## ASSET-031 — VI | EN language chip

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 1× 160×72, 2× 320×144 (each half 80×72 at 1×) |
| Format | PNG (sRGB, alpha) |
| Naming | ui_chip_lang_base.png, ui_chip_lang_select.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** **Base:** a pill split into two equal halves by a thin ink divider, with panel cream fill and a thick ink outline. **Select:** a half-pill highlight in bronze gold `#E8A93B`, the size of one half, which the game slides under the chosen language. "VI" and "EN" are live text set by the game, never drawn in the PNG. It lives in the pause menu.

**Art Bible Anchors:**
- §1 P3 / §7: no text in art; labels are a text layer
- §3 UI shape grammar: a pill shape
- §4 Colour-blind safety: the selected half differs by position and fill, not by hue alone

**Generation Prompt:** Flat mobile game UI toggle, modern kids' cartoon style, soft rounded shapes, flat colours, thick warm ink-brown outline (#3A2A20). A single wide pill-shaped toggle split into two equal halves by a thin ink-brown vertical divider, flat light cream fill (#FFF6E3), completely empty with no labels. Separately, one half-pill highlight shape in bronze gold (#E8A93B) with the same outline. Transparent background, flat light. Negative: text, letters, numbers, VI, EN, flags, watermark, blood, gore, scary faces, photorealistic, anime, icons, patterns, glossy 3D bevel.

**Status:** Needed

---

## ASSET-032 — Beat progress dots (empty / filled)

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 1× 28×28, 2× 56×56 each |
| Format | PNG (sRGB, alpha) |
| Naming | ui_dot_beat_empty.png, ui_dot_beat_filled.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** **Empty:** a circle with a thick ink outline and a pale panel cream fill `#FFF6E3`. **Filled:** the same circle filled with progress green `#3FA34D`, a small lighter highlight and the same outline. The beat-end star sparkle is a separate effect in code and not part of this asset. The dots are placed top-centre in a row, one per beat; the quiz screen reuses them top-left.

**Art Bible Anchors:**
- §4 Semantic usage: safe / correct / progress in green; UI tone `#3FA34D`
- §4 Colour-blind safety: filled vs outline shape
- §3: circles mean friendly and safe

**Generation Prompt:** Flat mobile game UI icon pair, modern kids' cartoon style, soft rounded shapes, flat colours, thick warm ink-brown outline (#3A2A20). Two small circles side by side, each on its own transparent canvas: one empty with a pale cream fill (#FFF6E3), one filled bright green (#3FA34D) with a small highlight. Flat light. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, stars, ticks, glow, gradient, patterns.

**Status:** Needed

---

## ASSET-033 — Hint hand (point / press-and-hold)

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 1× 96×96, 2× 192×192 each |
| Format | PNG (sRGB, alpha) |
| Naming | ui_hint_hand_point.png, ui_hint_hand_press.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A friendly, chunky cartoon child's hand with a short cream `#FFF6E3` sleeve cuff, its index finger pointing down-left toward a pad. It has a warm skin tone `#E9B98E` (proposal) and a thick ink outline. **Point:** the fingertip is round and relaxed. **Press:** the same hand with the fingertip slightly squashed flat and a small soft cream press-ring under the tip, used for hold hints. The 1 s bob is animated in code. The fingertip pivot is at the bottom-left of the canvas.

**Art Bible Anchors:**
- Hints GDD Visual/Audio: a cartoon hand in the rounded style, ink-brown outline; a hold hint presses and stays
- §3: soft rounded forms
- §1 P2 / Hints UI: drawn above the HUD, never inside another pad's area

**Generation Prompt:** Flat mobile game UI tutorial icon, modern kids' cartoon style, soft rounded shapes, flat colours with soft gradients, thick warm ink-brown outline (#3A2A20). A single chunky friendly cartoon child's hand with a short cream (#FFF6E3) sleeve cuff, warm skin tone (#E9B98E), index finger extended and pointing down-left, other fingers curled softly, rounded fingertip. Second version: the same hand pressing down, fingertip slightly squashed, with a small soft cream ring under it. Transparent background, flat even light. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, white glove, claws, long nails, adult hand, veins, thin line icon.

**Status:** Needed

---

## ASSET-034 — Stuck arrow

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 1× 64×64, 2× 128×128 |
| Format | PNG (sRGB, alpha) |
| Naming | ui_hint_arrow.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A chunky, downward-pointing arrow with a fat rounded head and a short rounded shaft. It is filled star gold `#FFC531` with a lighter highlight and a thick ink outline. The game rotates it as needed and makes it bounce above the target. It must read at thumbnail size.

**Art Bible Anchors:**
- Hints GDD: a gold bouncing arrow above the target, readable at thumbnail size
- §4 Semantic usage: gold means interactive
- §3: downward shapes kept soft and rounded, nothing jagged

**Generation Prompt:** Flat mobile game UI icon, modern kids' cartoon style, soft rounded shapes, flat colours with a soft gradient, thick warm ink-brown outline (#3A2A20). A single chunky arrow pointing straight down, with a fat rounded arrowhead and a short thick rounded shaft, bright star gold (#FFC531) with a lighter highlight. Centred, transparent background, flat light. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, sharp arrowhead, thin arrow, red, glow, sparkles.

**Status:** Needed

---

## ASSET-035 — Story-screen frame (9-slice)

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 9-slice source 1× 192×192 (insets 64 px), 2× 384×384 (insets 128 px) |
| Format | PNG (sRGB, alpha) |
| Naming | ui_frame_story.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A warm paper panel in paper cream `#F3E6C8` with a very light paper grain (the one UI piece allowed texture, as the story mood carrier). It has a large corner radius and an ink-brown `#4A3428` outer line. The border is a band of a simple bronze-drum ring pattern (concentric lines plus a small tick row) in bronze gold `#E8A93B` and ink brown. A full drum-ring medallion sits in each corner. Edge segments are a clean repeat that **tiles**, not stretches, and the centre is flat paper. The picture and text box are placed inside by the game.

**Art Bible Anchors:**
- §2 Story scene mood carrier: a warm paper-grain border with a bronze-drum ring motif
- §7 Art view: rounded panels with a thin bronze-drum ring border
- §9 ref 1: Đông Sơn motif, drawn as a clean graphic, not the woodblock style; motif origin to be sourced

**Generation Prompt:** Flat mobile game UI panel frame, modern kids' cartoon style, soft rounded shapes, flat colours with soft gradients, warm ink-brown outline (#4A3428), Vietnamese motifs as accents. A single square rounded-corner panel of warm handmade paper (#F3E6C8) with a very subtle paper grain, and a border band made of a simple Đông Sơn bronze-drum concentric ring pattern in bronze gold (#E8A93B) and ink brown, with one small round drum-ring medallion in each corner. Flat empty paper centre. Front view, transparent background outside the panel, flat even light. Negative: text, letters, numbers, Chinese characters, watermark, blood, gore, scary faces, photorealistic, anime, woodblock print style, torn paper, burnt edges, stains, birds, people, heavy texture, drop shadow.

**Status:** Needed
