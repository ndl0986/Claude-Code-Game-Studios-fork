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

## Update — 2026-11-18 — TASK-054a follow-ups (no re-review)
Review mode: lean · Workflow: standard
Change: I1 (safety): the chord check reads the OS key state at the Q down (CGEventSource keyState), and keys pressed while ⌘ was held leave the held set when ⌘ is released, so a lost key-up never blocks the chord (Parent Gate AC-27; AC-1k3); the key-state read without an Input Monitoring prompt is NOT ASSESSED, with the ⌘-release rule as fallback. I2: layer 3 emits gateTouch(ended) when the pointer leaves the moon region + moon_slop_pt 20 pt (G1; new knob; AC-1k5). I3 (safety): ⌘-combinations swallowed in every state while childLockActive, Panel open row fixed (AC-1k2). I4: a wrong answer or timeout returns to the state the gate opened from; the chord works on the Title and is ignored in the Gate challenge and Panel open (AC-1k4). Wording and rule edits from the TASK-054 follow-up list (production/team/TASK-054-followups.md @ 84f7ea2); Parent Gate G-numbers cited as given by game-qc-ios (TASK-048 not merged). Review: game-qc-ios, from the diff.
Reviewed-Content-Hash: design/gdd/input-key-filter.md e0aab170b758b949109f2d01c9045593afa93b76

## Update — 2026-11-18 — TASK-054a review fixes (no re-review)
Review mode: lean · Workflow: standard
Change: game-qc-ios's diff review: I1's key-state read is a build decision with a release check (no Input Monitoring prompt on a clean Mac, else removed from the build; no run-time fallback, PKC), the ⌘-release rule stated as alone passing AC-27 / k3, the held-set-only limit and its cure stated, new AC-1k6 (real Mac, release-blocking, NOT ASSESSED until run).
Reviewed-Content-Hash: design/gdd/input-key-filter.md aa441ae5b394c020fb3156b879b9c800aad847b9

## Update — 2026-11-18 — TASK-054b text (no re-review)
Review mode: lean · Workflow: standard
Change: I5: R6's sentence "The chord replaces the moon hold only…" moved off the end of the held-set-limit bullet onto its own R6-level line. Text only; no rule changed. Review: game-qc-ios, from the diff.
Reviewed-Content-Hash: design/gdd/input-key-filter.md 8bf6b260a886d63f988e59a5dc2c719809a79c37

## Update — 2026-11-18 — TASK-056a cross-review fixes (no re-review)
Review mode: lean · Workflow: standard
Change: B-1: R6 says Shift and Caps Lock are ignored and Fn disqualifies the chord (K-26 leader call), AC-1j adds the Fn and Shift cases. W-1: one ⌘ signal, Input's kiosk-on mode kioskModeOn (set by Child Lock-in from Waiting to Off, so off after an engage timeout); AC-1k and k2 merged with the timeout case. W-2: Cancel and Esc return to the gate's origin (States, AC-1k4). W-8: moon_slop_pt owned by Input (10–40). W-9: App Shell in Downstream; the leader's index note marked done. From design/gdd/gdd-cross-review-2026-11-18.md and K-26. Review: game-qc-android (diff re-run).
Reviewed-Content-Hash: design/gdd/input-key-filter.md d72642557b630aff374132b13c6085e033de2bab

## Update — 2026-11-18 — TASK-083 gate outputs and contract answers (no re-review)
Review mode: lean · Workflow: standard
Change: game-qc-android's input-filter-v1 questions IF-Q1–Q11, as the Input author. R8 adds the Gate challenge outputs gateDigit(digit, anotherKeyHeld) and gateCancel (Esc), neither a press; States rows say so, and Panel open emits nothing (a non-⌘ key passes to the panel). Adapter rules, no KeyEvent field (ADR-0002 D5 unchanged): a keypad 0–9 key arrives as character nil + positionKey digit (IF-Q1); Esc as character "\u{1b}", Android KEYCODE_ESCAPE mapped explicitly (IF-Q8); hardware system keys never reach KidCore (IF-Q2); the iPad touch batch is sorted by the adapter in window px (IF-Q7, IF-Q10). R5: the ⌘ mode-off exception is macOS only, iPadOS ⌘-combinations are swallowed (IF-Q11). R6 (safety, IF-Q9, leader-approved): releasing ⌘ empties the held set on every platform, so a key lost under ⌘ never blocks ⌃⌥⌘Q whenever it went down; a key still physically down only sends repeats or its up, Fn/K-26 unchanged, anotherKeyHeld excludes it. ACs: 1c, 1i, 1k3, 1m (adapter suites), 3e reworded; 1p–1s added. Review: game-qc-android, from the diff.
Reviewed-Content-Hash: design/gdd/input-key-filter.md f77e169480dd3d946527c8a99124299ad4eefec2

## Update — 2026-11-18 — TASK-098 gateDigitUp (no re-review)
Review mode: lean · Workflow: standard
Change: Parent Gate G13 B7 needs to know when a hardware digit is still down. R8 adds gateDigitUp(digit): in the Gate challenge, emitted when a key that produced a gateDigit leaves the held set (its up; a cancel or focus-loss clear; the ⌘-release clear of R6), one per key in down order; nothing for keys that gave no gateDigit, nor on leaving the challenge. The gate keeps a count (+1/−1). After a ⌘-release clear the count is 0 even if a digit is physically down (accepted, as R6 accepts for the chord). States Gate row and new AC-1t. No KeyEvent field (ADR-0002 D5 unchanged). Option (a) chosen over a flag on the keypad touch: one source of key events for the gate, mirrors gateDigit. Review: game-qc-android, from the diff.
Reviewed-Content-Hash: design/gdd/input-key-filter.md 88fcc4d8faf5341c691dcded81da9a412117e1a8
