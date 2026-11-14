# Review log: map-and-timeline.md

## Review — 2026-11-14 — Verdict: APPROVED (lean self-review; dev peer review pending)
Review mode: lean · Workflow: standard
Scope signal: M
Specialists: none (lean mode)
Blocking items: 0 | Recommended: 2
Summary: Complete for standard tier (6/6 required, with Formulas for pin position, spacing and region glow). The map only displays Hero progression's derived state; it never decides unlocks. QC G5 is answered by the completed state (stars and medal). The modern map with Hoàng Sa and Trường Sa is required (D-28).
Prior verdict resolved: First review
Findings:
- [RECOMMENDED] Cross-system: the schema needs hero.map and hero.era (request after review).
- [RECOMMENDED] Decision: D-27 slice stub and D-28 map source are Luan's.
Reviewed-Content-Hash: design/gdd/map-and-timeline.md 6a837c8eb2fc9630062d90174fa9ee063eefafb9
Reviewed-Content-Hash: design/registry/entities.yaml dfeacb02917f751cb1dfd88cf490c7ec3d8d2d0f
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/hero-progression.md c5b7dbf80b1d18f35f60ee4c713549e10d03b160
Reviewed-Content-Hash: design/gdd/mission-flow.md 85cb878b47b2d79fbdd7fe9d8718b2461d8045c4
Reviewed-Content-Hash: design/gdd/game-concept.md 2ee5801590b66b9404c289645f337bc459690eba

## Peer review — 2026-11-14 — game-dev-ios: REVISE (minor), fixes applied
Layout: map box x 40–700, y 20–700; timeline as a vertical column on the right (x 740–1240, y 140–700; the leader's call). Pins closer than pin_world (= pad_min / k) merge into a cluster pin that opens the multi-hero picker (F2, AC11). Region is data (hero.map.region). A drag past ~10 pt never taps (AC12). Schema 1.5 agreed: hero.map {x, y, region} plus an optional hero.era; the modern location uses place. Awaiting confirmation.
