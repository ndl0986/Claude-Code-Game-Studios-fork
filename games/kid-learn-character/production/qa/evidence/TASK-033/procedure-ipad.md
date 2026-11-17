# TASK-033: measuring press → picture and press → sound on the child's iPad

Simulator numbers say little about a real iPad's touch, display and audio path. This procedure gives the real
numbers with a phone camera. It takes about 20 minutes. Until someone runs it, every **iPad device** number in
`design/tech/TASK-033-anim-runtime.md` is **NOT ASSESSED**.

## What you need
- The child's iPad (note the model and iPadOS version: Settings → General → About).
- The spike app installed on it (game-dev-ios builds it with the Personal Team, as for the last game's device
  run).
- A phone that records **slow motion at 240 fps** (iPhone: Camera → Slo-Mo, set 240 fps in Settings → Camera →
  Record Slo-mo). At 240 fps each video frame is 4.17 ms.
- For the sound check: a quiet room. The phone's microphone records the roar.
- Optional: a hardware keyboard paired with the iPad.

## Set-up
1. iPad: brightness up, Low Power Mode off, sound up, silent mode off, plugged in.
2. Open the spike app. Choose **A SpriteKit** (later repeat with **B Rive**).
3. Put the phone on a stand looking at the iPad from the side, so one shot holds **the finger, the key "D" and
   the middle of the screen** (where the letter appears).

## Check 1: press → first picture (5 presses per runtime)
1. Start the slow-motion recording.
2. Tap **D** firmly, once. Wait until the dinosaur has formed (about 2 s). Repeat 5 times.
3. Stop the recording.
4. For each press, step through the video frame by frame (Photos → Edit shows frames; or any player that steps
   frames):
   - **Frame A:** the first frame where the fingertip touches the key (the finger stops moving / the skin
     flattens).
   - **Frame B:** the first frame where the screen changes (the letter's glow appears).
   - Latency = (B − A) × 4.17 ms.
5. Write the five numbers in the table below.

## Check 2: press → first sound (3 presses per runtime)
1. Record slow motion with sound, close to the iPad's speaker.
2. Tap **D** 3 times, 3 s apart.
3. In the video, find frame A (finger touches) and the first frame where the roar's waveform starts (iMovie
   or any editor that shows the audio waveform; or listen frame by frame).
4. Latency = (sound frame − A) × 4.17 ms. Phone audio and video can be offset by a few ms; treat this as ±10 ms.

## Check 3 (if a keyboard is paired): key → picture
Same as check 1, filming the keyboard's **D** key and the screen together.

## Check 4: mash (30 s)
Tap all three keys fast with several fingers for 30 s, then press **Log**. Note whether anything stutters,
freezes or doubles up. The summary at the top right shows maxActiveMorphs (should be 1).

## Results (fill in)

| Runtime | Check | Press 1 | 2 | 3 | 4 | 5 | Median |
|---|---|---|---|---|---|---|---|
| SpriteKit | touch → picture (ms) | | | | | | |
| SpriteKit | touch → sound (ms) | | | | — | — | |
| Rive | touch → picture (ms) | | | | | | |
| Rive | touch → sound (ms) | | | | — | — | |
| SpriteKit | keyboard → picture (ms) | | | | | | |

iPad model / iPadOS: ______ · Phone / fps: ______ · Date: ______ · By: ______

**Reading the numbers:** under ~100 ms feels instant to a person; the concept's "Every Press Answers" needs the
key to light up at once. The display alone adds up to one refresh (16.7 ms at 60 Hz, 8.3 ms at 120 Hz).
