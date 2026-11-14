# Handover: TASK-001 (game concept) → game-art-content

*2026-11-14 · from game-dev-001 · branch `design/TASK-001-game-concept`*

You now own art direction and the history content of each hero's story.
game-dev-001 ran `/brainstorm`, and Luan answered every design question in that session. This doc covers what came out of it, what Luan decided, what you own now and what is still open.

**Read next:** `design/gdd/game-concept.md` (Status: Approved). Treat that file as the
source of truth. This doc only summarizes it and adds the context the concept leaves out.

## 1. What /brainstorm produced

| Commit | What |
|---|---|
| `a4ac513` | The concept, written and approved by Luan |
| `c48a634` | Storybook content ships in timed app updates |
| `266f2f8` | Trần Quốc Toản is the first hero; heroes go in historical order; story beats left out |
| `ffcab9b` | **No cards.** Missions are 2D side-scrolling attack/defend; the quiz unlocks the next hero |

**Concept, in short:** *Dải Đất Anh Hùng (Land of Heroes)* is a 2D side-scrolling
action story game for Vietnamese primary-school children, aged about 6–10. Each mission
**is** one national hero's famous story. The child moves the hero with big on-screen
buttons: move, attack, defend, and maybe a special move. Enemies are few, slow and
forgiving, and there's no blood or gore.

**Mission structure:** a short story scene with picture and voice, then 3–4
side-scrolling beats in story order, then the story's ending, then a **3–5 question
quiz**. The quiz gives 1–3 stars and **unlocks the next hero** on the map of Vietnam and
the historical timeline. A session lasts 5–15 minutes and always ends back on the map.

**Extra content:** storybook mini-games, illustrated pages where each page is a short
touch mini-game. They're added over time, day by day or on Vietnamese celebrations.

> **Hero cards no longer exist.** The leader's brief for this handover mentioned a "hero
> card structure", but Luan removed cards after that brief was written: "the game is no
> card game, it will be 2D game with some simple action for attach, defense,...". Don't
> design cards or a card album.

**Pillars (locked):**
1. **Sống lại câu chuyện** (Live the story): the mission *is* the famous moment. When fun and story conflict, the story wins.
2. **Đúng sự thật** (True to history): every claim is labelled fact, interpretation or invented, and signed off.
3. **Nhỏ chơi được** (Small hands can do it): a 6-year-old finishes. Mastery comes from stars, not from blocking progress.
4. **Học mà vui** (Learn by playing): learning is the reward, and passing the quiz unlocks the next hero.
5. **An toàn cho trẻ** (Safe for kids): no data collection, ads, accounts or chat. It works offline.

**Anti-pillars:** no timers, lives or energy that block play · no graphic violence or gore
(battles are shown through knock-back, symbols, tides and victory) · no generic mini-games
that ignore the story · no leaderboards, chat, accounts or ads to kids · no invented
details presented as fact.

## 2. Luan's decisions (Luan's words where recorded)

| Topic | Decision |
|---|---|
| Idea | "a mobile game about Vietnamese historical figures, the player targeting is starting from primary school level in Vietnam, they are able to learn about all heroes in the historical by playing the missions which are based on their main or famous stories" |
| Experience mix | Story & Discovery, Challenge & Mastery, Relaxation & Flow, "also need some quizz for kids to learn about the VN historical" |
| Concept pick | "mix 2 and 1, while 2 is the main stories flow but 1 will be additional games, able to enhance and provide later day by day or based on the real-time celebration in VN" (2 = map + hero missions, 1 = storybook mini-games) |
| Languages | "we need to support both EN and VI, default is VN but always can turn to EN" |
| Core action feel | Light action (picked over a calm puzzle). Later made specific: "2D game with some simple action for attach, defense" |
| Story fidelity | **Story-first**: the mission is the famous moment, step by step |
| 2D view | **Side-scrolling** |
| Quiz reward | **Unlock the next hero** (picked over unlocking moves or fact pages) |
| Cards | **None** (see the quote above) |
| Visual style | **Modern kids' cartoon** with Vietnamese motifs, picked over Đông Hồ folk painting and lacquer art |
| Storybook delivery | "use timed app updates for storybook content": the game stays fully offline (`c48a634`) |
| First hero | "since we are able to add more and more heros and the timeline will be adjust to match with real-time life of the hero, can just start with Trần Quốc Toản" (`266f2f8`) |
| Hero order | **Historical order**: heroes go in the order they lived, and the map shows where each story happened |
| Story beats | game-dev-001 drafted 4 beats for Trần Quốc Toản. Luan chose **"Remove the beats"**, so the story is left to the content owner and written from verified sources |
| Reviewer | "we will need new team member as art-desisnger which cover the content, history, real stories and stuff": that's you. You draft with sources and Luan signs off history |
| Engine | No preference: `/setup-engine` decides later |
| Team / timeline | Luan solo plus the AI studio (now plus you). Timeline: "Weeks" |
| Pillars, concept | Pillars locked as drafted; concept approved |

## 3. What game-art-content owns now

- **Art direction.** Run `/art-bible` next. The concept's *Visual Identity Anchor*
  section is your seed:
  - **Rule:** soft, rounded, bright cartoon heroes in a world whose patterns, clothing
    and objects are clearly Vietnamese.
  - **Principles:** friendly but respectful heroes · motifs as accents, not noise ·
    readable at phone size.
  - **Text:** never paint text into the art, because the game switches between VI and EN.
  - **Colour:** warm primaries for interaction and rewards, natural greens and river
    blues for the map, and battle drama shown in sky and water, not blood.
  - **Side-scrolling needs:** the hero's run, attack and defend animations, enemy
    knock-back that isn't violent, and scrolling backgrounds.
- **Each hero's mission story beats**, starting with **Trần Quốc Toản**:
  - 3–4 beats in story order, playable as side-scrolling attack and defend;
  - every beat **cites its sources** and is labelled fact, interpretation or invented
    (or "legend");
  - the 3–5 quiz questions and answers come from the same sources;
  - VI first, then EN.
- **History facts stay ⟨placeholder⟩ until Luan signs them off.** Don't state dates,
  ages, places or how a story ends as fact before that. How to show a hero's death or a
  battle to 6–10 year olds is a content decision for you and Luan.
- **Historical-order timeline:** the list of heroes in the order they lived, and where
  each story happened on the map.

## 4. Open questions and planning

**Open for Luan:**
1. **Monetization:** paid, free, or school or government funded? The default is no ads or purchases aimed at kids.
2. **Portrait or landscape?** Side-scrolling usually points to landscape. Settle it with the first prototype on a real phone.
3. **Timeline:** "weeks" covers the MVP only, not a store release. Not confirmed yet.

**Scope (estimates, solo + AI):**

| Tier | Content | Timeline |
|---|---|---|
| MVP | 1 hero (Trần Quốc Toản): side-scrolling mission, quiz, stars, map/timeline, VI/EN, offline, Android + iOS | ~3–5 weeks |
| Vertical slice | The MVP hero polished on real phones, with final art and voice | ~6–8 weeks |
| First release | 2 heroes + 1 storybook, store-ready for kids' categories | ~2–3 months |
| Full vision | Many heroes ⟨placeholder⟩ in historical order, storybook calendar | 12–24 months |

**Next steps from the concept:** `/setup-engine` → `/prototype` (one story-first
side-scrolling mission) → `/art-bible` → `/design-review design/gdd/game-concept.md` →
`/map-systems` → `/design-system` per system → architecture → `/vertical-slice` on real phones.

**Blocked on content (on you):**
- Trần Quốc Toản's story beats and quiz with sources. The final mission, voice script
  and level layout all wait on these. A prototype can use stand-in beats, as long as they're labelled.
- The art bible, which every final asset waits on.
- Luan's history sign-off, which every fact shown to players waits on.

## 5. Context not in the concept

- Luan **skipped the taste questions** (favourite game moments, wished-for game, top three
  games), so there are no reference games. Ask Luan if you need them for the art bible.
- **Rejected or replaced by Luan:**
  - hero cards and the card album;
  - calm placement puzzles (picked light action instead);
  - mechanic-first and balanced story fidelity;
  - top-down and single-screen views;
  - Đông Hồ and lacquer art as the main style;
  - a content-download server;
  - game-dev-001's drafted Trần Quốc Toản beats (waiting outside the council, crushing the
    orange, raising the "Phá cường địch, báo hoàng ân" banner, leading his band). These
    were removed so the content owner writes the story from sources. Don't take them as
    verified.
- Luan answers fast and short, and often changes direction once something is concrete
  (cards → none, puzzle → action). Show a small concrete draft early and ask one question at a time.
- Luan said "yes" to an either/or question once. Re-ask instead of guessing.
