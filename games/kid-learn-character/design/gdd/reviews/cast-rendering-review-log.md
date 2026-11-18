# Review log: design/gdd/cast-rendering.md

## Review — 2026-11-18 — Verdict: APPROVED
Review mode: lean · Workflow: standard
Scope signal: L (one system, 7 formulas, 4 dependency GDDs plus Reveal Stage and Parade downstream, and the SVG-rendering ADR still to write; producer should verify)
Specialists: none (lean). Note: run in the authoring session (game-dev-ios, TASK-044), so it is not an independent read; game-dev-android reviewed the plan and does the independent read.
Blocking items: 0 | Recommended: 4 (applied before the commit) | Advisory: 3
Summary: All 8 sections are present (Formulas required: halo, speck alpha, the stardust cap, idle and hop, memory, the late-art wait). The plan's R1–R12 are in, with game-dev-android's six items (SVG subset and baked file, units and tiers, late art that never moves the Press Queue's numbers, per-platform speck determinism, the memory formula, the blend as maths) and Luan's K-16. The leader's four notes are in (F7 worked table with 0.05 s at the default no-extension hold, the chosen no-key-waiting rule, the hop 13 units marked a proposal, willForm for hasWord, TASK-045 art bible follow-ups). No registry exists, so values were checked against the art bible, MorphCore, Key Table, Press Queue, Audio & Voice, K-08/K-11/K-16 and the one-shot.
Prior verdict resolved: First review
Findings:
- [RECOMMENDED, applied] R4: the one-shot's glyph edge colour (#fffaeb, L ≈ 0.96) is above the art bible's L 0.88 frame cap → highlight cream #f8efdc (L 0.87) at 85%.
- [RECOMMENDED, applied] R5/F2: the one-shot's halo blur ran 44–60 (73–100%), not the art bible's 60–100% → the GDD follows the art bible and says so; the glow disk (radius 230, 25%) added.
- [RECOMMENDED, applied] R10: "a waiting key never replaces a half-faded creature" was not true under the chosen full-0.5 s rule (a key queued after the wait, during the fade-in) → stated as an accepted limit (≤ form_s), an edge case added, AC-14 reworded.
- [RECOMMENDED, applied] R9: the Key Table load check proves the files exist, not that the cast file parses → willForm true = passed the theme check or resident; false = known missing or Failed this run; a later parse failure goes through R10.
- [ADVISORY] Dependencies: Reveal Stage, Parade and Accessibility have no GDD yet; each must name Cast Rendering and the R12 interface. Reveal Stage carries willForm → hasWord to the Press Queue and Audio.
- [ADVISORY] MorphCore's ownership table lists "the halo pulse" under the Reveal Stage; R1 here splits it (Reveal Stage: when; Cast Rendering: the look). A one-line MorphCore touch-up would remove the overlap.
- [ADVISORY] Tuning: halo_steady 0.8, reduce_motion_scale 0.5 (hop 13 units) and the list tier 192 px are proposals; the F7 choice makes K-16's 0.5 s apply only with no key waiting or a word-extended hold (0.05 s at the plain 3.0 s hold with a key waiting).
Reviewed-Content-Hash: design/gdd/cast-rendering.md c2b664643e6fdc0708cce40015276c5ee0d37d03
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/game-concept.md e525c154ca1b014fe3ca0024ba5a339d37135429
Reviewed-Content-Hash: design/gdd/systems-index.md 02e247b598a2df9f3bc7fe9d6ef0775c96f85941
Reviewed-Content-Hash: design/art/art-bible.md 1a8306227139727ca120d88e6f74223b68b08dba
Reviewed-Content-Hash: design/gdd/morphcore.md 7a65f1c4513cf05fc49fc11342e9c619485b6e66
Reviewed-Content-Hash: design/gdd/key-table-theme-data.md e108179924cb3f53191a26f006791f88e7e342bd
Reviewed-Content-Hash: design/gdd/press-queue.md f73cb9bd44f9d6ca15ca48975e5a43d77bb7870f
Reviewed-Content-Hash: design/gdd/audio-voice.md 1f3d8158975fa07f5bac347250674314dc0ac4f0
Reviewed-Content-Hash: production/team/decisions.md 4baed8206a9b8920b39a20154cb0d523e6a75118

## Update — 2026-11-18 — parade count (no re-review)
Review mode: lean · Workflow: standard
Change: K-17 makes a parade every 6 creatures: R10, F6, the measurement plan and an edge case now use `parade_count` (6; ≈ 1.1 MB at the 256 tier) instead of 8, and a walker that is also the current stage creature keeps a separate parade-role copy (Parade plan, TASK-046).
Reviewed-Content-Hash: design/gdd/cast-rendering.md 7638b1bbf8c772dd1014f27375a2c17811cee115

## Update — 2026-11-18 — game-dev-android independent read: REVISE, addressed
Review mode: lean · Workflow: standard
Source: game-dev-android's independent read of 3aa1c99 (relayed by the leader); the MorphCore ownership wording (73e9c9a) and parade_count (febd066) were already on the branch.
Findings:
- [BLOCKING] F4 capped the scene too, so a speck over a scene channel above the cap (Day sky blue, highlight cream) darkened it → C = max(C_scene, min(C_cap, C_scene + Σ aᵢcᵢ)); AC-10 checks a speck over a brighter scene pixel leaves it unchanged (fixed)
- [RECOMMENDED] Late art and sound: E8/E9 play during the F7 wait while the specks hold the silhouette → Edge Case accepts it (≤ 0.5 s; Audio does not hold E8) (fixed)
- [RECOMMENDED] F1 / AC-6: stage_to_px 1.6 matched no fit → 11" iPad 1.87 (by width) and 2.32 (by height), tied to the TASK-049 stage-fit rule; the 6 px results are unchanged (fixed)
- [RECOMMENDED] MorphCore ownership row split when / look (73e9c9a, its log) (fixed)
- [RECOMMENDED] F6/R10 parade_count 6 (K-17, ≈ 1.1 MB) and a separate parade copy of a walker that is the stage creature (febd066) (fixed)
Reviewed-Content-Hash: design/gdd/cast-rendering.md 8a503e2f8257d53ce8cf3c406690e6b420f6b43b

## Update — 2026-11-18 — TASK-054b per-look glyph and the Scene worst case (no re-review)
Review mode: lean · Workflow: standard
Change: C1: R4, R5, R7 and new F8 key the glyph edge (amber #8a4b12 6 u in Morning/Day), the halo (saturated amber in Morning/Day, proposal #f6a93b; 70% size at Night, radius 230 → 161), the Night top stop (#fff1b8 → #ffd36e) and the creature's 15% Night dim to the Scene's look and lookBlend, blended in linear RGB so the Scene's 160-case check shares one edge model; F4's cap uses the current top stop; the halo's current radius is published for the Scene; Interactions, two edge cases and AC-18 added. C2: R11's measurement run includes the Scene's worst case (Night, snow 60 + windy, 3 clouds, 50 stars).
Reviewed-Content-Hash: design/gdd/cast-rendering.md 633aa4552182f511e341012e2786923fe3adfe4e

## Update — 2026-11-18 — K-25 edge switch (no re-review)
Review mode: lean · Workflow: standard
Change: K-25 (Luan, after game-art-content's finding and an exact recheck): R4 and F8 drive the glyph edge from the Scene's sky-mid luminance, not lookBlend: amber #80450f (L 0.089) above L_x ≈ 0.308 and cream #f8efdc at 100% (was 85%) below, with ±0.005 hysteresis and a 1 s wall-clock cross-dissolve, no colour blend; the floor is ≥ 3:1 at w 0 and 1 and ≥ 2.5:1 inside crossfades (measured minimum 2.57:1). The F8 table adds skyMidL and the two switch times; castDim multiplies linear RGB; the Scene row reads skyMidL; an edge case for hovering at L_x; AC-18 restated.
Reviewed-Content-Hash: design/gdd/cast-rendering.md fb093009752428febf40e087cbc610bbf31771f1

## Update — 2026-11-18 — TASK-056c cross-review fixes (no re-review)
Review mode: lean · Workflow: standard
Change: from /review-all-gdds 2026-11-18 (design/gdd/gdd-cross-review-2026-11-18.md): W-3: R3 puts s and idleTime on the play clock supplied by the Reveal Stage (R8), the edge dissolve stays wall-clock; W-6: Key Table cite → §4; W-9: Scene and App Shell added to Dependencies; nit: the shown edge floors at 2.53:1 under hysteresis (R4, F8). Text only; no rule changed.
Reviewed-Content-Hash: design/gdd/cast-rendering.md dd6e05e7ee77cf26f2d7ae0e71e3239c515d414b

## Update — 2026-11-18 — TASK-059b stray markup removed (no re-review)
Review mode: lean · Workflow: standard
Change: deletes two stray lines of tool markup ("</content>", "</invoke>") left at the end of the file by its author's writing tool; no content or rule changed.
Reviewed-Content-Hash: design/gdd/cast-rendering.md d8929011578465d6b1ad4118f551540f5bdbc9d9
