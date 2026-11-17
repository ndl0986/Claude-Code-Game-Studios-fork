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
  // --- Tap the creature: it hops and makes its own sound again (After play: helps the child learn it) ---
  tap_cooldown_s: { value: 0.9, min: 0.2, max: 3, step: 0.1 },   // s: taps closer than this only sparkle, so sounds never stack
  hop_px: { value: 26, min: 0, max: 60, step: 2 },               // px: how high the creature hops on a tap
  hop_s: { value: 0.45, min: 0.2, max: 1, step: 0.05 },          // s: the hop's length
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
// Theme: DINOSAURS. Every letter A-Z has one dinosaur-world creature or thing; its name contains
// the letter, often but not always as the first letter (C is triCeratops). The demo fixes one
// per key; production gets a small database with several per key per theme (K-07).
// creature: which drawing family; opts: that family's variant; pal: its colours;
// sound: which synth recipe; say: the letter's name spelled the way it sounds (so the voice
// says just "D", never "letter D"; A is "A." because "ay" was read like "eye"); word: spoken after.
const ROAR_BIG = { kind: 'roar', f0: 58, cut: 900, dur: 1.6, vol: 1, vib: 6 };
const ROAR_DEEP = { kind: 'roar', f0: 70, cut: 600, dur: 1.3, vol: 0.9, vib: 5 };
const GRUMBLE = { kind: 'roar', f0: 85, cut: 450, dur: 0.9, vol: 0.7, vib: 3 };
const HONK = { kind: 'honk', f0: 260, f1: 380, n: 2 };
const CHIRP = { kind: 'chirp', f0: 900, f1: 1400, n: 3 };
const RAPTOR = { kind: 'chirp', f0: 650, f1: 1050, n: 2 };
const SCREECH = { kind: 'chirp', f0: 1100, f1: 1700, n: 2 };
window.KEY_TABLE = {
  A: { name: 'Ankylosaurus', word: 'ankylosaurus', say: 'A.', creature: 'ankylosaurus', sound: { kind: 'thump', f0: 60, cut: 380, dur: 0.8, vol: 0.7, vib: 4 } },
  B: { name: 'Brachiosaurus', word: 'brachiosaurus', say: 'bee', creature: 'sauropod', opts: { tall: true }, pal: { body: '#8fbf6a', dark: '#77a556', belly: '#d2e8b4', spot: '#6f9e4f' }, sound: ROAR_DEEP },
  C: { name: 'Triceratops', word: 'triceratops', say: 'see', creature: 'horned', opts: { horns: 'tri' }, sound: GRUMBLE },
  D: { name: 'Diplodocus', word: 'diplodocus', say: 'dee', creature: 'sauropod', pal: { body: '#5fb3a8', dark: '#4a988e', belly: '#c2e6e0', spot: '#3f8a82' }, sound: ROAR_DEEP },
  E: { name: 'Edmontosaurus', word: 'edmontosaurus', say: 'ee', creature: 'duckbill', opts: { head: 'duck' }, pal: { body: '#9fb8d8', dark: '#7f9cc2', belly: '#e4ecf6', stripe: '#6f8bb0' }, sound: HONK },
  F: { name: 'Fossil', word: 'fossil', say: 'eff', creature: 'fossil', sound: { kind: 'crack' } },
  G: { name: 'Gallimimus', word: 'gallimimus', say: 'jee', creature: 'ostrich', opts: { gallimimus: true }, pal: { body: '#d8b06a', feather: '#efd39a', leg: '#b98a46', beak: '#f2a640' }, sound: CHIRP },
  H: { name: 'Hadrosaurus', word: 'hadrosaurus', say: 'aitch', creature: 'duckbill', opts: { head: 'bump' }, pal: { body: '#8cc4a0', dark: '#6faa86', belly: '#d8efdf', stripe: '#5a9472' }, sound: HONK },
  I: { name: 'Iguanodon', word: 'iguanodon', say: 'eye', creature: 'duckbill', opts: { head: 'thumb' }, sound: HONK },
  J: { name: 'Juravenator', word: 'juravenator', say: 'jay', creature: 'raptor', opts: { fuzz: true, snout: 0.8, tail: 1.15, bigEye: true }, pal: { body: '#7aa7d6', dark: '#5f8cbc', feather: '#b9d6f2', belly: '#d9e8f7' }, sound: SCREECH },
  K: { name: 'Kentrosaurus', word: 'kentrosaurus', say: 'kay', creature: 'plated', opts: { kind: 'kentro' }, pal: { body: '#c9a24f', dark: '#ad8a3e', belly: '#ecd9a6', plate: '#e86f4f' }, sound: GRUMBLE },
  L: { name: 'Lambeosaurus', word: 'lambeosaurus', say: 'el', creature: 'duckbill', opts: { head: 'hatchet' }, pal: { body: '#e7a0b8', dark: '#cf86a0', belly: '#f8dbe5', stripe: '#bf6f8c', crest: '#e0c08a' }, sound: HONK },
  M: { name: 'Maiasaura', word: 'maiasaura', say: 'em', creature: 'duckbill', opts: { head: 'brow', baby: true }, pal: { body: '#a98fd6', dark: '#8f75c0', belly: '#e3d8f5', stripe: '#7c62ad', crest: '#7fcf8f' }, sound: HONK },
  N: { name: 'Nest', word: 'nest', say: 'en', creature: 'nest', sound: { kind: 'crack' } },
  O: { name: 'Oviraptor', word: 'oviraptor', say: 'oh', creature: 'ostrich', sound: CHIRP },
  P: { name: 'Pteranodon', word: 'pteranodon', say: 'pee', creature: 'flyer', sound: SCREECH },
  Q: { name: 'Quetzalcoatlus', word: 'quetzalcoatlus', say: 'cue', creature: 'flyer', opts: { standing: true }, pal: { body: '#e3a35e', dark: '#c4864a', wing: '#f4cf9c', crest: '#d9534f' }, sound: SCREECH },
  R: { name: 'Raptor', word: 'raptor', say: 'are', creature: 'raptor', opts: { stripes: true, brows: true }, pal: { body: '#6fae6a', dark: '#5a9256', belly: '#cfe6c4', mark: '#3f7a3c' }, sound: RAPTOR },
  S: { name: 'Stegosaurus', word: 'stegosaurus', say: 'ess', creature: 'plated', sound: GRUMBLE },
  T: { name: 'T-Rex', word: 'tee rex', say: 'tee', creature: 'rex', sound: ROAR_BIG },
  U: { name: 'Utahraptor', word: 'utahraptor', say: 'you', creature: 'raptor', opts: { armFeathers: true, crest: true }, sound: RAPTOR },
  V: { name: 'Velociraptor', word: 'velociraptor', say: 'vee', creature: 'raptor', opts: { armFeathers: true, speckles: true, snout: 1.25, tail: 1.1 }, pal: { body: '#b99a6a', dark: '#9c7f54', feather: '#e2c79a', belly: '#ecdcc0', mark: '#7a5f3a' }, sound: RAPTOR },
  W: { name: 'Wuerhosaurus', word: 'wuerhosaurus', say: 'double you', creature: 'plated', opts: { kind: 'wuerho' }, pal: { body: '#6fa7b8', dark: '#5a8e9e', belly: '#cfe6ee', plate: '#e0c08a' }, sound: GRUMBLE },
  X: { name: 'Xenoceratops', word: 'xenoceratops', say: 'ex', creature: 'horned', opts: { horns: 'xeno' }, pal: { body: '#8f9fd8', dark: '#7584c0', belly: '#dfe4f6', frill: '#f29ab0' }, sound: GRUMBLE },
  Y: { name: 'Yutyrannus', word: 'yutyrannus', say: 'why', creature: 'rex', opts: { feathers: true }, pal: { body: '#d97a5a', dark: '#bd6246', belly: '#f6c7b4', ridge: '#e0c08a' }, sound: ROAR_BIG },
  Z: { name: 'Zuniceratops', word: 'zuniceratops', say: 'zee', creature: 'horned', opts: { horns: 'zuni' }, pal: { body: '#b6c46a', dark: '#99a654', belly: '#e6ecc0', frill: '#e8704f' }, sound: GRUMBLE },
};
// The numbers: the digit morphs into exactly that many baby dinosaurs (0: an empty nest).
['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine'].forEach((w, d) => {
  window.KEY_TABLE[String(d)] = d === 0
    ? { name: '0: empty nest', word: 'an empty nest', say: w, creature: 'nest', opts: { empty: true }, sound: { kind: 'chirp', f0: 700, f1: 900, n: 1 } }
    : { name: `${d} baby dinosaur${d > 1 ? 's' : ''}`, word: `${w} baby dinosaur${d > 1 ? 's' : ''}`, say: w, creature: 'babies', opts: { n: d }, sound: { kind: 'chirp', f0: 1200, f1: 1700, n: Math.min(d, 5) } };
});
window.KEY_ORDER = Object.keys(window.KEY_TABLE).filter(k => /[A-Z]/.test(k)).concat('0123456789'.split('')); // A-Z then 0-9 (JS lists digit keys first, so order them here)
