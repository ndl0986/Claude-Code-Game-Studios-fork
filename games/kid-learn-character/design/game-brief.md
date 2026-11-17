# Game Brief: Letter Morph: Dinosaurs

## In your words
thử với chữ cái có trong Dinosoaur

(Questions 1–6 not answered: the usual options taken.)

After play: khi bé chơi, nên đisable tất cả các phím ngoài phím letter và number, các phím còn lại, khi đang focus trên màn hình game thì sẽ bị mất tác dụng
After play: không cần hiện dòng chữ DINOSAUR sẵn trên màn hình, thay vào đó, có thể gợi ý bằng các chữ cái ngẫu nhiên hiện trên màn hình chính của game
After play: không cần đọc letter A, letter D, ... chỉ cần đọc A hoặc D hoặc 1 (one) khi được nhấn
After play (asked): "D" rồi "dinosaur" — keep the word after the letter's name
After play: có 1 hiểu lầm, mình nói bắt đầu với dinosaur là 1 chủ đề, tức là mình thể cho bé gõ bất ký ký tự nào ngoài 8 ký tự thì vẫn có thể đọc và hiện 1 khủng long tương ứng, có thể ký tự không phải là đầu tiên tương ứng với phím đc nhấn
After play: với bản đề demo, có thể fix cứng mỗi ký tự là 1 con vật/đồ vật, tương ứng với từng chủ đề, nhưng với bản production, nên xây dựng cơ sở dữ liệu vừa đủ để tạo sự đa dạng
After play (asked): the A–Z table and numbers as N baby dinosaurs — "Làm đúng như vậy"
After play: khoảnh khắc hay và vui nhất là sau khi kết thúc 1 loạt phím, thì có đoàn khủng long chạy qua, rất vui và bất ngờ
After play: tệ nhất là khi nhấn vào các phím controls, thì có thê bị chuyển app hoặc mất focus lên game
After play: trong bản dùng thử, phần đọc ký tự A đang bị sai, đang theo tiếng Việt, không đúng tiếng Anh

**Pitch:** Dinosaurs is the theme: a toddler presses any letter or number, and the big glowing letter dissolves into stardust and becomes a dinosaur-world creature (C: triceratops) or that many baby dinosaurs, while a voice says "C… triceratops!".

**Genre:** toddler toy / early-learning sandbox *(inferred (strong))*

**Controls:** tap a glowing letter that drifts on screen, or press letters on a real keyboard; every key other than a letter or digit does nothing while the game has focus.

**Question:** does the stardust morph, plus the 3-key queue with a ~3 s hold, delight a 2.5–3-year-old for 5+ minutes without ever feeling broken or slow? *(inferred (strong))*

**Hooks:** the letter's own shape turns into the creature; every key in DINOSAUR is a different dinosaur-world surprise. *(inferred (strong))*

**Intent:** no goal to reach · soft or no failure *(you said, in the concept: "no goals, no right or wrong")*

## Look and references
- Look: "Stardust Storybook". A calm dusk-blue to cream gradient background. The pressed letter shows big, centred and warm golden, glows, then breaks into drifting gold and white stardust that gathers into a flat, rounded 2D vector creature with friendly colours (green Stegosaurus with orange plates, a purple T‑Rex, a blue Ankylosaurus…). The creature idles with a gentle breathing bob. Signature detail: the stardust takes the letter's outline before flowing into the creature. Sparkle, never strobe. Every figure is drawn: no emoji, no plain circles. *(provisional)*
- References: Typer Shark (pressing keys is the fun); picture-book alphabets. *(from the concept)*
- View: 2D · Camera: fixed, front-on stage above the keyboard. *(provisional)*

## First minute
The screen shows a soft dusk scene with a few glowing letters drifting in at random spots, pulsing gently until the first press. The child taps anything: the key lights up, the letter rises big and golden, glows, dissolves into stardust and becomes the creature with its sound, and the voice says "D… dinosaur!". The next tap brings another. Mashing queues up to three, and each one plays in turn. *(provisional)*

## Challenge
None by design: there is no failure and no wrong key. What changes: discovering all 36 keys; every 8 new creatures met, a soft "parade" of those 8 walks across once. *(provisional)*

## Core loop
- Press a letter (screen or keyboard), and the key lights up at once.
- The letter morphs into its creature, with its sound and the spoken "letter… word".
- The creature idles until the next press; mashing queues up to 3, each held about 3 s, and extra presses only sparkle.
- Repeat; favourites get pressed again.

## Goal & fail state
- No goal and no fail. A session feels complete when the child has met all 8 creatures (the parade plays once).

## Features
- [x] Every letter A–Z and digit 0–9, as random glowing hint letters on screen (tappable) plus the hardware keyboard; every other key does nothing
- [x] Stardust morph: letter → particles in the letter's shape → creature, all values in config.js
- [x] Theme Dinosaurs: 26 drawn dinosaur-world creatures A–Z, one per key, name contains the letter (A Ankylosaurus … C Triceratops, F Fossil, N Nest … Z Zuniceratops), each with its own outline and an idle bob; digits 1–9 become that many baby dinosaurs, 0 an empty nest
- [ ] Sound: synthesized roar or chirp per creature plus sparkle chime; browser speech in US English, just the letter's name then the word: "D… dinosaur" (never "letter D")
- [x] Mash queue: max 3 pending, ~3 s hold while queued, extra presses sparkle only
- [x] A parade of the last 8 new creatures, every 8 met *(guessed)*
- [x] Tweak panel (queue size, hold time, morph speed, volume), hidden behind a long-press corner (parent gate stand-in) *(provisional)*

## Keep
- the dinosaur parade running across after a run of keys: the most fun, a happy surprise *(you said)* · pins: parade_s 11, parade_delay_s 1.5

## Avoid
- A fixed DINOSAUR key row on screen *(you said)*
- The voice saying "letter D" / "capital D" *(you said)*
- Any key other than letters and digits doing anything while the game has focus *(you said)*
- Scores, timers, quizzes, fail states, text the child must read (beyond the letter), ads, links out, network, data collection, strobing, loud stings. *(from the concept's anti-pillars)*

## Out of scope
- A database with several creatures per key per theme, for variety: production (K-07); the demo fixes one per key
- Other themes (Vehicles…): grow it
- Theme packs and Mash World (objects stay in a scene): grow it
- Recorded voice and licensed art: in the native Swift app (ADR-0001)
- 3D creatures: later (K-01)

## Build order
1. The slice: 8 keys → morph → creature + sound + voice, with the mash queue; no way to lose.
2. The parade and the tweak panel.

---
**Kill condition:** the child loses interest within a minute, or the 3 s hold makes them think the keys are broken, even after two tuning rounds.

**Who it's for / what they feel:** Luan's 2.5–3-year-old child, with a parent beside them; wonder and calm.

**Games you love / don't:** Love Typer Shark (typing is the fun).
