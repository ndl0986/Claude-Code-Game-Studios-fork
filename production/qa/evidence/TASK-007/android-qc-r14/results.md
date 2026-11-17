# TASK-007 Android QC, round 14 (native Kotlin, build beea731)

**Overall r14 verdict: PASS**, with one sub-item **NOT ASSESSED** because of the test environment: FrameClock at slow 0.1 (§6a). Everything the leader listed passes:
- the skin hint hand;
- the W17 fist (the banner kept on the training finish);
- the W20 skip-warning layout, both paths and the medal rule;
- the W18 leave card: keep, leave to the title, the entry lock, keys, the run discarded and nothing written;
- the preview APK;
- the short regression. FrameClock at real speed is exactly 51 frames, 4 of 4.

| Item | Value |
|---|---|
| Builds | Debug `beea731`, sha256 `c74e5dd17b840a6286d45382f8234a2868382b4819259455d2184dc56e0bb59b`. Preview, sha256 `4d74806c55ee0ab7494a738a0f3d305fdb6aadb54c5ab7042b36fe82d1386b16`. QC re-hashed both on the Mac and on the device after install, and both match the leader's. |
| Diff against the preview build `73efb30` | a5e8c37 (hint hand skin + cuff), c1c8fbe (W17 fist, W20 icons and order), beea731 (W18 leave card), plus the docs and strings merges. FrameClock and the frame loop are **unchanged** (GameView only gains the opt-in recorder and the P/Esc/Enter → card handling). |
| Device | `emulator-5554` (mp17863), landscape, k ≈ 0.488 |
| Host load | Several iOS-build spikes (up to 86). One cold start took 58.8 s at load 69 (not a defect). Runs at load ≥ 20 are marked invalid and were rerun. |
| Tools | `hint.py` now detects the skin hand + cuff. `run4.py` now uses the W20 skip-warning layout: it detects at gold (1010, 480) and cream (560, 480), and taps Keep reading at (820, 529) and Skip anyway at (410, 529). Both are committed in `production/qa/tools/android/`. |

## 1. Hint hand (ASSET-033): PASS

Lossless screencaps, `special` stage, 14 frames each in VI and EN, plus the beat-1 walk hint.

- **In the hand region (28 frames):**
  - skin `#F1C9A0`: 90 101 px;
  - cuff `#FFF6E3`: 25 311 px;
  - ink `#3A2A1F` outline: 52 024 px;
  - **`#F5C9A0`: 0, white `#FFFFFF`: 0, red cuff `#D9342B`: 0**, so no white glove is left.
- **Shape:** a child's hand pointing at Cờ, with a cream sleeve cuff and the ink outline (`r14-01b-hint-hand-closeup.png`). It looks the same in VI and EN and on the walk hint (`r14-01/02/03`).
- **Placement (AC12, visible square):** across 104 hand blobs, every hint pixel is at y ≥ 276, and the hand reaches x 1065.6, outside Cờ's pad_min square (1075–1223). Two blobs touch the *drawn* Cờ rim at its largest pulse. That is the same fingertip contact as r12 observation (b), which the leader accepted.
- Judged against ASSET-033 only, per the leader's note. The dev README's iOS-glove reference row is out of date and is not carried into this report.

## 2. W17: PASS

The hold-meter (beat 3) special pad shows a **clenched fist**: skin `#F1C9A0`, ink outline, cream cuff, in VI ("Cờ") and EN ("Flag"); the label waits for D-34 (`r14-10-holdmeter-fist-vi/en(-pad).png`). The training finish's special pad still shows **the banner** (`r14-11-training-finish-banner-pad-vi(-pad).png`).

## 3. W20 skip warning: PASS

- **Layout (VI/EN, `r14-20-skipwarn-*`):**
  - **"Đọc tiếp / Keep reading"** is on the **right**, gold, big and pulsing (the default), with an **open-book** icon. Its fill is x 594.7–1049.2 (≈ 454, mid-pulse) and 173–174 tall.
  - **"Vẫn bỏ qua / Skip anyway"** is on the **left**, white, smaller, with a **skip-arrow (»)**. Its fill is x 237.8–589 (≈ 344–351) and **150.7 tall**.
  - Both are ≥ pad_min (147.5).
- **Paths:**
  - Keep reading returns to intro box 1 (`r14-21`).
  - Skip anyway skips the intro into beat 1 play (`r14-22`).
  - A real tap on Bỏ qua opens the warning (`r14-23`, `r14-26`).
- **Medal rule:**
  - **A run that skips** (first warning Keep reading, second Skip anyway, then a perfect quiz) saves `stars=3, completed=true` and **no medal**. Results say "Đọc hết câu chuyện để nhận huy hiệu nhé", and the title shows 3★ with a grey medal (`r14-24/25`, `r14-prefs-after-skip-run.xml`).
  - **A run that chooses Keep reading and then reads everything** saves `stars=3, completed, medal=true`. Results show "Nhận được huy hiệu!", and **after a relaunch the title shows 3★ + gold** (`r14-26/27/28`, `r14-prefs-after-keep-reading-run.xml`).

## 4. W18 leave card: PASS

| Check | Result | Evidence |
|---|---|---|
| Pause menu | "Chơi tiếp" big on top; "Về bản đồ" smaller, below, with a map icon | `r14-31-pause-menu-vi`, `r14-40-pause-menu-en` |
| Card | Map picture; "Về bản đồ? / Leave the story?"; "Về bản đồ / To the map" cream, small, left, map icon; "Chơi tiếp / Keep playing" gold, big, right, pulsing, ▶; **no red** | `r14-32-leave-card-vi`, `r14-41-leave-card-en` |
| Chơi tiếp → menu, run intact | Card Chơi tiếp → pause menu (`r14-33`) → resume (`r14-34`). The hero's legs (x 443.2–476.0) and the scenery (sky disc x 919.5–1025.7) are **identical** before the pause and after the resume. | `r14-30`, `r14-34` |
| 0.25 s entry lock | A tap on the card's **Chơi tiếp** and, in a separate run, on its **Về bản đồ** 0.12 s after the card opens: **both dropped**, the card stays (and the early Về bản đồ does not leave). A later tap works. | `r14-35`, `r14-36` |
| Keys | **P, Esc and Enter** on the card each return to the pause menu (Chơi tiếp) | `r14-37-key-*` |
| Leave | Card **Về bản đồ** → **the title** (expected until TASK-025's map; not filed) | `r14-38-after-leave-title` |
| Run discarded; saved progress kept; nothing written | Start after leaving opens a **fresh intro at box 1** (`r14-39`). The title still shows **3★ + gold medal**. The save file is **byte-identical** before and after the leave, and its **mtime is unchanged** (1794891907). | `r14-38`, `r14-39` |

## 5. Preview APK: PASS

- `install -r` succeeds: `com.galaxyandsun.daidatanhhung.preview`, `0.1.0-preview`.
- No DEBUGGABLE flag; `run-as` → "package not debuggable".
- A launch with debug extras (`startScreen play --ei beat 3`) opens the plain title (`pv14-01`).
- UNSIGNED badges are on the title, every story box and the quiz, and the "Bản chơi thử" line shows.
- **All four changes appear in the preview, reached with real taps only:**
  - the W20 skip warning (`pv14-03`);
  - the skin hint hand on beat 1 (`pv14-04`) and on the hold (`pv14-05`);
  - the **fist** on the hold-meter pad (917 skin px, `pv14-05-holdmeter-fist.png`);
  - the pause menu and **leave card**, then leave → title (`pv14-06/07/08`).
- The full mission played (autoplay with skips) through to the quiz. 0 FATAL/ANR.
- The preview's training-finish banner pad was not captured separately; it is the same code as the debug build (§2).

## 6. Short regression

| Item | Result | Measurement |
|---|---|---|
| **a. FrameClock, real speed** | **PASS** | Pause 0.32 s after the Cờ tap, then resume. Resume frame → night = **0.850, 0.850, 0.850, 0.851 s = 51 frames** (resume frame + 50 sim frames) in 4 of 4 runs, load 7.2–8.8. |
| **a. FrameClock, slow 0.1** | **NOT ASSESSED** (test environment) | Today the emulator stalls during the long slow-motion hold, and **the r13 build stalls too**. The app's own frame-time recorder (`debug.ddah.frametime`) logged intervals up to **383–517 ms**, even at load 6–8. Intervals over 250 ms exceed FrameClock's clamp (by design), which drops sim time and stretches the hold. ft1's 383 ms stall exceeds the clamp by 133 ms wall = 13 ms game, which matches its 0.853 s. Results at load < 20: r14 0.842, 0.852, 0.847, 0.914, 0.853, 0.840; the r13 control under the same conditions gave 0.837, 0.840, 0.842. Every out-of-range run has a stall > 250 ms after the resume. Idle, the app runs a clean 16.7 ms per frame with or without screenrecord, so this is host contention, not an r14 change (r14 doesn't touch FrameClock or the loop). Runs at load ≥ 20 are invalid and not listed. |
| b. Debug paths write no progress | **PASS** | After `pm clear`: results/newmedal, quiz past the end, unlock, skip-warning "Skip anyway", and the new **pause → leave card → Về bản đồ** each left **no save file**. A normal launch saved `seen_open` only (`r14-60`). |
| c. Tap lock (0.35 s mash) | **PASS** | Dialogue lines held 1.683, 1.750, 1.735, 1.750, 1.749, 1.750, 1.767, 1.749 s (≥ 1.5), load 5.0. |
| d. Partner ratio | **PASS** | 143 / 230 px = **0.622** (`r14-62`). |
| e. Full mission → quiz → 3★ + medal | **PASS** | §3, keep-reading run: all beats, ending, quiz 5/5, 0 retries; 3★ + medal, still there after a relaunch. |
| logcat | **PASS** | Crash buffer since boot: **empty**; 0 FATAL, 0 ANR. |

## Environment

- No emulator stop; 0 foreign input on 5554. The `input keyevent` P/Esc/Enter came from QC.
- Not assessed, as before: sound, a real low-end phone.
