# Dinosaurs art tools

These scripts draw the Dinosaurs cast as code. They write the layered cast SVGs (`../art/`) and the silhouettes
(`../sil/`) to `design/assets/specs/dinosaurs-assets.md`. Every figure in `../art/` and `../sil/` comes from these
scripts. To change a figure (after Luan's look, say), edit its template here and regenerate. Don't hand-edit the
SVGs, or the next run will overwrite your change.

| File | What it does |
|---|---|
| `lib.py` | The helpers (from TASK-136): shape primitives; `Part` (one part with its `data-pivot`, its body, outline and detail groups, and its back and front child parts); the writer; the node and fill checks. |
| `figures.py` | One parametric template per family (rex, flyer, sauropod, raptor, ankylosaur, duckbill, horned, plated, ornithomimid, objects, babies), the spec's colours per item, and the `FIG` table mapping each key to its template. |
| `contact_sheet.py` | Builds a square review sheet: each cast SVG beside its grey silhouette, at half size. |
| `lint.py` | A local check of the ADR-0003 D4 SVG subset and structure. |

## Regenerating

The scripts need Python 3 and **shapely**, installed in a throwaway venv **outside the repo**. Don't commit the
venv.

```sh
python3 -m venv <scratch>/geovenv && <scratch>/geovenv/bin/pip install shapely
<scratch>/geovenv/bin/python -I content/themes/dinosaurs/src/art-tools/figures.py content/themes/dinosaurs t,d,r,p,a,9
<scratch>/geovenv/bin/python -I content/themes/dinosaurs/src/art-tools/lint.py content/themes/dinosaurs/src/{art,sil}/*.svg
```

- **Keys:** `figures.py` takes a comma list of keys: letters, and `0`–`9`.
- **What it prints:** for each figure, its part count, its stage and parade node counts against the spec's caps
  (R-2: stage ≤ 23, parade ≤ 15, ≤ 5 parts), its bounding box and the S-1 fill check. It ends with `ALL OK` or
  `PROBLEM`.
- **Same input, same bytes:** the output depends only on the templates, so a re-run writes byte-identical files.
- **Review sheet:** `contact_sheet.py <theme-dir> <out.svg> <stem>…` writes the sheet. Render it headless, with no
  window: `qlmanage -t -s 1800 -o <dir> <out.svg>`.

## How a figure is built

- **Body colours:** the same-colour body shapes within a part are unioned into one path per colour (ADR-0009 D3
  counts fills).
- **Outline:** each part's outline is the boundary of its body union (Ink, 6 units, round joins and caps, opacity
  0.8).
- **Silhouette:** the union of every body shape, grown by 3 units with round joins, written as one `M`/`L`/`Z`
  path. So ADR-0003 D4's raster check holds by construction.
- **Thinnest body shape: 12 units** (about 2–3 px at the parade size; game-dev-ios render note): nothing in `body` is drawn thinner, since the parade keeps body and drops detail.
- **Idle parts (OQ-1):** families with a head or tail draw them as parts with pivots, pending OQ-1.
- **The babies (R-3):** they keep one fixed size across every number, so S-1's 60 % fill can't bind them. The spec's
  S-1 proposed default exempts Numbers 1–3 (4–9 meet it by width); the run prints `fill exempt` for a baby figure
  that falls short.
  Their node caps are per baby.

## Licence of the geometry library

shapely 2.2.0 is **BSD-3-Clause** (its package metadata says `License-Expression: BSD-3-Clause`). Its wheel bundles
the GEOS 3.14.1 library (LGPL-2.1). Both are used **only at authoring time**, in the venv:
- nothing from them is committed;
- nothing from them is linked into the app;
- nothing from them ships with the content.

The committed SVGs are plain data. No other third-party code is used.
