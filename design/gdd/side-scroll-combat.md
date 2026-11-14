# Side-scroll Movement & Combat

> **Status**: Approved (peer review: game-dev-ios, 2026-11-14)
> **Author**: game-art-content (Luan decides)
> **Last Updated**: 2026-11-14
> **Last Verified**: 2026-11-14
> **Implements Pillar**: Nhỏ chơi được (Small hands can do it), An toàn cho trẻ (Safe for kids), Sống lại câu chuyện (Live the story)
> **Task**: TASK-008 · Tier: standard (Player Fantasy and Tuning Knobs skipped by tier; values live in `content/data/tuning.json`)

## Summary

The hero moves left and right, swings a blunt staff and holds a shield. A few slow enemies take
turns: each one glows and shows "!" before it strikes. A held shield always blocks. A hit enemy
is knocked back. After a few hits it drops its weapon and runs home. Nobody is hurt or dies, and
the hero has no health.

> **Quick reference** — Layer: `Core` · Priority: `Vertical Slice` · Key deps: `Input & touch controls, Content data & claims` · Used by: `Mission flow & beat types`

## Overview

Combat is how a child takes part in the story's battle moments.

- **Beats it runs:** the `fight` beat and the enemy encounters inside `reach-the-flag` (Mission
  flow). It also provides hero movement for `walk` and `training`.
- **Why it is forgiving by design:**
  - enemies attack one at a time;
  - every attack is telegraphed for over a second;
  - holding defend always blocks it;
  - an unblocked hit only pushes the hero back a step.
- **Where the challenge lives:** in reading the "!" and choosing to block or swing, and in the
  stars from the quiz, never in failing (*Small hands can do it*).
- **No injury:** defeat is shown by knock-back, a dropped weapon and running home. It is never
  injury (*Safe for kids*, art bible §3).
- **Source of the values:** every value comes from the TASK-003 browser prototype (`203d73e`),
  where it was played on an Android emulator through QC round r3.

## Detailed Design

### Core Rules

**Hero**

1. **Move.** Holding ◀ or ▶ moves the hero at `hero_speed`. Releasing stops at once, with no
   sliding. The hero faces the last direction moved.
2. **Attack.** Tapping attack starts a swing lasting `attack_time`.
   - The hit is checked once, at `attack_hit_at` (45%) of the swing.
   - A new swing can start after `attack_cooldown`.
   - Moving during a swing is slowed to `attack_move_mul` (40%) of `hero_speed`.
   - Pads fire on press (P-01).
   - **Auto-face (G2):** when a swing starts, the hero first turns to face the **nearest
     non-fleeing enemy**. Only enemies count, never training dummies or the practice partner.
     On a tie, or with no enemy present, the hero keeps the current facing.
   - **Facing locked during a swing (G2, rule 2b):** while a swing is active, move input still
     moves the hero (× `attack_move_mul`) but **doesn't change facing**. Facing follows the move
     direction again once the swing ends.
3. **Hit test.** A swing hits **every** non-fleeing enemy that is either in front of the hero
   within `attack_range`, or closer than `attack_close_range` on either side (F5). One swing can
   hit two enemies.
4. **Defend.** While defend is held, the hero raises the shield. The hero can't move or attack
   while defending: one action at a time, readable for a child. An attack tap while defending
   is **dropped, not queued**: releasing defend does not start a late swing. Defend doesn't
   count as held while a caption is showing.
5. **No health.** The hero has no health, lives or energy. An unblocked strike:
   - pushes the hero back by `hero_pushback`, away from the striker;
   - flashes the hero for `hurt_time`;
   - shows "Ối! / Oof!".

   The child keeps full control during the flash.

**Enemies**

6. **Kinds.**

| Kind | Hits to run away | Speed | Knock-back | Telegraph | Look (art bible §3, §5) |
|---|---|---|---|---|---|
| `spear` | `hp_spear` (2) | `enemy_speed` | `knockback` | `telegraph` | Dome helmet with knob, padded spear |
| `shield` | `hp_shield` (3) | `enemy_speed` | `knockback` | `telegraph` | Dome helmet, tall shield |
| `leader` | `hp_leader` (3) | × `leader_speed_mul` (0.75) | × `leader_knock_mul` (0.5) | × `leader_telegraph_mul` (1.2) | Wider, never taller than the hero, padded club |

7. **Spawning.** A fight's `enemies` list walks in, in order.
   - Each enemy starts `spawn_offset` past the screen edge (the left edge for indexes in
     `from_left`, otherwise the right).
   - The first walk-in waits `first_spawn_delay` (0.4 s) after the fight starts. Then
     enemies come one per `spawn_gap`, never more than `max_active` on screen.
   - Fleeing enemies don't count toward `max_active`.
8. **Queueing.** On each side of the hero, enemies line up by distance.
   - The nearest stands at `enemy_reach − stand_gap`.
   - The others wait `queue_spacing` further back each.
9. **One strike at a time.** An enemy may start a windup only when all of these hold:
   - it is the nearest on its side;
   - it is within `enemy_reach + windup_reach_extra`;
   - it has been approaching for **more than** `approach_min_time` (strictly greater). On
     leaving `rest`, its approach timer starts already at `approach_min_time`, so it may wind
     up again from the next frame;
   - **no other enemy anywhere is in windup or strike**.
10. **Telegraph.** In windup, the enemy glows and shows a "!" for `telegraph` seconds (× 1.2 for
    the leader). At the end it strikes.
    - The strike lands if the hero is within `enemy_reach + strike_reach_extra`.
    - If defend is held **at that instant** (the frame the strike resolves), the strike is
      **blocked**. Pressing and releasing defend earlier in the windup does not block: the enemy is knocked back
      by `block_knock`, and the game shows "Đỡ được! / Blocked!" with a clang.
    - Otherwise the hero is pushed (rule 5).
11. **Getting hit.** A hit enemy is knocked back by its knock-back distance, played out over
    `kb_decay` (F4), and goes to `hurt` for `hurt_recover` (0.35 s, P-03). **Hitting an
    enemy in windup cancels its strike.**
12. **Running away.** When an enemy's hits reach its kind's count, it drops its weapon (the
    weapon stays on the ground and fades) and runs away from the hero at `flee_speed`. It is
    removed once `flee_remove_margin` px past the screen edge. It never comes back.
13. **Fight end.** A fight's goal is met when its queue is empty and no enemy is on screen,
    fleeing ones included. Mission flow then runs `end_pause`.

**Camera and space**

14. **Free scroll** (`walk`, `reach-the-flag` outside encounters): the camera
    follows the hero, keeping it `camera_follow_offset` px from the left edge. It never scrolls back
    left. The hero can't walk off the left edge (`hero_edge_margin`).
15. **Locked fight.** A `fight` beat, and each encounter in `reach-the-flag` (D-06), locks the
    camera with the hero at `lock_offset` px from the left edge.
    - **Fight-zone bounds (G2):** until the fight ends, the hero is clamped to
      [`lockX + enemy_reach + hero_edge_margin`, `lockX + W − enemy_reach − hero_edge_margin`],
      which is [220, 1060] with today's tuning. A front enemy's stand point (`enemy_reach −
      stand_gap` away) is then always on screen, on either side. These bounds are derived, so
      there's no new tuning key.
    - Outside locked fights, the bounds are `hero_edge_margin` from the left edge only, as before.
15b. **Capped camera in training** (TASK-020a; iOS QC r3, confirmed on Android by a bot test;
    game-dev-android's review). From a `training` beat's `beat_play` start until `beat_end`
    (through the dummies, blocks and finish steps), the camera keeps following right as in Rule
    14, but **never goes past a cap**:
    - `lockX = max(camera, xStart − hero_edge_margin)`, fixed at `beat_play` start; the camera
      is `min(follow, lockX)` and still never moves left;
    - the hero's right limit is `lockX + W − enemy_reach − hero_edge_margin`; the left limit
      stays `camera + hero_edge_margin` (Rule 14);
    - no jump and no snap: the camera only stops following, and the hero is only stopped, never
      moved. No new tuning key.
    - **Worked example (TQT, `tuning.json` defaults: W 1280, `hero_edge_margin` 70,
      `enemy_reach` 150, `camera_follow_offset` 460):** lockX = xStart − 70. The camera reaches
      it when the hero is at xStart + 390, then stops. The hero is limited to xStart … xStart +
      990. The dummies at xStart + 300, 600, 900 are inside, and the partner stays on screen.
    - **Data guard (R14b, Mission flow Rule 7c):** `dummies × dummy_spacing ≤ W − enemy_reach −
      2 × hero_edge_margin` (990 today), so the last dummy is always inside the zone.
    - Why: under free scroll a child holding ▶ walked past the dummies; the camera never scrolls
      left, so after about 3 s of ▶ the first dummy was unreachable and after 5 s none were, and
      training could never end (a softlock on both apps).
    - Why: before this rule, a child holding ▶ ended up at the right edge facing away, with a
      right-side enemy standing off-screen. The reach-the-flag beat couldn't be finished by
      touch (Android QC r2, G2: 280–410 s; measured unfinishable within 900 s).
16. **Special in combat: not now** (D-10: B, Luan 2026-11-14). Fights and reach-the-flag
    encounters have no special pad. The rules below are kept for a later version, so the design
    isn't lost; `special_push` and `special_cooldown` stay in `tuning.json` unused:
    - Tapping special waves the banner: followers cheer, and every non-fleeing enemy on screen
      is pushed by `special_push` **away from the hero**, on both sides.
    - It does **not** count as a hit, so special never ends a fight by itself.
    - Cooldown is `special_cooldown`. During cooldown the special pad shows a draining ring and
      a tap plays a soft sound. There is no "not ready" text.

**World layout** (`ground_y`, `hero_start_x`, `beat_start_x`, `beat_gap` in `tuning.json`)
belongs to Mission flow (`design/gdd/mission-flow.md`, Core Rule 2; beat positions are
`beatX(i)`, Mission flow F5). This system only reads it.

### Frame order

One fixed step, dt = 1/60, in this order. It is the prototype's `updatePlay` / `updateEnemies`
(`203d73e`), agreed by game-dev-ios and game-dev-android. Both apps must follow it, because the
same-frame edge cases below depend on it.

1. Read input. Defend counts as held only while not in a caption.
2. Update the hero's timers: attack cooldown, hurt flash.
3. Advance the current swing (`atk += dt / attack_time`). When it crosses `attack_hit_at`, run
   the hit check (F5) once. When it reaches 1, the swing ends and `attack_cooldown` starts.
4. Start a new swing if attack was tapped and the hero is not defending, not swinging and has
   no cooldown. Otherwise the tap is dropped. **When a swing starts, the hero auto-faces the
   nearest non-fleeing enemy** (Rule 2). A new swing first advances on the **next** step.
5. Move the hero (× `attack_move_mul` while swinging; no move while defending). **While a swing
   is active, movement doesn't change facing** (Rule 2, 2b).
6. Clamp the hero (**to the fight-zone bounds while locked**, Rules 15, 15b) and set the camera (locked
   during a fight and a caption; capped in training, Rule 15b; otherwise
   `camera = max(camera, hero.x − camera_follow_offset)`).
7. Start the beat once the hero passes `beatX(i)` (Mission flow F5: each beat's start adds the
   previous beat's extent plus `beat_gap`, not `i × beat_gap`).
8. In a fight: the spawn timer advances by dt (the stall timer is Hints' `progress_timer`; see
   below). Spawn at most one enemy if the
   queue isn't empty, active (non-fleeing) < `max_active` and the spawn timer ≤ 0. The timer
   then resets to `spawn_gap`.
9. For each enemy, in list order:
   1. its timer += dt;
   2. its knock-back step (F4);
   3. side, rank and stand distance;
   4. its state switch. Windup → strike resolves here, and block is checked only at this
      instant (F6).
10. Remove enemies that fled past the locked screen ± `flee_remove_margin`.
11. Fight end: when the queue and the enemy list are both empty, Combat reports goal-met; the end
    timer advances in this step, and Mission flow owns `end_pause` and what follows it (the
    caption; Mission flow Rule 2, TASK-020 A5).
12. Effects: particles, floating words, dropped weapons.

Combat only **reports events** (hit, block, pushed, windup, flee). The no-progress timer, its
resets (on progress, caption or card close, and resume) and `hint_delay` belong to Hints
(`design/gdd/hints-and-onboarding.md`, Rule 5 and F1).

### States and Transitions

**Enemy** (state names from the prototype):

| State | Does | Leaves to | When |
|---|---|---|---|
| `enter` | Walks in from off-screen at `enter_speed` | `approach` | Within `enter_to_approach_dist` (260 px) of its stand point |
| `approach` | Walks to its queue stand point at `enemy_speed`; it uses `enter_speed` while still farther than 260 px | `windup` / `hurt` / `flee` | Rule 9 / hit / last hit |
| `windup` | Glows and shows "!" for the telegraph time | `strike` / `hurt` / `flee` | Telegraph elapsed / hit (strike cancelled) / last hit |
| `strike` | The strike resolves on entry (block or push), then lasts `strike_time` | `rest` / `hurt` / `flee` | Elapsed / hit / last hit |
| `rest` | Drifts to its stand point at `rest_speed_mul` × speed | `approach` (with `approach_min_time` already counted) / `hurt` / `flee` | `enemy_rest` elapsed / hit / last hit |
| `hurt` | Knocked back, leans, dizzy | `approach` / `flee` | `hurt_recover` elapsed / last hit |
| `flee` | Runs away, weapon dropped | removed | `flee_remove_margin` px past the screen edge |

**Hero:** `idle` ⇄ `walk` · `attack` (it can walk slowly) · `defend` (no move or attack) ·
`pushed` (a flash overlay on any state, with no loss of control).

### Interactions with Other Systems

| System | In | Out | Owner |
|---|---|---|---|
| Mission flow & beat types | beat type, fight params (`enemies`, `max_active`, `from_left`), encounters (D-06), the visible pads | goal met (fight cleared, flag touched, walk end reached) | Mission flow GDD |
| Input & touch controls | press, hold and release of move, attack, defend, special | (none) | Input GDD (P-01: pads fire on press) |
| Content data | `content/data/tuning.json` values; enemy kinds from `mission.schema.json` | (none) | Content contract |
| Hints & onboarding | (none) | events: `hit`, `block`, `pushed`, `flee`, `windup_started`, hero moved. Hints computes "no progress" itself | Hints GDD |
| Audio & voice-over | (none) | events for SFX: swing, hit drum, clang, bonk, flee, enemy windup (`sfx_enemy_windup`), enemy strike (`sfx_enemy_strike`) (Audio Rule 5) | Audio GDD |

## Formulas

The F1 (enemy strike cycle) formula is defined as:

`T_cycle = telegraph × m_kind + strike_time + enemy_rest`

`approach_min_time` applies only to an enemy's first approach (and after `hurt`). After `rest`, the prototype counts it as already passed, so it is not part of the repeating cycle.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| telegraph | float (s) | 0.4–2.5 | data file (`telegraph`, 1.1) | Warning time before a strike |
| m_kind | float | 1 (spear, shield) / 1.2 (leader) | data file (`leader_telegraph_mul`, 0.5–2) | Leader telegraphs longer |
| strike_time | float (s) | 0.1–0.6 | data file (0.25) | The strike itself |
| enemy_rest | float (s) | 0.4–4 | data file (1.6) | Pause after a strike |

**Output Range:** 0.9–7.6 s at the schema bounds. The default is 2.95 s (spear, shield) or
3.17 s (leader). With one strike at a time, the hero faces at most one strike per T_cycle. At
the minimum (0.4 + 0.1 + 0.4 = 0.9 s) a 6-year-old can't react, so **telegraph must stay
≥ 0.8 s** (see Edge Cases).
**Example:** spear 1.1 × 1 + 0.25 + 1.6 = 2.95 s; leader 1.1 × 1.2 + 0.25 + 1.6 = 3.17 s.

The F2 (hits to clear a fight) formula is defined as:

`H = Σ_enemies hp_kind`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| hp_kind | int | spear 1–6, shield 1–8, leader 1–12 | data file (2, 3, 3) | Hits before that kind runs away |
| enemies | list | 1–8 | data file (beat params) | The fight's walk-in list |

**Output Range:** 1–96 at the bounds. Design target per fight: 4–10.
**Example:** the prototype's beat 3 is shield, spear, shield, spear: 3 + 2 + 3 + 2 = 10 hits.

The F3 (fastest fight time) formula is defined as:

`T_fight_min = H × (attack_time + attack_cooldown) + (n − 1) × spawn_gap + T_enter`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| H | int | from F2 | calculated | Hits needed |
| attack_time, attack_cooldown | float (s) | 0.12–0.6, 0–0.6 | data file (0.28, 0.12) | One swing plus its gap |
| n | int | 1–8 | data file (enemy count) | Enemies in the fight |
| spawn_gap | float (s) | 0.2–4 | data file (1.0) | Time between walk-ins |
| T_enter | float (s) | ~1–2 | calculated: (spawn_offset + distance) / enter_speed | First enemy walking in |

**Output Range:** the lower bound only. A child blocking and missing takes 2–4× this. The target
for a child is 20–60 s per fight ⟨tuning: confirm in the vertical-slice playtest⟩.
**Example:** beat 3: 10 × 0.4 + 3 × 1.0 + 1.5 = 8.5 s minimum, and about 20–35 s for a child.

The F4 (knock-back) formula is defined as:

`kb_0 = knockback × k_kind`; each frame `step = kb × min(1, dt / kb_decay)`, `x += step`, `kb −= step`, and `kb = 0` once `|kb| < 2 px`.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| knockback | float (px) | 40–400 | data file (170) | Push on a hit |
| k_kind | float | 1 / 0.5 (leader) | data file (`leader_knock_mul`) | Leader is heavier |
| kb_decay | float (s) | 0.05–1 | data file (0.25) | How fast the push plays out |
| dt | float (s) | frame time | engine | Frame step |

**Output Range:** total push = kb_0 (it converges), so 170 px for spear and shield and 85 px
for the leader. About 95% plays out within 3 × kb_decay (0.75 s) at 60 fps. With
`dt ≥ kb_decay` (a frame hitch) the whole push applies in one frame, which is visible but
harmless.
**Example:** spear hit: 170 px, mostly within 0.75 s.

The F5 (attack hit test) formula is defined as:

`hits(e) = e.state ≠ flee ∧ ((sign(dx) = face ∧ |dx| ≤ attack_range) ∨ |dx| < attack_close_range)`, where `dx = e.x − hero.x`, checked once at `attack_hit_at × attack_time` after the press.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| attack_range | float (px) | 80–300 | data file (175) | Reach in front |
| attack_close_range | float (px) | 0–120 | data file (50) | Hits even behind, when overlapping |
| attack_hit_at | float | 0.1–0.9 | data file (0.45) | When in the swing the hit lands |

**Output Range:** boolean per enemy. The hit lands 0.126 s after the press (0.45 × 0.28).
`attack_range` (175) must stay ≥ `enemy_reach − stand_gap` (140), or a front enemy at its stand
point can't be hit. That is a coupling, so both rows say so in `tuning.json`.
**Example:** an enemy at dx = +150 with the hero facing right: hit. At dx = −40: hit
(close). At dx = −150: miss.

The F6 (block) formula is defined as:

`blocked = defend_held(at strike start) ∧ |dx| ≤ enemy_reach + strike_reach_extra`; if not blocked and in range, the hero is pushed by `hero_pushback`.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| enemy_reach | float (px) | 80–260 | data file (150) | Strike distance |
| strike_reach_extra | float (px) | 0–120 | data file (40) | Grace past reach |
| hero_pushback | float (px) | 0–250 | data file (90) | Push on an unblocked hit |
| block_knock | float (px) | 0–200 | data file (70) | Push on the enemy when blocked |

**Output Range:** boolean. Only the frame the strike resolves counts: defend held then
blocks, and defend pressed and released earlier in the windup does not. The habit taught is
"hold the shield from the '!' until the strike". The 1.1 s telegraph makes that easy for ages
6–10.
**Example:** the hero holds defend 0.3 s into a 1.1 s windup and keeps holding: blocked.

## Edge Cases

- **If `telegraph` is set below 0.8 s**: validation warns (R15), because the strike becomes hard to
  react to for a 6-year-old (F1). The schema allows 0.4, but content should not go below 0.8.
- **If `attack_range` < `enemy_reach − stand_gap`**: validation fails (R14). The front enemy stands
  out of reach and the fight could never end.
- **If the child holds defend forever**: no enemy is ever hit, so the fight doesn't end. After
  `hint_delay` of no hit while enemies are present, Hints shows the attack hint. There is no
  timeout and no penalty.
- **If the child spams attack**: one swing per `attack_time + attack_cooldown` (0.4 s), and
  the extra taps are ignored. Spamming is a valid way to win. Blocking is never required,
  because an unblocked strike costs only a step back. This is intended: the "!" teaches
  defending without forcing it.
- **If the hero stands between enemies on both sides**: only one strike at a time (rule 9),
  so the hero is never hit from both sides at once.
- **If an enemy is hit during windup**: its strike is cancelled, and it goes to `hurt`, then
  `approach`, and its telegraph starts again later.
- **If the hero's hit lands in the same frame an enemy's windup would end**: the hero's hit
  check (frame step 3) runs before enemies update (step 9). The enemy goes to `hurt` first, so
  **its strike is cancelled**, and nothing is blocked or pushed that frame.
- **If attack is tapped in the same frame defend is released**: step 1 reads defend as not held,
  so the swing starts (step 4). If defend is still held that frame, the tap is dropped.
- **If the hit check and a move happen in the same frame**: the hit check uses the hero's
  position before this frame's move (step 3 before step 5).
- **If an enemy's knock-back and a strike happen in the same frame**: knock-back moves it first
  (step 9.2), then the strike's range check (step 9.4) uses the new position, so a far-knocked
  enemy can miss.
- **If a swing hits the last enemy and another is still queued**: the queued enemy spawns
  after `spawn_gap`. The fight ends only when the queue is empty and the screen is clear.
- **If a child holds ▶ from the start of training**: the camera follows until its cap
  (Rule 15b), then stops; the hero stops at xStart + 990 (TQT) with every dummy and the partner
  still on screen and reachable by walking back left.
- **If the hero is pushed into the locked-camera edge**: the position is clamped at
  `hero_edge_margin`, and the push stops there. No damage.
- **If knock-back pushes an enemy off-screen** (not fleeing): it walks back from where it is.
  It is not removed.
- **If two enemies overlap the hero** (close range): one swing hits both (F5).
- **If the app is paused mid-windup**: all timers freeze, and pause releases every held pad
  (Mission flow Rule 11). On resume, the windup's telegraph **restarts from 0**, so the child
  always gets the full warning to press defend again. This is new versus the prototype.
- **If `max_active` is larger than the enemy count**: everyone spawns, one per `spawn_gap`.
- **If special is tapped during cooldown** (later version only, Rule 16): nothing happens, and a
  soft sound plays with the draining ring on the pad. There is no text.

## Dependencies

| System | Direction | Hard/Soft | Interface |
|---|---|---|---|
| Input & touch controls | this depends on it | Hard | Pad press, hold and release (P-01: on press) |
| Content data & claims | this depends on it | Hard | `tuning.json`; enemy kinds in `mission.schema.json` |
| Mission flow & beat types | depends on this | Hard | Runs fights and encounters; goal-met events |
| Hints & onboarding | depends on this | Soft | Combat events (hit, block, pushed, windup, flee, hero moved) |
| Audio & voice-over | depends on this | Soft | SFX events, including windup and strike (Audio Rule 5) |

Mission flow lists this system as a hard dependency (`design/gdd/mission-flow.md`, bidirectional).

## Visual/Audio Requirements

Art-director lens (art bible §§3–5):
- **Telegraph:** a pulsing glow ring plus a "!" bubble over the enemy, visible at thumbnail size.
  It is yellow-gold, never red (§4: red never reads as threat or blood here).
- **Hit:** the enemy leans back, with a soft spark burst in the colour of the staff's wood, and
  its helmet wobbles. No impact marks or injury frames (§3).
- **Block:** a white spark between the shield and the weapon, "Đỡ được! / Blocked!" as a text
  pop (a text layer), and a clang.
- **Pushed:** the hero flashes and "Ối! / Oof!" pops. No pain face: surprise only (§5).
- **Run away:** the weapon drops and stays on the ground fading, and the enemy runs with
  flailing arms and a dizzy swirl. There is no lying-down pose for anyone (§5).
- **Leader:** wider, not taller, than the hero (§3; QC rework at TASK-003).
- **Audio:** swing swoosh, drum on a hit, clang on a block, soft bonk when pushed, a light
  "run away" jingle on flee, and drums for fight music (Audio GDD).

📌 **Asset Spec**: after approval, run `/asset-spec system:side-scroll-combat` for the hero
animation set (art bible §5), the three enemy kinds with all 7 states, the telegraph ring, sparks
and dropped weapons.

## Game Feel

- **Response:** a pad press acts on the next frame. The swing starts at once and the hit lands at
  0.126 s, which reads as instant to a child.
- **Weight:** the knock-back plays out over about 0.75 s (F4), so a hit visibly "does
  something". The leader moves half as far, so it feels heavier.
- **Readability over speed:** a 1.1 s telegraph and one strike at a time. Moving at 40% during
  a swing keeps the hero from sliding through enemies.
- **No hit-stop** in the vertical slice (the prototype had none). Revisit after the playtest if
  hits feel weak.
- **Feel checks** are QC per platform, not fixtures (`content/README.md`).

## UI Requirements

- Pads: ◀ ▶ bottom-left; defend and attack bottom-right. No special pad in combat (D-10); in the later version, special goes above attack when the beat
  uses it. At least `pad_min` (72 pt/dp), clear of the system gesture zones (QC r3 O5).
- Text pops ("Ối!", "Đỡ được!") come from `strings.json` (VI/EN), never from art.
- No health bar and no enemy health bars. Progress is the enemies running away.

📌 **UX Flag — Side-scroll Combat**: the mission HUD and pad layout go in `/ux-design` with
Mission flow's screens.

## Cross-References

| This doc references | Where | What |
|---|---|---|
| Mission flow & beat types | `design/gdd/mission-flow.md` | Beat types, goal events, `end_pause`, D-06 encounters |
| Content data contract | `content/data/tuning.json`, `content/schema/mission.schema.json`, `content/README.md` | All values; enemy kinds; feel is QC, not fixtures |
| Art bible | `design/art/art-bible.md` §§3–5 | Enemy shapes, no injury, leader width, telegraph colour |
| Prototype | `203d73e` `prototypes/tqt-mission/index.html` (`updateEnemies`, `heroAttack`, `updatePlay`) | State machine, hidden literals, behaviour |
| QC evidence | `qa/TASK-003-android` r3 (O5 pads clear of the gesture zone, O6 one tone per press) | Pad placement, input |
| Decisions | `production/team/decisions.md` P-01, P-03, D-06, D-09, D-10 | Press timing, hurt 0.35 s, encounters, tuning keys, no special in combat |

## Acceptance Criteria

1. **GIVEN** a spear enemy (`hp_spear` 2) in range, **WHEN** the hero lands 2 swings,
   **THEN** after the first it is `hurt` for 0.35 s, and after the second it is `flee` with its
   weapon on the ground.
2. **GIVEN** a fight with `max_active` 2 and 4 enemies, **WHEN** play runs, **THEN** never more
   than 2 non-fleeing enemies are on screen, and walk-ins are ≥ `spawn_gap` (1.0 s) apart.
3. **GIVEN** two enemies at their stand points on opposite sides, **WHEN** both could strike,
   **THEN** at no frame are two enemies in `windup` or `strike` together.
4. **GIVEN** an enemy in `windup`, **WHEN** 1.1 s pass (1.32 s for the leader), **THEN** it
   enters `strike`. **GIVEN** defend is held at that moment and the hero is within 190 px,
   **THEN** the strike is blocked and the enemy moves 70 px back.
5. **GIVEN** an enemy strikes and defend is not held, **WHEN** the strike resolves, **THEN**
   the hero moves 90 px away from it, flashes for 0.5 s, and can still move and attack during
   the flash.
6. **GIVEN** an enemy in `windup`, **WHEN** the hero hits it, **THEN** no strike happens from
   that windup.
7. **GIVEN** the hero faces right, **WHEN** a swing lands, **THEN** enemies at dx +175 and
   −49 are hit and an enemy at dx −51 is not (F5 boundaries).
8. **GIVEN** a spear hit, **WHEN** the knock-back plays out, **THEN** the enemy ends 170 ± 2 px
   from where it was hit (85 ± 2 px for a leader) (F4).
9. **GIVEN** a fight whose queue is empty, **WHEN** the last enemy is still fleeing on screen,
   **THEN** the goal is not met until it is `flee_remove_margin` past the edge.
10. **GIVEN** defend held, **WHEN** move or attack is pressed, **THEN** the hero neither moves
    nor swings.
11. **GIVEN** `tuning.json` with `attack_range` 130 and `enemy_reach − stand_gap` 140, **WHEN**
    the content is validated, **THEN** validation fails with R14. **GIVEN** `telegraph` 0.7,
    **THEN** validation warns with R15 (both in `content/README.md` and
    `content/fixtures/validity.json`, schema 1.1).
12. **GIVEN** the vertical slice on a phone, **WHEN** the attack pad is pressed, **THEN** the swing
    visibly starts in the next frame (frame-step recording) and the hit spark appears within
    0.15 s.
13. **GIVEN** any enemy state, **WHEN** screenshots of all 7 states are captured, **THEN** none
    shows injury, blood, or a figure lying down (content reviewer sign-off, evidence in
    `production/qa/evidence/`).
14. **GIVEN** the Trần Quốc Toản slice fights, **WHEN** an adult plays without blocking, **THEN**
    each fight still ends (no fail state), within 60 s per fight (combat F3; it keeps Mission
    flow AC14's 3–5 min mission total).
15. **GIVEN** an enemy in `windup`, **WHEN** defend is pressed and released 0.5 s into it and
    not held when the strike resolves, **THEN** the strike is **not** blocked and the hero is
    pushed 90 px.
16. **GIVEN** a fight starts, **WHEN** 0.39 s have passed, **THEN** no enemy has spawned. At
    0.4 s (`first_spawn_delay`), the first enemy spawns.
17. **GIVEN** an enemy whose windup ends on frame N, **WHEN** the hero's swing crosses
    `attack_hit_at` on the same frame N, **THEN** the enemy is `hurt` and no strike, block or
    push happens on frame N (frame order steps 3 → 9).
18. **GIVEN** the hero is defending, **WHEN** attack is tapped and defend released on the next
    frame, **THEN** no swing starts (the tap was dropped, not queued).
19. **GIVEN** an enemy 0.8 s into a 1.1 s windup with defend held, **WHEN** the game is paused
    and resumed, **THEN** defend is no longer held, and the windup lasts another full 1.1 s
    before the strike (the telegraph restarts from 0).
20. **GIVEN** a locked encounter with `tuning.json` defaults, **WHEN** the child holds ▶ the whole
    time, **THEN** the hero's x never exceeds lockX + 1060, and the first enemy is fully on
    screen and in front of the hero.
21. **GIVEN** an enemy on the hero's left and ▶ held, **WHEN** attack is tapped, **THEN** the swing
    faces left and stays facing left until the swing ends, even though ▶ is held (2b).
22. **GIVEN** a training beat with dummies and the partner, **WHEN** attack is tapped, **THEN**
    auto-face ignores them (facing changes only from move input).
23. **GIVEN** the Trần Quốc Toản reach-the-flag beat and the three scripted strategies (hold ▶ and
    tap 2/s; alternate ▶ ½ s and tap; stand still and tap 2/s while an encounter holds the camera, walk ▶ otherwise), **WHEN** each is simulated in the
    core, **THEN** each finishes the beat in **≤ 60 s** (measured: Android 31–39 s, iOS 34–47 s).

24. **GIVEN** the Trần Quốc Toản training beat with `tuning.json` defaults, **WHEN** ▶ is held for
    5 s from `beat_play` start, **THEN** the camera is never beyond xStart − 70 and never
    moves more than one frame's follow step at a time (no jump), the hero's x never exceeds
    xStart + 990 and never snaps, every dummy is still reachable, and a scripted run then
    completes training (3 hits, 3 blocks, special).

Logic criteria 1–11 and 15–24 need automated unit tests that follow the frame order. Feel
criteria 12–14 need a QC recording or screenshot on each platform.

## Open Questions

| # | Question | Owner | By |
|---|---|---|---|
| D-09 | Done: `special_push` and `special_cooldown` are in `tuning.json` (unused until Rule 16 returns); R14 and R15 are in `content/README.md` (schema 1.1) | — | Closed |
| — | Hit-stop: add a short freeze (e.g. 0.05 s) if playtests find hits weak? | Luan, after the vertical-slice playtest | Playtest |
| D-10 | **Decided (Luan, 2026-11-14): B, later.** No special in combat now; Rule 16 kept for a future version | — | Closed |
