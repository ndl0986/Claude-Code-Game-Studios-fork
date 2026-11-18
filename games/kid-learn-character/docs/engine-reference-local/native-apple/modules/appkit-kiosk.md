# AppKit kiosk (macOS child lock-in)

| Claim | Status |
|---|---|
| `NSApplication.presentationOptions` "should be in effect for the system when this app is active"; an invalid combination raises | **SOURCED** — https://developer.apple.com/documentation/appkit/nsapplication/presentationoptions-swift.property (TASK-033 research) |
| `currentSystemPresentationOptions` is KVO-observable; options apply only while the app is active | **SOURCED** — https://developer.apple.com/documentation/appkit/nsapplication/currentsystempresentationoptions |
| With `[.hideDock, .hideMenuBar, .disableProcessSwitching, .disableForceQuit, .disableSessionTermination, .disableHideApplication, .disableAppleMenu]` (+ `.disableScreenCornerInteractions` on 27): ⌘H, ⌘Q, ⌘Space held; Dock and menu bar hidden | **PROVEN (TASK-033)** on a real Mac, keys injected at the HID tap (`evidence/TASK-033/lockin/`) |
| `.disableScreenCornerInteractions` is macOS 27.0+ and needs `.hideDock` / `.autoHideDock` | **SOURCED** — https://developer.apple.com/documentation/appkit/nsapplication/presentationoptions-swift.struct |
| Native full screen (`window(_:willUseFullScreenPresentationOptions:)`) vs a borderless window at the screen frame | **NOT SOURCEABLE**: App Shell R7 leaves it to the Mac build (ADR-0008) |
| A crash with the kiosk on leaves the Mac usable | **NOT SOURCEABLE**: Child Lock-in's `kill -9` test, ADR-0008's device slot |
| Presentation-option flags as documented in the header (Dock, menu bar, Apple menu, ⌘Tab, ⌘⌥Esc, PowerKey panel, Hide); `.disableScreenCornerInteractions` macOS 27.0+, needs `.hideDock` / `.autoHideDock` | **SOURCED** (macOS 27.0 SDK `NSApplication.h`, ADR-0008 Sources) |
| A borderless window cannot become key unless `canBecomeKey` is overridden | **SOURCED** (AppKit documentation; header has the overridable property); ADR-0008 D3 subclasses |
| Which way out a physical keyboard / trackpad still has, per full-screen mode | **NOT SOURCEABLE**; ADR-0008's decision rule (M-3, M-4) |
