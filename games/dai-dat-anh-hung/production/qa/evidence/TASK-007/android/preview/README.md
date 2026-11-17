# TASK-007 Android preview build (D-37) evidence

Device: emulator-5556 (devandroid002). APK: `assemblePreview`, signed with the local key (CN=Dai Dat Anh Hung preview, O=local).

APK checks (aapt / apksigner): package `com.galaxyandsun.daidatanhhung.preview` (D-38), label "Dải Đất Anh Hùng (preview)", version `0.1.0-preview`, no `debuggable` flag (`run-as` refuses it), signed; no sample or draft content in the assets. `assembleRelease` still fails on the R12 content gate (C01–C16).

| Shot | Checks |
|---|---|
| 01 | Launched with debug extras (`startScreen results`, `newmedal`): ignored, the title shows. UNSIGNED badges and the "Bản chơi thử" test line show; the mission is not hidden |
| 02–04 | Start → intro → part 1 plays |
| frametime-DRYRUN-emulator-5556 | `frametime.sh` dry run on the emulator, 40 s of play: three 10 s summaries. **Not a device measurement** (an emulator with software GPU); the real-phone run waits for Luan's phone |
