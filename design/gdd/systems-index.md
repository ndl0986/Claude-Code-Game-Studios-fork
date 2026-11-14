# Systems Index: Dải Đất Anh Hùng (Land of Heroes)

> **Status**: Approved (Luan, 2026-11-14, via the leader) · Task: TASK-008
> **Created**: 2026-11-14
> **Last Updated**: 2026-11-14
> **Source Concept**: design/gdd/game-concept.md
> **Gates**: PR-SCOPE and CD-SYSTEMS skipped (lean mode).

---

## Overview

Dải Đất Anh Hùng is a small, story-first game, and its systems are few.

- **The core loop:** one hero's famous story is played as 4 side-scrolling beats
  (*Live the story*), then a short quiz gives stars and unlocks the next hero, in historical
  order (*Learn by playing*).
- **What the game needs:** almost everything serves that loop. It needs:
  - forgiving touch combat with no lives (*Small hands can do it*);
  - beat types that can tell a non-combat moment such as the orange;
  - a quiz that rewards remembering, without shame;
  - VI/EN text switchable at any time;
  - content data in which every historical line traces to a signed-off claim (*True to
    history*);
  - local-only, offline progress (*Safe for kids*).
- **What it leaves out:** economy, multiplayer, accounts and analytics, by design.
- **Build:** native iOS (Swift + SpriteKit) and Android (Kotlin), both reading one shared
  `content/` data set.
- **Order of work:** the vertical-slice tier is one mission played end to end on real phones,
  so it is designed first.

**Data contract (not redefined in any GDD):** `content/README.md`,
`content/schema/*.schema.json`, `content/data/tuning.json` (tuning values) and
`content/data/rules.json` (game rules), from the TASK-005 ADR. Content sources are
`design/narrative/heroes/<hero>.md` and the visual rules are in `design/art/art-bible.md`.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Content data & claims | Core | Vertical Slice | Approved (data contract) | `content/README.md` + `content/schema/` (no GDD) | none |
| 2 | Language & text (VI/EN) | Core | Vertical Slice | Approved | `design/gdd/language-and-text.md` | 1, 4 |
| 3 | Input & touch controls (inferred) | Core | Vertical Slice | Approved | `design/gdd/input-and-touch.md` | 1 |
| 4 | Save & progress (inferred) | Persistence | Vertical Slice | Approved | `design/gdd/save-and-progress.md` | none |
| 5 | Side-scroll movement & combat | Gameplay | Vertical Slice | Approved | `design/gdd/side-scroll-combat.md` | 3, 1 |
| 6 | Mission flow & beat types | Narrative | Vertical Slice | Approved | `design/gdd/mission-flow.md` | 5, 1, 2, 3 |
| 7 | Quiz & stars | Gameplay | Vertical Slice | Approved | `design/gdd/quiz-and-stars.md` | 1, 2, 4 |
| 8 | Hints & onboarding | Meta | Vertical Slice | Approved | `design/gdd/hints-and-onboarding.md` | 6, 5, 3, 10, 1 |
| 9 | Hero progression & unlock | Progression | Vertical Slice (unlock screen) / Alpha (full) | Approved | `design/gdd/hero-progression.md` | 7, 4, 1 |
| 10 | Audio & voice-over | Audio | Vertical Slice | Approved | `design/gdd/audio-and-voice-over.md` | 1, 2, 4 |
| 11 | Map & timeline | UI | Alpha (stub in VS) | Approved | `design/gdd/map-and-timeline.md` | 9, 1, 4, 2 |
| 12 | Settings & parent area (inferred: sources and credits page) | UI | Full Vision (first release) | Not Started | — | 2, 1 |
| 13 | Storybook mini-games & content calendar | Gameplay | Full Vision | Not Started | — | 2, 4, 1 |

**Cross-cutting, not a GDD:** accessibility requirements live in
`design/accessibility-requirements.md` (written with `/ux-design`, at that fixed path).
Every system above must meet them.

**What each system covers:**
- **2:** the switch at any time, Vietnamese diacritic fonts, layout for longer EN text.
- **3:** landscape thumb pads; move, attack, defend, special.
- **4:** local only, offline, no child data.
- **5:** camera and parallax, attack/defend, telegraph, knock-back and running away, enemy
  states `enter, approach, windup, strike, rest, hurt, flee`; no lives or game over.
- **6:** intro → beats → ending → quiz; walk, hold-meter, training, fight, reach-the-flag.
- **7:** 3–5 questions, retry until right, stars counted over the whole quiz.
- **8:** one new button per beat, hand icon, voice prompt, slow-down after a miss.
- **9:** historical order; finishing the quiz unlocks the next hero.
- **10:** voice-over per line ID, SFX feedback per press, music.
- **11:** regions, hero places, historical order.
- **13:** device-date unlock, content ships in timed app updates.

---

## Categories

| Category | Description | Systems here |
|----------|-------------|--------------|
| **Core** | Foundation systems everything depends on | 1, 2, 3 |
| **Gameplay** | The systems that make the game fun | 5, 7, 13 |
| **Progression** | How the player grows over time | 9 |
| **Persistence** | Save state and continuity | 4 |
| **UI** | Player-facing information displays | 11, 12 |
| **Audio** | Sound and voice | 10 |
| **Narrative** | Story delivery | 6 |
| **Meta** | Onboarding | 8 |

No economy, no social and no analytics, by pillar (*An toàn cho trẻ / Safe for kids*).

---

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|------|------------|------------------|----------------|
| **MVP** | Folded into the Vertical Slice. The browser prototype (TASK-003) already answered "is this fun?" | — | — |
| **Vertical Slice** | One complete mission (Trần Quốc Toản) on real iOS and Android phones | TASK-006/007 native slice | Design FIRST |
| **Alpha** | Every system present in rough form; full map and progression; 2 heroes | Alpha | Design SECOND |
| **Full Vision** | Parent area, storybooks and calendar, many heroes | First release and later | Design as needed |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. Content data & claims: every line and number the apps show comes from here, and every history line traces to a signed-off claim.
2. Input & touch controls: every action a child takes goes through the same big landscape thumb pads.
3. Save & progress: stars and unlocks must survive app restarts, offline, with no child data.
4. Language & text: depends on 1 and Save & progress (`lang`). Every string is `{vi, en}` and can switch at any moment.

### Core Layer (depends on foundation)

1. Side-scroll movement & combat: depends on Input, Content data.
2. Quiz & stars: depends on Content data, Language, Save.
3. Mission flow & beat types: depends on Combat, Content data, Language, Input.

### Feature Layer (depends on core)

1. Hero progression & unlock: depends on Quiz & stars, Save, Content data.
2. Hints & onboarding: depends on Mission flow, Combat, Input, Audio, Content data.
3. Map & timeline: depends on Hero progression, Content data.
4. Storybook mini-games & content calendar: depends on Language, Save, Content data.

### Presentation Layer (depends on features)

1. Audio & voice-over: depends on Content data (line IDs) and Language. It is designed before Hints, because voice prompts carry the onboarding for children who can't read yet.
2. Settings & parent area: depends on Language, Content data (the sources page).

### Polish Layer (depends on everything)

1. Accessibility requirements (cross-cutting doc, not a system GDD).

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | Mission flow & beat types | Vertical Slice | Core | game-designer; game-art-content (story voice, claims) | M |
| 2 | Side-scroll movement & combat | Vertical Slice | Core | systems-designer, game-designer | M |
| 3 | Quiz & stars | Vertical Slice | Core | systems-designer; game-art-content (question rules) | S |
| 4 | Hints & onboarding | Vertical Slice | Feature | game-designer, ux-designer | S |
| 5 | Hero progression & unlock | Vertical Slice / Alpha | Feature | game-designer | S |
| 6 | Language & text | Vertical Slice | Foundation | localization-lead | S |
| 7 | Save & progress | Vertical Slice | Foundation | systems-designer | S |
| 8 | Audio & voice-over | Vertical Slice | Presentation | audio-director | S |
| 9 | Input & touch controls | Vertical Slice | Foundation | ux-designer | S |
| 10 | Map & timeline | Alpha | Feature | game-designer; game-art-content | M |
| 11 | Settings & parent area | Full Vision | Presentation | ux-designer; game-art-content | S |
| 12 | Storybook mini-games & content calendar | Full Vision | Feature | game-designer, live-ops-designer | M |

Foundation systems 6–9 come after the core GDDs on purpose. The TASK-005 data contract
and the TASK-003 prototype already fix most of their rules, so the core GDDs only reference
them. Their own GDDs document what the core ones leave open.

**Tuning evidence:** the browser prototype at `203d73e` (`prototypes/tqt-mission/config.js`)
and the TASK-003 QC findings on `qa/TASK-003-android` and `qa/TASK-003-ios`. Each value
in a GDD cites its source, or is marked ⟨tuning⟩.

---

**Open item for Map & timeline (#11), from QC (G5, 2026-11-14):** the slice's title screen,
which stands in for the map, shows **no progress**: no stars, medal or completed state for the
hero. A child who finished the mission sees the same screen as before. The Map & timeline GDD
must show each hero's state, best stars and medal (Hero progression Rule 10 and UI). Until then,
the slice title could show the hero's stars and medal as a minimal stub; that's a decision with
the GDD.

## Circular Dependencies

- **None found.** Hints depends on Audio (voice prompts), and Audio does not depend on Hints.
  Mission flow calls the Quiz at its end, but the Quiz does not depend on Mission flow; it reads its own content.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| Side-scroll movement & combat | Design | Fun action for 6–10 year olds without violence or failure might feel flat | Prototype evidence (TASK-003 QC); knock-back, running away and stars as the challenge; playtest the vertical slice on phones |
| Mission flow & beat types | Design | Some famous moments don't fit a touch action (the orange) | Non-combat beat types (hold-meter, training); the story wins over fun (pillar 1) |
| Audio & voice-over | Scope | VO in two languages doubles the cost per hero | Line IDs from the data contract; VO optional until the vertical slice is signed off |
| Storybook mini-games & content calendar | Scope / Technical | Every celebration update must clear store review before its date | Content calendar with review lead time; device-date unlock bundled in app updates |
| Content data & claims | Scope | History sign-off can block release | Release build refuses unsigned claims; sign-off tracked per claim |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 13 |
| Design docs started | 10 |
| Design docs reviewed | 10 GDDs (lean self-review plus a dev peer review each) |
| Design docs approved | 10 GDDs, plus the Content data & claims contract (TASK-005); Mission flow; Combat; Quiz & stars; Hints & onboarding; Hero progression; Language & text; Save & progress; Audio & voice-over; Map & timeline; Input & touch controls) |
| MVP systems designed | n/a (folded into the Vertical Slice) |
| Vertical Slice systems designed | 10/10 (all approved) |

---

## Next Steps

- [x] Review and approve this systems enumeration (Luan, 2026-11-14)
- [ ] GDDs in the order above, starting with Mission flow & beat types (`/design-system`)
- [ ] `/design-review` on each completed GDD, plus a peer review: game-dev-ios for combat and mission flow, game-dev-android for quiz & stars
- [ ] `design/accessibility-requirements.md` via `/ux-design`
- [ ] `/vertical-slice` on real phones (TASK-006/007) before production
