# Review log: design/gdd/press-queue.md

## Review — 2026-11-18 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: M
Specialists: none (lean)
Blocking items: 1 | Recommended: 2
Summary: All 8 sections are present (Formulas required: F1 hold, F2 accept predicate, F3 cap, F4 wait, F5 Reduce Motion). The accept/queue/ignore rules (R3), synchronous per-press outcome (R4), one tick per frame (R5), the startReveal → {formedS, revealLen} contract with fallbacks (R6), formed exactly once with the timeout and stale-id rules (R7), panel and background clear + settle (R8, R9), restingSince for the Parade (R10), revealId = MorphCore's press count (R2) and the injected-clock ACs cover TASK-043's criteria, game-dev-ios's nine must-state items and Luan's K-15. F1 matches Audio & Voice F6 and uses Key Table voiceDurations with the T + 1.5 bound. One blocker: F1's build check mixed revealLen into the word-cap condition and gave the wrong bound. Revised the same day by the author (TASK-043). No registry exists (design/registry/ absent); values were cross-checked against the named GDDs and decisions.
Prior verdict resolved: First review
Findings:
- [BLOCKING] Formulas, F1 build check: "hold_s + hold_ext_max_s ≥ revealLen_max + word_offset_s + word_len_max_s" used revealLen where the word starts from formedS, giving hold_s ≥ 2.95 for the word cap (correct: 2.45) and hiding MorphCore's separate hold ≥ T + form_s constraint → split into check 1 (cap never cuts a word: hold_s ≥ 2.45) and check 2 (hold_s ≥ revealLen = 2.95); Tuning Knobs range cites both (fixed)
- [RECOMMENDED] Edge Cases: a started-at-once r0 (event time, in the past) can be earlier than the last tick's targetTimestamp on Apple → stated as allowed, same uptime clock, s never negative (fixed)
- [RECOMMENDED] Dependencies: Reveal Stage, Hint Letters, Parade, Parent Gate & Panel, App Shell, Keyboard Row and Accessibility have no GDD yet; each must name the Press Queue, and Reveal Stage must restate the startReveal / formed contract (open)
Values cross-checked: queue 3 and ~3 s (K-06), T 2.45 / 1.2 and F5 2.95 / 1.5 (MorphCore), word_offset_s 0.25, hold_ext_max_s 1.5, word_len ≤ 1.25 (Audio F6, Key Table V15), ping on overflow (K-13 / Audio E2), Title startPlay (Input, Audio E5), reveal count for the seed (K-11), K-15 answers. Key Table's open line "whether a theme change clears the queue" is answered in R8 (it does not; the panel already has).
Reviewed-Content-Hash: design/gdd/press-queue.md a6a1d629b15462d4a7d69eca7f5d5f885b591450
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/game-concept.md e525c154ca1b014fe3ca0024ba5a339d37135429
Reviewed-Content-Hash: design/gdd/systems-index.md b5a843b05a30dfb1d90e76079026f1fc6da722e8
Reviewed-Content-Hash: design/art/art-bible.md 1a8306227139727ca120d88e6f74223b68b08dba
Reviewed-Content-Hash: design/gdd/input-key-filter.md 14c4a9a102f93f6ed093d038b3dcc1387550e738
Reviewed-Content-Hash: design/gdd/morphcore.md 7a65f1c4513cf05fc49fc11342e9c619485b6e66
Reviewed-Content-Hash: design/gdd/audio-voice.md 1f3d8158975fa07f5bac347250674314dc0ac4f0
Reviewed-Content-Hash: design/gdd/key-table-theme-data.md 6fa1ce3101c052754590905f734280abc25e3540
Reviewed-Content-Hash: design/gdd/settings-store.md 6e2df80d2d4061d730f3e2cb322e8d9669e51359
Reviewed-Content-Hash: production/team/decisions.md 36c2e5cc9c0c5ff4a437dc57012cb6ebb1a034e9

## Re-review — 2026-11-18 — Verdict: APPROVED
Reviewer: game-dev-ios (independent read, recorded by game-leader at merge)
Summary: All nine of game-dev-ios's plan items are present (R2, R4–R11, AC-6, AC-9…AC-13, AC-22). The self-fixed F1 blocker is right (check 1 hold_s ≥ 2.45, check 2 hold_s ≥ 2.95). Agrees with the author's choices: the hold counts as passed after the panel closes; a theme change never clears the queue. Receipt a6a1d62 matches the file.
Prior verdict resolved: Yes (NEEDS REVISION, fixed)
Carried to Reveal Stage (non-blocking): (1) the glyph-sparkles-out fallback forms no creature, so startReveal should also return hasWord (or word_end) and F1 drops the word term then; (2) revealLen = T + form_s for a morph; Cast Rendering's late-art rule keeps formedS and revealLen fixed after startReveal.

## Update — 2026-11-18 — TASK-050 cross-GDD follow-ups (no re-review)
Review mode: lean · Workflow: standard
Change: TASK-050: startReveal returns {formedS, revealLen, hasWord} and F1 drops the word term when hasWord is false (not only when there is no word line); R10's start rule points to Parade F2; new R8a: the queue freezes while the parent-gate challenge shows and resumes on a wrong answer or timeout, frozen time never counting; K-15's clear only when the panel actually opens (K-20). Interactions, Edge Cases, AC-23, AC-24. Wording and interface follow-ups from K-18/K-19/K-20 and the Cast Rendering and Reveal Stage reviews; verdict unchanged; review by game-dev-ios.
Reviewed-Content-Hash: design/gdd/press-queue.md e3f251e964d1741a83ea0ab55fa7bd1b608560fc

## Update — 2026-11-18 — TASK-050 follow-ups, part 2 (no re-review)
Review mode: lean · Workflow: standard
Change: R8a restated on the play clock (uptime minus total frozen time, Reveal Stage freeze/resume, K-20) instead of shifting r0/formedAt; AC-23 updated. Verdict unchanged; review by game-dev-ios.
Reviewed-Content-Hash: design/gdd/press-queue.md 74baa26023078384bde9b731ff69dcfd30c25fff

## Update — 2026-11-18 — TASK-050 wording notes from game-dev-android (no re-review)
Review mode: lean · Workflow: standard
Change: R8a's play clock now reads uptime − total frozen or background time (as Reveal Stage R8); States table gains a Frozen row (no tick, no press; resume returns to the state it froze in). Optional notes from game-dev-android's APPROVE of c4ae20d. Verdict unchanged.
Reviewed-Content-Hash: design/gdd/press-queue.md a4fc49fbda37a95a7730b76bb1405430f515b984

## Update — 2026-11-18 — TASK-056a cross-review fixes (no re-review)
Review mode: lean · Workflow: standard
Change: W-6: four Key Table cites point at its §4 (the pick rule). W-9: the peers list is no longer 'not written yet'. From design/gdd/gdd-cross-review-2026-11-18.md and K-26. Review: game-qc-android (diff re-run).
Reviewed-Content-Hash: design/gdd/press-queue.md d8d2ac774eeff254e1e18f65d9ab9b76ec0d80e5
