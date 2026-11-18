# Review log: design/gdd/child-lock-in.md

## Review — 2026-11-18 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: M
Specialists: none (lean)
Blocking items: 1 | Recommended: 1
Summary: All 8 sections are present (Formulas: F1 engage time and the timeout). The approved plan's items are written as rules with ACs: the R2 option set with the tested and NOT ASSESSED lists and the long power press as the unblockable way out; the six R3 preconditions matching App Shell's "ready" plus active and childLockActive; the R4 disengage order (options, covers, Input mode) for OFF, Reset, Quit and Suspend; R5's ways out citing Parent Gate G2/G8/G11, release only on didResignActive, overlays only, crash recovery NOT ASSESSED; R6's non-key dusk covers rebuilt on screen changes; R7's 5 s timeout counting only while active with an in-memory failure flag; R8's text-only Guided Access guidance and guidedAccessEnabled for G7; R9 Android NOT ASSESSED; K-12, K-21, K-23 as decided. One blocker: R5's "no separate NSWindow" contradicted R6's extra-display cover windows. Revised the same day by the author (TASK-052). No registry exists (design/registry/ absent); values were cross-checked against ADR-0001, TASK-033, the merged GDDs and decisions. The Parent Gate GDD (TASK-048) is not merged yet; its G-rule numbers are cited as relayed by the leader.
Prior verdict resolved: First review
Findings:
- [BLOCKING] Detailed Design, R5 vs R6: "No separate NSWindow … while childLockActive can be true" forbids the K-23 extra-display covers, which are NSWindows → R5 and AC-11 name the covers as the only other windows, each with canBecomeKey and canBecomeMain false (fixed)
- [RECOMMENDED] Dependencies: Parent Gate & Grown-up Panel (TASK-048) must name Child Lock-in (switch, Quit, G2, G7, the failure-flag notice, overlays only); Input's follow-up (⌘ swallowed in every state while childLockActive) is queued by the leader; App Shell (TASK-051 @ 0bb713b) already carries the ready signal, overlays and the NOT ASSESSED crash (open until those merge)
Values cross-checked: option set (ADR-0001 9b, TASK-033); ⌘H/⌘Q/⌘Space tested, the rest NOT ASSESSED (TASK-033); chord ⌃⌥⌘Q exact, nothing else held (Input R6, TASK-050); childLock stored only as ON, OFF for the run (Settings Store R8, K-21); lock after ready (K-12); panel auto-close 60 s (K-19); K-23 Q1–Q4; Guided Access steps (support.apple.com/en-us/111795 via TASK-033); PKC-07.
Reviewed-Content-Hash: design/gdd/child-lock-in.md 1676395a481c89d56de7a85d8960d46da19694af
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/game-concept.md e525c154ca1b014fe3ca0024ba5a339d37135429
Reviewed-Content-Hash: design/gdd/systems-index.md 6a112dbc010728a85f640458c740b36d32817a76
Reviewed-Content-Hash: docs/architecture/adr-0001-native-apple.md 44e15a46a094d4d4f066b8476bfcfe8a97b43dda
Reviewed-Content-Hash: design/tech/TASK-033-anim-runtime.md b4aa509896eb20eec4630a447824fe47f2339d25
Reviewed-Content-Hash: design/gdd/input-key-filter.md fd2286b73dad5e6608b42103370102f8f9b44c72
Reviewed-Content-Hash: design/gdd/settings-store.md d0629a5f8a9ed9bb6d224656bb1606456dea1ddd
Reviewed-Content-Hash: design/gdd/privacy-kids-compliance.md a9e00c7a32009cd99a7d1597672c90132ba73d4e
Reviewed-Content-Hash: production/team/decisions.md fe4761035a309a289bdb33b864b79baae62fc9ea

## Update — 2026-11-18 — independent read fixes (no re-review)
Review mode: lean · Workflow: standard
Change: game-qc-ios's independent read (REVISE, bookkeeping): R5's chord bullet now says the chord is judged from the OS key state once TASK-054 I1 lands (merged Input R6 uses the held set today); open follow-ups are named, not credited as done (I1, I3 and S1/S2, open in TASK-054a, owner game-dev-android); a release-blocking note says AC-3/AC-6 need S1/S2 and I3, and AC-17's chord path needs I1; AC-16/AC-17 marked NOT ASSESSED inline; the cover colour cited as App Shell's launch colour (proposal). No rule changed.
Reviewed-Content-Hash: design/gdd/child-lock-in.md 4f3fefd7aacd007bb5d0b41c207f87972b1759c2

## Update — 2026-11-18 — TASK-054b text (no re-review)
Review mode: lean · Workflow: standard
Change: L1: R5's chord bullet matches the merged build decision: judged from the OS key state (if Input AC-1k6 passes), otherwise from the held set kept honest by the ⌘-release rule (Input R6, TASK-054a). Also the Dependencies and the release-blocking note now say S1/S2, I1 and I3 landed in TASK-054a (5e1c365): AC-3 and AC-6 are no longer blocked by design but stay NOT ASSESSED until run; AC-17's chord path depends on Input AC-1k6 (real Mac, release-blocking, NOT ASSESSED). Text only; no rule changed. Review: game-qc-ios, from the diff.
Reviewed-Content-Hash: design/gdd/child-lock-in.md 7298161cfbdbff84d6d83627661100951de6560b

## Update — 2026-11-18 — TASK-056a cross-review fixes (no re-review)
Review mode: lean · Workflow: standard
Change: W-1: one signal kioskModeOn (Input's kiosk-on mode): on in Waiting, Locked and Suspended, off in Off; on the engage timeout it goes off (⌘Q works, no Quit row) while childLockActive stays true; Parent Gate G7 shows Quit whenever it is on; States, Interactions and AC-8 updated. W-10: R2 lists the Title; panelWillOpen dropped (unused). W-9: AC-6 marker refreshed. From design/gdd/gdd-cross-review-2026-11-18.md and K-26. Review: game-qc-android (diff re-run).
Reviewed-Content-Hash: design/gdd/child-lock-in.md c04c66982c334222b5c9d9fa82323e534dd0687c
