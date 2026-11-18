# Review log: design/gdd/morphcore.md

## Review — 2026-11-18 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: M
Specialists: none (lean)
Blocking items: 1 | Recommended: 3
Summary: All 8 sections are present. The GDD defers to morph contract v1 without restating it, the F1/F2 timing mapping is consistent with the worked examples and the fixture times, and Luan's Q1, Q2, Q4 and Q5 decisions are folded into the rules. One blocker: Rule 9 fell back to "shipped defaults" when the bundled timing data failed validation, which is undefined (the defaults are that data) and would push a programmer to hard-code timings against ADR-0001 Decision 6. Revised the same day by the author (TASK-038): build-time validation plus a no-morph fallback. A fresh re-review was not run; game-dev-ios's review of TASK-038 is the next independent read.
Prior verdict resolved: First review
Findings:
- [BLOCKING] Detailed Design, Rule 9 / Edge Cases / AC-7: the runtime fallback to "shipped defaults" was undefined and implied hard-coded timings → bundled data validated at build time (AC-7); bad data at run time builds no morph and takes the missing-glyph fallback; no hard-coded timings (fixed)
- [RECOMMENDED] Tuning Knobs: individually valid ranges can combine into a reveal far longer than the ~3 s hold (morph_speed 0.5 with all maxima gives T = 16 s) → the build-time test reports reveal (F5) vs the Press Queue's hold; the Press Queue GDD decides whether it is an error (fixed)
- [RECOMMENDED] Acceptance Criteria, AC-11: "holds the frame budget" had no number → p99 ≤ one display refresh during a reveal, proposed, with the Mac spike's miss noted (fixed)
- [RECOMMENDED] Dependencies: Key Table & Theme Data, Reveal Stage, Cast Rendering and Accessibility have no GDD yet (Key Table is in progress as TASK-036), so bidirectionality can't be checked; each of them must name MorphCore and the contract (open)
Reviewed-Content-Hash: design/gdd/morphcore.md 699c26fe97e5413c07d09a3f1efeac09db825f43
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/game-concept.md e525c154ca1b014fe3ca0024ba5a339d37135429
Reviewed-Content-Hash: design/gdd/systems-index.md 6652c64909266be6f7de820ddfbff3a731c77c7d
Reviewed-Content-Hash: design/art/art-bible.md a01094340e7e5b7bdae636f4cc879d0f84b472b5
Reviewed-Content-Hash: docs/architecture/morph-contract-v1.md 4935b3ac7490c131eb67bdf4c388b14a5f7ed46b
Reviewed-Content-Hash: docs/architecture/adr-0001-native-apple.md 9bd960cdffd4bec53f0f2875d6f4c7a33f873a70

## Update — 2026-11-18 — ownership wording (no re-review)
Review mode: lean · Workflow: standard
Change: TASK-044 (Cast Rendering R1): the ownership table splits the halo: WHEN it is on (and the creature's `form_s` fade-in) is the Reveal Stage's, how it LOOKS (the ~2.2 Hz blur pulse, steady under Reduce Motion) is Cast Rendering's; Visual/Audio Requirements line matched. Wording only; no rule changed.
Reviewed-Content-Hash: design/gdd/morphcore.md 936291c0a2a5e5e3df31fba9f300df58920d4adb

## Re-review — 2026-11-18 — Verdict: APPROVED
Review mode: lean (independent read) · Workflow: standard
Reviewer: game-dev-ios (independent of the author, game-dev-android), for the leader, TASK-038; recorded here for the TASK-058 bookkeeping after the gate check.
What was read: morphcore.md at 89fb1cc (content 699c26fe97e5413c07d09a3f1efeac09db825f43, the file the first entry stamps, with its fixes already applied). Re-checked today against the current file: the only changes since are the Status line and the halo ownership wording (the "ownership wording" update above, TASK-044); no rule changed.
Prior verdict resolved: Yes — the first entry's blocker (Rule 9's undefined runtime fallback) is fixed as stated there: bundled timing data validated at build time (AC-7), and bad data at run time builds no morph and takes the missing-glyph fallback (the creature fades in), with no hard-coded timings.
Checked:
- F1 maps travel = flow_s + spread_s, so each speck's flight lasts flow_s; the worked sets recomputed: normal T 2.45 s, plus form_s 2.95 s; reduced T 1.2 s, 1.5 s.
- Rule 4: the solid glyph stays until s > glow, and the specks start on its baked outline.
- Rule 7: no hold in the morph spec (the Press Queue owns it); Rule 5: an injectable seed source, derived per platform from (key, count), tested with fixed seeds (AC-12); Reduce Motion takes effect at the next reveal.
- Luan's decisions written as decided: 240 particles, a different morph on every press, the v1 multi-piece share.
- AC-11's performance basis against the TASK-033 run summaries: Mac SpriteKit frame p99 26.73 ms, iPad Simulator 17.07 ms (both match).
- The missing-asset fallbacks agree with Key Table & Theme Data (silhouette missing → the glyph sparkles out; glyph missing → the creature fades in).
Findings:
- [ADVISORY] Rule 4: place the glyph by MorphCore's unit box, not the renderer's bounds, so the swap never shifts (now carried by Reveal Stage R5's shared transforms and its AC-6).
- [ADVISORY] Rule 5 still says "press count"; "reveal count" is more exact, since presses the mash rule drops don't advance it (Press Queue R2 and Reveal Stage R3 use the reveal count; the meaning is already stated in Rule 5).
- [ADVISORY] Rule 4: link the glyph's rise to Input R8's press origin (now carried by Reveal Stage R2 and R5).
Reviewed-Content-Hash: design/gdd/morphcore.md 936291c0a2a5e5e3df31fba9f300df58920d4adb
Reviewed-Content-Hash: docs/architecture/morph-contract-v1.md 4935b3ac7490c131eb67bdf4c388b14a5f7ed46b
