# Game Concept: Letter Morph

*Created: 2026-11-17*
*Status: Approved (revised 2026-11-18 after /design-review to match decisions K-01…K-08, the art bible and the prototype iterations 1–4; K-44 lines added 2026-11-18, TASK-120)*
*Working title. The final name is decision K-04 (open). Project folder: `kid-learn-character`.*

---

## Elevator Pitch

> It's a magical alphabet toy for toddlers where every key the child presses, on screen or on a
> real keyboard, turns into its letter or number, and then that letter dissolves into stardust
> and settles into a thing from today's theme: **D** becomes a diplodocus, **3** becomes three baby dinosaurs.
> The child mashes the keyboard, and the whole world answers.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Toddler toy / early-learning sandbox (no goals, no fail state) |
| **Platform** | Native Apple first: iPadOS + macOS (Swift), then iPhone; Android (Kotlin) later (K-03) |
| **Target Audience** | Children aged 2.5–3, played alongside a parent (see Target Player Profile) |
| **Player Count** | Single-player, with the parent as co-player beside the child |
| **Session Length** | 5–15 minutes |
| **Monetization** | None: no ads, no in-app purchases (Safe by Design) |
| **Estimated Scope** | Small (MVP in ~1 week; full vision ~1–3 months, solo developer with a Claude team) |
| **Comparable Titles** | Toddler alphabet and "baby smash" keyboard apps (not researched); Typer Shark as the typing-is-fun reference (Luan's favourite) |

---

## Core Fantasy

"The letters are alive, and I wake them up." The child, who cannot read yet, has the power to make
magic happen with any key: every press is answered with wonder, and nothing they do is ever wrong.
It is Luan's own observation of their child turned into a toy: a 2.5–3-year-old loves pressing keys
and buttons, and loves it most when the answer is a theme they adore (dinosaurs, vehicles).

---

## Unique Hook

It's like an alphabet flashcard app, **and also** the child watches the letter's own shape glow,
dissolve into stardust and become the object, so the link between the letter and the thing is
something they see happen, not two pictures side by side.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Discovery** (exploration, secrets) | 1 | Every key hides a surprise; the child finds out what each letter becomes |
| **Sensation** (sensory pleasure) | 2 | The stardust morph, soft glow, the object's own sound, the spoken word |
| **Submission** (relaxation, comfort zone) | 3 | No goals, timers or fail state; calm colours and gentle sounds |
| **Fantasy** (make-believe, role-playing) | 4 | Letters as sleeping creatures that wake up |
| **Fellowship** (social connection) | 5 | The parent sits beside the child and says the words along |
| **Expression** (self-expression, creativity) | N/A in MVP | Comes with Mash World (Tier 2): the child fills a scene |
| **Narrative** (drama, story arc) | N/A | No story |
| **Challenge** (obstacle course, mastery) | N/A | Deliberately absent (anti-pillar) |

### Key Dynamics (Emergent player behaviors)

- The child mashes keys to see "what's next", then slows down and presses favourites on purpose.
- The child goes back to a favourite letter again and again ("dinosaur again!").
- The child starts to say the letter or word along with the voice.
- The parent names letters and asks "where is the D?", turning the toy into a game of their own.

### Core Mechanics (Systems we build)

1. **Key input:** a hardware keyboard on iPad and Mac, plus touch on a few glowing **hint letters**
   that drift in the sky (a touch on a fading hint still counts); an **optional on-screen keyboard
   row**, off by default, turned on by a grown-up (art bible §7). Only letters A–Z and digits 0–9 do
   anything; every other key is swallowed, held keys and repeats are ignored.
1a. **Theme key table (K-07):** a **theme** (Dinosaurs first) covers every key: each letter becomes
   a cast member whose name contains the letter, often but not always first (C = triCeratops); each
   digit becomes that many baby dinosaurs (0 = an empty nest). Data (JSON), not code. The demo fixes
   one item per key per theme; production has a small per-key database for variety.
2. **Morph reveal:** one shared "stardust morph" effect for every key: the big letter glows,
   dissolves into particles, and the particles form the object, which then idles gently.
3. **Sound and voice:** the cast member's own sound plus the spoken line (US English, the letter's
   name then the word: "C… triceratops"; never "letter C"). **Tap the cast member** on stage and it
   hops and makes its own sound again (iteration 4), so the child links the creature to its sound.
4. **Mash control:** a queue of at most 3 pending keys; further presses only sparkle; while keys
   are queued, each reveal holds for about 3 s.
5. **Parade:** every 6 new cast members met, those 6 walk across the hills once (K-17) (Luan's favourite
   moment in the playtest: Keep).
6. **Parent gate and child lock-in:** settings sit behind a grown-up check (hold the moon, or the
   parent key chord on the Mac). Child lock-in keeps the child in the app: a kiosk mode on the Mac,
   Guided Access guidance on the iPad (TASK-033; the playtest's worst moment was shortcuts
   switching apps).
7. **The stage follows the clock (K-08):** morning, day, dusk, night from the device's clock; a
   grown-up can pick today's weather by hand. No network, no location.

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** (freedom, meaningful choice) | Any key, any time, in any order; nothing is wrong | Core |
| **Competence** (mastery, skill growth) | "I press, magic happens", then "I know D is the dinosaur" | Supporting |
| **Relatedness** (connection, belonging) | Played next to a parent who says the words along | Supporting |

### Player Type Appeal (Bartle Taxonomy)

- [ ] **Achievers** (goal completion, collection, progression) — How: not served on purpose; no scores or collections
- [x] **Explorers** (discovery, understanding systems, finding secrets) — How: primary; every key is a secret to uncover
- [x] **Socializers** (relationships, cooperation, community) — How: secondary; the parent as co-player sharing the "wow"
- [ ] **Killers/Competitors** (domination, PvP, leaderboards) — How: not served

**Not for:** children who want goals or challenge (about 5+), or parents who want a structured
curriculum with progress tracking and tests.

### Flow State Design

- **Onboarding curve**: none needed: the first press already works. No tutorial, no text.
- **Difficulty scaling**: none; there is no difficulty. Novelty comes from 36 different keys.
- **Feedback clarity**: every press is acknowledged at once (the key lights up), even when queued
  or ignored.
- **Recovery from failure**: there is no failure. Mashing never breaks, freezes or stacks the game.

---

## Core Loop

### Moment-to-Moment (30 seconds)

The child presses a key or touches a hint letter. A chime answers at once; the big letter rises
from where it was pressed, glows, dissolves into stardust and settles into the cast member
(D → a diplodocus that hums) while the voice says "D… diplodocus".
The object idles gently until the next press. Satisfying through instant acknowledgement, a
moment of wonder, and the visible letter-to-object link. When the child mashes, up to 3 keys
queue and each reveal holds about 3 s; extra presses only sparkle. Touching the cast member makes it
hop and make its sound again.

### Short-Term (5-15 minutes)

Exploration: which key becomes what? The child finds favourites and presses them again. Numbers
count: **3** becomes three baby dinosaurs, and the voice says "three… three baby dinosaurs".
Every 6 new cast members met, they walk across the hills in a parade (K-17).

### Session-Level (30-120 minutes)

Not applicable at this age: a session is about 5–15 minutes, a toddler's attention span. It ends
when the child wanders off or a parent closes the app; nothing is lost, there is nothing to save.

### Long-Term Progression

None for the child: no scores, levels, unlocks or "seen" marks (art bible §4). There is **a parade meter, not a
score** (K-44): it lights one step per new creature toward the next parade, empties with each parade and is never
saved. The toy grows
instead: the Dinosaurs theme first, then new themes (Vehicles…) chosen by a parent, driven by the
child's feedback, and more items per key (K-07). It is a toy, so it is
never "done".

### Retention Hooks

- **Curiosity**: "what does this key become?" across 36 keys; later, new themes.
- **Surprise**: the parade, which arrives without warning after a run of new creatures.
- **Investment**: favourite letters the child wants to see again ("the dinosaur!").
- **Social**: the parent and child playing together.
- **Mastery**: recognising letters and numbers, passively.

---

## Game Pillars

### Pillar 1: Every Press Answers
Every press is acknowledged at once, and mashing never breaks, freezes or stacks the game.

*Design test*: Debating a richer animation or a faster acknowledgement → faster acknowledgement.

### Pillar 2: The Letter Comes Alive
The letter or number shape is the star, and it visibly becomes the object.

*Design test*: Debating showing the object alone or the letter morphing into it → the morph.

### Pillar 3: Calm Magic
Wonder without overstimulation: sparkle, soft colours, gentle sounds, no strobing. (Pulls against
Pillar 1's energy, on purpose.)

*Design test*: Debating louder and flashier or calmer → calmer.

### Pillar 4: Things the Child Loves
Content follows the child's passions (dinosaurs, vehicles).

*Design test*: Debating a generic object or a theme favourite → the theme favourite.

### Pillar 5: Safe by Design
A parent can hand the device over without worry: offline, no data, a parent gate.

*Design test*: Debating a feature that needs the network or data, or none → none.

### Anti-Pillars (What This Game Is NOT)

- **NOT scores, timers, quizzes or fail states**: they would compromise Calm Magic and Every Press Answers. *(K-44:
  a parade meter, not a score: it shows the way to the next parade, holds no total and is never saved.)*
- **NOT text the child must read** (beyond the letter or number itself): it would compromise The Letter Comes Alive.
- **NOT ads, in-app purchases, accounts, network or analytics**: they would compromise Safe by Design.
- **NOT strobing effects, loud stings or endless reward loops**: they would compromise Calm Magic.

---

## Visual Identity Anchor

*The art bible (`design/art/art-bible.md`, Approved 2026-11-17) is the source of truth; this is
its summary. The brainstorm's provisional "Stardust Storybook" anchor was sharpened there.*

**Visual rule:** *The letter is light, and the light gently settles into the thing.*

**Supporting principles** (art bible §1):
1. **The glyph gets the first look** (Pillar 2): the letter is the brightest, largest, warmest
   thing on screen, and the stardust keeps its outline before it becomes the cast member.
   *Design test: when something competes with the glyph, dim or shrink the competitor.*
2. **One flat, friendly silhouette** (Pillar 4): rounded flat shapes a 3-year-old can name from the
   outline alone; never emoji, never plain circles. *Design test: more detail or a cleaner
   silhouette → the silhouette.*
3. **Drift, never flash** (Pillar 3): light fades up, glows and drifts. The one exception, by
   Luan's choice (K-08), is the glyph's halo pulse at ~2.2 Hz: a blur pulse below the
   three-flashes-per-second threshold; every other pulse is ≤ 1 Hz. *Design test: a faster,
   brighter burst or a slower glow → the slower glow.*

**The stage follows the clock** (art bible §2, K-08): morning, day, dusk (the home look), night,
plus calm weather picked by hand by a grown-up. **Colour:** gold means only "a letter"; cast
members sit in eight hue slots; no colour means right, wrong or reward (art bible §4).

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| Typer Shark (Luan's favourite) | Pressing keys is the fun, and every key press matters | No goal, no danger, no reading: for a toddler | Validates "the keyboard as the game" |
| Toddler "smash the keyboard" apps (not researched) | Any key does something; safe for mashing | Each key teaches its own letter, through a morph | The mashing need is real (observed in Luan's child) |
| Alphabet flashcards / picture books | Letter + object + word | The letter *becomes* the object; it is animated and spoken | The pairing is the learning goal |

**Non-game inspirations**: Luan's child playing with sound-button toys (dinosaurs, vehicles);
picture-book alphabets.

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 2.5–3 years (the first player is Luan's own child) |
| **Gaming experience** | None: pre-reader, first screen toys |
| **Time availability** | 5–15 minutes at a time, with a parent nearby |
| **Platform preference** | iPad (touch or hardware keyboard), a parent's Mac |
| **Current games they play** | Sound-button toys on themes they love (dinosaurs, vehicles) |
| **What they're looking for** | Press something and get a delightful answer about the things they love |
| **What would turn them away** | Waiting, text, anything that says "wrong", scary or loud effects; for the parent: ads, purchases, links out, data collection |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | Native Swift (K-03; Luan's Unity familiarity noted but not used): SpriteKit in a SwiftUI shell, one Xcode project under `apple/` (ADR-0001). The morph is computed by a UI-free MorphCore to **morph contract v1** (`docs/architecture/morph-contract-v1.md`), which an Android port must match; Rive and an engine-as-a-library were rejected (TASK-033) |
| **Key Technical Challenges** | Hardware keyboard input and child lock-in on iPadOS and macOS (⌘Tab, Mission Control, Guided Access shortcuts NOT ASSESSED yet); press-to-sound latency on a real iPad (NOT ASSESSED; Simulator/Mac only so far); one morph for every glyph; how SVG art reaches the screen (a later ADR) |
| **Art Style** | 2D first, 3D later for a few favourites (K-01); flat, rounded, outlined cast (art bible) |
| **Art Pipeline Complexity** | Medium: per theme, 26 SVG cast members + silhouettes and the number babies, one shared morph |
| **Audio Needs** | Moderate: per theme, 36 cast sounds, voice lines for 36 letter/number names and 36 words (US English), a press chime |
| **Networking** | None: no network, no location, no analytics (Pillar 5; K-08 keeps weather hand-picked) |
| **Content Volume** | Dinosaurs theme in the MVP: 26 letters + 10 numbers; each later theme adds the same; production adds several items per key (K-07) |
| **Procedural Systems** | The shared stardust morph (MorphCore: glyph points → silhouette points, seeded, data-timed) |

---

## Risks and Open Questions

### Design Risks
- The ~3 s hold while mashing may feel slow to a toddler; tune it in play (config value).
- Will a 2.5-year-old notice the letter at all, or only watch the cast member?
- Hint letters drift and fade: a slow aim can miss (mitigated: a touch on a fading hint counts).

### Technical Risks
- Child lock-in: ⌘Tab, ⌘⌥Esc, Mission Control, Globe and iPad shortcuts under Guided Access are NOT
  ASSESSED (TASK-033); a physical-keyboard check is needed.
- All latency figures are Simulator/Mac lower bounds; the child's real iPad is not measured.
- A first native Swift build pipeline for this team; signing and the Kids category.
- The SVG rendering path in SpriteKit is undecided (a later ADR with an iPad measurement).

### Market Risks
- Toddler alphabet apps are a crowded space (not researched).
- The App Store Kids category has strict rules (no third-party analytics or ads); the TASK-032
  checklist covers them.

### Scope Risks
- Per theme: 36 sets of art, silhouette, sound and voice; production wants several per key (K-07).
- 14 MVP systems against a ~1-week MVP: treat "~1 week" as an aspiration and re-estimate at the
  Production gate (`/estimate`; producer, gate check 2026-11-18).

### Open Questions
- Where do art and voice come from (made, generated or licensed)? → `/asset-spec` and the audio
  direction.
- The game's name (K-04) → later.
- Does the App Store Kids category apply to the macOS app? → Luan checks App Store Connect
  (TASK-034, not verified).

---

## MVP Definition

**Core hypothesis**: Luan's 2.5–3-year-old child stays delighted pressing keys for 5+ minutes and
comes back to it, because every key turns into a magical, spoken letter and object.

**Required for MVP** (systems index, 14 MVP systems):
1. Hardware keyboard + hint letters, A–Z and 0–9, from the Dinosaurs theme's JSON key table;
   every other key does nothing.
2. The shared stardust morph, the cast member's sound and the US English line ("C… triceratops");
   tap the cast member to hear its sound again.
3. Mash control: a queue of at most 3, about 3 s per reveal while queued; nothing ever breaks.
4. The parade every 6 new cast members (K-17).
5. Fully offline, no data; a parent gate for anything that is not play; child lock-in.
6. Runs on iPad and Mac (iPhone later).

**Explicitly NOT in MVP** (defer to later):
- Time of day and hand-picked weather, the optional on-screen keyboard row, Reduce Motion
  (Vertical Slice).
- More themes and more items per key (Alpha; K-07).
- Mash World: cast members stay in a scene (Full Vision).
- Vietnamese voice, iPhone, Android; 3D cast members.

### Scope Tiers (if budget/time shrinks)

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | Dinosaurs theme: 26 letters + 10 numbers, US English | Morph, sound and voice, tap sound, mash control, hints, parade, parent gate, child lock-in | ~1 week (aspiration; re-estimate at the Production gate) |
| **Vertical Slice** | The same theme | Time of day + hand-picked weather, optional keyboard row, Reduce Motion | +1–2 weeks |
| **Alpha: more themes** | Vehicles… (36 each), more items per key | A grown-up picks the theme behind the gate | +1–2 weeks per theme, driven by the child's feedback |
| **Full Vision** | Several themes, Vietnamese voice, Mash World, some 3D favourites | iPhone, then Android | ~1–3 months in total |

---

## Next Steps

- [x] `/setup-engine`: native Swift recorded in ADR-0001 (Proposed; TASK-035 update in review)
- [x] `/prototype`: `prototypes/letter-morph-dinosaur/`, iterations 1–4, PROCEED
- [x] `/art-bible`: 9 sections, Approved
- [x] `/design-review design/gdd/game-concept.md`: NEEDS REVISION → revised 2026-11-18
- [x] `/map-systems`: `design/gdd/systems-index.md` (20 systems, 14 MVP)
- [ ] `/gate-check systems-design` to leave Concept
- [ ] `/design-system` per system, in the systems index's design order
