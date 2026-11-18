<!-- PROTOTYPE - NOT FOR PRODUCTION -->
# Spike test art (TASK-077): three layered creatures for the ADR-0009 render spike

**SPIKE / TEST ART ONLY.** These are not Dinosaurs-set items and must not ship, unless Luan later says otherwise.
They exist so the ADR-0009 render spike (game-dev-ios) measures real layered art (parts, layers, pivots, strokes),
not only the TASK-033 silhouette.

**Where:** ADR-0003 D1 puts source SVGs at `content/themes/<id>/src/art/`, but it gives no path for test art, and
files there would look like set items to the bake tool and the staleness check. So they live here,
`prototypes/DeviceSpike/art/`, as the leader asked.

## Hypothesis, how to run, status

- **Hypothesis served:** the ADR-0009 spike can measure frame time and load time of layered cast art (parts,
  nested pivots, three layers, 80% stroke groups) on real devices with either rendering option.
- **How to use:** the spike loads these SVGs (or their bake, once the ADR-0003 bake tool exists). Open any file in
  a browser or Quick Look to view it.
- **Status:** in progress (art delivered; the spike's findings are game-dev-ios's, in ADR-0009).
- **Findings:** the layer-id point below; no others yet.

## The files

| File | Family / key | Moving parts (`data-pivot`, artboard units) | Body hue slot |
|---|---|---|---|
| `cast_dino_d_testsauropod_01.svg` | sauropod, D | `root` (320 410), `tail` (182 316), `neck` (400 262) → `head` (474 126) | teal `#5fb3a8` (L 0.375, S 36%) |
| `cast_dino_t_testrex_01.svg` | rex, T | `root`, `tail` (196 270), `neck` (360 250) → `head` (380 176) → `jaw` (398 182) | violet `#9b7fd0` (L 0.267, S 46%) |
| `cast_dino_q_testflyer_01.svg` | flyer, Q | `root`, `wing_far` (312 282), `wing_near` (342 286) | coral `#c4864a` (L 0.293, S 51%) |

- **Naming:** ADR-0003 D1 and Key Table V6: `cast_<assetPrefix>_<key>_<name>_<nn>`, prefix `dino`, one-token names
  (`testsauropod`, `testrex`, `testflyer`), edition `01`. The `test` in each name keeps them apart from real items.
- **Artboard:** 640 × 440, anchor at the feet (320, 410), facing right (art bible §8, Cast Rendering R2).
- **Subset** (ADR-0003 D4, Cast Rendering R2): only `svg`, `g`, `path`, `circle`, `ellipse`, `rect`; `fill`,
  `fill-opacity`, `stroke`, `stroke-width`, round joins and caps, `opacity` on `g`, `rotate` transforms, `id`,
  `data-pivot`; hex colours and `none`. No CSS, gradients, `use`, masks, filters or text. A `<title>` marks each file
  as test art (ignored by the bake, D4). Checked with a local script against D4's three layers.
- **Layers:** every part has `body`, `outline` and `detail` layer groups, drawn in that order. The `outline` layer is
  Ink `#2a2340`, 6 units, round joins and caps, `fill="none"`, **group opacity 0.8** (art bible §4), so where
  strokes overlap they don't darken. Tails and necks are their own parts placed **before** the torso, so the torso
  covers their joins.
- **Colour** (art bible §4): body colours are in the band (L 0.20–0.47, S 35–65%), in three different hue slots;
  accents (the flyer's crest `#d9534f`, S 64%) are ≤ 75%. There is no gold and no Letter Gold. Eyes are highlight
  cream `#f8efdc` with Ink pupils, blush is rose `#e8a6b8` at 70%, and every face is friendly (art bible §5): closed
  smiles, no teeth, no claws at the viewer.
- **K-16 / K-25:** the creatures carry no glow and no gold (K-16 keeps gold for the stardust only); K-25's per-look
  changes (the 15% Night dim) are applied by Cast Rendering at draw time, not baked into the art.
- **Not included:** silhouettes (`sil_…svg`). The spike measures drawing; a real item's silhouette export (one
  compound path, art bible §8) would come with the set art.

## A finding for ADR-0003 D4 (layer ids)

D4 says each part group holds the layer groups `body`, `outline` and `detail`, identified by `id`. SVG ids must be
**unique in a file**, so once parts nest (`neck` → `head` → `jaw`) every part can't have a group with `id="body"`.
These files use **`<part>_<layer>`** (`root_body`, `neck_outline`, `jaw_detail`). The bake tool should read layers
by that suffix (or by an agreed `data-layer` attribute, which D4's allow-list would then need). Flagged to
game-dev-ios and the leader in TASK-077.

## Evidence

Headless renders (macOS Quick Look thumbnailer `qlmanage -t`, no window; K-34) are retained in
`production/qa/evidence/TASK-077/` as 1280 × 1280 PNGs, which shows the artboard scaled 2× and centred on white.
