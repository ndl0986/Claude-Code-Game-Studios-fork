# UIKit and AppKit input

| Claim | Status |
|---|---|
| macOS `NSEvent.addLocalMonitorForEvents` delivers keyDown with `timestamp`, `isARepeat`; returning nil swallows | **PROVEN (TASK-033)** on a real Mac |
| iPadOS `pressesBegan` / `UIKey` (`charactersIgnoringModifiers`, `keyCode` as `UIKeyboardHIDUsage`) | **PROVEN (TASK-033)** to build and run on the iPad Simulator; no hardware key pressed — device NOT ASSESSED |
| An app cannot block iPad system shortcuts; `wantsPriorityOverSystemBehavior` only reorders against text input and focus | **SOURCED** — https://developer.apple.com/documentation/uikit/uikeycommand/wantspriorityoversystembehavior (TASK-033 research) |
| Reading the OS key state on the Mac (`CGEventSource` key state) and whether it triggers a TCC prompt | **NOT SOURCEABLE**: Input AC-1k6 (TASK-057 R-2), run in ADR-0007's device slot |
| ⌘Tab, ⌘⌥Esc, Mission Control, Spaces, Globe/fn, hot corners with a physical keyboard | **NOT SOURCEABLE**: injected keys did not trigger them (TASK-033); physical-keyboard check in ADR-0007/0008 |
| `addLocalMonitorForEvents`: events before `sendEvent:`; return nil to stop dispatch; not called inside menu / control tracking | **SOURCED** (macOS 27.0 SDK `NSEvent.h`, ADR-0007 Sources) |
| A global monitor sees key events only with accessibility trust | **SOURCED** (`NSEvent.h`); not used (ADR-0007, PKC) |
| `kIOHIDRequestTypeListenEvent` (Input Monitoring) needs the user's grant | **SOURCED** (`IOHIDLib.h`); never requested (ADR-0007) |
| Whether `CGEventSourceKeyState` triggers Input Monitoring | **NOT SOURCEABLE** (header silent); ADR-0007 D4 decided by M-1 |
| `pressesBegan`: override all four press methods; handle cancelled presses | **SOURCED** (iOS 27.1 SDK `UIResponder.h`) |
| Whether macOS delivers a key-up to the local monitor while ⌘ is held | **NOT SOURCEABLE**; M-3's Keys log records it (Input R6 holds either way) |
