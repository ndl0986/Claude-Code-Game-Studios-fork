# Kid Learn Character: Apple Kids category + COPPA rules for the opt-in weather feature

**Task:** TASK-034. **Owner:** game-qc-ios. **Written:** 2026-11-17. **Base:** `docs/kid-learn-character-plan` @ 5aaaea7.
**Status:** desk research. Nothing was built or run. Every test case below is a plan.
**Decision under review (K-08, as the leader quoted it):** "Time of day from the system clock (no network); weather from
the network, opt-in behind the parent gate, asking for network, time and weather/location access; changes Pillar 5 and
the no-network anti-pillar; QC checks Kids + COPPA before any build; scope tier not decided."
**App:** native Swift, iPadOS + macOS first, children 2.5–3, Kids category intended.

## How to read this file

- The format follows the Android checklist (`qa/TASK-032-kids-store-rules-android` @ ac7b97b).
- **Sources** [S#] are listed at the end with the date read (all 2026-11-17). Quotes are verbatim from the live page.
  Anything QC could not tie to an official page is marked **not verified**.
- **QC is not legal review.** Rows that need a legal judgement are marked **Luan (legal)**. QC can say what the rule
  text says and check that the build does what the design promises. Whether that is enough under COPPA or GDPR is
  Luan's call, with advice if he wants it.
- "Time of day from the system clock" needs no network, no data and no permission. **It raises no Kids or COPPA issue**
  and is not discussed further. Everything below is about the weather half.

## Short answer

1. **Apple allows a network feature in a Kids app**, but the Kids rules forbid sending "personally identifiable
   information or device information to third parties". So a **third-party weather API is the one option to rule out**
   (it receives at least the device's IP address).
2. **COPPA: precise device location is personal information** and needs verifiable parental consent. A parent-gated
   toggle is not that consent (Apple says so too). **Coarse location "tantamount to a ZIP code" does not need consent**,
   per the FTC. The IP address on any request is a persistent identifier, but it is exempt when it is used only to
   perform the network communication and nothing else is collected. A notice is still required.
3. **Recommendation: the parent picks a city by hand** in the parent area (no Location Services at all). The app asks
   **Apple WeatherKit** for that city's weather with the city's coordinates rounded to about 10 km. It is **off by
   default**, behind the parent gate, with a plain-language consent screen. Only the city and the last condition are
   kept, on the device. This keeps Core Location, its permission prompt and every third party out of the app.
4. **Open points QC could not verify:** whether the Kids category exists for **Mac** apps; whether Apple counts as a
   "third party" for WeatherKit under 1.3; the exact privacy label App Review expects; and how WeatherKit's required
   attribution link fits the "no links out" rule. Each is listed in Part F.

---

## Part A: What Apple's rules say (App Review Guidelines, "Last Updated: October 16, 2026" [S1])

| # | Rule (verbatim quote) | What it means for weather | How QC verifies it | Who decides |
|---|---|---|---|---|
| A-01 | **1.3 Kids Category:** "These apps must not include links out of the app, purchasing opportunities, or other distractions to kids unless reserved for a designated area behind a parental gate." | The weather setting and any weather link (including WeatherKit's attribution link, A-12) live only in the parent area. | Play every key and the whole child area: no tap opens Safari, a web view or the App Store. The weather settings are reachable only through the gate. | QC |
| A-02 | **1.3:** "Keep in mind that once customers expect your app to follow the Kids Category requirements, it will need to continue to meet these guidelines in subsequent updates, even if you decide to deselect the category." | Weather can't be added later outside the rules by leaving the category. | — | Luan |
| A-03 | **1.3:** "Kids Category apps may not send personally identifiable information or device information to third parties." | Any network request carries the device's IP address. A **third-party** weather API would receive it, along with a location. | Build: list every host the app contacts (WX-30). Any host not run by Apple, or by us, is a FAIL. | QC; Luan for Apple's view of WeatherKit (F-02) |
| A-04 | **1.3:** "Apps in the Kids Category should not include third-party analytics or third-party advertising." … "In limited cases, third-party analytics may be permitted provided that the services do not collect or transmit the IDFA or any identifiable information about children (such as name, date of birth, email address), their location, or their devices. This includes any device, network, or other information that could be used directly or combined with other information to identify users and their devices." | "Network … information" and "their location" are named. That is the same family of data a weather API would get. | `otool -L` and `nm` on the app binary; the bundled frameworks list: no third-party SDK (WX-31). | QC |
| A-05 | **5.1.4 (b):** "For the sake of clarity, the parental gate requirement for the Kid's Category is generally not the same as securing parental consent to collect personal data under these privacy statutes." | **The gate is not consent.** If the app collects personal information (precise location), the gate alone isn't enough (Part B). | Review of the flow, Part D. | Luan (legal) |
| A-06 | **5.1.4 (b):** "apps in the Kids Category or those that collect, transmit, or have the capability to share personal information (such as name, address, email, location, photos, videos, drawings, the ability to chat, other personal data, or persistent identifiers used in combination with any of the above) from a minor must include a privacy policy and must comply with all applicable children's privacy statutes." | A privacy policy is needed anyway (Kids Category). "Location" is in Apple's list. | The policy exists (App Store Connect field and in the app behind the gate) and describes the weather request (WX-40). | Luan writes it; QC checks it matches the build |
| A-07 | **5.1.4 (a):** "Apps intended primarily for kids should not include third-party analytics or third-party advertising." | Same as A-04. | WX-31 | QC |
| A-08 | **5.1.1 (ii) Permission:** "Apps that collect user or usage data must secure user consent for the collection, even if such data is considered to be anonymous at the time of or immediately following collection. … Apps must also provide the customer with an easily accessible and understandable way to withdraw consent." | The opt-in toggle is the consent for this rule; turning it off withdraws it. | WX-10, WX-14 | QC |
| A-09 | **5.1.1 (iii) Data Minimization:** "Apps should only request access to data relevant to the core functionality of the app and should only collect and use data that is required to accomplish the relevant task." | Weather needs a rough area, not a precise position. Weather is not core to a letter toy, so the lightest option wins. | Request contents check (WX-32). | QC |
| A-10 | **5.1.1 (iv) Access:** "Where possible, provide alternative solutions for users who don't grant consent. For example, if a user declines to share Location, offer the ability to manually enter an address." | Apple names manual entry as the alternative to Location. The recommendation makes it the only way. | — | — |
| A-11 | **5.1.5 Location Services:** "Use Location Services in your app only when it is directly relevant to the features and services provided by the app. … Ensure that you notify and obtain consent before collecting, transmitting, or using location data. If your app uses Location Services, be sure to explain the purpose in your app" | If device location is used, it needs a purpose string and consent before any use. With a hand-picked city, the app doesn't use Location Services at all. | `Info.plist`: no `NSLocation*UsageDescription` keys (WX-33); no location prompt ever appears (WX-12). | QC |
| A-12 | **WeatherKit attribution [S6]:** "If your apps, web apps, or websites display any weather data from Apple … you must clearly display the Apple Weather trademark (Weather), as well as the legal link to other data sources." | The attribution needs a **link**. In a Kids app, links out must sit behind the parental gate (A-01). **Not verified:** whether showing the mark in the child area with the link only in the parent area meets WeatherKit's terms (F-03). | The child area shows no tappable link; the parent area shows the Weather mark and the legal link (WX-21). | Luan / game-dev-ios (ask Apple if unsure) |
| A-13 | **Kids apps page [S3]:** "Kids apps should not transmit personally identifiable information or device information to third parties — even in sections intended for adults — unless the parent explicitly consents." "Provide parental gates: These are adult-level tasks that must be completed in order to continue using your app or game." | **The parent area is no exemption** ("even in sections intended for adults"). The page allows third-party transmission **with explicit parent consent**, but Guideline 1.3 [S1] has no such exception. QC treats 1.3 as the rule App Review applies. | — | Luan |
| A-14 | **2.3.8 via 5.1.4:** "use of terms like 'For Kids' and 'For Children' in app metadata is reserved for the Kids Category." | Not weather-specific. Noted for the listing. | — | Luan |

### Privacy label ("App Privacy" in App Store Connect [S2])

- "'Collect' refers to transmitting data off the device and storing it in a readable form for longer than the time it
  takes you and/or your third-party partners to service the request."
- "Data that is processed only on device is not 'collected' and does not need to be disclosed in your answers."
- "if an authentication token or IP address is sent on a server call and not retained … you do not need to disclose
  this in your answers in App Store Connect." Also: "If you derive anything from that data and send it off device, the
  resulting data should be considered separately."
- "Coarse Location: Information that describes the location of a user or device with lower resolution than a latitude
  and longitude with three or more decimal places, such as Approximate Location Services." "Precise Location: … the
  same or greater resolution as a latitude and longitude with three or more decimal places".

What this means:
- The **IP address on the weather request needs no label entry** if nobody keeps it.
- A **city's coordinates rounded to fewer than three decimal places are "Coarse Location"** by Apple's definition.
- WeatherKit says "Location information is used only to provide weather forecasts, is not associated with any
  personally identifiable information, and is never tracked between requests" [S6]. It does **not** say how long Apple
  keeps a request.
- So **whether the label can stay "Data Not Collected" is not verified.** QC's safe reading: declare **Coarse
  Location, App Functionality, Not linked to the user, Not used for tracking**, unless Apple confirms otherwise (F-04).

### Privacy manifest and Info.plist [S7], [S8]

- `PrivacyInfo.xcprivacy` records "The types of data collected by your app or third-party SDK. You need to provide this
  information for your app or third-party SDK on all platforms" (macOS included). If the label declares Coarse
  Location, the manifest's `NSPrivacyCollectedDataTypes` must declare it too, so the two match. `NSPrivacyTracking`
  stays false. There are no tracking domains.
- With a hand-picked city: **no** `NSLocationWhenInUseUsageDescription`, **no** `NSLocationDefaultAccuracyReduced`.
- If device location were used, `NSLocationDefaultAccuracyReduced` = true makes "all Core Location services … receive
  service at the reduced-accuracy service level" [S8]. That key is documented for **iOS, iPadOS, visionOS and watchOS
  only, not macOS** [S8]. So a Mac build could not default to approximate location this way, which is one more reason
  to avoid device location.
- **Not verified (not read on an official page this session):**
  - the WeatherKit capability/entitlement needed in the App ID;
  - the macOS App Sandbox network entitlement (`com.apple.security.network.client`) a sandboxed Mac App Store app needs
    for outgoing connections.

  game-dev-ios should confirm both in its tech plan.

### Does the Kids category apply to the Mac app? (leader's addition 1)

- **Not verified.** No official page QC read lists the platforms the Kids category is available on.
  - The App Review Guidelines' 1.3 text names no platform [S1].
  - The Kids apps page names none [S3].
  - App Store Connect's age-rating help says Kids-category apps "can't be made available on visionOS apps". QC read
    that only through a summary of the page, so it is not a verbatim quote [S4].
- **What is verified:**
  - The App Review Guidelines apply to App Store submissions in general.
  - Section 2.4.5 adds Mac App Store requirements on top ("Apps distributed via the Mac App Store have some additional
    requirements to keep in mind") [S1].
  - Nothing in the guidelines exempts a Mac app from 1.3 or 5.1.4 if it is in the Kids category.
  - **COPPA (Part B) applies whatever the platform**: it is about the service being directed to children, not the store.
- **QC's working rule:** build the Mac app to the **same** Kids rules and the same weather flow. Then, whether or not
  Apple offers the Kids category for Mac, the Mac app meets the stricter bar, and the two builds stay one design.
- **To verify:** whoever has App Store Connect access (Luan) looks at the age-rating screen of a macOS platform
  version and records whether "Made for Kids" is offered (F-01).

---

## Part B: COPPA (16 CFR Part 312, eCFR text as of 2026-11-13 [S9]; FTC FAQ [S10])

The FTC FAQ notes: "The COPPA Rule was amended on April 22, 2025. Review the revised Rule for the most up-to-date
requirements under COPPA." [S10]. The eCFR text below is the current rule. **Not verified:** the amendments'
compliance date (the Federal Register page was not readable from this machine).

| # | Rule (verbatim) | Weather reading | Who decides |
|---|---|---|---|
| B-01 | **312.2 "Personal information"** includes "(7) A persistent identifier that can be used to recognize a user over time and across different websites or online services. Such persistent identifier includes, but is not limited to, a customer number held in a cookie, an Internet Protocol (IP) address, a processor or device serial number, or unique device identifier;" and "(9) Geolocation information sufficient to identify street name and name of a city or town" | Any network request sends the IP address (a persistent identifier). Device latitude/longitude is geolocation. | — |
| B-02 | **FAQ G.4:** "COPPA would apply if an app collects the user's longitude and latitude." | **Precise device location = personal information** → notice + verifiable parental consent before collection. | Luan (legal) |
| B-03 | **FAQ G.3:** "COPPA does not require an operator to notify parents and obtain their consent before collecting the type of coarse geolocation services described" ("coarse geolocation information, tantamount to collecting a ZIP code but nothing more specific"). "However, the operator should be quite certain that, in all instances, the geolocation information it collects is more general than that sufficient to identify street name and name of city or town." | A **city chosen by the parent, sent as coordinates rounded to about 10 km**, is coarser than a ZIP code. By G.3 it needs no consent. **Not verified:** that a city-level point counts as "more general" in the FTC's eyes (the FAQ's example is a ZIP code). | Luan (legal) |
| B-04 | **FAQ G.2:** "it is not sufficient to provide such notification and choice to the child user … If the operator intends to collect geolocation information, the operator will be responsible for notifying parents and obtaining their consent prior to such collection." | If device location were used, the choice must be the **parent's**, made **before** any collection. A gate is not proof that it's the parent (A-05). | Luan (legal) |
| B-05 | **FAQ G.1:** "COPPA covers the collection of geolocation information, not just its use or disclosure." | Not storing the location does not avoid COPPA. Sending it is enough. | — |
| B-06 | **312.2 "Collects or collection"** "means the gathering of any personal information from a child by any means, including … (3) Passive tracking of a child online." | Sending device location from the child's device counts, even without storing it. | — |
| B-07 | **312.5(c)(7)** (an exception to prior parental consent): "Where an operator collects a persistent identifier and no other personal information and such identifier is used for the sole purpose of providing support for the internal operations of the website or online service. In such case, the operator shall provide notice under § 312.4(d)(3)". "Support for the internal operations" includes "(ii) Perform network communications". | **The IP address on the weather request is exempt**, but **only if no other personal information is collected** (so no precise location) and it is used for nothing else. A **notice** is still required: the privacy policy says so. | Luan (legal) |
| B-08 | **312.4(d):** "an operator must post a prominent and clearly labeled link to an online notice of its information practices with regard to children on the home or landing page or screen of its website or online service" | The privacy notice must be reachable in the app. In a Kids app that link sits behind the gate (A-01). **Not verified:** whether a link behind a parental gate counts as "prominent" on the landing screen. | Luan (legal) |
| B-09 | **FAQ F.5:** "You are not collecting personal information simply because your app interacts with personal information that is stored on the device and is never transmitted." | A city and weather **cached on the device only** is not "collection" (Part E). | — |
| B-10 | **312.2 "Third party"** excludes "A person who provides support for the internal operations of the website or online service and who does not use or disclose information protected under this part for any other purpose." | Under COPPA, a weather provider that only serves the request and doesn't reuse the IP can count as internal-operations support, not a "third party". This is **not** the same as Apple's 1.3 wording (A-03). Both rules must be met. | Luan (legal) |

**The answers to the leader's questions:**
- **Is a coarse location / weather lookup "personal information"?**
  - Precise device location: **yes** (B-01, B-02).
  - Coarse location "tantamount to a ZIP code" or coarser: **no consent needed per the FTC FAQ** (B-03).
  - The IP address: **yes, it is personal information, but exempt** when used only for the network call and nothing
    else is collected (B-07).
- **Is verifiable parental consent needed, or does a parent-gated toggle with no data stored suffice?**
  - With **precise device location**: verifiable parental consent is needed. A gate is not consent (A-05, B-04), and
    "no data stored" doesn't help, because sending counts (B-05, B-06).
  - With a **hand-picked city sent coarsely** and nothing else: per B-03 and B-07, **no verifiable parental consent**.
    A **notice** is still needed (privacy policy, B-07, B-08), and Apple's own consent rule needs a user choice
    (A-08), which the parent's opt-in under the gate gives.
  - That conclusion is QC's reading of the FTC text, not legal advice. **Luan (legal)**.

---

## Part C: The options compared

| | What leaves the device | Kids category (Apple) | COPPA consent | Privacy label / manifest / Info.plist | Pillar 5 effect |
|---|---|---|---|---|---|
| **(a) WeatherKit + device location, precise** | Lat/long (≥ 3 decimals) + IP to Apple | Allowed only if Apple is not a "third party" under 1.3 (**not verified**, F-02); needs a 5.1.5 purpose string and consent | **Yes**, verifiable parental consent (B-02, B-04); the gate is not enough (A-05) | Label: Precise Location; manifest the same; `NSLocationWhenInUseUsageDescription`; a system location prompt | Largest break: a permission prompt and personal data |
| **(b) WeatherKit + device location, approximate** (`NSLocationDefaultAccuracyReduced`) | Approximate position + IP to Apple | As (a) | Probably **no** if truly ZIP-level or coarser (B-03); **not verified** that iOS's approximate area always is | Label: Coarse Location; location purpose string; a prompt (shows approximate); **not available on macOS** by this key [S8] | Large: still a system prompt and Core Location |
| **(c) WeatherKit + a city the parent picks** (recommended) | The city's coordinates rounded to ~0.1° (~10 km) + IP to Apple | Same open point as (a) on Apple as a "third party" (F-02), but no Location Services, no prompt, no device data | **No** VPC per B-03 + B-07 (Luan (legal)); notice in the privacy policy | Label: Coarse Location, App Functionality, not linked (safe reading; F-04); manifest the same; **no** location keys | Smallest: network only when switched on; no device data; no prompt |
| **(d) Third-party weather API** (any provider) | Location (device or city) + IP to the provider | **Conflicts with 1.3** "may not send … device information to third parties" (the IP address is network/device information, A-03, A-04) | Possibly exempt as internal-operations support (B-10), but Apple's rule is stricter | Label: the provider counts as a third-party partner; its SDK would need its own manifest | **Not allowed** for a Kids-category app in QC's reading; reject |
| **Coarse vs precise location** | Precise: ≥ 3 decimals (Apple) / street level (FTC). Coarse: fewer decimals / ZIP level or wider | Both need 5.1.5 consent if Location Services are used | Precise: VPC. Coarse: none (B-03) | Precise or Coarse Location on the label | — |

---

## Part D: Recommendation and the exact flow

**Recommendation: option (c).** WeatherKit only, with a city the parent picks by hand. Off by default. No Core
Location, no third-party service, nothing kept except on the device.

### Flow

1. **Default: off.** A fresh install makes no network request at all. The scene follows the system clock only.
2. **Parent area → parent gate** (the same gate as the other grown-up settings; an adult-level task a 2.5–3-year-old
   can't pass by mashing).
3. **"Weather in the scene" setting**, off. The parent turns it on.
4. **Consent screen** (parent-facing, in the parent's language), before anything is sent:
   - what it does: "The sky in the game will match the weather in a city you choose";
   - what leaves the device: "the city's area (about 10 km), and your device's network address, sent to Apple Weather
     when the app is open and connected; nothing is sent when it's off";
   - what is kept: "only the city and the last weather, on this device";
   - who receives it: "Apple Weather. No other company";
   - how to stop: "Turn this off at any time in this same place; the city and weather are deleted";
   - a link to the privacy policy (behind the gate already);
   - two buttons: **Turn on** / **Not now**. Only **Turn on** goes on.
5. **Pick a city:** a list or search **bundled in the app** (no network for the search; no typing a street address).
   The app stores the city's name and coordinates rounded to 1 decimal place (~11 km).
6. **Request:** when weather is on, the app is in the foreground and the network is reachable, it asks WeatherKit for
   the **current condition** at the rounded city point. At most once per hour (a QC proposal; the dev decides).
7. **Show:** the scene maps the condition to a small set of looks (sunny, cloudy, rain, snow, fog, night from the
   clock). No numbers or text for the child. The **Weather mark and the legal attribution link appear only in the
   parent area** (pending F-03).
8. **No network, a failure or an old cache:** the clock scene, silently. No error message to the child, no retry
   spinner.
9. **Turn off:** this stops all requests and deletes the city and the cached weather at once.

### What to store (leader's addition 2) and why it changes nothing

- A cache kept **only on the device** is not "collected" for Apple's label [S2] or under COPPA (B-09). It adds no label
  row and no consent. It does add one thing: **a stored city is location data on a device a child uses**. If it ever
  left the device (iCloud backup, sync, a crash report), the analysis would change.
- **Minimum to store:** the city's display name, its coordinates at 1 decimal place, the last condition code (for
  example `rain`), and the time it was fetched (so stale weather is dropped, for example after 3 hours).
- **Store nothing else:** no temperatures, forecast, history, request log, device location or IP.
- Keep it in the app's own preferences. **Do not sync it** (no `NSUbiquitousKeyValueStore`, no CloudKit). Delete it on
  turn-off.
- **Not verified:** whether to exclude it from device backups (`isExcludedFromBackup`). Apple's rules read this session
  don't address backups; it's a cheap extra step if Luan wants it.

### Conflict with Pillar 5 (for the design owner; QC doesn't edit the concept)

Pillar 5's design test says: "Debating a feature that needs the network or data, or none → none." The anti-pillars
list "NOT ads, in-app purchases, accounts, network or analytics." K-08 overrides both for this one feature. If K-08
stands:
- the concept and the privacy policy must stop saying "offline" or "no network" without qualification;
- the store listing must not promise "no internet needed";
- the "no data" claim holds only for the label reading in F-04.

---

## Part E: Test cases QC would run (when a build exists)

Tools are the same as on the last game: `xcrun simctl`, `plutil`, `otool`, `nm`, `codesign -d --entitlements`, and
`nettop -p <pid>` on the Mac host (Simulator and Mac app processes are host processes). They're all on this Mac
already; nothing new is installed. Verdicts are PASS / FAIL / NOT ASSESSED; no evidence file = NO EVIDENCE.

| ID | Check | Steps | Expected |
|---|---|---|---|
| WX-01 | Off by default, no traffic | Fresh install (iPad sim, Mac app); play 5 min, all 36 keys; `nettop -p <pid> -L 1` before and after | 0 bytes in/out; no weather keys in prefs |
| WX-02 | Clock scene without weather | Set the sim clock to morning / noon / evening / night | Scene follows the clock; no network |
| WX-10 | The setting is behind the gate | From the child area, mash every key and the screen for 60 s (XCUITest) | Gate never passed; weather setting never shown |
| WX-11 | Gate resists a toddler | 100 random taps on the gate screen | Not passed; gate closes back to play |
| WX-12 | No location prompt ever | Full flow on, off, on; Mac and iPad | No system location alert at any point |
| WX-13 | Consent screen before any request | Turn on → consent screen; tap "Not now" | Stays off; 0 bytes (nettop) |
| WX-14 | Turn on, then off deletes data | Turn on, pick a city, wait for weather; turn off; dump prefs | Requests stop; city and cache keys gone |
| WX-15 | Consent text matches the build | Compare the screen text with WX-30/32 results | Every item true (city area, Apple only, kept on device) |
| WX-20 | No link in the child area | Play everything with weather on | No tap opens Safari, the App Store or a web view |
| WX-21 | Attribution | Parent area, weather on | Weather mark + legal link present there; child area has no tappable link (per F-03) |
| WX-22 | Offline / failure | Airplane mode (device) or no network (Mac Wi-Fi off); also a bad response | Clock scene; no error, alert or spinner for the child |
| WX-23 | Stale cache | Weather on, fetch; go offline; advance the clock 4 h | Cached weather dropped after the limit; clock scene |
| WX-24 | Rate | Weather on, app open 2 h | At most one request per hour (or the dev's number) |
| WX-25 | Background | Send the app to the background 10 min | No requests while in the background |
| WX-26 | City change | Change city in the parent area | One new request; old city and cache replaced |
| WX-30 | Hosts contacted | Weather on, 10 min; `nettop` + `log stream` for the app's connections | Only Apple WeatherKit hosts (exact names: **not verified**, record what's seen); no other host |
| WX-31 | No third-party code | `otool -L`, `nm -U`, `find *.app -name "*.framework"` | Only Apple frameworks; no analytics, ads or weather SDK |
| WX-32 | Coarse request | Debug build: log the request coordinates | Rounded to 1 decimal; never the device position (there is none) |
| WX-33 | Info.plist | `plutil -p Info.plist` | No `NSLocation*` keys; no `NSUserTrackingUsageDescription` |
| WX-34 | Privacy manifest | `plutil -p PrivacyInfo.xcprivacy` | `NSPrivacyTracking` false; collected types match the App Store label (F-04) |
| WX-35 | Entitlements | `codesign -d --entitlements - <app>` | WeatherKit and (Mac) network client only, as game-dev-ios's plan lists them; nothing else |
| WX-36 | Cache never leaves the device | Search the binary and prefs for iCloud key-value or CloudKit use | None |
| WX-40 | Privacy policy | Read the policy in App Store Connect and in the app | Says weather is optional, off by default, what's sent and to whom, kept on device, how to turn it off |
| WX-41 | Both platforms | Run WX-01…26 on the iPad simulator and the Mac app | Same results on both |

---

## Part F: Not verified / for Luan

| # | Question | Why it's open | Who |
|---|---|---|---|
| F-01 | Does the App Store offer the Kids category ("Made for Kids") for a **macOS** app? | No official page read lists the platforms (Part A). | Luan checks App Store Connect |
| F-02 | Is **Apple's WeatherKit** a "third party" under Guideline 1.3? | 1.3 bans sending device information to third parties; Apple's pages don't say how first-party services count. QC's reading: Apple is the platform, not a third party, but **not verified**. | Luan (ask App Review if needed) |
| F-03 | Does showing the Weather mark in the child area, with the **legal link only behind the gate**, satisfy WeatherKit's attribution terms? | WeatherKit requires the link; 1.3 bans links out outside a gated area. | Luan / game-dev-ios |
| F-04 | Privacy label: "Data Not Collected" or "Coarse Location, App Functionality, not linked"? | Apple's label rules exempt an un-retained IP, but the page doesn't say how a rounded location sent to Apple is treated. QC's safe reading is to declare it. | Luan |
| F-05 | Is a city-level point "more general than street + city" for the FTC (B-03)? | The FAQ's example is a ZIP code. | Luan (legal) |
| F-06 | The 2025 COPPA amendments' compliance date | The Federal Register page wasn't readable here. | Luan (legal) |
| F-07 | WeatherKit entitlement; Mac sandbox network entitlement | Not read on an official page this session. | game-dev-ios (TASK-030 plan) |
| F-08 | Does the gated privacy-policy link meet 312.4(d) "prominent … on the home or landing page"? | The Kids gate and the COPPA notice pull in opposite directions. | Luan (legal) |
| F-09 | Other laws (GDPR-K, UK Children's Code, Vietnam) | Out of this task's scope. | Luan (legal) |

---

## Sources (all read 2026-11-17)

- [S1] Apple, App Review Guidelines (page shows "Last Updated: October 16, 2026"): https://developer.apple.com/app-store/review/guidelines/ — sections 1.3, 2.4.5, 5.1.1, 5.1.4, 5.1.5 (read in full, raw page text)
- [S2] Apple, App privacy details on the App Store: https://developer.apple.com/app-store/app-privacy-details/
- [S3] Apple, Design safe and age-appropriate experiences (Kids apps): https://developer.apple.com/app-store/kids-apps/
- [S4] Apple, App Store Connect Help, Set an app age rating: https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating (read as a tool summary, not verbatim)
- [S5] Apple, WeatherKit: https://developer.apple.com/weatherkit/ and documentation https://developer.apple.com/documentation/weatherkit (platforms: iOS, iPadOS, Mac Catalyst, macOS, tvOS, visionOS, watchOS)
- [S6] Apple, WeatherKit Get started (privacy statement, attribution, 500,000 calls/month included with the Apple Developer Program): https://developer.apple.com/weatherkit/get-started/ ; data sources: https://developer.apple.com/weatherkit/data-source-attribution/
- [S7] Apple, Privacy manifest files: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- [S8] Apple, NSLocationDefaultAccuracyReduced (platforms: iOS, iPadOS, visionOS, watchOS): https://developer.apple.com/documentation/bundleresources/information-property-list/nslocationdefaultaccuracyreduced ; CLAccuracyAuthorization (iOS, iPadOS, Mac Catalyst, macOS, tvOS, visionOS, watchOS): https://developer.apple.com/documentation/corelocation/claccuracyauthorization
- [S9] eCFR, 16 CFR Part 312, Children's Online Privacy Protection Rule (version 2026-11-13, via the eCFR API): https://www.ecfr.gov/current/title-16/chapter-I/subchapter-C/part-312 — 312.2 definitions, 312.4(d), 312.5(c)(7)
- [S10] FTC, Complying with COPPA: Frequently Asked Questions: https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions — sections C.5, F.5, G.1–G.4
- Android counterpart format: `qa/TASK-032-kids-store-rules-android` @ ac7b97b (`kids-store-rules-google.md`)
