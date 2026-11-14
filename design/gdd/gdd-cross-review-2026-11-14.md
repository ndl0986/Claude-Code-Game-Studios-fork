## Cross-GDD Review Report

Date: 2026-11-14 · Task: TASK-010
GDDs Reviewed: 4 of 4 present (mission-flow, side-scroll-combat, quiz-and-stars, hints-and-onboarding)
Not read: none
Focus: full (consistency + design theory + scenarios)
Systems Covered: Mission flow & beat types, Side-scroll movement & combat, Quiz & stars, Hints & onboarding
Reviewers: two `game-designer` agents in parallel (Phase 2; Phases 3–4), compiled by game-art-content.
They read the GDD files directly rather than pasted excerpts.
Entity registry: empty, so the consistency checks relied on full GDD reads. Run `/consistency-check` once hero, place and event entities exist.
Engine: native iOS and Android (ADR-0001); no engine reference applies.

---

### Consistency Issues

#### Blocking
None.

#### Warnings

⚠️ **C1. Systems index misses two dependency edges.**
- Mission flow depends on Input (Hard), but index row 6 lists `5, 1, 2`.
- Hints depends on Content data (Hard, `hint_delay`), but index row 8 lists `6, 5, 3, 10`.

Fix: add the two edges to `systems-index.md`.

⚠️ **C2. The "stuck" timer on resume, and who owns it.**
- Hints Rule 5 resets its timer when the game resumes from pause.
- Combat's frame order resets the stall timer only on a hit or a caption closing, and its edge
  case says "all timers freeze" on pause.
- Three docs each claim to produce the no-progress signal:
  - Hints F1 computes `progress_timer > hint_delay`;
  - Combat's Interactions table emits `no_progress`;
  - Mission flow's Interactions table emits "no progress for `hint_delay` s".

Options:
- (a) Hints owns its own `progress_timer`, built from raw events. Remove the pre-thresholded
  outputs from Combat and Mission flow.
- (b) Combat owns it, adds "reset on resume", and Hints consumes the event.

⚠️ **C3. Quiz cites the wrong rule for "no text in pictures".** Quiz Visual/Audio says "(R10)".
R10 is about asset ids resolving; the no-text rule is the un-numbered Assets rule in
`content/README.md`.

⚠️ **C4. Combat Rule 16 points at the wrong decision.** It says "raised with D-08", but the
decision that governs special in combat is **D-10**.

⚠️ **C5. Two acceptance criteria can't both hold for a 4-fight mission.**
- Combat AC14 allows "within 2 minutes per fight". Four fights could take up to 8 minutes.
- Mission flow AC14 targets 3–5 minutes before the quiz. Mission flow F1's `T_play` range (10–90 s)
  is also below Combat's ceiling.

Options:
- (i) tighten Combat AC14 toward F3's 20–60 s;
- (ii) tie Mission flow AC14 to the beat set D-08 picks;
- (iii) resolve D-08 first.

#### Info
- ℹ️ `advance_debounce`, `bump_stop`, `special_push` and `special_cooldown` are labelled
  "proposed" in the GDDs, but they already exist in `tuning.json` with the same values. Update
  the labels and D-09's status.
- ℹ️ `ui.results.more_heroes` is quoted in Mission flow and now exists in `strings.json`
  (TASK-009 c6c1d2f). It just needs to be merged.
- ℹ️ It's ambiguous which loop advances the `end_pause` timer in a fight (Combat step 11 vs
  Mission flow). The value is clearly owned by Mission flow.
- ℹ️ Bidirectional dependencies between the 4 GDDs: all reciprocal. Dependencies on Not Started
  systems are expected.
- ℹ️ Every tuning key, rules field, schema field, fixture, rule ID and decision ID the GDDs cite
  exists under that name, except C3 and C4.

---

### Game Design Issues

#### Blocking
None. The open tensions below are design decisions for Luan, not defects.

#### Warnings

⚠️ **G1. Combat has no mastery axis, and defend is dominated** (combat Rule 4, Rule 10, edge case
"Spamming is a valid way to win").
- Blocking can't be combined with moving or attacking.
- A block pushes the enemy away, so it has to re-approach, which slows the fight down.
- An unblocked hit costs only a step, and doesn't affect progress or stars.

So the "!" telegraph and the defend teach-hint train a skill with no payoff. This fits pillar 3
(mastery lives in stars), but the challenge is flat. Options for Luan:
- (a) accept combat as pure participation;
- (b) give blocking a small positive payoff (e.g. a block stuns the enemy so the next hit
  counts double, or blocks fill the banner meter);
- (c) leave it and playtest whether "Đỡ được!" is satisfying on its own.

⚠️ **G2. What stars measure: the concept disagrees with the Quiz GDD.**
- The concept says "later heroes add a little speed or more targets; stars … reward the extra
  challenge", and "1–3 stars for replay mastery".
- Quiz Rule 7 derives stars **only** from quiz retries, so harder combat can't change them.
- Also, "add a little speed" collides with Combat's telegraph floor (≥ 0.8 s; F1).

Options:
- (a) correct the concept: stars measure story recall, and difficulty scales by enemy count and
  hits only, within the readability floor;
- (b) make stars reflect combat too.

⚠️ **G3. Stars have no payoff beyond lighting the map, yet they drive the only replay loop.**
Unlock never depends on stars. A replay means a full 3–5 min mission for one star, plus
re-tapping every story box if D-07 = A. Options:
- give stars a visible reward (a map decoration, a "Did you know?" fact page per star, a banner
  colour);
- and/or pick D-07 = B (skip story on replay).

⚠️ **G4. Pillar 1 depends on D-08.** With D-08 = A (4 fights, the current slice data), the orange
and the banner, the two most famous moments and the strongest "hero's hands" beat, are told in the
intro, not played. That is against "played and not just read" and the anti-pillar "generic
mini-games that ignore the story". Recommendation: C for the slice (plays the orange), B before
Alpha.

⚠️ **G5. Special in the slice adds a 5th thumb pad** for 6-year-olds on small phones, if D-10 = A.
That's over the attention budget. D-10's own recommendation (B, later) avoids it.

#### Info
- ℹ️ Safe for kids: no violation. No gore, and the death is one calm line over a still; Quiz Q7
  forbids death questions. No timers that block play: only the sub-second `feedback_time` and
  `end_pause`.
- ℹ️ The concept's Unique Hook ("opens once the child tells the story back") reads as a knowledge
  gate, but finishing always unlocks. That's a participation gate by design (pillar 3). Align the
  wording, or accept it.
- ℹ️ The quiz shifts the player's role from "hero's hands" to "student". The why-line and beat
  pictures bridge it, so it's a mild seam.

---

### Cross-System Scenario Issues

Scenarios walked: 6
1. First 60 seconds of the first mission
2. Language switch from pause mid-fight
3. App backgrounded during a windup
4. Last enemy flees → caption → next beat walk-in
5. Quiz finished → best-of stars → next_hero null
6. Replaying a hero

#### Blockers
None in the design. One process gate, already tracked: with C01–C11 unsigned (D-03), a
**release** build has no playable hero (R12). Only debug builds run the slice until Luan signs.

#### Warnings
- ⚠️ **S1 (replay; Quiz + Save):** the quiz shuffle is deterministic (Rule 3: `seed` from
  `tuning.json` + question index, fixed for app parity), so every replay shows the same
  positions. A child can farm 3★ by memorising card positions instead of the history. Options:
  - (a) accept it;
  - (b) reseed per run (`seed + run_count + question_index`) and keep the fixture testing the
    algorithm, not one fixed order.
- ⚠️ **S2 (pause mid-fight; Mission flow + Combat):** whether pause releases a **held defend** is
  unspecified (it is only stated for hold-meter). After resume, the windup continues with its
  remaining time, so a released defend may leave the child a fraction of a second. Harmless (one
  step back), but both apps need the same rule (P-04). Recommendation: pause releases all held pads,
  and on resume the current windup restarts its telegraph from 0.
- ⚠️ **S3 (replay cost; Mission flow + Quiz):** see G3 and D-07.

#### Info
- ℹ️ S4 (first 60 s, D-08 = B): the child walks in `walk_to[0]`, a beat card interrupts, then
  walks again in the walk beat. Slightly awkward. Consider starting beat 1's card right after
  the intro.
- ℹ️ S5 (last enemy fleeing): the final flee-run happens before goal-met, so it falls outside
  Mission flow's "under 1.5 s dead time" (measured from goal-met). Check it in the playtest.
- ℹ️ S6 (results on a first play): "best" equals this run. The open question on showing best
  stars waits for the `/ux-design` results screen.
- ℹ️ Backgrounding during a windup, and quiz → null next hero: fully consistent across the docs.

---

### GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
|-----|--------|------|----------|
| side-scroll-combat.md | C2 stall-timer ownership/resume; C4 D-10 reference; C5 AC14 bound; S2 pause releases defend; "proposed" labels | Consistency | Warning |
| hints-and-onboarding.md | C2 no-progress ownership | Consistency | Warning |
| mission-flow.md | C2 interface; C5 F1 `T_play` range / AC14; "proposed" labels; S2 pause rule | Consistency | Warning |
| quiz-and-stars.md | C3 R10 citation; S1 shuffle per run (if Luan picks b) | Consistency | Warning |
| systems-index.md | C1 two missing edges | Consistency | Warning |
| game-concept.md | G2 what stars measure; Unique Hook wording | Design Theory | Warning (Luan) |

---

### Verdict: CONCERNS

No blocking issues. There are warnings in consistency (C1–C5), design (G1–G5) and scenarios
(S1–S3). The consistency warnings are small edits. G1–G3, S1 and the open D-07/D-08/D-10 are
design calls for Luan.
