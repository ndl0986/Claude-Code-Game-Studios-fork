# Asset Specs — Theme: Dinosaurs (Demo 1)

> **Source**: `design/gdd/key-table-theme-data.md` (§ The Dinosaurs theme: letters, numbers), `design/gdd/cast-rendering.md`
> (R2 structure, R7 idles, roles), Parade R9 (digits walk as their group)
> **Art Bible**: `design/art/art-bible.md` (§3 shape language, §4 creature palettes, §5 character direction, §8 asset standards)
> **Render limits**: `docs/architecture/adr-0009-render-path.md` (Proposed; D2, D3 node counts; P-2 pending)
> **Pattern**: the TASK-077 test creatures, `prototypes/DeviceSpike/art/` (test art only; these specs are for real set items)
> **Generated**: 2026-11-20 (TASK-133; Demo 1, K-48)
> **Status**: 36 assets specced / 0 approved / 0 in production / 0 done
> **Review**: game-dev-ios (render constraints). Mode: solo. The art-director and technical-artist agents were skipped:
> these specs come from the art bible and the GDDs in this session, and game-dev-ios's render read is the technical
> check.

**What this is.** One spec per cast member of the Dinosaurs theme: the 26 letters, and the 10 numbers (0 is the empty
nest; 1–9 are that many baby dinosaurs). Each spec is a pair of files, the layered cast SVG and its silhouette.
**Specs only**: nothing is drawn yet. The art is **team-authored layered SVG** (K-48 leader default; no paid
illustrator unless Luan decides one), so there are no image-generator prompts: the skill's "generation prompt" field
is replaced by the shared drawing rules (S-1 to S-9) and each item's outline trait.

## Shared rules (every item)

- **S-1 Artboard and pose** (art bible §5, §8; Cast Rendering R2). `viewBox="0 0 640 440"`, anchor at the feet
  **(320, 410)**, side view, **facing right**, standing on y 410. The figure fills **≥ 60% of the artboard in height
  (≥ 264 units) or width (≥ 384 units)**. The one exception: the in-flight flyer (P) hovers, with its body around
  y 200–330. Cast Rendering draws the ground shadow at the anchor; the SVG has no shadow.
- **S-2 Structure** (art bible §8; ADR-0003 D4; K-37).
  - **Parts:** every figure has a `root` part (`data-pivot="320 410"`); other parts nest in it. A part a family's idle
    moves carries its `data-pivot` (artboard units, at the joint). Child parts sit inside their parent's group (`head`
    inside `neck`, `jaw` inside `head`). Parts are drawn in **document order** (Cast Rendering R2), so a child that
    sits **behind** its parent (a tail, a neck joining the torso, a far wing) comes **before** the parent's layer
    groups, and one in **front** (a head on its neck, a near wing) comes after them, as in the TASK-077 art.
    *(Corrected in TASK-136: it said every child comes after.)*
  - **Part names** match `[a-z]+(_[a-z]+)*` (ADR-0003 D4): **no digits**. The babies are `baby_one` … `baby_nine`.
    *(Corrected in TASK-136: the spec had `baby_1`, which the bake would reject.)*
  - **Layers:** inside each part, three groups in this order, named after the part: `<part>_body`, `<part>_outline`,
    `<part>_detail`, all present even when empty. Part names are lowercase words joined by `_`, never `body`,
    `outline` or `detail`.
  - **Drawing order:** parts behind the torso (tail, far wing, far legs) come **before** the parts in front, so the
    torso covers their joins (TASK-077).
- **S-3 Outline** (art bible §4, §8; ADR-0009 D3).
  - Every outline stroke is in its part's `<part>_outline` group: Ink `#2a2340`, `stroke-width` **6**, round joins and
    caps, `fill="none"`, with **`opacity="0.8"` on the group** (never on the strokes).
  - One width and one colour per part: the renderer merges a part's outline into one stroked path inside one effect
    node.
  - The outline traces the silhouette edge and the major inner joins only; markings never get an outline (§3: "an
    outline marks a hero").
- **S-4 Face and feet** (art bible §3, §5).
  - **Eye:** large, looking forward and right. The eye white is highlight cream `#f8efdc` and the pupil Ink
    `#2a2340`, both in `head_body` (or `root_body`), so the eye survives the parade size. A small cream highlight
    sits on the pupil in `*_detail`.
  - **Mouth:** a closed smile, an Ink stroke 4 units wide in `*_detail`. Only the T-Rex and Yutyrannus show teeth,
    as 2–3 tiny rounded cream nubs.
  - **Blush:** rose `#e8a6b8`, `fill-opacity` 0.7, in `*_detail`.
  - **Legs and toes:** stubby legs; toes are bone cream `#f3e6c8`, in `*_body`, with no claws facing the viewer.
  - No angry brows, and no open jaws wider than the head. Raptor R's brows are soft and part of the outline trait.
- **S-5 Colour** (art bible §4).
  - **Body:** the item's slot colour, within the band (relative luminance 0.20–0.47, HSL S 35–65%, ochre ≤ 60%).
    Each body below is checked against it.
  - **Far side** (far legs, far wing): the body darkened by 10 lightness points. It is a shade, not bound by the band.
  - **Belly:** the body mixed 50/50 with highlight cream.
  - **Accents** (plates, frills, crests): ≤ 75% saturation.
  - **Never gold or Letter Gold** on a cast member. Every colour passes the red check (R/(R+G+B) < 0.8, ADR-0013 G2).
  - **Colours in the SVG are the base colours.** The per-look multiply and the 15% Night dim are applied at draw time
    (Cast Rendering F8; ADR-0009 D2), never painted in.
  - **Siblings** in one family never share a slot, and leaf and mint never appear in one family (the Key Table's slot
    assignment already satisfies both).
- **S-6 Detail** (art bible §5; Cast Rendering F1). Markings (spots, stripes, speckles, feather tips, blush,
  highlights) go in `*_detail` only. They are **second cues**: the figure must be nameable without them. Give each
  marking at least **12 artboard units** on its short side so it survives the `list` role's 6 px rule. The parade
  drops all detail.
- **S-7 Silhouette file** (art bible §3, §8; MorphCore). `sil_dino_<key>_<name>_01.svg` is on the same artboard and
  anchor, at the **rest pose** (every idle at phase 0).
  - **The shape:** one `<path>` holding a single compound path, filled, no strokes, no `detail`. It is the union of
    every `*_body` shape plus the outline's outer edge (each outline stroke expanded by 3 units, half its width), so
    the stardust lands on the visible edge.
  - **The test:** its white render at 64 px tall must be nameable and distinct from its family siblings (named per
    family below).
- **S-8 Files and the SVG subset** (art bible §8; ADR-0003 D1, D4; Key Table V6).
  - **Paths:** sources go to `content/themes/dinosaurs/src/art/` and `…/src/sil/`; the bake writes
    `cast/<castId-stem>.json` and `sil/<…>.json`.
  - **Names:** `cast_dino_<key>_<name>_01.svg` and `sil_dino_<key>_<name>_01.svg`, with `<key>` lowercase and `<name>`
    one token `[a-z][a-z0-9]*`. The castId is `dino_<key>_<name>_01`.
  - **Elements:** only `svg`, `g`, `path`, `circle`, `ellipse`, `rect`, `line`, `polyline`, `polygon`.
  - **Attributes:** `fill`, `fill-opacity`, `stroke`, `stroke-width`, round `stroke-linejoin` / `stroke-linecap`,
    `opacity` on `g`, and `translate` / `rotate` / `scale` transforms only.
  - **Also allowed (needed):** `d`, each shape's geometry (`cx`, `cy`, `r`, `rx`, `ry`, `x`, `y`, `width`,
    `height`, `x1`, `y1`, `x2`, `y2`, `points`), `id` (part and layer names), `data-pivot` and `transform`, plus the
    root's `xmlns`, `version`, `width`, `height` and `viewBox` (ADR-0003 D4).
  - **Values:** hex colours only. This is a house rule, stricter than the bake: ADR-0003 D4 also accepts
    `rgb(r, g, b)`. *(TASK-133 render read.)*
  - **Not allowed:** gradients, masks, clips, filters, `use`, text, CSS, `style` or `class`. A `<title>` is allowed (it
    is ignored).
- **S-9 Not in the SVG:** the ground shadow, the per-look colour, the idles (data: Cast Rendering R7), the tap hop,
  the parade bob and the sounds.

## Render limits (ADR-0009)

ADR-0009 is **Proposed**: rows P-2 (iPad) and M-13 (Mac) will pick live paths (A), textures (B) or the mix, and they
measure the **TASK-077 test art**. So the real set must stay inside what P-2 measures, or P-2 doesn't speak for it.
- **R-1 Outline per part in an effect node** (D3): the outline is one merged stroke per part, in one `SKEffectNode`
  at 0.8. So keep S-3: one outline group per part, one width, one colour. **At most 5 parts per figure** (the test rex
  has 5).
- **R-2 Node caps per figure** under A-candidate (D3: one node per fill shape, plus one per part's merged outline):
  - **stage ≤ 23** (body and detail fills plus parts), the most the test art reaches (19–23);
  - **parade ≤ 15** (body fills plus parts; the parade draws `body` + `outline`, R3), against 12–15 measured.
  - The bake tool reports shapes per figure (ADR-0009 Risks), so an artist sees an overrun at build.
  - **If a figure needs more, stop and ask game-dev-ios before drawing it.** Each item's node plan below is the
    budget to draw to, not a measurement.
  - Under B (textures per part) the same parts become one texture per part per tier (about 179 KB of PNG per creature
    over 3–5 parts, H-1). Fewer parts is cheaper either way.
- **R-3 Numbers 4–9 are over the single-figure caps.** A number is **one figure** of n babies (Parade R9: "3" walks as
  one place in the line). Each baby bobs on its own phase (Cast Rendering R7), so each baby is a part:

  | Number | Parts | Stage nodes | Parade nodes | Within caps (≤ 5 parts, 23, 15)? |
  |---|---|---|---|---|
  | 1 · 2 · 3 | 1 · 2 · 3 | 6 · 12 · 18 | 4 · 8 · 12 | yes |
  | 4 | 4 | 24 | 16 | over (stage and parade) |
  | 5 | 5 | 30 | 20 | over |
  | 6 · 7 · 8 · 9 | 6–9 | 36–54 | 24–36 | over (parts too) |

  Per baby: 3 body fills, 2 detail elements (the eye highlight and the smile, S-4) and 1 outline node. The parade
  drops the detail. The babies' `root` holds no shapes, so its empty outline group creates **no** effect node (a rule
  for the renderer, confirmed by game-dev-ios).

  - **Why:** the test art has no group figure, so P-2 does not measure one.
  - **Agreed with game-dev-ios (OQ-2):** **the 9 babies** (the worst real figure: 9 parts, 54 stage / 36 parade
    nodes) become a fourth figure in DeviceSpike's Render screen, on the stage and in the parade, for the decisive
    P-2 on the oldest supported iPad and for M-13, judged under D1's rule. It's built from ASSET-006 once drawn, or
    from a stand-in made from the Numbers master if the device session comes first. Footprint is recorded too.
  - **Until then:** draw the baby master and 1–3. Numbers 4–9 are drawn but marked **budget pending**.
  - **Fallbacks if 9 fails, in order:** (1) D1's per-role mix: the parade draws numbers as textures, which keeps
    every baby's own bob (Cast Rendering R7); (2) the back row as one part, which changes the motion, so that one is
    a design call for game-art-content and Luan.
  - The 9 is in batch 1 so it can be measured early (OQ-2).
- **R-4 Sizes on screen:** a stage figure is about 280–360 units tall on the 1280×720 stage (art bible §5), about 775
  physical px on the largest iPad, so ≤ 1024 px per part texture under B. Parade figures are about 85 units tall.

## Numbers master: the baby dinosaur

**One shared, simpler drawing** (art bible §5: round body, big head; the count is what reads), placed n times.
- **Shape** at scale 1: about **90 units tall and 84 wide**. The head and body are one rounded path, the head about
  half the height. There are two stubby feet in the body colour (no cream toes at this size, so the baby stays at 3
  body shapes; TASK-136), a short tail stub on the left, and it faces right.
- **Shapes per baby:** `body` holds 3 shapes: the body path (pastel), the eye white and the pupil. `detail` holds 2,
  the eye highlight and a small closed smile (Ink, 4 units). The blush is dropped at this size (6 px rule). `outline`
  holds 1 group: Ink, 6 units, 0.8.
- **Pastels, fixed order** (art bible §4: one per slot plus a second coral, apricot), as played:
  1 `#7fcf8f`, 2 `#f2a37a`, 3 `#8fb4ea`, 4 `#d8b87a` (ochre baby), 5 `#c39af0`, 6 `#f29ab0`, 7 `#6fc9c0`,
  8 `#e48a5a`, 9 `#a5d46a`. The front row takes 1–5 and the back row 6–9, so neighbours always differ.
- **Contrast:** pastels sit above the body band by design (art bible §4 names them apart). The 80% outline carries the
  greyscale stage test.
- **Part per baby:** `baby_one` … `baby_n` inside `root`, each with `data-pivot` at its feet: x from the layout formula,
  y 410 (front row) or 292 (back row). `root` holds no shapes.
- **The empty nest (0)** is N's nest without its `egg` part (Key Table numbers: "the same art as N, shown empty"), as
  its own file.

## Families at a glance

| Family | Members (trait) | Parts | Idle (Cast Rendering R7) | Silhouette sibling test |
|---|---|---|---|---|
| sauropod | B neck-up · D neck-forward | root, tail, neck → head | neck sway, 0.22 Hz | B's vertical neck vs D's level neck |
| rex | T plain · Y feathered | root, tail, neck → head → jaw | jaw nod | Y's feather fringe breaks the back edge; T's is smooth |
| raptor | J fuzz · R stripes-brows · U arm-feathers-crest · V long-snout | root, tail, head | head look | J scalloped back; R brow bump; U arm fringe and crest; V the longest head |
| ankylosaur | A club-tail | root, tail, head | tail wag | (no sibling) the club and low wide body |
| flyer | P in-flight · Q standing | P: root, wing_far, wing_near · Q: root, wing_near, head | wing flap | open wings in the air vs a tall standing shape |
| duckbill | E duck-bill · H bump · I thumb-spike · L hatchet-crest · M brow-baby | root, tail, head (prepared) | **none yet: OQ-1** | the head line differs for each (flat bill, bump, crest, brow and baby); I's spike up off the hand |
| horned | C tri-horn · X xeno-horns · Z zuni-horns | root, tail, head (prepared) | **none yet: OQ-1** | horn count and frill edge: 3 horns; a spiked frill; 2 horns and a plain frill |
| plated | S plates · K spikes · W low-plates | root, tail, head (prepared) | **none yet: OQ-1** | tall rounded plates vs spikes vs long low plates |
| ornithomimid | G gallimimus · O oviraptor | root, tail, head (prepared) | **none yet: OQ-1** | G's long neck and legs vs O's tall head crest |
| object | F fossil · N nest · 0 empty nest | F, 0: root · N: root, egg | N: egg wobble with a peek | F slab with a bone; N bowl with an egg; 0 the bowl alone |
| babies | 1–9 | baby_one … baby_nine | per-baby bob, 0.95 Hz | the count |

**Prepared parts:** families with no idle in Cast Rendering's data yet still get `tail` and `head` as parts with
pivots, so an idle can be added in data later without redrawing (OQ-1). They cost one outline node each and are
inside R-2.

## Drawing order (batches)

| Batch | Items | Why this order |
|---|---|---|
| **1 (first)** | **T** (rex, the Title creature), **D** (sauropod, closest to the test art), **R** (raptor), **P** (flyer in flight), **A** (ankylosaur), **9** (the baby master × 9) | One of each family with an idle (jaw, neck, head, wings, tail), so every idle's parts and pivots are proven first. T is on the Title from the first frame. **9 is the render-budget worst case** (R-3), drawn early so P-2 can measure it. |
| 2 | B, Y, J, U, V, Q | The rest of the families with idles: the second sauropod, rex and flyer, and the other raptors. |
| 3 | E, H, I, L, M | Duckbills: one body, five head traits. |
| 4 | C, X, Z, S, K, W | Horned and plated: one body each, horn and plate traits. |
| 5 | G, O, F, N, 0, 1 | Ornithomimids, the objects, and the single baby. |
| 6 | 2, 3, 4, 5, 6, 7, 8 | Layout variants of the baby master. 4–9 stay "budget pending" until R-3 is decided. |

## Per-item specs

The node plan counts the A-candidate nodes the drawing is budgeted to (R-2). Every `detail` element is its own
node, a stroke or a fill: the item's markings, plus the mouth and eye highlight S-4 puts there, plus T's and Y's
teeth nubs, drawn as one path of non-overlapping subpaths (TASK-133 render read). Pivots are the family's starting points
(the TASK-077 values where they exist); an artist may move a pivot to the drawn joint and must record it in
`data-pivot`.

### ASSET-001 — T T-Rex (`dino_t_trex_01`) · batch 1

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_t_trex_01.svg`, `src/sil/sil_dino_t_trex_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | rex / plain |
| Outline trait | the classic big head, tiny arms, thick tail; a closed smile with tiny rounded nubs (the TASK-077 test rex is the pattern). The Title creature (K-22) |
| Slot and colours | violet: body `#9a6fd1` (L 0.228, S 52%, H 266°), far-side `#7f48c5`, belly `#c9afd6`; accents ridge `#c39af0` |
| Parts (`data-pivot`) | `root` (320 410) · `tail` (196 270) · `neck` (360 250) · `head` (380 176 (inside neck)) · `jaw` (398 182 (inside head)) |
| Idle | jaw nod (`jaw`, rotate) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `tail_body`, `tail_outline`, `tail_detail`, `neck_body`, `neck_outline`, `neck_detail`, `head_body`, `head_outline`, `head_detail`, `jaw_body`, `jaw_outline`, `jaw_detail` |
| `detail` (second cues) | back ridge bumps ×3, blush |
| Node plan (A-candidate) | 5 parts, ~9 body fills, ~7 detail elements (back ridge bumps ×3, blush, mouth, eye highlight, teeth nubs) → stage 21 (cap 23), parade 14 (cap 15) |

### ASSET-002 — D Diplodocus (`dino_d_diplodocus_01`) · batch 1

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_d_diplodocus_01.svg`, `src/sil/sil_dino_d_diplodocus_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | sauropod / neck-forward |
| Outline trait | a long neck held forward and level, and a long whip tail (the TASK-077 test sauropod is the pattern) |
| Slot and colours | teal: body `#5fb3a8` (L 0.375, S 36%, H 172°), far-side `#48978d`, belly `#acd1c2`; accents spots `#3f8a82` |
| Parts (`data-pivot`) | `root` (320 410) · `tail` (182 316) · `neck` (400 262) · `head` (474 126 (inside neck)) |
| Idle | neck sway (`neck`, rotate, 0.22 Hz as played) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `tail_body`, `tail_outline`, `tail_detail`, `neck_body`, `neck_outline`, `neck_detail`, `head_body`, `head_outline`, `head_detail` |
| `detail` (second cues) | 3 back spots, blush |
| Node plan (A-candidate) | 4 parts, ~9 body fills, ~6 detail elements (3 back spots, blush, mouth, eye highlight) → stage 19 (cap 23), parade 13 (cap 15) |

### ASSET-003 — R Raptor (`dino_r_raptor_01`) · batch 1

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_r_raptor_01.svg`, `src/sil/sil_dino_r_raptor_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | raptor / stripes-brows |
| Outline trait | soft brow ridges over the eyes and a stripe band along the back (stripes are the second cue; the brows are on the outline) |
| Slot and colours | leaf: body `#68b761` (L 0.377, S 37%, H 115°), far-side `#4f9d48`, belly `#b0d39e`; accents stripes `#5a9256` |
| Parts (`data-pivot`) | `root` (320 410) · `tail` (210 300) · `head` (408 214) |
| Idle | head look (`head`, rotate about the neck base) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `tail_body`, `tail_outline`, `tail_detail`, `head_body`, `head_outline`, `head_detail` |
| `detail` (second cues) | 3 back stripes, blush |
| Node plan (A-candidate) | 3 parts, ~9 body fills, ~6 detail elements (3 back stripes, blush, mouth, eye highlight) → stage 18 (cap 23), parade 12 (cap 15) |

### ASSET-004 — P Tapejara (`dino_p_tapejara_01`) · batch 1

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_p_tapejara_01.svg`, `src/sil/sil_dino_p_tapejara_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | flyer / in-flight |
| Outline trait | wings open in flight and a big rounded sail crest on the head |
| Slot and colours | teal: body `#5fb6b0` (L 0.390, S 37%, H 176°), far-side `#479b95`, belly `#acd2c6`; accents crest `#e67151`, wing `#9fd9cf` |
| Parts (`data-pivot`) | `root` (320 410) · `wing_far` (300 250) · `wing_near` (330 255) |
| Idle | wing flap (`wing_far`, `wing_near`, rotate, opposite phase); hovers: the body sits at y ~200–330, the ground shadow stays at the anchor (art bible §5) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `wing_far_body`, `wing_far_outline`, `wing_far_detail`, `wing_near_body`, `wing_near_outline`, `wing_near_detail` |
| `detail` (second cues) | wing finger lines ×2, blush |
| Node plan (A-candidate) | 3 parts, ~9 body fills, ~5 detail elements (wing finger lines ×2, blush, mouth, eye highlight) → stage 17 (cap 23), parade 12 (cap 15) |

### ASSET-005 — A Ankylosaurus (`dino_a_ankylosaurus_01`) · batch 1

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_a_ankylosaurus_01.svg`, `src/sil/sil_dino_a_ankylosaurus_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | ankylosaur / club-tail |
| Outline trait | a low wide body with a rounded club at the tail tip; armour bumps along the back edge |
| Slot and colours | blue: body `#5f8fd6` (L 0.269, S 59%, H 216°), far-side `#3673cc`, belly `#acbfd9`; accents club `#3f68a8`, studs `#a9c6f2` |
| Parts (`data-pivot`) | `root` (320 410) · `tail` (170 330) · `head` (470 300) |
| Idle | tail wag (`tail`, rotate); `head` prepared (no idle in data yet) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `tail_body`, `tail_outline`, `tail_detail`, `head_body`, `head_outline`, `head_detail` |
| `detail` (second cues) | 3 armour studs, blush |
| Node plan (A-candidate) | 3 parts, ~9 body fills, ~6 detail elements (3 armour studs, blush, mouth, eye highlight) → stage 18 (cap 23), parade 12 (cap 15) |

### ASSET-006 — 9 · nine baby dinosaurs (`dino_9_babies_01`) · batch 1

| Field | Value |
|---|---|
| Category | Cast member (a counted group), layered SVG + its silhouette |
| Files | `src/art/cast_dino_9_babies_01.svg`, `src/sil/sil_dino_9_babies_01.svg` |
| Family / variant | babies / 9: the one shared **baby** drawing (Numbers master, below) placed 9× |
| Layout | front row 5 at x = 320 + 104·(i − 2), feet on y 410, scale 1.05; back row 4 at x = 320 + 104·(j − 1.5), feet on y 292, scale 0.95, drawn first (as played) |
| Colours | baby `i` takes pastel `i` in the fixed order (Numbers master): `#7fcf8f`, `#f2a37a`, `#8fb4ea`, `#d8b87a`, `#c39af0`, `#f29ab0`, `#6fc9c0`, `#e48a5a`, `#a5d46a` |
| Parts (`data-pivot`) | `root` (320 410) holding `baby_one` · `baby_two` · `baby_three` · `baby_four` · `baby_five` · `baby_six` · `baby_seven` · `baby_eight` · `baby_nine`, each with its pivot at that baby's feet |
| Idle | each baby bobs on its own phase (Cast Rendering R7: `abs(sin(3t + ph))`, 0.95 Hz) |
| Layer ids | `root_*` (empty but present), and `baby_<word>_body`, `baby_<word>_outline`, `baby_<word>_detail` |
| Node plan (A-candidate) | 9 baby parts (root holds no shapes), per baby 3 body + 2 detail (eye highlight, smile) + 1 outline → stage 54, parade 36 **Over the single-figure caps: see Render limits, R-3.** |

### ASSET-007 — B Brachiosaurus (`dino_b_brachiosaurus_01`) · batch 2

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_b_brachiosaurus_01.svg`, `src/sil/sil_dino_b_brachiosaurus_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | sauropod / neck-up |
| Outline trait | the neck rises almost straight up, head at the top of the artboard; front legs longer than back |
| Slot and colours | leaf: body `#8fbf6a` (L 0.441, S 40%, H 94°), far-side `#75ac4a`, belly `#c3d7a3`; accents spots `#77a556` |
| Parts (`data-pivot`) | `root` (320 410) · `tail` (186 320) · `neck` (392 250) · `head` (420 64 (inside neck)) |
| Idle | neck sway (`neck`, rotate, 0.22 Hz as played) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `tail_body`, `tail_outline`, `tail_detail`, `neck_body`, `neck_outline`, `neck_detail`, `head_body`, `head_outline`, `head_detail` |
| `detail` (second cues) | 3 back spots, blush |
| Node plan (A-candidate) | 4 parts, ~9 body fills, ~6 detail elements (3 back spots, blush, mouth, eye highlight) → stage 19 (cap 23), parade 13 (cap 15) |

### ASSET-008 — Y Yutyrannus (`dino_y_yutyrannus_01`) · batch 2

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_y_yutyrannus_01.svg`, `src/sil/sil_dino_y_yutyrannus_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | rex / feathered |
| Outline trait | the rex body with a soft feather fringe along the neck, back and arms |
| Slot and colours | coral: body `#d97a5a` (L 0.294, S 63%, H 15°), far-side `#cf5931`, belly `#e8b49b`; accents feathers `#eaa36c` |
| Parts (`data-pivot`) | `root` (320 410) · `tail` (196 270) · `neck` (360 250) · `head` (380 176 (inside neck)) · `jaw` (398 182 (inside head)) |
| Idle | jaw nod (`jaw`, rotate) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `tail_body`, `tail_outline`, `tail_detail`, `neck_body`, `neck_outline`, `neck_detail`, `head_body`, `head_outline`, `head_detail`, `jaw_body`, `jaw_outline`, `jaw_detail` |
| `detail` (second cues) | feather tips ×3, blush |
| Node plan (A-candidate) | 5 parts, ~9 body fills, ~7 detail elements (feather tips ×3, blush, mouth, eye highlight, teeth nubs) → stage 21 (cap 23), parade 14 (cap 15) |

### ASSET-009 — J Juravenator (`dino_j_juravenator_01`) · batch 2

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_j_juravenator_01.svg`, `src/sil/sil_dino_j_juravenator_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | raptor / fuzz |
| Outline trait | a soft fuzz edge along the back and tail outline (scalloped), big eye, short snout |
| Slot and colours | blue: body `#7aa7d6` (L 0.366, S 53%, H 211°), far-side `#538dca`, belly `#b9cbd9`; accents fuzz `#a9c6f2` |
| Parts (`data-pivot`) | `root` (320 410) · `tail` (210 300) · `head` (408 214) |
| Idle | head look (`head`, rotate about the neck base) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `tail_body`, `tail_outline`, `tail_detail`, `head_body`, `head_outline`, `head_detail` |
| `detail` (second cues) | fuzz tufts ×3, blush |
| Node plan (A-candidate) | 3 parts, ~9 body fills, ~6 detail elements (fuzz tufts ×3, blush, mouth, eye highlight) → stage 18 (cap 23), parade 12 (cap 15) |

### ASSET-010 — U Utahraptor (`dino_u_utahraptor_01`) · batch 2

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_u_utahraptor_01.svg`, `src/sil/sil_dino_u_utahraptor_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | raptor / arm-feathers-crest |
| Outline trait | feather fringe on the arms and a small head crest |
| Slot and colours | coral: body `#c76a4a` (L 0.229, S 53%, H 15°), far-side `#aa5234`, belly `#e0ac93`; accents feathers `#eaa36c`, crest `#8a4630` |
| Parts (`data-pivot`) | `root` (320 410) · `tail` (210 300) · `head` (408 214) |
| Idle | head look (`head`, rotate about the neck base) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `tail_body`, `tail_outline`, `tail_detail`, `head_body`, `head_outline`, `head_detail` |
| `detail` (second cues) | arm feather tips ×2, blush |
| Node plan (A-candidate) | 3 parts, ~9 body fills, ~5 detail elements (arm feather tips ×2, blush, mouth, eye highlight) → stage 17 (cap 23), parade 12 (cap 15) |

### ASSET-011 — V Velociraptor (`dino_v_velociraptor_01`) · batch 2

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_v_velociraptor_01.svg`, `src/sil/sil_dino_v_velociraptor_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | raptor / long-snout |
| Outline trait | a long, low snout (the head reads longer than any other raptor); speckles as the second cue |
| Slot and colours | ochre: body `#b99a6a` (L 0.345, S 36%, H 36°), far-side `#a3814d`, belly `#d8c4a3`; accents speckles `#9e7633` |
| Parts (`data-pivot`) | `root` (320 410) · `tail` (210 300) · `head` (408 214) |
| Idle | head look (`head`, rotate about the neck base) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `tail_body`, `tail_outline`, `tail_detail`, `head_body`, `head_outline`, `head_detail` |
| `detail` (second cues) | 4 speckles, blush |
| Node plan (A-candidate) | 3 parts, ~9 body fills, ~7 detail elements (4 speckles, blush, mouth, eye highlight) → stage 19 (cap 23), parade 12 (cap 15) |

### ASSET-012 — Q Quetzalcoatlus (`dino_q_quetzalcoatlus_01`) · batch 2

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_q_quetzalcoatlus_01.svg`, `src/sil/sil_dino_q_quetzalcoatlus_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | flyer / standing |
| Outline trait | standing tall on folded wings like a giraffe-stork, long beak, small crest |
| Slot and colours | coral: body `#dea363` (L 0.426, S 65%, H 31°), far-side `#d58a39`, belly `#ebc9a0`; accents crest `#e67151`, wing `#c4864a` |
| Parts (`data-pivot`) | `root` (320 410) · `wing_near` (300 300) · `head` (390 96) |
| Idle | wing flap (`wing_near`, a small folded-wing lift); `head` prepared |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `wing_near_body`, `wing_near_outline`, `wing_near_detail`, `head_body`, `head_outline`, `head_detail` |
| `detail` (second cues) | wing fold line, blush |
| Node plan (A-candidate) | 3 parts, ~9 body fills, ~4 detail elements (wing fold line, blush, mouth, eye highlight) → stage 16 (cap 23), parade 12 (cap 15) |

### ASSET-013 — E Edmontosaurus (`dino_e_edmontosaurus_01`) · batch 3

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_e_edmontosaurus_01.svg`, `src/sil/sil_dino_e_edmontosaurus_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | duckbill / duck-bill |
| Outline trait | a flat, wide duck bill on a long low head; no crest |
| Slot and colours | blue: body `#9fb8d8` (L 0.466, S 42%, H 214°), far-side `#7b9dc9`, belly `#ccd3da`; accents bill `#f3e6c8` |
| Parts (`data-pivot`) | `root` (320 410) · `tail` (190 300) · `head` (430 170) |
| Idle | none in Cast Rendering data yet (breathe only); `tail`, `head` prepared (OQ-1) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `tail_body`, `tail_outline`, `tail_detail`, `head_body`, `head_outline`, `head_detail` |
| `detail` (second cues) | 2 back stripes, blush |
| Node plan (A-candidate) | 3 parts, ~9 body fills, ~5 detail elements (2 back stripes, blush, mouth, eye highlight) → stage 17 (cap 23), parade 12 (cap 15) |

### ASSET-014 — H Hadrosaurus (`dino_h_hadrosaurus_01`) · batch 3

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_h_hadrosaurus_01.svg`, `src/sil/sil_dino_h_hadrosaurus_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | duckbill / bump |
| Outline trait | a rounded bump on the snout above the bill |
| Slot and colours | mint: body `#7dc396` (L 0.456, S 37%, H 141°), far-side `#5ab37a`, belly `#bad9b9`; accents bump `#6aa982` |
| Parts (`data-pivot`) | `root` (320 410) · `tail` (190 300) · `head` (430 170) |
| Idle | none in Cast Rendering data yet (breathe only); `tail`, `head` prepared (OQ-1) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `tail_body`, `tail_outline`, `tail_detail`, `head_body`, `head_outline`, `head_detail` |
| `detail` (second cues) | 2 back stripes, blush |
| Node plan (A-candidate) | 3 parts, ~9 body fills, ~5 detail elements (2 back stripes, blush, mouth, eye highlight) → stage 17 (cap 23), parade 12 (cap 15) |

### ASSET-015 — I Iguanodon (`dino_i_iguanodon_01`) · batch 3

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_i_iguanodon_01.svg`, `src/sil/sil_dino_i_iguanodon_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | duckbill / thumb-spike |
| Outline trait | a cream thumb spike sticking up from the front hand (rounded tip, pointing up, not at the viewer) |
| Slot and colours | ochre: body `#c99a52` (L 0.361, S 52%, H 36°), far-side `#b18137`, belly `#e0c497`; accents thumb `#f3e6c8` |
| Parts (`data-pivot`) | `root` (320 410) · `tail` (190 300) · `head` (430 170) |
| Idle | none in Cast Rendering data yet (breathe only); `tail`, `head` prepared (OQ-1) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `tail_body`, `tail_outline`, `tail_detail`, `head_body`, `head_outline`, `head_detail` |
| `detail` (second cues) | 3 back spots, blush |
| Node plan (A-candidate) | 3 parts, ~9 body fills, ~6 detail elements (3 back spots, blush, mouth, eye highlight) → stage 18 (cap 23), parade 12 (cap 15) |

### ASSET-016 — L Lambeosaurus (`dino_l_lambeosaurus_01`) · batch 3

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_l_lambeosaurus_01.svg`, `src/sil/sil_dino_l_lambeosaurus_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | duckbill / hatchet-crest |
| Outline trait | a tall hatchet-shaped crest on top of the head, leaning forward |
| Slot and colours | rose: body `#e7a0b8` (L 0.456, S 60%, H 340°), far-side `#dd779a`, belly `#f0c8ca`; accents crest `#c94f6d` |
| Parts (`data-pivot`) | `root` (320 410) · `tail` (190 300) · `head` (430 170) |
| Idle | none in Cast Rendering data yet (breathe only); `tail`, `head` prepared (OQ-1) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `tail_body`, `tail_outline`, `tail_detail`, `head_body`, `head_outline`, `head_detail` |
| `detail` (second cues) | 2 back stripes, blush |
| Node plan (A-candidate) | 3 parts, ~9 body fills, ~5 detail elements (2 back stripes, blush, mouth, eye highlight) → stage 17 (cap 23), parade 12 (cap 15) |

### ASSET-017 — M Maiasaura (`dino_m_maiasaura_01`) · batch 3

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_m_maiasaura_01.svg`, `src/sil/sil_dino_m_maiasaura_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | duckbill / brow-baby |
| Outline trait | a small brow crest above the eye, and a tiny baby peeking out beside the front foot (part of the outline) |
| Slot and colours | violet: body `#a98fd6` (L 0.329, S 46%, H 262°), far-side `#8c6ac8`, belly `#d0bfd9`; accents brow `#8f75c0`, baby `#c39af0` |
| Parts (`data-pivot`) | `root` (320 410) · `tail` (190 300) · `head` (430 170) |
| Idle | none in Cast Rendering data yet (breathe only); `tail`, `head` prepared (OQ-1) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `tail_body`, `tail_outline`, `tail_detail`, `head_body`, `head_outline`, `head_detail` |
| `detail` (second cues) | baby eye, blush |
| Node plan (A-candidate) | 3 parts, ~9 body fills, ~4 detail elements (baby eye, blush, mouth, eye highlight) → stage 16 (cap 23), parade 12 (cap 15) |

### ASSET-018 — C Triceratops (`dino_c_triceratops_01`) · batch 4

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_c_triceratops_01.svg`, `src/sil/sil_dino_c_triceratops_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | horned / tri-horn |
| Outline trait | a round frill behind the head with three horns: two long brow horns and a short nose horn |
| Slot and colours | coral: body `#dd8d63` (L 0.353, S 64%, H 21°), far-side `#d46e39`, belly `#ebbea0`; accents frill `#e0c08a`, horns `#f3e6c8` |
| Parts (`data-pivot`) | `root` (320 410) · `tail` (190 320) · `head` (430 300) |
| Idle | none in Cast Rendering data yet (breathe only); `tail`, `head` (frill and horns) prepared (OQ-1) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `tail_body`, `tail_outline`, `tail_detail`, `head_body`, `head_outline`, `head_detail` |
| `detail` (second cues) | frill rim dots ×2, blush |
| Node plan (A-candidate) | 3 parts, ~9 body fills, ~5 detail elements (frill rim dots ×2, blush, mouth, eye highlight) → stage 17 (cap 23), parade 12 (cap 15) |

### ASSET-019 — X Xenoceratops (`dino_x_xenoceratops_01`) · batch 4

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_x_xenoceratops_01.svg`, `src/sil/sil_dino_x_xenoceratops_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | horned / xeno-horns |
| Outline trait | a frill edged with a row of long spikes pointing up, and short brow horns |
| Slot and colours | blue: body `#8f9fd8` (L 0.356, S 48%, H 227°), far-side `#697fcb`, belly `#c3c7da`; accents frill `#b9c3ec`, horns `#f3e6c8` |
| Parts (`data-pivot`) | `root` (320 410) · `tail` (190 320) · `head` (430 300) |
| Idle | none in Cast Rendering data yet (breathe only); `tail`, `head` (frill and horns) prepared (OQ-1) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `tail_body`, `tail_outline`, `tail_detail`, `head_body`, `head_outline`, `head_detail` |
| `detail` (second cues) | frill rim dots ×2, blush |
| Node plan (A-candidate) | 3 parts, ~9 body fills, ~5 detail elements (frill rim dots ×2, blush, mouth, eye highlight) → stage 17 (cap 23), parade 12 (cap 15) |

### ASSET-020 — Z Zuniceratops (`dino_z_zuniceratops_01`) · batch 4

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_z_zuniceratops_01.svg`, `src/sil/sil_dino_z_zuniceratops_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | horned / zuni-horns |
| Outline trait | two long brow horns, no nose horn, and a short plain frill |
| Slot and colours | leaf: body `#abbb54` (L 0.448, S 43%, H 69°), far-side `#8f9d3f`, belly `#d2d598`; accents frill `#d6dca8`, horns `#f3e6c8` |
| Parts (`data-pivot`) | `root` (320 410) · `tail` (190 320) · `head` (430 300) |
| Idle | none in Cast Rendering data yet (breathe only); `tail`, `head` (frill and horns) prepared (OQ-1) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `tail_body`, `tail_outline`, `tail_detail`, `head_body`, `head_outline`, `head_detail` |
| `detail` (second cues) | frill rim dots ×2, blush |
| Node plan (A-candidate) | 3 parts, ~9 body fills, ~5 detail elements (frill rim dots ×2, blush, mouth, eye highlight) → stage 17 (cap 23), parade 12 (cap 15) |

### ASSET-021 — S Stegosaurus (`dino_s_stegosaurus_01`) · batch 4

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_s_stegosaurus_01.svg`, `src/sil/sil_dino_s_stegosaurus_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | plated / plates |
| Outline trait | two rows of tall rounded plates along the back, staggered; four rounded tail spikes |
| Slot and colours | leaf: body `#7cb85a` (L 0.393, S 40%, H 98°), far-side `#639c43`, belly `#bad39b`; accents plates `#e79c56`, plates_far `#d77f30` |
| Parts (`data-pivot`) | `root` (320 410) · `tail` (180 320) · `head` (470 330) |
| Idle | none in Cast Rendering data yet (breathe only); `tail`, `head` prepared (OQ-1) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `tail_body`, `tail_outline`, `tail_detail`, `head_body`, `head_outline`, `head_detail` |
| `detail` (second cues) | 2 flank spots, blush |
| Node plan (A-candidate) | 3 parts, ~9 body fills, ~5 detail elements (2 flank spots, blush, mouth, eye highlight) → stage 17 (cap 23), parade 12 (cap 15) |

### ASSET-022 — K Kentrosaurus (`dino_k_kentrosaurus_01`) · batch 4

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_k_kentrosaurus_01.svg`, `src/sil/sil_dino_k_kentrosaurus_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | plated / spikes |
| Outline trait | short plates over the shoulders turning into tall rounded spikes along the hips and tail |
| Slot and colours | ochre: body `#c9a24f` (L 0.388, S 53%, H 41°), far-side `#af8836`, belly `#e0c896`; accents spikes `#e0c08a` |
| Parts (`data-pivot`) | `root` (320 410) · `tail` (180 320) · `head` (470 330) |
| Idle | none in Cast Rendering data yet (breathe only); `tail`, `head` prepared (OQ-1) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `tail_body`, `tail_outline`, `tail_detail`, `head_body`, `head_outline`, `head_detail` |
| `detail` (second cues) | 2 flank stripes, blush |
| Node plan (A-candidate) | 3 parts, ~9 body fills, ~5 detail elements (2 flank stripes, blush, mouth, eye highlight) → stage 17 (cap 23), parade 12 (cap 15) |

### ASSET-023 — W Wuerhosaurus (`dino_w_wuerhosaurus_01`) · batch 4

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_w_wuerhosaurus_01.svg`, `src/sil/sil_dino_w_wuerhosaurus_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | plated / low-plates |
| Outline trait | long, low, rounded plates (wider than tall) along the back |
| Slot and colours | teal: body `#6ca9bb` (L 0.352, S 37%, H 194°), far-side `#4d92a7`, belly `#b2cccc`; accents plates `#e0c08a` |
| Parts (`data-pivot`) | `root` (320 410) · `tail` (180 320) · `head` (470 330) |
| Idle | none in Cast Rendering data yet (breathe only); `tail`, `head` prepared (OQ-1) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `tail_body`, `tail_outline`, `tail_detail`, `head_body`, `head_outline`, `head_detail` |
| `detail` (second cues) | 2 flank stripes, blush |
| Node plan (A-candidate) | 3 parts, ~9 body fills, ~5 detail elements (2 flank stripes, blush, mouth, eye highlight) → stage 17 (cap 23), parade 12 (cap 15) |

### ASSET-024 — G Gallimimus (`dino_g_gallimimus_01`) · batch 5

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_g_gallimimus_01.svg`, `src/sil/sil_dino_g_gallimimus_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | ornithomimid / gallimimus |
| Outline trait | an ostrich-like long neck and long legs, small beaked head, fluffy tail |
| Slot and colours | ochre: body `#d8b06a` (L 0.467, S 59%, H 38°), far-side `#cd9b42`, belly `#e8d0a3`; accents feathers `#efd39a`, beak `#e0c08a` |
| Parts (`data-pivot`) | `root` (320 410) · `tail` (200 280) · `head` (430 150) |
| Idle | none in Cast Rendering data yet (breathe only); `tail`, `head` prepared (OQ-1) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `tail_body`, `tail_outline`, `tail_detail`, `head_body`, `head_outline`, `head_detail` |
| `detail` (second cues) | tail fluff tufts ×2, blush |
| Node plan (A-candidate) | 3 parts, ~9 body fills, ~5 detail elements (tail fluff tufts ×2, blush, mouth, eye highlight) → stage 17 (cap 23), parade 12 (cap 15) |

### ASSET-025 — O Oviraptor (`dino_o_oviraptor_01`) · batch 5

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_o_oviraptor_01.svg`, `src/sil/sil_dino_o_oviraptor_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | ornithomimid / oviraptor |
| Outline trait | a tall rounded head crest and a short parrot-like beak; arm feathers |
| Slot and colours | rose: body `#e68ca8` (L 0.384, S 64%, H 341°), far-side `#dd6288`, belly `#efbec2`; accents crest `#c94f6d`, beak `#e0c08a` |
| Parts (`data-pivot`) | `root` (320 410) · `tail` (200 280) · `head` (430 150) |
| Idle | none in Cast Rendering data yet (breathe only); `tail`, `head` prepared (OQ-1) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `tail_body`, `tail_outline`, `tail_detail`, `head_body`, `head_outline`, `head_detail` |
| `detail` (second cues) | arm feather tips ×2, blush |
| Node plan (A-candidate) | 3 parts, ~9 body fills, ~5 detail elements (arm feather tips ×2, blush, mouth, eye highlight) → stage 17 (cap 23), parade 12 (cap 15) |

### ASSET-026 — F Fossil (`dino_f_fossil_01`) · batch 5

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_f_fossil_01.svg`, `src/sil/sil_dino_f_fossil_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | object / fossil |
| Outline trait | a rounded rock slab with a curled cream bone shape set into it (an object, not a creature) |
| Slot and colours | shared: shared constant `#6e4a2c`; accents bone `#f3e6c8` |
| Parts (`data-pivot`) | `root` (320 410) |
| Idle | none (breathe only) |
| Layer ids | `root_body`, `root_outline`, `root_detail` |
| `detail` (second cues) | 2 small pebble flecks |
| Node plan (A-candidate) | 1 parts, ~4 body fills, ~2 detail elements (2 small pebble flecks) → stage 7 (cap 23), parade 5 (cap 15) |

### ASSET-027 — N Nest (`dino_n_nest_01`) · batch 5

| Field | Value |
|---|---|
| Category | Cast member, layered SVG + its silhouette |
| Files | `src/art/cast_dino_n_nest_01.svg`, `src/sil/sil_dino_n_nest_01.svg` (baked to `cast/…json`, `sil/…json`) |
| Family / variant | object / nest |
| Outline trait | a woven bowl nest with one cream egg showing a little peeking eye (an object) |
| Slot and colours | shared: shared constant `#a8743f`; accents egg `#f3e6c8` |
| Parts (`data-pivot`) | `root` (320 410) · `egg` (320 352) |
| Idle | egg wobble with a peek (`egg`, rotate) |
| Layer ids | `root_body`, `root_outline`, `root_detail`, `egg_body`, `egg_outline`, `egg_detail` |
| `detail` (second cues) | weave lines ×3, the peek eye |
| Node plan (A-candidate) | 2 parts, ~5 body fills, ~4 detail elements (weave lines ×3, the peek eye) → stage 11 (cap 23), parade 7 (cap 15) |

### ASSET-028 — 0 · an empty nest (`dino_0_nest_01`) · batch 5

| Field | Value |
|---|---|
| Category | Cast member (the theme's `countedItem.emptyCastId`), layered SVG + its silhouette |
| Files | `src/art/cast_dino_0_nest_01.svg`, `src/sil/sil_dino_0_nest_01.svg` |
| Family / variant | object / nest, **empty**: N's nest drawn from the same source with the `egg` part removed (Key Table numbers) |
| Slot and colours | shared constant nest `#a8743f`, far-side weave `#835a31`, inner shadow Ink at 25% |
| Parts (`data-pivot`) | `root` (320 410) |
| Idle | none (breathe only) |
| Layer ids | `root_body`, `root_outline`, `root_detail` |
| `detail` | weave lines ×3 |
| Node plan (A-candidate) | 1 part, ~4 body, ~3 detail (weave lines) → stage 8, parade 5 |

### ASSET-029 — 1 · one baby dinosaur (`dino_1_babies_01`) · batch 5

| Field | Value |
|---|---|
| Category | Cast member (a counted group), layered SVG + its silhouette |
| Files | `src/art/cast_dino_1_babies_01.svg`, `src/sil/sil_dino_1_babies_01.svg` |
| Family / variant | babies / 1: the one shared **baby** drawing (Numbers master, below) placed 1× |
| Layout | front row 1 at x = 320 + 104·(i − 0), feet on y 410, scale 1.05 (as played) |
| Colours | baby `i` takes pastel `i` in the fixed order (Numbers master): `#7fcf8f` |
| Parts (`data-pivot`) | `root` (320 410) holding `baby_one`, each with its pivot at that baby's feet |
| Idle | each baby bobs on its own phase (Cast Rendering R7: `abs(sin(3t + ph))`, 0.95 Hz) |
| Layer ids | `root_*` (empty but present), and `baby_<word>_body`, `baby_<word>_outline`, `baby_<word>_detail` |
| Node plan (A-candidate) | 1 baby parts (root holds no shapes), per baby 3 body + 2 detail (eye highlight, smile) + 1 outline → stage 6, parade 4 |

### ASSET-030 — 2 · two baby dinosaurs (`dino_2_babies_01`) · batch 6

| Field | Value |
|---|---|
| Category | Cast member (a counted group), layered SVG + its silhouette |
| Files | `src/art/cast_dino_2_babies_01.svg`, `src/sil/sil_dino_2_babies_01.svg` |
| Family / variant | babies / 2: the one shared **baby** drawing (Numbers master, below) placed 2× |
| Layout | front row 2 at x = 320 + 104·(i − 0.5), feet on y 410, scale 1.05 (as played) |
| Colours | baby `i` takes pastel `i` in the fixed order (Numbers master): `#7fcf8f`, `#f2a37a` |
| Parts (`data-pivot`) | `root` (320 410) holding `baby_one` · `baby_two`, each with its pivot at that baby's feet |
| Idle | each baby bobs on its own phase (Cast Rendering R7: `abs(sin(3t + ph))`, 0.95 Hz) |
| Layer ids | `root_*` (empty but present), and `baby_<word>_body`, `baby_<word>_outline`, `baby_<word>_detail` |
| Node plan (A-candidate) | 2 baby parts (root holds no shapes), per baby 3 body + 2 detail (eye highlight, smile) + 1 outline → stage 12, parade 8 |

### ASSET-031 — 3 · three baby dinosaurs (`dino_3_babies_01`) · batch 6

| Field | Value |
|---|---|
| Category | Cast member (a counted group), layered SVG + its silhouette |
| Files | `src/art/cast_dino_3_babies_01.svg`, `src/sil/sil_dino_3_babies_01.svg` |
| Family / variant | babies / 3: the one shared **baby** drawing (Numbers master, below) placed 3× |
| Layout | front row 3 at x = 320 + 104·(i − 1), feet on y 410, scale 1.05 (as played) |
| Colours | baby `i` takes pastel `i` in the fixed order (Numbers master): `#7fcf8f`, `#f2a37a`, `#8fb4ea` |
| Parts (`data-pivot`) | `root` (320 410) holding `baby_one` · `baby_two` · `baby_three`, each with its pivot at that baby's feet |
| Idle | each baby bobs on its own phase (Cast Rendering R7: `abs(sin(3t + ph))`, 0.95 Hz) |
| Layer ids | `root_*` (empty but present), and `baby_<word>_body`, `baby_<word>_outline`, `baby_<word>_detail` |
| Node plan (A-candidate) | 3 baby parts (root holds no shapes), per baby 3 body + 2 detail (eye highlight, smile) + 1 outline → stage 18, parade 12 |

### ASSET-032 — 4 · four baby dinosaurs (`dino_4_babies_01`) · batch 6

| Field | Value |
|---|---|
| Category | Cast member (a counted group), layered SVG + its silhouette |
| Files | `src/art/cast_dino_4_babies_01.svg`, `src/sil/sil_dino_4_babies_01.svg` |
| Family / variant | babies / 4: the one shared **baby** drawing (Numbers master, below) placed 4× |
| Layout | front row 4 at x = 320 + 104·(i − 1.5), feet on y 410, scale 1.05 (as played) |
| Colours | baby `i` takes pastel `i` in the fixed order (Numbers master): `#7fcf8f`, `#f2a37a`, `#8fb4ea`, `#d8b87a` |
| Parts (`data-pivot`) | `root` (320 410) holding `baby_one` · `baby_two` · `baby_three` · `baby_four`, each with its pivot at that baby's feet |
| Idle | each baby bobs on its own phase (Cast Rendering R7: `abs(sin(3t + ph))`, 0.95 Hz) |
| Layer ids | `root_*` (empty but present), and `baby_<word>_body`, `baby_<word>_outline`, `baby_<word>_detail` |
| Node plan (A-candidate) | 4 baby parts (root holds no shapes), per baby 3 body + 2 detail (eye highlight, smile) + 1 outline → stage 24, parade 16 **Over the single-figure caps: see Render limits, R-3.** |

### ASSET-033 — 5 · five baby dinosaurs (`dino_5_babies_01`) · batch 6

| Field | Value |
|---|---|
| Category | Cast member (a counted group), layered SVG + its silhouette |
| Files | `src/art/cast_dino_5_babies_01.svg`, `src/sil/sil_dino_5_babies_01.svg` |
| Family / variant | babies / 5: the one shared **baby** drawing (Numbers master, below) placed 5× |
| Layout | front row 5 at x = 320 + 104·(i − 2), feet on y 410, scale 1.05 (as played) |
| Colours | baby `i` takes pastel `i` in the fixed order (Numbers master): `#7fcf8f`, `#f2a37a`, `#8fb4ea`, `#d8b87a`, `#c39af0` |
| Parts (`data-pivot`) | `root` (320 410) holding `baby_one` · `baby_two` · `baby_three` · `baby_four` · `baby_five`, each with its pivot at that baby's feet |
| Idle | each baby bobs on its own phase (Cast Rendering R7: `abs(sin(3t + ph))`, 0.95 Hz) |
| Layer ids | `root_*` (empty but present), and `baby_<word>_body`, `baby_<word>_outline`, `baby_<word>_detail` |
| Node plan (A-candidate) | 5 baby parts (root holds no shapes), per baby 3 body + 2 detail (eye highlight, smile) + 1 outline → stage 30, parade 20 **Over the single-figure caps: see Render limits, R-3.** |

### ASSET-034 — 6 · six baby dinosaurs (`dino_6_babies_01`) · batch 6

| Field | Value |
|---|---|
| Category | Cast member (a counted group), layered SVG + its silhouette |
| Files | `src/art/cast_dino_6_babies_01.svg`, `src/sil/sil_dino_6_babies_01.svg` |
| Family / variant | babies / 6: the one shared **baby** drawing (Numbers master, below) placed 6× |
| Layout | front row 5 at x = 320 + 104·(i − 2), feet on y 410, scale 1.05; back row 1 at x = 320 + 104·(j − 0), feet on y 292, scale 0.95, drawn first (as played) |
| Colours | baby `i` takes pastel `i` in the fixed order (Numbers master): `#7fcf8f`, `#f2a37a`, `#8fb4ea`, `#d8b87a`, `#c39af0`, `#f29ab0` |
| Parts (`data-pivot`) | `root` (320 410) holding `baby_one` · `baby_two` · `baby_three` · `baby_four` · `baby_five` · `baby_six`, each with its pivot at that baby's feet |
| Idle | each baby bobs on its own phase (Cast Rendering R7: `abs(sin(3t + ph))`, 0.95 Hz) |
| Layer ids | `root_*` (empty but present), and `baby_<word>_body`, `baby_<word>_outline`, `baby_<word>_detail` |
| Node plan (A-candidate) | 6 baby parts (root holds no shapes), per baby 3 body + 2 detail (eye highlight, smile) + 1 outline → stage 36, parade 24 **Over the single-figure caps: see Render limits, R-3.** |

### ASSET-035 — 7 · seven baby dinosaurs (`dino_7_babies_01`) · batch 6

| Field | Value |
|---|---|
| Category | Cast member (a counted group), layered SVG + its silhouette |
| Files | `src/art/cast_dino_7_babies_01.svg`, `src/sil/sil_dino_7_babies_01.svg` |
| Family / variant | babies / 7: the one shared **baby** drawing (Numbers master, below) placed 7× |
| Layout | front row 5 at x = 320 + 104·(i − 2), feet on y 410, scale 1.05; back row 2 at x = 320 + 104·(j − 0.5), feet on y 292, scale 0.95, drawn first (as played) |
| Colours | baby `i` takes pastel `i` in the fixed order (Numbers master): `#7fcf8f`, `#f2a37a`, `#8fb4ea`, `#d8b87a`, `#c39af0`, `#f29ab0`, `#6fc9c0` |
| Parts (`data-pivot`) | `root` (320 410) holding `baby_one` · `baby_two` · `baby_three` · `baby_four` · `baby_five` · `baby_six` · `baby_seven`, each with its pivot at that baby's feet |
| Idle | each baby bobs on its own phase (Cast Rendering R7: `abs(sin(3t + ph))`, 0.95 Hz) |
| Layer ids | `root_*` (empty but present), and `baby_<word>_body`, `baby_<word>_outline`, `baby_<word>_detail` |
| Node plan (A-candidate) | 7 baby parts (root holds no shapes), per baby 3 body + 2 detail (eye highlight, smile) + 1 outline → stage 42, parade 28 **Over the single-figure caps: see Render limits, R-3.** |

### ASSET-036 — 8 · eight baby dinosaurs (`dino_8_babies_01`) · batch 6

| Field | Value |
|---|---|
| Category | Cast member (a counted group), layered SVG + its silhouette |
| Files | `src/art/cast_dino_8_babies_01.svg`, `src/sil/sil_dino_8_babies_01.svg` |
| Family / variant | babies / 8: the one shared **baby** drawing (Numbers master, below) placed 8× |
| Layout | front row 5 at x = 320 + 104·(i − 2), feet on y 410, scale 1.05; back row 3 at x = 320 + 104·(j − 1), feet on y 292, scale 0.95, drawn first (as played) |
| Colours | baby `i` takes pastel `i` in the fixed order (Numbers master): `#7fcf8f`, `#f2a37a`, `#8fb4ea`, `#d8b87a`, `#c39af0`, `#f29ab0`, `#6fc9c0`, `#e48a5a` |
| Parts (`data-pivot`) | `root` (320 410) holding `baby_one` · `baby_two` · `baby_three` · `baby_four` · `baby_five` · `baby_six` · `baby_seven` · `baby_eight`, each with its pivot at that baby's feet |
| Idle | each baby bobs on its own phase (Cast Rendering R7: `abs(sin(3t + ph))`, 0.95 Hz) |
| Layer ids | `root_*` (empty but present), and `baby_<word>_body`, `baby_<word>_outline`, `baby_<word>_detail` |
| Node plan (A-candidate) | 8 baby parts (root holds no shapes), per baby 3 body + 2 detail (eye highlight, smile) + 1 outline → stage 48, parade 32 **Over the single-figure caps: see Render limits, R-3.** |

## Open questions

| # | Question | Owner | Recommendation |
|---|---|---|---|
| OQ-1 | Duckbills, horned, plated and ornithomimids have **no family idle** in Cast Rendering's data (art bible §5 lists sauropod, raptor, ankylosaur, rex, nest and flyer idles only), so 13 letters (E H I L M, C X Z, S K W, G O) only breathe. Add idles? | Cast Rendering owner; Luan (it changes the feel) | Yes, in data later: a slow `head` nod (≤ 0.3 Hz) and a small `tail` sway. These specs already give them `head` and `tail` parts with pivots, so no redraw is needed. |
| OQ-2 | Numbers 4–9 exceed the single-figure caps (R-3). Measure the 9 babies in P-2 / M-13, or pick a fallback now? | game-dev-ios (ADR-0009) | **Agreed (game-dev-ios, TASK-133 review):** the 9 babies are measured as a fourth figure in P-2 and M-13. 4–9 stay budget pending until then; if 9 fails, the per-role mix comes first (R-3). |
| OQ-3 | The far-side shade is the body −10 lightness points; for the darkest bodies (T 0.228, U 0.229, A 0.269) it drops to about 0.14. Fine on the stage? | game-art-content, at batch 1 | Check on T in batch 1 against the Night dim. If the far legs vanish, use −6 instead. |

## Not covered here

- Sounds (`sfx_dino_…`), voice lines (TASK-108/110) and glyphs (`glyph_…`), which have their own specs and pipelines.
- The scene, hints, meter and UI art (art bible §6, §7).
- Production variety (more items per key, K-07): later editions are `_02`, etc.
