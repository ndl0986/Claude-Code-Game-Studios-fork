# TASK-054 follow-up batch

**054a merged 2026-11-18 (fe63267): S1, S2, I1–I4, H1, A1.** Remaining for 054b: C1, C2, R1, P0, P1, V1, I5, L1. (queued by game-leader, 2026-11-18)

Small edits to Approved GDDs, collected while the last MVP GDDs were written. Send as one task once
TASK-048, TASK-051 and TASK-052 are merged. Each GDD gets a dated "no re-review" log entry with a receipt.

## Settings Store
- S1: R10 sends one change notification for a run-only OFF of the Mac child lock (no write, or a write
  that keeps `childLock: true`). Child Lock-in needs it to disengage. (game-qc-ios)
- S2: define the run value explicitly as `childLockActive` (= stored `childLock` at launch; OFF changes only
  the run value, K-21). Parent Gate and Child Lock-in use this name. (leader call)

## Input & Key Filter
- I1 (safety; either route is fine as long as Parent Gate AC-27's stale-key case passes): R6 "no other key held" must not trust a held set that lost a key-up while ⌘ was held:
  read the OS key state at the Q down (e.g. CGEventSource keyState), or clear ⌘-pressed keys on the ⌘
  flagsChanged release. A stale key must never block the kiosk way out. (game-qc-ios)
- I2: Layer 3 emits `gateTouch(ended)` when the pointer leaves the moon region + 20 pt of slop. (game-qc-ios)
- I3 (safety): while `childLockActive`, ⌘-combinations are swallowed in every state, Gate challenge and
  Panel open included (⌘Q must not skip Quit's 1.5 s hold). (game-qc-ios, game-dev-android TASK-052)
- I4: a wrong answer or timeout returns to the state the gate opened from (Title or Play); the chord works
  on Title and is ignored in Panel open. (game-qc-ios)

## Cast Rendering
- C1: per-look glyph and creature changes keyed by the Scene's `look` + `lookBlend`, taking the Scene GDD's exact
  list so its 160-case build check and Cast Rendering share one edge model: amber 6 px outline and
  saturated halo in Morning/Day; at Night the palest stop dropped, halo at 70%, creature 15% dim; blends
  with lookBlend (art bible §2). (game-dev-ios takes it)
- C2: add the Scene's worst case (snow 60 + windy) to the R11 device measurement run.

## Reveal Stage
- R1: publish `mashing` (Press Queue snapshot queue length ≥ 1, or an ignored press in the last 1 s) for the
  Scene's R3a weather halving; also publish `haloOn` (on through the glow phase, R5 timeline) for the Scene's
  halo fade-out. (TASK-053, game-dev-ios)

## Input & Key Filter (054b)
- I5 (text): in R6, the sentence "The chord replaces the moon hold only: the gate's second step…" is glued to the
  end of the "Limit of the held set alone" bullet; put it on its own line at the R6 level. (game-qc-ios)

## Child Lock-in
- L1: if 054a's TCC check removes the keyState read, R5's "judged from the OS key state" becomes "from the OS key
  state, or the held set kept honest by the ⌘-release rule". (game-qc-ios)

## Hint Letters
- H1: F5's "Mac 700-pt window, k 1.10" row cannot occur (App Shell minimum 960×540 pt → stage_to_px 1.5,
  22.5 mm, k = 1); correct the row and AC-7's k values. (game-dev-android)

## Parent Gate & Panel
- P0 (text): Dependencies name game-art-content as TASK-054 owner; 054a (Settings, Input) is game-dev-android.
  Already drafted by game-qc-ios as fc9bdef on design/TASK-048-gdd-parent-gate-panel (after the merge): the owner
  line and the covers in G7's Quit cell (matches TASK-052 R4). Merge that commit into the 054b branch and review it there.
- P1: the moon is the sky's only moon; it takes the Scene's `look`; daytime moon at 70% in Morning/Day.
  (TASK-053 Scene)

## App Shell & Title
- A1 (wording): AC-3 "in that order" → "all four, before the options" (preconditions arrive in any order);
  R7's reason → "would move focus away; Child Lock-in releases only on didResignActive". (game-dev-android)

## Privacy & Kids Compliance
- V1: the continuous clock used by App Shell R6 (ContinuousClock / mach_continuous_time) — check whether
  it needs a privacy-manifest required-reason entry (PKC-09 / system boot time API). (game-dev-ios)
- V2: L-07 (OS crash logs) stays Luan's call; App Shell cites it.

## Queued after TASK-060 / TASK-061 (next follow-up batch, TASK-062)
- Hint Letters: read the keyboard row band (y ≥ 582) as an F4 clearance box; note that with the row on the parade
  lane (448) visually overlaps the bottom hint slots, accepted (K-26 dims and stills hints). (TASK-060)
- Reveal Stage: list the keyboard row band next to its published boxes; set `accessibilityIgnoresInvertColors` on
  the stage view (with App Shell). (TASK-060, TASK-061)
- Cast Rendering: stardust twinkle steady under Reduce Motion; ambient idles change on the next frame (K-29).
- Reveal Stage: Reduce Motion rule for the tap / ignored-press sparkles (owner decides).
- App Shell + art bible: play-button breathe rate 0.38 vs 0.48 Hz; play button's physical touch floor.
- Every motion GDD: read Accessibility's `reduceMotion` flag, not the OS API.
- Reveal Stage R10: add the On-screen Keyboard Row at z 35 (above the current creature, below glyph/specks) to the draw-order line (ADR-0006 D1, TASK-070).
