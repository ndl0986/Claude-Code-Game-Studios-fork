# TASK-003 Android QC, re-test r3 (fix commit c7f1173). INTERRUPTED, partial

**Status: partial.** This was committed early because Orca is restarting. Only B4 is finished, and it passes. Every other item is **not run yet (interrupted)**.

| Item | Value |
|---|---|
| Build | `c7f1173` (on top of `4b70244`), merged into `qa/TASK-003-android` as `6331321`. |
| Device | Android emulator `mp17863`, API 36, Chrome 133. This round uses `-gpu host`: the Mac was heavily loaded by other sessions (a VM at about 312% CPU plus the iOS Simulator), and under `swiftshader` the emulator's system process stopped responding (ANR) and swallowed taps. Those trials were thrown away. |
| Date | 2026-11-14 |

| Item | Result | Notes | Evidence |
|---|---|---|---|
| B4: Start goes fullscreen and locks landscape (15+ taps) | **PASS, 18/18** | Each trial: fresh reload, a pre-tap delay of 0–3 s, then one tap. Taps were `sendevent` holds of 0.03–0.5 s, plus 3 instant `input tap`s, at 5×3 different points on the button. All 18 went to `intro`, fullscreen, `landscape-primary`. Chrome had focus in every trial. In r2, 7 of 15 failed. | `b4-fullscreen-trials.txt` |
| B4 side effect: VI\|EN on the title arms fullscreen | not run yet (interrupted) | | |
| O5: pads clear of the bottom gesture zone in fullscreen, upward-slide behaviour, pads ≥72 CSS px | not run yet (interrupted) | | |
| O6: one tap tone per press | not run yet (interrupted). Partial finding below. | | `b4-fullscreen-trials.txt` (`tone660`) |
| Smoke: one beat by touch, one quiz answer, 0 console errors | not run yet (interrupted) | The B4 trials (18 reloads) logged no console errors; the full log check is not done yet. | |

## Partial finding for O6 (to confirm during play)

In the B4 trials, every Start press called `tone(660)` twice. In trial 1 it was called 4 times, with `audio.ac.currentTime` = 0.

- In 15 trials the AudioContext didn't exist yet (`none`), so both calls were silent no-ops.
- In trials 1, 9 and 17 the context existed with `currentTime = 0`, and the de-duplication did not stop the second call.
- Likely cause, from the code: `audio.ac.currentTime - (sfx.lastTap || -1) < 0.08`. When `lastTap` is `0`, `||` treats it as false and substitutes `-1`, so the check never fires while the context clock is at 0. A suggested fix is `sfx.lastTap ?? -1`.
- Not checked yet: whether there is still a double tone once the clock is running, during play. That is the O6 test proper.
