# Architecture Traceability Index
Last Updated: 2026-11-18
Engine: none configured (native Swift 6.4 / SpriteKit / SwiftUI, ADR-0001); engine validation NOT ASSESSED
Source: `docs/architecture/architecture-review-2026-11-18.md` (Mode: full, TASK-111). IDs are permanent and live in `docs/architecture/tr-registry.yaml`.

## Coverage Summary
- Total requirements: 83 (17 GDDs)
- Covered (Accepted ADR): 59 (71%)
- Covered (Proposed ADR only): 16 (19%)
- Partial: 6 (7%)
- Gaps: 2 (2%)

Status key: **Covered** = an Accepted ADR decides it. **Covered (Proposed)** = only a Proposed ADR decides it (caps the verdict at CONCERNS; route out: `/architecture-decision accept ADR-NNNN`). **Partial** = ambiguous or incomplete. **GAP** = no ADR.

## Full Matrix

| TR-ID | GDD | Layer | Requirement | ADR coverage | Status | Note |
|---|---|---|---|---|---|---|
| TR-input-001 | input-key-filter.md | Foundation | Classify normalized key events: character first, position fallback, modifiers, held set, chord (R2-R6) | ADR-0002 D5; ADR-0004 input-filter-v2 | Covered |  |
| TR-input-002 | input-key-filter.md | Foundation | Touch layers, batch sort and hint hit radius (R7, F1) | ADR-0002 D6; ADR-0004; ADR-0006 D7 | Covered |  |
| TR-input-003 | input-key-filter.md | Foundation | Kiosk command-key exception and the Mac chord under kioskModeOn (R5, R6) | ADR-0002 D7; ADR-0007 D3 (Proposed) | Covered (Proposed) | chord logic is Accepted (ADR-0002); the AppKit monitor and key-state read rest on ADR-0007 |
| TR-input-004 | input-key-filter.md | Foundation | Platform adapters: UIKit presses and AppKit key monitor produce normalized events; HID position map; Input Monitoring prompt (AC-1k6) | ADR-0007 (Proposed) | Covered (Proposed) | device rows M-1, M-2, M-3, P-15 pending |
| TR-input-005 | input-key-filter.md | Foundation | Only letters and digits count; held keys, repeats and all other keys swallowed, system keys untouched (R4, R5) | ADR-0002 D5; ADR-0004 input-filter-v2; ADR-0007 D2/D3 | Covered | logic Accepted; adapter disposition in ADR-0007 |
| TR-keytable-001 | key-table-theme-data.md | Foundation | Bundled themes validated at build and at load; unknown versions refused (V1-V17, sections 5-6) | ADR-0003 D2/D3; ADR-0004 key-table-schema-v1 | Covered |  |
| TR-keytable-002 | key-table-theme-data.md | Foundation | Item pick with no immediate repeat; peek for prefetch (section 4) | ADR-0002 D4; ADR-0004 | Covered |  |
| TR-keytable-003 | key-table-theme-data.md | Foundation | Data-driven per-key database (K-07), versioned JSON schema, one validator | ADR-0001 D6; ADR-0003 D1/D2 | Covered |  |
| TR-keytable-004 | key-table-theme-data.md | Foundation | Voice and sfx pipeline: pre-rendered TTS, AAC mono, loudness target, voiceDurations from data (V12, V15) | ADR-0003 D5/D6 | Covered |  |
| TR-keytable-005 | key-table-theme-data.md | Foundation | rowWords valid with v1 fallback (V17) | ADR-0003 D2; ADR-0004 key-table-schema-v1 | Covered |  |
| TR-morph-001 | morphcore.md | Foundation | Morph positions within 1e-3 of the shared fixture on every platform | ADR-0002 D1/D2/D4; ADR-0004; morph-contract-v1 | Covered |  |
| TR-morph-002 | morphcore.md | Foundation | UI-free math; glyph and silhouette paths in the v1 SVG subset, glyphs baked from the OFL font | ADR-0001 D6; ADR-0003 D4 | Covered |  |
| TR-morph-003 | morphcore.md | Foundation | Frame time p99 within one refresh with 240 specks (AC-11) | ADR-0009 D1 (Proposed) | Covered (Proposed) | partial on the spike, passes only on the production re-run |
| TR-settings-001 | settings-store.md | Foundation | One record, atomic write, per-field validation, migration (R1-R7) | ADR-0005 D1-D3; ADR-0004 settings-record-v2 | Covered |  |
| TR-settings-002 | settings-store.md | Foundation | Device only, no sync, one app-written key (R3; PKC-01, 05, 09) | ADR-0005 D5/D6/D8 | Covered |  |
| TR-settings-003 | settings-store.md | Foundation | Settings read before the first frame (R5) | ADR-0005 D9; ADR-0004 app-shell-v1 | Covered |  |
| TR-settings-004 | settings-store.md | Foundation | childLock stored only as ON; OFF is run-only (R8, K-21); Reset removes the record (R9) | ADR-0005 D4, D2 remove() | Covered |  |
| TR-settings-005 | settings-store.md | Foundation | Same bytes on both platforms; F1 rounding, F2 gain | ADR-0004 settings-record-v2; ADR-0002 D2/D8 | Covered |  |
| TR-pkc-001 | privacy-kids-compliance.md | Foundation | No network, no SDK, no identifiers, no location (PKC-01..04) | ADR-0001 D8; ADR-0011 D5/D6 | Covered |  |
| TR-pkc-002 | privacy-kids-compliance.md | Foundation | Privacy manifest with CA92.1 / 35F9.1; entitlements allowlist (PKC-05..09) | ADR-0005 D5/D8; ADR-0011 D5 | Covered |  |
| TR-pkc-003 | privacy-kids-compliance.md | Foundation | No log call carrying input, code or accessibility state in release builds (PKC-14) | ADR-0011 D5/D6 | Covered |  |
| TR-pkc-004 | privacy-kids-compliance.md | Foundation | Scans run on signed Release products, evidence retained per release candidate | ADR-0011 D3/D5/D6 | Covered |  |
| TR-audio-001 | audio-voice.md | Core | Event schedule E1-E12, no stacking speech, mash ceiling, freeze pause (R1-R4, R6) | ADR-0002 D6/D7; ADR-0004 audio-plan-v1 | Covered | logic only |
| TR-audio-002 | audio-voice.md | Core | Press to chime within one frame of the first answering frame, on a device (AC-16) | ADR-0010 D4/D9 (Proposed) | Covered (Proposed) | device row P-1 pending |
| TR-audio-003 | audio-voice.md | Core | Fixed primed players, nothing created or decoded on a press, max 7 sounds (R2, AC-5, AC-10) | ADR-0010 D2/D4 (Proposed) | Covered (Proposed) |  |
| TR-audio-004 | audio-voice.md | Core | No click on a cut; mute and volume; limiter and mash gain F1 (R2.2, R3, R4.5, AC-9, AC-13, AC-14) | ADR-0010 D2/D5 (Proposed) | Covered (Proposed) | rows P-7, M-14 pending |
| TR-audio-005 | audio-voice.md | Core | Session category, interruptions, silent mode, route and format changes (R6, AC-15, AC-20, AC-21) | ADR-0010 D1/D7/D8 (Proposed) | Covered (Proposed) | rows P-8, P-9 pending |
| TR-audio-006 | audio-voice.md | Core | Voice source, licence and no run-time TTS (R8, Q8, L-09) | ADR-0003 D5/D6; ADR-0010 D10 | Covered | licence closed by K-41 per commit f69e3029 |
| TR-queue-001 | press-queue.md | Core | Accept, queue (max 3), ignore; holdEff; timeout (R3-R7, F1) | ADR-0002; ADR-0004 press-queue-v1 | Covered | ADR-0002 does not list press-queue.md in its GDD table; coverage is by ADR-0004 |
| TR-queue-002 | press-queue.md | Core | formed reported exactly once; Press Queue and Reveal Stage contract (R6, R7, R11) | ADR-0004 press-queue-v1, reveal-timing-v1 | Covered |  |
| TR-queue-003 | press-queue.md | Core | Gate freeze, panel and background clear and settle (R8, R9, AC-20..24) | ADR-0004 press-queue-v1; ADR-0002 D7 | Covered |  |
| TR-cast-001 | cast-rendering.md | Core | SVG subset bake tool; one baked file and one draw interface for both render options (R2, R7, R11) | ADR-0003 D1/D4 | Covered |  |
| TR-cast-002 | cast-rendering.md | Core | Load on demand, resident cap, late-art wait that never moves the queue (R10, F6, F7, AC-15) | ADR-0002 D6 ResidencySink; ADR-0009 D5 (Proposed) | Covered (Proposed) | ADR-0004 excludes F6 as dependent on ADR-0009 |
| TR-cast-003 | cast-rendering.md | Core | Per-look edge switch on skyMidL, halo, dim (F8, K-25) | ADR-0004 scene-look-v1; ADR-0009 D2 | Covered |  |
| TR-cast-004 | cast-rendering.md | Core | Render-path decision (live paths, textures or a mix) backed by a device measurement (R11, AC-17) | ADR-0009 (Proposed) | Covered (Proposed) | rows P-2, M-13 pending |
| TR-cast-005 | cast-rendering.md | Core | Draw interface carries no platform types (R12, AC-16) | ADR-0002 D6 RenderSink; ADR-0009 D2 | Covered |  |
| TR-cast-006 | cast-rendering.md | Core | Speck cap F4, 6 px rule F1, tap hop F5 as pure functions (F1, F4, F5, F7) | ADR-0004 reveal-timing-v1 | Covered |  |
| TR-cast-007 | cast-rendering.md | Core | Shipped idles at or under 1 Hz (AC-11): a build check on the data | none (ADR-0004 lists Accessibility F1 as a QC tool, not a decision) | Partial | same lint as TR-a11y-003 |
| TR-reveal-001 | reveal-stage.md | Feature | startReveal lengths, formed and shown, timeline, shared transforms (R3-R5) | ADR-0004 reveal-timing-v1 | Covered |  |
| TR-reveal-002 | reveal-stage.md | Feature | Play clock, freeze, resume, settle (R8) | ADR-0002 D3/D7 | Covered |  |
| TR-reveal-003 | reveal-stage.md | Feature | Stage fit contain-and-extend; published rects and boxes (R10, F1) | ADR-0006 D1/D2; ADR-0004 reveal-timing-v1 | Covered |  |
| TR-reveal-004 | reveal-stage.md | Feature | Fixed draw-order layers; SpriteKit scene behind RenderSink; display-link frame driver | ADR-0006 D1/D3 | Covered |  |
| TR-reveal-005 | reveal-stage.md | Feature | Reduce Motion timing set picked at start (R9) | ADR-0006 D6; ADR-0004 | Covered |  |
| TR-reveal-006 | reveal-stage.md | Feature | Tap-the-creature hop and cooldown (F6) | ADR-0004 reveal-timing-v1 | Covered |  |
| TR-hints-001 | hint-letters.md | Feature | Spawn, clearances, life, originFor, freeze and Dimmed (R2-R9, F1-F4) | ADR-0002 D4/D6; ADR-0004 hint-letters-v1 | Covered |  |
| TR-hints-002 | hint-letters.md | Feature | Hit diameter at least 18 mm from ppi, with bubble scale k (R11, F5) | ADR-0006 D7; ADR-0002 D6 DisplayMetrics | Covered |  |
| TR-hints-003 | hint-letters.md | Feature | Hint knobs data-validated at build, slots pass F4 (AC-21) | ADR-0003 D1 (data/ knob files) | Partial | ADR-0003 names the knob files but no validator rule for hint knobs or slots |
| TR-parade-001 | parade.md | Feature | Batches per theme, start rule, walk across the visible rect, own clock (R1-R8, F2, F3) | ADR-0004 parade-v1 | Covered |  |
| TR-parade-002 | parade.md | Feature | Walkers drawn at parade detail size within the resident set; art wait (AC-12, AC-18) | ADR-0009 D1/D5 (Proposed) | Covered (Proposed) |  |
| TR-gate-001 | parent-gate-panel.md | Feature | Two-step gate: moon hold, code challenge, sleep, timeout, confirm holds (G1-G10, F1) | ADR-0004 gate-logic-v1 | Covered |  |
| TR-gate-002 | parent-gate-panel.md | Feature | Challenge code from its own seeded random stream; words, never numerals | ADR-0002 D4; ADR-0004 gate-logic-v1 | Covered |  |
| TR-gate-003 | parent-gate-panel.md | Feature | Gate and panel are in-window overlays, never a separate window, sheet or popover (G11, AC-34) | ADR-0006 D1/D4 | Covered |  |
| TR-gate-004 | parent-gate-panel.md | Feature | Hardware digits and the Mac chord open and answer the gate (AC-03, AC-07) | ADR-0007 D2/D3 (Proposed) | Covered (Proposed) |  |
| TR-gate-005 | parent-gate-panel.md | Feature | Quit row follows kioskModeOn; overlays keep key; lock page shows Guided Access line (G7, G8, AC-28, AC-35) | ADR-0008 D3/D5/D7 (Proposed) | Covered (Proposed) |  |
| TR-gate-006 | parent-gate-panel.md | Feature | Panel accessibility: VoiceOver, Dynamic Type to largest size, 44 pt targets, 60 pt keypad (AC-24, AC-32, Accessibility AC-13) | ADR-0006 D6 (Reduce Motion only) | GAP | no ADR decides panel accessibility |
| TR-gate-007 | parent-gate-panel.md | Feature | Failed settings write handled; lock back ON after relaunch (AC-19, AC-33) | ADR-0005 D4; ADR-0005 Validation 1 | Covered |  |
| TR-lock-001 | child-lock-in.md | Feature | Engage only after ready + R3; never trap; engage timeout; options set (R2-R7) | ADR-0002 D6/D7; ADR-0008 D2/D5/D6 (Proposed) | Covered (Proposed) |  |
| TR-lock-002 | child-lock-in.md | Feature | iPad Guided Access instructions and observation (R8) | ADR-0001 9c; ADR-0008 D7 | Covered | baseline part Accepted in ADR-0001; ADR-0008 extends |
| TR-lock-003 | child-lock-in.md | Feature | Way out: parent chord opens the gate at any time the kiosk is on (R5) | ADR-0001 9b; ADR-0007 D3; ADR-0008 D3 (Proposed) | Covered (Proposed) |  |
| TR-lock-004 | child-lock-in.md | Feature | Extra displays covered; sleep and wake keep the lock (R6) | ADR-0008 D4/D5 (Proposed) | Covered (Proposed) |  |
| TR-lock-005 | child-lock-in.md | Feature | Kiosk full-screen mode (borderless or native) and kill -9 recovery (AC-13..17) | ADR-0006 D4; ADR-0008 D1 (Proposed) | Covered (Proposed) | rows M-3..M-7 pending |
| TR-shell-001 | app-shell-title.md | Presentation | Launch order, Title starts, pending start, ready set (R1-R6, F1) | ADR-0004 app-shell-v1; ADR-0005 D9 | Covered |  |
| TR-shell-002 | app-shell-title.md | Presentation | Away rule counts device sleep: 30 min on the away clock (R6, F3) | ADR-0002 D3 AwayClock | Covered |  |
| TR-shell-003 | app-shell-title.md | Presentation | Windows on iPad and Mac, safe stage, overlays in the main window (R7) | ADR-0006 D4 | Covered |  |
| TR-shell-004 | app-shell-title.md | Presentation | iPad status bar and home indicator hidden, edge-swipe deferral follows the gate (R7, K-39, AC-14) | ADR-0006 D4 (windows only) | Partial | no ADR names edgeDeferral, the status bar or the home indicator |
| TR-shell-005 | app-shell-title.md | Presentation | Memory-warning shedding order (F4, AC-11) | ADR-0002 D6 AppLifecycle; ADR-0004 app-shell-v1 | Covered |  |
| TR-shell-006 | app-shell-title.md | Presentation | No collection APIs; cold launch restores nothing (AC-9, AC-12) | ADR-0011 D5; ADR-0005 | Covered |  |
| TR-scene-001 | scene-time-weather.md | Feature | Wall-clock looks, lookBlend, jump fade, weather pick (R2-R9, F1, F3) | ADR-0002 D3 WallClock; ADR-0004 scene-look-v1 | Covered |  |
| TR-scene-002 | scene-time-weather.md | Feature | Weather element draw within caps and device cost F6 worst case (R3, AC-4, AC-19) | ADR-0006 D1 layer 0; ADR-0004 scene-look-v1; ADR-0009 (Proposed) | Partial | the cost is measured in ADR-0009's run, which is Proposed |
| TR-scene-003 | scene-time-weather.md | Feature | Contrast build check: 160 cases with the F8 edge model (R5, AC-5) | ADR-0004 scene-look-v1 | Covered |  |
| TR-scene-004 | scene-time-weather.md | Feature | Two clocks; freeze stops elements, look follows wall clock (AC-11) | ADR-0002 D3/D7 | Covered |  |
| TR-scene-005 | scene-time-weather.md | Feature | No network, location or audio from the Scene (AC-18; K-08) | ADR-0001 D8; ADR-0011 | Covered |  |
| TR-kbrow-001 | onscreen-keyboard-row.md | Feature | Layout, hit rect, light, word draw, Due and change (F1-F4) | ADR-0004 keyboard-row-v1 | Covered |  |
| TR-kbrow-002 | onscreen-keyboard-row.md | Feature | Row words from theme data with v1 fallback (AC-16) | ADR-0003 D2 | Covered |  |
| TR-kbrow-003 | onscreen-keyboard-row.md | Feature | Row is a layer at z 35 and feeds the same press path as a touch (R12) | ADR-0001 9a; ADR-0006 D1 | Covered |  |
| TR-kbrow-004 | onscreen-keyboard-row.md | Feature | Off by default, kept in settings; hit rect at least 18 mm (AC-1, AC-3) | ADR-0005; ADR-0004 settings-record-v2; ADR-0006 D7 | Covered |  |
| TR-a11y-001 | accessibility.md | Polish | One Reduce Motion flag read live, never stored, re-read on return (A1, AC-01..04) | ADR-0002 D6 AccessibilityState; ADR-0006 D6; ADR-0005 | Covered |  |
| TR-a11y-002 | accessibility.md | Polish | Smart Invert opt-out on the stage, panel inverted (A10, K-30) | ADR-0006 D5 | Covered |  |
| TR-a11y-003 | accessibility.md | Polish | Flash safety: F2 flash detector gate on the busy scenario (WCAG 2.3.1), F2b red-flash palette check (AC-07..09) | ADR-0009 D6 (Proposed; says "not decided here") | Partial | ADR-0004 calls it a QC tool; ADR-0011 has no gate for it; no ADR decides where it runs |
| TR-a11y-004 | accessibility.md | Polish | Palette and idle lints in the build: F1 idle frequency, A5 contrast for hints and panel (AC-05, AC-10) | ADR-0004 scene-look-v1 (the 160 Scene cases only) | Partial | hint and panel contrast and the F1 idle lint have no ADR gate |
| TR-a11y-005 | accessibility.md | Polish | Child touch floor at least 18 mm on each device class (AC-12) | ADR-0006 D7 | Covered |  |
| TR-a11y-006 | accessibility.md | Polish | No accessibility value stored, sent or logged (AC-16; PKC-05, 14) | ADR-0005 D5; ADR-0011 D5/D6 | Covered |  |
| TR-android-001 | accessibility.md | Polish | Android port: Kotlin modules, adapters, Remove animations, TalkBack, gesture insets (Accessibility AC-17, Hint Letters AC-20, Keyboard Row AC-19, Parent Gate AC-39) | ADR-0012 (cited by ADR-0002..0011, file does not exist) | GAP | deferred by K-03; non-blocking while Apple ships first |

## Known Gaps

| TR-ID | GDD | Suggested ADR | Severity |
|---|---|---|---|
| TR-gate-006 | parent-gate-panel.md AC-24, AC-32 | `/architecture-decision grown-up panel accessibility` | advisory |
| TR-android-001 | accessibility.md AC-17 and three more | ADR-0012 (cited by nine ADRs, absent) | advisory, deferred by K-03 |

Partial rows and the ADR that should absorb them:

| TR-ID | Missing decision | Suggested home |
|---|---|---|
| TR-a11y-003 | where the F2 flash detector and F2b palette gate run, and that FAIL blocks a release candidate | ADR-0011 (build gates); ADR-0009 D6 says "not decided here" |
| TR-a11y-004, TR-cast-007 | F1 idle-frequency lint, A5 contrast for hints and panel | ADR-0003 validator or ADR-0011 |
| TR-hints-003 | validator rule for hint knobs and slots (AC-21) | ADR-0003 |
| TR-shell-004 | iPad status bar, home indicator, `edgeDeferral` | ADR-0006 D4 amendment |
| TR-scene-002 | weather cost in the device run | ADR-0009 (Proposed) |

## Proposed-only dependencies

| ADR | Rows | Device rows pending |
|---|---|---|
| ADR-0007 | TR-input-003, TR-input-004, TR-gate-004, TR-lock-003 | M-1, M-2, M-3, P-15, P-4 |
| ADR-0008 | TR-lock-001, TR-lock-003, TR-lock-004, TR-lock-005, TR-gate-005 | M-3..M-7, P-4 |
| ADR-0009 | TR-cast-002, TR-cast-004, TR-morph-003, TR-parade-002 | P-2, M-13 |
| ADR-0010 | TR-audio-002, TR-audio-003, TR-audio-004, TR-audio-005 | P-1, P-7, P-8, P-9, M-14 |

## Superseded Requirements

None. The registry was empty before this review; the provisional IDs of architecture.md's baseline were adopted without renaming. Two contracts named in ADR-0004 are superseded as contracts (settings-record-v1 by v2, input-filter-v1 by v2); the requirements they test are unchanged.

## Story and test linkage

Not built: no stories exist yet (`production/epics/` is empty). `/architecture-review rtm` adds those columns later.
