# Review log: Input & Key Filter (`design/gdd/input-key-filter.md`)

## Review — 2026-11-18 — Verdict: APPROVED
Review mode: lean · Workflow: standard
Scope signal: M (two small formulas, six downstream systems, no new ADR; producer should verify before sprint
planning)
Specialists: none (lean). Note: run in the authoring session (game-dev-ios, TASK-037), so it is not an independent
read; game-dev-android reviewed the plan, and the leader may ask for an independent pass.
Blocking items: 0 | Recommended: 4 (applied in the same commit) | Advisory: 2
Summary: All required sections at `standard` are present (Overview, Detailed Design, Formulas, Edge Cases,
Dependencies, Acceptance Criteria; Tuning Knobs also present; Player Fantasy advisory and omitted). The rules
follow ADR-0001 Decisions 4 and 9 and art bible §7, and record Luan's decisions (layout, chord, swallowed = nothing,
empty-stage sparkle). No registry exists, so values were checked against the concept, the systems index, ADR-0001
and the art bible: no conflicts.
Prior verdict resolved: First review
Findings:
- [RECOMMENDED, applied] Detailed Design R6: the order of checks was implicit; with the Mac kiosk off, ⌃⌥⌘Q could
  read as a ⌘-combination passed to the menus. An explicit check order now puts the chord first.
- [RECOMMENDED, applied] Acceptance Criteria AC-2: the example's "D′ = 3" was unclear; rewritten as D, B, 3.
- [RECOMMENDED, applied] Acceptance Criteria AC-1l: the F2 boundary (gap equal to `repress_min_s`) had no test
  case and is fragile in floating point; added a case with a 1e-9 s tolerance.
- [RECOMMENDED, applied] Detailed Design R3: Fn added "where the platform reports it" (iPadOS has no Fn flag).
- [ADVISORY] Dependencies: none of the six downstream GDDs exists yet (Press Queue, Parent Gate & Grown-up Panel,
  Child Lock-in, Hint Letters, On-screen Keyboard Row, Reveal Stage); each must name Input & Key Filter when written.
  Key Table & Theme Data (the key format) is on the TASK-036 branch, not on this one.
- [ADVISORY] Dependencies: the systems index lists Hint Letters and the On-screen Keyboard Row as depending on
  the Press Queue only; their touches reach it through Input, so the index should add Input & Key Filter (the
  leader updates the index).
Reviewed-Content-Hash: design/gdd/input-key-filter.md bc074544bfd4323bd2a38f618742f22711231b21
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/game-concept.md e525c154ca1b014fe3ca0024ba5a339d37135429
Reviewed-Content-Hash: design/gdd/systems-index.md 6652c64909266be6f7de820ddfbff3a731c77c7d
Reviewed-Content-Hash: docs/architecture/adr-0001-native-apple.md 9bd960cdffd4bec53f0f2875d6f4c7a33f873a70
Reviewed-Content-Hash: design/art/art-bible.md a01094340e7e5b7bdae636f4cc879d0f84b472b5

## Revision — 2026-11-18 — Independent read: game-dev-android (via the leader) — Verdict: APPROVE once A and B are in
Review mode: lean · Workflow: standard
Note: the reader's verdict, relayed by the leader; the author applied the changes below in the same session.
Blocking items: 2 (applied) | Recommended: 2 (applied)
Findings:
- [BLOCKING, applied] A. R4: Android injected keys often carry `scanCode` 0, so all would share held-set id 0.
  Id is now `scanCode` if non-zero, else `keyCode`, tagged by kind so the two never collide. R2.3 names each
  platform's position source (Android: `scanCode` through the US evdev map, else `keyCode`). Edge case,
  AC-1n and the Android NOT ASSESSED line added.
- [BLOCKING, applied] B. R5: hardware system keys (volume, mute, power, camera, brightness) always pass to the
  system and are never presses (on Android, returning `true` would kill the volume rocker). First in R6's order
  of checks; excluded from AC-1b; AC-1m added; Mac media keys noted as system-defined events; iPad keyboard media
  keys NOT ASSESSED.
- [RECOMMENDED, applied] R7: stable order within one iPad touch batch (timestamp, then stage x, then y); AC-3e
  extended.
- [RECOMMENDED, applied] R1: the Android ADR should catch keys in `dispatchKeyEvent`.
- [DECISION, applied] Open Question Q1 closed (Luan, 2026-11-18): on the title screen any letter or digit key
  starts play (`startPlay`), like the play button, and is not a press; the held set carries into Play. States
  table, R8 outputs, AC-1o.
Reviewed-Content-Hash: design/gdd/input-key-filter.md bbbc45714a1c29c1a25ec86c921a6e938773b71f

## Update — 2026-11-18 — TASK-050 cross-GDD follow-ups (no re-review)
Review mode: lean · Workflow: standard
Change: TASK-050: R8 origin is nil from Input and set by the Play router from Hint Letters' originFor(key) (K-18); R6 the Mac chord counts only with no other key held and starts the gate's second step (K-19); nothing reaches play during the gate challenge (K-20), new Gate challenge state; AC 1j extended. Wording and interface follow-ups from K-18/K-19/K-20 and the Cast Rendering and Reveal Stage reviews; verdict unchanged; review by game-dev-ios.
Reviewed-Content-Hash: design/gdd/input-key-filter.md 8c1a71612d35412e14543e2f0d9a44ba65a8e5cb

## Update — 2026-11-18 — TASK-050 follow-ups, part 2 (no re-review)
Review mode: lean · Workflow: standard
Change: Gate challenge state row: digit keys and touches go only to the challenge's keypad; nothing reaches Play or the queue (K-20); exits on wrong, timeout or correct, correct → Panel open. Verdict unchanged; review by game-dev-ios.
Reviewed-Content-Hash: design/gdd/input-key-filter.md 1bdc1f15e4f76b3bd5c43c65fdc359238de133e9

## Update — 2026-11-18 — TASK-050 wording notes from game-dev-android (no re-review)
Review mode: lean · Workflow: standard
Change: R6 chord wording: the held set is empty when Q goes down; ⌃⌥⌘ are read from the modifier flags (flagsChanged on the Mac, not in the held set). Optional notes from game-dev-android's APPROVE of c4ae20d. Verdict unchanged.
Reviewed-Content-Hash: design/gdd/input-key-filter.md fd2286b73dad5e6608b42103370102f8f9b44c72
