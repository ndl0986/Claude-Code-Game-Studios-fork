# Review log: design/gdd/audio-voice.md

## Review — 2026-11-18 — Verdict: APPROVED
Review mode: lean · Workflow: standard
Scope signal: M (1 system, 6 formulas, 9 dependencies, the audio ADR still to write; producer should verify)
Specialists: none (lean)
Blocking items: 0 | Recommended: 3 | Advisory: 2
Summary: All 8 sections are present (Formulas required: the system defines gains, ducking, the mash falloff, loudness targets and the hold constraint). Every event the brief names has a trigger, a time and a player (R1), with times taken from MorphCore F1/F3/F6 for both timing sets. Luan's six answers are written as decisions (Q1 word after the cast sound and the F6 hold constraint, Q2 ping, Q3 build-time TTS, Q4 silent switch respected, Q5 loudness targets, Q6 counting chirps). game-dev-ios's must-cover items from the plan review are all in (latency AC per device, players kept running, no click on a cut, decode at the output format, re-prime, decoding inside the theme load, limiter and headroom, tap during the word, chirps on the cast player, R6 interruption handling, title chime). The self-review fixed two internal errors before the commit: the F3 bus-sum claim held only in a steady mash (now bounded by 2.57 × one chime, and the F1 headroom uses it), and "10 keys at once" counted 3 accepted presses instead of 4 (1 starts + 3 queued).
Prior verdict resolved: First review
Findings:
- [RECOMMENDED] Dependencies: Press Queue, Reveal Stage, Parade and Parent Gate & Grown-up Panel have no GDD yet, so bidirectionality can't be checked. The Press Queue GDD must carry F6 (hold ≥ word end, capped +1.5 s) and report accepted / ignored per press; the panel GDD owns "show the device is silenced if detectable" (open)
- [RECOMMENDED] Key Table & Theme Data: F6 wants each word line's duration from data. Until that GDD adds a per-line duration (or a build-generated map), the Press Queue uses the bound T + 1.5 s. Follow-up for game-art-content (open)
- [RECOMMENDED] Settings Store (TASK-039, in progress): must list master volume (0–1, default 0.5) and mute as Audio & Voice inputs (open; to tell game-dev-android)
- [ADVISORY] AC-9 and AC-16 are device criteria; AC-16 (press → chime within one frame of the first answering frame) is NOT ASSESSED until the TASK-033 iPad procedure runs. Bluetooth is excluded on purpose
- [ADVISORY] F5's ~19 MB of decoded PCM per theme is an estimate; it feeds the real iPad memory budget (Q9)
Reviewed-Content-Hash: design/gdd/audio-voice.md 554acef3b7e6ebd59dee118b9839d131c8b09d8a
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/systems-index.md 43d58b9fcad339e55b4e458be0f7145aa8654a7d
Reviewed-Content-Hash: design/gdd/key-table-theme-data.md f8f54faf82ac675dfdf929b0465ef4bdff8253c8
Reviewed-Content-Hash: design/gdd/morphcore.md 699c26fe97e5413c07d09a3f1efeac09db825f43
Reviewed-Content-Hash: design/art/art-bible.md a01094340e7e5b7bdae636f4cc879d0f84b472b5
Reviewed-Content-Hash: docs/architecture/adr-0001-native-apple.md 9bd960cdffd4bec53f0f2875d6f4c7a33f873a70
Reviewed-Content-Hash: production/team/decisions.md 851d029c9350a0f9ce2f6d528146b3ca974207af
