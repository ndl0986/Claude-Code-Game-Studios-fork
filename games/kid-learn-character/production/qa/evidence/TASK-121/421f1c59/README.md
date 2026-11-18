# TASK-121 — letter-morph-dinosaur iteration 6 at 421f1c59 (K-46)

Supersedes `../73a55436/` (iteration 5). Headless Chrome through `.claude/scripts/one-shot-run.sh` (the game copied to a
temp folder, time and chance fixed, 60 steps a second); never a person's browser window. `scripted-runs.tsv`: each run's
rows, paths masked.

**The scripted run:** `KeyA wait:2.4 … KeyL wait:2.4` — 12 different letters, a press every ~2.43 s, so the stage never
rests and the queue is never empty. The first key leaves the title, so the batch is **B C D E F G**. G appears at about
19.65 s, its light lands at ~20.25 s, it finishes forming at ~20.15 s (armed), and the parade is due 1.5 s later, ~21.65 s.

| Shot | Step / time | What it shows |
|---|---|---|
| `meter-3of6.png` | 708 / 11.8 s | the §7 meter at 3 of 6, beside the queue tokens (x 850–1018 at queue_max 3) |
| `flight-midair.png` | 1197 / 19.95 s | the light flying from G to the 6th cell, mid-arc; 5 lit; H and I queued |
| `full-glow.png` | 1260 / 21.0 s | all 6 lit with the soft full glow; no parade yet (the 1.5 s beat) |
| `just-before-start.png` | 1296 / 21.6 s | still full and glowing, no parade, H's reveal on stage |
| `parade-start.png` | 1344 / 22.4 s | the parade walking in, the meter drained, H answered in front, I and J queued |

So the parade starts between 21.6 s and 22.4 s, as due at ~21.65 s, with presses still coming. All runs: 0 crash,
error, nonfinite or console rows; `uncaught 0`.

Not shown by stills: the eases, the 0.5 Hz breathe and the drain over time; Luan's replay with the child is the check for
feel. The driver cuts its `state` row at 200 characters, so the start is bracketed by shots at fixed steps.
