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

## Peer review — 2026-11-14 — game-dev-ios: REVISE (minor), fixes applied
Findings and fixes:
- Story text order: fight beats keep the prototype order (play → caption, P-04); non-fight beats get a beat card before play. Rationale in Core Rule 2.
- No map in the slice: "the map" means the title screen until Map & timeline ships.
- R13 minimum buttons per type added (Core Rule 7b, AC15), matching schema 1.1. Defend is optional in a fight.
- Untyped tuning values: advance_debounce and bump_stop proposed for the D-09 batch; the page slide and meter pulses are feel constants; T_box, walk_gap and T_special are estimates only.
- AC12 (voice-over) deferred until `vo` exists.
- F2 and AC4: the walk start and end are defined (x_start, + length_screens × 1280).
- VI|EN only on the title and pause screens (P-04); the HUD toggle is removed.
Awaiting game-dev-ios confirmation.

## Peer re-review — 2026-11-14 — game-dev-ios: APPROVE @ 08046fb
All peer findings were checked as fixed. Status set to Approved.

## Cross-GDD review fixes — 2026-11-14 (TASK-010, gdd-cross-review-2026-11-14.md)
Consistency fixes C1–C5, S2 (pause releases held pads; the windup restarts on resume), stale "proposed" labels and D-09 done, plus alignment with Luan's D-08 (B) and D-10 (B, no special in combat). Status stays Approved; these are consistency edits, not design changes, except S2, which is new behaviour for both apps.

## Update — 2026-11-14 — D-07 (Luan): skip and medal
Core Rule 15 (skip on every story screen, a one-time kind warning per run, "Skip anyway" ends only that story section, no warning once the medal is earned, the medal is reported at quiz end), a skip_warning state, edge cases, UI, AC16–19, and the walk-props open question. Needs a peer re-review of Rule 15.

## Update — 2026-11-14 — devs' parity review additions
F5 beat positions (with the beat extent per type); the warning returns after "Keep reading" and only "Skip anyway" stops it (leader's call); pads by phase; end_pause for every type; Rule 7c training partner, dummies and hold-meter cap; the F4 walk_gap estimate from dummy_spacing; AC20–21.

## Update — 2026-11-14 — TASK-016: dialogue beat type
Rule 7 (six types), 7b (dialogue: no buttons), new 7d (order, speakers and portraits, ask button, skip/medal, R4c requested, language, hints), the dialogue_line state, F5 extent, new F6 dialogue time, AC23–25. Needs dev peer review together with the schema request.
