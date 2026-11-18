# UIKit and AppKit input

| Claim | Status |
|---|---|
| macOS `NSEvent.addLocalMonitorForEvents` delivers keyDown with `timestamp`, `isARepeat`; returning nil swallows | **PROVEN (TASK-033)** on a real Mac |
| iPadOS `pressesBegan` / `UIKey` (`charactersIgnoringModifiers`, `keyCode` as `UIKeyboardHIDUsage`) | **PROVEN (TASK-033)** to build and run on the iPad Simulator; no hardware key pressed — device NOT ASSESSED |
| An app cannot block iPad system shortcuts; `wantsPriorityOverSystemBehavior` only reorders against text input and focus | **SOURCED** — https://developer.apple.com/documentation/uikit/uikeycommand/wantspriorityoversystembehavior (TASK-033 research) |
| Reading the OS key state on the Mac (`CGEventSource` key state) and whether it triggers a TCC prompt | **NOT SOURCEABLE**: Input AC-1k6 (TASK-057 R-2), run in ADR-0007's device slot |
| ⌘Tab, ⌘⌥Esc, Mission Control, Spaces, Globe/fn, hot corners with a physical keyboard | **NOT SOURCEABLE**: injected keys did not trigger them (TASK-033); physical-keyboard check in ADR-0007/0008 |
