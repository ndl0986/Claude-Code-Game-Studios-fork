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

## Update — 2026-11-18 — game-dev-ios review + Luan's letter-sound picks (TASK-036)
Not a re-review; it records one consumer fix and Luan's decisions.
- Fix (matches TASK-038): glyph missing → no morph, the cast member fades in, with the voice.
- P1: P = **Tapejara** replaces pteranodon (/p/ inside; flyer in flight; teal slot unchanged).
- X1: **Xenoceratops kept** as the one recorded exception to T5 / K-09. New theme field
  `soundExceptions` and item `sound: "exception"`; V4 allows it only for listed keys.
- C1–C3: Triceratops, Oviraptor, Utahraptor, Quetzalcoatlus kept.
- Still open: hue-slot cap counted per edition (art-director). The silhouette-storage and family-name
  findings are handled outside this GDD (leader).
Reviewed-Content-Hash: design/gdd/key-table-theme-data.md f8f54faf82ac675dfdf929b0465ef4bdff8253c8

## Update — 2026-11-18 — TASK-042 follow-ups (no re-review)
Review mode: lean · Workflow: standard
Change: three follow-ups from the Settings Store and Audio & Voice GDDs. (1) Section 5 and Edge Cases: at launch there is no current theme, so a stored themeId that fails the check (or is not bundled) loads Dinosaurs in memory and the stored themeId is kept (Settings Store R6). (2) New theme field `voiceDurations` (locale → line id → seconds, written by the build tool) and validator rule V15: complete, within ±0.01 s of each file, word lines ≤ 1.25 s, letter/number lines ≤ 1.0 s (Audio & Voice F6, A3); run-time fallback to the bound T + 1.5 s. (3) Dependencies: back-references to Audio & Voice and Settings Store, and the Press Queue's use of the durations. ACs 13–14 added. Verdict unchanged.
Reviewed-Content-Hash: design/gdd/key-table-theme-data.md 6fa1ce3101c052754590905f734280abc25e3540

## Update — 2026-11-18 — TASK-042 V15 priming note (no re-review)
Review mode: lean · Workflow: standard
Change: from game-dev-ios's review of TASK-042: V15's duration is the decoded length with AAC encoder priming and padding removed (what the app's decoder returns and Audio schedules), not the container duration; priming (~2112 samples ≈ 44 ms at 48 kHz) would otherwise break ±0.01 s.
Reviewed-Content-Hash: design/gdd/key-table-theme-data.md e108179924cb3f53191a26f006791f88e7e342bd

## Update — 2026-11-18 — TASK-050 cross-GDD follow-ups (no re-review)
Review mode: lean · Workflow: standard
Change: TASK-050: Rule 4.5 `peek(key)` for prefetch (the item resolve would pick now; lastShown and the variety stream unchanged), the Reveal Stage interaction row, AC-15. Wording and interface follow-ups from K-18/K-19/K-20 and the Cast Rendering and Reveal Stage reviews; verdict unchanged; review by game-dev-ios.
Reviewed-Content-Hash: design/gdd/key-table-theme-data.md 3732afc4fa931107ff03ab93f9d73a6551e4f483

## Update — 2026-11-18 — TASK-050 item 9 (no re-review)
Review mode: lean · Workflow: standard
Change: K-22: new theme field `titleCastId` (the one cast member idling on the Title; Dinosaurs = the T-Rex, as played), validator rule V16 (must name an item in the theme), run-time fallback to the first item in canonical order (key A, item 0) with one debug log line, App Shell & Title rows in Interactions and Dependencies, AC-16. Verdict unchanged; review by game-dev-android.
Reviewed-Content-Hash: design/gdd/key-table-theme-data.md 6878f022785a592f47c810effdde3d332360a3bc

## Update — 2026-11-18 — TASK-050 item 9 fix (no re-review)
Review mode: lean · Workflow: standard
Change: mechanical fix from game-dev-android's check of ed7e812: the V16 row had been inserted inside the V15 row (after "48 "); V15 is whole again (its word ≤ 1.25 s and letter ≤ 1.0 s limits, cited by Audio F6/AC-6 and Press Queue F1) and V16 is its own row. No content change.
Reviewed-Content-Hash: design/gdd/key-table-theme-data.md 640a8fc4bb90c1b95656ed32f90d046078e50488

## Update — 2026-11-18 — TASK-060 schema 2 and rowWords (no re-review)
Review mode: lean · Workflow: standard
Change: schemaVersion 2 adds the required theme field `rowWords` (K-29: the keyboard row's word pool; Dinosaurs = 16 words, no given names) and validator rule V17 (≥ 8 unique entries, 2–8 letters A–Z, every letter a theme key, toddler-safe review). The app knows majors 1 and 2; a v1 theme (or a pool failing V17 at load) loads with the row fallback: the first cast name of 2–8 letters in canonical order (Dinosaurs: FOSSIL), else ABC, one debug line. AC-6 now tests an unknown major 3 and the v1 fallback; AC-17 added; Interactions and Dependencies name the On-screen Keyboard Row. Review: game-dev-android (with TASK-060).
Reviewed-Content-Hash: design/gdd/key-table-theme-data.md c73c0a8e9abbb3b520ef953760a39bce3fc12eb8

## Update — 2026-11-18 — TASK-069 ADR-0003 follow-ups (no re-review)
Review mode: lean · Workflow: standard
Change: ADR-0003 (Accepted) D1/D3/D4: `id` = folder = Settings themeId (Dinosaurs "dinosaurs"); new field `assetPrefix` ("dino") used in castIds and asset names, checked by new V18 (present, [a-z]{2,8}, unique across bundled themes, id matches the folder); `art` names the baked cast/cast_….json, with its SVG source found by the stem rule (src/art/, and src/sil/ for silhouettes); V6 uses the prefix; V7 checks existence in exact case and, at build, the sources by stem. AC-18 added. No schema bump (v2 has not shipped). Review: game-dev-android from the diff.
Reviewed-Content-Hash: design/gdd/key-table-theme-data.md ba50e4e2980d09c4be947addfd2717d2739e8ea3

## Update — 2026-11-18 — TASK-069 part 2: contract questions KT-Q1–Q9 and V18 nits (no re-review)
Review mode: lean · Workflow: standard
Change: answers to game-qc-android's key-table-schema-v1 questions, written into the rules: KT-Q1 seeding is per platform and the fixture feeds raw draws (F1 text, AC 8); KT-Q2 a draw is consumed only when |C| ≥ 2 (n = 2 with last set draws nothing); KT-Q3 a missing key is V2 only, V3 is extra or malformed keys; KT-Q4 exactly-one-item is a build setting `singleItemPerKey`, not a theme field; KT-Q5 V5 digit words are exact `<number word> <singular|plural>`; KT-Q6 V6 castId pattern `^<prefix>_<key>_<name>_<nn>$` with nn the two-digit edition index (not the variant field), prefix = assetPrefix or, for v1, id; KT-Q7 `shared` is outside V10's cap and sibling rule; KT-Q8 V17's letter clause is a deliberate guard; KT-Q9 unknown and missing required fields are decode errors (= V1), schema-dependent fields (rowWords, assetPrefix) decode as absent and are checked by V17/V18. game-dev-android's nits: V18 runs over the full theme list at build and launch before any load; v1 themes use id for V6.
Reviewed-Content-Hash: design/gdd/key-table-theme-data.md b8570e7474720983d1fec2e2db878edc77b75712

## Update — 2026-11-20 — TASK-145b sound and voice files are .caf, K-52 (no re-review)
Review mode: lean · Workflow: standard
Change: K-52 (Luan): baked audio is uncompressed 16-bit LPCM in .caf. The sfx field example, the built voice path pattern and its examples, the asset-formats line, the naming list and the example item now read .caf instead of .m4a. No rule changes otherwise. Lands together with key-table-schema-v2 (TASK-146) and the KidCore validator change (game-dev-android).
fixture: key-table-schema-v2 (TASK-146)
Reviewed-Content-Hash: design/gdd/key-table-theme-data.md 11fc4c83ea1106038d5eeb8fd8bb2e9f103dc5e3
