# Android QC helpers (TASK-007, emulator mp17863 / emulator-5554)

These are the QC session's measurement scripts, kept here so a restart or reboot can't wipe them. They are rebuilt from the session transcript, with the later in-place patches applied. All coordinates are world 1280 × 720, mapped with K = 1.28055, OX = 448.5, OY = 74 (landscape, k ≈ 0.488). The scripts are QC-only and never touch game code.

**Setup:**

```sh
QCW=<work dir>                # scratch dir: outputs (png, mp4, logs) land here, not in the repo
cp production/qa/tools/android/* $QCW/
cd $QCW
swiftc -O frames.swift -o frames && swiftc -O sheet.swift -o sheet
export QCW EV=<evidence dir>  # EV defaults to .../evidence/TASK-007/android-qc-r12
source h.sh; source tt.sh; source dj.sh; source fhm.sh
```

Then run `zsh emuwatch.sh &` (with EMULOG=<emulator log>) and `zsh intwatch.sh &`.

| File | One line |
|---|---|
| `h.sh` | Shell basics: `$A` adb, `$P` package, `wt`, `tap`, `shot` (screencap to `$EV`), `launch` (am start with debug extras). |
| `tt.sh` | `tt name 'script' [sleep]`: runs a fastmt script under `getevent` and appends the kernel down/up timing (script echo cut to 100 chars) to `$EV/input-timing.txt`. |
| `wt.py` | Runs a world-coordinate multi-touch script through `mt.py`, using `sendevent`; each event costs ≈ 0.5 s, so don't use it for timing. |
| `mt.py` | Generates the device-side `sendevent` script for multi-touch on `/dev/input/event1`. Sends ABS_MT_PRESSURE and TOUCH_MAJOR like `fastmt.py`; without them the app ignores the touch (r12 re-check). Signature `3 57 101012` (the input watcher uses it). |
| `fastmt.py` | Streams raw `input_event` structs through one `cat`, so taps hold for exactly their scripted length. Use it for every timing test. |
| `mash.py` | `mash.py X Y N [interval] [hold]`: a fastmt script of N taps. |
| `tl.py` | Timeline: slot-0 taps every IV from T0 and a slot-1 pad held PH of every PP s (env TX/TY/IV/T0, PX/PY/PH/PP), output as a fastmt script. |
| `dj.sh` | `dj name "<am extras>" ntaps [x y] [reclimit]`: debug-jump, record, mash every 0.35 s, then a deliberate tap; pulls the mp4. |
| `run4.py` | Full-flow autoplay, title to quiz: `run4.py <tag> read\|skipwarn\|skipnowarn`. It detects screens with pixel probes and HUD dots. |
| `quiz3.py` | Quiz autoplay with a slot plan per question, e.g. `'2;1;2;0;0'` for a perfect run. It reuses `run4.py`'s probes. |
| `frames.swift` | `frames dump <mp4> <outdir> <t0> <t1> [width]` and `frames probe <mp4> "<rects>"`: per-frame PNGs or per-frame mean colours. Pass width 2400 for full resolution. |
| `sheet.swift` | Contact sheet of PNGs. In zsh, pass the list as `${=sel}`. |
| `boxes.py` | Run it by full path (it finds `frames` next to itself). `boxes.py <mp4> [thr] [y0] [y1]`: times where the panel text strips change (rolling-lock box changes). |
| `boxes2.py` | `boxes2.py <mp4> t0 t1 y0 y1 [x0 x1]`: the 12 largest frame-to-frame changes of thin strips, in time order (env THR/LAG). |
| `fhp.py` | `fhp.py mp4 t0 t1`: per frame, whether pads are visible, the banner cloth top (x 300) and day/night sky; prints changes. |
| `fhp2.py` | `fhp2.py mp4`: banner top, day/dim/night sky and pause overlay per frame; prints changes. |
| `fhm.sh` | `fhm mp4`: per-frame Cờ pad, banner-top band and sky probes through `frames probe`, printing transitions. |
| `scan.py` | `scan.py col\|row W A B`: runs of similar colour along a world column or row on the live screen. |
| `bbox.py` | `bbox.py x0 y0 x1 y1 RRGGBB[,…] [tol]`: world bbox of a colour on the live screen. |
| `px.py` | `px.py wx,wy …`: RGB at world points from a raw screencap. |
| `pngpx.py` | Library, no CLI: `load(png)` decodes a screenshot PNG for `pbbox.py`, `fig2.py` and `hint.py`. |
| `fig2.py` | `fig2.py frame.png [heroX0-X1] [partnerX0-X1]`: hero and partner heights (hair top to shoes, device px), their ratio, and the gap between them. Check the gap by eye when a hut is behind them. |
| `hint.py` | `hint.py png…`: pads (cream/gold regions) and the white hint glove in world coords; flags overlap with a pad's drawn box and hint pixels above y 276. |
| `rn.sh` | `source rn.sh; rn <mp4> [scale]`: pause-dim and day/night transitions, then last resume frame → first night frame, in wall s and game s (wall × scale; 0.1 for slow 0.1, 1 for real speed). |
| `handtrack.py` | `handtrack.py <dir of full-res frames>`: per frame, pause dim, the hint hand's x (world y 400) and the Cờ pad's width, for checking that a resume causes no jump. |
| `pbbox.py` | `pbbox.py file.png x0 y0 x1 y1 RRGGBB tol`: world bbox of a colour in a saved screenshot. |
| `shot.sh` | `shot.sh <delay> [out.png]`: screencap plus a 900 px preview `v.png`. |
| `emuwatch.sh` | Every 2 s, watches the emulator log (`$EMULOG`) and the qemu process. On a stop it records the time and process snapshots in `emu-stop-evidence.txt`. |
| `intwatch.sh` | Every 2 s, logs host processes that could inject input (adb, monkey, sendevent, input), with their parent chains, to `intwatch-ps.txt`. |
