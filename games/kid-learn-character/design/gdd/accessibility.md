# Accessibility

> **Status**: In Review
> **Author**: game-qc-ios for Luan (TASK-061); plan reviewed by game-qc-android
> **Last Updated**: 2026-11-18
> **Last Verified**: 2026-11-18 (WCAG 2.2 read raw from w3.org on this date)
> **Implements Pillar**: Pillar 3 (Calm Magic) and Pillar 5 (Safe by Design); serves Pillar 1 (Every Press Answers: every answer reads without sound)

## Summary

Accessibility owns one flag and one gate. The flag is **Reduce Motion**, read live from the OS and
published to every system; the gate is the **photosensitivity check** (no more than three flashes
per second, measured the WCAG way). Everything else in this document is collected from the GDDs that
own it (the per-system Reduce Motion rules, contrast, colour backups, touch sizes, the parent's
VoiceOver, audio) and cited, not restated as new rules.

> **Quick reference**: Layer `Meta` · Priority `Vertical Slice` · Key deps: MorphCore, Reveal Stage,
> Scene, Hint Letters, Parade (and every system that moves). Owns `reduceMotion` and the F2 gate.

---

## Overview

The player is 2.5–3 and can't read; a grown-up sets the device up. So accessibility here means:
- the toy follows the **device's own settings** (Reduce Motion, silent mode), with nothing to set in
  the app (art bible §7: "follow the iOS/macOS Reduce Motion setting");
- it **stays under three flashes per second**, and its pulses change blur, size or position, not brightness
  (art bible §1 rule 3, "Drift, never flash"; §2 rules 1–2);
- **no meaning rests on colour or on sound alone** (art bible §4 colourblind table; Audio R5);
- targets are sized for **small fingers** (Hint Letters F5's 18 mm floor);
- the **grown-up panel** works with VoiceOver and Dynamic Type (Parent Gate & Grown-up Panel).

Decisions: K-16 (Reduce Motion softens cast rendering), K-20 (reveal), K-24 (scene), K-25 (contrast
during crossfades), K-29 (twinkle steady, Switch Control accepted, one toggle-timing rule).

## Player Fantasy

For the parent with a child sensitive to motion or light: *"I turned on Reduce Motion for the iPad
once, and this toy calmed down too. Nothing in it blinks."* For the child: the same toy, a little
gentler. For a grown-up using VoiceOver: the panel reads every control by name.

---

## Detailed Design

### Core Rules

**A1. One Reduce Motion flag.**
- Accessibility publishes **`reduceMotion`** (boolean) and one change event.
  - iPadOS: `UIAccessibility.isReduceMotionEnabled`, updated on
    `UIAccessibility.reduceMotionStatusDidChangeNotification`.
  - macOS: `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`, updated on
    `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification`.
  - Android: "Remove animations" (`Settings.Global.ANIMATOR_DURATION_SCALE` = 0). **NOT ASSESSED** until
    the Android ADR.
- It is **read live and never stored** (Settings Store R2). There is **no in-app Reduce Motion
  switch**: the art bible §7 rule is to follow the OS, and the Settings Store's field list (R1) is
  closed.
- **Every system reads this flag, not the OS API** (one source; tests inject it). Today each motion
  GDD names "the Reduce Motion flag" from Accessibility in its Interactions; the follow-up list asks
  each to say "Accessibility's `reduceMotion`" explicitly where it doesn't.

**A2. When a change takes effect** (K-29, one rule).
- **Reveal-locked parts change from the next reveal:** the timing set (MorphCore), the reveal's
  motion (Reveal Stage R9), the hold (Press Queue F5), the voice timings (Audio R1), and the halo and hop of the reveal (Cast Rendering R5, R8).
- **The stardust twinkle is reveal-locked** (author's classification, K-29 doesn't list it): the specks exist
  only inside a reveal, and a running reveal keeps its set, so the twinkle goes steady from the next
  reveal.
- **Ambient parts change on the next frame:** clouds, rain and snow, stars (Scene R8); hints (Hint
  Letters R10); the parade's bob (Parade R7); **an idling creature's idle amplitude** (Cast Rendering;
  follow-up, because Cast Rendering today keeps a running idle until the next reveal); the title's
  breathe (App Shell); the moon ring (Parent Gate).

**A3. The Reduce Motion rules, collected.** Each row is the owner's rule; this GDD adds none.

| System | Under Reduce Motion | Source | When |
|---|---|---|---|
| MorphCore | the **reduced timing set** (provisional: T 1.2 s, glow 0.4 s) | MorphCore Rule 8, Q3 | next reveal |
| Reveal Stage | glyph rises straight, no scale overshoot; creature appears with no pop overshoot; the leaving creature only fades, no sink | Reveal Stage R9, K-20 | next reveal |
| Cast Rendering | halo steady at `halo_steady` 80% (× 0.7 at Night); idles × 0.5; hop 13 units; **stardust twinkle steady at a fixed alpha (K-29; follow-up)** | Cast Rendering R5, R7, R8; K-16; K-29 | halo, hop: next reveal; idles: next frame; twinkle: next reveal (A2) |
| Hint Letters | no drift, no pulse, no scale-in; a 0.3 s consume fade | Hint Letters R10 | next frame |
| Parade | the same 11 s walk; step bob × 0.5 (Cast Rendering R8) | Parade R7, K-17 | next frame |
| Scene | clouds still; rain and snow at half count and half speed; stars steady; fades unchanged | Scene R8, K-24 | next frame |
| App Shell & Title | the play button breathes at half amplitude; the title creature as Cast Rendering | App Shell R2, F2 | next frame |
| Parent Gate & Panel | the ring fills (progress) with no pulse; challenge and panel appear with no fade; the dim is instant; the "Child lock is OFF" notice disappears with no fade | Parent Gate UI Requirements, G9 | next frame |
| Press Queue | the hold stays 3 s (K-15); only `formedS` and `revealLen` follow the reduced set | Press Queue F5 | next reveal |
| Audio & Voice | the voice timings follow the active set | Audio R1 | next reveal |
| Settings, Input, Key Table, Privacy, Child Lock-in | none (no motion) | — | — |

**Flags to owners** (no rule is set here):
- **Reveal Stage:** the tap and ignored-press **sparkles** have no Reduce Motion rule. The owner
  decides (keep, or soften).
- **App Shell & art bible:** the play button breathes at **0.38 Hz** (App Shell `title_breathe_hz`)
  but the art bible §2 rule 2 note says **0.48 Hz**. Both are ≤ 1 Hz, so F1 passes either way; the
  owners pick one.
- **Art bible §7** asks for "a calmer parade"; K-17 decided that only the bob halves. Noted as
  consistent with K-17.

**A4. Photosensitivity.** Nothing in the game flashes (art bible §1 rule 3). It is checked two ways:
- **F1, a data lint** run on every build: every periodic animation's rate in the shipped data is
  ≤ 1 Hz, except the named exceptions, and every rate is < 3 Hz with no exception.
- **F2, the gate**, measured on captured frames against WCAG 2.3.1 (below). F1 can't replace it:
  several pulses out of phase over overlapping areas can add up to flashing that no single rate shows.

The pulses, collected:

| Pulse | Rate | What it changes | Source | F1 |
|---|---|---|---|---|
| Glyph halo | ~2.2 Hz (`halo_hz`; one-shot `sin(14t)`, 2.23 Hz) | blur between 60% and 100% of its maximum; the fill never pulses | Cast Rendering R5, F2; art bible §2 rule 1; K-08 | exception (named) |
| Stardust twinkle | ~1.43 Hz (9 rad/s) | speck size and alpha, not the scene's brightness | Cast Rendering R6, F3; K-16 | exception (named) |
| Parade step bob | ~2.2 Hz (`abs(sin(7t + i))`) | position only | Cast Rendering R8; K-16 | exception (named) |
| Hint pulse (until the first press) | 0.64 Hz (4 rad/s) | size × (1 + 0.06·p) and glow | Hint Letters R7 | ≤ 1 Hz |
| Hint drift | 0.11 and 0.21 Hz | position | Hint Letters R7 | ≤ 1 Hz |
| Creature idles, breathe | ≤ 1 Hz (breathe 0.33 Hz; babies 0.95 Hz) | pose | Cast Rendering R7 (build check) | ≤ 1 Hz |
| Title play button | 0.38 Hz (App Shell; see flag) | scale ± 4% | App Shell | ≤ 1 Hz |
| Star twinkle | ≤ 0.35 Hz | alpha | Scene; art bible §2 | ≤ 1 Hz |
| Snow sway | ≤ 0.3 Hz | position | Scene | ≤ 1 Hz |
| Lightning, thunder flashes | never | — | Scene; art bible §2 | — |

**A5. Contrast** (collected; the numbers are their owners').
- The glyph: ≥ 3:1 against the sky mid band at the ends of every crossfade; **K-25 exception:**
  ≥ 2.5:1 inside a 15-min crossfade or the 3 s jump fade (measured minimum 2.57:1; the edge actually
  shown floors at 2.53:1 under hysteresis); the 1 s edge cross-dissolve is skipped by the Scene's
  160-case build check (Cast Rendering R5; K-25).
- Hints and queue tokens: Letter Gold ink `#b9631c` on highlight cream, about 4:1 (art bible §4).
- Grown-up panel controls: Dusk Blue `#46558f`, 6.5:1 on the card (art bible §4).
- The moon's progress ring: Starlight, about 2.5:1 on the day sky; its length and the hold time carry
  it (art bible §4 trade-off, Luan 2026-11-17).

**A6. No meaning by colour alone** (art bible §4 colourblind table, as a rule for every system):

| Meaning | Colour | Backup cue |
|---|---|---|
| A letter or number | Letter Gold | largest, centred, outlined, spoken |
| I heard you | Starlight | a four-point star at the press point, plus a chime |
| Hint vs waiting | the same gold on cream | a drifting rounded square vs a small circle in a still row |
| Which creature | slot | silhouette trait and spoken name |
| Moon gate progress | ring | ring length and hold time |

Under deuteranopia the raptors R, U and V converge to one brown; their outline traits tell them apart
(art bible §3, §4). Panel switches show On/Off text (Parent Gate).

**A7. Touch targets.**

(a) **Child targets.** The number's owner is **Hint Letters F5: an 18 mm physical floor** (hit
diameter; scaled up by `k` if a device would go under it).

| Target | Size | Source |
|---|---|---|
| Hint letter | hit diameter 27–31 mm on iPads, ≥ 22.5 mm on the smallest Mac window (k = 1 on every MVP device) | Hint Letters F5 |
| On-screen keyboard row key | hit rect 144 × 134 units (the drawn key plus 8 units a side), which meets the 18 mm floor; a short common word or name, at most 8 letters | `onscreen-keyboard-row.md` (hit rect, F2; its V17 caps the word at 8, within K-29's ≤ 9) |


Not targets: the title play button (any tap except the moon starts play, App Shell R3), a tap on a
cast member and a tap on the empty stage. Any touch there answers (a hop or
a sparkle), so they need no floor.

(b) **Grown-up targets: ≥ 44 pt** (Apple's minimum).

| Target | Size | Source |
|---|---|---|
| Panel controls | ≥ 44 pt | Parent Gate G7 |
| Challenge keypad | 60 pt keys, 12 pt gaps | Parent Gate G3 |
| The moon (a grown-up target drawn on the child's stage) | ≥ 44 pt diameter, 20 pt slop | Parent Gate G1; Input R7 |

**A8. The grown-up's side** (collected from Parent Gate & Grown-up Panel).
- **VoiceOver:** the moon is one element ("Grown-ups", hint "Double-tap and hold to open settings";
  VoiceOver's double-tap-and-hold is a long press); the code's label has no "·"; keypad keys accept
  accessibility activation; focus lands on the code text and returns to the stage on close (G3,
  Edge Cases, AC-24).
- **Dynamic Type:** the panel scrolls; the keypad keeps its size and gaps (AC-32).
- **Switch Control / AssistiveTouch (K-29):** accepted for the MVP and documented. A 1.5 s hold of
  the moon or a confirm button may not be possible; on the Mac the ⌃⌥⌘Q chord replaces the moon
  hold; on the iPad the grown-up pauses Switch Control to open the gate.
- **The child's side has no text** (art bible §7), so nothing on it is designed for VoiceOver.
  **NOT ASSESSED:** what VoiceOver's own gestures do on the stage if it is left on during play.

**A9. Audio** (collected).
- **Every sound has a visual answer**; with the sound off, everything still reads (Audio R5; art bible
  §7). No meaning is carried by sound alone.
- **Silent mode is respected** (K-13; Audio R6).
- **Loudness targets** (K-13): voice −16 LUFS, cast −20, chime −26, ping −30, parade −22, ≤ −1 dBTP.
- **Mono Audio (OS setting): no effect.** Audio R4 step 2 decodes every buffer "to the output's
  sample rate, mono", so there is no stereo information to lose.
- **Captions: none** (K-30). The player can't read; the glyph and the creature are the visual equivalent of
  "D… diplodocus".
- Hearing aids and other hearing devices are the OS's.

**A10. Other OS settings** (out of scope, one line each).
- **Reduce Transparency** (iOS, macOS; K-30): no effect. The game uses no system blur or vibrancy; the
  panel's dim is a plain overlay. A system material added later follows the setting.
- **Increase Contrast** (iOS, macOS; K-30): not supported in the MVP; the A5 floors are the contrast design.
- **Differentiate Without Color** (iOS, macOS): no change needed; A6 already holds everywhere.
- **Bold Text** (iOS; K-30): the panel follows it through Dynamic Type and the system font as far as the
  bundled family allows. **NOT ASSESSED:** whether the bundled family has a bold weight.
- **Smart Invert** (iOS): **decided (K-30, from art bible §4): the stage opts out**
  (`accessibilityIgnoresInvertColors = true` on the stage view), because inverting it would break the
  §4 contrast floors and colour meanings; the grown-up panel follows Smart Invert. Follow-up below.
- **Classic Invert** (iOS) and **Invert colors** (macOS): can't be opted out of; the OS inverts
  everything, by the user's choice. Stated as such.
- **Android** (NOT ASSESSED until the Android ADR): the flag from "Remove animations"; **TalkBack**
  on the parent panel as VoiceOver; font scale on the panel; colour correction and inversion are
  OS-wide, as on Apple.

**A11. Privacy.** No accessibility setting is stored (Settings Store R2; PKC-05) or sent (PKC-01). In
release builds no accessibility setting is logged: PKC-14 today covers the child's input only, so
extending its code scan to accessibility settings is a follow-up for the Privacy owner. Reading an OS
flag on the device is not collection.

### States and Transitions

| State | Meaning | Changes when |
|---|---|---|
| `reduceMotion = false` | the normal set and motion | the OS setting turns on → `true` (A2 timing) |
| `reduceMotion = true` | the reduced set and the A3 rules | the OS setting turns off → `false` (A2 timing) |

The flag is read at launch and on every OS change event, and again when the app returns to the
foreground (an event may be missed while inactive).

### Interactions with Other Systems

| System | Direction | What |
|---|---|---|
| MorphCore, Reveal Stage, Press Queue, Audio & Voice | out | `reduceMotion`, read at reveal start (A2) |
| Cast Rendering | out | `reduceMotion`: halo, hop and twinkle at reveal start; idles on the next frame (K-29) |
| Hint Letters, Parade, Scene, App Shell & Title, Parent Gate & Panel | out | `reduceMotion`, applied on the next frame (A2) |
| Settings Store | — | stores nothing for accessibility (R2) |
| Privacy & Kids Compliance | constraint | A11 |
| Every visible system | gate | F2 runs on the whole stage, so every system's motion is in it |

---

## Formulas

**F1. Rate lint** (every build, on the shipped data).

`pass = ∀ animation a: rate(a) < 3 Hz ∧ (rate(a) ≤ 1 Hz ∨ a ∈ {halo, stardust twinkle, parade step bob})`

| Variable | Meaning | Range |
|---|---|---|
| `rate(a)` | an animation's repeat rate in Hz; for `abs(sin(ω t))` it is ω / π, for `sin(ω t)` ω / 2π | > 0 |

Examples: the halo 2.23 Hz → exception, < 3 → pass; a new idle at 1.2 Hz → FAIL (not an exception);
the parade bob `abs(sin(7t))` → 7 / π = 2.23 Hz → exception, pass; hint pulse 4 / 2π = 0.64 Hz → pass.

**F2. The photosensitivity gate** (WCAG 2.3.1, Level A; definitions quoted from WCAG 2.2, w3.org, read
2026-11-18).

WCAG 2.3.1: "Web pages do not contain anything that flashes more than three times in any one second
period, or the flash is below the general flash and red flash thresholds." The thresholds pass if
"there are no more than three general flashes and / or no more than three red flashes within any
one-second period; or the combined area of flashes occurring concurrently occupies no more than a
total of .006 steradians within any 10 degree visual field on the screen (25% of any 10 degree visual
field on the screen) at typical viewing distance". "A general flash is defined as a pair of opposing
changes in relative luminance of 10% or more of the maximum relative luminance (1.0) where the
relative luminance of the darker image is below 0.80". A red flash is "any pair of opposing
transitions involving a saturated red", where saturated red means "one transition is either to or from
a state with a value R/(R + G + B) that is greater than or equal to 0.8, and the difference between
states is more than 0.2 (unitless) in the CIE 1976 UCS chromaticity diagram".

**The 10° field for this game** (replacing WCAG's desktop example of 341 × 256 px at 1024 × 768):

```
field_mm = 2 · d · tan(5°)          d = 300 mm (a toddler's viewing distance)  →  52.5 mm
field_px = field_mm / 25.4 · ppi
area_max = 0.25 · (π/4) · field_px²   (the 10° field is a circle of diameter field_px; area_max is
                                      computed from the unrounded field_px)
```

| Device | ppi | `field_px` | `area_max` (px) |
|---|---|---|---|
| 11" and 13" iPad | 264 | 545.6 | 58,449 |
| Mac, 2× screen | 254 | 524.9 | 54,105 |
| Mac, 1× external display | 109 | 225.3 | 9,964 |

(Check: the 10° field is a cone of half-angle 5°, 2π(1 − cos 5°) ≈ 0.0239 sr, and 25% of it is
≈ 0.0060 sr, the WCAG figure; the on-screen disc of diameter `field_px` subtends the same 0.0239 sr to
within 0.1%. A square field would be 27% too lenient, so it is not used.)

**The measurement.**

```
L(p, f)    = 0.2126·R + 0.7152·G + 0.0722·B        WCAG relative luminance of pixel p in frame f (linear sRGB)
transitions (zig-zag rule, per pixel p): keep the running extreme E since the last transition (start:
  E = L(p, 0), direction unknown). At frame f, if L moves against the current direction by ≥ 0.1
  from E, and the darker of E and L(p, f) is < 0.80, a transition is stamped at frame f; the direction
  flips and E = L(p, f). Otherwise E follows L while it moves in the current direction.
  (Changes smaller than 0.1 never register, so sub-threshold noise is ignored.)
window(t)        = the frames in (t − 1 s, t]: exactly 60 frames at 60 fps (half-open)
flashing(p, t)   = (transitions of p stamped in window(t)) / 2 > 3      i.e. 7 or more transitions
FAIL if ∃ t, ∃ field position F:  #{ p ∈ F : flashing(p, t) } > area_max
```

- **Capture:** 60 fps, every frame, the full stage at the device's native resolution, sRGB values
  converted per WCAG; the field slides over every position (step ≤ `field_px` / 4) for every frame.
- **Scenario:** the K-26 busy case: a seeded mash (the Press Queue's mash fixture) with a walking
  parade, at Night and at Day, with light rain and with snow; once with Reduce Motion off and once on.
  10 s per run.
- **Where:** the simulator runs it on every build (the luminance math doesn't depend on the GPU); the
  **release gate is the run on a real iPad and a real Mac** (frame timing does). **NOT ASSESSED** until
  device time from Luan.
- **F2b, red flash (run on the palette):** every colour in the art bible (51 hex values, read
  2026-11-18) has R/(R+G+B) < 0.8, both on 8-bit sRGB values (highest 0.604, `#80450f`) and on linear
  values (highest 0.781, Letter Gold `#b9631c`). A blend of colours can't exceed its highest component's ratio **when the blend is done and measured in
  the same space** (alpha blending in linear space measured in linear values, gamma-space blending
  measured in 8-bit values, and additive glow): the blend's ratio is a weighted mediant of the
  components'. So with this palette **no saturated red can appear and the red-flash condition can't
  occur**. Not guaranteed for a gamma-space blend measured in linear values or for screen/multiply
  modes; the frame backstop below covers those. The linear margin is thin (0.781), so the F2 capture also logs each frame's highest
  per-pixel R/(R+G+B) as a backstop, and any palette change re-runs F2b. **Scope:** F2b runs on the shipped palette, the theme data and
  every SVG fill (the build's colours, not only the art bible's: e.g. `#3b2f45`, `#d9a070`, `#ffd27a`
  appear in GDDs), so a colour added outside the art bible is caught. The Letter Gold margin (0.781 against 0.8) is
  noted for the art bible owner in K-30: any warmer gold must re-run F2b.

Example: in a 10 s Night capture on an 11" iPad, if 60,000 px inside one field (a disc of diameter
545.6 px) each show 7 transitions (3.5 flashes) within one second, F2 FAILs (60,000 > 58,449); if only
55,000 px do, that second passes. A pixel with 6 transitions (3 flashes) never counts.

---

## Edge Cases

- **Reduce Motion turns on mid-reveal:** the reveal keeps its locked set; the next one uses the new
  set; ambient motion changes on the next frame (A2, K-29).
- **The app is in the background when the setting changes:** the flag is re-read on return (States).
- **Reduce Motion and mashing in snow:** the Scene's factors stack to ×0.25 (Scene R3a, R8).
- **A new animation is added in a later GDD:** F1 fails the build unless it is ≤ 1 Hz or added to the
  exception list by a decision; F2 covers it automatically.
- **A palette change adds a red:** F2b fails if R/(R+G+B) ≥ 0.8 on any new colour; then F2's red-flash
  rule must be implemented, not skipped.
- **A device with a different ppi** (a later iPad or Mac): `field_px` is computed from its ppi; nothing
  else changes.
- **VoiceOver on during play:** NOT ASSESSED (A8).
- **Smart Invert on:** the stage keeps its colours; the panel inverts (A10).

## Dependencies

- **Reads:** the OS accessibility settings (A1). Android NOT ASSESSED.
- **Collects from (each must keep naming Accessibility's flag):** MorphCore, Reveal Stage, Press
  Queue, Cast Rendering, Hint Letters, Parade, Scene: Time of Day & Weather, App Shell & Title, Parent
  Gate & Grown-up Panel, Audio & Voice, Settings Store (R2), Privacy & Kids Compliance.
- **Documents:** art bible §1–§4, §7; decisions K-08, K-13, K-15, K-16, K-17, K-20, K-24, K-25, K-26,
  K-29, K-30; WCAG 2.2 SC 2.3.1 and its definitions (w3.org, read 2026-11-18).

**Follow-ups for other GDDs** (listed here, not edited):

| GDD | Follow-up |
|---|---|
| Cast Rendering | the stardust twinkle steady at a fixed alpha under Reduce Motion (K-29, "the stardust twinkle holds steady"), from the next reveal (A2); idle amplitude changes on the next frame (K-29, "Mid-session Reduce Motion toggle"), not the next reveal |
| Reveal Stage | decide the sparkles under Reduce Motion (A3 flag) |
| App Shell & Title / art bible | pick 0.38 or 0.48 Hz for the play button (A3 flag) |
| App Shell & Title / Reveal Stage | set `accessibilityIgnoresInvertColors` on the stage view (A10, leader decision) |

| Every motion GDD | name "Accessibility's `reduceMotion`" as the flag's source in its Interactions (A1) |
| Parent Gate & Grown-up Panel | record the Switch Control / AssistiveTouch acceptance (K-29) in its Edge Cases |
| Privacy & Kids Compliance | extend PKC-14's release log scan to accessibility settings (A11) |

## Tuning Knobs

| Knob | Value | Safe range | Affects |
|---|---|---|---|
| `viewing_distance_mm` | 300 | 250–400 | the 10° field size in F2; a shorter distance gives a smaller field and a smaller `area_max`, which is stricter. 300 mm is a toddler holding the iPad close; a value below 300 is stricter, above it more lenient |
| F1 exception list | halo, stardust twinkle, parade step bob | changed only by a decision | which pulses may exceed 1 Hz |
| F2 scenario length | 10 s per run | ≥ 5 s | how much of the busy case is captured |

The Reduce Motion values themselves are their owners' knobs (A3).

## UI Requirements

None of its own. The panel's accessibility (VoiceOver, Dynamic Type, switch text) is the Parent Gate
GDD's (A8).

---

## Acceptance Criteria

1. **AC-01 · one flag:** with the injected flag on, every system in A3 applies its rule; with the OS
   API mocked to a different value and the flag injected, the systems follow the flag (no system reads
   the OS directly; code review plus test; partly manual evidence).
2. **AC-02 · never stored:** after toggling Reduce Motion and relaunching, the Settings Store record has
   no new field (Settings Store R2).
3. **AC-03 · toggle timing (K-29):** GIVEN a reveal in progress and clouds drifting, WHEN the flag turns
   on THEN the running reveal keeps its set and its specks keep twinkling; the next reveal uses the
   reduced set with steady specks; and the clouds, hints, parade bob and idle amplitude change on the
   next frame.
4. **AC-04 · re-read on return:** GIVEN the app in the background, WHEN the OS setting changes and the app
   returns THEN the flag reflects the new value before the next frame.
5. **AC-05 · F1 lint:** the lint over the shipped data passes; a test fixture with an idle at 1.2 Hz
   fails it, naming the animation; a fixture at 3.0 Hz fails even on the exception list.
6. **AC-06 · F2 field math:** for ppi 264, 254 and 109 the tool's `field_px` is 545.6, 524.9 and 225.3 and
   `area_max` 58,449, 54,105 and 9,964 px (unit test; from the unrounded `field_px`).
7. **AC-07 · F2 detector:** a synthetic clip with a full-screen 4 Hz black/white flash FAILs; the same
   flash confined to 20% of a field passes; a 3 Hz full-screen flash passes **at every phase offset** against the 60-frame window; a 3.5 Hz
   full-screen flash FAILs; a ΔL = 0.08 flicker passes (below 10%); random noise of ±0.04 passes; a
   flicker between L 0.85 and 1.0 passes (darker ≥ 0.80) (unit tests on the detector).
8. **AC-08 · F2 gate (NOT ASSESSED until device time):** the K-26 busy scenario, Night and Day, rain and
   snow, Reduce Motion off and on, on a real iPad and a real Mac at 60 fps: no FAIL. The simulator run
   passes on every build.
9. **AC-09 · F2b red flash:** the palette check over every hex in the art bible reports the highest
   R/(R+G+B) (8-bit 0.604, linear 0.781) and passes (< 0.8); adding `#ff0000` to a test palette fails it. It runs on the shipped palette, theme data and SVG fills.
   The F2 capture's logged per-pixel maximum stays < 0.8.
10. **AC-10 · contrast:** the Scene's 160-case check (K-25) passes; hints and panel controls meet A5
    (build check on the palette).
11. **AC-11 · no colour-only meaning:** for each A6 row, a desaturated (greyscale) screenshot still shows
    the backup cue (manual: retained screenshots of hint vs queued token, the moon ring).
12. **AC-12 · child touch floor:** on every MVP device class, a hint's hit diameter and a keyboard-row key's hit rect are ≥ 18 mm
    (Hint Letters F5; On-screen Keyboard Row F2).
13. **AC-13 · grown-up targets:** every panel control is ≥ 44 pt and the keypad keys are 60 pt with
    12 pt gaps (UI test reading frames).
14. **AC-14 · sound off:** with the device muted, a 2-minute seeded session's screenshots show a visual
    answer for every event in Audio R1 (manual: retained screenshots).
15. **AC-15 · Smart Invert:** with Smart Invert on, the stage's pixels are unchanged and the panel is
    inverted (manual: retained screenshot pair).
16. **AC-16 · privacy (release build):** no stored value (PKC-05) or network call (PKC-01) carries an
    accessibility setting, and the release build's code scan finds no log call carrying one (once
    PKC-14's scan is extended; follow-up).
17. **AC-17 · Android (NOT ASSESSED: no Android build, K-03):** "Remove animations" drives the flag;
    TalkBack reads the panel.

---

## Open Questions

| # | Question | Owner |
|---|---|---|
| Q1 | The sparkles under Reduce Motion | Reveal Stage owner |
| Q2 | 0.38 vs 0.48 Hz for the play button | App Shell / art bible owners |
| Q3 | Device time for AC-08 (F2 on a real iPad and Mac) | Luan |
| Q4 | What VoiceOver does on the stage if left on during play | QC, on a device |
| Q5 | Whether the bundled font has a bold weight (Bold Text) | Art / lead programmer |
