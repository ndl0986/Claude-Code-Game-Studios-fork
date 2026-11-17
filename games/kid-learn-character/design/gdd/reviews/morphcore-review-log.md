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
