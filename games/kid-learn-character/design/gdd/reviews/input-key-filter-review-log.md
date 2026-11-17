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
Reviewed-Content-Hash: design/gdd/input-key-filter.md e6c3a30178291a8b4b632ff9762ed3e05ede6dca
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/game-concept.md e525c154ca1b014fe3ca0024ba5a339d37135429
Reviewed-Content-Hash: design/gdd/systems-index.md 6652c64909266be6f7de820ddfbff3a731c77c7d
Reviewed-Content-Hash: docs/architecture/adr-0001-native-apple.md 9bd960cdffd4bec53f0f2875d6f4c7a33f873a70
Reviewed-Content-Hash: design/art/art-bible.md a01094340e7e5b7bdae636f4cc879d0f84b472b5
