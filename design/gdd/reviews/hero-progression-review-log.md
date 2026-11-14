# Review log: hero-progression.md

## Review — 2026-11-14 — Verdict: APPROVED (lean self-review; peer review pending)
Review mode: lean · Workflow: standard
Scope signal: M
Specialists: none (lean mode)
Blocking items: 0 | Recommended: 1
Summary: Complete for standard tier (6/6 required, with Formulas required). Unlock is derived from completed heroes in timeline order, so progression survives content updates; seen_open prevents re-locking. The medal (D-07) and best stars are never lowered. One cross-system item: P-04 (3) saves an unlocked list, which this GDD replaces with completed + seen_open (D-16, for the save ADR).
Prior verdict resolved: First review
Findings:
- [RECOMMENDED] Cross-system: P-04 (3) saved keys differ from Rule 11; resolve in the D-04 save ADR (D-16).
Reviewed-Content-Hash: design/gdd/hero-progression.md 7ee3e6eea509a294ba2b5908e3af8c11e283080e
Reviewed-Content-Hash: design/registry/entities.yaml dfeacb02917f751cb1dfd88cf490c7ec3d8d2d0f
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/game-concept.md 2ee5801590b66b9404c289645f337bc459690eba
Reviewed-Content-Hash: design/gdd/quiz-and-stars.md 222777502ac1a4a3282b720980105608d5787a2b
Reviewed-Content-Hash: design/gdd/mission-flow.md 89c327ac37a267c41cd8dd14fb8291af48ad9b6a

## Peer review — 2026-11-14 — game-dev-android: REVISE, fixes applied
- seen_open is written for every open hero on each title/map load and at quiz finish; AC11 (a hero inserted before an open but uncompleted A leaves A open) and AC12.
- Rule 6: R18 checks next_hero against the index order at build time, ignoring claims; at run time the unlock screen names the hero that actually opened.
- timeline_order is an integer in gaps of 10 (Trần Quốc Toản = 10; the sample = 999, excluded from R17); no year field.
- The medal-earned string: ui.medal.earned is reused and shows only in the run that earns it.
Data edits: tran-quoc-toan mission.json and drafts/mission-fights.json have timeline_order 10; samples/heroes/sample has 999 and next_hero null. Checks: 0 errors.
Awaiting game-dev-android confirmation.
