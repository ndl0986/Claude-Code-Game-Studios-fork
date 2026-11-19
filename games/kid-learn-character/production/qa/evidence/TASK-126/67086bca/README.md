# TASK-126 — the meter light per Parade R12a / F4, at 67086bca

Headless Chrome through `.claude/scripts/one-shot-run.sh` (the game copied to a temp folder, time and chance fixed, 60
steps a second); never a person's browser or the Mac's screen. `scripted-runs.tsv`: each run's rows, paths masked.

**The scripted run** (as TASK-121's): `KeyA wait:2.4 … KeyL wait:2.4`, a press every ~2.43 s, never resting; the first
key leaves the title, so the batch is B–G. G is shown at ~19.65 s: its light launches then, its cell's fill starts at
+0.75 (~20.4 s) as the light fades, the light is gone at +0.9; G finishes forming at ~20.15 s (armed, as played in
iteration 6) and the parade is due 1.5 s later, ~21.65 s.

| Shot | Step / time | What it shows |
|---|---|---|
| `flight-midair.png` | 1206 / 20.1 s | the 16-unit Starlight star mid-curve at about (717, 112), F4's B(u) from the cast box top toward cell 6; 5 cells lit |
| `crossfade-cell-filling.png` | 1230 / 20.5 s | the light fading on cell 6 while the cell fills (litAt 20.4): one crossfade, no dip |
| `just-before-start.png` | 1296 / 21.6 s | all 6 lit with the full glow; no parade yet |
| `parade-start.png` | 1344 / 22.4 s | the parade walking in, the meter drained, H answered in front, I and J queued |

All runs: 0 crash, error, nonfinite or console rows; `uncaught 0`.
