# Developer pre-freeze pass for iOS r8 (not QC evidence)

game-dev-ios's run-and-observe check before freezing r8, on its own Simulator "iPhone 18 Pro – dev-ios"
(iOS 27.0, FB836E51-D39E-42C3-A60E-96159EE6516C), shut down afterwards. QC's device was not used.
Screens via debug launch arguments (`-beat N` is 1-based; `-stage card|ask|caption|telegraph|flagnear`).

**What k the iPhones resolve to and which quiz layout they get** (r8c): the world is fitted to the safe rect
(Input Rule 1), so k = min(safe w / 1280, safe h / 720). This dev Simulator resolves to k ≈ 0.529; QC's iPhone 18
Pro reference is k 0.517. With the corner block at 18 + P (P = pad_min / k), the reference quiz cards would end at
432 + P and Tiếp starts at 702 − P, so the **small quiz layout** applies for k < 72/135 ≈ 0.533: **both iPhones get
the small layout** (cards on Tiếp's row while choosing; after the right pick the right card in the left slot, the
why line right of it, Tiếp 450 wide at x 812–1262), and each new question takes the entry lock.

| Shot | Checks |
|---|---|
| 01–02 intro VI / EN | Placeholder still: the hero's determined portrait in a drum ring, 256 at y 45–301, centred, clear of pause/sound; no hero sprite behind the panel (story-screens §5.2, AC12) |
| 03 beat card EN (walk), 04 beat card VI (training) | Placeholder 208 at y 25–233, ≥ 8 above the "Part 1 / Phần 3" label (28 px, #FFC531, ink outline); no play sprites, no beat dots, no flag |
| 05 caption EN (sample hero) | Placeholder 256 above "Part 2"; the sample hero has no portrait art, so the frame shows its grey stand-in |
| 06 dialogue VI line 1, 07 dialogue EN ask line | Background dimmed black 0.30; no play sprites, no dots; the speaker's portrait and the ask hint hand still show |
| 08 ending EN | Its own still, full-bleed (pic.scene_tqt_ending, the r8d redraw), no placeholder, no sprite. Note for art: the redrawn flag's pole top sits under the pause/sound corner |
| 09 training EN (banner beat) | Stuck arrow gold #FFC531 with an ink outline, rotated, beside the dummy on the side away from the hero, fully below the motto bar |
| 10 reach-the-flag VI, telegraph | The "!" beside the enemy's head at head height, away from the hero, below the bar (HUD AC17) |
| 11 reach-the-flag EN, `-stage flagnear` | **Banner-beat goal flag (leader call, parity): pole 10 × 180 (top y 290, foot on the ground), cloth 92 × 60 at the pole top (y 295–355)**, fully below the bar (≥ 276), drawn under the bar's layer (before r8 it drew over the motto). The stuck arrow points at the pole + cloth from the side nearer the centre |
| 12 quiz VI choosing, 13–14 quiz EN / VI right | The small layout at k 0.529: cards on Tiếp's row; after the right pick the right card in the left slot, the why line right of it, Tiếp 450 wide |
| 15 title VI | The corner block 18 from the top/left (sound), the hero card and Start unchanged |
| 16 training EN, slow motion ×0.1 (frozen build, from the UI case's attachment) | QC r5 N1: "Oof!" on the day village sky with the **ink** outline (SkyContrast picks ink on #A9D3EC/#CDE6EE; cream only on the dark camp band) |

Input Rule 13b (every story box and dialogue line takes the rolling lock) is covered by GameCore
`EveryBoxLockTests` (intro, beat card, caption, the 9-line Bình Than dialogue with its ask lines, a deliberate tap
at 0.6 s, two quick ask taps, the quiz lock only at small k) and by the UI cases `R8CasesUITests` (results below).

## Automated results

- **GameCore** `swift test`: 134/134, including EveryBoxLockTests, StoryPlaceholderTests, HintPlacementTests (mutation-checked),
  CornerBlockTests, QuizSwitchTests, PopOutlineTests (SkyContrast: the pop outline by the sky's colours, QC r5 N1) and
  FullRunMashTests (a full run from the title with Tiếp mashed every 0.35 s: medal earned and saved, 3★, every story box
  held ≥ 1.5 s; mutation-checked).
- **Full suite on the pre-flag build** (4141da0 + the r7 NOT ASSESSED changes, own Simulator, 4 app + 14 UI cases, ~80 min with
  the ~300 s XCTest teardown per case): 12 UI passed; the two new mash cases failed **in the test code**, not the app:
  the debug log kept only 24 entries and the press entries pushed the first dialogue lines out, and the hold was measured to the
  next log entry (a press) instead of the next box. Fixed (log 120, holds between place changes) and re-run on the frozen build.
  The ◀-as-the-card-appears case was exercised inside the lock (press log "locked": true) on its first launch.
- **Frozen build c388736** (`production/qa/builds/TASK-006-ios-c388736/`, run with its own `ios-touch-tests.sh`, ONLY per case,
  own Simulator): 6/6 passed: R8 dialogue mash (every line ≥ 1.5 s, 9 lines in order), R8 intro mash, R8 pause/sound inside the
  lock, R8 placeholder / no sprites / no top stack, B7 attack mash (`-stage flag`, draws the flag), slow-motion hit (draws the
  flag; adds shot 16). Shots 08, 10, 11 were re-shot on this build.
- **Pre-flag build only** (the full suite above): the other 8 UI cases (R2-03, ◀→▶ slide, ▶ across a beat change, B1, 15b, title
  card tap, skip warning → quiz → 3★ relaunch, ◀ as the training card appears) and the 4 app unit tests. The flag change is
  render-only and none of these draws the flag.

**Release check (this freeze's sources):** Release built three times into one derived-data path: A1, A2 (touch-and-rebuild
control) and B (every `#if DEBUG` block removed from `GameScene.swift` and `DaiDatAnhHungApp.swift`). Each links, then stops at
the R12 content gate (claims unsigned), as designed. The executable is byte-identical in A1, A2 and B (B relinked); the B
objects differ only in shifted source-line debug info. `strings` finds no `debugState`, `resetProgress`, `sprites_visible`,
`dots_visible` or `lock_context` in the executable.
