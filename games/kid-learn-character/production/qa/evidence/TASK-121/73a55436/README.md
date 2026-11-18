# TASK-121 — letter-morph-dinosaur iteration 5 at 73a55436 (K-44, K-45)

Headless Chrome through `.claude/scripts/one-shot-run.sh` (the game copied to a temp folder, time and chance fixed by the
driver, 60 steps a second); never a person's browser window. `scripted-runs.tsv` holds each run's rows (paths masked).

**The scripted run:** `KeyA wait:2.4 KeyB wait:2.4 … KeyL wait:2.4` — 12 different letters, one press every ~2.43 s
(a press is held 2 steps), so the child never rests. The first key (A) leaves the title, so the batch is **B C D E F G**.
Reveals then run every 3 s (hold_s) with the queue never empty, the case that never reached a parade before (K-45).

| Shot | Step / time | What it shows |
|---|---|---|
| `meter-3of6.png` | 672 / 11.2 s | the meter at 3 of 6 (B, C, D formed); E waiting as a queue token |
| `meter-6of6-batch-full.png` | 1206 / 20.1 s | G, the 6th, forming: all 6 steps lit; H and I queued |
| `parade-start-21s.png` | 1260 / 21.0 s | the parade walking in from the left, the meter emptied, H's reveal in front, I queued: presses keep being answered |
| `before-TASK-121-same-moment-21s.png` | 1260 / 21.0 s | the same inputs on the previous version (the plan tip before this change): no parade |
| `end-30s.png` / `before-TASK-121-end-30s.png` | 1806 / 30.1 s | the parade's last walker leaving at the right / the previous version: still no parade |

All runs: 0 crash, error, nonfinite or console rows; `uncaught 0`.

Not shown by a still: the fill and empty eases (meter_fill_s 0.5 s, one ease each, never periodic) and the parade's own
walk; Luan's play with the child is the check for feel. The game's `state` row is cut at 200 characters by the driver,
so the parade's start is shown by the shots at fixed steps, not by a state field.
