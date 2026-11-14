# Game Concept: Dải Đất Anh Hùng (Land of Heroes)

*Created: 2026-11-14*
*Status: Approved (Luan, 2026-11-14) · Task: TASK-001*

> **Placeholder notice.** Every hero, event, date and story beat named in this
> document is an **illustrative placeholder ⟨placeholder⟩**. The real hero and event
> list, sources and the named history reviewer come from the team's history
> material, which has not arrived yet (see `production/project-plan.md`, "Material
> we need from the team"). Nothing here is a verified historical claim.

> **Luan's idea, in his words:** "a mobile game about Vietnamese historical figures,
> the player targeting is starting from primary school level in Vietnam, they are able
> to learn about all heroes in the historical by playing the missions which are based
> on their main or famous stories". Concept pick: "mix 2 and 1, while 2 is the main
> stories flow but 1 will be additional games, able to enhance and provide later day by
> day or based on the real-time celebration in VN". Languages: "we need to support both
> EN and VI, default is VN but always can turn to EN". Experience: Story & Discovery,
> Challenge & Mastery, Relaxation & Flow, "also need some quizz for kids to learn about
> the VN historical".

---

## Elevator Pitch

> It's a light-action story game for Vietnamese primary-school children where you
> **play each national hero's famous moment** on a map of Vietnam, then answer a short
> quiz to earn that hero's card, lighting up the map one region at a time.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Educational story game: light action missions + collection, with a quiz layer |
| **Platform** | Mobile: Android + iOS phones, touch-first (tablets later) |
| **Target Audience** | Vietnamese primary-school children, about 6–10 (see Target Player Profile) |
| **Player Count** | Single-player |
| **Session Length** | 5–15 minutes (one or two missions, or one storybook) |
| **Monetization** | None decided (open question; no ads or purchases aimed at kids unless Luan decides) |
| **Estimated Scope** | Large (12–24 months, solo + AI studio) for the full vision; MVP ~3–5 weeks *(estimates)* |
| **Comparable Titles** | Educational story apps and kids' puzzle apps: not researched |

**Languages.** Vietnamese (default) and English. The player can switch language at any
time (first-launch choice + a toggle in settings). All text, voice-over and fonts cover
both, with full Vietnamese diacritics (e.g. *Hưng Đạo Đại Vương*). English text runs
longer, so UI layouts must fit both.

---

## Core Fantasy

"**I was the hero's hands at the moment that made history.**" The child doesn't read
about the legend, they do it: rowing, tapping, swiping through the story's turning
point ⟨placeholder examples: helping Thánh Gióng grow, setting stakes for the Bạch Đằng
tide⟩, and then proves they remember it. Over time they fill in a map of their own
country with the heroes who protected it.

---

## Unique Hook

It's like a **sticker album of heroes on a map of Vietnam**, *and also* every sticker
is earned by **playing that hero's real famous moment** and then **telling the story
back in a quiz**. Between the main missions, **storybook mini-games arrive on real
Vietnamese days and celebrations** ⟨placeholder: Giỗ Tổ Hùng Vương, 30/4, 2/9⟩, so the
game follows the national calendar the child lives in.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Narrative** | 1 | Each mission is one hero's famous story, told with picture, voice and play (story-first) |
| **Discovery** | 2 | New regions light up; quiz answers unlock "Did you know?" fact pages; storybooks arrive on celebration days |
| **Challenge** | 3 | Light, forgiving tap/swipe action beats; 1–3 stars for replay mastery |
| **Submission** | 4 | Calm pace, no timers that block play, soft failure, instant retry |
| **Fantasy** | 5 | "I helped the hero"; child-sized role in the legend |
| **Sensation** | 6 | Bright cartoon art, drums and voice, big clear feedback |
| **Expression** | N/A | Not a goal for MVP |
| **Fellowship** | N/A | No social features (child safety) |

### Key Dynamics
- Children replay a mission to get a missing star, re-living the story each time.
- Children tell parents or classmates the hero's story they just played.
- Children open the game on celebration days to find the new storybook.
- Children look at the map to see which region and hero comes next.

### Core Mechanics
1. **Story-first light-action missions**: 3–4 action beats per hero, each a beat of the
   real story, built from a small shared set of touch actions (tap, swipe, drag, hold).
2. **Story quiz**: 3–5 picture-supported questions after each mission; correct answers
   upgrade the hero card and unlock fact pages.
3. **Map of Vietnam + hero cards**: regions unlock hero missions; cards collect stars and facts.
4. **Storybook mini-games** (later content): illustrated pages, each a short touch
   mini-game, released day by day or on Vietnamese celebrations.
5. **Bilingual presentation**: VI default, EN switchable at any time, voice + text.

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** | Pick which unlocked hero to play; replay for stars; choose language | Supporting |
| **Competence** | Forgiving actions + stars; the quiz proves "I know this now" | Core |
| **Relatedness** | National heroes, family celebrations, something to share with parents (no in-game social) | Supporting |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** — How: stars, filling the map, completing the card album
- [x] **Explorers** — How: discovering each story, fact pages, new storybooks on celebration days
- [ ] **Socializers** — Not served in-game (child safety); sharing happens offline with family
- [ ] **Killers/Competitors** — Not served: no leaderboards or PvP

**Secondary audience:** parents and teachers, who choose the game for the child. They
want trustworthy history, no ads or data collection, and a conversation starter.

### Flow State Design

- **Onboarding curve**: the first mission teaches each touch action inside the story,
  with voice prompts and a hand icon, no reading required to start.
- **Difficulty scaling**: later heroes add a little speed or more targets; stars, not
  progress, reward the extra challenge.
- **Feedback clarity**: big animation, sound and voice on every beat; stars and card
  upgrades at the end.
- **Recovery from failure**: a missed beat slows down and replays instantly; no lives,
  no game-over screen, no shaming. Quiz mistakes show the right answer with the story picture.

---

## Core Loop

### Moment-to-Moment (30 seconds)
The child performs one simple touch action that *is* a story beat (row, dodge, tap to
raise, swipe to throw ⟨placeholder examples⟩). It is satisfying through big feedback
(voice line, drum hit, bright animation), forgiving timing (slow speed, wide targets,
no instant fail) and a small story payoff after each beat.

### Short-Term (5 minutes)
One mission: short story scene (picture + voice) → 3–4 action beats in story order →
story ending → 3–5 question quiz → hero card upgrade + 1–3 stars. "One more" comes from
the next region lighting up and a card with an empty star slot.

### Session-Level (5–15 minutes)
One or two missions, or one storybook mini-game. Every session ends back on the map, a
natural stopping point with no cliffhanger timer. Sessions are deliberately shorter than
the template's 30–120 minutes because the players are primary-school children.

### Long-Term Progression
The map of Vietnam fills region by region; hero cards gain stars and fact pages. The
main game is "done" when every main hero's mission is played; the storybook calendar
continues after that.

### Retention Hooks
- **Curiosity**: the next dark region on the map; the next celebration's storybook.
- **Investment**: the card album and the lit-up map (saved locally on the device).
- **Social**: none in-game; children share stories with family and class offline.
- **Mastery**: the missing third star on a hero card.

---

## Game Pillars

### Pillar 1: Sống lại câu chuyện (Live the story)
Every mission *is* the hero's famous moment, played and not just read.

*Design test*: debating a fun mechanic vs. one that matches the story, **the story wins**.

### Pillar 2: Đúng sự thật (True to history)
Every claim is labelled fact, interpretation or invented, and signed off by the named
history reviewer.

*Design test*: debating a dramatic invented detail vs. a plain verified one, **the
verified one wins**, or the invented one is labelled.

### Pillar 3: Nhỏ chơi được (Small hands can do it)
A 6–10 year old plays and reads it alone: big touch targets, short text with voice,
forgiving timing, no failure shame.

*Design test*: debating more challenge vs. a 6-year-old finishing, **the 6-year-old
finishes**; mastery lives in stars, not in blocked progress.

### Pillar 4: Học mà vui (Learn by playing)
Learning is part of the reward: the quiz upgrades cards, facts unlock as treasures.

*Design test*: debating a separate lesson screen vs. folding the fact into play or
reward, **fold it in**.

### Pillar 5: An toàn cho trẻ (Safe for kids)
No data collection, no ads, no purchases or chat aimed at kids, and it works offline.

*Design test*: debating a feature that needs child data or a network login vs. none,
**none**, unless Luan decides otherwise.

### Anti-Pillars (What This Game Is NOT)

- **NOT timers, lives or energy that block play**: they break *Small hands can do it*
  and invite monetization pressure.
- **NOT graphic violence or gore**: battles are shown through symbols, tides and victory,
  not killing; otherwise *Safe for kids* and the reviewer's sign-off fail.
- **NOT generic reusable mini-games that ignore the story**: they break *Live the story*.
- **NOT leaderboards, chat, accounts or ads to kids**: they break *Safe for kids*.
- **NOT invented details presented as fact**: that breaks *True to history*.

---

## Visual Identity Anchor

**Direction: Modern kids' cartoon with Vietnamese motifs** (chosen by Luan; art-director
gate skipped in lean review mode).

**One-line rule:** *Soft, rounded, bright cartoon heroes in a world whose patterns,
clothing and objects are unmistakably Vietnamese.*

**Supporting principles**
1. **Friendly heroes, respectful heroes.** Characters are rounded and warm, never
   comic-silly. *Design test*: if a pose or expression would make a teacher or the history
   reviewer uncomfortable, redraw it.
2. **Motifs as accents, not noise.** Bronze-drum patterns, lotus, bamboo, áo dài and
   period clothing appear on frames, cards and backgrounds. *Design test*: if a screen is
   hard to read at a glance on a phone, remove motif detail first.
3. **Readable at phone size.** Big silhouettes, high contrast for touch targets, text never
   painted into art (it must switch between VI and EN). *Design test*: every interactive
   thing is recognisable at thumbnail size.

**Colour philosophy:** bright, warm primaries for interaction and rewards (gold stars,
red accents from the national palette used sparingly), softer natural greens and river
blues for the map and backgrounds; battles use dramatic sky and water colour, not blood.

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| Interactive picture books (genre) | Page-by-page story with touch play | Each page is a story beat mini-game, released on celebrations | Proven format for young readers (not researched) |
| Sticker / card albums (genre) | Collection and completion drive | Cards are earned by playing and remembering a true story | Gives a reason to replay and return |
| Map-progression mobile games (genre) | A visible map that fills up | The map is Vietnam, and each region is a real hero | Turns progress into geography and history |

Luan did not name reference games (Phase 1 questions skipped). **Non-game inspirations**:
Vietnamese legends as told to children, school history lessons, national celebrations.

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | About 6–10 (Vietnamese primary school) |
| **Gaming experience** | Casual; may be a first game on a parent's phone |
| **Time availability** | 5–15 minute sessions, often with a parent's permission |
| **Platform preference** | A parent's or family Android phone (often low-end) or iPhone |
| **Current games they play** | Not researched |
| **What they're looking for** | Fun stories and rewards; for parents, trustworthy history in Vietnamese |
| **What would turn them away** | Too much reading, frustrating failure, scary violence; for parents, ads, purchases or data collection |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | No preference stated; `/setup-engine` decides with this concept and the mobile platform (the project plan's candidate is Godot 4, alternative Unity) |
| **Key Technical Challenges** | Android + iOS builds for a first game; Vietnamese diacritic fonts and VI/EN voice; switching language at runtime; adding storybook content after release without collecting data; performance on low-end Android |
| **Art Style** | 2D modern kids' cartoon |
| **Art Pipeline Complexity** | Medium (custom 2D; likely AI-assisted, needs an art bible for consistency) |
| **Audio Needs** | Moderate: voice-over in two languages per mission, music, SFX |
| **Networking** | None. The game stays fully offline; storybook content ships in **timed app updates** (Luan, 2026-11-14), so no content server or download |
| **Content Volume** | MVP: 1 hero mission (~5 min), 1 map region, 1 quiz. First release: 2 heroes + 1 storybook. Full vision: many heroes ⟨placeholder count⟩ + a calendar of storybooks |
| **Procedural Systems** | None |

---

## Risks and Open Questions

### Design Risks
- Story-first light action may be hard to make fun for every story; some famous moments
  don't map naturally to a touch action.
- Children may skip story scenes and quizzes; the learning must sit inside the reward.
- Battle stories must feel heroic without violence; balance is set with the reviewer.

### Technical Risks
- Engine not chosen; both mobile builds are unproven in this template (plan: build an
  empty project for Android and iOS in phase 0).
- Storybooks "day by day or on celebrations" ship in **timed app updates** (decided):
  each celebration's update must clear Google Play and App Store review before the date,
  so releases are planned on a content calendar with review lead time. "Day by day"
  pages are bundled in the update and unlocked by the device date, offline.
- Runtime VI/EN switching with voice doubles audio assets and requires layouts that fit both.
- `TD-FEASIBILITY skipped — Lean mode`: feasibility not reviewed by the technical-director.

### Market Risks
- Audience size and competition for Vietnamese children's history games: not researched.
- Kids'-category store rules (Google Play Families, Apple Kids) may restrict features: not researched.
- Vietnam game publishing licence (G1) affects commercial launch (from the project plan).

### Scope Risks
- Each hero is a hand-built mission (story-first), the biggest cost driver for a solo developer.
- Luan's "weeks" timeline fits the MVP, not a store release.
- Art and two-language voice per hero are labour-heavy.
- `PR-SCOPE skipped — Lean mode`: scope not reviewed by the producer.

### Open Questions
- **Which heroes and events, in what order?** Placeholder until the team's history material arrives.
- **Who is the named history reviewer?** Needed before any content is final.
- **Monetization**: paid, free, school/government funded? (Luan decides; no ads to kids by default.)
- ~~How storybook content arrives after release~~ **Decided (Luan, 2026-11-14): timed app updates**, no content download.
- **Portrait or landscape?** Answer with the first prototype on a real phone.
- **Do children read the story scenes or skip them?** Answer with an MVP playtest.

---

## MVP Definition

**Core hypothesis**: Primary-school children enjoy playing a hero's famous moment as
light touch action, and afterwards can answer simple questions about that story.

**Required for MVP**:
1. One story-first hero mission ⟨placeholder hero⟩ with 3–4 light-action beats
2. The quiz (3–5 questions) that upgrades the hero card and gives 1–3 stars
3. One lit-up region on the map of Vietnam and one hero card
4. Vietnamese default with a working English switch, full diacritic fonts
5. Runs offline on one Android phone and one iPhone

**Explicitly NOT in MVP** (defer to later):
- Storybook mini-games and the celebration calendar
- More than one hero; the full map and card album
- Accounts, analytics or monetization (and no content download at any tier: storybooks ship in app updates)

### Scope Tiers (if budget/time shrinks)

| Tier | Content | Features | Timeline *(estimates, solo + AI)* |
| ---- | ---- | ---- | ---- |
| **MVP** | 1 hero, 1 region | Mission, quiz, card, stars, VI/EN | ~3–5 weeks |
| **Vertical Slice** | 1 hero polished on real phones | MVP + final art and voice | ~6–8 weeks |
| **First Release** | 2 heroes + 1 storybook | Store-ready for kids' categories | ~2–3 months |
| **Full Vision** | Many heroes ⟨placeholder⟩, full map, storybook calendar | All features, polished | 12–24 months |

If time runs out: ship the MVP hero alone, polished, and add heroes and storybooks later.

---

## Next Steps

- [x] Luan approves this concept (design and content decision), 2026-11-14
- [ ] `/setup-engine`: choose and pin the engine for Android + iOS (later task)
- [ ] `/prototype [core mechanic]`: validate the story-first light-action mission (later task)
- [ ] Collect the team's hero list, sources and reviewer; replace every ⟨placeholder⟩
- [ ] `/art-bible`: modern kids' cartoon with Vietnamese motifs
- [ ] `/design-review design/gdd/game-concept.md`
- [ ] `/map-systems`, then `/design-system` per system
- [ ] `/create-architecture`, `/architecture-decision`, `/architecture-review`
- [ ] `/vertical-slice` on real phones before production
