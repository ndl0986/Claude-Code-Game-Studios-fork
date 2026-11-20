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

## Update — 2026-11-18 — TASK-050 follow-ups, part 2 (no re-review)
Review mode: lean · Workflow: standard
Change: Reveal Stage freeze()/resume() for the gate challenge (K-20): every player pauses in place (E12 included), nothing new starts, resume continues them; panel and background keep cut/settle. Frozen state row, AC-21. Verdict unchanged; review by game-dev-ios.
Reviewed-Content-Hash: design/gdd/audio-voice.md 3a9bb37d3088e038b99fc50c49f1e1fa7e2b5ce1

## Update — 2026-11-18 — TASK-056d cross-review fixes (no re-review)
Review mode: lean · Workflow: standard
Change: W-8: the chime-falloff window (F3, knobs) renamed mash_window_s → chime_window_s; mash_window_s is the Scene's mashing window (a different signal). From /review-all-gdds 2026-11-18 (design/gdd/gdd-cross-review-2026-11-18.md) and K-26. Verdict unchanged; diff re-run by game-qc-android.
Reviewed-Content-Hash: design/gdd/audio-voice.md 54410d1a1974580736d15e121d0ad14fd4f5d306

## Update — 2026-11-18 — TASK-062 follow-ups (no re-review)
Review mode: lean · Workflow: standard
Change: Interactions: Accessibility's reduceMotion (A1) reaches the voice timings through MorphCore at reveal start. Follow-ups from the Keyboard Row (TASK-060) and Accessibility (TASK-061) GDDs; verdict unchanged; review by game-qc-ios from the diff.
Reviewed-Content-Hash: design/gdd/audio-voice.md f72cfa129302bdcb39fc8245ab92752d35164f76

## Update — 2026-11-18 — TASK-086 contract questions AU-Q1–Q8 (no re-review)
Review mode: lean · Workflow: standard
Change: answers to game-qc-android's audio-plan-v1 questions, written into the rules. AU-Q1: T in R1 means the Reveal Stage's formedS (the fade-in end for fallbacks); E8 follows willForm (a creature shown) and sfx, not hasWord; E9 follows hasWord. AU-Q2: E7 plays when the solid glyph breaks up (dissolve or sparkle-out), not in the glyph-missing fallback. AU-Q3: F3 window is half-open and shared by E1/E2/E3. AU-Q4: a sound frees its player at its end; free players before steals; ties steal the lowest-numbered. AU-Q5: ducking moves linearly in dB at fixed rates, starting from the current dB; d = 10^(dB/20). AU-Q6: the F1 trims stay provisional knobs (no edit). AU-Q7: E11 replaces E8 for digits. AU-Q8: paused sounds carry their remaining length; events due while frozen fire at their play time after resume. Verdict unchanged.
Reviewed-Content-Hash: design/gdd/audio-voice.md 0124f9531a0bb12e249490be909d338f344d891e

## Update — 2026-11-18 — TASK-088a E8/E9 at formedS (no re-review)
Review mode: lean · Workflow: standard
Change: R1 E8, E9 and E11 now read `s = formedS` (and `formedS + word_offset_s`), equal to T for a morph, the fade-in end for the fallbacks; E8 plays when a creature forms and sfx exists; E9 plays only when hasWord (a creature forms AND the active locale has the item's word line), matching Reveal Stage (TASK-088b). The late-art edge row and AC-1 (fallback cases) updated. Builds on the AU-Q1–Q8 entry above. Review: game-qc-android.
Reviewed-Content-Hash: design/gdd/audio-voice.md 5b4c029ac7917e603565127b3265eca2a38a65d2

## Update — 2026-11-18 — TASK-088a aligned with Reveal Stage AC-5 (no re-review)
Review mode: lean · Workflow: standard
Change: AC-1's fallback cases restated with Reveal Stage AC-5's example numbers (TASK-088b @ 4d83b81e): sfx without a word line gives E8 at 2.45 and no E9; art missing gives neither.
Reviewed-Content-Hash: design/gdd/audio-voice.md b9db0299f13d5297edb4ee3af73248355d1c31d8

## Update — 2026-11-18 — TASK-088a review item 1 (no re-review)
Review mode: lean · Workflow: standard
Change: from game-qc-android's REVISE: F3 counts the E1/E2/E3 sounds started in (t − chime_window_s, t] that come before this one in delivery order, so a same-timestamp batch is attenuated (the half-open (t − w, t) of AU-Q3 left them all at n = 0); AC-8 adds the one-batch case.
Reviewed-Content-Hash: design/gdd/audio-voice.md 7f30e65849f904273ecc1b11ccf812bd9071f3c3

## Update — 2026-11-18 — TASK-088a review item 2 (no re-review)
Review mode: lean · Workflow: standard
Change: E7 in the invalid-timing-set fallback, confirmed with game-dev-ios (Reveal Stage F5): the glyph is drawn and fades out at fallback_glow_s under the creature's fade-in, so E7 plays at fallback_glow_s (0.8 s); none in the glyph-missing fallback; at glow in the art-missing one. AC-1 adds the invalid-set case (E7 0.8, E8 1.30, E9 1.55).
Reviewed-Content-Hash: design/gdd/audio-voice.md 6d07bd606e108f7878507da7f8831b7411976144

## Update — 2026-11-18 — TASK-090b cut_settle_s (no re-review)
Review mode: lean · Workflow: standard
Change: new Tuning Knob `cut_settle_s` = 0.04 s, constrained to ≥ max(cut_fade_s, 0.03) + 0.01, one value for both platforms (ADR-0010 D5/D7 review, game-dev-android R2). Referenced in R2.2 (a cut settles; a replacing sound starts up to cut_settle_s late), R6 (the freeze pause settles; a paused sound continues from about cut_settle_s after the freeze) and AC-21 (continue within cut_settle_s). Review: game-dev-ios.
Reviewed-Content-Hash: design/gdd/audio-voice.md 6b5e9ff8359ee2e8878794f49c9bcae3def1c21a

## Update — 2026-11-18 — TASK-090b freeze resumes from position (no re-review)
Review mode: lean · Workflow: standard
Change: leader's correction: the freeze no longer loses cut_settle_s. R6: the pause fades over cut_fade_s and settles over cut_settle_s (no click), and each sound resumes from the frame it had reached at the freeze moment, fading back in over cut_fade_s; nothing is lost (ADR-0010 resume-from-position, game-dev-ios). AC-21 back to "continue from where they paused", adding: the resume point equals the pause point and the fade-in takes cut_fade_s. The cut_settle_s knob row and R2.2 (cut replacements up to cut_settle_s late) are unchanged.
Reviewed-Content-Hash: design/gdd/audio-voice.md 1dba2cd72a89be26a558e93092dc5bc5137d76ad

## Update — 2026-11-18 — TASK-090b review (game-dev-ios): REVISE → addressed (no re-review)
Review mode: lean · Workflow: standard
Change: R6 and AC-21: a frozen sound resumes from the frame reached at the freeze moment or up to cut_settle_s earlier (a little heard again, nothing skipped; measured 0–17 ms, ADR-0010 H-1), testable as freezeFrame − cut_settle_s × rate ≤ resume ≤ freezeFrame. The nit: the players "stop playing" (API-neutral) instead of "are paused". Knob row reworded to match.
Reviewed-Content-Hash: design/gdd/audio-voice.md 6f34636324f22949650cd130ff17dcfaed52bb56

## Update — 2026-11-18 — TASK-093 knob wording (no re-review)
Review mode: lean · Workflow: standard
Change: the cut_settle_s knob row's Effect now says "the player is stopped" (was "stopped or paused"), matching R6's API-neutral wording.
Reviewed-Content-Hash: design/gdd/audio-voice.md 67279ba7ce2335c2b2f9296904aea2a9648427f4

## Update — 2026-11-18 — TASK-100 R6 resume figure (no re-review)
Review mode: lean · Workflow: standard
Change: R6's parenthetical now reads "(about 0–20 ms is heard again)", from ADR-0010 (merged Proposed, 3e39b8d8; the resume rewinds max(20 ms, IO period + 5 ms), capped at cut_settle_s), replacing the earlier 0–17 ms; a note adds that "nothing skipped" holds while the platform's capture uncertainty is at most cut_settle_s (ADR-0010 D7), measured by P-7. Rule and AC-21 unchanged.
Reviewed-Content-Hash: design/gdd/audio-voice.md 69116ac3ad1a1e939c7adcba58f5eaebbeb916b9

## Update — 2026-11-18 — TASK-108 Kokoro pick (no re-review)
Review mode: lean · Workflow: standard
Change: R8 names the engine and settings (K-41: Kokoro-82M, af_heart, lang a, speed 0.88, pinned package and weights), espeak-ng build-only (K-36), Piper not used, and the K-35 respelling rule; the TTS licence open item is removed (L-09 closed). Review: game-qc-android from the diff.
Reviewed-Content-Hash: design/gdd/audio-voice.md b5677bc5eb639e14f86fbfb80782ec651bfd6957

## Update — 2026-11-18 — TASK-108 Q8 closed (no re-review)
Review mode: lean · Workflow: standard
Change: from game-qc-android's REVISE: Open Question Q8 (TTS licence) moved to Resolved, "closed by K-41: Kokoro-82M, Apache-2.0, attribution in the acknowledgements; Privacy L-09 (R8)".
Reviewed-Content-Hash: design/gdd/audio-voice.md 434d426d4bdf9e67e25a23e31b922bb88f5d4e0f

## Update — 2026-11-18 — TASK-110 voice script (no re-review)
Review mode: lean · Workflow: standard
Change: R8 defines the build-only voice script, content/themes/<id>/src/voice-scripts/<locale>.json (ADR-0003 D1, D6): the engine settings plus a respell map from line id to the TTS input; every other line uses the Key Table say/word. Dinosaurs en-us gets Luan's seven r2 picks (K-35, K-41); triceratops stays as spelled; displayed and Key Table names unchanged. A respelled line must still pass V15. Review: game-qc-android.
Reviewed-Content-Hash: design/gdd/audio-voice.md 9692a7ca8ace023623279458e75921c096f21f66

## Update — 2026-11-20 — TASK-139b contract fixture lines for earlier changes (no GDD change)
Review mode: lean · Workflow: standard
Change: none to this GDD. ADR-0004 D6 lines, found by TASK-139's drift check (game-qc-android), for the contract-cited sections changed after their contracts were cut: Detailed Design and Acceptance Criteria by TASK-090b, TASK-093, TASK-100, TASK-108, TASK-110 (after audio-plan-v1); Formulas by TASK-086 and TASK-088a (after press-queue-v1).
fixture: none (audio-plan-v1: cut_settle_s and the resume frame are the adapter's, ADR-0010 D4/D5/D7; Kokoro and the voice script are the pipeline's; the plan's outputs are unchanged)
fixture: none (press-queue-v1: no case cites Audio Formulas)
Reviewed-Content-Hash: design/gdd/audio-voice.md 9692a7ca8ace023623279458e75921c096f21f66

## Update — 2026-11-20 — TASK-145 audio is uncompressed CAF, K-52 (no re-review)
Review mode: lean · Workflow: standard
Change: K-52 (Luan): baked audio is uncompressed 16-bit linear PCM in .caf (AAC is not byte-stable; ADR-0003 D4). R4.1 reads the .caf files into the players' PCM at theme load; R8 names the .caf pipeline and vo_<locale>_<kind>_<id>.caf; the art bible §8 reference reads LPCM .caf. R4.1 says the audio is "read in" (LPCM), not decoded. No rule, timing or loudness target changes. Review: game-dev-android.
fixture: none (audio-plan-v1 names no file path or format in any case; 0 occurrences of .m4a)
Reviewed-Content-Hash: design/gdd/audio-voice.md 9538c82cb168ce8556d39928028bfeb27cc30ec7

## Update — 2026-11-20 — content-pipeline/004 voice trim note (no re-review)
Review mode: lean · Workflow: standard
Change: A dated note in R8, the bake step story 004 implements (leader-approved D5 detail): each rendered voice line is trimmed of leading and trailing audio below −50 dBFS on the K-weighted 10 ms envelope, keeping 20 ms with a 5 ms linear fade at each end, before loudness normalisation; the three values are voice-script data; V15 durations and AC-6 limits measure the trimmed file. R8's respelled-line sentence now says "measured on the trimmed file". No rule, target or timing changes. Requested by game-dev-android for story 004.
fixture: none (audio-plan-v1 names no audio file and has no durations; its "trims" are gain trims, AU-Q6)
Reviewed-Content-Hash: design/gdd/audio-voice.md b9e4a3e1db1d78549afda9d6606733d00888ac58
