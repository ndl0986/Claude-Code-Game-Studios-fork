# Mac session 1: results (TASK-134)

**Session paused by Luan after D1a** (2026-11-20, no new date). D1 did not pass, so no M row was started; every M row is NOT ASSESSED and is carried to the next Mac session.

**Who:**
- QC: game-qc-ios, writing the results as the session runs.
- Driver: game-dev-ios.
- Luan presses the physical keys and does the gestures.

**Date:** 2026-11-20. MAC FREE is granted by Luan for this session (K-34).

**Mac:** Mac16,8, macOS 27.2.1; built-in "Color LCD" 3024 × 1964 Retina (main) + an external "LG FULL HD" 1920 × 1080 display. The serial and hostname are never recorded.

**Build under test:** `DeviceSpike` macOS at **4a51386d**, which names this folder (ADR-0011 D6). The gate is `4a51386d/spike-check-mac.txt`: every item PASS, exit 0, ad-hoc signed, sandbox only. It includes the dead-man: every lock auto-unlocks after `-deadman` s (180 tonight), and if the main thread doesn't answer in 2 s it ends the process.

**Rules:**
- **Spike runs are ADR evidence, never AC evidence** (device-checks plan, Spike runs). A row not run is **NOT ASSESSED**,
  never a pass.

**Masking:** team ID, Apple ID, certificate ID, `$HOME`, paths, the Mac's hostname and serial. Screenshots show the
app's own windows only; no desktop captures are committed.

| Check | Result | Build | Feeds | Evidence | Notes |
|---|---|---|---|---|---|
| D1 Dry run (recovery) | **NOT PASSED**: D1a launched 13:29:02 (`DeviceSpike -screen lock -deadman 180`, run directly; `pgrep` none before, 13:28:54); the app **quit normally, exit 0, at 14:17:01** (not the dead-man's `_exit(3)`; stdout/stderr empty, so no dead-man line); `pgrep` none after, 14:17:41. No "locked" report from Luan reached the driver, so the `pkill` step, the `-deadman 30` auto-unlock, "Hang main 10 s" and chord → overlay → Unlock **were not run** | DeviceSpike Lock (4a51386d) | session safety | `D1/d1-log.txt` | Whether the lock was ever shown, and what quit the app, is not recorded. A normal quit leaves no presentation options behind, and nothing is left running |
| M-1 Input Monitoring (the read exercised) | **NOT ASSESSED** (session paused by Luan; D1 not passed, so no M row started) | DeviceSpike Keys | ADR-0007 D4 | `M-1/` screenshots + `tccutil` output + `keys-log.txt` | scoped `tccutil reset ListenEvent com.galaxyandsun.devicespike`; read ON; "key-state read called (n=…)" with n > 0, or NOT ASSESSED |
| M-2 ⌘ window before the chord | **NOT ASSESSED** (session paused by Luan; D1 not passed, so no M row started) | DeviceSpike Lock | ADR-0007 D3 | `M-2/launch-log.txt` | settings read → monitor installed ≤ 5 s |
| M-3 Physical keyboard and trackpad, lock on (both modes) | **NOT ASSESSED** (session paused by Luan; D1 not passed, so no M row started) | DeviceSpike Lock / Keys | ADR-0008 mode; ADR-0007 keyboard part | `M-3/` screenshot per item + `table.md` + `keys-log.txt` | each R2 item blocked or not **per mode**; key-ups under ⌘ recorded |
| M-4 Two displays (both modes) | **NOT ASSESSED** (session paused by Luan; D1 not passed, so no M row started) | DeviceSpike Lock | ADR-0008 | `M-4/` | cover on the 2nd display; key-window log |
| M-5 Crash with the lock on (both modes) | **NOT ASSESSED** (session paused by Luan; D1 not passed, so no M row started) | DeviceSpike Lock | ADR-0008 (acceptance gate) | `M-5/` | `kill -9` restores the Dock, menu bar and desktop |
| M-6 Sleep and wake (both modes) | **NOT ASSESSED** (session paused by Luan; D1 not passed, so no M row started) | DeviceSpike Lock | ADR-0008 | `M-6/` | lock re-applied after login |
| M-7 Ways out | **NOT ASSESSED** (session paused by Luan; D1 not passed, so no M row started) | DeviceSpike Lock (stub gate) | ADR-0008 (acceptance gate) | `M-7/` | stub overlay; the production re-run has the real gate |
| M-10 Mac window and ppi | **NOT ASSESSED** (session paused by Luan; D1 not passed, so no M row started) | DeviceSpike Render | closes ADR-0006 V6/V7 | `M-10/` | 960 × 540 pt; full screen; the 72 dpi unknown case if a display reports it |
| M-12 Flash gate (Mac) | **NOT ASSESSED** (session paused; also, the F2 detector, ADR-0013 G3, doesn't exist yet) | DeviceSpike Render + frame dump | ADR-0013 rehearsal | `M-12/` | NOT ASSESSED unless the F2 detector tool exists |
| M-13 Render measurement (Mac) | **NOT ASSESSED** (session paused by Luan; D1 not passed, so no M row started) | DeviceSpike Render | ADR-0009 D1 | `M-13/` | the Overlap check first; A-candidate (effect node), B-load, original A (information) |
| M-14 No click (Mac speaker) | **NOT ASSESSED** (session paused by Luan; D1 not passed, so no M row started) | DeviceSpike Audio | ADR-0010 | `M-14/` | tap measure (Δ, start delay vs rewind) + listening; P-7's open pop to split |
| M-8, M-9, M-11, M-15, M-16 | NOT ASSESSED | — | — | — | the production app is needed |

**After the session:** DeviceSpike not running (`pgrep -x DeviceSpike` none at 14:17:41); it ended by a normal quit, so no presentation options are left. No relaunch until a new date (Luan). MAC FREE ends with the pause.

**Evidence checked by QC:** the branch adds only text files under `TASK-134/` (no PNGs). Masking scan of `D1/d1-log.txt` and the earlier gate logs: no `$HOME` or scratch path (the app path is `<app>`), username, hostname, serial, team ID, certificate ID or Apple ID.
