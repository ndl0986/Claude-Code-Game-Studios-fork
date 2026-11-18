# Review log: design/gdd/parade.md

## Review — 2026-11-18 — Verdict: APPROVED
Review mode: lean · Workflow: standard
Scope signal: S–M (1 system, 3 formulas, 7 dependencies, no new ADR; producer should verify)
Specialists: none (lean)
Blocking items: 0 | Recommended: 3 | Advisory: 2
Summary: All 8 sections are present (Formulas required: the batch threshold, the start time and the walk). K-17 is written as decided throughout (6 distinct keys per batch, per theme, no cap; press keeps the parade walking; panel/background fade or drop it, counted, not replayed; Reduce Motion halves the bob; art wait ≤ 0.5 s; debug start only; a tap on a walker sparkles), plus the leader defaults (the key is the unit; glyph-only does not count). game-dev-android's plan items are in: lastShown for the walker's item, the as-played start (restingSince + (revealLen − formedS) + delay), the walk's own clock and re-arming from Ended, stage units with W as an interface ask, a separate shown() event, residency, P9. Checked: F3's last walker ends at W + 250 for any n; 216.4 u/s at n 6, W 1280; F2 gives 4.45 s (normal) and 3.0 s (reduced), with a form_s margin over Audio F6's word end. Self-review fixed one inconsistency before the commit: the Armed state said it counted nothing new while R2.5 and Edge Cases hold extra keys for the next batch (now consistent).
Prior verdict resolved: First review
Findings:
- [RECOMMENDED] Dependencies: Reveal Stage has no GDD; its author must restate the Interface section (shown, lane y, draw order, walker taps, stage width) (open)
- [RECOMMENDED] Cast Rendering F6 says "8 × parade set"; with K-17 it is parade_count (6). Sent to game-dev-ios by the leader (open)
- [RECOMMENDED] Press Queue R10's example start rule (restingSince + parade_delay_s) is superseded by F2 here; that GDD may point to F2 at its next touch (open)
- [ADVISORY] The physical speed (37–43 mm/s) depends on the stage-fit rule, which no GDD owns yet (App Shell / Reveal Stage)
- [ADVISORY] AC-18 is a device screenshot criterion; it needs the real art and Cast Rendering's parade role
Reviewed-Content-Hash: design/gdd/parade.md 25d4d1d1095ada23a425091aa8b3586b6d97b192
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/game-brief.md ca66d372d8235f6f0effd7a6f6957c85c44df681
Reviewed-Content-Hash: design/gdd/press-queue.md f73cb9bd44f9d6ca15ca48975e5a43d77bb7870f
Reviewed-Content-Hash: design/gdd/audio-voice.md 1f3d8158975fa07f5bac347250674314dc0ac4f0
Reviewed-Content-Hash: design/art/art-bible.md ff95ca81ce8e7a2adbf92f5ce92267c3fe355cda
Reviewed-Content-Hash: production/team/decisions.md 23b7f9ecc504f023e181c4fea06d89a74ce731f4

## Update — 2026-11-18 — game-dev-ios independent read: REVISE → addressed
Review mode: lean · Workflow: standard
Source: game-dev-ios's independent read of 7265545 (relayed by the leader): 2 required (both from K-20 arriving after the first review), 4 recommended. F2, F3's W + 250, the skip rule and the interface were confirmed.
Findings:
- [REQUIRED] F3 under K-20 (contain + extend, W ≥ 1280; wide Mac windows fit by height, so the visible rect starts left of stage x 0) → x_i = rect.minX − 100 + speed·pt − i·gap with W = rect.width; draw test −150 ≤ x − rect.minX ≤ W + 150; physical-speed table: fit-by-width rows (39 / 37 mm/s) plus one wide-Mac row (W 1920 → 274.5 u/s ≈ 80 mm/s, stated as the cost of the pinned 11 s); Interface 5 rewritten to K-20's visible rect; AC-6 extended (fixed)
- [REQUIRED] K-20 gate freeze → new R6a: Reveal Stage freeze()/resume(); Walking pauses pt, the walkers and E12 and resumes where they stopped; Armed / Waiting for art do not count frozen time; R6's fade applies only after the correct answer opens the panel; Walking state row; AC-19 (fixed)
- [RECOMMENDED] Lane y → "the lane y from Reveal Stage" (558 as played = 478 + GROUND_SHIFT 80, moving up with the keyboard row); 478 dropped (fixed)
- [RECOMMENDED] Walker item → the batch stores {key, castId} from shown(...); no lastShown read (it resets on a theme change); AC-5 updated (fixed)
- [RECOMMENDED] Horizon lift → Scene: Time of Day & Weather (#15) on the Parade's paradeWalking signal (Visual/Audio, Interactions, Dependencies, States) (fixed)
- [RECOMMENDED] Cast Rendering parade_count follow-up closed: merged in e2d665e (F6, R10) (fixed)
- New follow-up (open): Audio & Voice has no pause for E12; R6a asks for one on the gate freeze
Reviewed-Content-Hash: design/gdd/parade.md 5362ec4651bfba78ada2d6524392ce1482ff2278
Reviewed-Content-Hash: production/team/decisions.md 23b7f9ecc504f023e181c4fea06d89a74ce731f4

## Update — 2026-11-18 — TASK-050 item 8 (no re-review)
Review mode: lean · Workflow: standard
Change: Interface 6 now cites the Reveal Stage R8 signals (settle, freeze, resume) and the Press Queue R8, R9 and R8a (the gate freeze on the play clock, added in TASK-050), from game-dev-ios's nit. Verdict unchanged.
Reviewed-Content-Hash: design/gdd/parade.md f2e4445aca32b3e358a730460d0350de4df83d2f

## Update — 2026-11-18 — TASK-056d cross-review fixes (no re-review)
Review mode: lean · Workflow: standard
Change: W-9: Scene moved from Upstream to Downstream (it reads paradeWalking); Reveal Stage cited by path instead of 'no GDD yet'; Audio's freeze pause closed (TASK-050). K-26: Hint Letters added to Downstream (reads paradeWalking to dim and hold the hints). From /review-all-gdds 2026-11-18 (design/gdd/gdd-cross-review-2026-11-18.md) and K-26. Verdict unchanged; diff re-run by game-qc-android.
Reviewed-Content-Hash: design/gdd/parade.md 1635d85de1ff5176df125b7a673418f883a2eac6

## Update — 2026-11-18 — TASK-062 follow-ups (no re-review)
Review mode: lean · Workflow: standard
Change: Interactions: Accessibility's reduceMotion (A1), next frame. Follow-ups from the Keyboard Row (TASK-060) and Accessibility (TASK-061) GDDs; verdict unchanged; review by game-qc-ios from the diff.
Reviewed-Content-Hash: design/gdd/parade.md 8fc6e7be1b8b7a12d5212ed76fa446fa9248879f

## Update — 2026-11-18 — TASK-101 contract questions (no re-review)
Review mode: lean · Workflow: standard
Change: PA-Q1–Q9 answered in a new 'Precise rules for the contract' subsection: inclusive start tick on the play clock; the art wait (same tick if resident, else first all-resident tick or the inclusive 0.5 s timeout; 3 of 6 walks, 2 skips; a skip needs a new rest); the Walking-entry order; held keys and the next batch; Ended at pt ≥ 11, panel/background at once with paradeWalking off at once; inclusive draw test and clamped alpha; Reduce Motion bob 2.5 from the next tick; per-theme state; freeze holds the wait, panel/background while Waiting → Armed. Verdict unchanged; review by game-qc-android.
Reviewed-Content-Hash: design/gdd/parade.md 4634d12d4160f0f88a278ae0fdbb163a3f547a1d

## Update — 2026-11-18 — TASK-120 parade meter (K-44) and start without a rest (K-45) — revision, in review
Review mode: lean · Workflow: standard
Change: New R12 parade meter (a cell per new creature at its shown, left to right; full glow 0.5 Hz, 0.35–0.45, steady under Reduce Motion; handover drain over fade_s; per theme, not saved; holds under the gate and panel; not a target; Play only; no sound; drawn by the Reveal Stage from a meter snapshot, Interface 7) and F4 with flash bounds (≤ 1 Hz, glow ΔL ≤ 0.066, ≤ 2 transitions per pixel per second). K-45: R2/F2 rewritten, t_start = armedAt + parade_delay_s (1.5 s after the 6th creature formed, no rest; tune after the word by Audio F6), re-anchored at panel close, return, skip retry (one per formed reveal) and Ended; prefetch from Armed; PA-Q1/Q2/Q4/Q9, States, Interactions (no Press Queue input), Edge Cases, Dependencies, knobs (parade_delay_s 1.5–3; meter knobs), ACs 3, 4, 7, 8, 12, 19 rewritten and AC-20–AC-30 added. Open Questions MT-Q1–Q5 for Luan with recommendations; follow-ups incl. parade-v1 (21 of 30 cases change). Review: game-qc-android (cross-GDD, from the diff); render read by game-dev-ios.
Reviewed-Content-Hash: design/gdd/parade.md 425d08b1147465b7d10798d8b5f6341c9d57a39b

## Update — 2026-11-18 — TASK-120 glow example fix (no re-review)
Review mode: lean · Workflow: standard
Change: from game-qc-android's REVISE: F4's example and AC-23 gave the glow at +0.2 s as 0.20, dropping the sine term; by F4 it is 0.5 · (0.40 + 0.05 · sin(0.2π)) = 0.215.
Reviewed-Content-Hash: design/gdd/parade.md d056c399102d58342aa5fd09dd73ee40de8c3eb2

## Update — 2026-11-18 — TASK-120 render-read fixes (no re-review)
Review mode: lean · Workflow: standard
Change: From game-dev-ios's render read: Interface 7's snapshot carries drainAt (the Walking-entry time) instead of a draining flag, and F4's drain and glow fade-out run from it; the glow swing bound is ≤ 0.085 (≤ 0.067 with sRGB-value blending) after the track went to 70%; MT-Q4 notes the meter is placed from queue_max (art bible §7). The 0.215 example was already fixed at 74da3aad.
Reviewed-Content-Hash: design/gdd/parade.md c60bccd6a9ed8ddecc5613a80a51ca2be76791a0

## Update — 2026-11-18 — TASK-120 K-46 answers and the meter light (revision, in review)
Review mode: lean · Workflow: standard
Change: Luan's K-46 closes MT-Q1–Q5: from Play entry, no sound, beside the tokens, the 1.5 s beat kept (R2 now says K-45 removed the rest, not the beat), and MT-Q3 yes: new R12a, the meter light. A 16-unit Starlight star launched at the counting shown from the cast box's top centre, a quadratic rise-then-glide to its cell over meter_fly_s 0.9 s (sine ease-in-out), fading over the last 0.15 s; the cell lights on arrival (litAt = launch + 0.9; fullAt and the glow move with it; 6th cell full at armedAt + 1.3 < 1.5). One at a time; none for held keys or under Reduce Motion; removed with the cell lit at once on the gate, panel or background; next-batch cells during a walk; z 70 above the meter. F4: path formula and hint check, flash bounds (each pixel ≤ 2 transitions per 1 s, swept strip 26,800 px on iPad). Snapshot adds fullAt and flight. Knobs meter_fly_s, meter_land_s. ACs 22, 23 updated; AC-31–AC-35 added. Review: game-qc-android (cross-GDD) and game-dev-ios (render read of the flight), baad1961..tip.
Reviewed-Content-Hash: design/gdd/parade.md 76dafbae4a08a832dc47472eefa7928fc7070dc2

## Update — 2026-11-18 — TASK-120 MT-Q3 history row marked superseded (no re-review)
Review mode: lean · Workflow: standard
Change: The resolved-questions history row for MT-Q3 now leads with "Superseded: Luan chose yes, K-46; see R12a" so the old recommendation cannot be read as current.
Reviewed-Content-Hash: design/gdd/parade.md 8b9d74d6d67df241f4103add12585e5af607ab54

## Update — 2026-11-18 — TASK-120 meter light landing crossfade (no re-review)
Review mode: lean · Workflow: standard
Change: From game-dev-ios's render read (option a): litAt = launchAt + meter_fly_s − meter_land_s (0.75 s), so the cell's fill starts as the light's fade starts (one crossfade, no dip); fullAt follows (6th cell full at armedAt + 1.15; glow seen ~0.75 s); constraint and knob note updated; the swept strip stated as a range, 10,800–37,400 px on an 11-inch iPad (27,600 default); one line on why a single flight field suffices (meter_fly_s ≤ 1.1 < 1.2 s). AC-22, 23, 31, 35 times updated.
Reviewed-Content-Hash: design/gdd/parade.md 16a839ee8bf58c44b04bee7228237e422339a804
