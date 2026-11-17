# Game Concept: Letter Morph

*Created: 2026-11-17*
*Status: Draft*
*Working title. The final name is decision K-04 (open). Project folder: `kid-learn-character`.*

---

## Elevator Pitch

> It's a magical alphabet toy for toddlers where every key the child presses, on screen or on a
> real keyboard, turns into its letter or number, and then that letter dissolves into stardust
> and becomes a thing: **D** becomes a roaring dinosaur, **3** becomes three bouncing apples.
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

1. **Key input:** an on-screen toddler keyboard (big keys) plus hardware keyboard input on iPad and
   Mac; every key A–Z and 0–9 maps to one entry in a data table (JSON).
2. **Morph reveal:** one shared "stardust morph" effect for every key: the big letter glows,
   dissolves into particles, and the particles form the object, which then idles gently.
3. **Sound and voice:** the object's sound plus the spoken line ("D… dinosaur", US English, letter
   name then word).
4. **Mash control:** a queue of at most 3 pending keys; further presses are ignored, with a soft
   sparkle on the key *(proposal)*; while keys are queued, each reveal holds for about 3 s.
5. **Parent gate:** settings (theme packs later, language later) sit behind a grown-up check.

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

The child presses a key. The key lights up at once; the big letter appears, glows, dissolves into
stardust and becomes the object (D → a dinosaur that roars) while the voice says "D… dinosaur".
The object idles gently until the next press. Satisfying through instant acknowledgement, a
moment of wonder, and the visible letter-to-object link. When the child mashes, up to 3 keys
queue and each reveal holds about 3 s; extra presses are ignored with a soft sparkle *(proposal)*.

### Short-Term (5-15 minutes)

Exploration: which key becomes what? The child finds favourites and presses them again. Numbers
count: **3** splits into three apples that bounce, and the voice says "three".

### Session-Level (30-120 minutes)

Not applicable at this age: a session is about 5–15 minutes, a toddler's attention span. It ends
when the child wanders off or a parent closes the app; nothing is lost, there is nothing to save.

### Long-Term Progression

None for the child: no scores, levels or unlocks. The toy grows instead: new theme packs
(Dinosaurs, Vehicles…) chosen by a parent, driven by the child's feedback. It is a toy, so it is
never "done".

### Retention Hooks

- **Curiosity**: "what does this key become?" across 36 keys; later, new theme packs.
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

- **NOT scores, timers, quizzes or fail states**: they would compromise Calm Magic and Every Press Answers.
- **NOT text the child must read** (beyond the letter or number itself): it would compromise The Letter Comes Alive.
- **NOT ads, in-app purchases, accounts, network or analytics**: they would compromise Safe by Design.
- **NOT strobing effects, loud stings or endless reward loops**: they would compromise Calm Magic.

---

## Visual Identity Anchor

*Provisional: derived from the brainstorm (feel "magical"; K-01 "2D first, 3D later").
AD-CONCEPT-VISUAL was skipped (Lean mode); `/art-bible` confirms or replaces it.*

**Direction: "Stardust Storybook"**

**Visual rule:** every letter is made of light, and the light becomes the thing.

**Supporting principles:**
1. **The glyph is the hero.** The letter or number is shown big, bold and centred before it morphs.
   *Design test: a decorative background or a clearer glyph → the clearer glyph.*
2. **Soft storybook 2D.** Flat, rounded illustrations with gentle idle motion; 3D only later for a
   few favourites. *Design test: more detail or a cleaner silhouette a toddler can read → the
   cleaner silhouette.*
3. **Sparkle, never strobe.** Particles drift and twinkle; nothing flashes. *Design test: a faster,
   brighter burst or a slower glow → the slower glow.*

**Colour philosophy:** calm, low-saturation backgrounds (dusk blue, cream) so the warm, glowing
letter and the stardust carry the colour; each object keeps its own clear, friendly colours.

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
| **Recommended Engine** | Native Swift (K-03: no cross-platform engine; Luan's Unity familiarity noted but not used). `/setup-engine` records it; an early team idea is SpriteKit 2D behind a swappable stage |
| **Key Technical Challenges** | Hardware keyboard input on iPadOS and macOS; low audio latency; one morph effect that works for all 36 glyphs; mash control with no stacking |
| **Art Style** | 2D first, 3D later for a few favourites (K-01) |
| **Art Pipeline Complexity** | Medium (custom 2D: 36 illustrations plus one shared morph effect) |
| **Audio Needs** | Moderate: 36 object sounds, 36 voice lines (US English), soft ambience |
| **Networking** | None (offline, Safe by Design) |
| **Content Volume** | 36 keys (A–Z, 0–9) in the MVP; each theme pack adds up to 36 more |
| **Procedural Systems** | The shared stardust morph (particles from the glyph's shape to the object's) |

---

## Risks and Open Questions

### Design Risks
- The ~3 s hold while mashing may feel slow to a toddler; tune it in the prototype.
- Some letters have no good toddler-safe object (Q, X, Z); TASK-029's draft uses X = fox.
- Will a 2.5-year-old notice the letter at all, or only watch the object?

### Technical Risks
- Hardware keyboard events on iPad (`pressesBegan`) and Mac; system shortcuts that could exit the app.
- A first native Swift build pipeline for this team; signing and the Kids category.
- Audio latency between the press and the sound.

### Market Risks
- Toddler alphabet apps are a crowded space (not researched).
- The App Store Kids category has strict rules (no third-party analytics or ads); the TASK-032
  checklist covers them.

### Scope Risks
- 36 sets of picture, sound and voice line in one week; licensing for art and voice.
- Making the shared morph look good for every glyph could take longer than expected.

### Open Questions
- How long should the hold be while mashing? → the prototype, then the child plays it.
- Should an ignored press (the queue is full) give a sparkle? → the prototype (proposal above).
- The game's name (K-04) → later.
- Where do art and voice come from (made, generated or licensed)? → `/art-bible` and TASK-029.

---

## MVP Definition

**Core hypothesis**: Luan's 2.5–3-year-old child stays delighted pressing keys for 5+ minutes and
comes back to it, because every key turns into a magical, spoken letter and object.

**Required for MVP**:
1. On-screen keyboard plus hardware keyboard, A–Z and 0–9, from a JSON data table.
2. The shared stardust morph, the object's sound and the US English line ("D… dinosaur").
3. Mash control: a queue of at most 3, about 3 s per reveal while queued; nothing ever breaks.
4. Fully offline, no data; a parent gate for anything that is not play.
5. Runs on iPad (plus Mac where the shared code allows it).

**Explicitly NOT in MVP** (defer to later):
- Mash World: objects stay in a scene (Tier 2).
- Theme packs (Tier 1).
- Vietnamese voice, iPhone, Android (Tier 3).
- 3D objects.

### Scope Tiers (if budget/time shrinks)

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 36 keys, one default set, US English | Morph, sound and voice, mash control, keyboards, parent gate | ~1 week |
| **Tier 1: Theme packs** | Dinosaurs, Vehicles… (up to 36 each) | Parent picks the pack behind the gate | +1–2 weeks per pack, driven by the child's feedback |
| **Tier 2: Mash World** | One scene per theme | Objects step into the scene and stay (max N), oldest leaves | +2–3 weeks |
| **Full Vision** | Several packs, Vietnamese voice, some 3D favourites | iPhone, then Android | ~1–3 months in total |

---

## Next Steps

- [ ] `/setup-engine`: record native Swift (K-03) — not in the engine table; last game used an ADR plus a `project.yaml` engine block
- [ ] **Prototype the core idea** (`/prototype`): a throwaway browser sketch of the morph and the mash rule, played by the child
- [ ] `/art-bible`: confirm the Visual Identity Anchor
- [ ] `/design-review design/gdd/game-concept.md`
- [ ] If the prototype PROCEEDS: `/map-systems`
- [ ] `/design-system` per system (prototype learnings in Tuning Knobs)
- [ ] `/gate-check` to leave Concept
