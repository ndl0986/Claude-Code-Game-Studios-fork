# Dải Đất Anh Hùng: Android (vertical slice)

TASK-007. This is the **native vertical slice** of one mission (Trần Quốc Toản), built to prove
the game on Android devices. It is **not yet the production codebase**: the full build follows
the epics and stories, and this code is kept, refactored or rewritten as they decide.

- Kotlin + Android SDK only, no game framework (Luan, 2026-11-14). The one library is
  kotlinx.serialization (approved). JUnit 4 is used for tests only.
- A `SurfaceView` with a render thread. The render thread runs a `Choreographer` loop with a
  fixed 1/60 s step and an accumulator (the frame delta is clamped to 0.25 s), draws through
  `lockHardwareCanvas`, and plays sound through `SoundPool` (USAGE_GAME).
- The spec is `design/gdd/` (mission-flow, side-scroll-combat, quiz-and-stars,
  hints-and-onboarding). The functional reference is the TASK-003 browser prototype @203d73e.
- Content comes from `content/` (ADR-0001). `content/data` is bundled in every build;
  `content/samples` is bundled in debug builds only.

## Build and run

You need JDK 17 and the Android SDK at `~/Android/sdk` (platform 35, build-tools 35.0.1).

```bash
cd android
export JAVA_HOME=/opt/homebrew/opt/openjdk@17   # the system java is 1.8
echo "sdk.dir=$HOME/Android/sdk" > local.properties
./gradlew :app:testDebugUnitTest :app:assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n com.galaxyandsun.daidatanhhung/.GameActivity
```

**TODO (pre-release):** raise `compileSdk` and `targetSdk` from 35 to **36** before any Play
upload. Play has required API 36 for new apps and updates since 2026-08-31. Luan chose 35 for
now. This needs `sdkmanager "platforms;android-36"`.

## Layout

| Path | What |
|---|---|
| `app/src/main/java/.../core/` | Pure Kotlin with no `android.*` imports. It holds the content model and loader, the validator (R2, R4–R16, R4b), the claim gate, the quiz and stars, the mission simulation, the screen flow and Mulberry32. |
| `app/src/main/java/.../` | The Android layer: `GameActivity` (immersive, cutout, insets, prefs), `GameView` (loop, input), `Renderer` / `Figures` / `Draw` (placeholder art drawn in code) and `Audio` (placeholder synthesised tones). |
| `app/src/test/` | JUnit tests. They run every shared fixture in `content/fixtures/`, validate `data/`, `samples/` and `drafts/`, and test the mission rules (telegraph, block, flee, hints, frame order). |

## Rules worth knowing

- **Firing:** menu buttons and quiz cards fire on **touch-up inside**. This is a deliberate
  change from the prototype, to avoid stray palm taps. The ◀ ▶ / attack / defend pads act on
  **touch-down**. Pointers are tracked by id; cancel, focus loss and pause release them all.
- **Safe rect:** the world is 1280×720, letterboxed inside the per-side maximum of the system
  bars (ignoring visibility, so pads don't jump), the display cutout and the mandatory gesture
  insets. It is recomputed on every insets change. Pads are at least `pad_min` (72 dp) across.
- **Audio** is created in `GameApp.onCreate`. Start stays disabled until every sound has loaded,
  so the first tap is never silent (browser QC O8). The tap tone plays at most once per 80 ms.
- **Claim gate (R12):** `assembleRelease` runs `:app:contentGate`. It fails while any claim
  cited by a bundled hero is not approved, or when a schema MAJOR is newer (R11). Debug builds
  play with `UNSIGNED Cxx` badges instead. At run time, a release build hides an unsigned
  mission and logs it.
- **Saved data (D-16, D-07):** `lang`, the best `stars.<hero>`, `completed.<hero>`,
  `seen_open.<hero>` and `medal.<hero>`, and nothing else. They are written with a synchronous
  commit at quiz finish, before results. `seen_open` is also written on every title load.
- **Beats (D-08 B):** walk, hold-meter, training, fight and reach-the-flag. Non-fight beats show a
  card before play; fights show a caption after. Beat starts follow mission-flow F5 (`beatX`).
- **QC builds:** a build handed to QC is committed and copied to
  `production/qa/builds/TASK-007-<hash>.apk` (git-ignored). Evidence is captured on a separate
  AVD, never on the QC device during a round.

## Debug screen jumps (screenshots)

```bash
adb shell am start -n com.galaxyandsun.daidatanhhung/.GameActivity \
  --es startScreen quiz --ei q 2 --es stage wrong --es lang en
```

- `startScreen`: title, intro, play, caption, pause, ending, quiz, results, unlock, skipwarn (the
  D-07 warning over the intro).
- `beat`: the beat number for play and caption. `q`: the question number for quiz. `stars`: the
  star count for results and unlock.
- `stage`: for play, `start`, `card` (a non-fight beat's card), `telegraph` (fight), `meter`
  (hold-meter at 60%), `blocks` / `special` (training steps) or `encounter` (reach-the-flag). For
  quiz, `wrong` or `right`. For results, `nomedal`.
- `--es hero sample` loads the test-only sample hero. `--es missionFile <file>` plays a draft
  mission from `content/drafts/heroes/<id>/`.
- `--ez freeze true` draws without stepping, to capture a 1.1 s telegraph.
- Keys mirror the prototype for QC with `adb shell input keyevent`: A/D or the D-pad move,
  J/Space attack, K defend, Enter next, P pause, M mute, L language, 1–3 answer.
