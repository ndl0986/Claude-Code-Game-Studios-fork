# TASK-080: plan for the next contract batches (ADR-0004)

> **Author:** game-qc-android · **Date:** 2026-11-18 · **Review:** game-dev-android
> **Plan only.** No spec or case is written by this task. Each contract below lands later as
> `contracts/<name>-v1/{spec.md, cases.json, sources.lock}`, in the `case-schema-v1.md` format with per-section
> `sources.lock`, as TASK-068 did.
> **Base:** `docs/kid-learn-character-plan` @ 11eab609 (ADR-0002, 0003, 0004 and 0005 Accepted; ADR-0006 and 0011
> Proposed; TASK-068 merged as 12f6f474).

## 1. Order

Contracts are specs plus hand-written cases, so they don't wait on the scaffold story. The scaffold only *runs*
them. The order follows the play path from the bottom up, so each contract can treat the ones before it as fixed
inputs (ADR-0004 D1: one owner per number).

| Batch | Contracts | Why this order | Reviewer |
|---|---|---|---|
| **2 (this plan)** | **input-filter-v1**, then **press-queue-v1** | The bottom of the play path: every press goes Input → Press Queue. ADR-0007 and device check P-15 already cite input-filter-v1. press-queue-v1 consumes Input's R8 event shape as input only | game-dev-ios |
| 3 | reveal-timing-v1, audio-plan-v1 | The reveal chain: `startReveal` → {formedS, revealLen, hasWord} feeds both the queue's F1 and Audio's E-times. Written together so that E6–E9 (audio-plan-v1) and formedS (reveal-timing-v1) each have one owner | game-dev-ios (timing), game-art-content (audio content facts) |
| 4 | hint-letters-v1, keyboard-row-v1 | Touch-target systems with their own draw streams (`hints`, `keyboard-row`); they use input-filter-v1's hit tests as inputs | game-dev-android (Hint Letters author), game-art-content (row words) |
| 5 | gate-logic-v1, app-shell-v1 | The grown-up and lifecycle chains; they need the `gate-code` stream (ADR-0004 D2) and the away clock | game-dev-ios |
| 6 (Vertical Slice) | parade-v1, scene-look-v1 | Scene is a Vertical Slice system; parade-v1 reads the queue's `restingSince` | game-art-content |

**morph-contract-v1:** no migration. It stays at `docs/architecture/morph-contract-v1.md` and
`content/fixtures/morph-contract-v1.json`, moves only with a v2 (architecture.md; ADR-0004 D1), and keeps its own
SplitMix64 seed. `contracts/README.md` already points to it. Nothing to do in any batch.

The rest of this plan details **batch 2**. Batches 3–6 get their own plan when they're next.

## 2. input-filter-v1

**Owner GDD:** `design/gdd/input-key-filter.md`. **Layer:** KidCore. **Reviewer:** game-dev-ios.

**Sections covered** (sources.lock pins these `##` sections: Detailed Design, Formulas, Edge Cases, Acceptance
Criteria; plus ADR-0002 `## Decision` for D5):
- R2 key resolution: numpad first, then the character fold, the US-QWERTY position fallback, or nothing;
- R3 modifiers: disqualifying Ctrl / Alt / Cmd / Fn; ignored Shift / Caps / Num Lock;
- R4 held set and repeats, the clears, and a missed up;
- R5 swallowing: hardware system keys pass; one ⌘ signal, `kioskModeOn`, in every state;
- R6 the Mac chord:
  - exact ⌃⌥⌘Q, with Shift and Caps ignored and Fn disqualifying;
  - empty held set;
  - the OS key-state read with `KeyStateQuery` present and absent;
  - the ⌘-release rule (k3);
  - where it works: Title and Play, ignored in the challenge and panel;
  - iPad: no chord;
- R7 touch layers in order: hint (incl. fading), row key, moon with `gateTouch` began/ended including the slop, cast,
  sparkle. Also overlapping hints (nearest centre wins), multi-touch, and the batch sort by time then x then y;
- R8 the event contract: order, no dropping, `origin` nil for a hardware key, and the other outputs;
- States: Title (`startPlay`, the held set kept into Play), Play, Gate challenge (digits to the keypad), Panel open
  (the filter off except ⌘ while the kiosk mode is on), Inactive;
- F1 hint hit radius; F2 re-press gap;
- Edge Cases: every listed case except the two marked NOT ASSESSED (Bluetooth hot-plug, IME).

**Out of scope (and where it's tested instead):**
- the adapters' platform mappings (UIKey / NSEvent / scanCode → D5): ADR-0007, device check P-15;
- AC-1k6, the TCC prompt: device check M-1;
- media keys on a real iPad: device check P-4;
- pixel → stage conversion: reveal-timing-v1 (Reveal Stage F1). Input cases use a 1280 × 720 px window with no
  insets, so F1 is the identity, plus one `pxPerPt` = 2 case for the moon slop in points;
- what the gate does with `openPanel` during moon sleep: gate-logic-v1 (Input still emits it; R6).

**Estimated cases:** about 85.

| Group | Cases |
|---|---|
| R2 | ~14: A–Z / 0–9; lower-case fold; numpad with Num Lock on and off; AZERTY digit row; Cyrillic → position; `é` not E; Space, Esc, arrows, dead key, Globe → nothing |
| R3 | ~8: each disqualifier, alone and in pairs; Shift, Caps |
| R4 | ~10 |
| R5 | ~10: system keys pass; ⌘Q / ⌘H / ⌘W in each of 4 states with the mode on and off, plus `childLockActive` true with the mode off |
| R6 | ~14 |
| R7 | ~12 |
| R8 | ~4 |
| States | ~8 |
| F1 / F2 | ~5 |

**Streams:** none.

**Seams and inputs** (ADR-0002):
- D5 `KeyEvent`, including `kind: modifiersChanged`, and D5 `TouchEvent`. Their `time` comes from `t.uptime`
  (case-schema-v1 S17).
- D6 `DisplayMetrics` (`windowPx`, `pxPerPt`, insets) for the slop in points.
- D6 `KeyStateQuery`, optional: `given.keyState` is either absent or a list of non-modifier physical ids that are
  down.
- D3 uptime only.
- Contract-local `given`: `platform`, `state` (Title / Play / GateChallenge / PanelOpen / Inactive),
  `kioskModeOn`, `heldSet`, and the published hit regions (hints `{id, key, centre, drawRadius, onStage}`, row key
  rectangles, the moon circle, the cast shape) in stage units.

**Outputs** (ordered, per step): `press {key, source, origin}`, `sparkle`, `creatureTap`, `gateTouch {phase,
pointerId}`, `openPanel`, `startPlay`, `keypadDigit` (challenge), `panelKey` (panel open), `passToSystem`, or
nothing. `expectState`: `heldSet`.

**Questions for the GDD owner** (owner: the Input GDD's author, via game-dev-ios; none guessed in a case):
- **IF-Q1, numpad in D5.** R2.1 puts the numpad first ("by its physical position … Num Lock on or off"). D5's
  `KeyEvent` has `positionKey` but no numpad flag. Does the adapter give a numpad 5 `positionKey` "5" (the same as
  the top row)? If so, does `character` with Num Lock off reach the fold first? Which field, or a new flag, tells
  Input it's a numpad key?
- **IF-Q2, system keys in D5.** R5's "hardware system keys always pass" and the order of checks start with "system
  key → pass to the system". `KeyEvent` has no field that marks a system key. Is it a `physicalId` class, a new
  flag, or adapter-only (never reaching `KidCore`)? This decides whether input-filter-v1 can have `passToSystem`
  cases at all.
- **IF-Q3, the ⌘-release rule's scope.** "Every key that went down while ⌘ was held is removed": does that include
  keys that went down while ⌘ was held but before the last `modifiersChanged`? And a key pressed with ⌘ and then
  released before ⌘ (its up removed it already)?
- **IF-Q4, the challenge keypad.** In Gate challenge, R6 says "digit keys go only to the challenge's keypad". Does
  Input emit them as a new `keypadDigit` output, or as a `press` that the Parent Gate routes? This sets the output
  name. Is a numpad digit with Num Lock off a keypad digit there?
- **IF-Q5, Panel open.** "The filter is off; keys go to the grown-up panel as normal input." Is that an Input output
  at all (`panelKey`), or does Input emit nothing and the platform's text system handles the panel? Without an
  output, Panel open cases can only assert "no press" and the ⌘ swallowing.
- **IF-Q6, a touch moved off the moon and back.** `gateTouch(ended)` fires "once" when the pointer leaves the slop
  region. If the same pointer comes back inside, is there any new `began`? (Presumably not; confirm.)
- **IF-Q7, the batch sort key.** "By timestamp, then stage x, then stage y": exact equality on doubles? With equal
  time and x, smaller y first?

## 3. press-queue-v1

**Owner GDD:** `design/gdd/press-queue.md`. **Layer:** KidCore. **Reviewer:** game-dev-ios.

**Sections covered** (sources.lock: Detailed Design, Formulas, Edge Cases, Acceptance Criteria; plus Audio & Voice
F6 for `word_end`, and ADR-0002 `## Decision` for D3 and D7.2):
- R2 state, revealId from 1 with no gaps;
- R3 accept / queue / ignore: never jumping a queued key, out-of-order stamps, the Title;
- R4 outcome in the callback;
- R5 `tick`: the formed timeout, then at most one advance per tick;
- R6 `startReveal` and the locked `holdEff`;
- R7 `formed` rules;
- R8 panel: clear and settle, hold passed;
- R8a gate freeze and resume on the play clock;
- R9 background;
- R10 `restingSince`;
- R11 snapshot;
- R12 sources equal;
- F1 every table row, including the missing-`voiceDurations` row and `hasWord` false;
- F2 predicate;
- F3 mash bursts at rest and during a hold, and `queue_max` = 0;
- F4 waiting time, worst case 11.55 s;
- F5 Reduce Motion locked at start;
- AC-1–18, 20, 22, 23, 24.

**Out of scope:**
- AC-19 (hint on overflow): an integration test across Input, Queue and Hint Letters; hint-letters-v1 owns the
  hint's reaction.
- AC-21 (queue data validation at build): ADR-0003's content validator. Its cases go in a later queue-data entry
  point if ADR-0003 asks.
- The item pick: key-table-schema-v1. The queue only passes the stubbed item's `castId` through.
- `formedS` / `revealLen` themselves: reveal-timing-v1. Here they come from a stub.

**Estimated cases:** about 55.

| Group | Cases |
|---|---|
| R3 / F2 | ~10 |
| R5 | ~6 |
| R6 / F1 | ~8: every F1 row plus `hasWord` false |
| R7 | ~5 |
| F3 | ~4 |
| F4 | ~3 |
| R8 / R8a / R9 | ~8 |
| R10 / R11 | ~4 |
| AC-10 revealId run, AC-18 three sources, AC-22 | ~4 |
| F5 | ~3 |

**Streams:** none. The queue draws nothing; the item pick's draws are key-table-schema-v1's.

**Seams and inputs:**
- D3: uptime from `t.uptime`; **the play clock derived, never given**. Freeze, resume, settle and background come
  as events.
- D7.2 freeze chain events: `freeze`, `resume`, `settle`, `panelOpen` / `panelClose`, `background` /
  `foreground`.
- Contract-local:
  - `press {key, source, origin}`: the R8 shape from Input, as an input;
  - `tick`;
  - `formed {revealId}`;
  - `given.revealStub`: per key, `{formedS, revealLen, hasWord, castId}` as the fake Reveal Stage and Key Table;
  - `given.wordLen`: per key, the `voiceDurations` value, or absent for the missing-entry row;
  - `given.knobs`: `hold_s`, `queue_max`, `formed_timeout_s`, `word_offset_s`, `hold_ext_max_s`.

**Outputs:** `started {revealId, r0, castId}` (r0 in play-clock time), `queued {index}`, `ignored`,
`startReveal {revealId, key, source, origin, r0}` (the call to the Reveal Stage), and `log` (formed timeout,
missing voiceDurations). `expectState`: `current`, `queue` keys, `restingSince`, `nextRevealId`. **Field kinds:**
`r0`, `restingSince` and `holdEff` are `time` (1e-9).

**Questions for the GDD owner** (Press Queue's author, via game-dev-ios):
- **PQ-Q1, clock wording.** R3 says the decision "uses `p.time` on the monotonic uptime clock", and R8a says a
  press's `p.time` "is turned into play-clock time when it arrives". The cases will follow R8a (compare in play
  time; `r0` reported in play time). Can R3's sentence say so, so that a reader of R3 alone doesn't compare uptime
  with play time?
- **PQ-Q2, tick before press in the same frame.** When a tick and a press share a frame time, the cases run them
  in step order. Is "tick first, then the frame's events" or "events, then tick" the rule? R5 says the tick comes
  "before drawing" but not relative to input callbacks. It changes whether a press at exactly `r0 + holdEff` with
  a queue starts or queues.
- **PQ-Q3, settle and `formedAt`.** On a panel or background settle, the reveal "settles to formed with its hold
  passed". What are `formedAt` and so `restingSince` then: the settle time? And is `restingSince` published during
  Panel open, which affects the Parade (parade-v1 reads it)?
- **PQ-Q4, the formed timeout.** Is `now ≥ r0 + revealLen + formed_timeout_s` inclusive at equality? The cases
  will test both sides of it.
- **PQ-Q5, `started.item`.** R4's outcome carries `item`. The contract compares only `castId`. Is anything else of
  the item part of the queue's contract?

## 4. How each contract gets written (both)

1. QC writes `spec.md` and the hand-written cases from the GDD sections above, with each `source` a
   `"gdd: <file> <section>"` (ADR-0004 D7).
2. The fixture-expanding generator is kept out of the repo, as in TASK-068. The cases are re-derived by an
   independent throwaway reference before sending, and the result is reported.
3. Questions IF-Q* and PQ-Q* go to the owner first. Any case that depends on an answer waits for it; nothing is
   guessed.
4. `sources.lock` is cut from `.claude/scripts/review-receipts.sh sections-hash`, keeping only the cited `##`
   sections.
5. Review by game-dev-ios from the diff. Merge as v1, which is then immutable (ADR-0004 D6).

**Effort:** about 1 session for input-filter-v1 and 1 for press-queue-v1, after the owner's answers.
