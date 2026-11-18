# Systems Index: Letter Morph (working title; K-04 open)

> **Status**: Draft
> **Created**: 2026-11-17
> **Last Updated**: 2026-11-18
> **Source Concept**: design/gdd/game-concept.md (with decisions K-01…K-08 in production/team/decisions.md, the art bible design/art/art-bible.md, the one-shot prototypes/letter-morph-dinosaur/ iterations 1–4, and the TASK-033/034 reports)

---

## Overview

Letter Morph is a toddler toy with one 30-second loop: a key press (screen or hardware) becomes its
glyph, the glyph dissolves into stardust and settles into a theme cast member that makes its sound
while a voice says "D… diplodocus". There is no goal, score or failure, so the systems are few and
small, and almost all of them serve **Pillar 1 (Every Press Answers)** and **Pillar 2 (The Letter
Comes Alive)**; **Pillar 5 (Safe by Design)** turns into whole systems of its own (the parent gate,
child lock-in, privacy compliance), because the player is 2.5–3 years old.

- **Key Table & Theme Data** is the data heart: every key A–Z and 0–9 maps to a cast member, its
  silhouette, sound and spoken lines, per theme (K-07: one fixed item per key in the demo, a small
  per-key database in production).
- **Input & Key Filter** turns a touch or a hardware key into a press; only letters and digits
  count, held keys and repeats are ignored, every other key is swallowed.
- **MorphCore** computes the glyph-to-silhouette stardust morph from data; it is UI-free and its
  contract (morph contract v1, TASK-035) is what an Android port must match.
- **Audio & Voice** plays the press chime, the cast member's own sound and the spoken letter + word
  with low latency (TASK-033: keep players primed, off the main thread).
- **Settings Store (inferred)** keeps the grown-up's choices on the device only; nothing else is
  saved and nothing leaves the device.
- **Press Queue** is the mash rule: at most 3 waiting presses, ~3 s per reveal while keys wait,
  extra presses only sparkle.
- **Reveal Stage** runs the reveal on screen, the idle cast member, and the tap-the-creature hop
  with its sound (iteration 4).
- **Cast Rendering (inferred)** draws cast members from SVG sources with data-driven idles at three
  detail sizes (art bible §5, §8); how SVG reaches the screen is decided by a later ADR.
- **Scene: Time of Day & Weather** follows the device clock (morning, day, dusk, night) and a
  weather picked by hand behind the parent gate (K-08; no network, no location).
- **Hint Letters** float a few glowing letters in the sky as touch targets; a touch on a fading
  hint still counts.
- **Parade** walks the last 8 new cast members across the hills, every 8 met (Luan's Keep).
- **Parent Gate & Grown-up Panel** opens by holding the moon, or the parent key chord on the Mac.
- **On-screen Keyboard Row** is an optional row of big letter keys, off by default (art bible §7).
- **Child Lock-in** is the macOS kiosk behind the parent gate and the iPad Guided Access guidance
  (TASK-033).
- **App Shell & Title (inferred)** covers launch, the title, resume and backgrounding.
- **Accessibility** follows Reduce Motion with a reduced timing set and keeps every meaning off
  colour alone (art bible §4, §7).
- **Privacy & Kids Compliance (inferred)** is the constraint every build passes: no analytics, no
  third-party SDKs, privacy manifest, Kids category rules (TASK-034).
- **Theme Packs**, **Localization** (a Vietnamese voice, K-02) and **Mash World** (cast members stay
  in the scene) come after the MVP.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Key Table & Theme Data | Data | MVP | Approved | design/gdd/key-table-theme-data.md | — |
| 2 | Input & Key Filter | Core | MVP | Approved | design/gdd/input-key-filter.md | — |
| 3 | MorphCore | Core | MVP | Approved | design/gdd/morphcore.md | — |
| 4 | Settings Store (inferred) | Persistence | MVP | Approved | design/gdd/settings-store.md | — |
| 5 | Privacy & Kids Compliance (inferred) | Meta | MVP | Not Started | design/gdd/privacy-kids-compliance.md | — |
| 6 | Audio & Voice | Audio | MVP | Not Started | design/gdd/audio-voice.md | Key Table & Theme Data |
| 7 | Press Queue | Gameplay | MVP | Not Started | design/gdd/press-queue.md | Input & Key Filter |
| 8 | Cast Rendering (inferred) | Presentation | MVP | Not Started | design/gdd/cast-rendering.md | Key Table & Theme Data, MorphCore |
| 9 | Reveal Stage | Gameplay | MVP | Not Started | design/gdd/reveal-stage.md | MorphCore, Audio & Voice, Press Queue, Cast Rendering, Key Table & Theme Data |
| 10 | Hint Letters | Gameplay | MVP | Not Started | design/gdd/hint-letters.md | Key Table & Theme Data, Input & Key Filter, Press Queue |
| 11 | Parade | Gameplay | MVP | Not Started | design/gdd/parade.md | Reveal Stage, Cast Rendering |
| 12 | Parent Gate & Grown-up Panel | UI | MVP | Not Started | design/gdd/parent-gate-panel.md | Settings Store, Input & Key Filter |
| 13 | Child Lock-in | Platform | MVP | Not Started | design/gdd/child-lock-in.md | Input & Key Filter, Parent Gate & Grown-up Panel |
| 14 | App Shell & Title (inferred) | Presentation | MVP | Not Started | design/gdd/app-shell-title.md | Reveal Stage, Settings Store |
| 15 | Scene: Time of Day & Weather | Presentation | Vertical Slice | Not Started | design/gdd/scene-time-weather.md | Settings Store |
| 16 | On-screen Keyboard Row | UI | Vertical Slice | Not Started | design/gdd/onscreen-keyboard-row.md | Input & Key Filter, Press Queue, Settings Store |
| 17 | Accessibility | Meta | Vertical Slice | Not Started | design/gdd/accessibility.md | MorphCore, Reveal Stage, Scene: Time of Day & Weather, Hint Letters, Parade |
| 18 | Theme Packs | Content | Alpha | Not Started | design/gdd/theme-packs.md | Key Table & Theme Data, Parent Gate & Grown-up Panel |
| 19 | Localization (inferred) | Meta | Alpha | Not Started | design/gdd/localization.md | Audio & Voice, Key Table & Theme Data |
| 20 | Mash World | Gameplay | Full Vision | Not Started | design/gdd/mash-world.md | Reveal Stage, Cast Rendering, Scene: Time of Day & Weather |

---

## Categories

| Category | Description | Systems here |
|----------|-------------|--------------|
| **Core** | Foundation systems everything depends on | Input & Key Filter, MorphCore |
| **Data** | The key/theme content model (custom) | Key Table & Theme Data |
| **Gameplay** | The systems that make the toy delightful | Press Queue, Reveal Stage, Hint Letters, Parade, Mash World |
| **Persistence** | What stays on the device | Settings Store |
| **UI** | Player- and grown-up-facing screens | Parent Gate & Grown-up Panel, On-screen Keyboard Row |
| **Audio** | Sound and voice | Audio & Voice |
| **Presentation** | Drawing and the stage (custom) | Cast Rendering, Scene: Time of Day & Weather, App Shell & Title |
| **Platform** | OS-level safety (custom) | Child Lock-in |
| **Content** | Themes beyond the first (custom) | Theme Packs |
| **Meta** | Outside the core loop | Privacy & Kids Compliance, Accessibility, Localization |

Progression and Economy do not apply: there are no scores, levels, unlocks or currency (anti-pillars).
Narrative does not apply.

---

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|------|------------|------------------|----------------|
| **MVP** | Required for the core loop to function. Without these, you can't test "is this fun?" | First playable native build (~1 week, concept MVP) | Design FIRST |
| **Vertical Slice** | Required for one complete, polished area. Demonstrates the full experience. | Vertical slice / demo | Design SECOND |
| **Alpha** | All features present in rough form. Complete mechanical scope, placeholder content OK. | Alpha milestone | Design THIRD |
| **Full Vision** | Polish, edge cases, nice-to-haves, and content-complete features. | Beta / Release | Design as needed |

**Why each tier** (Luan approved, 2026-11-17):
- **MVP (14):** the 30-second loop cannot run without Key Table, Input, MorphCore, Audio, Press
  Queue, Reveal Stage and Cast Rendering (Pillars 1 and 2). Hint Letters are how a touch-only child
  reaches letters when the keyboard row is off. The Parade is Luan's favourite moment (Keep). Child
  Lock-in answers the worst moment of the browser playtest (shortcuts stealing focus). Settings
  Store, the Parent Gate and Privacy & Kids Compliance carry Pillar 5. App Shell is the minimum
  wrapper.
- **Vertical Slice (3):** the MVP runs on the fixed dusk look; time of day and weather, the optional
  keyboard row and Reduce Motion complete the experience.
- **Alpha (2):** more themes (concept Tier 1) and a second voice language (K-02).
- **Full Vision (1):** Mash World (concept Tier 2).

> **Scope note:** 14 MVP systems against a ~1-week MVP is dense, though most are small. Luan chose
> one GDD per system (2026-11-17). PR-SCOPE skipped — Lean mode.

---

## Dependency Map

### Foundation Layer (no dependencies)

1. Key Table & Theme Data — every other content-facing system reads it; the K-07 database lives here.
2. Input & Key Filter — the only door for a press (screen, hardware key, optional keyboard row).
3. MorphCore — UI-free maths with a cross-platform contract (morph contract v1).
4. Settings Store (inferred) — device-only storage of the grown-up's choices.
5. Privacy & Kids Compliance (inferred) — a constraint every build satisfies (no network, no SDKs).

### Core Layer (depends on foundation)

1. Audio & Voice — depends on: Key Table & Theme Data
2. Press Queue — depends on: Input & Key Filter
3. Cast Rendering (inferred) — depends on: Key Table & Theme Data, MorphCore (silhouettes)
4. Scene: Time of Day & Weather — depends on: Settings Store

### Feature Layer (depends on core)

1. Reveal Stage — depends on: MorphCore, Audio & Voice, Press Queue, Cast Rendering, Key Table & Theme Data
2. Hint Letters — depends on: Key Table & Theme Data, Input & Key Filter, Press Queue
3. Parade — depends on: Reveal Stage, Cast Rendering
4. Parent Gate & Grown-up Panel — depends on: Settings Store, Input & Key Filter
5. Child Lock-in — depends on: Input & Key Filter, Parent Gate & Grown-up Panel
6. On-screen Keyboard Row — depends on: Input & Key Filter, Press Queue, Settings Store

### Presentation Layer (depends on features)

1. App Shell & Title (inferred) — depends on: Reveal Stage, Settings Store

### Polish Layer (depends on everything)

1. Accessibility — depends on: MorphCore, Reveal Stage, Scene: Time of Day & Weather, Hint Letters, Parade
2. Theme Packs — depends on: Key Table & Theme Data, Parent Gate & Grown-up Panel
3. Localization (inferred) — depends on: Audio & Voice, Key Table & Theme Data
4. Mash World — depends on: Reveal Stage, Cast Rendering, Scene: Time of Day & Weather

**Bottlenecks** (many dependents, highest risk): Key Table & Theme Data, MorphCore, Press Queue,
Reveal Stage. **Leaves** (no dependents, can be designed late): Child Lock-in, App Shell, Parade,
Accessibility, Localization, Mash World.

TD-SYSTEM-BOUNDARY skipped — Lean mode.

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | Key Table & Theme Data | MVP | Foundation | game-designer, systems-designer | M |
| 2 | Input & Key Filter | MVP | Foundation | game-designer, ux-designer | S |
| 3 | MorphCore | MVP | Foundation | systems-designer, technical-artist | M |
| 4 | Settings Store | MVP | Foundation | systems-designer | S |
| 5 | Privacy & Kids Compliance | MVP | Foundation | security-engineer, release-manager | S |
| 6 | Audio & Voice | MVP | Core | audio-director, sound-designer | M |
| 7 | Press Queue | MVP | Core | game-designer, systems-designer | S |
| 8 | Cast Rendering | MVP | Core | technical-artist, art-director | M |
| 9 | Reveal Stage | MVP | Feature | game-designer | M |
| 10 | Hint Letters | MVP | Feature | game-designer, ux-designer | S |
| 11 | Parade | MVP | Feature | game-designer, art-director | S |
| 12 | Parent Gate & Grown-up Panel | MVP | Feature | ux-designer | S |
| 13 | Child Lock-in | MVP | Feature | ux-designer, security-engineer | S |
| 14 | App Shell & Title | MVP | Presentation | ux-designer | S |
| 15 | Scene: Time of Day & Weather | Vertical Slice | Core | art-director, technical-artist | M |
| 16 | On-screen Keyboard Row | Vertical Slice | Feature | ux-designer | S |
| 17 | Accessibility | Vertical Slice | Polish | accessibility-specialist | S |
| 18 | Theme Packs | Alpha | Polish | game-designer, art-director | M |
| 19 | Localization | Alpha | Polish | localization-lead, audio-director | S |
| 20 | Mash World | Full Vision | Polish | game-designer | M |

Effort: S = 1 session, M = 2–3 sessions.

---

## Circular Dependencies

- **Press Queue <-> Reveal Stage:** the queue starts a reveal, and the reveal's timing decides when
  the queue may advance. Resolution: the Press Queue owns the timing (the hold time is data) and the
  Reveal Stage only reports a "formed" event; design the two together, with that contract named in
  both GDDs.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| Key Table & Theme Data | Scope | 26 cast members + 10 numbers per theme, each with art, silhouette, sound and voice; production wants several per key (K-07) | Fixed one-per-key for the MVP; database schema designed for variety from day one |
| MorphCore | Technical | Cross-platform exactness; art tools exporting SVG the subset can't parse | Morph contract v1 + shared fixtures (TASK-035); a bake tool that fails loudly |
| Cast Rendering | Technical | SVG rendering path unproven in SpriteKit (live vector vs PNG tiers) | Later ADR backed by a real-iPad measurement (art bible §8) |
| Child Lock-in | Technical | ⌘Tab, Mission Control, Globe and iPad shortcuts under Guided Access are NOT ASSESSED | Physical-keyboard checks on a real Mac and iPad before release |
| Privacy & Kids Compliance | Scope | Kids category / COPPA rules; macOS Kids category applicability not verified | TASK-034 findings; Luan's legal calls; build checks (no network, privacy manifest) |
| Audio & Voice | Technical | Press-to-sound latency on a real iPad not measured; recorded voice not sourced | TASK-033 iPad procedure; voice sourcing decision |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 20 |
| Design docs started | 6 |
| Design docs reviewed | 4 |
| Design docs approved | 4 |
| MVP systems designed | 4/14 |
| Vertical Slice systems designed | 0/3 |

---

## Next Steps

- [ ] Review and approve this systems enumeration
- [ ] Design MVP-tier systems first (use `/design-system [system-name]`)
- [ ] Run `/design-review` on each completed GDD
- [ ] Run `/gate-check systems-design` to leave the Concept stage
- [ ] Run `/gate-check technical-setup` when MVP systems are designed
- [ ] Validate the highest-risk systems with `/vertical-slice` before committing to Production
