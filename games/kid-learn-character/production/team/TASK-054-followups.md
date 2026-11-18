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
- **Done (TASK-054b, 12384c76: R10 publishes `haloOn` and `mashing`; checked in TASK-085a):** R1: publish `mashing` (Press Queue snapshot queue length ≥ 1, or an ignored press in the last 1 s) for the
  Scene's R3a weather halving; also publish `haloOn` (on through the glow phase, R5 timeline) for the Scene's
  halo fade-out. (TASK-053, game-dev-ios)

## Input & Key Filter (054b)
- I5 (text): in R6, the sentence "The chord replaces the moon hold only: the gate's second step…" is glued to the
  end of the "Limit of the held set alone" bullet; put it on its own line at the R6 level. (game-qc-ios)

## Child Lock-in
- L1: if 054a's TCC check removes the keyState read, R5's "judged from the OS key state" becomes "from the OS key
  state, or the held set kept honest by the ⌘-release rule". (game-qc-ios)

## Hint Letters
- **Done (TASK-054a, bc075e52; checked in TASK-085b):** H1: F5's "Mac 700-pt window, k 1.10" row cannot occur (App Shell minimum 960×540 pt → stage_to_px 1.5,
  22.5 mm, k = 1); correct the row and AC-7's k values. (game-dev-android)

## Parent Gate & Panel
- **Done (b11c8d4d, the fc9bdef content merged with TASK-048; owner line updated in ec2f6030; checked in TASK-085b):** P0 (text): Dependencies name game-art-content as TASK-054 owner; 054a (Settings, Input) is game-dev-android.
  Already drafted by game-qc-ios as fc9bdef on design/TASK-048-gdd-parent-gate-panel (after the merge): the owner
  line and the covers in G7's Quit cell (matches TASK-052 R4). Merge that commit into the 054b branch and review it there.
- **Done (ec2f6030, Parent Gate UI Requirements; checked in TASK-085b):** P1: the moon is the sky's only moon; it takes the Scene's `look`; daytime moon at 70% in Morning/Day.
  (TASK-053 Scene)

## App Shell & Title
- **Done (TASK-054a, bc075e52: AC-3 "in any order of arrival, before 'ready'", R7's didResignActive reason; checked in TASK-085a):** A1 (wording): AC-3 "in that order" → "all four, before the options" (preconditions arrive in any order);
  R7's reason → "would move focus away; Child Lock-in releases only on didResignActive". (game-dev-android)

## Privacy & Kids Compliance
- **Done (TASK-085a: App Shell R6 names ADR-0002 D3 `AwayClock`; `mach_continuous_time` is not a SystemBootTime required-reason API, so 35F9.1 stays PKC-09/AC-09's call):** V1: the continuous clock used by App Shell R6 (ContinuousClock / mach_continuous_time) — check whether
  it needs a privacy-manifest required-reason entry (PKC-09 / system boot time API). (game-dev-ios)
- V2: L-07 (OS crash logs) stays Luan's call; App Shell cites it.

## Queued after TASK-060 / TASK-061 (next follow-up batch, TASK-062)
- **Done (TASK-062, b384818b; checked in TASK-085b):** Hint Letters: read the keyboard row band (y ≥ 582) as an F4 clearance box; note that with the row on the parade
  lane (448) visually overlaps the bottom hint slots, accepted (K-26 dims and stills hints). (TASK-060)
- **Done (TASK-062, c4d4ef7b: R10 lists the band `y ≥ 582`; R1 sets `accessibilityIgnoresInvertColors` on the stage view, K-30; checked in TASK-085a):** Reveal Stage: list the keyboard row band next to its published boxes; set `accessibilityIgnoresInvertColors` on
  the stage view (with App Shell). (TASK-060, TASK-061)
- **Done (TASK-062, b384818b: R6 twinkle × 0.6 reveal-locked, R7 idles next frame with `idle_rm_ease_s`; checked in TASK-085b):** Cast Rendering: stardust twinkle steady under Reduce Motion; ambient idles change on the next frame (K-29).
- **Done (TASK-062, c4d4ef7b: R9 keeps the tap and ignored-press sparkles unchanged, leader's call; checked in TASK-085a):** Reveal Stage: Reduce Motion rule for the tap / ignored-press sparkles (owner decides).
- **Art bible side done (TASK-062, b384818b: §2 rule 2 reads ~~0.48~~ 0.38 Hz, dated; checked in TASK-085b); App Shell side done (TASK-062, c4d4ef7b: R2 keeps 0.38 Hz as played; R3: any tap except the moon starts play, so no physical touch floor; checked in TASK-085a).** App Shell + art bible: play-button breathe rate 0.38 vs 0.48 Hz; play button's physical touch floor.
- **Done (TASK-062, b384818b: all ten motion GDDs name "Accessibility's `reduceMotion` (its A1; never the OS API)"; checked in TASK-085b):** Every motion GDD: read Accessibility's `reduceMotion` flag, not the OS API.
- **Done (TASK-085a: R10's draw order names the row; the z values point to ADR-0006 D1's table):** Reveal Stage R10: add the On-screen Keyboard Row at z 35 (above the current creature, below glyph/specks) to the draw-order line (ADR-0006 D1, TASK-070).
- ~~Reveal Stage R3 table cells:~~ done (TASK-088c, 34ab7951). "true if the item has a word line" → "…in the active locale" to match the prose (TASK-088b nit, game-qc-android).
- ~~Reveal Stage F5 invalid-set row: state the glyph is drawn and fades out at fallback_glow_s~~ done (TASK-088b, 7d16be9d).
- ~~Reveal Stage invalid-set row: does the glyph's rise~~ done: fallback_rise_s 0.45 (TASK-088c, 34ab7951). use the invalid set's `letter_in` or a fallback value? (TASK-088b nit ii, game-qc-android stubs it as an input) — game-dev-ios.
- ~~Audio knob row (cut_settle_s Effect column):~~ done (TASK-093, c724f9ec). "stopped or paused" → "stopped" (TASK-090b nit, game-dev-ios) — game-art-content.
- ~~Audio R6: replace the quoted measured freeze-resume figure~~ done (TASK-100, 6bcd32be). with ADR-0010's final measured range (rewind cut_settle_s/2: ~5–20 ms heard again, never skipped; game-dev-ios sends the number after the final runs); rule and AC-21 unchanged — game-art-content, next Audio touch.
- App Shell R6 (v2 of app-shell-v1, on request): order of background notifications (Reveal settle, Audio cut, Hint clear, Parade drop, Input Inactive) and the list for a return to Play (not R4's entry) — game-dev-ios advisory, TASK-094.
- DeviceSpike Freeze continuity: add a second correlation just after resume (gain back to 1) to confirm heard content starts at 'from' (game-qc-ios note on ADR-0010) — game-dev-ios, next DeviceSpike touch; or P-7 records it by listening.
- Parade precise rules: drop "plus any batch keys beyond parade_count" (can't happen; batch never grows past 6) — game-art-content, next Parade touch (TASK-101a nit).
- Cast Rendering F6: 1024 px tier is a HEIGHT per R3 (full image 1490 × 1024), not a width; restate F6's per-set figure and its 1.5× cap (game-dev-android finding, TASK-103) — game-dev-ios, next Cast Rendering touch.
- F2 detector (Accessibility / P-3, M-12): take each frame's timestamp from the in-app dump, never assume an even display rate (the dump slows frames) — game-dev-android nit on TASK-106; check the F2 tool spec when it's written.
- Mouse-button pointer ids: other buttons numbered 2 + buttonNumber leaves ids 2,3 unused (harmless; tidy at next ADR-0007/adapter touch) — game-dev-android nit.
- Scaffold: the `LetterMorph` scheme's Test action leaves out LetterMorphUITests (TASK-109 used the `LetterMorphUITests` scheme); add it, or document the scheme in verify.sh — game-dev-android, next scaffold touch. Observation only: Dusk fill reads (61,77,129) on the Mac capture vs (70,85,143) on the iPad simulator (display colour profile likely).
- Voice script format (content/themes/dinosaurs/src/voice-scripts/en-us.json, TASK-110) is the first content/ file and ADR-0003 defines no voice-script format: game-dev-android (bake tool) confirms the shape before the bake reads it. quetzalcoatlus trims to ~1.22 s (V15 1.25 s): if the bake measures it over, faster speed for that line or a new respelling back to Luan's ear.
- TASK-111 advisory: TR-gate-006 grown-up panel accessibility gap; ADR-0012 Android (deferred, K-03); partials (idle-frequency lint, hint/panel contrast gate, hint knob validation, weather cost).
- Content validator: check the cross-knob constraint meter_fly_s − meter_land_s + meter_step_s ≤ parade_delay_s (Parade F4) instead of a note — game-dev-android (validator), with ADR-0003 validator rules. Press Queue R10's Parade example is superseded by Parade R2 (K-45) — owner at next touch.
- Prototype alignment after Luan's replay: meter light per Parade R12a (0.9 s from cast box top, sine ease, cell fill at launch+0.75) + any change from Luan's feedback — game-dev-ios.
