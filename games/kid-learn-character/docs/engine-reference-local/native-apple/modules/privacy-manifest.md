# Privacy manifest and required-reason APIs

| Claim | Status |
|---|---|
| `NSPrivacyAccessedAPICategorySystemBootTime` covers `ProcessInfo.systemUptime` and `mach_absolute_time()`; reason `35F9.1`: "measure the amount of time that has elapsed between events that occurred within the app or to perform calculations to enable timers" | **SOURCED** — https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype (read 2026-11-18) |
| `mach_continuous_time`, `clock_gettime`, Swift `ContinuousClock` are not on that list | **SOURCED** (same page, by absence, 2026-11-18) |
| `UserDefaults` is a required-reason API; reason `CA92.1` for the app's own data | **SOURCED** — https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api (cited by PKC-09) |
