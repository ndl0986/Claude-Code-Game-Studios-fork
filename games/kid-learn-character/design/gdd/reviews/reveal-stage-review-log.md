# Review log: design/gdd/reveal-stage.md

## Review — 2026-11-18 — Verdict: APPROVED
Review mode: lean · Workflow: standard
Scope signal: L (one system with the Play-screen router and frame driver, 6 formulas, 7 upstream and 6 downstream systems, five cross-GDD follow-ups; no new ADR; producer should verify)
Specialists: none (lean). Note: run in the authoring session (game-dev-ios, TASK-049); game-dev-android reviewed the plan and does the independent read.
Blocking items: 0 | Recommended: 3 (applied before the commit) | Advisory: 3
Summary: All 8 sections are present (Formulas required: stage fit, rise, pop, leave, fallback lengths, cooldown). Every contract other GDDs put on the Reveal Stage is restated: Press Queue (startReveal → {formedS, revealLen, hasWord}, formed once, snapshot, settle), Cast Rendering (draw calls, willForm, late art, halo when vs look), MorphCore (box transforms, seed per revealId), Audio (E1–E10 times, word never cut, hasWord), Key Table (resolve, peek), Input (origin, hit layer), Parade (shown separate from formed, lane 558, visible rect, draw order, walker taps, freeze pauses the walk), K-15, K-16, K-18 (originFor), K-20 (contain + extend, freeze/resume, Reduce Motion). No registry exists, so values were checked against those GDDs, the decisions and the one-shot.
Prior verdict resolved: First review
Findings:
- [RECOMMENDED, applied] F3: the example said pop 1.0 at u = 0.5; it is 0.99 (0.96 + 0.03); the normal pop's small peak (≈ 1.002) and the fade-in fallbacks' fadeStart (formedS − form_s) are now stated.
- [RECOMMENDED, applied] F5: a fade-in fallback with formedS = glow + form_s (reduced 0.7 s) would start the word at 0.95 s, before a 1.0 s letter line ends on the single voice player → formedS = max(…, letter_len_max_s − word_offset_s).
- [RECOMMENDED, applied] R8: the leader's Parade decision (freeze pauses a walking parade and its tune; Armed rest time does not count) added to freeze/resume and Edge Cases.
- [ADVISORY] Five follow-ups for other GDDs (Press Queue hasWord and play clock, Input R8 origin note, Key Table peek, Audio pause on freeze) are listed in Dependencies for TASK-050; Hint Letters (TASK-047) must expose originFor(key) as named here.
- [ADVISORY] Accepted limit: if late art never arrives, shown(creature) was already sent at formedS, so the Parade may count a creature the child did not see (rare; logged).
- [ADVISORY] row_lift 110 and sparkle_out_s 0.6 are proposals; AC-12/13/16 are device or screenshot criteria.
Reviewed-Content-Hash: design/gdd/reveal-stage.md d67911a70556f75337cf3f351c1665731edc1f7b
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/game-concept.md e525c154ca1b014fe3ca0024ba5a339d37135429
Reviewed-Content-Hash: design/gdd/systems-index.md e4b8da5e4cc3353630b8ea281460e0d471186c24
Reviewed-Content-Hash: design/art/art-bible.md ff95ca81ce8e7a2adbf92f5ce92267c3fe355cda
Reviewed-Content-Hash: design/gdd/press-queue.md f73cb9bd44f9d6ca15ca48975e5a43d77bb7870f
Reviewed-Content-Hash: design/gdd/cast-rendering.md 9cb004bc2ee8b3de1dcc717a573ab3d4862317cf
Reviewed-Content-Hash: design/gdd/morphcore.md 936291c0a2a5e5e3df31fba9f300df58920d4adb
Reviewed-Content-Hash: design/gdd/audio-voice.md 1f3d8158975fa07f5bac347250674314dc0ac4f0
Reviewed-Content-Hash: design/gdd/key-table-theme-data.md e108179924cb3f53191a26f006791f88e7e342bd
Reviewed-Content-Hash: design/gdd/input-key-filter.md 14c4a9a102f93f6ed093d038b3dcc1387550e738
Reviewed-Content-Hash: production/team/decisions.md ca25cf70d2a5b72aa5a11df2ff9847764c557c2a

## Update — 2026-11-18 — game-dev-android independent read: APPROVE, two additions
Review mode: lean · Workflow: standard
Change: from game-dev-android's read of b76fa21 (APPROVE): R10 and the Hint Letters row now publish the cast box, glyph box and token circles in stage units for Hint Letters R5's clearances (the moon rect is the Parent Gate's); the Hint Letters row says hints take panel open / close from the Parent Gate directly (K-18), while freeze / resume for the challenge comes from here.
Reviewed-Content-Hash: design/gdd/reveal-stage.md 713b8b7789dc2e66dd68291fedd52a7b26e4d0b7

## Update — 2026-11-18 — TASK-054b Scene flags (no re-review)
Review mode: lean · Workflow: standard
Change: R1 (TASK-054b): R10 publishes `haloOn` (the Glow phase) and `mashing` (queue length ≥ 1 or an ignored outcome in the last 1 s, on the play clock) for the Scene's R3/R3a; the Scene row in Interactions lists what it reads; AC-17 added.
Reviewed-Content-Hash: design/gdd/reveal-stage.md aa1099094a5009d3cf2291bf7687d1aa08eaee1a

## Update — 2026-11-18 — TASK-056c cross-review fixes (no re-review)
Review mode: lean · Workflow: standard
Change: from /review-all-gdds 2026-11-18 (design/gdd/gdd-cross-review-2026-11-18.md): W-6: Key Table cites → §4; W-9: Hint Letters is no longer "no GDD yet", and R8 cites Audio's gate-freeze rule and AC-21 instead of a follow-up; Info: R8 states the play clock runs under the panel and that nothing waits on it there. Text only; no rule changed.
Reviewed-Content-Hash: design/gdd/reveal-stage.md d6c0206ac4d61e436e04064edaf3c5f17405aca5

## Update — 2026-11-18 — TASK-059b stray markup removed (no re-review)
Review mode: lean · Workflow: standard
Change: deletes two stray lines of tool markup ("</content>", "</invoke>") left at the end of the file by its author's writing tool; no content or rule changed.
Reviewed-Content-Hash: design/gdd/reveal-stage.md 09269c33e01e5c4e95b0aa6898201b83756223d2

## Update — 2026-11-18 — TASK-062 follow-ups (no re-review)
Review mode: lean · Workflow: standard
Change: R1: the stage view sets accessibilityIgnoresInvertColors = true (K-30; App Shell owns the window). R9: the tap and ignored-press sparkles stay unchanged under Reduce Motion (leader's call, Accessibility A3 flag), and the flag is Accessibility's reduceMotion (A1). R10: the keyboard row band listed with the published boxes. Follow-ups from the Keyboard Row (TASK-060) and Accessibility (TASK-061) GDDs; verdict unchanged; review by game-qc-ios from the diff.
Reviewed-Content-Hash: design/gdd/reveal-stage.md f9058fb25faf2264bdf788984eb18fe3ff57819b

## Update — 2026-11-18 — TASK-085a follow-ups (no re-review)
Review mode: lean · Workflow: standard
Task: TASK-085a
Change: R10's draw order names the On-screen Keyboard Row (while on) between the current creature and the glyph or specks; the zPositions point to ADR-0006 D1's table (row at z 35) as the one source (TASK-070). Checked, already landed: R1 mashing/haloOn (TASK-054b), the keyboard row band and accessibilityIgnoresInvertColors, the sparkles' Reduce Motion rule (TASK-062). Review: game-qc-ios, from the diff.
Reviewed-Content-Hash: design/gdd/reveal-stage.md 1001fdbc68023d7373858c6d2c8967e9cdcb1fa1
