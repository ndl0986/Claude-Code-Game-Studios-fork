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

## Update — 2026-11-18 — volume aligned with the Settings Store (no re-review)
Review mode: lean · Workflow: standard
Change: the leader flagged a mismatch with the merged Settings Store GDD (K-12): `volume` is an integer 0–10, default 8, handed to Audio as `gain = muted ? 0 : level/10`, with a slider preview from the panel. R5, F1 (v is that gain; a fixed −3 dB headroom trim `g_head` added so the aligned worst case stays below full scale at the default level 8: 0.88), Interactions, Dependencies, Tuning Knobs, AC-13 and AC-14 updated. The recommended Settings Store finding from the first entry is resolved. Verdict unchanged; game-dev-ios's independent read is in progress.
Reviewed-Content-Hash: design/gdd/audio-voice.md 22672ded5e7e1f5475dafc4113cbe7a0ebd0db79
Reviewed-Content-Hash: design/gdd/settings-store.md 6e2df80d2d4061d730f3e2cb322e8d9669e51359

## Update — 2026-11-18 — game-dev-ios independent read: REVISE, addressed
Review mode: lean · Workflow: standard
Source: game-dev-ios's independent read of 6cfd991 (relayed by the leader). Required 1–2 were already in 29818c8; recommended 3–5 are in this revision.
Findings:
- [REQUIRED] Volume must follow the merged Settings Store (0–10, default 8, gain = muted ? 0 : level/10, slider preview) → done in 29818c8 (R5, F1, knobs, Interactions, Dependencies, AC-13, AC-14). The first entry's Recommended item "Settings Store must list master volume (0–1, default 0.5)" is **superseded** by K-12 and closed (fixed)
- [REQUIRED] Headroom at the default level 8: the aligned worst case 1.94 × 0.64 = 1.24 exceeded full scale → a fixed −3 dB headroom trim (g_head) brings it to 0.88 at level 8, so AC-13 holds "no gain reduction at level 8"; the limiter acts only at levels 9–10 in the all-peaks-aligned case (fixed, 29818c8)
- [RECOMMENDED] Silent mode: "obeys silent mode, does not mix" is .soloAmbient (not .ambient); current iPads have silent mode in Control Center; iOS cannot read silent mode; macOS has none → R6 names .soloAmbient as the requirement (the audio ADR confirms), says "not detectable" with a static panel hint, AC-20 is iPad-only and checks no mixing. The first entry's panel item now reads "static hint" (fixed)
- [RECOMMENDED] Engine start: R2.1 (runs from start-up) conflicted with the "Not started" state (starts on first input) → the engine starts silent at launch; "no sound before the first input" means nothing is scheduled (R2.1, R6, States) (fixed)
- [RECOMMENDED] AC-6 tied letter lines to MorphCore's provisional reduced T → a fixed letter_len_max_s = 1.0 s (A3, knobs, AC-6) (fixed)
Reviewed-Content-Hash: design/gdd/audio-voice.md 5f743e882a62b62e7206eaa670419154889d6d9a

## Update — 2026-11-18 — TASK-042: F6 names voiceDurations (no re-review)
Review mode: lean · Workflow: standard
Change: F6 and Dependencies now name the Key Table's `voiceDurations` field (TASK-042, checked by its V15) as the source of each word line's length; the bound T + 1.5 s stays as the run-time fallback for a missing entry. The first entry's Recommended item on a per-line duration is closed (fixed).
Reviewed-Content-Hash: design/gdd/audio-voice.md 1f3d8158975fa07f5bac347250674314dc0ac4f0

## Update — 2026-11-18 — TASK-050 cross-GDD follow-ups (no re-review)
Review mode: lean · Workflow: standard
Change: TASK-050: E9 is skipped when hasWord is false; Edge Cases confirm E8/E9 play on time during Cast Rendering's late-art wait and nothing is cut if the specks sparkle out; hasWord false skips E8 and E9. Wording and interface follow-ups from K-18/K-19/K-20 and the Cast Rendering and Reveal Stage reviews; verdict unchanged; review by game-dev-ios.
Reviewed-Content-Hash: design/gdd/audio-voice.md df83c5e1d8eac9184fb8852c95464ac2e8f77e73
