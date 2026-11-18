# AVFAudio (sound and voice)

| Claim | Status |
|---|---|
| `AVAudioEngine` + `AVAudioPlayerNode` play decoded PCM buffers on macOS and iOS 27 | **PROVEN (TASK-033)** (Mac; iPad Simulator) |
| stop + schedule + play on the main thread costs 3–10 ms | **PROVEN (TASK-033)** (Mac; iPad Simulator) |
| Press → first audible sample: Sim ≈ 8–9 ms, Mac ≈ 18–19 ms (estimates from schedule time plus reported latencies) | **PROVEN (TASK-033)** as estimates only; device NOT ASSESSED |
| `.soloAmbient` obeys silent mode and does not mix | **NOT SOURCEABLE** here; audio ADR (ADR-0010) to source and prove |
| Engine stops on interruption / configuration change; media-services reset needs a rebuilt graph | **NOT SOURCEABLE** here; audio ADR to source and prove |
| AAC priming and padding (~2112 samples) affect decoded length | **NOT SOURCEABLE** here (Key Table V15 states it); the build tool proves it by measurement |
