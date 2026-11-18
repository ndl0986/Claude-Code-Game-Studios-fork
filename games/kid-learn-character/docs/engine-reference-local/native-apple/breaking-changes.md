# Native Apple — Breaking Changes (26 → 27 SDKs)

Rule: PROVEN (TASK-033), SOURCED (Apple URL) or NOT SOURCEABLE (see `VERSION.md`).

| Change | Status | Impact on this project |
|---|---|---|
| `NSApplication.PresentationOptions.disableScreenCornerInteractions` is new in macOS 27.0; it needs `.hideDock` or `.autoHideDock` to take effect | **SOURCED** — https://developer.apple.com/documentation/appkit/nsapplication/presentationoptions-swift.struct (read for TASK-033, `research/child-lock-in.md`); **PROVEN (TASK-033)** on a real Mac, macOS 27.2.1 | The kiosk sets it only on macOS 27+; on macOS 26 it is absent (an availability check) — Child Lock-in R2 |
| `UIRequiresFullScreen` is deprecated in iOS / iPadOS 26.0; under Windowed Apps the system "doesn't present your app's scene full screen" and scales it on resize | **SOURCED** — https://developer.apple.com/documentation/bundleresources/information-property-list/uirequiresfullscreen (read 2026-11-18, ADR-0006) | Not set; every scene size supported (ADR-0006 D4, App Shell R7) |
| SpriteKit, `CADisplayLink`, `AVAudioSession` on iOS 27 | **PROVEN (TASK-033)**, iPad Simulator only | Built and ran; device behaviour NOT ASSESSED |

No other breaking change is recorded. An API not listed here is not known to be unchanged: it is unverified.
