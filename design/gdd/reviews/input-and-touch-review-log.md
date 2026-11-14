# Review log: input-and-touch.md

## Review — 2026-11-14 — Verdict: APPROVED (lean self-review; peer review by game-dev-android pending)
Review mode: lean · Workflow: standard
Scope signal: M
Specialists: none (lean mode)
Blocking items: 0 | Recommended: 1
Summary: Complete for standard tier (6/6 required, with Formulas for pad size, safe anchoring and debounce). It writes down what both apps already do and QC verified (P-01, P-04, TASK-013, O5, O6, B1, B4), plus the leader's pointer tie-break. B3 is fixed in the Hints GDD in the same commit.
Prior verdict resolved: First review
Findings:
- [RECOMMENDED] Tuning: pad_gap (12 pt) and drag_threshold need keys in tuning.json.
Reviewed-Content-Hash: design/gdd/input-and-touch.md 1cd2faf3e1d375120dfcd9163dccb177c4d9ed5a
Reviewed-Content-Hash: design/registry/entities.yaml dfeacb02917f751cb1dfd88cf490c7ec3d8d2d0f
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/side-scroll-combat.md 4d973418c3c85d29ae2681eb097237054557b1ec
Reviewed-Content-Hash: design/gdd/mission-flow.md 1f61e124f7f923be2e3bb886fff9bca161ce67b6
Reviewed-Content-Hash: design/gdd/quiz-and-stars.md 222777502ac1a4a3282b720980105608d5787a2b

## Update — 2026-11-14 — iOS QC r2 (iOS-R2-03, S2)
Rule 5b: pointers are tracked by identity; a release or cancel always releases the owned pad, wherever the pointer moved. AC13 (small moves then release → nothing held within one frame) and AC14 (a flag tap with a small move under drag_threshold still counts).

## Peer review — 2026-11-14 — game-dev-android: REVISE (4), applied (leader agreed)
1. Rule 6 / AC3: a second pointer on an owned pad is ignored until it lifts. 2. Rule 9: a pointer keeps its pad from down to up or cancel; only the ◀↔▶ slide changes it; drift is forgiven (new edge case). 3. AC14: the flag counts at press; the drag_threshold key is used by Rule 16 only. 4. Rule 2: Android mandatory gesture insets; iOS home-indicator inset.
