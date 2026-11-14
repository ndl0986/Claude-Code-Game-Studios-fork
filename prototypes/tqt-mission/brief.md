<!-- PROTOTYPE - NOT FOR PRODUCTION -->
# Game Brief: Dải Đất Anh Hùng: Trần Quốc Toản (mission prototype)

<!-- TASK-003. This brief lives in prototypes/tqt-mission/ only. The design record for the game is
design/gdd/game-concept.md (Approved); this brief pulls the prototype's fields out of it and the
approved TASK-003 plan. design/game-brief.md is not written. -->

## In your words
Leader's TASK-003 card (Luan gave the go, 2026-11-14): "a browser prototype of one side-scrolling
Trần Quốc Toản mission … Scope: move / attack / defend buttons, 3–4 beats, non-violent knock-back,
then a 3–5 question quiz that unlocks the next hero. Landscape, touch-first, thumb-size controls,
VI default with an EN switch, fonts with full Vietnamese diacritics. All history text is
⟨placeholder⟩ … Don't invent historical claims."

Concept (design/gdd/game-concept.md, Luan's decisions): "2D game with some simple action for attach,
defense"; side-scrolling; story-first; "default is VN but always can turn to EN"; visual style
modern kids' cartoon with Vietnamese motifs; no blood or gore, enemies are knocked back or run away;
no timers, lives or energy that block play.

Plan review (game-dev-001, approved): 1. picture or icon on every quiz answer, one short sentence
per intro line, hand/arrow control hints · 2. a gentle hint after ~5 s with no progress ·
3. stacked-diacritic placeholder "Ặ Ỗ Ữ ẫ ợ" in intro, quiz and buttons; EN fits at 640x360 ·
4. no network requests after load; language memory in localStorage · 5. shots of unlock and a
mid-beat telegraph in VI and EN; a full keyboard playthrough with zero console errors ·
6. quiz-only stars for now. (a) 4 beats from a beats array · (b) 4 questions, count 3–5.

**Pitch:** Play young hero Trần Quốc Toản's story as four short side-scrolling beats with big
move / attack / defend buttons, then answer a picture quiz to unlock the next hero.

**Genre:** side-scrolling beat-em-up, made gentle for children aged 6–10 *(inferred (strong))*

**Controls:** touch: ◀ ▶ pads bottom-left, Attack and hold-to-Defend bottom-right, every button
at least 72 CSS px on a 640x360 screen. Keys mirror them: ← → or A D move, J or Space attack,
hold K or Shift defend, Enter next, 1 2 3 answer, L language, P pause, M mute.
For QC: menu and answer buttons fire on touch-down (pointerdown), not on release. The canvas
fits inside the safe-area insets (notch, home-indicator zone). The first real tap on the title asks for
fullscreen (Android shows its one-time "Viewing full screen" dialog and Chrome its exit toast: OS
behaviour, not the game); in fullscreen the bottom fsGestureInset (32 CSS px) stays clear for the
system swipe-up.

**Question:** Can a 6-year-old play one hero's story as light touch action on a landscape phone,
then answer a short quiz about it?

**Hooks:** the mission *is* the story, beat by beat; the quiz about that story is what unlocks
the next hero.

**Intent:** soft or no failure *(you said: no timers, lives or energy that block play)*

## Look and references
- Look: modern kids' cartoon with Vietnamese motifs: soft, rounded, bright figures; warm
  primaries for anything you touch and for rewards (gold, red used sparingly); natural greens and
  river blues behind; bronze-drum ring pattern on the sun, the HUD medallions and frames; bamboo,
  areca palms, thatched houses, lotus, rattan shield. Enemies in muted purple-grey so they read as
  "the other side" with no ethnic features and grumpy-cartoon faces, never scary. Signature
  detail: the hero's rattan shield with a gold boss. Every figure drawn, no emoji, no plain
  circles. Text never painted into art.
- References: none from Luan (he skipped the taste questions). Values only from the genre
  (stop-and-go stages, telegraphed attacks).
- View: 2D · Camera: side view, follows the hero; locks at each fight until the group is gone,
  then "Đi tiếp →" points on (stop-and-go).

## First minute
Title: tap **Bắt đầu**. One picture panel with one short ⟨placeholder⟩ sentence, tap **Tiếp**.
A pointing hand bobs on ▶; the child holds it and the hero walks through a village. The screen
stops, a soldier walks in, the hand moves to Attack; one tap swings the staff and knocks him
back with a drum hit and a burst of stars. When a soldier glows yellow with a "!", the hand
moves to Defend; holding it blocks with a clang. After two hits he drops his spear and runs off,
and a one-line ⟨placeholder beat 1⟩ caption ends the beat.

## Challenge
The first real trouble is beat 2 (about minute 2): two soldiers at once, one of them a shield
soldier who takes three hits. Beat 3 sends one from behind. Beat 4 has the leader, wider and
slower, three hits. Telegraphs are 1.1 s, so watching and defending is the skill. A missed block
only pushes the hero back a little; nothing is lost and there is no game over. Stars come from
the quiz alone: 3 for no wrong answers, 2 for up to two, 1 for finishing.

## Core loop
- Walk right → the camera stops → knock back each soldier (attack, defend the glowing ones) →
  they drop their weapons and run → a story caption.
- Four beats in story order → a calm ending line → a 3–5 question picture quiz (wrong answers
  retry with no lock-out) → 1–3 stars → the next hero's slot unlocks → back to the map stub.

## Goal & fail state
- Goal: finish the four beats and the quiz; the next hero unlocks. A session is complete on the
  unlock screen.
- No failure: unblocked hits push the hero back; quiz mistakes cost a star, never progress.

## Features
- [x] Side-scrolling mission with stop-and-go fights, 4 beats read from `MISSION.beats` (3 or 4 work)
- [x] Move / attack / hold-to-defend, touch-first thumb pads + keyboard mirror, multi-touch
- [x] 3 enemy kinds, each with its own silhouette: spear soldier, shield soldier, leader
- [x] Telegraphed attacks (glow + "!"), defend always blocks when held
- [x] Non-violent knock-back: bounce, star burst, drum; the last hit drops the weapon and they run
- [x] First-time hand hints on move, attack and defend; a pulse hint after 5 s with no progress
- [x] Intro panel, beat captions and ending line, all ⟨placeholder⟩, one short sentence each
- [x] Quiz: 4 questions by default (3–5 in config), 3 picture answers each, retry on wrong
- [x] Stars (quiz only) and an unlock screen for the next hero ⟨placeholder⟩
- [x] VI default, EN switch on every screen, remembered in localStorage; bundled Nunito font
- [x] Pause, mute, and a "turn your phone sideways" overlay in portrait

## Keep
-

## Avoid
- blood, gore, deaths or health bars on enemies; battles shown through knock-back and running away
- timers, lives or energy that block play; a game over
- invented history presented as fact: every story line, quiz question and answer is ⟨placeholder⟩
- the drafted beats Luan removed (council, orange, banner text, leading a band)
- hero cards or a card album
- network requests, accounts, ads, analytics, data collection
- text painted into art

## Out of scope
- real story beats, quiz and sources: TASK-004 (game-art-content), Luan signs off
- final art, voice-over, music, the map of Vietnam and the timeline: later
- saving progress (only the language choice is stored), more heroes: grow it
- stars for action mastery on replay: a later decision (plan review 6)
- a phone build: this runs in a phone's browser; touch is built from the card, and no repo check
  plays touch: Android QC checks it on a device. Godot is TASK-002.

## Build order
1. The slice: title → intro → 4 beats (walk, fight, caption) → ending → quiz → stars → unlock,
   no failure, every value in `config.js`.

---
**Kill condition:** if children on a real phone cannot finish beat 1 without adult help after the
hints, or the quiz answers do not fit at 640x360.

**Who it's for / what they feel:** Vietnamese primary-school children, 6–10: "I was the hero in
that story, and I know what happened."

**Games you love / don't:** none given.
