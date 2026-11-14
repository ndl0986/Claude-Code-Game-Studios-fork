# ADR-0003: Save format and storage

## Status
Proposed

## Date
2026-11-14

## Last Verified
2026-11-14

## Decision Makers
Luan (accepts; D-22 backup is his call); game-dev-ios (author); game-dev-android (peer review);
game-art-content (save-and-progress GDD owner); the game team leader (relay). Task: TASK-022.

## Summary
Both apps store the player's progress as **one small versioned JSON document** with the same shape,
written **atomically** (write to a temp file, then rename) off the main thread, read once at launch,
and salvaged key by key if damaged. It replaces today's per-key UserDefaults / SharedPreferences
storage so that the quiz-finish write is all-or-nothing and a force-quit right after a change loses
nothing.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Native per platform (ADR-0001): iOS Swift (Foundation file APIs), Android Kotlin (java.io / AtomicFile) |
| **Domain** | Core (persistence) |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH, **NOT SOURCEABLE** (no engine reference for these stacks). The APIs used are long-standing (`Data.write(options: .atomic)`, `FileManager`; Android `AtomicFile`), and each is proven by a build, a run and the tests below, not from memory. |
| **References Consulted** | `design/gdd/save-and-progress.md` (Approved, incl. game-dev-ios's 4 clarifications), `design/gdd/hero-progression.md` (D-16), ADR-0001, `docs/architecture/architecture.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | AC3 (interrupted write → all or nothing), AC6 (newer save untouched), AC9 (force-quit right after a language switch keeps it) on each platform; the iOS and Android unit tests below |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Accepted) |
| **Enables** | Settings & parent area (reset), cloud-backup decision D-22, the map (reads progress) |
| **Blocks** | Shipping any build outside the team (progress format must be stable before players have saves) |
| **Ordering Note** | The slice's UserDefaults / SharedPreferences keys are migrated once on first launch of the new format (Migration Plan) |

## Context

### Problem Statement
The slice stores each key separately (iOS UserDefaults, Android SharedPreferences). The save GDD needs
three things that per-key storage can't promise on both platforms: the quiz-finish keys written as one
unit (Rule 4, AC3), a durable write before an immediate force-quit (AC9; UserDefaults persists
asynchronously), and a versioned format an older app can recognise and leave untouched (Rule 8, AC6).
Players will keep their saves across content updates for years, so the format must be decided before
anyone outside the team has a save.

### Constraints
- Offline, on-device only; no personal data (pillar *Safe for kids*).
- Tiny: under 20 KB even at 100 heroes (GDD F2).
- The same keys and meaning on both apps (parity), even though the storage code differs.
- Never crash and never show an error to a child on bad data.

### Requirements
- Keys: `save_version`, `lang`, `sound`, and per hero `completed`, `seen_open`, `stars` (1–3, best,
  never lowered), `medal` (never cleared). Unlocks are **derived** (D-16), never stored.
- The quiz-finish write is one atomic unit, before results; `seen_open` on title/map load; `lang` and
  `sound` immediately on change.
- Read once at launch; gameplay never waits on storage.
- A newer `save_version` is read-only for an older app: it runs fresh in memory and never writes.
- Damaged or missing → a quiet fresh start, keeping every individually valid key.
- Keys of heroes no longer bundled are kept.

## Decision

1. **One document per player**, `save.json`, in the app's private storage:
   - iOS: `Application Support/save.json` (not Documents; not visible in the Files app).
   - Android: `filesDir/save.json`.
2. **Shape** (identical on both apps):
   ```json
   {
     "save_version": 1,
     "lang": "vi",
     "sound": true,
     "heroes": {
       "tran-quoc-toan": { "completed": true, "seen_open": true, "stars": 3, "medal": true }
     }
   }
   ```
   Absent hero fields mean false / no stars. Unknown top-level keys and unknown heroes are preserved
   on rewrite (read into a pass-through map), so a newer app's extra data survives an older app's load.
3. **Atomic, durable writes.** Serialise the whole document and replace the file atomically; the
   temp naming is per platform: iOS `Data.write(to:options: .atomic)` (a temp file renamed over
   `save.json`); Android `AtomicFile` (its `.new` / `.bak` files, read back through `openRead()`). A
   crash mid-write leaves the previous file intact (AC3).
4. **When it writes, and durability.** Each write **starts at the change**: quiz finish (all its keys
   together, before results), title/map load (only if `seen_open` changed), and a `lang` / `sound`
   change. A ~2 KB atomic write is fast enough to run synchronously at that moment (or on a serial
   queue that the caller waits on). Force-stop and an out-of-memory kill skip the lifecycle callbacks,
   so durability never depends on onPause/onStop or a background flush; the background hook only waits
   for a write already in flight (AC9).
5. **Load once at launch**, before the first screen:
   - parse; on failure, start fresh (`lang vi`, `sound true`, no progress) and log in debug only;
   - **salvage per key**: each field is checked on its own (a type error or `stars` outside 1–3 drops
     only that field, AC4);
   - `save_version` greater than the app's → **read-only mode**: use the valid keys in memory and
     never write this session, settings included (Rule 8, AC6);
   - `save_version` lower → migrate forward step by step (none exist yet beyond the slice import).
6. **Only up.** The store refuses to lower `stars` or clear `completed`, `seen_open` or `medal`
   (defence in depth; the Core already only raises them).
7. **The Core is unchanged at its boundary:** `Progress.load`, `recordQuiz`, `markSeenOpen`,
   `saveLang` (+ `saveSound`) keep their meaning; only the storage behind them changes, and a fake
   store with a batch commit drives the tests.
8. **Backup (open, D-22, Luan decides):** recommendation **allow** the platform backup (iCloud /
   Google backup). The file holds only game flags (~2 KB, no personal data), and a child moving to a
   new or hand-me-down device keeps their heroes. The cost per platform:
   - **iOS:** allowing is the default (Application Support is backed up); no code. Excluding would set
     `isExcludedFromBackup` on the file.
   - **Android:** today's manifest has `allowBackup="false"`, so allowing **is a change**: set
     `allowBackup="true"` and add backup rules that include **only** `files/save.json`:
     `dataExtractionRules` (Android 12+) and `fullBackupContent` (Android 11 and below).

## Alternatives Considered

### Alternative 1: Keep per-key UserDefaults / SharedPreferences
- **Pros:** already built; trivial.
- **Cons:** no atomic multi-key write (AC3); UserDefaults persists asynchronously (AC9 at risk); no
  natural place for a version or a read-only mode.
- **Rejection Reason:** fails three ACs on at least one platform.

### Alternative 2: SQLite / Core Data / Room
- **Pros:** transactions, queries.
- **Cons:** a database for ~2 KB of flags; more code and migrations on two platforms; a dependency on Android.
- **Rejection Reason:** far heavier than the data needs.

### Alternative 3: One key-value entry holding the JSON
- **Pros:** atomic within one key on both stores.
- **Cons:** still asynchronous on iOS (AC9); mixes a document into a settings store.
- **Rejection Reason:** a file with atomic rename is simpler to reason about and identical on both.

## Consequences

### Positive
- One shape, testable by the same cases on both apps; all-or-nothing writes; safe across versions.
- A clear home for future reset (parent area) and migration.

### Negative
- A little more code than per-key storage (load, salvage, write queue, migration).
- The slice's existing keys need a one-time import.

## Risks
- **A bug in salvage drops progress.** Mitigation: unit tests for every damaged-field case; never
  delete the old file before the new one is written.
- **Older app overwrites a newer save.** Mitigation: read-only mode on a newer version (AC6 test).
- **Backup restores an old save onto a newer device state.** Accepted: the restored file wins as a
  whole; progress only goes up afterwards.

## GDD Requirements Addressed

| GDD | Requirement | How |
|---|---|---|
| save-and-progress | Rule 4 / AC3 atomic quiz-finish write | One document, write-then-rename |
| save-and-progress | Rule 7 / AC9 read once, no stalls, survive force-quit | Load at launch; background queue + flush on background |
| save-and-progress | Rule 8 / AC6 newer version read-only | Version check, no writes that session |
| save-and-progress | Rule 9 / AC4–5 damaged data | Per-key salvage, quiet fresh start |
| save-and-progress | Rule 10 unknown heroes kept | Pass-through of unknown heroes and keys |
| hero-progression | D-16 derived unlocks | No unlock list stored; `completed` + `seen_open` only |

## Performance Implications
- **CPU / IO:** one ~2 KB write per quiz finish or setting change, off the main thread.
- **Memory:** negligible. **Load time:** one small read at launch. **Network:** none.

## Migration Plan
On first launch with ADR-0003 code: if `save.json` is absent but slice keys exist in UserDefaults /
SharedPreferences (`lang`, `stars.<id>`, `completed.<id>`, `seen_open.<id>`, `medal.<id>`), build the
document from them, write it, and leave the old keys untouched (never deleted automatically). Then
write an `imported_from_prefs: true` marker in the document, so the import never runs twice (for
example after the player resets progress in a later parent area).

## Validation Criteria
- Unit tests on both apps (fake store with batch commit): AC1–AC7 and AC9 (simulated interrupt and
  immediate relaunch), migration from slice keys, unknown-key pass-through, only-up refusal.
- QC on each platform: force-quit right after a language switch (AC9); network off for a session (AC8).

## Related
- ADR-0001 (depends on). `docs/architecture/architecture.md` (Save Format section).
- `design/gdd/save-and-progress.md`, `design/gdd/hero-progression.md` (D-16). D-22 (backup).
