# TASK-007 Android QC, round 12 (native Kotlin, build 1ae1560)

**Overall r12 verdict: PASS.**
- **B8 still holds in the real flow:** the partner is in front of the hero, ≈ 54 world px clear, with a linear walk-in of 0.684 s and a hold of 1.517 s.
- **The new looks match the D-18 slice spec:**
  - banner cloth `#D64A2E` with a `#E8A93B` border inside the edge;
  - the partner drawn as a follower in `#D8C9A3` / `#B9705C`, with a plain topknot and no headband, at **0.622 ×** the hero's height.
- **The camera cuts on the beat change:** the first night frame already has the hero at the camp start (the r11 one-frame lag is gone).
- **The debug-save fix works:** debug jumps write no progress, and a real run still saves 3★ and the medal.
- **The release gate fails only on R12.**
- **Regression passes:** hold, mash, pause N=1/2/3, AC34, hints, rolling lock, camp pop, quiz AC7, story AC10, ending pole, VI/EN.

There are three minor observations, none blocking (§8).

| Item | Value |
|---|---|
| Build | `1ae1560` (JVM 165 per dev). Diff against the pre-freeze `e24855a`: 93e2770 (PARTNER_S = 0.62 × HERO_S, the partner's cue target scaled to match, tools/dev/android) and 1ae1560 (ShadowStore for debug jumps, DebugSaveTest). |
| APK | sha256 `08e0e94249a82e29cebeabb6a318a5c3e8cd656d481315bf9e0d44ed88cf9737`; QC re-hashed it on the Mac and on the device after install, and both match the leader's hash. |
| Specs | docs `0f90158` (Rule 7c Looks; look sheet D-18 (11); Hints Rule 6 / AC12, visible square; quiz AC7 and story AC10 at-rest wording; story-screens §5.2 corner block) |
| Device | `emulator-5554` (mp17863), landscape, k ≈ 0.488 |
| Input | Timing input streamed through one `cat` (`fastmt.py`); kernel `getevent -lt` lines are in `input-timing.txt`. Autoplay uses `wt.py`/`mt.py` (sendevent). |
| Host load | The 1-min load is noted with each timing item. One mash run hit load 74.85 (the iOS r9 build). It is marked INVALID in `input-timing.txt` and was rerun at 10.98. Every counted timing item ran at a 1-min load of 4–11. |

## 0. Live re-check of the QC helpers (they were rebuilt after the scratchpad was wiped)

Done before any measured result. The helpers are committed in `production/qa/tools/android/`.

| Helper | Result |
|---|---|
| `fastmt.py` + `tt.sh` (load 5) | **OK.** Scripted 0.06 s tap measures 0.058 s in the kernel; 0.6 s tap measures 0.599 s; a mash with a 0.35 s period gives downs at 0.349 / 0.699; two-slot touches line up. |
| `wt.py` + `mt.py` | **Fixed.** The restored `mt.py` was an early version without ABS_MT_PRESSURE / TOUCH_MAJOR, and the app ignored its touches (the first autoplay stayed on the title). Adding pressure 80 and touch-major 6 (the same values as `fastmt.py`) fixed it; the Start tap now opens the intro. |
| `run4.py` + `quiz3.py` | **OK.** Four full real-flow autoplays reached the quiz with 0 skip warnings, and `quiz3` scored 5/5 with 0 retries twice. HUD dots: training is the second "dots 3", and the night camp starts at "dots 4". |
| `px.py`, `bbox.py`, `pbbox.py`, `scan.py` | **OK.** The live and PNG results agree within the title button's idle pulse, and both tools vary by the same amount from capture to capture. |
| `frames` / `sheet` (rebuilt with swiftc), `boxes.py` | **OK.** `boxes.py` must be run by full path. Box changes give a signal of 83–154 against noise of ≤ 10. |
| `fhp.py`, `fhp2.py`, `fhm.sh` | **They agree with each other**, but their sky probes land on figures in the night camp at this hero position, so the hold was timed from direct pad and sky probes (§1). |
| `emuwatch.sh`, `intwatch.sh` | **OK.** Both ran all round. There was no emulator stop. |

## 1. B8, real flow (run 4, `tr12d.mp4`, EN, load 4–6)

**PASS.** This is a real autoplay from the title. The training beat was recorded from the second "dots 3" into the night camp.

| Check | Result | Measurement |
|---|---|---|
| Partner placement | **PASS** | The banner is behind the hero (left). The **partner is in front (right)**, facing left toward the hero and banner (`r12-02-realflow-hold-partner-front.png`, crop `r12-02c`). |
| No overlap | **PASS** | Hero's rightmost pixel (staff end) is at device x ≈ 1854; the partner's leftmost (face) at ≈ 1923. That is **≈ 69 device px ≈ 54 world px clear** (`r12-02b-realflow-gap-zoom.png`); r11 was ≈ 40. The cloth is far left of the hero. Colour masks can't separate the figures from the hut wall between them, so the gap was read from the zoomed frame. |
| Walk-in | **PASS** | The tunic first shows at the right edge at 50.821 s (it enters from off screen, so **no fade**). It moves at a **constant 4.7 world px per frame** and stops at 51.289 s, which is **0.684 s** after the banner appears at 50.605 s (r11: 0.683). |
| Hold | **PASS** | Pads hide at 50.605 s and the night camp starts at 52.122 s: **1.517 s** (r11: 1.518). |

## 2. Looks (D-18 slice placeholders)

| Check | Result | Measurement |
|---|---|---|
| Banner cloth | **PASS** | **`#D64A2E` exactly** (lossless screencap, `finishright` hold, `r12-12-finishright-hold.png`). r11 drew `#D9342B`. The H.264 video reads it as `#D95432`, so colours were taken from screencaps only. |
| Banner border | **PASS** | **`#E8A93B`**, inside the cloth's edge on all four sides: left 4 / right 4 / top 5 / bottom 4 device px (≈ 3–4 world px, spec ≈ 4). Cloth `#D64A2E` box: world x 484.6–601.7, y 288.9–352.2. The cloth sits below the HUD bar and clear of the hero's face. |
| Partner = follower, finish hold | **PASS** | Tunic **`#D8C9A3`**, sash **`#B9705C`**, plain dark topknot, **no red anywhere on the head** (0 px), no headband and no tails, no slate or violet. |
| Partner size | **PASS** | Hair top to shoes: partner **143 px**, hero **230 px**, ratio **0.622** (dev: 143 vs 231). The same in the real flow and in `finishright`. |
| Partner = follower, blocks step | **PASS** | The same follower look. The telegraph "!" sits beside the smaller head inside the glow (`r12-32-blocks-telegraph-follower.png`). Windup, strike and Oof are as before. |

## 3. Camera cut at the beat change

**PASS.** Frame-stepped across training → night camp at full resolution (real flow, `r12-03`/`r12-04`). The last day frame is 52.105 s. **The first night frame (52.122 s) already shows the hero at the camp start** (legs at world x 443.9–474.4), and every later frame shows him at the same x. There is no one-frame lag (the r11 observation is fixed), no snap-back and no scroll. The debug path (`finishright`, mash run) shows the same one-frame cut. AC34: no dummy, partner or prop on any night frame.

## 4. Training finish, debug stages (slow 0.1)

| Case | Result | Measurement |
|---|---|---|
| `finishright` | **PASS** | The partner walks in on screen and stands in front, facing left, **53 world px** clear of the hero; the cloth is behind the hero (`r12-10…12`). |
| `finishleft`, case (d) | **PASS** | The partner **fades in** (semi-transparent in `r12-14`), walks left and stops **beyond the banner**, facing it. Cloth right edge including the border: world x **301.0** (as r11). Partner's leftmost pixel (face): **323.7**. That gives **≈ 22 px clear** (≥ 8; r11: 12). `r12-15-finishleft-hold.png`. |
| Pause AC32, every resume ≥ 0.8 s (first pause during the rise at +0.29 s game) | **PASS** | Last resume → night: N=1 **0.837 s** (load 4.8), N=2 **0.835 s** (6.2), N=3 **0.832 s** (6.4); an extra N=3 run gave 0.822 s. The first frame after a resume shows the banner fully raised and the partner at its spot at full opacity, the same as the final frame (`r12-22-*`). Nothing got stuck. |
| Mash during the hold (Cờ/Attack, 85 taps at 0.2 s) | **PASS** | Pads hide at 2.310 s and the night starts at 17.377 s: **15.067 s wall = 1.507 s game** (load 11.0; r11: 1.515). In the camp the hero stands still and cheers, with no attack and no props, so nothing carried over. |

## 5. Hints (Hints Rule 6 / AC12 @ 0f90158, visible square)

**PASS**, with one observation (§8). Lossless screencaps, 14 frames each in VI and EN:
- **Special teach hand and stuck pulse:** 81 hand-blob checks in total.
  - Every hint pixel is at **y ≥ 276** (hand y 371.7–431.1).
  - The hand sits **left of Cờ at Cờ's mid-height**, pointing at it.
  - **No hint pixel is inside any pad's visible square.** Cờ is centred at x 1149, so its pad_min square (147.5) spans x 1075–1223, and the hand's furthest point is x 1062.4: **≥ 12.8 world px outside**.
- **Blocks-step Defend hand:** it stays above the Defend pad in every frame, with no overlap.

## 6. Debug-save fix (1ae1560)

**PASS.**

| Step | Save (`shared_prefs/game.xml`) | Screen |
|---|---|---|
| Reinstall (uninstall + install) | no file | — |
| Jump `results --es stage newmedal --ei stars 3` + Next ×3 | **no file** | Results show 3★ and a medal; the title inside the same debug process shows the medal from memory (by design, `r12-save-11`). |
| Jump `quiz --ei q 5 --es stage right` + past the end | **no file** | `r12-save-12/13` |
| Jump `unlock --ei stars 3` | **no file** | `r12-save-14` |
| Jump `ending` + 6 × Tiếp | **no file** | `r12-save-15` |
| Jump `title --es lang en` | `lang=en` only (settings still save) | `r12-save-16` |
| **Normal launch** | `seen_open` + `lang` only | **Title 0★, no medal** (`r12-save-17`, `r12-save-prefs-after-debug-jumps.xml`) |
| **Real full run** afterwards (EN, autoplay + perfect quiz) | `stars=3, completed=true, medal=true` (+ seen_open, lang) | Results 3★ + "You earned the medal!" (`r12-save-18`); **relaunch → title 3★ + gold medal** (`r12-save-19`, `r12-save-prefs-real-run-after-jumps.xml`) |

An earlier real run on a cleared save (VI) also saved 3★, completed and medal, and survived a relaunch (`r12-21-title-after-real-run-relaunch.png`, `r12-prefs-after-real-run.xml`).

## 7. Regression

| Item | Result | Notes |
|---|---|---|
| Release gate | **PASS** | `release-gate-1ae1560.log`: `:app:contentGate FAILED`, *R12 hero tran-quoc-toan: claims not approved: C01–C16*, and nothing else. |
| Rolling lock, 0.35 s mash (spec: each box holds ≥ `screen_enter_lock_max` 1.5 s) | **PASS** | **Intro, real flow from the title (load 4.5):** "Long ago" was accepted after 0.93 s, because no press had come in that time (≥ 0.6 s, allowed); the next boxes held **1.766 / 1.750 / 1.751 s**. **Dialogue, all 9 lines shown in order, none skipped (load 5.0):** lines 2–9 held **1.651, 1.750, 1.750, 1.766, 1.733, 1.750, 1.767, 1.750 s**. **"Quả cam" card (load 8.6):** box 2 held **1.667 s**. |
| Deliberate taps (load 6–7) | **PASS** | After box 2 enters: taps at +0.32/+0.67 and then a **0.45 s** gap do **not** advance; the same with a **0.62 s** gap **advances**. A single tap after 4 s or 8 s advances at once. |
| Camp double pop outline | **PASS** | "Oof!": red fill, cream inner outline, ink outer outline, over the mint hill and the navy sky (`r12-33-oof-camp-*.png`). The hero's hurt blink hides him for a frame. |
| Quiz AC7 (at rest / animated) | **PASS** | VI and EN, 30 frames each. **At rest**, Tiếp's gold fill ends at y 695.8 (≈ 702 with the rim) and its top is at 555. **While pulsing**, every pixel incl. shadow is **≤ 710.6** (≤ 720). `r12-51-quiz-right-vi/en`. |
| Story AC10 (at rest) | **PASS** | Intro, 20 frames: Bỏ qua rim y 552.9–702.8 (**≈ 150 tall**, ≥ 147.5); Tiếp at rest 553.7–702.0, so top and bottom match. While pulsing, the rim reaches 705.2 and the shadow 709.9 (≤ 720). The two buttons are far apart (≫ pad_gap). |
| Ending still + corner block | **PASS** | Full-bleed in VI and EN. Pole at world **x 501–515**, right of corner_right + 8 (416); top at y 121 (`r12-50-ending-vi/en`). |
| Full run, 3★ + medal | **PASS** | §6. |
| VI/EN | **PASS** | Quiz, ending, title, results. |
| logcat | **PASS** | 39 app starts: 0 FATAL, 0 ANR, 0 `DaiDat` W/E (`logcat-r12.txt` in the scratchpad). |

## 8. Observations (minor, none blocking)

1. **Partner skin is `#F5C9A0`, not the look sheet's `#F1C9A0`.** It is the same colour the hero's face uses, and ASSET-302 says "same skin as the hero", so this is a 4-unit difference between two spec texts, not a drawing bug. For game-art-content / design.
2. **Stuck pulse vs the drawn Cờ pad:** at the pulse's largest point, the hand's ink outline reaches the pad's gold rim with **0–2 device px** to spare (`r12-30b`, row 589). It passes AC12 as written (the visible square is pad_min, ≥ 12.8 world px away), but on screen the fingertip looks as if it touches the pulsing pad. For design: should the rule cover the pulse's drawn size?
3. **Border width** is 4–5 device px (≈ 3.1–3.9 world px) for "≈ 4 px". This is fine unless "4 px" means 4 world px exactly.

## Environment

- Watchers: no emulator stop. `intwatch` saw sendevent only with `mt.py`'s signature (`3 57 101012`), so **all input on 5554 was QC's own**.
- The emulator log has host-GPU "invalid color buffer" errors, with no visible effect.
- Not assessed, as before: the sound, and a real low-end phone.
