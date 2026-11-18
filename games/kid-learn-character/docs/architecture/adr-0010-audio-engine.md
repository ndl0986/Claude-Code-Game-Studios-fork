# ADR-0010: Audio engine (session, AVAudioEngine graph, no-click cuts, interruptions)

## Status

Proposed (TASK-087, 2026-11-18). **Acceptance waits for the device rows P-1, P-7, P-8, P-9 and M-14** (Decision
rule below); the decision rule is fixed now, before any row runs.

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**

## Date

2026-11-18

## Last Verified

2026-11-18, against Audio & Voice (R1–R8, F1–F6, AC-9, AC-13–AC-16, AC-20, AC-21), ADR-0001, ADR-0002 (D3, D6
`AudioOutput`, D7 chain 2), ADR-0003 (D5, D6), ADR-0006 (D3), decisions K-13, K-33, K-34, K-36, the TASK-075 spike
plan, the device-checks plan (P-1, P-7, P-8, P-9, M-14), the Xcode 27.1 SDK headers (Sources) and the headless
offline-render check (Validation, H-1).

## Decision Makers

Luan (accepts, after the rows); game-dev-ios (author, TASK-087); game-dev-android (independent review, as for
ADR-0006); game-qc-ios (checks the rows and evidence pointers against the device-checks plan); game-leader.

## Summary

Audio & Voice fixed what must be heard (the event table, 7 players on 4 buses, no click on a cut, silent mode, the
gate freeze); ADR-0002 fixed the `AudioOutput` seam. This ADR fixes the Apple adapter behind it: a `.soloAmbient`
session, one `AVAudioEngine` graph built and started once, primed PCM buffers scheduled off the main thread, **a cut
that fades the player's own mixer and stops it only once silent** (a hard stop measurably clicks), the freeze as the
same fade around pause, and the session and engine notifications, including **iPadOS 27's replacements for the
deprecated interruption notification**. The device numbers (latency, clicks on a real speaker, interruptions, silent
mode) are pending rows with pass/fail rules fixed here. It is TTS-engine-agnostic (K-33 open; K-36).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | None from the template's table (ADR-0001, K-28). Swift 6.4, Xcode 27.1, SDKs iOS 27.1 / macOS 27.0, deployment 26 |
| **Domain** | Audio |
| **Layer** | Platform adapter (app target), behind `KidCore`'s audio plan |
| **Knowledge Risk** | HIGH for device latency and session behaviour (rows pending); MEDIUM for the mixer's volume smoothing (measured offline, not documented) |
| **References Consulted** | `docs/engine-reference-local/native-apple/` (`modules/avfaudio.md`, `current-best-practices.md`, `deprecated-apis.md`); the SDK headers below; TASK-033 measurements; `prototypes/DeviceSpike` (TASK-078) |
| **Post-Cutoff APIs Used** | `AVAudioPlayerNode.playAudio()` (27.0; `play()` deprecated in 27), `AVAudioSession.didBecomeInactiveNotification` and `.resumptionRecommendationNotification` with `DeactivationContext` / `ResumptionContext` (iOS 27.0; `interruptionNotification` deprecated in 27): to be proven on the iPad by P-8 |
| **Verification Required** | Validation H-1–H-3 (headless), the rows P-1, P-7, P-8, P-9, M-14 |

### Sources (Xcode 27.1 SDK headers, read 2026-11-18)

Apple's documentation pages render with JavaScript and could not be fetched as text; the SDK headers carry the same
abstracts and the availability markers, and are quoted instead (`iPhoneOS27.1.sdk`, `AVFAudio.framework/Headers`
unless noted).
- `AVAudioSessionTypes.h`, `AVAudioSessionCategoryAmbient`: "Use this category for background sounds such as rain,
  car engine noise, etc. Mixes with other music." `AVAudioSessionCategorySoloAmbient`: "Use this category for
  background sounds. Other music will stop playing." Both `API_UNAVAILABLE(macos)`. *The header says nothing about the
  silent switch*; that `.soloAmbient` is silenced by silent mode stays **unsourced here** and is proved by P-9.
- `AVAudioPlayerNode.h`, `AVAudioPlayerNodeBufferInterrupts`: "The buffer interrupts any buffer already playing."
  `stop`: "Clear all of the node's previously scheduled events and stop playback." `play`:
  `API_DEPRECATED_WITH_REPLACEMENT("playAndReturnError:", ios(8.0, 27.0), …, macos(10.10, 27.0))`;
  `playAndReturnError:` is `NS_SWIFT_NAME(playAudio())`, `API_AVAILABLE(macos(27.0), ios(27.0))`.
- `AVAudioEngine.h`, `AVAudioEngineConfigurationChangeNotification`: "When the engine's I/O unit observes a change to
  the audio input or output hardware's channel count or sample rate, the engine stops itself … and issues this
  notification. The nodes remain attached and connected with previously set formats." And: "the engine must not be
  deallocated from within the client's notification handler because the callback happens on an internal dispatch
  queue". On `mainMixerNode`: "If the client has never explicitly set the connection format between the
  mainMixerNode and the outputNode, the engine will always set/update the format to track the format of the
  outputNode on (re)start".
- `AVAudioSessionTypes.h`, `AVAudioSessionInterruptionNotification` and `AVAudioSessionInterruptionOptionShouldResume`:
  `API_DEPRECATED("Use AVAudioSessionDidBecomeInactiveNotification and AVAudioSessionResumptionRecommendationNotification
  instead", ios(6.0, 27.0) …)`. `AVAudioSessionDidBecomeInactiveNotification` (ios 27.0): "Notification sent when the
  audio session becomes inactive", with an `AVAudioSessionDeactivationContext` (`source`: `App` or `System`).
  `AVAudioSessionResumptionRecommendationNotification` (ios 27.0): "Notification sent when the system provides a
  resumption recommendation", with an `AVAudioSessionResumptionContext` whose `recommendation` is `ShouldResume` or
  `ShouldNotResume`.
- `AVAudioSessionTypes.h`, `AVAudioSessionMediaServicesWereResetNotification`: "In the event that the server restarts,
  take appropriate steps to re-initialize any audio objects used by your application." `RouteChangeReason
  OldDeviceUnavailable`: "The old device became unavailable (e.g. headphones have been unplugged)."
- `AVAudioSession.h`, `setPreferredIOBufferDuration:`: "The preferred hardware IO buffer duration in seconds. The
  actual IO buffer duration may be different."
- `AudioToolbox.framework/Headers/AUComponent.h`, `kAudioUnitSubType_PeakLimiter` (`'lmtr'`): "A peak limiter"
  (in the iOS SDK; built and run on macOS by H-1 and on the iPad Simulator by TASK-078).
- `AVAudioEngine.h`, `AVAudioEngineManualRenderingModeOffline`: "The engine operates in an offline mode without any
  realtime constraints" (used by H-1).

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Accepted); ADR-0002 (Accepted: D3 uptime clock, D6 `AudioOutput`, D7 chain 2); ADR-0003 (Accepted: D5 decoded durations and loudness, D6 TTS pre-render); ADR-0006 (Accepted: D3, the frame AC-16 measures against) |
| **Enables** | The Audio & Voice adapter story; P-1's candidate run; the production re-runs of Audio AC-9, AC-15, AC-16, AC-20 |
| **Blocks** | The audio adapter story (it implements D1–D9) |
| **Ordering Note** | First of the four ★ spike ADRs (TASK-075 order: 0010 → 0009 → 0007 → 0008) |

## Context

### Problem Statement
`KidCore` plans what sounds and when (Audio & Voice R1–R3, F1–F6); `AudioOutput` (ADR-0002 D6) is the seam:
`play(event)`, `duck(bus, to, over)`, `pause()`, `resume()`, `cut(player, fade)`, `setGain(Double)`. What remains is
the Apple adapter: the session, the graph, how a sound starts within one frame of the press, how any sound stops
without a click, and what happens on interruptions, route changes and resets. TASK-033 measured only Mac and
Simulator estimates; the session behaviour was NOT SOURCEABLE (architecture.md, HIGH risk).

### Constraints
- Offline, no third-party audio code (PKC-03); AVFAudio only (ADR-0001).
- Deployment 26 with the 27 SDKs: two APIs this ADR needs are deprecated in 27 with 27-only replacements.
- The child's iPad model and iPadOS version are not yet known (device-checks plan, F-1).
- TTS engine undecided (K-33); espeak-ng only on the build machine (K-36).

### Requirements
- Nothing created, stopped or reconnected on a press (Audio R2.1, AC-10); at most 7 sounds.
- Chime onset within one display frame of the first answering frame on the iPad (AC-16).
- No discontinuity above −60 dBFS on any cut, mute, panel, freeze or headphones-out (AC-9, AC-21).
- Silent mode silences the toy and other apps' music stops (R6, AC-20).
- Recovery from interruptions, route and configuration changes, media-services reset (R6, AC-15).

## Decision

### D1. Session (iPadOS)
- Category **`.soloAmbient`**, mode `.default`, no options (Audio R6: silent mode respected; other music stops, per
  the header). `.ambient` mixes and `.playback` ignores silent mode (Alternatives).
- Set once at launch, then `setActive(true)`, **before** the engine starts (R6: silent start; nothing is scheduled
  until the first input).
- `setPreferredIOBufferDuration(0.005)`: a request ("the actual … may be different"); the actual
  `ioBufferDuration` and `outputLatency` are logged once at start and in every P-1 run.
- The sample rate is not set: the graph follows the hardware (D2).
- macOS has no session: the engine follows the default output device (D8).

### D2. The graph, built and started once
```
player(voice) ─ gate ─┐
player(cast)  ─ gate ─┤ bus mixers: voice 0 dB, cast −4, ui −10, music −8 (F1 g_bus)
player(ui)×4  ─ gate ─┤      └─▶ submix ─▶ PeakLimiter ('lmtr', ceiling F1/R4.5) ─▶ mainMixerNode ─▶ output
player(music) ─ gate ─┘                                     (g_master × g_head, F1; mute)
```
- 7 `AVAudioPlayerNode`s (Audio R2.1 table), each into **its own `AVAudioMixerNode` (the gate)**, then its bus mixer.
  The gate is what D5 fades; the bus mixer carries the bus trim and the duck (D6).
- Player → gate → bus connections use **mono float at the output's sample rate**; the `mainMixerNode → output`
  connection is **never set explicitly**, so the engine tracks the output format on every (re)start (header).
- Built, `prepare()`d and started at launch; every player is started once (`playAudio()` on 27, `play()` on 26) and
  **keeps running** (R2.1). Nothing is attached, detached, connected, stopped or created on a press (AC-10).

### D3. Buffers
- Decoded at theme load, off the main thread, to PCM at the output's sample rate, mono (R4.1–R4.2; AC-11): the theme
  becomes Active only then. Fixed sounds (chime, ping, twinkle, parade tune) once at start-up.
- A **priming generation** counter: on a format change (D8) every buffer is converted again off the main thread;
  until the new generation is ready, `play(event)` skips and logs (R4.4; AC-15).
- Durations come from ADR-0003 D5 (`voiceDurations`, priming removed); the adapter never measures them at run time.

### D4. Scheduling (`AudioOutput.play`)
- The main thread only posts the event (R4.3); one **serial audio queue** (QoS `.userInteractive`) does all graph
  work: scheduling, gates, ducks, freeze, restarts.
- An **idle** player (the ui pool picks an idle one first; voice, cast and music have one each) gets
  `scheduleBuffer(buffer, at: nil, options: .interrupts)` at once; its gate is already at 1.
- A **busy** player (a replacement: E6 over a line, E8/E10/E11 on the cast player, or the ui pool's steal of the
  oldest, R2.5) is **cut first (D5) and the new buffer scheduled when the cut completes**: such a sound starts up to
  `cut_settle_s` (40 ms) late. `.interrupts` alone on a sounding player is a hard switch and clicks (H-1).
  AC-16's single press always finds an idle ui player, so it pays nothing.
- Busy is tracked by the adapter (scheduled length from D3), not by asking the node.

### D5. The cut, without a click (`AudioOutput.cut`; R2.2, AC-9)
- **Never** `stop()`, `pause()` or `.interrupts` a player while it sounds: H-1 measured −38.7 dBFS discontinuities for
  all three (threshold −60).
- Cut = set that player's **gate** `outputVolume` to 0; the mixer smooths the change itself (H-1: the output falls below
  −60 dBFS **≈ 27 ms** after a jump to 0, with no discontinuity above the clean tone's floor, −76 dBFS); after
  **`cut_settle_s` = `cut_fade_s` + 0.01 s** (0.04 s with Audio's 0.03) `stop()` the player, restart it, and set the
  gate back to 1 (silent then, so no smoothing matters).
- If Audio ever sets `cut_fade_s` above the mixer's smoothing, the gate is stepped toward 0 over `cut_fade_s` in steps
  of one IO period (≤ 5 ms); each step is smoothed (H-1: a 30 ms stepped ramp also passes).
- **Mute** (R5, AC-14): the main mixer's volume to 0 (smoothed the same way) and D5 cuts on the voice and cast players.
  **Volume and the slider preview**: `setGain` sets the main mixer to F1's `g_master × g_head`, stepped over
  `cut_fade_s` when the change is large.
- **The panel, background, headphones out, theme switch** use the same cut.

### D6. Ducking (F2)
- The cast and music **bus** mixers are stepped along F2's dB-linear ramp (`duck_attack_s`, `duck_release_s`) in steps
  of one IO period on the audio queue; the mixer's smoothing rounds the steps. The ui bus is never ducked.

### D7. The gate freeze (`AudioOutput.pause` / `resume`; R6, AC-21; ADR-0002 D7 chain 2)
- `pause()`: every gate to 0; after `cut_settle_s`, `pause()` every player. `resume()`: `playAudio()` / `play()` every
  player, then every gate to 1 (the mixer smooths the rise, ≈ 27 ms).
- Consequence: a paused sound continues from **≈ `cut_settle_s` after** the freeze moment (that much of it was faded,
  not heard). AC-21's "continues from where it paused" holds within 40 ms; the plan's play clock, not the adapter,
  keeps new events from starting (R6).
- The engine keeps running through a freeze; only the background pauses the engine (D8).

### D8. Session and engine notifications
All handlers hop to the audio queue; none deallocates the engine (header).

| Event | iPadOS 27 + | iPadOS 26 | macOS | Action |
|---|---|---|---|---|
| Interruption begins | `didBecomeInactiveNotification` (`source` `.system`) | `interruptionNotification` `.began` | — | the engine has stopped; mark not running |
| Interruption ends | `resumptionRecommendationNotification` `.shouldResume` | `.ended` + `.shouldResume` | — | `setActive(true)`, restart the engine and players, re-prime if the format changed; else restart on the **next press** (R6; that press's chime may be late or skipped, logged) |
| Configuration change | `AVAudioEngineConfigurationChange` | same | same (output device change) | the engine stopped itself: restart; re-prime when the output format changed (D3) |
| Route: old device unavailable | `routeChangeNotification` `.oldDeviceUnavailable` | same | (config change) | D5 cut on voice and cast; nothing jumps to the speaker mid-line |
| Media services reset | `mediaServicesWereResetNotification` | same | — | rebuild the whole graph (D2), re-prime (D3) |
| Background / foreground | app lifecycle (ADR-0002 D6) | same | same | D5 cut on every player, then `engine.pause()`; on return, as "interruption ends" |
Which notification is observed is chosen with `if #available(iOS 27, *)`; the deprecated one is not observed on 27.

### D9. Latency target and what P-1 measures (AC-16)
- "Within one display frame of the first answering frame": the chime's acoustic onset no more than one display period
  (16.7 ms at 60 Hz, ADR-0006 D3) after the first frame that draws the press's answer, on built-in or wired output,
  filmed at 240 fps with the TASK-033 procedure. Bluetooth is NOT ASSESSED.
- The adapter logs, per press in debug builds: the event's uptime stamp, the hand-off to the audio queue, the schedule
  call, and the session's `ioBufferDuration` and `outputLatency`, so a failing P-1 can be split into its parts.

### D10. Voice source: engine-agnostic (ADR-0003 D6; K-33, K-36)
- The adapter plays decoded files by line id; it does not know or care how a line was made. No speech synthesis at
  run time, no TTS library linked (Audio R8). Which TTS engine renders the files is ADR-0003 D6's and K-33's (open);
  espeak-ng, if used, runs only on the build machine (K-36). Swapping TTS for a recorded voice changes files only.

### Decision rule (fixed before the rows run)
| Row | Pass (decides this ADR) | If it fails |
|---|---|---|
| **P-1** latency, candidate graph on `DeviceSpike` (and the TASK-033 no-Rive baseline) | every measured press: chime onset ≤ 1 display period after the first answering frame (AC-16, the TASK-033 procedure's presses) | if the **baseline** passes and the candidate fails: the extra stages are suspect: remove the per-player gates for the ui pool (cut ui sounds only by letting them end; they are ≤ 0.4 s), re-run; if both fail: raise to Luan with the split from D9's logs (IO buffer, output latency, scheduling); the ADR then records the measured figure and AC-16 goes back to Audio & Voice |
| **P-7** no click, iPad speaker and headphones-out | no discontinuity above −60 dBFS in the capture (H-1's detector on the capture) and no click heard | replace the gate fade with a per-sample gain ramp (Alternative 4) and re-run H-1 and P-7 |
| **M-14** no click, Mac speaker | as P-7 | as P-7 |
| **P-8** interruptions, route change, reset | the next press after each chimes (after re-priming), no crash; the log shows **which** interruption notification fired on the iPad's OS version | fix the handlers (not a design change); if the 27 replacements do not fire on iPadOS 27, observe the deprecated one there too and record it |
| **P-9** silent mode | no sound for any event; other app's music stops | `.soloAmbient` is the only category that both obeys silent mode and does not mix (D1, Alternatives); a failure goes to Luan (R6 is his decision Q4) |
Acceptance needs all five rows passing, or Luan accepting a recorded exception.

### Architecture Diagram
```
KidCore audio plan ──AudioOutput (ADR-0002 D6)──▶ AudioAdapter (app)
   main thread: post only                              │ serial audio queue
                                                       ▼
   session (D1) ─ engine graph (D2) ─ buffers (D3) ─ schedule (D4) ─ gates: cut (D5), freeze (D7) ─ ducks (D6)
                                ▲
             notifications (D8) ┘
```

### Key Interfaces
| `AudioOutput` (ADR-0002 D6) | Apple adapter |
|---|---|
| `play(event)` | D4: idle player → schedule now; busy → D5 cut, then schedule |
| `cut(player, fade)` | D5 gate fade, settle, stop, gate back to 1 |
| `duck(bus, to, over)` | D6 bus-mixer steps |
| `pause()` / `resume()` | D7 |
| `setGain(Double)` | D5 mute/volume on the main mixer |

### Implementation Guidelines
- One adapter type owns the engine; nothing else touches AVFAudio. All of it compiles in the app target only.
- Branch the two deprecations with `#available(iOS 27, macOS 27, *)`; no deprecated call on 27.
- Debug builds log one line per press (D9) and per notification (D8); release builds log no child input (PKC-14).
- Keep `prototypes/DeviceSpike/tools/offline-cut-check.swift`'s detector as the adapter story's headless test for
  AC-9 and AC-21 (rewritten to production standards, not copied).

## Alternatives Considered

### Alternative 1: `AVAudioPlayer` per sound
- **Rejected**: it creates and prepares a player per sound (AC-10 forbids it), and TASK-033 measured 3–10 ms per start.

### Alternative 2: `.ambient` or `.playback`
- **Rejected**: `.ambient` mixes with other music (header), against R6's "no other app's audio is mixed in";
  `.playback` is the category for music that is not meant to be silenced by the switch (unsourced here; R6 forbids
  ignoring silent mode).

### Alternative 3: Cut with `stop()`, `pause()` or `.interrupts` directly
- **Rejected**: H-1 measures −38.7 dBFS discontinuities, 21 dB over AC-9's −60.

### Alternative 4: A per-sample gain ramp (an `AVAudioSourceNode` or a fade written into a copy of the buffer)
- **Kept as the fallback** if P-7 or M-14 hears a click: exact and independent of the mixer's undocumented
  smoothing, but more code on the render thread.

### Alternative 5: Scheduling on the main thread
- **Rejected**: 3–10 ms of the frame (TASK-033, ADR-0001); R4.3.

## Consequences

### Positive
- No click by construction, with a headless check that runs on every build.
- Nothing on the press path but `scheduleBuffer` on an idle player.

### Negative
- A replacement on a busy player starts up to 40 ms late; a resumed sound loses ≤ 40 ms (D7).
- The no-click mechanism leans on the mixer's volume smoothing, which Apple does not document (Risks).
- Two code paths for interruptions (iPadOS 26 and 27).

### Neutral
- The TTS choice stays out of this ADR (D10).

## Risks
- **The mixer's smoothing changes or differs on the device.** Mitigation: H-1 runs in CI-local builds; P-7 and M-14
  listen on the speakers; Alternative 4 is ready.
- **The iOS 27 resumption notifications behave differently from the deprecated one.** Mitigation: P-8 logs which
  fired; D8's fallback.
- **The IO buffer request is not honoured** (larger buffer, more latency). Mitigation: D9 logs the actual values; the
  decision rule's split.
- **Bluetooth latency** is not held to AC-16 (Audio AC-16; NOT ASSESSED).

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| audio-voice.md R2, AC-5, AC-10 | TR-audio-001: fixed players, nothing created on a press, ≤ 7 sounds | D2, D4 |
| audio-voice.md R2.2, AC-9, AC-14 | no click on a cut, mute, volume | D5, H-1; rows P-7, M-14 |
| audio-voice.md R3, R4.5, F1, AC-13 | mash ceiling and limiter | D2 (limiter, trims); F1 on the main mixer |
| audio-voice.md R4, AC-11, AC-15 | decode at load, output format, re-prime | D3, D8 |
| audio-voice.md R6, AC-15, AC-20, AC-21 | session, interruptions, silent mode, freeze | D1, D7, D8; rows P-8, P-9 |
| audio-voice.md AC-16 | TR-audio-002: chime within one frame | D4, D9; row P-1 |
| audio-voice.md F2 | ducking | D6 |
| audio-voice.md R8; ADR-0003 D6 | voice source, no run-time TTS | D10 |

## Performance Implications
- **CPU**: 7 players, 12 mixers (7 gates, 4 buses, the submix) plus the main mixer, and one limiter run continuously at the IO rate (measured on the Mac by M-14's session;
  iPad by P-1's thermal note).
- **Memory**: decoded PCM per Audio F5; nothing allocated on a press.
- **Latency**: the IO buffer (requested 5 ms) plus output latency, logged (D9).
- **Network**: none.

## Migration Plan
None: no audio code exists in `apple/`. `prototypes/DeviceSpike`'s `AudioSpike` implements D1–D8 as a spike; the
adapter story rewrites it to production standards.

## Validation Criteria
Per K-34: headless runs need no MAC FREE; anything on the Mac's screen or speakers does.

**Headless (done or runnable now):**
- **H-1 Offline cut check** (`prototypes/DeviceSpike/tools/offline-cut-check.swift`, `AVAudioEngine` offline manual
  rendering, the D2 chain with the Apple limiter): a 100 Hz tone at −1 dBFS cut at 300 ms; detector = the largest
  second difference of the output (the clean tone's floor is −76 dBFS; AC-9's threshold −60 dBFS). Results
  (2026-11-18, macOS 27; output in `production/qa/evidence/TASK-087/<sha>/offline-cut-check.txt`):

  | Mechanism | Largest discontinuity | Verdict |
  |---|---|---|
  | hard `stop()` | −38.7 dBFS | FAIL |
  | `.interrupts` on a busy player (a new buffer replaces a sounding one) | −38.7 dBFS | FAIL |
  | `pause()` / play at once (a naive freeze) | −38.7 dBFS | FAIL |
  | gate to 0, `pause()` only 10 ms later (smoothing not finished) | −43.1 dBFS | FAIL |
  | gate to 0 at once (below −60 dBFS after 26.8 ms) | −76.3 dBFS (the floor) | PASS |
  | 30 ms stepped ramp, 5 ms or 1 ms steps | −76.3 dBFS (one earlier run −62.7) | PASS |
  | **D5 cut**: gate to 0, settle 40 ms, `stop()`, gate to 1 | −76.3 dBFS | **PASS** |
  | **D7 freeze / resume**: gate to 0, settle 40 ms, `pause()`; 100 ms later play, gate to 1 | −76.3 dBFS | **PASS** |

  These three FAILs, 21 dB over AC-9's −60 dBFS, are the measured reason for D5 and D7 and for Alternative 3's
  rejection. Offline rendering is deterministic up to the mixer's internals; the 1 ms-step ramp varied between
  −62.7 and −76.3 dBFS across runs, still under the threshold.
- **H-2 Build:** `DeviceSpike` with `AudioSpike` implementing D1–D8 (the gate cut, the freeze, the iOS 27 branches)
  builds for iOS Simulator and macOS with no warnings (2026-11-18, this ADR's sha). Its minimal spike check runs
  before each install (TASK-078 `tools/device-build.sh`).
- **H-3 Simulator smoke** (dev simulator, headless): the Audio screen opens; the engine logs its rate, IO buffer and
  output latency (TASK-078). Simulator timings are never evidence.

**Device rows (pending; the decision rule above):** P-1 (`ipad-1/P-1/`), P-7 (`ipad-1/P-7/`), P-8 (`ipad-1/P-8/`),
P-9 (`ipad-1/P-9/`), M-14 (`mac-1/M-14/`), as in `production/qa/device-checks-plan.md`.

## Related
- ADR-0001; ADR-0002 (D6 `AudioOutput`, D7 chain 2); ADR-0003 (D5, D6); ADR-0006 (D3).
- Audio & Voice GDD; Key Table & Theme Data (V15); Press Queue (F1, the hold).
- `production/team/TASK-075-spike-plan.md` (ADR-0010 section); `production/qa/device-checks-plan.md`.
- `docs/engine-reference-local/native-apple/modules/avfaudio.md` (updated with the Sources above).
