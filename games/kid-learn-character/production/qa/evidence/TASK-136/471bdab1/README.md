# TASK-136: Dinosaurs batch 1 art (T, D, R, P, A, 9)

**What:** the first six cast members of the Dinosaurs theme, drawn to `design/assets/specs/dinosaurs-assets.md`
(TASK-133): the layered cast SVG and the silhouette SVG for each, in `content/themes/dinosaurs/src/art/` and
`src/sil/`. The directory name is the plan commit the branch was cut from (`471bdab1`).

**Contact sheet for Luan:** `contact-sheet-batch1.png`, each cast SVG beside its silhouette (grey), on the
640 × 440 artboard with the feet line y 410. It was rendered headless with macOS Quick Look's thumbnailer (`qlmanage -t`,
no window; K-34), like the TASK-077 evidence. Its SVG source is `render-scripts/contact-sheet.svg`.

## How the art was made

The figures are team-authored (K-48), drawn as code in `render-scripts/draw.py`. Each body is built from simple
shapes: ellipses, circles, rounded rectangles, and one carved jaw. The script then does three things:
- **Body colours:** it unions the same-colour body shapes within a part into **one path per colour**. So a part's
  `body` layer holds one node per colour (ADR-0009 D3 counts fills per element).
- **Outline:** it writes each part's outline as **one path, the boundary of the union of that part's body shapes**:
  Ink, 6 units, round joins, `opacity 0.8` on the group (spec S-3).
- **Silhouette:** it writes the silhouette as the union of every body shape, **grown by 3 units with round joins**
  (the outer half of the outline stroke), as one compound path of `M`/`L`/`Z` only. So ADR-0003 D4's raster check
  (the silhouette against body + outer outline at rest) holds **by construction**, within the path-flattening error
  (24 segments per quarter circle).

The geometry library is shapely 2.2, installed in a throwaway venv in the session scratchpad (not committed). Re-running
`draw.py` with it reproduces these files exactly.

## Checks

| Check | Result |
|---|---|
| `nice -n 10 bash tools/ci/verify.sh --dev --no-xcode` | **PASS** (see the commit's report). `kidtools validate content`: PASS, with the theme **NOT ASSESSED: in progress** (src/ only, no theme.json yet) and **no FAIL**. |
| SVG subset and structure (ADR-0003 D4), local lint `render-scripts/lint.py` | **PASS, 12 files, 0 problems**: elements and attributes, hex colours, round joins and caps, no skew; unique ids; one `root`; part names `[a-z]+(_[a-z]+)*`; every part has `data-pivot` and its `_body`, `_outline`, `_detail` groups in order; outline stroke and 0.8; silhouettes one path, `M L Z` only, an `M` after every `Z`, no exponents. This stands in for the bake tool's checks, which come with the bake-tool story (`ContentValidator` only checks the staleness stub today). |
| Node plan (spec R-2), counted by `draw.py` | T 5 parts, stage 19 / parade 15 · D 4, 17 / 13 · R 3, 15 / 11 · P 3, 13 / 9 · A 3, 16 / 12: all within 23 / 15 and ≤ 5 parts. **9:** 9 baby parts, 54 / 36, the R-3 worst case agreed for measurement in P-2 / M-13 (budget pending). |
| Fill (spec S-1) | every figure ≥ 264 units tall or ≥ 384 wide, inside the artboard; feet on y 410. |

## Findings for the spec (fixed in this branch)

- **Part names can't hold digits** (ADR-0003 D4: `[a-z]+(_[a-z]+)*`). The spec's `baby_1` … `baby_n` would have
  failed the bake, so the babies are now `baby_one` … `baby_nine`.
- **S-2's part order:** "a child comes after the parent's layers" was too strict. Cast Rendering draws in document
  order, so back parts (tail, neck, far wing) come **before** the parent's layers, as the TASK-077 art does.
- **The baby's feet** have no cream toes, which keeps the baby at the 3 body shapes the node plan counts.
- **OQ-3 (the far-side shade):** at the body −10 lightness points, T's far leg (`#7f48c5`) reads clearly and stays
  separate from the near leg on the cream stage. No change yet; check it again on the device at Night (the 15% dim).
- **OQ-1 (idles):** still with Luan. `head` and `tail` parts are drawn with pivots on every figure that has them, as
  the spec says.

## Not in this batch

No `theme.json`, no bake, no sounds, and the other 30 items (batches 2–6).
