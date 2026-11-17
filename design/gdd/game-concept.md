# Game Concept: Dải Đất Anh Hùng (Land of Heroes)

*Created: 2026-11-14*
*Status: Approved (Luan, 2026-11-14) · Task: TASK-001*

> **Placeholder notice.** Every hero, event, date and story beat named in this
> document is an **illustrative placeholder ⟨placeholder⟩**. The real hero and event
> list, sources and the named history reviewer come from the team's history
> material, which has not arrived yet (see `production/project-plan.md`, "Material
> we need from the team"). Nothing here is a verified historical claim.
>
> **Exception (Luan, 2026-11-14): the first hero is Trần Quốc Toản.** His story beats
> are not written yet; the content and history owner writes and signs them off.

> **Luan's idea, in Luan's words:** "a mobile game about Vietnamese historical figures,
> the player targeting is starting from primary school level in Vietnam, they are able
> to learn about all heroes in the historical by playing the missions which are based
> on their main or famous stories". Concept pick: "mix 2 and 1, while 2 is the main
> stories flow but 1 will be additional games, able to enhance and provide later day by
> day or based on the real-time celebration in VN". Languages: "we need to support both
> EN and VI, default is VN but always can turn to EN". Experience: Story & Discovery,
> Challenge & Mastery, Relaxation & Flow, "also need some quizz for kids to learn about
> the VN historical".

---

## First Hero: Trần Quốc Toản

**Decided by Luan (2026-11-14):** "since we are able to add more and more heros and the
timeline will be adjust to match with real-time life of the hero, can just start with
Trần Quốc Toản". Heroes are added one at a time, each in its place on the historical
timeline; the MVP starts with this one hero.

**Hero order:** heroes are placed in **historical order** (the order they lived) on a
timeline; the map shows where each story happened (Luan, 2026-11-14).

**Mission beats:** not drafted here. Luan asked to leave Trần Quốc Toản's story beats
to the content and history owner (see below), who writes them from verified sources.

**Content and history owner:** none yet. Luan plans to add a **new team member, an art
designer who also covers the content, history and real stories**, and who signs off
each hero's mission.

---

## Elevator Pitch

> It's a 2D side-scrolling action story game for Vietnamese primary-school children
> where you **play each national hero's famous story** with simple attack and defend
> moves, then answer a short quiz to unlock the next hero on the map and the timeline.

> **No cards (Luan, 2026-11-14):** "the game is no card game, it will be 2D game with
> some simple action for attach, defense,...". Hero cards and the card album are
> removed; the quiz unlocks the next hero, and missions are side-scrolling.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Educational 2D side-scrolling action story game, with a quiz layer |
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

It's like a **kids' 2D side-scrolling action game**, *and also* every level **is a
real Vietnamese hero's famous story**, and the next hero on the map and timeline only
opens once the child **tells the story back in a quiz**. Between the main missions, **storybook mini-games arrive on real
Vietnamese days and celebrations** ⟨placeholder: Giỗ Tổ Hùng Vương, 30/4, 2/9⟩, so the
game follows the national calendar the child lives in.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Narrative** | 1 | Each mission is one hero's famous story, told with picture, voice and play (story-first) |
| **Discovery** | 2 | Passing the quiz unlocks the next hero on the timeline; their place on the map lights up; storybooks arrive on celebration days |
| **Challenge** | 3 | Simple, forgiving attack/defend action; 1–3 stars for remembering the story in the quiz (Quiz & stars Rule 7) |
| **Submission** | 4 | Calm pace, no timers that block play, soft failure, instant retry |
| **Fantasy** | 5 | "I helped the hero"; child-sized role in the legend |
| **Sensation** | 6 | Bright cartoon art, drums and voice, big clear feedback |
| **Expression** | N/A | Not a goal for MVP |
| **Fellowship** | N/A | No social features (child safety) |

### Key Dynamics
- Children replay a mission to get a missing star, re-living the story each time.
- Children tell parents or classmates the hero's story they just played.
- Children open the game on celebration days to find the new storybook.
- Children look at the map and timeline to see which hero comes next.

### Core Mechanics
1. **Story-first 2D side-scrolling missions**: the hero moves left to right through
   3–4 beats of the real story, using a few big on-screen buttons: move, attack,
   defend (a special move is optional). Enemies are few and forgiving.
2. **Story quiz**: 3–5 picture-supported questions after each mission; passing it
   gives 1–3 stars and **unlocks the next hero**.
3. **Map of Vietnam + historical timeline**: heroes appear in the order they lived;
   each finished hero lights up their place on the map and the timeline.
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

- [x] **Achievers** — How: stars, unlocking every hero, filling the map and timeline
- [x] **Explorers** — How: discovering each story, fact pages, new storybooks on celebration days
- [ ] **Socializers** — Not served in-game (child safety); sharing happens offline with family
- [ ] **Killers/Competitors** — Not served: no leaderboards or PvP

**Secondary audience:** parents and teachers, who choose the game for the child. They
want trustworthy history, no ads or data collection, and a conversation starter.

### Flow State Design

- **Onboarding curve**: the first mission teaches each touch action inside the story,
  with voice prompts and a hand icon, no reading required to start.
- **Difficulty scaling**: the one lever across heroes is **encounter composition**: how many
  enemies, which kinds, and from which sides (mission data). Timing stays global and gentle
  (`tuning.json`; the telegraph never drops below 0.8 s, R15), and a beat still fits the
  60 s play cap. Stars measure only quiz recall (Quiz & stars Rule 7), never play skill, and
  progress never depends on either (TASK-020 W16, A6).
- **Feedback clarity**: big animation, sound and voice on every beat; stars and the next
  hero unlocking at the end.
- **Recovery from failure**: a beat can't be failed; a mistake costs a moment and a small
  knock-back, and a wordless stuck hint appears after a few seconds without progress. No lives,
  no game-over screen, no shaming. A wrong quiz card greys out and the child tries again until
  right; then the why line explains.

---

## Core Loop

### Moment-to-Moment (30 seconds)
The child runs the hero left to right and presses big buttons to **attack** and
**defend** against a few slow, readable enemies, inside a beat of the real story. It is
satisfying through big feedback (voice line, drum hit, knock-back, bright animation),
forgiving timing (slow enemies, wide hit windows, defend that always works if held, no
instant fail) and a small story payoff after each beat. No blood or gore: enemies are
knocked back or run away.

### Short-Term (5 minutes)
One mission: short story scene (picture + voice) → 3–4 side-scrolling story beats in order →
story ending → 3–5 question quiz → 1–3 stars + **next hero unlocked**. "One more"
comes from the next hero appearing on the map and timeline, and a missing star.

### Session-Level (5–15 minutes)
One or two missions, or one storybook mini-game. Every session ends back on the map, a
natural stopping point with no cliffhanger timer. Sessions are deliberately shorter than
the template's 30–120 minutes because the players are primary-school children.

### Long-Term Progression
The map of Vietnam and the historical timeline light up hero by hero, in the order
the heroes lived; each hero keeps their best stars. The
main game is "done" when every main hero's mission is played; the storybook calendar
continues after that.

### Retention Hooks
- **Curiosity**: the next locked hero on the timeline; the next celebration's storybook.
- **Investment**: the lit-up map and timeline (saved locally on the device).
- **Social**: none in-game; children share stories with family and class offline.
- **Mastery**: the missing third star on a hero's mission.

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
Learning is part of the reward: passing the quiz unlocks the next hero.

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
   period clothing appear on frames, menus and backgrounds. *Design test*: if a screen is
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
| Kids' 2D side-scrolling action games (genre) | Simple run, attack and defend controls | Every level is a true hero's story, with a quiz gate | Familiar controls for young players |
| Map-progression mobile games (genre) | A visible map that fills up | The map is Vietnam and the timeline is history; each lit place is a real hero | Turns progress into geography and history |

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
| **Platforms and stack** | Two native apps (ADR-0001, accepted by Luan 2026-11-14). **iOS:** Swift + SpriteKit in a SwiftUI shell, minimum iOS 17 (ADR-0002). **Android:** Kotlin + the Android SDK only (SurfaceView game loop drawn with Canvas, SoundPool audio, no game framework). Both apps read one shared, bundled, offline `content/data/` folder of JSON. Godot 4 (TASK-002) is shelved; no engine from the template's engine table is used |
| **Key Technical Challenges** | The same rules written twice (Swift and Kotlin), kept equal by shared content and shared test fixtures; Vietnamese diacritic fonts and VI/EN voice; switching language at runtime; adding storybook content after release without collecting data; performance on low-end Android |
| **Art Style** | 2D modern kids' cartoon |
| **Art Pipeline Complexity** | Medium (custom 2D; likely AI-assisted, needs an art bible for consistency) |
| **Audio Needs** | Moderate: voice-over in two languages per mission, music, SFX |
| **Networking** | None. The game stays fully offline; storybook content ships in **timed app updates** (Luan, 2026-11-14), so no content server or download |
| **Content Volume** | MVP: 1 hero mission (~5 min), 1 lit place on the map and timeline, 1 quiz. First release: 2 heroes + 1 storybook. Full vision: many heroes ⟨placeholder count⟩ + a calendar of storybooks |
| **Procedural Systems** | None |
| **Memory budget** | At most 64 MB of decoded textures alive at any moment, on both apps (ADR-0002) |

---

## Risks and Open Questions

### Design Risks
- Story-first attack/defend action may be hard to fit every story; some famous moments
  don't map naturally to a touch action.
- Children may skip story scenes and quizzes; the learning must sit inside the reward.
- Battle stories must feel heroic without violence; balance is set with the reviewer.

### Technical Risks
- Two codebases (Swift, Kotlin) can drift apart. Mitigation (ADR-0001): one shared
  `content/data/` schema that carries the history sign-off gate, and the same test
  fixtures run on both apps.
- The studio template's engine tooling has no Swift or Kotlin support (no
  `docs/engine-reference/` folder, no `engines.tsv` row), so engine-dependent checks
  report NOT ASSESSED, and APIs newer than the model's knowledge are checked by building
  against the installed SDK, not from memory.
- Storybooks "day by day or on celebrations" ship in **timed app updates** (decided):
  each celebration's update must clear Google Play and App Store review before the date,
  so releases are planned on a content calendar with review lead time. "Day by day"
  pages are bundled in the update and unlocked by the device date, offline.
- Runtime VI/EN switching with voice doubles audio assets and requires layouts that fit both.
- Feasibility is shown by the vertical slice built on both apps and passed by QC: iOS
  r9 `9c12a4a` (QC `fc43e7d`) and Android r12 `1ae1560` (QC `25ce9c9`), reviewed at the
  Concept → Systems Design gate (2026-11-17).

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
- **Which heroes and events, in what order?** First hero decided: **Trần Quốc Toản** (Luan, 2026-11-14). More heroes are added over time, placed in historical order.
- ~~Who is the named history reviewer?~~ **Decided (Luan, 2026-11-14): Luan signs off history.** game-art-content drafts each hero's content with cited sources; nothing is final until Luan signs it off.
- **Monetization**: paid, free, school/government funded? (Luan decides; no ads to kids by default.)
- ~~How storybook content arrives after release~~ **Decided (Luan, 2026-11-14): timed app updates**, no content download.
- ~~Portrait or landscape?~~ **Decided (Luan): landscape.** Every GDD and both apps are
  landscape. Held in portrait, the app shows a picture-only "turn the phone" screen (title UX,
  `design/ux/title.md`).
- **Do children read the story scenes or skip them?** Answer with an MVP playtest.

---

## MVP Definition

**Core hypothesis**: Primary-school children enjoy playing a hero's famous moment as
light touch action, and afterwards can answer simple questions about that story.

**Required for MVP**:
1. One story-first hero mission, **Trần Quốc Toản**, with 3–4 side-scrolling attack/defend beats (see First Hero)
2. The quiz (3–5 questions) that gives 1–3 stars and unlocks the next hero slot
3. The map of Vietnam and timeline with Trần Quốc Toản lit up
4. Vietnamese default with a working English switch, full diacritic fonts
5. Runs offline on one Android phone and one iPhone

**Explicitly NOT in MVP** (defer to later):
- Storybook mini-games and the celebration calendar
- More than one hero; the full map and timeline
- Accounts, analytics or monetization (and no content download at any tier: storybooks ship in app updates)

### Scope Tiers (if budget/time shrinks)

| Tier | Content | Features | Timeline *(estimates, solo + AI)* |
| ---- | ---- | ---- | ---- |
| **MVP** | 1 hero | Side-scrolling mission, quiz, stars, map/timeline, VI/EN | ~3–5 weeks |
| **Vertical Slice** | 1 hero polished on real phones | MVP + final art and voice | ~6–8 weeks |
| **First Release** | 2 heroes + 1 storybook | Store-ready for kids' categories | ~2–3 months |
| **Full Vision** | Many heroes ⟨placeholder⟩, full map, storybook calendar | All features, polished | 12–24 months |

If time runs out: ship the MVP hero alone, polished, and add heroes and storybooks later.

---

## Next Steps

- [x] Luan approves this concept (design and content decision), 2026-11-14
- [x] Platform chosen: native per platform, Swift + SpriteKit and Kotlin (ADR-0001, 2026-11-14); `/setup-engine` not used
- [ ] `/prototype [core mechanic]`: validate the story-first side-scrolling attack/defend mission (later task)
- [ ] Collect the team's hero list, sources and reviewer; replace every ⟨placeholder⟩
- [ ] `/art-bible`: modern kids' cartoon with Vietnamese motifs
- [ ] `/design-review design/gdd/game-concept.md`
- [ ] `/map-systems`, then `/design-system` per system
- [ ] `/create-architecture`, `/architecture-decision`, `/architecture-review`
- [ ] `/vertical-slice` on real phones before production
