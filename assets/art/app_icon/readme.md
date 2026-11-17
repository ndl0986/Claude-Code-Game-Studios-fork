# App icon: PLACEHOLDER (TASK-026)

> **PLACEHOLDER.** It is good for TestFlight and internal builds. Final art waits for **D-18**
> (Luan's portrayal and palette sign-off). Asset manifest: ASSET-336 to ASSET-340.

**The mark:** a 12-point bronze-drum sun star (the centre star of a Đông Sơn drum) in bronze gold
`#E8A93B`. It has an ink-brown `#4A3428` outline and a paper-cream hub, and sits on a storm-indigo
`#3B3F6B` disc with an ink ring, over a river-blue `#3E8FC4` field. The colours come from the art
bible §4. The icon has no text, because text can't be read at icon size.

**Why not Trần Quốc Toản's flag:**
- its look belongs to the open D-18 portrayal;
- its bars are the answer to quiz Q4, so the icon would give the answer away.

## Files

| File | Size | Format | Use |
|---|---|---|---|
| `icon_ios_1024.png` | 1024×1024 | RGB, **no alpha**, square corners | iOS AppIcon (single size) and App Store. iOS applies the corner mask |
| `play_512.png` | 512×512 | RGB | Google Play listing icon. Play applies its own mask |
| `ic_launcher_foreground.png` | 432×432 (108dp @ xxxhdpi) | RGBA | Android adaptive icon foreground |
| `ic_launcher_background.png` | 432×432 | RGB, solid river blue | Android adaptive icon background |
| `ic_launcher_monochrome.png` | 432×432 | RGBA, white star on transparent | Android 13+ themed icon |

Regenerate with `python -I tools/art/make_app_icon.py .` (needs Pillow). The output is
deterministic.

## Safe zone (Android)

Every launcher mask (circle, squircle, rounded square, teardrop) keeps the centre **66dp circle**
of the 108dp layer, which is radius 132 px at 432 px. The script checks this and fails if
anything is outside it:

- foreground mark radius **120 px** (30dp) vs 132 px: OK
- monochrome star radius **102 px** vs 132 px: OK

On iOS the mark is a circle of radius 0.40 of the side. The rounded-corner mask (about 0.22 of the
side) never reaches it.

## Small-size check (previews)

These show how the icon looks under each mask at home-screen sizes. The Android previews are the
composite of both layers, cropped to the 72dp viewport and then masked.

| Preview | Size | Mask |
|---|---|---|
| `previews/ios_60.png`, `previews/ios_40.png` | 60, 40 px | iOS rounded rect (0.2237) |
| `previews/android_circle_60.png`, `_40.png` | 60, 40 px | circle |
| `previews/android_squircle_60.png`, `_40.png` | 60, 40 px | squircle (superellipse n = 4) |
| `previews/android_roundsquare_60.png`, `_40.png` | 60, 40 px | rounded square (0.16) |
| `previews/sheet.png` | all of the above at 4× zoom | for review |

At 40 px the star still shows its points, and the gold-on-indigo contrast holds under every mask.

## Wiring (for game-dev-ios / game-dev-android)

**iOS (Xcode 14+ single-size icon):** put `icon_ios_1024.png` in
`Assets.xcassets/AppIcon.appiconset/` and list it once in `Contents.json` with
`"idiom": "universal", "platform": "ios", "size": "1024x1024"`. Xcode generates the other sizes.

**Android:** copy the three layer PNGs to `res/mipmap-xxxhdpi/` (or scale them into the other
densities). Add `res/mipmap-anydpi-v26/ic_launcher.xml`:

```xml
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>
</adaptive-icon>
```

Use the same file as `ic_launcher_round.xml`. `<monochrome>` needs API 33, and older versions
ignore it. A legacy `ic_launcher.png` for API < 26 can be cut from `play_512.png`.
