# Review log: design/gdd/parent-gate-panel.md

## Review — 2026-11-18 — Verdict: NEEDS REVISION (lean; 3 blocking items are contract and AC defects, no rule contradicts K-10, K-15, K-17, K-19, K-20 or K-21)
Review mode: lean · Workflow: standard
Task: TASK-048
Scope signal: L (about 9 dependencies, 2 formulas, 24 ACs, edits to 4 other GDDs queued in TASK-050 and 3 in-progress GDDs; the systems index says effort S, which looks low; producer to verify)
Specialists: none (lean). Independent first review; the author was game-qc-ios and this pass read the GDD cold.
Blocking items: 3 | Recommended: 11 | Advisory: 9
Summary: All 5 required sections are present (Overview, Detailed Design, Edge Cases, Dependencies, Acceptance Criteria), plus Formulas (required: F1 and F2 define thresholds and rates), Player Fantasy and Tuning Knobs. F2 and AC-04 recompute correctly (below). The design follows K-10, K-15, K-17, K-19, K-20, K-21, PKC-02 and PKC-07, and no path reaches a link out or a destructive action without the gate plus a 1.5 s hold at a separate spot. The blocking problems are interface and check defects. The Mac "off for this run" lock has no change event in the Settings Store. The moon-drift reset needs an Input event that does not exist. AC-09 contradicts G3. The recommended items are parent-frustration traps (a 10 s dead moon after Cancel, two-thumb rollover counted as wrong, no drift tolerance) and gaps in F2, the chord and VoiceOver.
Prior verdict resolved: First review

Completeness (standard): Overview ✓, Detailed Design ✓ (accepted for Detailed Rules), Edge Cases ✓, Dependencies ✓, Acceptance Criteria ✓ = 5/5 required. Formulas ✓ (required here, present). Advisory: Player Fantasy ✓, Tuning Knobs ✓.

Dependency graph: Settings Store, Input & Key Filter, Press Queue, Audio & Voice, Privacy & Kids Compliance, Key Table all exist. Child Lock-in (#13), Hint Letters (#10, TASK-047), Reveal Stage (#9, TASK-049), Parade (#11, TASK-046), Scene (#15), Keyboard Row (#16), Accessibility (#17) and Localization (#19) have no GDD file yet. The first four are in progress and the GDD names their tasks. Back-links to this GDD are due when they are written.

Registry values: no design/registry/ exists, so no registry check was run. Values were checked by hand against decisions.md K-10, K-12, K-15, K-17, K-19, K-20, K-21, Settings Store R1/R4/R8/R9/R10/R11 and F1/F2, Input R5-R7 and States, Press Queue R8/R9, Audio R5/R6, PKC-02/07/14 and L-04, ADR-0001 9b/9c, and art bible §3/§4/§7. Values restated in G7 (volume 0-10, `muted`, `weather`, `windy`, `keyboardRow`, `childLock`, Dusk Blue `#46558f`, 15-22 pt) match their owners.

Recomputed math:
- F2 per attempt p = 10^-4. T_min = 1.5 + 0.2 + 10 = 11.7 s, so 3600 / 11.7 = 307.7 and R_max = 307. P(307) = 1 - 0.9999^307 = 1 - e^(-0.030702) = 3.02%, which matches "~3.0%". P(10) = 0.0999%, P(6) = 0.060%. All correct.
- A "peek" is impossible: a new code is drawn at every opening, so a first-digit hit gives no information. Any strategy that ignores the code has p = 10^-4. Q4 (`t_tap`) hardly matters: with t_tap = 0, R = 313/h and P = 3.1%.
- AC-04 part 1: mean 200,000 x 10^-4 = 20, sigma = sqrt(20 x 0.9999) = 4.47, 3 sigma = 13.4, so the range is 6.6 to 33.4 and the integers 7-33. Correct.
- AC-04 part 2: expected distinct = 10,000 x (1 - 0.9999^1000) = 951.7, which matches "≈ 952". Variance ≈ 10,000 x [e^-0.1 - 1.1 e^-0.2] = 42.3, sigma ≈ 6.5. The stated 930-970 is not centred (-3.3 sigma, +2.8 sigma). A ±3 sigma band is 932-971.
- Timers: AC-01, AC-10, AC-12, AC-18 (110.3 s) and AC-17 agree with G1, G8 and G10. AC-09 does not (item 3).

Test of the child-safety questions:
- Destructive action: the gate is a 1.5 s still hold plus 4 correct digits, then a trigger, then a 1.5 s hold at a separate spot. Worst case is about 3% per hour of nonstop gate mashing (K-21, accepted).
- Link out: none (G7 says so; AC-21 covers it).
- Stuck frozen play: a challenge lasts at most 20 s per correct digit. Background closes it. Not unbounded.
- Panel left open: G10's burst rule has a slow-tap gap (item 10).

Findings:
- [BLOCKING] G11, Interactions (Settings Store row), AC-15, AC-19: "off for this run only; the stored value is not set to false" has no change event. Settings Store R10 fires only on a write, and Child Lock-in "applies the kiosk on the change notification". AC-15 also requires "exactly one write and one R10 notification" per row. No current text says how the kiosk learns of the off switch, and TASK-050's board line covers only "childLock reverts ON at launch". Fix: specify the interface in G11 and name it in TASK-050. Suggested form: the store holds a runtime `childLockActive` next to the stored `childLock`. Switch On sets both. Switch Off (after the G8 hold) sets `childLockActive = false`, sends one R10 notification and does not write. Reset clears the override. Relaunch with stored `true` engages per R8. Add an AC-15 exception row for "Child lock off: one notification, zero writes".
- [BLOCKING] G1 (reset on a move outside the moon's hit region), Interactions (Input row): Input R7 emits only `gateTouch(began)` and `gateTouch(ended)`, so the move-off reset cannot be observed, and no Input change is named. Fix: add to TASK-050 either "Input emits `gateTouch(ended)` when the tracked pointer leaves the moon region" or a `gateTouch(moved, point)`. Say who owns the moon's hit region (size and position) and give a minimum of ≥ 44 pt.
- [BLOCKING] AC-09: "GIVEN a keypad touch at 15 s, THEN it closes at 35.0 s" is true only if that touch is a correct digit. G3 closes at once on the first wrong digit, and a Cancel touch closes it too. Fix: "a correct first digit at 15 s → closes at 35.0 s; a wrong digit at 15 s → closes at 15.0 s". G3 should also say that touches outside the keypad and the card, and non-digit keys, are consumed and do not reset the 20 s timer. Add an AC for it.
- [RECOMMENDED] G1 moon sleep, G4, States: sleep also starts on Cancel and Esc, but K-20 names only a wrong answer or a timeout. On iPad (no chord) a parent who taps Cancel gets a dead moon for 10 s with nothing visible, and may think the app is broken. Fix: Cancel and Esc close without sleep. They make no guess, a new code is drawn at every opening, and F2 does not change. Add a line to the G1 text that a hold kept down through sleep opens the challenge at sleep end + 1.5 s. Keep sleep for wrong digit, second pointer and timeout.
- [RECOMMENDED] G3 One touch at a time, AC-06: two-thumb typing on an iPad often overlaps touches by tens of ms, and the GDD counts any overlap as wrong, which costs a 10 s sleep and a new code. Fix: add a knob `overlap_grace_s` (suggest 0.15). Overlap shorter than that is not "wrong", and a palm (sustained) still is. Add an AC with a 0.1 s overlap (accepted) and a 0.5 s overlap (wrong). This needs Luan's nod because it softens game-qc-android item 2.
- [RECOMMENDED] G1 reset on drift: any move outside the region resets `t_held` to 0 with no tolerance, which a trembling finger or a Mac mouse will trigger on a small corner moon. Fix: once down, the region extends by `moon_slop_pt` (suggest 20 pt). The hold must still be still for 1.5 s, so F2 is unchanged. Add an AC for it.
- [RECOMMENDED] G2, Input R6, AC-03: three gaps. (a) Input R6 says Shift is ignored and G2 says "no other key held", so the GDD must say Shift, Caps Lock and Fn do not count. (b) A key whose up event was lost (Input R4 "up missed", and macOS drops key-ups for some keys pressed with ⌘ held) stays in the held set. The chord then never matches, and with the kiosk on the grown-up is left with the moon as the only way out. Fix: judge "no other key held" from keys down in the last N s or from the OS key state, and add an AC with a stale held key. (c) F2 covers only the moon path, and the chord ignores sleep (G2), so its attack rate is undefined. State why a child cannot reach it: it needs three modifiers, Q and no other key. Or apply sleep to the chord's second step.
- [RECOMMENDED] G2: the chord pressed while the challenge, the panel or the Title screen is showing is undefined. Fix: ignored in Challenge and Panel (do not redraw the code or reset the 20 s timer). For Title, say whether the gate exists there (Input's Title state has no gate rule) and name TASK-050 or the App Shell GDD.
- [RECOMMENDED] G5, Interactions (Audio, Parade): the challenge freezes the parade walk but "no cut" for audio, so the parade tune (Audio E12) keeps playing while the walk is paused and ends out of step on resume. Fix: say in G5 that Parade pauses or holds the tune with the walk, and name TASK-046 (it is in REWORK) and the Audio GDD owner.
- [RECOMMENDED] G10: touches at less than 3 per 1 s window each reset the 60 s timer, so a child tapping the card every 0.6 s keeps the panel open without limit. Fix: add `panel_max_s` (suggest 300 s from open, extended only by a slider drag or a held confirm), or reset only on a tap that changes a control. Add an AC.
- [RECOMMENDED] Tuning Knobs, F2: the safe ranges break K-21's accepted figures. `moon_sleep_s` at 5 s gives T_min = 6.7 s, 537 attempts/h and P = 5.2%; `gate_hold_s` 1.0 with sleep 5 gives 580/h and 5.6%. `code_words` 4-6 conflicts with G3 (four digits) and the AC-05 regex `{3}`, and it is not tunable, because it is a build constant. Fix: put the resulting hourly P next to each range end, raise the lower bounds to hold ≤ ~3% (`moon_sleep_s` ≥ 10, `gate_hold_s` ≥ 1.5), and either drop `code_words` as a knob or make AC-05 use `code_words`.
- [RECOMMENDED] AC-04: part 1 tests the PRNG, not the gate (the success probability is assumed to be 10^-4). Part 2's 930-970 is not centred on 951.7 (see the math above). Fix: say "fixed seed S, fully deterministic", use 932-971 (±3 sigma), and keep a UI-level check, because AC-05, AC-07 and AC-08 already show the real entry path.
- [RECOMMENDED] VoiceOver and Reduce Motion: AC-23 only checks that the challenge opens. G3 enters a digit "on its touch down", but VoiceOver activates with a double-tap (an accessibility activation, not a raw touch), and VoiceOver's exploring touches could also trigger the second-pointer rule. Fix: state that each key also accepts accessibility activation, add an AC that completes the code with VoiceOver on, give the words an accessible label without "·" ("Enter four, one, seven, two"), and name where focus lands on open and close. Split AC-23 into a Reduce Motion AC and a VoiceOver AC. Switch Control users cannot hold; note it (advisory below).
- [RECOMMENDED] Acceptance Criteria gaps: no AC for Cancel and Esc closing, the background during a hold (`t_held` resets), G9 Esc and Back to play, Dynamic Type scrolling with the keypad size kept, the macOS Quit button absent when the lock is off, a Settings write failure, and PKC-14 (the code and the held pointer are never logged in release: code scan). Add one AC each.
- [ADVISORY] Interactions, Input row: `openPanel` now means "begin the challenge" (K-19). Ask TASK-050 to rename it (e.g. `openGate`) so Input's States table (`openPanel` enters Panel open) is not wrong.
- [ADVISORY] G9, Start over: the GDD does not say whether the panel stays open after Reset and whether its controls re-read the new record. Say so (suggest: stays open, controls refresh).
- [ADVISORY] G4/G9, UI Requirements: the card fade is 0.2 s and the dim fade 0.3 s, and the opening transition outside Reduce Motion is not specified. Give one opening timing.
- [ADVISORY] F1, AC-01/AC-10: say that `t_held` is measured from the began event timestamp (Input R8 clock) and evaluated per frame, so the challenge opens on the first frame at or after 1.50 s.
- [ADVISORY] G1, AC-02: when the first pointer lifts while a second is on the moon, say the second does not take over (it must lift and press again).
- [ADVISORY] F2, Q4: the "realistic ≤ 10/h" figure is an assumption (K-21 accepted it). Q4 can be closed, since t_tap = 0 changes P by 0.1 point only.
- [ADVISORY] Accessibility: Switch Control and AssistiveTouch users cannot hold for 1.5 s. Note it for the Accessibility GDD (#17), with no change here.
- [ADVISORY] Dependencies: Hint Letters, Reveal Stage, Parade, Child Lock-in, Scene, Keyboard Row, Accessibility and Localization GDDs do not exist yet; add their back-links to this GDD when they land (TASK-046, 047, 049).
- [ADVISORY] Systems index row 12 shows effort S and status Not Started; update to In Review (or Needs Revision) and reconsider S.

Reviewed-Content-Hash: design/gdd/parent-gate-panel.md 56ee9585934a3fc204eb14991af6c5d19c216ea5
review-receipts: not stamped, no such file: design/registry/entities.yaml
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/settings-store.md 6e2df80d2d4061d730f3e2cb322e8d9669e51359
Reviewed-Content-Hash: design/gdd/input-key-filter.md 14c4a9a102f93f6ed093d038b3dcc1387550e738
Reviewed-Content-Hash: design/gdd/press-queue.md f73cb9bd44f9d6ca15ca48975e5a43d77bb7870f
Reviewed-Content-Hash: design/gdd/audio-voice.md 1f3d8158975fa07f5bac347250674314dc0ac4f0
Reviewed-Content-Hash: design/gdd/privacy-kids-compliance.md a9e00c7a32009cd99a7d1597672c90132ba73d4e
Reviewed-Content-Hash: design/art/art-bible.md ff95ca81ce8e7a2adbf92f5ce92267c3fe355cda
Reviewed-Content-Hash: docs/architecture/adr-0001-native-apple.md 44e15a46a094d4d4f066b8476bfcfe8a97b43dda
Reviewed-Content-Hash: design/gdd/systems-index.md e4b8da5e4cc3353630b8ea281460e0d471186c24
Reviewed-Content-Hash: production/team/decisions.md cef7e6d8add4a57c0f8df35531c29f8c12fc3f1e


## Review — 2026-11-18 (re-review) — Verdict: APPROVED (lean; 0 blocking; 6 recommended items stay open and are small text fixes, one of them the deliberate Q5 decision for the leader and Luan)
Review mode: lean · Workflow: standard
Task: TASK-048
Scope signal: L (unchanged; producer to verify)
Specialists: none (lean). The whole revised text (462 lines) was re-read, not only the changed parts.
Blocking items: 0 | Recommended: 6 open (1 deferred by decision) | Advisory: 7 open
Summary: All 3 blocking items are resolved. The runtime `childLockActive` with a write-free R10 notification (G11), the `gateTouch(ended)` on leaving the slop region (G1) and the corrected AC-09 are each in the text, with an AC and a TASK-050 pointer. 9 of the 11 recommended items are resolved, and the overlap grace stays open as Q5 by design. The new knob-range figures recompute correctly. The revision introduced two small contradictions and one task-list gap (below): G9 returns to Play although the chord now also works on Title, F1 still says `gate_hold_s` is safe from 1.0, and the Dependencies section no longer mirrors the Interactions list. None of these blocks implementation.
Prior verdict resolved: Yes for all 3 blocking items. Of the 11 recommended: 8 Resolved, 2 Partly (the F2 chord path and the AC gaps), and 1 Open by decision (the overlap grace, Q5). The remaining recommended item, the parade-tune task, is Partly. Advisory: 6 Resolved, 1 Partly, 2 not author actions.

Disposition of the prior items (line numbers are the current text):
- B1 `childLockActive` / write-free R10: RESOLVED. G11 L196-203 (store keeps `childLockActive`, off sets it false, one R10, no write, Reset sets both false); Interactions L233; AC-15 exception L411-412.
- B2 moon-drift event: RESOLVED. G1 L55-61 (this GDD owns the hit region; Input emits `gateTouch(ended)` when the pointer leaves the region grown by `moon_slop_pt`; TASK-050); Interactions L232; AC-26 L439-441.
- B3 AC-09: RESOLVED. L391-394 (right digit at 15 s → 35.0 s; wrong digit → 15 s; outside touches → 20.0 s). G3 L117-120 (timer resets only on an accepted digit; max 80 s).
- R1 Cancel/Esc no sleep: RESOLVED. G1 L72-77, States L222, G3 L112, AC-10 L397, AC-25 L436-438. I checked F2: Cancel makes no guess and the next code is new, so p is unchanged.
- R2 overlap grace: OPEN, deferred on purpose. Q5 L462; the behaviour is documented at Edge Cases L313-314. This is the leader's and Luan's call. If accepted, it needs a knob, a row in G3 and two ACs (0.1 s accepted, 0.5 s wrong).
- R3 drift slop: RESOLVED. G1 L58-60, Tuning L340, AC-26 (15 pt outside holds, 25 pt outside resets, consistent with 20 pt).
- R4a Shift/Caps/Fn: RESOLVED. G2 L82.
- R4b stale held key: RESOLVED. G2 L83-86 (OS key state at the moment Q goes down), AC-27 L442-444.
- R4c F2 and the chord path: PARTLY. G2 L87-88 applies moon sleep to the chord and says "F2 covers both", but F2 (L264-279) still names only the moon path, and the chord has no 1.5 s hold, so it is not slower than the moon path. With about 0.3 s to press the chord, T = 10.5 s, 342 attempts per hour, P = 3.36%, against 3.02%. This is still near K-21's figure and needs a physical three-modifier chord, but "can't be tried faster" is wrong. Fix: add one line to F2 giving the chord figure, or reword L87-88.
- R5 chord during challenge/panel and on Title: RESOLVED for the chord. G2 L89-93, L94, Interactions L232 and L239, AC-27 L443-444. The side effect on G9 is a new item (N1).
- R6 parade tune: PARTLY. G5 L135-136 and Interactions L238 say the tune pauses with the walk, but the owner is given as "Audio owner, with TASK-046", with no task for the Audio change (Audio E12 says nothing on pause), and AC-13 does not test the tune. Fix: add "Audio: parade tune pause/resume" to TASK-050's line, and add the tune to AC-13.
- R7 panel hard cap and reset rule: RESOLVED. G10 L188-193, Tuning L344, AC-18 L419-421, AC-29 L446.
- R8 knob ranges: RESOLVED with one stale line (N2). Tuning L338-339 and L349-350 are right (recomputed below).
- R9 AC-04: RESOLVED. L377-380: fixed seed, same count every run, 932-971 (±3 sigma). The strict bound is 933 (932.2); 932 is 3.03 sigma, which is immaterial.
- R10 VoiceOver: RESOLVED. G3 L108-109, Edge Cases L301-306, AC-24 L433-435; Reduce Motion split out as AC-23 L431-432.
- R11 missing ACs: PARTLY. Added: Cancel/Esc and G9 close (AC-25), background during a hold (AC-26), Quit absent with the lock off (AC-28), PKC-14 (AC-30). Still missing: Dynamic Type scrolling with the keypad size kept (L307-308), and a Settings write failure (L294-295). Add one AC each.
- A1 `openPanel` rename: RESOLVED. L94, L232.
- A2 Start over: RESOLVED. L163 (the panel stays open and every control shows its default).
- A3 fade timings: RESOLVED. G4 L123-124 gives the opening and dim timings. The parenthesis is hard to read; split it into two sentences.
- A4 `t_held` clock: RESOLVED. G1 L62-63.
- A5 second pointer takeover: PARTLY. The rule is in G1 L67-68, but AC-02 does not test that the second pointer does not take over when the first lifts.
- A6 Q4 closed: RESOLVED. L461; with t_tap = 0, T = 11.5 s, 313 per hour, P = 3.08%.
- A7 Switch Control: RESOLVED. L310-312.
- A8 absent GDDs: still open, and not an author action (Hint Letters, Reveal Stage, Parade, Child Lock-in, Scene, Keyboard Row, Accessibility and Localization have no file; back-links are due when they land).
- A9 systems index row 12: still open (L70 says Not Started, L188 effort S); not part of the GDD, update when the leader merges.

Recomputed knob-range figures (p = 10^-4 per attempt, R = floor(3600 / T)):
- `gate_hold_s` 3.0: T = 13.2 s, R = 272, P = 2.68%; the text says ≈ 2.7%. Correct.
- `moon_sleep_s` 5 (out of range): T = 6.7 s, R = 537, P = 5.23%; the text says ≈ 5.2%. Correct.
- `moon_sleep_s` 30: T = 31.7 s, R = 113, P = 1.12%; the text says ≈ 1.1%. Correct.
- Defaults (1.5 and 10): T = 11.7 s, R = 307, P = 3.02%; unchanged. With t_tap = 0: R = 313, P = 3.08%, so Q4 is closed correctly.
- The lower ends (1.5 and 10) hold K-21's figure. All of the revised ranges keep P at or below 3.02%.

New findings from the revision:
- [RECOMMENDED] N1, G9 L181 and States L216-226: G2 now lets the chord open the challenge on the Title screen (L89-92), but G9 says "Input returns to Play" and the States table has only "Idle (play)". A challenge or panel opened on Title must return to Title: the held set is kept there, and `startPlay` is the App Shell's. Fix: say in G9 and in the States table that close returns to the state it was opened from (Title or Play), and that Press Queue clear, settle and freeze are no-ops when nothing is running. Add an AC for a chord on Title followed by Cancel.
- [RECOMMENDED] N2, F1 L257: the variable table still says `gate_hold_s` "safe 1.0–3.0", but the Tuning Knobs row (L338) says 1.5–3.0 and explains why 1.0 breaks K-21. Fix: change L257 to "safe 1.5–3.0". The F1 `asleep` row (L258) can read "after a wrong answer or a timeout" for the same reason.
- [RECOMMENDED] R2, R4c, R6 and R11 above remain the other open items.
- [ADVISORY] Dependencies L318-321 list only the old TASK-050 content (Gate challenge state, "no other key held"). The Interactions rows L232-233 now also list the slop `gateTouch(ended)`, the chord on Title and ignored in Challenge/Panel, the `openPanel` rename and `childLockActive`. Mirror them, and ask the leader to extend the TASK-050 board line (production/team/board.md L32), which names only "childLock reverts ON at launch", to include `childLockActive` with the write-free notification, the slop event and the Audio tune pause.
- [ADVISORY] G1 L55-57 and Tuning L340: "50 stage px, ≥ 44 pt on every supported screen" is not true for a small Mac window (a scale below 0.88 gives a radius under 44 pt; the diameter of 100 px stays above 44 pt down to a scale of 0.44). Say whether 44 pt applies to the radius or the diameter, or define the region as `max(50 stage px, 22 pt)`. `moon_hit_px` is a px knob in a pt-range row.
- [ADVISORY] G10 L192: the 300 s cap applies "whatever the input", so a parent reading the privacy page or holding a confirm at 300 s is cut off. A cap that waits for a finished slider drag or confirm hold would avoid it. Also add the constraint `panel_max_s` ≥ `panel_idle_s` (ranges 120–900 and 30–300 allow idle > max).
- [ADVISORY] AC-03 and AC-27 have no case for Shift, Caps Lock or Fn held with the chord (G2 L82). AC-19 does not assert that the stored `childLock` stays true after the off-for-this-run switch.
- [ADVISORY] The numbering is intact: AC-01 to AC-31, and the internal references (AC-05, AC-08, G9, G11) resolve. The Android AC moved from AC-24 to AC-31.

Reviewed-Content-Hash: design/gdd/parent-gate-panel.md 7dd9651110e2a5ff8128b948fce40c1fcfc4c75c
review-receipts: not stamped, no such file: design/registry/entities.yaml
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/settings-store.md 6e2df80d2d4061d730f3e2cb322e8d9669e51359
Reviewed-Content-Hash: design/gdd/input-key-filter.md 14c4a9a102f93f6ed093d038b3dcc1387550e738
Reviewed-Content-Hash: design/gdd/press-queue.md f73cb9bd44f9d6ca15ca48975e5a43d77bb7870f
Reviewed-Content-Hash: design/gdd/audio-voice.md 1f3d8158975fa07f5bac347250674314dc0ac4f0
Reviewed-Content-Hash: design/gdd/privacy-kids-compliance.md a9e00c7a32009cd99a7d1597672c90132ba73d4e
Reviewed-Content-Hash: design/art/art-bible.md ff95ca81ce8e7a2adbf92f5ce92267c3fe355cda
Reviewed-Content-Hash: docs/architecture/adr-0001-native-apple.md 44e15a46a094d4d4f066b8476bfcfe8a97b43dda
Reviewed-Content-Hash: design/gdd/systems-index.md e4b8da5e4cc3353630b8ea281460e0d471186c24
Reviewed-Content-Hash: production/team/decisions.md cef7e6d8add4a57c0f8df35531c29f8c12fc3f1e

## Author follow-up — 2026-11-18 — after the re-review (APPROVED stands)
Task: TASK-048
- Open 2: F2 now has a row for the Mac chord: no hold, T ≈ 10.5 s, ~342/h, ~3.4%/h. This is slightly above K-21's ~3%, so it is flagged as Q6 to the leader and Luan, with the option of a 1.5 s chord hold (≈ 2.96%). G2 is reworded.
- Open 3: the parade tune pause/resume is named on the TASK-050 line (Dependencies) and in AC-13.
- Open 4: added AC-32 (Dynamic Type) and AC-33 (a Settings write failure).
- Open 5: G9 now closes back to the state the gate was opened from (Title or Play). Added AC-31.
- Open 6: F1's safe range for gate_hold_s is now 1.5–3.0.
- Advisories:
  - Dependencies now mirror the TASK-050 list.
  - The moon's 44 pt is a diameter.
  - panel_max_s lets a drag or hold finish first, and panel_max_s ≥ panel_idle_s.
  - AC-02 covers no takeover; AC-03 covers Shift and Caps Lock; AC-19 checks that the stored childLock stays true.
- Child Lock-in interface (TASK-052 plan review), all in G7 and G11:
  - engage on panelDidClose, disengage at once;
  - challenge and panel drawn in the main window;
  - ⌘ swallowed in every state while locked (TASK-050);
  - Quit = disengage, then terminate;
  - the "Child lock couldn't turn on" line (K-23);
  - the "Guided Access is on/off" line, read from guidedAccessEnabled.

  These are covered by AC-34 and AC-35, and the Android AC is now AC-36.
- Still open by decision: Q5 (overlap grace), Q6 (chord hold).
Post-fix GDD hash: b0a5f62ef9d271ca2ab3c970cfe8d52b41752cae

## Author follow-up — 2026-11-18 — game-qc-android independent read (REVISE, 1 must-fix: bookkeeping)
Task: TASK-048
- Must-fix: four changes were credited to the merged TASK-050 but aren't in the merged docs. They are now the open follow-up **TASK-054** (owner game-art-content):
  - S1/S2: childLockActive and its write-free OFF notification;
  - I1 (safety): the chord judged from OS key state;
  - I2: the moon slop gateTouch(ended);
  - I3 (safety): ⌘ swallowed in every state while locked;
  - I4: the chord on Title, and returning to the origin state.

  The Dependencies have a release-blocking note: AC-27 and AC-34 can't pass until I1 and I3 land, and AC-15/19, AC-26 and AC-31 depend on S1/S2, I2 and I4. These were checked as actually merged in TASK-050: Press Queue freeze, the Audio parade-tune pause, the Input Gate challenge state, and the exact chord from the held set. G11 and AC-15 stay as written (the leader's childLockActive model).
- Q5 is closed: game-qc-android's lift grace is in. A second keypad down counts if the first lifts within overlap_grace_s 0.15 s; otherwise it is wrong. A third pointer is wrong. F2 is unchanged. Added the knob and AC-36.
- Q6 is closed as (a); F2 already states ~3.4%/h.
- Nits:
  - The hint-over-moon edge case is now a fallback that Hint Letters F4 prevents.
  - Moon sleep runs on the continuous monotonic clock across the background. Added AC-37; the Android AC is now AC-38.
Post-fix GDD hash: 5aaead63265fa8072bf415160a669e1607cd8665
