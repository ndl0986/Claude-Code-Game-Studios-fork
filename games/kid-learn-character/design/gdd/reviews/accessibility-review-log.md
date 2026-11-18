# Review log: design/gdd/accessibility.md

## Review — 2026-11-18 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Task: TASK-061 (systems index #17, Accessibility, Meta, Vertical Slice)
Scope signal: M (producer should verify before sprint planning)
Specialists: none (lean; single-session analysis, run non-interactively for a teammate)
Blocking items: 2 | Recommended: 7 | Advisory: 8
Completeness: 5/5 required sections present, plus Formulas (numeric rules present); Player Fantasy, Tuning Knobs, UI Requirements, Open Questions also present.
Prior verdict resolved: First review
Non-interactive defaults taken: no AskUserQuestion widgets shown; no tracking updates made (systems-index.md not touched); only this log was written; no registry exists (design/registry/entities.yaml absent), so cross-document facts were checked against the named source GDDs directly.

Summary: The collected Reduce Motion rules (A3), the pulse table, the A2 timing rule (K-29) and the F1/F2 arithmetic (field 52.5 mm; px at 264/254/109 ppi; 51 hex values; 0.604 / 0.781 maxima) all check out against their sources. Two defects sit in the gate itself: the 10-degree field is modelled as a square, which makes area_max about 27% looser than the WCAG .006 sr figure the GDD claims to match, and the F2 detector leaves the transition and window definitions open enough for two implementations to disagree. Seven recommended fixes cover a twinkle-timing contradiction, broken table pipes, an unneeded play-button floor, unsourced keyboard-row numbers, new rules asserted under this GDD's name (PKC-14 extension, A10 scope calls), and the F2b scope and blend wording.

Findings:
- [BLOCKING] F2 "The 10° field" and AC-06: area_max = 0.25 * field_px^2 uses a square of side 2*d*tan5 (0.0306 sr), so area_max is 0.00765 sr, not the .006 sr WCAG figure. The "Check" line validates a circular cap (2*pi*(1-cos5) = 0.0239 sr, 25% = 0.00598 sr), not the table. Fix: area_max = 0.25 * (pi/4) * field_px^2 (circle-equivalent): 58,449 / 54,105 / 9,964 px at 264 / 254 / 109 ppi. Update the table, the 80,000 / 70,000 px example (70,000 then also FAILs), AC-06 (also state the rounding: field_px rounded for display, area_max from the unrounded value), and the Tuning Knob wording. If the square is wanted, drop the ".006 sr" claim and record it as a decision by Luan.
- [BLOCKING] F2 "The measurement" and AC-07: the detector is under-specified. (a) "adjacent peak-to-valley change" gives no extremum rule (noise, minimum swing, which frame stamps a transition); (b) "1 s window ending at frame t" is open or closed (60 or 61 frames); (c) flashes = floor(transitions/2) lets a sustained 3.5 Hz flicker (7 transitions per second) pass, but WCAG's "more than three flashes" is 3.5 > 3. Fix: define a zig-zag extremum (a reversal of at least 0.1 from the running extreme registers a transition at the extreme's frame, applying min(L) < 0.80 to the pair); window = half-open (t-1 s, t], exactly 60 frames; fail when transitions/2 > 3 with no floor (7 or more); add AC-07 cases: 3 Hz passes at every phase offset, 3.5 Hz FAILs, 0.1 swing in noise passes.
- [RECOMMENDED] A2 / A3 / Interactions / AC-03 / Edge Cases: the stardust twinkle is "next frame" in A3 and Interactions but is missing from A2's ambient list. The specks only exist during a reveal, and AC-03 / Edge Cases say a running reveal keeps its locked set. K-29 does not classify the twinkle. Fix: list it explicitly and pick one (conservative default: reveal-locked, next reveal, with idles on the next frame), then add it to AC-03. Also unify the "When" wording: Hint Letters and Parent Gate say "at once" in A3 while A2 says "next frame" (moon ring).
- [RECOMMENDED] Lines 107 and 234: `|sin(7t + i)|` and `|sin(ω t)|` inside table cells split the cell in GFM; the pulse table and the F1 variable table render wrong. Fix: write `abs(sin(7t + i))` or escape `\|`.
- [RECOMMENDED] A7(a) table and Follow-ups: "Title play button: no physical floor stated" is a non-issue. App Shell R3: any tap except the moon starts play, so the button is not a precise target. Fix: delete the row and the "state the play button's physical touch floor" half of the follow-up; keep the 0.38 / 0.48 Hz flag.
- [RECOMMENDED] A7(a) Keyboard row key "128 units ... random short common word, <= 9 keys": K-29 gives only "<= 9 distinct keys at the 18 mm floor"; the Keyboard Row GDD (onscreen-keyboard-row.md) is not on disk. "128 units" has no source. Fix: remove the number or cite it once the GDD lands; keep AC-12's 18 mm test as the check.
- [RECOMMENDED] A11 and AC-16: PKC-14 covers logging the child's input in release builds (debug builds may log to the console), not accessibility settings. "No accessibility setting is stored, logged or sent (PKC-14)" and "no log line mentions an accessibility setting" extend the rule under this GDD's name. Fix: scope AC-16 to release builds, cite PKC-01 / PKC-05 for storage and network, and add a Follow-up row asking the Privacy owner to add the accessibility flag to the PKC-14 scan.
- [RECOMMENDED] A10 and A9: "Increase Contrast not supported", "Reduce Transparency no effect", "Captions: none", "Bold Text follows Dynamic Type" are new scope calls with no owner or K-id; only Smart Invert is a leader decision, and it is not in production/team/decisions.md. Fix: label the others "proposed, for Luan or the leader to confirm" (or have Luan confirm them), and record Smart Invert as a K-id so AC-15 has a source.
- [RECOMMENDED] F2b: (1) the 51 art-bible hexes check out (8-bit max 0.604 #80450f; linear max 0.781 #b9631c), but the game also uses colours outside the art bible's hex list (#3b2f45, #d9a070, #ffd27a, rgba(255,200,90); all low ratio) and creature SVG art, so the check should run on the shipped palette, theme data and SVG fills, not the art bible text. (2) "A blend ... can't exceed its highest component's ratio" is the mediant property: true for alpha blending in linear space measured in linear, for gamma blending measured in gamma, and for additive glow in the same space. It is not guaranteed for a gamma-space blend measured in linear (nonlinear map); a numeric check of every pair of the 51 colours at 1% steps gave a max of 0.7805, below Letter Gold's own 0.7806, but a triple blend or screen / multiply blend modes are unproven. Fix: say "in the space where it is measured; the F2 per-pixel log backstops the rest", and extend AC-09 to the shipped data.
- [ADVISORY] A3 App Shell row cites "(Title motion, F)": use App Shell R2 (Motion) and F2.
- [ADVISORY] A3 omits the Parent Gate's lock notice, which disappears (no fade) under Reduce Motion (Parent Gate G4, line 207 of that GDD).
- [ADVISORY] Follow-ups cite "K-29 Q1 / Q3"; decisions.md K-29 has no numbered questions. Cite the bullet instead.
- [ADVISORY] A8 documents Switch Control / AssistiveTouch (K-29) only here; add a Follow-up for the Parent Gate GDD to note it where the 1.5 s hold is defined.
- [ADVISORY] systems-index #17 lists 5 dependencies and status Not Started; this GDD's Dependencies list 12 systems. Update the index on approval.
- [ADVISORY] AC-01 ("code review plus test"), AC-11, AC-14 and AC-15 are screenshot or review evidence, not automated; acceptable as UI / Visual evidence (retained), but label them manual.
- [ADVISORY] ppi table covers only 264 / 254 / 109; iPad mini (326 ppi) is out of MVP scope, and the "computed from ppi" Edge Case already covers it.
- [ADVISORY] Open question: the A4 claim "Nothing in the game flashes" sits beside a 2.2 Hz halo and 2.2 Hz bob; wording "never flashes" in Overview should say "stays under three flashes per second and changes blur, not brightness" to match art bible rule 1.

### Verified without findings
- F1 rates: halo sin(14t) 2.228 Hz; twinkle 9 / 2pi = 1.432 Hz; bob |sin(7t)| 7 / pi = 2.228 Hz; hint pulse 4 / 2pi = 0.637 Hz; hint drift 0.7 and 1.3 rad/s = 0.111 and 0.207 Hz; babies |sin(3t)| 0.955 Hz; breathe 0.33 Hz; title sin(2.4t) 0.382 Hz (the art bible's 0.48 Hz matches sin(3t) = 0.477, as flagged).
- F2 field: 2*300*tan5 = 52.49 mm; field_px 545.6 / 524.9 / 225.3; area_max (square) 74,419 / 68,888 / 12,686 as stated (blocking item concerns the model, not the arithmetic).
- A3 rows and rule numbers match: MorphCore Rule 8 and Q3 (reduced T 1.2, glow 0.4); Reveal Stage R9; Cast Rendering R5 / R7 / R8 (halo_steady 0.8, x0.7 Night, idles x0.5, hop 13); Hint Letters R10 (0.3 s consume fade; R9 "at once"); Parade R7 / K-17; Scene R8 / R3a (x0.25 stack); Parent Gate UI Requirements / G4; Press Queue F5 / K-15 (hold 3 s); Audio R1; Settings Store R2 (read live, never stored). A5 numbers match K-25 and art bible section 4. A7 and A8 numbers match Hint Letters F5 and Parent Gate G1 / G3 / G7 / AC-24 / AC-32. A9 matches K-13 and Audio R4.2, R5, R6.
- A2 matches K-29 (reveal-locked from next reveal; clouds, hints, parade, idling creature next frame); the additions (title breathe, moon ring, rain and snow, stars) are consistent extensions, subject to the twinkle item above.
- Follow-ups are complete against the A3 flags except the items noted above. NOT ASSESSED items are labelled (Android, AC-08 device time, AC-17, VoiceOver on stage, bold weight).
- Dependency graph: all collected-from GDDs exist; onscreen-keyboard-row.md does not (TASK-060 in progress). No registry file exists.

Reviewed-Content-Hash: design/gdd/accessibility.md 8b8059a9880bdf4f4d4752baa9c64e6bdfff5b13
review-receipts: not stamped, no such file: design/registry/entities.yaml
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/art/art-bible.md 3b829e1421f7eaa12e72cf7394b3947a42df7b63
Reviewed-Content-Hash: design/gdd/morphcore.md 936291c0a2a5e5e3df31fba9f300df58920d4adb
Reviewed-Content-Hash: design/gdd/reveal-stage.md d6c0206ac4d61e436e04064edaf3c5f17405aca5
Reviewed-Content-Hash: design/gdd/cast-rendering.md dd6e05e7ee77cf26f2d7ae0e71e3239c515d414b
Reviewed-Content-Hash: design/gdd/hint-letters.md 61ee882c83b3075f1b3221a6167fdb308a1040d3
Reviewed-Content-Hash: design/gdd/parade.md 1635d85de1ff5176df125b7a673418f883a2eac6
Reviewed-Content-Hash: design/gdd/scene-time-weather.md 3ec3f5a7be060a8661c26e139282eeeca277347c
Reviewed-Content-Hash: design/gdd/app-shell-title.md 2e7f2ef9dcdbcd02cd50078c115cb7035a3b7749
Reviewed-Content-Hash: design/gdd/parent-gate-panel.md 0576d85a17b704c4e8909134524c669e51c43024
Reviewed-Content-Hash: design/gdd/press-queue.md d8d2ac774eeff254e1e18f65d9ab9b76ec0d80e5
Reviewed-Content-Hash: design/gdd/audio-voice.md 54410d1a1974580736d15e121d0ad14fd4f5d306
Reviewed-Content-Hash: design/gdd/settings-store.md 2ddae72ca6a1ec7067b369e04e1056c9a0148edc
Reviewed-Content-Hash: design/gdd/privacy-kids-compliance.md 6ee522cecceb875f3ab354617121da1a14980ad2
Reviewed-Content-Hash: design/gdd/game-concept.md 5a150a0e8ee9e4c4bed1749196abf72271d4d8e8
Reviewed-Content-Hash: production/team/decisions.md 7cbcab5bfc439d11f9879c6c404bd4666da33c97

## Author follow-up — 2026-11-18 — after the first review (no re-review requested; for game-qc-android's independent read)
Task: TASK-061
- B1: F2 now uses a circular 10° field: area_max = 0.25·(π/4)·field_px², from the unrounded field_px. The figures are 58,449 / 54,105 / 9,964 px, the 0.006 sr check is restated, and the example and AC-06 are updated.
- B2: the detector is now a zig-zag rule (a reversal of ≥ 0.1 from the running extreme, with the darker side < 0.80) over a half-open 60-frame window. FAIL at > 3 flashes, i.e. ≥ 7 transitions. AC-07 adds 3 Hz at every phase, 3.5 Hz failing, and sub-threshold noise passing.
- R1:
  - The twinkle is classified as reveal-locked (author's classification; K-29 doesn't list it), in A2, A3, Interactions and AC-03.
  - "At once" is unified to "next frame".
- R2: abs(sin(...)) replaces |sin(...)|, whose pipes broke the tables.
- R3: the play-button floor row and its follow-up are dropped, because any tap except the moon starts play (App Shell R3). The 0.38/0.48 flag stays.
- R4: the keyboard-row "128 units" is removed; it will be cited from onscreen-keyboard-row.md when that lands.
- R5: A11 and AC-16 are scoped to release builds with PKC-01/05, and a PKC-14 extension follow-up is added.
- R6:
  - A10/A9 scope lines are labelled "proposed, to confirm".
  - Smart Invert is marked as a leader decision, to be recorded as a K-id.
- R7: F2b's blend claim is restated as "same space" (the mediant property). Its scope is extended to the shipped palette, theme data and SVG fills, and AC-09 is extended.
- Advisories:
  - App Shell R2/F2 cite.
  - The Parent Gate notice row.
  - K-29 bullet cites.
  - Switch Control and PKC-14 follow-ups.
  - Manual-evidence labels on AC-01/11/14/15.
  - The Overview's "never flashes" wording.
- Not changed: the systems-index dependency list (not ours to edit); iPad mini is out of MVP scope.
Post-fix GDD hash: ebffd9e2a9f3953512b6913990b087950269a733

## Update — 2026-11-18 — K-30 and the Keyboard Row (no re-review)
Task: TASK-061
Change:
- Smart Invert now cites K-30.
- A10/A9 drop the "proposed, to confirm" labels and cite K-30 (Reduce Transparency, Increase Contrast, Bold Text, captions).
- F2b states the Letter Gold margin, which K-30 notes for the art bible owner.
- A7 restores the keyboard-row row from onscreen-keyboard-row.md (444e2a9): a 144 × 134 u hit rect meets the 18 mm floor (its F2), and the word is capped at 8 letters (its V17, within K-29's ≤ 9).
- AC-12 now cites Keyboard Row F2, and its follow-up row is removed.
Reviewed-Content-Hash: design/gdd/accessibility.md 47a61c595bbae74d3740e75cac338093399daf17

## Update — 2026-11-18 — game-qc-android nits after APPROVE (no re-review)
Task: TASK-061
Change: A7 cites Key Table V17. F2 captures at the display refresh rate (60 or 120 Hz on ProMotion; recorded per run), with the window being the frames in (t − 1 s, t]. AC-07 and AC-08 match.
Reviewed-Content-Hash: design/gdd/accessibility.md 4cc7c647cc87a9deb798a2f73a0dc5f20b0acdfa

## Update — 2026-11-18 — TASK-065 follow-ups done in TASK-062 (no re-review)
Review mode: lean · Workflow: standard
Task: TASK-065
Change:
- A1, A2, A3 (the Cast Rendering row, the flag lines, the pulse table), A10 and the follow-up table now mark the TASK-062 items done (merged b384818b):
  - the twinkle at alpha × 0.6 (Cast Rendering R6/F3);
  - idles on the next frame, eased over idle_rm_ease_s, both ways (R7);
  - the sparkles unchanged (Reveal Stage R9);
  - 0.38 Hz kept, with the art bible amended;
  - the stage-view Smart Invert opt-out (Reveal Stage R1);
  - all 10 motion GDDs naming reduceMotion.
- Still open: the Parent Gate Switch Control edge-case note (K-29) and the PKC-14 scan extension.
- A blank line that had split the follow-up table is removed.
- No rule change.
Reviewed-Content-Hash: design/gdd/accessibility.md 46b193e259777e4780cb721292dcf79d66462a1a
