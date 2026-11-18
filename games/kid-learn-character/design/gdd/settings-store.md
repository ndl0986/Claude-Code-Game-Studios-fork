# Settings Store

> **Status**: Approved (independent review by game-dev-ios, 2026-11-18)
> **Author**: game-dev-android for Luan (TASK-039); plan reviewed by game-dev-ios
> **Last Updated**: 2026-11-18 (TASK-054a follow-ups)
> **Last Verified**: 2026-11-18, against ADR-0001 (Accepted) Decisions 8 and 9, art bible §2, §4 and §7, TASK-034
> **Implements Pillar**: Pillar 5 (Safe by Design)

## Summary

The Settings Store keeps the few choices a grown-up makes in the grown-up panel (volume, mute, theme, weather,
the keyboard row and, on the Mac, the child lock) on the device, so they are still there the next time the app
opens. It stores nothing about the child or their play, it never syncs, and a damaged or missing record falls
back to defaults without a crash. It stores values only. Other systems act on them.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None` (written by the Parent Gate &
> Grown-up Panel; read by Audio & Voice, Key Table & Theme Data, Scene: Time of Day & Weather, On-screen Keyboard
> Row, Child Lock-in and App Shell)

## Overview

Letter Morph has no progress, no scores and nothing to save (concept, Session-Level and Long-Term Progression).
What it does have is a handful of grown-up choices that would be annoying to set again every launch. The Settings
Store is the one place those choices live: one small record in the app's own local preferences, read once at
launch, written whenever the grown-up changes something, and reset to defaults by "Start over". The list of
stored fields is closed. Anything not on it is not stored, by any system. The store is also the evidence for
Pillar 5's "no data" claim: what is stored can be listed in one table, and none of it identifies or describes the
child.

## Player Fantasy

The child never meets this system. For the grown-up, the fantasy is "set it once": the volume they chose
yesterday, the theme the child loves, the weather they picked and the keyboard row they turned on are all still
there when the app opens again, and on the Mac the child lock is back on without anyone remembering to do it. The
grown-up can also trust that nothing about their child is being kept: there is nothing to clear, export or worry
about, and "Start over" really does return the app to how it was on day one.

## Detailed Design

### Core Rules

**R1. What is stored.** One record. Every field is set only from the grown-up panel (except `schemaVersion`).

| Field | Type and values | Default | Read by |
|---|---|---|---|
| `schemaVersion` | integer ≥ 1 | `1` | the store itself (R7) |
| `volume` | integer `0`–`10` (F1) | `8` (Luan, Q1) | Audio & Voice |
| `muted` | boolean | `false` | Audio & Voice |
| `themeId` | string, non-empty | `"dinosaurs"` | Key Table & Theme Data |
| `weather` | one of `clear`, `cloudy`, `lightRain`, `snow` | `clear` | Scene: Time of Day & Weather |
| `windy` | boolean; takes effect only with `lightRain` or `snow` (art bible §2) | `false` | Scene: Time of Day & Weather |
| `keyboardRow` | boolean | `false` (art bible §7: off by default) | On-screen Keyboard Row, Input & Key Filter |
| `childLock` | boolean; **macOS only** (the key does not exist on iPadOS or Android) | `false` | Child Lock-in. **Stored only as ON** (K-21, R8): turning it OFF in the panel lasts for this run only; the run value is `childLockActive` (R8) |

- **Reserved, not in v1:** `voiceLocale` (Alpha, K-02 Vietnamese voice). It arrives with a schema bump (R7).
- `muted` keeps `volume` untouched: unmuting returns to the same level.
- `windy` is kept when the weather is `clear` or `cloudy` but has no effect there; it takes effect again when the
  grown-up picks `lightRain` or `snow` (game-dev-ios's review).
- **Weather is kept until the grown-up changes it** (Luan, Q2, 2026-11-18). No date is stored. This supersedes
  the "today's weather" wording in the art bible §2 and K-08: the pick does not expire at midnight.

**R2. What is never stored.** The list in R1 is closed: **if a value is not in R1, no system stores it**, in this
record or anywhere else on the device. In particular, never:

- play history, seen letters or cast members, the parade's "8 met" count (art bible §4: no "seen" marks);
- press, reveal or session counts, the morph's reveal count (K-11), Key Table's `lastShown` (its R3);
- the variety seed or any morph seed;
- any timestamp or date (first launch, last launch, when a setting changed, weather pick date);
- analytics, events, logs written to disk, crash reports;
- any identifier: device id, IDFV, advertising id, install id, a generated UUID;
- the child's or grown-up's name, age or photo;
- parent-gate attempts or failures;
- Reduce Motion / "Remove animations" and the time of day: these are **read live** from the OS and the clock
  every time they are needed (art bible §7, K-08), never copied into the store.

A new field needs a GDD change to R1 and a schema bump (R7). Debug logging (R6) is never written to a file by
the app: on Apple it uses `Logger` at the **`.debug`** level, which the unified log keeps in memory only and does
not persist (`.default` and `.error` are persisted, so they are not used for these lines); on Android, Logcat. Framework
state the OS would save on the app's behalf is turned off where the app controls it, so the app's preferences hold
only the record:
- **macOS:** window restoration off, with SwiftUI's window restoration modifier (`.restorationBehavior(.disabled)`)
  or, for an AppKit window, `NSWindow.isRestorable = false` and an empty frame autosave name (no
  `setFrameAutosaveName`), so AppKit writes no `NSWindow Frame` key and no saved window state.
- **iPadOS:** no scene state restoration (no `stateRestorationActivity`, no `NSUserActivity` saved for the scene).
- **Android:** no `onSaveInstanceState` use for settings; the record is the only stored state.

**R3. Device only; no sync.**

- The record lives in the app's own local preferences (for example `UserDefaults.standard` on iOS/macOS, a
  `SharedPreferences` file or DataStore on Android). No app group, no shared container.
- **No sync of any kind:** no iCloud key-value store (`NSUbiquitousKeyValueStore`), no CloudKit, no Firebase or
  other cloud service, no network (ADR-0001 Decision 8: network none).
- **Why (Pillar 5):** data that leaves the device under the app's control changes the Kids-category and COPPA
  analysis (TASK-034, "What to store"); a family's second device should not silently inherit a Mac child lock or
  a weather pick; and "nothing leaves the device" is a promise the grown-up can check.
- **OS device backups are allowed** (Luan, Q4, 2026-11-18): the record holds settings only, nothing personal.
  On Apple, `UserDefaults` is included in iCloud and Finder device backups by default; the app does not exclude
  it. On Android, `android:allowBackup` / `dataExtractionRules` leave the file in Auto Backup and device-to-device
  transfer (the Android ADR sets the XML). A backup is the OS restoring the user's own device, not the app sending
  data, so it is not sync under this rule.

**R4. One record, written atomically.**

- The whole record is encoded as **one value under one key** (for example UTF-8 JSON stored as `Data` under the
  `UserDefaults` key `settings`), or as **one file written atomically** (write to a temporary file, then rename).
  Individual fields are never stored under separate keys. So a write either replaces the whole record or does
  not happen; a crash or power loss mid-write leaves the old record or the new one, never a mix.
- **Writes:** on every grown-up change, the store writes the full in-memory record at once (one exception: a
  run-only child-lock OFF changes only `childLockActive` and writes **nothing**, R8, K-21; the record keeps
  `childLock: true`). The volume slider
  writes when it is released, not on every step while dragging. **While dragging**, the grown-up panel sends
  the preview gain (F2 from the slider's current position) straight to Audio & Voice, so the grown-up hears the
  level as they move it; the store is not involved. **On release**, the store writes `volume` (F1) and sends one
  notification (R10). Writes happen on the main thread (the record is
  under 1 KB).
- **Reads never write.** A read that finds problems (R6, R7) fixes them in memory only; the record on disk is
  rewritten only by the next grown-up change or by Reset.
- **Apple Required-Reason API:** `UserDefaults` is a required-reason API. The privacy manifest declares
  `NSPrivacyAccessedAPICategoryUserDefaults` with reason **`CA92.1`** (data written and read by the app itself).
  The store reads **no file timestamps** (no modification or creation dates), so no file-timestamp reason is
  needed (Privacy & Kids Compliance owns the manifest).

**R5. Launch order and first launch.**

1. **Read the store**, synchronously, once, before the first frame. The record is tiny, so this is a few
   milliseconds at most.
   - **Android note (for its ADR):** DataStore is asynchronous; either block once at launch on its first value or
     use `SharedPreferences` for this one record. Either way, no frame is drawn with unread settings.
2. **Hand `themeId` to Key Table & Theme Data**, which loads and checks the theme **off the main thread** (Key
   Table R5).
3. **App Shell shows the title** and **holds play until the theme is loaded**: the play button and a title-screen
   key (`startPlay`, Input & Key Filter, Title state) do not enter Play until Key Table reports the theme ready.
   The Press Queue never sees a press before then.
4. **Stage:** Audio applies `volume`/`muted`, the Scene applies `weather`/`windy`, the keyboard row appears if
   `keyboardRow` is on.
5. **Mac child lock (R8)**, only after the app is ready.

- **First launch, or no record:** every field takes its R1 default; **nothing is written** until the grown-up
  first changes something. "No record" is a valid state, identical to all defaults.

**R6. Validation, per field.** Each field is checked on its own when the record is read:

- Missing, wrong type, or outside its R1 values → **that field's default**, in memory. The other fields are kept.
- `volume` given as a non-integer number inside 0–10 is rounded (F1); `NaN`, infinite or outside 0–10 → `8`.
- `weather` with an unknown name → `clear`. `windy` with `clear`/`cloudy` is valid (R1).
- `themeId` that is not a non-empty string → `"dinosaurs"`.
- **A `themeId` that names a theme that is not bundled, or that fails Key Table's load check at launch:** Key
  Table loads **Dinosaurs in memory**, and **the stored `themeId` is kept** (game-dev-ios's review). The store does
  not rewrite it; the next write keeps it unless the grown-up picks a theme. So a theme that fails once is not
  lost from the grown-up's choice, and the child still gets a working theme.
- `childLock` present on iPadOS or Android → ignored, and dropped from the record at the next write.
- Unknown keys inside the record → ignored (see R7 for a newer record).
- **The whole record unreadable** (not decodable, wrong type under the key, empty bytes) → all defaults in memory;
  the next write replaces it.
- Every fallback writes **one debug log line** (`.debug` level, R2; field name and reason, never the value of a theme
  path or anything else). **Never a crash, never a dialog**; the child sees nothing.

**R7. Schema version and migration.**

- `schemaVersion` starts at `1`. It changes only when R1 changes (a field added, removed, renamed or its meaning
  changed).
- **Older record** (version < app's): migrations run in steps, v1 → v2 → … → current, each a pure function from
  one record to the next, each unit-tested with a fixture. The result is used in memory and written at the next
  grown-up change (reads never write, R4).
- **Missing or invalid `schemaVersion`** (not an integer ≥ 1) → treated as version 1 and validated per R6.
- **Newer record** (version > app's; only after a downgrade, which the App Store does not do but TestFlight and
  development builds can): the app reads the fields it knows, with R6 validation, and ignores the rest. When this
  older app next writes, it writes the record **at its own version, and the newer fields are lost**. This is
  accepted and stated: the newer fields are grown-up settings, the newer app falls back to their defaults (R6),
  and keeping unknown keys would let a newer app read values an older app never validated.

**R8. Child lock comes back after a relaunch, only once the way out works** (Luan, Q3, 2026-11-18).

- The store only stores `childLock`. **Child Lock-in** applies the kiosk (`NSApplication.presentationOptions`,
  ADR-0001 Decision 9b), and only while the app is active.
- If `childLock` is `true` at launch, Child Lock-in engages it **only after all of**: the first frame has been
  drawn; the ⌃⌥⌘Q parent chord handler is installed (Input & Key Filter R6); and Input's kiosk-on mode is active
  (Input & Key Filter R5). The kiosk blocks force-quit and shutdown, so it must never engage before the way out
  works (game-dev-ios's safety point). Child Lock-in R3 holds the full list (also the window covering its display,
  the app active, and `childLockActive`).
- The `childLock` key does not exist off macOS (R1, R6).
- **The run value `childLockActive`** (macOS only; TASK-054 S2). Besides the stored `childLock`, the store keeps a
  **run value** `childLockActive`, in memory only and never written: **at launch it equals the stored `childLock`**
  (false when there is no record). It is what Child Lock-in engages and disengages on (Child Lock-in R3, R4), and
  what the Parent Gate's switch shows and sets (Parent Gate G11).
- **OFF lasts for this run only** (Luan, K-21; TASK-050). Turning the lock **ON** in the panel sets
  `childLockActive = true` **and** writes `childLock: true` (one write, one notification). Turning it **OFF** sets
  only `childLockActive = false`: **no write**, one notification (R10); the kiosk turns off for this run. Every
  later write of another field keeps `childLock: true` in the record, so `childLock` is **never persisted as false**
  once it has been turned on. At the next launch the lock is ON again and engages once the app is ready (the order above, K-12).
  Closing the panel with the lock OFF shows "Child lock is OFF" for a few seconds (the panel GDD's). The only way to
  clear the stored ON is Reset (R9), which removes the record.

**R9. Reset ("Start over").**

- The Parent Gate & Grown-up Panel owns the button and its confirmation. The store's part: Reset **removes the
  record** (or replaces it with an empty one), so the app is back to the first-launch state (R5), and every field
  takes its R1 default in memory.
- Reset sends **one** change notification carrying the whole new record (R10), not one per field, with
  `childLockActive = false`.
- Since nothing else is stored (R2), this is all of the app's saved state. If `childLock` was on, Child Lock-in
  turns the kiosk off when it receives the notification.

**R10. Change notifications.**

- Consumers read the current in-memory record and subscribe to changes. A change is delivered **on the main
  thread**, after the write has been issued, as the whole new record plus `childLockActive` (consumers compare what
  they care about).
- One grown-up change → one notification. Reset → one notification. **A run-only child-lock OFF → one
  notification with no write** (`childLockActive` false, the record unchanged; TASK-054 S1), so Child Lock-in can
  disengage. Reads at launch send none (consumers read the
  record directly in the R5 order).

**R11. Ownership.** The Settings Store owns storage, defaults, validation, migration, Reset and notifications. It
does **not** apply anything: Audio & Voice applies volume and mute, Key Table loads the theme, the Scene draws the
weather, the On-screen Keyboard Row shows itself, Child Lock-in applies the kiosk, and the Parent Gate & Grown-up
Panel owns every control that changes a field.

### States and Transitions

| State | Meaning | Enter / leave |
|---|---|---|
| **Unread** | Before launch step 1; nobody may read a field | left by the launch read (R5) |
| **Ready** | The in-memory record is valid (defaults, stored values, or a mix after R6) | entered after the read; stays for the rest of the run |

There is no "saving" state a consumer can see: a write replaces the record at once (R4) and the in-memory record
is already the new one.

### Interactions with Other Systems

| System | Direction | Interface |
|---|---|---|
| Parent Gate & Grown-up Panel | writes | sets each R1 field; calls Reset (R9); previews the volume gain to Audio while the slider is dragged (R4) |
| App Shell & Title | reads | runs the launch order (R5); **holds play until the theme is loaded** |
| Key Table & Theme Data | reads | `themeId` at launch and on change; falls back to Dinosaurs in memory (R6); saves nothing of its own state (its R3) |
| Audio & Voice | reads | `volume` (0–10, F2) and `muted`; also takes a preview gain from the panel during a slider drag (R4) |
| Scene: Time of Day & Weather | reads | `weather` and `windy`; time of day comes from the clock, not the store |
| On-screen Keyboard Row | reads | `keyboardRow` |
| Input & Key Filter | reads (indirectly) | the keyboard row's on/off decides whether row rectangles are published; Child Lock-in sets Input's kiosk-on mode |
| Child Lock-in | reads | `childLockActive` (macOS only) and its notifications; engages per R8 and Child Lock-in R3 |
| Privacy & Kids Compliance | evidence | R1–R4 are its list of stored data, its "no sync" and its Required-Reason entry |
| Accessibility | none | Reduce Motion is read live from the OS (R2), never stored |
| MorphCore, Press Queue, Parade, Hint Letters, Reveal Stage | none | keep no persisted state (R2) |

## Formulas

**F1. Volume level stored.**

From the slider: `level = clamp(round(x), 0, 10)`

From the record: `level = round(r)` if `r` is a finite number with `0 ≤ r ≤ 10`, otherwise `level = 8` (R6)

| Variable | Meaning | Range |
|---|---|---|
| `x` | the slider's position in steps | 0–10 (a real number while dragging) |
| `r` | the value read from the record | any JSON value |
| `level` | the stored volume | integer 0–10 |

`round` is half away from zero. The slider is clamped (its output can only leave 0–10 by rounding error); a read
value is never clamped: out of range or non-finite means the record is wrong, so the field takes its default.

Examples: slider at 7.4 → 7; at 7.5 → 8; at 0.4 → 0. Read 6.6 → 7; read 10 → 10; read 12, −1, 10.4 or NaN → 8.

**F2. Gain handed to Audio.**

`gain = muted ? 0 : level / 10`

| Variable | Meaning | Range |
|---|---|---|
| `level` | F1 | 0–10 |
| `muted` | R1 | true / false |
| `gain` | the linear app volume Audio applies on top of the device volume | 0.0–1.0 |

Examples: level 8, not muted → 0.8 (the default); level 8, muted → 0; level 0, not muted → 0 (silent, but
`muted` stays false so the panel shows the slider at 0, not "muted"). Audio & Voice may map `gain` through a
perceptual curve; that curve is its own and the store only hands over `gain`.

## Edge Cases

- **First launch:** no record; all defaults; nothing written until the first change (R5).
- **The app is killed during a write:** the old or the new record survives, never a mix (R4).
- **The record is garbage** (wrong type, corrupt bytes): all defaults, one log line, no crash; the next change
  overwrites it (R6).
- **One field is wrong** (e.g. `volume` = "loud"): that field is 8, the others are kept (R6).
- **The stored theme is not bundled any more, or fails its check:** Dinosaurs plays, the stored `themeId` is kept
  (R6). If the grown-up opens the panel, the panel shows Dinosaurs as the active theme (the panel GDD decides how).
- **`windy` with clear or cloudy:** kept, ignored; returns with rain or snow (R1).
- **A record restored from a backup on a new device:** read like any other record. On a new Mac with
  `childLock` on, the kiosk comes back only after the app is ready (R8).
- **A Mac record somehow on an iPad or Android device** (not possible through OS backups, which are per platform,
  but handled): `childLock` is ignored and dropped at the next write (R6).
- **A downgrade to an older build:** newer fields are lost at the next write (R7), stated and accepted.
- **Reset with the child lock on:** one notification; Child Lock-in turns the kiosk off (R9).
- **Two quick changes** (e.g. mute then unmute): two writes, two notifications, in order; the last one wins on
  disk.
- **Storage full or the write fails** (where the platform reports it: an atomic file write or
  `SharedPreferences.commit()` returns failure; `UserDefaults` does not report one): the in-memory record keeps the change for this run; one log line; the
  next change retries the whole record. The child sees nothing.
- **The weather was picked days ago:** it is still shown; the pick does not expire (R1, Luan Q2).

## Dependencies

- **Upstream:** none. The store reads no other system's data.
- **Downstream (each must name the Settings Store in its own GDD; none of their GDDs exist yet except Key Table
  and Input & Key Filter):**
  - Parent Gate & Grown-up Panel (writes every field, calls Reset).
  - App Shell & Title (launch order, holds play until the theme is loaded).
  - Key Table & Theme Data (`themeId`; its R3 and Interactions table already name the Settings Store).
  - Audio & Voice (`volume`, `muted`).
  - Scene: Time of Day & Weather (`weather`, `windy`).
  - On-screen Keyboard Row (`keyboardRow`).
  - Child Lock-in (`childLockActive`, R8 ordering; its R3 lists the full preconditions).
  - Input & Key Filter (keyboard row on/off and kiosk-on mode, both indirectly).
  - Privacy & Kids Compliance (R1–R4 as evidence; privacy manifest).
- **Documents:** ADR-0001 Decision 8 (network none) and 9b (kiosk); art bible §2 (weather list, "today's weather"
  superseded by R1), §4 (no "seen" marks), §7 (keyboard row off by default, Reduce Motion follows the OS, parent
  chord); TASK-034 "What to store" (device only, no sync); decisions K-07, K-08, K-10, K-11.
- **Platform ADRs:** the Android ADR chooses DataStore (blocking once) or `SharedPreferences` (R5) and writes the
  backup XML (R3).

## Tuning Knobs

These are design defaults, not play-tuning values. Changing a default changes what a new install looks like; it
never changes a stored value.

| Knob | Value | Safe range | Effect |
|---|---|---|---|
| Default `volume` | 8 | 5–10 | how loud a fresh install is; below 5 a grown-up may think the sound is broken |
| Volume steps | 11 (0–10) | fixed by the schema | a change needs a schema bump |
| Default `themeId` | `"dinosaurs"` | any bundled theme that passes the build gate | the first theme a child sees |
| Default `weather` | `clear` | any R1 weather | the first sky; clear keeps the glyph easiest to read |
| Default `keyboardRow` | `false` | fixed by art bible §7 | — |
| Default `childLock` | `false` | fixed: the kiosk must be turned on by a grown-up | — |

## Acceptance Criteria

All are unit tests against an in-memory or temporary store unless stated.

- **AC-1 Defaults:** GIVEN an empty store, WHEN it is read, THEN every field equals its R1 default (volume 8,
  muted false, themeId "dinosaurs", weather clear, windy false, keyboardRow false, childLock false on macOS and
  absent elsewhere), AND no record has been written.
- **AC-2 Round trip:** GIVEN each R1 field set to each of its boundary values (volume 0 and 10; every weather; both
  booleans), WHEN it is written and the store re-created and read, THEN the value is the same.
- **AC-3 Closed list:** GIVEN any sequence of panel changes, WHEN the stored record is decoded, THEN its keys are
  exactly `schemaVersion` plus the R1 fields for the platform (no `childLock` off macOS), AND no value is a date,
  UUID or identifier. **Build check:** the store is the only code that calls the platform preferences API
  (`UserDefaults`, `SharedPreferences`/DataStore) or writes a file in the app's container. (Keys the OS frameworks
  write on their own are outside this check; on macOS the app turns off window-frame autosave so AppKit writes no
  `NSWindow Frame` key, R2.)
- **AC-4 One field invalid:** GIVEN a record with exactly one bad field, for each of: volume "loud", volume NaN,
  volume 12, volume −1, weather "storm", themeId 5, themeId "", keyboardRow "yes", WHEN read, THEN only that
  field takes its default and every other field keeps its stored value, AND one log line names the field.
- **AC-5 Volume rounding (F1):** WHEN the slider releases at 7.4, 7.5 and 0.4, THEN the stored levels are 7, 8 and
  0; GIVEN a stored 6.6, THEN it reads as 7.
- **AC-6 Gain (F2):** level 8 unmuted → 0.8; level 8 muted → 0; level 0 unmuted → 0 with `muted` false.
- **AC-7 Garbage:** GIVEN the record is random bytes, an empty value, or a value of the wrong type under the key,
  WHEN read, THEN all defaults, no crash, no exception escapes the store, one log line.
- **AC-8 Atomic write:** GIVEN a stored record A, WHEN a write of record B is interrupted at any point (test seam:
  the writer fails before the commit/rename), THEN a read returns A or B in full; AND the record is one value
  under one key or one file (checked by inspecting the store's keys).
- **AC-9 Reads never write:** GIVEN a record with a bad field or an older version, WHEN it is read, THEN the bytes
  on disk are unchanged.
- **AC-10 Theme kept on failure:** GIVEN `themeId` "vehicles" stored and not bundled (or failing Key Table's
  check), WHEN the app launches, THEN Key Table loads Dinosaurs AND the stored `themeId` is still "vehicles"
  after a later write of `volume`.
- **AC-11 Windy kept:** GIVEN weather snow and windy true, WHEN the grown-up picks clear, THEN windy is still true
  in the record and the Scene shows no wind; WHEN they pick snow again, THEN wind is applied.
- **AC-12 Migration:** GIVEN a v1 fixture and (once one exists) each later version's fixture, WHEN read by the
  current app, THEN the migrated record equals the expected fixture. GIVEN a record with `schemaVersion` 99 and an
  unknown key, WHEN read, THEN the known fields are used; WHEN volume is then changed, THEN the record is written
  at the app's version without the unknown key.
- **AC-13 Reset:** GIVEN every field non-default, WHEN Reset runs, THEN a read gives all defaults, the store is in
  the first-launch state (AC-1), AND exactly one notification was delivered.
- **AC-14 Notifications:** WHEN one field changes, THEN exactly one notification, on the main thread, carrying
  the whole record; WHEN the store is read at launch, THEN none.
- **AC-15 Mac child lock order (integration, macOS):** GIVEN `childLock` true stored, WHEN the app launches, THEN
  the kiosk presentation options are applied only after the first frame AND after the ⌃⌥⌘Q handler and Input's
  kiosk-on mode are active (checked by a launch-order log or test seam), AND ⌃⌥⌘Q opens the panel right after.
- **AC-15b Child lock OFF is for this run (macOS, K-21):** GIVEN `childLock` true stored, WHEN the grown-up turns it
  OFF in the panel, THEN `childLockActive` is false, exactly one notification is delivered, **no write happens** (the
  bytes on disk are unchanged), and the kiosk turns off now; AND after any other field's write the record still
  holds `childLock: true`; GIVEN a launch, THEN `childLockActive` equals the stored `childLock`; WHEN the app relaunches, THEN the lock is ON and engages per AC-15. GIVEN
  Reset, THEN the record is removed and the next launch has the lock off (default).
- **AC-16 No sync (build check):** the app binary and sources reference no `NSUbiquitousKeyValueStore`, CloudKit or
  network API for the store; Android declares no cloud or network service for it. The Apple privacy manifest
  lists `NSPrivacyAccessedAPICategoryUserDefaults` with `CA92.1` and no file-timestamp category.
- **AC-17 Relaunch (on device, retained screenshot):** set volume 3, theme Dinosaurs, weather light rain + windy,
  keyboard row on; quit and relaunch; THEN the panel shows the same values and the stage shows rain with wind
  and the row.
- **AC-18 Launch holds play:** GIVEN a test seam delaying the theme load, WHEN play is pressed on the title, THEN
  Play is not entered and no press reaches the Press Queue until the theme is ready.

**NOT ASSESSED:** whether a restored device backup on a different Mac model changes any behaviour; the real
read time on the oldest supported iPad (expected well under one frame).

## Open Questions

- None open.
- **Decided (Luan, 2026-11-18):**
  - Q1: an in-app volume slider, default 0.8 (stored as 8 of 10), plus mute.
  - Q2: the weather pick is kept until the grown-up changes it; no date is stored (supersedes "today's weather").
  - Q3: the Mac child lock comes back by itself after a relaunch, only once the app is ready (R8).
  - Q4: OS device backups are allowed (R3).
- **Chosen by the author:** a newer record's unknown fields are dropped when an older app writes (R7); Reset
  removes the record rather than writing defaults (R9).
