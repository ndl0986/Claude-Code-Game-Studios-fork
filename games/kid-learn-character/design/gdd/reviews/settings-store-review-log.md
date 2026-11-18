# Review log: design/gdd/settings-store.md

## Review — 2026-11-18 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: S
Specialists: none (lean)
Blocking items: 1 | Recommended: 3
Summary: All 8 sections are present (5 required at standard, plus Formulas because F1/F2 define numeric rules). The closed stored-field list (R1), the never-stored list (R2), device-only storage with OS backups allowed (R3), the single atomic record (R4), the launch order (R5), per-field validation (R6), migration (R7), the Mac child-lock ordering (R8), Reset (R9) and notifications (R10) cover the TASK-039 acceptance criteria and every must-cover item from game-dev-ios's plan review; Luan's Q1–Q4 are written as decided. One blocker: AC-3 required that no other key exist in the app's preferences domain, which macOS AppKit breaks on its own (window-frame autosave writes NSWindow Frame keys), so the test would fail on a correct implementation. Revised the same day by the author (TASK-039). No registry exists (design/registry/ absent), so values were cross-checked against the Key Table GDD, the art bible and the decisions file instead.
Prior verdict resolved: First review
Findings:
- [BLOCKING] Acceptance Criteria, AC-3: "no other key exists under the app's preferences domain" is not testable as written: macOS frameworks write their own keys (window-frame autosave) → AC-3 checks the decoded record's keys plus a build check that only the store calls the preferences API; R2 turns off window-frame autosave and window state restoration (fixed)
- [RECOMMENDED] Formulas, F1: the formula clamped read values while R6 and the example treated out-of-range reads as invalid → split into a slider rule (clamp + round) and a read rule (round inside 0–10, else default 8), with examples for both (fixed)
- [RECOMMENDED] Edge Cases, write failure: UserDefaults reports no write failure, so "the write fails" was not observable on Apple → scoped to platforms that report it (atomic file write, SharedPreferences.commit) (fixed)
- [RECOMMENDED] Dependencies: Parent Gate & Panel, App Shell, Audio & Voice, Scene, On-screen Keyboard Row, Child Lock-in and Privacy & Kids Compliance have no GDD yet, so bidirectionality can't be checked; each must name the Settings Store and the fields it reads or writes. Key Table already does (its R3 and Interactions); Input & Key Filter's keyboard-row and kiosk links are indirect (open)
Values cross-checked: keyboard row off by default (art bible §7), weather list and windy as a modifier (art bible §2), no "seen" marks (§4), themeId only from Key Table (its R3, Interactions), no network (ADR-0001 D8), kiosk options and parent chord (D9b, K-10), reveal count not stored (K-11). Art bible §2 / K-08 "today's weather" is superseded by Luan's Q2 (R1); the art bible is not edited here.
Reviewed-Content-Hash: design/gdd/settings-store.md 25d7a5424a9af601a7a43cbeda9936f755bb573e
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/game-concept.md e525c154ca1b014fe3ca0024ba5a339d37135429
Reviewed-Content-Hash: design/gdd/systems-index.md 43d58b9fcad339e55b4e458be0f7145aa8654a7d
Reviewed-Content-Hash: design/art/art-bible.md a01094340e7e5b7bdae636f4cc879d0f84b472b5
Reviewed-Content-Hash: docs/architecture/adr-0001-native-apple.md 9bd960cdffd4bec53f0f2875d6f4c7a33f873a70
Reviewed-Content-Hash: design/gdd/key-table-theme-data.md f8f54faf82ac675dfdf929b0465ef4bdff8253c8
Reviewed-Content-Hash: design/compliance/TASK-034-kids-weather-rules.md efc8d1ecc3ad747f52894344afb5442089e0c52d
Reviewed-Content-Hash: production/team/decisions.md 851d029c9350a0f9ce2f6d528146b3ca974207af
