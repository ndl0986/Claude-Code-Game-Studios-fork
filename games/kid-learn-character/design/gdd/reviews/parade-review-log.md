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
