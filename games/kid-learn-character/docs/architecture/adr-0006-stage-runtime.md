# ADR-0006: Stage runtime (SpriteKit composition, frame driver, stage fit, windows)

## Status

Accepted (Luan, 2026-11-18; recorded by game-leader on Luan's explicit acceptance)

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**

## Date

2026-11-18

## Last Verified

2026-11-18, against ADR-0001 (Decision 9a, the swappable stage protocol), ADR-0002 (D3, D6, Risks; amended by K-34),
Reveal Stage (R10, F1), Cast Rendering, Scene, App Shell & Title (R7), Child Lock-in (R5), decisions K-20, K-28,
K-30, K-34, and Apple documentation read 2026-11-18 (URLs below).

## Decision Makers

Luan (accepts; K-34); game-dev-ios (author, TASK-070); game-dev-android (plan and independent review); game-leader.

## Summary

KidCore produces a render plan per frame, but nothing yet says how it reaches the screen on Apple, how frames are
driven, how the stage fits any window, or how pixel density is known. This ADR fixes one SpriteKit `SKView` per
window behind `RenderSink` with fixed layers in Reveal Stage R10's order and the gate and panel as in-window SwiftUI
overlays, the display-link frame driver into `tick(now:)` at up to 60 fps, stage fit from `DisplayMetrics`, the window
rules (any iPad scene size; the kiosk's full-screen mode left to ADR-0008), Smart Invert, Reduce Motion, and the ppi
rule.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | None from the template's table (ADR-0001, K-28). Swift 6.4, Xcode 27.1, SDKs iOS 27.1 / macOS 27.0, deployment 26 |
| **Domain** | Rendering |
| **Layer** | Presentation |
| **Knowledge Risk** | HIGH for device rendering cost (ADR-0009); MEDIUM for the window and accessibility APIs (SOURCED below, not yet built here) |
| **References Consulted** | `docs/engine-reference-local/native-apple/` (`VERSION.md`, `breaking-changes.md`, `current-best-practices.md` Frames and time, `modules/spritekit.md`, `modules/appkit-kiosk.md`); the Apple pages listed in Sources |
| **Post-Cutoff APIs Used** | `CADisplayLink.preferredFrameRateRange`, `NSView.displayLink` (PROVEN, TASK-033), `UIView.accessibilityIgnoresInvertColors`, `CGDisplayScreenSize`, `UIAccessibility.isReduceMotionEnabled`, `NSWorkspace.accessibilityDisplayShouldReduceMotion` on the 27 SDKs: to be proven by the scaffold and stage stories |
| **Verification Required** | Validation Criteria 1–7 |

### Sources (Apple developer documentation, read 2026-11-18)
- `UIRequiresFullScreen`: deprecated in iOS / iPadOS 26.0. "In iPadOS 26 and later on an iPad that supports the
  Windowed Apps multitasking mode … the system … doesn't present your app's scene full screen … Scales your app's
  presentation when the user resizes it, rather than changing the size of your app's scene."
  https://developer.apple.com/documentation/bundleresources/information-property-list/uirequiresfullscreen
- `accessibilityIgnoresInvertColors`: "Setting the property to true prevents the system from inverting the colors of
  the view and all of its subviews." https://developer.apple.com/documentation/uikit/uiview/accessibilityignoresinvertcolors
- `CGDisplayScreenSize(_:)`: "Returns the width and height of a display in millimeters … or 0 if the display is not
  valid. If Extended Display Identification Data (EDID) for the display device is not available, the size is
  estimated … with an assumed resolution of 2.835 pixels/mm or 72 dpi."
  https://developer.apple.com/documentation/coregraphics/cgdisplayscreensize(_:)
- `CADisplayLink.preferredFrameRateRange`: "a best attempt"; "Low Power Mode, critical thermal state, and
  accessibility settings can affect the system's frame rate."
  https://developer.apple.com/documentation/quartzcore/cadisplaylink/preferredframeraterange
- `UIScreen.nativeScale`: "The native scale factor for the physical screen" (px per pt, not ppi).
  https://developer.apple.com/documentation/uikit/uiscreen/nativescale
- `UIAccessibility.isReduceMotionEnabled`: "whether the Reduce Motion setting is in an enabled state."
  https://developer.apple.com/documentation/uikit/uiaccessibility/isreducemotionenabled
- `NSWorkspace.accessibilityDisplayShouldReduceMotion`: "whether the accessibility option to reduce motion is in an
  enabled state." https://developer.apple.com/documentation/appkit/nsworkspace/accessibilitydisplayshouldreducemotion

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Accepted); ADR-0002 (Accepted: D3, D6) |
| **Enables** | ADR-0008 (kiosk: the full-screen mode, within D4's constraints); ADR-0009 (render path, measured on this runtime); the stage stories (Reveal Stage, Scene, Cast Rendering drawing) |
| **Blocks** | The first stage story after the scaffold |
| **Ordering Note** | The last ADR in architecture.md's order that needs no device; the ★ spikes follow |

## Context

### Problem Statement
Reveal Stage R10 fixed the draw order and the contain-and-extend fit; ADR-0002 fixed `RenderSink`,
`DisplayMetrics` and `tick(now:)`. What remains is the Apple runtime: the view, the layers, the frame source, the
window behaviour, two accessibility settings and pixel density, which ADR-0002's Risks left NOT SOURCEABLE.

### Constraints
- The gate challenge and the panel never open another window (App Shell R7, Child Lock-in R5).
- No third-party renderer (PKC-03); SpriteKit per ADR-0001.
- iPadOS 26 cannot be held full screen (Sources).
- Device rendering cost is unmeasured (ADR-0009).

### Requirements
- The layers in R10's order on every frame; the whole safe stage visible in any window shape.
- One frame entry on the uptime clock; no rule depends on the frame rate.
- Physical touch targets never smaller than designed.

## Decision

### D1. Composition
- **One `SKView` per window**, wrapped for SwiftUI (`UIViewRepresentable` / `NSViewRepresentable`), implementing
  `RenderSink` (ADR-0002 D6). Not SwiftUI's `SpriteView`, so the view's accessibility and display-link settings stay
  under our control.
- **One stage root node** with fixed layer children and fixed `zPosition`, in Reveal Stage R10's order:

  | z | Layer | Owner of its content |
  |---|---|---|
  | 0 | Scene backdrop: sky, hills, ground, weather | Scene |
  | 10 | parade walkers | Parade |
  | 20 | leaving creature | Reveal Stage / Cast Rendering |
  | 30 | current creature | Reveal Stage / Cast Rendering |
  | 35 | On-screen Keyboard Row (when on) | On-screen Keyboard Row |
  | 40 | glyph or specks | Reveal Stage / Cast Rendering |
  | 50 | starlights and sparkles | Reveal Stage |
  | 60 | hint letters | Hint Letters |
  | 70 | queue tokens | Reveal Stage (Press Queue snapshot) |
  | 80 | the moon | Parent Gate |

- **The On-screen Keyboard Row** sits at z 35: above the current creature, below the rising glyph and the
  starlight or sparkle that answers a row press (40, 50), with hints (60) and tokens (70) above it. Row touches stay
  at Input's layer 2. Under `row_lift` the creature cannot overlap the row (anchor y 490; the row starts at y 582).
  **Reveal Stage R10's draw-order line needs the same entry** (a GDD follow-up routed by the leader; not edited here).
- **The gate challenge and the grown-up panel** (with its 55% dim) are **SwiftUI overlays above the `SKView` in the
  same window**: never a separate window, sheet or popover (App Shell R7, Child Lock-in R5).
- The adapter only maps the render plan onto nodes; no rule lives in the scene.

### D2. Stage fit
- The scene's `scaleMode` is `.resizeFill`, sized to the view in points. The stage root node carries KidCore's
  Reveal Stage F1 transform: scale `s_fit`, the centring offset, and the **y-axis flip** (KidCore is y-down,
  SpriteKit y-up).
- **Touches:** the adapter converts each touch's view point to window pixels with the same `pxPerPt` it publishes
  (`nativeScale` on iPad, `backingScaleFactor` on the Mac) and emits `TouchEvent` in px (ADR-0002 D5). It applies no
  stage transform itself; KidCore applies F1.
- `DisplayMetrics` (ADR-0002 D6) from the window and screen: `windowPx` = bounds × `nativeScale` (iPad) or
  `backingScaleFactor` (Mac); `pxPerPt`; safe-area insets in px; live gesture insets; `ppiX/ppiY` per D7.
- Any resize, rotation, Split View / Stage Manager / Windowed Apps change, or Mac window or screen change emits
  `displayMetricsChanged` and `screenChanged`. KidCore recomputes F1 and the published rects; the reveal in progress is
  not restarted (Reveal Stage edge case).

### D3. The frame driver
- iPad `CADisplayLink`; Mac `NSView.displayLink` (PROVEN, TASK-033). Each callback calls **`tick(now:
  targetTimestamp)`** on the uptime clock (ADR-0002 D3, D6): the only per-frame entry.
- **`preferredFrameRateRange`: min 30, max 60, preferred 60** (proposal, accepted by the leader): one rate on
  ProMotion and 60 Hz screens, calm and battery-friendly, within the 16.7 ms p99 budget. The system may still lower
  it (Sources). 120 Hz is measured in ADR-0009.
- **A dropped or late frame:** the next tick gets the next `targetTimestamp`; `s` jumps; anything due fires once on
  that frame (Reveal Stage edge case). No catch-up loop, no fixed-step simulation: every rule is time-based. A gap over
  0.25 s (a debugger, a hitch) is just a bigger jump; the play clock is unaffected unless frozen.

### D4. Windows
- **iPad:** every scene size is supported; `UIRequiresFullScreen` is **not** set (deprecated in 26.0 and not honoured
  as full screen under Windowed Apps, Sources). This confirms App Shell R7. Landscape first; any shape works through D2.
  - *Note 2026-11-18 (K-39, K-42, TASK-115; TR-shell-004; status unchanged, Accepted):* **the iPad's system overlays
    follow App Shell R7's two outputs**, on the root SwiftUI view of the one window (D1):
    - **Status bar: hidden throughout**, Title, Play, the gate challenge and the grown-up panel alike
      (`statusBarHidden {true}`, emitted once), so the safe area and the stage fit (D2) never move when an overlay
      opens or closes. iPadOS 27: `.toolbarVisibility(.hidden, for: .statusBar)` (the `.statusBar` placement is
      iOS 27+); iPadOS 26: `.statusBarHidden(true)`, which the 27.1 SDK marks for future deprecation in favour of the
      former. One `#available` branch, as in ADR-0010. Both set the hosting controller's `prefersStatusBarHidden`.
    - **Home indicator auto-hidden and system edge gestures deferred on every edge, in the Title and Play only**,
      both following `edgeDeferral` (on in the Title and Play, off while the Parent Gate's `gateOverlayShown` is true):
      `.persistentSystemOverlays(edgeDeferral ? .hidden : .automatic)` and
      `.defersSystemGestures(on: edgeDeferral ? .all : [])` (iOS 16+), which set the hosting controller's
      `prefersHomeIndicatorAutoHidden` and `preferredScreenEdgesDeferringSystemGestures`. In the gate and the panel
      neither applies, so a grown-up sees the indicator and one swipe acts at once (App Shell AC-14).
    - **If the root is ever a UIKit controller** instead (for example a hosting subclass), it overrides the three
      properties, forwards them from a child through `childViewControllerFor…` where the view is a child, and calls
      `setNeedsStatusBarAppearanceUpdate()`, `setNeedsUpdateOfHomeIndicatorAutoHidden()` and
      `setNeedsUpdateOfScreenEdgesDeferringSystemGestures()` on every `edgeDeferral` change (UIKit header, Sources).
    - **A speed bump, not a lock:** Guided Access stays the real lock (Child Lock-in, ADR-0008). Auto-hidden is the
      system's call, not a guarantee, and deferral only asks for a second swipe; how each behaves on a device, and in a
      window that is not full screen, is **not sourced** here and is what AC-14 measures (Simulator screenshots; the
      swipes on a device). The Mac has neither output and nothing here applies to it.
- **Mac, kiosk off:** one resizable window, minimum 960 × 540 pt (App Shell R7), native full screen allowed
  (`collectionBehavior` `.fullScreenPrimary`).
- **Mac, kiosk on:** native full screen (options through `window(_:willUseFullScreenPresentationOptions:)`) or a
  borderless window at the screen frame is **decided in ADR-0008**, after its MAC FREE device checks. Either must keep:
  one window; the overlays inside it (D1); `windowCoversDisplay` reported to `KioskEffects` (ADR-0002 D6).

### D5. Smart Invert (K-30)
On iPad the `SKView` sets `accessibilityIgnoresInvertColors = true`; the SwiftUI panel overlay does not, so the panel
follows Smart Invert. On the Mac, Invert is OS-wide and no per-view opt-out is claimed (K-30).

### D6. Reduce Motion
`AccessibilityState.reduceMotion` (ADR-0002 D6) is read live: iPad `UIAccessibility.isReduceMotionEnabled` and its
change notification; Mac `NSWorkspace.accessibilityDisplayShouldReduceMotion` (Sources). Each change emits
`accessibilityChanged`; KidCore applies it at the next reveal (Reveal Stage R9, Cast Rendering).

### D7. Pixel density (`DisplayMetrics.ppiX/Y`)
- **iPad:** there is no public ppi API (`nativeScale` is px per pt). A **bundled table keyed by the hardware model
  identifier** (`utsname.machine`; on the Simulator the `SIMULATOR_MODEL_IDENTIFIER` environment value). Each row cites
  Apple's tech-specs page for that model.
- **Mac:** computed from `CGDisplayScreenSize` (mm) and the display's pixel size. A size of 0, or one that implies the
  72 dpi no-EDID estimate (Sources), counts as **unknown**.
- **Unknown, on either platform: assume the HIGHEST ppi in that device class**, so physical targets come out larger,
  never smaller (a target of M mm is drawn as `M × ppi_assumed / 25.4` px, so its physical size is
  `M × ppi_assumed / ppi_real`), and write one `DebugLog` line naming the model or display. This corrects ADR-0002's
  Risks line (K-34; amendment note in ADR-0002).
- Reading the model identifier is not a required-reason API and is not an identifier under PKC-05 (it names a product
  model, not a device or person).

### D8. Measured later (ADR-0009), not decided here
Device frame time p50 / p99 with the full stage, node counts per layer, 60 vs 120 Hz power, and texture memory.

### Architecture Diagram
```
KidCore ──render plan──▶ RenderSink (SKView adapter) ──▶ stage root (F1 transform, y flip)
   ▲                                                        ├─ z0 Scene … z35 Keyboard Row … z80 moon (D1)
   │ tick(now: targetTimestamp)
display link (CADisplayLink / NSView.displayLink, ≤ 60 fps)
SwiftUI window: [ SKView ] + overlays (gate challenge, panel) — one window
```

### Key Interfaces
`RenderSink`, `DisplayMetrics`, `AccessibilityState`, `tick(now:)` (ADR-0002 D6) with the Apple implementations of
D1–D7.

### Implementation Guidelines
- The stage **must** be one `SKView` per window with D1's fixed layers and `zPosition`s.
- The gate and panel **must** be overlays in the main window; they **must never** be a separate window, sheet or
  popover.
- The display link **must** call `tick(now:)` with `targetTimestamp`; nothing else may drive KidCore per frame.
- Code **must never** catch up dropped frames or assume a frame rate.
- `UIRequiresFullScreen` **must not** be set.
- The iPad `SKView` **must** set `accessibilityIgnoresInvertColors = true`; the panel **must not**.
- An unknown ppi **must** take the class maximum, with one `DebugLog` line.

## Alternatives Considered

### Alternative 1: SwiftUI `SpriteView`
- **Description**: SwiftUI's built-in SpriteKit view.
- **Pros**: less wrapper code.
- **Cons**: less control over the view's accessibility property and the display-link frame source.
- **Rejection Reason**: D5 and D3 need that control.

### Alternative 2: Fixed-step simulation with catch-up
- **Description**: advance rules in 1/60 s steps, running extra steps after a hitch.
- **Pros**: classic game-loop determinism.
- **Cons**: every KidCore rule is already time-based and tested with injected clocks; catch-up bursts would replay
  sounds and starlights.
- **Rejection Reason**: unnecessary and harmful here.

### Alternative 3: Separate window or sheet for the panel
- **Description**: present the grown-up panel as a sheet or its own window.
- **Pros**: standard platform UI.
- **Cons**: the main window resigns key; on the Mac that drops the kiosk (Child Lock-in R5).
- **Rejection Reason**: D1.

## Consequences

### Positive
- One frame entry and fixed layers make the stage simple to test and swap (ADR-0001 9a).
- Any window shape works; the claim about iPad full screen is now sourced.

### Negative
- An iPad ppi table must be kept up to date; a new model takes the conservative maximum until added.
- The 60 fps cap leaves ProMotion's 120 Hz unused until ADR-0009 measures it.

### Neutral
- The kiosk's full-screen mode is deferred to ADR-0008.

## Risks
- **A new iPad model is missing from the table.** Mitigation: D7's class maximum plus a log line; add the row with its
  Apple tech-specs citation.
- **A Mac display without EDID.** Mitigation: D7 treats the 72 dpi estimate as unknown.
- **The system lowers the frame rate** (Low Power Mode, thermal). Mitigation: time-based rules (D3).
- **SpriteKit cost of layered art on a device.** Owned by ADR-0009.

## GDD Requirements Addressed

TR-IDs are provisional (architecture.md's baseline).

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| reveal-stage.md R10, F1 | TR-reveal-003: contain-and-extend fit; draw order | D1 layers; D2 transform and resize |
| app-shell-title.md R7 | windows on iPad and Mac; overlays in the main window | D4; D1 overlays |
| app-shell-title.md R7 (K-39), AC-14 | TR-shell-004: iPad status bar hidden; home indicator and edge deferral follow `edgeDeferral` | D4 note 2026-11-18 (TASK-115) |
| child-lock-in.md R5 | never resign key for the gate or panel | D1 overlays; D4 constraints for ADR-0008 |
| hint-letters.md F5, R11; parent-gate-panel.md (moon slop) | physical target sizes | D7 ppi rule |
| accessibility (K-30); reveal-stage.md R9 | Smart Invert opt-out; Reduce Motion | D5; D6 |
| cast-rendering.md R11 | the measurement plan's runtime | D8 hand-off to ADR-0009 |

## Performance Implications
- **CPU / GPU**: unmeasured on a device (ADR-0009). Capped at 60 fps.
- **Memory**: one `SKView`; texture memory per Cast Rendering F6 (ADR-0009).
- **Load Time**: none beyond the view's creation.
- **Network**: none.

## Migration Plan
None: no stage code exists. The TASK-033 spike's scene is a reference, not migrated.

## Validation Criteria
Per K-34: headless `swift test` and `xcodebuild` (build and test without a visible Simulator window) need no MAC FREE;
**anything with a visible Simulator window or on the Mac screen needs MAC FREE**. Simulator runs use the dev simulator,
never QC's E9F515E9….

1. **Stage fit (Simulator window, MAC FREE):** screenshots on the 11" and 13" iPad simulators and a Split View /
   Windowed Apps size; the safe stage is whole, no bars, and F1's scale and visible rect match the logged values.
2. **Layer order (headless):** a render plan with one node per layer yields D1's `zPosition` order (a node-tree
   snapshot test).
3. **Frame driver (headless):** a test display-link source with skipped `targetTimestamp`s: due events fire once, no
   catch-up, `tick` receives uptime values.
4. **Smart Invert (headless):** the iPad `SKView` reports `accessibilityIgnoresInvertColors == true`; the panel overlay
   `false`.
5. **Reduce Motion (Simulator window, MAC FREE):** toggling it emits `accessibilityChanged`; the next reveal uses the
   reduced set.
6. **ppi (headless, plus the Mac screen under MAC FREE):** a known model's row; an unknown model takes the class
   maximum with one log line; the Mac `CGDisplayScreenSize` path, including a 72 dpi result treated as unknown.
7. **Mac window (MAC FREE):** resize to the minimum, then native full screen with the kiosk off; the safe stage stays
   whole.

## Related
- ADR-0001 (9a, stage protocol); ADR-0002 (D3, D6; Risks amended per K-34); ADR-0008; ADR-0009.
- Reveal Stage, Cast Rendering, Scene, App Shell & Title, Child Lock-in GDDs.
- iOS 27.1 SDK interfaces, read 2026-11-18 (TASK-115): `UIKit.framework/Headers/UIViewController.h`
  (`prefersStatusBarHidden`, "Defaults to NO", deprecated only on visionOS; `preferredScreenEdgesDeferringSystemGestures`,
  "Default is UIRectEdgeNone", with `childViewControllerForScreenEdgesDeferringSystemGestures` and
  `setNeedsUpdateOfScreenEdgesDeferringSystemGestures`; `prefersHomeIndicatorAutoHidden`, "the application's preferred
  home indicator auto-hiding", with `childViewControllerForHomeIndicatorAutoHidden` and
  `setNeedsUpdateOfHomeIndicatorAutoHidden`; all iOS 11+) and `SwiftUI.swiftmodule/arm64e-apple-ios.swiftinterface`
  (`statusBarHidden(_:)`: iOS 13, `deprecated: 100000.0`, "Use .toolbarVisibility(_, for: .statusBar) instead";
  `ToolbarPlacement.statusBar`: iOS 27.0; `toolbarVisibility(_:for:)`: iOS 18; `persistentSystemOverlays(_:)` on a
  View: iOS 16; `defersSystemGestures(on:)`: iOS 16). The developer.apple.com pages render client-side and could not
  be read as text.
- `docs/engine-reference-local/native-apple/` (updated with the Sources above); `docs/registry/architecture.yaml`
  (`stage_view`).
