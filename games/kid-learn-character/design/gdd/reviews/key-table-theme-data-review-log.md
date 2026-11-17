# Review log: design/gdd/key-table-theme-data.md

## Review — 2026-11-18 — Verdict: APPROVED (lean; open content picks P1, X1, C1–C3 are Luan's)
Review mode: lean · Workflow: standard
Scope signal: M (one data format, a validator with 14 rules, one formula; no new ADR; producer to verify)
Specialists: none (lean)
Blocking items: 0 | Recommended: 3 | Advisory: 2
Task: TASK-036
Summary: First review, by the author. All 5 required sections are present at standard, plus Formulas
(the item-pick rule F1 is numeric), Player Fantasy and Tuning Knobs (advisory). The data model covers
the theme, key entry, item, glyph set and naming, and folds in game-dev-ios's 11 plan-review points.
Luan's Q1–Q6 answers (2026-11-18) are written as decisions. The Dinosaurs table matches the played
prototype's KEY_TABLE (names, words, say strings, families) and the art bible §4 hue slots; every
slot is within the cap of 4 and family siblings never share a slot. Rules and validation are precise
enough to build a validator from, and every acceptance criterion is checkable by the validator or a
unit or integration test.
Prior verdict resolved: First review

Completeness (standard): Overview ✓, Detailed Design ✓, Edge Cases ✓, Dependencies ✓, Acceptance
Criteria ✓, Formulas ✓ (required: F1 defines numeric pick probabilities). Advisory: Player Fantasy ✓,
Tuning Knobs ✓.

Dependency graph: none of the dependent GDDs exist yet (Audio & Voice, Cast Rendering, Reveal Stage,
Press Queue, Hint Letters, Parade, Parent Gate & Grown-up Panel, Theme Packs, Localization, Settings
Store, Input & Key Filter/TASK-037). Each is listed in Dependencies with what it uses; the back-links
are due when those GDDs are written. Existing references were checked: morph-contract-v1.md,
adr-0001-native-apple.md (Decision 6), art-bible.md §3/§4/§5/§8, decisions.md K-02/K-05/K-07/K-08.

Registry values: no design/registry/ exists for this game, so no registry check was run. The values
were checked by hand against their sources: the hue slots and the slot cap (art bible §4), the
artboard and anchor and sfx ≤ 2 s (§8), the morph-v1 command subset (contract §2), and the say strings
and words (prototype config.js).

Findings:
- [RECOMMENDED] Silhouette storage: ADR-0001 Decision 6 and art bible §8 say the silhouettes are
  path data "in the key table". This GDD stores a **reference** to a per-item silhouette file
  (sil_….json), as the task brief and the approved plan asked. The meaning is the same (data, not
  code; one compound path), but ADR-0001's wording should say "referenced from" at its next touch,
  or the format could inline the path. For game-dev-ios / the ADR owner.
- [RECOMMENDED] Art bible §3 lists families for B–Z but not ankylosaur (A) or the ornithomimid pair
  (G, O). This GDD names them "ankylosaur" and "ornithomimid" (O = oviraptor is not an ornithomimid,
  but it shares the prototype's "ostrich" drawing). art-director to name the families in §3.
- [RECOMMENDED] V10 hue-slot cap with 4–5 items per key: counted per edition (proposed). art-director
  to confirm before production content.
- [ADVISORY] The idle parameters are referenced by family id but their file belongs to Cast
  Rendering, which has no GDD yet.
- [ADVISORY] SFX are the prototype's synth recipes; real sounds and the recorded voice are not sourced
  (systems index high-risk row, Audio & Voice).

Open for Luan (content picks, not review findings): P1 (P replacement), X1 (X replacement), C1–C3.

Reviewed-Content-Hash: design/gdd/key-table-theme-data.md c5a59435cb59cef278c7c1e3a26723b83d0b54d3
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/art/art-bible.md a01094340e7e5b7bdae636f4cc879d0f84b472b5
Reviewed-Content-Hash: docs/architecture/morph-contract-v1.md 4935b3ac7490c131eb67bdf4c388b14a5f7ed46b
Reviewed-Content-Hash: docs/architecture/adr-0001-native-apple.md 9bd960cdffd4bec53f0f2875d6f4c7a33f873a70
Reviewed-Content-Hash: design/gdd/game-concept.md e525c154ca1b014fe3ca0024ba5a339d37135429
Reviewed-Content-Hash: production/team/decisions.md f952e72dffded60e03757aa070e59bbc13fc03f4
Reviewed-Content-Hash: design/gdd/systems-index.md 6652c64909266be6f7de820ddfbff3a731c77c7d
