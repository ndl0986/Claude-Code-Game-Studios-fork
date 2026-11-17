# TASK-033 child lock-in on macOS: kiosk test (2026-11-17)

**Machine:** MacBook Pro (Apple M4 Pro, 24 GB) with a second display connected. macOS 27.2.1 (26B131). Spike Release
build, sandboxed. Run by `prototypes/TASK-033-anim-runtime/tools/kiosk-check.sh 0|1`.

**Method:**
- Each shortcut was posted at the HID event tap (`tools/post-key.swift`, CGEvent), one at a time, only while
  Spike was the frontmost app.
- After each one, the script recorded the frontmost app (`lsappinfo front`) and whether Spike was still running.
- Lock screen (⌃⌘Q) and log out (⇧⌘Q) were never posted.
- A screenshot of the main display was taken after each shortcut. **They were deleted unviewed except two**,
  because they showed the owner's own desktop (browser, bookmarks): not evidence material. What those two showed
  is written below.

## Results

| Shortcut | Kiosk off (baseline) | Kiosk on (`-kiosk 1`) | Valid test? |
|---|---|---|---|
| Esc, Tab | held | held (swallowed by the app) | yes |
| ⌘H hide | **escaped** (Orca came to the front) | held | **yes** |
| ⌘Q quit | **escaped** (Spike quit) | held (swallowed by the in-app key monitor) | **yes** |
| ⌘Space Spotlight | **escaped** (the screenshot shows the Spotlight panel open; the front-app check is blind to it) | held (the screenshot shows no Spotlight panel, with the Dock and menu bar hidden) | **yes, by screenshot** |
| ⌘M, ⌘W, ⌘`, ⌃⌘F | held | held | weak (Spike has one window; no visible effect expected) |
| ⌘Tab app switcher | held | held | **no**: the injected chord did not switch apps even in the baseline (it sends no separate ⌘ key-down). NOT ASSESSED; needs a physical keyboard |
| ⌘⌥Esc Force Quit | held (its screenshot shows no Force Quit window) | held | **no**: not triggered by injection even in the baseline. NOT ASSESSED |
| ⌃↑ Mission Control, ⌃→ Spaces | held | held | **no**: the front-app check can't see these overlays and the screenshots were not reviewed. NOT ASSESSED |
| ⌃⌥⌘Q parent exit | (not posted: Spike had quit) | **Spike quit, as designed** | yes |

**Also observed:**
- With kiosk on, the Dock and menu bar disappeared from the main display while Spike ran.
- `currentSystemPresentationOptions` was logged by the app at start.

**Physical-keyboard check still needed** (the iPad procedure has the same kind of manual step): ⌘Tab, ⌘⌥Esc,
Mission Control and Spaces keys, the Globe/fn key, Touch ID / power button, and hot corners.
