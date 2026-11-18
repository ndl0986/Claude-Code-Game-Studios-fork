# AVFAudio (sound and voice)

| Claim | Status |
|---|---|
| `AVAudioEngine` + `AVAudioPlayerNode` play decoded PCM buffers on macOS and iOS 27 | **PROVEN (TASK-033)** (Mac; iPad Simulator) |
| stop + schedule + play on the main thread costs 3–10 ms | **PROVEN (TASK-033)** (Mac; iPad Simulator) |
| Press → first audible sample: Sim ≈ 8–9 ms, Mac ≈ 18–19 ms (estimates from schedule time plus reported latencies) | **PROVEN (TASK-033)** as estimates only; device NOT ASSESSED |
| `.soloAmbient`: "Other music will stop playing"; `.ambient`: "Mixes with other music" | **SOURCED** (iOS 27.1 SDK header `AVAudioSessionTypes.h`, ADR-0010 Sources) |
| `.soloAmbient` is silenced by silent mode | **NOT SOURCEABLE** (headers silent); ADR-0010 row P-9 proves it |
| Engine stops itself on a hardware channel-count or sample-rate change and posts `AVAudioEngineConfigurationChange`; nodes stay connected | **SOURCED** (`AVAudioEngine.h`, ADR-0010 Sources) |
| Media-services reset: "re-initialize any audio objects" | **SOURCED** (`AVAudioSessionTypes.h`) |
| `interruptionNotification` and `.shouldResume` are deprecated in iOS 27; replaced by `didBecomeInactiveNotification` + `resumptionRecommendationNotification` (27.0+) | **SOURCED** (`AVAudioSessionTypes.h`); behaviour on a device: ADR-0010 row P-8 |
| `AVAudioPlayerNode.play()` deprecated in the 27 SDKs; `playAudio()` (throws) is 27.0+ | **SOURCED** (`AVAudioPlayerNode.h`) |
| `stop()`, `pause()` or `.interrupts` on a sounding player clicks (−38.7 dBFS); an `AVAudioMixerNode.outputVolume` jump is smoothed by the mixer (below −60 dBFS ≈ 27 ms after a jump to 0, no discontinuity) | **PROVEN offline (TASK-087 H-1)**, macOS 27 manual rendering; device: rows P-7 / M-14 |
| AAC priming and padding (~2112 samples) affect decoded length | **NOT SOURCEABLE** here (Key Table V15 states it); the build tool proves it by measurement |
