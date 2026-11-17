# TASK-031 Android tech plan (WIP, PAUSED 2026-11-17)

Status: **paused before drafting**. The leader moved the game to the studio process (/brainstorm →
/setup-engine → /create-architecture). These notes are the facts gathered so far, kept for
/setup-engine and /create-architecture. Nothing here is decided.

## Measured reference

- Dải Đất Anh Hùng's preview APK (SurfaceView + Canvas, no third-party libraries): **1.2 MB**,
  3.6 MB unzipped, of which classes.dex is 3.2 MB. A plain-Canvas 2D build costs about 1 MB before
  content.

## Notes to carry forward (unverified until a spike measures them)

- **2D:** Compose (keyboard layout across tablet and phone, multi-touch through pointerInput)
  vs SurfaceView + Canvas (our last game, no dependencies). Compose adds a few MB after R8. Show
  one picture at a time. A 1024² ARGB bitmap is 4 MB decoded, so decode off the main thread.
  The letter glyph draws at once, and the picture fades in when it's ready.
- **3D:** Filament + gltfio, or SceneView (built on Filament; the non-AR artifact pulls in no
  ARCore). That's a native library per ABI (ship through App Bundle ABI splits), plus .glb
  content at roughly 0.5–2 MB per model, against roughly 0.1–0.2 MB per 2D WebP. iOS wants USDZ,
  so 3D needs one source and two exports. Before K-01, a one-day spike (two tiny APKs) would
  measure the APK size difference, memory (PSS) and press-to-sound latency.
- **Input:**
  - Mashing: queue the presses and keep only the last one each frame (latest wins); a
    generation counter cancels stale decodes and sounds.
  - Hardware keys: ignore repeatCount > 0, map KEYCODE_A–Z, 0–9 and NUMPAD_0–9, and use
    unicodeChar for non-QWERTY layouts.
  - Back: a no-op callback while the child plays. Home, Recents and Meta shortcuts can't be
    blocked, so offer screen pinning (startLockTask, which shows the system prompt) behind the
    parent gate.
  - Run immersive, with gesture-exclusion rectangles at the edges.
- **Audio:** SoundPool, with every clip loaded at start (decoded PCM about 10 MB for 36 voices
  plus 26 object sounds) and 4 streams at most. A new press stops the previous press's streams and
  cancels its queued voice → object sound. SoundPool has no completion callback, so per-sound
  durationMs comes from the data (written by a build tool). Oboe only if measured latency is too
  high; MediaPlayer is too slow. AAC .m4a plays on both platforms.
- **Content JSON (to agree with iOS):** keys[] with id, kind (letter/number), label, picture
  {2d, 3d: {glb, usdz}}, word {lang}, sounds {object, voice {lang}}, durationMs, count and
  countPicture (numbers), plus layouts {abc, qwerty} as rows. It gets a JSON Schema and a shared
  fixture test on both platforms, as in the last game.
- **Families policy in code:**
  - The merged manifest has no INTERNET permission, and the AD_ID permission is removed
    (tools:node="remove").
  - A dependency allowlist check fails the build on Firebase, Play services or ad/analytics
    libraries.
  - No WebView and no links out. The Data safety form says no data collected.
  - targetSdk at Play's level when we submit.
- **Layout:** games/kid-learn-character/android/ with content/ as its sibling (the same pattern as
  the last game). Pure-Kotlin core (content, key map, press arbiter, sound plan) gets JVM tests;
  ui/ and audio/ sit on top.
- **Rough size:** 2D v1 is about 12–13 dev days. 3D adds 5–8 days plus content.
