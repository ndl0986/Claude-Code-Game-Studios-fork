# TASK-126 — iteration 7 at e9373593: the R12a meter light, armed at the 6th creature's shown

Supersedes `../67086bca/` (arming then was at the 6th's form end, 0.5 s later). Headless Chrome through
`.claude/scripts/one-shot-run.sh` (the game copied to a temp folder, time and chance fixed, 60 steps a second); never a
person's browser or the Mac's screen. `scripted-runs.tsv`: each run's rows, paths masked.

**The scripted run:** `KeyA wait:2.4 … KeyL wait:2.4`, a press every ~2.43 s, never resting; the first key leaves the
title, so the batch is B–G. G is **shown at ~19.65 s = armedAt** (Parade R2): its light launches; its cell's fill starts
at +0.75 (~20.4 s) as the light fades; the 6th cell is **full at armedAt + 1.15 (~20.8 s)**; the parade is due at
**armedAt + 1.5 (~21.15 s)**.

| Shot | Step / time | What it shows |
|---|---|---|
| `flight-midair.png` | 1206 / 20.1 s | the star mid-curve (F4's B(u)) from the cast box top toward cell 6 |
| `crossfade-cell-filling.png` | 1230 / 20.5 s | the light fading on cell 6 while the cell fills: one crossfade |
| `sixth-cell-full.png` | 1254 / 20.9 s | all 6 cells full and the glow up, before the start |
| `just-before-start.png` | 1266 / 21.1 s | still full, no parade |
| `parade-start.png` | 1314 / 21.9 s | the parade walking in, the meter drained, presses still answered (I queued) |

The start is bracketed between 21.1 s and 21.9 s, as due at ~21.15 s. All runs: 0 crash, error, nonfinite or console
rows; `uncaught 0`.
