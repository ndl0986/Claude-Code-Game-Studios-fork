// PROTOTYPE - NOT FOR PRODUCTION
// Question: does the stardust morph, plus the 3-key queue with a ~3 s hold, delight a 2.5-3-year-old for 5+ minutes without ever feeling broken or slow?
// Date: 2026-11-17
// Every tuning value lives here, each with value, min, max and step. The game reads them live
// through tune.<name> (index.html); the grown-up panel (hold the moon) writes them back here.
window.CONFIG = {
  seed: 1, // every gameplay random call reads rng(), seeded from this (or ?seed= in the address)
  volume: { value: 0.5, min: 0, max: 1, step: 0.05 },
  // --- The mash rule (concept: queue of 3, ~3 s per reveal while keys wait) ---
  hold_s: { value: 3, min: 1, max: 6, step: 0.25 },        // s: a reveal holds at least this long before a queued key plays
  queue_max: { value: 3, min: 0, max: 5, step: 1 },         // keys that may wait; presses beyond only sparkle
  // --- The stardust morph (durations are divided by morph_speed) ---
  morph_speed: { value: 1, min: 0.5, max: 2, step: 0.05 },  // x: 2 = twice as fast
  letter_in_s: { value: 0.45, min: 0.1, max: 1.5, step: 0.05 }, // s: letter rises from its key and grows
  glow_s: { value: 0.35, min: 0, max: 1.5, step: 0.05 },        // s: letter glows at centre
  dissolve_s: { value: 0.4, min: 0.1, max: 1.5, step: 0.05 },   // s: letter becomes stardust in its own outline
  flow_s: { value: 0.9, min: 0.2, max: 2.5, step: 0.05 },       // s: stardust flows to the creature's shape
  form_s: { value: 0.5, min: 0.1, max: 1.5, step: 0.05 },       // s: creature fades in, stardust fades out
  particles: { value: 420, min: 100, max: 900, step: 20 },      // count of stardust specks per morph
  swirl: { value: 0.35, min: 0, max: 1, step: 0.05 },           // how much the stardust curves on its way
  // --- Hint letters: a few glowing letters drift in at random spots (no fixed key row) ---
  hint_count: { value: 3, min: 0, max: 6, step: 1 },          // letters on screen at once
  hint_life_s: { value: 6, min: 2, max: 15, step: 0.5 },       // s: how long one lingers
  hint_size: { value: 120, min: 70, max: 170, step: 5 },       // px: a hint bubble's size
  // --- Look ---
  creature_scale: { value: 1, min: 0.6, max: 1.3, step: 0.05 },
  bob_px: { value: 5, min: 0, max: 15, step: 1 },                // px: idle breathing bob
  key_flash_s: { value: 0.35, min: 0.1, max: 1, step: 0.05 },    // s: a pressed key glows this long
  // --- Sound and voice ---
  voice_rate: { value: 0.85, min: 0.5, max: 1.3, step: 0.05 },
  voice_pitch: { value: 1.15, min: 0.5, max: 2, step: 0.05 },
  roar_volume: { value: 0.35, min: 0, max: 1, step: 0.05 },      // creature sounds stay gentle (Calm Magic)
  chime_volume: { value: 0.12, min: 0, max: 0.5, step: 0.01 },
  // --- Parade and the grown-up gate ---
  parade_delay_s: { value: 1.5, min: 0, max: 5, step: 0.25 },    // s after the 8th creature forms
  parade_s: { value: 11, min: 4, max: 25, step: 0.5 },           // s: the parade's walk across
  gate_hold_s: { value: 1.5, min: 0.5, max: 4, step: 0.25 },     // s: hold the moon to open the grown-up panel
};

// The key table: data, not code (concept: "the key -> picture -> sound table is data").
// creature: which drawing; sound: which synth recipe; say: the letter's name spelled the way it
// sounds (so the voice says just "D", never "capital D" or "letter D"); word: spoken after.
window.KEY_TABLE = {
  D: { name: 'Dinosaur', word: 'dinosaur', say: 'dee', creature: 'sauropod', sound: { kind: 'roar', f0: 70, cut: 600, dur: 1.3, vol: 0.9, vib: 5 } },
  I: { name: 'Iguanodon', word: 'iguanodon', say: 'eye', creature: 'iguanodon', sound: { kind: 'honk', f0: 260, f1: 380, n: 2 } },
  N: { name: 'Nest', word: 'nest', say: 'en', creature: 'nest', sound: { kind: 'crack' } },
  O: { name: 'Oviraptor', word: 'oviraptor', say: 'oh', creature: 'oviraptor', sound: { kind: 'chirp', f0: 900, f1: 1400, n: 3 } },
  S: { name: 'Stegosaurus', word: 'stegosaurus', say: 'ess', creature: 'stegosaurus', sound: { kind: 'roar', f0: 85, cut: 450, dur: 0.9, vol: 0.7, vib: 3 } },
  A: { name: 'Ankylosaurus', word: 'ankylosaurus', say: 'ay', creature: 'ankylosaurus', sound: { kind: 'thump', f0: 60, cut: 380, dur: 0.8, vol: 0.7, vib: 4 } },
  U: { name: 'Utahraptor', word: 'utahraptor', say: 'you', creature: 'utahraptor', sound: { kind: 'chirp', f0: 650, f1: 1050, n: 2 } },
  R: { name: 'T-Rex', word: 'rex', say: 'are', creature: 'rex', sound: { kind: 'roar', f0: 58, cut: 900, dur: 1.6, vol: 1, vib: 6 } },
};
window.KEY_ORDER = ['D', 'I', 'N', 'O', 'S', 'A', 'U', 'R']; // the letters with a creature (hints are drawn from these)
