# Native Apple — Current Best Practices (this project's domains)

Rule: PROVEN (TASK-033), SOURCED (Apple URL) or NOT SOURCEABLE (see `VERSION.md`).

## Structure (ADR-0001)
- UI-free Swift packages (`KidCore`, `MorphCore`) for every rule, tested with `swift test`; platform code only in
  the app target. **PROVEN (TASK-033)**: the spike's `MorphCore` package built and its fixture test passed on the
  Mac.
- One multiplatform Xcode project under `apple/` (ADR-0001 Decision 2). NOT yet built (the scaffold story).

## Frames and time
- Drive the stage from the display link and read `targetTimestamp`; event `timestamp` and the display link share
  the uptime clock. **PROVEN (TASK-033)** on a real Mac (`NSView.displayLink`) and on the iPad Simulator
  (`CADisplayLink`).
- `ProcessInfo.beginActivity(.latencyCritical)` for measurement runs. **PROVEN (TASK-033)** on a real Mac.

- `CADisplayLink.preferredFrameRateRange` is a best-effort range; Low Power Mode, thermal state and accessibility
  settings can lower it. **SOURCED** —
  https://developer.apple.com/documentation/quartzcore/cadisplaylink/preferredframeraterange (ADR-0006 D3: 30–60, preferred 60).

## Accessibility
- Smart Invert opt-out per view: `accessibilityIgnoresInvertColors` "prevents the system from inverting the colors of
  the view and all of its subviews". **SOURCED** — https://developer.apple.com/documentation/uikit/uiview/accessibilityignoresinvertcolors
- Reduce Motion: `UIAccessibility.isReduceMotionEnabled` (iPadOS), `NSWorkspace.accessibilityDisplayShouldReduceMotion`
  (macOS). **SOURCED** — https://developer.apple.com/documentation/uikit/uiaccessibility/isreducemotionenabled,
  https://developer.apple.com/documentation/appkit/nsworkspace/accessibilitydisplayshouldreducemotion

## Displays
- No public iPad ppi API: `UIScreen.nativeScale` is "the native scale factor for the physical screen" (px per pt).
  **SOURCED** — https://developer.apple.com/documentation/uikit/uiscreen/nativescale. ppi comes from a model table
  (ADR-0006 D7).
- Mac: `CGDisplayScreenSize` returns a display's size in mm, or 0; without EDID it estimates at 72 dpi. **SOURCED** —
  https://developer.apple.com/documentation/coregraphics/cgdisplayscreensize(_:)

## Input
- macOS: `NSEvent.addLocalMonitorForEvents` for keyDown/keyUp with `timestamp` and `isARepeat`. **PROVEN
  (TASK-033)** on a real Mac.
- iPadOS: `pressesBegan` / `UIKey` hardware keys. **PROVEN (TASK-033)** to build and run on the iPad Simulator;
  **no hardware key was pressed into it** — NOT ASSESSED on a device.
- `UIKeyCommand.wantsPriorityOverSystemBehavior` does not let an app block system shortcuts. **SOURCED** —
  https://developer.apple.com/documentation/uikit/uikeycommand/wantspriorityoversystembehavior (TASK-033 research).

## Audio
- `AVAudioEngine` + `AVAudioPlayerNode` for output. **PROVEN (TASK-033)** on the Mac and iPad Simulator; press →
  first audible sample was an estimate only. Device latency NOT ASSESSED (ADR-0001 follow-up 2).
- Session category `.soloAmbient` for "obeys silent mode, does not mix" (Audio & Voice R6). **NOT SOURCEABLE**
  here: to be proven and sourced by the audio ADR.

## Kiosk and lock-in
- `NSApplication.presentationOptions` for the Mac kiosk; options apply only while the app is active; an invalid
  combination raises. **SOURCED** — https://developer.apple.com/documentation/appkit/nsapplication/presentationoptions-swift.property;
  **PROVEN (TASK-033)**: ⌘H, ⌘Q, ⌘Space held on a real Mac (`evidence/TASK-033/lockin/`).
- iPad: Guided Access is the lock (the user starts it); the app observes `UIAccessibility.isGuidedAccessEnabled`.
  **SOURCED** — https://developer.apple.com/documentation/uikit/uiaccessibility/isguidedaccessenabled.

## Privacy
- `PrivacyInfo.xcprivacy`: `NSPrivacyAccessedAPICategorySystemBootTime` lists `ProcessInfo.systemUptime` and
  `mach_absolute_time()`; reason `35F9.1` covers time elapsed between in-app events. **SOURCED** —
  https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype
  (read 2026-11-18, TASK-054b V1). `mach_continuous_time` / `ContinuousClock` are not on that list.
