# TASK-007 Android QC r12 checklist (prepared before the freeze)

Sources: dev branch commit e24855a (not frozen yet). Docs at **0f90158** (leader, replaces e9f70a9; adds Hints Rule 6 / AC12 visible-square wording): Rule 7c "Looks", look sheet D-18 (11), ASSET-302/305, quiz AC7 and story AC10 at-rest wording, story-screens §5.2 corner block.

## Setup (when the frozen hash arrives)
1. Confirm the frozen hash is e24855a or later. Diff it against e24855a and add anything new to this list.
2. Start mp17863 (emulator24.log), then run adb root, rotation lock and the watchers (update emuwatch.sh's log name).
3. Hash the APK sha256 on the Mac and on the device, compare it with the leader's, uninstall the old build, install the new one, and capture logcat.
4. Create branch qa/TASK-007-android-r12 from qa/TASK-007-android-r11 @ 4321a86. In h.sh, set EV to android-qc-r12.

## 1. B8 regression: finish hold and partner placement (real flow, autoplay as r10/r11)
- [ ] The partner is in front of the hero (right side) and faces the banner. There is no overlap with the cloth or the hero in any frame; r11 measured ≈ 40 world px clear.
- [ ] The walk-in is linear and lasts ≈ 0.67 s. When the partner enters from off screen there is no fade.
- [ ] The hold is ≈ 1.5 s (r11: 1.518 s).
- [ ] With stage finishleft, the partner fades in beyond the banner with ≥ 8 px clear (r11: 12 px). With finishright, the partner stands in front.
- [ ] Pause at N = 1, 2 and 3: every resume gives ≈ 0.82 s and never gets stuck.
- [ ] AC34: no props appear on the first night-camp frame.
- [ ] Mash during the hold doesn't shorten it (r11: 1.515 s).
- [ ] The new partner sprite is shorter (0.62 ×). Re-measure clearance with the new silhouette, including the staff reach of 140 world px.

## 2. Looks (D-18 slice placeholders)
- [ ] Raised banner cloth: colour #D64A2E (r11 drew #D9342B), sampled with pngpx in the middle of the cloth.
- [ ] Banner border: ≈ 4 px #E8A93B, inside the cloth's edge, on all sides. The cloth box is the same size as in r11 (compare the bbox with r11's), and it is still below the bar, clear of the face.
- [ ] The partner in the blocks step (stage blocks) and in the finish hold looks like a follower:
  - tunic #D8C9A3, sash #B9705C, skin #F1C9A0;
  - a plain topknot, with no headband and no tails;
  - height ≈ 0.62 × the hero's, measured from the bbox of both sprites in the same frame.
  It must not read as a second hero.
- [ ] Neither partner has slate or violet anywhere, and neither looks like an enemy.
- [ ] Blocks step regression: windup, strike, Đỡ timing and hint hands are unchanged; the stick reach is unchanged.

## 3. Camera cut at the beat change (this fixes the r11 one-frame lag observation)
- [ ] Real flow, frame-stepped across training → night camp, the same as `r11-02-realflow-first-night-f_*`. On the first night frame:
  - the hero is already at the camp start position;
  - the theme and the view change in the same frame, with no old screen x for even one frame.
- [ ] Check every other beat boundary the same way: walk → dialogue → hold → training → reach-the-flag, and sample hero beats on village, bamboo, river and camp. Look for a one-frame lag, a snap-back or a scroll.
- [ ] The camera never scrolls back. The training cap is still at xStart − 70 during the beat (Rule 15b).

## 4. Regular regression
- [ ] Rolling lock under a 0.35 s mash (intro, cards, 9 dialogue lines, "Quả cam"): each screen holds ≈ 1.7–1.8 s. A deliberate 0.60 s tap advances; a 0.45 s tap doesn't.
- [ ] Hint hands (Hints Rule 6, AC12 @ 0f90158): every hint pixel is at y ≥ 276, and **no hint pixel is inside any pad's visible square** (pad_min diameter, touch slop excluded; judge by the drawn square, not the touch rect). Check the teach hand and the stuck pulse, in VI and EN, at k 0.488.
- [ ] The camp double pop outline shows (cream inside, ink outside).
- [ ] Hold timing and the mash test.
- [ ] Full run after pm clear: 0 skip warnings, perfect quiz, prefs show stars=3, completed=true, medal=true, and the title shows 3★ and gold.
- [ ] Quiz AC7 (new wording): Tiếp's settled box ends at y 702, and every animated pixel (pulse, rim, shadow) is ≤ 720. r11 measured ≈ 706 / 710, so the r11 observation now passes under the new wording.
- [ ] Story AC10: Bỏ qua and Tiếp edges are measured at rest; animated pixels are ≤ 720.
- [ ] Ending still (r11 docs): the pole is at png x 250–258, world 500 on Android, right of x 416, so it clears the pause/sound block. Check this only if the APK has the updated scene_tqt_ending.png. The full-bleed layout shows in VI and EN.
- [ ] VI and EN on the quiz and the ending.
- [ ] logcat: 0 FATAL, 0 ANR, 0 DaiDat warnings.
- [ ] Watcher: no foreign input on 5554. Record the host load.

## Not assessed (as before)
- Sound.
- A real low-end phone.

## Added by the leader at freeze (1ae1560)
- [ ] Diff 1ae1560 against e24855a. It adds 93e2770 (PARTNER_S = 0.62 × HERO_S, the hint target moves with the partner, tools/dev/android) and 1ae1560 (debug jumps play on a ShadowStore; JVM 165).
- [ ] Partner size on screen is ≈ 0.62 × the hero's height (dev measured ≈ 143 vs 231 device px).
- [ ] Debug-save fix, after a reinstall:
  - run several debug jumps (results/new medal, quiz past the end, unlock), then a normal launch;
  - the title shows 0★ and no medal, and the prefs hold only settings + seen_open;
  - then a real full run still saves 3★ + medal across a relaunch.
- [ ] The release-gate log fails only on R12 (C01–C16).
- [ ] Note the 1-min load next to each timing item, and run those items only when the load is under ≈ 20. iOS r9 is building at the same time.
