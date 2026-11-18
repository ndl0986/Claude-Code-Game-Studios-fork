# Native Apple — Breaking Changes (26 → 27 SDKs)

Rule: PROVEN (TASK-033), SOURCED (Apple URL) or NOT SOURCEABLE (see `VERSION.md`).

| Change | Status | Impact on this project |
|---|---|---|
| `NSApplication.PresentationOptions.disableScreenCornerInteractions` is new in macOS 27.0; it needs `.hideDock` or `.autoHideDock` to take effect | **SOURCED** — https://developer.apple.com/documentation/appkit/nsapplication/presentationoptions-swift.struct (read for TASK-033, `research/child-lock-in.md`); **PROVEN (TASK-033)** on a real Mac, macOS 27.2.1 | The kiosk sets it only on macOS 27+; on macOS 26 it is absent (an availability check) — Child Lock-in R2 |
| iPadOS no longer lets an app require full screen (the `UIRequiresFullScreen` opt-out) | **NOT SOURCEABLE** — stated in App Shell R7 from model knowledge; no Apple URL recorded | App Shell supports any window shape anyway (contain-and-extend). Verify with a build and a source before ADR-0006 relies on it |
| SpriteKit, `CADisplayLink`, `AVAudioSession` on iOS 27 | **PROVEN (TASK-033)**, iPad Simulator only | Built and ran; device behaviour NOT ASSESSED |

No other breaking change is recorded. An API not listed here is not known to be unchanged: it is unverified.
