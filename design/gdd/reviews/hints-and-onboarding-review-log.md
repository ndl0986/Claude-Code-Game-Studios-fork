# Review log: hints-and-onboarding.md

## Review — 2026-11-14 — Verdict: APPROVED (lean self-review; peer review pending)
Review mode: lean · Workflow: standard
Scope signal: S
Specialists: none (lean mode)
Blocking items: 0 | Recommended: 0
Summary: Complete for standard tier (6/6 required, with Formulas required for hint_delay). The teach-hint priority matches the prototype's else-if order (move > attack > defend). Stall resets match P-04 (6) and QC O2. Voice prompts are deferred until Audio and vo exist.
Prior verdict resolved: First review
Findings:
- none
Reviewed-Content-Hash: design/gdd/hints-and-onboarding.md 28e0384372c435cac0932a68c45add4f05db7ced
Reviewed-Content-Hash: design/registry/entities.yaml dfeacb02917f751cb1dfd88cf490c7ec3d8d2d0f
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/game-concept.md 2ee5801590b66b9404c289645f337bc459690eba
Reviewed-Content-Hash: design/gdd/mission-flow.md 6494efc6985c00b1da459f38e6c3a0c84972a31e
Reviewed-Content-Hash: design/gdd/side-scroll-combat.md 1ecde74bbfd569d1ceb4c4544a16c0c616cf0de2

## Peer review — 2026-11-14 — game-dev-ios: REVISE (minor), fixes applied
- Walk progress is any movement, left or right (prototype `if (mv) idle = 0`).
- Reset on resume is kept, and marked as new versus the prototype (which froze the timers across a pause).
- The move hand shows during walk_to[0] in the slice; later, the first beat with move (Rule 2, AC1).
- AC4 is strict: not shown at step 300, shown at step 301 (5.0167 s) at dt 1/60.
Awaiting game-dev-ios confirmation.

## Peer re-review — 2026-11-14 — game-dev-ios: APPROVE @ 4769035
All findings were checked as fixed. Status set to Approved.

## Cross-GDD review fixes — 2026-11-14 (TASK-010, gdd-cross-review-2026-11-14.md)
Consistency fixes C1–C5, S2 (pause releases held pads; the windup restarts on resume), stale "proposed" labels and D-09 done, plus alignment with Luan's D-08 (B) and D-10 (B, no special in combat). Status stays Approved; these are consistency edits, not design changes, except S2, which is new behaviour for both apps.
