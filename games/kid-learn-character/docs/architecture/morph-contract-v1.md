# Morph contract v1 ("morph-v1")

**Status:** Proposed with ADR-0001 (TASK-035, 2026-11-17).
**Shared fixture:** `games/kid-learn-character/content/fixtures/morph-contract-v1.json`.
**Reference implementation:** the TASK-033 spike's `MorphCore` (a throwaway prototype). This document, not that
code, is the contract.

The stardust morph turns a glyph outline into an object silhouette with N particles. Every app (Swift now, Kotlin
later) must compute **the same particle positions**. A port passes when it reproduces every case in the shared
fixture within **±1e-3** (unit-box units). game-dev-android's independent Kotlin port matched the TASK-033 case
bit for bit.

What this contract fixes: path parsing, sampling, the random numbers, pairing, and particle positions over time.
What it does **not** fix (each app's own ADR):
- how particles are drawn (size, colour, twinkle, blending);
- how the glyph and the object picture are drawn (the later SVG-rendering ADR);
- audio, input, lock-in.

**Versioning:** any change to a rule below is a new contract version (v2…). The fixture is regenerated **only** on
a version bump, and its `"contract"` field names the version.

## 1. Inputs
- `glyphPath`, `silhouettePath`: path data strings in the subset of section 2. They are **morph input data**:
  the particles' start and end points. They are not how the glyph or the object is drawn.
- `spec`, with times in **seconds from the press**:
  - `count` N (≥ 1);
  - `seed`, an unsigned 64-bit integer, written as a **decimal string** in JSON;
  - `glow`, `dissolve`, `travel`, `spread` (< travel);
  - `drift` and `swirl` (unit-box units).
- A "reduced" timing set (Reduce Motion / Android "Remove animations") is just another `spec`. The rules don't
  change.

## 2. Path subset and tokenizer
Scan the string one character at a time, building a current number:
- **A letter other than `e`/`E`** ends the current number and is a command token.
- **Space, comma, `\n`, `\t`** end the current number.
- **`-`** starts a new number (ending the current one) **unless the current number is empty or ends in `e`/`E`**.
  `10-5` is 10 and −5; `1e-5` is one number.
- **`.`** starts a new number when the current number already contains `.` **and contains no lowercase `e`**.
  `-.5.5` is −0.5 and 0.5. Note the v1 quirk: only lowercase `e` blocks this rule.
- **Any other character** (digits, `+`, `e`, `E`) is appended to the current number.
- At the end, the last number is flushed.

Numbers are parsed as plain decimal doubles (`1e1` = 10, `2E+1` = 20). Producers must emit only plain decimal
numbers.

**Commands:** `M m L l H h V v C c Q q Z z`. Any other letter is an error.
- The current point starts at (0, 0). Lowercase means relative to the current point. For `C`/`Q`, every control
  point of a relative command is relative to the point at the command's start.
- A number where a command is expected repeats the previous command. **After `M`/`m`, further pairs are
  `L`/`l`.**
- `M`: ends the current subpath, sets the current point and the subpath start, and begins a new subpath with that
  point.
- `L`, `H`, `V`: append the new point.
- `C` (cubic) and `Q` (quadratic): flattened with exactly **16 segments**. Append the points at t = k/16 for
  k = 1…16, using the Bernstein form. Cubic: (1−t)³·P0 + 3(1−t)²t·C1 + 3(1−t)t²·C2 + t³·P1. Quadratic:
  (1−t)²·P0 + 2(1−t)t·C + t²·P1.
- `Z`: if the subpath's last point differs from its first, append the first. Then end the subpath; the current
  point becomes the subpath start. A number directly after `Z` is an error.
  - **v1 quirk:** a drawing command after `Z` without a new `M` starts a subpath **without** the start point.
    Producers must emit `M` after every `Z`.
- **A subpath counts only if it has 2 or more points.** A lone `M` is dropped everywhere, including the bounding
  box.

## 3. Sampling (N points, then the unit box)
1. **Segments:** every pair of consecutive points in every kept subpath, in order. **Jumps between subpaths are
   not segments.**
   - The length is **`sqrt(dx·dx + dy·dy)`, written out exactly like this**. Ports must **not** use a library
     `hypot` (e.g. `kotlin.math.hypot`), which rounds differently at the last bit.
   - Zero-length segments are kept.
2. `total` = the sum of the lengths. If N = 0 or total = 0, the result is empty.
3. For k = 0…N−1:
   - `target = total * k / N`, computed in that order;
   - while (not on the last segment) and `acc + len[si] < target`: `acc += len[si]; si += 1`;
   - `f = len[si] > 0 ? clamp((target − acc) / len[si], 0, 1) : 0`;
   - the point is `a + (b − a)·f`.

   `acc` and `si` carry over from one k to the next. The first point is the first subpath's start.
4. **Unit box:** take the bounding box of **all points of all kept subpaths** (the whole flattened path, not the
   samples). `side = max(width, height)` (1 if that is 0); `cx`, `cy` = the box centre. Each point becomes
   `((x − cx)/side, (y − cy)/side)`. The longer side is 1, the box is centred on (0, 0), and **y points down**.

`from` = sample(glyphPath, N); `to` = sample(silhouettePath, N).

## 4. Random numbers: SplitMix64
State `s` (UInt64) = seed. With wrap-around (modulo 2⁶⁴) arithmetic and logical (unsigned) shifts:
```
next():  s = s + 0x9E3779B97F4A7C15
         z = s
         z = (z ^ (z >>> 30)) * 0xBF58476D1CE4E5B9
         z = (z ^ (z >>> 27)) * 0x94D049BB133111EB
         return z ^ (z >>> 31)
nextUnit() = (next() >>> 11) * 2^-53          // a double in [0, 1)
```
For seed 0, the first three outputs are 0xE220A8397B1DCDAF, 0x6E789E6AA1B965F4 and 0x06C45D188009454F. Each
fixture case also lists `rngFirst4` for its own seed, as decimal strings.

## 5. Pairing and per-particle draws (one RNG, in this order)
1. `perm = [0, 1, …, N−1]`. If N > 1, for i = N−1 down to 1: `j = floor(nextUnit() · (i + 1))`, then swap
   `perm[i]` and `perm[j]`. Particle i flies from `from[i]` to `to[perm[i]]`.
2. Then for i = 0…N−1, four draws in this order:
   - `driftX = (2·nextUnit() − 1)·drift`
   - `driftY = (2·nextUnit() − 1)·drift`
   - `delay = nextUnit()·spread`
   - `bow = (2·nextUnit() − 1)·swirl`

## 6. Position of particle i at time s
`smooth(u) = v·v·(3 − 2v)` with `v = clamp(u, 0, 1)`. Let p = from[i], q = to[perm[i]], d = (driftX, driftY).
- **s ≤ glow:** p.
- **glow < s ≤ glow + dissolve:** `p + d·smooth((s − glow)/dissolve)`.
- **otherwise:**
  - `a = p + d`;
  - `u = smooth((s − glow − dissolve − delay)/(travel − spread))`;
  - control point `c = ((a.x + q.x)/2 − bow·(q.y − a.y), (a.y + q.y)/2 + bow·(q.x − a.x))`;
  - position = `(1−u)²·a + 2(1−u)u·c + u²·q`.

At `s ≥ glow + dissolve + travel` every particle is exactly on `to[perm[i]]`.

## 7. The shared fixture (`content/fixtures/morph-contract-v1.json`)
- **Fields:**
  - `contract` = "morph-v1", `tolerance` = 1e-3;
  - `cases[]`, each with `id`, `glyphPath`, `silhouettePath`, `spec` (seed as a string), `rngFirst4` (strings),
    `from`, `to`, `pairing`, `times` and `positions[time][particle] = [x, y]`;
  - `tokenizer[]`: `d` plus the expected raw (un-normalised) `polylines`.
- **Cases:**
  - `D-dinosaur` (the TASK-033 case, N = 240);
  - `3-relative`: a digit glyph to a silhouette written with `m h v c l q z`, N = 120;
  - `count-1` (N = 1);
  - `zero-length`: zero-length segments and a lone trailing `M`.
  - Each is checked at s = 0, mid-dissolve, half the duration, and the end.
- **Tokenizer cases:** `M0 0L1e1-5`, `M0 0L-.5.5`, `M10-5L20-5`, `M0,0\n\tL.5.5`, `M1e-1 2E+1L3 4`.
- **How it was generated:**
  - `swift run morph-contract-fixture ../fixtures <out>` in the TASK-033 prototype's `MorphCore`.
  - Glyphs: `glyph-D.json` and `glyph-3.json`, baked from Fredoka (OFL 1.1, Version 2.001, weight 600) by
    `tools/bake-glyph.swift`. The dinosaur is a hand-drawn placeholder.
  - Checked by `ContractV1Tests` (1e-9).
- The spike's own `prototypes/TASK-033-anim-runtime/fixtures/morph-D-dinosaur.json` is the superseded pre-v1
  fixture. Its D case is the same data as `D-dinosaur`.

## 8. Producing paths (the bake tool)
Art tools export arcs (`A`), `S`/`T` shorthand, transforms and nested groups, none of which v1 parses.
- The bake tool must flatten each cast member's silhouette into **one compound path** using only the v1 subset,
  with plain decimal numbers and an `M` after every `Z`. It **fails loudly** on anything else.
- A CI check parses every path in the key table with a v1 parser.
- Glyph outlines are baked the same way from the bundled OFL font. The font name, version and licence are recorded
  next to each glyph file.
