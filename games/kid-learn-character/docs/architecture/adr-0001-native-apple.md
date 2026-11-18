# ADR-0001: Native Apple stack: Swift, SpriteKit in a SwiftUI shell, one Xcode project

## Status
Accepted (Luan, 2026-11-18)

## Date
2026-11-17. Revised 2026-11-17 (TASK-035): adds the TASK-033 spike's findings. Accepted by Luan 2026-11-18.
Clarified 2026-11-18 (wording only, approved by Luan; no decision changed): Decision 6 says where silhouette
path data lives.

## Last Verified
2026-11-17 (TASK-035), against the TASK-033 spike's builds (Release, Xcode 27.1 (27A9275), iOS SDK 27.1, macOS
SDK 27):
- **macOS:** the app ran on a **real Mac** (MacBook Pro, Apple M4 Pro, macOS 27.2.1 (26B131)).
- **iPadOS:** the app ran on the **Simulator only** (iPad (A16), iOS 27.0). **No real iPad has run it.**

Any claim below not covered by those runs or by a cited official page is marked NOT ASSESSED. Nothing here is
taken from memory (see Knowledge Risk).

## Decision Makers
- **Luan:** K-03 (fully native, Apple first); SpriteKit in SwiftUI, one `apple/` project, deployment target 26+;
  K-08 (no network, no location).
- **game-leader:** author of the original ADR.
- **game-dev-ios:** TASK-033 spike and this revision (TASK-035).
- **game-dev-android:** reviewed the spike report and this revision's plan; independently ported the morph to
  Kotlin and matched the fixture bit for bit.

## Summary
The game is native on every platform (K-03). The first app is one Xcode multiplatform project under `apple/` for
iPadOS and macOS, with iPhone to follow.
- **Swift:** SpriteKit draws the key-to-picture scene and the stardust morph (K-01: 2D first); SwiftUI is the app
  shell and the parent gate.
- **The rules** (key table, mash queue) live in a UI-free Swift package, `KidCore`.
- **The morph's math** lives in `MorphCore`, a UI-free package, and follows a written, versioned contract
  (`morph-contract-v1.md`) with a shared fixture that the later Android app must also pass.
- **No third-party runtime and no network:** Rive and engines-as-libraries were tested or researched and
  rejected.
- **Child lock-in:**
  - Only letters and digits act; every other key is swallowed.
  - On macOS a parent-gated kiosk mode applies.
  - On iPad, parents use Guided Access.
- **Android** (Kotlin) comes later as its own native app under `android/`, with its own ADR.
- The studio template has no row for this stack, so engine-aware checks report NOT ASSESSED.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | None from the template's engine table. Swift 6.4 (swiftlang-6.4.0.34.1), Xcode 27.1 (27A9275), SDKs: iOS 27.1, macOS 27.0, on macOS 27.2 |
| **Domain** | Core |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH. **NOT SOURCEABLE**: `docs/engine-reference/` has no SpriteKit, SwiftUI, iPadOS 27 or macOS 27 folder, and `.claude/engines/engines.tsv` has no Swift row. These SDKs postdate the model's knowledge, so API claims are proven by building and running, never from memory. |
| **References Consulted** | `design/gdd/game-concept.md`; `production/team/decisions.md` (K-01, K-03, K-05, K-07, K-08); `design/art/art-bible.md` §7 (UX rules) and §8 (Asset Standards); `design/tech/TASK-033-anim-runtime.md` and `production/qa/evidence/TASK-033/` (spike report, measurements, official-source research); `games/dai-dat-anh-hung/docs/architecture/adr-0001-native-per-platform.md` (precedent for a stack the template doesn't know) |
| **Post-Cutoff APIs Used** | Built and run in the TASK-033 spike. **Proven on a real Mac:** `NSEvent.addLocalMonitorForEvents` (keyDown, `timestamp`, `isARepeat`); `NSApplication.presentationOptions` incl. `.disableScreenCornerInteractions` (macOS 27+); `NSView.displayLink` / `CADisplayLink.targetTimestamp`; `AVAudioEngine` + `AVAudioPlayerNode`; `ProcessInfo.beginActivity(.latencyCritical)`. **Simulator only:** UIKit `pressesBegan` / `UIKey` hardware-keyboard delivery (the code built and ran, but no hardware key was pressed into it); `UIAccessibility.isGuidedAccessEnabled` (logged `false`; Guided Access not exercised); `CADisplayLink`, SpriteKit and AVAudioSession on iOS 27. Anything else the scaffold uses is proven by its own build. |
| **Verification Required** | Unchanged: the app builds, launches and is observed on an iPad Simulator and on macOS, with retained screenshots in `production/qa/evidence/` (`.claude/docs/run-and-observe.md`). New: the iPad device numbers come from TASK-033's camera procedure on a real iPad; the keyboard shortcuts marked NOT ASSESSED are checked on a physical keyboard; `KidCore`/`MorphCore` tests pass, incl. the morph contract fixture. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | The key-table / content-data ADR; the audio ADR; the SVG-rendering ADR (open follow-up below); a later Android ADR (which adopts `morph-contract-v1`); a 3D (RealityKit) ADR if K-01 moves to 3D |
| **Blocks** | The scaffold story (first Xcode project). Now accepted (2026-11-18), so this ADR no longer holds it back. |
| **Ordering Note** | Written at Concept stage so `/setup-engine` has a recorded engine. Revised by TASK-035 with the TASK-033 spike. Accepted by Luan on 2026-11-18. `/create-architecture` and `/architecture-decision` extend it. |

## Context

### Problem Statement
Luan chose a fully native app per platform, Apple first (K-03). The template can configure Godot, Unity, Unreal
or Web, but not Swift, so the stack needs one recorded decision that code roots, test roots and later stories can
cite. Luan also asked whether a graphics or animation engine could be combined with native Swift now and native
Android later. TASK-033 answered that with a spike, and this revision records the answer.

### Constraints
- **Toddlers (2.5–3) with a parent:** big touch targets, instant feedback, no network, no data (concept pillars
  Every Press Answers and Safe by Design). Apple Kids category rules apply.
- **Input:** an on-screen keyboard plus a hardware keyboard on iPad and Mac, with the same behaviour.
- **Child lock-in:** in Luan's playtest of the browser one-shot, the worst moment was control keys switching apps
  or losing focus.
- **2D first, 3D later** for a few favourites (K-01); the scene layer must be swappable.
- **Schedule:** MVP in about one week (concept MVP), so the toolchain must be the least-friction one.
- **Team:** one developer owns the Apple app; Android comes after.

### Requirements
- Every key A–Z and 0–9 maps to a picture, sound and spoken line from a data table (JSON), not code (K-07:
  themes cover every key).
- A queue of at most 3 pending keys, further presses ignored, about 3 s per reveal while queued.
- One shared stardust-morph effect for all 36 glyphs, driven by data, identical on Apple and Android.
- Parent-gated settings; fully offline (K-08); Reduce Motion respected (art bible §7).

## Decision

**1. Stack.**
- **Language and scene:** Swift. SpriteKit for the scene: it draws the glyph, the particles at the positions
  `MorphCore` computes, the object and its idle motion.
- **SwiftUI:** the app shell, the optional on-screen keyboard row if it's simpler there, and the parent gate.
- **Audio:** AVAudioEngine for the object sound and the voice line. Sounds are stored as AAC `.m4a` mono and
  decoded to PCM at load (art bible §8).
  - **Audio note for the audio ADR:** in the spike, `AVAudioPlayerNode.stop()` + `scheduleBuffer` + `play()` on
    the main thread took **3–10 ms** before the sound was scheduled. That's **measured on the Mac and the iPad
    Simulator only**. The audio ADR keeps players primed and cuts with a short fade off the main thread.
- **Tests:** XCTest.

**2. One project.**
- A single Xcode multiplatform project under `apple/` for iPadOS and macOS now. iPhone is added as a destination
  later, not a new project.
- Minimum deployment: iPadOS 26 and macOS 26. The spike built with a deployment target of 26 against the 27 SDKs;
  the scaffold build confirms it.
- The bundle ID is set when the name is chosen (K-04, open).

**3. Code and test roots.**

| | Code root | Unit tests | UI / device tests |
|---|---|---|---|
| Apple | `apple/` (Xcode project; the game rules in `apple/KidCore/`, the morph in `apple/MorphCore/` or a `MorphCore` target inside `KidCore`; the scaffold story picks) | `apple/KidCore/Tests/`, the `MorphCore` tests, and `apple/<App>Tests/` (XCTest) | `apple/<App>UITests/` |
| Shared data | `content/` (the key table, glyph and silhouette path data, morph timings, fixtures) | `content/fixtures/` read by both apps' tests | — |
| Android (later) | `android/` | its own ADR | its own ADR |

The template's skills default the code root to `src/`. **Every task brief must name its root (`apple/`).** Code
must never be written under `src/`. Prototype code (`prototypes/`) is never imported.

**4. `KidCore` and `MorphCore` stay UI-free.**
- **No UI imports:** the key table loader, the mash queue and its timing, the key filter (Decision 9) and the
  morph live in Swift packages with no SwiftUI, SpriteKit, UIKit or AppKit imports. They run as plain unit tests.
- **`MorphCore` follows the morph contract:** `docs/architecture/morph-contract-v1.md`, "morph-v1". The contract
  fixes:
  - the SVG path subset and its tokenizer;
  - 16-segment curves;
  - arc-length sampling into a centred, y-down unit box;
  - SplitMix64;
  - the Fisher–Yates pairing and the four per-particle draws;
  - the phase and Bézier formulas.
- **Two rules that broke ports elsewhere:** segment length is **`sqrt(dx²+dy²)` written out, never a library
  `hypot`**. **UInt64 values** (seed, RNG outputs) are **JSON strings**.
- **The shared fixture** is `content/fixtures/morph-contract-v1.json`, with 4 cases plus tokenizer cases.
  - A port passes within **±1e-3**.
  - The Swift tests check it, and the Android app's tests must too.
  - It's regenerated only on a contract version bump.
- **What the contract fixes, and what it doesn't:** it fixes the numbers only. Each platform's stage, drawing,
  audio and lock-in belong to its own ADR.

**5. Swappable stage.** The scene sits behind a small protocol (show an entry, advance the queue; it takes
particle positions from `MorphCore`). So SpriteKit can be replaced by RealityKit for 3D favourites without
changing `KidCore` or `MorphCore`.

**6. Data-driven.**
- **The data:** keys, pictures, sounds, spoken lines, theme packs (K-07), and the tuning values are JSON bundled in
  the app, never hard-coded. Tuning covers queue size 3, a reveal hold of about 3 s, the morph timings and the
  particle count. The art bible §8 proposes 420 particles per morph; the spike measured 240.
- **Reduce Motion:** a second, platform-neutral **"reduced"** timing set in the same data, chosen by the
  iOS/macOS Reduce Motion setting (art bible §7).
- **Glyph outlines** are **baked at build time to SVG path strings** from the bundled OFL font by a tool. The font
  name, version and licence are recorded with each glyph file (`glyph_<font>_<char>.json`). No font is rasterised
  at run time on any platform.
- **Object silhouettes** are **one compound SVG path per cast member** (art bible §8), baked to its own file
  (`sil/sil_….json`). The key table does not hold the path: each entry names that file in its `silhouette` field
  (Key Table & Theme Data). *(Clarification 2026-11-18: the wording was "in the key table".)*
- **These path strings are morph input data:** the particles' sample points. They are **not** how the glyph or the
  object picture is drawn. That's the SVG-rendering decision, left open (Open follow-ups).
- **The bake tool:** it flattens each silhouette into the v1 subset only (M/L/H/V/C/Q/Z, plain decimal numbers,
  `M` after every `Z`) and **fails loudly** otherwise. A CI check parses every path file the key table names with a v1 parser
  (contract §8).

**7. The `project.yaml` engine block.**
- `engine.name` and `engine.code_root` stay **unset**: `engine.name` accepts only Godot, Unity, Unreal or Web, and
  a wrong value would route work to the wrong specialists.
- A commented block records the stack.
- Template checks that need an engine row (specialist routing, code-root scans, `/security-audit` engine rows)
  report NOT ASSESSED and never pass.
- `CLAUDE.md` and `.claude/` are symlinks to the shared repo root, so this setup doesn't edit the shared
  Technology Stack lines; this ADR is the record.

**8. Dependencies and network.**
- **Network: none** (K-08, Pillar 5 Safe by Design).
  - No network call and no location. The weather is picked by a grown-up behind the parent gate; the time of day
    comes from the system clock.
  - There's no network code on iPadOS.
  - On macOS the sandboxed app has **no `com.apple.security.network.client` entitlement**, so any attempt is
    denied by the sandbox.
  - (For the later Android ADR: the same rule means no `INTERNET` permission and no advertising-ID permission in
    the manifest.)
- **No third-party runtime or SDK** enters the app without its own ADR.
- **If Rive (or Lottie) is ever added**, these rules apply. The spike measured why:
  - Rive's legacy Apple API (`RiveFile` / `RiveModel` / `RiveViewModel`) **defaults `loadCdn` to `true`**. With it,
    Rive's own `hosted_assets.riv` made the runtime request `https://public.uat.rive.app/cdn/uuid/…` **as soon as
    the file loaded**; the sandbox denied it. With `loadCdn: false`: zero requests.
    (`production/qa/evidence/TASK-033/network/`)
  - **The rules:**
    1. `loadCdn: false` on every load.
    2. Files only from the bundle, never `webURL`/`httpUrl`/`.url(...)`.
    3. Every asset exported **Embedded or Referenced, never Hosted**.
    4. A unit test loads every bundled file under a `URLProtocol` that fails on any request.
    5. A paid editor plan: free exports show a Rive splash screen.
    6. A privacy-manifest check (Rive ships one; Lottie is on Apple's commonly-used-SDK list).

**9. Child lock-in** (Luan's playtest; art bible §7).
- **(a) Keys inside the app, both platforms.**
  - Exactly one letter A–Z or digit 0–9 with no ⌘/⌃/⌥ is a press. Every other key is **swallowed**, never passed
    up the responder chain: iPadOS `pressesBegan` without `super`; on macOS the local key monitor returns `nil`.
  - Held keys and auto-repeat are ignored.
  - The optional on-screen keyboard row (off by default, art bible §7) feeds the same press path.
  - **Requirement:** the filter lives in `KidCore` with a unit test. Today it exists only in the prototype
    (`prototypes/TASK-033-anim-runtime/Spike/Input.swift`).
- **(b) macOS kiosk, behind the parent gate.**
  - A grown-up turns on "Child lock". The app applies `NSApplication.presentationOptions = [.hideDock,
    .hideMenuBar, .disableProcessSwitching, .disableForceQuit, .disableSessionTermination,
    .disableHideApplication, .disableAppleMenu]`, plus `.disableScreenCornerInteractions` on macOS 27+. The
    window fills the screen, and the app also swallows ⌘-keys.
  - **The parent key chord** (⌃⌥⌘ + a key) opens the grown-up panel, which holds the way out (art bible §7). In
    the spike the chord quit the app.
  - **Tested on the real Mac** (keys posted at the HID event tap, `evidence/TASK-033/lockin/`): **blocks ⌘H, ⌘Q
    and ⌘Space (tested)**, all of which escape without it; the Dock and menu bar hide.
  - **NOT ASSESSED:** ⌘Tab, ⌘⌥Esc (Force Quit), Mission Control, Spaces, the Globe/fn key, hot corners and the
    power/Touch ID button. The injected keys didn't trigger them even without kiosk, so a physical keyboard
    check is needed.
- **(c) iPadOS: Guided Access, no app-side lock.**
  - An app can't block system keyboard shortcuts (⌘Tab, ⌘H/Globe+H, ⌘Space). The system gets them first, and
    `wantsPriorityOverSystemBehavior` only reorders against text input and focus.
  - Single App Mode needs a supervised MDM device, so it isn't for a family iPad.
  - The app therefore:
    - shows **Guided Access instructions** in the parent area (Settings → Accessibility → Guided Access, set a
      passcode, triple-click the top button; support.apple.com/en-us/111795);
    - observes `UIAccessibility.isGuidedAccessEnabled`;
    - avoids timed prompts and anything that leaves the app.
  - **NOT ASSESSED:** whether hardware-keyboard shortcuts escape Guided Access. Apple doesn't say, and it hasn't
    been tried on a device.

## Alternatives Considered

### Alternative 1: Unity (C#)
- **Description**: One engine and codebase for all platforms. Luan already knows it.
- **Pros**: Familiar to Luan; one codebase also for Android; 3D is easy.
- **Cons**: Contradicts K-03 (fully native); heavy for a toddler toy; no direct benefit for the MVP; Apple
  platform features (hardware keyboard, Kids category) go through another layer.
- **Rejection Reason**: Luan reaffirmed native Swift in /brainstorm (2026-11-17).

### Alternative 2: SwiftUI only (Canvas / TimelineView, no SpriteKit)
- **Description**: Draw the morph with SwiftUI.
- **Pros**: One framework; less to learn.
- **Cons**: No built-in particle system for the stardust; harder to move to 3D later.
- **Rejection Reason**: SpriteKit gives particles and a scene graph out of the box.

### Alternative 3: Separate `ios/` and `macos/` projects
- **Description**: Two Xcode projects sharing `KidCore`.
- **Pros**: Platform-specific tuning is isolated.
- **Cons**: More duplicated setup, and not needed for the MVP.
- **Rejection Reason**: One multiplatform project is enough; split later only if a platform diverges.

### Alternative 4: Web (HTML) as the product
- **Description**: A browser game.
- **Pros**: Fastest to start.
- **Cons**: Not native (K-03); hardware keyboard and Kids-category fit are weaker.
- **Rejection Reason**: Allowed only as a throwaway sketch (`/prototype --path html`), rebuilt natively.

### Alternative 5: Rive for the morph assets (TASK-033, built and measured)
- **Description**: Play authored Rive animations (RiveRuntime 6.30.1, MIT) for the letter → object morph; the
  same `.riv` would play on rive-android.
- **Pros**: Fast. On the Simulator/Mac, press → first frame was 9–17 ms median, a lower bound, about the same as
  SpriteKit. Artist-authored motion. One file plays on both platforms.
- **Cons**:
  - The morph is procedural. Rive's docs claim no runtime glyph → silhouette morph, so 36 keys means about 36
    authored animations (or an unverified, server-signed path-effect script).
  - It adds **5,528 KB** to an arm64 iOS app (≈ 2.2 MB zipped; the app without it is 540 KB).
  - Its legacy API fetches CDN-hosted assets by default (Decision 8).
  - A shipped file needs a paid editor plan to avoid the splash screen.
- **Rejection Reason**: SpriteKit + `MorphCore` does every key from data at the same speed, with no dependency,
  no network path and a contract Android already passed.

### Alternative 6: An engine as a library (Unity as a Library; LibGodot) (TASK-033, official sources)
- **Description**: Embed a game engine inside the native app for the scene.
- **Pros**: Engine tooling; one scene for both platforms.
- **Cons**:
  - **Unity as a Library:**
    - supports Android, iOS and Windows, **not macOS**;
    - renders full-screen only and allows one runtime instance;
    - keeps 80–180 MB after unload;
    - `UnityFramework` is on Apple's commonly-used-SDK list;
    - Unity doesn't document that a player with diagnostics and Analytics off sends nothing: not verified.
  - **LibGodot:** stable since Godot 4.6 for desktop only. iOS/Android embedding is in open PRs, and SwiftGodotKit
    uses a fork.
- **Rejection Reason**: It can't cover iPad + Mac, adds data-collection risk in the Kids category, and isn't
  released for mobile. Filament (a 3D renderer) is noted only for a possible 3D ADR. Lottie plays authored
  animations, like Rive.

## Consequences

### Positive
- Best fit for iPad touch, hardware keyboards and Apple's Kids category, with the platform's own audio and tooling.
- `KidCore` and `MorphCore` make the rules and the morph unit-testable without a Simulator, and keep a 3D swap
  cheap.
- The morph is a written contract with a shared fixture, so Android reuses the exact behaviour without sharing
  code.
- Content stays data, so theme packs (concept Tier 1) are a data change plus art.
- No network and no third-party SDK keep the Kids-category story simple.

### Negative
- Android, when it comes, is a second implementation of the stage, audio and lock-in, plus a port of `MorphCore`
  against the contract.
- The template's engine-aware tooling doesn't cover this stack (NOT ASSESSED).
- No pinned API reference for SpriteKit or SwiftUI: API use is verified by building and running.
- iPad lock-in depends on parents using Guided Access; the app can't enforce it.

## Risks
- **Post-cutoff SDK APIs misremembered.** Mitigation: every API is proven by a build and a run (the list above
  separates Mac-proven from Simulator-only).
- **Hardware-keyboard events differ between iPad and Mac.** Mitigation: the TASK-033 spike ran on the Mac. The
  iPad keyboard path ran only on the Simulator without a real key press, so it's checked on a real iPad with a
  keyboard.
- **The morph contract drifts between platforms.** Mitigation: the versioned spec, the shared fixture in both
  apps' CI, and no library `hypot`.
- **Art tools export paths the v1 parser can't read** (arcs `A`, `S`/`T`, transforms, nested groups).
  Mitigation: the bake tool flattens to the subset and fails loudly; a CI parse check.
- **Skills write code under `src/`.** Mitigation: briefs name `apple/`, and reviews reject `src/`.
- **Deployment target 26 is wrong for the child's iPad.** Mitigation: Luan confirms the iPad's OS; the scaffold
  build verifies the target.
- **Real-device performance is unknown.** All latency and frame figures are lower bounds from the Simulator and the
  Mac. Mitigation: TASK-033's camera procedure on the child's iPad before release decisions rely on them.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| game-concept.md | Native, Apple first: iPadOS + macOS, then iPhone (K-03) | One Xcode multiplatform project in `apple/` |
| game-concept.md | Pillar 1: every press answers, mashing never breaks | `KidCore` mash queue (max 3), unit-tested without UI. The spike's 60 s mash at 10 presses/s kept at most 1 active morph, 1 voice and flat memory (Simulator/Mac) |
| game-concept.md | Pillar 2 and K-01: letter morphs into the object, 2D first | `MorphCore` + `morph-contract-v1`; SpriteKit draws it; swappable stage for a later 3D |
| game-concept.md | Pillar 5 and K-08: safe, offline, parent gate; no network, no location | Network none (Decision 8); weather picked by hand; SwiftUI parent gate |
| game-concept.md / K-07 | Data-driven key, picture, sound table; themes cover every key | Bundled JSON read by `KidCore`; glyph and silhouette path data (Decision 6) |
| art-bible.md §7 | Reduce Motion; parent chord opens the grown-up panel on the Mac; optional on-screen keyboard row, off by default | "reduced" timing set (Decision 6); kiosk + parent chord (Decision 9b); keyboard row on the same press path (9a) |
| art-bible.md §8 | Silhouette path per cast member; glyphs baked from the OFL font; SVG rendering decided by an ADR with an iPad measurement | Decision 6 + contract §8; SVG rendering left open (Open follow-ups) |

## Performance Implications
- **CPU**: One scene, a few hundred particles and one object at a time. The spike measured frame p99 of 17.1 ms
  (Simulator, 60 Hz) and 26.7 ms (Mac, 75 Hz) for SpriteKit with 240 particles. **On a real iPad: NOT ASSESSED.**
- **Memory**: 36 pictures plus sounds; budgeted when the art bible sets sizes (§8: load creatures on demand). The
  spike held flat memory through a 60 s mash (≈ 27 MB Simulator, ≈ 167 MB Mac).
- **Latency**: press → first frame drawn was 11–12 ms median, p95 18–21 ms (SpriteKit, Simulator/Mac). That's a
  **lower bound**: it doesn't include touch/keyboard delivery or display scan-out. The device number comes from
  the camera procedure.
- **Load Time**: the table and first assets load before the first key is shown.
- **Network**: None.

## Migration Plan
Nothing to migrate.
- The paused TASK-030 iOS plan and the TASK-031 Android notes feed the next ADRs.
- The TASK-033 prototype is never imported. `MorphCore` is rewritten to production standards against
  `morph-contract-v1`, and the prototype's pre-v1 fixture is superseded by `content/fixtures/morph-contract-v1.json`.

## Open follow-ups (not decided here)
1. **How the SVG art reaches the screen** (art bible §8): live vector paths (SKShapeNode) versus PNG tiers
   rasterised at build time (stage, list, parade). Decided by a later ADR in `/create-architecture`, **backed by a
   measurement on a real iPad**. This ADR only fixes the path data used as morph input.
2. **iPad device numbers:** run `production/qa/evidence/TASK-033/procedure-ipad.md` (240 fps camera: press → frame,
   press → sound) on the child's iPad.
3. **The audio ADR:** primed players, cuts off the main thread, loudness matching (art bible §8).
4. **Physical-keyboard lock-in checks:**
   - macOS: ⌘Tab, ⌘⌥Esc, Mission Control, Spaces, Globe/fn, hot corners;
   - iPad: shortcuts under Guided Access.
5. **The Android ADR:** adopts `morph-contract-v1` and the fixture; no `INTERNET`/ad-ID permission; "reduced"
   timings from "Remove animations"; its own stage, audio and lock-in.

## Validation Criteria
- The app builds, launches and plays all 36 keys on an iPad Simulator and on macOS, with retained screenshots in
  `production/qa/evidence/`.
- `KidCore` tests prove the mash rule (3 queued, the 4th ignored, hold timing from data) and **the key filter**
  (letters and digits act; everything else is swallowed; repeats ignored).
- `MorphCore` tests pass **every case in `content/fixtures/morph-contract-v1.json`**, including the tokenizer
  cases.
- A **no-request test:** the app makes no URL-loading request during a full play session (a `URLProtocol` probe,
  as in the spike).
- The macOS **kiosk** blocks ⌘H, ⌘Q and ⌘Space, and the parent chord opens the grown-up panel. The NOT ASSESSED
  shortcuts are checked on a physical keyboard.
- **Reduce Motion** on → the "reduced" timings are used.
- A hardware keyboard on a real iPad or Mac plays the same as touch.

## Related
- `design/gdd/game-concept.md`; `production/team/decisions.md` (K-01, K-03, K-05, K-06, K-07, K-08);
  `design/art/art-bible.md` §7, §8.
- `docs/architecture/morph-contract-v1.md`; `content/fixtures/morph-contract-v1.json`.
- `design/tech/TASK-033-anim-runtime.md`; `production/qa/evidence/TASK-033/` (runs, network, lockin, research,
  procedure-ipad.md).
- Precedent: `games/dai-dat-anh-hung/docs/architecture/adr-0001-native-per-platform.md`.
- Follow-ups: the scaffold story; the key-table, audio and SVG-rendering ADRs; a "Native" row in the template's
  engine table (Luan's call).
