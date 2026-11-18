# Review log: design/gdd/scene-time-weather.md

## Review — 2026-11-18 — Verdict: APPROVED
Review mode: lean · Workflow: standard
Scope signal: M (1 system, 6 formulas, 8 dependencies, no new ADR; producer should verify)
Specialists: none (lean)
Blocking items: 0 | Recommended: 3 | Advisory: 2
Summary: All 8 sections are present (Formulas required: the look timing, colour blending, weather motion, counts, the lift). K-24 is written as decided throughout, and all 7 of game-dev-ios's plan items are in: two clocks (look on the wall clock, motion on the play clock, R9); one moon (the gate's) and the sun per the §2 table; the mashing signal and ×0.5 (stacked to ×0.25 with Reduce Motion); the halo fade from Reveal Stage R10 and Cast Rendering R5; the clamped extension with mirrored hills following the ground line; the 160-case build check with mid-blend samples; the device cost folded into Cast Rendering R11. Checked by computation: every named colour's L (sun 0.66, peach 0.63, amber 0.41, snow 0.67, all ≤ 0.69); the Day/Dusk mid-band blend at 0.5 (L 0.33); the Dusk lift (L 0.40); F4's counts on the four Reveal Stage F1 rects; AC-11's 20 s freeze (w 0.022). Self-review fixed one AC before the commit: AC-10 claimed no element within 0.2 r of the glyph, but the smoothstep factor there is 0.104 (now stated as ≤ 0.11 × base, 0 at the centre).
Art-bible note: §4 "Temperature" (warmth only from the horizon in Morning, only from the glyph and creatures in Day) vs the §2 table's pale sun `#ecd29a`: the §2 table wins (the sun is the table's desaturated pale yellow); "the moon is the only warm sky element" is a Night line and does not conflict.
Prior verdict resolved: First review
Findings:
- [RECOMMENDED] Cast Rendering: the per-look glyph and creature changes (amber outline, night palest-stop drop, halo 70%, 15% creature dim), blended by lookBlend, are owned by no GDD yet; the R5 build check needs them. Queued follow-up for game-dev-ios (open)
- [RECOMMENDED] Parent Gate & Grown-up Panel: the daytime moon (70% in Morning and Day) from look/lookBlend. Queued follow-up (open)
- [RECOMMENDED] Reveal Stage: publish `mashing` (queue length ≥ 1 or an ignored press in the last 1 s, play clock) for R3a (open)
- [ADVISORY] Rain speed, streak length, the amber lift hex and the sun positions are proposals, tuned in play
- [ADVISORY] AC-19 (device cost) waits for Cast Rendering R11's combined device run
Reviewed-Content-Hash: design/gdd/scene-time-weather.md 1113250d1ba8eed5c1daf1e51676dfbb41cc2ad4
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/settings-store.md d0629a5f8a9ed9bb6d224656bb1606456dea1ddd
Reviewed-Content-Hash: design/gdd/reveal-stage.md 93aa8034932cb593f28347a7b22196ecf59f9907
Reviewed-Content-Hash: design/gdd/cast-rendering.md 9cb004bc2ee8b3de1dcc717a573ab3d4862317cf
Reviewed-Content-Hash: design/gdd/parade.md f2e4445aca32b3e358a730460d0350de4df83d2f
Reviewed-Content-Hash: design/art/art-bible.md ff95ca81ce8e7a2adbf92f5ce92267c3fe355cda
Reviewed-Content-Hash: production/team/decisions.md fe4761035a309a289bdb33b864b79baae62fc9ea
Reviewed-Content-Hash: design/compliance/TASK-034-kids-weather-rules.md efc8d1ecc3ad747f52894344afb5442089e0c52d

## Update — 2026-11-18 — independent read: APPROVE; F4 fix (no re-review)
Review mode: lean · Workflow: standard
Change: game-dev-ios's independent read of 4b03332 is APPROVE (all 7 plan items in). His F4 fix: A_ratio divides by the safe sky band 1280 × 320 (y 0…320), not 1280 × 300; A_ratio is now 1.00 / 1.27 / 1.375 / 1.34 for the four rects; stars unchanged (capped); a clouds column added (11" iPad: 3 cloudy, 2 with rain or snow; 13" and 21:9: 4 / 3). No AC used the old figures.
Reviewed-Content-Hash: design/gdd/scene-time-weather.md 1c442e010786ec085de1240405a13529ce8406cd

## Update — 2026-11-18 — TASK-054c K-25 (no re-review)
Review mode: lean · Workflow: standard
Change: R3/F3d read the halo's current glow radius published by Cast Rendering R5 (230 u, 161 u at full Night) and the Reveal Stage's haloOn. R5/F2/AC-5 restated for K-25: the same edge model as Cast Rendering F8 (cream #f8efdc at 100% below sky-mid L_x ≈ 0.308, amber #80450f at or above, 1 s wall-clock switch dissolve excluded from the check); ≥ 3:1 at w 0 and 1, ≥ 2.5:1 at the inside samples, plus an analytic assertion at L_x (the crossover can fall between samples). Computed with the shipped data: lowest look 4.36:1, lowest sample 2.68:1, at L_x 2.57:1; the old edge (#8a4b12, cream 85%) gives 2.32:1 and fails. Review by game-dev-ios.
Reviewed-Content-Hash: design/gdd/scene-time-weather.md 14e09364ce6808a3f715654f3c8f9e8b6a1a5983
Reviewed-Content-Hash: production/team/decisions.md 91dfbeea83b146e126e09a893a0d23a42d17329c
