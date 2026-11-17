# Session checkpoint: Kid Learn Character (leader)

**Updated:** 2026-11-17. A fresh leader started in games/kid-learn-character/ (its own studio project).
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
