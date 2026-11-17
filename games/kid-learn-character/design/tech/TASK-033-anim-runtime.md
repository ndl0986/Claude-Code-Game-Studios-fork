# TASK-033: 2D animation runtime for the letter morph (spike report)

**Author:** game-dev-ios · **Date:** 2026-11-17 · **Branch:** `spike/TASK-033-anim-runtime`
**Prototype:** `prototypes/TASK-033-anim-runtime/` (throwaway) · **Evidence:** `production/qa/evidence/TASK-033/`
**Question (Luan):** can a graphics/UI engine be combined with native Swift now and native Android later, and
what should draw the letter → object morph?

## Recommendation

**Use SpriteKit only for the morph, driven by a pure-Swift morph core (`MorphCore`) whose numbers a Kotlin port
must reproduce from a shared fixture.**
- Don't adopt Rive for the morph, and don't embed an engine as a library.
- Rive stays an option only for hand-animated extras later, under the dependency rules in "Rive: the loadCdn
  finding" below.
- Add a child lock-in layer (key filter on both platforms; kiosk mode on macOS; Guided Access guidance for iPad
  parents).

Why:
1. **The morph is procedural, and only the native core does that with no per-key authoring.**
   - MorphCore turns any glyph outline and any object silhouette into the stardust morph from data. Adding a key
     is a JSON row plus the object's outline.
   - Rive's docs make no claim that a runtime can morph an arbitrary glyph into an arbitrary silhouette. A stock
     .riv measures runtime cost only, so 36 morphs would mean 36 authored animations, or an unverified path-effect
     script.
2. **Both runtimes are fast enough, so speed doesn't separate them.**
   - On the simulator and the Mac, press → first frame is about 10–17 ms for both (a lower bound).
   - Both survive a 60 s mash at 10 presses/s with one morph, one voice and flat memory.
3. **Rive costs about 5.5 MB installed (≈ 2.2 MB compressed) per iOS app and adds a network path we have to
   police.** The SpriteKit-only app is 0.5 MB.
4. **An engine as a library doesn't fit this game.**
   - Unity as a Library has no macOS target, renders full-screen only and is on Apple's privacy-manifest list.
     Unity doesn't document that a player with diagnostics and Analytics off sends nothing.
   - LibGodot embedding on iOS/Android isn't in a stable release.
5. **Android reuse comes from the shared core contract, not from a shared runtime.**
   - The recipe is about 150 lines of plain arithmetic, SVG paths and a specified RNG.
   - `fixtures/morph-D-dinosaur.json` pins its output.
   - Android draws the same particles with Canvas or Compose (desk estimate below).

## Comparison

All measured numbers come from Release builds of the spike.
- **iPad Simulator:** iPad (A16), iOS 27.0, a 60 Hz display, on an M4 Pro Mac. Indicative only.
- **Mac:** MacBook Pro M4 Pro, macOS 27.2.1, the Spike window on a 75 Hz display.
- **Child's iPad: NOT ASSESSED** until `evidence/TASK-033/procedure-ipad.md` is run.

| | (a) SpriteKit + MorphCore | (b) Rive (RiveRuntime 6.30.1, stock `mascot.riv`) |
|---|---|---|
| **Press → first frame drawn**, median / p95, warm (cold) | Sim **11.3 / 17.6 ms** (12.7 / 14.3), n = 27 (3). Mac **12.3 / 21.2 ms** (15.2 / 16.4), n = 13 (3) | Sim **9.3 / 12.4 ms** (11.4 / 12.6), n = 27 (3). Mac **16.9 / 22.3 ms** (14.8 / 18.8), n = 14 (3) |
| **Press → estimated presentation**, median warm | Sim 26.9 ms · Mac 14.5 ms | Sim 23.6 ms · Mac 23.0 ms |
| **Press → estimated first audible sample**, median warm | Sim 8.4 ms · Mac 18.4 ms | Sim 9.0 ms · Mac 19.2 ms |
| **Frame time** p50 / p99 (latency run) | Sim 16.67 / 17.07 ms · Mac 13.34 / 26.73 ms | Sim 16.67 / 17.36 ms · Mac 13.34 / 15.43 ms (a max of ≈ 2 s is Rive pausing its draw loop while idle, not a hitch) |
| **Mash** 60 s at 10 presses/s | 599 presses: 1 started, 14 queued (max 3), 584 dropped. At most 1 active morph, 1 voice. Memory flat: Sim 23.4 → 26.8 MB, Mac 167.0 → 167.0 MB. Frame p99 Sim 16.92, Mac 26.73 ms | Same queue result, max 1 morph, 1 voice. Memory Sim 26.1 → 25.6 MB, Mac 150.3 → 150.1 MB. Frame p99 Sim 17.35, Mac 15.43 ms |
| **Authoring effort for 36 morphs** | **One shared effect.** Per key: the object's outline as an SVG path (exported from the art) plus a JSON row; glyphs are baked by a tool. Engineering per key ≈ 0 | Per key: one authored glyph → object animation in the Rive editor (≈ 36 animations; our desk estimate is 1–3 h each for a simple shape morph, not measured). A generic morph would need a Luau path-effect script, compiled and signed by Rive's servers: feasibility not verified |
| **App-size delta**, iOS arm64 Release (approximation of a thinned build) | SpikeNoRive.app **540 KB** (199 KB zipped) | Spike.app **6,152 KB** (2,443 KB zipped): **RiveRuntime.framework adds 5,528 KB** |
| **Licence / cost** | Apple SDK; Fredoka font OFL 1.1 (bake tool only) | Runtime MIT, free. The editor's free plan exports **with a Rive splash screen**; no splash needs Cadet, $17/seat/month |
| **Android reuse** | Same recipe plus the shared fixture (Kotlin must match to 1e-3); same JSON, SVG paths and baked glyphs; new drawing code | The same .riv plays on rive-android, with per-feature gaps. Latest release 11.16.3, per Maven Central's `app/rive/rive-android/maven-metadata.xml` (`<release>11.16.3</release>`, lastUpdated 2026-11-11; repo1.maven.org/maven2/app/rive/rive-android/maven-metadata.xml). MIT, minSdk 21 (README "Supported Versions"). The rive-android README doesn't name a renderer; Rive's docs say the Rive Renderer is the default (rive.app/docs/runtimes/choose-a-renderer). Size per ABI not verified |
| **Offline / Kids / COPPA** | No network code; nothing collected | Runtime ships a PrivacyInfo.xcprivacy that collects nothing. Its legacy API **fetches CDN-hosted assets at play time by default** (below). Not on Apple's commonly-used-SDK list |

**How the numbers were measured** (`Spike/Metrics.swift`):
- **Start:** the event's own timestamp (`UITouch`/`UIPress.timestamp`, `NSEvent.timestamp`; synthetic presses use
  `CACurrentMediaTime()`, the same clock).
- **First frame:** the renderer's callback for the first frame after the press: SpriteKit `didFinishUpdate`, Rive
  `drawRive` in a `RiveView` subclass. This is when the frame is **encoded**, a **lower bound**: SKView doesn't
  expose drawables or present times.
- **Presentation estimate:** the next display-link `targetTimestamp` after that frame.
- **Sound estimate:** the time the buffer was scheduled, plus `ioBufferDuration` and `outputLatency` (iPad), or the
  output node's `presentationLatency` plus its maximum frames per render (Mac).
- **Cold:** the first press after launch and the first press of each key. **Warm:** every other press.
- On the Mac about half the latency presses arrived while a reveal was still running, so they were queued and
  not counted (hence n = 13–14).
- Real touch and keyboard delivery to the app is in none of these numbers; the iPad camera procedure measures it.

**Void runs (discarded, kept outside the evidence):**
- The first Mac batch launched the app in the background (App Nap throttled timers and frames).
- The second ran while the Mac's screen was locked (0 frames drawn).
- The valid batch ran with the app in front, under `beginActivity(.latencyCritical)`.

**Audio note for the audio ADR:** `AVAudioPlayerNode.stop()` + `scheduleBuffer` + `play()` on the main thread took
3–10 ms before the sound was scheduled. The production audio path should keep players primed and cut with a short
fade off the main thread.

## Rive: the `loadCdn` finding and how we enforce it

**Finding, tested with the sandboxed macOS build, Release, no `com.apple.security.network.client`:**
- **Rive's own `hosted_assets.riv` with `loadCdn: true`:** the runtime requested
  `https://public.uat.rive.app/cdn/uuid/…` **as soon as the file loaded**. The in-app `URLProtocol` probe saw
  2 requests; the sandbox denied DNS (`Operation not permitted`), giving `NSURLErrorDomain -1003`.
- **The same file with `loadCdn: false`, the stock file and SpriteKit:** 0 requests, 0 sockets (`lsof`).

Evidence: `evidence/TASK-033/network/` (stderr with `OS_ACTIVITY_DT_MODE`, `[net]` probe lines, `lsof` samples,
entitlements).

The legacy Apple API (`RiveFile`, `RiveModel`, `RiveViewModel`) defaults **`loadCdn` to `true`**
(`RiveModel.swift` and `RiveViewModel.swift` in rive-ios 6.30.1). Rive's own security page says the same: the
legacy runtime downloads Hosted assets unless `loadCdn: false`; the new Apple runtime doesn't download them by
default.

**Static check:** the RiveRuntime binary's only network paths are `CDNFileAssetLoader`
(`https://public.rive.app/cdn/uuid`) and the `initWithHttpUrl:` loaders (`NSURLSession`). There are no analytics
strings. (`network/static-rive-binary.txt`)

**Enforcement, if Rive is ever added:**
1. Pass `loadCdn: false` on every legacy load. Load files only from bundled `Data` or a resource, never
   `webURL`/`httpUrl` or `.url(...)`; a code review rule plus a grep in CI.
2. Every `.riv` is exported with **Embedded** or **Referenced** assets, never Hosted. A unit test loads each
   bundled .riv under a `URLProtocol` that fails the test on any request.
3. The app has no network entitlement on macOS (sandbox denies it) and no network code on iOS. The Kids-category
   review then rests on "no network", which the probe test keeps true.

## Engine as a library (desk research, official sources, 2026-11-17)

**Unity as a Library:**
- Supported on Android, iOS and Windows/UWP. **macOS isn't supported**, so it can't cover ADR-0001's iPad + Mac
  target.
- Limits: one Unity runtime per process, **full-screen rendering only**, 80–180 MB kept after unload, no reload
  after Quit on iOS. (docs.unity3d.com/6000.0/Documentation/Manual/UnityasaLibrary.html)
- Unity states no binary size.
- Licence: Personal is free up to $200K revenue/funding; Pro beyond that. The Runtime Fee was cancelled
  (unity.com/products/pricing-updates).
- Data:
  - Engine diagnostics can be disabled per build profile (docs.unity.com … configure-diagnostics-editor).
  - Unity Analytics is a separate package that can be left out or disabled in the Dashboard (docs.unity.com/ugs …
    analytics/manual/faq).
  - **No Unity page states that a player with both off sends nothing**: not verified; only a network capture
    would prove it.
  - `UnityFramework` is on Apple's commonly-used-SDK list (privacy manifest and signature required;
    developer.apple.com/support/third-party-SDK-requirements/).

**LibGodot:**
- Core LibGodot ("build Godot as a library") is in **stable Godot 4.6** (2026-01-26) for **Linux, Windows and
  macOS** (github.com/godotengine/godot/pull/110863; godotengine.org/releases/4.6/).
- iOS and Android embedding is still in open PRs (#124015, #99705).
- SwiftGodotKit embeds Godot in Swift on iOS and macOS, but it builds from a **fork** of 4.7.
- No Kotlin binding was found.
- **Not usable for iPad + Android in a released version.**

**Filament:** Google's Apache-2.0 physically based **3D** renderer for Android, iOS, macOS and others (v1.81.0,
2026-11-17; github.com/google/filament). It isn't a 2D/vector animation tool. It's relevant only if K-01 moves to
3D, where it could be the shared 3D renderer on both platforms.

**Lottie:** Apache-2.0 vector-animation players for iOS/macOS and Android, authored in After Effects via Bodymovin
(github.com/airbnb/lottie-ios, lottie-android). It's on Apple's commonly-used-SDK list. Like Rive, it plays
authored animations, not a procedural morph.

Full notes with every link: `evidence/TASK-033/research/runtimes-and-engines.md` and `research/child-lock-in.md`. Anything marked "not verified" wasn't
found on an official page.

## Android (desk estimate, not measured)

- **The recipe is fixed:** SplitMix64 (ULong), the SVG subset with 16-segment curves, arc-length sampling, the
  pairing shuffle and the per-particle draws. The doc comment of `MorphCore/Sources/MorphCore/Morph.swift` gives
  it in full.
  - **Segment length is `sqrt(dx² + dy²)`, written out** (MorphCore's own `hypot` is `(a*a + b*b).squareRoot()`).
    Ports must **not** use a library `hypot`: `kotlin.math.hypot` rounds differently at the last bit, and the
    arc-length sampling then drifts.
  - **UInt64 values in the fixture stay strings** (`rngFirst4`): JSON numbers lose precision above 2^53. Parse
    them as unsigned 64-bit.
- **The proof:** load `fixtures/morph-D-dinosaur.json`, run the Kotlin morph, and compare the 240 particles at
  t = 0, 0.5 and 1 within 1e-3. **Done:** game-dev-android's independent Kotlin port matched it bit for bit.
- **Drawing:**
  - `Canvas.drawPoints(float[], paint)` and Compose `drawPoints(PointMode.Points, cap = Round)` use **one Paint,
    one colour and one size per call**, so they suit only uniform dots.
  - Twinkling or size-varying stardust (as on iOS) needs **`drawCircle` per particle**, or **`drawBitmap` per
    particle from a pre-blurred soft-dot bitmap with a per-draw alpha** (`Paint.alpha`).
  - Avoid `BlurMaskFilter` per point.
  - `RenderEffect` (API 31+) applies to a View, a RenderNode or a Compose `graphicsLayer`. It does **not** apply
    to a frame drawn with `SurfaceView` / `lockHardwareCanvas`.
- **Budget:** 240–600 particles at 60 fps is **NOT ASSESSED**. It stays so until it's measured on a real low-end
  tablet (game-dev-android).

## Child lock-in (Luan's playtest: control keys switched apps)

1. **iPad: Guided Access (system feature).**
   - Apple's guide: Settings → Accessibility → Guided Access, set a passcode, triple-click the top button in the
     app, then Start. It can disable touch areas, hardware buttons, motion and the onscreen keyboard, and set a
     time limit. (support.apple.com/en-us/111795)
   - **Apple doesn't say whether hardware-keyboard shortcuts (⌘Tab, ⌘H or Globe+H, ⌘Space, Globe) still work
     during Guided Access: NOT ASSESSED** until tested on the child's iPad with its keyboard. The procedure has
     the step.
   - An app can't block those shortcuts itself. UIKeyCommand's `wantsPriorityOverSystemBehavior` only reorders
     against text input and focus; the system gets first chance.
   - Single App Mode (`requestGuidedAccessSession`) needs a supervised MDM device, so it isn't for a family iPad.
   - **What the app must do:**
     - no time-outs that need a reply;
     - nothing that leaves the app (no links, no share sheets);
     - parent settings behind the in-app gate;
     - observe `UIAccessibility.isGuidedAccessEnabled` (the spike logs it) and, for example, hide the parent
       button while Guided Access is on;
     - a "How to lock the iPad" page in the parent area with the steps above.
2. **macOS: kiosk mode, tested on this Mac** (`evidence/TASK-033/lockin/README.md`).
   - `NSApplication.presentationOptions = [.hideDock, .hideMenuBar, .disableProcessSwitching, .disableForceQuit,
     .disableSessionTermination, .disableHideApplication, .disableAppleMenu]`, plus
     `.disableScreenCornerInteractions` on macOS 27. The window fills the screen.
   - The in-app key monitor swallows ⌘-keys too. **Only the parent chord ⌃⌥⌘Q quits.**
   - Results, posted as HID events:
     - ⌘H, ⌘Q and ⌘Space **escape without kiosk and are blocked with it**. Spotlight is confirmed by screenshot.
     - The Dock and menu bar hide.
     - ⌘Tab, ⌘⌥Esc, Mission Control and Spaces didn't trigger even without kiosk when injected, so they're **NOT
       ASSESSED** until checked on a physical keyboard. So are the Globe/fn key, hot corners and the power/Touch
       ID button.
   - Kiosk mode works in a sandboxed build.
3. **Keys inside the app (both platforms, built):**
   - Exactly one letter A–Z or digit 0–9, with no ⌘/⌃/⌥, is a press.
   - Every other key is swallowed: never passed up the responder chain (iPad `pressesBegan` without `super`; Mac
     local monitor returns `nil`). It's counted in the logs.
   - Held keys and auto-repeat are ignored.
   - What the OS keeps for itself (iPad ⌘Tab/⌘H/Globe) never reaches an app: on iPad that's Guided Access's job.
4. **ADR-0001 changes this implies** (I don't edit the ADR; for the leader and Luan):
   - **Input:** "Only letters and digits act; all other keys are swallowed; held/repeat ignored." This is a rule in
     the input layer, with a KidCore test for the key filter.
   - **macOS:** a parent-gated **Child lock** setting that applies the presentation options above. A parent exit
     (chord or parent gate) is required. It's documented as blocking ⌘Tab/⌘H/⌘Q/Spotlight, pending the physical
     check.
   - **iPadOS:** no app-side lock exists. The parent area carries Guided Access instructions, and the app
     observes Guided Access state.

## ADR-0001 changes the recommendation needs

1. **Decision §1/§5:** name `MorphCore`, as part of `KidCore` or a sibling UI-free package, as the owner of the
   morph math, with the shared fixture as the Android contract. The stage protocol takes particle positions from
   it.
2. **Decision §6 (data):**
   - Glyph outlines are **pre-baked to SVG path strings** at build time from a bundled OFL font, by a tool.
   - Object silhouettes are SVG path strings in the key table.
   - Morph timings live in JSON.
   - So no font rasterising at run time on either platform.
3. **A dependency rule:** no third-party runtime in the app without its own ADR. If Rive (or Lottie) is ever
   added: `loadCdn: false`, bundled files only, Embedded/Referenced assets, the `URLProtocol` no-request test, a
   paid editor plan (no splash), and a privacy-manifest check.
4. **Alternatives considered:** record "Rive for morph assets" and "an engine as a library (Unity as a Library,
   LibGodot)" as rejected, with this report's reasons.
5. **Child lock-in:** the input and macOS kiosk rules above, with iPad Guided Access guidance.
6. **Audio (for the audio ADR):** keep players primed off the main thread; the stop + schedule + play cost was
   3–10 ms.

## Not assessed / open
- **Every iPad device number** (camera procedure, `procedure-ipad.md`).
- **iPad hardware-keyboard shortcuts under Guided Access.**
- **Mac** ⌘Tab / ⌘⌥Esc / Mission Control / Globe with a physical keyboard.
- **Rive:**
  - a real authored glyph → object .riv, which needs the Rive editor and an account;
  - whether runtime path data can be driven from app code;
  - rive-android size per ABI.
- **Unity:** whether a player with diagnostics and Analytics off makes any network call (needs a capture).
- **The exact App Store thinned size:** that needs a signed export, which would register an App ID on Luan's Apple
  account, so it wasn't done. The arm64 Release .app size above is the approximation.
