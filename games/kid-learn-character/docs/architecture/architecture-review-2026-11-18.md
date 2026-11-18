# Architecture Review Report (TASK-111)

Date: 2026-11-18
Mode: full
Run by: a fresh subagent with no prior context, started from game-qc-android's session (which authored ADR-0004), so the review is not anchored on that session's ADR threads (TASK-111; the leader's instruction). **The findings below are the subagent's, unedited**; only this line was added.
Workflow: standard (rigor: standard, automation: guided)
Engine: none configured (`engine.name` unset on purpose; ADR-0001 chooses native Swift / SpriteKit / SwiftUI)
GDDs Reviewed: 17 system GDDs (all 14 MVP, plus the 3 Vertical Slice GDDs: scene-time-weather, onscreen-keyboard-row, accessibility). `game-concept.md`, `gdd-cross-review-2026-11-18.md`, `systems-index.md` and `reviews/` were not treated as system GDDs.
ADRs Reviewed: 11 (0001-0006 and 0011 Accepted; 0007, 0008, 0009, 0010 Proposed) plus morph-contract-v1 as referenced

Prior report: none (`RECEIPT: NONE`), so the freshness check had nothing to stand on and the full review ran.

Choices made where the skill asks the user (nobody can answer interactively):
- Phase 8 write approval: option [A] (all files) was taken, limited to the three files the task allows: this report, `requirements-traceability.md`, `tr-registry.yaml`. Not written: `docs/consistency-failures.md` (does not exist, and no red conflict was found), `production/session-state/active.md` (outside the allowed set).
- Phase 2 ambiguous matches: the registry was empty (`requirements: []`), so there was nothing to match. The provisional IDs of the architecture.md baseline were kept where the intent matched (rule 2), so no provisional ID is renamed.
- A requirement counts as Covered only when an Accepted ADR decides it. When the only deciding ADR is Proposed it is "Covered (Proposed)", which caps the verdict at CONCERNS. Where a requirement splits into a logic half (Accepted ADR-0002 / ADR-0004) and an adapter half (Proposed ADR-0007..0010), the halves are separate TR rows.
- Review-input receipts: `.claude/docs/technical-preferences.md` and the skill files sit at the repository root (`../../.claude/`); paths below are relative to the game folder.

Reviewed-Content-Hash lines (taken last, after the TR registry was written):

Reviewed-Content-Hash: docs/architecture/adr-0001-native-apple.md 44e15a46a094d4d4f066b8476bfcfe8a97b43dda
Reviewed-Content-Hash: docs/architecture/adr-0002-modules-seams-types.md 813659e946ec2a433497735d5dea7ed8c2ef6315
Reviewed-Content-Hash: docs/architecture/adr-0003-content-pipeline.md 1596a1fa38433aa33e10a59a3ec966bf5de0e8c6
Reviewed-Content-Hash: docs/architecture/adr-0004-contracts-fixtures-harness.md 743cf462894d311e321ed8c0892e4a7400b4ace1
Reviewed-Content-Hash: docs/architecture/adr-0005-settings-persistence.md 96cb7e085752b43ab0ad18277b6cf38990468c08
Reviewed-Content-Hash: docs/architecture/adr-0006-stage-runtime.md 9720b187837f84627f88e5d13804c033cf6507d8
Reviewed-Content-Hash: docs/architecture/adr-0007-input-adapters.md 6470961732cbb17235752546f5a898e7a8e3237a
Reviewed-Content-Hash: docs/architecture/adr-0008-kiosk-lockin.md d52aa0eec713347cf211e89eb7456c2f6f694b31
Reviewed-Content-Hash: docs/architecture/adr-0009-render-path.md 6c1cb4e6d0a32d35d9cc52aec9f54bcdc7ce3b50
Reviewed-Content-Hash: docs/architecture/adr-0010-audio-engine.md 847e364ae38d3da3ae2b23adb6763c0975efced1
Reviewed-Content-Hash: docs/architecture/adr-0011-build-verify-pkc.md 63bfc7616845f4a8ab831732fb5052bc41d4ad28
Reviewed-Content-Hash: design/gdd/accessibility.md d3a39163b69dee89a97eb460c69e36d0b9a0c074
Reviewed-Content-Hash: design/gdd/app-shell-title.md ff2021bed6f4796edd7b74292612238feb7469cb
Reviewed-Content-Hash: design/gdd/audio-voice.md 434d426d4bdf9e67e25a23e31b922bb88f5d4e0f
Reviewed-Content-Hash: design/gdd/cast-rendering.md 1155ee3e93b073dfc4e8d5e3cf34b0354935bc9e
Reviewed-Content-Hash: design/gdd/child-lock-in.md 8fea01e0c82e1c8d14b4f882e594bbb5a87d674f
Reviewed-Content-Hash: design/gdd/game-concept.md 5a150a0e8ee9e4c4bed1749196abf72271d4d8e8
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-11-18.md a232f7b206045b8bb2e61e5632f012279006ea6b
Reviewed-Content-Hash: design/gdd/hint-letters.md a557920dc32a071d9b55b97b80b598552a068e74
Reviewed-Content-Hash: design/gdd/input-key-filter.md 88fcc4d8faf5341c691dcded81da9a412117e1a8
Reviewed-Content-Hash: design/gdd/key-table-theme-data.md b8570e7474720983d1fec2e2db878edc77b75712
Reviewed-Content-Hash: design/gdd/morphcore.md 356e232993cdde915c0d6daf1d3483ec03c5bd43
Reviewed-Content-Hash: design/gdd/onscreen-keyboard-row.md 078055581428800bf231136040abdac28dc0a038
Reviewed-Content-Hash: design/gdd/parade.md 4634d12d4160f0f88a278ae0fdbb163a3f547a1d
Reviewed-Content-Hash: design/gdd/parent-gate-panel.md 88580d8ec0ec5f17a6da7a4a9cad38ba54719739
Reviewed-Content-Hash: design/gdd/press-queue.md d29da5f89c7d76ed6cc0fdb1d4c6fca5b435a4b6
Reviewed-Content-Hash: design/gdd/privacy-kids-compliance.md def53257a879999f4704f046a5755a597dc4bcc5
Reviewed-Content-Hash: design/gdd/reveal-stage.md e9f98355e1a2e2ae14efcb1613bd2a4219016964
Reviewed-Content-Hash: design/gdd/scene-time-weather.md 1e9c05abf21db9f1af54079dcfc915845b88cd3a
Reviewed-Content-Hash: design/gdd/settings-store.md 7c7b51ce297ced5efcd22c21f5f012f4aef0f4f1
Reviewed-Content-Hash: design/gdd/systems-index.md 239120c57701ad83a4abfc3ad180d9992796d8fb
Reviewed-Content-Hash: docs/architecture/tr-registry.yaml bb203e055cf5de3879b88800d3848fc937e3dedb
Reviewed-Content-Hash: docs/architecture/architecture.md 848c64ffda6103d72c39e7beb433da25e965bd99
Reviewed-Content-Hash: project.yaml ce430bbccbe1e511ed24697f29f7fc5affa6f38d
Reviewed-Content-Hash: ../../.claude/docs/technical-preferences.md 405658044f5eea733789e232808d963416897112
Reviewed-Content-Hash: ../../.claude/skills/architecture-review/SKILL.md 8c1dd9d6f27f396e3b769b939de27d780d7c486a
Reviewed-Content-Hash: ../../.claude/skills/architecture-review/references/1-load.md 9a65759ebdbb2cb1f9744775bfed18cb25e76347
Reviewed-Content-Hash: ../../.claude/skills/architecture-review/references/2-extract-requirements.md d08ea0b0e9ab9760b0d8bfe0cd9115f0bc40f8e2
Reviewed-Content-Hash: ../../.claude/skills/architecture-review/references/3-traceability.md bb7b6b65c5e5e5b8869fa692413aa831615dede7
Reviewed-Content-Hash: ../../.claude/skills/architecture-review/references/4-conflicts.md 0d30f8173b23248a32523a365b606dd1ce9642ab
Reviewed-Content-Hash: ../../.claude/skills/architecture-review/references/5-engine.md 9a0de3ccca214e473e9433450462e0c6e57f9de2
Reviewed-Content-Hash: ../../.claude/skills/architecture-review/references/6-document-coverage.md dcce78482ec2ce60048989b6f9d1f797dd0a9a0e
Reviewed-Content-Hash: ../../.claude/skills/architecture-review/references/7-report.md a43e17378df952791974dab5f10d7a98c16156fe
Reviewed-Content-Hash: ../../.claude/skills/architecture-review/references/8-write.md bf6d8946fc7b9e19eda7f65503a5c8f593a0d2b1
Reviewed-Content-Hash: ../../.claude/skills/architecture-review/references/9-handoff.md ade419da14b200ae3bc8d00ed3f2c04707a6275b
Reviewed-Content-Hash: ../../.claude/skills/architecture-review/references/lens-engine.md d7770f2737d185cf51a338aaf550fa01b773fb07

---

## Traceability Summary

Total requirements: 83 (registered as TR-IDs in `docs/architecture/tr-registry.yaml`; the registry was empty before this review)

| Status | Count |
|---|---|
| Covered (an Accepted ADR decides it) | 59 |
| Covered (Proposed): only a Proposed ADR decides it | 16 |
| Partial | 6 |
| Gap | 2 |

By layer (Covered / Covered-Proposed / Partial / Gap):

| Layer | Covered | Proposed only | Partial | Gap |
|---|---|---|---|---|
| Foundation (Key Table, Input, MorphCore, Settings, Privacy) | 19 | 3 | 0 | 0 |
| Core (Audio, Press Queue, Cast Rendering) | 9 | 6 | 1 | 0 |
| Feature (Reveal, Hints, Parade, Gate, Lock-in, Keyboard Row, Scene) | 22 | 7 | 2 | 1 |
| Presentation (App Shell) | 5 | 0 | 1 | 0 |
| Polish (Accessibility, Android) | 4 | 0 | 2 | 1 |

The full per-requirement matrix is in `docs/architecture/requirements-traceability.md`.

Foundation-layer result: no Foundation requirement is a Gap or Partial. Three Foundation rows rest on Proposed ADR-0007 or ADR-0009 only: TR-input-003 (kiosk command-key exception and the Mac chord), TR-input-004 (UIKit / AppKit input adapters), TR-morph-003 (240-speck frame time, AC-11). Each has its logic half Accepted (ADR-0002, ADR-0004) and its device half Proposed.

### Coverage Gaps (no ADR exists)

- G-1 (Feature, gate) `TR-gate-006`: parent-gate-panel.md AC-24, AC-32 and accessibility.md AC-13: the grown-up panel works with VoiceOver, Dynamic Type to the largest size, 44 pt controls and 60 pt keypad keys. No ADR names VoiceOver, Dynamic Type or the 44 pt rule (`grep` for VoiceOver / accessibilityLabel / Dynamic Type finds one hit, in ADR-0004, not a decision). ADR-0006 D6 covers only Reduce Motion for the panel. Suggested: `/architecture-decision grown-up panel accessibility (SwiftUI labels, Dynamic Type, target sizes)`. Domain: UI. Engine risk: MEDIUM.
- G-2 (Polish, android) `TR-android-001`: Android port gaps (accessibility.md AC-17, hint-letters.md AC-20, onscreen-keyboard-row.md AC-19, parent-gate-panel.md AC-39). ADR-0002, 0003, 0004, 0005, 0007, 0008, 0009, 0010 and 0011 all cite "ADR-0012 (Android)", and `docs/architecture/adr-0012*` does not exist. Deferred by K-03 (Apple first) and every Android AC is marked NOT ASSESSED in its GDD, so this is advisory.

### Partial coverage

- P-1 `TR-a11y-003` flash safety (accessibility.md F2, AC-07..09): ADR-0009 D6 says "Frame rate, flash gate, windows, Smart Invert (same build, not decided here)"; ADR-0004 "Excluded" says "Accessibility F1/F2: QC tools, unit-tested in `apple/Tools`"; ADR-0011 has no gate for it (`grep -i flash` finds only ADR-0009). Nothing decides where the gate runs, what blocks a release, or that the detector is run in CI. This is a photosensitivity safeguard for a toddler product.
- P-2 `TR-a11y-004` palette and idle lints (accessibility.md AC-05, AC-10): only the Scene's 160 contrast cases (scene-look-v1) are in a contract; hint and panel contrast (A5) and the F1 idle-frequency lint are not in ADR-0003 validator rules or ADR-0011 gates.
- P-3 `TR-cast-007` idles at or under 1 Hz (cast-rendering.md AC-11): the same missing lint as P-2.
- P-4 `TR-hints-003` hint knobs (hint-letters.md AC-21): ADR-0003 D1 lists `data/` knob files (hints among them) but no validator rule fails the build for a missing or out-of-range hint knob or a slot that fails F4.
- P-5 `TR-shell-004` iPad edge behaviour (app-shell-title.md R7, K-39, AC-14): status bar and home indicator hidden, `edgeDeferral` follows the gate. ADR-0006 D4 covers windows and `UIRequiresFullScreen` only; no ADR names `edgeDeferral`, the status bar or the home indicator (`grep -i` finds nothing).
- P-6 `TR-scene-002` weather cost (scene-time-weather.md AC-4, AC-19): the draw layer is Accepted (ADR-0006 D1 layer 0), the cost F6 worst case is measured in ADR-0009's run (Proposed).

### Covered only by Proposed ADRs (cap the verdict at CONCERNS)

Route out for every row below: `/architecture-decision accept ADR-NNNN`, after the named device rows run. The owner has put those device measurements on hold, so these are expected, not defects.

| ADR | TR rows resting on it | Pending device rows |
|---|---|---|
| ADR-0007 Input adapters | TR-input-003, TR-input-004, TR-gate-004, TR-lock-003 (with ADR-0008) | M-1, M-2, M-3, P-15, P-4 (keyboard part) |
| ADR-0008 Kiosk and lock-in | TR-lock-001, TR-lock-003, TR-lock-004, TR-lock-005, TR-gate-005 | M-3..M-7, P-4 |
| ADR-0009 Render path | TR-cast-002, TR-cast-004, TR-morph-003, TR-parade-002 | P-2, M-13 |
| ADR-0010 Audio engine | TR-audio-002, TR-audio-003, TR-audio-004, TR-audio-005 | P-1, P-7, P-8, P-9, M-14 |

## Cross-ADR Conflicts

None found, and none blocking. Checks run (read of the Decision, Engine Compatibility and Dependencies sections, plus targeted grep):

- Kiosk options set: ADR-0001 Decision 9b (`[.hideDock, .hideMenuBar, .disableProcessSwitching, .disableForceQuit, .disableSessionTermination, .disableHideApplication, .disableAppleMenu]` plus `.disableScreenCornerInteractions` on macOS 27) matches ADR-0008 D2. ADR-0006 D4 defers the full-screen mode to ADR-0008 D1 (borderless preferred) and states the constraints ADR-0008 must keep: no contradiction.
- Overlays: ADR-0006 D1/D4 (gate and panel are in-window SwiftUI overlays) is consistent with ADR-0008 D3/D5 ("overlays inside the one window") and ADR-0001.
- Audio: ADR-0001 states AVAudioEngine; ADR-0010 builds on it. ADR-0001's spike note uses `AVAudioPlayerNode.play()`; ADR-0010 D-list uses `playAudio()` on 27 and `play()` on 26 behind `#available`. The deployment target is iPadOS / macOS 26 (ADR-0001), and every 27-only API (ADR-0008 `disableScreenCornerInteractions`, ADR-0010 `playAudio`, `didBecomeInactiveNotification`) is guarded: no minimum-OS conflict.
- Ownership of numbers: ADR-0004 "One owner per number" (E6-E9 in audio-plan-v1, startReveal outputs in reveal-timing-v1) is not contradicted by ADR-0010 or ADR-0009.
- Persistence: ADR-0005 D5 (one app-written key `settings`) and ADR-0011's PKC-05 scan agree.
- Dependency graph (`.claude/scripts/adr-dep-graph.sh docs/architecture`): 11 ADRs, no `NO_DEPS_SECTION`, no `UNFILLED_DEPS`, no `CYCLE`, no `BLOCKED_BY_CYCLE`. Running the script with no argument printed `ADRS: 0` (it did not find the game's `docs/architecture` from the game folder); passing the directory fixed it.

Advisory drift between documents (not conflicts):

- A-1 Superseded contracts still named as current: ADR-0004 D1 table lists `settings-record-v1` and `input-filter-v1` (and ADR-0005 lines 17 and 48 and ADR-0004 line 328 repeat them); `contracts/README.md` "Current versions" says settings-record-v1 is "superseded by settings-record-v2" and input-filter-v1 "superseded-by: input-filter-v2". ADR-0007 already cites input-filter-v2. The accepted ADRs should carry a dated note, as ADR-0003 D6 did for Kokoro.
- A-2 Contract count: architecture.md line 302 says "the 12-contract list"; ADR-0004 D1 lists 13 contracts beside morph-contract-v1, and `contracts/README.md` has 14 registry rows (with the two v2 contracts).

## ADR Dependency Order

Script `ORDER:` row, as emitted:
adr-0001, adr-0002, adr-0004, adr-0006, adr-0003, adr-0005, adr-0007, adr-0008, adr-0009, adr-0010, adr-0011

```
Foundation (no dependencies):        ADR-0001 Native Apple stack (Accepted)
Depends on Foundation:               ADR-0002 Modules, seams, types (Accepted)
                                     ADR-0004 Contracts, fixtures, harness (Accepted; needs 0001, 0002)
                                     ADR-0006 Stage runtime (Accepted; needs 0001, 0002)
Content / persistence:               ADR-0003 Content pipeline (Accepted; needs 0001, 0002, 0004)
                                     ADR-0005 Settings persistence (Accepted; needs 0002, 0004)
Feature layer (all Proposed):        ADR-0007 Input adapters (needs 0001, 0002, 0006)
                                     ADR-0008 Kiosk and lock-in (needs 0001, 0002, 0006, 0007 Proposed)
                                     ADR-0009 Render path (needs 0001, 0002, 0003, 0006)
                                     ADR-0010 Audio engine (needs 0001, 0002, 0003, 0006)
Build / verify:                      ADR-0011 Build, verification, PKC (Accepted; needs 0002-0005)
```

Unresolved dependencies: ADR-0008 depends on ADR-0007, which is still Proposed. ADR-0008 cannot be accepted before ADR-0007. All Accepted ADRs depend only on Accepted ADRs. Dangling reference: ADR-0012 (Android) is cited by nine ADRs and does not exist (advisory, G-2).

## ADR Structure Check

| Check | Result |
|---|---|
| `## Engine Compatibility` present | 11 of 11 ADRs. Each carries Engine, Domain, Knowledge Risk, References Consulted, Post-Cutoff APIs Used, Verification Required |
| `## GDD Requirements Addressed` present | 11 of 11 ADRs |
| `## Status` present | 11 of 11 |
| `## ADR Dependencies` present and filled | 11 of 11 |
| Missing sections | 0 |

Minor: no ADR addresses `parade.md` or `press-queue.md` in its own "GDD Requirements Addressed" table apart from ADR-0004 (and ADR-0009 for the parade's drawing). ADR-0002's table does not list press-queue.md, accessibility.md or parade.md. Coverage was credited through ADR-0004's contracts (advisory).

## GDD Revision Flags

None from the engine cross-check, which was not run (see below). No GDD assumption was found to contradict an Accepted ADR.

## Engine Compatibility Issues

- Engine validation: NOT ASSESSED. `engine.name` is unset by design: ADR-0001 chooses native Swift / SpriteKit / SwiftUI, which is not a supported engine in the template (`.claude/engines/engines.tsv` has no row for it and there is no `docs/engine-reference/<engine>/` folder). The engine-reference cross-check, the deprecated-API audit and the specialist look (Phase 5) were therefore not run and are not marked PASS. Not a defect of the project.
- What can be said without an engine reference: all 11 ADRs record their own Knowledge Risk (ADR-0001 HIGH, "NOT SOURCEABLE"; ADR-0006 and ADR-0010 cite Apple headers) and the claims are labelled PROVEN, SOURCED or NOT SOURCEABLE. Those labels were not independently re-verified here.
- Deprecated-API audit: NOT ASSESSED for the same reason. ADR-0006 D2 and ADR-0010 name deprecations themselves (`UIRequiresFullScreen`, `AVAudioPlayerNode.play()`); they were read, not audited.

## Architecture Document Coverage

`docs/architecture/architecture.md` exists, so Phase 6 ran. It is stale against the ADRs:

- AD-1 (blocking for the gate): "ADR Audit" (line 283 onward) lists only ADR-0001 and morph-contract-v1 and says "the implementation-level choices ... have **no ADR yet**", while ADR-0002 to ADR-0011 exist. The Required ADRs table (line 294) still shows them as to-do.
- AD-2: "GDDs Covered (15, all Approved)" omits `onscreen-keyboard-row` and `accessibility`; both are Approved MVP/VS GDDs in systems-index.md (17 GDDs in total). Its Technical Requirements Baseline has no rows for the keyboard row or accessibility.
- AD-3: its status block says "ADRs Referenced: ADR-0001 ... (Accepted)" and "Independent read: game-dev-android (pending)"; TD-ARCHITECTURE and LP-FEASIBILITY were skipped (lean mode).
- AD-4: it numbers ADR-0012 as "Android, later" and nothing writes it (see G-2).
- Orphaned architecture (a system in architecture.md with no GDD): none found. Every system in systems-index.md priority MVP or Vertical Slice has a GDD; Theme Packs, Localization and Mash World have none, correctly, since they are Alpha and later.
- Layer map, module ownership, data flow and API boundaries were checked at heading level only (`## System Layer Map`, `## Module Ownership`, `## Data Flow`, `## API Boundaries`); the cross-system flows named in the GDD Dependencies sections (Press Queue to Reveal Stage, Parade to Scene, Child Lock-in to App Shell) appear in ADR-0004 contracts. Not re-traced edge by edge.

---

### Verdict: CONCERNS

Reasons, in order of weight:
1. 16 requirements (including 3 Foundation and 6 Core) rest only on Proposed ADRs 0007, 0008, 0009, 0010. The skill caps this at CONCERNS. Expected, because acceptance waits on the device measurements the owner has put on hold.
2. 6 partial and 2 gap rows, none in the Foundation layer (the FAIL trigger "Foundation/Core requirement uncovered" is not met: there is no uncovered Foundation requirement; Core has one Partial, TR-cast-007).
3. No cross-ADR conflict, no dependency cycle, no ADR missing Engine Compatibility or GDD Requirements Addressed.
4. Engine validation: NOT ASSESSED (by design) and keeps the verdict from PASS in `full` mode. It ranks below CONCERNS, so CONCERNS is the verdict.

### Blocking Issues (must resolve before a PASS)

- B-1: ADR-0007, ADR-0008, ADR-0009, ADR-0010 are Proposed; accept them after their device rows (known, on hold). Until then 16 TR rows stay "Covered (Proposed)". File: `docs/architecture/adr-0007-input-adapters.md` (and 0008, 0009, 0010) `## Status`.
- B-2: `docs/architecture/architecture.md` contradicts the ADR set (ADR Audit, Required ADRs, "GDDs Covered (15)"). Refresh it, or `/create-control-manifest`, `/create-epics` and the gate will read stale content.
- B-3: Flash safety (TR-a11y-003) has no deciding ADR. Decide where the F2 detector and F2b palette check run and that a FAIL blocks a release candidate (ADR-0011 is the natural home; ADR-0009 D6 explicitly does not decide it).

### Advisory (not blocking)

- TR-gate-006 panel accessibility (G-1); TR-a11y-004 / TR-cast-007 lints; TR-hints-003 hint-knob validation; TR-shell-004 iPad edge deferral; TR-scene-002 weather cost (ADR-0009 run).
- TR-android-001: write ADR-0012 or remove the nine citations; every Android AC is already NOT ASSESSED.
- A-1 superseded contract names in ADR-0004 / ADR-0005; A-2 "12-contract" count.
- Phase 5 NOT ASSESSED lines (engine reference, deprecated APIs): by design.

### Required ADRs (most foundational first)

1. Accept ADR-0007, then ADR-0008 (device rows M-1..M-7, P-4, P-15), `/architecture-decision accept ADR-0007`.
2. Accept ADR-0010 (P-1, P-7, P-8, P-9, M-14) and ADR-0009 (P-2, M-13).
3. New: build-gate additions to ADR-0011 or a small ADR for Accessibility F1/F2/F2b gates, hint-knob validator rules and A5 contrast (covers P-1..P-4).
4. New: grown-up panel accessibility (VoiceOver, Dynamic Type, target sizes) and iPad edge behaviour (`edgeDeferral`, status bar, home indicator); the second could be an ADR-0006 amendment.
5. Later: ADR-0012 Android.

## Skipped or not run

- Phase 3b / `rtm` story and test linkage: not run (`full` mode with no stories: `production/epics/` has none).
- Phase 5 engine cross-check: NOT ASSESSED (above).
- Reflexion log append: not done (no red conflict; the file does not exist).
- Session state append (`production/session-state/active.md`): not done, outside the allowed write set.
