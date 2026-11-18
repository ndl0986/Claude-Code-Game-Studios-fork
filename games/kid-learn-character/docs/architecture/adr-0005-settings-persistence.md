# ADR-0005: Settings persistence on Apple

## Status

Proposed

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**

## Date

2026-11-18

## Last Verified

2026-11-18, against Settings Store (R1–R10, K-12, K-21, TASK-054 S1/S2), ADR-0002 (Accepted: D2, D6), ADR-0004
(Accepted: D3, settings-record-v1), Privacy & Kids Compliance (PKC-01, 05, 09, 10), App Shell & Title (R1, R7),
Child Lock-in (R7), Parent Gate & Panel (AC-19, AC-33), and `docs/engine-reference-local/native-apple/`.

## Decision Makers

Luan (accepts); game-dev-ios (author, TASK-067); game-qc-ios (plan and independent review: Privacy, the Parent Gate's
child-lock side); game-leader.

## Summary

The Settings Store needs one small record kept on the device, written all-or-nothing, with no sync and a single
privacy reason. On Apple, the record is the exact bytes from `KidCore`'s canonical writer, stored as `Data` under the
single `UserDefaults.standard` key `settings`; the backend never transforms them, cannot report a failed write, and
is proved by kill tests on the Simulator that read back from disk.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | None from the template's table (ADR-0001, K-28). Swift 6.4, Xcode 27.1, SDKs iOS 27.1 / macOS 27.0, deployment 26 |
| **Domain** | Core |
| **Layer** | Foundation |
| **Knowledge Risk** | MEDIUM. The `UserDefaults` required reason is SOURCED; the on-disk atomicity of one key's replacement and the OS-written keys are NOT SOURCEABLE and are proved by the runs below |
| **References Consulted** | `docs/engine-reference-local/native-apple/modules/privacy-manifest.md` (CA92.1, SOURCED); `current-best-practices.md` (Privacy); Settings Store R3, R4 |
| **Post-Cutoff APIs Used** | `UserDefaults` `data(forKey:)`, `set(_:forKey:)`, `removeObject(forKey:)` on the 27 SDKs: to be proven by the Settings Store story's build (not yet built) |
| **Verification Required** | Validation Criteria 1–6 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (Accepted: D2 types, D6 `SettingsBackend`); ADR-0004 (Accepted: D3 harness layers, settings-record-v1) |
| **Enables** | The Settings Store story (with settings-record-v1); the launch path of App Shell and Child Lock-in |
| **Blocks** | The Settings Store story |
| **Ordering Note** | The Android half (DataStore or SharedPreferences, backup XML) is ADR-0012, not here |

## Context

### Problem Statement
The Settings Store (R1–R10) keeps a closed list of grown-up choices on the device, written as one record, never
synced, and read before the first frame. ADR-0002 D6 defined the `SettingsBackend` seam and ADR-0004 D3 put the
canonical bytes in `KidCore`; the Apple storage behind the seam, its failure semantics and its proofs are undecided.

### Current State
Nothing is built. Settings Store R4 allows "one value under one key" or "one file written atomically"; this ADR picks
the first.

### Constraints
- No sync, no network, no app-initiated iCloud (PKC-01; K-12 allows OS device backups only).
- Exactly one app-written key in the app's preferences domain (PKC-05).
- One privacy reason for `UserDefaults` (PKC-09).
- No third-party code (PKC-03). Under 1 KB, main thread (Settings R4).

### Requirements
- The same bytes on Apple as `KidCore` writes and as Android will store (ADR-0002 D8, settings-record-v1).
- A crash never leaves a mixed record (Settings R4).
- `childLock` is never stored as false (K-21).

## Decision

### D1. Storage
- **One value under one key:** `"settings"` in `UserDefaults.standard`, the app's own domain. No app group, no
  `UserDefaults(suiteName:)`, no file (Settings R3, R4).
- **The value is `Data`:** the exact UTF-8 bytes from `KidCore`'s hand-written canonical writer (ADR-0004 D3: sorted
  keys, no whitespace, integers as numbers). The backend never parses, re-encodes or transforms them; `read()` returns
  them byte for byte.
- **Not used:** `register(defaults:)` (the defaults are `KidCore`'s, Settings R1), `synchronize()`, KVO observation,
  `@AppStorage`. There is one writer, on the main thread.

### D2. `SettingsBackend` on Apple (ADR-0002 D6)
| Call | Apple | Notes |
|---|---|---|
| `read() → [UInt8]?` | `data(forKey: "settings")` | nil when the key is absent, or when a non-`Data` value sits under it; `KidCore`'s reader then treats it as no record or garbage → defaults, one log line (Settings R6) |
| `write([UInt8]) → Bool?` | `set(Data, forKey: "settings")` | returns **nil**: `UserDefaults` reports no failure, so "cannot report" is nil (ADR-0002 D6), never true. `false` is for a backend that can report one (Android, ADR-0012) |
| `remove()` | `removeObject(forKey: "settings")` | Reset (Settings R9) |

- All calls run on the main thread (the record is under 1 KB, Settings R4).
- **Parent Gate AC-33** (a failed write) is testable on Apple **only through the test seam**: a fake `SettingsBackend`
  whose `write` returns `false`. The real backend never reports a failure.
- A write that silently failed keeps the change in memory for the run; the next change writes the whole record again
  (Settings edge case).

### D3. Atomicity
- The whole record is one value under one key, so a write replaces it wholly or not at all; there are never separate
  keys that could mix (Settings R4).
- Apple's guarantee that one key's replacement is atomic on disk is **NOT SOURCEABLE** here. It is relied on and
  proved by kill tests at the API level, on the dev simulator only (never QC's simulator E9F515E9…):
  - **(a)** the app writes alternating records A and B and is killed at random points; then
    `xcrun simctl spawn <dev sim> killall cfprefsd` (a plain SIGTERM, which may flush on exit), and the value is read
    back in a **fresh process**, so it comes from disk;
  - **(b)** the harsher case: `killall -9 cfprefsd` **right after `set` returns**, then read back in a fresh process;
  - **(c)** 100 runs of each. **Pass:** every read is A or B, whole, and `KidCore`'s validator accepts it.
  - **(d) The limit:** this proves all-or-nothing at the API level only. Atomicity under power loss on a device stays
    **NOT SOURCEABLE / NOT ASSESSED**.
- **Backstop:** Settings Store R6. A garbled record gives defaults and one log line, never a crash.

### D4. `childLock` (K-21)
- The canonical writer serializes the **stored** `childLock`, never the run value `childLockActive`. A record holds
  `"childLock":true` or no `childLock` key; never false.
- Turning the lock **OFF** in the panel changes only `childLockActive` and **writes nothing** (Settings S1/S2).
- The key exists only in macOS records; an iPad that reads one ignores it and drops it at the next write (Settings
  R6). This is `KidCore`'s rule; the backend stays dumb. It is stated here so the Apple proof covers it.

### D5. One app-written key (PKC-05)
- The domain holds exactly `"settings"` plus the keys on an **OS-key allowlist** pinned in this ADR:

  **OS-key allowlist: `[]` (initial).** The first Simulator run and the first Mac run (under MAC FREE) fill it; each
  addition is an edit of this ADR citing that run's evidence file.

- The check **FAILs** on any key that is neither `"settings"` nor on the list, so a new OS key means an ADR edit,
  never a silent pass. The one-key acceptance criteria are **NOT ASSESSED** until those first runs have filled the
  list; they never PASS against the initial empty list.
- Expected: empty or near-empty, with window-frame autosave and window / scene state restoration turned off
  (Settings R2, App Shell R7).
- **Check paths:**
  - Mac (MAC FREE): `plutil -p ~/Library/Containers/<bundle id>/Data/Library/Preferences/<bundle id>.plist`, after
    quitting the app or after `killall cfprefsd`.
  - Simulator: the same plist inside the app's data container (`xcrun simctl get_app_container <dev sim> <bundle id>
    data`), after `killall cfprefsd` in the simulator.

### D6. Privacy manifest
`NSPrivacyAccessedAPICategoryUserDefaults` with **`CA92.1` only** (data written and read by the app itself). Not
`1C8F.1`: there is no app group. The manifest's other entries follow PKC-09, which this ADR cites rather than
restates.

### D7. Backups (K-12)
Allowed. The app excludes nothing: no `isExcludedFromBackup`, and no file outside the preferences domain. A restored
record is read like any other (Settings edge case).

### D8. No iCloud key-value storage, no CloudKit, no app group
- **Why:** PKC-01 (no app-initiated iCloud or sync; no iCloud entitlement); Settings R3 (a second device must not
  silently inherit a Mac child lock or a weather pick); K-12 (device backups only).
- **Checks** (joining PKC-01's):
  - entitlements (`codesign -d --entitlements -`): none of `com.apple.developer.ubiquity-kvstore-identifier`,
    `com.apple.developer.icloud-container-identifiers`, `com.apple.developer.icloud-services`,
    `com.apple.security.application-groups`;
  - API scan: no `NSUbiquitousKeyValueStore`, `CKContainer`, `url(forUbiquityContainerIdentifier:)`,
    `UserDefaults(suiteName:)`.

### D9. The launch read
Synchronous, once, before the first frame (Settings R5, App Shell R1 step 1). Child Lock-in's engage timer counts from
this read (Child Lock-in R7).

### Architecture Diagram
```
KidCore Settings (record, validation, canonical writer/reader)
        │  bytes ([UInt8])            ▲ bytes or nil
        ▼                             │
SettingsBackend (ADR-0002 D6) ── Apple: UserDefaults.standard, key "settings", Data ── cfprefsd ── plist
```

### Key Interfaces
`SettingsBackend` (ADR-0002 D6) with the Apple semantics of D2.

### Implementation Guidelines
- The backend **must** store and return the canonical bytes unchanged; it **must never** parse or re-encode them.
- It **must** use `UserDefaults.standard` and the single key `"settings"`; it **must never** use a suite, an app
  group, a file, `NSUbiquitousKeyValueStore` or CloudKit.
- `write` **must** return nil on Apple; it **must never** return true.
- The writer **must** serialize the stored `childLock`, never `childLockActive`.
- The app **must** turn off window-frame autosave and window / scene state restoration (D5).

## Alternatives Considered

### Alternative 1: One file written atomically
- **Description**: write the bytes to a temporary file in Application Support, then rename (Settings R4's other option).
- **Pros**: atomic rename is a well-known file-system guarantee; write failures are reported.
- **Cons**: needs file paths, a directory, and care with backups; a file in the container is a second place data lives
  (PKC-05's "one key" check would need a second rule).
- **Estimated Effort**: slightly more.
- **Rejection Reason**: `UserDefaults` is simpler for under 1 KB and keeps PKC-05's check to one domain.

### Alternative 2: Separate keys per field
- **Description**: one `UserDefaults` key per setting.
- **Pros**: idiomatic; no canonical writer.
- **Cons**: a crash can leave a mix (Settings R4 forbids it); no "same bytes" across platforms.
- **Rejection Reason**: breaks R4 and settings-record-v1.

### Alternative 3: iCloud key-value storage
- **Description**: `NSUbiquitousKeyValueStore` so settings follow the family's Apple ID.
- **Pros**: convenience across devices.
- **Cons**: app-initiated sync (PKC-01); a second device would inherit a Mac child lock (Settings R3).
- **Rejection Reason**: D8.

## Consequences

### Positive
- One key, one reason, one record: the privacy checks are simple and exact.
- The bytes are identical to `KidCore`'s output and to Android's (settings-record-v1).

### Negative
- A failed write cannot be detected on Apple; AC-33 needs a test seam.
- On-device power-loss atomicity remains unproved (D3 (d)).

### Neutral
- The OS-key allowlist starts empty and is filled from evidence.

## Risks
- **The OS writes a key we did not expect** (a new SDK behaviour). Mitigation: the D5 check FAILs; the key is added to
  the allowlist by an ADR edit only after review.
- **A garbled record after power loss.** Mitigation: Settings Store R6 (defaults, one log line, no crash).
- **cfprefsd caching hides a broken write in a same-process read.** Mitigation: every D3 read-back is in a fresh
  process after cfprefsd is killed.

## GDD Requirements Addressed

TR-IDs are provisional (architecture.md's baseline).

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| settings-store.md R3, R4 | TR-settings-001: device only; one record, atomic | D1, D3, D8 |
| settings-store.md R5 | the read before the first frame | D9 |
| settings-store.md R6 | garbled or wrong-type values → defaults | D2 read semantics; D3 backstop |
| settings-store.md R8, K-21, S1/S2 | `childLock` stored only as ON; OFF is run-only | D4 |
| settings-store.md R9 | Reset removes the record | D2 `remove()` |
| privacy-kids-compliance.md PKC-01, 05, 09 | no sync; one app-written key; CA92.1 | D5, D6, D8 |
| parent-gate-panel.md AC-19, AC-33 | lock back ON after relaunch; a failed write | D4, Validation 1; D2 test seam |
| child-lock-in.md R7 | the engage timer from the settings read | D9 |

## Performance Implications
- **CPU**: negligible (one read at launch, one write per grown-up change).
- **Memory**: under 1 KB.
- **Load Time**: the synchronous read is a few milliseconds (Settings R5); measured in Validation 4.
- **Network**: none.

## Migration Plan
None: nothing is stored today. Schema migrations are `KidCore`'s (Settings R7).

## Validation Criteria
1. **Bytes round trip:** every settings-record-v1 "record → bytes" case, written through the real backend and read
   back, is byte-identical (Simulator).
   - **The D4 case runs on macOS** (`childLock` is macOS-only): a macOS host unit test or the Mac app, through the
     real backend, **under MAC FREE**, and **NOT ASSESSED until it has run**. Lock ON → OFF for the run → a volume
     change → the bytes still contain `"childLock":true`; then a **cold launch** reads it and `childLockActive` is
     true again (K-21; Parent Gate AC-19); after Reset the key is absent.
   - **The iPad counterpart runs on the Simulator:** a record containing `"childLock":true` is read with the key
     ignored (`childLockActive` false, no kiosk), and after the next write the bytes contain no `childLock` key
     (D4; Settings R6).
2. **One key** (D5): the plist at the D5 paths holds only `"settings"` plus the allowlist; Simulator first, then the
   Mac under MAC FREE. NOT ASSESSED until the first runs fill the allowlist.
3. **Privacy manifest:** `plutil -p PrivacyInfo.xcprivacy` shows `NSPrivacyAccessedAPICategoryUserDefaults` with
   `CA92.1` only; the rest per PKC-09.
4. **Launch order:** an instrumented launch logs the settings read before the first frame.
5. **Atomicity:** D3 (a) and (b), 100 runs each, with pass rule (c) and the limit (d).
6. **No iCloud, no app group:** the D8 entitlement and API checks.
7. **NOT ASSESSED:** a real device backup and restore, and a restored record on a new Mac (Settings edge case).

## Related
- Settings Store GDD; ADR-0002 (D2, D6); ADR-0004 (D3, settings-record-v1); ADR-0012 (the Android half).
- Privacy & Kids Compliance (PKC-01, 05, 09, 10); `docs/registry/architecture.yaml` (`settings_persistence`).
