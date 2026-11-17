# Review log: game-concept.md

## Review — 2026-11-17 — Verdict: APPROVED (lean; known-open Luan decisions D-14, D-31, D-35 remain)
Review mode: lean · Workflow: standard
Scope signal: n/a (concept document, not a system; no implementation scope)
Specialists: none (lean mode)
Blocking items: 0 | Recommended: 5
Task: TASK-022 (Concept → Systems Design gate, concerns 1 and 4)
Summary: This is the first `/design-review` of the concept. The 8-section GDD checklist doesn't
apply to a concept document: `gdd-structure-check.sh` reports all 8 ABSENT because the concept
follows `.claude/docs/templates/game-concept.md`. Checked against that template, every section
is present, plus First Hero and Visual Identity Anchor. Gate concern 1 is fixed in this task:
Technical Considerations, Technical Risks and Next Steps now state the native stack (ADR-0001:
Swift + SpriteKit on iOS 17+, Kotlin + Android SDK; ADR-0002: ≤64 MB decoded textures). No Godot,
Unity or "Engine not chosen" text remains. The pillars, core loop and audience are coherent and
match the built slice. What remains is Luan's open decisions (below) and some stale wording that
predates the team and the slice (recommended).
Prior verdict resolved: First review

Known-open items (Luan's decisions; not new findings):
- D-14 (W16, stars and difficulty): the concept text already follows option A (L106 stars = quiz
  recall, Quiz & stars Rule 7; L157–161 difficulty = encounter composition only), changed by
  TASK-020a (1feac26). Luan has not decided D-14 yet. If he picks B, those lines change back. The
  "visible payoff per star" part of D-14 is not in the concept.
- D-35 (A13, ads and purchases): L67 "no ads or purchases aimed at kids unless Luan decides" is
  unchanged. The pillar-5 design test (L235–236, "**none**, unless Luan decides otherwise") carries
  the same opening. D-35 names only L67; it should cover L236 too (sent to the leader as text).
- D-31 (W1, reading load, no voice): the concept promises voice (L104, L156 "no reading required
  to start", L182, Pillar 3 L220 "short text with voice"), but the slice ships text only. Still open.

Earlier concept warnings (2026-11-14 cross-review, TASK-020):
- W1: still open (D-31).
- W16: concept text fixed (TASK-020a); decision still open (D-14). → **RESOLVED 2026-11-17** (D-14 A, TASK-022d; see update below).
- A11: resolved. Open Questions records landscape as decided (Luan). The "turn the phone" screen
  is specified in `design/ux/title.md` (L136).
- A13: still open (D-35). → **RESOLVED 2026-11-17** (D-35 A, TASK-022d; see update below).

Findings:
- [RECOMMENDED] First Hero (L40–42): "Content and history owner: none yet. Luan plans to add a new
  team member…" is stale. game-art-content owns the content, and Luan signs off history (Open
  Questions L356).
- [RECOMMENDED] Placeholder notice (L6–13) and Pillar 2 (L213–214): the "named history reviewer"
  and "history material has not arrived yet" predate the decision that Luan signs off history.
  Change them to "signed off by Luan".
- [RECOMMENDED] First Hero (L35) and Core Mechanics 3 (L125–126): "the map shows where each story
  happened" contradicts D-36 (Luan's direction, 2026-11-16: pins mark each hero's hometown, with
  heroes listed per place). Align after TASK-021 (`map-and-timeline.md`, "Map & Hometowns") merges.
- [RECOMMENDED] Next Steps (L396–406): the prototype (TASK-003), art bible (TASK-004), map-systems
  (TASK-008), architecture (architecture.md, ADR-0001–0003) and vertical slice (iOS r9 / Android
  r12) are done but still unticked. Only the platform line was ticked in this task.
- [RECOMMENDED] Core Identity (L72): "first-launch choice + a toggle in settings" assumes the open
  D-20 (language choice screen on first launch). Mark it pending D-20. Also, the medal (D-07, full
  story played) appears nowhere in the concept's reward description (L106, L183, L201).
- [ADVISORY] Market Risks: the kids'-category store rules (Google Play Families, Apple Kids) are
  still "not researched". They are needed before First Release, not for Systems Design.
- [ADVISORY] Header Status still reads "Approved (Luan, 2026-11-14)". The document has changed
  since (TASK-020a, TASK-022) without a re-approval note.

Dependency graph: the concept has no Dependencies section (template). The files it cites exist:
quiz-and-stars.md, title.md, map-and-timeline.md, art-bible.md, systems-index.md, architecture.md,
ADR-0001, ADR-0002.
Registry values: `design/registry/entities.yaml` has no entries, so no values were cross-checked
against it. Platform, iOS 17 and the 64 MB values were checked against ADR-0001 and ADR-0002.

Reviewed-Content-Hash: design/gdd/game-concept.md f53366ccf8b70e87e1ca074ad31bccc484703714
Reviewed-Content-Hash: design/registry/entities.yaml dfeacb02917f751cb1dfd88cf490c7ec3d8d2d0f
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: docs/architecture/adr-0001-native-per-platform.md 2a7aa3064cee1b2f4a20a12188b1e5eb8c90273f
Reviewed-Content-Hash: docs/architecture/adr-0002-asset-pipeline-and-budgets.md 911dbe1cb593923466e5aee5969b49329f926dee
Reviewed-Content-Hash: production/team/decisions.md 69e7687fddec619d7b259794f054ac9220e420bc
Reviewed-Content-Hash: design/gdd/reviews/gdd-cross-review-TASK-020.md 8a178de797e8c17195c148e0b13d178af9861952
Reviewed-Content-Hash: design/ux/title.md d297e16473eface0317e19dff1e14e4b2cdfeb76

## Update — 2026-11-17 — Luan decided D-35 A and D-14 A (TASK-022d)
Not a re-review; it records the decisions applied to the concept.
- **A13 / D-35: RESOLVED.** Both "unless Luan decides" clauses are removed, so the concept matches
  *Safe for kids*. The Monetization row now reads "None decided (open question; no ads or purchases
  aimed at kids)". The pillar-5 design test ends "**none**."
- **W16 / D-14: RESOLVED.** Confirmed that the concept already followed A (TASK-020a 1feac26). Two
  drifts were tightened:
  - Flow State "Difficulty scaling" now says later heroes scale by enemy count and the hits they
    take (their kinds), plus side, **never by reaction time**, and that stars measure story recall
    only.
  - Retention "Mastery" now says the missing third star is on the hero's quiz (story recall), not
    "mission".
  - Every other star line already names the quiz (L110, L128, L188, L379).
  - Not added: a per-star payoff, because that D-14 sub-choice is still open.
- Still open: D-31 (W1).
