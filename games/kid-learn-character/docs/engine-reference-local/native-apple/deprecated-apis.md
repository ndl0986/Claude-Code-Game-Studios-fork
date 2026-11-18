# Native Apple — Deprecated or Avoided APIs

Rule: PROVEN (TASK-033), SOURCED (Apple URL) or NOT SOURCEABLE (see `VERSION.md`).

| API | Status | Use instead |
|---|---|---|
| `AVAudioPlayerNode.stop()` + `scheduleBuffer` + `play()` on the main thread per press | **PROVEN (TASK-033)** to cost 3–10 ms on the main thread (Mac and iPad Simulator); not deprecated, avoided | Players primed and running; schedule with interruption, off the main thread (Audio & Voice R2, R4) |
| Rive `loadCdn` default (true) | **PROVEN (TASK-033)**: it fetched from a CDN on load | Not used (ADR-0001 chose SpriteKit); recorded for any future SDK ADR (PKC-03) |
| `UIAccessibility.requestGuidedAccessSession` for a family iPad | **SOURCED**: "Entering Single App mode is supported only for devices that are supervised using Mobile Device Management (MDM)" — https://developer.apple.com/documentation/uikit/uiaccessibility/requestguidedaccesssession(enabled:completionhandler:) (TASK-033 research) | Show Guided Access instructions; observe `isGuidedAccessEnabled` (Child Lock-in R8) |

No Apple deprecation of an API this project plans to use is recorded. NOT SOURCEABLE beyond this table.
