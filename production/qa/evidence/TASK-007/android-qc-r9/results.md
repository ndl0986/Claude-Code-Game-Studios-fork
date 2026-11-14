# TASK-007 Android QC, round 9 (native Kotlin, build f92e1d2)

**Overall r9 verdict: PASS.** The ending now shows the full-bleed scene. The goal flag sits wholly below the bar. The raised training banner sits below the bar, behind the hero's head and clear of his face. The "Ối!" pop has an ink outline on the village, bamboo and river skies and a cream one on the camp. Regression: everything from r8 still passes (rolling lock, B7, 3★ + medal, small quiz, story screens, cues below the bar, title, skip warning, VI/EN). Design notes: the raised banner is visible only ≈ 0.57 s at normal speed; the camp "Ối!" sits in front of the mint hills, not the night sky, and its cream outline is ≈ 1.5:1 there; and the hint hand above "Cờ" enters the bar band.

| Item | Value |
|---|---|
| Build | `f92e1d2` (145 JVM tests per dev). APK sha256 `439aca57280bf1634eaaaa04b347f2205b2f0675931c031786762ba6757a8020`, re-hashed by QC and on the device. ea70edb was uninstalled first. |
| Specs | docs/vn-history-game-plan @ 6b01fbd (r8d 243dfcf, r8e 8b42d5f) |
| Device | `emulator-5554` (mp17863), API 36, 1080x2400 at 420 dpi, landscape, k ≈ 0.488 |
| Input | Timing input streamed through one `cat` (`fastmt.py`), with kernel `getevent -lt` lines in `input-timing.txt`. Durations come from screenrecord frames (≈ 60 fps). |
| Host load | 8–20 for the whole round (`uptime` 19.7 at install, 11 at the flow mash, 8.6 at the end). No emulator stall or crash. |
| Date | 2026-11-15 |

## 1. Ending (`pic.scene_tqt_ending`)

**PASS.** Full-bleed scene in VI and EN: lilac/peach sky, sun, red banner cloth on its pole, river and grass. **No orange tint and no figures.** The banner cloth (≈ y 55–140 world) and the sun sit above the panel's top; the pole continues behind the panel. Evidence: `r9-01-ending-vi.png`, `r9-01-ending-en.png`, and the real-flow ending in the B7 run (§5).

## 2. Goal flag on the reach-the-flag beat

**PASS.** `--es stage flag` (debug: past the encounter), measured live. Bar bottom at **y 268**. The flag's **pole is y ≈ 302–468.5** (x 1000–1005) and its **cloth y ≈ 300–369** (x 1006–1143), so the whole flag is inside y 290–470 and fully below the bar. No red-on-red (the r8 observation is fixed). After idling, the gold stuck arrow with its ink outline points at the flag **from the side away from the hero** (x ≥ 1160, y 348–412). Evidence: `r9-03-flag-near.png`, `r9-04-flag-stall-arrow.png`.

## 3. Raised training banner (after the Cờ tap)

| Check | Result | Measurement | Evidence |
|---|---|---|---|
| Position (`--ef slow 0.1`, tap on Cờ) | **PASS** | Measured on the saved frame: cloth **x 285–430, y 284–358**; pole x 280–287, y 287–440. The top is ≥ 276 (bar bottom 268 + 8). The cloth ends at the back of the hero's head; his face (skin x 430–489, y 333–389) is clear. | `r9-07-raise-banner-slow01.png` |
| **Visible time at normal speed** (asked for the design question) | — | Kernel tap on Cờ at 0 (0.08 s press). The cloth is first drawn at 2.326 s (video) and **last drawn at 2.880 s; gone at 2.895 s, so ≈ 0.57 s on screen**. Then the training beat ends: the next frame (3.01 s) is beat 5. A child barely sees it. | `rb.mp4` (scratchpad), `r9-06-raise-banner-normal.png`, `input-timing.txt` |

Note: the debug jump `--es stage special` goes straight from the training finish to beat 5 play, with no "Phần 5" card. In the **real flow** (full run, §5) the Phần 5 card ("Cùng đánh giặc") shows after training as expected (`r9R-08-next-d1.png`), so this is debug-only.

## 4. "Ối! / Oof!" pop outline per sky (sample hero, `--ef slow 0.3`, not defended)

| Sky (sample beat) | Outline | Result | Evidence |
|---|---|---|---|
| Village (beat 1) | **ink** (#403020 sampled ≈ #3A2A20) on #B0D0C8 hill/sky, ≈ 8:1 | **PASS** | `r9-11-oof-village.png` |
| Bamboo (beat 2) | **ink** | **PASS** | `r9-12-oof-bamboo.png` |
| River (beat 3) | **ink** | **PASS** | `r9-13-oof-river.png` |
| Camp night (beat 4) | **cream** (#F8F0E0 sampled) | **PASS to spec** | `r9-14-oof-camp.png` |

**Readability on the camp (as asked):** the pop sits at about y 300–330 world, which on the camp background is **in front of the mint hills (#B0D0C8), not the navy night sky** (#384068, which starts above and beside it). There the cream outline is **≈ 1.5:1** against the hill, and the red fill ≈ 2.8:1, so the word reads weakly. Against the night sky, cream would be ≈ 9.8:1, and ink on the mint hill ≈ 8.1:1. In the capture the "Ối!" is legible, but faint at its edges. This is a design call: choose the outline by what is actually behind the pop (hill band vs sky), not by the theme.

The TQT training village pop (r8) is still ink.

## 5. Regression

| Item | Result | Notes | Evidence |
|---|---|---|---|
| Rolling lock, real flow (title → dialogue → "Quả cam" card; 0.35 s mash with ▶ on a second finger, 50 s) | **PASS** | Intro 2.696 → 4.427 → 6.193 → 7.943 → play 9.693 (1.73, 1.77, 1.75, 1.75). Card 1: 13.977 → 15.643 → 17.392 → play 19.143 (1.67, 1.75, 1.75). **Dialogue, 9 lines:** 27.843 → 29.643 → 31.393 → 33.143 → 34.910 → 36.659 → 38.409 → 40.160 → 41.911 → play 43.662 (1.80, 1.75, 1.75, 1.77, 1.75, 1.75, 1.75, 1.75, 1.75). "Quả cam": 47.559 → 49.259 → play 51.010 (1.70, 1.75). | `r9-20-flow-mash.png`, `flow9.mp4` (scratchpad), `input-timing.txt` |
| B7 ending under an Attack mash (from `stage flag`, ▶ held to the flag) | **PASS** | Ending box 1 at 5.708 → box 2 at 7.341 (**1.63 s**) → quiz at 9.091 (**1.75 s**). | `r9-21-*`, `b7r9.mp4` |
| Full read-everything run, 3★ + medal | **PASS** | `pm clear`, autoplay reading every box/line, 0 skip warnings. Real-flow story screens: intro, Phần 1/3/4/5 cards, dialogue, the new ending (`r9R-01..09`). Perfect quiz with 0 retries. Prefs `stars=3, completed=true, medal=true`. Title after: 3★ and the gold medal. | `r9R-*`, `r9R-results.png`, `r9-40-title-after-run.png` |
| Small quiz layout | **PASS** | Unchanged from r8: Tiếp x 808–1264 (rim; gold 812.5–1260), y 554–701 plus a 4 px shadow to 705 (≤ 720). Right card in the left slot, why line to its right. Pill unclipped in VI/EN. | `r9-30-quiz-right-vi/en` |
| Per-question lock | **PASS** | Tiếp at kernel 0 and 0.300; Q2 shows with no card picked. | `r9-31` |
| Story/dialogue screens without the play layer | **PASS** | All real-flow story shots have no sprites, dots, goal or banner. | `r9R-01..09` |
| "!" / arrow below the bar | **PASS** | Flag arrow §2. The leader/partner/dummy cue layout is unchanged from r8 (this round's pop recordings show the "!" beside the head on all four sample skies). | `r9-04`, pop frames |
| Title card (D-27) | **PASS** | Fresh: outline (r9 skip-warning run after `pm clear`); after the run: 3★ and gold. | `r9-40` |
| Skip warning → Keep reading | **PASS** | Fresh data: "Đọc tiếp" returns to intro box 1. | `r9-32`, `r9-33` |
| VI/EN | **PASS** | Ending, quiz. | `r9-01`, `r9-30` |
| logcat | **PASS** | 16 app starts since install: 0 FATAL, 0 ANR, 0 `DaiDat` warnings. | `logcat-r9.txt` (scratchpad) |

## 6. Observation only: the special-pad hint hand above "Cờ"

**Yes, it enters the bar band.** On the training finish (`--es stage special`), the white hint hand above "Cờ" spans **y ≈ 226–307** at x 1150, so its top ≈ 42 px is inside the bar band (156–268), drawn over the red bar. Evidence: `r9-05-special-before.png`.

## Environment

- Watcher: 122 samples since install. Every input was QC's own; **no foreign input on 5554**.
- No emulator crash this round.
- Not assessed, as before: the sound, and a real low-end phone.
