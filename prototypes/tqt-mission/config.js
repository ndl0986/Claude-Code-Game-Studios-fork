// PROTOTYPE - NOT FOR PRODUCTION
// Question: Can a 6-year-old play one hero's story as light touch action on a landscape phone, then answer a short quiz about it?
// Date: 2026-11-14 · TASK-003
// Every tuning value lives here, each with value, min, max and step. The game reads them live
// through tune.<name> (index.html); the tweak panel, an add-on, writes them back here.
window.CONFIG = {
  seed: 1, // every gameplay random call reads rng(), seeded from this (or ?seed= in the address)
  volume: { value: 0.5, min: 0, max: 1, step: 0.05 },

  // Hero
  heroSpeed: { value: 330, min: 120, max: 600, step: 10 },       // walk speed, px/s (world is 1280x720)
  attackTime: { value: 0.28, min: 0.12, max: 0.6, step: 0.02 },  // one staff swing, s
  attackCooldown: { value: 0.12, min: 0, max: 0.6, step: 0.02 }, // gap after a swing before the next, s
  attackRange: { value: 175, min: 80, max: 300, step: 5 },       // reach in front of the hero, px
  knockback: { value: 170, min: 40, max: 400, step: 10 },        // how far a hit pushes an enemy, px
  heroPushback: { value: 90, min: 0, max: 250, step: 10 },       // how far an unblocked hit pushes the hero, px
  hurtTime: { value: 0.5, min: 0.1, max: 1.5, step: 0.05 },      // hero flash after an unblocked hit, s (no damage)

  // Enemies (forgiving on purpose: slow, readable, one attack at a time)
  enemySpeed: { value: 140, min: 40, max: 300, step: 10 },       // walk speed near the hero, px/s
  enterSpeed: { value: 320, min: 100, max: 700, step: 10 },      // walking in from the screen edge until close, px/s
  enemyReach: { value: 150, min: 80, max: 260, step: 5 },        // distance they stop at and strike from, px
  telegraph: { value: 1.1, min: 0.4, max: 2.5, step: 0.05 },     // glow + "!" before a strike, s
  strikeTime: { value: 0.25, min: 0.1, max: 0.6, step: 0.05 },   // the strike itself, s
  enemyRest: { value: 1.6, min: 0.4, max: 4, step: 0.1 },        // pause after a strike, s
  spawnGap: { value: 1.0, min: 0.2, max: 4, step: 0.1 },         // time between soldiers walking in, s
  fleeSpeed: { value: 420, min: 150, max: 800, step: 10 },       // running away after the last hit, px/s
  hpSpear: { value: 2, min: 1, max: 6, step: 1 },                // hits before a spear soldier drops his spear
  hpShield: { value: 3, min: 1, max: 8, step: 1 },               // hits before a shield soldier gives up
  hpLeader: { value: 3, min: 1, max: 12, step: 1 },              // hits before the leader gives up (approved plan: 3)
  leaderSpeedMul: { value: 0.75, min: 0.3, max: 1.5, step: 0.05 },// leader walk speed as a share of enemySpeed
  standGap: { value: 10, min: 0, max: 60, step: 2 },            // how far inside enemyReach the front enemy stands, px
  queueSpacing: { value: 150, min: 60, max: 300, step: 10 },     // gap between enemies waiting their turn on one side, px
  kbDecay: { value: 0.25, min: 0.05, max: 1, step: 0.05 },       // time a knock-back takes to play out, s
  spawnOffset: { value: 80, min: 0, max: 300, step: 10 },        // how far off-screen enemies start, px
  lockOffset: { value: 500, min: 200, max: 900, step: 10 },      // hero's screen x when a fight's camera locks, px
  leaderKnockMul: { value: 0.5, min: 0.1, max: 1, step: 0.05 },  // leader knock-back as a share of knockback

  // Help for small hands (plan review 1 and 2)
  padMinCss: { value: 72, min: 44, max: 120, step: 2 },          // thumb pads never smaller across than this, CSS px
  fsGestureInset: { value: 32, min: 0, max: 64, step: 2 },      // bottom space kept clear in fullscreen for Android's swipe-up gesture, CSS px
  hintDelay: { value: 5, min: 2, max: 15, step: 0.5 },           // no progress this long → pulse Attack / ▶ + arrow, s
  endPause: { value: 0.6, min: 0, max: 3, step: 0.1 },           // after the last soldier runs, before the caption, s

  // Quiz (plan review (b): 4 by default, 3–5)
  quizCount: { value: 4, min: 3, max: 5, step: 1 },              // questions asked, from content.js
  star3Retries: { value: 0, min: 0, max: 5, step: 1 },           // wrong answers allowed for 3 stars
  star2Retries: { value: 2, min: 0, max: 8, step: 1 },           // wrong answers allowed for 2 stars (more = 1 star)
  feedbackTime: { value: 0.9, min: 0.3, max: 3, step: 0.1 },     // "Đúng rồi!" before the next question, s
};

// The mission's beats, in story order (plan review (a)). Plain data, not tuning values: TASK-004
// drops the sourced beats in here as 3 or 4 entries; the caption for beat N is content.js
// CONTENT.beats[N]. enemies: in walk-in order, each 'spear' | 'shield' | 'leader'.
// maxActive: how many may be on screen at once. fromLeft: indexes in enemies[] that walk in behind.
// type: 'fight' (the only type built; TASK-003b adds walk / hold / training / reach and an unknown
// type warns and plays as a fight). theme: the background, 'village' | 'bamboo' | 'river' | 'camp' (stand-in places, no history claim).
window.MISSION = {
  beats: [
    { type: 'fight', theme: 'village', enemies: ['spear', 'spear'], maxActive: 1, fromLeft: [] },
    { type: 'fight', theme: 'bamboo', enemies: ['spear', 'shield', 'spear'], maxActive: 2, fromLeft: [] },
    { type: 'fight', theme: 'river', enemies: ['shield', 'spear', 'shield', 'spear'], maxActive: 2, fromLeft: [3] },
    { type: 'fight', theme: 'camp', enemies: ['spear', 'leader', 'spear'], maxActive: 2, fromLeft: [2] },
  ],
};
