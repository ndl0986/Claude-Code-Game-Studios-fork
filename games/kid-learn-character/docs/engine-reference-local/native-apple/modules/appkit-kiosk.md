# AppKit kiosk (macOS child lock-in)

| Claim | Status |
|---|---|
| `NSApplication.presentationOptions` "should be in effect for the system when this app is active"; an invalid combination raises | **SOURCED** — https://developer.apple.com/documentation/appkit/nsapplication/presentationoptions-swift.property (TASK-033 research) |
| `currentSystemPresentationOptions` is KVO-observable; options apply only while the app is active | **SOURCED** — https://developer.apple.com/documentation/appkit/nsapplication/currentsystempresentationoptions |
| With `[.hideDock, .hideMenuBar, .disableProcessSwitching, .disableForceQuit, .disableSessionTermination, .disableHideApplication, .disableAppleMenu]` (+ `.disableScreenCornerInteractions` on 27): ⌘H, ⌘Q, ⌘Space held; Dock and menu bar hidden | **PROVEN (TASK-033)** on a real Mac, keys injected at the HID tap (`evidence/TASK-033/lockin/`) |
| `.disableScreenCornerInteractions` is macOS 27.0+ and needs `.hideDock` / `.autoHideDock` | **SOURCED** — https://developer.apple.com/documentation/appkit/nsapplication/presentationoptions-swift.struct |
| Native full screen (`window(_:willUseFullScreenPresentationOptions:)`) vs a borderless window at the screen frame | **NOT SOURCEABLE**: App Shell R7 leaves it to the Mac build (ADR-0008) |
| A crash with the kiosk on leaves the Mac usable | **NOT SOURCEABLE**: Child Lock-in's `kill -9` test, ADR-0008's device slot |
