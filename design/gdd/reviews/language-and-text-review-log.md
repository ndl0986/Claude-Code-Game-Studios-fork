# Review log: language-and-text.md

## Review — 2026-11-14 — Verdict: APPROVED (lean self-review; peer review by game-dev-android pending)
Review mode: lean · Workflow: standard
Scope signal: S
Specialists: none (lean mode)
Blocking items: 0 | Recommended: 2
Summary: Complete for standard tier (6/6 required, with Formulas required for budgets and line fit). The slice rule is VI by default with the switch on the title and pause (P-04). The concept's first-launch choice is a proposal (D-20). VI length was measured in today's data (0.38–1.7× EN), which motivates VI budgets (D-21).
Prior verdict resolved: First review
Findings:
- [RECOMMENDED] Cross-system: R8 budgets EN only; VI needs budgets and max lines (D-21).
- [RECOMMENDED] The first-launch picker is new UI for both apps (D-20, Luan).
Reviewed-Content-Hash: design/gdd/language-and-text.md 441c939492e616ba1c61d8794e8243688f10de1d
Reviewed-Content-Hash: design/registry/entities.yaml dfeacb02917f751cb1dfd88cf490c7ec3d8d2d0f
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/game-concept.md 2ee5801590b66b9404c289645f337bc459690eba
Reviewed-Content-Hash: design/gdd/mission-flow.md a6fc3e25358511360b90999874e86d1ad5cc96fd
Reviewed-Content-Hash: design/narrative/writing-guide.md b46f07dbc5222f8c1013e41a599a6a959a44a5ca
Reviewed-Content-Hash: content/data/rules.json f00841c558d539129bcb20973e610bd7e98dbdf1

## Peer review — 2026-11-14 — game-dev-android: REVISE, fixes applied
- F1 is now testable: greedy wrap with Nunito's real advances (cmap/hmtx), 3% kerning allowance, box_width/font_px/max_lines per field in rules.json (proposed), and overflow fails R8c on both apps (AC5).
- Sizes in world px at the fitted scale: body ≥ 37 (including quiz choices), labels next to icons ≥ 28 (pad labels, counters, map stub); the current sizes to raise are listed.
- Run-time ellipsis allowed only as a safety net; in a shipped build it is a bug.
Awaiting confirmation.

## Peer re-review — 2026-11-14 — game-dev-android: items 2–3 APPROVE; F1 fix applied
F1 reads advances from content/metrics/nunito-advances.json at the field weight (800/600), not hmtx (the variable font defaults to wght 200, and bold renders 8.6% wider). The goal bar and quiz why grow to 37.
