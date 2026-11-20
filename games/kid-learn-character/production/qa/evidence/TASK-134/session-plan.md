# TASK-134 Mac session 1: recovery plan and run order

Build: DeviceSpike macOS, source **a19e8c85** (gate `a19e8c85/spike-check-mac.txt`: every item PASS, exit 0; ad-hoc
signed, sandbox only). Mac: macOS 27.2.1, built-in 3024 × 1964 Retina (main) + an external 1920 × 1080 display.
Driver: game-dev-ios (launches, logs, window-only screenshots). Results: game-qc-ios (`results.md`). Luan talks to the
leader only. Nothing is launched before Luan's "go".

## 1. Recovery (read before any locked row)

The lock (`Kiosk.lock()`) sets `[.hideDock, .hideMenuBar, .disableProcessSwitching, .disableForceQuit,
.disableSessionTermination, .disableHideApplication, .disableAppleMenu]` + `.disableScreenCornerInteractions` (macOS
27), so ⌥⌘Esc, ⌘Tab, logout and the Apple menu are off while locked. Ways out, in order:

| # | Way out | Who | Works when |
|---|---|---|---|
| R1 | ⌃⌥⌘Q → the overlay → **Close**, then **Unlock**; or hold **Quit (1.5 s)** (unlocks and quits) | Luan | the app is active and its window is key (the chord is a local monitor; it does **not** work after a focus loss, e.g. M-4 clicks on a cover, M-6 sleep) |
| R2 | **Dead-man** (new in a19e8c85): every lock auto-unlocks after `-deadman` seconds (tonight **180 s = the 3-min row limit**), log line `[lock] dead-man: auto-unlock after 180 s locked`; if the main thread is hung it ends the process after 2 s more | automatic | always, including a hung main thread or a lost key window |
| R3 | `pkill -x DeviceSpike` (SIGTERM), then `pkill -9 -x DeviceSpike` 3 s later if still running; macOS restores the Dock, menu bar and Force Quit when the process ends (proved in the dry run D1 before any other row) | game-dev-ios, from the session shell (tested: runs with no permission prompt) | always, independent of focus or the app's state |
| R4 | Hold the **power button ~10 s** (forced restart) | Luan, told by the leader | only if R1–R3 all failed; unsaved work is lost, hence the prep below |

Rules for every locked row:
- **3-minute limit per lock.** The app is launched with `-deadman 180` for every locked row (R2 enforces it); I also
  run R3 without asking at 3:00 after Luan reports "locked" if the desktop has not come back.
- **One shell kept ready**: the session that launched DeviceSpike holds the exact R3 commands; no other tool is used
  during a locked row, so no new permission prompt can block it.
- After every unlock or kill, Luan confirms "Dock and menu bar back" before the next row.
- While locked, stay on the **Lock** screen (never ◀ Menu): the lock state lives in that screen's object, so leaving
  it could leave the options applied without the overlay; if it happens, R2 or R3.

## 2. Luan's prep (before "go", ~5 min)

1. Save and **close** your work apps (M-5 kills DeviceSpike; M-3 blocks shortcuts; R4 would lose unsaved work).
2. Turn on **Do Not Disturb** (Control Center › Focus): screenshots are of DeviceSpike's own window only, but
   banners would cover it.
3. Keep the **external display** connected (M-4) and the **trackpad** usable; set the speaker volume to about half
   (M-14); be ready to **close the lid and log in** (M-6).
4. The child is out of view (DeviceSpike's screens are adult test screens).

## 3. Run order (about 1 h 50 min; each row is sent as short numbered steps when it starts)

| # | Row | Locked? | Time | What it needs from Luan |
|---|---|---|---|---|
| D1 | **Dry run** (required first): Lock (borderless) → I run R3 → Luan confirms the desktop is back. Relaunch with `-deadman 30`, Lock, wait → auto-unlock seen. Lock again, and at about 25 s tap **Hang main 10 s (dead-man test)** → the app ends by itself about 2 s after the 30 s mark (the `_exit` path) and the desktop comes back. Lock again → ⌃⌥⌘Q → overlay → Close → Unlock | yes, 3 × < 1 min | 10 min | taps, say what you see |
| 1 | **M-5** crash with the lock on: lock (each mode), I run `kill -9`; the Dock, menu bar and a usable desktop come back | yes | 6 min | describe the desktop (no capture) |
| 2 | **M-7** ways out: chord → overlay → Quit (hold 1.5 s) ends the app with the desktop usable; ⌘Q in the open overlay does nothing; the overlay is in the main window. The wrong-code and panel-OFF parts need the real gate: NOT ASSESSED | yes | 8 min | chord, hold Quit |
| 3 | **M-3** keyboard and trackpad with the lock on, **both modes** (borderless, then native full screen), in ≤ 3-min locks: ⌘H, ⌘Q, ⌘Space, ⌘Tab, ⌥⌘Esc, Mission Control / Spaces (F3, ⌃↑, ⌃←/→), 3- and 4-finger swipes, Notification Center, hot corners, Globe/fn, Touch ID, a short power-key press; keyboard part on the **Keys** screen (unlocked): every key's normalized event and whether key-ups arrive under ⌘ | yes | 25 min | press each key/gesture; say "blocked" or what happened |
| 4 | **M-4** two displays: in each mode the external display shows the cover; clicks on it do nothing; the app stays in front | yes | 8 min | click the external display; describe (no capture) |
| 5 | **M-6** sleep and wake: lock, close the lid (or display sleep), open, log in; is the lock applied again? (the dead-man's 180 s counts awake time only) | yes | 6 min | close the lid, log in |
| 6 | **M-1** no Input Monitoring prompt: F-5 `tccutil reset ListenEvent com.galaxyandsun.devicespike` (**this bundle only**, with Luan's OK); first launch: no prompt; Keys screen: key-state read ON, press ⌃⌥⌘Q and a few ⌘-combinations, read count > 0; no prompt; app not listed in Privacy & Security › Input Monitoring | no | 10 min | OK for F-5; say whether any prompt appears; look at the Input Monitoring list |
| 7 | **M-2** ⌘ window before the chord works: launch log, monitor install time after launch | no | 3 min | none (MAC FREE) |
| 8 | **M-10** window and ppi: resize to the 960 × 540 minimum, native full screen with the kiosk off; ppi readout on the built-in display and on the external one (unknown → class maximum + one log line) | no | 8 min | drag the window corner; move it to the external display |
| 9 | **M-13** Render measurement: Overlap check first, then the A-candidate, B-load and original A, 30 s each + Log stats (`-option a/candidate/b` where it saves a click) | no | 10 min | a few taps |
| 10 | **M-14** no click on a cut, built-in speaker: the Tone buttons at 100 Hz and 1 kHz (the whole-sound detector line per button), "Tone, no event", Play/Cut per bus; say per button "no", "click at start" or "click at stop" | no | 10 min | listen |
| — | **M-12** flash gate | — | — | NOT ASSESSED: the F2 detector (ADR-0013 G3) does not exist yet |
| — | M-8, M-9, M-11, M-15, M-16 | — | — | NOT ASSESSED: need the production app |

**If short on time**, skip in this order: M-10, M-2, M-6, M-13 (the iPad P-2 already has numbers). Keep D1, M-5, M-7,
M-3, M-4 (they decide ADR-0008's mode) and M-14 (P-7's open pop, now on a second device).

## 4. Evidence (masked; DeviceSpike windows only)

- Window-only screenshots: `screencapture -o -l <window id>` with the id of DeviceSpike's own window
  (`winid DeviceSpike`), never a full-screen or desktop capture. Desktop states (M-4, M-5, M-6, D1) are Luan's
  description, relayed word for word.
- Each frame is checked for notification banners before it is kept; one with a banner is deleted from disk.
- Logs: the app's on-screen log (window capture) and its launch console; UDIDs, user names and paths masked.
- At the end: DeviceSpike quit, `tccutil` state noted; nothing is left running.
