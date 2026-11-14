# Review log: side-scroll-combat.md

## Review — 2026-11-14 — Verdict: NEEDS REVISION (revision applied; awaiting peer re-review)
Review mode: lean · Workflow: standard
Scope signal: L
Specialists: none (lean mode; systems-designer and qa-lead lenses applied in authoring)
Blocking items: 1 | Recommended: 1
Summary: Complete for standard tier (6/6 required, with Formulas required). F1 added approach_delay to every cycle, but the prototype counts it as already passed after rest. Fixed: the cycle is 2.95 s (spear) or 3.17 s (leader). Boundary checks on F2–F6 passed; F5 couples attack_range to enemy_reach - stand_gap (validation rule added). Hints, Audio and Input GDDs don't exist yet (design order). Next: peer review by game-dev-ios.
Prior verdict resolved: First review
Findings:
- [BLOCKING] Formulas F1: approach_delay double-counted after rest. Fixed.
- [RECOMMENDED] Open Questions: 14 hidden prototype literals need tuning.json keys (D-09 sent to the leader).
Reviewed-Content-Hash: design/gdd/side-scroll-combat.md d6db97b37393b919bf1f39bdc6b03ed63484b5ca
Reviewed-Content-Hash: design/registry/entities.yaml dfeacb02917f751cb1dfd88cf490c7ec3d8d2d0f
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/game-concept.md 2ee5801590b66b9404c289645f337bc459690eba
Reviewed-Content-Hash: design/gdd/mission-flow.md b6c14cba5586266e8f09bff0403fbcb64ce0446a
Reviewed-Content-Hash: design/art/art-bible.md 851eadc6ddd3c5341d202cf8cbde728d12884163

## Note — 2026-11-14 — rename only (no design change)
Tuning keys renamed to the names already in content/data/tuning.json (TASK-005b, 012114c), and variable ranges aligned to that file. D-09 reduced to special_push, special_cooldown and the two validation rules. The hashes above are from before this rename; the peer review covers the renamed file.

## Peer review — 2026-11-14 — game-dev-ios: REVISE (minor), fixes applied
Findings and fixes:
- Key names: the merged 005b names were already applied (ed8d430). D-09 is now only special_push and special_cooldown.
- Rule 7: first_spawn_delay 0.4 s added (AC16).
- Rule 9: approach must be strictly more than approach_min_time; on leaving rest the timer starts at approach_min_time.
- F6 and Rule 10: block is checked only at the frame the strike resolves; press-and-release earlier doesn't block (AC15). The old "any time during the telegraph" wording is removed.
- Frame order: new subsection with the prototype order agreed by both devs. Same-frame edge cases derived from it. Correction: a hit in the same frame a windup ends now cancels the strike (the earlier text said the strike resolves first) (AC17).
- Rule 4: an attack tap while defending is dropped, not queued (AC18).
- World layout keys belong to mission-flow; cross-referenced.
- AC11 cites R14 and R15 (schema 1.1 validity fixtures).
- Rule 16 (special): waits for Luan. The push goes away from the hero on both sides; no "not ready" text.
Awaiting game-dev-ios confirmation.
