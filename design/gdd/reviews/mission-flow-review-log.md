# Review log: mission-flow.md

## Review — 2026-11-14 — Verdict: NEEDS REVISION (revisions applied; awaiting peer re-review)
Review mode: lean · Workflow: standard
Scope signal: L
Specialists: none (lean mode)
Blocking items: 2 | Recommended: 2
Summary: The structure is complete for standard tier (6/6 required, with Formulas required). Two internal inconsistencies blocked it: training needs move but didn't list it, and a Game Feel claim cited a QC finding that does not exist. Both were fixed in the same session. Dependency GDDs don't exist yet (design order). Next: peer review by game-dev-ios.
Prior verdict resolved: First review
Findings:
- [BLOCKING] Detailed Design (Core Rule 7): training walks between dummies (F4 walk_gap) but its buttons omitted move. Fixed.
- [BLOCKING] Game Feel: "QC showed an instant cut felt abrupt" is not in any QC report. Replaced with the prototype value, marked not playtested.
- [RECOMMENDED] States: gate_check fail can't happen in a release map that already hides the hero. Clarified as a safety re-check.
- [RECOMMENDED] Interactions: no-progress hint now names tuning.json hint_delay.
Reviewed-Content-Hash: design/gdd/mission-flow.md b6c14cba5586266e8f09bff0403fbcb64ce0446a
Reviewed-Content-Hash: design/registry/entities.yaml dfeacb02917f751cb1dfd88cf490c7ec3d8d2d0f
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/game-concept.md 2ee5801590b66b9404c289645f337bc459690eba
Reviewed-Content-Hash: design/narrative/heroes/tran-quoc-toan.md 1df517e7bd3a99bde277d54f0c9aafefb8678275
Reviewed-Content-Hash: design/art/art-bible.md 851eadc6ddd3c5341d202cf8cbde728d12884163
