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
