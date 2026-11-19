# iPad session 1a: results (TASK-127)

**Session paused by Luan partway through** (2026-11-19). Every row not run is NOT ASSESSED and is carried to the next iPad session.

**Who and when:**
- QC: game-qc-ios, writing the results as the session runs.
- Driver: game-dev-ios.
- Luan holds the device and does the hands-on steps.

**Date:** 2026-11-19.

**Device:** iPad13,4, iPad Pro 11-inch (3rd generation, M1), iPadOS 27.2 (24B119). The UDID and name are masked (`<udid>` / `<ipad>`). **Not the oldest supported iPad** (deployment target iPadOS 26), so P-2's figures are "measured on iPad13,4, not the oldest supported device".

**Builds under test:**
- `DeviceSpike` from source **7db7511a**, which names this folder (ADR-0011 D6). The **installed product was gated at adc11194**: 7db7511a plus evidence commits only, 0 non-evidence files differ (checked). It was rebuilt because the first product's profile didn't list the iPad (0xe8008012); see `install.txt`. The install gate is on that exact product: `build-ios.txt`, `test.txt`, `spike-check-ios.txt` (items 1–7 PASS, exit 0; entitlements `application-identifier`, `team-identifier`, `get-task-allow` only; no network, Rive or URL loading).
- For P-1's baseline: the TASK-033 app **SpikeNoRive** built at **b30e9713**. Its source is identical to 7db7511a, because b30e9713 adds only evidence files (checked: 0 non-evidence files differ). The install gate is in `P-1-baseline/`: spike check items 1–5, 7 PASS, exit 0, no Rive; MorphCore tests 7/7.

**Rules:**
- **Spike runs are ADR evidence, never AC evidence** (device-checks plan, Spike runs). A PASS here decides the ADR row
  only. The GDD acceptance criteria wait for the production re-run named per row.
- **Every row not run is NOT ASSESSED**, never a pass.

**Masking:** UDID, team ID, Apple ID, certificate ID, `$HOME` and all paths are masked in every committed file.

| Check | Result | Build | Feeds | Evidence | Notes |
|---|---|---|---|---|---|
| F-2 Developer Mode | **PASS** (19:46:10, `devicectl` developerModeStatus enabled) | — | setup | `install.txt` | Xcode + Device Hub open 19:41:56–19:45:01 with leader/Luan OK (K-34); device registered for the Personal Team profile; DeviceSpike installed 19:47:30 |
| F-3 Trust the developer certificate | **PASS** (19:48–19:49) | — | setup | the app's first launch log on the iPad (uptime 291.0 s) | Luan trusted it in Settings › General › VPN & Device Management; DeviceSpike opened (Luan, relayed by the leader) |
| F-4 Guided Access passcode | **NOT ASSESSED** (not set up; the session paused before P-4) | — | setup (P-4) | — (a setting; Luan confirms) | |
| H-2 Overlap check (device confirmation) | **PASS**, agrees with headless 6e455bfc (19:57; two runs identical) | DeviceSpike | ADR-0009 D3 | `P-2/h2-overlap.txt` (+ screenshot) | stroke alpha 0.8 and node alpha 0.8: crossing 0.961, arm 0.800 → BLENDS TWICE; **outline = effect node**, so the A-candidate is measured with the effect node; ADR-0013's lower-bound rule doesn't apply |
| P-2 Render: A-candidate, B-load, original A (information) | **PASS on iPad13,4** for frame time, load and not-rebuilt; crisp **NOT ASSESSED** (the A-candidate needs a tap to select; Luan was away); **the decisive oldest-iPad run is NOT ASSESSED** (ADR-0009 D1 judges P-2 on the oldest supported iPad) | DeviceSpike | ADR-0009 D1 | `P-2/p2-run2.txt`, `p2-run2-log-screen.png`, `render-open-optionA.png` (run 1: `p2-run1-log.txt`, `p2-run1-memory.txt`, no frame times) | Run 2 at 120 Hz, each option held 38–43 s; stats = last 1200 frame deltas (10 s). **A-candidate (`outline=effect node`):** p50 / p99 **8.34 / 8.34 ms**, load 0.1–0.2 ms per creature, footprint 137.9–138.3 MiB (peak 139.8). **B-load:** 8.34 / 8.34 ms, load 3.9–5.6 ms, 118.5–118.6 MiB (peak 128.4). **Original A** (information): 8.34 / 8.34 ms, load 0.1 ms, 93.5–94.3 MiB. All under p99 16.7 ms and load 1.2 s, even at the 120 Hz budget (8.33 ms). **Not rebuilt per frame:** one "creatures built" line per option change, none during the holds. Memory: xctrace Activity Monitor, physical footprint at ~1 s samples (the .trace files stay local: size and device identifiers). **Not measured on the spike:** app-size delta, Settings Store read time (production re-run) |
| P-1 Latency: baseline (TASK-033 app) and candidate (DeviceSpike Audio) | **NOT ASSESSED** (no 240 fps camera this session; Luan deferred it to the weekend; the TASK-033 baseline built and gated but not installed) | both | ADR-0010 | `P-1/` videos + tables | 240 fps film; not with the child watching |
| P-7 No click on a cut | **FAIL (open)**: the detector's cuts PASS (cut voice −66.4, cut cast −69.7, cut music −73.6, mute voice −73.9 dBFS, threshold −60), but **Luan heard a pop on every button except Tone freeze**, and start and stop weren't told apart. ADR-0010 P-7 needs both the tap measure and the listening, so a heard pop isn't a pass until its cause is split (a start pop, a stop pop, or the button's own sound) | DeviceSpike Audio | ADR-0010 | `P-7/p7-notes.txt`, `p7-route-builtin.png`, `p7-log-1.png`, `p7-log-2.png` | Built-in speaker (io 5.33 ms, out 5.50 ms; rewind would be max(20, 10.33) = 20 ms). **Freeze continuity's Δ, the start delay against the rewind, and the capped-rewind line: not read** (below the log box's visible area; the session paused). The detector arms 50 ms before a cut, so it **doesn't cover a sound's start**; the tones are 100 Hz, which the built-in speaker barely reproduces. Luan's words are verbatim in the notes. Follow-up (game-dev-ios, own branch): find the pop's cause and add a start-of-sound window, then the weekend re-run separates start from stop. **Headphones-out mid-line: not run** (a Bluetooth disconnect was to stand in, since the spike handles `oldDeviceUnavailable` for any port; wired headphones-out stays NOT ASSESSED) |
| P-8 Interruptions | **NOT ASSESSED** (session paused; Luan deferred it to the weekend) | DeviceSpike Audio | ADR-0010 | `P-8/` | route change by Bluetooth speaker disconnect (as P-7) |
| P-9 Silent switch | **NOT ASSESSED** (session paused) | DeviceSpike Audio | ADR-0010 | `P-9/` screenshots | built-in speaker only |
| P-4 Guided Access + keyboard shortcuts + media keys | **NOT ASSESSED** (Guided Access part: session paused; shortcuts and media keys: no hardware keyboard) | DeviceSpike | ADR-0008 (Guided Access); ADR-0007 (media keys) | `P-4/` | |
| P-15 Hardware keyboard: 36 keys, numpad, modifiers | **NOT ASSESSED** (no hardware keyboard this session) | DeviceSpike Keys | ADR-0007 | `P-15/` | compared with input-filter-v2 |
| P-0, P-12 (also in 1a, need the production app) | NOT ASSESSED | — | — | — | no production build yet |

**After the session:** `DeviceSpike` **removed from the iPad at 20:24:19** (`devicectl device uninstall app`; `device info apps` shows 0 matches afterwards). The TASK-033 app was **never installed** (built and gated at b30e9713 only). Timeline: `session.txt`.

**Spike-only observations** (not verdicts; for the owners):
- `DeviceSpike`'s ppi table has no iPad13,4 row (Apple spec **264 ppi**; the spike reports **"326 unknownClassMax"**), so it fell back to the class maximum (326, `unknownClassMax`), as ADR-0006 D7 says. The production ppi table needs iPad13,4. Flash fields (ADR-0013 D6) use the class floor anyway.
- The launch line reads `build=dev` (the SpikeCommit Info key isn't set). The build sha is taken from the gate log.
- RenderScene's "creatures built with option …" label prints "B" for the A-candidate. The `[render] option=` stats line is the reliable label.
- **Screenshots checked by QC:** the committed PNGs show only DeviceSpike's own view and the iPad status bar (time, date, Wi-Fi, battery). Run 1's screenshot with a personal notification banner was deleted before any commit (branch history: only the six PNGs now in `P-2/` and `P-7/` were ever added). Run 2 used Do Not Disturb.
