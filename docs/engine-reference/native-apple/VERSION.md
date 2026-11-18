# Native Apple — Version Reference

`engine.name` is **unset on purpose** (ADR-0001; K-28): the stack is native Swift, which has no row in
`.claude/engines/engines.tsv`. This folder exists so `/create-architecture` (Phase 0a) and later skills have a
pinned, sourced reference instead of model memory. It is **not** an engine configuration: skills that check
`engine.name` keep reporting NOT ASSESSED for engine checks, as at the Systems Design gate.

| Field | Value |
|-------|-------|
| **Stack** | Swift + SwiftUI shell + SpriteKit stage; AVFoundation audio; UIKit / AppKit input (ADR-0001) |
| **Swift** | 6.4 (swiftlang-6.4.0.34.1) |
| **Xcode** | 27.1 (27A9275) |
| **SDKs** | iOS 27.1, macOS 27.0 (built on macOS 27.2) |
| **Deployment target** | iPadOS 26, macOS 26 (ADR-0001 Decision 2) |
| **Project Pinned** | 2026-11-17 (TASK-033 spike), recorded here 2026-11-18 (TASK-059) |
| **Last Docs Verified** | 2026-11-18 (the Apple URLs cited in this folder) |
| **LLM Knowledge Risk** | **HIGH.** These SDKs postdate the model's knowledge. |

## The rule for every API claim in this folder

Each claim is one of:
- **PROVEN (TASK-033):** built and run in the TASK-033 spike (`design/tech/TASK-033-anim-runtime.md`,
  `production/qa/evidence/TASK-033/`), naming where (real Mac, or iPad Simulator only);
- **SOURCED:** an Apple developer documentation URL, quoted or summarised, with the date read;
- **NOT SOURCEABLE:** neither; it must be proven by a build before anything depends on it.

Nothing is stated from memory. A claim that a build disproves is corrected here in the same change.

## Files

- `breaking-changes.md` — changes that affect this project between the deployment target (26) and the SDKs (27).
- `deprecated-apis.md` — APIs not to use.
- `current-best-practices.md` — patterns the spike proved or Apple documents, for this project's domains.
- `modules/` — one page per domain: `spritekit.md`, `avfaudio.md`, `uikit-input.md`, `appkit-kiosk.md`,
  `guided-access.md`, `privacy-manifest.md`.
