# TASK-137: Dinosaurs batches 3–6 art (the remaining 24 items)

**What:** the 24 remaining cast items, drawn by the family templates in `content/themes/dinosaurs/src/art-tools/` to
`design/assets/specs/dinosaurs-assets.md`. With batches 1 and 2, the Dinosaurs theme now has **all 36** items, each a
layered cast SVG plus a silhouette.

| Batch | Items | Templates |
|---|---|---|
| 3 | E Edmontosaurus, H Hadrosaurus, I Iguanodon, L Lambeosaurus, M Maiasaura | duckbill |
| 4 | C Triceratops, X Xenoceratops, Z Zuniceratops, S Stegosaurus, K Kentrosaurus, W Wuerhosaurus | horned, plated |
| 5 | G Gallimimus, O Oviraptor, F Fossil, N Nest (with an egg), 0 Empty nest, 1 One baby | ornithomimid, objects, babies |
| 6 | 2–8 baby dinosaurs | babies |

The branch is stacked on batch 2 (`content/dino-batch-2` @ 7da516b6). It goes to review as one batch, as the leader
agreed, once the template approach is approved on batch 2.

**Contact sheets:**
- `contact-sheet-batch3-4.png`
- `contact-sheet-batch5-6.png`
- `contact-sheet-cumulative.png`: all 36.

They were rendered headless (`qlmanage -t`, no window), and the SVG sources sit beside them. Sheets of more than 12
items now use 4 pairs per row, so they fit Quick Look's square.

## Checks

| Check | Result |
|---|---|
| `nice -n 10 bash tools/ci/verify.sh --dev --no-xcode` | **PASS** (`verify.log`, paths masked). The theme still reads **NOT ASSESSED: in progress** (src/ only). `swift test Tools` includes story 004's raster check on **all 36** baked pairs. |
| Local D4 lint | **PASS, 72 files, 0 problems** (`lint.log`). |
| Node plan (R-2): parts, stage / parade (`figures-run.log`) | E 3, 16/12 · H 3, 16/12 · I 3, 15/11 · L 3, 16/12 · M 3, 18/13 · C 3, 17/13 · X 3, 17/13 · Z 3, 17/13 · S 3, 18/14 · K 3, 17/13 · W 3, 16/12 · G 3, 17/13 · O 3, 17/13 · F 1, 4/3 · N 2, 11/4 · 0 1, 6/2: all within 23 / 15 and ≤ 5 parts. **Babies 1–8:** 6 stage / 4 parade per baby, from 1 = 6/4 to 8 = 48/32. 4–8 are over the single-figure caps and stay **budget pending** (R-3), as 9 does. |
| Fill (S-1) | All figures pass except babies 1–3, which the **S-1 proposed default** exempts. The spec is updated in this branch: one fixed baby size, so the count reads. The leader recorded it as a Proposed default that Luan can overturn. The run prints `fill exempt` for them. |
| Reproducible | A fresh `figures.py` run of all 36 keys into scratch matched all 72 committed SVGs byte for byte. Batches 1 and 2 are unchanged. |

## Template fixes made on the visual pass (before commit)

- **Duckbills:** the front leg comes down from under the chest. Placed in front of the body, it read as a separate
  post.
- **K:** the tall hip spikes sit on the back, not just above it.
- **I:** the thumb spike points forward out of the chest, where it reads.
- **J (batch 2's branch already holds it):** the smile is kept inside the short head.
- **After game-dev-ios's batch-2 render note** (body shapes no thinner than about 12 units, since the parade keeps
  `body`): S's four tail spikes, C's nose horn, X's short brow horns and the duckbills' front toe went from 10 units
  to 12. The counts are unchanged.

## My calls to review

- **Duckbills:**
  - E's bill is a cream duck bill;
  - H has a bump on its nose;
  - L's hatchet crest is a rounded quad;
  - M has a brow mark, with a tiny baby beside her front foot that is part of her outline.
- **X:** a row of four long spikes on the frill. **Z:** a smaller frill with two long brow horns.
- **S:** two staggered plate rows (far and near) and four tail spikes. **W:** low, wide, rounded plates.
- **G:** a beaked small head, a long neck and a fluffy tail tip. **O:** a tall crest and a parrot beak.
- **F:** a bone ring in a rock slab. Its silhouette is the rock alone, because the bone is inside it.
- **N:** the egg is its own part, `egg`, with a pivot for the egg wobble, behind the nest's front.
- **Babies:** 6–8 put the extra babies in a back row (5 in front). This is the same rule as 9.

## Not in this branch

There is still no `theme.json`, no bake and no sounds.
