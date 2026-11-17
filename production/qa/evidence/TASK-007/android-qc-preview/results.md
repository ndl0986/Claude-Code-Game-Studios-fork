# TASK-007 Android QC: D-37 preview build (73efb30)

**Verdict: PASS (8/8).** This is a short check of the preview build, not a full regression (the leader's scope).

| # | Check | Result | Evidence |
|---|---|---|---|
| 1 | sha256 | **PASS** | `7abaecc1c335f0ecc9c8a20cad8a39f7ed69b814940dfacc42bcab1fee4192b3`. QC re-hashed it on the Mac (`TASK-007-73efb30-preview.apk`) and on the device after install; both match the leader's hash. |
| 2 | Package, label, side by side | **PASS** | `com.galaxyandsun.daidatanhhung.preview`, versionName `0.1.0-preview`, label **"Dải Đất Anh Hùng (preview)"** (`badging.txt`). Installed with `install -r` **next to** the normal debug build `com.galaxyandsun.daidatanhhung` (r13 3183874), and both are listed (`packages.txt`, `dumpsys-packages.txt`). Each app has its own save. |
| 3 | Not debuggable | **PASS** | No `DEBUGGABLE` in pkgFlags (the debug build has it). `run-as com.galaxyandsun.daidatanhhung.preview` → **"run-as: package not debuggable"**; `run-as` on the debug build works (control) (`run-as.txt`). |
| 4 | Debug extras ignored; no sample or draft hero | **PASS** | Six launches: plain; `startScreen results` + `newmedal`/`stars 3`; `startScreen play --ei beat 4 --es stage finishright`; `startScreen quiz --ei q 5`; `hero sample`; `startScreen ending --es lang en`. **Every one opens the same VI title** (`pv-01…06-launch.png`): no jump, no language override, no sample hero, and only Trần Quốc Toản is listed. The save afterwards holds only `seen_open` (no stars or medal from the "results" jump). |
| 5 | UNSIGNED badges + "Bản chơi thử" | **PASS** | Title: "UNSIGNED C01,C02" on the hero card and the "Bản chơi thử" line. Every story box, dialogue line, card, the ending and the quiz cards show their UNSIGNED badges (`pvrun-01…10`). |
| 6 | Full mission, progress saves and survives a relaunch | **PASS** | From the title: Start, autoplay through all 5 beats (intro, cards, dialogue with the ask, hold, training, reach-the-flag), the ending (`pvrun-09`), then the quiz 5/5 with 0 retries. 0 skip warnings (load 8.2 → 4.9). Results: 3★ + "Nhận được huy hiệu!" (`pv-20`). Prefs: `stars=3, completed=true, medal=true, seen_open` (`pv-prefs-after-run.xml`). **Force-stop and relaunch: the title shows 3★ + gold medal** (`pv-21`), and the save is unchanged. |
| 7 | logcat | **PASS** | 8 preview starts: **0 FATAL, 0 ANR**, 0 `DaiDat` W/E, 0 "hiding mission" (`logcat-summary.txt`). |
| 8 | `phone-install.sh` refuses emulators (optional) | **PASS** | The 73efb30 copy, run with `emulator-5554` and with `emulator-5556`: **"is an emulator; this script is for a real phone", exit 2**. It stops before the key step, and `~/.config/daidatanhhung` was unchanged. |

Notes:
- The preview was launched with `am start -n …preview/com.galaxyandsun.daidatanhhung.GameActivity`; monkey was not used. Autoplay input is QC's own sendevent and fastmt.
- Not assessed (outside this scope): a real phone (D-37's purpose), sound, the frame-time recorder (`debug.ddah.frametime`).
