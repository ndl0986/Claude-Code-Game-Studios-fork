# Gate Check: Concept → Systems Design

**Date:** 2026-11-17
**Config:** `workflow: standard`, `review_mode: lean`, `qa.level: standard`, `team.size: individual`
**Stage at check:** Concept (`project.yaml`)
**Verdict:** **CONCERNS** (stage not advanced)

## Required artifacts (1/1)

| Artifact | Status |
|---|---|
| `design/gdd/game-concept.md` | PRESENT (398 lines, substantive) |

## Recommended

| Item | Status |
|---|---|
| Game pillars (5) + anti-pillars | PRESENT (`game-concept.md`, Game Pillars) |
| Visual Identity Anchor (one-line rule + 3 principles) | PRESENT (`game-concept.md`, Visual Identity Anchor) |
| Concept prototype (`prototypes/`) | ABSENT — substituted by the built vertical slice: iOS r9 `9c12a4a` (QC `fc43e7d`) and Android r12 `1ae1560` (QC `25ce9c9`), both QC PASS, played by Luan and his child |

## Quality checks (3/4)

| Check | Result |
|---|---|
| Core loop described | PASS |
| Target audience identified (ages 6–10, Vietnamese primary school) | PASS |
| Visual Identity Anchor present | PASS |
| Concept reviewed with `/design-review` | NOT DONE — only read as context by the 2026-11-14 cross-review (CONCERNS) and TASK-020 (FAIL); concept warnings W1, W16, A11, A13 carried from those |

## Director panel (standard tier: 2 of 4)

- **Producer — CONCERNS.** Scope realistic for a solo developer; slice proves the loop. Stars/difficulty promise in the concept drifts from the GDDs (W16, open D-14). Pillar 5 text "no ads or purchases aimed at kids unless Luan decides" undercuts the Safe-for-kids pillar (A13, open D-35). No dedicated concept review.
- **Technical Director — CONCERNS.** Feasibility proven on both native apps. Technical Considerations / Risks sections still recommend Godot 4 / Unity and say "Engine not chosen", contradicting native Swift + Kotlin locked by ADR-0001. Systems designed from this text would start from the wrong platform.
- Creative Director and Art Director: not consulted at `standard` (enable with `modes.workflow: full`).

## Concerns

1. Stale engine language in the concept's Technical Considerations / Risks.
2. Stars/difficulty promise vs GDDs — resolves with D-14.
3. "Unless Luan decides" in pillar 5 — resolves with D-35 (recommended: remove).
4. No `/design-review` of `game-concept.md`.

## Recommendations

1. game-art-content: reconcile concern 1 (doc-only), then run `/design-review design/gdd/game-concept.md` (concern 4).
2. Luan: decide D-14 and D-35 in `production/team/decisions.md`.
3. Leader: re-run this gate; on PASS advance `project.stage` to Systems Design.

## Note

`project.stage` lags reality: the project already has GDDs, ADRs and a QC-passed native slice. After this gate, Systems Design → Technical Setup and Technical Setup → Pre-Production follow before the Pre-Production → Production gate, which is where the slice and the family playtest count as evidence.
