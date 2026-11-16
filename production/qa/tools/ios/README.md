# iOS QC helpers (game-qc-ios)

Scripts kept here because the session scratchpad is wiped on restart. Compile the Swift ones into a scratch
folder, never into the repo: `swiftc -O scan.swift -o $TMPDIR/scan` (same for hist2, sheet).

- `q8.sh`: screenshot, launch with debug args, terminate, dump the app's UserDefaults (`U=` picks the Simulator).
- `scan.swift`: colour runs along a row/column (index = px/2) for measuring sizes and edges in screenshots.
- `hist2.swift`: top exact colours in a rect (ink/outline sampling, contrast).
- `sheet.swift`: contact sheet for viewing several shots at once (squashes aspect; never measure on it).

Geometry notes: 18 Pro shots are 2622×1206 (3×); 17e 2532×1170. World px per screen px is measured from a known
feature (the beat-card placeholder 25–233 gave 1.545 px/world on the 17e). Seed saves with
`xcrun simctl spawn <udid> defaults write <data container>/Library/Preferences/<bundle id> key -int N` while the app is
stopped. XCUITest attachments are portrait 1206×2622.
