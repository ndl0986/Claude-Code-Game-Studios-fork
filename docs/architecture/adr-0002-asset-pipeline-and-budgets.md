# ADR-0002: Asset pipeline and texture/memory budgets

## Status
Proposed

## Date
2026-11-14

## Last Verified
2026-11-14

## Decision Makers
Luan (accepts; logged as D-19); game-dev-ios (author); game-dev-android (input and peer review);
game-art-content (asks for the budgets; agrees the follow-up schema change); the game team leader (relay).

## Summary
Both native apps scale one 1280×720 world, so art ships as **one resolution set at 1.5× (a 1920×1080
world)**, authored at 2×. No texture is larger than **2048×2048**. Sprites are split into atlases by
what is on screen together. Sprites use lossless WebP and backgrounds lossy WebP (PNG still allowed).
**At most 64 MB of decoded textures are alive at any moment**: the hero, enemies and UI stay
resident; backgrounds and theme props load per beat, with the next beat prefetched. The iOS minimum is **iOS 17**. The numbers
are proposals until both apps measure them (Validation Criteria).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Native per platform (ADR-0001): iOS Swift + SpriteKit; Android Kotlin + Android SDK (hardware Canvas) |
| **Domain** | Rendering / Core (asset loading and memory) |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH. **NOT SOURCEABLE**: no `docs/engine-reference/` exists for SpriteKit, Metal or the Android SDK. Texture limits below come from the platforms' published minimums as the devs know them, and are verified by measuring (Validation Criteria), not from a pinned reference. |
| **References Consulted** | ADR-0001; `design/assets/asset-manifest.md` and `design/assets/specs/*.md` (TASK-014); `content/README.md`; `content/schema/assets.schema.json`; game-dev-android's Android input (2026-11-14) |
| **Post-Cutoff APIs Used** | None decided here. iOS decodes WebP through ImageIO (`UIImage`), available long before iOS 17. |
| **Verification Required** | Decode memory and frame time with a 2048² test atlas on the low-end Android target and on the iPhone Duo (iOS 27.1) Simulator, then on a real iPhone when one is available. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Accepted): native per platform, shared `content/data/`, offline bundle |
| **Enables** | The R19 picture-size check and the `assets.json` width/height fields (schema 1.2, a separate data branch after acceptance); TASK-013 (full-screen backdrop); final art production after D-18 |
| **Blocks** | Final art export (TASK-014 specs → files). Placeholder art in the slice is not blocked. |
| **Ordering Note** | Accept only after both apps' measurements are written into Validation Criteria. |

## Context

### Problem Statement
TASK-014 wrote 87 asset specs. Some sheets are large: the training partner is 25 frames of 512² cells,
a **4096×3072 sheet at 2×**, and the backgrounds are authored at 3840×2160. We have no engine to set
budgets (the template's `/setup-engine` budgets are NOT ASSESSED for native). The target includes
low-end Android phones and primary-school children's hand-me-down devices. Without a budget, a single
4096² sheet (64 MB decoded) can fail to upload or push a 1–2 GB phone out of memory.

### Constraints
- Gameplay is a fixed 1280×720 world scaled to the screen (ADR-0001), so the scale factor, not the
  screen density, picks how sharp art looks: k ≈ 1.3–1.5 on 1080p-tall phones (1.28 on the Android
  emulator; about 1.45 on the iPhone Duo cover display) and up to ~2 on tablets.
- OpenGL ES 3.0, and so Android's hardware Canvas, only guarantees a 2048 max texture size; a bitmap
  over the device limit is not drawn ("Bitmap too large to be uploaded into a texture").
- Fully offline, everything bundled (ADR-0001), so download size matters too.
- The two apps must look the same and load the same files from `content/data/`.

### Requirements
- Sharp on phones; acceptable on tablets.
- Never exceed the weakest supported GPU's texture limit.
- A mission's art fits comfortably in memory on the low-end target.
- One pipeline, one set of files, for both apps.

## Decision

1. **One resolution set: author at 2×, ship 1.5×.** Artists author at 2× (a 2560×1440 world). The
   export pipeline downsamples to **1.5×** (a 1920×1080 world), the only set bundled. There are no
   1×/2×/3× density buckets: neither app picks images by density. A 2× set is added only if tablets
   become a target, with its own budget review. The specs' "1×/2×" sizes stay as authoring references.
2. **No texture larger than 2048×2048**, on both platforms. iOS Metal allows larger textures, but both
   apps follow the Android floor so they ship the same files. Anything bigger is split:
   - **Sprite sheets:** split by animation set (e.g. the partner: idle/walk, windup/strike, cheer)
     into ≤ 2048² atlases. At 1.5× a 512² 2× cell becomes 384², so 25 frames fit in 2048² (5 × 5).
   - **Backgrounds:** 3840×2160 at 2× becomes 2880×1620 at 1.5×, split into **two tiles** of
     1440×1620 (or layer-by-layer parallax strips ≤ 2048 wide).
3. **Atlases by what is on screen together, loaded per beat:** hero; enemies (all three kinds); one
   props atlas per theme (village, bamboo, river, camp); UI and icons; quiz pictures per hero.
   Backgrounds are standalone images (tiles).
   - **Resident** for the whole mission: hero, enemies, UI/HUD and the font.
   - **Per beat:** that beat's theme background tiles and props. The next beat's set is prefetched
     during `walk_to` and the beat card, and the previous beat's set is released once the new beat plays.
   - **Quiz pictures** load when the quiz starts; play art is released then.
   - Decoding happens **off the render thread** on both apps.
   - **iOS:** `SKTexture.preload` / `SKTextureAtlas.preload` for the prefetch; textures are released by
     dropping every reference once the beat ends.
   - **Android:** decode with `Bitmap.Config.HARDWARE` (GPU memory only, one copy); `recycle()` after
     the last frame that draws the bitmap. The app ships as an AAB with all art in the base module (no
     Play Asset Delivery, offline per ADR-0001). WebP/PNG are stored uncompressed in the package, so
     asset bytes ≈ download bytes.
   Why per beat: TQT's mission uses 3 themes, and their backgrounds alone are about 53 MB decoded
   (2 tiles × 3 themes × 8.9 MB), so loading the whole mission at start cannot fit 64 MB.
4. **Formats:** lossless **WebP** for sprites with alpha; lossy WebP (quality ≈ 85) for opaque
   backgrounds; **PNG stays allowed** (`assets.json` already accepts png|webp). Both apps decode WebP
   (Android natively, iOS through ImageIO). Audio stays m4a/AAC or wav (ADR-0001); voice-over budgets
   are a later ADR. Android decodes with `Bitmap.Config.HARDWARE` (pixels in GPU memory only; RGB_565
   was measured but only halves WebP, not PNG, and HARDWARE makes it unnecessary). On iOS, SpriteKit
   textures count toward the app's memory footprint (unified memory), so the 64 MB limit applies to them
   in full.
5. **Budgets** (proposed for the low-end Android target; iOS is held to the same so the apps match):
   | Budget | Limit |
   |---|---|
   | Largest texture / atlas | 2048 × 2048 |
   | Decoded textures alive **at any moment**, prefetch included | ≤ 64 MB |
   | of which resident (hero, enemies, UI) | ≤ 32 MB (two 2048² atlases' worth) |
   | of which current + next beat (backgrounds + props) | ≤ 32 MB |
   | One mission's art + data, compressed | ≤ 15 MB |
   | App download (font + art + 2 languages of voice, later) | ≤ 60 MB |
6. **Minimum iOS version: iOS 17.** That's the project's current deployment target (TASK-006). It's
   listed here because it decides which children's devices can install the game. Apple's own App Store
   figures for June 7, 2026: 79% of active iPhones on iOS 26, 14% on iOS 18 and **7% on earlier
   versions**. iOS 17 therefore excludes **at most 7%** of active iPhones (the share below iOS 17 alone
   is NOT SOURCEABLE from that data; the 7% includes iOS 17 itself). iPads aren't covered by those
   figures. Lowering the target is possible: nothing in the slice needs iOS 17 specifically
   (SpriteKit, SwiftUI's `SpriteView` and WebP decoding all predate it). Luan decides; the default is
   iOS 17.
7. **Not decided here:** the final art style and its lock (D-18), voice-over sizes, a tablet 2× set,
   any download or streaming (offline only, ADR-0001).

### Follow-up (after acceptance, separate data branch, agreed with game-art-content)
- `assets.json` gains `width` and `height` per picture (schema **1.2**, a MINOR bump).
- New rule **R19**: every picture is ≤ 2048 on both sides, and within its kind's expected 1.5× size.
  It starts as a warning, and becomes an error once the measurements confirm the budgets.

### Architecture Diagram

```
 artist (2× source) ──export──▶ 1.5× files, ≤2048² each ──▶ content/data/pictures/…  (+ assets.json)
                                   │  WebP lossless (sprites) / lossy (backgrounds) / PNG ok
                                   ▼
            iOS: UIImage(ImageIO) → SKTexture        Android: BitmapFactory → hardware Canvas
            load per mission, release on leaving      load per mission, release on leaving
            budget: ≤ 64 MB decoded per mission       (RGB_565 for opaque backgrounds)
```

### Key Interfaces
- `content/data/assets.json`: id → file, bytes (now); + width, height (schema 1.2).
- An atlas is a set of picture ids that one mission loads together; the apps load by id, never by
  hard-coded path.

### Implementation Guidelines
- **Must** never bundle an image larger than 2048 on either side.
- **Must** load a mission's atlases at mission start and release them when the mission ends.
- **Must** read every picture through `assets.json` ids; **must never** hard-code file paths in code.
- **Must never** put text inside a picture (art bible; ADR-0001).
- **Should** prefer WebP; PNG only when WebP is not available from the art tool.

## Alternatives Considered

### Alternative 1: Ship 2× only
- **Pros**: sharpest everywhere, including tablets.
- **Cons**: ~1.78× the memory and size of 1.5×; a 4096² sheet at 2× breaks the 2048 limit.
- **Rejection Reason**: phones are the target, and 1.5× covers their k ≈ 1.3–1.5.

### Alternative 2: Density buckets (1×/2×/3× asset catalogs and Android drawables)
- **Pros**: each device gets "its" size.
- **Cons**: the world scale, not density, decides sharpness; two platform-specific pipelines; more files.
- **Rejection Reason**: doesn't fit a scaled fixed world, and breaks one-file-set parity.

### Alternative 3: 4096² atlases
- **Pros**: fewer draw batches.
- **Cons**: 64 MB per sheet decoded; fails on GPUs limited to 2048.
- **Rejection Reason**: memory and compatibility risk on low-end phones.

### Alternative 4: PNG only
- **Pros**: simplest; universal tools.
- **Cons**: much larger than WebP for painted art; pushes the download budget.
- **Rejection Reason**: WebP is decoded by both apps; PNG stays as a fallback.

## Consequences

### Positive
- One set of files for both apps, sized for phones.
- No device hits a texture-size failure; memory per mission is bounded.
- Artists know the export rule before final art starts.

### Negative
- Large sheets must be split by animation set (more atlases, a little more loading code).
- Tablets look slightly soft until a 2× set exists.
- Two downsampling steps (author 2× → ship 1.5×) need an export script (a tools task).

## Risks
- **The budgets are estimates.** Mitigation: measure on both apps before acceptance (below).
- **Specs written at 4096².** Mitigation: the export rule splits them; asset specs get a note (game-art-content).
- **iOS 17 excludes a few devices.** Mitigation: the figure is in front of Luan; the target can go lower.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| game-concept.md | Android + iOS phones, performance on a low-end Android phone | 2048 cap, per-mission memory budget, one 1.5× set |
| game-concept.md | Pillar 5: offline; content in timed app updates | Download budget; everything bundled |
| art bible §3, §7 | No text in art; banner words as a text layer | Restated as a must-never |
| mission-flow.md / side-scroll-combat.md | Animated sprites for every state | Atlases by on-screen set, split by animation |

## Performance Implications
- **CPU**: decode at mission start (WebP decode is slower than PNG; measured below).
- **Memory**: ≤ 64 MB decoded textures per mission.
- **Load Time**: target ≤ 1 s mission load on the low-end phone (to measure).
- **Network**: none.

## Migration Plan
The slice's placeholder art is drawn in code, so nothing to migrate. Final art follows this ADR from its
first export; `assets.json` gets width/height in the follow-up data branch.

## Validation Criteria
To be filled before acceptance (the leader logs this ADR as D-19):
- [x] Android decode memory (game-dev-android, AVD devandroid002 API 36 arm64, debug AtlasBenchActivity @ 2852a4e):
  2048² atlas = 16.0 MB decoded; a 1440×1620 tile = 8.9 MB (RGB_565: 4.45 MB, WebP only);
  `Bitmap.Config.HARDWARE` heap +0.005 MB (GPU memory only).
- [x] Android decode time (ARGB / HARDWARE, Apple-silicon host CPU; expect 3–5× slower on a low-end phone):
  atlas: WebP lossless 33 / 67 ms, WebP q85 28 / 35 ms, PNG 21 / 29 ms; tile: WebP lossless 13 / 19 ms, q85 6 / 11 ms, PNG 14 / 16 ms.
  File sizes on synthetic art (ratios only): atlas 981 KB lossless WebP / 318 KB q85 / 791 KB PNG; tile 173 / 36 / 160 KB.
- [ ] Android frame time: **NOT ASSESSED**. The AVD renders through SwiftShader (a software GPU), so its p50 33 ms / p95 50 ms is not a valid number. It needs a real low-end phone.
- [ ] iOS memory (game-dev-ios): decoded texture memory for a 2048² atlas and a 1440×1620 tile, WebP and PNG, with Instruments on the iPhone Duo Simulator after iOS QC round 1 frees the device. Memory numbers are valid on the Simulator.
- [ ] iOS frame time: **needs a real iPhone**. Simulator frame times run on the host Mac's GPU and CPU and aren't device numbers, so the Simulator can't close this box.
- [ ] At every beat of the TQT mission, resident + current + next-beat textures add up to ≤ 64 MB decoded (a spreadsheet from the asset manifest at 1.5×, using each atlas's real fill, not 2048² each).

## Related
- ADR-0001 (depends on). TASK-013 (full-screen backdrop uses the background tiling rule). TASK-014 asset specs.
- Source for the iOS share: Apple's App Store figures for June 7, 2026, as reported by
  [iClarified](https://www.iclarified.com/101140/ios-26-adoption-reaches-86-on-recent-iphones-79-overall-chart) and
  [9to5Mac](https://9to5mac.com/2026/02/13/apple-announces-ios-26-usage-numbers-heres-how-they-compare/) (the February figures).
