# Team board

Fallback tracker until GitHub Issues are enabled on `ndl0986/Claude-Code-Game-Studios-fork`
and `gh` has write access (`.claude/skills/game-team-lead/SKILL.md` § 1). Each task moves to
an issue once Issues are on. The leader owns this file.

| ID | Task | Type | Owner | Status | Branch | Updated |
|---|---|---|---|---|---|---|
| TASK-001 | `/brainstorm`: game concept for the Vietnamese-heroes mobile game | design | game-dev-001 | done (awaiting merge) | `design/TASK-001-game-concept` @ `6dcf8ba` | 2026-11-14 |

## Team changes

| Item | Status | Blocks |
|---|---|---|
| New member `game-art-content` (Claude session): art designer + content/history; drafts each hero's mission beats with sources. History sign-off: Luan | Worktree ready; start with `tools/team/start-game-art-content.sh` | Final content for Trần Quốc Toản (MVP hero) until Luan signs off |

## TASK-001: Game concept

- **Goal:** turn Luan's idea into the written concept that later steps build from.
- **Idea (Luan's words):** "a mobile game about Vietnamese historical figures, the player targeting is
  starting from primary school level in Vietnam, they are able to learn about all heroes in the
  historical by playing the missions which are based on their main or famous stories".
- **Inputs:** `production/project-plan.md`, `project.yaml` (stage Concept, rigor standard, goal mobile).
- **Output:** `design/gdd/game-concept.md` (or what `/brainstorm` writes at rigor standard).
- **Acceptance:**
  - core loop, mission structure (one mission = one hero's famous story) and learning goals are written;
  - the audience is primary-school children in Vietnam: reading level, session length, safety;
  - Vietnamese first, English second; Android + iOS phones, touch-first;
  - the hero and event list is a placeholder until the team's history material and reviewer arrive;
  - Luan approved the concept (design and content decision: § 4 escalation).
- **QC:** none (design doc, no build). Android and iOS QC skipped.

**Result (2026-11-14):** `design/gdd/game-concept.md` written and approved by Luan. Concept
"Dải Đất Anh Hùng (Land of Heroes)": a map of Vietnam, one story-first, light-action mission
per hero, then a 3–5 question quiz that upgrades a hero card. Committed `a4ac513`; not pushed,
not merged. Acceptance: all 5 met (per the dev's check). Lean review skipped the director
gates (CD-PILLARS, AD-CONCEPT-VISUAL, TD-FEASIBILITY, PR-SCOPE).

**Decided (Luan, 2026-11-14, `c48a634`):** storybook content ships in timed app updates on a
content calendar with store-review lead time; fully offline, no content server; daily pages
bundled and unlocked by device date.

**Decided (Luan, 2026-11-14, `266f2f8`):** first (MVP) hero is Trần Quốc Toản; heroes are added
one at a time in historical order, and the map shows where each story happened. Mission story
beats are left out of the concept: the content member writes them.

**Decided (Luan, 2026-11-14, `ffcab9b`):** not a card game. A 2D game with side-scrolling
missions and simple actions (attack, defend, …); passing the quiz unlocks the next hero. Hero
cards and the album are removed.

**Handover (`6dcf8ba`):** `production/team/handover-TASK-001-to-art-content.md`, sent to
game-art-content, which now owns art direction and story content.

**Decided (Luan, 2026-11-14, relayed to game-art-content):** sources: primary-school SGK Lịch sử
first, then Đại Việt sử ký toàn thư; tradition details labelled legend. Trần Quốc Toản's death:
one calm line in the ending, no scene. Landscape for missions, menus and the map until the phone
prototype confirms it. Art references: game-art-content proposes 3–5, Luan picks.

**Open questions for Luan:** monetization; "weeks" covers the MVP only, not a store release.
