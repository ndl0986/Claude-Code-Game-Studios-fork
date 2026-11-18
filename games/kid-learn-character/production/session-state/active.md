# Session checkpoint: Kid Learn Character (leader)

**Updated:** 2026-11-18. Leader session id in leader-session.txt. Ask Luan in Vietnamese, write files in English.
**Latest (2026-11-18, ADR-0009 merge):** ADR-0009 merged Proposed (2a6e9fab): outline = merged path in SKEffectNode per part (H-2 headless 6e455bfc: single SKShapeNode blends twice); DeviceSpike A-candidate b4fa26c9 merged (87eaddca); TASK-107 plan merged (c1b2896f). All 14 contracts written (TASK-101). Proposed ADRs awaiting device rows: 0007, 0008, 0009, 0010. WAITING ON LUAN: TTS pick; short MAC FREE (signed build, macOS launch+screenshot, UI test); iPad spike session (H-2 confirm, P-2/M-13, P-1, P-15, P-4, audio rows).
**Latest (2026-11-18, c4decc31):** SCAFFOLD MERGED (TASK-079, a4adca84; QC --qc PASS df6a154e): apple/ MorphCore/KidCore/Tools/ContractKit + LetterMorph app, tools/ci verify/pkc-scan/sim-guard, K-40 registry. ADR-0010 merged Proposed (awaits P-1/P-7/P-8/P-9/M-14). 12 contract dirs (9 live + 2 superseded + morph). K-39 iPad portrait/overlays, K-40 D5 not-started state. In flight: TASK-100 Audio R6 figure, TASK-101 contracts batch 6, TASK-102 ADR-0007/0008, TASK-103 ADR-0009. WAITING ON LUAN: TTS pick; short MAC FREE (signed build, macOS launch+screenshot, UI test — release-blocking); iPad spike session.
**Latest (2026-11-18, 43a6e9d1):** ADR-0006 + ADR-0011 Accepted; contracts merged: key-table-schema-v1, settings-record-v1, input-filter-v1, press-queue-v1. Device-checks plan (35 checks + P-15, spike column) merged; DeviceSpike v1 merged (prototypes/, install-gated). K-35 respell, K-36 espeak build-only, K-37 bundle com.galaxyandsun.lettermorph + Personal Team + SVG layer ids, K-38 ContractKit. In flight: TASK-079 scaffold S1 (game-dev-android), TASK-086 contracts batch 3 (game-qc-android), TASK-087 ADR-0010 draft (game-dev-ios). WAITING ON LUAN: TTS voice pick (samples in scratchpad tts-listen-1/production/ALL_*.wav), first iPad spike session + MAC FREE.
**Latest (2026-11-18, 8cf524b):** 7/14 MVP GDDs approved: Key Table, Input, MorphCore, Settings, Privacy (L-01…L-09 open for Luan, ask at release prep), Audio, Press Queue; art bible K-16 amendments merged (TASK-045). K-17 Parade (every 6, per theme), K-18 Hint Letters, K-19 Parent gate recorded.
In flight: TASK-044 Cast Rendering 3aa1c99 → game-dev-android read (+ MorphCore halo one-liner by game-dev-ios); TASK-046 Parade plan REVISE (game-art-content); TASK-047 Hint plan + TASK-048 Gate plan → game-qc-android review; TASK-049 Reveal Stage plan (game-dev-ios). Left: Child Lock-in #13, App Shell #14.
**STAGE: Technical Setup** (gate CONCERNS accepted by Luan 2026-11-18, production/gate-checks/2026-11-18-systems-design-to-technical-setup.md). Systems Design done: 14/14 MVP + Scene approved, cross-review PASS, K-01…K-26.
**Done & pushed (docs/kid-learn-character-plan @ 0181fb3):** concept (revised after /design-review), ADR-0001 (TASK-035 merged;
Luan ACCEPTED 2026-11-18, status flip sent to game-dev-ios), morph contract v1 + content/fixtures/, art bible (Approved),
systems index (20 systems, 14 MVP, one GDD per system), one-shot prototype (iterations 1–4), decisions K-01…K-08.
**NEXT:** /design-system in design order: 1 Key Table & Theme Data, 2 Input & Key Filter, 3 MorphCore, 4 Settings Store,
5 Privacy & Kids Compliance … (K-00: later stages go to team members; Luan decides who).
**Pre-Production conditions:** real-iPad latency + physical-keyboard lock-in checks (NOT ASSESSED); /estimate at Production gate.
GitHub Issues disabled + gh READ only: track on board.md.
**K-14:** merge + push peer-approved tasks into docs/kid-learn-character-plan WITHOUT asking (report after); still ask for decisions; never main.

**Role:** game team LEADER (game-leader). Luan chose the ORIGINAL studio process (K-00): the leader
runs the Concept-stage skills WITH Luan here; team members get the later stages.
**Read first:** production/team/kickoff-notes.md (Luan's idea), production/team/decisions.md,
production/team/board.md.
**Decided:** K-03 fully native, Apple first: iPadOS + macOS (Swift), then iPhone; Android later.
**Open for /brainstorm:** K-01 2D/3D, K-02 language (proposed English), K-04 name, K-05 US/UK
voice + letter name vs letter sound.
**Inputs on pushed branches (data for the concept, not decisions):**
- design/TASK-029-content-list @ dddd373: A–Z/0–9 content draft (X = fox).
- qa/TASK-032-kids-store-rules-android @ ac7b97b: Google Families + COPPA checklist + TC-01..34.
- plan/TASK-031-android-tech @ 45b9fe1: Android notes (later).
- game-dev-ios's idea (not written): SpriteKit 2D behind a swappable stage (RealityKit if 3D),
  a KidCore Swift package, pressesBegan, AVAudioEngine, a shared JSON key table.
**Next steps:** /start (Luan is not new; pick the path for an existing idea) → /brainstorm →
design/gdd/game-concept.md → /setup-engine (native Swift is not in the engine table; last game
used ADR-0001 + a project.yaml engine block, see games/dai-dat-anh-hung/docs/architecture/) →
/art-bible → /map-systems → /gate-check.
**Still waiting on Luan (old game/repo):** "delete backups" (~/.Claude-Code-Game-Studios-fork.pre-ssd-bak,
~/.learn-dotnet-interview.pre-ssd-bak) and "merge" (docs/TASK-007-r14-readme 1b2662d,
qa/TASK-028-android-paths 4925fed, qa/TASK-028-paths 47b5834 into docs/vn-history-game-plan).
**Members:** all idle, on the old worktrees. tools/team/start-member.sh now starts them in
<worktree>/games/kid-learn-character (they need that branch checked out first).
