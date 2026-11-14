# Asset Specs — System: Quiz & Stars

> **Source**: design/gdd/quiz-and-stars.md
> **Art Bible**: design/art/art-bible.md
> **Generated**: 2026-11-14 · Task: TASK-014
> **Review**: lean mode. art-director wrote the specs; technical-artist was skipped, so technical constraints were not validated. Sizes follow art bible §8 as set by game-art-content.
> **Status**: 23 assets specced / 0 approved / 0 in production / 0 done

**Shared rules for the 15 quiz pictures (ASSET-001–015):** each picture is one object, centred, filling about 80% of the canvas, on a transparent background. It sits on the cream answer card (ASSET-017). The light is flat and even with no cast shadow (§2 Quiz). Outlines are warm ink brown `#4A3428` (§4). There is no text, numeral or character anywhere in the picture (§1 P3, §7). The three choices for one question match in scale, line weight and detail, so that only the content tells them apart. Rice green and lavender-grey are kept out of the pictures because they mean "right" and "try again" on the cards (§4 UI palette).

---

## ASSET-001 — Quiz picture: Trần dynasty flag (Q1, correct)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 512×512 |
| Format | PNG (sRGB, alpha) |
| Naming | quiz_flag_tran.png |
| Replaces | content/data/pictures/quiz_flag_tran.png |
| Texture Res | single 512×512 |

**Visual Description:** A tall, upright rectangular banner on a short wooden pole with a rounded finial. The banner is flat vermilion with a bronze-gold border band and a soft fold at the free edge. Its silhouette is a vertical rectangle, which sets it apart from the triangle (ASSET-002) and the square (ASSET-003). The exact Trần flag design is ⟨placeholder⟩.

**Art Bible Anchors:**
- §3 Hero silhouette: the banner is a plain shape and colour, never painted characters
- §4 Red must never read as blood: flat, clean vermilion area with no drips or gradient pooling
- §4 Colour-blind safety: the flags differ by outline shape first, colour second

**Generation Prompt:** Modern kids' cartoon icon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines (#4A3428), Vietnamese motifs as accents. A single tall vertical rectangular cloth banner on a short wooden pole with a round knob on top. The cloth is flat vermilion (#D64A2E) with a bronze-gold (#E8A93B) border band and a gentle soft fold. Centred, front view, filling 80% of the frame, transparent background, flat even light, no shadow. Negative: text, letters, numbers, Chinese characters, symbols on the cloth, watermark, blood, gore, scary faces, photorealistic, anime, triangular pennant, swallowtail, torn cloth, fire, battle scene, people.

**Status:** Needed

---

## ASSET-002 — Quiz picture: Lý dynasty flag (Q1, distractor)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 512×512 |
| Format | PNG (sRGB, alpha) |
| Naming | quiz_flag_ly.png |
| Replaces | content/data/pictures/quiz_flag_ly.png |
| Texture Res | single 512×512 |

**Visual Description:** A long triangular pennant flying sideways from the same wooden pole, with its rounded tip pointing right. The cloth is warm ochre-gold `#D9A441` with an ink-brown border band. The silhouette is a horizontal triangle, so it reads as a different flag even in greyscale. The exact Lý flag design is ⟨placeholder⟩.

**Art Bible Anchors:**
- §3 Enemy silhouettes / UI grammar: the triangle's tip is rounded, with no sharp point
- §4 Colour-blind safety: this is the triangle shape against the rectangle and the square
- §1 P3: the cloth carries no word or symbol

**Generation Prompt:** Modern kids' cartoon icon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines (#4A3428), Vietnamese motifs as accents. A single long triangular pennant flag flying sideways from a short wooden pole with a round knob, the tip pointing right and rounded. The cloth is flat warm ochre-gold (#D9A441) with an ink-brown (#4A3428) edge band. Centred, side view, filling 80% of the frame, transparent background, flat even light, no shadow. Negative: text, letters, numbers, Chinese characters, symbols on the cloth, watermark, blood, gore, scary faces, photorealistic, anime, rectangular banner, red cloth, green cloth, torn cloth, people.

**Status:** Needed

---

## ASSET-003 — Quiz picture: Lê dynasty flag (Q1, distractor)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 512×512 |
| Format | PNG (sRGB, alpha) |
| Naming | quiz_flag_le.png |
| Replaces | content/data/pictures/quiz_flag_le.png |
| Texture Res | single 512×512 |

**Visual Description:** A square flag on the same pole, with a scalloped (wavy) lower edge. The cloth is river blue `#3E8FC4` with a cream `#F3E6C8` inner border line. Its silhouette is a square with a wavy bottom, distinct from the rectangle and the triangle. The exact Lê flag design is ⟨placeholder⟩.

**Art Bible Anchors:**
- §4 Colour-blind safety: the square and wavy-edge shape gives a third distinct silhouette
- §3 Environment geometry: gentle curves, no sharp corners
- §1 P3: no word or symbol on the cloth

**Generation Prompt:** Modern kids' cartoon icon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines (#4A3428), Vietnamese motifs as accents. A single square flag with a soft scalloped wavy bottom edge on a short wooden pole with a round knob. The cloth is flat river blue (#3E8FC4) with a thin cream (#F3E6C8) inner border line. Centred, front view, filling 80% of the frame, transparent background, flat even light, no shadow. Negative: text, letters, numbers, Chinese characters, symbols on the cloth, stars on the cloth, watermark, blood, gore, scary faces, photorealistic, anime, triangular pennant, red cloth, green cloth, people.

**Status:** Needed

---

## ASSET-004 — Quiz picture: young child (Q2, correct "too young")

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 512×512 |
| Format | PNG (sRGB, alpha) |
| Naming | quiz_child.png |
| Replaces | content/data/pictures/quiz_child.png |
| Texture Res | single 512×512 |

**Visual Description:** A small, round-faced boy about 6 years old shown full-body, standing with both hands at his sides and a calm, open smile. He wears a plain, simple tunic and trousers in muted earth tones (straw `#C9A66B`, soft brown). He has no banner, no weapon, no vermilion and no gold accent, so he must **not** read as Trần Quốc Toản. His small size against an implied adult scale is the cue: a short body and a big head, about 2.5 heads tall.

**Art Bible Anchors:**
- §5 Telling characters apart: neutral-NPC earth tones, not the hero's warm accent or signature prop
- §3 Hero vs supporting shapes: a simpler silhouette with lower saturation than the hero
- §1 P1: dignified and friendly, never silly

**Generation Prompt:** Modern kids' cartoon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines (#4A3428), Vietnamese motifs as accents. A single small Vietnamese village boy about six years old, full body, standing straight, calm open smile, big round head, short body. He wears a plain simple tunic and trousers in muted straw (#C9A66B) and soft brown, barefoot or in simple sandals, with simple short hair. Centred, front view, filling 80% of the frame, transparent background, flat even light, no shadow. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, banner, flag, spear, staff, weapon, armour, red clothes, gold trim, helmet, crying, sick, adult.

**Status:** Needed

---

## ASSET-005 — Quiz picture: hourglass (Q2, distractor "late")

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 512×512 |
| Format | PNG (sRGB, alpha) |
| Naming | quiz_hourglass.png |
| Replaces | content/data/pictures/quiz_hourglass.png |
| Texture Res | single 512×512 |

**Visual Description:** A chunky, rounded hourglass with a warm wooden frame (top and bottom caps joined by two turned posts) and two plump glass bulbs. Most of the sand, in bronze gold, has run into the bottom bulb, with a thin stream still falling. The glass is a pale blue-white tint with one soft highlight.

**Art Bible Anchors:**
- §3 Props: the simplest, icon-like form
- §4 Bronze gold for the sand, ink-brown outline
- §2 Quiz: flat even light, no drama

**Generation Prompt:** Modern kids' cartoon icon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines (#4A3428), Vietnamese motifs as accents. A single chunky rounded hourglass with a warm wooden frame and two plump glass bulbs. Bronze-gold sand (#E8A93B) has mostly run into the bottom bulb, with a thin stream falling. Pale blue-white glass with one soft highlight. Centred, upright, filling 80% of the frame, transparent background, flat even light, no shadow. Negative: text, letters, numbers, clock face, watermark, blood, gore, scary faces, photorealistic, anime, broken glass, people.

**Status:** Needed

---

## ASSET-006 — Quiz picture: bed (Q2, distractor "ill")

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 512×512 |
| Format | PNG (sRGB, alpha) |
| Naming | quiz_bed.png |
| Replaces | content/data/pictures/quiz_bed.png |
| Texture Res | single 512×512 |

**Visual Description:** A simple low wooden sleeping platform in three-quarter view, with a folded cream blanket and a rounded pillow. Nobody is in the bed. It suggests rest, not sickness: there is no medicine, no thermometer and no patient. The period furniture form is ⟨placeholder⟩.

**Art Bible Anchors:**
- §1 P3 / Safe for kids: no illness or injury imagery, only the object
- §6: timber forms with gentle curves; period detail ⟨placeholder⟩
- §3 Props: a single readable form

**Generation Prompt:** Modern kids' cartoon icon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines (#4A3428), Vietnamese motifs as accents. A single simple low wooden bed platform in three-quarter view, with a soft folded cream (#F3E6C8) blanket and a plump rounded pillow. The bed is empty. Centred, filling 80% of the frame, transparent background, flat even light, no shadow. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, person in bed, sick person, medicine, thermometer, hospital, dark room.

**Status:** Needed

---

## ASSET-007 — Quiz picture: orange (Q3, correct)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 512×512 |
| Format | PNG (sRGB, alpha) |
| Naming | quiz_fruit_orange.png |
| Replaces | content/data/pictures/quiz_fruit_orange.png |
| Texture Res | single 512×512 |

**Visual Description:** One whole, round orange with a short stem and one leaf, and a lightly dimpled peel. Its colour is warm orange `#F29A2E` with a soft highlight. The orange is whole, never crushed or squashed: the quiz asks about the legend, and a crushed fruit would read as mess.

**Art Bible Anchors:**
- §3: a circle reads as friendly and safe
- §2 Quiz: flat even light
- Hero doc §4 Q3: legend question; the picture shows the object only

**Generation Prompt:** Modern kids' cartoon icon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines (#4A3428), Vietnamese motifs as accents. A single whole round orange fruit with a short stem and one leaf, lightly dimpled peel, warm orange (#F29A2E) with a soft highlight. Centred, filling 80% of the frame, transparent background, flat even light, no shadow. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, crushed fruit, juice splash, cut orange, slices, multiple fruits, hand.

**Status:** Needed

---

## ASSET-008 — Quiz picture: banana (Q3, distractor)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 512×512 |
| Format | PNG (sRGB, alpha) |
| Naming | quiz_fruit_banana.png |
| Replaces | content/data/pictures/quiz_fruit_banana.png |
| Texture Res | single 512×512 |

**Visual Description:** A small bunch of three plump, curved yellow bananas `#F5D04A` joined at a brown stem, with soft rounded tips. It is a long, curved silhouette set against the orange's circle and the coconut's large oval.

**Art Bible Anchors:**
- §3 Props: the simplest readable form
- §6: banana is a Vietnamese-first plant
- §2 Quiz: flat even light

**Generation Prompt:** Modern kids' cartoon icon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines (#4A3428), Vietnamese motifs as accents. A small bunch of three plump curved yellow bananas (#F5D04A) joined at a short brown stem, soft rounded tips. Centred, filling 80% of the frame, transparent background, flat even light, no shadow. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, peeled banana, brown spots, banana leaf, hand.

**Status:** Needed

---

## ASSET-009 — Quiz picture: coconut (Q3, distractor)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 512×512 |
| Format | PNG (sRGB, alpha) |
| Naming | quiz_fruit_coconut.png |
| Replaces | content/data/pictures/quiz_fruit_coconut.png |
| Texture Res | single 512×512 |

**Visual Description:** One whole young coconut shown as a large, slightly egg-shaped oval with a small cap at the top. Its colour is muted olive `#8E9A4A`, deliberately duller and yellower than the UI's correct green. It is visibly the largest and heaviest of the three fruits.

**Art Bible Anchors:**
- §4 UI palette: kept clear of correct-green `#3FA34D`
- §3: a wide oval reads as heavy and harmless
- §6: Vietnamese-first fruit

**Generation Prompt:** Modern kids' cartoon icon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines (#4A3428), Vietnamese motifs as accents. A single whole young Vietnamese coconut, large slightly egg-shaped oval with a small rounded cap on top, muted olive skin (#8E9A4A) with a soft highlight. Centred, filling 80% of the frame, transparent background, flat even light, no shadow. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, cut coconut, straw, palm tree, bright green, face on the coconut.

**Status:** Needed

---

## ASSET-010 — Quiz picture: banner with 3 bars (Q4, distractor)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 512×512 |
| Format | PNG (sRGB, alpha) |
| Naming | quiz_count_3.png |
| Replaces | content/data/pictures/quiz_count_3.png |
| Texture Res | single 512×512 |

**Visual Description:** The shared Q4 banner: a vertical rectangular cloth hanging from a horizontal rod, flat vermilion `#D64A2E`, the same silhouette as the hero's banner in beat 3. Down its centre are **3** short, rounded, horizontal embroidered gold bars (abstract word-blocks) `#E8A93B`, each with an ink-brown outline, evenly spaced in one column. The bars stand for counted words; there are no characters or numerals. ASSET-010, 011 and 012 are identical except for the bar count and layout.

**Art Bible Anchors:**
- §3 Hero silhouette / §7: the banner is a plain shape, and the words are never painted
- §4 Colour-blind safety: gold bars on vermilion carry an ink outline so they can be counted in greyscale
- §4 Red must never read as blood: flat clean cloth

**Generation Prompt:** Modern kids' cartoon icon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines (#4A3428), Vietnamese motifs as accents. A single vertical rectangular cloth banner hanging from a short horizontal wooden rod with round end knobs. The cloth is flat vermilion (#D64A2E). Exactly three large short rounded embroidered gold bars (abstract word-blocks, like lines of stitched writing, with no letters or characters) (#E8A93B), each with an ink-brown outline, evenly spaced in one vertical column. Centred, front view, filling 80% of the frame, transparent background, flat even light, no shadow. Negative: round dots, polka dots, text, letters, numbers, Chinese characters, calligraphy, watermark, blood, gore, scary faces, photorealistic, anime, extra bars, star shapes, torn cloth, people, pole in ground.

**Status:** Needed

---

## ASSET-011 — Quiz picture: banner with 6 bars (Q4, correct)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 512×512 |
| Format | PNG (sRGB, alpha) |
| Naming | quiz_count_6.png |
| Replaces | content/data/pictures/quiz_count_6.png |
| Texture Res | single 512×512 |

**Visual Description:** The same banner as ASSET-010, with **6** gold bars in two columns of three  so a 6-year-old can count them at a glance. The bars are the same size as in ASSET-010.

**Art Bible Anchors:**
- §3 / §7: no painted words; bars stand in for them
- §4 Colour-blind safety: ink-outlined bars
- Hero doc §4 Q4: legend question (the six words)

**Generation Prompt:** Modern kids' cartoon icon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines (#4A3428), Vietnamese motifs as accents. A single vertical rectangular cloth banner hanging from a short horizontal wooden rod with round end knobs. The cloth is flat vermilion (#D64A2E). Exactly six large short rounded embroidered gold bars (abstract word-blocks, like lines of stitched writing, with no letters or characters) (#E8A93B) with ink-brown outlines, arranged in two neat columns of three . Centred, front view, filling 80% of the frame, transparent background, flat even light, no shadow. Negative: round dots, polka dots, text, letters, numbers, Chinese characters, calligraphy, watermark, blood, gore, scary faces, photorealistic, anime, extra bars, fewer bars, star shapes, torn cloth, people.

**Status:** Needed

---

## ASSET-012 — Quiz picture: banner with 10 bars (Q4, distractor)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 512×512 |
| Format | PNG (sRGB, alpha) |
| Naming | quiz_count_10.png |
| Replaces | content/data/pictures/quiz_count_10.png |
| Texture Res | single 512×512 |

**Visual Description:** The same banner as ASSET-010, with **10** gold bars in two columns of five. The bars are slightly smaller than in ASSET-010 (about 85%) so all ten fit with clear gaps, and they still read clearly as more than six.

**Art Bible Anchors:**
- §3 / §7: no painted words
- §4 Colour-blind safety: ink-outlined bars
- §3 Props: clear spacing, no clutter

**Generation Prompt:** Modern kids' cartoon icon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines (#4A3428), Vietnamese motifs as accents. A single vertical rectangular cloth banner hanging from a short horizontal wooden rod with round end knobs. The cloth is flat vermilion (#D64A2E). Exactly ten short rounded embroidered gold bars (abstract word-blocks, like lines of stitched writing, with no letters or characters) (#E8A93B) with ink-brown outlines, in two neat columns of five with clear gaps. Centred, front view, filling 80% of the frame, transparent background, flat even light, no shadow. Negative: round dots, polka dots, text, letters, numbers, Chinese characters, calligraphy, watermark, blood, gore, scary faces, photorealistic, anime, overlapping bars, star shapes, torn cloth, people.

**Status:** Needed

---

## ASSET-013 — Quiz picture: Mông–Nguyên helmet (Q5, correct)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 512×512 |
| Format | PNG (sRGB, alpha) |
| Naming | quiz_helmet_a.png |
| Replaces | content/data/pictures/quiz_helmet_a.png |
| Texture Res | single 512×512 |

**Visual Description:** An empty helmet with no head and no face, from the in-game enemy helmet family: a wide, rounded dome with a soft knob on top, a broad curved neck flap, and a muted cool slate-violet `#7A7395` with a lighter rim band. It must match the beat 4 enemy helmet so that a child who played the mission can recognise it. The exact Mông–Nguyên helmet form is ⟨placeholder⟩.

**Art Bible Anchors:**
- §3 Enemy silhouettes: rounded dome, no points toward the player
- §4 Semantic usage: enemy slate-violet `#7A7395`
- Luan rule 1 / §3 No ethnic caricature: helmet only, no face or head

**Generation Prompt:** Modern kids' cartoon icon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines (#4A3428), Vietnamese motifs as accents. A single empty historical soldier's helmet, nobody wearing it, three-quarter view: a wide rounded dome with a small soft round knob on top and a broad curved neck flap, muted cool slate-violet (#7A7395) with a lighter rim band. Centred, filling 80% of the frame, transparent background, flat even light, no shadow. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, face, head, eyes, person, spikes, horns, sharp points, red, dents, damage, weapons.

**Status:** Needed

---

## ASSET-014 — Quiz picture: Minh helmet (Q5, distractor)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 512×512 |
| Format | PNG (sRGB, alpha) |
| Naming | quiz_helmet_b.png |
| Replaces | content/data/pictures/quiz_helmet_b.png |
| Texture Res | single 512×512 |

**Visual Description:** An empty, taller, narrow-crowned helmet that rises in a rounded cone to a small ball finial, with a short flared brim and two side flaps. It is muted teal-grey `#5F8A8B`. Its silhouette is tall and narrow against helmet a's wide dome. The exact Minh helmet form is ⟨placeholder⟩.

**Art Bible Anchors:**
- §3: rounded tip only, no sharp point
- §4 Colour-blind safety: distinct outer shape plus a distinct cool colour
- Luan rule 1: helmet only, no face

**Generation Prompt:** Modern kids' cartoon icon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines (#4A3428), Vietnamese motifs as accents. A single empty historical helmet, nobody wearing it, three-quarter view: a tall narrow crown rising in a rounded cone to a small ball finial, a short flared brim and two soft side flaps, muted teal-grey (#5F8A8B). Centred, filling 80% of the frame, transparent background, flat even light, no shadow. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, face, head, person, sharp spike, horns, wide dome, red, damage, weapons.

**Status:** Needed

---

## ASSET-015 — Quiz picture: Thanh helmet (Q5, distractor)

| Field | Value |
|-------|-------|
| Category | Sprite |
| Dimensions | 512×512 |
| Format | PNG (sRGB, alpha) |
| Naming | quiz_helmet_c.png |
| Replaces | content/data/pictures/quiz_helmet_c.png |
| Texture Res | single 512×512 |

**Visual Description:** An empty, low, rounded cap with a wide, flat, upturned brim all round and a single round bead and short soft tassel on top. It is muted taupe-brown `#8B7A66`. Its silhouette is flat and wide-brimmed, unlike the dome (a) and the tall cone (b). The exact Thanh helmet form is ⟨placeholder⟩.

**Art Bible Anchors:**
- §3: soft rounded forms, no points
- §4 Colour-blind safety: a third silhouette, and the brim reads in greyscale
- Luan rule 1: helmet only, no face

**Generation Prompt:** Modern kids' cartoon icon, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines (#4A3428), Vietnamese motifs as accents. A single empty historical cap-helmet, nobody wearing it, three-quarter view: a low rounded crown, a wide flat upturned brim all around, and one round bead with a short soft tassel on top, muted taupe-brown (#8B7A66). Centred, filling 80% of the frame, transparent background, flat even light, no shadow. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, face, head, braid, person, spikes, red, damage, weapons, tall crown.

**Status:** Needed

---

## ASSET-016 — Ending still: banner on the riverbank

| Field | Value |
|-------|-------|
| Category | Environment |
| Dimensions | 1920×1080 |
| Format | PNG (sRGB, alpha; fully opaque) |
| Naming | scene_tqt_ending.png |
| Replaces | content/data/pictures/scene_tqt_ending.png |
| Texture Res | 1× 1920×1080 ships as the 1:1 replacement; author the master at 3840×2160 (§8) and keep the 2× export |

**Visual Description:** A wide, quiet riverbank at dawn. A long, calm horizontal river runs across the lower half, with soft reed tufts on the near bank and low hills fading into haze behind. The hero's plain vermilion banner stands on its pole on the bank, left of centre, hanging in still air with one soft fold. The only warm point is a low sun disc (or one lantern on the water) whose gold reflection runs toward the banner. There are no figures anywhere, and no weapons, boats in battle or fallen objects. The lower third stays calm and low-detail so the story text box can sit below without competing.

**Art Bible Anchors:**
- §2 Calm ending line: dawn haze, low contrast, cool-soft, one warm light that stays, no death scene or fallen body
- §6: long calm horizontals; the river location is ⟨placeholder⟩, not a history claim
- §1 P3 / Luan rule 2: the banner carries no painted words

**Generation Prompt:** Modern kids' cartoon background illustration, soft rounded shapes, flat colours with soft gradients, warm ink-brown outlines (#4A3428) on near objects only, Vietnamese motifs as accents, wide 16:9 landscape. A peaceful empty riverbank at dawn in Vietnam: a calm wide river across the lower half, soft reed tufts on the near bank, low rounded hills fading into pale mist behind. A plain vermilion (#D64A2E) cloth banner on a wooden pole stands still on the bank, left of centre, hanging in calm air with one gentle fold. A low warm gold sun (#E8A93B) just above the far hills casts a single soft reflection across the water toward the banner. Cool soft palette: haze blue (#9FB8C8), river blue (#3E8FC4) desaturated, storm indigo (#3B3F6B) only in the far hills, paper cream (#F3E6C8) sky glow. Low contrast, gentle, reverent, very still, no dramatic shadows. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, people, figures, bodies, lying figures, graves, tombstones, weapons, broken spears, fire, smoke, red sky, storm, battle, boats fighting, torn banner, words on the banner.

**Status:** Needed

---

## ASSET-017 — Answer card: default (cream)

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 9-slice source 1× 128×128 (insets 40 px), 2× 256×256 (insets 80 px); stretched in game to about one third of the screen width |
| Format | PNG (sRGB, alpha) |
| Naming | ui_card_default.png |
| Replaces | new (the slice draws the card in code) |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A large-radius rounded rectangle (corner radius equal to the inset) with a flat panel fill `#FFF6E3` and a thick outline `#3A2A20` (6 px at 2×). A soft inner bottom lip, 2–3 px darker cream, makes it feel pressable. There is no motif or texture, and the edges and centre are flat colour so they stretch cleanly.

**Art Bible Anchors:**
- §2 Quiz mood carrier: big cream answer cards, nothing competing
- §4 UI palette: panel fill `#FFF6E3`, outline `#3A2A20`; flat and untextured
- §3 UI shape grammar: everything rounded, no sharp corners

**Generation Prompt:** Flat mobile game UI element, modern kids' cartoon style, soft rounded shapes, flat colours with a minimal soft gradient, thick warm ink-brown outline (#3A2A20). A single empty rounded-rectangle card with large rounded corners, flat light cream fill (#FFF6E3), a thick even outline, and a slightly darker cream lip along the bottom inner edge. Square canvas, centred, transparent background, flat even light, no texture. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, patterns, motifs, paper texture, drop shadow, sharp corners, icons.

**Status:** Needed

---

## ASSET-018 — Answer card: try again (lavender-grey)

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 9-slice source 1× 128×128 (insets 40 px), 2× 256×256 (insets 80 px) |
| Format | PNG (sRGB, alpha) |
| Naming | ui_card_wrong.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** Identical in shape and outline to ASSET-017, with the fill changed to soft lavender-grey `#9C8FB8` and a slightly darker lavender lip. The circular-arrow icon (ASSET-020) is a separate sprite placed by the game in the card's top-right corner, so the 9-slice stays clean. The gentle wobble is an animation in code. Never red, and no "X".

**Art Bible Anchors:**
- §4 UI palette "Try again" / Luan rule 3: `#9C8FB8` with a circular-arrow icon, never red
- §4 Colour-blind safety: the icon and the wobble carry the meaning, not the colour alone
- §3 UI shape grammar: the same rounded shape as the default card

**Generation Prompt:** Flat mobile game UI element, modern kids' cartoon style, soft rounded shapes, flat colours with a minimal soft gradient, thick warm ink-brown outline (#3A2A20). A single empty rounded-rectangle card with large rounded corners, flat soft lavender-grey fill (#9C8FB8), a thick even outline, and a slightly darker lavender lip along the bottom inner edge. Square canvas, centred, transparent background, flat even light, no texture. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, red, pink, X mark, cross, warning sign, patterns, drop shadow, sharp corners.

**Status:** Needed

---

## ASSET-019 — Answer card: right (green)

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 9-slice source 1× 128×128 (insets 40 px), 2× 256×256 (insets 80 px) |
| Format | PNG (sRGB, alpha) |
| Naming | ui_card_right.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** Identical in shape to ASSET-017, filled with the UI correct green `#3FA34D`, with a slightly lighter green inner rim highlight. The tick icon (ASSET-021) is a separate sprite placed by the game top-right. The glow and star burst are effects added in code.

**Art Bible Anchors:**
- §4 UI palette "Correct" `#3FA34D`, always with a tick icon
- §4 Colour-blind safety: tick vs circular arrow, pop vs wobble
- Quiz GDD Game Feel: success is louder than failure (the brightest card state)

**Generation Prompt:** Flat mobile game UI element, modern kids' cartoon style, soft rounded shapes, flat colours with a minimal soft gradient, thick warm ink-brown outline (#3A2A20). A single empty rounded-rectangle card with large rounded corners, flat bright friendly green fill (#3FA34D), a thick even outline, and a lighter green inner rim highlight. Square canvas, centred, transparent background, flat even light, no texture. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, patterns, drop shadow, sharp corners, neon glow.

**Status:** Needed

---

## ASSET-020 — Icon: try again (circular arrow)

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 1× 64×64, 2× 128×128 |
| Format | PNG (sRGB, alpha) |
| Naming | ui_icon_retry.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A thick, chunky circular arrow (about 300° of arc) with a rounded arrowhead, filled in panel cream `#FFF6E3` inside a round lavender `#9C8FB8` badge, all with an ink outline `#3A2A20`. It is a filled, illustrated icon, not a thin line.

**Art Bible Anchors:**
- §4 UI palette / Luan rule 3: the circular-arrow icon for try again
- §7 Icons: filled and rounded, no thin outline icons
- §4 Colour-blind safety: the non-colour backup for the wrong state

**Generation Prompt:** Flat mobile game UI icon, modern kids' cartoon style, soft rounded shapes, flat colours, thick warm ink-brown outline (#3A2A20). A chunky thick circular "try again" arrow curling about three-quarters of a circle with a rounded arrowhead, cream fill (#FFF6E3), on a round soft lavender-grey badge (#9C8FB8). Centred, transparent background, flat light. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, X mark, cross, red, thin line icon, sharp arrowhead, warning triangle.

**Status:** Needed

---

## ASSET-021 — Icon: correct (tick)

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 1× 64×64, 2× 128×128 |
| Format | PNG (sRGB, alpha) |
| Naming | ui_icon_tick.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A thick, rounded-end tick filled in panel cream `#FFF6E3` inside a round green `#3FA34D` badge, with an ink outline `#3A2A20`. It matches ASSET-020 in badge size and stroke weight so the two read as a pair.

**Art Bible Anchors:**
- §4 UI palette "Correct": always with a tick icon
- §7 Icons: filled and rounded
- §4 Colour-blind safety: tick vs circular-arrow shape

**Generation Prompt:** Flat mobile game UI icon, modern kids' cartoon style, soft rounded shapes, flat colours, thick warm ink-brown outline (#3A2A20). A chunky thick check-mark tick with rounded ends, cream fill (#FFF6E3), on a round bright green badge (#3FA34D). Centred, transparent background, flat light. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, thin line icon, sharp corners, sparkles, extra symbols.

**Status:** Needed

---

## ASSET-022 — Results star: earned (filled)

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 1× 96×96, 2× 192×192 |
| Format | PNG (sRGB, alpha) |
| Naming | ui_star_earned.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** A soft five-point star with rounded tips, filled in star gold `#FFC531` with a lighter upper-left highlight facet and a thick ink outline `#3A2A20`. The pop-in and sparkle are animations in code, not baked in.

**Art Bible Anchors:**
- §3 UI shape grammar: soft five-point star with rounded tips, filled when earned
- §4 UI palette: star earned `#FFC531`
- §4 Colour-blind safety: the ink outline separates gold from cream panels

**Generation Prompt:** Flat mobile game UI icon, modern kids' cartoon style, soft rounded shapes, flat colours with a soft gradient, thick warm ink-brown outline (#3A2A20). A single plump five-point star with softly rounded tips, filled bright star gold (#FFC531) with a lighter highlight on the upper-left. Centred, transparent background, flat light. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, sharp points, face on the star, glitter, outer glow, extra stars.

**Status:** Needed

---

## ASSET-023 — Results star: not earned (outline)

| Field | Value |
|-------|-------|
| Category | UI |
| Dimensions | 1× 96×96, 2× 192×192 |
| Format | PNG (sRGB, alpha) |
| Naming | ui_star_unearned.png |
| Replaces | new |
| Texture Res | 1× and 2× per art bible §8 |

**Visual Description:** The exact silhouette of ASSET-022, drawn as an outline only: a thick ink outline `#3A2A20` around a pale, see-through cream inner fill `#FFF6E3` at 50% opacity. It is visibly "empty" but not grey or sad.

**Art Bible Anchors:**
- §3 / §4: an outline shape when not earned (fill vs outline backup)
- Quiz GDD Visual/Audio: unearned stars are outlines
- §1 P1: encouraging, not a scold

**Generation Prompt:** Flat mobile game UI icon, modern kids' cartoon style, soft rounded shapes, thick warm ink-brown outline (#3A2A20). A single plump five-point star with softly rounded tips drawn as an empty outline, with a pale translucent cream inner fill (#FFF6E3). Centred, transparent background, flat light. Negative: text, letters, numbers, watermark, blood, gore, scary faces, photorealistic, anime, gold fill, grey, broken star, cracks, sad face, sharp points.

**Status:** Needed
