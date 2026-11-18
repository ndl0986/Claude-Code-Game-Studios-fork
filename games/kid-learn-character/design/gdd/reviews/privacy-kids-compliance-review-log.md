# Review log: design/gdd/privacy-kids-compliance.md

## Review — 2026-11-18 — Verdict: NEEDS REVISION (lean; 2 blocking items are check-method defects; Luan's calls L-01…L-09 are not review items)
Review mode: lean · Workflow: standard
Scope signal: M (14 rules, two platform columns, no formulas, no new ADR; the Android ADR later takes the Android column; producer to verify)
Specialists: none (lean)
Blocking items: 2 | Recommended: 10 | Advisory: 7
Task: TASK-040
Summary: Independent first review (the author was game-qc-ios; this pass read the GDD cold). All 5 required
sections are present at standard (Overview, Detailed Design, Edge Cases, Dependencies, Acceptance Criteria),
plus Player Fantasy and Tuning Knobs (advisory). Formulas is "Not applicable"; accepted, because every
threshold is an absolute zero and the gate order is a rule, not a formula. The design matches Pillar 5, the
anti-pillars, ADR-0001 Decision 8, K-08, K-12 (backups allowed) and K-13 (build-time TTS), and agrees with
the Settings Store draft (R1–R4, CA92.1, no file timestamps, field name only in logs). Rule IDs PKC-01…14,
the AC list, the source tags [A1–A10, C1–C3, G1–G7] and L-01…L-09 all resolve. The blocking problems are in
the checks, not the rules: some named checks cannot detect what they claim to (shown by a test build), so a
build could PASS while breaking a rule.
Prior verdict resolved: First review

Completeness (standard): Overview ✓, Detailed Design ✓ (accepted for Detailed Rules), Edge Cases ✓,
Dependencies ✓, Acceptance Criteria ✓ = 5/5 required. Formulas: not required (no numeric rules; N/A
accepted). Advisory: Player Fantasy ✓, Tuning Knobs ✓.

Dependency graph: Settings Store (#4) exists only on origin/design/TASK-039-gdd-settings-store; its draft
already points back to this GDD (R4, Interactions, Dependencies), so the link is bidirectional there. Input &
Key Filter (#2) and Key Table & Theme Data (#1) exist on disk. Audio & Voice, Parent Gate & Grown-up Panel,
Child Lock-in, Scene: Time of Day & Weather, App Shell, Theme Packs and Localization have no GDD yet; the
back-links are due when they are written. Docs checked: game-concept.md (Pillar 5, anti-pillars),
adr-0001-native-apple.md Decision 8, decisions.md K-03/K-08/K-12/K-13, key-table-theme-data.md §5,
systems-index.md #5, design/compliance/TASK-034-kids-weather-rules.md (A-01, B-08, B-09, F-01, F-08, F-09,
the Mac working rule).

Registry values: no design/registry/ exists for this game, so no registry check was run. Values checked by
hand against their sources: the ADR network rule and entitlement name, K-08 weather by hand, K-12 backups,
Settings Store R1/R4/R6, TASK-034 B-09 (FAQ F.5 quote) and F-01.

Not verified by this review: no network access was available, so none of the [A*], [C*], [G*] URLs or quoted
sentences were re-fetched. Only the quotes that TASK-034 also holds (1.3 text, F.5, 312.2 (7) and (9), 312.4(d))
were compared with it, and they agree. The COPPA item numbering and dates, the Apple age-band wording and the
Google policy wording rest on the author's "read raw 2026-11-18" claim.

Test run (blocking item 1): a small Swift program was built on this Mac that calls NSWorkspace open, a file
modification date, a creation date and ProcessInfo.systemUptime. `nm -um` listed the NSWorkspace class and the
date-key symbols but NOT the selectors `openURL:` and `systemUptime`; `strings` found both. So `nm -um` finds
classes, C symbols and constants, and misses selector-only APIs. (Scratch files only, not in the repo.)

Findings:
- [BLOCKING] PKC-02, PKC-05, PKC-09, AC3, AC9: the Apple symbol check is `nm -um`, which cannot see
  Objective-C selectors. Named targets that are selector-only (`openURL:` / `open(_:options:)`,
  `identifierForVendor`, `systemUptime`, `modificationDate`/`creationDate` property reads, `requestReview`)
  would never be listed, so a build that calls them still passes. The 35F9.1 "present if and only if" test
  (PKC-09, AC9) depends on seeing `systemUptime`, so it cannot be run as written. Fix: split each scan into
  (a) `nm -um` for classes, C functions and constants and (b) `strings -` (or `otool -ov` on `__objc_methname`)
  for selectors; add a positive control, i.e. run the scan once against a fixture binary that calls each
  named API and record that it is detected, before trusting a clean result.
- [BLOCKING] PKC-03, AC5: "no third-party SDK" is checked only with `otool -L` and `Frameworks/`. A Swift
  package or static library linked into the main binary appears in neither, so the rule's main case passes
  unseen. PKC-13 catches only a diff, not the baseline. Fix: add to PKC-03 and AC5 the dependency list from the
  project (`Package.resolved`, the package references in `project.pbxproj`; no Pods or Carthage) which must
  equal {KidCore, MorphCore} and nothing else, and an `nm`/`strings` scan of the main binary for module
  prefixes outside Apple's and ours.
- [RECOMMENDED] PKC-07 and L-04 vs PKC-02 / PKC-01: PKC-07 and L-04 let Luan choose "a gated link" to the
  privacy policy, but PKC-02 says no links out and none of the grown-up items "leave the app", and its checks
  (`SafariServices`, `openURL`) would FAIL. Fix: say that choosing the gated link is a PKC-13 change that
  edits PKC-02 (a named exception: one `openURL` call in the gated panel, one URL, https) and PKC-01 before it
  ships; or drop the option from PKC-07.
- [RECOMMENDED] PKC-11 and Edge Cases "A Mac build outside the Kids category": PKC-11's Apple check needs a
  "Made for Kids" screenshot on iPadOS and macOS, while the Edge Case says a Mac with no Kids option "still
  meets every PKC rule" and L-01 is open. If the option does not exist for macOS, the Mac gate can never leave
  NOT ASSESSED, which blocks the release. Fix: add the macOS branch to PKC-11: "if Luan's screenshot of the
  macOS age-rating screen shows no Made for Kids option, PKC-11 is PASS for macOS on the screenshot alone,
  recorded as 'not offered'"; AC10 the same.
- [RECOMMENDED] PKC-01 (c), Tuning Knobs, AC1 entitlements allowlist: "the entitlements must equal" the
  allowlist, which lists `application-identifier`, team id and `get-task-allow` false. Real signed builds may
  differ: key names (`com.apple.application-identifier`, `com.apple.developer.team-identifier` on macOS),
  `get-task-allow` absent rather than false on a distribution build, `beta-reports-active` on TestFlight. This
  was not verified on an archive. Fix: mark the allowlist "to be pinned from the first archive (not verified)"
  and compare to the pinned list; any key outside it is read by a person, as AC3 does for symbols.
- [RECOMMENDED] PKC-09, AC9: the manifest must hold "exactly" UserDefaults/CA92.1, but the scan names only
  the file-timestamp and boot-time APIs. Apple's other two required-reason categories (disk space, active
  keyboards) are not scanned, and the Input & Key Filter GDD reads keyboard events (line 139 uses the uptime
  clock), so a keyboard-layout or disk-space call is plausible. Fix: add `activeInputModes`, `statfs`,
  `volumeAvailableCapacity*`, `systemFreeSize` to the scan (strings and nm), and decide now whether the app's
  own timing code calls `systemUptime`/`mach_absolute_time` (then 35F9.1 is expected, not "only if").
- [RECOMMENDED] PKC-14, AC13: `log stream --process` on a release build shows dynamic strings as
  `<private>`, and `print()` writes to stdout, which `log stream` does not capture; a clean run does not prove
  nothing is logged. Fix: keep the runtime run, but make the code scan the real check: no `print`, `NSLog`,
  `os_log`, `Logger` or `dump` call that takes input under a non-DEBUG condition (a grep with the list in the
  rule), and check the release binary for the same format strings.
- [RECOMMENDED] PKC-05, AC7: the stored data "holds only the R1 fields", but a macOS app domain can also hold
  OS-added keys (window frames, restoration) which Settings Store R2 says are turned off. As written AC7 can
  fail for a reason outside the Settings Store, or pass while such keys exist. Fix: AC7 reads the whole app
  domain (`defaults read <bundle id>` / the container plist) and expects exactly one key (`settings`, per
  Settings Store R4) whose decoded value has only R1 fields; any other key is a FAIL or a person-read note.
- [RECOMMENDED] Overview, Summary, PKC-01 vs K-12: "nothing about the child can leave the device",
  "no data" and PKC-01 "no iCloud" read as absolute, while K-12 allows OS device backups (the settings go to
  the user's iCloud/Google account). The Edge Case handles it, but the headline text does not. Fix: state in
  the Overview and PKC-01 "no app-initiated iCloud or sync; OS backups of the settings are allowed (K-12,
  Edge Cases)", and in the Player Fantasy say it is true when PKC-10 and L-07 hold.
- [RECOMMENDED] Header "Last Verified" and Player Fantasy: the header says every official source was read raw
  on 2026-11-18, but [C3] is marked "read 2026-11-17 for TASK-034", and the Player Fantasy states the listing
  "says 'Data Not Collected', and that is true" before L-05, L-07 and Q2 are settled. Fix: "every source except
  [C3] (2026-11-17)"; Player Fantasy: "will say ... and the gate (PKC-10) checks it is true".
- [RECOMMENDED] PKC-02 and PKC-14 go beyond their cited sources: "share sheets" and "review prompts" are not in
  the Guideline 1.3 text quoted in TASK-034 A-01…A-04 (links out, purchasing, distractions behind a gate;
  third-party analytics), and 1.3 allows links out behind a parental gate, which PKC-02 forbids. PKC-14 (no
  logging of input) cites COPPA 312.2 and "passive tracking", which the definition does not state for logs.
  Fix: add a column value or note "team rule (Pillar 5), stricter than the source" for these parts, so a
  reader does not think Apple or the FTC requires them.
- [RECOMMENDED] Scripted session (PKC-01 (c), Tuning Knobs, AC2): it opens and closes the parent panel but
  does not change any setting, so a network or file access triggered by a change (theme load, weather, volume
  write) is never exercised in the 0-bytes run, while AC7 does change every setting. Fix: the session also
  sets every setting once (volume, mute, weather, windy, theme, keyboard row, child lock on macOS) and resets.
- [ADVISORY] Acceptance Criteria: AC numbers coincide with PKC numbers only by chance (AC9 = PKC-09, AC10 =
  PKC-10/11, AC12 = PKC-13, AC13 = PKC-14); label each AC with its rules ("AC-09 [PKC-09]") so a story can cite it.
- [ADVISORY] AC4 and AC8: "every touch target in the child area" is not enumerated; point to the Input & Key
  Filter key classes and the screen list so QC's "tried once each" can be audited.
- [ADVISORY] Android column, PKC-08 and Tuning Knobs: "permission allowlist: none" will likely fail once
  AndroidX core is on the approved list, because it merges a `<app id>.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`
  entry (not verified here). Note it for the Android ADR (Q5).
- [ADVISORY] COPPA position, Dates: the parenthesis "(The plan expected this date to be not sourceable; it was
  found in the Federal Register text itself.)" is author process, not design; remove it.
- [ADVISORY] Dependencies: the reference to `qa/TASK-032-kids-store-rules-android @ ac7b97b` (unpushed WIP)
  cannot be followed by a reader; drop it or say where the file will be.
- [ADVISORY] Edge Cases: no row for OS features that store or move app state by default (state restoration,
  Handoff/NSUserActivity, Spotlight donation, Auto Backup of other files). Settings Store R2 covers some; add
  one line pointing to it or add the Handoff/Spotlight "not used" check to PKC-08.
- [ADVISORY] COPPA position: "The game is directed to children, so COPPA is the frame" sits beside Q3, which
  doubts COPPA's notice duty for an app that collects nothing. Consistent enough (Luan's call L-02), but the
  first sentence could say "assumed to apply" until L-02 is answered.
Reviewed-Content-Hash: design/gdd/privacy-kids-compliance.md e35e9bf358814473c23274d70e648d2aee19c9ac
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/game-concept.md e525c154ca1b014fe3ca0024ba5a339d37135429
Reviewed-Content-Hash: design/gdd/systems-index.md b5750c60b50582731e57064d5789981cbc794337
Reviewed-Content-Hash: design/gdd/key-table-theme-data.md f8f54faf82ac675dfdf929b0465ef4bdff8253c8
Reviewed-Content-Hash: docs/architecture/adr-0001-native-apple.md 44e15a46a094d4d4f066b8476bfcfe8a97b43dda
Reviewed-Content-Hash: production/team/decisions.md b379a096d7e6bf64ca7a98ab6af20eceabf803b7
(Settings Store GDD read from origin/design/TASK-039-gdd-settings-store; not stamped, it is not on this branch.)

## Review — 2026-11-18 (re-review) — Verdict: APPROVED (lean; 4 recommended fixes to make at the next touch, none blocking)
Review mode: lean · Workflow: standard
Scope signal: M (unchanged; producer to verify)
Specialists: none (lean)
Blocking items: 0 | Recommended: 4 (new) | Advisory: 7 (5 carried or partly resolved, 2 new)
Task: TASK-040
Summary: Re-review of the revised text (GDD hash 211a810, was e35e9bf). Both blocking items are resolved: the
"Apple API scan" (Core Rules, lines 67–78) uses two passes and must be proven on a fixture binary first, and
PKC-03 now has a project-dependency check plus a module-name scan. 9 of the 10 recommended items are
resolved and 1 is partly resolved; the advisory items are resolved or partly resolved except the AC labels.
No broken rule, AC or source IDs were introduced. The revision introduced four defects, all on the
fail-safe side (a correct build could be marked FAIL, or a check is unclear), so none blocks.
Prior verdict resolved: Yes (NEEDS REVISION → both blocking items resolved)

Prior items (line numbers are in the revised GDD):
- [B1 nm -um selectors] RESOLVED: lines 67–78 (two passes: `nm -um`, then `otool -ov` + `strings -a`; fixture
  proof before first use and after any Xcode or script change); PKC-02, 05, 09, 12 say "API scan"; AC3 (350–354).
- [B2 PKC-03 static linking] RESOLVED in intent: line 86 (a) project dependencies, (d) module-name scan; AC5
  (360–364). The wording of (a) is wrong, see N1.
- [R PKC-07/L-04 gated link] RESOLVED: line 90 and line 319 make it a PKC-13 change with a named exception.
- [R PKC-11 macOS] RESOLVED: line 94 and AC10 (380–382) pass on the "not offered" screenshot.
- [R entitlements allowlist] RESOLVED: line 272 "pinned from the first Release archive (not verified yet)";
  the key names and `beta-reports-active` are listed as examples.
- [R PKC-09 scan] RESOLVED: line 92 and AC9 (375–379) add DiskSpace and ActiveKeyboards and say 35F9.1 is
  "expected; the API scan decides" (Input & Key Filter R8 was checked: it does name the uptime clock).
- [R PKC-14 logs] RESOLVED: line 97 and AC13 (388–391) make the code scan the real check and the runtime run
  supporting, and say why (`<private>`, stdout).
- [R PKC-05/AC7 stored data] PARTLY RESOLVED: line 88 and AC7 (368–371) now name the `settings` key and ignore
  OS-written keys, but they conflict with the scripted session's reset, see N2.
- [R headline vs K-12] RESOLVED: lines 13–14, 27–28, PKC-01 (84), Player Fantasy (47–48).
- [R Last Verified / Player Fantasy] RESOLVED: line 6 names [C3] as 2026-11-17; lines 47–48 say "meant to say".
- [R PKC-02/14 beyond source] RESOLVED: lines 79–80 and 85 (team rule); PKC-14 source is "Team rule" (97).
- [R scripted session] PARTLY RESOLVED: Tuning Knobs line 276 adds "every setting changed once and then
  reset", backgrounding and resume; PKC-01 (c) (line 84) still describes the old session ("every key, the
  parade and the parent panel"). Point it at §Tuning Knobs.
- [A AC labels] OPEN: ACs are still plain numbers (AC3 and AC10 now list their rules in the title).
- [A AC4/AC8 enumeration] PARTLY RESOLVED: AC4 (355–358) names the targets and a "QC screen inventory"; that
  inventory is not a file anywhere. Name its path (for example `production/qa/screen-inventory.md`).
- [A Android permissions "none"] PARTLY RESOLVED: Tuning Knobs (274) is fixed, but PKC-08's Android column
  (line 91) still says "(expected: none)" and AC1 (343–346) is unaffected. Align PKC-08 with line 274.
- [A COPPA dates parenthesis] RESOLVED (lines 126–128).
- [A unpushed TASK-032 reference] PARTLY RESOLVED: disclosed as local-only (261–263); still not followable.
- [A OS-feature Edge Case] RESOLVED in intent (244–247); see N3 and N4.
- [A COPPA "assumes applies"] RESOLVED (107–108).

New findings from the revision:
- [RECOMMENDED] N1 PKC-03 (a), AC5: "`Package.resolved` ... list exactly {KidCore, MorphCore} (local
  packages)". Package.resolved does not list local packages, and with no remote dependency it may not exist.
  ADR-0001 also allows MorphCore to be a target inside KidCore. A correct build would fail this check. Fix:
  "no remote package: `Package.resolved` is absent or has no pins, and `project.pbxproj` has no
  `XCRemoteSwiftPackageReference`; local package references are only KidCore (and MorphCore if it is its own
  package)"; and make (d)'s allowed modules the same set plus the app target.
- [RECOMMENDED] N2 AC7 against the scripted session: the session changes every setting "and then reset"
  (276), but a Reset removes the record (Settings Store R9), so the app domain then holds no `settings` key
  and AC7's "exactly one app-written key" cannot be true at the end. "Reset" is also ambiguous (each setting
  back, or "Start over"). Fix: order the session as change all, snapshot the preferences domain (AC7 reads
  this), then Start over; and add "after Start over no app-written key remains (or an empty record)".
- [RECOMMENDED] N3 Edge Cases (246–247): "macOS window-state restoration stays on the device" reads as
  restoration being on, while Settings Store R2 turns window-frame autosave and state restoration off where
  the app controls it. Fix: "restoration is turned off (Settings Store R2); anything the OS still keeps
  stays on the device".
- [RECOMMENDED] N4 Edge Cases (244–247): the `NSUserActivity`, `CoreSpotlight`, `Intents`/`AppIntents` scan is
  named "(API scan)" but is in no PKC row, no AC, and not in the fixture, which is defined as "every API named
  in PKC-01…12". Fix: add these names to PKC-08 or PKC-12's Apple check, to AC3's list and to the fixture.
- [ADVISORY] PKC-09 and PKC-03 scans: `strings -a` matching "stat" or "creationDate" as substrings is noisy;
  the scan script should match whole selector or symbol names. PKC-03 (d) reads `$s<len><Module>` names, so a
  statically linked C-only library would not show; (a) is the backstop.
- [ADVISORY] The entitlement pin (272) has no owner or step; add "release-manager pins it on the first
  archive, as a story task" so AC1 can run.
Reviewed-Content-Hash: design/gdd/privacy-kids-compliance.md 211a810d6c0aacd7e44d7343205e404c56e833f1
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/game-concept.md e525c154ca1b014fe3ca0024ba5a339d37135429
Reviewed-Content-Hash: design/gdd/systems-index.md b5750c60b50582731e57064d5789981cbc794337
Reviewed-Content-Hash: design/gdd/key-table-theme-data.md f8f54faf82ac675dfdf929b0465ef4bdff8253c8
Reviewed-Content-Hash: design/gdd/input-key-filter.md bbbc45714a1c29c1a25ec86c921a6e938773b71f
Reviewed-Content-Hash: docs/architecture/adr-0001-native-apple.md 44e15a46a094d4d4f066b8476bfcfe8a97b43dda
Reviewed-Content-Hash: production/team/decisions.md b379a096d7e6bf64ca7a98ab6af20eceabf803b7
(Settings Store GDD read from origin/design/TASK-039-gdd-settings-store, blob 25d7a5424a9af601a7a43cbeda9936f755bb573e; not on this branch.)

## Author follow-up — 2026-11-18 — after the re-review (no new verdict; APPROVED stands)
Task: TASK-040
The author (game-qc-ios) folded in the re-review's items:
- N1: PKC-03 (a) and AC-05 now require no remote package (Package.resolved absent or without pins, no XCRemoteSwiftPackageReference). The local packages are KidCore, plus MorphCore if it is its own package. The module-name set in (d) adds the app target and notes C-only libraries.
- N2: the scripted session (Tuning Knobs) is now ordered: change every setting → snapshot → "Start over" (Settings Store R9) → second snapshot. AC-07 reads both. PKC-01 (c) points at that session.
- N3: the Edge Cases now say window-frame autosave and state restoration are off (Settings Store R2).
- N4: the Handoff, Spotlight and Siri donation APIs are in PKC-12's Apple check, AC-03, AC-11 and the scan fixture ("PKC-01…12 and Edge Cases").
- Partials and advisories:
  - The ACs are labelled AC-01…AC-14 with their PKC IDs.
  - PKC-08's Android column is aligned with the Tuning Knobs allowlist.
  - AC-04 names the inventory file production/qa/privacy-gate/touch-targets.md, which QC writes before the first gate run.
  - release-manager pins the entitlements on the first archive.
  - The scan matches whole names.
- Still open by design: the TASK-032 reference stays local-only (the leader asked for it to be cited only as a draft).
Post-fix GDD hash: 781bdd0d00f0912b5311275dff325631152fdbd8

## Author follow-up — 2026-11-18 — game-qc-android text re-review (APPROVE except 3 Android fixes)
Task: TASK-040
- PKC-05: `apkanalyzer dex references` replaced by `dexdump -d` on classes*.dex for the named framework calls (Settings$Secure "android_id", TelephonyManager, Build.getSerial, WifiInfo, AdvertisingIdClient).
- PKC-03 / AC-05 (and PKC-02's package check): `apkanalyzer dex packages --defined-only --proguard-mappings mapping.txt`, using the same release build's mapping, kept as evidence; without it the row is NOT ASSESSED.
- Release APK route named: (b) the signed universal APK from Play Console's App bundle explorer, supplied by Luan; (a) `bundletool --mode=universal` only with Luan's OK; NOT ASSESSED until the Android ADR.
- Nits: every Android cell now starts with "NOT ASSESSED: no Android build (K-03)". PKC-02 has a static dexdump backstop for VIEW intents and market:// / http(s) strings. PKC-08 reads `<queries>` with `aapt2 dump xmltree`, because `dump permissions` doesn't show it.

## Update — 2026-11-18 — TASK-056b V1 (no re-review)
Review mode: lean · Workflow: standard
Task: TASK-056
Change: a one-line note on PKC-09's API scan. The continuous clock (App Shell R6) is not a listed required-reason API; Apple lists only systemUptime and mach_absolute_time under System boot time (checked by game-dev-ios 2026-11-18). The existing 35F9.1 entry would cover it if Apple adds it. No rule change.
Reviewed-Content-Hash: design/gdd/privacy-kids-compliance.md 6ee522cecceb875f3ab354617121da1a14980ad2

## Update — 2026-11-18 — TASK-065 (no re-review)
Review mode: lean · Workflow: standard
Task: TASK-065
Change: PKC-14 now also covers the device's accessibility settings (Reduce Motion, VoiceOver, Guided Access, Smart Invert): none is logged in release or ever sent. The code scan and AC-13 include them (Accessibility A11 follow-up). No other change.
Reviewed-Content-Hash: design/gdd/privacy-kids-compliance.md dcf664a9ba7c30c3f4405b2bb9b596b93c6991ef
