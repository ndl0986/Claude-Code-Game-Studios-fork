# App Shell & Title

> **Status**: Approved (independent read by game-dev-android, merged 2026-11-18)
> **Author**: game-dev-ios for Luan (TASK-051); plan reviewed by game-dev-android
> **Last Updated**: 2026-11-18
> **Last Verified**: 2026-11-18, against Input & Key Filter (Title and Inactive states), Audio & Voice (E5, R2.1,
> R6), Settings Store (R5, R8), Key Table & Theme Data §5, Press Queue (R3, R9), Reveal Stage (R8, R10), Hint
> Letters (R9), Parade (R6), Privacy & Kids Compliance (PKC-01, 02, 05, 09, 12, 14; L-07), decisions K-10, K-12,
> K-13, K-15, K-18, K-20–K-22, the art bible §2 and §7, and the one-shot's title scene
> **Implements Pillar**: Pillar 1 (Every Press Answers), Pillar 5 (Safe by Design)

## Summary

The App Shell owns the app's life: how it launches, the Title screen, the switches between Title, Play, the
grown-up gate and panel, and the background, the window on iPad and Mac, memory warnings and quitting. It draws
only the Title. Play belongs to the Reveal Stage, the gate and panel to the Parent Gate & Grown-up Panel, the Mac
kiosk to Child Lock-in. It stores nothing and sends nothing anywhere.

> **Quick reference** — Layer: `Presentation` · Priority: `MVP` · Key deps: `Reveal Stage`, `Settings Store`
> (also Key Table & Theme Data, Input & Key Filter, Audio & Voice, Hint Letters, Parade, Child Lock-in, Parent
> Gate & Grown-up Panel)

## Overview

The child's grown-up opens the app. A sky in the colour of the hour fills the screen at once, a T-Rex breathes on
the hill, and a warm play button glows. There are no words. The child presses any letter, or taps anywhere but the
moon: a chime, and the toy is ready for its first letter. If the grown-up switches away and comes back soon, the
child finds their creature where they left it; after more than half an hour away, the Title greets them again.

Behind that, the App Shell runs the launch in a fixed order so the first frame is already right, so a press never
reaches play before the theme is loaded, and so the Mac child lock never closes before its way out works.

## Player Fantasy

**"It's always ready."** For the child, the toy opens straight onto something warm to touch, and anything they
press or tap starts it; nothing has to be read or found. For the grown-up, the app opens fast, comes back to where
the child was after a short break, and never shows an ad, a prompt, a link or a login, and never leaves the Mac
locked in a way they can't undo.

## Detailed Design

### Core Rules

**R1. Launch sequence** (the order matters; the theme load needs the settings).

| Step | What happens | Owner (rule) |
|---|---|---|
| 1 | Read the Settings Store synchronously, before the first frame | Settings Store R5 |
| 2 | Hand `themeId` to the Key Table, which loads and checks the theme off the main thread, including decoding its audio. A stored theme that fails (or is not bundled) loads Dinosaurs in memory and keeps the stored id | Key Table §5, Audio R4.1 |
| 3 | In parallel with 2: start the audio engine, silent; install Input's handlers, including the Mac's ⌃⌥⌘Q chord | Audio R2.1, Input R6 |
| 4 | **First frame: the Title**, already in the clock's look (art bible §2: "the first frame is already in the right look") | this GDD (R2) |
| 5 | **Mac only:** App Shell signals **"the app is ready"** when all of these hold: the first frame has been drawn, the ⌃⌥⌘Q chord handler is installed, Input's kiosk-on mode is on, and the window covers its display. If `childLock` is stored true, Child Lock-in then engages the kiosk once its own preconditions also hold: the app is active and `childLockActive` is on (Child Lock-in R3, TASK-052). Turning it off in the panel lasts for this run only; it comes back at the next launch (K-21) | Settings Store R8, K-12, K-21, Child Lock-in R3 |
| 6 | When the Key Table reports the theme ready, play may start (R3) | this GDD |

- **Launch screen** (the static image the OS shows before step 4): a plain field of the **Dusk sky's mid colour**
  `#46558f` (proposal). It can't follow the clock, so it carries nothing else.
- **No launch-time network, identifier or prompt** of any kind (PKC-01, 02, 05): no review prompt, no "more apps",
  no tracking prompt, no permission prompt.

**R2. The Title screen** (art bible §2 Title state "a door left ajar", energy 2; K-22).
- **Contents:** the Scene backdrop for the time of day and weather; the theme's **title creature** idling on the
  ground line (Key Table `titleCastId`; Dinosaurs: the T-Rex, K-22), drawn by Cast Rendering at the `stage` role;
  the **play button**, the one icon (art bible §7), with light gathering on it (a gold glow at dusk and night,
  carried by its amber outline in morning and day); the **moon** (the Parent Gate).
- **No text** at all: no wordmark, no control hints (K-22, art bible §7).
- **Motion:** the play button breathes at `title_breathe_hz` (0.38 Hz, ±4% scale, as played), within the ≤ 1 Hz rule;
  the title creature idles as in Play (Cast Rendering R7). With Reduce Motion the breathe amplitude halves
  (`reduce_motion_scale`, Cast Rendering).
- **Silent** until the first input (Audio R6). No hints on the Title (Hint Letters).
- **Layout:** in stage units on the safe stage, fitted by the Reveal Stage's contain-and-extend transform
  (Reveal Stage R10): the play button at (640, 520), the title creature anchored on the ground line, the moon where
  the Parent Gate puts it.

**R3. What starts play** (K-10, K-22).
- **Keys:** any letter or digit key gives Input's `startPlay` (Input Title state). Every other key does nothing
  (system keys still pass, Input R5).
- **Touch / click:** **any tap except the moon** starts play (as played). A touch on the moon goes to the Parent
  Gate (`gateTouch`, as in Play); App Shell owns all other Title touches (Input Title state).
- **On start:** the E5 title chime plays at once (Audio E5), and the play button lights fully.
- **The title press is not the first reveal** (Input decision): Play opens on an empty stage, and the child's next
  press starts reveal 1 (Press Queue R3, AC-17 there). Input's held set carries over, so the key that started play
  does not also make a press until it goes up and down again.
- **While the theme is still loading** (the follow-up assigned to App Shell, Settings Store R5.3): App Shell keeps
  **one pending start**. The chime plays and the button lights at once; Play is entered as soon as the Key Table
  reports the theme ready; further starts are absorbed. The Press Queue never sees a press before the theme is
  ready. If the theme never becomes ready (it cannot for Dinosaurs: the build gate), the Title stays, with one
  debug log line.

**R4. Entering Play.** App Shell switches to Play and tells, in this order: Input (Play state), the Press Queue
(empty queue, no current, its R3), the Reveal Stage (Empty), Hint Letters (Play entered: fresh hints, the pulse
resets, its R9). The Parade's batches are **not** reset by a return to the Title; they
reset only at launch (Parade R1).

**R5. The grown-up gate and panel.** App Shell only switches states; the gate and panel are the Parent Gate's.
- Opening the number challenge: the Reveal Stage `freeze()`s play (K-20, Reveal Stage R8).
- A correct answer: the panel opens, and the Reveal Stage `settle()`s (K-15).
- Closing the panel returns to the state the gate was opened from (Play, or the Title).
- The **device-silenced hint** ("No sound? Check silent mode and the volume") is a static line in the grown-up
  panel, laid out by the Parent Gate & Grown-up Panel GDD (Audio R6, K-13). Silent mode cannot be detected, so
  nothing appears on the child's screens.

**R6. Background and return** (K-15, K-22).
- **To the background** (iPad: the scene leaves the foreground; Mac: the app is hidden or its window is minimised):
  the Reveal Stage settles (its R8; the queue is cleared, Press Queue R9), Audio cuts its players (its R6), Hint
  Letters clears (its R9), a walking parade drops (Parade R6), Input clears its held set (Inactive). App Shell
  notes the time on the **continuous monotonic clock** (R6 note) in memory.
- **Return, away ≤ `title_after_s` (30 min, K-22):** back to Play with the settled creature, three fresh hints
  (Hint Letters R9), and the next press starts at once.
- **Return, away > `title_after_s`:** to the **Title** (R2), as if Play had not begun: the next start enters Play
  afresh (R4).
- **Clock note:** "away" is measured on a monotonic clock **that keeps counting while the device sleeps** (Apple:
  the continuous clock, `ContinuousClock` / `mach_continuous_time`; Android: `SystemClock.elapsedRealtime`), not
  the uptime clock of Input R8, which stops during sleep, so an iPad put to sleep overnight still counts as away.
  It is held in memory only; nothing is stored (Settings Store R2). Privacy follow-up: confirm this clock's
  required-reason entry with PKC-09 (35F9.1, "time elapsed between events in the app").
- **The Mac's window losing key focus** (another app in front, with the kiosk off) is Input's Inactive state, not
  the background: nothing settles; play simply receives no keys.
- **Cold launch** (the OS ended the process, a crash, or a quit): always the Title (R1), with nothing restored,
  because nothing is stored (Settings Store R2).

**R7. Windows and the safe area.**
- **iPad:** landscape (both ways) when full screen. iPadOS no longer lets an app require full screen, so Split View,
  Slide Over and Stage Manager windows of any shape are supported: App Shell hands the window size and safe-area
  insets to the Reveal Stage, whose contain-and-extend fit (its R10) keeps the whole safe stage visible inside the
  safe area; a narrow or portrait window simply gets more sky and ground. Guided Access (Child Lock-in) normally
  keeps the app full screen.
- **Mac:** one resizable window, minimum `mac_min_window` 960 × 540 pt (proposal); full screen allowed. With the
  kiosk on, the window fills the screen and stays so (ADR-0001 Decision 9b; Child Lock-in). Whether that is native
  full screen (the options then go through `window(_:willUseFullScreenPresentationOptions:)`) or a borderless window
  at the screen's frame is **decided in the Mac build, NOT ASSESSED**. Closing the window quits the app (one
  window). ⌘Q quits only with the kiosk off (Input R5).
- **One window, overlays inside it:** the gate's challenge and the grown-up panel are **overlays drawn in the main
  window**, never separate windows, sheets or popovers, so the window never resigns key while they show (a
  `didResignKey` would drop the lock; Child Lock-in review).
- **Any resize** (window, rotation, Split View change) republishes the Reveal Stage's fit; the reveal in progress
  is not restarted, and Cast Rendering may change texture tier (its edge case).

**R8. Memory warnings.** App Shell receives the OS memory warning and asks the owners to shed what can be
rebuilt, in this order:
1. Cast Rendering's **prefetched** figures (its R10);
2. the **leaving** creature (its fade ends at once);
3. `list`-role textures.
- A **second warning within `memory_escalate_s` (30 s)**: also the parade's figures; a walking parade ends as if
  the panel had opened (it counts as played, Parade R6).
- **Never shed:** the current creature, the active theme's decoded audio (Audio R4.1) and the fixed sounds, the
  current morph.
- Each warning writes one debug log line; nothing is shown to the child. A shed prefetch is simply loaded again at
  its reveal's start (late art, Cast Rendering R10).

**R9. Crashes and relaunch** (PKC-01, 02, 05, 14).
- The app has **no crash reporter, no MetricKit or diagnostics subscription, no upload, and no "last session"
  marker** (the Settings Store's list is closed, its R2).
- After a crash, nothing relaunches the app by itself; the next launch is a normal cold launch to the Title (R6).
- On the Mac with the child lock stored on, the kiosk engages only once the app is ready (R1 step 5), so the chord
  always works once the kiosk is on. That a crash **with the kiosk on** leaves the Mac usable (the OS drops the
  presentation options when the process dies) is **NOT ASSESSED**; Child Lock-in's `kill -9` test covers it.
- Whether the OS's own opt-in crash reports (shared by the user with developers) count as "collection" for the
  store labels and COPPA is **Luan's open call L-07** in the Privacy & Kids Compliance GDD; this GDD does not decide
  it.

### States and Transitions

| State | Entered when | Input | Leaves to |
|---|---|---|---|
| **Launching** | the process starts | none | Title (first frame, R1) |
| **Title** | launch; a return after > 30 min | `startPlay`, taps (R3); the moon to the gate | Play (start, theme ready); Gate (moon); Background |
| **Play** | a start from the Title; a return ≤ 30 min | Reveal Stage | Gate (moon or chord); Background |
| **Gate** | the moon hold or the chord (Parent Gate) | the gate's | Panel (correct); the previous state (wrong, timeout) |
| **Panel** | a correct answer | the panel's | the state the gate was opened from (close, or the panel's 60 s auto-close, K-19) |
| **Background** | the app leaves the foreground | none | Play or Title on return (R6) |

### Interactions with Other Systems

| System | Direction | What passes |
|---|---|---|
| Settings Store | in | the launch read (R1); `childLock` for Child Lock-in |
| Key Table & Theme Data | out / in | `themeId` to load; "theme ready"; `titleCastId` (new field, Dependencies) |
| Input & Key Filter | out / in | the state (Title, Play, Inactive); in: `startPlay`, Title touches |
| Audio & Voice | out | start the engine at launch; E5 on start; background cut |
| Reveal Stage | out | enter Play; freeze / settle (through the gate); the window size and safe area; it returns the stage fit used for the Title |
| Press Queue | out (via Reveal Stage) | Play entered with an empty queue; background clear |
| Hint Letters | out | Play entered; background and return (its R9) |
| Parade | out | background (drop); memory escalation (end the walk) |
| Cast Rendering | out | draw the title creature; memory shedding (R8) |
| Child Lock-in | out | "the app is ready" (R1 step 5) |
| Parent Gate & Grown-up Panel | in / out | the gate and panel states; the silent-mode hint in the panel (R5) |
| Scene: Time of Day & Weather | out | the Title's backdrop |
| Privacy & Kids Compliance | evidence | R1 (no prompts, no network), R9 (no crash collection), L-07 |

## Formulas

**F1. Launch timeline.**
```
t_settings ≤ t_firstFrame ≤ t_ready_theme     (the Title can show before the theme is ready)
t_ready    = max(t_firstFrame, t_chordInstalled, t_kioskModeOn, t_windowCoversDisplay)     (Mac)
t_kiosk    ≥ max(t_ready, t_appActive, t_childLockActiveOn)          (Child Lock-in R3; childLock true)
t_playable = t_ready_theme
```
The read is a few milliseconds (Settings Store R5). Device times are NOT ASSESSED (Cast Rendering's measurement
plan covers the theme load).

**F2. Play-button breathe.**
```
scale(t) = 1 + k · 0.04 · sin(2π · title_breathe_hz · t)       k = 1, or 0.5 with Reduce Motion
```
`title_breathe_hz` 0.38 (the one-shot's `sin(2.4t)`). Example: t = 0.66 s (a quarter period) → 1.04; with Reduce
Motion 1.02.

**F3. Return after the background.**
```
away   = t_return − t_background          (continuous monotonic clock, in memory)
target = (away > title_after_s) ? Title : Play
```
Examples with `title_after_s` = 1800 s: away 10 min → Play; away 31 min → Title; the iPad slept 8 h → Title.

**F4. Memory escalation.**
```
level = (t_warning − t_previousWarning ≤ memory_escalate_s) ? 2 : 1
```
Level 1 sheds R8 steps 1–3; level 2 also the parade. Example: warnings at 100 s and 120 s → the second is level 2;
at 100 s and 140 s → both level 1.

## Edge Cases

| Case | What happens |
|---|---|
| **A letter pressed during the launch screen** | No handler yet; nothing happens. Once the Title shows, keys work (R3). |
| **A start while the theme loads** | Chime and lit button at once; Play when ready; extra starts absorbed (R3). |
| **The stored theme fails at launch** | Dinosaurs loads in memory, the stored id is kept (Key Table §5); the Title shows Dinosaurs' title creature. |
| **A tap on the moon on the Title** | Goes to the Parent Gate, not a start (R3). |
| **The gate opened from the Title** | Correct → panel; closing it returns to the Title (R5). |
| **Back after 29 min / after 31 min** | Play with the settled creature / the Title (R6, F3). |
| **The iPad slept overnight with the app open** | Away is counted on the continuous clock → the Title (R6). |
| **The process was ended while in the background** | A cold launch: the Title (R6). |
| **A theme changed in the panel, then a return to the Title** | The Title shows the new theme's title creature. |
| **Split View makes the window narrow or portrait** | Contain-and-extend; more sky and ground; the reveal continues (R7). |
| **The Mac window resized below the minimum** | Not possible; the window stops at 960 × 540 pt (R7). |
| **The kiosk is on and the grown-up tries to resize or leave full screen** | The kiosk keeps it full screen (Child Lock-in). |
| **Child lock turned off in the panel, app relaunched** | The kiosk comes back once the app is ready (K-21). |
| **A crash with the kiosk on** | The OS ends the app; whether the Mac is then usable at once is NOT ASSESSED (Child Lock-in's `kill -9` test); the next launch engages the kiosk only after the app is ready (R9). |
| **Two memory warnings 20 s apart during a parade** | The second ends the parade (counted as played) and frees its figures (R8). |
| **A memory warning during a late-art wait** | The current creature is never shed; its load continues (R8). |
| **Reduce Motion on the Title** | The button breathes at half amplitude; the creature's idle softens (Cast Rendering). |

## Dependencies

- **Upstream:** Reveal Stage (`design/gdd/reveal-stage.md`: the stage fit, Play, freeze and settle); Settings Store
  (`design/gdd/settings-store.md`: the launch read, `childLock`, R8).
- **Also reads or drives:** Key Table & Theme Data (theme load, the launch fallback, `titleCastId`); Input & Key
  Filter (Title, Play and Inactive states, `startPlay`); Audio & Voice (E5, the engine start, the background cut);
  Hint Letters (Play entry, background, R9); Parade (background, memory); Cast Rendering (the title creature,
  memory shedding); Child Lock-in (the kiosk after the app is ready); Parent Gate & Grown-up Panel (the gate,
  panel and the silent-mode hint); Scene (the Title backdrop).
- **Follow-ups for other GDDs (not edited here):**
  - **Key Table & Theme Data:** a theme field `titleCastId` (Dinosaurs: the T-Rex; K-22), validated at build (the
    leader has sent it to game-art-content).
  - **Parent Gate & Grown-up Panel:** the static silent-mode hint in the panel (R5); the gate can be opened from
    the Title, and closing the panel returns there.
  - **Privacy & Kids Compliance:** the continuous clock for "away" (R6) and its required-reason entry (PKC-09);
    OS crash reports stay L-07.
  - **Child Lock-in:** the "app is ready" signal from R1 step 5.
- **Decisions:** K-10, K-12, K-13, K-15, K-18, K-20, K-21, K-22.

## Tuning Knobs

| Knob | Value | Safe range | Source | Effect |
|---|---|---|---|---|
| `title_after_s` | 1800 s (30 min) | 300–7200 | K-22 | how long away before the Title greets again |
| `title_breathe_hz` | 0.38 Hz, ±4% | ≤ 1 Hz, 0–8% | one-shot | the play button's breathe |
| play button position | (640, 520) | inside the safe stage | one-shot | where the door is |
| launch screen colour | `#46558f` | a sky mid colour | **proposal** | the frame before the first frame |
| `mac_min_window` | 960 × 540 pt | 800 × 450 – 1280 × 720 | **proposal** | the smallest Mac window |
| `memory_escalate_s` | 30 s | 10–120 | proposal | when a second warning also sheds the parade |

## Acceptance Criteria

Logic tests use injected clocks and fakes for the Settings Store, Key Table, Audio, Reveal Stage, Hint Letters,
Parade and Child Lock-in. Screenshots are retained in `production/qa/evidence/`.

1. **AC-1 Launch order:** an instrumented launch logs the settings read before the first frame, the theme load
   started after the read, and "playable" only after "theme ready".
2. **AC-2 First frame:** at 06:30, 12:00, 17:00 and 21:00 (injected clock) the first frame is the matching look
   (screenshots), with no text on screen.
3. **AC-3 Mac kiosk order:** with `childLock` stored true, the kiosk options are applied only after the first frame,
   the chord handler, Input's kiosk-on mode **and the window covering its display** (a test seam logs each, in that
   order, before the options); ⌃⌥⌘Q opens the gate right after. The gate and panel open as overlays in the same
   window (no window resigns key).
4. **AC-4 K-21:** child lock turned off in the panel, then a relaunch: the kiosk engages again once ready.
5. **AC-5 Title starts:** D, 7 and a tap at (200, 200) each start play; Space, Esc and a tap on the moon do not.
6. **AC-6 Not reveal 1:** after a start by D, the Press Queue has no current and an empty queue; D's repeat and up
   make no press; the next D down is reveal 1.
7. **AC-7 Pending start:** with a seam delaying the theme load by 2 s, a start at 0.1 s plays E5 at once and enters
   Play exactly once, at 2.0 s; starts at 0.5 s and 1.0 s change nothing.
8. **AC-8 Return (F3):** away 10 min → Play with the settled creature and three fresh hints; away 31 min → the
   Title; a simulated 8 h sleep (continuous clock advanced, uptime not) → the Title.
9. **AC-9 Cold launch:** after the process is ended in the background, the next launch shows the Title with
   nothing restored.
10. **AC-10 Windows (screenshots):** an iPad full screen in both landscape directions, a Split View narrow window and
    Stage Manager; a Mac window at the minimum, at full screen and with the kiosk on: the safe stage is always
    whole and inside the safe area.
11. **AC-11 Memory (F4):** a warning sheds prefetched, leaving and list textures in that order, never the current
    creature or the decoded audio; a second within 30 s also ends a walking parade, counted as played.
12. **AC-12 No collection (scan):** the API scan finds no crash reporter, MetricKit subscriber, diagnostics upload,
    review prompt, tracking prompt or launch-time permission prompt (PKC-01, 02, 05, 09).
13. **AC-13 Device (NOT ASSESSED):** launch-to-first-frame and launch-to-playable times on a real iPad and Mac.

**NOT ASSESSED:** device launch times; iPadOS multitasking behaviour on a real device; L-07 (Luan's call).

## Open Questions

- None open for Luan.
- **Decided (Luan, K-22, 2026-11-18):** more than 30 min away → the Title, otherwise Play; any tap except the moon
  (and any letter or digit key) starts play; no text on the Title; one title creature per theme (`titleCastId`).
- **Chosen by the author (proposals in Tuning Knobs):** the launch-screen colour, the Mac minimum window, the
  memory escalation window, and measuring "away" on the continuous (sleep-inclusive) clock so K-22's 30 min also
  counts device sleep.
- **Open elsewhere:** L-07, OS crash reports vs "collection" (Privacy & Kids Compliance, Luan).
</content>
</invoke>
