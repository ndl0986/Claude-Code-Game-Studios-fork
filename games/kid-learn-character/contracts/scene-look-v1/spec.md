# scene-look-v1

**Owner GDDs:** `design/gdd/scene-time-weather.md` (with "Precise rules for the contract", TASK-101a) and
`design/gdd/cast-rendering.md` F8's edge switch (TASK-104); K-25. **Colours:** `design/art/art-bible.md` §2.
**Layer:** KidCore. **ADR:** ADR-0004 (D2 stream `scene-weather`), ADR-0002 (D3 wall and play clocks).
**Cases:** hand-written by game-qc-android (TASK-101), reviewed by game-art-content, with game-dev-ios for the F8 cases.

## What it covers

- **F1 look and `lookBlend`:**
  - the AC-1 table, the boundary itself (16:00 → Dusk, w 0), a half-way crossfade, and the wrap before 06:00;
  - real minutes (16:00:20 → w 0.022).
- **F2 `skyMidL`:** each look; 16:07's weighted mean; rain unchanged (the tint is luminance-preserving, SC-Q3).
- **R5 build check, all 160 cases** (4 pairs × 5 weights × 4 weathers × lift off and on):
  - each case's contrast (the better of the fill and the edge shown, the worse edge inside 0.303–0.313), its
    brightest sky value, and pass;
  - the anchors 2.68 (Night→Morning, w 0.5) and 4.36 (Day);
  - the brightest sky value includes the sun `#ecd29a` (L 0.663) wherever Morning or Day has a share, and snow;
  - three test cases that must fail: a look below 3:1 at w 1, a sky stop above L 0.69, and a sun above L 0.69
    (which passes at Night, where no sun is drawn) (AC-5).
- **F4 counts** on the four rects for rain, snow and cloudy, and the base stars by look (AC-4).
- **F8 edge switch (TASK-104):**
  - the launch edge at exactly L_x;
  - hysteresis inclusive at 0.313 and 0.303, with nothing between;
  - the dissolve at 1 per wall-clock second, and a reversal at a partial mix (0.4) coming back in 0.4 s;
  - the state kept across a background (0.306, inside the band, stays amber).
- **R2 clock jump:**
  - the wall-step threshold (SC-Q2) and the 3 s smoothstep fade of the drawn `skyMidL`, with the edge switching
    during it;
  - normal ticking never jumps; a background return shows the wall-clock look at once (AC-3).
- **R3a mashing:** the factor moves 1 per s to 0.5 and back; a quarter with Reduce Motion (AC-9).
- **R7 / F5 lift:** λ at 1/0.6 per s; the horizon L of the F5 example (AC-14).
- **R9 two clocks:** under a freeze, mashing, λ and rain positions hold while w follows the wall clock (AC-11).
- **F3 / the `scene-weather` stream:**
  - rain: clouds then streaks, 2 draws each; the fall, a wrap taking 1 draw, the windy 15° tilt;
  - snow: 4 draws each (SC-Q9).

**Not covered here, and why:**
- **Drawing, the extension, the sun and moon, no sound or network (AC-12, AC-16–18):** screenshots and code checks.
- **Device cost (AC-19):** Cast Rendering's run.
- **The panel weather fade (AC-7), the halo factor (AC-10), cloud drift and snow sway, AC-8:** looks, or
  not exactly specified (≤ limits only).

## `given` fields

- `knobs`: the GDD's values (crossfade 15 min, jump fade 3 s, jump threshold 1 min, L_x 0.308, the glyph fill and
  edge colours, the lift colours and amount 0.35, the snow colour, base stars, mash factor and fade, fade_s 0.6,
  rain speed 420, windy tilt 15°, ground y 558).
- `palette`: the art bible §2 sky stops per look (a test palette in two cases).
- `rect`, `weather`, `windy`, `accessibility {reduceMotion}`.

## Events

| Event | Fields | Emits |
|---|---|---|
| `lookAt`, `skyMidAt` | `minutesOfDay` (+ `weather`) | `look {prev, look, w}`, `skyMidL {value}` |
| `buildCase` | `prev`, `look`, `w`, `weather`, `lift` | `buildCase {contrast, maxSkyL, pass}` |
| `countsAt` | `rect`, `look`, `weather` | `counts {stars, rain, snow, clouds}` |
| `liftAt` | `horizon`, `d`, `lam` | `horizonL {value}` |
| `edgeInput` | `skyMidL` (with `t.wall`) | `edgeSwitch {to}` |
| `frame` | — (`t.uptime`, `t.wall`) | `jumpFade`, `edgeSwitch`, `wrap` |
| `weather` | `value`, `windy` | `elements {clouds, parts}` (from the `scene-weather` draws) |
| `mashing`, `paradeWalking`, `freeze`, `resume`, `background`, `foreground` | — | — |

**State (`expectState`):** `skyMidL` (drawn), `edge`, `amberAlpha`, `mash`, `countFactor`, `lambda`, `parts`.
**Field kinds:** luminances, contrasts, positions `geometry` (1e-6); times `time` (1e-9). The jump fade mixes linear
colours, so the drawn `skyMidL` is the same mix of luminances.

## Answers from the GDD authors (SC-Q1–Q10, game-art-content, TASK-101a @ 752e6b8f; CR-Q1, game-dev-ios, TASK-104 @ 5fa2bbff)

The cases follow the merged text, and sources.lock is cut on it.
