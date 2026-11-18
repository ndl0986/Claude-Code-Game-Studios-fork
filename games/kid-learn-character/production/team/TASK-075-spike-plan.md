# TASK-075 — Plan to the four ★ spike ADRs (0007 input, 0008 kiosk, 0009 render path, 0010 audio)

> Author: game-dev-ios (TASK-075) · Review: game-qc-ios (owner of `production/qa/device-checks-plan.md`) ·
> 2026-11-18 · Plan only: no ADR text, no spike code yet.

Inputs: `production/qa/device-checks-plan.md` (b11ea6d2; rows M-, S-, P-, flags F-, sessions),
`docs/architecture/architecture.md` (Required ADRs), ADR-0001…0006 (Accepted), ADR-0011 (Proposed, c15d9830),
K-28 (local CI, Personal Team), K-34 (headless needs no MAC FREE), the Input, Child Lock-in, Parent Gate, Cast
Rendering, Scene, Audio & Voice and Accessibility GDDs, and the TASK-033 spike
(`prototypes/TASK-033-anim-runtime/`).

## The short version

- **One spike app, not four.** A single multiplatform `DeviceSpike` app (iPad + Mac) with one screen per spike serves
  every spike row. Luan installs **one** build on the iPad per session (one Personal Team signing, re-signed only if a
  session is more than 7 days after the install, F-1), and the Mac runs the same project.
- **Headless first.** Every spike's code, unit tests and Simulator build are done before any device time (K-34). The
  device sessions only measure.
- **Each ADR can reach Proposed before its rows run**, with the measurements written as pending and a **decision rule
  fixed in advance** (what result picks which option). Acceptance waits for the rows.
- **Order:** 0010 audio (its first row, P-1, can run on the existing TASK-033 app now) → 0009 render path → 0007 input
  and 0008 kiosk together (one Mac lock screen, Mac session 1's "lock and keys" half).
- **verify.sh:** not required for spike code (it lives in `prototypes/`, outside the gated cores). A **minimal spike
  check** runs instead before each install (§ "Checks before an install"). Spike code is never promoted into `apple/`;
  the stories re-implement it there, where ADR-0011's `verify.sh` applies.
- **One gap in the device-checks plan:** no row checks **iPad hardware-keyboard delivery on a real iPad** (`pressesBegan`
  / `UIKey`, all 36 keys, numpad, modifiers), which ADR-0007 needs. Proposed as **P-15** for game-qc-ios to add.

## Where the spike code lives

- `prototypes/TASK-0xx-device-spike/`: one Xcode multiplatform project (iPadOS + macOS, deployment 26), throwaway
  (prototypes are outside the code root, directory-structure.md). It reuses the TASK-033 `MorphCore` package by path.
- **Rive is not in it.** TASK-033's app fetched from Rive's CDN on load; ADR-0001 rejected Rive. The spike app is
  SpriteKit only, so it makes no network request on Luan's devices (PKC-01 hygiene even for a spike).
- Each spike screen is reachable from a debug menu; nothing is behind a gate (it is not the child's app).
- Evidence follows the device-checks plan (ADR-0011 D6 path): `production/qa/evidence/<run task id>/<short-sha>/<check-id>/`.

## Per ADR

### ADR-0007 — Input adapters ★

**(a) The decision.** How raw platform key events become ADR-0002 D5's normalized `KeyEvent`:
- iPad: `pressesBegan/Ended/Cancelled` with `UIKey` (`charactersIgnoringModifiers`, `keyCode` as
  `UIKeyboardHIDUsage`, `modifierFlags`); Mac: the `NSEvent` local monitor for `keyDown`/`keyUp` plus `flagsChanged`
  → `modifiersChanged`;
- the US-position map (HID usage / Mac key code → `positionKey`), numpad, Fn reporting where it exists;
- whether `KeyStateQuery` (`anyNonModifierDown(except:)`) is wired (only if M-1 shows no Input Monitoring prompt);
- the event delivery order and the touch adapter's point → px conversion (ADR-0006 D2).

Must satisfy: Input & Key Filter R1–R8, I1 (the ⌘-release rule), AC-1j/k/k3/k6; ADR-0002 D2, D5, D6; ADR-0006 D2;
input-filter-v1 (ADR-0004).

**(b) Headless now.**
- The mapping functions as pure functions over `(characters, keyCode, modifierFlags, isRepeat)` tuples, unit-tested
  on the Mac host and the iPad Simulator (`UIKey` can't be constructed, so the adapter splits a thin `UIKey` reader
  from a testable mapper).
- Mac: synthesized `NSEvent.keyEvent(...)` and `flagsChanged` events through the monitor in a host test.
- The HID-usage and Mac-key-code tables for US, AZERTY and QWERTZ, checked against input-filter-v1's cases.

**(c) Evidence rows.** M-1 (no Input Monitoring prompt → `KeyStateQuery` in or out), M-2 (the ⌘ window before the
chord), M-3 (physical keyboard and trackpad, shared with ADR-0008), **P-15 (proposed: iPad hardware keys on a device)**.
**Proposed before the rows: yes.** The adapter shape and tables are decidable now; `KeyStateQuery` is written as
"conditional on M-1: wired only if M-1 passes; otherwise absent and Input uses the ⌘-release rule (already the
GDD's fallback)".

**(d) Spike build.** `DeviceSpike` **Keys** screen: shows each normalized event live (character, positionKey, mask,
kind) and logs them; on the Mac it also offers the key-state read behind a switch (off by default, for M-1's clean
first launch). Same build as ADR-0008's Lock screen.

**(e) Size: S** (1–2 days). Runs in Mac session 1's first half and iPad session 1a (P-15).

### ADR-0008 — Kiosk and child lock-in ★

**(a) The decision.**
- The Mac kiosk's full-screen mode: **native full screen** (options via `window(_:willUseFullScreenPresentationOptions:)`)
  or **a borderless window at the screen frame** (ADR-0006 D4 left it here);
- the exact presentation-options set (Child Lock-in R2) on macOS 26 and 27 (`.disableScreenCornerInteractions` is 27+);
- covers on extra displays (R6), sleep/wake re-apply (R6), the engage timeout (R7), never trapping (R5);
- iPad: Guided Access observation and the panel's status line (R8).

Must satisfy: Child Lock-in R1–R9, AC-12–17; Parent Gate G7, G11; App Shell R1, R7; ADR-0002 D6 (`KioskEffects`),
D7 chain 3; ADR-0006 D1 (overlays in the main window), D4.

**(b) Headless now.**
- The `KidCore`-side Child Lock-in state machine already has unit tests in its story; the spike only needs a stub that
  drives `KioskEffects`.
- The `KioskEffects` adapter for both full-screen modes, built for macOS; unit tests for the options sets and the
  availability check (macOS 26 vs 27).
- A Simulator build of the iPad Guided Access status page.

**(c) Evidence rows.** M-3, M-4, M-5, M-6, M-7 (Mac session 1, "lock and keys"), P-4 (Guided Access, iPad session 1a).
**Proposed before the rows: yes, with a decision rule.** Both modes are specified; the rule: *prefer the borderless
window at the screen frame (one window, no Space transition, simplest key handling); choose native full screen only if
M-3 or M-4 shows a way out or a focus loss that the borderless window has and native full screen does not.* M-5 (crash)
and M-6 (sleep) are recorded for both modes. Acceptance after Mac session 1.

**(d) Spike build.** `DeviceSpike` **Lock** screen (Mac): a switch for the two modes, the options set applied through
the real adapter, an in-window overlay stub for the gate and panel (to check the window stays key), a stub chord
(⌃⌥⌘Q → overlay), the second-display cover, and a launch log for the engage timing (M-2). iPad: a **Guided Access**
page showing `isGuidedAccessEnabled` live (P-4).

**(e) Size: M** (2–3 days), shared with ADR-0007's Keys screen.

### ADR-0009 — SVG render path ★

**(a) The decision.** Cast Rendering R11's option A (live vector paths) vs B (PNG tiers per part, rasterised at build
time), or a mix (for example A for `stage`, B for `parade`).

Must satisfy: Cast Rendering R1–R12, F1, F6 (residency), the R11 measurement plan; Scene F6 (the worst case added by
TASK-054b C2); MorphCore AC-11; ADR-0006 D1–D3, D8 (60 fps cap; 120 Hz measured here); art bible §8.

**(b) Headless now.**
- A prototype bake tool for the SVG subset (Cast Rendering R2) → the baked JSON; both renderers drawing the same
  baked file; option B's rasteriser run at build time.
- Unit tests: the same baked creature drawn by A and B gives the same bounding boxes within 1 px; the subset rejector.
- Simulator frame-time smoke runs (not evidence: device numbers only count from P-2 / M-13).
- **Dependency: TASK-077** (game-art-content; game-dev-ios reviews): at least three layered creature SVGs in Cast
  Rendering's subset (a sauropod with neck parts, a rex with a jaw, a flyer with wings), plus the Dinosaurs glyphs and
  silhouettes. The Render screen's device runs wait for it; without it the spike would only measure the TASK-033
  silhouette.

**(c) Evidence rows.** P-2 (iPad: frame time, load per role, memory, app-size delta, crispness), M-13 (Mac), and the
same build serves P-3 / M-12 (the flash gate) and P-11 / M-10 (window and ppi) and P-13 (Smart Invert pair).
**Proposed before the rows: yes, with thresholds fixed in advance** (from Cast Rendering R11 and ADR-0006):
*pick B if A misses p99 ≤ 16.7 ms on the oldest supported iPad with the combined worst case, or a creature's load
exceeds the reduced T (1.2 s); pick A if both pass and A's app size is smaller; a mix if only the parade fails under
A.* Acceptance after iPad session 1b and Mac session 1's second half.

**(d) Spike build.** `DeviceSpike` **Render** screen: an A/B switch at run time, the full stage (Scene worst case:
Night, snow 60 + windy, 3 clouds, 50 stars; the current and leaving creatures; 240 specks; the glyph halo; a parade of
6), the TASK-033 Metrics recorder, the **debug frame dump at the display-link rate** for P-3 / M-12, a 60 / 120 Hz
switch (ADR-0006 D8), and the ADR-0006 ppi readout (P-11, M-10) and `accessibilityIgnoresInvertColors` on its `SKView`
(P-13).

**(e) Size: L** (4–6 days, most of it the bake tool and the two renderers), plus the art dependency.

### ADR-0010 — Audio engine ★

**(a) The decision.**
- Session category (`.soloAmbient` for "obeys silent mode, does not mix", Audio R6), activation timing (silent start
  at launch, R2.1);
- the `AVAudioEngine` graph: the 7 players and 4 buses (R2), the peak limiter (R4.5), primed buffers at the output
  format (R4.2), scheduling off the main thread (R4.3);
- the no-click cut mechanism (R2.2), ducking (F2);
- interruptions, route changes and media-services reset (R6), and the gate freeze's pause / resume (TASK-050, AC-21).

Must satisfy: Audio & Voice R1–R8, F1–F6, AC-9, AC-15, AC-16, AC-20, AC-21; ADR-0002 D6 (`AudioOutput`), D7 chain 2;
Key Table `voiceDurations` (V15).

**(b) Headless now.**
- The engine adapter against the audio-plan sink; an offline render (`AVAudioEngine` manual rendering mode) for the
  no-click cut and the limiter, checked by a sample-discontinuity detector, so AC-9 has a headless pre-check.
- Unit tests for scheduling and the player pool; a Simulator build of the audio screen.

**(c) Evidence rows.** P-1 (press → sound latency, the TASK-033 procedure), P-7 (no click, iPad), P-8 (interruptions),
P-9 (silent mode), M-14 (no click, Mac).
**Proposed before the rows: yes.** The structure is decidable now; the latency and click results are written as
pending with the AC thresholds (AC-16: within one display frame of the first answering frame on built-in or wired
output; AC-9: no discontinuity above −60 dBFS). Acceptance after iPad session 1a.

**(d) Spike build.**
- **P-1 can run now on the TASK-033 app only in a build with the Rive target removed** (or proven to use `loadCdn:
  false`), running option A (SpriteKit) only, signed with the Personal Team and passing the minimal spike check
  (including "no Rive in the installed build"). That gives the latency baseline early. Otherwise P-1 waits for
  `DeviceSpike`.
- The `DeviceSpike` **Audio** screen adds: the candidate graph and session, a cut button per bus (voice line, cast
  sound, parade tune), mute, a scripted reveal sequence, headphones-unplug and interruption logging, and a silent-mode
  check. It serves P-7, P-8, P-9 on the iPad and M-14 on the Mac. If it is ready before iPad session 1a, P-1 re-runs on
  it, so the latency is measured on the candidate graph.

**(e) Size: M** (2–3 days).

## What spike evidence can and cannot close

Spike evidence **decides ADR options; it does not pass GDD acceptance criteria** on the production app. Per row:

| Row | GDD AC | What the spike run gives |
|---|---|---|
| M-1 | Input AC-1k6 | Decides whether ADR-0007 wires `KeyStateQuery`. TCC is per bundle ID, so the **release gate re-runs M-1 on the production macOS app** |
| M-3–M-7 | Child Lock-in AC-13–17 | Decides ADR-0008's full-screen mode. The ACs **re-run on the production app** with the real gate, panel and Quit (a short subset is fine) |
| P-2, M-13 | Cast Rendering AC-17, MorphCore AC-11 | Decides ADR-0009. With three test creatures (TASK-077), the app-size delta for all 36 items and the "raise 240 particles" call are **partial**, recorded as partial |
| P-3, M-12 | Accessibility AC-08 | An ADR-0009 and F2-detector **rehearsal**. The release gate is the production busy case |
| P-13 | Accessibility AC-15 | **Stage half only** (the `SKView` opt-out). The panel half waits for the production panel |
| P-11, M-10 | ADR-0006 V6, V7 (ADR-0006 Accepted) | **Can close** ADR-0006 V6 / V7: the spike stage implements ADR-0006 D2 as written (the F1 transform, `DisplayMetrics` from the window, `.resizeFill`, the touch px conversion) and D7's ppi rule |
| P-1, P-7–P-9, M-14 | Audio AC-16, AC-9, AC-15, AC-20 | Decides ADR-0010. The ACs re-run on the production app with Audio & Voice |
| P-4 | Child Lock-in AC-12 | Decides ADR-0008's Guided Access observation. The panel's status line re-runs on the production panel |
| P-15 (proposed) | Input R1–R4 | Decides ADR-0007's iPad adapter. Re-runs on the production app |

## Builds and sessions: fewest installs

| Build | Contents | Serves rows | Install |
|---|---|---|---|
| **TASK-033 spike app, Rive removed** | SpriteKit morph + audio, the latency procedure (option A only) | P-1 (baseline) | iPad, after Setup F-1–F-3 and the minimal spike check |
| **`DeviceSpike` v1** (one app, iPad + Mac) | Audio, Render (A/B), Keys, Lock / Guided Access screens | P-1 (re-run), P-2, P-3, P-4, P-7, P-8, P-9, P-11, P-13, **P-15**; M-1–M-7, M-10, M-12, M-13, M-14 | **one** iPad install for both 1a and 1b (re-sign if more than 7 days apart); the Mac runs it from Xcode under MAC FREE |

The production-app rows (P-0, P-5, P-6, P-10, P-12, P-14, M-8, M-9, M-11, M-15, M-16, S-1–S-4) wait for the real
stories; they are not spike rows and are not planned here.

**Suggested sessions** (the device-checks plan's, with the builds above):
- **iPad session 1a:** P-1 (on `DeviceSpike` if ready, else the TASK-033 app), P-7, P-8, P-9, P-4, **P-15** → evidence for
  ADR-0010 and ADR-0007, and P-4 for ADR-0008.
- **iPad session 1b:** P-2 + P-5 (P-5 waits for a release app; skip it here), P-3, P-11, P-13 → ADR-0009 (P-11, P-13
  also close ADR-0006 rows).
- **Mac session 1, first half ("lock and keys"):** M-1–M-7 → ADR-0007, ADR-0008.
- **Mac session 1, second half:** M-10, M-12, M-13, M-14 → ADR-0009, ADR-0010 (M-10 closes an ADR-0006 row).

## Checks before an install (the minimal spike check, instead of `verify.sh`)

ADR-0011 is Accepted (fd35c14f); its `verify.sh` gates the cores under `apple/`. Spike code stays in `prototypes/` and
never moves into `apple/`, so it runs this minimal check instead. It applies to **both** installs (the TASK-033 build
for P-1 and `DeviceSpike`), before either goes onto Luan's iPad or runs on his Mac:
1. It builds headless for the iPad Simulator and macOS, and its unit tests pass.
2. **No network** (PKC-01 static subset): the entitlements show no `com.apple.security.network.client` / `.server`;
   a static grep finds no `URLSession`, `NWConnection` or web view.
3. **No Rive in the installed build:** no Rive framework or package in the target, the bundle or its symbols.
4. No remote Swift package (PKC-03 (a)).
5. **No permissions** (PKC-04, 06, 08 static subset): no `NS*UsageDescription` key in Info.plist (the Audio screen's
   silent-mode and route checks need no microphone: they only observe the session and its route); no location,
   camera or microphone entitlement (`com.apple.security.device.audio-input`, `.camera`,
   `.personal-information.location`); no URL schemes (`CFBundleURLTypes`, `LSApplicationQueriesSchemes`).
6. **The Mac key-state read is off by default** (the Keys screen's switch), so M-1 sees a clean first launch.
7. The build's short sha is recorded in the session's `results.md`.

**After each iPad session, the spike app is removed from the child's iPad** (its debug menu is ungated; leader's
choice, QC's recommendation), and the removal is recorded in that session's `results.md`.

## Order and size

| Step | Work | Size | Device |
|---|---|---|---|
| 0 | Setup F-1–F-3 (Luan); P-1 on the TASK-033 app (iPad session 1a can start) | Luan ~20 min + 20 min | iPad |
| 1 | ADR-0010 audio: headless adapter and offline click check; `DeviceSpike` Audio screen; ADR-0010 **Proposed** (pending P-1, P-7–P-9, M-14) | M | — |
| 2 | ADR-0007 + 0008: Keys and Lock screens; both ADRs **Proposed** (decision rules, pending M-1–M-7, P-4, P-15) | S + M | — |
| 3 | ADR-0009: bake tool prototype, renderers A and B, Render screen; ADR-0009 **Proposed** (thresholds, pending P-2, M-13) | L (+ art) | — |
| 4 | iPad session 1a, iPad session 1b, Mac session 1 (both halves) | per the device-checks plan | iPad, Mac |
| 5 | Each ADR updated with its results and taken to Luan for acceptance | S each | — |

Steps 1–3 are headless and can overlap: 1 and 2 by one developer, 3 by another if the leader assigns it. One
`DeviceSpike` v1 build is cut once steps 1–3 are done, so Luan installs once.

## For game-qc-ios (owner of the device-checks plan)

1. **Add P-15:** "iPad hardware keyboard on a real iPad: all 36 keys, numpad, Shift/Caps/⌘/⌥/⌃ (and Fn/Globe where
   reported) through `pressesBegan`; the normalized events match input-filter-v1's expectations" (Input R1–R4,
   ADR-0007). iPad session 1a, ~10 min, needs a hardware keyboard.
2. Rows P-2, P-3, P-11, P-13 and M-10, M-12, M-13 can name `DeviceSpike` v1 as their build; P-4 its Guided Access page;
   M-1–M-7 its Lock screen.
3. P-1 may run twice: once now on the TASK-033 app (a baseline), once on `DeviceSpike` (the candidate graph).

## Questions

None for Luan: no store, money, legal or new framework. The ADR-0009 art is TASK-077 (game-art-content); P-15 and a
"spike run / ADR evidence" column go into the device-checks plan in TASK-076 (game-qc-ios); game-dev-ios reviews
both.
