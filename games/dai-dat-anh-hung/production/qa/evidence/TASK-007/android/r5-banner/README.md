# Banner layer at 37 px: for the layout decision (TASK-020 W9, leader's option c)

Captured by game-dev-android on its own AVD (emulator-5556), with the r5 work-in-progress code at
1d1145a. **This is not a QC build.**

| Shot | Shows |
|---|---|
| `banner-en-reach-encounter.png` | EN motto at 37 px takes **2 lines**. The red bar grows upward from the ground line (bottom 554) and covers the fighters' legs during an encounter. |
| `banner-en-training.png` | The same in training (dummies step; per-step pads, with the attack hand from above). |
| `banner-vi-training-28px-r4.png` | For comparison: r4 (c00c5e0), VI at the old 28 px, 1 line, under the ground line. VI at 37 px is still 1 line. |

Leader's call: move the bar into the sky band in **every** language (game-art-content to spec the
position). game-dev-android builds it when the spec hash arrives.
