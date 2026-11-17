# Review log: design/gdd/game-concept.md

## Review — 2026-11-18 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: S
Specialists: none (lean)
Blocking items: 3 | Recommended: 4
Summary: The concept's core (pillars, core loop, MDA, target player) still holds, but it lagged the newer decisions: the Visual Identity Anchor contradicted the art bible and K-08, the K-07 theme model was missing, and Core Mechanics/MVP still made the on-screen keyboard the main input and missed hints, the parade, the tap sound, inert non-letter keys and child lock-in. Revised the same day (Luan chose "fix now"); a fresh re-review was not run, Luan accepted the revision and asked to re-run the gate.
Prior verdict resolved: First review
Findings:
- [BLOCKING] Visual Identity Anchor: "nothing flashes"/dusk-only contradicted art bible §1–2 and K-08 (2.2 Hz glow, time of day) → replaced by the art bible summary
- [BLOCKING] Core Mechanics / Scope Tiers: K-07 theme model missing (MVP "one default set", Dinosaurs in Tier 1) → theme key table added; MVP = Dinosaurs theme
- [BLOCKING] Core Mechanics / MVP: on-screen keyboard as main input; hints, parade, tap sound, inert keys, child lock-in, clock scene missing → rewritten to match the systems index
- [RECOMMENDED] Risks / Open Questions: resolved items removed; NOT ASSESSED lock-in and iPad latency, SVG path, macOS Kids added
- [RECOMMENDED] Technical Considerations: SpriteKit + MorphCore + morph contract v1, no Rive, no network
- [RECOMMENDED] Scope: Vertical Slice tier added; "~1 week" marked an aspiration
- [RECOMMENDED] Next Steps: checklist updated
Reviewed-Content-Hash: design/gdd/game-concept.md e525c154ca1b014fe3ca0024ba5a339d37135429
review-receipts: not stamped, no such file: design/registry/entities.yaml
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/art/art-bible.md a01094340e7e5b7bdae636f4cc879d0f84b472b5
Reviewed-Content-Hash: production/team/decisions.md f952e72dffded60e03757aa070e59bbc13fc03f4
Reviewed-Content-Hash: design/game-brief.md ca66d372d8235f6f0effd7a6f6957c85c44df681
