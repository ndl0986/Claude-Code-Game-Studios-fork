# Dải Đất Anh Hùng: demo video (TASK-027), 2026-11-17

`daidatanhhung-demo-2026-11-17.mp4`: **3:12**, 1920 × 1080, 30 fps, H.264 (High), no audio (the build is silent), 8.7 MB. sha256 `c687c7f7bad3a868156bb0fd4f3203d3627c635fa1b3d48e203b72e2ef8be191`.

- **Build:** the Android r14 preview APK `TASK-007-beea731-preview.apk` (sha256 `4d74806c…6b16`, the build Luan installs on his phone). It was a fresh install, in Vietnamese, starting at 0★.
- **Device:** the Android emulator (mp17863, a 2400 × 1080 phone shape), not a real phone. The video is cropped to the game area (the phone's side bars removed) and scaled to 1080p.
- **Capture:** `adb screenrecord` at native resolution in three parts. Each part was rolled over on a still story box, so the joins don't show. The parts were joined and trimmed with ffmpeg. There are no debug overlays. The UNSIGNED badges on the history text are part of the preview build: the text is waiting for the history reviewer.

## What it shows (in order)

| Time | Content |
|---|---|
| 0:00 | Title card: "Dải Đất Anh Hùng / demo build (Android), 2026-11-17" (3 s) |
| 0:03 | Title screen, fresh: 0★, grey medal, "Bản chơi thử" |
| 0:05 | Story intro, 4 boxes at reading pace |
| 0:21 | First walk, with the hint hand |
| 0:27 | **Pause** once ("Tạm dừng"), then "Chơi tiếp" |
| 0:30 | Part 1 card "Khi các vương hầu họp bàn ở Bình Than" |
| 0:42 | Dialogue at Bình Than, all 9 lines, including "Xin vào!" |
| 1:20 | Part 3 card "Quả cam" and the hold meter (the fist pad) |
| 1:34 | Part 4 card "Lá cờ sáu chữ vàng" |
| 1:46 | Training: dummies, blocks with the follower partner, raising the banner |
| 2:09 | Night camp; part 5 card "Cùng đánh giặc" |
| 2:22 | The fight on the way to the Trần army's flag; the flag at 2:33 |
| 2:37 | Ending (2 boxes) |
| 2:47 | Quiz: questions 1, 2 and 5 answered correctly (3 and 4 cut for length) |
| 3:01 | Results: 3★ + "Nhận được huy hiệu!" |
| 3:08 | Back to the title, now 3★ + gold medal |

Trimmed for length: walking stretches, about 70 s of the training beat, the start of the reach-the-flag run, and quiz questions 3–4. These are jump cuts.

## Key frames (1920 × 1080, for slides)

`demo-01-story-intro.png`, `demo-02-dialogue-ask-the-king.png`, `demo-03-training-banner-raised.png`, `demo-04-reach-the-flag-fight.png`, `demo-05-quiz-right-answer.png`, `demo-06-results-3-stars-medal.png`.

## Rough on camera (for whoever presents it)

- The game was played by a QC script, not a child, so the movement is a bit mechanical: short stop-and-go walks, and repeated attack taps in training and in the fight.
- The pause menu opens over the part 1 card, not during play (the walk had just ended).
- It's the emulator. A real phone may look smoother or slower; the preview build's frame-time recorder can check that on Luan's phone.
- Placeholder art (circle portraits, simple figures, flat backgrounds) and the UNSIGNED badges are expected at this stage.
