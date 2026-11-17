# iOS QC helpers (game-qc-ios)

> **TASK-028 (2026-11-17):** the game moved to `games/dai-dat-anh-hung/`. Every path in this guide is relative to that
> folder; run the commands from there (e.g. `cd games/dai-dat-anh-hung`).

Scripts kept here because the session scratchpad is wiped on restart. Compile the Swift ones into a scratch
folder, never into the repo: `swiftc -O scan.swift -o $TMPDIR/scan` (same for hist2, sheet).

- `q8.sh`: screenshot, launch with debug args, terminate, dump the app's UserDefaults (`U=` picks the Simulator).
- `scan.swift`: colour runs along a row/column (index = px/2) for measuring sizes and edges in screenshots.
- `hist2.swift`: top exact colours in a rect (ink/outline sampling, contrast).
- `sheet.swift`: contact sheet for viewing several shots at once (squashes aspect; never measure on it).
- `raw.swift` (`raw <png> x y`): the stored pixel value (NSBitmapImageRep getPixel). Use it for colours; `hist2`'s sRGB
  conversion shifts them (#F1C9A0 read as #F5D3AF).
- `findc.swift` (`findc <png> r g b [tol]`): 40 px grid cells holding an exact colour (where a colour is, and isn't).
- `crop.swift` (`crop <png> x y w h scale <out>`): crop in screen coordinates and scale up, for viewing.
- `col.swift` (`col <png> x y0 y1`): runs of one colour down a column (button heights, rims).
- `gap.swift` (`gap <png> x0 x1 y0 y1`): the smallest gap between a gold drum ring and ink text below it (iOS-R11-01).

Geometry notes: 18 Pro shots are 2622×1206 (3×); 17e 2532×1170. World px per screen px is measured from a known
feature (the beat-card placeholder 25–233 gave 1.545 px/world on the 17e). Seed saves with
`xcrun simctl spawn <udid> defaults write <data container>/Library/Preferences/<bundle id> key -int N` while the app is
stopped. XCUITest attachments report portrait 1206×2622 to sips, but NSBitmapImageRep (every tool here) reads them in
landscape screen coordinates 2622×1206; `crop` gives a viewable landscape copy.
