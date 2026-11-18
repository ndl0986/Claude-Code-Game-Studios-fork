# Review log: design/gdd/onscreen-keyboard-row.md

## Review — 2026-11-18 — Verdict: APPROVED
Review mode: lean · Workflow: standard
Scope signal: S–M (1 system, 4 formulas, 9 dependencies, no new ADR; producer should verify)
Specialists: none (lean)
Blocking items: 0 | Recommended: 3 | Advisory: 2
Summary: All 8 sections are present (Formulas required: the layout, the physical floor, the light, the draw). K-29 is written as decided (a short common word from the theme's rowWords pool; seeded no-repeat draw; change once every distinct letter is pressed and on each Play entry, only at a quiet moment, 0.3 s fades; shown with a hardware keyboard; active in a parade; hidden on the Title; hardware presses light the key). game-dev-android's plan items are in: the 8-letter cap (hit span 64…1216), the 18 mm floor stated on the hit rect (21.6 × 20.1 mm at the smallest Mac window; k = 1 on every MVP device), exact R2c definitions on the play clock, starvation accepted (leader call), the parade-lane note (leader call), the TASK-059 seed rule with a fixture case, Key Table schema 2 with the v1 fallback, and the published row band. Checked by computation: F1 centres and spans for n 2/3/4/8; every F2 row; the F4 fixture (index 2). Self-review fixed one thing before the commit: the Key Table fallback example named NEST, but in canonical order the first cast name of 2–8 letters is FOSSIL (key F).
Prior verdict resolved: First review
Findings:
- [RECOMMENDED] Hint Letters: read the row band (y ≥ 582) in F4 as a clearance box, and note the parade lane at 448 crossing the bottom slots with the row on (follow-up batch) (open)
- [RECOMMENDED] Reveal Stage: list the row band next to its cast, glyph and token boxes (follow-up batch) (open)
- [RECOMMENDED] TASK-059: add the F4 row draw case to key-table-schema-v1 (or a keyboard-row-v1) (open)
- [ADVISORY] K-29's text says "≤ 9 distinct keys"; this GDD and V17 cap words at 8 letters (game-dev-android's must-fix, the leader approved); K-29 may be worded to match
- [ADVISORY] AC-19 (Android insets) is NOT ASSESSED until an Android build exists
Reviewed-Content-Hash: design/gdd/onscreen-keyboard-row.md f1619f8c2ca21e57ab0ec344e84874e4ceeae523
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/key-table-theme-data.md c73c0a8e9abbb3b520ef953760a39bce3fc12eb8
Reviewed-Content-Hash: design/gdd/input-key-filter.md d72642557b630aff374132b13c6085e033de2bab
Reviewed-Content-Hash: design/gdd/press-queue.md d8d2ac774eeff254e1e18f65d9ab9b76ec0d80e5
Reviewed-Content-Hash: design/gdd/reveal-stage.md d6c0206ac4d61e436e04064edaf3c5f17405aca5
Reviewed-Content-Hash: design/gdd/hint-letters.md 61ee882c83b3075f1b3221a6167fdb308a1040d3
Reviewed-Content-Hash: design/gdd/settings-store.md 2ddae72ca6a1ec7067b369e04e1056c9a0148edc
Reviewed-Content-Hash: design/art/art-bible.md 3b829e1421f7eaa12e72cf7394b3947a42df7b63
Reviewed-Content-Hash: production/team/decisions.md 7cbcab5bfc439d11f9879c6c404bd4666da33c97
