# Scene: Time of Day & Weather

> **Status**: Approved (independent read by game-dev-ios, merged 2026-11-18)
> **Author**: game-art-content for Luan (TASK-053); plan reviewed by game-dev-ios
> **Last Updated**: 2026-11-18 (TASK-054c: K-25 edge model and thresholds; live halo radius)
> **Last Verified**: 2026-11-18
> **Implements Pillar**: Pillar 3 (Calm Magic); serves Pillar 5 (Safe by Design) and Pillar 1 (the glyph stays first)

## Summary

The Scene is the backdrop behind everything: the sky, the hills and the ground. The sky follows the device's own
clock through four looks (Morning, Day, Dusk, Night), and a grown-up can add calm weather (cloudy, light rain,
snow, optionally windy) behind the parent gate. There is no network, no location and no permission (K-08,
TASK-034). The Scene fills the whole screen, beyond the safe stage (K-20), keeps the glyph the brightest and
warmest thing in every look and weather (art bible §2), warms the horizon while the parade walks, and is the same
on the Title. It makes no sound.

> **Quick reference** — Layer: `Presentation` · Priority: `Vertical Slice` · Key deps: `Settings Store` (also
> reads Reveal Stage's visible rect, ground line, play clock and mashing signal, and the Parade's `paradeWalking`;
> read by Parent Gate (the moon), Cast Rendering (look), App Shell & Title)

## Overview

A child plays after breakfast: the sky is pale blue with a peach band at the horizon and a low, pale sun. After
school it is Day; at four it slowly turns into the lilac Dusk of the prototype; after half past seven it is Night,
deep blue, with more stars. None of it changes while the child watches: a change takes 15 minutes of real time.
If the parent picked snow, a few round flakes drift down behind the letter; they thin out while the child mashes,
and they never cross the glyph's glow.

This GDD owns: the four looks and their timing (R2), weather and windy (R3, R4), readability and the build check
(R5), filling the extended screen (R6), the parade's horizon lift (R7), Reduce Motion (R8), the two clocks and the
freeze (R9), the Title (R10) and silence (R11). It publishes `look` and `lookBlend` for others.

It does **not** own: the moon (the Parent Gate draws it; R1), the glyph's and creatures' per-look changes (Cast
Rendering, a queued follow-up), the stage transform and the ground line (Reveal Stage R10), the stored weather
(Settings Store), or the parade (Parade).

## Player Fantasy

**"The sky outside the window is in my game."** The child does not have to know what time it is: the morning sun,
the evening dimming and the quiet starry night tell them, without words (art bible §6). For the grown-up, the
weather they picked this morning is still there, and night play is dim and calm before bed. Nothing in the sky
ever competes with the letter.

## Detailed Design

### Core Rules

**R1. Ownership and layers** (art bible §6: sky, hills, stage).
- The Scene draws, back to front: the **sky** (vertical gradient, stars, the sun in Morning and Day, clouds,
  rain or snow), the **back and front hills**, and the **ground** (the cream stage floor). It is the bottom of the
  draw order (Reveal Stage R10) and fills the whole **visible rect**, not just the safe stage (R6).
- **One moon (decided by the leader, as played):** the Scene draws **no moon disc**. The moon in the corner is the
  Parent Gate's moon and is the sky's only moon; the Scene gives the gate `look` and `lookBlend`, and the gate draws
  it (`#e6d6a4`, at 70% as a "daytime moon" in Morning and Day, art bible §2).
- **The sun:** a flat disc `#ecd29a` with no rays, low in Morning and high in Day (art bible §2 table), fading out
  with the Day → Dusk crossfade; no sun at Dusk or Night. Its L 0.66 is under the sky cap (0.69). *Art-bible note:*
  the §4 "Temperature" lines say warmth in Morning comes only from the horizon and in Day only from the glyph and
  creatures; the §2 table, which Luan approved row by row, has the pale sun. **The §2 table wins**: the sun is the
  desaturated pale yellow the table names, not a warm accent. "The moon is the only warm sky element" is a Night
  line and does not conflict (no sun at Night).
- It **publishes** `look` (the current phase) and `lookBlend` (the previous phase, the current one and the weight,
  F1) for the Parent Gate (the moon), Cast Rendering (the per-look glyph and creature changes) and anyone else who
  needs the look, and **`skyMidL`** (the blended sky-mid luminance with the weather tint, F2; K-25), which Cast
  Rendering's edge switch (its R4, F8) and R5's build check both read. All three follow the wall clock (R9).
- Nothing in the Scene is touchable. A touch on the sky or ground is a `sparkle` (Input R7).

**R2. Time of day** (K-08, art bible §2; K-24).
- The **local wall clock** (the device's time and time zone) picks the phase. The boundaries are data, the art
  bible's proposal, tuned in play: **Morning 06:00, Day 10:00, Dusk 16:00, Night 19:30**; Night runs to 06:00.
- **Crossfade:** each boundary starts a **15-minute** crossfade from the previous look to the new one, **starting at
  the boundary** (K-24): 16:00 → fully Dusk at 16:15. A child never sees it happen in a session.
- **First frame:** on launch, on return from the background, and on Title entry, the first frame is already the
  right look for the wall clock (art bible §2): no fade from a stale look.
- **A clock jump while the app is in front** (the user changes the clock or time zone, a DST change, a large
  correction): the drawn look fades to the new target over **3 s** (K-24). While the app is in the background,
  nothing is drawn, so the return just shows the right look (first frame rule).
- No network, no permission, no location (K-08; TASK-034: the system clock raises no Kids or COPPA issue).

**R3. Weather** (K-08, K-12, art bible §2; K-24).
- `weather` (`clear`, `cloudy`, `lightRain`, `snow`) and `windy` come from the Settings Store. The pick is **kept
  until changed** (K-12): no date, no expiry.
- **Clear:** no overlay.
- **Cloudy:** 2–4 flat, rounded clouds drifting at ≤ 8 u/s, tinted to the current look, never darker than the
  sky's top colour.
- **Light rain:** 40–70 thin streaks at ≤ 35% opacity, cool grey-blue matched to the look; the sky stops lose 10%
  saturation; **2–3 pale clouds** (K-24).
- **Snow:** ≤ 60 round flakes `#cfd6e3`, falling at 20–40 u/s with a sway ≤ 0.3 Hz; **2–3 pale clouds** (K-24).
- **Never:** lightning, thunder flashes, dark storm clouds.
- **A change from the panel fades in over ~2 s** (`weather_fade_s`) while the panel is open (K-24), so the parent
  sees it on close. (The art bible's slow crossfade is for time of day only.)
- **Inside the glyph's glow:** weather fades to nothing near the glyph. Each element's alpha is multiplied by the
  halo factor F3d, using the **glyph box from Reveal Stage R10** and **the halo's current glow radius published by
  Cast Rendering R5** (230 u, 161 u at full Night; its F8). Neither is hard-coded here. The factor is 1 while the
  Reveal Stage's `haloOn` is false.
- Weather is **sky**: it counts toward the sky brightness cap (R5) and is drawn behind the hills.

**R3a. Mashing thins the weather** (art bible §2, state table, Mashing row: "weather particles halve").
- `mashing` is true while the Press Queue snapshot's queue length is ≥ 1, **or** an `ignored` press happened in the
  last `mash_window_s` (1 s) on the play clock. The Reveal Stage publishes it (Interface). This **Scene-owned**
  knob is the one the Reveal Stage cites (its R10). Audio & Voice's chime falloff uses its own, separate
  `chime_window_s` (Audio F3).
- While true, the **rain or snow count** is multiplied by `mash_factor` (0.5), faded in and out over
  `mash_fade_s` (0.5 s) by alpha. Clouds and stars are unchanged.
- It stacks with Reduce Motion's factor (R8): the lowest is ×0.25.

**R4. Windy** (art bible §2; Settings Store R1).
- Acts **only with `lightRain` or `snow`**: rain and snow tilt by `windy_tilt_deg` (15°, ≤ 20°), and their clouds
  drift ×2; no gusts. With `clear` or `cloudy` it is stored and has no effect.

**R5. Readability in every look and weather** (art bible §1, §2, §4).
- **The caps** (art bible §2, §4 rules 1–3): every sky stop, sun, cloud, streak and flake is at **L ≤ 0.69**; the
  glyph reaches **≥ 3:1** against the sky's mid band through its fill or its edge **at the looks themselves**, and
  **≥ 2.5:1 inside a crossfade** (K-25, a dated exception in the art bible); the sky uses **no Letter Gold** and its
  yellow stays pale (the sun).
- **Build check (AC-5):** over every look pair in the cycle (Night → Morning → Day → Dusk → Night) at blend weights
  0, 0.25, 0.5, 0.75 and 1 (F1), × the four weathers, × the horizon lift off and on (R7), the check computes every
  sky colour and fails the build on any cap breach: 4 × 5 × 4 × 2 = **160 cases**. The glyph's edge follows **the
  same edge model as Cast Rendering F8** (K-25), read from the case's **`skyMidL`** (F2, the same value the switch
  reads): cream `#f8efdc` at 100% below L_x ≈ 0.308, amber `#80450f` above it. Inside the switch's hysteresis band
  (`skyMidL` 0.303–0.313) either edge can be showing, so the check takes the **worse** of the two there. The 1 s
  switch cross-dissolve is **excluded** (it is a wall-clock moment, not a case). The check asserts **≥ 3:1 at w = 0 and 1** and **≥ 2.5:1 at w = 0.25, 0.5, 0.75**, against
  the case's blended sky mid band, through the better of the fill (`#ffd36e`) and the edge. Because the worst point
  (the crossover, where cream and amber are equal) can fall between samples, the check **also asserts the edge's
  contrast is ≥ 2.5:1 over the whole hysteresis band**, which bounds every in-between frame. With the shipped data:
  lowest sampled 2.68:1 (Night→Morning, w 0.5); at L_x 2.57:1; at the band's edges 2.53:1 (cream at 0.313) and
  2.54:1 (amber at 0.303); at the looks 4.36:1 (Day) and above. Because the extension clamps to the end stops (R6), the extended
  areas are covered by the same colours.
- **Hints** sit on their own cream bubble with gold ink (Hint Letters R12), so the sky does not carry their
  contrast; they are in the sky band y 150–420, where only stars, the sun, clouds and weather can be.
- **Creatures** keep their 80% Ink outline in every look (art bible §4), which separates them from any ground.
- **No strobing** (art bible §1 "drift, never flash"): stars twinkle at ≤ 0.35 Hz (the one-shot's 0.1–0.35 Hz),
  snow sways at ≤ 0.3 Hz, every change is a fade of ≥ 2 s (weather) or 3 s (jump) or 15 min (time), and nothing
  flashes.

**R6. Filling the extended screen** (K-20; Reveal Stage R10, F1).
- The Scene draws the whole **visible rect** published by the Reveal Stage (stage units; it extends past 0…1280 and
  0…720): 4:3 iPads gain sky above and ground below (the 11" iPad's rect is y −87…807, the 13" y −120…840); wide Mac
  windows gain hills to the sides (the 21:9 rect is x −220…1500).
- **Sky gradient:** defined over the safe stage, top at y 0, mid at `sky_mid_y` (330), horizon at the sky's bottom
  (`ground_y + 42` = 600, the one-shot's 520 + 80). Above y 0 the colour is **clamped to the top stop**; there is
  no extrapolation.
- **Ground:** the cream gradient from the ground's top curve to y 720 (`#efe2c6` → `#e3d1ae` in Dusk; per look in
  the art bible table), **clamped to its bottom stop** below y 720.
- **Hills and ground line follow the Reveal Stage's ground line** (y 558, moving up by `row_lift` with the keyboard
  row, Reveal Stage R10): the hill curves are defined relative to it.
- **Sideways:** beyond x 0 and x 1280 the hill and ground curves continue as the **mirror image** of their edge
  (x < 0 uses the curve at −x; x > 1280 uses it at 2560 − x), so there is never a gap or a seam, and the parade
  always has ground under its whole walk (Parade F3).
- **Stars** are placed over the whole visible sky (F4), capped at the art bible's 50. Hints stay in the safe stage
  (Hint Letters), not in the extension.
- A window resize (Mac) or a keyboard-row change redraws from the new rect and ground line on the next frame.

**R7. The horizon lift during a parade** (art bible §2, §4 "the only allowed warming"; Parade; K-24).
- While the Parade signals `paradeWalking`, the **horizon stop** blends **35%** toward **peach `#f0c9b0`** (Morning,
  Day) or **amber `#d9a070`** (Dusk, Night), mixed by `lookBlend` (F5).
- The lift fades in and out over the parade's `fade_s` (0.6 s) on the play clock, so it pauses with a frozen parade.
- Both targets pass the caps (peach L 0.63, amber L 0.41, neither is Letter Gold); the build check covers the lift.

**R8. Reduce Motion** (K-24; art bible §7).
- **Clouds hold still** (no drift; windy's ×2 has nothing to act on).
- **Rain and snow at half count and half speed**; the windy tilt is kept.
- **Stars steady:** no twinkle (each star at its mean alpha).
- The looks, crossfades and the horizon lift are fades, not motion, and are unchanged.

**R9. Two clocks; freeze, panel and background.**
- **`look` and `lookBlend` follow the wall clock**, always: under the gate's freeze, under the panel and in the
  background they keep tracking it, so the first frame after any return is right (R2). The 2 s weather fade (R3)
  and the 3 s jump fade (R2) are wall-clock fades too.
- **All motion runs on the Reveal Stage's play clock** (its R8): cloud drift, rain and snow, star twinkle, the
  mashing fade and the horizon lift. On `freeze()` (the gate's number challenge) the play clock stops, so the sky
  holds still under the gate; on `resume()` it continues **without a jump**.
- **Panel open:** the Scene keeps drawing (and moving: the panel is not a freeze) under the panel's 55% navy dim
  (art bible §2). A weather pick fades in there (R3).
- **Background:** nothing is drawn. On return the first frame shows the wall-clock look and the stored weather.

**R10. The Title** (K-22; art bible §2: "the first frame is already in the right look").
- The Title uses **the same Scene**: the same look, the same weather (K-24) and the same extension. The title
  creature (Key Table `titleCastId`) stands on the same ground.
- There is no parade on the Title (no lift) and no mashing (no queue).

**R11. Sound: none** (K-24). The Scene has no weather or ambient sound, keeping Audio & Voice's rule A5 (no music
bed).

### States and Transitions

The Scene is continuous; these are the conditions it runs under.

| State | When | Look (wall clock) | Motion (play clock) |
|---|---|---|---|
| **Running** | Play or Title, in front | follows F1 | runs |
| **Fading** | a clock jump (3 s) or a weather pick (2 s) | fades from the drawn state to the target | runs |
| **Frozen** | the gate challenge (Reveal Stage `freeze`) | keeps following F1 | stopped; resumes without a jump |
| **Under the panel** | the grown-up panel is open | keeps following F1 | runs, under the dim |
| **Hidden** | background | not drawn (tracked) | not drawn |

### Interactions with Other Systems

| System | Direction | What passes |
|---|---|---|
| Settings Store | in | `weather`, `windy`, and the change notification (its R10) |
| Reveal Stage | in | the visible rect, the ground line (with `row_lift`), the play clock and `freeze`/`resume`, `mashing`, the glyph box and whether the glyph's halo is shown (its R8, R10) |
| Cast Rendering | in / out | in: the halo's current glow radius (its R5, 230 → 161 u at Night) and the glyph edge model (its F8, K-25); out: `look`, `lookBlend` and `skyMidL` for the per-look glyph and creature changes and the edge switch (its R4, R7, F8) |
| Parade | in | `paradeWalking` (the horizon lift) |
| Parent Gate & Grown-up Panel | out | `look`, `lookBlend` for the moon (daytime moon, follow-up); the panel's dim is drawn over the Scene |
| Hint Letters | none directly | hints sit in the sky band, on their own bubbles |
| Accessibility | in | Accessibility's `reduceMotion` (its A1; never the OS API), applied on the next frame (R8) |
| App Shell & Title | in | Title entry, background and return (R2 first frame, R10) |
| Audio & Voice | none | no Scene sound (R11) |

## Formulas

**F1. The look at a wall-clock time** (wall clock).
```
t        = local time in minutes since midnight
b        = boundaries: Morning 360, Day 600, Dusk 960, Night 1170 (minutes)
P        = the phase whose boundary is the latest b ≤ t (before 360: Night, whose boundary was 1170 yesterday)
prev(P)  = the phase before P in the cycle Night → Morning → Day → Dusk → Night
since    = minutes since P's boundary (wrapping past midnight)
w        = clamp(since / crossfade_min, 0, 1)                  crossfade_min = 15
lookBlend = (prev(P), P, w);  look = P
```
| Local time | P | since | w | Drawn |
|---|---|---|---|---|
| 15:55 | Day | 355 | 1 | fully Day |
| 16:07 | Dusk | 7 | 0.467 | 53% Day, 47% Dusk |
| 16:15 | Dusk | 15 | 1 | fully Dusk |
| 23:00 | Night | 210 | 1 | fully Night |
| 06:05 | Morning | 5 | 0.333 | 67% Night, 33% Morning |

**Jump fade:** when the target `(prev, P, w)` jumps (a clock or time-zone change in front), the drawn colours fade
from what is on screen to the new target over `jump_fade_s` (3 s): `c = mix(c_drawn, c_target, smoothstep(τ / 3))`.

**F2. Colour blending.** Each colour (sky stops, hills, ground, sun alpha, the glyph's edge style for the check) is
blended in **linear RGB**:
```
c = toSRGB( lerp( toLinear(a), toLinear(b), w ) )
```
Relative luminance is linear in linear RGB, so `L(c)` lies between `L(a)` and `L(b)`: if both ends pass the L ≤ 0.69
cap, every blend does **by construction**. The **glyph contrast is not guaranteed by construction** (it depends on
the blended sky and on which edge is drawn), so the build check samples w = 0.25, 0.5, 0.75 (R5; K-25). The edge is
**never** colour-blended over sky L (a mixed edge drops to about 1.4:1); it switches at L_x with a 1 s dissolve
(Cast Rendering F8).

Example: Day mid `#a8c8e8` (L 0.56) and Dusk mid `#46558f` (L 0.10) at w 0.5 → L 0.33, between the two, under
the cap.

**`skyMidL`** (published, K-25): the relative luminance of the **drawn** sky mid band, that is, the mid stop of the
look blend (F1) after the weather tint (rain's −10% saturation) and any jump fade:
```
skyMidL = L( tint_weather( toSRGB( lerp( toLinear(mid(prev)), toLinear(mid(P)), w ) ) ) )
```
Clear weather, by look: Morning 0.615, Day 0.555, Dusk 0.098, Night 0.029. Because luminance is linear in linear
RGB, in clear weather a crossfade's `skyMidL` is the weighted mean: 16:07 → 0.533 × 0.555 + 0.467 × 0.098 = 0.342.
The horizon lift (R7) changes the horizon stop, not the mid band, so it does not move `skyMidL`.

**F3. Weather motion** (play clock `p`, seconds; stage units).
- **a. Rain:** each streak falls at `rain_speed` (420 u/s) along the tilt: `x += v·sin(θ)·dt`, `y += v·cos(θ)·dt`,
  θ = `windy_tilt_deg` when windy, else 0; length `rain_len` 18 u. A streak below the ground line wraps to above
  the visible top at a seeded x.
- **b. Snow:** fall speed per flake `v ∈ [20, 40]` u/s (seeded); sway `x += A·sin(2π f p + φ)` with `f ≤ 0.3` Hz,
  `A` 12 u; the tilt as for rain.
- **c. Clouds:** drift `≤ 8` u/s (×2 windy with rain or snow), wrapping across the visible rect width plus a margin.
- **d. Halo factor:** with `d` = the element's distance from the glyph box centre (Reveal Stage R10) and `r` = the
  halo's current glow radius published by Cast Rendering R5 (230 u, 161 u at full Night):
  `h = smoothstep(clamp(d / r, 0, 1))` while `haloOn` (Reveal Stage R10), else 1.
  An element at the glyph's centre is invisible; at `r` and beyond it is untouched.
- **e. Factors:** `speed × 0.5` and `count × 0.5` under Reduce Motion (R8); `count × mash` under mashing (R3a), where
  `mash` fades between 1 and 0.5 over 0.5 s. Counts are applied by fading surplus elements' alpha, never by
  popping them.

**F4. Element counts for the visible area.**
```
A_ratio   = (visible sky area) / (safe sky area 1280 × 320)        (sky: y from rect.minY to 320)
n_stars   = min(50, round(base_stars(look) × A_ratio))              base: Morning 4, Day 0, Dusk 46, Night 50
n_rain    = min(70, round(55 × A_vis / A_safe)) × factors           (A over the whole visible rect)
n_snow    = min(60, round(45 × A_vis / A_safe)) × factors
n_clouds  = cloudy: 3 (4 if A_ratio ≥ 1.3); rain or snow: 2 (3 if A_ratio ≥ 1.3)
```
| Rect | A_ratio (sky) | A_vis / A_safe | stars (Night) | rain | snow | clouds: cloudy / rain or snow |
|---|---|---|---|---|---|---|
| 16:9, 1280 × 720 | 1.00 | 1.00 | 50 | 55 | 45 | 3 / 2 |
| 11" iPad, 1280 × 894 | 407/320 = 1.27 | 1.24 | 50 (cap) | 68 | 56 | 3 / 2 |
| 13" iPad, 1280 × 960 | 440/320 = 1.375 | 1.33 | 50 (cap) | 70 (cap) | 60 (cap) | 4 / 3 |
| 21:9 Mac, 1720 × 720 | 1720/1280 = 1.34 | 1.34 | 50 (cap) | 70 (cap) | 60 (cap) | 4 / 3 |

Dusk at 16:9 gives the one-shot's 46 stars.

**F5. The horizon lift.**
```
target  = mix(peach #f0c9b0, amber #d9a070, nightness)       nightness = the Dusk+Night share of lookBlend
h'      = mix(h, target, 0.35 × λ)                           λ fades 0 ↔ 1 over fade_s (0.6 s, play clock)
```
Example (Dusk, horizon `#b8a0c8`, L 0.39): h' at λ 1 → 65% `#b8a0c8` + 35% `#d9a070` in linear RGB, L ≈ 0.40, warmer,
under the cap.

**F6. Draw cost** (no separate claim). The worst case is **snow 60 + windy, 3 clouds, 50 stars, mashing off,
Reduce Motion off** at Night: 113 small sprites + 3 gradient fills + 2 hill shapes + the ground. It is folded into
**Cast Rendering's measurement plan (under its R11, run as its AC-17)** as **one combined run** with its 240 specks (p99 ≤ 16.7 ms target, NOT
ASSESSED on a real iPad until that run). No textures are needed: the gradients are fills, the elements are small
shapes.

## Edge Cases

| Case | What happens |
|---|---|
| **The app opens at 16:07** | The first frame is 53% Day / 47% Dusk (F1); no fade from Dusk or Day. |
| **The user changes the time zone mid-play** | The look fades to the new target over 3 s (R2). |
| **DST change at 02:00 while playing** | Both sides are Night (w 1); nothing visible changes. |
| **The device clock is wildly wrong** | The Scene shows the look for that clock; no network check (K-08). |
| **Return from the background after hours** | The first frame is the wall-clock look (no fade). After > 30 min the App Shell shows the Title (K-22), same rule. |
| **Weather changed in the panel** | Fades in over ~2 s under the dim (R3); on close it is fully there. |
| **Weather set to cloudy with windy on** | Windy has no effect (R4); clouds drift at their normal speed. |
| **Rain at Day, windy** | 2–3 pale clouds drift ×2, streaks tilt 15°, the sky loses 10% saturation. |
| **Mashing with snow** | Flakes fade to half within 0.5 s; back to full 1 s after the last ignored press with an empty queue (R3a). |
| **Mashing with snow under Reduce Motion** | ×0.25 of the base count, half speed (R3a, R8). |
| **The gate challenge opens during snow** | The flakes stop where they are; on a wrong answer they continue from there (R9). The look keeps following the wall clock. |
| **The challenge stays open across 16:00** | The look's crossfade runs under the gate (wall clock); motion is still stopped. |
| **A parade starts at 16:07** | The lift's target mixes peach and amber by `lookBlend` (F5). |
| **A frozen parade** | The lift holds at its current λ (play clock). |
| **The keyboard row turns on** | The ground line moves up by `row_lift`; the hills and ground follow on the next frame (R6). |
| **A 32:9 ultra-wide Mac window** | The visible rect is about 2560 u wide (x −640…1920); mirrored hills cover it (R6); counts cap (F4). |
| **The glyph rises through falling snow** | Flakes near the glyph fade by the halo factor (F3d); none cross its centre. |
| **Weather stored as an unknown value** | The Settings Store gives `clear` (its R6); the Scene shows clear. |
| **Title at night with snow** | The same night sky and snow (R10). |

## Dependencies

**Upstream (the Scene reads):**
- **Settings Store** (`design/gdd/settings-store.md`): `weather`, `windy`, change notifications.
- **Reveal Stage** (`design/gdd/reveal-stage.md`): the visible rect and ground line (R10, F1), the play clock and
  `freeze`/`resume` (R8), the glyph box and halo state. **Interface ask:** publish `mashing` (queue length ≥ 1 or an
  ignored press in the last 1 s, R3a).
- **Cast Rendering** (`design/gdd/cast-rendering.md`): the halo's current glow radius (R5) and the glyph edge model
  (F8, K-25), which R5's build check shares.
- **Parade** (`design/gdd/parade.md`): `paradeWalking`.
- **Accessibility:** the Reduce Motion flag.

**Downstream (read the Scene):**
- **Parent Gate & Grown-up Panel:** `look`, `lookBlend` for the moon. **Queued follow-up:** the gate draws the
  daytime moon (70% in Morning and Day) and takes `lookBlend`.
- **Cast Rendering:** `look`, `lookBlend` and `skyMidL` for the per-look glyph and creature changes of art bible §2
  (its R4, R5, R7, F8: the amber `#80450f` / cream edge switched on `skyMidL`, K-25; the saturated halo in Morning and
  Day; at Night the palest stop dropped, the halo at 70%, the creature's 15% ambient dim).
- **App Shell & Title:** the same Scene on the Title (R10).
- **Parade:** the mirrored hills under the walk on wide windows (R6).

- **Privacy & Kids Compliance** (`design/gdd/privacy-kids-compliance.md`): the Scene is clock and hand-picked
  weather only, with no network, location or data; any live weather is a PKC-13 change that re-opens that GDD
  (TASK-034 stays the starting point).

**Normative:** K-08, K-12, K-20, K-22, K-24, K-25; TASK-034; art bible §1, §2, §4, §6, §7.

## Tuning Knobs

| Knob | Value | Safe range | Source | Effect |
|---|---|---|---|---|
| boundaries | 06:00 / 10:00 / 16:00 / 19:30 | ±2 h each, in order | art bible §2 (proposal, tuned in play) | when each look starts |
| `crossfade_min` | 15 | 5–60 | art bible §2; K-24 (starts at the boundary) | how long a look change takes |
| `jump_fade_s` | 3 | 1–10 | K-24 | fade after a clock or zone jump |
| `weather_fade_s` | 2 | 1–5 | K-24 | fade of a panel weather pick |
| `sky_mid_y` | 330 | 250–420 | one-shot (0.55 of 600) | where the mid band sits |
| cloud count / speed | 2–4 / ≤ 8 u/s | art bible caps | art bible §2 | cloud cover |
| `rain` base / speed / length | 55 / 420 u/s / 18 u | 40–70 / 250–600 / 10–30 | art bible §2 (count); proposed (speed, length) | rain density |
| `snow` base / speed / sway | 45 / 20–40 u/s / ≤ 0.3 Hz, 12 u | ≤ 60 / art bible / 0–20 u | art bible §2 | snow density |
| `windy_tilt_deg` | 15 | 0–20 | art bible §2 (≤ 20°) | wind lean |
| `mash_factor` / `mash_window_s` / `mash_fade_s` | 0.5 / 1 / 0.5 | 0.25–1 / 0.5–2 / 0.2–1 | art bible §2 Mashing row; proposed; `mash_window_s` is owned here (Reveal Stage R10 cites it; Audio's window is `chime_window_s`) | weather thinning while mashing |
| Reduce Motion count / speed | 0.5 / 0.5 | 0–1 | K-24 | calmer weather |
| `lift_amount` | 0.35 | 0.1–0.5 | K-24 | horizon warmth in a parade |
| lift targets | peach `#f0c9b0` / amber `#d9a070` | L ≤ 0.69, not Letter Gold | art bible §2; proposed amber | the warm colour |
| sun position / radius | Morning (1060, 470) low, Day (980, 140) high / 46 u | clear of the moon's rect and the glyph box | proposed | where the sun sits |
| base stars | Morning 4, Day 0, Dusk 46, Night 50 | ≤ 50 | art bible §2, §6; one-shot | star density |

## Visual/Audio Requirements

- Colours: the art bible §2 table for every look; weather per §2; the caps of §2 and §4 (R5).
- Flat fills, no texture; only the sky and ground use a gradient (art bible §6).
- No sound (R11).

## UI Requirements

None. The weather picker is in the grown-up panel (Parent Gate & Grown-up Panel GDD), stored by the Settings Store.

## Cross-References

- `design/gdd/systems-index.md`: system #15.
- `design/gdd/settings-store.md`: R1 (`weather`, `windy`), R6, R10.
- `design/gdd/reveal-stage.md`: R8 (play clock, freeze), R10 and F1 (visible rect, ground line, draw order).
- `design/gdd/cast-rendering.md`: R4 and F8 (edge model), R5 (halo radius), the measurement plan for the
  SVG-rendering ADR (under R11) and AC-17 (the device run).
- `design/gdd/parade.md`: `paradeWalking`, F3 (the walk on wide windows).
- `design/gdd/hint-letters.md`: the sky band, R12 (hint bubbles).
- `design/compliance/TASK-034-kids-weather-rules.md`.
- `production/team/decisions.md`: K-08, K-12, K-20, K-22, K-24.
- `prototypes/letter-morph-dinosaur/index.html`: `drawSky`, `drawGround`, `bakeScenery`.

## Acceptance Criteria

Logic criteria use an injected wall clock, play clock, settings and rect. Screenshots are retained in
`production/qa/evidence/`.

1. **AC-1 Boundaries.** F1 gives the table's phase and weight for 15:55, 16:07, 16:15, 23:00 and 06:05.
2. **AC-2 First frame.** Launching at 16:07 draws the 0.467 blend on the first frame, with no fade.
3. **AC-3 Clock jump.** With the app in front at 12:00 (Day), setting the clock to 21:00 fades to Night over 3 s
   (± one frame); the same change while in the background shows Night on the first frame back.
4. **AC-4 Weather caps.** For each weather, the element counts, opacities, speeds and sway stay within R3's limits on
   the four F4 rects; rain and snow show 2–3 clouds; clear shows none.
5. **AC-5 Build check.** The check runs the 160 cases of R5 with Cast Rendering F8's edge model and passes the
   shipped data (≥ 3:1 at w 0 and 1, lowest 4.36:1; ≥ 2.5:1 at the samples inside, lowest 2.68:1; ≥ 2.5:1 at L_x,
   2.57:1). A test palette with a cloud at L 0.72, a look
   at w 1 below 3:1, or the old edge (amber `#8a4b12`, cream at 85%: 2.32:1 inside) fails the build and names the
   case. The 1 s switch dissolve is not a case.
6. **AC-6 Windy.** With windy on: rain and snow tilt 15° and their clouds drift ×2; with cloudy or clear nothing
   changes.
7. **AC-7 Panel pick.** Picking snow in the panel reaches full count within 2 s ± 0.1 s, before the panel closes.
8. **AC-8 Kept.** Snow picked, app quit and relaunched the next day: snow is shown (K-12).
9. **AC-9 Mashing.** With snow and a queue of 1, the visible flake count is half the base within 0.5 s; 1 s after
   the queue empties with no ignored press, it is back to full. With Reduce Motion on too: a quarter.
10. **AC-10 Halo.** With the glyph's halo shown, a weather element at the glyph box centre has alpha 0, one at
    0.2 × r has at most 0.11 × its base alpha (F3d: smoothstep(0.2) = 0.104), and one at r or beyond has its full
    alpha.
11. **AC-11 Two clocks.** Under `freeze()` for 20 s: every element's position is unchanged, and the look's blend
    weight keeps changing with the wall clock (a freeze from 16:00 to 16:00:20 moves w from 0 to 0.022); after
    `resume()` the elements continue from where they stopped.
12. **AC-12 Extension (screenshots).** On the four Reveal Stage F1 rects (11" and 13" iPad, 16:9 and 21:9 Mac),
    the sky and ground fill the screen with no bar, no seam at x 0 or 1280, and the sky above y 0 equals the top
    stop.
13. **AC-13 Ground line.** With the keyboard row on, the hills and ground move up by `row_lift` on the next frame.
14. **AC-14 Horizon lift.** During a parade at Dusk, the horizon stop reaches the F5 colour within 0.6 s and returns
    within 0.6 s after the walk; at 16:07 the target is the F5 mix.
15. **AC-15 Reduce Motion.** With the flag on: clouds do not move, rain and snow are at half count and half speed
    with the tilt kept, and stars do not change alpha.
16. **AC-16 One moon, one sun.** At Night the Scene draws no moon disc and no sun; in Morning and Day it draws the
    sun `#ecd29a` and no moon disc (the gate's moon is drawn by the Parent Gate).
17. **AC-17 Title.** The Title at 21:00 with snow shows the Night sky and snow, with no lift.
18. **AC-18 No network, no sound.** The Scene's code calls no network or location API and requests no audio
    (code review and a build check over its sources).
19. **AC-19 Device cost.** The F6 worst case is part of Cast Rendering's single device run (its measurement plan
    under R11, AC-17) (NOT ASSESSED until
    then).

## Open Questions

None for Luan; K-24 answered all of them. Follow-ups for other GDDs (queued by the leader):
- **Cast Rendering:** the per-look glyph and creature changes, blended by `lookBlend` (game-dev-ios).
- **Parent Gate & Grown-up Panel:** the daytime moon, from `look`/`lookBlend`.
- **Reveal Stage:** publish `mashing` (R3a).

**Resolved (Luan, K-24, 2026-11-18):** Q1 the crossfade starts at the boundary; Q2 a clock jump fades over 3 s; Q3
a panel weather pick fades in over ~2 s; Q4 rain and snow show 2–3 pale clouds; Q5 the lift is 35% toward peach by
day and amber by night; Q6 Reduce Motion: clouds still, rain and snow at half count and speed, stars steady; Q7 no
weather sound; Q8 the Title shows the weather. **Leader decisions:** one moon (the gate's); the sun follows the §2
table.
