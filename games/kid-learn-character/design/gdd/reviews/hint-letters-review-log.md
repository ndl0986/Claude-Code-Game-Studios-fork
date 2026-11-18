# Review log: design/gdd/hint-letters.md

## Review — 2026-11-18 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: M
Specialists: none (lean)
Blocking items: 1 | Recommended: 2
Summary: All 8 sections are present (Formulas required: pick, fades, drift, placement validity, physical size). The plan-review items from game-qc-android (drift in every clearance, slots with jitter re-checked on the jittered centre and an empty-screen AC at the widest creature and k > 1, the 18 mm floor with phones out of scope, live Android gesture insets marked NOT ASSESSED, a named hintTime clock with drift as a pure function of age) and Luan's K-15, K-18 and K-20 are written as rules with ACs. Numbers re-derived: L1 152.1 from the moon, R1 142.0 from the middle token (the plan's 155.8 used the far token), jittered L1 138.9, spacing ≥ 190 ≥ 185.6, 11" iPad 27.0 mm. One blocker: the moon, token and glyph positions were written as this system's own constants, though the Parent Gate and Reveal Stage own them. Revised the same day by the author (TASK-047). No registry exists (design/registry/ absent); values were cross-checked against the named GDDs, the one-shot and decisions.
Prior verdict resolved: First review
Findings:
- [BLOCKING] Detailed Design, R5: the moon, queue-token, glyph and cast positions are other systems' (Parent Gate, Reveal Stage) but were stated as fixed here, so a move in TASK-049 would silently break every clearance → R5 reads them as published rectangles in stage units, uses the one-shot / art-bible values until then, and AC-5's static build check re-runs on the published values (fixed)
- [RECOMMENDED] Formulas, F5 capacity at k = 1.2: the text said only the outer columns remain, but L1 and R1 also fail the scaled moon and token clearances (167.4 / 157.4 against 152.1 / 142.0) → stated: L3 and R3 remain, 2 hints (fixed)
- [RECOMMENDED] Detailed Design, R5 static margins: "clears the glyph box by ≥ 27" was wrong (475 − 360 − 97.8 = 17.2) → corrected, and the 42.2 stage-edge margin worded as the circle plus drift (fixed)
- [OPEN] Dependencies: Reveal Stage (TASK-049), Parent Gate & Grown-up Panel, App Shell and Accessibility must name Hint Letters (originFor, stage_to_px, the published rectangles, the freezes); Input & Key Filter's R8 origin line goes to its owner in TASK-050
Values cross-checked: hint_count 3, life 6 × U(0.8, 1.2), gap 0.7, fades 0.6 / 0.8, size 120, drift ±10 / ±8 at 0.7 / 1.3 rad/s, pulse 4 rad/s ±6% (one-shot); hitRadius 75 (Input F1); sky-only areas and Letter Gold on cream (art bible §4, §6, §7); ignored hint stays (K-15); K-18 items 1–7; stage fit and challenge freeze (K-20). K-21 (gate risk, Mac child lock) does not touch hints.
Reviewed-Content-Hash: design/gdd/hint-letters.md 58edd5c55ed51f397313512a49966a25448a3a61
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/game-brief.md ca66d372d8235f6f0effd7a6f6957c85c44df681
Reviewed-Content-Hash: design/gdd/game-concept.md e525c154ca1b014fe3ca0024ba5a339d37135429
Reviewed-Content-Hash: design/gdd/systems-index.md e4b8da5e4cc3353630b8ea281460e0d471186c24
Reviewed-Content-Hash: design/art/art-bible.md ff95ca81ce8e7a2adbf92f5ce92267c3fe355cda
Reviewed-Content-Hash: design/gdd/input-key-filter.md 14c4a9a102f93f6ed093d038b3dcc1387550e738
Reviewed-Content-Hash: design/gdd/press-queue.md f73cb9bd44f9d6ca15ca48975e5a43d77bb7870f
Reviewed-Content-Hash: design/gdd/key-table-theme-data.md e108179924cb3f53191a26f006791f88e7e342bd
Reviewed-Content-Hash: production/team/decisions.md cef7e6d8add4a57c0f8df35531c29f8c12fc3f1e

## Update — 2026-11-18 — TASK-054a follow-ups (no re-review)
Review mode: lean · Workflow: standard
Change: H1: F5's Mac 700-pt row replaced by App Shell's 960 × 540 pt minimum (2× 254 ppi: stage_to_px 1.5, 22.5 mm; 1× 109 ppi: 26.2 mm; k = 1); the capacity notes say k > 1 cannot occur in the MVP (phones only); AC-7 keeps 1.10 and 1.2 as simulated factors. Wording and rule edits from the TASK-054 follow-up list (production/team/TASK-054-followups.md @ 84f7ea2); Parent Gate G-numbers cited as given by game-qc-ios (TASK-048 not merged). Review: game-qc-ios, from the diff.
Reviewed-Content-Hash: design/gdd/hint-letters.md 5501526f0fbbf339c54132d0f52fc61939a8ad8d

## Update — 2026-11-18 — TASK-056a cross-review fixes (no re-review)
Review mode: lean · Workflow: standard
Change: K-26 (Luan): while the Parade is Walking (paradeWalking), hints dim to parade_hint_alpha 0.5 (proposal) over 0.6 s, hold still (no drift, ages, lives or spawns), stay tappable, and resume on Ended without the 0/0.7/1.4 replay: R9 rows, a Dimmed state, the Parade Interactions and Dependencies rows, two knobs, AC-18b. W-6: the R9 theme row cites Key Table §4. From design/gdd/gdd-cross-review-2026-11-18.md and K-26. Review: game-qc-android (diff re-run).
Reviewed-Content-Hash: design/gdd/hint-letters.md 8a0fc351301575da6d305cdc3decd091f8a61016

## Update — 2026-11-18 — TASK-056a review fix (no re-review)
Review mode: lean · Workflow: standard
Change: game-qc-android's review: option (a), hintTime stops while the parade is Walking (Dimmed), as in Frozen; R6's hintTime definition, the R9 Parade rows and the Dimmed state say so; the first-press pulse holds; the dim fade runs on the play clock. Dependencies' Parade line is a plain cite (TASK-056d did it).
Reviewed-Content-Hash: design/gdd/hint-letters.md 15d217671d25cf93d93b2145e8d681910b99493d

## Update — 2026-11-18 — TASK-056a review fix 2 (no re-review)
Review mode: lean · Workflow: standard
Change: game-qc-android's review: the Frozen state now exits to Dimmed when the challenge fails or times out while the parade is still Walking (Parade R6a), and to Running when the panel closes (the parade has faded out); no replay; the 0.5 dim is kept while Frozen.
Reviewed-Content-Hash: design/gdd/hint-letters.md 1b9e2c650de556f3da60f980276f17631a3e148a

## Update — 2026-11-18 — TASK-057a re-run info notes (no re-review)
Review mode: lean · Workflow: standard
Change: R-3: R4's seed cite points at Key Table §4 (point 4, Variety seed). From the cross-review re-run (PASS, e8c8344). Text only; no rule changed. Review: game-qc-android, from the diff.
Reviewed-Content-Hash: design/gdd/hint-letters.md 61ee882c83b3075f1b3221a6167fdb308a1040d3

## Re-review — 2026-11-18 — Verdict: APPROVED
Reviewer: game-qc-android (independent read for TASK-047; logged afterwards under TASK-058, because the leader's gate-check found the read unlogged)
Review mode: lean · Workflow: standard
Scope: the whole GDD at 78a5b50 (file 58edd5c5…), then the diffs e2a5cba (file e1fc5f92…) and 198c910 (file 49cb36cd…).
Checked:
- The four conditions of the plan approval are all present:
  - (a) F4 is checked on the jittered centre, with 4 redraws, then zero jitter, then the next slot (R5, AC-4 over 100k spawns, including the drifted circles over each hint's life);
  - (b) the slots the widest creature blocks are named (L2, L4, R2, R4 at the estimate), and the empty-screen AC runs in the worst case (AC-6, AC-7);
  - (c) the K-20 challenge freeze: hintTime stops, with no replay (R9, AC-14), and the panel works the same way (AC-15);
  - (d) Android gesture insets are read live, and an on-screen hint is never moved (R11, AC-20, NOT ASSESSED until an Android build).
- Numbers recomputed independently, all matching:
  - static slots: L1 to the moon 152.1; R1 to the middle token 142.0; glyph-box spare 17.2; stage edges 42.2;
  - slot spacing after jitter ≥ 190;
  - at k = 1.2: 222.7 / 167.4 / 157.4 / 117.4;
  - F5 hit sizes: 27.0 / 31 / 30 / 16.4 mm, with k = 1.10.
- Non-blocking note: the drop to 2 hints starts at k ≈ 1.044, not 1.2. e2a5cba stated it, and AC-7 added k = 1.10. TASK-054a H1 later made k > 1 impossible in the MVP.
- 198c910: hints are drawn above the creature (Reveal Stage R10), so what a child sees on top is what a touch hits (Input R7).
Later diffs, each approved by game-qc-android:
- TASK-056a ed68d7b: the K-26 Dimmed state. 146b23d: hintTime stops while the parade walks. ddc0531: Frozen → Dimmed when the parade is still walking, and the 0.5 dim is kept.
- TASK-057a 8034d93: R4 cites Key Table §4 point 4.
- The cross-review (TASK-055) found no Hint Letters blocker; its re-run after TASK-056 was PASS.
Prior verdict resolved: Yes (NEEDS REVISION, its blocker and recommendations fixed by the author before this read)
Reviewed-Content-Hash: design/gdd/hint-letters.md 61ee882c83b3075f1b3221a6167fdb308a1040d3

## Update — 2026-11-18 — TASK-062 follow-ups (no re-review)
Review mode: lean · Workflow: standard
Change: R5/F4: the keyboard row band (y ≥ 582, while the row is on) is a clearance box like the cast and glyph boxes (every slot passes; the bottom slots are 172 away); a note that with the row on the parade lane (448) visually crosses the bottom slots, accepted under K-26; the Interactions row names Accessibility's reduceMotion (A1). Follow-ups from the Keyboard Row (TASK-060) and Accessibility (TASK-061) GDDs; verdict unchanged; review by game-qc-ios from the diff.
Reviewed-Content-Hash: design/gdd/hint-letters.md 12ae0610d107d6c5ff6d21ae3f8d4ec418a89cc7

## Update — 2026-11-18 — TASK-089b R13 draw and tick order (review pending)
Review mode: lean · Workflow: standard
Change: new R13 pins the hints-stream draw order (key, lazy slot pick in base order L1–L4, R1–R4, 5 jittered tries
then zero jitter, life, phase; no draw for a pool or free list of 1), hint ids per launch, the inclusive gap test, the
per-frame tick (expire, then attempt unless a hint was removed this frame), the Reduce Motion consume fade as
drawing only, originFor's drawn centre, the pulse's first press including Dimmed, and the dim fade's constant rate.
F4: every check inclusive on exact values; R5's 148 / 138 marked as rounded. New AC-23 for the contract. Answers
game-qc-android's HL-Q1–12 (TASK-089). Normative change: needs game-qc-android's review (leader, TASK-089b).
Reviewed-Content-Hash: (pending review) design/gdd/hint-letters.md a557920dc32a071d9b55b97b80b598552a068e74

## Update — 2026-11-18 — TASK-120 parade meter clearance (no re-review)
Review mode: lean · Workflow: standard
Change: R5 and F4: the parade meter's box (x 846–1022, y 40–76 with its glow, published by the Reveal Stage) is a clearance box (≥ 97.8); every slot passes at any jitter (R2 124 / 114, R1 178); no capacity threshold moves (R2 would fail only above k ≈ 1.27). Review: game-qc-android from the diff.
Reviewed-Content-Hash: design/gdd/hint-letters.md cd7dbb2f94e689df982b5680cd4b315ac1727bc7
