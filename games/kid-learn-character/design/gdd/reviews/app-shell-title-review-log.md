# Review log: design/gdd/app-shell-title.md

## Review — 2026-11-18 — Verdict: APPROVED
Review mode: lean · Workflow: standard
Scope signal: M (one system, 4 small formulas, 2 upstream and ~10 driven systems, no new ADR; producer should verify)
Specialists: none (lean). Note: run in the authoring session (game-dev-ios, TASK-051); game-dev-android reviewed the plan and does the independent read.
Blocking items: 0 | Recommended: 3 (applied before the commit) | Advisory: 3
Summary: All 8 sections are present (Formulas: the launch timeline, the button breathe, the return rule, the memory escalation). The eight plan items are covered: the launch order (settings → theme load ∥ audio and chord → first frame Title → Mac kiosk after ready, K-12/K-21), Title contents and starts (any tap except the moon, letter/digit keys; not reveal 1), the pending start while the theme loads, the silent-mode hint in the panel, background and return (K-15, K-22's 30 min), windows on iPad and Mac, memory shedding with Cast Rendering's residency, and crashes with nothing collected (L-07 cited, not decided). K-22 is written as decided. No registry exists; values were checked against the named GDDs, the decisions and the one-shot.
Prior verdict resolved: First review
Findings:
- [RECOMMENDED, applied] R6: K-22 says "uptime clock", but the uptime clock stops while the device sleeps, so an iPad left asleep overnight would not count as away → "away" uses the continuous (sleep-inclusive) monotonic clock, in memory only; flagged to the leader and the Privacy follow-up (PKC-09).
- [RECOMMENDED, applied] R6: the Mac's background was defined as "hides or is deactivated", which overlapped Input's Inactive (window not key) → background is hidden or minimised; losing key focus stays Inactive.
- [RECOMMENDED, applied] R4: a stray "Audio (nothing to stop)" in the Play-entry order removed.
- [ADVISORY] Follow-ups for other GDDs: Key Table titleCastId; Parent Gate (silent-mode hint, gate from the Title); Privacy (continuous clock, L-07); Child Lock-in ("app is ready").
- [ADVISORY] Proposals: launch-screen colour #46558f, Mac minimum 960 × 540 pt, memory_escalate_s 30 s.
- [ADVISORY] AC-10 and AC-13 are device/screenshot criteria.
Reviewed-Content-Hash: design/gdd/app-shell-title.md 598584b1f91d15f518a2cdf700ee78cd61e9ee54
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/game-concept.md e525c154ca1b014fe3ca0024ba5a339d37135429
Reviewed-Content-Hash: design/gdd/systems-index.md 04e962d408dfa9487f10c44bd9189a1246aba1c1
Reviewed-Content-Hash: design/art/art-bible.md ff95ca81ce8e7a2adbf92f5ce92267c3fe355cda
Reviewed-Content-Hash: design/gdd/settings-store.md 6e2df80d2d4061d730f3e2cb322e8d9669e51359
Reviewed-Content-Hash: design/gdd/input-key-filter.md 14c4a9a102f93f6ed093d038b3dcc1387550e738
Reviewed-Content-Hash: design/gdd/audio-voice.md 1f3d8158975fa07f5bac347250674314dc0ac4f0
Reviewed-Content-Hash: design/gdd/key-table-theme-data.md e108179924cb3f53191a26f006791f88e7e342bd
Reviewed-Content-Hash: design/gdd/hint-letters.md 75e34cae7f4d392b2fcef8f22487a4656dc8fd00
Reviewed-Content-Hash: design/gdd/parade.md 80eba63007c5502982d0c69e1a9ae6509ffe8d01
Reviewed-Content-Hash: design/gdd/privacy-kids-compliance.md a9e00c7a32009cd99a7d1597672c90132ba73d4e
Reviewed-Content-Hash: production/team/decisions.md ed7e2987c99b2fc575d9f2dcf719e50f7ec61a53

## Update — 2026-11-18 — game-dev-android independent read: REVISE, addressed
Review mode: lean · Workflow: standard
Source: game-dev-android's independent read of 2ff0f91 (relayed by the leader), plus a constraint from game-qc-ios's Child Lock-in review.
Findings:
- [BLOCKING] R1 step 5 / F1: "app is ready" did not match Child Lock-in's preconditions → ready = first frame, chord installed, kiosk mode on, window covering its display; Child Lock-in adds the app being active and childLockActive on (its R3); AC-3 checks the window covers the display before the options (fixed)
- [BLOCKING] R9 and the edge case claimed a crash with the kiosk on leaves the Mac usable, untested → NOT ASSESSED, citing Child Lock-in's kill -9 test (fixed)
- [RECOMMENDED] R7: native full screen vs a borderless window at the screen frame → "decided in the Mac build, NOT ASSESSED", naming window(_:willUseFullScreenPresentationOptions:) for the native case (fixed)
- [RECOMMENDED] R7 (game-qc-ios): the gate challenge and the panel are overlays in the main window, never separate windows or sheets, so didResignKey never drops the lock (fixed)
Reviewed-Content-Hash: design/gdd/app-shell-title.md ef2a879a99004c2f3244890c39cc9e560dbf64be

## Update — 2026-11-18 — TASK-054a follow-ups (no re-review)
Review mode: lean · Workflow: standard
Change: A1: AC-3 logs all four ready conditions in any order of arrival before the options; R7's overlay reason now says another window would move focus away and Child Lock-in releases only on didResignActive. Wording and rule edits from the TASK-054 follow-up list (production/team/TASK-054-followups.md @ 84f7ea2); Parent Gate G-numbers cited as given by game-qc-ios (TASK-048 not merged). Review: game-qc-ios, from the diff.
Reviewed-Content-Hash: design/gdd/app-shell-title.md 02d7c90895449c9ad40a1dbbe9996794c33d8bbf

## Update — 2026-11-18 — TASK-056c cross-review fixes (no re-review)
Review mode: lean · Workflow: standard
Change: from /review-all-gdds 2026-11-18 (design/gdd/gdd-cross-review-2026-11-18.md): W-2: Cancel and Esc on a gate opened from the Title return to the Title (R5, States, an edge case; Parent Gate §G9); W-10: Interactions and F1 name the run value childLockActive where they mean it. Text only; no rule changed.
Reviewed-Content-Hash: design/gdd/app-shell-title.md 09dc4b56bb283e6dfb84ff83b5b494070234a3e1

## Update — 2026-11-18 — TASK-057b ready wording (no re-review)
Review mode: lean · Workflow: standard
Change: R-1: since TASK-056a, Input's kiosk-on mode (kioskModeOn) is Child Lock-in's own output on entering Waiting, so App Shell's "ready" (R1 step 5, F1) is now first frame + chord installed + window covering its display; Child Lock-in sets kioskModeOn on Waiting and applies the options once its R3 preconditions hold. AC-3 aligned (ready fires with the lock off too). Text only.
Reviewed-Content-Hash: design/gdd/app-shell-title.md 973139da5486e46e4a0fc9ed5a06df34f66a397a

## Update — 2026-11-18 — TASK-057b wording (no re-review)
Review mode: lean · Workflow: standard
Change: from game-qc-android's diff review (REVISE, wording): Waiting (and so kioskModeOn) starts at the settings read and can come before "ready", so R1 step 5 no longer says "then", and AC-3 says Child Lock-in sets kioskModeOn on entering Waiting (possibly before "ready") and applies the options only after "ready" plus its R3. F1 unchanged.
Reviewed-Content-Hash: design/gdd/app-shell-title.md 2e7f2ef9dcdbcd02cd50078c115cb7035a3b7749

## Update — 2026-11-18 — TASK-059b stray markup removed (no re-review)
Review mode: lean · Workflow: standard
Change: deletes two stray lines of tool markup ("</content>", "</invoke>") left at the end of the file by its author's writing tool; no content or rule changed.
Reviewed-Content-Hash: design/gdd/app-shell-title.md f8d7498422bcd569090952989df48366203ecdda

## Update — 2026-11-18 — TASK-062 follow-ups (no re-review)
Review mode: lean · Workflow: standard
Change: R2: the play-button breathe stays 0.38 Hz as played (leader's call; the art bible §2 note is amended) and the flag is Accessibility's reduceMotion (A1), next frame. R3: the play button needs no physical touch floor, since any tap except the moon starts play. An Accessibility row added to Interactions. Follow-ups from the Keyboard Row (TASK-060) and Accessibility (TASK-061) GDDs; verdict unchanged; review by game-qc-ios from the diff.
Reviewed-Content-Hash: design/gdd/app-shell-title.md ff2c7c4cf7970d79f7e66890c113d3f414def5c7

## Update — 2026-11-18 — TASK-085a follow-ups (no re-review)
Review mode: lean · Workflow: standard
Task: TASK-085a
Change: Privacy V1: R6's clock note names ADR-0002 D3 AwayClock (ContinuousClock / mach_continuous_time; Android elapsedRealtime); mach_continuous_time is not a SystemBootTime required-reason API, so App Shell adds no manifest entry and 35F9.1 stays PKC-09 / AC-09's call. Replaces the open "Privacy follow-up" sentence. Checked, already landed: A1 wording (TASK-054a), breathe 0.38 Hz and no physical touch floor for the play button (TASK-062). Review: game-qc-ios, from the diff.
Reviewed-Content-Hash: design/gdd/app-shell-title.md ad0e7f50e3b9d4760c0b5e07c84ae370135f0453

## Update — 2026-11-18 — TASK-090 K-39 portrait and system overlays (no re-review)
Review mode: lean · Workflow: standard
Task: TASK-090
Change: R7 (K-39): iPad allows every orientation, portrait included, and any window shape; the stage is contained and extends, never letterboxed (K-20). New R7 rule: on the Title and in Play the status bar and home indicator are hidden and system edge gestures are deferred on every edge (prefersStatusBarHidden, .persistentSystemOverlays(.hidden), preferredScreenEdgesDeferringSystemGestures); in the gate challenge and the grown-up panel edge gestures are not deferred, and the status bar stays hidden throughout so the stage fit never jumps; Guided Access stays the real lock. Author's reading of K-39's "during play": the child-facing Title and Play, not the grown-up's screens. AC-10 adds both portrait directions; new AC-14 (overlays, device swipes NOT ASSESSED until run); an Edge Cases row for rotation mid-reveal. Review: game-qc-ios, from the diff.
Reviewed-Content-Hash: design/gdd/app-shell-title.md 4b7c340a6bd8134c6f9753c231d3d4a2ff497802
