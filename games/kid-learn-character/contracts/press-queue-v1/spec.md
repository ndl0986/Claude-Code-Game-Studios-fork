# press-queue-v1

**Owner GDD:** `design/gdd/press-queue.md`. **Layer:** KidCore. **ADR:** ADR-0004 (D1, D4), ADR-0002 (D3, D7.2).
**Cases:** hand-written by game-qc-android (TASK-081), reviewed by game-dev-android (the GDD's author).

## What it covers

- **R2** state and the `revealId` counter (from 1, no gaps).
- **R3 / F2** accept, queue or ignore: never jumping a queued key, out-of-order stamps, the first press after the
  Title.
- **R4** the outcome in the callback; **R5** `tick` (the formed timeout, then at most one advance).
- **R6** `startReveal` and the locked `holdEff`; **R7** the `formed` rules.
- **R8** panel; **R8a** gate freeze and resume; **R9** background; **R10** `restingSince`; **R11** the queued keys
  in order; **R12** sources are equal.
- **F1:** every table row, the missing-`voiceDurations` bound, `hasWord` false, a long fallback.
- **F3** mash; **F4** worst wait; **F5** Reduce Motion locked at start.
- **AC-1–15, 17, 18, 20, 22, 23, 24.**

**Not covered here, and why:**
- **AC-16 theme switch:** the item comes from Key Table's resolve (key-table-schema-v1). The queue passes `castId`
  through and never reads it (PQ-Q5).
- **AC-19 hint on overflow:** an integration test with Hint Letters; hint-letters-v1 owns the hint's reaction.
- **AC-21 queue-data validation:** ADR-0003's content validator at build.
- **`formedS` and `revealLen` themselves:** reveal-timing-v1. Here they come from a stub.

## Clocks

Cases give **uptime only**. The play clock is **uptime minus the time spent frozen (`freeze` … `resume`) or in the
background (`background` … `foreground`)** (R8a, Reveal Stage R8). Every time the queue reports or keeps (`r0`,
`holdEff` boundaries, `formedAt`, `restingSince`) is play-clock time, and a press's own stamp is converted on arrival
(R3, TASK-082). A `play` field never appears in a case (case-schema-v1 S13). Both comparisons are inclusive (`≥`,
R5, TASK-082).

**Exact boundaries:** cases that test `≥` at equality use dyadic stub lengths (`formedS` 2.5, `revealLen` 3.0,
word 0.5, so `holdEff` = 3.25), so the sum is exact on every platform. The F1 table rows use the GDD's own values,
which aren't dyadic, so they assert `holdEff` within the `time` tolerance and never compare at a boundary.

## `given` fields

- **`reveal`:** key → the fake Reveal Stage and Key Table answer for a reveal of that key:
  - `formedS`, `revealLen`, `hasWord`;
  - `castId` (passed through);
  - `wordLen` (the key's `voiceDurations` value; absent means the entry is missing);
  - an optional `reduced: {formedS, revealLen}`, used when Reduce Motion is on at the reveal's start.
- **`knobs`:** overrides of `hold_s` 3.0, `queue_max` 3, `formed_timeout_s` 1.0, `word_offset_s` 0.25,
  `hold_ext_max_s` 1.5.
- **`accessibility`:** `{reduceMotion}` at the start (default false).

## Events

| Event | Fields | Meaning |
|---|---|---|
| `press` | `key`, `source` (`hardwareKey`, `hint(<id>)`, `keyboardRow`), `origin`? (stage point), `stampLag`? | Input's R8 event. Its stamp is `t.uptime − stampLag` (default 0): the one way a case states an out-of-order stamp, since `t.uptime` never decreases (S16) |
| `tick` | — | `tick(now)`, with `now` = the play time of `t.uptime`. It's an event in delivery order like any other (R5, TASK-082) |
| `formed` | `revealId` | the Reveal Stage reports formed |
| `freeze`, `resume` | — | the gate challenge opens / closes without the panel (R8a) |
| `panelOpen`, `panelClose` | — | R8: clear and settle on open. A challenge's freeze ends when the panel opens. The panel is not a freeze |
| `background`, `foreground` | — | R9: clear and settle; background time doesn't count |
| `accessibilityChanged` | `reduceMotion` | affects only reveals that start afterwards (F5) |

## Outputs

Each step's outputs come in this order.

| `out` | Fields | When |
|---|---|---|
| `startReveal` | `revealId`, `key`, `source`, `origin` (null for a hardware key), `r0` | the queue calls the Reveal Stage (R6): first, on every start |
| `log` | — | a debug log line: a missing `voiceDurations` entry (after `startReveal`, before the outcome), or the formed timeout |
| `started` | `revealId`, `r0`, `castId` | a press that starts at once (R4) |
| `queued` | `index` (0-based) | |
| `ignored` | — | |

A tick that advances the queue emits `startReveal` only, since there's no press to return an outcome to. Clears
(panel, background) emit nothing for the dropped presses (AC-14).

**State (`expectState`):**
- `current` (`revealId`, `key`, `holdEff`, `formed`, `formedAt`);
- `queueKeys` (in order, R11);
- `restingSince` (`null` when none, R10);
- `nextRevealId`.

**Field kinds:** `r0`, `holdEff`, `formedAt` and `restingSince` are `time` (1e-9). There are no other doubles.

## Answers from the GDD author (TASK-080 PQ-Q1–Q5; written into press-queue.md by TASK-082 @ 143a4167)

- **PQ-Q1:** compare in play time (R3, R8a).
- **PQ-Q2:** delivery order, with `tick` as an event. Both orders at the boundary are tested
  (`PQ-Q2-tick-first-at-boundary`, `PQ-Q2-press-first-at-boundary`). An empty-queue press at exactly
  `r0 + holdEff` starts.
- **PQ-Q3:** on a settle, `formedAt` is the settle's play time, `restingSince = formedAt`, and it's published while
  the panel is open (`AC14-panel-clears-and-settles`).
- **PQ-Q4:** inclusive, tested on both sides (`AC11-formed-timeout-inclusive`, `AC2-…`).
- **PQ-Q5:** only `castId` passes through.

The cases are written to these answers. If TASK-082 isn't merged when this contract merges, `sources.lock` is cut
again after it.
